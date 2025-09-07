import 'package:flutter/material.dart';

class Palette {
  // 기본 색상
  static const Color white = Colors.white;
  static const Color black = Color(0xFF1A1A1A);
  static const Color transparent = Colors.transparent;

  // 메인 브랜드 색상 - 현대적이고 세련된 블루/그린 계열
  static const Color primary = Color(0xFF2563EB); // 모던 블루
  static const Color primaryLight = Color(0xFF60A5FA); // 밝은 블루
  static const Color primaryDark = Color(0xFF1E40AF); // 어두운 블루
  static const Color secondary = Color(0xFF059669); // 세련된 에메랄드 그린
  static const Color secondaryLight = Color(0xFF34D399); // 밝은 그린
  static const Color secondaryDark = Color(0xFF047857); // 어두운 그린

  // 액센트 색상
  static const Color accent = Color(0xFF8B5CF6); // 세련된 보라
  static const Color accentLight = Color(0xFFA78BFA);
  static const Color warning = Color(0xFFF59E0B); // 모던 오렌지
  static const Color danger = Color(0xFFEF4444); // 모던 레드
  static const Color success = Color(0xFF10B981); // 성공 그린

  // 헤더/푸터용 진한 청록색
  static const Color darkTeal = Color(0xFF0F766E); // 진한 청록색
  static const Color darkTealDark = Color(0xFF134E4A); // 더 진한 청록색

  // 그레이 계열 - 현대적인 뉴트럴 색상
  static const Color grey50 = Color(0xFFF9FAFB);
  static const Color grey100 = Color(0xFFF3F4F6);
  static const Color grey200 = Color(0xFFE5E7EB);
  static const Color grey300 = Color(0xFFD1D5DB);
  static const Color grey400 = Color(0xFF9CA3AF);
  static const Color grey500 = Color(0xFF6B7280);
  static const Color grey600 = Color(0xFF4B5563);
  static const Color grey700 = Color(0xFF374151);
  static const Color grey800 = Color(0xFF1F2937);
  static const Color grey900 = Color(0xFF111827);

  // 배경 색상
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = white;
  static const Color surfaceVariant = grey50;

  // 기존 색상들과의 호환성을 위한 매핑
  @deprecated
  static const Color mainPurple = primary;
  @deprecated
  static const Color mainLightPurple = primaryLight;
  @deprecated
  static const Color mainLightGrey = grey100;
  @deprecated
  static const Color mainMediumPurple = accent;
  @deprecated
  static const Color mainLime = secondary;
  @deprecated
  static const Color lavender = accentLight;
  @deprecated
  static const Color mediumViolet = accent;
  @deprecated
  static const Color violet = accent;
  @deprecated
  static const Color greenishLime = secondary;
  @deprecated
  static const Color darkerGreenishLime = secondaryDark;
  @deprecated
  static const Color lightLime = secondaryLight;
  @deprecated
  static const Color greyTenPer = grey100;
  @deprecated
  static const Color lightPurpleSky = grey50;
  @deprecated
  static const Color mainGrey = grey500;
  @deprecated
  static const Color earth = Color(0xFFD4A574);
  @deprecated
  static const Color lightEarth = Color(0xFFE8D5B7);
  @deprecated
  static const Color lightestEarth = Color(0xFFF3E8D0);
  @deprecated
  static const Color deepGreen = secondaryDark;
  @deprecated
  static const Color lightGreen = secondary;
  @deprecated
  static const Color lightestGreen = secondaryLight;

  // 그라데이션
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, secondaryDark],
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [white, grey50],
  );
}
