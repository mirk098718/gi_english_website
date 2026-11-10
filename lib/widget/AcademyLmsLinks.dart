import 'package:flutter/material.dart';
import 'package:gi_english_website/util/AppLanguage.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/UrlIUtil.dart';

/// 파주 캠퍼스 초등·중등 외부 LMS 바로가기.
class AcademyLmsLinks extends StatelessWidget {
  final bool showHeading;
  final bool onDark;
  final bool compact;
  final bool centered;
  final bool showElementary;
  final bool showMiddle;

  const AcademyLmsLinks({
    Key? key,
    this.showHeading = true,
    this.onDark = false,
    this.compact = false,
    this.centered = false,
    this.showElementary = true,
    this.showMiddle = true,
  })  : assert(showElementary || showMiddle),
        super(key: key);

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

    final items = <Widget>[
      if (showElementary) ele,
      if (showMiddle) middle,
    ];
    final gap = SizedBox(width: centered && compact ? 8 : 10);
    final Widget buttons = Row(
      mainAxisSize: centered ? MainAxisSize.max : MainAxisSize.min,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) gap,
          if (centered) Expanded(child: items[i]) else items[i],
        ],
      ],
    );

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
                tr(context, "초등·중등 온라인 학습"),
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

    Widget line(String text, TextStyle style, double lineHeight) {
      final textWidget = Text(
        text,
        maxLines: 1,
        softWrap: false,
        overflow: fill ? TextOverflow.visible : TextOverflow.ellipsis,
        style: style,
      );
      if (!fill) return textWidget;
      return SizedBox(
        width: double.infinity,
        height: lineHeight,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: textWidget,
        ),
      );
    }

    final label = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        line(
          title,
          TextStyle(
            fontFamily: 'NotoSansKR',
            fontWeight: FontWeight.w800,
            fontSize: compact ? 11 : 14,
            height: 1.2,
            color: foreground,
          ),
          compact ? 14 : 17,
        ),
        SizedBox(height: 2),
        line(
          subtitle,
          TextStyle(
            fontFamily: 'NotoSansKR',
            fontWeight: FontWeight.w500,
            fontSize: compact ? 10 : 12,
            color: foreground.withValues(alpha: 0.82),
          ),
          compact ? 12 : 15,
        ),
      ],
    );

    return Semantics(
      button: true,
      label: '$title $subtitle',
      excludeSemantics: true,
      child: Material(
        color: background,
        elevation: 2,
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
