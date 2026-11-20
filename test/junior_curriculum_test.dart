import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gi_english_website/class/JuniorCurriculum.dart';
import 'package:gi_english_website/pages/SchoolOnlineJuniorCurriculumPage.dart';
import 'package:gi_english_website/widget/OnlineProgramSideMenu.dart';

void main() {
  test('주 2회는 8회 26만 원이고, 3개월은 5%를 뺀다', () {
    const offer = JuniorOffer.twiceAWeek;
    expect(offer.sessionsPerMonth, 8);
    expect(offer.monthlyPrice, 260000);
    expect(offer.quarterSessions, 24);
    expect(offer.quarterListPrice, 780000);
    expect(offer.quarterPrice, 741000);
    expect(offer.price(quarter: false), 260000);
    expect(offer.price(quarter: true), 741000);
  });

  test('주 3회는 12회 33만 원이고, 3개월은 5%를 뺀다', () {
    const offer = JuniorOffer.threeTimesAWeek;
    expect(offer.sessionsPerMonth, 12);
    expect(offer.monthlyPrice, 330000);
    expect(offer.quarterSessions, 36);
    expect(offer.quarterListPrice, 990000);
    expect(offer.quarterPrice, 940500);
  });

  testWidgets('왼쪽 메뉴에서 커리큘럼 다음에 주니어 커리큘럼이 있다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OnlineProgramSideMenu(
            selectedIndex: OnlineProgramSideMenu.juniorIndex,
            isMobile: true,
          ),
        ),
      ),
    );

    expect(find.text('커리큘럼'), findsOneWidget);
    expect(find.text('주니어 커리큘럼'), findsOneWidget);
    expect(find.text('내 강의실'), findsOneWidget);
    final curriculum = tester.getTopLeft(find.text('커리큘럼')).dx;
    final junior = tester.getTopLeft(find.text('주니어 커리큘럼')).dx;
    final classroom = tester.getTopLeft(find.text('내 강의실')).dx;
    expect(curriculum, lessThan(junior));
    expect(junior, lessThan(classroom));
  });

  testWidgets('주 3회 3개월을 고르면 할인가가 선택 금액이 된다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: JuniorCurriculumContent(),
          ),
        ),
      ),
    );

    expect(find.text('초중등 1:1 화상 영어 수업'), findsOneWidget);
    expect(find.text('원서'), findsOneWidget);
    expect(find.text('화상'), findsOneWidget);
    expect(find.text('선택한 금액 260,000원'), findsOneWidget);
    expect(find.text('260,000원'), findsWidgets);
    expect(find.text('330,000원'), findsWidgets);

    await tester.tap(find.text('주 3회'));
    await tester.pump();
    expect(find.text('선택한 금액 330,000원'), findsOneWidget);

    await tester.tap(find.text('3개월'));
    await tester.pump();
    expect(find.text('선택한 금액 940,500원'), findsOneWidget);
    expect(find.text('정가 990,000원에서 5% 할인'), findsOneWidget);
    expect(find.text('3개월 동안 36회 수업입니다.'), findsOneWidget);

    await tester.ensureVisible(find.text('내용 보기'));
    await tester.tap(find.text('내용 보기'));
    await tester.pumpAndSettle();
    expect(find.text('세부 프로그램'), findsOneWidget);
  });
}
