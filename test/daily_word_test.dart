import 'package:flutter_test/flutter_test.dart';
import 'package:gi_english_website/util/DailyWord.dart';

void main() {
  test('같은 날짜에는 같은 단어와 표현을 보여 준다', () {
    final morning = DateTime(2026, 11, 5, 8, 0);
    final evening = DateTime(2026, 11, 5, 23, 40);
    final first = DailyWord.forDate(morning);
    final second = DailyWord.forDate(evening);

    expect(second.word, first.word);
    expect(second.expression, first.expression);
    expect(first.expression.toLowerCase(), contains(first.word.toLowerCase()));
  });

  test('다음 날에는 다른 단어를 보여 준다', () {
    final today = DailyWord.forDate(DateTime(2026, 11, 5));
    final tomorrow = DailyWord.forDate(DateTime(2026, 11, 6));

    expect(tomorrow.word, isNot(today.word));
  });

  test('목록을 한 바퀴 돌면 같은 단어로 돌아온다', () {
    final start = DailyWord.forDate(DateTime(2026, 1, 1));
    final wrapped = DailyWord.forDate(
      DateTime(2026, 1, 1).add(Duration(days: DailyWord.words.length)),
    );

    expect(wrapped.word, start.word);
    expect(wrapped.expression, start.expression);
  });
}
