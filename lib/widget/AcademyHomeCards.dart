import 'package:flutter/material.dart';
import 'package:gi_english_website/pages/SchoolCodingPage.dart';
import 'package:gi_english_website/widget/AcademyHeroBanner.dart';
import 'package:gi_english_website/pages/SchoolCurriculumElePage.dart';
import 'package:gi_english_website/pages/SchoolCurriculumHighSchoolPage.dart';
import 'package:gi_english_website/pages/SchoolCurriculumMiddleSchoolPage.dart';
import 'package:gi_english_website/pages/SchoolMapPage.dart';
import 'package:gi_english_website/pages/SchoolNZPage.dart';
import 'package:gi_english_website/pages/SchoolTeachersPage.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/Palette.dart';

class AcademyHomeCards extends StatelessWidget {
  final bool compact;

  const AcademyHomeCards({Key? key, this.compact = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final programs = _programItems(context);
    final guides = _guideItems(context);
    return Container(
      width: double.infinity,
      color: Palette.white,
      padding: EdgeInsets.fromLTRB(
        compact ? 20 : 48,
        compact ? 36 : 56,
        compact ? 20 : 48,
        compact ? 28 : 48,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '프로그램',
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
            '파주 캠퍼스에서 고를 수 있는 수업',
            style: TextStyle(
              fontFamily: 'NotoSansKR',
              fontSize: compact ? 22 : 28,
              fontWeight: FontWeight.w800,
              color: Palette.black,
            ),
          ),
          SizedBox(height: compact ? 20 : 28),
          SizedBox(
            height: compact ? 288 : 332,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: programs.length,
              separatorBuilder: (_, __) => SizedBox(width: compact ? 12 : 16),
              itemBuilder: (context, index) => _card(context, programs[index]),
            ),
          ),
          SizedBox(height: compact ? 28 : 36),
          Text(
            '학원 안내',
            style: TextStyle(
              fontFamily: 'NotoSansKR',
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w600,
              color: Palette.darkTeal,
              letterSpacing: 0.4,
            ),
          ),
          SizedBox(height: 12),
          SizedBox(
            height: compact ? 288 : 332,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: guides.length,
              separatorBuilder: (_, __) => SizedBox(width: compact ? 12 : 16),
              itemBuilder: (context, index) => _card(context, guides[index]),
            ),
          ),
        ],
      ),
    );
  }

  List<_AcademyItem> _programItems(BuildContext context) {
    return [
      _AcademyItem(
        title: '초등부',
        subtitle: '예비초~초6 · 오후 수업',
        imageAsset: AcademyHeroBanner.elementary,
        onTap: () => MenuUtil.push(context, SchoolCurriculumElePage()),
      ),
      _AcademyItem(
        title: '중등부',
        subtitle: '예비중·중학생 · 저녁 수업',
        imageAsset: AcademyHeroBanner.middle,
        onTap: () =>
            MenuUtil.push(context, SchoolCurriculumMiddleSchoolPage()),
      ),
      _AcademyItem(
        title: '고등부',
        subtitle: '예비고·고등학생 · 곧 공개',
        imageAsset: AcademyHeroBanner.high,
        onTap: () => MenuUtil.push(context, SchoolCurriculumHighSchoolPage()),
      ),
      _AcademyItem(
        title: '선택 프로그램',
        subtitle: '코딩 · 액티비티',
        imageAsset: AcademyHeroBanner.coding,
        onTap: () => MenuUtil.push(context, SchoolCodingPage()),
      ),
      _AcademyItem(
        title: '뉴질랜드',
        subtitle: '해외 연계 프로그램',
        imageAsset: AcademyHeroBanner.nz,
        onTap: () => MenuUtil.push(context, SchoolNZPage()),
      ),
    ];
  }

  List<_AcademyItem> _guideItems(BuildContext context) {
    return [
      _AcademyItem(
        title: '교원/운영시스템 소개',
        subtitle: '원어민 · 한국인 선생님 · 운영시스템',
        imageAsset: AcademyHeroBanner.teachers,
        onTap: () => MenuUtil.push(context, SchoolTeachersPage()),
      ),
      _AcademyItem(
        title: '상담/오시는 길',
        subtitle: '레벨 상담 · 파주 운정',
        imageAsset: AcademyHeroBanner.map,
        onTap: () => MenuUtil.push(context, SchoolMapPage()),
      ),
    ];
  }

  Widget _card(BuildContext context, _AcademyItem item) {
    final width = compact ? 196.0 : 232.0;
    return SizedBox(
      width: width,
      child: Material(
        color: Palette.white,
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Palette.grey200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(11)),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Image.asset(
                      item.imageAsset,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),
                  ),
                ),
                Container(
                  height: 3,
                  color: Palette.darkTeal,
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontFamily: 'NotoSansKR',
                          fontWeight: FontWeight.w800,
                          fontSize: compact ? 16 : 17,
                          color: Palette.navy,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          fontFamily: 'NotoSansKR',
                          fontSize: compact ? 12 : 13,
                          color: Palette.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AcademyItem {
  final String title;
  final String subtitle;
  final String imageAsset;
  final VoidCallback onTap;

  const _AcademyItem({
    required this.title,
    required this.subtitle,
    required this.imageAsset,
    required this.onTap,
  });
}
