import 'package:flutter/material.dart';
import 'package:gi_english_website/util/Palette.dart';

class EasyRadio extends StatelessWidget {
  final String label;
  final dynamic uniqueValue;
  final MyGroupValue myGroupValue;
  final void Function(VoidCallback fn) setStateOfParent;
  final void Function(MyGroupValue myGroupValue) onChanged;

  EasyRadio(this.uniqueValue, this.myGroupValue, this.setStateOfParent,
      {Key? key, required this.onChanged, this.label = ""})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    //widget. 위에 StatefulWidget에 접근하는 방법.
    return Row(
      children: [
        Text(label,
            style: TextStyle(
                color: Palette.black,
                fontFamily: "NotoSansKR",
                fontWeight: FontWeight.normal,
                fontSize: 14)),
        Radio(
            value: uniqueValue, //고유값. (체크박스랑 다름)
            groupValue: myGroupValue.value, //공유값
            onChanged: (dynamic value) {
              //클릭되었을때,
              if (uniqueValue != null) {
                myGroupValue.value = uniqueValue;
                onChanged(myGroupValue);
                setStateOfParent(() {});
              }
            }),
      ],
    );
  }
}

class MyGroupValue {
  dynamic value;

  MyGroupValue(this.value);
}
