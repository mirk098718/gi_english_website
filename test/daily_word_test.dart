import 'package:flutter_test/flutter_test.dart';
import 'package:gi_english_website/util/DailyWord.dart';
import 'package:gi_english_website/util/DailyWordLookup.dart';

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

  test('위키낱말사전 항목에서 뜻과 예문을 고른다', () {
    final word = DailyWordLookup.parseWiktionaryEntry({
      'word': 'ready',
      'source': {
        'url': 'https://en.wiktionary.org/wiki/ready',
        'license': {'name': 'CC BY-SA 4.0'},
      },
      'entries': [
        {
          'partOfSpeech': 'adjective',
          'senses': [
            {
              'definition': 'Prepared for immediate action or use.',
              'examples': ['The troops are ready for battle.'],
              'translations': [
                {
                  'language': {'code': 'ko', 'name': 'Korean'},
                  'word': '준비된',
                },
              ],
            },
          ],
        },
      ],
    });

    expect(word, isNotNull);
    expect(word!.word, 'ready');
    expect(word.meaning, '준비된');
    expect(word.expression, 'The troops are ready for battle.');
    expect(word.sourceUrl, 'https://en.wiktionary.org/wiki/ready');
  });

  test('한국어 뜻이 있는 뜻풀이의 예문을 고른다', () {
    final word = DailyWordLookup.parseWiktionaryEntry({
      'word': 'still',
      'source': {'url': 'https://en.wiktionary.org/wiki/still'},
      'entries': [
        {
          'senses': [
            {
              'definition': 'Not moving; calm.',
              'examples': ['Sit there and stay still!'],
              'translations': [],
            },
            {
              'definition': 'Up to a time, as in the preceding time.',
              'examples': ['Is it still raining?'],
              'translations': [
                {
                  'language': {'code': 'ko', 'name': 'Korean'},
                  'word': '여전히',
                },
              ],
            },
          ],
        },
      ],
    });

    expect(word!.meaning, '여전히');
    expect(word.expression, 'Is it still raining?');
  });

  test('예문이 없으면 그 단어는 건너뛴다', () {
    final word = DailyWordLookup.parseWiktionaryEntry({
      'word': 'quiet',
      'entries': [
        {
          'senses': [
            {'definition': 'Making little noise.', 'examples': []},
          ],
        },
      ],
    });

    expect(word, isNull);
  });
}
