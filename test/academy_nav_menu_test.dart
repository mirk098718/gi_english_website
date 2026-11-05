import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gi_english_website/widget/AcademyNavMenu.dart';
import 'package:gi_english_website/widget/SiteNav.dart';

void main() {
  testWidgets('어학원 메뉴를 열면 하위 메뉴를 고를 수 있다', (tester) async {
    SiteNavItem? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AcademyNavMenu(onSelect: (item) => selected = item),
        ),
      ),
    );

    expect(find.text('소개'), findsOneWidget);
    expect(find.text('프로그램'), findsOneWidget);
    expect(find.text('커리큘럼'), findsOneWidget);
    expect(find.text('커뮤니티'), findsOneWidget);
    expect(find.text('정규 초등부'), findsOneWidget);
    expect(find.text('공지사항'), findsOneWidget);

    await tester.tap(find.text('정규 초등부'));
    await tester.pump();

    expect(selected?.label, '정규 초등부');
  });

  testWidgets('좁은 화면에서도 아래쪽 하위 메뉴까지 스크롤된다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              height: 220,
              child: AcademyNavMenu(onSelect: (_) {}),
            ),
          ),
        ),
      ),
    );

    expect(find.text('학원 홈'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('FAQ'),
      80,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('FAQ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
