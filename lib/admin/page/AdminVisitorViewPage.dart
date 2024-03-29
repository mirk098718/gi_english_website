//TODO:카페 비지터, 스쿨 비지터를 분리해서 이 페이지에 저장한다. jsonstring 으로 저장해서 여기 보여주면 될듯??

import 'package:flutter/material.dart';
import 'package:gi_english_website/class/SchoolVisitor.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/repository/SchoolVisitorRepository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminVisitorViewPage extends StatefulWidget {
  const AdminVisitorViewPage({Key? key}) : super(key: key);

  @override
  _AdminVisitorViewPageState createState() => _AdminVisitorViewPageState();
}

class _AdminVisitorViewPageState extends State<AdminVisitorViewPage> {
  //인스턴스필드.. (기본적)
  //클래스 필드 -> static.
  List<SchoolVisitor> schoolVisitorList = [];
  bool isInit = false;

  @override
  Widget build(BuildContext context) {
    if (!isInit) {
      isInit = true;
      print("_AdminVisitorViewPageState build");
      Future<SharedPreferences> prefsFuture = SharedPreferences.getInstance();
      prefsFuture.then((prefs) async {
        schoolVisitorList.clear();

        /*
       key.startsWith("CafeVisitor:")
       key.startsWith("SchoolVisitor:")
         */

        schoolVisitorList.addAll(
            await SchoolVisitorRepository.getList("childName", isNull: false));

        setState(() {});
      });
    }

    return Scaffold(
      body: Column(
        children: [
          Container(
              alignment: Alignment.center,
              color: Palette.mainLightGrey,
              width: 200,
              height: 50,
              child: Text("School Visitor")),
          Expanded(
            child: Column(
                children: schoolVisitorList
                    .map((schoolVisitor) => ListTile(
                          title: Text(schoolVisitor.parentName),
                        ))
                    .toList()),
          )
        ],
      ),
    );
  }
}
