import 'package:flutter/material.dart';
import 'package:gi_english_website/util/Palette.dart';

class EasyRadio extends StatelessWidget {
  final String label;
  final String value;

  /// RadioGroup과 함께 사용. RadioGroup이 groupValue와 onChanged를 관리합니다.
  EasyRadio(this.value, {Key? key, this.label = ""}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: TextStyle(
                color: Palette.black,
                fontFamily: "NotoSansKR",
                fontWeight: FontWeight.normal,
                fontSize: 14)),
        Radio<String>(value: value),
      ],
    );
  }
}

class MyGroupValue {
  dynamic value;

  MyGroupValue(this.value);
}
