import 'package:flutter/material.dart';
import 'package:gi_english_website/util/Palette.dart';

/// 홈: 매주 인강 → 학습지 → 원어민 화상 → 피드백.
class HomeWeeklyLoopBand extends StatelessWidget {
  final bool compact;

  const HomeWeeklyLoopBand({Key? key, this.compact = false}) : super(key: key);

  static const List<_LoopStep> _steps = [
    _LoopStep(
      number: '1',
      title: '15분 인강',
      body: '레벨별로 매주 문법과 유용한 표현을 짧은 인강으로 먼저 듣습니다.',
      icon: Icons.play_arrow_rounded,
    ),
    _LoopStep(
      number: '2',
      title: '정리 · 학습지',
      body: '내용 정리 자료와 인터랙티브 학습지로 그 주 배운 것을 스스로 확인합니다.',
      icon: Icons.edit_note_rounded,
    ),
    _LoopStep(
      number: '3',
      title: '원어민 화상',
      body: '같은 주, 원어민 강사와 1:1 화상 수업을 예약해 배운 표현을 실제로 써봅니다.',
      icon: Icons.videocam_rounded,
    ),
    _LoopStep(
      number: '4',
      title: '강사 피드백',
      body: '수업 후 강사가 피드백을 주어, 쓴 영어를 바로 고치고 다음 주로 이어갑니다.',
      icon: Icons.chat_bubble_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Palette.grey50,
      padding: EdgeInsets.fromLTRB(
        compact ? 20 : 48,
        compact ? 36 : 56,
        compact ? 20 : 48,
        compact ? 36 : 56,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '주간 학습 루프',
            style: TextStyle(
              fontFamily: 'NotoSansKR',
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w600,
              color: Palette.darkTeal,
              letterSpacing: 0.4,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '배우고, 말하고, 고칩니다',
            style: TextStyle(
              fontFamily: 'NotoSansKR',
              fontSize: compact ? 22 : 28,
              fontWeight: FontWeight.w800,
              color: Palette.black,
            ),
          ),
          SizedBox(height: compact ? 10 : 12),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 720),
            child: Text(
              '매주 인강과 학습지로 준비하고, 원어민과 바로 써본 뒤 피드백을 받습니다. 배운 내용을 실제로 쓰고 고치는 것이 핵심입니다.',
              style: TextStyle(
                fontFamily: 'NotoSansKR',
                fontSize: compact ? 14 : 16,
                height: 1.6,
                color: Palette.grey600,
              ),
            ),
          ),
          SizedBox(height: compact ? 24 : 32),
          LayoutBuilder(
            builder: (context, constraints) {
              if (compact || constraints.maxWidth < 980) {
                return _columnSteps();
              }
              return _rowSteps();
            },
          ),
        ],
      ),
    );
  }

  Widget _rowSteps() {
    final children = <Widget>[];
    for (var i = 0; i < _steps.length; i++) {
      children.add(Expanded(child: _stepCard(_steps[i])));
      if (i < _steps.length - 1) {
        children.add(_horizontalArrow());
      }
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _columnSteps() {
    return Column(
      children: [
        for (var i = 0; i < _steps.length; i++) ...[
          _stepCard(_steps[i]),
          if (i < _steps.length - 1) _verticalArrow(),
        ],
      ],
    );
  }

  Widget _horizontalArrow() {
    return Padding(
      padding: EdgeInsets.only(top: 36, left: 4, right: 4),
      child: SizedBox(
        width: 36,
        child: Row(
          children: [
            Expanded(
              child: Container(height: 2, color: Palette.darkTeal),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              size: 22,
              color: Palette.darkTeal,
            ),
          ],
        ),
      ),
    );
  }

  Widget _verticalArrow() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Container(width: 2, height: 10, color: Palette.darkTeal),
          Icon(
            Icons.arrow_downward_rounded,
            size: 22,
            color: Palette.darkTeal,
          ),
        ],
      ),
    );
  }

  Widget _stepCard(_LoopStep step) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 18,
        compact ? 16 : 20,
        compact ? 16 : 18,
        compact ? 16 : 20,
      ),
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Palette.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Palette.navy,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  step.number,
                  style: TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Palette.white,
                  ),
                ),
              ),
              SizedBox(width: 10),
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Palette.darkTeal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  step.icon,
                  size: 22,
                  color: Palette.darkTeal,
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          Text(
            step.title,
            style: TextStyle(
              fontFamily: 'NotoSansKR',
              fontWeight: FontWeight.w800,
              fontSize: compact ? 16 : 17,
              color: Palette.navy,
            ),
          ),
          SizedBox(height: 6),
          Text(
            step.body,
            style: TextStyle(
              fontFamily: 'NotoSansKR',
              fontSize: compact ? 13 : 14,
              height: 1.55,
              color: Palette.grey600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoopStep {
  final String number;
  final String title;
  final String body;
  final IconData icon;

  const _LoopStep({
    required this.number,
    required this.title,
    required this.body,
    required this.icon,
  });
}
