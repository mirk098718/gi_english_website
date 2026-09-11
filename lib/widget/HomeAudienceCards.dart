import 'package:flutter/material.dart';
import 'package:gi_english_website/class/OnlineCourse.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/widget/SiteNav.dart';

class HomeAudienceCards extends StatelessWidget {
  final bool compact;

  const HomeAudienceCards({Key? key, this.compact = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final items = _onlineItems(context);
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
            '대상별 과정',
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
            '지금 필요한 영어부터 고르세요',
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
              itemCount: items.length,
              separatorBuilder: (_, __) => SizedBox(width: compact ? 12 : 16),
              itemBuilder: (context, index) => _card(context, items[index]),
            ),
          ),
          SizedBox(height: compact ? 28 : 36),
          _campusShortcut(context),
        ],
      ),
    );
  }

  List<_AudienceItem> _onlineItems(BuildContext context) {
    OnlineCourse course(String id) => OnlineCourse.findById(id)!;
    return [
      _AudienceItem(
        title: '왕초보',
        subtitle: '파닉스부터 차근차근',
        imageAsset: 'assets/audience-beginner.png',
        onTap: () => SiteNav.goCourse(context, course('beginner_phonics')),
      ),
      _AudienceItem(
        title: '기초',
        subtitle: '문법과 일상 회화',
        imageAsset: 'assets/audience-basic.png',
        onTap: () =>
            SiteNav.goCourse(context, course('basic_grammar_speaking')),
      ),
      _AudienceItem(
        title: '중급',
        subtitle: '자연스럽게 말하기',
        imageAsset: 'assets/audience-intermediate.png',
        onTap: () => SiteNav.goCourse(
            context, course('intermediate_grammar_speaking')),
      ),
      _AudienceItem(
        title: '비즈니스',
        subtitle: '회의·이메일 실전',
        imageAsset: 'assets/audience-business.png',
        onTap: () => SiteNav.goCourse(context, course('business_english')),
      ),
      _AudienceItem(
        title: '고급회화',
        subtitle: '토론과 프리미엄 스피킹',
        imageAsset: 'assets/audience-advanced.png',
        onTap: () =>
            SiteNav.goCourse(context, course('advanced_premium_speaking')),
      ),
    ];
  }

  Widget _campusShortcut(BuildContext context) {
    final imageWidth = compact ? 112.0 : 168.0;
    final imageHeight = compact ? 84.0 : 112.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '학원',
          style: TextStyle(
            fontFamily: 'NotoSansKR',
            fontSize: compact ? 12 : 13,
            fontWeight: FontWeight.w600,
            color: Palette.darkTeal,
            letterSpacing: 0.4,
          ),
        ),
        SizedBox(height: 12),
        Material(
          color: Palette.white,
          child: InkWell(
            onTap: () => SiteNav.goAcademy(context),
            borderRadius: BorderRadius.circular(12),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Palette.grey200),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(11),
                    ),
                    child: SizedBox(
                      width: imageWidth,
                      height: imageHeight,
                      child: Image.asset(
                        'assets/audience-campus.png',
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                      ),
                    ),
                  ),
                  Container(
                    width: 3,
                    height: imageHeight,
                    color: Palette.darkTeal,
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        compact ? 14 : 20,
                        compact ? 12 : 16,
                        compact ? 10 : 16,
                        compact ? 12 : 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '초중등 파주캠퍼스 바로가기',
                            style: TextStyle(
                              fontFamily: 'NotoSansKR',
                              fontWeight: FontWeight.w800,
                              fontSize: compact ? 16 : 18,
                              color: Palette.navy,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '오프라인 초중등 회화 · 파주 운정',
                            style: TextStyle(
                              fontFamily: 'NotoSansKR',
                              fontSize: compact ? 12 : 13,
                              color: Palette.grey600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(right: compact ? 10 : 16),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: compact ? 14 : 16,
                      color: Palette.grey500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _card(BuildContext context, _AudienceItem item) {
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

class _AudienceItem {
  final String title;
  final String subtitle;
  final String imageAsset;
  final VoidCallback onTap;

  const _AudienceItem({
    required this.title,
    required this.subtitle,
    required this.imageAsset,
    required this.onTap,
  });
}
