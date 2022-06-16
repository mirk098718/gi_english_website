
import 'package:flutter/material.dart';

class WidgetUtil {
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

  static Widget textFieldWithLabel(String label,
      {ValueChanged<String>? onChanged, bool obscureText = false}) {
    return Row(
      children: [
        Text(label),
        SizedBox(width: 15),
        Expanded(
          child: TextField(onChanged: onChanged, obscureText: obscureText),
        )
      ],
    );
  }

}
