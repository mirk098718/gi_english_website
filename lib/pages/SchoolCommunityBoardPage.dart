import 'package:flutter/material.dart';
import 'package:gi_english_website/class/FAQ.dart';
import 'package:gi_english_website/pages/SchoolConsultationPage.dart';
import 'package:gi_english_website/pages/SchoolGalleryPage.dart';
import 'package:gi_english_website/pages/SchoolCommunityNoticePage.dart';
import 'package:gi_english_website/pages/WorkingAdminLoginPage.dart';
import 'package:gi_english_website/pages/AdminFAQWritePage.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/FAQService.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/widget/ButtonState.dart';
import 'package:gi_english_website/widget/CommunityPageLayout.dart';
import 'package:gi_english_website/widget/BoardTable.dart';
import 'package:gi_english_website/util/WidgetUtil.dart';
import 'package:intl/intl.dart';

class SchoolCommunityBoardPage extends StatefulWidget {
  const SchoolCommunityBoardPage({Key? key}) : super(key: key);

  @override
  _SchoolCommunityBoardPageState createState() =>
      _SchoolCommunityBoardPageState();
}

class _SchoolCommunityBoardPageState extends State<SchoolCommunityBoardPage> {
  bool _isAdmin = false;

  List<ButtonState> get buttonStateList => [
        ButtonState("Notice Board", BehaviorColor.colorOnDefault,
            SchoolCommunityNoticePage()),
        ButtonState(
            "FAQ", BehaviorColor.colorOnClick, SchoolCommunityBoardPage()),
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
      currentPage: "FAQ",
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
                "FAQ",
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
            "자주 묻는 질문과 답변을 확인하실 수 있습니다.",
            style: TextStyle(
              fontSize: 14,
              color: Palette.grey600,
              fontFamily: "NotoSansKR",
            ),
          ),
          SizedBox(height: 20),
          _buildFAQBoard()
        ],
      ),
    );
  }

  Widget _buildFAQBoard() {
    return StreamBuilder<List<FAQ>>(
      stream: FAQService.getFAQsStreamSorted(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            padding: EdgeInsets.all(40),
            child: Center(
              child: Text(
                'FAQ를 불러오는데 오류가 발생했습니다.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red,
                  fontFamily: "NotoSansKR",
                ),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: EdgeInsets.all(40),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Palette.primary),
              ),
            ),
          );
        }

        List<FAQ> faqs = snapshot.data ?? [];
        List<Map<String, dynamic>> faqData = faqs.map((faq) {
          return {
            'id': faq.id,
            'title': faq.question,
            'category': faq.category,
            'date': DateFormat('yyyy.MM.dd').format(faq.createdAt),
            'isImportant': faq.isImportant,
            'content': faq.answer,
          };
        }).toList();

        return BoardTable(
          items: faqData,
          headers: ["카테고리", "질문", "작성일"],
          onItemTap: (item) => _showFAQDialog(item),
          emptyMessage: "등록된 FAQ가 없습니다.",
        );
      },
    );
  }

  void _showFAQDialog(Map<String, dynamic> faq) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              if (faq['isImportant'] ?? false) ...[
                Icon(Icons.star, color: Palette.primary, size: 20),
                SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  faq['title'] ?? '',
                  style: TextStyle(fontFamily: "NotoSansKR"),
                ),
              ),
            ],
          ),
          content: Container(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (faq['isImportant'] ?? false)
                            ? Palette.primary.withOpacity(0.1)
                            : Palette.grey100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        faq['category'] ?? 'FAQ',
                        style: TextStyle(
                          fontSize: 12,
                          color: (faq['isImportant'] ?? false)
                              ? Palette.primary
                              : Palette.grey600,
                          fontFamily: "NotoSansKR",
                        ),
                      ),
                    ),
                    Spacer(),
                    Text(
                      faq['date'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Palette.grey600,
                        fontFamily: "NotoSansKR",
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Palette.grey50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Palette.grey200),
                  ),
                  child: Text(
                    faq['content'] ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: "NotoSansKR",
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("닫기", style: TextStyle(fontFamily: "NotoSansKR")),
            ),
          ],
        );
      },
    );
  }

  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkingAdminLoginPage(category: 'faq'),
      ),
    ).then((_) {
      // 로그인 후 돌아왔을 때 관리자 상태 다시 확인
      _checkAdminStatus();
    });
  }

  void _navigateToWritePage() async {
    // 이미 로그인된 상태면 바로 FAQ 글쓰기 페이지로
    bool isAdmin = await AuthService.isAdmin();
    if (isAdmin) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdminFAQWritePage(),
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
          builder: (context) => WorkingAdminLoginPage(category: 'faq'),
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
