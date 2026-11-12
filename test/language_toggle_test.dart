import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gi_english_website/util/AppLanguage.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/widget/OnlinePlanCard.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppLanguage.instance.code = 'ko';
  });

  tearDown(() {
    AppLanguage.instance.code = 'ko';
  });

  testWidgets('한글 화면이 영어로 바뀌고 다시 한글로 돌아온다', (tester) async {
    await tester.pumpWidget(
      LangScope(
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Column(
                children: [
                  const LanguageToggle(),
                  Text(tr(context, '온라인 영어 · 원어민 1:1')),
                  Text(tr(context, '글림아일랜드 어학원')),
                  Text(tr(context, '무료 체험하기')),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('온라인 영어 · 원어민 1:1'), findsOneWidget);
    expect(find.text('글림아일랜드 어학원'), findsOneWidget);
    expect(find.text('Korean'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pump();

    expect(
      find.text('Online English · 1:1 with a native teacher'),
      findsOneWidget,
    );
    expect(find.text('Gleam Island Academy'), findsOneWidget);
    expect(find.text('Try it free'), findsOneWidget);
    expect(find.text('온라인 영어 · 원어민 1:1'), findsNothing);

    await tester.tap(find.text('Korean'));
    await tester.pump();

    expect(find.text('온라인 영어 · 원어민 1:1'), findsOneWidget);
    expect(find.text('글림아일랜드 어학원'), findsOneWidget);
    expect(find.text('무료 체험하기'), findsOneWidget);
  });

  test('운영자·강사 문장도 메인 화면 언어를 따른다', () {
    AppLanguage.instance.code = 'ko';
    expect(
      AppLanguage.instance.translate('온라인 프로그램 관리'),
      '온라인 프로그램 관리',
    );
    expect(AppLanguage.instance.translate('월'), '월');

    AppLanguage.instance.code = 'en';
    expect(
      AppLanguage.instance.translate('온라인 프로그램 관리'),
      'Online program',
    );
    expect(AppLanguage.instance.translate('월'), 'Mon');
    expect(
      AppLanguage.instance.fill(
        '매주 {p0}요일 {p1}을 다시 엽니다.',
        {'p0': 'Mon', 'p1': '9:00 AM'},
      ),
      'Opens 9:00 AM every Mon again.',
    );
    expect(
      AppLanguage.instance.fill('{p0}년 {p1}월', {'p0': 2026, 'p1': 11}),
      '11/2026',
    );
    expect(
      AppLanguage.instance.translate(
        '인강을 듣고, 퀴즈로 다지고, 1:1 화상으로 실사용해봅니다.',
      ),
      'Watch the lessons, lock them in with a quiz, and use them in a 1:1 live class.',
    );
    expect(AppLanguage.instance.translate('지금 판매 중'), 'On sale now');
    expect(AppLanguage.instance.translate('내용 보기'), 'See details');
    expect(AppLanguage.instance.translate('정규고등부'), 'High school');
    expect(AppLanguage.instance.translate('정규프로그램'), 'Regular program');
    expect(
      AppLanguage.instance.fill('1회 {p0}', {'p0': '₩15,000'}),
      '₩15,000 per class',
    );
  });

  testWidgets('상품 카드와 학원 왼쪽 메뉴가 영어로 바뀐다', (tester) async {
    await tester.pumpWidget(
      LangScope(
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: SingleChildScrollView(
                child: Column(
                children: [
                  const LanguageToggle(),
                  OnlinePlanCard(
                    index: '2',
                    title: '영문법 인강 + 원어민 화상 회화',
                    summary: '인강을 듣고, 퀴즈로 다지고, 1:1 화상으로 실사용해봅니다.',
                    priceLine: '레벨별 180,000원~',
                    color: Palette.secondaryDark,
                    imageAsset: 'assets/plan-card-bundle.jpg',
                    selected: false,
                    current: true,
                    onTap: () {},
                  ),
                  MyWidget.leftMenuMiddle(Palette.navy, '정규고등부'),
                  MyWidget.leftMenuMiddle(Palette.white, '정규프로그램'),
                ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('지금 판매 중'), findsOneWidget);
    expect(find.text('내용 보기'), findsOneWidget);
    expect(find.text('레벨별 180,000원~'), findsOneWidget);
    expect(find.text('정규고등부'), findsOneWidget);
    expect(find.text('정규프로그램'), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pump();

    expect(find.text('On sale now'), findsOneWidget);
    expect(find.text('See details'), findsOneWidget);
    expect(
      find.text(
        'Watch the lessons, lock them in with a quiz, and use them in a 1:1 live class.',
      ),
      findsOneWidget,
    );
    expect(find.text('From ₩180,000 by level'), findsOneWidget);
    expect(find.text('High school'), findsOneWidget);
    expect(find.text('Regular program'), findsOneWidget);
    expect(find.text('지금 판매 중'), findsNothing);
    expect(find.text('정규고등부'), findsNothing);
  });
}
