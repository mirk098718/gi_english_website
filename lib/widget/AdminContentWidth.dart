import 'package:flutter/material.dart';

/// 웹 넓은 화면에서 관리자·강사 본문이 가로로 끝없이 늘어나지 않게 한다.
class AdminContentWidth extends StatelessWidget {
  static const double maxWidth = 1100;

  final Widget child;

  const AdminContentWidth({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth > maxWidth
            ? maxWidth
            : constraints.maxWidth;
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: width,
            height: constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : null,
            child: child,
          ),
        );
      },
    );
  }
}
