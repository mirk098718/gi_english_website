import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WhyChooseNzWeb extends StatefulWidget {
  const WhyChooseNzWeb({Key? key}) : super(key: key);

  @override
  _WhyChooseNzWebState createState() => _WhyChooseNzWebState();
}

class _WhyChooseNzWebState extends State<WhyChooseNzWeb> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: WebView(
          initialUrl: "https://www.youtube.com/watch?v=Ytc6ClRRhw0",
        )
    );
  }
}