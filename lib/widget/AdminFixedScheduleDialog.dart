import 'package:flutter/material.dart';
import 'package:gi_english_website/class/OnlineCourse.dart';
import 'package:gi_english_website/class/OnlineNativeTeacher.dart';
import 'package:gi_english_website/class/TeacherClassBands.dart';
import 'package:gi_english_website/util/AppLanguage.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/EnrollmentService.dart';
import 'package:gi_english_website/util/FixedWeeklySchedule.dart';
import 'package:gi_english_website/util/Palette.dart';

/// 메인 관리자가 주니어·재원생 화상의 매주 요일과 시간을 정하는 창.
class AdminFixedScheduleDialog extends StatefulWidget {
  final String userId;
  final String email;
  final String memberName;
  final String phone;
  final String preferredTeacherUid;
  final OnlineCourse course;
  final int totalSessions;

  const AdminFixedScheduleDialog({
    Key? key,
    required this.userId,
    required this.email,
    required this.memberName,
    required this.phone,
    required this.preferredTeacherUid,
    required this.course,
    required this.totalSessions,
  }) : super(key: key);

  static Future<bool> open(
    BuildContext context, {
    required String userId,
    required String email,
    required String memberName,
    required String phone,
    required String preferredTeacherUid,
    required OnlineCourse course,
    required int totalSessions,
  }) async {
    final shape = FixedWeeklySchedule.shapeFor(course);
    if (shape == null) return false;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AdminFixedScheduleDialog(
        userId: userId,
        email: email,
        memberName: memberName,
        phone: phone,
        preferredTeacherUid: preferredTeacherUid,
        course: course,
        totalSessions: totalSessions,
      ),
    );
    return saved == true;
  }

  @override
  State<AdminFixedScheduleDialog> createState() =>
      _AdminFixedScheduleDialogState();
}

class _AdminFixedScheduleDialogState extends State<AdminFixedScheduleDialog> {
  List<OnlineNativeTeacher> _teachers = [];
  OnlineNativeTeacher? _teacher;
  final Set<int> _days = {};
  String? _time;
  DateTime _startDate = FixedWeeklySchedule.dateOnly(DateTime.now());
  bool _loading = true;
  bool _saving = false;
  String? _error;

  FixedScheduleShape? get _shape =>
      FixedWeeklySchedule.shapeFor(widget.course);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final teachers = await AuthService.activeNativeTeachers();
    if (!mounted) return;
    OnlineNativeTeacher? selected;
    for (final teacher in teachers) {
      if (teacher.accountUid == widget.preferredTeacherUid &&
          widget.preferredTeacherUid.isNotEmpty) {
        selected = teacher;
        break;
      }
    }
    selected ??= teachers.isEmpty ? null : teachers.first;
    setState(() {
      _teachers = teachers;
      _teacher = selected;
      _loading = false;
    });
  }

  List<WeeklySlot> get _slots {
    final time = _time;
    if (time == null) return const [];
    return FixedWeeklySchedule.slotsOnWeekdays(
      weekdays: _days.toList(),
      time: time,
    );
  }

  String _preview() {
    final shape = _shape;
    final time = _time;
    if (shape == null || time == null || _days.length != shape.slotsPerWeek) {
      return '';
    }
    if (widget.totalSessions <= 0 ||
        widget.totalSessions % shape.slotsPerWeek != 0) {
      return '';
    }
    final weeks = widget.totalSessions ~/ shape.slotsPerWeek;
    final lessons = FixedWeeklySchedule.lessons(
      slots: _slots,
      weeks: weeks,
      now: DateTime.now(),
      startsOn: _startDate,
    );
    if (lessons.isEmpty) return '';
    final first = lessons.first;
    final last = lessons.last;
    final firstLabel =
        '${EnrollmentService.formatBookingDate(first.date)} ${EnrollmentService.formatBookingTime(first.time)}';
    if (lessons.length == 1) return '1회차 $firstLabel';
    final lastLabel =
        '${EnrollmentService.formatBookingDate(last.date)} ${EnrollmentService.formatBookingTime(last.time)}';
    return '1회차 $firstLabel\n${lessons.length}회차 $lastLabel';
  }

  Future<void> _save() async {
    final teacher = _teacher;
    final shape = _shape;
    if (teacher == null || shape == null) return;
    if (_days.length != shape.slotsPerWeek || _time == null) {
      setState(() {
        _error = '요일을 ${shape.slotsPerWeek}개 고르고, 같은 시간을 정해 주세요.';
      });
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await EnrollmentService.placeAdminFixedSchedule(
      userId: widget.userId,
      email: widget.email,
      memberName: widget.memberName,
      phone: widget.phone,
      courseId: widget.course.id,
      totalSessions: widget.totalSessions,
      teacher: teacher,
      slots: _slots,
      startsOn: _startDate,
    );
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _saving = false;
        _error = error;
      });
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final shape = _shape;
    final slotsPerWeek = shape?.slotsPerWeek ?? 1;
    final preview = _preview();
    return AlertDialog(
      title: Text(tr(context, '수업 시간 정하기'),
          style: TextStyle(fontFamily: "Jalnan")),
      content: SizedBox(
        width: 460,
        child: _loading
            ? const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(context,
                          '이 수강생의 매주 수업 요일과 시간을 정합니다. 고른 시작일부터 전체 회차만큼 들어갑니다.'),
                      style: TextStyle(
                        fontFamily: "NotoSansKR",
                        fontSize: 13,
                        height: 1.45,
                        color: Palette.grey600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: _saving ? null : _pickStartDate,
                      icon: const Icon(Icons.event, size: 18),
                      label: Text(
                        tf(context, '시작일 {p0}', {
                          'p0': EnrollmentService.formatBookingDate(_startDate),
                        }),
                        style: TextStyle(fontFamily: "NotoSansKR"),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (_teachers.isEmpty)
                      Text(
                        tr(context, '선택할 선생님이 없습니다.'),
                        style: TextStyle(
                          fontFamily: "NotoSansKR",
                          color: Palette.danger,
                        ),
                      )
                    else
                      DropdownButtonFormField<OnlineNativeTeacher>(
                        initialValue: _teacher,
                        decoration: InputDecoration(
                          labelText: tr(context, '선생님'),
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          for (final teacher in _teachers)
                            DropdownMenuItem(
                              value: teacher,
                              child: Text(teacher.name,
                                  style:
                                      TextStyle(fontFamily: "NotoSansKR")),
                            ),
                        ],
                        onChanged: _saving
                            ? null
                            : (value) => setState(() => _teacher = value),
                      ),
                    const SizedBox(height: 14),
                    Text(
                      tf(context, '요일을 {p0}개 고르세요.', {'p0': slotsPerWeek}),
                      style: TextStyle(
                        fontFamily: "NotoSansKR",
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: [
                        for (final day in [1, 2, 3, 4, 5, 6, 7])
                          FilterChip(
                            label: Text(
                              tr(context, _dayLabel(day)),
                              style: TextStyle(fontFamily: "NotoSansKR"),
                            ),
                            selected: _days.contains(day),
                            onSelected: _saving
                                ? null
                                : (selected) {
                                    setState(() {
                                      if (selected) {
                                        if (_days.length >= slotsPerWeek) {
                                          _error =
                                              '요일을 $slotsPerWeek개 고르고, 같은 시간을 정해 주세요.';
                                          return;
                                        }
                                        _days.add(day);
                                      } else {
                                        _days.remove(day);
                                      }
                                      _error = null;
                                    });
                                  },
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _time,
                      decoration: InputDecoration(
                        labelText: tr(context, '시간'),
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        for (final time in TeacherClassBands.timeSlots)
                          DropdownMenuItem(
                            value: time,
                            child: Text(
                              EnrollmentService.formatBookingTime(time),
                              style: TextStyle(fontFamily: "NotoSansKR"),
                            ),
                          ),
                      ],
                      onChanged: _saving
                          ? null
                          : (value) => setState(() {
                                _time = value;
                                _error = null;
                              }),
                    ),
                    if (preview.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        preview,
                        style: TextStyle(
                          fontFamily: "NotoSansKR",
                          fontSize: 13,
                          height: 1.45,
                          color: Palette.secondaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        tr(context, _error!),
                        style: TextStyle(
                          fontFamily: "NotoSansKR",
                          fontSize: 13,
                          color: Palette.danger,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: Text(tr(context, '닫기')),
        ),
        ElevatedButton(
          onPressed: _saving || _teachers.isEmpty ? null : _save,
          child: Text(tr(context, _saving ? '저장 중' : '이 시간으로 넣기')),
        ),
      ],
    );
  }

  Future<void> _pickStartDate() async {
    final today = FixedWeeklySchedule.dateOnly(DateTime.now());
    final initial = _startDate.isBefore(today) ? today : _startDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: today.add(const Duration(days: 180)),
      helpText: tr(context, '시작일'),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _startDate = FixedWeeklySchedule.dateOnly(picked);
      _error = null;
    });
  }

  String _dayLabel(int day) {
    const labels = ['월', '화', '수', '목', '금', '토', '일'];
    return labels[day - 1];
  }
}
