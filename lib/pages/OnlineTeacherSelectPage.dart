import 'package:flutter/material.dart';
import 'package:gi_english_website/util/SiteLayout.dart';
import 'package:gi_english_website/util/AppLanguage.dart';
import 'package:gi_english_website/class/OnlineCourse.dart';
import 'package:gi_english_website/class/OnlinePlan.dart';
import 'package:gi_english_website/class/OnlineNativeTeacher.dart';
import 'package:gi_english_website/pages/MemberLoginPage.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
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

  const OnlineTeacherSelectPage({
    Key? key,
    required this.course,
    this.extendEnrollment = false,
    this.plan = OnlinePlan.bundle,
    this.sessionCount = 0,
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
      _selected = teachers.firstWhere(
        (t) => t.id == currentId,
        orElse: () => teachers.first,
      );
    });
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

    setState(() => _paying = true);
    final order = await PaymentService.createOrder(
      course: widget.course,
      nativeTeacher: _selected!,
      extendEnrollment: widget.extendEnrollment,
      plan: widget.plan,
      totalSessions: widget.course.sessionsFor(
        widget.plan,
        sessions: widget.sessionCount,
      ),
    );
    if (order == null) {
      if (!mounted) return;
      setState(() => _paying = false);
      _toast('주문을 생성하지 못했습니다. 로그인 상태를 확인해주세요.', error: true);
      return;
    }

    final error = await PaymentService.requestTossPayment(order);
    if (!mounted) return;
    setState(() => _paying = false);
    if (error != null) {
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

  String _orderSummary(OnlineCourse course) {
    final sessions = course.sessionsFor(
      widget.plan,
      sessions: widget.sessionCount,
    );
    final amount = OnlinePlan.won(
      course.amountFor(widget.plan, sessions: widget.sessionCount),
    );
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
            tr(context, "선택한 과정을 담당할 메인 원어민 강사입니다.\n이후 화상수업은 이 선생님을 중심으로 진행되며, 해당 선생님이 열어 둔 시간에만 예약할 수 있습니다.\n메인 강사는 나중에 바꿀 수 있습니다. 하루 일정이 안 맞으면 다른 선생님으로 예약하고, 마음에 들면 그 선생님을 메인 강사로 고정할 수 있습니다."),
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
              onSelected: (teacher) => setState(() => _selected = teacher),
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
              onPressed: (_paying || _selected == null) ? null : _startPayment,
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
