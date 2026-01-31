import 'package:flutter/material.dart';
import 'Palette.dart';

class ModernWidgets {
  // 현대적인 카드 위젯
  static Widget modernCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? backgroundColor,
    double? elevation,
    BorderRadius? borderRadius,
  }) {
    return Container(
      margin: margin ?? EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: backgroundColor ?? Palette.surface,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Palette.grey200.withValues(alpha:0.5),
            spreadRadius: 0,
            blurRadius: elevation ?? 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.all(20),
        child: child,
      ),
    );
  }

  // 현대적인 버튼
  static Widget modernButton({
    required String text,
    required VoidCallback onPressed,
    Color? backgroundColor,
    Color? textColor,
    EdgeInsetsGeometry? padding,
    double? borderRadius,
    double? fontSize,
    FontWeight? fontWeight,
    bool isOutlined = false,
    IconData? icon,
  }) {
    final bgColor = backgroundColor ?? Palette.primary;
    final txtColor = textColor ?? Palette.white;

    Widget buttonChild = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, color: txtColor, size: fontSize ?? 16),
          SizedBox(width: 8),
        ],
        Text(
          text,
          style: TextStyle(
            color: txtColor,
            fontSize: fontSize ?? 16,
            fontWeight: fontWeight ?? FontWeight.w600,
            fontFamily: "NotoSansKR",
          ),
        ),
      ],
    );

    if (isOutlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding:
              padding ?? EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 12),
          ),
          side: BorderSide(color: bgColor, width: 2),
        ),
        child: buttonChild,
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        padding: padding ?? EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 12),
        ),
        elevation: 2,
        shadowColor: bgColor.withValues(alpha:0.3),
      ),
      child: buttonChild,
    );
  }

  // 현대적인 텍스트 필드
  static Widget modernTextField({
    required TextEditingController controller,
    String? labelText,
    String? hintText,
    IconData? prefixIcon,
    IconData? suffixIcon,
    VoidCallback? onSuffixIconPressed,
    bool obscureText = false,
    ValueChanged<String>? onChanged,
    EdgeInsetsGeometry? margin,
  }) {
    return Container(
      margin: margin ?? EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        onChanged: onChanged,
        style: TextStyle(
          fontFamily: "NotoSansKR",
          fontSize: 16,
          color: Palette.grey800,
        ),
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: Palette.grey500)
              : null,
          suffixIcon: suffixIcon != null
              ? IconButton(
                  icon: Icon(suffixIcon, color: Palette.grey500),
                  onPressed: onSuffixIconPressed,
                )
              : null,
          filled: true,
          fillColor: Palette.grey50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Palette.grey200, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Palette.primary, width: 2),
          ),
          labelStyle: TextStyle(
            fontFamily: "NotoSansKR",
            color: Palette.grey600,
          ),
          hintStyle: TextStyle(
            fontFamily: "NotoSansKR",
            color: Palette.grey400,
          ),
        ),
      ),
    );
  }

  // 현대적인 메뉴 아이템
  static Widget modernMenuItem({
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
    IconData? icon,
    Color? selectedColor,
  }) {
    final color =
        isSelected ? (selectedColor ?? Palette.primary) : Palette.grey600;
    final bgColor = isSelected
        ? (selectedColor ?? Palette.primary).withValues(alpha:0.1)
        : Colors.transparent;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: color, size: 20),
                SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontFamily: "NotoSansKR",
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 현대적인 섹션 헤더
  static Widget modernSectionHeader({
    required String title,
    String? subtitle,
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      padding: padding ?? EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Palette.grey900,
              fontFamily: "NotoSansKR",
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                color: Palette.grey600,
                fontFamily: "NotoSansKR",
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 현대적인 구분선
  static Widget modernDivider({
    EdgeInsetsGeometry? margin,
    Color? color,
    double? thickness,
  }) {
    return Container(
      margin: margin ?? EdgeInsets.symmetric(vertical: 16),
      height: thickness ?? 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            color ?? Palette.grey200,
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  // 현대적인 정보 카드
  static Widget modernInfoCard({
    required String title,
    required String content,
    IconData? icon,
    Color? accentColor,
    EdgeInsetsGeometry? margin,
  }) {
    return modernCard(
      margin: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (accentColor ?? Palette.primary).withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: accentColor ?? Palette.primary,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Palette.grey900,
                    fontFamily: "NotoSansKR",
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Palette.grey700,
              fontFamily: "NotoSansKR",
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // 현대적인 푸터
  static Widget modernFooter() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Palette.secondaryDark, Color(0xFF022C22)],
        ),
      ),
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Gi Gleam Island 어학원 파주",
            style: TextStyle(
              color: Palette.white,
              fontFamily: "NotoSansKR",
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          SizedBox(height: 12),
          Text(
            "경기도 파주시 해올2길 2 태산 W 타워 7층 701~703호 (다율동 1044)\n"
            "문의 : 031 942 0908\n"
            "email : gienglish.paju@gmail.com\n"
            "사업자명 : 글림아일랜드 어학원 / 대표자명 : 김남희",
            style: TextStyle(
              color: Palette.grey300,
              fontFamily: "NotoSansKR",
              fontSize: 14,
              height: 1.5,
            ),
          ),
          SizedBox(height: 16),
          modernDivider(
            color: Palette.white.withValues(alpha:0.3),
            margin: EdgeInsets.symmetric(vertical: 8),
          ),
          Text(
            "Copyright ⓒ 글림아일랜드어학원",
            style: TextStyle(
              color: Palette.grey400,
              fontFamily: "NotoSansKR",
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // 모바일용 현대적인 푸터
  static Widget modernMobileFooter() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Palette.secondaryDark, Color(0xFF022C22)],
        ),
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Gi Gleam Island 어학원 파주",
            style: TextStyle(
              color: Palette.white,
              fontFamily: "NotoSansKR",
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            "경기도 파주시 해올2길 2 태산 W 타워 7층",
            style: TextStyle(
              color: Palette.grey300,
              fontFamily: "NotoSansKR",
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            "ⓒ 글림아일랜드교육",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Palette.grey400,
              fontFamily: "NotoSansKR",
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
