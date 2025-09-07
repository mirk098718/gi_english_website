import 'package:flutter/material.dart';

class StretchTestPage extends StatelessWidget {
  const StretchTestPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 11, child: Text("test")),
          Expanded(flex: 7, child: Text("test2")),
        ],
      )
    );
  }
}
