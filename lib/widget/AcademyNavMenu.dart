import 'package:flutter/material.dart';
import 'package:gi_english_website/util/AppLanguage.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/widget/SiteNav.dart';

/// 모바일에서 「글림아일랜드 어학원」을 누르면 열리는 하위 메뉴.
class AcademyNavMenu extends StatelessWidget {
  final ValueChanged<SiteNavItem> onSelect;

  const AcademyNavMenu({Key? key, required this.onSelect}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Palette.white,
      child: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.fromLTRB(4, 4, 4, 12),
        children: [
          for (final group in SiteNav.academyGroups) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Text(
                tr(context, group.title),
                style: TextStyle(
                  fontFamily: "NotoSansKR",
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Palette.grey500,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            for (final item in group.items)
              InkWell(
                onTap: () => onSelect(item),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          tr(context, item.label),
                          style: TextStyle(
                            fontFamily: "NotoSansKR",
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Palette.black,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: Palette.grey400,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
