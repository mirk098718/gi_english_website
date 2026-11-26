import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/EnrollmentService.dart';
import 'package:gi_english_website/util/NoticeImages.dart';
import 'package:gi_english_website/util/NotificationService.dart';
import 'package:gi_english_website/util/notice_image_prepare_stub.dart'
    if (dart.library.html) 'package:gi_english_website/util/notice_image_prepare_web.dart';

class LessonMaterial {
  final String id;
  final String enrollmentId;
  final String weekId;
  final int weekNumber;
  final String bookingId;
  final String userId;
  final String teacherId;
  final String fileName;
  final String mimeType;
  final DateTime createdAt;

  const LessonMaterial({
    required this.id,
    required this.enrollmentId,
    required this.weekId,
    required this.weekNumber,
    required this.bookingId,
    required this.userId,
    required this.teacherId,
    required this.fileName,
    required this.mimeType,
    required this.createdAt,
  });

  bool get isImage => mimeType.startsWith('image/');
  bool get isPdf => mimeType == 'application/pdf';

  String get ref => LessonMaterialService.refFor(enrollmentId, id);
}

class LessonMaterialService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'lesson_materials';
  static const String refPrefix = 'teacher-material:';
  static const int maxFilesPerWeek = 6;
  // Firestore 문서 1MiB 한도. base64·필드 여유를 두고 PDF는 700KB까지.
  static const int maxPdfBytes = 700 * 1024;

  static String refFor(String enrollmentId, String materialId) =>
      '$refPrefix$enrollmentId/$materialId';

  static ({String enrollmentId, String materialId})? parseRef(String ref) {
    if (!ref.startsWith(refPrefix)) return null;
    final rest = ref.substring(refPrefix.length);
    final slash = rest.indexOf('/');
    if (slash <= 0 || slash >= rest.length - 1) return null;
    return (
      enrollmentId: rest.substring(0, slash),
      materialId: rest.substring(slash + 1),
    );
  }

  static Future<List<LessonMaterial>> listForEnrollment(
    String enrollmentId,
  ) async {
    if (enrollmentId.isEmpty) return [];
    try {
      // 수강생 규칙은 userId 기준이라 enrollmentId만으로 조회하면 permission-denied 가 난다.
      final uid = AuthService.currentUser?.uid ?? '';
      final staff = await AuthService.isStaff();
      final QuerySnapshot<Map<String, dynamic>> snapshot;
      if (!staff && uid.isNotEmpty) {
        snapshot = await _firestore
            .collection(_collection)
            .where('userId', isEqualTo: uid)
            .get();
      } else {
        snapshot = await _firestore
            .collection(_collection)
            .where('enrollmentId', isEqualTo: enrollmentId)
            .get();
      }
      final list = snapshot.docs
          .map((doc) => _fromDoc(doc.id, doc.data()))
          .where((item) => item.enrollmentId == enrollmentId)
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      print('회차 자료 조회 오류: $e');
      return [];
    }
  }

  static Future<Map<String, List<LessonMaterial>>> byWeekForEnrollment(
    String enrollmentId,
  ) async {
    final list = await listForEnrollment(enrollmentId);
    final out = <String, List<LessonMaterial>>{};
    for (final item in list) {
      final key = item.weekId.isNotEmpty ? item.weekId : 'week_${item.weekNumber}';
      out.putIfAbsent(key, () => []).add(item);
    }
    return out;
  }

  static Future<List<LessonMaterial>> listForTeacher(String teacherId) async {
    if (teacherId.isEmpty) return [];
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('teacherId', isEqualTo: teacherId)
          .get();
      return snapshot.docs.map((doc) => _fromDoc(doc.id, doc.data())).toList();
    } catch (e) {
      print('강사 회차 자료 조회 오류: $e');
      return [];
    }
  }

  static LessonMaterial _fromDoc(String id, Map<String, dynamic> data) {
    DateTime createdAt = DateTime.now();
    final raw = data['createdAt'];
    if (raw is Timestamp) createdAt = raw.toDate();
    return LessonMaterial(
      id: id,
      enrollmentId: data['enrollmentId']?.toString() ?? '',
      weekId: data['weekId']?.toString() ?? '',
      weekNumber: _int(data['weekNumber']),
      bookingId: data['bookingId']?.toString() ?? '',
      userId: data['userId']?.toString() ?? '',
      teacherId: data['teacherId']?.toString() ?? '',
      fileName: data['fileName']?.toString() ?? '',
      mimeType: data['mimeType']?.toString() ?? '',
      createdAt: createdAt,
    );
  }

  static int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String? _extensionOf(String fileName) {
    final name = fileName.trim().toLowerCase();
    final dot = name.lastIndexOf('.');
    if (dot < 0) return null;
    return name.substring(dot + 1);
  }

  static String? _validateFile(String fileName, Uint8List bytes) {
    final ext = _extensionOf(fileName) ?? '';
    const imageExt = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    if (imageExt.contains(ext)) {
      final reason = NoticeImages.rejectionReason(
        fileName: fileName,
        byteLength: bytes.length,
      );
      return reason;
    }
    if (ext == 'pdf') {
      if (bytes.isEmpty) return '파일이 비어 있습니다.';
      if (bytes.length > maxPdfBytes) {
        return 'PDF는 700KB 이하만 보낼 수 있습니다.';
      }
      return null;
    }
    return 'jpg, png, gif, webp, pdf만 보낼 수 있습니다.';
  }

  static Future<({String mimeType, Uint8List bytes})?> _prepareBytes(
    Uint8List bytes,
    String fileName,
  ) async {
    final ext = _extensionOf(fileName) ?? '';
    if (ext == 'pdf') {
      return (mimeType: 'application/pdf', bytes: bytes);
    }
    try {
      final prepared = await prepareNoticeImage(bytes, fileName);
      return (mimeType: prepared.mimeType, bytes: prepared.bytes);
    } catch (e) {
      return null;
    }
  }

  static Future<String?> upload({
    required EnrollmentRecord enrollment,
    required String weekId,
    required int weekNumber,
    required String bookingId,
    required String teacherId,
    required Uint8List bytes,
    required String fileName,
    required List<LessonMaterial> currentForWeek,
    String teacherName = '',
    String courseTitle = '',
  }) async {
    if (teacherId.isEmpty) return '강사 정보가 없습니다.';
    final reason = _validateFile(fileName, bytes);
    if (reason != null) return reason;
    if (currentForWeek.length >= maxFilesPerWeek) {
      return '회차마다 파일은 $maxFilesPerWeek개까지 보낼 수 있습니다.';
    }
    final prepared = await _prepareBytes(bytes, fileName);
    if (prepared == null) {
      return '파일을 처리하지 못했습니다.';
    }
    if (prepared.bytes.length > NoticeImages.maxStoredBytes &&
        prepared.mimeType != 'application/pdf') {
      return '이미지가 너무 큽니다. 더 작은 파일로 올려 주세요.';
    }
    if (prepared.mimeType == 'application/pdf' &&
        prepared.bytes.length > maxPdfBytes) {
      return 'PDF가 너무 큽니다.';
    }
    final dataUrl =
        'data:${prepared.mimeType};base64,${base64Encode(prepared.bytes)}';
    try {
      final doc = _firestore.collection(_collection).doc();
      await doc.set({
        'enrollmentId': enrollment.id,
        'weekId': weekId,
        'weekNumber': weekNumber,
        'bookingId': bookingId,
        'userId': enrollment.userId,
        'teacherId': teacherId,
        'fileName': fileName.trim().isEmpty ? 'file' : fileName.trim(),
        'mimeType': prepared.mimeType,
        'dataUrl': dataUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });
      final weekLabel =
          weekNumber > 0 ? '$weekNumber회차' : '화상수업';
      final who = teacherName.trim().isNotEmpty ? teacherName.trim() : '강사';
      await NotificationService.notifyUser(
        userId: enrollment.userId,
        title: '강사 자료',
        body: courseTitle.isNotEmpty
            ? '$who · $courseTitle $weekLabel에 자료가 도착했습니다.'
            : '$who · $weekLabel에 자료가 도착했습니다.',
        type: 'lesson_material',
        bookingId: bookingId,
        senderId: teacherId,
      );
      return null;
    } catch (e) {
      print('회차 자료 업로드 오류: $e');
      return '파일을 보내지 못했습니다.';
    }
  }

  static Future<String?> remove({
    required String materialId,
    required String teacherId,
  }) async {
    if (materialId.isEmpty) return null;
    try {
      final ref = _firestore.collection(_collection).doc(materialId);
      final snap = await ref.get();
      if (!snap.exists) return null;
      final data = snap.data() ?? {};
      final docTeacher = data['teacherId']?.toString() ?? '';
      final isOwner = await AuthService.isAdmin();
      if (!isOwner && docTeacher != teacherId) {
        return '이 파일을 지울 수 없습니다.';
      }
      await ref.delete();
      return null;
    } catch (e) {
      print('회차 자료 삭제 오류: $e');
      return '파일을 지우지 못했습니다.';
    }
  }

  static final Map<String, Uint8List> _cache = {};

  static Future<Uint8List?> bytesForRef(String ref) async {
    final cached = _cache[ref];
    if (cached != null) return cached;
    final parsed = parseRef(ref);
    if (parsed == null) return null;
    try {
      final doc = await _firestore
          .collection(_collection)
          .doc(parsed.materialId)
          .get();
      final dataUrl = doc.data()?['dataUrl']?.toString() ?? '';
      final bytes = _decodeDataUrl(dataUrl);
      if (bytes != null) _cache[ref] = bytes;
      return bytes;
    } catch (e) {
      print('회차 자료 읽기 오류: $e');
      return null;
    }
  }

  static Future<String?> mimeForRef(String ref) async {
    final parsed = parseRef(ref);
    if (parsed == null) return null;
    try {
      final doc = await _firestore
          .collection(_collection)
          .doc(parsed.materialId)
          .get();
      return doc.data()?['mimeType']?.toString();
    } catch (_) {
      return null;
    }
  }

  static Uint8List? _decodeDataUrl(String dataUrl) {
    final comma = dataUrl.indexOf(',');
    if (comma < 0 || !dataUrl.startsWith('data:')) return null;
    try {
      return base64Decode(dataUrl.substring(comma + 1));
    } catch (_) {
      return null;
    }
  }
}