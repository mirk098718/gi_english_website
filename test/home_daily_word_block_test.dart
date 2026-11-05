import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gi_english_website/util/DailyWord.dart';
import 'package:gi_english_website/widget/HomeDailyWordBlock.dart';

void main() {
  testWidgets('오늘의 단어와 그 단어를 쓴 표현을 보여 준다', (tester) async {
    final date = DateTime(2026, 11, 5);
    final word = DailyWord.forDate(date);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeDailyWordBlock(date: date, word: word),
        ),
      ),
    );

    expect(find.text('11월 5일 · 오늘의 단어'), findsOneWidget);
    expect(find.text(word.word), findsOneWidget);
    expect(find.text(word.meaning), findsOneWidget);
    expect(find.text('오늘의 표현'), findsOneWidget);
    expect(find.text(word.expression), findsOneWidget);
    expect(find.text(word.expressionMeaning), findsOneWidget);
  });
}
