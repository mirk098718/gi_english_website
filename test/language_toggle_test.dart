import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gi_english_website/util/AppLanguage.dart';
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
}
