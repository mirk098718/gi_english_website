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

  static const String _heroAsset = 'assets/hero-device-mockups-16x9.png';

  Widget mainImage() {
    final screen = MediaQuery.sizeOf(context);
    final heroHeight = (screen.height - 72).clamp(520.0, 720.0);
    return SizedBox(
      width: double.infinity,
      height: heroHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: Palette.navyDark),
          _heroDeviceShot(scale: 1.18, alignment: Alignment(0.78, 0)),
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Palette.navyDark,
                    Palette.navyDark.withValues(alpha: 0.82),
                    Palette.navyDark.withValues(alpha: 0.18),
                    Palette.navyDark.withValues(alpha: 0),
                  ],
                  stops: const [0.0, 0.22, 0.42, 0.58],
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
      color: Palette.navyDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(24, 28, 24, 8),
            child: _heroCopy(compact: true),
          ),
          AspectRatio(
            aspectRatio: 1.4,
            child: _heroDeviceShot(
              scale: 1.52,
              alignment: Alignment(0.86, 0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroDeviceShot({
    required double scale,
    required Alignment alignment,
  }) {
    return ClipRect(
      child: Transform.scale(
        scale: scale,
        alignment: alignment,
        child: Image.asset(
          _heroAsset,
          fit: BoxFit.cover,
          alignment: alignment,
          filterQuality: FilterQuality.high,
        ),
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
            color: Palette.secondaryLight,
          ),
        ),
        SizedBox(height: compact ? 10 : 14),
        Text(
          '인강과 화상수업으로\n영어 실력을 만듭니다',
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
          '매주 강의를 보고, 원어민과 1:1로 말하고,\n내 시간에 맞춰 수업을 예약합니다.',
          style: TextStyle(
            fontFamily: 'NotoSansKR',
            fontSize: compact ? 14 : 16,
            height: 1.6,
            color: Palette.white.withValues(alpha: 0.78),
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
                  foregroundColor: Palette.white,
                  side: BorderSide(color: Palette.white.withValues(alpha: 0.45)),
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
