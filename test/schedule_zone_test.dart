import 'package:flutter_test/flutter_test.dart';
import 'package:gi_english_website/util/AppLanguage.dart';
import 'package:gi_english_website/util/ScheduleZone.dart';

void main() {
  final monday = DateTime(2026, 11, 16);

  test('한국시각은 영어로 Korea time이다', () {
    AppLanguage.instance.code = 'en';
    expect(AppLanguage.instance.translate('한국시각'), 'Korea time');
    AppLanguage.instance.code = 'ko';
  });

  test('한국을 고르면 추가 시각이 없다', () {
    expect(ScheduleZone.korea.localTime(monday, '06:00'), isNull);
    expect(ScheduleZone.byId('없는지역').isKorea, isTrue);
  });

  test('미국 동부에서 한국 월요일 아침은 전날 오후다', () {
    final local = ScheduleZone.byId('America/New_York').localTime(monday, '06:00');
    expect(local, isNotNull);
    expect(local!.hour, 16);
    expect(local.minute, 0);
    expect(local.dayDelta, -1);
    expect(local.weekday, DateTime.sunday);
  });

  test('같은 시각의 요일 차이는 한 주 동안 같다', () {
    final zone = ScheduleZone.byId('America/Los_Angeles');
    final first = zone.localTime(monday, '09:30');
    expect(first, isNotNull);
    for (var i = 1; i < 7; i++) {
      final next = zone.localTime(monday.add(Duration(days: i)), '09:30');
      expect(next!.hour, first!.hour);
      expect(next.minute, first.minute);
      expect(next.dayDelta, first.dayDelta);
    }
  });

  test('호주 동부는 한국 오후보다 두 시간 뒤다', () {
    final local =
        ScheduleZone.byId('Australia/Sydney').localTime(monday, '15:30');
    expect(local!.hour, 17);
    expect(local.minute, 30);
    expect(local.dayDelta, 0);
    expect(local.weekday, DateTime.monday);
  });

  test('뉴질랜드 밤 시각은 다음 날로 넘어간다', () {
    final local =
        ScheduleZone.byId('Pacific/Auckland').localTime(monday, '22:00');
    expect(local!.hour, 2);
    expect(local.minute, 0);
    expect(local.dayDelta, 1);
    expect(local.weekday, DateTime.tuesday);
  });
}
