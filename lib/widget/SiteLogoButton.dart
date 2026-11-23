import 'package:flutter/material.dart';
import 'package:gi_english_website/pages/SchoolAboutPage.dart';
import 'package:gi_english_website/pages/SchoolMainPage.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/widget/GleamMark.dart';

/// 로그인된 계정의 좌측 상단 로고. 온라인 메인으로 보낸다.
class SiteLogo {
  static void go(BuildContext context) {
    if (AuthService.currentUser != null) {
      MenuUtil.push(context, const SchoolMainPage());
      return;
    }
    MenuUtil.push(context, const SchoolAboutPage());
  }

  /// 관리자 앱바 왼쪽. 로고는 온라인 메인으로, 뒤로가기는 그대로 둔다.
  static Widget staffLeading(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SiteLogoButton(onDark: true),
        if (canPop) const BackButton(),
      ],
    );
  }

  static double staffLeadingWidth(BuildContext context) {
    return Navigator.of(context).canPop() ? 104 : 52;
  }
}

class SiteLogoButton extends StatelessWidget {
  final bool onDark;

  const SiteLogoButton({Key? key, this.onDark = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => SiteLogo.go(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Center(
          child: GleamMark(height: 20, lightPlate: onDark),
        ),
      ),
    );
  }
}
