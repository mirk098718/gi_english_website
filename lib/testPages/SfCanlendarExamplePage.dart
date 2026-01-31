import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class SfCanlendarExamplePage extends StatelessWidget {
  const SfCanlendarExamplePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:SfCalendar(
        view: CalendarView.month,
        onTap: (CalendarTapDetails calendarTapDetails){
          //마감일과 현재일을 비교. 마감일을 넘겼는가? 마감일을 넘기지 않았는가?


          //DateTime이라는 자료형이 있음. (dart꺼)
          //이 녀석이 날짜를 표현.
          print("opnTap calendarTapDetails.date:${calendarTapDetails.date}");
                },
      ),
    );
  }
}
