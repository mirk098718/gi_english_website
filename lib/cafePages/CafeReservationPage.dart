import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/SnackbarUtil.dart';
import 'package:gi_english_website/widget/EasyRadio.dart';
import 'package:gi_english_website/widget/MobileCafeLayout.dart';
import 'package:gi_english_website/widget/WebCafeLayout.dart';
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
            "???????????? ????????????",
            style: TextStyle(fontFamily: "Jalnan", fontSize: 20),
          ),
          SizedBox(
            height: 20,
          ),
          Text("????????? ???????????? ????????? ???????????? ????????????????????? ???????????? ????????????, ????????? ????????? ???????????? ????????????.\n"
              "(????????? ???????????? ?????? ??????, ???????????? ????????? ??? ????????????.)"),
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
          Text("????????? ?????? ???????????? ??????, ???????????? ????????? ????????? ????????? ???????????????."),
          SizedBox(
            height: 20,
          ),
          submitButton(),
          SizedBox(
            height: 20,
          ),
          Text("1??? ???????????? ?????? ???, ???????????? ?????? ????????? ???????????????.(?????? ??? ????????? ???????????????.)"),
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
          "????????????",
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
      SnackbarUtil.showSnackBar("${periodMyGroupValue.value} ??????", context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "?????? ???~???",
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
      SnackbarUtil.showSnackBar("${periodMyGroupValue.value} ??????", context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "?????? ?????????",
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
      SnackbarUtil.showSnackBar("${periodMyGroupValue.value} ??????", context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "?????? ?????????",
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
      SnackbarUtil.showSnackBar("${programMyGroupValue.value} ??????", context);
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
            "?????? ??????",
            style: TextStyle(fontFamily: "Jalnan", fontSize: 20),
          ),
          SizedBox(height: 20),
          Text("???????????? ????????? ??????????????????."),
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

                  //???????????? ???????????? ??????. ???????????? ????????????? ???????????? ????????? ?????????????

                  //DateTime????????? ???????????? ??????. (dart???)
                  //??? ????????? ????????? ??????.
                  print(
                      "opnTap calendarTapDetails.date:${calendarTapDetails
                          .date}");
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
          //       //???????????? ???????????? ??????. ???????????? ????????????? ???????????? ????????? ?????????????
          //
          //
          //       //DateTime????????? ???????????? ??????. (dart???)
          //       //??? ????????? ????????? ??????.
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
        Text("?????? ??????"),
        MyWidget.roundEdgeTextFieldVisitorVer(onChanged: (text) {
          cafeVisitor.childName = text;
        }),
        SizedBox(
          height: 20,
        ),
        Text("?????? ??????"),
        MyWidget.roundEdgeTextFieldVisitorVer(onChanged: (text) {
          cafeVisitor.childAge = int.tryParse(text) ?? 0;
        }),
        SizedBox(
          height: 20,
        ),
        Text("???????????? ??????"),
        MyWidget.roundEdgeTextFieldVisitorVer(onChanged: (text) {
          cafeVisitor.parentName = text;
        }),
        SizedBox(
          height: 20,
        ),
        Text("???????????? ?????????"),
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
                      "????????????",
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
                      "????????????",
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
            "?????? ?????????",
            style: TextStyle(fontFamily: "Jalnan", fontSize: 20),
          ),
          SizedBox(height: 20),
          Text("???????????? ?????? ?????? ????????? ??????????????????."),
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

                  //???????????? ???????????? ??????. ???????????? ????????????? ???????????? ????????? ?????????????

                  //DateTime????????? ???????????? ??????. (dart???)
                  //??? ????????? ????????? ??????.
                  print(
                      "opnTap calendarTapDetails.date:${calendarTapDetails
                          .date}");
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
      SnackbarUtil.showSnackBar("????????? ??????????????????.", context);
      return;
    }

    await state.cafeVisitor.save();

    // cafeVisitorListTile.add(ListTile(
    //   title: Text(
    //       "${state.cafeVisitor.childName},${state.cafeVisitor.childAge}"),
    //   subtitle: Text("????????? ??????: ${state.cafeVisitor.parentName} / ????????? ?????????: ${state
    //       .cafeVisitor.parentNumber}"),
    // )

        DialogUtil.showAlert(context, "????????? ?????????????????????.");
  }

  void moveCafeReservationPage() {
    var context = state.context;
    MenuUtil.push(context, CafeReservationPage());
  }

}
