import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gi_english_website/class/OnlineNativeTeacher.dart';
import 'package:gi_english_website/pages/OnlineTeacherSelectPage.dart';
import 'package:gi_english_website/util/AppLanguage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppLanguage.instance.code = 'ko';
  });

  OnlineNativeTeacher teacher(String id) {
    return OnlineNativeTeacher(
      id: id,
      name: id,
      nationality: 'Canada',
      intro: '소개',
      imageAsset: 'assets/nativeTeacherPortrait.png',
    );
  }

  Future<void> pumpGrid(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: OnlineTeacherCardGrid(
              teachers: [teacher('a'), teacher('b'), teacher('c')],
              selectedId: 'a',
              onSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('웹에서는 강사 카드가 한 줄에 세 장이다', (tester) async {
    await pumpGrid(tester, const Size(1280, 900));
    final tops = ['a', 'b', 'c']
        .map((id) => tester.getTopLeft(find.byKey(ValueKey('teacher-card-$id'))).dy)
        .toList();
    expect(tops[0], tops[1]);
    expect(tops[1], tops[2]);
    final width = tester.getSize(find.byKey(const ValueKey('teacher-card-a'))).width;
    expect(width, lessThan(1280 / 2));
    expect(width, greaterThan(1280 / 4));
  });

  testWidgets('모바일에서는 강사 카드가 한 줄에 하나다', (tester) async {
    await pumpGrid(tester, const Size(390, 900));
    final topA = tester.getTopLeft(find.byKey(const ValueKey('teacher-card-a'))).dy;
    final topB = tester.getTopLeft(find.byKey(const ValueKey('teacher-card-b'))).dy;
    expect(topB, greaterThan(topA));
    expect(
      tester.getSize(find.byKey(const ValueKey('teacher-card-a'))).width,
      390,
    );
  });

  testWidgets('사진이 위쪽 테두리를 덮지 않도록 테두리만큼 안쪽이 비어 있다', (tester) async {
    await pumpGrid(tester, const Size(1280, 900));
    final card = find.byKey(const ValueKey('teacher-card-a'));
    final box = tester.widget<Container>(
      find.descendant(of: card, matching: find.byType(Container)).first,
    );
    expect(box.padding, const EdgeInsets.all(2.5));
    expect(find.descendant(of: card, matching: find.byType(ClipRRect)), findsOneWidget);
  });
}
