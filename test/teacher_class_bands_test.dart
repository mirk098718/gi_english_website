import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gi_english_website/class/TeacherClassBands.dart';
import 'package:gi_english_website/widget/TeacherClassTimeLine.dart';

void main() {
  TeacherClassBands bands(List<int> days, List<String> periods) {
    return TeacherClassBands(days: days.toSet(), periods: periods.toSet());
  }

  test('요일이나 시간대가 없으면 시간표를 줄이지 않는다', () {
    expect(TeacherClassBands.empty.active, isFalse);
    expect(TeacherClassBands.empty.allows(1, '15:00'), isTrue);
    expect(bands([1], []).keywords, isEmpty);
    expect(bands([], [TeacherClassBands.pm]).keywords, isEmpty);
  });

  test('평일 오후와 주말 오전, 하루만인 일요일을 키워드로 줄인다', () {
    expect(
      bands([1, 2, 3, 4, 5], [TeacherClassBands.pm]).keywords,
      ['평일 오후'],
    );
    expect(
      bands([6, 7], [TeacherClassBands.am]).keywords,
      ['주말 오전'],
    );
    expect(
      bands([7], [TeacherClassBands.am]).keywords,
      ['일요일 오전'],
    );
    expect(
      bands([1, 3, 5], [TeacherClassBands.am]).keywords,
      ['월수금 오전'],
    );
    expect(
      bands([3], [TeacherClassBands.am]).keywords,
      ['수요일 오전'],
    );
  });

  test('고른 요일과 오전·오후의 교집합만 열린다', () {
    final window = bands(
      [1, 2, 3, 4, 5, 7],
      [TeacherClassBands.am, TeacherClassBands.pm],
    );
    expect(window.keywords, [
      '평일 오전',
      '일요일 오전',
      '평일 오후',
      '일요일 오후',
    ]);
    expect(window.allows(1, '09:30'), isTrue);
    expect(window.allows(1, '12:00'), isTrue);
    expect(window.allows(6, '09:30'), isFalse);
    expect(window.allows(7, '11:30'), isTrue);
    expect(TeacherClassBands.periodOf('11:30'), TeacherClassBands.am);
    expect(TeacherClassBands.periodOf('12:00'), TeacherClassBands.pm);
  });

  testWidgets('강사 카드에 Class Time 키워드가 소개 아래에 붙는다', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TeacherClassTimeLine(
          bands: TeacherClassBands(
            days: {1, 2, 3, 4, 5, 7},
            periods: {TeacherClassBands.pm, TeacherClassBands.am},
          ),
        ),
      ),
    ));
    expect(find.textContaining('Class Time :'), findsOneWidget);
    expect(find.textContaining('평일 오후'), findsOneWidget);
    expect(find.textContaining('일요일 오전'), findsOneWidget);
  });
}
