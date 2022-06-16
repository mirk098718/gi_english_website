import 'package:flutter/material.dart';

import '../util/Palette.dart';

class VerticalDivider extends StatelessWidget {
  const VerticalDivider({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: Palette.mainLightPurple,
    );
  }
}
