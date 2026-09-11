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
    if (compact) {
      return Container(
        width: double.infinity,
        color: Palette.navyDark,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(24, 28, 24, 8),
              child: _heroCopy(context, compact: true),
            ),
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Image.asset(
                _heroAsset,
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ],
        ),
      );
    }

    final heroHeight = (screen.height - 72).clamp(520.0, 720.0);
    return Container(
      width: double.infinity,
      height: heroHeight,
      color: Palette.navyDark,
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Padding(
              padding: EdgeInsets.fromLTRB(56, 40, 32, 40),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 560),
                  child: _heroCopy(context, compact: false),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Padding(
              padding: EdgeInsets.fromLTRB(0, 16, 28, 16),
              child: Image.asset(
                _heroAsset,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
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
