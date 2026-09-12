import 'package:flutter/material.dart';
import 'package:gi_english_website/class/OnlineCourse.dart';
import 'package:gi_english_website/class/OnlineNativeTeacher.dart';
import 'package:gi_english_website/pages/MemberLoginPage.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/PaymentService.dart';
import 'package:gi_english_website/widget/MobileSchoolLayout.dart';
import 'package:gi_english_website/widget/OnlineProgramSideMenu.dart';
import 'package:gi_english_website/widget/WebSchoolLayout.dart';

import '../util/WidgetUtil.dart';

/// 과정 확정 후 · 결제 전 원어민 메인 강사 선택.
class OnlineTeacherSelectPage extends StatefulWidget {
  final OnlineCourse course;

  const OnlineTeacherSelectPage({Key? key, required this.course})
      : super(key: key);

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
    final width = MediaQuery.of(context).size.width;
    if (width > 768) {
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
    final course = widget.course;
    return Container(
      alignment: Alignment.topLeft,
      width: double.maxFinite,
      padding: EdgeInsets.all(20),
      color: Palette.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('원어민 강사 선택',
              style: TextStyle(fontFamily: 'Jalnan', fontSize: 20)),
          WidgetUtil.myDivider(),
          SizedBox(height: 12),
          Text(
            '선택한 과정을 담당할 메인 원어민 강사입니다.\n'
            '이후 화상수업은 이 선생님을 중심으로 진행되며, '
            '해당 선생님이 열어 둔 시간에만 예약할 수 있습니다.\n'
            '스케줄이 맞지 않을 때만 다른 선생님으로 변경할 수 있습니다.',
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
                Text('선택한 과정',
                    style: TextStyle(
                        fontFamily: 'NotoSansKR',
                        fontSize: 12,
                        color: Palette.grey500)),
                SizedBox(height: 6),
                Text('${course.order}. ${course.title}',
                    style: TextStyle(
                        fontFamily: 'NotoSansKR',
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                SizedBox(height: 4),
                Text(
                    '${course.subtitle} · 화상 ${course.defaultSessions}회 · ${course.priceLabel}',
                    style: TextStyle(
                        fontFamily: 'NotoSansKR',
                        fontSize: 13,
                        color: Palette.grey600)),
              ],
            ),
          ),
          SizedBox(height: 24),
          Text('강사 선택', style: TextStyle(fontFamily: 'Jalnan', fontSize: 15)),
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
                '현재 선택할 수 있는 원어민 강사가 없습니다. 학원으로 문의해 주세요.',
                style: TextStyle(
                  fontFamily: 'NotoSansKR',
                  fontSize: 13,
                  color: Palette.grey600,
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 720;
                if (wide) {
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: _teachers
                        .map((t) => SizedBox(
                              width: (constraints.maxWidth - 16) / 2,
                              child: _teacherCard(t),
                            ))
                        .toList(),
                  );
                }
                return Column(
                  children: _teachers
                      .map((t) => Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: _teacherCard(t),
                          ))
                      .toList(),
                );
              },
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
                _paying ? '결제창 여는 중...' : '선택 완료 · 결제하기',
                style: TextStyle(fontFamily: 'Jalnan', fontSize: 15),
              ),
            ),
          ),
          SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _teacherCard(OnlineNativeTeacher teacher) {
    final selected = _selected?.id == teacher.id;
    return InkWell(
      onTap: () => setState(() => _selected = teacher),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: selected
              ? Palette.secondary.withValues(alpha: 0.06)
              : Palette.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Palette.darkTeal : Palette.grey200,
            width: selected ? 2.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 280,
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
                        ? '소개가 곧 업데이트됩니다.'
                        : teacher.intro,
                    style: TextStyle(
                      fontFamily: 'NotoSansKR',
                      fontSize: 14,
                      height: 1.55,
                      color: Palette.grey700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
