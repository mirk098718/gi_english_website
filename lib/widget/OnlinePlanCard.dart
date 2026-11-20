import 'package:flutter/material.dart';
import 'package:gi_english_website/util/AppLanguage.dart';
import 'package:gi_english_website/util/Palette.dart';

/// 온라인 상품 3종 중 하나를 고르는 카드.
class OnlinePlanCard extends StatelessWidget {
  final String index;
  final String title;
  final String summary;
  final String priceLine;
  final Color color;
  final String imageAsset;
  final bool selected;
  final bool current;
  final VoidCallback onTap;

  const OnlinePlanCard({
    Key? key,
    required this.index,
    required this.title,
    required this.summary,
    required this.priceLine,
    required this.color,
    required this.imageAsset,
    required this.selected,
    required this.onTap,
    this.current = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color.withValues(alpha: 0.06) : Palette.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? color : Palette.grey200,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 1200 / 520,
                  child: Image.asset(
                    imageAsset,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      index,
                      style: TextStyle(
                        fontFamily: 'Jalnan',
                        fontSize: 13,
                        color: Palette.white,
                      ),
                    ),
                  ),
                  if (current) ...[
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Palette.secondaryDark,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tr(context, '지금 판매 중'),
                        style: TextStyle(
                          fontFamily: 'NotoSansKR',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Palette.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 12),
              Text(
                tr(context, title),
                style: TextStyle(
                  fontFamily: 'NotoSansKR',
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  height: 1.35,
                  color: Palette.grey900,
                ),
              ),
              SizedBox(height: 8),
              Text(
                tr(context, summary),
                style: TextStyle(
                  fontFamily: 'NotoSansKR',
                  fontSize: 13,
                  height: 1.45,
                  color: Palette.grey600,
                ),
              ),
              SizedBox(height: 12),
              Text(
                tr(context, priceLine),
                style: TextStyle(
                  fontFamily: 'Jalnan',
                  fontSize: 13,
                  color: color,
                ),
              ),
              SizedBox(height: 8),
              Text(
                tr(context, '내용 보기'),
                style: TextStyle(
                  fontFamily: 'NotoSansKR',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Palette.grey500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
