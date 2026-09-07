import 'package:flutter/material.dart';
import 'package:gi_english_website/class/ClassPlacementQuiz.dart';
import 'package:gi_english_website/class/OnlineCourse.dart';
import 'package:gi_english_website/util/Palette.dart';

enum _PlacementStep { part1, part2, result }

class ClassPlacementDialog extends StatefulWidget {
  final ValueChanged<OnlineCourse>? onViewCourse;

  const ClassPlacementDialog({Key? key, this.onViewCourse}) : super(key: key);

  static Future<void> show(
    BuildContext context, {
    ValueChanged<OnlineCourse>? onViewCourse,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ClassPlacementDialog(onViewCourse: onViewCourse),
    );
  }

  @override
  State<ClassPlacementDialog> createState() => _ClassPlacementDialogState();
}

class _ClassPlacementDialogState extends State<ClassPlacementDialog> {
  _PlacementStep _step = _PlacementStep.part1;
  int _part1Index = 0;
  int _part2Index = 0;
  final List<int?> _part1Answers =
      List<int?>.filled(ClassPlacementQuiz.part1Questions.length, null);
  final List<int?> _part2Answers =
      List<int?>.filled(ClassPlacementQuiz.part2Questions.length, null);
  PlacementResult? _result;

  static const _bodyStyle = TextStyle(
    fontFamily: 'NotoSansKR',
    fontSize: 14,
    height: 1.55,
    color: Palette.grey800,
  );

  int? get _currentChoice {
    if (_step == _PlacementStep.part1) return _part1Answers[_part1Index];
    if (_step == _PlacementStep.part2) return _part2Answers[_part2Index];
    return null;
  }

  bool get _canGoBack {
    if (_step == _PlacementStep.result) return false;
    if (_step == _PlacementStep.part2) return true;
    return _part1Index > 0;
  }

  bool get _canGoNext => _currentChoice != null;

  String get _nextLabel {
    if (_step == _PlacementStep.part1 &&
        _part1Index == ClassPlacementQuiz.part1Questions.length - 1) {
      return ClassPlacementQuiz.shouldSkipPart2(_filledPart1())
          ? '결과 보기'
          : '실력 진단 시작';
    }
    if (_step == _PlacementStep.part2 &&
        _part2Index == ClassPlacementQuiz.part2Questions.length - 1) {
      return '결과 보기';
    }
    return '다음';
  }

  double get _progress {
    if (_step == _PlacementStep.result) return 1;
    if (_step == _PlacementStep.part1) {
      return (_part1Index + 1) / ClassPlacementQuiz.part1Questions.length;
    }
    return (_part2Index + 1) / ClassPlacementQuiz.part2Questions.length;
  }

  String get _progressLabel {
    if (_step == _PlacementStep.part1) {
      return 'PART 1  ${_part1Index + 1} / ${ClassPlacementQuiz.part1Questions.length}';
    }
    if (_step == _PlacementStep.part2) {
      return 'PART 2  ${_part2Index + 1} / ${ClassPlacementQuiz.part2Questions.length}';
    }
    return '배정 결과';
  }

  void _selectChoice(int number) {
    setState(() {
      if (_step == _PlacementStep.part1) {
        _part1Answers[_part1Index] = number;
      } else if (_step == _PlacementStep.part2) {
        _part2Answers[_part2Index] = number;
      }
    });
  }

  void _goBack() {
    setState(() {
      if (_step == _PlacementStep.part2) {
        if (_part2Index == 0) {
          _step = _PlacementStep.part1;
          _part1Index = ClassPlacementQuiz.part1Questions.length - 1;
        } else {
          _part2Index--;
        }
      } else if (_part1Index > 0) {
        _part1Index--;
      }
    });
  }

  void _goNext() {
    final choice = _currentChoice;
    if (choice == null) return;

    if (_step == _PlacementStep.part1) {
      if (_part1Index < ClassPlacementQuiz.part1Questions.length - 1) {
        setState(() => _part1Index++);
        return;
      }
      final answers = _filledPart1();
      if (ClassPlacementQuiz.shouldSkipPart2(answers)) {
        setState(() {
          _result = ClassPlacementQuiz.evaluate(part1Answers: answers);
          _step = _PlacementStep.result;
        });
        return;
      }
      setState(() {
        _step = _PlacementStep.part2;
        _part2Index = 0;
      });
      return;
    }

    if (_part2Index < ClassPlacementQuiz.part2Questions.length - 1) {
      setState(() => _part2Index++);
      return;
    }

    setState(() {
      _result = ClassPlacementQuiz.evaluate(
        part1Answers: _filledPart1(),
        part2Answers: _filledPart2(),
      );
      _step = _PlacementStep.result;
    });
  }

  List<int> _filledPart1() =>
      _part1Answers.map((value) => value ?? 0).toList();

  List<int> _filledPart2() =>
      _part2Answers.map((value) => value ?? 0).toList();

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.9;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Palette.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 560, maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(),
            _progressBar(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: _body(),
              ),
            ),
            if (_step != _PlacementStep.result) _footer(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              '클래스 배정 테스트',
              style: TextStyle(
                fontFamily: 'NotoSansKR',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Palette.grey900,
              ),
            ),
          ),
          IconButton(
            tooltip: '닫기',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Palette.grey500),
          ),
        ],
      ),
    );
  }

  Widget _progressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _progressLabel,
            style: const TextStyle(
              fontFamily: 'NotoSansKR',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Palette.secondary,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 6,
              backgroundColor: Palette.grey100,
              color: Palette.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    switch (_step) {
      case _PlacementStep.part1:
        return _part1Body();
      case _PlacementStep.part2:
        return _part2Body();
      case _PlacementStep.result:
        return _resultBody();
    }
  }

  Widget _part1Body() {
    final question = ClassPlacementQuiz.part1Questions[_part1Index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_part1Index == 0) ...[
          Text(ClassPlacementQuiz.part1Intro, style: _bodyStyle),
          const SizedBox(height: 12),
          _infoBox(ClassPlacementQuiz.skipNotice),
          const SizedBox(height: 20),
        ],
        Text(
          '수강 목적 및 배경',
          style: TextStyle(
            fontFamily: 'NotoSansKR',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Palette.grey500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Q${_part1Index + 1}. ${question.prompt}',
          style: const TextStyle(
            fontFamily: 'NotoSansKR',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            height: 1.45,
            color: Palette.grey900,
          ),
        ),
        const SizedBox(height: 16),
        ...question.choices.map(_choiceTile),
      ],
    );
  }

  Widget _part2Body() {
    final question = ClassPlacementQuiz.part2Questions[_part2Index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_part2Index == 0) ...[
          Text(
            '객관적 실력 진단입니다. 문항마다 정답이 하나이며, 정답 수에 따라 클래스가 배정됩니다.',
            style: _bodyStyle,
          ),
          const SizedBox(height: 16),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Palette.secondary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            question.category,
            style: const TextStyle(
              fontFamily: 'NotoSansKR',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Palette.secondary,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          question.prompt,
          style: const TextStyle(
            fontFamily: 'NotoSansKR',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            height: 1.45,
            color: Palette.grey900,
          ),
        ),
        const SizedBox(height: 16),
        ...question.choices.map(_choiceTile),
      ],
    );
  }

  Widget _choiceTile(PlacementChoice choice) {
    final selected = _currentChoice == choice.number;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? Palette.secondary.withValues(alpha: 0.08)
            : Palette.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _selectChoice(choice.number),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? Palette.secondary : Palette.grey200,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  choice.circledLabel,
                  style: TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: selected ? Palette.secondary : Palette.grey700,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    choice.text,
                    style: TextStyle(
                      fontFamily: 'NotoSansKR',
                      fontSize: 14,
                      height: 1.45,
                      color: selected ? Palette.grey900 : Palette.grey700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Palette.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Palette.grey200),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'NotoSansKR',
          fontSize: 13,
          height: 1.5,
          color: Palette.grey600,
        ),
      ),
    );
  }

  Widget _resultBody() {
    final result = _result;
    if (result == null) return const SizedBox.shrink();
    final course = result.course;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '배정 결과',
          style: TextStyle(
            fontFamily: 'NotoSansKR',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Palette.grey500,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Palette.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Palette.secondary.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: Palette.grey200.withValues(alpha: 0.6),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${course.order}번 클래스',
                style: const TextStyle(
                  fontFamily: 'NotoSansKR',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Palette.secondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                course.title,
                style: const TextStyle(
                  fontFamily: 'NotoSansKR',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Palette.grey900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                course.subtitle,
                style: const TextStyle(
                  fontFamily: 'NotoSansKR',
                  fontSize: 14,
                  color: Palette.grey600,
                ),
              ),
              const SizedBox(height: 16),
              Text(result.explanation, style: _bodyStyle),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Palette.grey700,
                  side: const BorderSide(color: Palette.grey300),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  '닫기',
                  style: TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (widget.onViewCourse != null) ...[
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => widget.onViewCourse!(course),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Palette.secondary,
                    foregroundColor: Palette.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    '이 과정 보기',
                    style: TextStyle(
                      fontFamily: 'NotoSansKR',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _footer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Row(
        children: [
          OutlinedButton(
            onPressed: _canGoBack ? _goBack : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: Palette.grey700,
              side: const BorderSide(color: Palette.grey300),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              '이전',
              style: TextStyle(
                fontFamily: 'NotoSansKR',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _canGoNext ? _goNext : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Palette.secondary,
              foregroundColor: Palette.white,
              disabledBackgroundColor: Palette.grey200,
              disabledForegroundColor: Palette.grey400,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              _nextLabel,
              style: const TextStyle(
                fontFamily: 'NotoSansKR',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
