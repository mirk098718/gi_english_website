import 'package:gi_english_website/class/OnlineCourse.dart';
import 'package:gi_english_website/util/TeacherScheduleService.dart';

/// 주니어·재원생 화상의 매주 고정 시간.
///
/// 성인 온라인은 결제한 뒤 회차마다 빈 시간을 고른다.
/// 이 두 상품은 결제 전에 요일과 시간을 정하고, 그 칸을 결제한 주 수만큼
/// 같은 선생님 스케줄에 미리 넣는다.
class WeeklySlot {
  final int weekday;
  final String time;

  const WeeklySlot({required this.weekday, required this.time});

  String get key => '$weekday|$time';

  Map<String, dynamic> toMap() => {'weekday': weekday, 'time': time};

  static WeeklySlot? fromMap(dynamic raw) {
    if (raw is! Map) return null;
    final weekday = raw['weekday'];
    final day = weekday is int ? weekday : int.tryParse('$weekday');
    final time = raw['time']?.toString() ?? '';
    if (day == null || day < 1 || day > 7 || !RegExp(r'^\d{2}:\d{2}$').hasMatch(time)) {
      return null;
    }
    return WeeklySlot(weekday: day, time: time);
  }
}

class ScheduledLesson {
  final DateTime date;
  final String time;
  final int weekday;

  const ScheduledLesson({
    required this.date,
    required this.time,
    required this.weekday,
  });
}

class FixedScheduleShape {
  final int slotsPerWeek;
  final int weeks;

  const FixedScheduleShape({
    required this.slotsPerWeek,
    required this.weeks,
  });

  int get sessions => slotsPerWeek * weeks;
}

class FixedWeeklySchedule {
  /// 결제 직전 임시 점유. 이 시간이 지나면 결제되지 않은 점유는 다시 열린다.
  static const Duration holdFor = Duration(hours: 24);

  /// 하루 전. 이 시각이 지나면 그 회차는 옮기지 못한다.
  static const Duration changeLead = Duration(hours: 24);

  static FixedScheduleShape? shapeFor(OnlineCourse course) {
    if (!course.fixedSpeakingPrice) return null;
    final weeks = course.id.endsWith('_quarter') ? 12 : 4;
    if (weeks <= 0 || course.defaultSessions <= 0) return null;
    if (course.defaultSessions % weeks != 0) return null;
    final slots = course.defaultSessions ~/ weeks;
    if (slots <= 0) return null;
    return FixedScheduleShape(slotsPerWeek: slots, weeks: weeks);
  }

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime at(DateTime date, String time) {
    final parts = time.split(':');
    final hour = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    final day = dateOnly(date);
    return DateTime(day.year, day.month, day.day, hour, minute);
  }

  /// [earliest] 이후에 오는 첫 수업일. 오늘 시간이 이미 지났으면 다음 주다.
  static DateTime nextDate(WeeklySlot slot, DateTime earliest) {
    final start = dateOnly(earliest);
    var delta = slot.weekday - start.weekday;
    if (delta < 0) delta += 7;
    var date = start.add(Duration(days: delta));
    if (!at(date, slot.time).isAfter(earliest)) {
      date = date.add(const Duration(days: 7));
    }
    return dateOnly(date);
  }

  static List<ScheduledLesson> lessons({
    required List<WeeklySlot> slots,
    required int weeks,
    required DateTime now,
    DateTime? notBefore,
  }) {
    if (weeks <= 0 || slots.isEmpty) return const [];
    final earliest = notBefore ?? now;
    final items = <ScheduledLesson>[];
    for (final slot in slots) {
      final first = nextDate(slot, earliest);
      for (var i = 0; i < weeks; i++) {
        final date = dateOnly(first.add(Duration(days: 7 * i)));
        items.add(ScheduledLesson(
          date: date,
          time: slot.time,
          weekday: slot.weekday,
        ));
      }
    }
    items.sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      if (byDate != 0) return byDate;
      return a.time.compareTo(b.time);
    });
    return items;
  }

  static bool patternFits({
    required TeacherAvailability availability,
    required List<WeeklySlot> slots,
    required int weeks,
    required DateTime now,
    DateTime? notBefore,
  }) {
    if (slots.isEmpty || weeks <= 0) return false;
    final seen = <String>{};
    for (final slot in slots) {
      if (!seen.add(slot.key)) return false;
    }
    final items = lessons(
      slots: slots,
      weeks: weeks,
      now: now,
      notBefore: notBefore,
    );
    if (items.length != slots.length * weeks) return false;
    for (final item in items) {
      if (availability.isClosed(item.date, item.time)) return false;
      if (availability.isOccupied(item.date, item.time)) return false;
    }
    return true;
  }

  /// 그 요일·시간이 앞으로 [weeks]주 동안 모두 비어 있는 칸.
  static List<WeeklySlot> openSlots({
    required TeacherAvailability availability,
    required int weeks,
    required DateTime now,
    required List<String> times,
    DateTime? notBefore,
  }) {
    final open = <WeeklySlot>[];
    for (var weekday = 1; weekday <= 7; weekday++) {
      for (final time in times) {
        final slot = WeeklySlot(weekday: weekday, time: time);
        if (patternFits(
          availability: availability,
          slots: [slot],
          weeks: weeks,
          now: now,
          notBefore: notBefore,
        )) {
          open.add(slot);
        }
      }
    }
    return open;
  }
}
