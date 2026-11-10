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

  testWidgets('Korean and English switch the visible copy', (tester) async {
    await tester.pumpWidget(
      LangScope(
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Column(
                  children: [
                    const LanguageToggle(),
                    Text(tr(context, '상담신청')),
                    Text(tr(context, '오시는 길')),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('상담신청'), findsOneWidget);
    expect(find.text('오시는 길'), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pump();

    expect(find.text('Book Now'), findsOneWidget);
    expect(find.text('Find Us'), findsOneWidget);
    expect(find.text('상담신청'), findsNothing);

    await tester.tap(find.text('Korean'));
    await tester.pump();

    expect(find.text('상담신청'), findsOneWidget);
    expect(find.text('Book Now'), findsNothing);
  });
}
