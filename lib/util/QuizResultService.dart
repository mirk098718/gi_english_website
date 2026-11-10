import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gi_english_website/class/QuizResult.dart';

/// 연습문제 최근 결과를 `quiz_results/{userId}_{quizId}`에서 읽는다.
///
/// 문서는 퀴즈마다 하나다. 학생이 다시 풀면 그 문서를 통째로 덮어쓴다.
class QuizResultService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<QuizResultLookup> fetchForUser({
    required String userId,
    required Iterable<String> quizIds,
  }) async {
    final ids = quizIds.where((id) => id.trim().isNotEmpty).toSet();
    if (userId.isEmpty || ids.isEmpty) return QuizResultLookup.empty;

    var unavailable = false;
    final loaded = <QuizResult>[];
    await Future.wait(ids.map((quizId) async {
      try {
        final snap = await _firestore
            .collection('quiz_results')
            .doc(QuizResult.documentId(userId, quizId))
            .get();
        final data = snap.data();
        if (!snap.exists || data == null) return;
        loaded.add(QuizResult.fromMap(snap.id, data));
      } on FirebaseException catch (error) {
        if (error.code == 'permission-denied') unavailable = true;
      } catch (_) {}
    }));

    return QuizResultLookup(
      results: QuizResult.keepLatest(loaded),
      unavailable: unavailable && loaded.isEmpty,
    );
  }
}
