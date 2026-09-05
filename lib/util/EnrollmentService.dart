import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:gi_english_website/class/OnlineCourse.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/UrlIUtil.dart';

/// 온라인 프로그램 수강 정보(결제/배정)와 강의 자료를 다루는 서비스.
///
/// Firestore 구조
/// - members/{uid} : { email, name, phone, isActive, teacherId }
/// - enrollments/{docId} : {
///     userId, email, memberName, courseId, isActive,
///     totalSessions, completedSessions, remainingSessions,
///     isPaid, paidAmount, paidAt, paymentNote,
///     expiresAt, createdAt, lastSessionAt
///   }
/// - online_courses/{courseId} : { meetingUrl, updatedAt }
/// - online_lessons/{docId} : { courseId, title, description, videoUrl, order, createdAt }
/// - online_weeks/{docId} : {
///     courseId, weekNumber, title, description, videoUrl,
///     problemLinks: [{ title, url }],
///     checklistItems: [{ id, label }],
///     createdAt, updatedAt
///   }
/// - enrollments/{id}/session_logs/{logId} : { delta, completedAfter, totalSessions, adminName, createdAt }
/// - enrollments/{id}/week_progress/{weekId} : { checkedItemIds, updatedAt }
/// - week_bookings/{docId} : {
///     userId, memberName, courseId, weekId, weekNumber,
///     date, time, status, teacherId, createdAt, confirmedAt, confirmedBy
///   }
class EnrollmentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// 화상수업 링크가 따로 등록되지 않은 경우 사용하는 기본 Jitsi 회의실.
  static const String _jitsiBaseUrl = 'https://meet.jit.si';

  /// 1주차에 기본으로 넣는 실험 인강. 선생님이 따로 등록하지 않아도 모든 과정에 보인다.
  static const String defaultWeek1VideoUrl = 'https://youtu.be/C4Dr_beoGoc';

  static String defaultWeekId(String courseId, int weekNumber) =>
      '${courseId}_week_$weekNumber';

  static OnlineWeek defaultWeek1(String courseId) {
    return OnlineWeek(
      id: defaultWeekId(courseId, 1),
      courseId: courseId,
      weekNumber: 1,
      title: '1주차 인강: 관사의 쓰임',
      description: '이번 주 인강을 시청한 뒤 체크리스트를 직접 확인하세요.',
      videoUrl: defaultWeek1VideoUrl,
      problemLinks: const [
        WeekProblemLink(title: '리뷰 및 문제풀이', url: ''),
      ],
      checklistItems: const [
        WeekChecklistItem(id: 'watch_video', label: '인강 시청하기'),
        WeekChecklistItem(id: 'solve_problems', label: '문제풀이 하기'),
      ],
    );
  }

  /// 로그인한 회원이 결제(배정)한 과정 목록.
  static Future<List<OnlineCourse>> myCourses() async {
    final user = AuthService.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _firestore
          .collection('enrollments')
          .where('userId', isEqualTo: user.uid)
          .get();

      final now = DateTime.now();
      final List<OnlineCourse> courses = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();

        if (data['isActive'] == false) continue;

        final expiresAt = data['expiresAt'];
        if (expiresAt is Timestamp && expiresAt.toDate().isBefore(now)) {
          continue;
        }

        final course =
            OnlineCourse.findById(data['courseId']?.toString() ?? '');
        if (course != null && !courses.contains(course)) {
          courses.add(course);
        }
      }

      courses.sort((a, b) => a.order.compareTo(b.order));
      return courses;
    } catch (e) {
      print('수강 정보 조회 오류: $e');
      return [];
    }
  }

  /// 로그인한 회원의 수강 배정 상세(남은 회차 등 포함).
  static Future<List<EnrollmentRecord>> myEnrollments() async {
    final user = AuthService.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _firestore
          .collection('enrollments')
          .where('userId', isEqualTo: user.uid)
          .get();

      final now = DateTime.now();
      final List<EnrollmentRecord> records = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['isActive'] == false) continue;

        final expiresAt = data['expiresAt'];
        if (expiresAt is Timestamp && expiresAt.toDate().isBefore(now)) {
          continue;
        }

        final record = EnrollmentRecord.fromMap(doc.id, data);
        if (record.course != null) records.add(record);
      }

      records.sort((a, b) {
        final ao = a.course?.order ?? 0;
        final bo = b.course?.order ?? 0;
        return ao.compareTo(bo);
      });
      return records;
    } catch (e) {
      print('내 수강 정보 조회 오류: $e');
      return [];
    }
  }

  /// 과정의 강의 영상 목록. 아직 업로드된 자료가 없으면 빈 목록.
  static Future<List<OnlineLesson>> lessons(String courseId) async {
    try {
      final snapshot = await _firestore
          .collection('online_lessons')
          .where('courseId', isEqualTo: courseId)
          .get();

      final lessons = snapshot.docs
          .map((doc) => OnlineLesson.fromMap(doc.id, doc.data()))
          .toList();

      lessons.sort((a, b) => a.order.compareTo(b.order));
      return lessons;
    } catch (e) {
      print('강의 자료 조회 오류: $e');
      return [];
    }
  }

  /// 과정의 화상수업 입장 주소.
  static Future<String> meetingUrl(String courseId) async {
    try {
      final doc =
          await _firestore.collection('online_courses').doc(courseId).get();

      if (doc.exists) {
        final url = doc.data()?['meetingUrl']?.toString();
        if (url != null && url.isNotEmpty) return url;
      }
    } catch (e) {
      print('화상수업 링크 조회 오류: $e');
    }

    return defaultMeetingUrl(courseId);
  }

  static String defaultMeetingUrl(String courseId) {
    final roomName = 'GleamIsland-$courseId';
    return '$_jitsiBaseUrl/$roomName';
  }

  // ----- 회차별 화상수업 -----

  /// 과정의 화상수업 회차 목록 (회차 순).
  static Future<List<OnlineSession>> sessions(String courseId) async {
    try {
      final snapshot = await _firestore
          .collection('online_sessions')
          .where('courseId', isEqualTo: courseId)
          .get();

      final list = snapshot.docs
          .map((doc) => OnlineSession.fromMap(doc.id, doc.data()))
          .toList();

      list.sort((a, b) => a.order.compareTo(b.order));
      return list;
    } catch (e) {
      print('화상수업 회차 조회 오류: $e');
      return [];
    }
  }

  /// 화상수업 회차 생성. meetingUrl이 비어 있으면 과정별 기본 Jitsi 방을 회차별로 만든다.
  static Future<String?> addSession({
    required String courseId,
    required String title,
    required int order,
    String meetingUrl = '',
    DateTime? scheduledAt,
  }) async {
    try {
      if (title.trim().isEmpty) return '회차 제목을 입력해주세요.';
      if (order <= 0) return '회차 번호는 1 이상이어야 합니다.';

      final url = meetingUrl.trim().isEmpty
          ? '$_jitsiBaseUrl/GleamIsland-$courseId-$order'
          : meetingUrl.trim();

      await _firestore.collection('online_sessions').add({
        'courseId': courseId,
        'title': title.trim(),
        'order': order,
        'meetingUrl': url,
        'isLive': false,
        'scheduledAt':
            scheduledAt == null ? null : Timestamp.fromDate(scheduledAt),
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      print('화상수업 회차 생성 오류: $e');
      return '회차 생성에 실패했습니다.';
    }
  }

  /// 진행 중으로 표시된 모든 회차 (관리자 배너용).
  static Future<List<OnlineSession>> liveSessions() async {
    try {
      final snapshot = await _firestore
          .collection('online_sessions')
          .where('isLive', isEqualTo: true)
          .get();

      final list = snapshot.docs
          .map((doc) => OnlineSession.fromMap(doc.id, doc.data()))
          .toList();

      list.sort((a, b) => a.order.compareTo(b.order));
      return list;
    } catch (e) {
      print('진행 중 화상수업 조회 오류: $e');
      return [];
    }
  }

  /// 회차를 만들고 생성된 문서 id를 돌려준다.
  /// 실패 시 null을 반환한다.
  static Future<String?> createSessionReturningId({
    required String courseId,
    required String title,
    required int order,
    String meetingUrl = '',
    DateTime? scheduledAt,
  }) async {
    try {
      final url = meetingUrl.trim().isEmpty
          ? '$_jitsiBaseUrl/GleamIsland-$courseId-$order'
          : meetingUrl.trim();

      final ref = await _firestore.collection('online_sessions').add({
        'courseId': courseId,
        'title': title.trim(),
        'order': order,
        'meetingUrl': url,
        'isLive': false,
        'scheduledAt':
            scheduledAt == null ? null : Timestamp.fromDate(scheduledAt),
        'createdAt': FieldValue.serverTimestamp(),
      });
      return ref.id;
    } catch (e) {
      print('화상수업 회차 생성 오류: $e');
      return null;
    }
  }

  /// 수업 시작/종료. 시작 시 회원 화면의 입장 버튼이 활성화된다.
  static Future<String?> setSessionLive({
    required String sessionId,
    required bool isLive,
    String hostName = '',
  }) async {
    try {
      final payload = <String, dynamic>{
        'isLive': isLive,
        'hostName': hostName,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (isLive) {
        payload['startedAt'] = FieldValue.serverTimestamp();
        payload['endedAt'] = null;
      } else {
        payload['endedAt'] = FieldValue.serverTimestamp();
      }

      await _firestore
          .collection('online_sessions')
          .doc(sessionId)
          .update(payload);
      return null;
    } catch (e) {
      print('화상수업 상태 변경 오류: $e');
      return '수업 상태 변경에 실패했습니다.';
    }
  }

  static Future<String?> updateSession({
    required String sessionId,
    required String title,
    required int order,
    required String meetingUrl,
    DateTime? scheduledAt,
  }) async {
    try {
      if (title.trim().isEmpty) return '회차 제목을 입력해주세요.';
      if (order <= 0) return '회차 번호는 1 이상이어야 합니다.';

      await _firestore.collection('online_sessions').doc(sessionId).update({
        'title': title.trim(),
        'order': order,
        'meetingUrl': meetingUrl.trim(),
        'scheduledAt':
            scheduledAt == null ? null : Timestamp.fromDate(scheduledAt),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      print('화상수업 회차 수정 오류: $e');
      return '회차 수정에 실패했습니다.';
    }
  }

  static Future<String?> deleteSession(String sessionId) async {
    try {
      await _firestore.collection('online_sessions').doc(sessionId).delete();
      return null;
    } catch (e) {
      print('화상수업 회차 삭제 오류: $e');
      return '회차 삭제에 실패했습니다.';
    }
  }

  // ----- 관리자용 -----

  /// 전체 수강 배정 목록.
  /// [memberIds]가 있으면 해당 회원들의 배정만 반환한다 (강사용).
  static Future<List<EnrollmentRecord>> listEnrollments(
      {List<String>? memberIds}) async {
    try {
      final snapshot = await _firestore.collection('enrollments').get();

      var list = snapshot.docs
          .map((doc) => EnrollmentRecord.fromMap(doc.id, doc.data()))
          .toList();

      if (memberIds != null) {
        final allowed = memberIds.toSet();
        list = list.where((e) => allowed.contains(e.userId)).toList();
      }

      list.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return list;
    } catch (e) {
      print('수강 배정 목록 조회 오류: $e');
      return [];
    }
  }

  /// 이메일로 회원에게 과정 배정.
  /// [allowedMemberIds]가 있으면 해당 회원에게만 배정 가능하다 (강사용).
  static Future<String?> assignCourseByEmail({
    required String email,
    required String courseId,
    required int totalSessions,
    DateTime? expiresAt,
    List<String>? allowedMemberIds,
    bool isPaid = false,
    int paidAmount = 0,
    String paymentNote = '',
  }) async {
    try {
      if (totalSessions <= 0) {
        return '전체 수업 횟수는 1회 이상이어야 합니다.';
      }

      final member = await AuthService.findMemberByEmail(email);
      if (member == null) {
        return '해당 이메일의 회원을 찾을 수 없습니다. 먼저 회원가입이 필요합니다.';
      }

      final userId = member['uid']?.toString() ?? '';
      if (userId.isEmpty) return '회원 정보가 올바르지 않습니다.';

      if (allowedMemberIds != null && !allowedMemberIds.contains(userId)) {
        return '배정된 회원에게만 수업을 등록할 수 있습니다.';
      }

      if (OnlineCourse.findById(courseId) == null) {
        return '유효하지 않은 과정입니다.';
      }

      // 이미 활성 배정이 있으면 중복 생성하지 않음
      final existing = await _firestore
          .collection('enrollments')
          .where('userId', isEqualTo: userId)
          .get();

      DocumentReference? existingRef;
      for (final doc in existing.docs) {
        if (doc.data()['courseId']?.toString() == courseId) {
          existingRef = doc.reference;
          break;
        }
      }

      if (existingRef != null) {
        return '이미 배정된 과정입니다. 회원의 배정 목록에서 변경 또는 복구해주세요.';
      }

      final payload = <String, dynamic>{
        'userId': userId,
        'email': email.trim(),
        'memberName': member['name']?.toString() ?? '',
        'courseId': courseId,
        'isActive': true,
        'totalSessions': totalSessions,
        'completedSessions': 0,
        'remainingSessions': totalSessions,
        'isPaid': isPaid,
        'paidAmount': paidAmount,
        'paymentNote': paymentNote,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (isPaid) {
        payload['paidAt'] = FieldValue.serverTimestamp();
      }

      if (expiresAt != null) {
        payload['expiresAt'] = Timestamp.fromDate(expiresAt);
      }

      payload['createdAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('enrollments').add(payload);

      return null;
    } catch (e) {
      print('수강 배정 오류: $e');
      return '수강 배정 중 오류가 발생했습니다.';
    }
  }

  /// 결제 정보 수정 (메인 관리자용).
  static Future<String?> updatePaymentInfo({
    required String enrollmentId,
    required bool isPaid,
    required int paidAmount,
    String paymentNote = '',
  }) async {
    try {
      final payload = <String, dynamic>{
        'isPaid': isPaid,
        'paidAmount': paidAmount,
        'paymentNote': paymentNote,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (isPaid) {
        payload['paidAt'] = FieldValue.serverTimestamp();
      } else {
        payload['paidAt'] = null;
      }
      await _firestore
          .collection('enrollments')
          .doc(enrollmentId)
          .update(payload);
      return null;
    } catch (e) {
      print('결제 정보 수정 오류: $e');
      return '결제 정보 수정에 실패했습니다.';
    }
  }

  static Future<String?> setEnrollmentActive(
      String enrollmentId, bool isActive) async {
    try {
      await _firestore.collection('enrollments').doc(enrollmentId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      print('수강 상태 변경 오류: $e');
      return '수강 상태 변경에 실패했습니다.';
    }
  }

  /// 배정 과정 또는 전체 회차를 변경한다.
  ///
  /// 과정이 바뀌면 새 과정으로 간주해 진행 회차를 0으로 초기화한다.
  /// 같은 과정의 전체 회차만 바꾸면 기존 진행 횟수를 유지한다.
  static Future<String?> updateEnrollment({
    required String enrollmentId,
    required String userId,
    required String currentCourseId,
    required String courseId,
    required int totalSessions,
  }) async {
    try {
      if (OnlineCourse.findById(courseId) == null) {
        return '유효하지 않은 과정입니다.';
      }
      if (totalSessions <= 0) {
        return '전체 수업 횟수는 1회 이상이어야 합니다.';
      }

      if (currentCourseId != courseId) {
        final userEnrollments = await _firestore
            .collection('enrollments')
            .where('userId', isEqualTo: userId)
            .get();
        final duplicated = userEnrollments.docs.any((doc) =>
            doc.id != enrollmentId &&
            doc.data()['courseId']?.toString() == courseId);
        if (duplicated) {
          return '해당 회원에게 이미 배정된 과정입니다.';
        }
      }

      final ref = _firestore.collection('enrollments').doc(enrollmentId);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(ref);
        if (!snapshot.exists) {
          throw StateError('수강 배정 정보를 찾을 수 없습니다.');
        }

        final data = snapshot.data() as Map<String, dynamic>;
        final courseChanged = currentCourseId != courseId;
        final previousCompleted = _intValue(data['completedSessions']);
        final completed = courseChanged
            ? 0
            : previousCompleted.clamp(0, totalSessions).toInt();

        transaction.update(ref, {
          'courseId': courseId,
          'totalSessions': totalSessions,
          'completedSessions': completed,
          'remainingSessions': totalSessions - completed,
          'isActive': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      return null;
    } catch (e) {
      print('수강 배정 변경 오류: $e');
      return '수강 배정 변경에 실패했습니다.';
    }
  }

  /// 화상수업 완료 횟수를 증감하고 처리 이력을 남긴다.
  /// delta는 보통 1(완료) 또는 -1(되돌리기).
  ///
  /// [adminName]은 이력에 남길 처리자 이름이다.
  static Future<SessionUpdateResult> adjustCompletedSessions(
      String enrollmentId, int delta,
      {String adminName = ''}) async {
    try {
      final ref = _firestore.collection('enrollments').doc(enrollmentId);
      final logRef = ref.collection('session_logs').doc();

      final result = await _firestore
          .runTransaction<SessionUpdateResult>((transaction) async {
        final snapshot = await transaction.get(ref);
        if (!snapshot.exists) {
          throw StateError('수강 배정 정보를 찾을 수 없습니다.');
        }

        final data = snapshot.data() as Map<String, dynamic>;
        final total = _intValue(data['totalSessions']);
        final current = _intValue(data['completedSessions']);
        final next = current + delta;

        if (total <= 0) {
          throw StateError('전체 수업 횟수를 먼저 설정해주세요.');
        }
        if (next < 0) {
          throw StateError('진행 횟수는 0회보다 작을 수 없습니다.');
        }
        if (next > total) {
          throw StateError('남은 수업 횟수가 없습니다.');
        }

        final enrollmentUpdate = <String, dynamic>{
          'completedSessions': next,
          'remainingSessions': total - next,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (delta > 0) {
          enrollmentUpdate['lastSessionAt'] = FieldValue.serverTimestamp();
        }
        transaction.update(ref, enrollmentUpdate);

        transaction.set(logRef, {
          'delta': delta,
          'completedAfter': next,
          'totalSessions': total,
          'adminName': adminName,
          'createdAt': FieldValue.serverTimestamp(),
        });

        return SessionUpdateResult(
          completedSessions: next,
          totalSessions: total,
          allCompleted: delta > 0 && next >= total,
        );
      });
      return result;
    } on StateError catch (e) {
      return SessionUpdateResult(error: e.message);
    } catch (e) {
      print('수업 횟수 변경 오류: $e');
      return SessionUpdateResult(error: '수업 횟수 변경에 실패했습니다.');
    }
  }

  /// 특정 수강 배정의 화상수업 처리 이력(최신순).
  static Future<List<SessionLog>> sessionLogs(String enrollmentId) async {
    try {
      final snapshot = await _firestore
          .collection('enrollments')
          .doc(enrollmentId)
          .collection('session_logs')
          .get();

      final logs = snapshot.docs
          .map((doc) => SessionLog.fromMap(doc.id, doc.data()))
          .toList();

      logs.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return logs;
    } catch (e) {
      print('수업 이력 조회 오류: $e');
      return [];
    }
  }

  static Future<String?> deleteEnrollment(String enrollmentId) async {
    try {
      await _firestore.collection('enrollments').doc(enrollmentId).delete();
      return null;
    } catch (e) {
      print('수강 배정 삭제 오류: $e');
      return '수강 배정 삭제에 실패했습니다.';
    }
  }

  static Future<String?> saveMeetingUrl(String courseId, String url) async {
    try {
      await _firestore.collection('online_courses').doc(courseId).set({
        'meetingUrl': url.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return null;
    } catch (e) {
      print('화상수업 링크 저장 오류: $e');
      return '화상수업 링크 저장에 실패했습니다.';
    }
  }

  static Future<String?> addLesson({
    required String courseId,
    required String title,
    String description = '',
    required String videoUrl,
    int order = 0,
  }) async {
    try {
      await _firestore.collection('online_lessons').add({
        'courseId': courseId,
        'title': title.trim(),
        'description': description.trim(),
        'videoUrl': UrlUtil.normalizeVideoUrl(videoUrl),
        'order': order,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      print('강의 추가 오류: $e');
      return '강의 자료 등록에 실패했습니다.';
    }
  }

  static Future<String?> deleteLesson(String lessonId) async {
    try {
      await _firestore.collection('online_lessons').doc(lessonId).delete();
      return null;
    } catch (e) {
      print('강의 삭제 오류: $e');
      return '강의 자료 삭제에 실패했습니다.';
    }
  }

  /// 수강 시작일 기준 현재 주차 (1주차부터).
  static int currentWeekNumber(DateTime? startedAt, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final start = startedAt ?? today;
    final startDay = DateTime(start.year, start.month, start.day);
    final todayDay = DateTime(today.year, today.month, today.day);
    final days = todayDay.difference(startDay).inDays;
    if (days < 0) return 1;
    return (days ~/ 7) + 1;
  }

  static Future<EnrollmentRecord?> myEnrollmentForCourse(String courseId) async {
    final records = await myEnrollments();
    for (final record in records) {
      if (record.courseId == courseId) return record;
    }
    return null;
  }

  static Future<List<OnlineWeek>> weeks(String courseId) async {
    try {
      final snapshot = await _firestore
          .collection('online_weeks')
          .where('courseId', isEqualTo: courseId)
          .get();

      final weeks = snapshot.docs
          .map((doc) => OnlineWeek.fromMap(doc.id, doc.data()))
          .toList();
      if (!weeks.any((week) => week.weekNumber == 1)) {
        weeks.add(defaultWeek1(courseId));
      }
      weeks.sort((a, b) => a.weekNumber.compareTo(b.weekNumber));
      return weeks;
    } catch (e) {
      print('주간 커리큘럼 조회 오류: $e');
      return [defaultWeek1(courseId)];
    }
  }

  static Future<Map<String, List<String>>> weekProgress(
      String enrollmentId) async {
    try {
      final snapshot = await _firestore
          .collection('enrollments')
          .doc(enrollmentId)
          .collection('week_progress')
          .get();

      final Map<String, List<String>> result = {};
      for (final doc in snapshot.docs) {
        final raw = doc.data()['checkedItemIds'];
        if (raw is List) {
          result[doc.id] =
              raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
        } else {
          result[doc.id] = [];
        }
      }
      return result;
    } catch (e) {
      print('주차 진도 조회 오류: $e');
      return {};
    }
  }

  static Future<String?> setWeekChecklist({
    required String enrollmentId,
    required String weekId,
    required List<String> checkedItemIds,
  }) async {
    try {
      await _firestore
          .collection('enrollments')
          .doc(enrollmentId)
          .collection('week_progress')
          .doc(weekId)
          .set({
        'checkedItemIds': checkedItemIds,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return null;
    } catch (e) {
      print('체크리스트 저장 오류: $e');
      return '체크리스트 저장에 실패했습니다.';
    }
  }

  static Map<String, dynamic> _weekPayload({
    required String courseId,
    required int weekNumber,
    required String title,
    String description = '',
    required String videoUrl,
    required List<WeekProblemLink> problemLinks,
    required List<WeekChecklistItem> checklistItems,
  }) {
    return {
      'courseId': courseId,
      'weekNumber': weekNumber,
      'title': title.trim(),
      'description': description.trim(),
      'videoUrl': UrlUtil.normalizeVideoUrl(videoUrl),
      'problemLinks': problemLinks
          .where((e) => e.url.trim().isNotEmpty)
          .map((e) => {
                'title': e.title.trim().isEmpty ? '문제풀이' : e.title.trim(),
                'url': e.url.trim(),
              })
          .toList(),
      'checklistItems': checklistItems
          .where((e) => e.label.trim().isNotEmpty)
          .map((e) => {
                'id': e.id.trim().isEmpty
                    ? 'item_${e.label.hashCode.abs()}'
                    : e.id.trim(),
                'label': e.label.trim(),
              })
          .toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static Future<String?> _weekNumberTaken({
    required String courseId,
    required int weekNumber,
    String? exceptWeekId,
  }) async {
    final existing = await weeks(courseId);
    final taken = existing.any(
        (week) => week.weekNumber == weekNumber && week.id != exceptWeekId);
    if (taken) return '이미 같은 주차 번호가 등록되어 있습니다.';
    return null;
  }

  static Future<String?> addWeek({
    required String courseId,
    required int weekNumber,
    required String title,
    String description = '',
    required String videoUrl,
    List<WeekProblemLink> problemLinks = const [],
    List<WeekChecklistItem> checklistItems = const [],
  }) async {
    if (weekNumber < 1) return '주차 번호는 1 이상이어야 합니다.';
    if (title.trim().isEmpty) return '주차 제목을 입력해주세요.';
    final duplicate = await _weekNumberTaken(
        courseId: courseId, weekNumber: weekNumber);
    if (duplicate != null) return duplicate;

    try {
      final payload = _weekPayload(
        courseId: courseId,
        weekNumber: weekNumber,
        title: title,
        description: description,
        videoUrl: videoUrl,
        problemLinks: problemLinks,
        checklistItems: checklistItems,
      );
      payload['createdAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('online_weeks').add(payload);
      return null;
    } catch (e) {
      print('주차 등록 오류: $e');
      return '주간 학습 등록에 실패했습니다.';
    }
  }

  static Future<String?> updateWeek({
    required String weekId,
    required String courseId,
    required int weekNumber,
    required String title,
    String description = '',
    required String videoUrl,
    List<WeekProblemLink> problemLinks = const [],
    List<WeekChecklistItem> checklistItems = const [],
  }) async {
    if (weekNumber < 1) return '주차 번호는 1 이상이어야 합니다.';
    if (title.trim().isEmpty) return '주차 제목을 입력해주세요.';
    final duplicate = await _weekNumberTaken(
      courseId: courseId,
      weekNumber: weekNumber,
      exceptWeekId: weekId,
    );
    if (duplicate != null) return duplicate;

    try {
      await _firestore.collection('online_weeks').doc(weekId).set(
            _weekPayload(
              courseId: courseId,
              weekNumber: weekNumber,
              title: title,
              description: description,
              videoUrl: videoUrl,
              problemLinks: problemLinks,
              checklistItems: checklistItems,
            ),
            SetOptions(merge: true),
          );
      return null;
    } catch (e) {
      print('주차 수정 오류: $e');
      return '주간 학습 수정에 실패했습니다.';
    }
  }

  static Future<String?> deleteWeek(String weekId) async {
    try {
      await _firestore.collection('online_weeks').doc(weekId).delete();
      return null;
    } catch (e) {
      print('주차 삭제 오류: $e');
      return '주간 학습 삭제에 실패했습니다.';
    }
  }

  static const List<String> bookingTimeSlots = [
    '10:00',
    '11:00',
    '14:00',
    '16:00',
    '19:00',
    '20:00',
    '21:00',
  ];

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static String formatBookingDate(DateTime d) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')} (${weekdays[d.weekday - 1]})';
  }

  /// 해당 주차에서 아직 남은 예약 가능일. 주차가 지났으면 오늘부터 7일을 연다.
  static List<DateTime> remainingBookingDates({
    required DateTime? enrollmentStart,
    required int weekNumber,
    DateTime? now,
  }) {
    final today = dateOnly(now ?? DateTime.now());
    final start = dateOnly(enrollmentStart ?? today)
        .add(Duration(days: (weekNumber - 1) * 7));
    final end = start.add(Duration(days: 6));
    final dates = <DateTime>[];
    for (var d = start; !d.isAfter(end); d = d.add(Duration(days: 1))) {
      if (!d.isBefore(today)) dates.add(d);
    }
    if (dates.isEmpty) {
      for (var i = 0; i < 7; i++) {
        dates.add(today.add(Duration(days: i)));
      }
    }
    return dates;
  }

  static List<String> remainingTimeSlots(DateTime date, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final day = dateOnly(date);
    if (day.isAfter(dateOnly(current))) return List.of(bookingTimeSlots);
    if (day.isBefore(dateOnly(current))) return [];
    final hm =
        '${current.hour.toString().padLeft(2, '0')}:${current.minute.toString().padLeft(2, '0')}';
    return bookingTimeSlots.where((slot) => slot.compareTo(hm) > 0).toList();
  }

  static Future<List<WeekBooking>> myWeekBookings({
    required String courseId,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) return [];
    try {
      final snapshot = await _firestore
          .collection('week_bookings')
          .where('userId', isEqualTo: user.uid)
          .where('courseId', isEqualTo: courseId)
          .get();
      final list = snapshot.docs
          .map((doc) => WeekBooking.fromMap(doc.id, doc.data()))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      print('내 예약 조회 오류: $e');
      return [];
    }
  }

  static Future<List<WeekBooking>> staffWeekBookings() async {
    try {
      QuerySnapshot snapshot;
      if (await AuthService.isAdmin()) {
        snapshot = await _firestore.collection('week_bookings').get();
      } else {
        final uid = AuthService.currentUser?.uid;
        if (uid == null) return [];
        snapshot = await _firestore
            .collection('week_bookings')
            .where('teacherId', isEqualTo: uid)
            .get();
      }
      final list = snapshot.docs
          .map((doc) =>
              WeekBooking.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
      list.sort((a, b) {
        if (a.status == 'pending' && b.status != 'pending') return -1;
        if (a.status != 'pending' && b.status == 'pending') return 1;
        return b.createdAt.compareTo(a.createdAt);
      });
      return list;
    } catch (e) {
      print('예약 목록 조회 오류: $e');
      return [];
    }
  }

  static Future<String?> requestWeekBooking({
    required EnrollmentRecord enrollment,
    required OnlineWeek week,
    required DateTime date,
    required String time,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) return '로그인이 필요합니다.';
    final day = dateOnly(date);
    final allowed = remainingBookingDates(
      enrollmentStart: enrollment.createdAt,
      weekNumber: week.weekNumber,
    );
    if (!allowed.any((d) => d == day)) {
      return '선택할 수 없는 날짜입니다.';
    }
    if (!remainingTimeSlots(day).contains(time)) {
      return '선택할 수 없는 시간입니다.';
    }

    try {
      final existing = await myWeekBookings(courseId: enrollment.courseId);
      final open = existing.where((b) =>
          b.weekId == week.id &&
          (b.status == 'pending' || b.status == 'confirmed'));
      if (open.isNotEmpty) {
        return '이미 이 주차 예약이 있습니다. 강사 확인을 기다려 주세요.';
      }

      final member = await AuthService.currentMemberDoc();
      await _firestore.collection('week_bookings').add({
        'userId': user.uid,
        'memberName': enrollment.memberName.isNotEmpty
            ? enrollment.memberName
            : (member?['name']?.toString() ?? ''),
        'email': enrollment.email,
        'courseId': enrollment.courseId,
        'weekId': week.id,
        'weekNumber': week.weekNumber,
        'weekTitle': week.title,
        'date': Timestamp.fromDate(day),
        'time': time,
        'status': 'pending',
        'teacherId': member?['teacherId']?.toString() ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      print('예약 신청 오류: $e');
      return '예약 신청에 실패했습니다.';
    }
  }

  static Future<String?> confirmWeekBooking(String bookingId) async {
    try {
      final name = AuthService.currentUser?.displayName ??
          AuthService.currentUser?.email ??
          '강사';
      await _firestore.collection('week_bookings').doc(bookingId).update({
        'status': 'confirmed',
        'confirmedAt': FieldValue.serverTimestamp(),
        'confirmedBy': name,
      });
      return null;
    } catch (e) {
      print('예약 확인 오류: $e');
      return '예약 확인에 실패했습니다.';
    }
  }

  static Future<String?> rejectWeekBooking(String bookingId) async {
    try {
      await _firestore.collection('week_bookings').doc(bookingId).update({
        'status': 'rejected',
        'confirmedAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      print('예약 거절 오류: $e');
      return '예약 거절에 실패했습니다.';
    }
  }

  /// 영상 파일을 Storage에 업로드하고 다운로드 URL을 반환한다.
  static Future<String?> uploadLessonVideo({
    required String courseId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    try {
      final safeName = fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
      final path =
          'online_lessons/$courseId/${DateTime.now().millisecondsSinceEpoch}_$safeName';
      final ref = _storage.ref().child(path);
      final metadata =
          SettableMetadata(contentType: _guessContentType(fileName));
      await ref.putData(bytes, metadata);
      return await ref.getDownloadURL();
    } catch (e) {
      print('영상 업로드 오류: $e');
      return null;
    }
  }

  static String _guessContentType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.mp4')) return 'video/mp4';
    if (lower.endsWith('.webm')) return 'video/webm';
    if (lower.endsWith('.mov')) return 'video/quicktime';
    return 'application/octet-stream';
  }

  static int _intValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

/// 화상수업 횟수 증감 처리 결과.
class SessionUpdateResult {
  final String? error;
  final bool allCompleted;
  final int completedSessions;
  final int totalSessions;

  SessionUpdateResult({
    this.error,
    this.allCompleted = false,
    this.completedSessions = 0,
    this.totalSessions = 0,
  });

  bool get success => error == null;
}

/// 화상수업 처리 이력 한 건.
class SessionLog {
  final String id;
  final int delta;
  final int completedAfter;
  final int totalSessions;
  final String adminName;
  final DateTime? createdAt;

  SessionLog({
    required this.id,
    required this.delta,
    required this.completedAfter,
    required this.totalSessions,
    required this.adminName,
    this.createdAt,
  });

  factory SessionLog.fromMap(String id, Map<String, dynamic> data) {
    DateTime? createdAt;
    final createdRaw = data['createdAt'];
    if (createdRaw is Timestamp) createdAt = createdRaw.toDate();

    return SessionLog(
      id: id,
      delta: EnrollmentService._intValue(data['delta']),
      completedAfter: EnrollmentService._intValue(data['completedAfter']),
      totalSessions: EnrollmentService._intValue(data['totalSessions']),
      adminName: data['adminName']?.toString() ?? '',
      createdAt: createdAt,
    );
  }
}

/// 회차별 화상수업 (예: 1회차 화상수업).
class OnlineSession {
  final String id;
  final String courseId;
  final String title;
  final int order;
  final String meetingUrl;
  final bool isLive;
  final String hostName;
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final DateTime? endedAt;

  OnlineSession({
    required this.id,
    required this.courseId,
    required this.title,
    required this.order,
    required this.meetingUrl,
    required this.isLive,
    this.hostName = '',
    this.scheduledAt,
    this.startedAt,
    this.endedAt,
  });

  /// 한 번이라도 진행되고 종료된 회차.
  bool get isFinished => !isLive && endedAt != null;

  /// 종료 버튼을 누르지 않고 창만 닫는 경우를 대비한 자동 만료 시간.
  static const Duration autoExpiry = Duration(hours: 3);

  /// 실제로 지금 입장 가능한 상태인지.
  /// isLive가 true여도 시작 후 [autoExpiry]가 지나면 종료된 것으로 본다.
  bool get isLiveNow {
    if (!isLive) return false;
    final started = startedAt;
    if (started == null) return true;
    return DateTime.now().difference(started) < autoExpiry;
  }

  /// isLive는 true지만 자동 만료 시간이 지난 상태.
  bool get isStale => isLive && !isLiveNow;

  factory OnlineSession.fromMap(String id, Map<String, dynamic> data) {
    DateTime? toDate(dynamic raw) => raw is Timestamp ? raw.toDate() : null;

    return OnlineSession(
      id: id,
      courseId: data['courseId']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      order: EnrollmentService._intValue(data['order']),
      meetingUrl: data['meetingUrl']?.toString() ?? '',
      isLive: data['isLive'] == true,
      hostName: data['hostName']?.toString() ?? '',
      scheduledAt: toDate(data['scheduledAt']),
      startedAt: toDate(data['startedAt']),
      endedAt: toDate(data['endedAt']),
    );
  }
}

class WeekProblemLink {
  final String title;
  final String url;

  const WeekProblemLink({required this.title, required this.url});
}

class WeekChecklistItem {
  final String id;
  final String label;

  const WeekChecklistItem({required this.id, required this.label});
}

class WeekBooking {
  final String id;
  final String userId;
  final String memberName;
  final String email;
  final String courseId;
  final String weekId;
  final int weekNumber;
  final String weekTitle;
  final DateTime date;
  final String time;
  final String status;
  final String teacherId;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final String confirmedBy;

  WeekBooking({
    required this.id,
    required this.userId,
    required this.memberName,
    required this.email,
    required this.courseId,
    required this.weekId,
    required this.weekNumber,
    required this.weekTitle,
    required this.date,
    required this.time,
    required this.status,
    required this.teacherId,
    required this.createdAt,
    this.confirmedAt,
    this.confirmedBy = '',
  });

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';

  String get statusLabel {
    switch (status) {
      case 'confirmed':
        return '강사 확인 완료';
      case 'rejected':
        return '거절됨';
      default:
        return '강사 확인 대기';
    }
  }

  factory WeekBooking.fromMap(String id, Map<String, dynamic> data) {
    DateTime toDate(dynamic raw) {
      if (raw is Timestamp) return EnrollmentService.dateOnly(raw.toDate());
      return EnrollmentService.dateOnly(DateTime.now());
    }

    DateTime? toDateTime(dynamic raw) =>
        raw is Timestamp ? raw.toDate() : null;

    return WeekBooking(
      id: id,
      userId: data['userId']?.toString() ?? '',
      memberName: data['memberName']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      courseId: data['courseId']?.toString() ?? '',
      weekId: data['weekId']?.toString() ?? '',
      weekNumber: EnrollmentService._intValue(data['weekNumber']),
      weekTitle: data['weekTitle']?.toString() ?? '',
      date: toDate(data['date']),
      time: data['time']?.toString() ?? '',
      status: data['status']?.toString() ?? 'pending',
      teacherId: data['teacherId']?.toString() ?? '',
      createdAt: toDateTime(data['createdAt']) ?? DateTime.now(),
      confirmedAt: toDateTime(data['confirmedAt']),
      confirmedBy: data['confirmedBy']?.toString() ?? '',
    );
  }
}

class OnlineWeek {
  final String id;
  final String courseId;
  final int weekNumber;
  final String title;
  final String description;
  final String videoUrl;
  final List<WeekProblemLink> problemLinks;
  final List<WeekChecklistItem> checklistItems;

  OnlineWeek({
    required this.id,
    required this.courseId,
    required this.weekNumber,
    required this.title,
    required this.description,
    required this.videoUrl,
    this.problemLinks = const [],
    this.checklistItems = const [],
  });

  int checkedCount(List<String> checkedIds) {
    if (checklistItems.isEmpty) return 0;
    return checklistItems.where((item) => checkedIds.contains(item.id)).length;
  }

  factory OnlineWeek.fromMap(String id, Map<String, dynamic> data) {
    final links = <WeekProblemLink>[];
    final rawLinks = data['problemLinks'];
    if (rawLinks is List) {
      for (final item in rawLinks) {
        if (item is Map) {
          final url = item['url']?.toString() ?? '';
          if (url.isEmpty) continue;
          links.add(WeekProblemLink(
            title: item['title']?.toString() ?? '문제풀이',
            url: url,
          ));
        }
      }
    }

    final checks = <WeekChecklistItem>[];
    final rawChecks = data['checklistItems'];
    if (rawChecks is List) {
      for (var i = 0; i < rawChecks.length; i++) {
        final item = rawChecks[i];
        if (item is Map) {
          final label = item['label']?.toString() ?? '';
          if (label.isEmpty) continue;
          final itemId = item['id']?.toString().trim();
          checks.add(WeekChecklistItem(
            id: (itemId == null || itemId.isEmpty) ? 'item_$i' : itemId,
            label: label,
          ));
        } else if (item != null) {
          checks.add(WeekChecklistItem(id: 'item_$i', label: item.toString()));
        }
      }
    }

    return OnlineWeek(
      id: id,
      courseId: data['courseId']?.toString() ?? '',
      weekNumber: EnrollmentService._intValue(data['weekNumber']),
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      videoUrl: UrlUtil.normalizeVideoUrl(data['videoUrl']?.toString() ?? ''),
      problemLinks: links,
      checklistItems: checks,
    );
  }
}

class OnlineLesson {
  final String id;
  final String title;
  final String description;
  final String videoUrl;
  final int order;

  OnlineLesson({
    required this.id,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.order,
  });

  factory OnlineLesson.fromMap(String id, Map<String, dynamic> data) {
    return OnlineLesson(
      id: id,
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      videoUrl: data['videoUrl']?.toString() ?? '',
      order: (data['order'] is int) ? data['order'] as int : 0,
    );
  }
}

class EnrollmentRecord {
  final String id;
  final String userId;
  final String email;
  final String memberName;
  final String courseId;
  final bool isActive;
  final int totalSessions;
  final int completedSessions;
  final int remainingSessions;
  final bool isPaid;
  final int paidAmount;
  final String paymentNote;
  final DateTime? paidAt;
  final DateTime? expiresAt;
  final DateTime? createdAt;
  final DateTime? lastSessionAt;

  EnrollmentRecord({
    required this.id,
    required this.userId,
    required this.email,
    required this.memberName,
    required this.courseId,
    required this.isActive,
    required this.totalSessions,
    required this.completedSessions,
    required this.remainingSessions,
    this.isPaid = false,
    this.paidAmount = 0,
    this.paymentNote = '',
    this.paidAt,
    this.expiresAt,
    this.createdAt,
    this.lastSessionAt,
  });

  OnlineCourse? get course => OnlineCourse.findById(courseId);

  factory EnrollmentRecord.fromMap(String id, Map<String, dynamic> data) {
    DateTime? expiresAt;
    final expiresRaw = data['expiresAt'];
    if (expiresRaw is Timestamp) expiresAt = expiresRaw.toDate();

    DateTime? createdAt;
    final createdRaw = data['createdAt'];
    if (createdRaw is Timestamp) createdAt = createdRaw.toDate();

    DateTime? lastSessionAt;
    final lastRaw = data['lastSessionAt'];
    if (lastRaw is Timestamp) lastSessionAt = lastRaw.toDate();

    DateTime? paidAt;
    final paidRaw = data['paidAt'];
    if (paidRaw is Timestamp) paidAt = paidRaw.toDate();

    return EnrollmentRecord(
      id: id,
      userId: data['userId']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      memberName: data['memberName']?.toString() ?? '',
      courseId: data['courseId']?.toString() ?? '',
      isActive: data['isActive'] != false,
      totalSessions: EnrollmentService._intValue(data['totalSessions']),
      completedSessions: EnrollmentService._intValue(data['completedSessions']),
      remainingSessions: data.containsKey('remainingSessions')
          ? EnrollmentService._intValue(data['remainingSessions'])
          : (EnrollmentService._intValue(data['totalSessions']) -
                  EnrollmentService._intValue(data['completedSessions']))
              .clamp(0, 1 << 31)
              .toInt(),
      isPaid: data['isPaid'] == true,
      paidAmount: EnrollmentService._intValue(data['paidAmount']),
      paymentNote: data['paymentNote']?.toString() ?? '',
      paidAt: paidAt,
      expiresAt: expiresAt,
      createdAt: createdAt,
      lastSessionAt: lastSessionAt,
    );
  }
}
