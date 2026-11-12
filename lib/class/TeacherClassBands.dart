/// 강사가 고른 큰 수업 시간.
/// 요일과 오전·오후를 모두 골랐을 때만 시간표를 그 범위로 줄인다.
class TeacherClassBands {
  static const am = 'am';
  static const pm = 'pm';

  final Set<int> days;
  final Set<String> periods;

  const TeacherClassBands({
    this.days = const {},
    this.periods = const {},
  });

  static const empty = TeacherClassBands();

  static const _short = {
    1: '월',
    2: '화',
    3: '수',
    4: '목',
    5: '금',
    6: '토',
    7: '일',
  };

  static const _full = {
    1: '월요일',
    2: '화요일',
    3: '수요일',
    4: '목요일',
    5: '금요일',
    6: '토요일',
    7: '일요일',
  };

  bool get active => days.isNotEmpty && periods.isNotEmpty;

  static String periodOf(String time) {
    final hour = int.tryParse(time.split(':').first) ?? 0;
    return hour < 12 ? am : pm;
  }

  bool allows(int weekday, String time) {
    if (!active) return true;
    if (!days.contains(weekday)) return false;
    return periods.contains(periodOf(time));
  }

  TeacherClassBands toggleDay(int weekday) {
    if (weekday < 1 || weekday > 7) return this;
    final next = Set<int>.of(days);
    if (!next.add(weekday)) next.remove(weekday);
    return TeacherClassBands(days: next, periods: periods);
  }

  TeacherClassBands togglePeriod(String period) {
    if (period != am && period != pm) return this;
    final next = Set<String>.of(periods);
    if (!next.add(period)) next.remove(period);
    return TeacherClassBands(days: days, periods: next);
  }

  factory TeacherClassBands.fromMap(Map<String, dynamic>? data) {
    final map = data ?? const <String, dynamic>{};
    final days = <int>{};
    final rawDays = map['classDays'];
    if (rawDays is List) {
      for (final item in rawDays) {
        final day = item is int ? item : int.tryParse('$item');
        if (day != null && day >= 1 && day <= 7) days.add(day);
      }
    }
    final periods = <String>{};
    final rawPeriods = map['classPeriods'];
    if (rawPeriods is List) {
      for (final item in rawPeriods) {
        final period = item.toString();
        if (period == am || period == pm) periods.add(period);
      }
    }
    return TeacherClassBands(days: days, periods: periods);
  }

  Map<String, dynamic> toFirestore() {
    final dayList = days.toList()..sort();
    final periodList = <String>[
      if (periods.contains(am)) am,
      if (periods.contains(pm)) pm,
    ];
    return {
      'classDays': dayList,
      'classPeriods': periodList,
    };
  }

  /// 수강생 카드에 붙는 말. 예: 평일 오후, 일요일 오전, 월수금 오전.
  List<String> get keywords {
    if (!active) return const [];
    final lines = <String>[];
    for (final period in [am, pm]) {
      if (!periods.contains(period)) continue;
      final label = period == am ? '오전' : '오후';
      final weekdays = days.where((day) => day >= 1 && day <= 5).toSet();
      final weekend = days.where((day) => day == 6 || day == 7).toSet();
      if (weekdays.length == 5) {
        lines.add('평일 $label');
      } else if (weekdays.isNotEmpty) {
        lines.add('${_dayGroup(weekdays)} $label');
      }
      if (weekend.length == 2) {
        lines.add('주말 $label');
      } else if (weekend.length == 1) {
        lines.add('${_full[weekend.first]} $label');
      }
    }
    return lines;
  }

  static String _dayGroup(Set<int> days) {
    final sorted = days.toList()..sort();
    if (sorted.length == 1) return _full[sorted.first]!;
    return sorted.map((day) => _short[day]).join();
  }
}
