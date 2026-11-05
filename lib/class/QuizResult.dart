/// 학생이 연습문제를 끝까지 채점한 최근 결과.
///
/// 같은 퀴즈를 다시 풀면 이전 점수와 주관식 답을 지우고 이번 풀이만 남긴다.
class QuizResult {
  final String id;
  final String userId;
  final String quizId;
  final String title;
  final String courseId;
  final int weekNumber;
  final int correctCount;
  final int totalCount;
  final List<QuizEssayAnswer> essays;
  final DateTime? updatedAt;

  const QuizResult({
    required this.id,
    required this.userId,
    required this.quizId,
    required this.title,
    required this.courseId,
    required this.weekNumber,
    required this.correctCount,
    required this.totalCount,
    required this.essays,
    required this.updatedAt,
  });

  /// 맞은 개수를 전체 문제 수 기준 퍼센트로 반올림한다.
  int get percent => percentFor(correctCount, totalCount);

  String get scoreLabel => '$correctCount / $totalCount문제 · $percent%';

  static int percentFor(int correct, int total) {
    if (total <= 0) return 0;
    return ((correct * 100) / total).round();
  }

  String get savedAtLabel {
    final time = updatedAt?.toLocal();
    if (time == null) return '';
    final month = time.month.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '${time.year}.$month.$day $hour:$minute';
  }

  bool isNewerThan(QuizResult other) {
    final mine = updatedAt;
    final theirs = other.updatedAt;
    if (mine == null) return false;
    if (theirs == null) return true;
    return mine.isAfter(theirs);
  }

  /// 퀴즈 주소에서 저장 키를 뽑는다. 주소가 퀴즈가 아니면 빈 문자열.
  static String quizIdFromUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return '';
    final path = trimmed.split('?').first.split('#').first;
    final name = path.split('/').where((part) => part.isNotEmpty).last;
    const suffix = '-quiz.html';
    if (!name.endsWith(suffix)) return '';
    final id = name.substring(0, name.length - suffix.length);
    if (!RegExp(r'^[a-z0-9-]{3,64}$').hasMatch(id)) return '';
    return id;
  }

  static String documentId(String userId, String quizId) => '${userId}_$quizId';

  /// 같은 퀴즈가 여러 번 있으면 더 최근 시각의 결과만 남긴다.
  static Map<String, QuizResult> keepLatest(Iterable<QuizResult> items) {
    final map = <String, QuizResult>{};
    for (final item in items) {
      if (item.quizId.isEmpty) continue;
      final previous = map[item.quizId];
      if (previous == null || item.isNewerThan(previous)) {
        map[item.quizId] = item;
      }
    }
    return map;
  }

  factory QuizResult.fromMap(String id, Map<String, dynamic> data) {
    final essays = <QuizEssayAnswer>[];
    final rawEssays = data['essays'];
    if (rawEssays is List) {
      for (final item in rawEssays) {
        if (item is Map) {
          essays.add(QuizEssayAnswer.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }
    final total = _intValue(data['totalCount']);
    return QuizResult(
      id: id,
      userId: data['userId']?.toString() ?? '',
      quizId: data['quizId']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      courseId: data['courseId']?.toString() ?? '',
      weekNumber: _intValue(data['weekNumber']),
      correctCount: _intValue(data['correctCount']),
      totalCount: total < 1 ? 25 : total,
      essays: essays,
      updatedAt: _time(data['updatedAt']),
    );
  }

  static int _intValue(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  static DateTime? _time(dynamic raw) {
    if (raw is DateTime) return raw;
    if (raw == null) return null;
    try {
      final value = (raw as dynamic).toDate();
      if (value is DateTime) return value;
    } catch (_) {}
    return null;
  }
}

class QuizEssayAnswer {
  final int index;
  final String title;
  final String prompt;
  final String answer;

  const QuizEssayAnswer({
    required this.index,
    required this.title,
    required this.prompt,
    required this.answer,
  });

  bool get hasAnswer => answer.trim().isNotEmpty;

  factory QuizEssayAnswer.fromMap(Map<String, dynamic> data) {
    return QuizEssayAnswer(
      index: QuizResult._intValue(data['index']),
      title: data['title']?.toString() ?? '',
      prompt: data['prompt']?.toString() ?? '',
      answer: data['answer']?.toString() ?? '',
    );
  }
}

/// 한 학생의 퀴즈 조회 결과. 권한이 없으면 점수 없음과 구분한다.
class QuizResultLookup {
  final Map<String, QuizResult> results;
  final bool unavailable;

  const QuizResultLookup({
    required this.results,
    required this.unavailable,
  });

  static const empty = QuizResultLookup(results: {}, unavailable: false);
}
