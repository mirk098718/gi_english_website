import 'package:flutter/widgets.dart';

/// 폰은 세로든 가로든 모바일 헤더를 쓴다.
/// 가로만 보면 폰을 눕혔을 때 768을 넘어 데스크톱 헤더가 열린다.
bool useMobileSchoolLayout(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  if (size.width <= 768) return true;
  return size.shortestSide <= 500;
}
