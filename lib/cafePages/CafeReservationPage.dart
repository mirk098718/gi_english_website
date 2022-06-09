import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gi_english_website/cafePages/CafeAboutPage.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/widget/EasyRadio.dart';
import 'package:gi_english_website/widget/MobileCafeLayout.dart';
import 'package:gi_english_website/widget/WebCafeLayout.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class CafeReservationPage extends StatefulWidget {
  const CafeReservationPage({Key? key}) : super(key: key);

  @override
  _CafeReservationPageState createState() => _CafeReservationPageState();
}

class _CafeReservationPageState extends State<CafeReservationPage> {
  MyGroupValue myGroupValue = MyGroupValue("");
  MyGroupValue myGroupValue2 = MyGroupValue("program1");

  final childNameController = TextEditingController();
  final parentNameController = TextEditingController();
  final childAgeController = TextEditingController();
  final parentContactController = TextEditingController();


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

  Widget submitButton(){
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
          onPressed: () {
            // String childName = childNameController.text;
            // double childAge = double.parse(childAgeController.text);
            // String parentName = parentNameController.text;

            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                    content: Container(
                      width: 250,
                      height: 260,
                      alignment: Alignment.center,
                      padding: EdgeInsets.all(30),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 50,
                          ),
                          Text(
                            "예약이 완료되었습니다.",
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(
                            height: 60,
                          ),
                          Container(
                            width: 150,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                primary: Palette.mainLime,
                                onPrimary: Palette.black,
                              ),
                              onPressed: () {
                                MenuUtil.pop(context);
                              },
                              child: Text(
                                "확인",
                                style: TextStyle(fontFamily: "Jalnan"),
                              ),
                            ),
                          )
                        ],
                      ),
                    ));
              },
            );
          }),
    );
  }

  Widget weekdayPeriodRadio() {
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
          myGroupValue,
          setState,
          label: "14:30 ~ 16:30",
        ),
        EasyRadio(
          "period2",
          myGroupValue,
          setState,
          label: "16:30 ~ 18:30",
        ),
        EasyRadio(
          "period3",
          myGroupValue,
          setState,
          label: "18:30 ~ 20:30",
        ),
      ],
    );
  }

  Widget saturdayPeriodRadio() {
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
          myGroupValue,
          setState,
          label: "10:30 ~ 12:30 ",
        ),
        EasyRadio(
          "satPeriod2",
          myGroupValue,
          setState,
          label: "12:30 ~ 14:30",
        ),
        EasyRadio(
          "satPeriod3",
          myGroupValue,
          setState,
          label: "14:30 ~ 16:30",
        ),
        EasyRadio(
          "satPeriod4",
          myGroupValue,
          setState,
          label: "16:30 ~ 18:30",
        ),
        EasyRadio(
          "satPeriod5",
          myGroupValue,
          setState,
          label: "18:30 ~ 20:30",
        ),
      ],
    );
  }

  Widget sundayPeriodRadio() {
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
          myGroupValue,
          setState,
          label: "11:00 ~ 13:00",
        ),
        EasyRadio(
          "sunPeriod2",
          myGroupValue,
          setState,
          label: "13:00 ~ 15:00",
        ),
        EasyRadio(
          "sunPeriod3",
          myGroupValue,
          setState,
          label: "15:00 ~ 17:00",
        ),
        EasyRadio(
          "sunPeriod34",
          myGroupValue,
          setState,
          label: "17:00 ~ 19:00",
        ),
      ],
    );
  }

  Widget programRadio() {
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
          myGroupValue2,
          setState,
          label: "Storytelling",
        ),
        EasyRadio(
          "program2",
          myGroupValue2,
          setState,
          label: "Creative Art",
        ),
        EasyRadio(
          "program3",
          myGroupValue2,
          setState,
          label: "Visual Contents",
        ),
        EasyRadio(
          "program4",
          myGroupValue,
          setState,
          label: "Physical Activities",
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
        roundEdgeTextField(childNameController),
        SizedBox(
          height: 20,
        ),
        Text("아이 연령"),
        roundEdgeTextField(childAgeController),
        SizedBox(
          height: 20,
        ),
        Text("보호자님 성함"),
        roundEdgeTextField(parentNameController),
        SizedBox(
          height: 20,
        ),
        Text("보호자님 연락처"),
        roundEdgeTextField(parentContactController),
        SizedBox(
          height: 20,
        ),
      ],
    );
  }

  Widget roundEdgeTextField(TextEditingController controller) {
    return Container(
      padding: EdgeInsets.only(top: 7, bottom: 7),
      width: 500,
      color: Colors.transparent,
      child: TextField(
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
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
                    onPressed: () {
                      MenuUtil.push(context, CafeReservationPage());
                    },
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
            mobileMainImage(),
            leftBox(),
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
                    onPressed: () {
                      MenuUtil.push(context, CafeReservationPage());
                    },
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


}
