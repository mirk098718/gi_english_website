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
    if (compact) {
      return Container(
        color: Palette.white,
        padding: EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          children: [
            _boardCard(
              context,
              title: 'Notice Board',
              height: 350,
              onTitlePressed: () {
                MenuUtil.push(context, SchoolCommunityNoticePage());
              },
              child: _noticeList(context),
            ),
            SizedBox(height: 20),
            _boardCard(
              context,
              title: 'FAQ',
              height: 350,
              onTitlePressed: () {
                MenuUtil.push(context, SchoolCommunityBoardPage());
              },
              child: _faqList(context),
            ),
          ],
        ),
      );
    }

    return Container(
      color: Palette.white,
      padding: EdgeInsets.symmetric(vertical: 56, horizontal: 40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Spacer(),
          Expanded(
            flex: 5,
            child: _boardCard(
              context,
              title: 'Notice Board',
              height: 550,
              onTitlePressed: () {
                MenuUtil.push(context, SchoolCommunityNoticePage());
              },
              child: _noticeList(context),
            ),
          ),
          Spacer(),
          Expanded(
            flex: 5,
            child: _boardCard(
              context,
              title: 'FAQ',
              height: 550,
              onTitlePressed: () {
                MenuUtil.push(context, SchoolCommunityBoardPage());
              },
              child: _faqList(context),
            ),
          ),
          Spacer(),
        ],
      ),
    );
  }

  Widget _boardCard(
    BuildContext context, {
    required String title,
    required double height,
    required VoidCallback onTitlePressed,
    required Widget child,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Palette.white,
        border: Border.all(color: Palette.grey100, width: 3),
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 50,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Palette.grey100,
              border: Border.all(color: Palette.grey100, width: 3),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: TextButton(
              onPressed: onTitlePressed,
              child: Text(
                title,
                style: TextStyle(
                  color: Palette.black,
                  fontFamily: 'Jalnan',
                ),
              ),
            ),
          ),
          Expanded(child: child),
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
        return Container(
          color: Palette.white,
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: notices.length,
            separatorBuilder: (_, __) =>
                Container(height: 1, color: Palette.grey200),
            itemBuilder: (context, index) =>
                _noticeItem(context, notices[index]),
          ),
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
        return Container(
          color: Palette.white,
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: faqs.length,
            separatorBuilder: (_, __) =>
                Container(height: 1, color: Palette.grey200),
            itemBuilder: (context, index) => _faqItem(context, faqs[index]),
          ),
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
      return Container(
        color: Palette.white,
        padding: EdgeInsets.all(20),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: compact ? 2 : 4,
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
    return Container(
      color: Palette.white,
      padding: EdgeInsets.all(20),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: compact ? 12 : 14,
            color: color,
            fontFamily: 'NotoSansKR',
          ),
        ),
      ),
    );
  }

  Widget _noticeItem(BuildContext context, Notice notice) {
    final limit = compact ? 40 : 60;
    final preview = notice.content.length > limit
        ? '${notice.content.substring(0, limit)}...'
        : notice.content;

    return InkWell(
      onTap: () {
        if (notice.id != null) {
          MenuUtil.push(context, NoticeDetailPage(noticeId: notice.id!));
        }
      },
      child: Container(
        padding: EdgeInsets.all(compact ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (notice.isImportant) ...[
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 4 : 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Palette.danger,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      '중요',
                      style: TextStyle(
                        color: Palette.white,
                        fontSize: compact ? 8 : 10,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'NotoSansKR',
                      ),
                    ),
                  ),
                  SizedBox(width: compact ? 6 : 8),
                ],
                Expanded(
                  child: Text(
                    notice.title,
                    style: TextStyle(
                      color: Palette.black,
                      fontFamily: 'NotoSansKR',
                      fontWeight: FontWeight.bold,
                      fontSize: compact ? 13 : 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  DateFormat('MM.dd').format(notice.createdAt),
                  style: TextStyle(
                    color: Palette.grey600,
                    fontFamily: 'NotoSansKR',
                    fontSize: compact ? 10 : 12,
                  ),
                ),
              ],
            ),
            SizedBox(height: compact ? 6 : 8),
            Text(
              preview,
              style: TextStyle(
                color: Palette.grey700,
                fontFamily: 'NotoSansKR',
                fontSize: compact ? 12 : 13,
                height: compact ? 1.3 : 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _faqItem(BuildContext context, FAQ faq) {
    final limit = compact ? 30 : 50;
    final preview = faq.answer.length > limit
        ? '${faq.answer.substring(0, limit)}...'
        : faq.answer;

    return InkWell(
      onTap: () {
        MenuUtil.push(context, SchoolCommunityBoardPage());
      },
      child: Container(
        padding: EdgeInsets.all(compact ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 4 : 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: faq.isImportant ? Palette.darkTeal : Palette.grey300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    faq.category,
                    style: TextStyle(
                      color:
                          faq.isImportant ? Palette.white : Palette.grey700,
                      fontSize: compact ? 8 : 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'NotoSansKR',
                    ),
                  ),
                ),
                SizedBox(width: compact ? 6 : 8),
                if (faq.isImportant) ...[
                  Icon(
                    Icons.star,
                    color: Palette.darkTeal,
                    size: compact ? 12 : 14,
                  ),
                  SizedBox(width: 4),
                ],
              ],
            ),
            SizedBox(height: compact ? 6 : 8),
            Text(
              'Q: ${faq.question}',
              style: TextStyle(
                color: Palette.black,
                fontFamily: 'NotoSansKR',
                fontWeight: FontWeight.bold,
                fontSize: compact ? 13 : 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: compact ? 4 : 6),
            Text(
              'A: $preview',
              style: TextStyle(
                color: Palette.grey700,
                fontFamily: 'NotoSansKR',
                fontSize: compact ? 12 : 13,
                height: compact ? 1.3 : 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
