import 'dart:async';

import 'package:gi_english_website/util/quiz_result_bridge_stub.dart'
    if (dart.library.html) 'package:gi_english_website/util/quiz_result_bridge_web.dart'
    as impl;

/// 문제풀이 페이지의 완료 저장이 끝나면 강의실이 다시 읽도록 알린다.
class QuizResultEvents {
  static final StreamController<void> _saved =
      StreamController<void>.broadcast();

  static Stream<void> get saved => _saved.stream;

  static void notifySaved() {
    if (!_saved.isClosed) _saved.add(null);
  }
}

/// 문제풀이 탭이 로그인한 사이트 탭에 점수와 주관식을 넘기면 저장한다.
void startQuizResultBridge() {
  impl.startQuizResultBridge(QuizResultEvents.notifySaved);
}
