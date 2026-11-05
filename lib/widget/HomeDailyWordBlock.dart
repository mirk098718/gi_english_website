import 'package:flutter/material.dart';
import 'package:gi_english_website/util/DailyWord.dart';
import 'package:gi_english_website/util/Palette.dart';

/// 학원 홈과 온라인 홈 아래에 두는 오늘의 단어.
class HomeDailyWordBlock extends StatelessWidget {
  final bool compact;
  final DateTime? date;

  const HomeDailyWordBlock({Key? key, this.compact = false, this.date})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final today = date ?? DateTime.now();
    final word = DailyWord.forDate(today);
    return Container(
      width: double.infinity,
      color: Palette.white,
      padding: EdgeInsets.fromLTRB(
        compact ? 20 : 48,
        compact ? 28 : 40,
        compact ? 20 : 48,
        compact ? 36 : 48,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 860),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              compact ? 18 : 28,
              compact ? 18 : 24,
              compact ? 18 : 28,
              compact ? 18 : 24,
            ),
            decoration: BoxDecoration(
              color: Palette.grey50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Palette.grey200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${today.month}월 ${today.day}일 · 오늘의 단어',
                  style: TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontSize: compact ? 12 : 13,
                    fontWeight: FontWeight.w600,
                    color: Palette.darkTeal,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  word.word,
                  style: TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontSize: compact ? 28 : 36,
                    fontWeight: FontWeight.w800,
                    color: Palette.navy,
                    height: 1.15,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  word.meaning,
                  style: TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontSize: compact ? 15 : 16,
                    fontWeight: FontWeight.w600,
                    color: Palette.grey700,
                  ),
                ),
                SizedBox(height: compact ? 16 : 20),
                Text(
                  '오늘의 표현',
                  style: TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontSize: compact ? 12 : 13,
                    fontWeight: FontWeight.w600,
                    color: Palette.darkTeal,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  word.expression,
                  style: TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontSize: compact ? 16 : 18,
                    fontWeight: FontWeight.w700,
                    height: 1.45,
                    color: Palette.black,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  word.expressionMeaning,
                  style: TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontSize: compact ? 14 : 15,
                    height: 1.5,
                    color: Palette.grey600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
