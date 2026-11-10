import 'package:flutter/material.dart';
import 'package:gi_english_website/util/AppLanguage.dart';
import 'package:gi_english_website/class/QuizResult.dart';
import 'package:gi_english_website/util/Palette.dart';

/// 최근 퀴즈 점수와 주관식 답안 다시 보기.
class QuizResultSummary extends StatelessWidget {
  final QuizResult result;
  final bool dense;

  const QuizResultSummary({
    Key? key,
    required this.result,
    this.dense = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final savedAt = result.savedAtLabel;
    return Padding(
      padding: EdgeInsets.only(top: dense ? 6 : 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [
              if (result.title.trim().isNotEmpty) result.title.trim(),
              result.scoreLabel,
            ].join(' · '),
            style: TextStyle(
              fontFamily: "NotoSansKR",
              fontSize: dense ? 12 : 13,
              fontWeight: FontWeight.w700,
              color: Palette.secondaryDark,
              height: 1.4,
            ),
          ),
          if (savedAt.isNotEmpty)
            Text(
              '최근 저장 $savedAt',
              style: TextStyle(
                fontFamily: "NotoSansKR",
                fontSize: 11,
                color: Palette.grey500,
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => showQuizEssayDialog(context, result),
              child: Text(
                tr(context, "주관식 답안 보기"),
                style: TextStyle(
                  fontFamily: "NotoSansKR",
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          if (!dense)
            Text(
              tr(context, "다시 풀고 25문제를 모두 채점하면 이 정답률과 주관식 답이 최근 풀이로 바뀝니다."),
              style: TextStyle(
                fontFamily: "NotoSansKR",
                fontSize: 11,
                height: 1.4,
                color: Palette.grey500,
              ),
            ),
        ],
      ),
    );
  }
}

Future<void> showQuizEssayDialog(BuildContext context, QuizResult result) {
  final essays = result.essays;
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(
          result.title.trim().isEmpty ? tr(context, "주관식 답안") : result.title.trim(),
          style: TextStyle(fontFamily: "Jalnan", fontSize: 16),
        ),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.scoreLabel,
                  style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontWeight: FontWeight.w700,
                    color: Palette.secondaryDark,
                  ),
                ),
                SizedBox(height: 12),
                if (essays.isEmpty)
                  Text(
                    tr(context, "저장된 주관식 답이 없습니다."),
                    style: TextStyle(
                      fontFamily: "NotoSansKR",
                      fontSize: 13,
                      color: Palette.grey600,
                    ),
                  )
                else
                  ...essays.map((essay) {
                    final heading = essay.title.trim().isEmpty
                        ? '주관식 ${essay.index}'
                        : essay.title.trim();
                    return Padding(
                      padding: EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            heading,
                            style: TextStyle(
                              fontFamily: "NotoSansKR",
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (essay.prompt.trim().isNotEmpty) ...[
                            SizedBox(height: 4),
                            Text(
                              essay.prompt.trim(),
                              style: TextStyle(
                                fontFamily: "NotoSansKR",
                                fontSize: 12,
                                height: 1.45,
                                color: Palette.grey600,
                              ),
                            ),
                          ],
                          SizedBox(height: 4),
                          Text(
                            essay.hasAnswer ? essay.answer.trim() : tr(context, "작성하지 않음"),
                            style: TextStyle(
                              fontFamily: "NotoSansKR",
                              fontSize: 14,
                              height: 1.45,
                              color: essay.hasAnswer
                                  ? Palette.black
                                  : Palette.grey500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(tr(context, "닫기"), style: TextStyle(fontFamily: "NotoSansKR")),
          ),
        ],
      );
    },
  );
}
