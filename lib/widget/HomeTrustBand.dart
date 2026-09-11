import 'package:flutter/material.dart';
import 'package:gi_english_website/util/Palette.dart';

/// 홈: 캠퍼스·원어민 강사 신뢰 밴드.
class HomeTrustBand extends StatelessWidget {
  final bool compact;

  const HomeTrustBand({Key? key, this.compact = false}) : super(key: key);

  static const List<_TrustFact> _facts = [
    _TrustFact(
      title: '파주운정 캠퍼스',
      body: '초등, 중등, 고등 소수정예 영어 현장을 운영하고 있습니다.',
    ),
    _TrustFact(
      title: '검증된 원어민 강사 풀',
      body:
          '오프라인 학원 현장에서 철저히 훈련받은 원어민 강사, 또는 현지에 거주하며 영어 강의 자격을 갖춘 원어민을 검증한 뒤에만 수업에 배치합니다.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Palette.navyDark,
      padding: EdgeInsets.fromLTRB(
        compact ? 20 : 48,
        compact ? 40 : 64,
        compact ? 20 : 48,
        compact ? 40 : 64,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              _wordmark(),
              SizedBox(height: compact ? 28 : 40),
              compact ? _stackedFacts() : _rowFacts(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rowFacts() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < _facts.length; i++) ...[
            if (i > 0) SizedBox(width: 24),
            Expanded(child: _fact(_facts[i])),
          ],
        ],
      ),
    );
  }

  Widget _stackedFacts() {
    return Column(
      children: [
        for (var i = 0; i < _facts.length; i++) ...[
          if (i > 0) SizedBox(height: 16),
          _fact(_facts[i]),
        ],
      ],
    );
  }

  Widget _fact(_TrustFact fact) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        compact ? 18 : 22,
        compact ? 18 : 22,
        compact ? 18 : 22,
        compact ? 18 : 22,
      ),
      decoration: BoxDecoration(
        color: Palette.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Palette.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _certMark(),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  fact.title,
                  style: TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontSize: compact ? 17 : 19,
                    fontWeight: FontWeight.w800,
                    color: Palette.secondaryLight,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            fact.body,
            style: TextStyle(
              fontFamily: 'NotoSansKR',
              fontSize: compact ? 13 : 14,
              height: 1.55,
              color: Palette.white.withValues(alpha: 0.78),
            ),
          ),
        ],
      ),
    );
  }

  Widget _wordmark() {
    return Semantics(
      label: 'Gleam Education',
      image: true,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(compact ? 12 : 14),
            decoration: BoxDecoration(
              color: Color(0xFFF7F4EA),
              borderRadius: BorderRadius.circular(16),
            ),
            child: SizedBox(
              height: compact ? 88 : 112,
              width: compact ? 92 : 118,
              child: Image.asset(
                'assets/gleamEducationLogo.png',
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
          SizedBox(height: 14),
          Text(
            'Gleam Education',
            style: TextStyle(
              fontFamily: 'NotoSansKR',
              fontSize: compact ? 18 : 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: Palette.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _certMark() {
    final size = compact ? 22.0 : 24.0;
    return Semantics(
      label: '인증',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Palette.secondaryLight.withValues(alpha: 0.16),
          border: Border.all(color: Palette.secondaryLight, width: 1.5),
        ),
        child: Icon(
          Icons.check_rounded,
          size: compact ? 14 : 16,
          color: Palette.secondaryLight,
        ),
      ),
    );
  }
}

class _TrustFact {
  final String title;
  final String body;

  const _TrustFact({
    required this.title,
    required this.body,
  });
}
