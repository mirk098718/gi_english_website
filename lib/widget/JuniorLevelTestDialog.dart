import 'package:flutter/material.dart';
import 'package:gi_english_website/class/JuniorLevel.dart';
import 'package:gi_english_website/class/JuniorLevelTest.dart';
import 'package:gi_english_website/util/AppLanguage.dart';
import 'package:gi_english_website/util/Palette.dart';

/// 초등부 또는 중등부 레벨테스트. 끝나면 레벨 1~6을 돌려준다.
class JuniorLevelTestDialog extends StatefulWidget {
  final String band;

  const JuniorLevelTestDialog({Key? key, required this.band}) : super(key: key);

  static Future<JuniorLevel?> open(BuildContext context, {required String band}) {
    return showDialog<JuniorLevel>(
      context: context,
      builder: (_) => JuniorLevelTestDialog(band: band),
    );
  }

  @override
  State<JuniorLevelTestDialog> createState() => _JuniorLevelTestDialogState();
}

class _JuniorLevelTestDialogState extends State<JuniorLevelTestDialog> {
  late final List<JuniorLevelQuestion> _questions;
  late final List<int?> _answers;
  int _index = 0;
  JuniorLevel? _result;

  @override
  void initState() {
    super.initState();
    _questions = JuniorLevelTest.questionsFor(widget.band);
    _answers = List<int?>.filled(_questions.length, null);
  }

  String get _bandLabel =>
      widget.band == JuniorLevel.middle ? '중등부 레벨테스트' : '초등부 레벨테스트';

  void _pick(int choice) {
    setState(() => _answers[_index] = choice);
  }

  void _next() {
    if (_answers[_index] == null) return;
    if (_index < _questions.length - 1) {
      setState(() => _index += 1);
      return;
    }
    setState(() => _result = JuniorLevelTest.result(widget.band, _answers));
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return AlertDialog(
      title: Text(tr(context, result == null ? _bandLabel : '레벨테스트 결과'),
          style: TextStyle(fontFamily: 'Jalnan')),
      content: SizedBox(
        width: 460,
        child: result == null ? _question() : _done(result),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(tr(context, result == null ? '닫기' : '레벨만 보고 닫기')),
        ),
        if (result == null)
          ElevatedButton(
            onPressed: _answers[_index] == null ? null : _next,
            child: Text(tr(context, _index == _questions.length - 1 ? '결과 보기' : '다음')),
          )
        else
          ElevatedButton(
            onPressed: () => Navigator.pop(context, result),
            child: Text(tr(context, '이 레벨로 쓰기')),
          ),
      ],
    );
  }

  Widget _question() {
    final question = _questions[_index];
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${_index + 1} / ${_questions.length}',
            style: TextStyle(fontFamily: 'NotoSansKR', color: Palette.grey600),
          ),
          const SizedBox(height: 8),
          Text(
            question.prompt,
            style: TextStyle(fontFamily: 'NotoSansKR', fontSize: 15, height: 1.45),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < question.choices.length; i++)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                _answers[_index] == i
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: _answers[_index] == i ? Palette.darkTeal : Palette.grey400,
              ),
              title: Text(question.choices[i],
                  style: TextStyle(fontFamily: 'NotoSansKR')),
              onTap: () => _pick(i),
            ),
        ],
      ),
    );
  }

  Widget _done(JuniorLevel result) {
    final correct = JuniorLevelTest.score(widget.band, _answers);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tf(context, '{p0}문항 중 {p1}문항을 맞혀 {p2}입니다.', {
            'p0': _questions.length,
            'p1': correct,
            'p2': result.label,
          }),
          style: TextStyle(
            fontFamily: 'NotoSansKR',
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          tr(context, '프로그램 선택의 내 레벨에 이 결과가 들어갑니다. 원하면 직접 고칠 수 있습니다.'),
          style: TextStyle(
            fontFamily: 'NotoSansKR',
            fontSize: 13,
            height: 1.45,
            color: Palette.grey600,
          ),
        ),
      ],
    );
  }
}
