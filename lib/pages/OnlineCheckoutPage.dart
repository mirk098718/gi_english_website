import 'package:flutter/material.dart';
import 'package:gi_english_website/util/SiteLayout.dart';
import 'package:gi_english_website/util/AppLanguage.dart';
import 'package:gi_english_website/class/OnlineCourse.dart';
import 'package:gi_english_website/class/OnlinePlan.dart';
import 'package:gi_english_website/pages/MemberLoginPage.dart';
import 'package:gi_english_website/pages/OnlineTeacherSelectPage.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/EnrollmentService.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/PaymentService.dart';
import 'package:gi_english_website/widget/MobileSchoolLayout.dart';
import 'package:gi_english_website/widget/OnlineProgramSideMenu.dart';
import 'package:gi_english_website/widget/WebSchoolLayout.dart';

import '../util/WidgetUtil.dart';

/// 온라인 프로그램 결제(과정 선택) 페이지.
/// 과정 선택 후 원어민 강사 선택 화면으로 이동한다.
class OnlineCheckoutPage extends StatefulWidget {
  final String? initialCourseId;
  final bool extendEnrollment;
  final String? initialPlan;
  final int? initialSessions;

  const OnlineCheckoutPage({
    Key? key,
    this.initialCourseId,
    this.extendEnrollment = false,
    this.initialPlan,
    this.initialSessions,
  }) : super(key: key);

  @override
  _OnlineCheckoutPageState createState() => _OnlineCheckoutPageState();
}

class _OnlineCheckoutPageState extends State<OnlineCheckoutPage> {
  OnlineCourse? _selected;
  late String _plan;
  late int _speakingSessions;
  List<PaymentOrder> _myPayments = [];
  bool _paying = false;

  @override
  void initState() {
    super.initState();
    _plan = OnlinePlan.resolve(
      stored: widget.initialPlan,
      courseId: widget.initialCourseId,
    );
    _speakingSessions = widget.initialSessions ?? 8;
    if (_speakingSessions <= 0) _speakingSessions = 8;
    if (widget.initialCourseId != null) {
      _selected = OnlineCourse.findById(widget.initialCourseId!);
    }
    if (_plan == OnlinePlan.speaking) {
      _selected = OnlineCourse.speaking;
    }
    _selected ??= OnlineCourse.all.first;
    _loadMyPayments();
  }

  Future<void> _loadMyPayments() async {
    if (AuthService.currentUser == null) return;
    final list = await PaymentService.myPayments();
    if (!mounted) return;
    setState(() => _myPayments = list);
  }

  void _goTeacherSelect() {
    if (AuthService.currentUser == null) {
      MenuUtil.push(context, MemberLoginPage());
      return;
    }
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(context, "과정을 선택해주세요."),
              style: TextStyle(fontFamily: "NotoSansKR")),
          backgroundColor: Palette.danger,
        ),
      );
      return;
    }
    if (_plan == OnlinePlan.lecture) {
      _paySelected();
      return;
    }
    MenuUtil.push(
      context,
      OnlineTeacherSelectPage(
        course: _plan == OnlinePlan.speaking
            ? OnlineCourse.speaking
            : _selected!,
        extendEnrollment: widget.extendEnrollment,
        plan: _plan,
        sessionCount: _speakingSessions,
      ),
    );
  }

  Future<void> _paySelected() async {
    if (AuthService.currentUser == null) {
      MenuUtil.push(context, MemberLoginPage());
      return;
    }
    final course = _plan == OnlinePlan.speaking
        ? OnlineCourse.speaking
        : _selected;
    if (course == null || _paying) return;
    setState(() => _paying = true);
    final order = await PaymentService.createOrder(
      course: course,
      plan: _plan,
      totalSessions: course.sessionsFor(_plan, sessions: _speakingSessions),
      extendEnrollment: widget.extendEnrollment,
    );
    if (!mounted) return;
    if (order == null) {
      setState(() => _paying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(context, "주문을 생성하지 못했습니다. 로그인 상태를 확인해주세요."),
              style: TextStyle(fontFamily: "NotoSansKR")),
          backgroundColor: Palette.danger,
        ),
      );
      return;
    }
    final error = await PaymentService.requestTossPayment(order);
    if (!mounted) return;
    setState(() => _paying = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error, style: TextStyle(fontFamily: "NotoSansKR")),
          backgroundColor: Palette.danger,
        ),
      );
    }
  }

  Future<void> _payExtension() async {
    if (AuthService.currentUser == null) {
      MenuUtil.push(context, MemberLoginPage());
      return;
    }
    final course = _selected;
    if (course == null || _paying) return;
    final enrollments = await EnrollmentService.myEnrollments();
    EnrollmentRecord? record;
    for (final item in enrollments) {
      if (item.courseId == course.id) {
        record = item;
        break;
      }
    }
    final teacher = record?.nativeTeacher;
    if (teacher == null) {
      if (!mounted) return;
      MenuUtil.push(
        context,
        OnlineTeacherSelectPage(course: course, extendEnrollment: true),
      );
      return;
    }
    setState(() => _paying = true);
    final order = await PaymentService.createOrder(
      course: course,
      nativeTeacher: teacher,
      extendEnrollment: true,
      plan: _plan,
      totalSessions: course.sessionsFor(_plan, sessions: _speakingSessions),
    );
    if (!mounted) return;
    if (order == null) {
      setState(() => _paying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(context, "주문을 생성하지 못했습니다. 로그인 상태를 확인해주세요."),
              style: TextStyle(fontFamily: "NotoSansKR")),
          backgroundColor: Palette.danger,
        ),
      );
      return;
    }
    final error = await PaymentService.requestTossPayment(order);
    if (!mounted) return;
    setState(() => _paying = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error, style: TextStyle(fontFamily: "NotoSansKR")),
          backgroundColor: Palette.danger,
        ),
      );
    }
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
            OnlineProgramSideMenu(selectedIndex: 1, isMobile: true),
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
            child: OnlineProgramSideMenu(selectedIndex: 1),
          ),
          Expanded(child: content()),
        ],
      ),
    );
  }

  Widget content() {
    final loggedIn = AuthService.currentUser != null;

    return Container(
      alignment: Alignment.topLeft,
      width: double.maxFinite,
      padding: EdgeInsets.all(20),
      color: Palette.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, widget.extendEnrollment ? "수강 연장 결제" : "프로그램 결제"),
            style: TextStyle(fontFamily: "Jalnan", fontSize: 20),
          ),
          WidgetUtil.myDivider(),
          SizedBox(height: 12),
          Text(
            tr(
              context,
              widget.extendEnrollment
                  ? "기한이 지난 수강에 회차와 수강 기한을 더합니다. 인강만 상품은 기간만 늘어나고, 이미 진행한 회차는 그대로 남습니다. (테스트 결제: 실제 출금되지 않습니다)"
                  : "상품과 과정을 고른 뒤 결제합니다. 화상이 포함된 상품은 원어민 강사를 고릅니다.\n결제 완료 시 내 강의실에 과정이 자동으로 배정됩니다. (테스트 결제: 실제 출금되지 않습니다)",
            ),
            style: TextStyle(
                fontFamily: "NotoSansKR",
                fontSize: 13,
                height: 1.6,
                color: Palette.grey600),
          ),
          SizedBox(height: 24),
          if (!loggedIn) ...[
            Container(
              width: double.maxFinite,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Palette.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Palette.grey200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr(context, "로그인이 필요합니다"),
                      style: TextStyle(
                          fontFamily: "Jalnan",
                          fontSize: 15,
                          color: Palette.secondaryDark)),
                  SizedBox(height: 10),
                  Text(tr(context, "결제 전 회원 로그인 또는 회원가입을 진행해주세요."),
                      style: TextStyle(fontFamily: "NotoSansKR", fontSize: 13)),
                  SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Palette.secondaryDark,
                      foregroundColor: Palette.white,
                    ),
                    onPressed: () => MenuUtil.push(context, MemberLoginPage()),
                    child:
                        Text(tr(context, "회원 로그인"), style: TextStyle(fontFamily: "Jalnan")),
                  ),
                ],
              ),
            ),
          ] else ...[
            if (!widget.extendEnrollment) ...[
              Text(tr(context, "상품 선택"),
                  style: TextStyle(fontFamily: "Jalnan", fontSize: 15)),
              SizedBox(height: 12),
              _planSwitcher(),
              SizedBox(height: 24),
            ],
            if (_plan == OnlinePlan.speaking) ...[
              Text('화상 횟수', style: TextStyle(fontFamily: "Jalnan", fontSize: 15)),
              SizedBox(height: 12),
              _sessionPicker(),
            ] else ...[
              Text(tr(context, "과정 선택"),
                  style: TextStyle(fontFamily: "Jalnan", fontSize: 15)),
              SizedBox(height: 12),
              ...OnlineCourse.all.map(_courseOption),
            ],
            SizedBox(height: 24),
            if (_selected != null) _summaryCard(_selected!),
            SizedBox(height: 20),
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
                onPressed: _paying
                    ? null
                    : (widget.extendEnrollment
                        ? (_plan == OnlinePlan.lecture
                            ? _paySelected
                            : _payExtension)
                        : _goTeacherSelect),
                icon: Icon(Icons.arrow_forward, color: Palette.white),
                label: Text(
                  tr(
                    context,
                    _paying
                        ? "결제창 여는 중..."
                    : (widget.extendEnrollment
                        ? "연장 결제하기"
                        : (_plan == OnlinePlan.lecture
                            ? "인강 결제하기"
                            : "다음 · 원어민 강사 선택")),
                  ),
                  style: TextStyle(fontFamily: "Jalnan", fontSize: 15),
                ),
              ),
            ),
            SizedBox(height: 32),
            Text(tr(context, "내 결제 내역"),
                style: TextStyle(fontFamily: "Jalnan", fontSize: 15)),
            SizedBox(height: 12),
            if (_myPayments.isEmpty)
              Text(tr(context, "아직 결제 내역이 없습니다."),
                  style: TextStyle(
                      fontFamily: "NotoSansKR", color: Palette.grey500))
            else
              ..._myPayments.take(10).map(_paymentTile),
          ],
          SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _planSwitcher() {
    final items = [
      (OnlinePlan.lecture, '1. 인강+퀴즈'),
      (OnlinePlan.bundle, '2. 인강+화상'),
      (OnlinePlan.speaking, '3. 원어민 화상 1:1 회화'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in items)
          ChoiceChip(
            label: Text(
              item.$2,
              style: TextStyle(
                fontFamily: 'NotoSansKR',
                fontWeight: FontWeight.w700,
                color: _plan == item.$1 ? Palette.white : Palette.grey800,
              ),
            ),
            selected: _plan == item.$1,
            selectedColor: Palette.secondaryDark,
            backgroundColor: Palette.white,
            side: BorderSide(
              color: _plan == item.$1 ? Palette.secondaryDark : Palette.grey300,
            ),
            onSelected: (_) {
              setState(() {
                _plan = item.$1;
                if (_plan == OnlinePlan.speaking) {
                  _selected = OnlineCourse.speaking;
                } else if (_selected == null || _selected!.isSpeakingProduct) {
                  _selected = OnlineCourse.all.first;
                }
              });
            },
          ),
      ],
    );
  }

  Widget _sessionPicker() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final count in OnlinePlan.speakingSessionChoices)
          ChoiceChip(
            label: Text(
              '$count회 · ${OnlinePlan.won(count * OnlinePlan.speakingSessionPrice)}',
              style: TextStyle(
                fontFamily: 'NotoSansKR',
                fontWeight: FontWeight.w700,
                color: _speakingSessions == count ? Palette.white : Palette.grey800,
              ),
            ),
            selected: _speakingSessions == count,
            selectedColor: Palette.accent,
            onSelected: widget.extendEnrollment
                ? null
                : (_) => setState(() => _speakingSessions = count),
          ),
      ],
    );
  }

  String _planTitle(String plan) {
    if (plan == OnlinePlan.lecture) return '단계별 영문법 인강';
    if (plan == OnlinePlan.speaking) return '원어민 화상 1:1 회화';
    return '영문법 인강 + 원어민 화상 회화';
  }

  String _courseDetail(OnlineCourse course) {
    if (_plan == OnlinePlan.lecture) {
      return '${course.subtitle} · 인강 ${OnlinePlan.lessonsPerLevel}편 · 퀴즈';
    }
    return '${course.subtitle} · 화상 ${course.defaultSessions}회 포함';
  }

  String _includedLine(OnlineCourse course) {
    if (_plan == OnlinePlan.lecture) {
      return '인강 ${OnlinePlan.lessonsPerLevel}편 + 퀴즈 · 수강 ${OnlinePlan.lectureAccessWeeks}주 · 화상 없음';
    }
    if (_plan == OnlinePlan.speaking) {
      return '원어민 화상 1:1 회화 $_speakingSessions회 · 인강 없음';
    }
    return '화상수업 ${course.defaultSessions}회 + 인강 · 퀴즈';
  }

  Widget _courseOption(OnlineCourse course) {
    final selected = _selected?.id == course.id;
    return InkWell(
      onTap: () => setState(() => _selected = course),
      child: Container(
        width: double.maxFinite,
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? course.accentColor.withValues(alpha: 0.08)
              : Palette.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? course.accentColor : Palette.grey200,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? course.accentColor : Palette.grey400,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${course.order}. ${course.title}',
                      style: TextStyle(
                          fontFamily: "NotoSansKR",
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  SizedBox(height: 4),
                  Text(_courseDetail(course),
                      style: TextStyle(
                          fontFamily: "NotoSansKR",
                          fontSize: 12,
                          color: Palette.grey600)),
                ],
              ),
            ),
            Text(OnlinePlan.won(course.amountFor(_plan, sessions: _speakingSessions)),
                style: TextStyle(
                    fontFamily: "Jalnan",
                    fontSize: 14,
                    color: Palette.secondaryDark)),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(OnlineCourse course) {
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Palette.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Palette.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr(context, "주문 요약"), style: TextStyle(fontFamily: "Jalnan", fontSize: 14)),
          SizedBox(height: 10),
          Text('상품: ${_planTitle(_plan)}',
              style: TextStyle(fontFamily: "NotoSansKR", fontSize: 13)),
          Text('과정: ${course.title}',
              style: TextStyle(fontFamily: "NotoSansKR", fontSize: 13)),
          Text('포함: ${_includedLine(course)}',
              style: TextStyle(fontFamily: "NotoSansKR", fontSize: 13)),
          SizedBox(height: 8),
          Text(
              '결제 금액: ${OnlinePlan.won(course.amountFor(_plan, sessions: _speakingSessions))}',
              style: TextStyle(
                  fontFamily: "Jalnan",
                  fontSize: 16,
                  color: Palette.secondaryDark)),
        ],
      ),
    );
  }

  Widget _paymentTile(PaymentOrder order) {
    final color = order.status == 'paid'
        ? Palette.success
        : (order.status == 'failed' ? Palette.danger : Palette.grey600);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text('${order.courseTitle} · ${order.amountLabel}',
          style: TextStyle(fontFamily: "NotoSansKR", fontSize: 13)),
      subtitle: Text(order.statusLabel,
          style: TextStyle(
              fontFamily: "NotoSansKR",
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold)),
    );
  }
}
