import 'package:flutter/material.dart';
import 'package:gi_english_website/class/OnlineCourse.dart';
import 'package:gi_english_website/util/EnrollmentService.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/UrlIUtil.dart';

/// 강사/관리자가 수강생 카드에서 보는 회차별 인강·문제 체크.
class StudentLearningProgressPanel extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final records = enrollments.where((item) => item.isActive).toList();
    if (records.isEmpty) {
      return Text(
        '수강 배정 정보가 없습니다.',
        style: TextStyle(
          fontFamily: "NotoSansKR",
          fontSize: dense ? 12 : 13,
          color: Palette.grey500,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < records.length; i++) ...[
          if (i > 0) SizedBox(height: dense ? 10 : 14),
          _enrollmentBlock(records[i]),
        ],
      ],
    );
  }

  Widget _enrollmentBlock(EnrollmentRecord enrollment) {
    final course = enrollment.course ?? OnlineCourse.findById(enrollment.courseId);
    final weeks = (progressByEnrollment[enrollment.id] ?? const <StudentWeekProgress>[])
        .where((week) =>
            onlyWeekNumber == null || week.weekNumber == onlyWeekNumber)
        .toList();
    final title = course?.title ?? enrollment.courseId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dense ? '학습 진도 · $title' : '학습 진도',
          style: TextStyle(
            fontFamily: "Jalnan",
            fontSize: dense ? 12 : 13,
            color: Palette.secondaryDark,
          ),
        ),
        if (!dense) ...[
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
            onlyWeekNumber == null
                ? '아직 체크한 학습이 없습니다.'
                : '$onlyWeekNumber회차 학습 체크가 없습니다.',
            style: TextStyle(
              fontFamily: "NotoSansKR",
              fontSize: 12,
              color: Palette.grey500,
            ),
          )
        else
          ...weeks.map(_weekBlock),
      ],
    );
  }

  Widget _weekBlock(StudentWeekProgress week) {
    final problems = week.problemLinks.isEmpty
        ? const [WeekProblemLink(title: '등록된 문제 없음', url: '')]
        : week.problemLinks;

    return Container(
      width: double.maxFinite,
      margin: EdgeInsets.only(bottom: dense ? 6 : 8),
      padding: EdgeInsets.all(dense ? 10 : 12),
      decoration: BoxDecoration(
        color: Palette.grey50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: week.readyToBook ? Palette.secondary.withValues(alpha: 0.35) : Palette.grey200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [
              if (week.weekNumber > 0) '${week.weekNumber}회차',
              if (week.weekTitle.isNotEmpty) week.weekTitle,
              if (week.readyToBook) '예약 가능',
            ].join(' · '),
            style: TextStyle(
              fontFamily: "NotoSansKR",
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8),
          _line(
            label: '인강',
            title: week.videoLabel,
            url: week.videoUrl,
            done: week.videoChecked,
          ),
          ...problems.map((link) => _line(
                label: '문제',
                title: link.title.trim().isEmpty ? '문제풀이' : link.title.trim(),
                url: link.url,
                done: week.problemsChecked,
              )),
        ],
      ),
    );
  }

  Widget _line({
    required String label,
    required String title,
    required String url,
    required bool done,
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
                    onTap: () => UrlUtil.open(url),
                    child: Text(
                      '열기',
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
