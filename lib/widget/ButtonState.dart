import 'package:flutter/material.dart';
import 'package:gi_english_website/util/Palette.dart';

class BehaviorColor {
  static const Color colorOnClick = Palette.primaryLight;
  static const Color colorOnDefault = Palette.surface;
  static const Color colorOnHover = Palette.grey100;

  static const Color colorOnClickCafe = Palette.secondary;
  static const Color colorOnDefaultCafe = Palette.surface;
  static const Color colorOnHoverCafe = Palette.secondaryLight;
}

class ButtonState {
  String label;
  Color color;
  Widget nextPage;

  ButtonState(this.label, this.color, this.nextPage);
}

class NoticeBoardEntry {
  String entryNumber;
  String title;
  Color color;

  NoticeBoardEntry(this.entryNumber, this.title, this.color);
}
