import 'package:flutter/material.dart';
import 'package:gi_english_website/util/ModernWidgets.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/widget/AcademyBulletinBoards.dart';
import 'package:gi_english_website/widget/AcademyHomeCards.dart';
import 'package:gi_english_website/widget/AcademyLmsLinks.dart';
import 'package:gi_english_website/widget/MobileSchoolLayout.dart';
import 'package:gi_english_website/widget/WebSchoolLayout.dart';

class SchoolAboutPage extends StatelessWidget {
  const SchoolAboutPage({Key? key}) : super(key: key);

  static const String _heroAsset = 'assets/academy-hero-about.png';

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width > 768) {
      return WebSchoolLayout(content: _desktopScroll(context));
    }
    return MobileSchoolLayout(content: _mobileScroll(context));
  }

  Widget _desktopScroll(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        color: Palette.background,
        child: Column(
          children: [
            _hero(context, compact: false),
            AcademyHomeCards(),
            AcademyBulletinBoards(),
            _philosophy(compact: false),
            ModernWidgets.modernFooter(),
          ],
        ),
      ),
    );
  }

  Widget _mobileScroll(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _hero(context, compact: true),
          AcademyHomeCards(compact: true),
          AcademyBulletinBoards(compact: true),
          _philosophy(compact: true),
        ],
      ),
    );
  }

  Widget _hero(BuildContext context, {required bool compact}) {
    final screen = MediaQuery.sizeOf(context);
    final height = compact
        ? 520.0
        : (screen.height - 72).clamp(560.0, 760.0);

    return SizedBox(
      width: double.infinity,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            _heroAsset,
            fit: BoxFit.cover,
            alignment: const Alignment(0.28, 0),
            filterQuality: FilterQuality.high,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                stops: const [0.0, 0.32, 0.58, 1.0],
                colors: [
                  Palette.navy.withValues(alpha: compact ? 0.90 : 0.88),
                  Palette.navy.withValues(alpha: compact ? 0.64 : 0.58),
                  Palette.navy.withValues(alpha: compact ? 0.30 : 0.22),
                  Palette.navy.withValues(alpha: compact ? 0.16 : 0.08),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 24 : 56,
              compact ? 36 : 48,
              compact ? 24 : 40,
              compact ? 28 : 48,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: compact ? 520 : 560),
                child: _heroCopy(context, compact: compact),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroCopy(BuildContext context, {required bool compact}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '파주 운정 · 초중등 오프라인',
          style: TextStyle(
            fontFamily: 'NotoSansKR',
            fontSize: compact ? 12 : 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
            color: Palette.secondaryLight,
          ),
        ),
        SizedBox(height: compact ? 10 : 14),
        Text(
          '글림아일랜드 파주 캠퍼스에서\n영어를 말하고 자랍니다',
          style: TextStyle(
            fontFamily: 'NotoSansKR',
            fontSize: compact ? 26 : 40,
            fontWeight: FontWeight.w800,
            height: 1.28,
            color: Palette.white,
          ),
        ),
        SizedBox(height: compact ? 12 : 16),
        Text(
          '초등·중등·고등 대상 원어민 회화,\n학습과 액티비티, 그리고 내신 및 입시가 함께하는 현장입니다.',
          style: TextStyle(
            fontFamily: 'NotoSansKR',
            fontSize: compact ? 14 : 16,
            height: 1.6,
            color: Palette.white.withValues(alpha: 0.78),
          ),
        ),
        SizedBox(height: compact ? 20 : 28),
        AcademyLmsLinks(
          showHeading: false,
          onDark: true,
          compact: compact,
          centered: true,
        ),
      ],
    );
  }

  Widget _philosophy({required bool compact}) {
    return Container(
      width: double.infinity,
      color: Palette.white,
      padding: EdgeInsets.fromLTRB(
        compact ? 24 : 80,
        compact ? 40 : 72,
        compact ? 24 : 80,
        compact ? 48 : 80,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 860),
          child: Text(
            '"GLEAM ISLAND는 반짝이는 섬이라는 뜻으로, 뉴질랜드 교육 철학을 바탕으로 한 이름입니다. 자유로운 탐구와 토론, 놀이와 학습이 함께하는 소수정예 영어 현장을 지향합니다."',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'NotoSansKR',
              fontSize: compact ? 20 : 28,
              fontWeight: FontWeight.w600,
              height: 1.7,
              color: Palette.navy,
            ),
          ),
        ),
      ),
    );
  }
}
