import 'package:flutter/material.dart';
import 'package:gi_english_website/class/ClassPlacementQuiz.dart';
import 'package:gi_english_website/class/OnlineCourse.dart';
import 'package:gi_english_website/pages/MemberLoginPage.dart';
import 'package:gi_english_website/pages/OnlineTeacherSelectPage.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/widget/ClassPlacementDialog.dart';
import 'package:gi_english_website/widget/MobileSchoolLayout.dart';
import 'package:gi_english_website/widget/OnlineProgramSideMenu.dart';
import 'package:gi_english_website/widget/WebSchoolLayout.dart';

import '../util/WidgetUtil.dart';

class SchoolOnlineCurriculumPage extends StatefulWidget {
  final String? initialCourseId;

  const SchoolOnlineCurriculumPage({Key? key, this.initialCourseId})
      : super(key: key);

  @override
  _SchoolOnlineCurriculumPageState createState() =>
      _SchoolOnlineCurriculumPageState();
}

class _SchoolOnlineCurriculumPageState
    extends State<SchoolOnlineCurriculumPage> {
  late OnlineCourse? _selectedCourse;
  final GlobalKey _courseListKey = GlobalKey();
  final Map<String, GlobalKey> _courseKeys = {
    for (final course in OnlineCourse.all) course.id: GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    _selectedCourse = OnlineCourse.findById(widget.initialCourseId ?? '') ??
        OnlineCourse.all.first;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialCourseId != null) {
        _scrollToSelectedCourse();
      }
    });
  }

  void _scrollToSelectedCourse() {
    final id = _selectedCourse?.id;
    final target = id == null
        ? _courseListKey.currentContext
        : (_courseKeys[id]?.currentContext ?? _courseListKey.currentContext);
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 420),
      alignment: 0.08,
    );
  }

  void _openPlacementTest() {
    ClassPlacementDialog.show(
      context,
      onViewCourse: (course) {
        Navigator.of(context).pop();
        setState(() => _selectedCourse = course);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToSelectedCourse();
        });
      },
    );
  }

  void _goTeacherSelect() {
    if (AuthService.currentUser == null) {
      MenuUtil.push(context, MemberLoginPage());
      return;
    }
    final course = _selectedCourse;
    if (course == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('과정을 선택해주세요.',
              style: TextStyle(fontFamily: 'NotoSansKR')),
          backgroundColor: Palette.danger,
        ),
      );
      return;
    }
    MenuUtil.push(context, OnlineTeacherSelectPage(course: course));
  }

  @override
  Widget build(BuildContext context) {
    MediaQueryData mediaQueryData = MediaQuery.of(context);
    Size size = mediaQueryData.size;
    double width = size.width;
    if (width > 768) {
      return WebSchoolLayout(content: scrollView());
    } else {
      return MobileSchoolLayout(content: mobileScrollView());
    }
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
            OnlineProgramSideMenu(selectedIndex: 0, isMobile: true),
            content(compact: true),
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
            child: OnlineProgramSideMenu(selectedIndex: 0),
          ),
          Expanded(child: content()),
        ],
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: "Jalnan",
        fontSize: 15,
        color: Palette.secondaryDark,
      ),
    );
  }

  Widget bodyText(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Palette.black,
        fontFamily: "NotoSansKR",
        fontWeight: FontWeight.normal,
        fontSize: 14,
        height: 1.6,
      ),
    );
  }

  Widget content({bool compact = false}) {
    return Container(
      alignment: Alignment.topLeft,
      width: double.maxFinite,
      padding: EdgeInsets.all(compact ? 20 : 28),
      color: Palette.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "수강과정 전체보기",
            style: TextStyle(fontFamily: "Jalnan", fontSize: 20),
          ),
          WidgetUtil.myDivider(),
          SizedBox(height: 20),
          _serviceOverview(compact: compact),
          SizedBox(height: 28),
          _placementSection(),
          SizedBox(height: 28),
          sectionTitle("과정 구성"),
          SizedBox(height: 16),
          bodyText(
            "온라인 프로그램은 학습 목표에 따라 단계별로 구성되어 있으며, 각 과정은 주 단위로 진행됩니다.\n"
            "매주 인강을 보고, 문제풀이 링크로 복습한 뒤, 체크리스트를 스스로 확인합니다.\n"
            "수강생의 레벨 진단 후 적합한 과정을 배정해 드립니다.",
          ),
          SizedBox(height: 28),
          KeyedSubtree(
            key: _courseListKey,
            child: sectionTitle("과정을 선택하세요"),
          ),
          SizedBox(height: 8),
          bodyText('각 과정의 이미지와 설명을 보고, 맞는 과정을 선택해 주세요.'),
          SizedBox(height: 16),
          RadioGroup<String>(
            groupValue: _selectedCourse?.id,
            onChanged: (id) {
              final course = OnlineCourse.findById(id ?? '');
              if (course != null) {
                setState(() => _selectedCourse = course);
              }
            },
            child: Column(
              children: [
                for (final course in OnlineCourse.all)
                  _courseRadioOption(course, compact: compact),
              ],
            ),
          ),
          SizedBox(height: 20),
          SizedBox(
            width: double.maxFinite,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Palette.secondaryDark,
                foregroundColor: Palette.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _goTeacherSelect,
              icon: Icon(Icons.arrow_forward, color: Palette.white),
              label: Text(
                '다음 · 원어민 강사 선택',
                style: TextStyle(fontFamily: 'Jalnan', fontSize: 15),
              ),
            ),
          ),
          SizedBox(height: 28),
          sectionTitle("수업 진행 방식"),
          SizedBox(height: 16),
          bodyText(
            "1. 이 페이지에서 원하는 과정을 선택합니다.\n"
            "2. 메인 원어민 강사를 고릅니다.\n"
            "3. 결제 후 내 강의실에서 인강·화상수업을 진행합니다.",
          ),
          SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _courseRadioOption(OnlineCourse course, {required bool compact}) {
    final selected = _selectedCourse?.id == course.id;
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        course.imageAsset,
        width: compact ? double.infinity : 260,
        height: compact ? 188 : 200,
        fit: BoxFit.cover,
        alignment: Alignment.center,
      ),
    );
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${course.order}. ${course.title}',
          style: TextStyle(
            fontFamily: 'NotoSansKR',
            fontWeight: FontWeight.w800,
            fontSize: compact ? 18 : 20,
            color: Palette.grey900,
          ),
        ),
        SizedBox(height: 4),
        Text(
          '${course.subtitle} · 화상 ${course.defaultSessions}회',
          style: TextStyle(
            fontFamily: 'NotoSansKR',
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Palette.darkTeal,
          ),
        ),
        SizedBox(height: 10),
        Text(
          course.description,
          style: TextStyle(
            fontFamily: 'NotoSansKR',
            fontSize: 14,
            height: 1.6,
            color: Palette.grey700,
          ),
        ),
        SizedBox(height: 12),
        ...course.highlights.map(
          (item) => Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.check_circle,
                      size: 16, color: Palette.darkTeal),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontFamily: 'NotoSansKR',
                      fontSize: 13,
                      height: 1.45,
                      color: Palette.grey700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          course.priceLabel,
          style: TextStyle(
            fontFamily: 'Jalnan',
            fontSize: 18,
            color: Palette.secondaryDark,
          ),
        ),
      ],
    );

    return InkWell(
      key: _courseKeys[course.id],
      onTap: () => setState(() => _selectedCourse = course),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.maxFinite,
        margin: EdgeInsets.only(bottom: 18),
        padding: EdgeInsets.all(compact ? 16 : 20),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? Palette.darkTeal : Palette.grey200,
            width: selected ? 2 : 1,
          ),
          color: selected
              ? Palette.darkTeal.withValues(alpha: 0.04)
              : Palette.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _courseRadioHeader(course, selected),
                  SizedBox(height: 12),
                  image,
                  SizedBox(height: 14),
                  details,
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _courseRadio(course),
                  SizedBox(width: 8),
                  image,
                  SizedBox(width: 20),
                  Expanded(child: details),
                ],
              ),
      ),
    );
  }

  Widget _courseRadioHeader(OnlineCourse course, bool selected) {
    return Row(
      children: [
        _courseRadio(course),
        SizedBox(width: 4),
        Text(
          selected ? '선택됨' : '이 과정 선택',
          style: TextStyle(
            fontFamily: 'NotoSansKR',
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: selected ? Palette.darkTeal : Palette.grey500,
          ),
        ),
      ],
    );
  }

  Widget _courseRadio(OnlineCourse course) {
    return Radio<String>(
      value: course.id,
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Palette.darkTeal;
        return Palette.grey400;
      }),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _serviceOverview({required bool compact}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'assets/curriculum-service-overview.jpg',
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        SizedBox(height: 10),
        Text(
          '인강 · 디지털 교재 · 실시간 화상수업 · 피드백 체크리스트가 한 화면에서 이어집니다.',
          style: TextStyle(
            fontFamily: 'NotoSansKR',
            fontSize: compact ? 12 : 13,
            height: 1.5,
            color: Palette.grey600,
          ),
        ),
      ],
    );
  }

  Widget _placementSection() {
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Palette.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '「나에게 맞는 클래스 선택하기」',
            style: TextStyle(
              fontFamily: 'NotoSansKR',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Palette.grey900,
            ),
          ),
          SizedBox(height: 10),
          Text(
            ClassPlacementQuiz.skipNotice,
            style: TextStyle(
              fontFamily: 'NotoSansKR',
              fontSize: 13,
              height: 1.55,
              color: Palette.grey600,
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Palette.secondary,
                foregroundColor: Palette.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 28),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _openPlacementTest,
              child: Text(
                'Test',
                style: TextStyle(
                  fontFamily: 'NotoSansKR',
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
