import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gi_english_website/class/JuniorCurriculum.dart';
import 'package:gi_english_website/class/OnlineCourse.dart';
import 'package:gi_english_website/class/OnlinePlan.dart';
import 'package:gi_english_website/pages/SchoolCodingPage.dart';
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
    expect(
      find.text(JuniorCurriculumContent.description),
      findsWidgets,
    );
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
    expect(find.text('940,500원 결제하기'), findsOneWidget);
    expect(find.text('원어민 강사를 고른 뒤 결제합니다.'), findsOneWidget);
    expect(find.text('정가 990,000원에서 5% 할인'), findsOneWidget);
    expect(find.text('3개월 동안 36회 수업입니다.'), findsOneWidget);

    await tester.ensureVisible(find.text('내용 보기'));
    await tester.tap(find.text('내용 보기'));
    await tester.pumpAndSettle();
    expect(find.text('세부 프로그램'), findsOneWidget);
  });

  test('주니어와 프리토킹은 회당 금액이 아니라 고른 금액으로 결제된다', () {
    final month = OnlineCourse.junior(JuniorOffer.twiceAWeek, quarter: false);
    expect(month.amountFor(OnlinePlan.speaking), 260000);
    expect(month.sessionsFor(OnlinePlan.speaking, sessions: 4), 8);
    expect(month.fixedSpeakingPrice, isTrue);
    expect(OnlineCourse.findById(month.id), same(month));
    expect(OnlineCourse.all.contains(month), isFalse);

    final quarter =
        OnlineCourse.junior(JuniorOffer.threeTimesAWeek, quarter: true);
    expect(quarter.amountFor(OnlinePlan.speaking, sessions: 8), 940500);
    expect(quarter.sessionsFor(OnlinePlan.speaking, sessions: 8), 36);
    expect(quarter.nameFor(OnlinePlan.speaking), '초중등 1:1 화상 영어 수업 · 주 3회 · 3개월');

    final talk = OnlineCourse.enrolledFreeTalk;
    expect(talk.amountFor(OnlinePlan.speaking, sessions: 12), 70000);
    expect(talk.sessionsFor(OnlinePlan.speaking, sessions: 12), 4);
    expect(OnlineCourse.findById(talk.id), same(talk));
    expect(OnlineCourse.catalog.contains(talk), isTrue);
    expect(OnlineCourse.catalog.contains(quarter), isTrue);
  });

  test('재원생 프리토킹은 주 1회 20분, 4회에 7만 원이다', () {
    expect(EnrolledFreeTalk.sessions, 4);
    expect(EnrolledFreeTalk.minutes, 20);
    expect(EnrolledFreeTalk.price, 70000);
    expect(EnrolledFreeTalk.priceLabel(), '70,000원');
  });

  testWidgets('선택 프로그램은 주니어 수업과 원어민 사진만 있는 프리토킹을 보여 준다',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: OptionalProgramBody()),
        ),
      ),
    );

    expect(find.text('선택 프로그램'), findsOneWidget);
    expect(find.text('1. 주니어 커리큘럼'), findsOneWidget);
    expect(find.text(JuniorCurriculumContent.description), findsWidgets);
    expect(find.text('2. 원어민 화상 프리토킹 (재원생 대상)'), findsOneWidget);
    expect(find.text('주 1회 · 20분 · 4회 70,000원'), findsOneWidget);
    expect(find.text('70,000원 결제하기'), findsOneWidget);
    expect(find.text('원어민 강사를 고른 뒤 결제합니다.'), findsWidgets);
    expect(
      find.text(
        '재원생만 들을 수 있는 수업입니다. 원서와 문제 없이, 원어민 선생님과 이야기만 합니다.',
      ),
      findsOneWidget,
    );

    final assets = tester
        .widgetList<Image>(find.byType(Image))
        .map((image) => (image.image as AssetImage).assetName)
        .toList();
    expect(assets, contains('assets/junior-reader-spread.jpg'));
    expect(
      assets.where((name) => name == 'assets/plan-card-speaking.jpg').length,
      2,
    );
    expect(assets, isNot(contains('assets/optionalPrograms.png')));
    expect(assets, isNot(contains('assets/middleSchoolOptionalProgram.png')));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: EnrolledFreeTalkSection()),
      ),
    );
    final freeTalkAssets = tester
        .widgetList<Image>(find.byType(Image))
        .map((image) => (image.image as AssetImage).assetName)
        .toList();
    expect(freeTalkAssets, ['assets/plan-card-speaking.jpg']);
    expect(find.text('원서'), findsNothing);
  });
}
