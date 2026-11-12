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

  /// 30분 칸. 오전 6시부터 밤 11시까지. 예약 칸과 같다.
  static final List<String> timeSlots = _buildTimeSlots();

  static List<String> _buildTimeSlots() {
    final slots = <String>[];
    for (var hour = 6; hour <= 23; hour++) {
      slots.add('${hour.toString().padLeft(2, '0')}:00');
      if (hour < 23) slots.add('${hour.toString().padLeft(2, '0')}:30');
    }
    return slots;
  }

  static const int _slotMinutes = 30;
  static const int _narrowMinutes = 180;

  /// 매주 닫아 둔 칸을 뺀 뒤의 말.
  /// 넓은 구간은 오전·오후, 연속 3시간 이하는 아침·점심·저녁.
  /// 같은 요일에 둘 다 열려 있으면 오전과 오후를 함께 적는다.
  List<String> keywordsFor(Set<String> closedRoutines) {
    if (!active) return const [];
    final bySignature = <String, Set<int>>{};
    final labelsBySignature = <String, List<String>>{};
    for (final day in days.toList()..sort()) {
      final labels = _labelsForDay(day, closedRoutines);
      if (labels.isEmpty) continue;
      final signature = labels.join('|');
      bySignature.putIfAbsent(signature, () => <int>{}).add(day);
      labelsBySignature[signature] = labels;
    }
    final groups = bySignature.entries.toList()
      ..sort((a, b) => _min(a.value).compareTo(_min(b.value)));
    final lines = <String>[];
    for (final group in groups) {
      lines.addAll(_phrases(group.value, labelsBySignature[group.key]!));
    }
    return lines;
  }

  /// 매주 닫기가 없을 때의 말. 예: 평일 오후, 월화 오전, 오후.
  List<String> get keywords => keywordsFor(const {});

  List<String> _labelsForDay(int weekday, Set<String> closedRoutines) {
    final open = <String>[];
    for (final time in timeSlots) {
      if (!allows(weekday, time)) continue;
      if (closedRoutines.contains('${weekday}_$time')) continue;
      open.add(time);
    }
    final labels = <String>[];
    for (final run in _runs(open)) {
      labels.addAll(_labelRun(run));
    }
    return _dedupe(labels);
  }

  List<List<String>> _runs(List<String> open) {
    if (open.isEmpty) return const [];
    final index = <String, int>{
      for (var i = 0; i < timeSlots.length; i++) timeSlots[i]: i,
    };
    final runs = <List<String>>[];
    var current = <String>[open.first];
    for (var i = 1; i < open.length; i++) {
      final previous = index[open[i - 1]] ?? -1;
      final next = index[open[i]] ?? -1;
      if (next == previous + 1) {
        current.add(open[i]);
      } else {
        runs.add(current);
        current = <String>[open[i]];
      }
    }
    runs.add(current);
    return runs;
  }

  List<String> _labelRun(List<String> run) {
    final minutes = run.length * _slotMinutes;
    if (minutes > _narrowMinutes) {
      final startsAm = periodOf(run.first) == am;
      final endsPm = periodOf(run.last) == pm;
      if (startsAm && endsPm) return const ['오전', '오후'];
      return [startsAm ? '오전' : '오후'];
    }
    return [_narrowLabel(run)];
  }

  String _narrowLabel(List<String> run) {
    final start = _minutes(run.first);
    final middle = start + (run.length * _slotMinutes) ~/ 2;
    if (middle < 11 * 60) return '아침';
    if (middle < 17 * 60) return '점심';
    return '저녁';
  }

  static int _minutes(String time) {
    final parts = time.split(':');
    final hour = int.tryParse(parts.first) ?? 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return hour * 60 + minute;
  }

  static List<String> _dedupe(List<String> labels) {
    final seen = <String>{};
    final unique = <String>[];
    for (final label in labels) {
      if (seen.add(label)) unique.add(label);
    }
    return unique;
  }

  static int _min(Set<int> days) {
    var minDay = 8;
    for (final day in days) {
      if (day < minDay) minDay = day;
    }
    return minDay;
  }

  List<String> _phrases(Set<int> days, List<String> labels) {
    final weekdays = days.where((day) => day >= 1 && day <= 5).toSet();
    final weekend = days.where((day) => day == 6 || day == 7).toSet();
    final text = labels.join(', ');
    final lines = <String>[];
    if (weekdays.length == 5) {
      lines.add('평일 $text');
    } else if (weekdays.isNotEmpty) {
      lines.add('${_dayGroup(weekdays)} $text');
    }
    if (weekend.length == 2) {
      lines.add('주말 $text');
    } else if (weekend.length == 1) {
      lines.add('${_full[weekend.first]} $text');
    }
    return lines;
  }

  static String _dayGroup(Set<int> days) {
    final sorted = days.toList()..sort();
    if (sorted.length == 1) return _full[sorted.first]!;
    return sorted.map((day) => _short[day]).join();
  }
}
