import 'package:flutter/material.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/ModernWidgets.dart';
import 'package:gi_english_website/widget/EasyKeyboardListener.dart';
import 'package:gi_english_website/widget/HomeAudienceCards.dart';
import 'package:gi_english_website/widget/HomeClassAlertBand.dart';
import 'package:gi_english_website/widget/HomeTrustBand.dart';
import 'package:gi_english_website/widget/HomeWeeklyLoopBand.dart';
import 'package:gi_english_website/widget/MobileSchoolLayout.dart';
import 'package:gi_english_website/widget/SiteNav.dart';
import 'package:gi_english_website/widget/WebSchoolLayout.dart';
import '../admin/page/AdminLoginPage.dart';

class SchoolMainPage extends StatefulWidget {
  const SchoolMainPage({Key? key}) : super(key: key);

  @override
  _SchoolMainPageState createState() => _SchoolMainPageState();
}

class _SchoolMainPageState extends State<SchoolMainPage> {
  final hiddenMenu = "hiddenmenu";
  final idController = TextEditingController();
  final pwController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    MediaQueryData mediaQueryData = MediaQuery.of(context);
    Size size = mediaQueryData.size;
    double width = size.width;

    Widget returnWidget;
    if (width > 768) {
      returnWidget = desktopUi(context);
    } else {
      returnWidget = mobileUi(context);
    }

    return EasyKeyboardListener(
      onValue: (String value) {
        if (value == hiddenMenu) {
          MenuUtil.pop(context);
          MenuUtil.push(context, AdminLoginPage());
        }
      },
      inputLimit: hiddenMenu.length,
      child: returnWidget,
    );
  }

  Widget desktopUi(context) {
    return WebSchoolLayout(content: scrollView());
  }

  Widget mobileUi(context) {
    return MobileSchoolLayout(content: mobileScrollView());
  }

  static const String _heroAsset = 'assets/hero-online-gleam.jpg';
  static const Color _heroBg = Color(0xFFF6F6F1);

  Widget mainImage() {
    final screen = MediaQuery.sizeOf(context);
    final heroHeight = (screen.height - 72).clamp(520.0, 720.0);
    return SizedBox(
      width: double.infinity,
      height: heroHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: _heroBg),
          Image.asset(
            _heroAsset,
            fit: BoxFit.cover,
            alignment: Alignment(0.28, 0),
            filterQuality: FilterQuality.high,
          ),
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    _heroBg,
                    _heroBg.withValues(alpha: 0.92),
                    _heroBg.withValues(alpha: 0.35),
                    _heroBg.withValues(alpha: 0),
                  ],
                  stops: const [0.0, 0.22, 0.4, 0.56],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(56, 40, 32, 40),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 520),
                child: _heroCopy(compact: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget mobileMainImage() {
    return Container(
      width: double.infinity,
      color: _heroBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(24, 28, 24, 8),
            child: _heroCopy(compact: true),
          ),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.asset(
              _heroAsset,
              fit: BoxFit.cover,
              alignment: Alignment(0.55, 0),
              filterQuality: FilterQuality.high,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroCopy({required bool compact}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '온라인 영어 · 원어민 1:1',
          style: TextStyle(
            fontFamily: 'NotoSansKR',
            fontSize: compact ? 12 : 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
            color: Palette.darkTeal,
          ),
        ),
        SizedBox(height: compact ? 10 : 14),
        Text(
          '인강으로 배운 영어,\n원어민 화상 수업에서\n완벽히 내 것으로 만듭니다',
          style: TextStyle(
            fontFamily: 'NotoSansKR',
            fontSize: compact ? 24 : 36,
            fontWeight: FontWeight.w800,
            height: 1.28,
            color: Palette.navy,
          ),
        ),
        SizedBox(height: compact ? 12 : 16),
        Text(
          '매주 강의를 보고, 연습문제를 푼 후,\n내 시간에 맞춰 원어민과 1:1 수업을 예약합니다.',
          style: TextStyle(
            fontFamily: 'NotoSansKR',
            fontSize: compact ? 14 : 16,
            height: 1.6,
            color: Palette.grey700,
          ),
        ),
        SizedBox(height: compact ? 20 : 28),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              height: compact ? 42 : 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Palette.darkTeal,
                  foregroundColor: Palette.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 22),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => SiteNav.openPlacement(context),
                child: Text(
                  '무료 체험하기',
                  style: TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 13 : 14,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: compact ? 42 : 46,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Palette.navy,
                  side: BorderSide(color: Palette.navy.withValues(alpha: 0.28)),
                  padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 22),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => SiteNav.goCourses(context),
                child: Text(
                  '과정 보기',
                  style: TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontWeight: FontWeight.w600,
                    fontSize: compact ? 13 : 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }


  Widget scrollView() {
    return SingleChildScrollView(
      child: Container(
        color: Palette.background,
        child: Column(
          children: [
            mainImage(),
            HomeWeeklyLoopBand(),
            HomeClassAlertBand(),
            HomeAudienceCards(),
            HomeTrustBand(),
            ModernWidgets.modernFooter(),
          ],
        ),
      ),
    );
  }

  // mobile

  Widget mobileScrollView() {
    return SingleChildScrollView(
      child: Container(
        child: Column(
          children: [
            mobileMainImage(),
            HomeWeeklyLoopBand(compact: true),
            HomeClassAlertBand(compact: true),
            HomeAudienceCards(compact: true),
            HomeTrustBand(compact: true),
          ],
        ),
      ),
    );
  }

}
