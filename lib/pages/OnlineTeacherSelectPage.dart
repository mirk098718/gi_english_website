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
  OnlineNativeTeacher? _selected = OnlineNativeTeacher.all.first;
  bool _paying = false;

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
            SizedBox(height: 51, child: MyWidget.mobileSchoolFooter()),
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
            '스케줄이 맞지 않을 때만 다른 선생님으로 변경할 수 있습니다.\n'
            '(지금은 임시 AI 프로필입니다)',
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
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 720;
              if (wide) {
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: OnlineNativeTeacher.all
                      .map((t) => SizedBox(
                            width: (constraints.maxWidth - 12) / 2,
                            child: _teacherCard(t),
                          ))
                      .toList(),
                );
              }
              return Column(
                children: OnlineNativeTeacher.all
                    .map((t) => Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: _teacherCard(t),
                        ))
                    .toList(),
              );
            },
          ),
          SizedBox(height: 24),
          if (_selected != null) ...[
            Text(
              '메인 강사: ${_selected!.name} (${_selected!.nationality})',
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
              onPressed: _paying ? null : _startPayment,
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? Palette.secondary.withValues(alpha: 0.06)
              : Palette.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Palette.secondary : Palette.grey200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                teacher.imageAsset,
                width: 88,
                height: 88,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          teacher.name,
                          style: TextStyle(
                            fontFamily: 'NotoSansKR',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color:
                            selected ? Palette.secondary : Palette.grey400,
                        size: 22,
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    teacher.nationality,
                    style: TextStyle(
                      fontFamily: 'NotoSansKR',
                      fontSize: 12,
                      color: Palette.grey500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    teacher.intro,
                    style: TextStyle(
                      fontFamily: 'NotoSansKR',
                      fontSize: 13,
                      height: 1.45,
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
