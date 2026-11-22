import 'package:flutter/material.dart';
import 'package:gi_english_website/util/SiteLayout.dart';
import 'package:gi_english_website/util/AppLanguage.dart';
import 'package:gi_english_website/class/JuniorLevel.dart';
import 'package:gi_english_website/class/OnlineCourse.dart';
import 'package:gi_english_website/class/OnlinePlan.dart';
import 'package:gi_english_website/class/OnlineNativeTeacher.dart';
import 'package:gi_english_website/pages/MemberLoginPage.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/EnrollmentService.dart';
import 'package:gi_english_website/util/FixedWeeklySchedule.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/TeacherScheduleService.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/PaymentService.dart';
import 'package:gi_english_website/widget/MobileSchoolLayout.dart';
import 'package:gi_english_website/widget/TeacherClassTimeLine.dart';
import 'package:gi_english_website/widget/OnlineProgramSideMenu.dart';
import 'package:gi_english_website/widget/WebSchoolLayout.dart';

import '../util/WidgetUtil.dart';

/// 과정 확정 후 · 결제 전 원어민 메인 강사 선택.
class OnlineTeacherSelectPage extends StatefulWidget {
  final OnlineCourse course;
  final bool extendEnrollment;
  final String plan;
  final int sessionCount;
  final JuniorLevel? juniorLevel;

  const OnlineTeacherSelectPage({
    Key? key,
    required this.course,
    this.extendEnrollment = false,
    this.plan = OnlinePlan.bundle,
    this.sessionCount = 0,
    this.juniorLevel,
  }) : super(key: key);

  @override
  State<OnlineTeacherSelectPage> createState() =>
      _OnlineTeacherSelectPageState();
}

class _OnlineTeacherSelectPageState extends State<OnlineTeacherSelectPage> {
  List<OnlineNativeTeacher> _teachers = [];
  OnlineNativeTeacher? _selected;
  bool _paying = false;
  bool _loading = true;
  bool _loadingSchedule = false;
  List<WeeklySlot> _openSlots = [];
  List<int> _weekdays = [];
  String? _clockTime;
  DateTime? _extensionStart;
  DateTime _startDate = FixedWeeklySchedule.dateOnly(DateTime.now());
  final GlobalKey _fixedTimeKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  Future<void> _loadTeachers() async {
    final teachers = await AuthService.selectableNativeTeachers(
      kind: TeacherPickKind.checkout,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _teachers = teachers;
      if (teachers.isEmpty) {
        _selected = null;
        return;
      }
      final currentId = _selected?.id;
      // 주니어·재원생은 강사를 고른 뒤에만 매주 시간을 연다.
      if (_needsFixedTime && (currentId == null || currentId.isEmpty)) {
        _selected = null;
      } else {
        _selected = teachers.firstWhere(
          (t) => t.id == currentId,
          orElse: () => teachers.first,
        );
      }
    });
    await _loadFixedSchedule();
  }

  void _selectTeacher(OnlineNativeTeacher teacher) {
    setState(() {
      _selected = teacher;
      _weekdays = [];
      _clockTime = null;
    });
    _loadFixedSchedule();
    if (!_needsFixedTime) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _fixedTimeKey.currentContext;
      if (target == null || !mounted) return;
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 320),
        alignment: 0.05,
      );
    });
  }

  bool get _needsFixedTime => widget.course.fixedSpeakingPrice;

  FixedScheduleShape? get _shape =>
      FixedWeeklySchedule.shapeFor(widget.course);

  Future<void> _loadFixedSchedule() async {
    if (!_needsFixedTime) return;
    final teacher = _selected;
    final shape = _shape;
    if (teacher == null || shape == null) {
      if (!mounted) return;
      setState(() {
        _openSlots = [];
        _weekdays = [];
        _clockTime = null;
        _loadingSchedule = false;
      });
      return;
    }
    setState(() => _loadingSchedule = true);
    var uid = teacher.accountUid;
    if (uid.isEmpty) {
      uid = await AuthService.uidForNativeProfile(teacher.id);
    }
    await EnrollmentService.sweepExpiredFixedHolds(uid);
    final availability = await TeacherScheduleService.load(uid);
    final notBefore = widget.extendEnrollment
        ? await EnrollmentService.fixedExtensionStart(widget.course.id)
        : null;
    final start = _clampedStart(notBefore);
    final open = FixedWeeklySchedule.openSlots(
      availability: availability,
      weeks: shape.weeks,
      now: DateTime.now(),
      times: EnrollmentService.bookingTimeSlots,
      notBefore: notBefore,
      startsOn: start,
    );
    if (!mounted) return;
    setState(() {
      _loadingSchedule = false;
      _extensionStart = notBefore;
      _startDate = start;
      _openSlots = open;
      _weekdays = _weekdays
          .where((day) => open.any((slot) => slot.weekday == day))
          .toList();
      final shared = _weekdays.length == shape.slotsPerWeek
          ? FixedWeeklySchedule.timesOpenOnEveryWeekday(
              open: open,
              weekdays: _weekdays,
            )
          : const <String>[];
      if (_clockTime != null && !shared.contains(_clockTime)) {
        _clockTime = null;
      }
    });
  }

  List<WeeklySlot> get _pickedSlots {
    final time = _clockTime;
    if (time == null) return const [];
    return FixedWeeklySchedule.slotsOnWeekdays(
      weekdays: _weekdays,
      time: time,
    );
  }

  Future<void> _startPayment() async {
    if (AuthService.currentUser == null) {
      MenuUtil.push(context, MemberLoginPage());
      return;
    }
    if (_selected == null) {
      _toast('원어민 강사를 선택해주세요.', error: true);
      return;
    }
    final shape = _shape;
    if (_needsFixedTime &&
        (shape == null ||
            _pickedSlots.length != shape.slotsPerWeek ||
            !FixedWeeklySchedule.sameClockTime(_pickedSlots))) {
      _toast('요일을 고른 뒤, 남은 시간 하나를 고르세요. 그 시간은 결제한 회차 모두에 같습니다.',
          error: true);
      return;
    }

    setState(() => _paying = true);
    final level = widget.course.id.startsWith('junior_') ? widget.juniorLevel : null;
    if (level != null) {
      final userId = AuthService.currentUser?.uid ?? '';
      if (userId.isNotEmpty) {
        await EnrollmentService.saveJuniorLevel(userId: userId, level: level);
      }
    }
    final order = await PaymentService.createOrder(
      course: widget.course,
      nativeTeacher: _selected!,
      extendEnrollment: widget.extendEnrollment,
      plan: widget.plan,
      juniorLevel: level,
      totalSessions: widget.course.sessionsFor(
        widget.plan,
        sessions: widget.sessionCount,
      ),
      fixedSlots: _needsFixedTime ? _pickedSlots : const [],
    );
    if (order == null) {
      if (!mounted) return;
      setState(() => _paying = false);
      _toast('주문을 생성하지 못했습니다. 로그인 상태를 확인해주세요.', error: true);
      return;
    }
    if (_needsFixedTime) {
      final holdError = await EnrollmentService.holdFixedSchedule(
        orderId: order.orderId,
        course: widget.course,
        teacher: _selected!,
        slots: _pickedSlots,
        extension: widget.extendEnrollment,
        startsOn: _startDate,
      );
      if (holdError != null) {
        if (!mounted) return;
        setState(() => _paying = false);
        _toast(holdError, error: true);
        await _loadFixedSchedule();
        return;
      }
    }

    final error = await PaymentService.requestTossPayment(order);
    if (!mounted) return;
    setState(() => _paying = false);
    if (error != null) {
      if (_needsFixedTime) {
        await EnrollmentService.releaseUnpaidFixedHold(order.orderId);
      }
      _toast(error, error: true);
    }
  }

  void _toast(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontFamily: 'NotoSansKR')),
        backgroundColor: error ? Palette.danger : Palette.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!useMobileSchoolLayout(context)) {
      return WebSchoolLayout(content: scrollView());
    }
    return MobileSchoolLayout(content: mobileScrollView());
  }

  Widget scrollView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          contentGroup(),
          MyWidget.footer(),
        ],
      ),
    );
  }

  Widget mobileScrollView() {
    return SingleChildScrollView(
      child: Container(
        color: Palette.white,
        child: Column(
          children: [
            OnlineProgramSideMenu(selectedIndex: OnlineProgramSideMenu.classroomIndex, isMobile: true),
            content(),
          ],
        ),
      ),
    );
  }

  Widget contentGroup() {
    return Container(
      color: Palette.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 232,
            child: OnlineProgramSideMenu(selectedIndex: OnlineProgramSideMenu.classroomIndex),
          ),
          Expanded(child: content()),
        ],
      ),
    );
  }

  bool get _fixedTimeReady {
    if (!_needsFixedTime) return true;
    final shape = _shape;
    return shape != null &&
        _pickedSlots.length == shape.slotsPerWeek &&
        FixedWeeklySchedule.sameClockTime(_pickedSlots);
  }

  void _toggleWeekday(int weekday) {
    final shape = _shape;
    if (shape == null) return;
    setState(() {
      if (_weekdays.contains(weekday)) {
        _weekdays.remove(weekday);
      } else if (_weekdays.length < shape.slotsPerWeek) {
        _weekdays = [..._weekdays, weekday]..sort();
      }
      _clockTime = null;
    });
  }

  void _selectClockTime(String time) {
    setState(() => _clockTime = _clockTime == time ? null : time);
  }

  DateTime _clampedStart(DateTime? notBefore) {
    final today = FixedWeeklySchedule.dateOnly(DateTime.now());
    var start = FixedWeeklySchedule.dateOnly(_startDate);
    if (start.isBefore(today)) start = today;
    if (notBefore != null) {
      final floor = FixedWeeklySchedule.dateOnly(notBefore);
      if (start.isBefore(floor)) start = floor;
    }
    return start;
  }

  Future<void> _pickStartDate() async {
    final today = FixedWeeklySchedule.dateOnly(DateTime.now());
    var first = today;
    final extension = _extensionStart;
    if (extension != null) {
      final floor = FixedWeeklySchedule.dateOnly(extension);
      if (floor.isAfter(first)) first = floor;
    }
    final initial = _startDate.isBefore(first) ? first : _startDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: today.add(const Duration(days: 180)),
      helpText: tr(context, '시작일'),
    );
    if (picked == null || !mounted) return;
    setState(() => _startDate = FixedWeeklySchedule.dateOnly(picked));
    await _loadFixedSchedule();
  }

  Widget _fixedTimeSection() {
    final shape = _shape;
    if (shape == null) return const SizedBox.shrink();
    const names = ['월', '화', '수', '목', '금', '토', '일'];
    final openDays = FixedWeeklySchedule.weekdaysWithOpenTime(_openSlots);
    final daysReady = _weekdays.length == shape.slotsPerWeek;
    final sharedTimes = daysReady
        ? FixedWeeklySchedule.timesOpenOnEveryWeekday(
            open: _openSlots,
            weekdays: _weekdays,
          )
        : const <String>[];
    final lessons = _fixedTimeReady
        ? FixedWeeklySchedule.lessons(
            slots: _pickedSlots,
            weeks: shape.weeks,
            now: DateTime.now(),
            notBefore: _extensionStart,
            startsOn: _startDate,
          )
        : const <ScheduledLesson>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, '매주 고정 시간'),
          style: TextStyle(fontFamily: 'Jalnan', fontSize: 15),
        ),
        SizedBox(height: 8),
        Text(
          tf(context, '먼저 요일을 {p0}개 고르세요. 요일을 다 고르면 이 선생님에게 남은 시간이 열립니다. 그 시간은 결제한 {p1}회 모두 같습니다.', {
            'p0': shape.slotsPerWeek,
            'p1': shape.sessions,
          }),
          style: TextStyle(
            fontFamily: 'NotoSansKR',
            fontSize: 13,
            height: 1.5,
            color: Palette.grey600,
          ),
        ),
        SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _paying ? null : _pickStartDate,
          icon: const Icon(Icons.event, size: 18),
          label: Text(
            tf(context, '시작일 {p0}', {
              'p0': EnrollmentService.formatBookingDate(_startDate),
            }),
            style: TextStyle(fontFamily: 'NotoSansKR'),
          ),
        ),
        SizedBox(height: 6),
        Text(
          tr(context, '이 날부터 매주 수업이 들어갑니다. 오늘보다 뒤로 미룰 수 있습니다.'),
          style: TextStyle(
            fontFamily: 'NotoSansKR',
            fontSize: 12,
            height: 1.5,
            color: Palette.grey600,
          ),
        ),
        SizedBox(height: 12),
        if (_loadingSchedule)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (openDays.isEmpty)
          Text(
            tr(context, '이 선생님이 열어 둔 시간 중, 결제한 기간 동안 모두 비어 있는 시간이 없습니다.'),
            style: TextStyle(
              fontFamily: 'NotoSansKR',
              fontSize: 13,
              height: 1.5,
              color: Palette.grey600,
            ),
          )
        else ...[
          Text(
            tr(context, '요일'),
            style: TextStyle(
              fontFamily: 'NotoSansKR',
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: openDays.map((day) {
              final selected = _weekdays.contains(day);
              final full = _weekdays.length >= shape.slotsPerWeek;
              return ChoiceChip(
                label: Text(
                  tr(context, names[day - 1]),
                  style: TextStyle(fontFamily: 'NotoSansKR'),
                ),
                selected: selected,
                onSelected: (!selected && full) ? null : (_) => _toggleWeekday(day),
              );
            }).toList(),
          ),
          if (daysReady) ...[
            SizedBox(height: 16),
            Text(
              tr(context, '시간'),
              style: TextStyle(
                fontFamily: 'NotoSansKR',
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            SizedBox(height: 6),
            if (sharedTimes.isEmpty)
              Text(
                tr(context, '고른 요일에 공통으로 남은 시간이 없습니다. 요일을 다시 고르세요.'),
                style: TextStyle(
                  fontFamily: 'NotoSansKR',
                  fontSize: 13,
                  height: 1.5,
                  color: Palette.grey600,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: sharedTimes.map((time) {
                  return ChoiceChip(
                    label: Text(
                      EnrollmentService.formatBookingTime(time),
                      style: TextStyle(fontFamily: 'NotoSansKR'),
                    ),
                    selected: _clockTime == time,
                    onSelected: (_) => _selectClockTime(time),
                  );
                }).toList(),
              ),
          ],
        ],
        if (lessons.isNotEmpty) ...[
          SizedBox(height: 4),
          Text(
            tf(context, '이렇게 {p0}회가 미리 들어갑니다.', {'p0': lessons.length}),
            style: TextStyle(
              fontFamily: 'NotoSansKR',
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Palette.secondaryDark,
            ),
          ),
          SizedBox(height: 6),
          ...lessons.take(8).map(
                (lesson) => Text(
                  '${EnrollmentService.formatBookingDate(lesson.date)} ${EnrollmentService.formatBookingTime(lesson.time)}',
                  style: TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontSize: 12,
                    height: 1.5,
                    color: Palette.grey700,
                  ),
                ),
              ),
          if (lessons.length > 8)
            Text(
              tf(context, '외 {p0}회', {'p0': lessons.length - 8}),
              style: TextStyle(
                fontFamily: 'NotoSansKR',
                fontSize: 12,
                color: Palette.grey600,
              ),
            ),
        ],
      ],
    );
  }

  String _orderSummary(OnlineCourse course) {
    final sessions = course.sessionsFor(
      widget.plan,
      sessions: widget.sessionCount,
    );
    final amount = OnlinePlan.won(
      course.amountFor(widget.plan, sessions: widget.sessionCount),
    );
    if (course.fixedSpeakingPrice) {
      return tf(context, '{p0} · 화상 {p1}회 · {p2}', {
        'p0': tr(context, course.subtitle),
        'p1': sessions,
        'p2': amount,
      });
    }
    if (widget.plan == OnlinePlan.speaking) {
      return '원어민 화상 1:1 회화 $sessions회 · $amount';
    }
    return '화상 $sessions회 · $amount';
  }

  Widget content() {
    final course = widget.course;
    return Container(
      alignment: Alignment.topLeft,
      width: double.maxFinite,
      padding: EdgeInsets.all(20),
      color: Palette.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr(context, "원어민 강사 선택"),
              style: TextStyle(fontFamily: 'Jalnan', fontSize: 20)),
          WidgetUtil.myDivider(),
          SizedBox(height: 12),
          Text(
            tr(
              context,
              _needsFixedTime
                  ? "주니어와 재원생 화상은 결제 전에 요일을 고르고, 그 선생님 스케줄에 남은 시간 하나를 고릅니다.\n고른 시간은 결제한 회차 모두에 같고, 그 기간 동안 선생님 스케줄에 미리 들어갑니다.\n하루 전에 한 회차만 못 하면, 고정 시간이 아니어도 선생님이 되는 빈 시간을 골라야만 그 회차를 옮길 수 있습니다."
                  : "선택한 과정을 담당할 메인 원어민 강사입니다.\n이후 화상수업은 이 선생님을 중심으로 진행되며, 해당 선생님이 열어 둔 시간에만 예약할 수 있습니다.\n메인 강사는 나중에 바꿀 수 있습니다. 하루 일정이 안 맞으면 다른 선생님으로 예약하고, 마음에 들면 그 선생님을 메인 강사로 고정할 수 있습니다.",
            ),
            style: TextStyle(
              fontFamily: 'NotoSansKR',
              fontSize: 13,
              height: 1.6,
              color: Palette.grey600,
            ),
          ),
          SizedBox(height: 20),
          Container(
            width: double.maxFinite,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Palette.grey50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Palette.grey200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr(context, "선택한 과정"),
                    style: TextStyle(
                        fontFamily: 'NotoSansKR',
                        fontSize: 12,
                        color: Palette.grey500)),
                SizedBox(height: 6),
                Text('${course.order}. ${course.localizedName(context, widget.plan)}',
                    style: TextStyle(
                        fontFamily: 'NotoSansKR',
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                SizedBox(height: 4),
                Text(
                    _orderSummary(course),
                    style: TextStyle(
                        fontFamily: 'NotoSansKR',
                        fontSize: 13,
                        color: Palette.grey600)),
              ],
            ),
          ),
          SizedBox(height: 24),
          Text(tr(context, "강사 선택"), style: TextStyle(fontFamily: 'Jalnan', fontSize: 15)),
          SizedBox(height: 12),
          if (_loading)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_teachers.isEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                tr(context, "현재 선택할 수 있는 원어민 강사가 없습니다. 학원으로 문의해 주세요."),
                style: TextStyle(
                  fontFamily: 'NotoSansKR',
                  fontSize: 13,
                  color: Palette.grey600,
                ),
              ),
            )
          else
            OnlineTeacherCardGrid(
              teachers: _teachers,
              selectedId: _selected?.id,
              onSelected: _selectTeacher,
            ),
          SizedBox(height: 24),
          if (_selected != null) ...[
            Text(
              _selected!.nationality.trim().isEmpty
                  ? '메인 강사: ${_selected!.name}'
                  : '메인 강사: ${_selected!.name} (${_selected!.nationality})',
              style: TextStyle(
                fontFamily: 'NotoSansKR',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Palette.secondaryDark,
              ),
            ),
            SizedBox(height: 16),
          ],
          if (_needsFixedTime && _selected == null && !_loading) ...[
            Text(
              tr(context, '원어민 강사를 고르면 요일을 먼저 고르고, 그 다음에 시간이 열립니다.'),
              style: TextStyle(
                fontFamily: 'NotoSansKR',
                fontSize: 13,
                height: 1.5,
                color: Palette.grey600,
              ),
            ),
            SizedBox(height: 20),
          ],
          if (_needsFixedTime && _selected != null) ...[
            KeyedSubtree(key: _fixedTimeKey, child: _fixedTimeSection()),
            SizedBox(height: 20),
          ],
          SizedBox(
            width: double.maxFinite,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Palette.secondaryDark,
                foregroundColor: Palette.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: (_paying || _selected == null || !_fixedTimeReady)
                  ? null
                  : _startPayment,
              icon: Icon(Icons.payment, color: Palette.white),
              label: Text(
                _paying
                    ? tr(context, "결제창 여는 중...")
                    : tr(
                        context,
                        widget.extendEnrollment
                            ? "선택 완료 · 연장 결제하기"
                            : "선택 완료 · 결제하기",
                      ),
                style: TextStyle(fontFamily: 'Jalnan', fontSize: 15),
              ),
            ),
          ),
          SizedBox(height: 40),
        ],
      ),
    );
  }

}

/// 결제 전 원어민 강사 카드. 웹은 한 줄에 3명, 모바일은 한 줄에 1명.
class OnlineTeacherCardGrid extends StatelessWidget {
  final List<OnlineNativeTeacher> teachers;
  final String? selectedId;
  final ValueChanged<OnlineNativeTeacher> onSelected;

  const OnlineTeacherCardGrid({
    Key? key,
    required this.teachers,
    required this.selectedId,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final web = !useMobileSchoolLayout(context);
        if (!web) {
          return Column(
            children: teachers
                .map((t) => Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: _card(context, t),
                    ))
                .toList(),
          );
        }
        const spacing = 16.0;
        const columns = 3;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: teachers
              .map((t) => SizedBox(
                    width: width,
                    child: _card(context, t, compact: true),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _card(BuildContext context, OnlineNativeTeacher teacher,
      {bool compact = false}) {
    final selected = selectedId == teacher.id;
    const radius = 16.0;
    final borderWidth = selected ? 2.5 : 1.0;
    return InkWell(
      key: ValueKey('teacher-card-${teacher.id}'),
      onTap: () => onSelected(teacher),
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        decoration: BoxDecoration(
          color: selected
              ? Palette.secondary.withValues(alpha: 0.06)
              : Palette.white,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: selected ? Palette.darkTeal : Palette.grey200,
            width: borderWidth,
          ),
        ),
        padding: EdgeInsets.all(borderWidth),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius - borderWidth),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: compact ? 148 : 220,
                  child: teacher.photoFill(),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Palette.white.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      selected
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      color: selected ? Palette.darkTeal : Palette.grey400,
                      size: 26,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    teacher.name,
                    style: TextStyle(
                      fontFamily: 'Jalnan',
                      fontSize: 20,
                    ),
                  ),
                  if (teacher.nationality.trim().isNotEmpty) ...[
                    SizedBox(height: 8),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Palette.grey100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        teacher.nationality,
                        style: TextStyle(
                          fontFamily: 'NotoSansKR',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Palette.grey700,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: 12),
                  Text(
                    teacher.intro.trim().isEmpty
                        ? tr(context, "소개가 곧 업데이트됩니다.")
                        : teacher.intro,
                    style: TextStyle(
                      fontFamily: 'NotoSansKR',
                      fontSize: 14,
                      height: 1.55,
                      color: Palette.grey700,
                    ),
                  ),
                  TeacherClassTimeLine(
                    bands: teacher.classBands,
                    closedRoutines: teacher.closedRoutineKeys,
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
