import 'package:flutter/material.dart';

/// 헤더와 같은 검정 반전 엠블럼.
class GleamMark extends StatelessWidget {
  static const ColorFilter invertToBlack = ColorFilter.matrix(<double>[
    -1, 0, 0, 0, 255,
    0, -1, 0, 0, 255,
    0, 0, -1, 0, 255,
    0, 0, 0, 1, 0,
  ]);

  final double height;
  final bool lightPlate;

  const GleamMark({
    Key? key,
    this.height = 36,
    this.lightPlate = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mark = SizedBox(
      height: height,
      child: ColorFiltered(
        colorFilter: invertToBlack,
        child: Image.asset(
          'assets/giEmblem.png',
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
    if (!lightPlate) return mark;
    return Container(
      padding: EdgeInsets.all(height * 0.28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: mark,
    );
  }
}
