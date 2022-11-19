import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/SnackbarUtil.dart';
import 'package:gi_english_website/util/repository/SchoolVisitorRepository.dart';
import 'package:gi_english_website/widget/ButtonState.dart';
import 'package:gi_english_website/widget/EasyRadio.dart';
import 'package:gi_english_website/widget/MobileSchoolLayout.dart';
import 'package:gi_english_website/widget/WebSchoolLayout.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../class/SchoolVisitor.dart';
import '../util/DialogUtil.dart';
import 'SchoolCommunityNoticePage.dart';
import 'SchoolGalleryPage.dart';

class SchoolConsultationPage extends StatefulWidget {
  const SchoolConsultationPage({Key? key}) : super(key: key);

  @override
  _SchoolConsultationPageState createState() => _SchoolConsultationPageState();
}

class _SchoolConsultationPageState extends State<SchoolConsultationPage> {

  late SchoolConsultationPageService s;
  late SchoolVisitor schoolVisitor;

  MyGroupValue levelMyGroupValue = MyGroupValue("Level0");
  MyGroupValue timeMyGroupValue = MyGroupValue("오전 09am ~ 12pm");

  List<ButtonState> buttonStateList = [
    ButtonState("Notice Board", BehaviorColor.colorOnDefault, SchoolCommunityNoticePage()),
    ButtonState("Gallery", BehaviorColor.colorOnDefault, SchoolGalleryPage()),
    ButtonState("입학상담", BehaviorColor.colorOnClick, SchoolConsultationPage()),
  ];

  @override
  void initState() {
    s = SchoolConsultationPageService(this);
    schoolVisitor = SchoolVisitor(
      childName: "",
      childAge: 0,
      parentName: "",
      parentNumber: "",
      time: timeMyGroupValue.value,
      level: levelMyGroupValue.value,
    );
  }


  @override
  Widget build(BuildContext context) {
    MediaQueryData mediaQueryData = MediaQuery.of(context);
    Size size = mediaQueryData.size;
    double width = size.width;
    if (width > 768) {
      return WebSchoolLayout(content: desktopScrollView());
    } else {
      return MobileSchoolLayout(content: mobileScrollView());
    }
  }

  Widget desktopScrollView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          mainImage(),
          Container(
            color: Palette.white,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Container(margin:EdgeInsets.only(top:40, left: 50),width: 1,height: 520, color:Palette.greyTenPer,),
                Expanded(child: calendarBox()),
                Container(margin:EdgeInsets.only(top:40,right:40),width: 1,height: 520, color:Palette.greyTenPer,),
                Expanded(child: content()),
              ],
            ),
          ),
          SizedBox(height: 213, child: MyWidget.footer()),
        ],
      ),
    );
  }

  Widget mobileScrollView() {
    return SingleChildScrollView(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // mobileMainImage(),
            mobileLeftMenu(),
            mobileCalendarBox(),
            mobileContent(),
            SizedBox(height: 51, child: MyWidget.mobileSchoolFooter())
          ],
        ),
      ),
    );
  }
  Widget content() {
    return Container(
      alignment: Alignment.topLeft,
      padding: EdgeInsets.all(40),
      color: Palette.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            alignment: Alignment.centerLeft,
            child: Text(
              "상담 신청하기",
              style: TextStyle(fontFamily: "Jalnan", fontSize: 20),
            ),
          ),
          SizedBox(height: 20),
          Text(style: TextStyle(
              color: Palette.black,
              fontFamily: "MaruBuri",
              fontWeight: FontWeight.normal,
              fontSize: 12),"입학 상담 및 입학 테스트를 원하시는 학부모님께서는 간단한 인적사항과 연락처를 남겨주세요. "),
          // Divider(),
          SizedBox(height: 20),
          Text(style: TextStyle(
              color: Palette.black,
              fontFamily: "MaruBuri",
              fontWeight: FontWeight.normal,
              fontSize: 12),"아이 이름"),
          MyWidget.roundEdgeTextFieldVisitorVer(onChanged: (text) {
            schoolVisitor.childName = text;
          }),
          SizedBox(height: 20),
          Text(style: TextStyle(
              color: Palette.black,
              fontFamily: "MaruBuri",
              fontWeight: FontWeight.normal,
              fontSize: 12),"보호자님 성함"),
          MyWidget.roundEdgeTextFieldVisitorVer(onChanged: (text) {
            schoolVisitor.parentName = text;
          }),
          SizedBox(height: 20),
          Text(style: TextStyle(
              color: Palette.black,
              fontFamily: "MaruBuri",
              fontWeight: FontWeight.normal,
              fontSize: 12),"보호자님 연락처"),
          MyWidget.roundEdgeTextFieldVisitorVer(onChanged: (text) {
            schoolVisitor.parentNumber = text;
          }),
          SizedBox(height: 20),
          Text(style: TextStyle(
              color: Palette.black,
              fontFamily: "MaruBuri",
              fontWeight: FontWeight.normal,
              fontSize: 12),"아이 연령"),
          MyWidget.roundEdgeTextFieldVisitorVer(onChanged: (text) {
            schoolVisitor.childAge = int.tryParse(text)??0;
          }),
          SizedBox(height: 20),
          Text(style: TextStyle(
              color: Palette.black,
              fontFamily: "MaruBuri",
              fontWeight: FontWeight.normal,
              fontSize: 12),"아이 레벨"),
          Divider(),
          levelRadio(),
          SizedBox(height: 20),
          Text(style: TextStyle(
              color: Palette.black,
              fontFamily: "MaruBuri",
              fontWeight: FontWeight.normal,
              fontSize: 12),"전화상담 희망시간"),
          Divider(),
          timeRadio(),
          SizedBox(height: 20),
          submitButton(),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget mobileContent() {
    return Container(
      alignment: Alignment.topLeft,
      padding: EdgeInsets.all(20),
      color: Palette.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            alignment: Alignment.centerLeft,
            child: Text(
              "상담 신청하기",
              style: TextStyle(fontFamily: "Jalnan", fontSize: 20),
            ),
          ),
          SizedBox(height: 20),
          Text(style: TextStyle(
              color: Palette.black,
              fontFamily: "MaruBuri",
              fontWeight: FontWeight.normal,
              fontSize: 12),"입학 상담 및 입학 테스트를 원하시는 학부모님께서는 간단한 인적사항과 연락처를 남겨주세요. "),
          Divider(),
          SizedBox(height: 20),
          Text(style: TextStyle(
              color: Palette.black,
              fontFamily: "MaruBuri",
              fontWeight: FontWeight.normal,
              fontSize: 12),"아이 이름"),
          MyWidget.roundEdgeTextFieldVisitorVer(onChanged: (text) {
            schoolVisitor.childName = text;
          }),
          SizedBox(height: 20),
          Text(style: TextStyle(
              color: Palette.black,
              fontFamily: "MaruBuri",
              fontWeight: FontWeight.normal,
              fontSize: 12),"보호자님 성함"),
          MyWidget.roundEdgeTextFieldVisitorVer(onChanged: (text) {
            schoolVisitor.parentName = text;
          }),
          SizedBox(height: 20),
          Text(style: TextStyle(
              color: Palette.black,
              fontFamily: "MaruBuri",
              fontWeight: FontWeight.normal,
              fontSize: 12),"보호자님 연락처"),
          MyWidget.roundEdgeTextFieldVisitorVer(onChanged: (text) {
            schoolVisitor.parentNumber = text;
          }),
          SizedBox(height: 20),
          Text(style: TextStyle(
              color: Palette.black,
              fontFamily: "MaruBuri",
              fontWeight: FontWeight.normal,
              fontSize: 12),"아이 연령"),
          MyWidget.roundEdgeTextFieldVisitorVer(onChanged: (text) {
            schoolVisitor.childAge = int.tryParse(text)??0;
          }),
          SizedBox(height: 20),
          Text(style: TextStyle(
              color: Palette.black,
              fontFamily: "MaruBuri",
              fontWeight: FontWeight.normal,
              fontSize: 12),"아이 레벨"),
          Divider(),
          levelRadio(),
          SizedBox(height: 20),
          Text(style: TextStyle(
              color: Palette.black,
              fontFamily: "MaruBuri",
              fontWeight: FontWeight.normal,
              fontSize: 12),"전화상담 희망시간"),
          Divider(),
          timeRadio(),
          SizedBox(height: 20),
          submitButton(),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget submitButton() {
    return Container(
        width: 150,
        height: 50,
        child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              primary: Palette.black,
              onPrimary: Palette.black,
            ),
            child: Text(
              "상담예약",
              style: TextStyle(fontFamily: "Jalnan", color: Palette.white),
            ),
            onPressed: s.submitButtonPressed)
    );
  }

  Widget calendarBox() {
    return Container(
      padding: EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "상담 희망일",
            style: TextStyle(fontFamily: "Jalnan", fontSize: 20),
          ),
          SizedBox(height: 20),
          Text(style: TextStyle(
              color: Palette.black,
              fontFamily: "MaruBuri",
              fontWeight: FontWeight.normal,
              fontSize: 12),"원하시는 대면 상담 날짜를 선택해주세요."),
          // Divider(),
          Container(
            width: 400,
            height: 400  ,
            alignment: Alignment.center,
            margin: EdgeInsets.only(left:30, top:60),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                width: 1,
                color: Colors.grey,
              ),
            ),
            child: SfCalendar(
              view: CalendarView.month,
              onTap: (CalendarTapDetails calendarTapDetails) {
                // DateTime dateTime = DateTime.now();
                DateTime? dateTime = calendarTapDetails.date;
                if (dateTime != null) {
                  // dateTime = dateTime.subtract(Duration(hours: 1));
                  // dateTime = dateTime.add(Duration(hours: 1));
                  // dateTime.isAfter(other);
                  // dateTime.isBefore(other);

                  //마감일과 현재일을 비교. 마감일을 넘겼는가? 마감일을 넘기지 않았는가?

                  //DateTime이라는 자료형이 있음. (dart꺼)
                  //이 녀석이 날짜를 표현.
                  print(
                      "opnTap calendarTapDetails.date:${calendarTapDetails.date}");
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget mainImage() {
    return Container(
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          Image.asset("assets/communityMainImage.png"),
          Container(
            padding: EdgeInsets.only(left: 40, bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "Appointment",
                  style: TextStyle(
                      color: Palette.white,
                      fontSize: 30,
                      fontFamily: "LucidaCalligraphy"),
                ),
                SizedBox(
                  height: 20,
                ),
                Container(
                  width: 150,
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      primary: Palette.black,
                      onPrimary: Palette.black,
                    ),
                    onPressed: () {MenuUtil.push(context, SchoolConsultationPage());},
                    child: Text("상담신청",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: "Jalnan",
                            color: Palette.white,
                            )),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  //mobile

  Widget mobileLeftMenu() {
    List<Widget> children = [];
    for (int i = 0; i < buttonStateList.length; i++) {
      ButtonState buttonState = buttonStateList[i];

      bool isFirst = (i == 0);
      bool isLast = (i == buttonStateList.length - 1);

      Widget child;
      if (isFirst) {
        child =
            MyWidget.mobileLeftMenuStart(buttonState.color, buttonState.label);
      } else if (isLast) {
        //last
        child =
            MyWidget.mobileLeftMenuEnd(buttonState.color, buttonState.label);
      } else {
        child =
            MyWidget.mobileLeftMenuMiddle(buttonState.color, buttonState.label);
      }

      children.add(InkWell(
        child: child,
        onHover: (value) {
          buttonState.color = value
              ? BehaviorColor.colorOnHover
              : (i == 2
                  ? BehaviorColor.colorOnClick
                  : BehaviorColor.colorOnDefault);
          setState(() {});
        },
        onTap: () {
          MenuUtil.push(context, buttonState.nextPage);
        },
      ));

      if (!isLast) {
        children.add(Container(
          width: 1,
          height: 40,
          color: Palette.mainLightPurple,
        ));
      }
    }

    return Container(
      color: Palette.white,
      padding: EdgeInsets.all(20),
      child: Container(
        // decoration: BoxDecoration(
        //   borderRadius: BorderRadius.circular(10),
        //   border: Border.all(
        //     width: 1,
        //     color: Palette.black,
        //   ),
        // ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: children,
          ),
        ),
      ),
    );
  }

  Widget mobileMainImage() {
    return Container(
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Image.asset("assets/communityMainImage.png"),
          Container(
            padding: EdgeInsets.only(left: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Appointment",
                  style: TextStyle(
                      color: Palette.white,
                      fontSize: 20,
                      fontFamily: "LucidaCalligraphy"),
                ),
                SizedBox(
                  height: 10,
                ),
                Container(
                  width: 150,
                  height: 40,
                  child: ElevatedButton(
                    child: Text(
                      "상담신청",
                      style:
                          TextStyle(fontFamily: "Jalnan", color: Palette.white),
                    ),
                    onPressed: () {
                      MenuUtil.push(context, SchoolConsultationPage());
                    },
                    style: ElevatedButton.styleFrom(
                      primary: Palette.black,
                      onPrimary: Palette.black,
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget mobileCalendarBox() {
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "상담 희망일",
            style: TextStyle(fontFamily: "Jalnan", fontSize: 20),
          ),
          SizedBox(height: 20),
          Text(style: TextStyle(
              color: Palette.black,
              fontFamily: "MaruBuri",
              fontWeight: FontWeight.normal,
              fontSize: 12),"원하시는 대면 상담 날짜를 선택해주세요."),
          Divider(),
          Container(
            width: 400,
            height: 400  ,
            alignment: Alignment.center,
            margin: EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                width: 1,
                color: Colors.grey,
              ),
            ),
            child: SfCalendar(
              view: CalendarView.month,
              onTap: (CalendarTapDetails calendarTapDetails) {
                // DateTime dateTime = DateTime.now();
                DateTime? dateTime = calendarTapDetails.date;
                if (dateTime != null) {
                  // dateTime = dateTime.subtract(Duration(hours: 1));
                  // dateTime = dateTime.add(Duration(hours: 1));
                  // dateTime.isAfter(other);
                  // dateTime.isBefore(other);

                  //마감일과 현재일을 비교. 마감일을 넘겼는가? 마감일을 넘기지 않았는가?

                  //DateTime이라는 자료형이 있음. (dart꺼)
                  //이 녀석이 날짜를 표현.
                  print(
                      "opnTap calendarTapDetails.date:${calendarTapDetails.date}");
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget levelRadio() {
    void onChanged(MyGroupValue myGroupValue) {
      levelMyGroupValue = myGroupValue;
      schoolVisitor.level = levelMyGroupValue.value;
      SnackbarUtil.showSnackBar("${levelMyGroupValue.value} 선택", context);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EasyRadio(
          "Level0",
          levelMyGroupValue,
          setState,
          label: "Level 0 알파벳 단계               ",
          onChanged: onChanged,
        ),
        EasyRadio(
          "Level1",
          levelMyGroupValue,
          setState,
          label: "Level 1 파닉스 단계               ",
          onChanged: onChanged,
        ),
        EasyRadio(
          "Level2",
          levelMyGroupValue,
          setState,
          label: "Level 2 리딩 / 문법 초보 단계",
          onChanged: onChanged,
        ),
        EasyRadio(
          "Level3",
          levelMyGroupValue,
          setState,
          label: "Level 3 리딩 / 문법 중급 단계",
          onChanged: onChanged,
        ),
        EasyRadio(
          "Level4",
          levelMyGroupValue,
          setState,
          label: "Level 4 리딩 / 문법 고급 단계",
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget timeRadio() {
    void onChanged(MyGroupValue myGroupValue) {
      timeMyGroupValue = myGroupValue;
      schoolVisitor.time = timeMyGroupValue.value;
      SnackbarUtil.showSnackBar("${timeMyGroupValue.value} 선택", context);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EasyRadio(
          "오전 09am ~ 12pm",
          timeMyGroupValue,
          setState,
          label: "오전 09am ~ 12pm",onChanged: onChanged,
        ),
        EasyRadio(
          "오후 01pm ~ 04pm",
          timeMyGroupValue,
          setState,
          label: "오후 01pm ~ 04pm",onChanged: onChanged,
        ),
        EasyRadio(
          "오후 05pm ~ 08pm",
          timeMyGroupValue,
          setState,
          label: "오후 05pm ~ 08pm",onChanged: onChanged,
        ),
      ],
    );
  }

}

class SchoolConsultationPageService {
  _SchoolConsultationPageState state;
  SchoolConsultationPageService(this.state);

  void submitButtonPressed()async{
    var context = state.context;

    if (!state.schoolVisitor.isValid()) {
      SnackbarUtil.showSnackBar("정보를 입력해주세요.", context);
      return;
    }

    final schoolVisitor = state.schoolVisitor;
    await SchoolVisitorRepository.save(schoolVisitor);
    DialogUtil.showAlert(context, "예약이 완료되었습니다.");
  }
}
