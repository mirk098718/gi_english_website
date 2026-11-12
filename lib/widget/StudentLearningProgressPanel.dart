import 'package:flutter/material.dart';
import 'package:gi_english_website/util/AppLanguage.dart';
import 'package:gi_english_website/class/OnlineCourse.dart';
import 'package:gi_english_website/class/QuizResult.dart';
import 'package:gi_english_website/util/EnrollmentService.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/QuizResultService.dart';
import 'package:gi_english_website/util/UrlIUtil.dart';
import 'package:gi_english_website/widget/QuizResultSummary.dart';

/// 강사/관리자가 수강생 카드에서 보는 회차별 인강·문제 체크와 최근 퀴즈 결과.
class StudentLearningProgressPanel extends StatefulWidget {
  final List<EnrollmentRecord> enrollments;
  final Map<String, List<StudentWeekProgress>> progressByEnrollment;
  final int? onlyWeekNumber;
  final bool dense;

  const StudentLearningProgressPanel({
    Key? key,
    required this.enrollments,
    required this.progressByEnrollment,
    this.onlyWeekNumber,
    this.dense = false,
  }) : super(key: key);

  @override
  State<StudentLearningProgressPanel> createState() =>
      _StudentLearningProgressPanelState();
}

class _StudentLearningProgressPanelState
    extends State<StudentLearningProgressPanel> {
  Map<String, QuizResultLookup>? _quizByUser;
  int _ticket = 0;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  @override
  void didUpdateWidget(covariant StudentLearningProgressPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.enrollments, widget.enrollments) ||
        !identical(oldWidget.progressByEnrollment, widget.progressByEnrollment)) {
      _loadQuizzes();
    }
  }

  Future<void> _loadQuizzes() async {
    final ticket = ++_ticket;
    final idsByUser = <String, Set<String>>{};
    for (final enrollment in widget.enrollments) {
      if (enrollment.userId.isEmpty) continue;
      final ids = idsByUser.putIfAbsent(enrollment.userId, () => <String>{});
      for (final week in widget.progressByEnrollment[enrollment.id] ??
          const <StudentWeekProgress>[]) {
        for (final link in week.problemLinks) {
          final quizId = QuizResult.quizIdFromUrl(link.url);
          if (quizId.isNotEmpty) ids.add(quizId);
        }
      }
      for (final lesson in EnrollmentService.catalogLessons(enrollment.courseId)) {
        final quizId = QuizResult.quizIdFromUrl(lesson.problemUrl);
        if (quizId.isNotEmpty) ids.add(quizId);
      }
    }

    final loaded = <String, QuizResultLookup>{};
    await Future.wait(idsByUser.entries.map((entry) async {
      loaded[entry.key] = await QuizResultService.fetchForUser(
        userId: entry.key,
        quizIds: entry.value,
      );
    }));
    if (!mounted || ticket != _ticket) return;
    setState(() => _quizByUser = loaded);
  }

  @override
  Widget build(BuildContext context) {
    final records = widget.enrollments.where((item) => item.isActive).toList();
    if (records.isEmpty) {
      return Text(
        tr(context, "수강 배정 정보가 없습니다."),
        style: TextStyle(
          fontFamily: "NotoSansKR",
          fontSize: widget.dense ? 12 : 13,
          color: Palette.grey500,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < records.length; i++) ...[
          if (i > 0) SizedBox(height: widget.dense ? 10 : 14),
          _enrollmentBlock(records[i]),
        ],
      ],
    );
  }

  Widget _enrollmentBlock(EnrollmentRecord enrollment) {
    final course = enrollment.course ?? OnlineCourse.findById(enrollment.courseId);
    final weeks = (widget.progressByEnrollment[enrollment.id] ??
            const <StudentWeekProgress>[])
        .where((week) =>
            widget.onlyWeekNumber == null ||
            week.weekNumber == widget.onlyWeekNumber)
        .toList();
    final title = course?.title ?? enrollment.courseId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.dense ? tf(context, '학습 진도 · {p0}', {'p0': title}): tr(context, "학습 진도"),
          style: TextStyle(
            fontFamily: "Jalnan",
            fontSize: widget.dense ? 12 : 13,
            color: Palette.secondaryDark,
          ),
        ),
        if (!widget.dense) ...[
          SizedBox(height: 4),
          Text(
            title.isEmpty ? enrollment.courseId : title,
            style: TextStyle(
              fontFamily: "NotoSansKR",
              fontSize: 12,
              color: Palette.grey600,
            ),
          ),
        ],
        SizedBox(height: 8),
        if (weeks.isEmpty)
          Text(
            widget.onlyWeekNumber == null
                ? tr(context, "아직 체크한 학습이 없습니다.")
                : tf(context, '{p0}회차 학습 체크가 없습니다.', {'p0': widget.onlyWeekNumber}),
            style: TextStyle(
              fontFamily: "NotoSansKR",
              fontSize: 12,
              color: Palette.grey500,
            ),
          )
        else
          ...weeks.map((week) => _weekBlock(week, enrollment.userId)),
      ],
    );
  }

  Widget _weekBlock(StudentWeekProgress week, String userId) {
    final problems = week.problemLinks.isEmpty
        ?  [WeekProblemLink(title: tr(context, '등록된 문제 없음'), url: '')]
        : week.problemLinks;

    return Container(
      width: double.maxFinite,
      margin: EdgeInsets.only(bottom: widget.dense ? 6 : 8),
      padding: EdgeInsets.all(widget.dense ? 10 : 12),
      decoration: BoxDecoration(
        color: Palette.grey50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: week.readyToBook
              ? Palette.secondary.withValues(alpha: 0.35)
              : Palette.grey200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [
              if (week.weekNumber > 0) tf(context, '{p0}회차', {'p0': week.weekNumber}),
              if (week.weekTitle.isNotEmpty) week.weekTitle,
              if (week.readyToBook) tr(context, "예약 가능"),
            ].join(' · '),
            style: TextStyle(
              fontFamily: "NotoSansKR",
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8),
          if (week.videoUrl.trim().isNotEmpty)
            _line(
              label: tr(context, '인강'),
              title: week.videoLabel,
              url: week.videoUrl,
              done: week.videoChecked,
              asPlayer: true,
            ),
          ...problems.map((link) => _line(
                label: tr(context, '문제'),
                title: link.title.trim().isEmpty ? tr(context, '문제풀이'): link.title.trim(),
                url: link.url,
                done: week.problemsChecked,
              )),
          _quizSection(week, userId),
        ],
      ),
    );
  }

  Widget _quizSection(StudentWeekProgress week, String userId) {
    final quizIds = week.problemLinks
        .map((link) => QuizResult.quizIdFromUrl(link.url))
        .where((id) => id.isNotEmpty)
        .toList();
    if (quizIds.isEmpty) return SizedBox.shrink();
    final lookup = _quizByUser?[userId];
    if (lookup == null || lookup.unavailable) return SizedBox.shrink();

    final results = <QuizResult>[];
    for (final quizId in quizIds) {
      final result = lookup.results[quizId];
      if (result != null) results.add(result);
    }
    if (results.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: 6),
        child: Text(
          tr(context, "저장된 퀴즈 결과가 없습니다."),
          style: TextStyle(
            fontFamily: "NotoSansKR",
            fontSize: 12,
            color: Palette.grey500,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: results
          .map((result) => QuizResultSummary(
                result: result,
                dense: widget.dense,
              ))
          .toList(),
    );
  }

  Widget _line({
    required String label,
    required String title,
    required String url,
    required bool done,
    bool asPlayer = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: done ? Palette.success : Palette.grey400,
          ),
          SizedBox(width: 6),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '$label · $title',
                  style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontSize: 12,
                    color: Palette.grey700,
                    height: 1.4,
                  ),
                ),
                if (url.trim().isNotEmpty)
                  InkWell(
                    onTap: () =>
                        asPlayer ? UrlUtil.openPlayer(url) : UrlUtil.open(url),
                    child: Text(
                      tr(context, "열기"),
                      style: TextStyle(
                        fontFamily: "NotoSansKR",
                        fontSize: 12,
                        color: Palette.secondaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
