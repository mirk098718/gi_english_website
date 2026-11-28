import 'package:flutter/material.dart';
import 'package:gi_english_website/util/AppLanguage.dart';
import 'package:gi_english_website/util/EnrollmentService.dart';
import 'package:gi_english_website/util/Palette.dart';

/// 끝난 결제분 요약. 첨부·진도 없이 과정·회차·강사·기간만 남긴다.
class PackageHistoryTile extends StatelessWidget {
  final EnrollmentRecord record;
  final String memberLabel;

  const PackageHistoryTile({
    Key? key,
    required this.record,
    this.memberLabel = '',
  }) : super(key: key);

  String _dateLabel(DateTime? value) {
    if (value == null) return '';
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y.$m.$d';
  }

  @override
  Widget build(BuildContext context) {
    final course = record.course;
    final title = course == null
        ? record.courseId
        : course.localizedName(context, record.plan);
    final teacher = record.nativeTeacherLabel.trim();
    final start = _dateLabel(record.paidAt ?? record.createdAt);
    final end = _dateLabel(record.lastSessionAt);
    final period = [
      if (start.isNotEmpty) start,
      if (end.isNotEmpty && end != start) end,
    ].join(' ~ ');

    return Container(
      width: double.maxFinite,
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Palette.grey50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Palette.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (memberLabel.trim().isNotEmpty) ...[
            Text(
              memberLabel.trim(),
              style: TextStyle(
                fontFamily: 'NotoSansKR',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Palette.grey700,
              ),
            ),
            SizedBox(height: 2),
          ],
          Text(
            title,
            style: TextStyle(
              fontFamily: 'NotoSansKR',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Palette.black,
            ),
          ),
          SizedBox(height: 4),
          Text(
            [
              tf(context, '{p0}회 완료', {'p0': record.totalSessions}),
              if (teacher.isNotEmpty) tf(context, '강사 {p0}', {'p0': teacher}),
              if (period.isNotEmpty) period,
            ].join(' · '),
            style: TextStyle(
              fontFamily: 'NotoSansKR',
              fontSize: 12,
              color: Palette.grey600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// 접는 히스토리 폴더.
class PackageHistoryFolder extends StatelessWidget {
  final List<EnrollmentRecord> records;
  final String Function(EnrollmentRecord record)? memberLabelOf;
  final bool initiallyExpanded;

  const PackageHistoryFolder({
    Key? key,
    required this.records,
    this.memberLabelOf,
    this.initiallyExpanded = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return SizedBox.shrink();
    final sorted = List<EnrollmentRecord>.from(records)
      ..sort((a, b) {
        final ae = a.lastSessionAt ?? a.paidAt ?? a.createdAt ?? DateTime(1970);
        final be = b.lastSessionAt ?? b.paidAt ?? b.createdAt ?? DateTime(1970);
        return be.compareTo(ae);
      });

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.only(bottom: 4),
        title: Text(
          tf(context, '히스토리 {p0}', {'p0': sorted.length}),
          style: TextStyle(
            fontFamily: 'NotoSansKR',
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          tr(context, '끝난 결제분의 과정·회차 기록입니다. 첨부나 상세 진도는 남기지 않습니다.'),
          style: TextStyle(
            fontFamily: 'NotoSansKR',
            fontSize: 12,
            color: Palette.grey600,
          ),
        ),
        children: [
          for (final record in sorted)
            PackageHistoryTile(
              record: record,
              memberLabel: memberLabelOf?.call(record) ?? '',
            ),
        ],
      ),
    );
  }
}
