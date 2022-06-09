import 'package:flutter/material.dart';
import 'package:gi_english_website/util/Palette.dart';

class LabelWithColor {
  String label;
  Color? color;

  LabelWithColor(this.label, this.color);
}

class AppbarDropdown extends StatelessWidget {
  final LabelWithColor labelWithColor;

  AppbarDropdown(String label, Color color, {Key? key})
      : labelWithColor = LabelWithColor(label, color),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        alignment: Alignment.center,
        color: labelWithColor.color,
        width: 140,
        height: 35,
        child: Text(
          labelWithColor.label,
          style: TextStyle(color: Palette.white),
        ));
  }
}
