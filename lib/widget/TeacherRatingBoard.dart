import 'package:flutter/material.dart';
import 'package:gi_english_website/util/AppLanguage.dart';
import 'package:gi_english_website/util/EnrollmentService.dart';
import 'package:gi_english_website/util/LessonRatingService.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/widget/LessonRatingPromptHost.dart';

/// 메인 관리자 강사 카드와 평가 창에서 쓰는 수업 별점 목록.
class TeacherRatingBoard extends StatelessWidget {
  final TeacherMonthStats stats;
  final List<LessonRating> ratings;

  /// null이면 해당 강사의 평가를 모두 보여 준다.
  final int? previewLimit;

  const TeacherRatingBoard({
    Key? key,
    required this.stats,
    required this.ratings,
    this.previewLimit,
  }) : super(key: key);

  static List<LessonRating> newestFirst(List<LessonRating> ratings) {
    final list = List<LessonRating>.from(ratings);
    list.sort((a, b) {
      final ad = a.ratedAt ?? a.createdAt;
      final bd = b.ratedAt ?? b.createdAt;
      final byTime = bd.compareTo(ad);
      if (byTime != 0) return byTime;
      return b.date.compareTo(a.date);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final ordered = newestFirst(ratings);
    final rated = ordered.where((rating) => rating.isRated).toList();
    final shown = previewLimit == null
        ? ordered
        : rated.take(previewLimit!).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.star_rounded, size: 18, color: Palette.warning),
            SizedBox(width: 4),
            Expanded(
              child: Text(
                tf(context, '이번달 평균 {p0} · 이번달 {p1}건 · 전체 {p2}건', {'p0': stats.averageStarsLabel, 'p1': stats.ratedCount, 'p2': rated.length}),
                style: TextStyle(
                  fontFamily: "NotoSansKR",
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Palette.grey800,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        if (shown.isEmpty)
          Text(
            tr(context, '학생 별점이 아직 없습니다.'),
            style: TextStyle(
              fontFamily: "NotoSansKR",
              fontSize: 12,
              color: Palette.grey500,
            ),
          )
        else
          ...shown.map((rating) => Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: TeacherRatingTile(rating: rating),
              )),
      ],
    );
  }
}

class TeacherRatingTile extends StatelessWidget {
  final LessonRating rating;

  const TeacherRatingTile({Key? key, required this.rating}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final who = rating.memberName.trim().isEmpty ? tr(context, '수강생'): rating.memberName.trim();
    final course = rating.courseTitle.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          [
            who,
            if (course.isNotEmpty) course,
            rating.lessonLabel,
          ].join(' · '),
          style: TextStyle(
            fontFamily: "NotoSansKR",
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Palette.black,
          ),
        ),
        SizedBox(height: 4),
        if (rating.isRated)
          LessonStarView(stars: rating.stars, size: 16)
        else
          LessonRatingStatusChip(rating: rating),
        if (rating.review.trim().isNotEmpty) ...[
          SizedBox(height: 4),
          Text(
            rating.review.trim(),
            style: TextStyle(
              fontFamily: "NotoSansKR",
              fontSize: 12,
              height: 1.4,
              color: Palette.grey700,
            ),
          ),
        ],
      ],
    );
  }
}
