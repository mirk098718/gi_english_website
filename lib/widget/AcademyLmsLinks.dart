import 'package:flutter/material.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/UrlIUtil.dart';

/// 파주 캠퍼스 초등·중등 외부 LMS 바로가기.
class AcademyLmsLinks extends StatelessWidget {
  final bool showHeading;
  final bool onDark;
  final bool compact;
  final bool centered;

  const AcademyLmsLinks({
    Key? key,
    this.showHeading = true,
    this.onDark = false,
    this.compact = false,
    this.centered = false,
  }) : super(key: key);

  static const String _middleUrl = 'http://gienglish.theclip.net/';
  static const String _eleUrl =
      'https://www.trophy9.com/account/account.do?stdcmd=sign&url=%2Fdefault%2Edo%3F';

  @override
  Widget build(BuildContext context) {
    final fill = centered;
    final ele = _cta(
      title: '초등부 온라인 바로가기',
      subtitle: 'Trophy9 학습실',
      onTap: () => UrlUtil.open(_eleUrl),
      primary: true,
      fill: fill,
    );
    final middle = _cta(
      title: '중등부 온라인 바로가기',
      subtitle: 'CLIP 학습실',
      onTap: () => UrlUtil.open(_middleUrl),
      primary: false,
      fill: fill,
    );

    final Widget buttons;
    if (centered) {
      buttons = Row(
        children: [
          Expanded(child: ele),
          SizedBox(width: compact ? 8 : 10),
          Expanded(child: middle),
        ],
      );
    } else {
      buttons = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ele,
          SizedBox(width: 10),
          middle,
        ],
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: showHeading ? 24 : 0),
      child: SizedBox(
        width: centered ? double.infinity : null,
        child: Column(
          crossAxisAlignment: centered
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            if (showHeading) ...[
              Text(
                '초등·중등 온라인 학습',
                style: TextStyle(
                  fontFamily: 'NotoSansKR',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Palette.navy,
                ),
              ),
              SizedBox(height: 10),
            ],
            buttons,
          ],
        ),
      ),
    );
  }

  Widget _cta({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool primary,
    required bool fill,
  }) {
    final Color background;
    final Color foreground;
    final BorderSide? border;

    if (onDark) {
      background = primary ? Palette.darkTeal : Palette.white;
      foreground = primary ? Palette.white : Palette.navy;
      border = primary
          ? BorderSide(color: Palette.secondaryLight.withValues(alpha: 0.55))
          : null;
    } else {
      background = primary ? Palette.darkTeal : Palette.navy;
      foreground = Palette.white;
      border = null;
    }

    final label = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'NotoSansKR',
            fontWeight: FontWeight.w800,
            fontSize: compact ? 11 : 14,
            height: 1.2,
            color: foreground,
          ),
        ),
        SizedBox(height: 2),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'NotoSansKR',
            fontWeight: FontWeight.w500,
            fontSize: compact ? 10 : 12,
            color: foreground.withValues(alpha: 0.82),
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      label: '$title $subtitle',
      excludeSemantics: true,
      child: Material(
        color: background,
        elevation: onDark ? 2 : 0,
        shadowColor: Palette.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            constraints: BoxConstraints(
              minHeight: compact ? 48 : 58,
              minWidth: fill ? 0 : (compact ? 160 : 228),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 18,
              vertical: compact ? 8 : 12,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: border == null ? null : Border.fromBorderSide(border),
            ),
            child: Row(
              mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
              children: [
                Icon(
                  Icons.open_in_new,
                  size: compact ? 14 : 20,
                  color: foreground,
                ),
                SizedBox(width: compact ? 6 : 10),
                if (fill) Expanded(child: label) else label,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
