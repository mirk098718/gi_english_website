import 'package:flutter/material.dart';
import 'package:gi_english_website/util/AppLanguage.dart';
import 'package:gi_english_website/class/OnlineCourse.dart';
import 'package:gi_english_website/class/QuizResult.dart';
import 'package:gi_english_website/util/EnrollmentService.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/QuizResultService.dart';
import 'package:gi_english_website/util/UrlIUtil.dart';
import 'package:gi_english_website/widget/AssignmentWorkSection.dart';
import 'package:gi_english_website/widget/QuizResultSummary.dart';

/// 강사/관리자가 수강생 카드에서 보는 회차별 인강·문제 체크와 최근 퀴즈 결과.
/// 상단에는 진행/다음 회차 1개만 두고, 수강완료·이후 수업은 접어 둔다.
class StudentLearningProgressPanel extends StatefulWidget {
  final List<EnrollmentRecord> enrollments;
  final Map<String, List<StudentWeekProgress>> progressByEnrollment;
  final int? onlyWeekNumber;
  final bool dense;
  final List<WeekBooking> bookings;

  const StudentLearningProgressPanel({
    Key? key,
    required this.enrollments,
    required this.progressByEnrollment,
    this.onlyWeekNumber,
    this.dense = false,
    this.bookings = const [],
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

    final finished = <StudentWeekProgress>[];
    final open = <StudentWeekProgress>[];
    for (final week in weeks) {
      if (_markedComplete(week, enrollment.completedSessions)) {
        finished.add(week);
      } else {
        open.add(week);
      }
    }
    open.sort((a, b) => a.weekNumber.compareTo(b.weekNumber));
    finished.sort((a, b) => b.weekNumber.compareTo(a.weekNumber));
    final focus = open.isEmpty ? null : open.first;
    final later = open.length <= 1 ? const <StudentWeekProgress>[] : open.sublist(1);

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
        else ...[
          if (focus != null) ...[
            _sectionLabel(tr(context, '이번 수업'), Palette.darkTeal),
            _weekBlock(focus, enrollment, featured: true),
          ],
          if (later.isNotEmpty)
            _collapsedGroup(
              title: tf(context, '이후 수업 {p0}', {'p0': later.length}),
              children: later
                  .map((week) => _weekBlock(week, enrollment))
                  .toList(),
            ),
          if (finished.isNotEmpty)
            _collapsedGroup(
              title: tf(context, '수강완료 {p0}', {'p0': finished.length}),
              children: finished
                  .map((week) => _weekBlock(week, enrollment))
                  .toList(),
            ),
        ],
      ],
    );
  }

  Widget _sectionLabel(String text, Color color) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'NotoSansKR',
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _collapsedGroup({
    required String title,
    required List<Widget> children,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: false,
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.only(bottom: 4),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: "NotoSansKR",
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        children: children,
      ),
    );
  }

  /// 체크가 끝나거나 회차 차감이 된 회차. 강사 화면의 '예약 가능'은 수강완료로 적는다.
  bool _markedComplete(StudentWeekProgress week, int completedSessions) {
    if (week.tracksAssignment) {
      return week.weekNumber > 0 && completedSessions >= week.weekNumber;
    }
    if (week.weekNumber > 0 && completedSessions >= week.weekNumber) {
      return true;
    }
    return week.readyToBook;
  }

  String _when(EnrollmentRecord enrollment, StudentWeekProgress week) {
    for (final booking in widget.bookings) {
      if (booking.userId != enrollment.userId ||
          booking.courseId != enrollment.courseId ||
          booking.weekNumber != week.weekNumber) {
        continue;
      }
      if (booking.isCancelled || booking.status == 'rejected') continue;
      return '${EnrollmentService.formatBookingDate(booking.date)} ${EnrollmentService.formatBookingTime(booking.time)}';
    }
    final session = enrollment.sessionAt(week.weekNumber);
    if (session == null) return '';
    return '${EnrollmentService.formatBookingDate(session.date)} ${EnrollmentService.formatBookingTime(session.time)}';
  }

  Widget _weekBlock(
    StudentWeekProgress week,
    EnrollmentRecord enrollment, {
    bool featured = false,
  }) {
    final problems = week.problemLinks.isEmpty
        ?  [WeekProblemLink(title: tr(context, '등록된 문제 없음'), url: '')]
        : week.problemLinks;
    final done = _markedComplete(week, enrollment.completedSessions);
    final userId = enrollment.userId;
    final when = _when(enrollment, week);
    final heading = [
      if (week.weekNumber > 0) tf(context, '{p0}회차', {'p0': week.weekNumber}),
      if (when.isNotEmpty) when,
      if (when.isEmpty && !week.tracksAssignment && week.weekTitle.isNotEmpty)
        week.weekTitle,
      if (done) tr(context, "수강완료"),
    ].join(' · ');

    return Container(
      width: double.maxFinite,
      margin: EdgeInsets.only(bottom: widget.dense ? 6 : 8),
      decoration: BoxDecoration(
        color: featured
            ? Palette.white
            : (done ? Palette.success.withValues(alpha: 0.06) : Palette.grey50),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: featured
              ? Palette.darkTeal
              : done
                  ? Palette.success.withValues(alpha: 0.45)
                  : Palette.grey200,
          width: featured ? 1.5 : 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: ValueKey('week-${week.weekId}'),
          initiallyExpanded: featured,
          minTileHeight: widget.dense ? 40 : 44,
          tilePadding: EdgeInsets.symmetric(horizontal: widget.dense ? 10 : 12),
          childrenPadding: EdgeInsets.fromLTRB(
            widget.dense ? 10 : 12,
            0,
            widget.dense ? 10 : 12,
            widget.dense ? 10 : 12,
          ),
          expandedAlignment: Alignment.centerLeft,
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          iconColor: Palette.grey600,
          collapsedIconColor: Palette.grey500,
          shape: const Border(),
          collapsedShape: const Border(),
          title: Text(
            heading,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: "NotoSansKR",
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: done ? Palette.success : Palette.black,
            ),
          ),
          children: [
            if (week.tracksAssignment)
              AssignmentStatusView(
                onlineProblemChecked: week.onlineProblemChecked,
                workbookChecked: week.workbookChecked,
                photoUrls: week.photoUrls,
              )
            else ...[
            if (week.videoUrl.trim().isNotEmpty)
              _line(
                label: tr(context, '인강'),
                title: week.videoLabel,
                url: week.videoUrl,
                userId: userId,
                done: week.videoChecked,
                asPlayer: true,
              ),
            ...problems.map((link) => _line(
                  label: tr(context, '문제'),
                  title: link.title.trim().isEmpty ? tr(context, '문제풀이'): link.title.trim(),
                  url: link.url,
                  userId: userId,
                  done: week.problemsChecked,
                )),
            _quizSection(week, userId),
            ],
          ],
        ),
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

  /// 강사·관리자가 문제를 열면 그 수강생의 최근 결과를 퀴즈 맨 위에 띄운다.
  String _quizUrlForStudent(String url, String userId) {
    if (userId.isEmpty || QuizResult.quizIdFromUrl(url).isEmpty) return url;
    final uri = Uri.parse(url);
    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      'student': userId,
    }).toString();
  }

  Widget _line({
    required String label,
    required String title,
    required String url,
    required String userId,
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
                    onTap: () => asPlayer
                        ? UrlUtil.openPlayer(url)
                        : UrlUtil.open(_quizUrlForStudent(url, userId)),
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
