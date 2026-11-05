import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gi_english_website/util/AuthService.dart';

/// 원어민 강사 스케줄: 닫힌 시간 + 매주 반복 닫기 + 이미 예약된 시간.
///
/// Firestore
/// - teacher_closed_slots/{teacherUid}_{yyyy-MM-dd}_{HHmm}
/// - teacher_closed_routines/{teacherUid}_{weekday}_{HHmm}
/// - teacher_open_exceptions/{teacherUid}_{yyyy-MM-dd}_{HHmm}
/// - teacher_occupied_slots/{teacherUid}_{yyyy-MM-dd}_{HHmm}
class TeacherScheduleService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static String dateKey(DateTime d) {
    final day = dateOnly(d);
    final y = day.year.toString().padLeft(4, '0');
    final m = day.month.toString().padLeft(2, '0');
    final dd = day.day.toString().padLeft(2, '0');
    return '$y-$m-$dd';
  }

  static String slotKey(DateTime d, String time) => '${dateKey(d)}_$time';

  static String routineKey(int weekday, String time) => '${weekday}_$time';

  static String docId(String teacherUid, DateTime d, String time) =>
      '${teacherUid}_${dateKey(d)}_${time.replaceAll(':', '')}';

  static String routineDocId(String teacherUid, int weekday, String time) =>
      '${teacherUid}_${weekday}_${time.replaceAll(':', '')}';

  static Future<String> resolveTeacherUid({
    required String nativeTeacherUid,
    required String nativeTeacherId,
  }) async {
    if (nativeTeacherUid.isNotEmpty) return nativeTeacherUid;
    return AuthService.uidForNativeProfile(nativeTeacherId);
  }

  static Future<TeacherAvailability> load(String teacherUid) async {
    if (teacherUid.isEmpty) {
      return TeacherAvailability(teacherUid: '');
    }

    final closedKeys = <String>{};
    final occupiedKeys = <String>{};
    final routineKeys = <String>{};
    final exceptionKeys = <String>{};
    final notes = <String, String>{};

    try {
      final closed = await _firestore
          .collection('teacher_closed_slots')
          .where('teacherId', isEqualTo: teacherUid)
          .get();
      for (final doc in closed.docs) {
        final data = doc.data();
        final key = data['slotKey']?.toString() ?? '';
        if (key.isNotEmpty) closedKeys.add(key);
        final note = data['note']?.toString().trim() ?? '';
        if (key.isNotEmpty && note.isNotEmpty) notes[key] = note;
      }
    } catch (e) {
      print('닫힌 스케줄 조회 오류: $e');
    }

    try {
      final routines = await _firestore
          .collection('teacher_closed_routines')
          .where('teacherId', isEqualTo: teacherUid)
          .get();
      for (final doc in routines.docs) {
        final key = doc.data()['routineKey']?.toString() ?? '';
        if (key.isNotEmpty) routineKeys.add(key);
      }
    } catch (e) {
      print('반복 닫기 조회 오류: $e');
    }

    try {
      final exceptions = await _firestore
          .collection('teacher_open_exceptions')
          .where('teacherId', isEqualTo: teacherUid)
          .get();
      for (final doc in exceptions.docs) {
        final key = doc.data()['slotKey']?.toString() ?? '';
        if (key.isNotEmpty) exceptionKeys.add(key);
      }
    } catch (e) {
      print('예외 열기 조회 오류: $e');
    }

    try {
      final occupied = await _firestore
          .collection('teacher_occupied_slots')
          .where('teacherId', isEqualTo: teacherUid)
          .get();
      for (final doc in occupied.docs) {
        final key = doc.data()['slotKey']?.toString() ?? '';
        if (key.isNotEmpty) occupiedKeys.add(key);
      }
    } catch (e) {
      print('예약된 스케줄 조회 오류: $e');
    }

    return TeacherAvailability(
      teacherUid: teacherUid,
      closedKeys: closedKeys,
      occupiedKeys: occupiedKeys,
      routineKeys: routineKeys,
      exceptionKeys: exceptionKeys,
      notes: notes,
    );
  }

  static Future<String?> setClosed({
    required String teacherUid,
    required DateTime date,
    required String time,
    required bool closed,
    String note = '',
  }) async {
    if (teacherUid.isEmpty) return '강사 계정이 없습니다.';
    final day = dateOnly(date);
    final ref = _firestore
        .collection('teacher_closed_slots')
        .doc(docId(teacherUid, day, time));
    try {
      if (closed) {
        final trimmed = note.trim();
        await ref.set({
          'teacherId': teacherUid,
          'dateKey': dateKey(day),
          'time': time,
          'slotKey': slotKey(day, time),
          'note': trimmed.isEmpty ? FieldValue.delete() : trimmed,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        await _deleteIfExists(ref);
      }
      return null;
    } catch (e) {
      print('스케줄 변경 오류: $e');
      return '스케줄 저장에 실패했습니다.';
    }
  }

  static Future<String?> setRoutineClosed({
    required String teacherUid,
    required DateTime date,
    required String time,
    required bool closed,
  }) async {
    if (teacherUid.isEmpty) return '강사 계정이 없습니다.';
    final weekday = dateOnly(date).weekday;
    final ref = _firestore
        .collection('teacher_closed_routines')
        .doc(routineDocId(teacherUid, weekday, time));
    try {
      if (closed) {
        await ref.set({
          'teacherId': teacherUid,
          'weekday': weekday,
          'time': time,
          'routineKey': routineKey(weekday, time),
          'createdAt': FieldValue.serverTimestamp(),
        });
        // 없는 문서를 delete하면 rules가 resource.data를 읽지 못해
        // permission-denied가 난다. 루틴은 이미 저장된 뒤라 새로고침하면
        // '매주'로 보이지만, 첫 저장은 실패로 표시됐다.
        await _deleteIfExists(_firestore
            .collection('teacher_open_exceptions')
            .doc(docId(teacherUid, dateOnly(date), time)));
        await _deleteIfExists(_firestore
            .collection('teacher_closed_slots')
            .doc(docId(teacherUid, dateOnly(date), time)));
      } else {
        await _deleteIfExists(ref);
      }
      return null;
    } catch (e) {
      print('반복 스케줄 변경 오류: $e');
      return '반복 스케줄 저장에 실패했습니다.';
    }
  }

  static Future<String?> setOpenException({
    required String teacherUid,
    required DateTime date,
    required String time,
    required bool openThisDay,
  }) async {
    if (teacherUid.isEmpty) return '강사 계정이 없습니다.';
    final day = dateOnly(date);
    final ref = _firestore
        .collection('teacher_open_exceptions')
        .doc(docId(teacherUid, day, time));
    try {
      if (openThisDay) {
        await ref.set({
          'teacherId': teacherUid,
          'dateKey': dateKey(day),
          'time': time,
          'slotKey': slotKey(day, time),
          'createdAt': FieldValue.serverTimestamp(),
        });
        await _deleteIfExists(_firestore
            .collection('teacher_closed_slots')
            .doc(docId(teacherUid, day, time)));
      } else {
        await _deleteIfExists(ref);
      }
      return null;
    } catch (e) {
      print('예외 스케줄 변경 오류: $e');
      return '스케줄 저장에 실패했습니다.';
    }
  }

  static Future<void> _deleteIfExists(DocumentReference ref) async {
    final snap = await ref.get();
    if (snap.exists) await ref.delete();
  }

  static Future<String?> setClosedMany({
    required String teacherUid,
    required List<DateTime> dates,
    required List<String> times,
    required bool closed,
    String note = '',
  }) async {
    if (dates.length != times.length) return '선택한 시간이 올바르지 않습니다.';
    for (var i = 0; i < dates.length; i++) {
      final error = await setClosed(
        teacherUid: teacherUid,
        date: dates[i],
        time: times[i],
        closed: closed,
        note: note,
      );
      if (error != null) return error;
    }
    return null;
  }

  static Future<String?> setRoutineClosedMany({
    required String teacherUid,
    required List<DateTime> dates,
    required List<String> times,
    required bool closed,
  }) async {
    if (dates.length != times.length) return '선택한 시간이 올바르지 않습니다.';
    for (var i = 0; i < dates.length; i++) {
      final error = await setRoutineClosed(
        teacherUid: teacherUid,
        date: dates[i],
        time: times[i],
        closed: closed,
      );
      if (error != null) return error;
    }
    return null;
  }

  static DocumentReference occupiedRef(
      String teacherUid, DateTime date, String time) {
    final day = dateOnly(date);
    return _firestore
        .collection('teacher_occupied_slots')
        .doc(docId(teacherUid, day, time));
  }

  static Map<String, dynamic> occupiedPayload({
    required String teacherUid,
    required DateTime date,
    required String time,
    required String bookingId,
  }) {
    final day = dateOnly(date);
    return {
      'teacherId': teacherUid,
      'dateKey': dateKey(day),
      'time': time,
      'slotKey': slotKey(day, time),
      'bookingId': bookingId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

class TeacherAvailability {
  final String teacherUid;
  final Set<String> closedKeys;
  final Set<String> occupiedKeys;
  final Set<String> routineKeys;
  final Set<String> exceptionKeys;
  final Map<String, String> notes;

  TeacherAvailability({
    required this.teacherUid,
    Set<String>? closedKeys,
    Set<String>? occupiedKeys,
    Set<String>? routineKeys,
    Set<String>? exceptionKeys,
    Map<String, String>? notes,
  })  : closedKeys = closedKeys ?? {},
        occupiedKeys = occupiedKeys ?? {},
        routineKeys = routineKeys ?? {},
        exceptionKeys = exceptionKeys ?? {},
        notes = notes ?? {};

  String noteFor(DateTime date, String time) =>
      notes[TeacherScheduleService.slotKey(date, time)] ?? '';

  bool isOneOffClosed(DateTime date, String time) =>
      closedKeys.contains(TeacherScheduleService.slotKey(date, time));

  bool isRoutine(DateTime date, String time) =>
      routineKeys.contains(
          TeacherScheduleService.routineKey(date.weekday, time));

  bool isException(DateTime date, String time) =>
      exceptionKeys.contains(TeacherScheduleService.slotKey(date, time));

  bool isClosed(DateTime date, String time) {
    if (isOneOffClosed(date, time)) return true;
    return isRoutine(date, time) && !isException(date, time);
  }

  bool isOccupied(DateTime date, String time) =>
      occupiedKeys.contains(TeacherScheduleService.slotKey(date, time));

  List<String> openTimes(DateTime date, List<String> remaining) {
    return remaining
        .where((time) => !isClosed(date, time) && !isOccupied(date, time))
        .toList();
  }

  String weekdayLabel(DateTime date) {
    const names = ['월', '화', '수', '목', '금', '토', '일'];
    return names[date.weekday - 1];
  }
}
