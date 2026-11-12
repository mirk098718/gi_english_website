import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gi_english_website/class/TeacherClassBands.dart';
import 'package:gi_english_website/util/TeacherScheduleService.dart';
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
      '평일 오전, 오후',
      '일요일 오전, 오후',
    ]);
    expect(window.allows(1, '09:30'), isTrue);
    expect(window.allows(1, '12:00'), isTrue);
    expect(window.allows(6, '09:30'), isFalse);
    expect(window.allows(7, '11:30'), isTrue);
    expect(TeacherClassBands.periodOf('11:30'), TeacherClassBands.am);
    expect(TeacherClassBands.periodOf('12:00'), TeacherClassBands.pm);
  });

  Set<String> closedExcept(int weekday, List<String> open) {
    final keep = open.toSet();
    return TeacherClassBands.timeSlots
        .where((time) => !keep.contains(time))
        .map((time) => '${weekday}_$time')
        .toSet();
  }

  test('연속 3시간 이하는 아침 점심 저녁으로 줄어든다', () {
    final monday = bands([1], [TeacherClassBands.am, TeacherClassBands.pm]);
    expect(
      monday.keywordsFor(closedExcept(1, ['06:00', '06:30', '07:00', '07:30', '08:00', '08:30'])),
      ['월요일 아침'],
    );
    expect(
      monday.keywordsFor(closedExcept(1, ['12:00', '12:30', '13:00', '13:30'])),
      ['월요일 점심'],
    );
    expect(
      monday.keywordsFor(closedExcept(1, ['19:00', '19:30', '20:00', '20:30'])),
      ['월요일 저녁'],
    );
    expect(
      bands([1, 2], [TeacherClassBands.pm]).keywordsFor(
        {
          ...closedExcept(1, ['18:00', '18:30', '19:00', '19:30', '20:00', '20:30']),
          ...closedExcept(2, ['18:00', '18:30', '19:00', '19:30', '20:00', '20:30']),
        },
      ),
      ['월화 저녁'],
    );
  });

  test('같은 요일에 오전과 오후가 같이 열린다', () {
    final both = bands([1, 2], [TeacherClassBands.am, TeacherClassBands.pm]);
    expect(both.keywords, ['월화 오전, 오후']);
    final morningAndEvening = closedExcept(1, [
      '06:00', '06:30', '07:00', '07:30', '08:00', '08:30',
      '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
      '19:00', '19:30', '20:00',
    ]);
    expect(
      bands([1], [TeacherClassBands.am, TeacherClassBands.pm])
          .keywordsFor(morningAndEvening),
      ['월요일 오전, 저녁'],
    );
  });

  test('주말 오전 안에서 이른 시간과 늦은 오전을 닫으면 주말 아침만 남는다', () {
    final weekendMorning = bands([6, 7], [TeacherClassBands.am]);
    final closed = <String>{
      '6_06:00',
      '6_06:30',
      '6_07:00',
      '6_07:30',
      '6_10:30',
      '6_11:00',
      '6_11:30',
      '7_06:00',
      '7_06:30',
      '7_07:00',
      '7_07:30',
      '7_09:00',
      '7_09:30',
      '7_10:00',
      '7_10:30',
      '7_11:00',
      '7_11:30',
    };
    expect(weekendMorning.keywordsFor(closed), ['주말 아침']);

    final availability = TeacherAvailability(
      teacherUid: 'teacher',
      routineKeys: closed,
      classBands: weekendMorning,
    );
    final saturday = DateTime(2026, 11, 14);
    final sunday = DateTime(2026, 11, 15);
    final monday = DateTime(2026, 11, 16);
    expect(
      availability.openTimes(saturday, TeacherClassBands.timeSlots),
      ['08:00', '08:30', '09:00', '09:30', '10:00'],
    );
    expect(
      availability.openTimes(sunday, TeacherClassBands.timeSlots),
      ['08:00', '08:30'],
    );
    expect(availability.openTimes(monday, TeacherClassBands.timeSlots), isEmpty);
  });

  testWidgets('강사 카드에 주말 아침 Class Time이 붙는다', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TeacherClassTimeLine(
          bands: TeacherClassBands(
            days: {6, 7},
            periods: {TeacherClassBands.am},
          ),
          closedRoutines: {
            '6_06:00',
            '6_06:30',
            '6_07:00',
            '6_07:30',
            '6_10:30',
            '6_11:00',
            '6_11:30',
            '7_06:00',
            '7_06:30',
            '7_07:00',
            '7_07:30',
            '7_09:00',
            '7_09:30',
            '7_10:00',
            '7_10:30',
            '7_11:00',
            '7_11:30',
          },
        ),
      ),
    ));
    expect(find.textContaining('Class Time :'), findsOneWidget);
    expect(find.textContaining('주말 아침'), findsOneWidget);
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
    expect(find.textContaining('평일 오전, 오후'), findsOneWidget);
    expect(find.textContaining('일요일 오전, 오후'), findsOneWidget);
  });
}
