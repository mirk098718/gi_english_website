import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gi_english_website/util/AuthService.dart';

/// 담당 강사가 학생마다 남기는 간단 메모.
class TeacherStudentNoteService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'teacher_student_notes';

  static String docId(String teacherId, String studentId) =>
      '${teacherId}_$studentId';

  static Future<Map<String, String>> notesForTeacher(String teacherId) async {
    if (teacherId.isEmpty) return {};
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('teacherId', isEqualTo: teacherId)
          .get();
      final out = <String, String>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final studentId = data['studentId']?.toString() ?? '';
        if (studentId.isEmpty) continue;
        out[studentId] = data['note']?.toString() ?? '';
      }
      return out;
    } catch (e) {
      print('강사 학생 메모 조회 오류: $e');
      return {};
    }
  }

  static Future<String?> save({
    required String teacherId,
    required String studentId,
    required String note,
  }) async {
    if (teacherId.isEmpty || studentId.isEmpty) {
      return '강사와 학생 정보가 없습니다.';
    }
    final trimmed = note.trim();
    try {
      await _firestore.collection(_collection).doc(docId(teacherId, studentId)).set({
        'teacherId': teacherId,
        'studentId': studentId,
        'note': trimmed,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': AuthService.currentUser?.uid ?? teacherId,
      }, SetOptions(merge: true));
      return null;
    } catch (e) {
      print('강사 학생 메모 저장 오류: $e');
      return '간단 메모를 저장하지 못했습니다.';
    }
  }
}