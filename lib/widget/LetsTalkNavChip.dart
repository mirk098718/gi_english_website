import 'package:flutter/material.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/widget/SiteNav.dart';

class LetsTalkNavChip extends StatelessWidget {
  final bool compact;
  final VoidCallback? onTap;

  const LetsTalkNavChip({
    Key? key,
    this.compact = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: "Let's Talk",
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap ?? () => SiteNav.goLetsTalk(context),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 14,
              vertical: compact ? 6 : 8,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: Palette.talkGradient,
              boxShadow: [
                BoxShadow(
                  color: Palette.talkCoral.withValues(alpha: 0.28),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.forum_rounded,
                  size: compact ? 14 : 16,
                  color: Palette.white,
                ),
                SizedBox(width: compact ? 5 : 6),
                Text(
                  "Let's Talk",
                  style: TextStyle(
                    fontFamily: 'Jalnan',
                    fontSize: compact ? 12 : 13,
                    color: Palette.white,
                    height: 1,
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
