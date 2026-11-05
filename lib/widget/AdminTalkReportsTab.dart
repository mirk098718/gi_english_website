import 'package:flutter/material.dart';
import 'package:gi_english_website/class/TalkRoom.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/TalkService.dart';

class AdminTalkReportsTab extends StatelessWidget {
  const AdminTalkReportsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TalkReport>>(
      stream: TalkService.watchReports(),
      builder: (context, snap) {
        if (snap.hasError) {
          return const Center(
            child: Text('신고 목록을 불러오지 못했어요.',
                style: TextStyle(fontFamily: 'NotoSansKR')),
          );
        }
        final reports = [...(snap.data ?? const <TalkReport>[])]
          ..sort((a, b) {
            if (a.isPending != b.isPending) return a.isPending ? -1 : 1;
            if (a.isAuto != b.isAuto) return a.isAuto ? -1 : 1;
            final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });
        if (snap.connectionState == ConnectionState.waiting &&
            reports.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (reports.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              "Let's Talk 신고가 아직 없습니다.",
              style: TextStyle(fontFamily: 'NotoSansKR', color: Palette.grey600),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemCount: reports.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final report = reports[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Palette.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: report.isPending
                      ? Palette.talkCoral.withValues(alpha: 0.35)
                      : Palette.grey200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: report.isPending
                              ? Palette.talkCoral.withValues(alpha: 0.12)
                              : Palette.grey100,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          report.isAuto
                              ? (report.isPending ? '자동 필터' : '자동 · 확인함')
                              : (report.isPending ? '대기' : '확인함'),
                          style: TextStyle(
                            fontFamily: 'NotoSansKR',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: report.isPending
                                ? Palette.talkCoralDark
                                : Palette.grey600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          report.reason,
                          style: const TextStyle(
                            fontFamily: 'Jalnan',
                            fontSize: 15,
                            color: Palette.navy,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    report.isAuto
                        ? '자동 감지 · ${report.reporterName} → ${report.targetName}'
                        : '대상 ${report.targetName}  ·  신고자 ${report.reporterName}',
                    style: const TextStyle(
                      fontFamily: 'NotoSansKR',
                      fontSize: 13,
                      color: Palette.grey700,
                    ),
                  ),
                  if (report.lastTopic.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '방 제목 ${report.lastTopic}',
                      style: const TextStyle(
                        fontFamily: 'NotoSansKR',
                        fontSize: 12,
                        color: Palette.grey600,
                      ),
                    ),
                  ],
                  if (report.detail.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      report.detail,
                      style: const TextStyle(
                        fontFamily: 'NotoSansKR',
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ],
                  if (report.isPending)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () =>
                            TalkService.markReportReviewed(report.id),
                        child: const Text('확인함으로 표시'),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
