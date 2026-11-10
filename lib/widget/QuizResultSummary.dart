import 'package:flutter/material.dart';
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
          if (result.essays.isNotEmpty) _essayDropdown(context),
        ],
      ),
    );
  }

  Widget _essayDropdown(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.only(bottom: 4),
        expandedAlignment: Alignment.centerLeft,
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        iconColor: Palette.grey600,
        collapsedIconColor: Palette.grey600,
        title: Text(
          '주관식 답 보기',
          style: TextStyle(
            fontFamily: "NotoSansKR",
            fontSize: dense ? 12 : 13,
            fontWeight: FontWeight.w700,
            color: Palette.black,
          ),
        ),
        children: [
          ...result.essays.map((essay) => _EssayAnswerBlock(
                essay: essay,
                dense: dense,
              )),
          if (!dense)
            Padding(
              padding: EdgeInsets.only(top: 2),
              child: Text(
                '다시 풀고 완료를 누르면 이 점수와 주관식 답이 최근 풀이로 바뀝니다.',
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontFamily: "NotoSansKR",
                  fontSize: 11,
                  height: 1.4,
                  color: Palette.grey500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EssayAnswerBlock extends StatelessWidget {
  final QuizEssayAnswer essay;
  final bool dense;

  const _EssayAnswerBlock({
    required this.essay,
    required this.dense,
  });

  @override
  Widget build(BuildContext context) {
    final heading = essay.title.trim().isEmpty
        ? '주관식 ${essay.index}'
        : essay.title.trim();
    final answerStyle = TextStyle(
      fontFamily: "NotoSansKR",
      fontSize: dense ? 12 : 14,
      height: 1.45,
      color: essay.hasAnswer ? Palette.black : Palette.grey500,
    );
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: dense ? 8 : 10),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: Palette.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Palette.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontFamily: "NotoSansKR",
              fontSize: dense ? 12 : 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (essay.prompt.trim().isNotEmpty) ...[
            SizedBox(height: 4),
            Text(
              essay.prompt.trim(),
              textAlign: TextAlign.left,
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
            essay.hasAnswer ? essay.answer.trim() : '작성하지 않음',
            textAlign: TextAlign.left,
            style: answerStyle,
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
          result.title.trim().isEmpty ? '주관식 답안' : result.title.trim(),
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
                    '저장된 주관식 답이 없습니다.',
                    style: TextStyle(
                      fontFamily: "NotoSansKR",
                      fontSize: 13,
                      color: Palette.grey600,
                    ),
                  )
                else
                  ...essays.map(
                    (essay) => _EssayAnswerBlock(essay: essay, dense: false),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('닫기', style: TextStyle(fontFamily: "NotoSansKR")),
          ),
        ],
      );
    },
  );
}
