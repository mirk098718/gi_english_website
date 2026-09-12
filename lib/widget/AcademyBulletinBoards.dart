import 'package:flutter/material.dart';
import 'package:gi_english_website/class/FAQ.dart';
import 'package:gi_english_website/class/Notice.dart';
import 'package:gi_english_website/pages/NoticeDetailPage.dart';
import 'package:gi_english_website/pages/SchoolCommunityBoardPage.dart';
import 'package:gi_english_website/pages/SchoolCommunityNoticePage.dart';
import 'package:gi_english_website/util/FAQService.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/NoticeService.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:intl/intl.dart';

/// 학원 홈 Notice Board + FAQ 카드.
class AcademyBulletinBoards extends StatelessWidget {
  final bool compact;

  const AcademyBulletinBoards({Key? key, this.compact = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final boards = compact
        ? Column(
            children: [
              _boardCard(
                context,
                title: '공지사항',
                onTitlePressed: () {
                  MenuUtil.push(context, SchoolCommunityNoticePage());
                },
                child: _noticeList(context),
              ),
              SizedBox(height: 12),
              _boardCard(
                context,
                title: 'FAQ',
                onTitlePressed: () {
                  MenuUtil.push(context, SchoolCommunityBoardPage());
                },
                child: _faqList(context),
              ),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _boardCard(
                  context,
                  title: '공지사항',
                  onTitlePressed: () {
                    MenuUtil.push(context, SchoolCommunityNoticePage());
                  },
                  child: _noticeList(context),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _boardCard(
                  context,
                  title: 'FAQ',
                  onTitlePressed: () {
                    MenuUtil.push(context, SchoolCommunityBoardPage());
                  },
                  child: _faqList(context),
                ),
              ),
            ],
          );

    return Container(
      color: Palette.white,
      padding: EdgeInsets.fromLTRB(
        compact ? 20 : 48,
        compact ? 8 : 36,
        compact ? 20 : 48,
        compact ? 24 : 40,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: boards,
        ),
      ),
    );
  }

  Widget _boardCard(
    BuildContext context, {
    required String title,
    required VoidCallback onTitlePressed,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Palette.white,
        border: Border.all(color: Palette.grey200),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 14,
                  color: Palette.navy,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Palette.navy,
                      fontFamily: 'NotoSansKR',
                      fontWeight: FontWeight.w800,
                      fontSize: compact ? 15 : 16,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onTitlePressed,
                  style: TextButton.styleFrom(
                    foregroundColor: Palette.grey600,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(
                      fontFamily: 'NotoSansKR',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('더보기'),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Palette.grey200),
          child,
        ],
      ),
    );
  }

  Widget _noticeList(BuildContext context) {
    return StreamBuilder<List<Notice>>(
      stream: NoticeService.getNoticesStreamSorted(),
      builder: (context, snapshot) {
        final status = _status(
          hasError: snapshot.hasError,
          waiting: snapshot.connectionState == ConnectionState.waiting,
          empty: (snapshot.data ?? []).isEmpty,
          errorText: '공지사항을 불러오는데 오류가 발생했습니다.',
          emptyText: '등록된 공지사항이 없습니다.',
        );
        if (status != null) return status;

        final notices = (snapshot.data ?? []).take(5).toList();
        return Column(
          children: [
            for (var i = 0; i < notices.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: Palette.grey200),
              _noticeItem(context, notices[i]),
            ],
          ],
        );
      },
    );
  }

  Widget _faqList(BuildContext context) {
    return StreamBuilder<List<FAQ>>(
      stream: FAQService.getFAQsStreamSorted(),
      builder: (context, snapshot) {
        final status = _status(
          hasError: snapshot.hasError,
          waiting: snapshot.connectionState == ConnectionState.waiting,
          empty: (snapshot.data ?? []).isEmpty,
          errorText: 'FAQ를 불러오는데 오류가 발생했습니다.',
          emptyText: '등록된 FAQ가 없습니다.',
        );
        if (status != null) return status;

        final faqs = (snapshot.data ?? []).take(5).toList();
        return Column(
          children: [
            for (var i = 0; i < faqs.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: Palette.grey200),
              _faqItem(context, faqs[i]),
            ],
          ],
        );
      },
    );
  }

  Widget? _status({
    required bool hasError,
    required bool waiting,
    required bool empty,
    required String errorText,
    required String emptyText,
  }) {
    if (hasError) {
      return _message(errorText, Palette.danger);
    }
    if (waiting) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Palette.darkTeal),
          ),
        ),
      );
    }
    if (empty) {
      return _message(emptyText, Palette.grey600);
    }
    return null;
  }

  Widget _message(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: compact ? 12 : 13,
            color: color,
            fontFamily: 'NotoSansKR',
          ),
        ),
      ),
    );
  }

  Widget _noticeItem(BuildContext context, Notice notice) {
    return InkWell(
      onTap: () {
        if (notice.id != null) {
          MenuUtil.push(context, NoticeDetailPage(noticeId: notice.id!));
        }
      },
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 14,
          vertical: compact ? 10 : 11,
        ),
        child: Row(
          children: [
            if (notice.isImportant) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: Palette.danger,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  '중요',
                  style: TextStyle(
                    color: Palette.white,
                    fontSize: compact ? 9 : 10,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'NotoSansKR',
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                notice.title,
                style: TextStyle(
                  color: Palette.black,
                  fontFamily: 'NotoSansKR',
                  fontWeight:
                      notice.isImportant ? FontWeight.w700 : FontWeight.w500,
                  fontSize: compact ? 13 : 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              DateFormat('MM.dd').format(notice.createdAt),
              style: TextStyle(
                color: Palette.grey500,
                fontFamily: 'NotoSansKR',
                fontSize: compact ? 11 : 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _faqItem(BuildContext context, FAQ faq) {
    return InkWell(
      onTap: () {
        MenuUtil.push(context, SchoolCommunityBoardPage());
      },
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 14,
          vertical: compact ? 10 : 11,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: faq.isImportant
                    ? Palette.navy.withValues(alpha: 0.08)
                    : Palette.grey100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                faq.category,
                style: TextStyle(
                  color: faq.isImportant ? Palette.navy : Palette.grey600,
                  fontSize: compact ? 10 : 11,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'NotoSansKR',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                faq.question,
                style: TextStyle(
                  color: Palette.black,
                  fontFamily: 'NotoSansKR',
                  fontWeight:
                      faq.isImportant ? FontWeight.w700 : FontWeight.w500,
                  fontSize: compact ? 13 : 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
