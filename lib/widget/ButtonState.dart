
import 'package:flutter/material.dart';
import 'package:gi_english_website/util/Palette.dart';

class BehaviorColor {
  static const Color colorOnClick = Palette.mainLightPurple;
  static const Color colorOnDefault = Palette.white;
  static const Color colorOnHover = Palette.mainMediumPurple;
}

class ButtonState {
  String label;
  Color color;
  Widget nextPage;

  ButtonState(this.label, this.color, this.nextPage);
}
