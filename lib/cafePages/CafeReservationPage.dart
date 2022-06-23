import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gi_english_website/class/Visitor.dart';
import 'package:gi_english_website/util/JsonUtil.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/SnackbarUtil.dart';
import 'package:gi_english_website/widget/EasyRadio.dart';
import 'package:gi_english_website/widget/MobileCafeLayout.dart';
import 'package:gi_english_website/widget/WebCafeLayout.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../class/CafeVisitor.dart';
import '../util/DialogUtil.dart';

class CafeReservationPage extends StatefulWidget {
  const CafeReservationPage({Key? key}) : super(key: key);

  @override
  _CafeReservationPageState createState() => _CafeReservationPageState();
}

class _CafeReservationPageState extends State<CafeReservationPage> {
  late CafeReservationPageService s;
  late CafeVisitor cafeVisitor;
  MyGroupValue periodMyGroupValue = MyGroupValue("");
  MyGroupValue programMyGroupValue = MyGroupValue("program1");

  @override
  void initState() {
    s = CafeReservationPageService(this);
    cafeVisitor = CafeVisitor(
      childName: "",
      childAge: 0,
      parentName: "",
      parentNumber: "",
      program: programMyGroupValue.value,
      programPeriod: periodMyGroupValue.value,
    );
  }

  @override
  Widget build(BuildContext context) {
    MediaQueryData mediaQueryData = MediaQuery.of(context);
    Size size = mediaQueryData.size;
    double width = size.width;
    if (width > 768) {
      return desktopUi(context);
    } else {
      return mobileUi(context);
    }
  }

  Widget desktopUi(context) {
    return WebCafeLayout(content: scrollView());
  }

  Widget mobileUi(context) {
    return MobileCafeLayout(content: mobileScrollView());
  }

  Widget contentGroup() {
    return Container(
        color: Palette.white,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(child: leftBox()),
            Expanded(child: content()),
          ],
        ));
  }

  Widget content() {
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.all(20),
      color: Palette.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "프로그램 예약하기",
            style: TextStyle(fontFamily: "Jalnan", fontSize: 20),
          ),
          SizedBox(
            height: 20,
          ),
          Text("아이의 프로그램 참여를 원하시는 학부모님께서는 원하시는 프로그램, 날짜와 시간을 선택하여 주십시오.\n"
              "(정원이 충족되지 않는 경우, 스케줄이 변동될 수 있습니다.)"),
          Divider(),
          SizedBox(
            height: 20,
          ),
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Palette.greyTenPer,
            ),
            child: programRadio(),
          ),
          SizedBox(
            height: 20,
          ),
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                width: 1,
                color: Colors.grey,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                weekdayPeriodRadio(),
                SizedBox(
                  height: 20,
                ),
                saturdayPeriodRadio(),
                SizedBox(
                  height: 20,
                ),
                sundayPeriodRadio(),
              ],
            ),
          ),
          textBoxGroup(),
          Text("정기권 구매 고객님의 경우, 예약신청 버튼을 누르면 예약이 완료됩니다."),
          SizedBox(
            height: 20,
          ),
          submitButton(),
          SizedBox(
            height: 20,
          ),
          Text("1회 프로그램 참여 시, 원하시는 결제 방법을 선택하세요.(결제 후 예약이 확정됩니다.)"),
          SizedBox(
            height: 20,
          ),
          Container(
            width: 400,
            height: 150,
            color: Colors.grey,
            child: Row(
              children: [],
            ),
          )
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
          primary: Palette.mainLime,
          onPrimary: Palette.black,
        ),
        child: Text(
          "예약신청",
          style: TextStyle(fontFamily: "Jalnan"),
        ),
        onPressed: s.submit,
      ),
    );
  }

  Widget weekdayPeriodRadio() {
    void onChanged(MyGroupValue myGroupValue) {
      periodMyGroupValue = myGroupValue;
      cafeVisitor.programPeriod = periodMyGroupValue.value;
      SnackbarUtil.showSnackBar("${periodMyGroupValue.value} 선택", context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "평일 월~금",
          style: TextStyle(fontFamily: "Jalnan"),
        ),
        SizedBox(
          height: 10,
        ),
        EasyRadio(
          "period1",
          periodMyGroupValue,
          setState,
          label: "14:30 ~ 16:30",
          onChanged: onChanged,
        ),
        EasyRadio(
          "period2",
          periodMyGroupValue,
          setState,
          label: "16:30 ~ 18:30",
          onChanged: onChanged,
        ),
        EasyRadio(
          "period3",
          periodMyGroupValue,
          setState,
          label: "18:30 ~ 20:30",
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget saturdayPeriodRadio() {
    void onChanged(MyGroupValue myGroupValue) {
      periodMyGroupValue = myGroupValue;
      cafeVisitor.programPeriod = periodMyGroupValue.value;
      SnackbarUtil.showSnackBar("${periodMyGroupValue.value} 선택", context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "주말 토요일",
          style: TextStyle(fontFamily: "Jalnan"),
        ),
        SizedBox(
          height: 10,
        ),
        EasyRadio(
          "satPeriod1",
          periodMyGroupValue,
          setState,
          label: "10:30 ~ 12:30 ",
          onChanged: onChanged,
        ),
        EasyRadio(
          "satPeriod2",
          periodMyGroupValue,
          setState,
          label: "12:30 ~ 14:30",
          onChanged: onChanged,
        ),
        EasyRadio(
          "satPeriod3",
          periodMyGroupValue,
          setState,
          label: "14:30 ~ 16:30",
          onChanged: onChanged,
        ),
        EasyRadio(
          "satPeriod4",
          periodMyGroupValue,
          setState,
          label: "16:30 ~ 18:30",
          onChanged: onChanged,
        ),
        EasyRadio(
          "satPeriod5",
          periodMyGroupValue,
          setState,
          label: "18:30 ~ 20:30",
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget sundayPeriodRadio() {
    void onChanged(MyGroupValue myGroupValue) {
      periodMyGroupValue = myGroupValue;
      cafeVisitor.programPeriod = periodMyGroupValue.value;
      SnackbarUtil.showSnackBar("${periodMyGroupValue.value} 선택", context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "주말 일요일",
          style: TextStyle(fontFamily: "Jalnan"),
        ),
        SizedBox(
          height: 10,
        ),
        EasyRadio(
          "sunPeriod1",
          periodMyGroupValue,
          setState,
          label: "11:00 ~ 13:00",
          onChanged: onChanged,
        ),
        EasyRadio(
          "sunPeriod2",
          periodMyGroupValue,
          setState,
          label: "13:00 ~ 15:00",
          onChanged: onChanged,
        ),
        EasyRadio(
          "sunPeriod3",
          periodMyGroupValue,
          setState,
          label: "15:00 ~ 17:00",
          onChanged: onChanged,
        ),
        EasyRadio(
          "sunPeriod34",
          periodMyGroupValue,
          setState,
          label: "17:00 ~ 19:00",
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget programRadio() {
    void onChanged(MyGroupValue myGroupValue) {
      programMyGroupValue = myGroupValue;
      cafeVisitor.program = programMyGroupValue.value;
      SnackbarUtil.showSnackBar("${programMyGroupValue.value} 선택", context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Program",
          style: TextStyle(fontFamily: "Jalnan"),
        ),
        SizedBox(
          height: 10,
        ),
        EasyRadio(
          "program1",
          programMyGroupValue,
          setState,
          label: "Storytelling",
          onChanged: onChanged,
        ),
        EasyRadio(
          "program2",
          programMyGroupValue,
          setState,
          label: "Creative Art",
          onChanged: onChanged,
        ),
        EasyRadio(
          "program3",
          programMyGroupValue,
          setState,
          label: "Visual Contents",
          onChanged: onChanged,
        ),
        EasyRadio(
          "program4",
          programMyGroupValue,
          setState,
          label: "Physical Activities",
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget leftBox() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "희망 날짜",
            style: TextStyle(fontFamily: "Jalnan", fontSize: 20),
          ),
          SizedBox(height: 20),
          Text("원하시는 날짜를 선택해주세요."),
          Divider(),
          Container(
            width: 400,
            height: 400,
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

          // SfCalendar(
          //   view: CalendarView.month,
          //   onTap: (CalendarTapDetails calendarTapDetails){
          //     // DateTime dateTime = DateTime.now();
          //     DateTime? dateTime = calendarTapDetails.date;
          //     if(dateTime != null) {
          //       // dateTime = dateTime.subtract(Duration(hours: 1));
          //       // dateTime = dateTime.add(Duration(hours: 1));
          //       // dateTime.isAfter(other);
          //       // dateTime.isBefore(other);
          //
          //       //마감일과 현재일을 비교. 마감일을 넘겼는가? 마감일을 넘기지 않았는가?
          //
          //
          //       //DateTime이라는 자료형이 있음. (dart꺼)
          //       //이 녀석이 날짜를 표현.
          //       print("opnTap calendarTapDetails.date:${calendarTapDetails.date}");
          //     }
          //   },
          // ),
        ],
      ),
    );
  }

  Widget textBoxGroup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 20,
        ),
        Text("아이 이름"),
        MyWidget.roundEdgeTextFieldVisitorVer(onChanged: (text) {
          cafeVisitor.childName = text;
        }),
        SizedBox(
          height: 20,
        ),
        Text("아이 연령"),
        MyWidget.roundEdgeTextFieldVisitorVer(onChanged: (text) {
          cafeVisitor.childAge = int.tryParse(text) ?? 0;
        }),
        SizedBox(
          height: 20,
        ),
        Text("보호자님 성함"),
        MyWidget.roundEdgeTextFieldVisitorVer(onChanged: (text) {
          cafeVisitor.parentName = text;
        }),
        SizedBox(
          height: 20,
        ),
        Text("보호자님 연락처"),
        MyWidget.roundEdgeTextFieldVisitorVer(onChanged: (text) {
          cafeVisitor.parentNumber = text;
        }),
        SizedBox(
          height: 20,
        ),
      ],
    );
  }

  Widget scrollView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          mainImage(),
          contentGroup(),
          SizedBox(height: 213, child: MyWidget.cafeFooter()),
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
                  "Booking",
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
                  height: 50,
                  child: ElevatedButton(
                    child: Text(
                      "예약문의",
                      style:
                          TextStyle(fontFamily: "Jalnan", color: Palette.white),
                    ),
                    onPressed: s.moveCafeReservationPage,
                    style: ElevatedButton.styleFrom(
                      primary: Palette.mainLime,
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

  //mobile

  Widget mobileScrollView() {
    return SingleChildScrollView(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // mobileMainImage(),
            mobileCalendarBox(),
            content(),
            SizedBox(height: 51, child: MyWidget.mobileCafeFooter())
          ],
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
                  "Booking",
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
                      "예약문의",
                      style:
                          TextStyle(fontFamily: "Jalnan", color: Palette.white),
                    ),
                    onPressed: s.moveCafeReservationPage,
                    style: ElevatedButton.styleFrom(
                      primary: Palette.mainLime,
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
          Text("원하시는 대면 상담 날짜를 선택해주세요."),
          Divider(),
          Container(
            width: 300,
            height: 300,
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
}

class CafeReservationPageService {
  _CafeReservationPageState state;

  CafeReservationPageService(this.state);

  void submit() async {
    var context = state.context;
    if (!state.cafeVisitor.isValid()) {
      SnackbarUtil.showSnackBar("정보를 입력해주세요.", context);
      return;
    }

    await state.cafeVisitor.save();
    DialogUtil.showAlert(context, "예약이 완료되었습니다.");
  }

  void moveCafeReservationPage() {
    var context = state.context;
    MenuUtil.push(context, CafeReservationPage());
  }

}
