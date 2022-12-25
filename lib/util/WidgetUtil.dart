
import 'package:flutter/material.dart';

import 'Palette.dart';

class WidgetUtil {

  static Widget myDivider(){
    return Container
      (margin: EdgeInsets.only(top: 5, bottom: 5), height: 1,width: double.infinity,color: Palette.black,);
  }

  static Widget withLabel(String label, Widget widget,
      {bool useExpanded = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(label),
        SizedBox(
          width: 15,
        ),
        useExpanded ? Expanded(child: widget) : widget
      ],
    );
  }

  static Widget textFieldWithLabel(String label, TextEditingController controller,
      {ValueChanged<String>? onChanged, bool obscureText = false}) {
    return Row(
      children: [
        Container(width: 80,alignment: Alignment.bottomLeft,child: Text(label)),
        Expanded(
          child: TextField(controller: controller, onChanged: onChanged, obscureText: obscureText),
        ),

      ],
    );
  }

}
