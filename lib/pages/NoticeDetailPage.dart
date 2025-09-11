import 'package:flutter/material.dart';
import 'package:gi_english_website/class/Notice.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/NoticeService.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/widget/WebSchoolLayout.dart';
import 'package:gi_english_website/widget/MobileSchoolLayout.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/pages/AdminNoticeWritePage.dart';
import 'package:intl/intl.dart';

class NoticeDetailPage extends StatefulWidget {
  final String noticeId;

  const NoticeDetailPage({Key? key, required this.noticeId}) : super(key: key);

  @override
  _NoticeDetailPageState createState() => _NoticeDetailPageState();
}

class _NoticeDetailPageState extends State<NoticeDetailPage> {
  Notice? _notice;
  bool _isLoading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadNotice();
    _checkAdminStatus();
  }

  Future<void> _loadNotice() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Notice? notice = await NoticeService.getNotice(widget.noticeId);
      setState(() {
        _notice = notice;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '공지사항을 불러오는데 실패했습니다.',
            style: TextStyle(fontFamily: "NotoSansKR"),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _checkAdminStatus() async {
    bool isAdmin = await AuthService.isAdmin();
    setState(() {
      _isAdmin = isAdmin;
    });
  }

  @override
  Widget build(BuildContext context) {
    MediaQueryData mediaQueryData = MediaQuery.of(context);
    Size size = mediaQueryData.size;
    double width = size.width;

    if (width > 768) {
      return WebSchoolLayout(content: _buildScrollView());
    } else {
      return MobileSchoolLayout(content: _buildScrollView());
    }
  }

  Widget _buildScrollView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildMainImage(),
          _buildContentGroup(),
          MyWidget.footer(),
        ],
      ),
    );
  }

  Widget _buildMainImage() {
    return Container(
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          Image.asset("assets/communityMainImage.png"),
          Container(
            padding: EdgeInsets.only(left: 40, bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "Notice Detail",
                  style: TextStyle(
                      color: Palette.white,
                      fontSize: 30,
                      fontFamily: "LucidaCalligraphy"),
                ),
                SizedBox(height: 20),
                Container(
                  width: 150,
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Palette.black,
                      foregroundColor: Palette.black,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text("뒤로가기",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: "Jalnan",
                          color: Palette.white,
                        )),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildContentGroup() {
    if (_isLoading) {
      return Container(
        color: Palette.white,
        padding: EdgeInsets.all(40),
        height: 400,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Palette.primary),
          ),
        ),
      );
    }

    if (_notice == null) {
      return Container(
        color: Palette.white,
        padding: EdgeInsets.all(40),
        height: 400,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Palette.grey400,
              ),
              SizedBox(height: 16),
              Text(
                "공지사항을 찾을 수 없습니다.",
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: "NotoSansKR",
                  color: Palette.grey600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Palette.white,
      padding: EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 관리자 버튼들
          if (_isAdmin) _buildAdminActions(),

          // 제목 영역
          _buildTitleSection(),

          SizedBox(height: 32),

          // 내용 영역
          _buildContentSection(),
        ],
      ),
    );
  }

  Widget _buildAdminActions() {
    return Container(
      margin: EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton.icon(
            onPressed: () => _editNotice(),
            icon: Icon(Icons.edit, size: 16),
            label: Text("수정"),
            style: OutlinedButton.styleFrom(
              foregroundColor: Palette.primary,
              side: BorderSide(color: Palette.primary),
            ),
          ),
          SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => _deleteNotice(),
            icon: Icon(Icons.delete, size: 16),
            label: Text("삭제"),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: BorderSide(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 중요 공지 표시
        if (_notice!.isImportant)
          Container(
            margin: EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              "중요",
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: "NotoSansKR",
              ),
            ),
          ),

        // 제목
        Text(
          _notice!.title,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            fontFamily: "NotoSansKR",
            color: Palette.black,
          ),
        ),

        SizedBox(height: 16),

        // 구분선
        Container(
          height: 2,
          width: double.infinity,
          color: Palette.primary,
        ),

        SizedBox(height: 16),

        // 메타 정보
        Row(
          children: [
            _buildMetaInfo("작성자", _notice!.author),
            SizedBox(width: 24),
            _buildMetaInfo("작성일",
                DateFormat('yyyy.MM.dd HH:mm').format(_notice!.createdAt)),
            if (_notice!.updatedAt != null) ...[
              SizedBox(width: 24),
              _buildMetaInfo("수정일",
                  DateFormat('yyyy.MM.dd HH:mm').format(_notice!.updatedAt!)),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildMetaInfo(String label, String value) {
    return Row(
      children: [
        Text(
          "$label: ",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: "NotoSansKR",
            color: Palette.grey600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontFamily: "NotoSansKR",
            color: Palette.grey800,
          ),
        ),
      ],
    );
  }

  Widget _buildContentSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Palette.grey50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Palette.grey200),
      ),
      child: Text(
        _notice!.content,
        style: TextStyle(
          fontSize: 16,
          height: 1.6,
          fontFamily: "NotoSansKR",
          color: Palette.black,
        ),
      ),
    );
  }

  Future<void> _editNotice() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminNoticeWritePage(notice: _notice),
      ),
    );

    if (result == true) {
      // 수정 완료 후 다시 로드
      _loadNotice();
    }
  }

  Future<void> _deleteNotice() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "공지사항 삭제",
          style: TextStyle(fontFamily: "NotoSansKR"),
        ),
        content: Text(
          "이 공지사항을 삭제하시겠습니까?\n삭제된 공지사항은 복구할 수 없습니다.",
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
      bool success = await NoticeService.deleteNotice(widget.noticeId);

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
        Navigator.pop(context, true); // 삭제 완료 후 이전 페이지로
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
    }
  }
}
