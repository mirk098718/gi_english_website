import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// 강사 스케줄 표는 한국 시각이다.
/// 다른 지역을 고르면 그 시각이 선택한 지역에서 몇 시인지 보여 준다.
class ScheduleZone {
  final String id;
  final String label;

  const ScheduleZone(this.id, this.label);

  static const koreaId = 'Asia/Seoul';

  static const korea = ScheduleZone(koreaId, '한국');

  static const choices = <ScheduleZone>[
    korea,
    ScheduleZone('America/New_York', '미국 동부'),
    ScheduleZone('America/Chicago', '미국 중부'),
    ScheduleZone('America/Denver', '미국 산악'),
    ScheduleZone('America/Los_Angeles', '미국 태평양'),
    ScheduleZone('Pacific/Honolulu', '하와이'),
    ScheduleZone('America/Toronto', '캐나다 동부'),
    ScheduleZone('America/Vancouver', '캐나다 태평양'),
    ScheduleZone('Europe/London', '영국'),
    ScheduleZone('Europe/Paris', '유럽 중부'),
    ScheduleZone('Asia/Dubai', '아랍에미리트'),
    ScheduleZone('Asia/Kolkata', '인도'),
    ScheduleZone('Asia/Singapore', '싱가포르'),
    ScheduleZone('Asia/Shanghai', '중국'),
    ScheduleZone('Asia/Tokyo', '일본'),
    ScheduleZone('Asia/Manila', '필리핀'),
    ScheduleZone('Australia/Perth', '호주 서부'),
    ScheduleZone('Australia/Adelaide', '호주 중부'),
    ScheduleZone('Australia/Sydney', '호주 동부'),
    ScheduleZone('Pacific/Auckland', '뉴질랜드'),
  ];

  bool get isKorea => id == koreaId;

  static ScheduleZone byId(String id) {
    for (final zone in choices) {
      if (zone.id == id) return zone;
    }
    return korea;
  }

  static bool _ready = false;

  static void ensure() {
    if (_ready) return;
    tzdata.initializeTimeZones();
    _ready = true;
  }

  /// [koreaDate]의 달력 날짜와 `HH:mm`을 한국 시각으로 읽고, 이 지역 시각으로 바꾼다.
  /// 한국이면 null이다.
  ZoneLocalTime? localTime(DateTime koreaDate, String time) {
    if (isKorea) return null;
    final parts = time.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    ensure();
    final source = tz.TZDateTime(
      tz.getLocation(koreaId),
      koreaDate.year,
      koreaDate.month,
      koreaDate.day,
      hour,
      minute,
    );
    final local = tz.TZDateTime.from(source, tz.getLocation(id));
    final origin = DateTime(koreaDate.year, koreaDate.month, koreaDate.day);
    final shifted = DateTime(local.year, local.month, local.day);
    return ZoneLocalTime(
      weekday: local.weekday,
      hour: local.hour,
      minute: local.minute,
      dayDelta: shifted.difference(origin).inDays,
    );
  }
}

class ZoneLocalTime {
  final int weekday;
  final int hour;
  final int minute;
  final int dayDelta;

  const ZoneLocalTime({
    required this.weekday,
    required this.hour,
    required this.minute,
    required this.dayDelta,
  });

  String get hhmm =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
