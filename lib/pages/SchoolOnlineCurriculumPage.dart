import 'package:flutter/material.dart';
import 'package:gi_english_website/util/SiteLayout.dart';
import 'package:gi_english_website/class/OnlineCourse.dart';
import 'package:gi_english_website/class/OnlinePlan.dart';
import 'package:gi_english_website/pages/MemberLoginPage.dart';
import 'package:gi_english_website/pages/OnlineTeacherSelectPage.dart';
import 'package:gi_english_website/util/AppLanguage.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/PaymentService.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/widget/ClassPlacementDialog.dart';
import 'package:gi_english_website/widget/OnlinePlanCard.dart';
import 'package:gi_english_website/widget/MobileSchoolLayout.dart';
import 'package:gi_english_website/widget/OnlineProgramSideMenu.dart';
import 'package:gi_english_website/widget/WebSchoolLayout.dart';

import '../util/WidgetUtil.dart';

class SchoolOnlineCurriculumPage extends StatefulWidget {
  final String? initialCourseId;
  final String? initialPlan;

  const SchoolOnlineCurriculumPage({
    Key? key,
    this.initialCourseId,
    this.initialPlan,
  }) : super(key: key);

  @override
  _SchoolOnlineCurriculumPageState createState() =>
      _SchoolOnlineCurriculumPageState();
}

class _SchoolOnlineCurriculumPageState
    extends State<SchoolOnlineCurriculumPage> {
  late OnlineCourse? _selectedCourse;
  late OnlineCourse? _lectureCourse;
  bool _lecturePaying = false;
  int _speakingSessions = 8;
  late String _highlightedPlan;
  final GlobalKey _courseListKey = GlobalKey();
  final GlobalKey _lectureKey = GlobalKey();
  final GlobalKey _bundleKey = GlobalKey();
  final GlobalKey _speakingKey = GlobalKey();
  final Map<String, GlobalKey> _courseKeys = {
    for (final course in OnlineCourse.all) course.id: GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    final initial = OnlineCourse.findById(widget.initialCourseId ?? '') ??
        OnlineCourse.all.first;
    _selectedCourse = initial.isSpeakingProduct ? OnlineCourse.all.first : initial;
    _lectureCourse = _selectedCourse;
    _highlightedPlan = OnlinePlan.normalize(widget.initialPlan);
    if (widget.initialPlan == null && widget.initialCourseId != null) {
      _highlightedPlan = OnlinePlan.bundle;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialCourseId != null &&
          !(_selectedCourse?.isSpeakingProduct ?? false)) {
        _scrollToSelectedCourse();
      } else if (widget.initialPlan != null) {
        _scrollToPlan(_highlightedPlan);
      }
    });
  }

  void _scrollToPlan(String plan) {
    final key = plan == OnlinePlan.lecture
        ? _lectureKey
        : (plan == OnlinePlan.speaking ? _speakingKey : _bundleKey);
    final target = key.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 420),
      alignment: 0.08,
    );
  }

  void _selectPlan(String plan) {
    setState(() => _highlightedPlan = plan);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToPlan(plan));
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
        setState(() {
          _selectedCourse = course;
          _lectureCourse = course;
          _highlightedPlan = OnlinePlan.bundle;
        });
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
          content: Text(tr(context, "과정을 선택해주세요."),
              style: TextStyle(fontFamily: 'NotoSansKR')),
          backgroundColor: Palette.danger,
        ),
      );
      return;
    }
    MenuUtil.push(
      context,
      OnlineTeacherSelectPage(course: course, plan: OnlinePlan.bundle),
    );
  }

  Future<void> _payLecture() async {
    if (_lecturePaying) return;
    if (AuthService.currentUser == null) {
      MenuUtil.push(context, MemberLoginPage());
      return;
    }
    final course = _lectureCourse;
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
    setState(() => _lecturePaying = true);
    final order = await PaymentService.createOrder(
      course: course,
      plan: OnlinePlan.lecture,
      totalSessions: course.sessionsFor(OnlinePlan.lecture),
    );
    if (!mounted) return;
    if (order == null) {
      setState(() => _lecturePaying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('주문을 생성하지 못했습니다. 로그인 상태를 확인해주세요.',
              style: TextStyle(fontFamily: 'NotoSansKR')),
          backgroundColor: Palette.danger,
        ),
      );
      return;
    }
    final error = await PaymentService.requestTossPayment(order);
    if (!mounted) return;
    setState(() => _lecturePaying = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error, style: TextStyle(fontFamily: 'NotoSansKR')),
          backgroundColor: Palette.danger,
        ),
      );
    }
  }

  void _goSpeakingTeacher() {
    if (AuthService.currentUser == null) {
      MenuUtil.push(context, MemberLoginPage());
      return;
    }
    MenuUtil.push(
      context,
      OnlineTeacherSelectPage(
        course: OnlineCourse.speaking,
        plan: OnlinePlan.speaking,
        sessionCount: _speakingSessions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!useMobileSchoolLayout(context)) {
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
            tr(context, "온라인 상품"),
            style: TextStyle(fontFamily: "Jalnan", fontSize: 20),
          ),
          WidgetUtil.myDivider(),
          SizedBox(height: 12),
          bodyText(
            tr(
              context,
              '원하시는 상품을 선택하세요. 클릭 시, 프로그램 상세 정보로 바로 이동합니다!',
            ),
          ),
          SizedBox(height: 16),
          _planCards(compact: compact),
          SizedBox(height: 28),
          Text(
            tr(context, '과정을 선택하세요'),
            style: TextStyle(
              fontFamily: 'NotoSansKR',
              fontWeight: FontWeight.w800,
              fontSize: compact ? 20 : 22,
              height: 1.35,
              color: Palette.grey900,
            ),
          ),
          SizedBox(height: 16),
          _placementSection(),
          SizedBox(height: 28),
          KeyedSubtree(
            key: _lectureKey,
            child: _lectureSection(compact: compact),
          ),
          SizedBox(height: 28),
          KeyedSubtree(
            key: _bundleKey,
            child: _bundleSection(compact: compact),
          ),
          SizedBox(height: 28),
          KeyedSubtree(
            key: _speakingKey,
            child: _speakingSection(),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _planCards({required bool compact}) {
    final cards = [
      OnlinePlanCard(
        index: '1',
        title: '단계별 영문법 인강',
        summary: '인강으로 문법 빌드업, 유용한 표현을 배우고, 퀴즈로 최종 정리합니다.',
        priceLine: '레벨별 안내 99,000원~',
        color: Palette.primary,
        imageAsset: 'assets/plan-card-lecture.jpg',
        selected: _highlightedPlan == OnlinePlan.lecture,
        onTap: () => _selectPlan(OnlinePlan.lecture),
      ),
      OnlinePlanCard(
        index: '2',
        title: '영문법 인강 + 원어민 화상 회화',
        summary: '인강을 듣고, 퀴즈로 다지고, 1:1 화상으로 실사용해봅니다.',
        priceLine: '레벨별 180,000원~',
        color: Palette.secondaryDark,
        imageAsset: 'assets/plan-card-bundle.jpg',
        selected: _highlightedPlan == OnlinePlan.bundle,
        current: true,
        onTap: () => _selectPlan(OnlinePlan.bundle),
      ),
      OnlinePlanCard(
        index: '3',
        title: '원어민 화상 1:1 회화',
        summary: '실전 원어민 회화.',
        priceLine: '1회 ${OnlinePlan.won(OnlinePlan.speakingSessionPrice)}',
        color: Palette.accent,
        imageAsset: 'assets/plan-card-speaking.jpg',
        selected: _highlightedPlan == OnlinePlan.speaking,
        onTap: () => _selectPlan(OnlinePlan.speaking),
      ),
    ];
    if (compact) {
      return Column(
        children: [
          for (final card in cards) ...[
            card,
            SizedBox(height: 12),
          ],
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return Column(
            children: [
              for (final card in cards) ...[
                card,
                SizedBox(height: 12),
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) SizedBox(width: 12),
              Expanded(child: cards[i]),
            ],
          ],
        );
      },
    );
  }

  Widget _lectureSection({required bool compact}) {
    return _planPanel(
      highlighted: _highlightedPlan == OnlinePlan.lecture,
      color: Palette.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionTitle('1. 단계별 영문법 인강'),
          SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/plan-card-lecture.jpg',
              width: double.infinity,
              fit: BoxFit.fitWidth,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '녹화해 둔 인강입니다. 재생과 일시정지로 봅니다.',
            style: TextStyle(
              fontFamily: 'NotoSansKR',
              fontSize: 12,
              height: 1.5,
              color: Palette.grey600,
            ),
          ),
          SizedBox(height: 16),
          bodyText(
            '인강으로 문법 빌드업, 유용한 표현을 배우고, 퀴즈로 최종 정리합니다.\n'
            '원어민 화상은 포함되지 않습니다.\n'
            '레벨마다 인강 ${OnlinePlan.lessonsPerLevel}편을 기준으로 하고, 강의실에는 등록된 편부터 열립니다.\n'
            '수강 기간은 ${OnlinePlan.lectureAccessWeeks}주입니다.',
          ),
          SizedBox(height: 16),
          RadioGroup<String>(
            groupValue: _lectureCourse?.id,
            onChanged: (id) {
              final course = OnlineCourse.findById(id ?? '');
              if (course != null && !course.isSpeakingProduct) {
                setState(() => _lectureCourse = course);
              }
            },
            child: Column(
              children: [
                for (final course in OnlineCourse.all)
                  _levelCourseCard(
                    course,
                    plan: OnlinePlan.lecture,
                    selected: _lectureCourse?.id == course.id,
                    compact: compact,
                    accent: Palette.primary,
                    priceLabel: course.lecturePriceLabel,
                    priceColor: Palette.primary,
                    onTap: () => setState(() => _lectureCourse = course),
                  ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Text(
            _lectureCourse == null
                ? '레벨을 고르면 그 금액으로 결제합니다.'
                : '${_lectureCourse!.order}. ${_lectureCourse!.localizedName(context, OnlinePlan.lecture)}',
            style: TextStyle(
              fontFamily: 'NotoSansKR',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              height: 1.5,
              color: Palette.grey800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '인강과 퀴즈를 바로 결제합니다.',
            style: TextStyle(
              fontFamily: 'NotoSansKR',
              fontSize: 13,
              height: 1.5,
              color: Palette.grey600,
            ),
          ),
          SizedBox(height: 12),
          _applyButton(
            label: _lecturePaying
                ? '결제창 여는 중...'
                : '${_lectureCourse?.lecturePriceLabel ?? ''} 결제하기'.trim(),
            onPressed: _lecturePaying ? null : _payLecture,
            color: Palette.primary,
            icon: Icons.payment,
          ),
        ],
      ),
    );
  }

  Widget _bundleSection({required bool compact}) {
    return _planPanel(
      highlighted: _highlightedPlan == OnlinePlan.bundle,
      color: Palette.secondaryDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionTitle('2. 영문법 인강 + 원어민 화상 회화'),
          SizedBox(height: 8),
          bodyText(
            '인강을 듣고, 퀴즈로 다지고, 1:1 화상으로 실사용해봅니다.\n'
            '지금 판매 중인 구성이며, 화상수업 ${OnlineCourse.all.first.defaultSessions}회가 포함됩니다.',
          ),
          SizedBox(height: 20),
          _serviceOverview(compact: compact),
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
            child: bodyText('각 과정의 이미지와 설명을 보고, 맞는 과정을 선택해 주세요.'),
          ),
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
                  _levelCourseCard(
                    course,
                    plan: OnlinePlan.bundle,
                    selected: _selectedCourse?.id == course.id,
                    compact: compact,
                    accent: Palette.darkTeal,
                    priceLabel: course.priceLabel,
                    priceColor: Palette.secondaryDark,
                    onTap: () => setState(() => _selectedCourse = course),
                    cardKey: _courseKeys[course.id],
                  ),
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
                tr(context, "다음 · 원어민 강사 선택"),
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
          SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _speakingSection() {
    return _planPanel(
      highlighted: _highlightedPlan == OnlinePlan.speaking,
      color: Palette.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionTitle('3. 원어민 화상 1:1 회화'),
          SizedBox(height: 12),
          bodyText(
            '실전 원어민 회화.\n'
            '인강과 퀴즈는 없고, 고른 원어민과 회화만 진행합니다.\n'
            '1회 ${OnlinePlan.won(OnlinePlan.speakingSessionPrice)}이며, 횟수를 고르면 금액이 정해집니다.',
          ),
          SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/plan-card-speaking.jpg',
              width: double.infinity,
              fit: BoxFit.fitWidth,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '화상으로 만나는 원어민과 1:1로 말합니다.',
            style: TextStyle(
              fontFamily: 'NotoSansKR',
              fontSize: 12,
              height: 1.5,
              color: Palette.grey600,
            ),
          ),
          SizedBox(height: 16),
          Wrap(
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
                      color: _speakingSessions == count
                          ? Palette.white
                          : Palette.grey800,
                    ),
                  ),
                  selected: _speakingSessions == count,
                  selectedColor: Palette.accent,
                  backgroundColor: Palette.white,
                  side: BorderSide(
                    color: _speakingSessions == count
                        ? Palette.accent
                        : Palette.grey300,
                  ),
                  onSelected: (_) => setState(() => _speakingSessions = count),
                ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            _speakingSessions == 8
                ? '8회는 지금 판매 중인 묶음과 같은 횟수입니다.'
                : '안내 금액이며, 회당 ${OnlinePlan.won(OnlinePlan.speakingSessionPrice)}입니다.',
            style: TextStyle(
              fontFamily: 'NotoSansKR',
              fontSize: 12,
              color: Palette.grey500,
            ),
          ),
          SizedBox(height: 16),
          _applyButton(
            label: '원어민 강사 선택하기',
            onPressed: _goSpeakingTeacher,
            color: Palette.accent,
          ),
        ],
      ),
    );
  }

  Widget _planPanel({
    required bool highlighted,
    required Color color,
    required Widget child,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: double.maxFinite,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: highlighted ? color.withValues(alpha: 0.04) : Palette.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted ? color : Palette.grey200,
          width: highlighted ? 2 : 1,
        ),
      ),
      child: child,
    );
  }

  Widget _applyButton({
    required String label,
    required VoidCallback? onPressed,
    Color? color,
    IconData icon = Icons.arrow_forward,
  }) {
    return SizedBox(
      width: double.maxFinite,
      height: 52,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Palette.secondaryDark,
          foregroundColor: Palette.white,
          disabledBackgroundColor: Palette.grey300,
          disabledForegroundColor: Palette.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: onPressed,
        icon: Icon(icon, color: Palette.white),
        label: Text(
          label,
          style: TextStyle(fontFamily: 'Jalnan', fontSize: 15),
        ),
      ),
    );
  }

  Widget _levelThumb(OnlineCourse course) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        course.imageAsset,
        width: 96,
        height: 72,
        fit: BoxFit.cover,
      ),
    );
  }

  String _courseMeta(OnlineCourse course, String plan) {
    final subtitle = tr(context, course.subtitleFor(plan));
    if (plan != OnlinePlan.bundle) return subtitle;
    if (AppLanguage.instance.isEnglish) {
      return '$subtitle · ${course.defaultSessions} live classes';
    }
    return '$subtitle · 화상 ${course.defaultSessions}회';
  }

  Widget _levelCourseCard(
    OnlineCourse course, {
    required String plan,
    required bool selected,
    required bool compact,
    required Color accent,
    required String priceLabel,
    required Color priceColor,
    required VoidCallback onTap,
    Key? cardKey,
  }) {
    final meta = _courseMeta(course, plan);
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${course.order}. ${course.localizedName(context, plan)}',
          style: TextStyle(
            fontFamily: 'NotoSansKR',
            fontWeight: FontWeight.w800,
            fontSize: compact ? 16 : 18,
            color: Palette.grey900,
          ),
        ),
        if (meta.isNotEmpty) ...[
          SizedBox(height: 4),
          Text(
            meta,
            style: TextStyle(
              fontFamily: 'NotoSansKR',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: accent,
            ),
          ),
        ],
        SizedBox(height: 10),
        Text(
          tr(context, course.description),
          style: TextStyle(
            fontFamily: 'NotoSansKR',
            fontSize: 14,
            height: 1.6,
            color: Palette.grey700,
          ),
        ),
        SizedBox(height: 12),
        ...course.highlightsFor(plan).map(
          (item) => Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.check_circle, size: 16, color: accent),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tr(context, item),
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
          priceLabel,
          style: TextStyle(
            fontFamily: 'Jalnan',
            fontSize: 18,
            color: priceColor,
          ),
        ),
      ],
    );

    return InkWell(
      key: cardKey,
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.maxFinite,
        margin: EdgeInsets.only(bottom: 18),
        padding: EdgeInsets.all(compact ? 16 : 20),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? accent : Palette.grey200,
            width: selected ? 2 : 1,
          ),
          color: selected ? accent.withValues(alpha: 0.04) : Palette.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Radio<String>(
              value: course.id,
              fillColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return accent;
                return Palette.grey400;
              }),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            SizedBox(width: 4),
            _levelThumb(course),
            SizedBox(width: compact ? 12 : 16),
            Expanded(child: details),
          ],
        ),
      ),
    );
  }

  Widget _serviceOverview({required bool compact}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'assets/plan-card-bundle.jpg',
            width: double.infinity,
            fit: BoxFit.fitWidth,
          ),
        ),
        SizedBox(height: 10),
        Text(
          tr(context, "인강 · 연습문제 · 실시간 화상수업 · 피드백 체크리스트가 한 화면에서 이어집니다."),
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
            tr(context, "내 레벨 테스트하기"),
            style: TextStyle(
              fontFamily: 'NotoSansKR',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Palette.grey900,
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
