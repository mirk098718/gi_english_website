import 'package:flutter/material.dart';


class EasyRadio extends StatelessWidget {
  String label;
  dynamic uniqueValue;
  MyGroupValue myGroupValue;
  void Function(VoidCallback fn) setStateOfParent;
  void Function(MyGroupValue myGroupValue) onChanged;

  EasyRadio(this.uniqueValue, this.myGroupValue, this.setStateOfParent,
      {Key? key, required this.onChanged, this.label=""})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    //widget. 위에 StatefulWidget에 접근하는 방법.
    return Row(
      children: [
        Text(label),
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
