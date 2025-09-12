import 'package:flutter/material.dart';
import 'package:gi_english_website/class/Notice.dart';
import 'package:gi_english_website/pages/AdminNoticeWritePage.dart';
import 'package:gi_english_website/pages/SchoolGalleryPage.dart';
import 'package:gi_english_website/pages/SchoolConsultationPage.dart';
import 'package:gi_english_website/pages/SchoolCommunityBoardPage.dart';
import 'package:gi_english_website/pages/NoticeDetailPage.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/NoticeService.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/widget/ButtonState.dart';
import 'package:gi_english_website/widget/CommunityPageLayout.dart';
import 'package:gi_english_website/widget/BoardTable.dart';
import 'package:gi_english_website/util/WidgetUtil.dart';
import 'package:intl/intl.dart';

class SchoolCommunityNoticePage extends StatefulWidget {
  const SchoolCommunityNoticePage({Key? key}) : super(key: key);

  @override
  _SchoolCommunityNoticePageState createState() =>
      _SchoolCommunityNoticePageState();
}

class _SchoolCommunityNoticePageState extends State<SchoolCommunityNoticePage> {
  bool _isAdmin = false;

  List<ButtonState> get buttonStateList => [
        ButtonState("Notice Board", BehaviorColor.colorOnClick,
            SchoolCommunityNoticePage()),
        ButtonState(
            "FAQ", BehaviorColor.colorOnDefault, SchoolCommunityBoardPage()),
        ButtonState(
            "Gallery", BehaviorColor.colorOnDefault, SchoolGalleryPage()),
        ButtonState(
            "입학상담", BehaviorColor.colorOnDefault, SchoolConsultationPage()),
      ];

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    bool isAdmin = await AuthService.isAdmin();
    if (mounted) {
      setState(() {
        _isAdmin = isAdmin;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommunityPageLayout(
      currentPage: "Notice Board",
      menuItems: buttonStateList,
      content: _buildContent(),
    );
  }

  Widget _buildContent() {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.all(20),
      color: Palette.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Notice Board",
                style: TextStyle(fontFamily: "Jalnan", fontSize: 20),
              ),
              if (_isAdmin)
                ElevatedButton.icon(
                  onPressed: () => _navigateToWritePage(),
                  icon: Icon(Icons.edit, size: 16),
                  label: Text("글쓰기"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Palette.primary,
                    foregroundColor: Palette.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
            ],
          ),
          WidgetUtil.myDivider(),
          SizedBox(height: 20),
          Text(
            "글림아일랜드의 최신 소식과 공지사항을 확인하세요.",
            style: TextStyle(
              fontSize: 14,
              color: Palette.grey600,
              fontFamily: "NotoSansKR",
            ),
          ),
          SizedBox(height: 20),
          _buildNoticeBoard()
        ],
      ),
    );
  }

  Widget _buildNoticeBoard() {
    return _buildStreamNoticeBoard();
  }

  Widget _buildStreamNoticeBoard() {
    return StreamBuilder<List<Notice>>(
      stream: NoticeService.getNoticesStreamSorted(),
      builder: (context, snapshot) {
        print('StreamBuilder 상태: ${snapshot.connectionState}');
        print('에러 여부: ${snapshot.hasError}');
        if (snapshot.hasError) {
          print('StreamBuilder 에러: ${snapshot.error}');
        }
        print('데이터 개수: ${snapshot.data?.length ?? 0}');

        if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error.toString());
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingWidget('공지사항을 불러오는 중...');
        }

        List<Notice> notices = snapshot.data ?? [];
        return _buildNoticeTable(notices);
      },
    );
  }

  Widget _buildErrorWidget(String error) {
    return Container(
      padding: EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '공지사항을 불러오는데 오류가 발생했습니다.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.red,
                fontFamily: "NotoSansKR",
              ),
            ),
            SizedBox(height: 8),
            Text(
              '오류: $error',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red[300],
                fontFamily: "NotoSansKR",
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {});
              },
              child: Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget(String message) {
    return Container(
      padding: EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Palette.primary),
            ),
            SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Palette.grey600,
                fontFamily: "NotoSansKR",
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoticeTable(List<Notice> notices) {
    print('최종 공지사항 개수: ${notices.length}');

    List<Map<String, dynamic>> noticeData = notices.map((notice) {
      return {
        'id': notice.id,
        'title': notice.title,
        'author': notice.author,
        'date': DateFormat('yyyy.MM.dd').format(notice.createdAt),
        'isImportant': notice.isImportant,
        'content': notice.content,
      };
    }).toList();

    return BoardTable(
      items: noticeData,
      headers: ["번호", "제목", "작성일"],
      onItemTap: (item) => _navigateToDetail(item['id']),
      emptyMessage: "등록된 공지사항이 없습니다.",
      isAdmin: _isAdmin,
      onEditTap: _isAdmin ? (item) => _editNotice(item['id']) : null,
      onDeleteTap:
          _isAdmin ? (item) => _deleteNotice(item['id'], item['title']) : null,
    );
  }

  void _navigateToDetail(String? noticeId) {
    if (noticeId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NoticeDetailPage(noticeId: noticeId),
        ),
      );
    }
  }

  void _navigateToWritePage() async {
    // 관리자만 글쓰기 페이지로 이동
    bool isAdmin = await AuthService.isAdmin();
    if (isAdmin) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdminNoticeWritePage(),
          fullscreenDialog: true,
        ),
      ).then((result) {
        // 글쓰기 완료 후 돌아왔을 때 목록 새로고침할 수 있도록
        if (result == true) {
          setState(() {});
        }
      });
    }
  }

  Future<void> _editNotice(String? noticeId) async {
    if (noticeId == null) return;

    try {
      Notice? notice = await NoticeService.getNotice(noticeId);
      if (notice == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('공지사항을 찾을 수 없습니다.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdminNoticeWritePage(notice: notice),
          fullscreenDialog: true,
        ),
      );

      if (result == true) {
        // 수정 완료 후 목록 새로고침
        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('공지사항 수정 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteNotice(String? noticeId, String? noticeTitle) async {
    if (noticeId == null) return;

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "공지사항 삭제",
          style: TextStyle(fontFamily: "NotoSansKR"),
        ),
        content: Text(
          "공지사항 '$noticeTitle'을(를) 삭제하시겠습니까?\n삭제된 공지사항은 복구할 수 없습니다.",
          style: TextStyle(fontFamily: "NotoSansKR"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              "취소",
              style: TextStyle(fontFamily: "NotoSansKR"),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(
              "삭제",
              style: TextStyle(fontFamily: "NotoSansKR"),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        bool success = await NoticeService.deleteNotice(noticeId);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '공지사항이 삭제되었습니다.',
                style: TextStyle(fontFamily: "NotoSansKR"),
              ),
              backgroundColor: Colors.green,
            ),
          );
          // 삭제 완료 후 목록 새로고침
          setState(() {});
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '공지사항 삭제에 실패했습니다.',
                style: TextStyle(fontFamily: "NotoSansKR"),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '공지사항 삭제 중 오류가 발생했습니다: $e',
              style: TextStyle(fontFamily: "NotoSansKR"),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
