import 'package:flutter/material.dart';
import 'package:gi_english_website/class/Notice.dart';
import 'package:gi_english_website/pages/WorkingAdminLoginPage.dart';
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
  bool _useStream = true; // 스트림 사용 여부

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
              Row(
                children: [
                  if (!_isAdmin)
                    ElevatedButton.icon(
                      onPressed: () => _navigateToLogin(),
                      icon: Icon(Icons.login, size: 16),
                      label: Text("관리자 로그인"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[600],
                        foregroundColor: Palette.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  if (_isAdmin) ...[
                    ElevatedButton.icon(
                      onPressed: () => _navigateToWritePage(),
                      icon: Icon(Icons.edit, size: 16),
                      label: Text("글쓰기"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Palette.primary,
                        foregroundColor: Palette.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _logout(),
                      icon: Icon(Icons.logout, size: 16),
                      label: Text("로그아웃"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Palette.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ],
                ],
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
          // 개발용 버튼들 (임시)
          if (_isAdmin)
            Container(
              margin: EdgeInsets.only(bottom: 20),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      await NoticeService.addDummyNotices();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('더미 공지사항 데이터가 추가되었습니다.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    child: Text('더미 데이터 추가'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () async {
                      bool isConnected = await NoticeService.checkConnection();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isConnected
                              ? 'Firebase 연결 성공!'
                              : 'Firebase 연결 실패!'),
                          backgroundColor:
                              isConnected ? Colors.green : Colors.red,
                        ),
                      );
                    },
                    child: Text('연결 확인'),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _useStream = !_useStream;
                      });
                    },
                    child: Text(_useStream ? 'Future 사용' : 'Stream 사용'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple),
                  ),
                ],
              ),
            ),
          _buildNoticeBoard()
        ],
      ),
    );
  }

  Widget _buildNoticeBoard() {
    if (_useStream) {
      return _buildStreamNoticeBoard();
    } else {
      return _buildFutureNoticeBoard();
    }
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
          return _buildErrorWidget(snapshot.error.toString(), isStream: true);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingWidget('Stream으로 공지사항을 불러오는 중...');
        }

        List<Notice> notices = snapshot.data ?? [];
        return _buildNoticeTable(notices);
      },
    );
  }

  Widget _buildFutureNoticeBoard() {
    return FutureBuilder<List<Notice>>(
      future: NoticeService.getNoticesSimple(),
      builder: (context, snapshot) {
        print('FutureBuilder 상태: ${snapshot.connectionState}');
        print('에러 여부: ${snapshot.hasError}');
        if (snapshot.hasError) {
          print('FutureBuilder 에러: ${snapshot.error}');
        }
        print('데이터 개수: ${snapshot.data?.length ?? 0}');

        if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error.toString(), isStream: false);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingWidget('Future로 공지사항을 불러오는 중...');
        }

        List<Notice> notices = snapshot.data ?? [];
        return _buildNoticeTable(notices);
      },
    );
  }

  Widget _buildErrorWidget(String error, {required bool isStream}) {
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
              '현재 ${isStream ? "Stream" : "Future"} 방식 사용',
              style: TextStyle(
                fontSize: 12,
                color: Palette.grey600,
                fontFamily: "NotoSansKR",
              ),
            ),
            SizedBox(height: 4),
            Text(
              '오류: $error',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red[300],
                fontFamily: "NotoSansKR",
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                  },
                  child: Text('다시 시도'),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _useStream = !_useStream;
                    });
                  },
                  child: Text('${isStream ? "Future" : "Stream"} 방식으로 전환'),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                ),
              ],
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
      headers: ["번호", "제목", "작성자", "작성일"],
      onItemTap: (item) => _navigateToDetail(item['id']),
      emptyMessage: "등록된 공지사항이 없습니다.",
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

  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkingAdminLoginPage(category: 'notice'),
      ),
    ).then((_) {
      // 로그인 후 돌아왔을 때 관리자 상태 다시 확인
      _checkAdminStatus();
    });
  }

  void _navigateToWritePage() async {
    // 이미 로그인된 상태면 바로 글쓰기 페이지로
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
    } else {
      // 로그인이 안된 상태면 로그인 페이지로
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WorkingAdminLoginPage(category: 'notice'),
        ),
      ).then((_) {
        // 로그인 후 돌아왔을 때 관리자 상태 다시 확인
        _checkAdminStatus();
      });
    }
  }

  Future<void> _logout() async {
    try {
      // AuthService를 통해 로그아웃 (SharedPreferences도 함께 정리됨)
      await AuthService.signOut();

      setState(() {
        _isAdmin = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('로그아웃되었습니다.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('로그아웃 중 오류가 발생했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
