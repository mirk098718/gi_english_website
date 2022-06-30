//TODO:카페 비지터, 스쿨 비지터를 분리해서 이 페이지에 저장한다. jsonstring 으로 저장해서 여기 보여주면 될듯??

import 'package:flutter/material.dart';
import 'package:gi_english_website/util/Palette.dart';

class AdminVisitorViewPage extends StatefulWidget {
  const AdminVisitorViewPage({Key? key}) : super(key: key);

  @override
  _AdminVisitorViewPageState createState() => _AdminVisitorViewPageState();
}

class _AdminVisitorViewPageState extends State<AdminVisitorViewPage> {
  @override
  Widget build(BuildContext context) {
    List<Widget> cafeVisitorListTile = [];
    List<Widget> schoolVisitorListTile = [];

    return Scaffold(
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(children: [
            Container(alignment: Alignment.center, color: Palette.mainLightGrey, width: 200, height:50, child: Text("Cafe Visitor")),
            Column(
              children: cafeVisitorListTile,
            )
            ],),
          Column(children: [
            Container(alignment: Alignment.center, color: Palette.mainLightGrey, width: 200, height:50, child: Text("School Visitor")),
            Column(
              children: schoolVisitorListTile
            )
          ],)
        ],
      ),
    );
  }
}
