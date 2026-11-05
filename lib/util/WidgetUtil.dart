
import 'package:flutter/material.dart';

import 'Palette.dart';

class WidgetUtil {

  static Widget myDivider(){
    return Container
      (margin: EdgeInsets.only(top: 5, bottom: 5), height: 1,width: double.infinity,color: Palette.black,);
  }

  /// 페이지 폭에 맞춰 줄어드는 이미지. 가로 스크롤을 만들지 않는다.
  static Widget pageImage(String asset, {double maxWidth = 700}) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Image.asset(
        asset,
        width: double.infinity,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
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
