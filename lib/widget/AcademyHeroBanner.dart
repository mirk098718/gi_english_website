import 'package:flutter/material.dart';
import 'package:gi_english_website/pages/SchoolConsultationPage.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/Palette.dart';

/// 학원 하위 메뉴 히어로. 16:9 사진을 배너 높이로 자르고 글이 읽히게 어둡게 깐다.
class AcademyHeroBanner extends StatelessWidget {
  static const String about = 'assets/academy-hero-about.png';
  static const String teachers = 'assets/academy-hero-teachers.png';
  static const String system = 'assets/academy-hero-system.png';
  static const String map = 'assets/academy-hero-map.png';
  static const String program = 'assets/academy-hero-program.png';
  static const String coding = 'assets/academy-hero-coding.png';
  static const String nz = 'assets/academy-hero-nz.png';
  static const String elementary = 'assets/academy-hero-ele.png';
  static const String middle = 'assets/academy-hero-middle.png';
  static const String high = 'assets/academy-hero-high.png';
  static const String community = 'assets/academy-hero-community.png';

  final String asset;
  final String title;
  final String buttonLabel;
  final VoidCallback? onButtonPressed;
  final bool compact;

  const AcademyHeroBanner({
    Key? key,
    required this.asset,
    required this.title,
    this.buttonLabel = '상담신청',
    this.onButtonPressed,
    this.compact = false,
  }) : super(key: key);

  static Widget photo(String asset, {bool compact = false}) {
    final height = compact ? 260.0 : 460.0;
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            asset,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Palette.navy.withValues(alpha: compact ? 0.52 : 0.42),
                  Palette.navy.withValues(alpha: 0.08),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: compact ? Alignment.centerLeft : Alignment.bottomLeft,
      children: [
        photo(asset, compact: compact),
        Padding(
          padding: EdgeInsets.only(
            left: compact ? 20 : 40,
            bottom: compact ? 0 : 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Palette.white,
                  fontSize: compact ? 20 : 30,
                  fontFamily: 'LucidaCalligraphy',
                ),
              ),
              SizedBox(height: compact ? 10 : 20),
              SizedBox(
                width: 150,
                height: 40,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: compact ? Palette.accent : Palette.black,
                    foregroundColor: Palette.black,
                  ),
                  onPressed: onButtonPressed ??
                      () => MenuUtil.push(context, SchoolConsultationPage()),
                  child: Text(
                    buttonLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Jalnan',
                      color: Palette.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
