import 'package:flutter_test/flutter_test.dart';
import 'package:gi_english_website/class/JuniorLevel.dart';
import 'package:gi_english_website/class/JuniorLevelTest.dart';

void main() {
  test('맞은 개수가 초등·중등 모두 레벨 1부터 6으로 나뉜다', () {
    expect(JuniorLevelTest.levelForScore(0), 1);
    expect(JuniorLevelTest.levelForScore(1), 1);
    expect(JuniorLevelTest.levelForScore(2), 2);
    expect(JuniorLevelTest.levelForScore(5), 3);
    expect(JuniorLevelTest.levelForScore(7), 4);
    expect(JuniorLevelTest.levelForScore(9), 5);
    expect(JuniorLevelTest.levelForScore(10), 6);
    expect(JuniorLevelTest.levelForScore(12), 6);
  });

  test('전부 맞히면 레벨 6이고 틀리면 그 아래다', () {
    final elementary = JuniorLevelTest.elementary;
    final allRight = [
      for (final question in elementary) question.correctIndex,
    ];
    expect(
      JuniorLevelTest.result(JuniorLevel.elementary, allRight).label,
      '초등부 레벨 6',
    );

    final none = List<int?>.filled(JuniorLevelTest.middle.length, 0);
    for (var i = 0; i < none.length; i++) {
      if (JuniorLevelTest.middle[i].correctIndex == 0) none[i] = 1;
    }
    expect(
      JuniorLevelTest.result(JuniorLevel.middle, none).level,
      1,
    );
  });

  test('회원 정보에서 1~6 레벨만 읽는다', () {
    expect(
      JuniorLevel.fromMap({
        'juniorLevel': 4,
        'juniorLevelBand': 'middle',
      })?.label,
      '중등부 레벨 4',
    );
    expect(
      JuniorLevel.fromMap({'juniorLevel': 7, 'juniorLevelBand': 'elementary'}),
      isNull,
    );
  });
}
