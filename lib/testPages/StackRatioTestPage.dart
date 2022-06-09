import 'package:flutter/material.dart';

class StackRatioTestPage extends StatelessWidget {
  const StackRatioTestPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FractionallySizedBox(
            widthFactor: 0.5,
            heightFactor: 0.5,
            child: Image.asset("assets/schoolMainImage.png"),
          ),
          Image.asset("assets/schoolMainCatch.png"),
        ],
      ),
    );
  }
}
