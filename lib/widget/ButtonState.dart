
import 'package:flutter/material.dart';
import 'package:gi_english_website/util/Palette.dart';

class BehaviorColor {
  static const Color colorOnClick = Palette.mainLightPurple;
  static const Color colorOnDefault = Palette.white;
  static const Color colorOnHover = Palette.mainMediumPurple;

  static const Color colorOnClickCafe = Palette.mainLime;
  static const Color colorOnDefaultCafe = Palette.white;
  static const Color colorOnHoverCafe = Palette.lightLime;
}

class ButtonState {
  String label;
  Color color;
  Widget nextPage;

  ButtonState(this.label, this.color, this.nextPage);
}
