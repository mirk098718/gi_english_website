import 'package:flutter/material.dart';
import 'package:gi_english_website/pages/SchoolConsultationPage.dart';
import 'package:gi_english_website/pages/SchoolCommunityNoticePage.dart';
import 'package:gi_english_website/pages/SchoolCommunityBoardPage.dart';
import 'package:gi_english_website/pages/NoticeDetailPage.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/ModernWidgets.dart';
import 'package:gi_english_website/util/NoticeService.dart';
import 'package:gi_english_website/util/FAQService.dart';
import 'package:gi_english_website/widget/EasyKeyboardListener.dart';
import 'package:gi_english_website/widget/MobileSchoolLayout.dart';
import 'package:gi_english_website/widget/WebSchoolLayout.dart';
import 'package:gi_english_website/class/Notice.dart';
import 'package:gi_english_website/class/FAQ.dart';
import '../admin/page/AdminLoginPage.dart';
import '../util/UrlIUtil.dart';
import 'package:intl/intl.dart';

class SchoolMainPage extends StatefulWidget {
  const SchoolMainPage({Key? key}) : super(key: key);

  @override
  _SchoolMainPageState createState() => _SchoolMainPageState();
}

class _SchoolMainPageState extends State<SchoolMainPage> {
  final hiddenMenu = "hiddenmenu";
  final idController = TextEditingController();
  final pwController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    MediaQueryData mediaQueryData = MediaQuery.of(context);
    Size size = mediaQueryData.size;
    double width = size.width;

    Widget returnWidget;
    if (width > 768) {
      returnWidget = desktopUi(context);
    } else {
      returnWidget = mobileUi(context);
    }

    return EasyKeyboardListener(
      onValue: (String value) {
        if (value == hiddenMenu) {
          MenuUtil.pop(context);
          MenuUtil.push(context, AdminLoginPage());
        }
      },
      inputLimit: hiddenMenu.length,
      child: returnWidget,
    );
  }

  Widget desktopUi(context) {
    return WebSchoolLayout(content: scrollView());
  }

  Widget mobileUi(context) {
    return MobileSchoolLayout(content: mobileScrollView());
  }

  Widget mainImage() {
    final screen = MediaQuery.sizeOf(context);
    final heroHeight = (screen.height - 72).clamp(480.0, 780.0);
    return SizedBox(
      width: double.infinity,
      height: heroHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            "assets/mainGateImageMiddleSchool.png",
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 48),
              child: Text(
                "Gleam Island School",
                style: TextStyle(
                  fontFamily: "Lovingu",
                  fontSize: 56,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(1.0, 1.0),
                      blurRadius: 8.0,
                      color: Colors.black45,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 32,
            right: 40,
            child: SizedBox(
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Palette.black.withValues(alpha: 0.78),
                  foregroundColor: Palette.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(horizontal: 22),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                onPressed: () {
                  MenuUtil.push(context, SchoolConsultationPage());
                },
                child: Text(
                  "상담 신청",
                  style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Palette.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget urlMenu() {
    return Container(
      alignment: Alignment.center,
      color: Palette.white,
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Container(
              height: 120,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: EdgeInsets.only(top: 5, bottom: 5),
                      alignment: Alignment.center,
                      child: Image.asset("assets/giAppBannerFinal.png"),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: 60,
                      alignment: Alignment.center,
                      child: Image.asset("assets/giAppDownload.png"),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.all(5),
                    width: 0.5,
                    height: 40,
                    color: Palette.grey500,
                  ),
                  Expanded(
                      flex: 1,
                      child: Container(
                        width: 80,
                        height: 80,
                        padding: EdgeInsets.all(10),
                        alignment: Alignment.center,
                        child: InkWell(
                            onTap: () async {
                              UrlUtil.open(
                                  'https://www.instagram.com/gleam_island_school/');
                            },
                            child: Image.asset("assets/instaLogo.png")),
                      )),
                  Container(
                    margin: EdgeInsets.all(5),
                    width: 0.5,
                    height: 40,
                    color: Palette.grey500,
                  ),
                  Expanded(
                      flex: 1,
                      child: Container(
                        width: 80,
                        height: 80,
                        padding: EdgeInsets.all(10),
                        alignment: Alignment.center,
                        child: InkWell(
                          onTap: () async {
                            UrlUtil.open(
                                'https://blog.naver.com/gleam-island-paju');
                          },
                          child: Container(
                              width: 40,
                              child: Image.asset("assets/naverBlogLogo.png")),
                        ),
                      )),
                ],
              ),
            ),
          ),
          Expanded(
              flex: 1,
              child: Container(
                height: 120,
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        margin: EdgeInsets.only(top: 15, bottom: 15),
                        child: InkWell(
                          child: Image.asset("assets/middleOnlineLink.png"),
                          onTap: () async {
                            UrlUtil.open('http://gienglish.theclip.net/');
                          },
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.all(5),
                      width: 0.5,
                      height: 40,
                      color: Palette.grey500,
                    ),
                    Expanded(
                      flex: 3,
                      child: Container(
                        margin: EdgeInsets.all(10),
                        child: InkWell(
                          child: Image.asset("assets/eleOnlineLink.png"),
                          onTap: () async {
                            UrlUtil.open(
                                'https://www.trophy9.com/account/account.do?stdcmd=sign&url=%2Fdefault%2Edo%3F');
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ))
        ],
      ),
    );
  }

  Widget bulletinBoard() {
    double eachBoardHeight = 550;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: 56, horizontal: 40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Spacer(),
          Expanded(
            flex: 5,
            child: _desktopGrayBoard(
              title: "Notice Board",
              height: eachBoardHeight,
              onTitlePressed: () {
                MenuUtil.push(context, SchoolCommunityNoticePage());
              },
              child: _buildNoticeList(),
            ),
          ),
          Spacer(),
          Expanded(
            flex: 5,
            child: _desktopGrayBoard(
              title: "FAQ",
              height: eachBoardHeight,
              onTitlePressed: () {
                MenuUtil.push(context, SchoolCommunityBoardPage());
              },
              child: _buildFAQList(),
            ),
          ),
          Spacer(),
        ],
      ),
    );
  }

  Widget _desktopGrayBoard({
    required String title,
    required double height,
    required VoidCallback onTitlePressed,
    required Widget child,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
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
                  fontFamily: "Jalnan",
                ),
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildNoticeList() {
    return StreamBuilder<List<Notice>>(
      stream: NoticeService.getNoticesStreamSorted(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            color: Colors.white,
            padding: EdgeInsets.all(20),
            child: Center(
              child: Text(
                '공지사항을 불러오는데 오류가 발생했습니다.',
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
            color: Colors.white,
            padding: EdgeInsets.all(20),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Palette.primary),
              ),
            ),
          );
        }

        List<Notice> notices = snapshot.data ?? [];
        // 최대 5개까지만 표시
        List<Notice> displayNotices = notices.take(5).toList();

        if (displayNotices.isEmpty) {
          return Container(
            color: Colors.white,
            padding: EdgeInsets.all(20),
            child: Center(
              child: Text(
                '등록된 공지사항이 없습니다.',
                style: TextStyle(
                  fontSize: 14,
                  color: Palette.grey600,
                  fontFamily: "NotoSansKR",
                ),
              ),
            ),
          );
        }

        return Container(
          color: Colors.white,
          child: ListView.separated(
            padding: EdgeInsets.all(0),
            itemCount: displayNotices.length,
            separatorBuilder: (context, index) => Container(
              height: 1,
              color: Palette.grey200,
            ),
            itemBuilder: (context, index) {
              Notice notice = displayNotices[index];
              return _buildNoticeItem(notice);
            },
          ),
        );
      },
    );
  }

  Widget _buildNoticeItem(Notice notice) {
    // 미리보기 텍스트 생성 (60자 제한)
    String preview = notice.content.length > 60
        ? '${notice.content.substring(0, 60)}...'
        : notice.content;

    return InkWell(
      onTap: () {
        if (notice.id != null) {
          MenuUtil.push(context, NoticeDetailPage(noticeId: notice.id!));
        }
      },
      child: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (notice.isImportant) ...[
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      "중요",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontFamily: "NotoSansKR",
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    notice.title,
                    style: TextStyle(
                      color: Palette.black,
                      fontFamily: "NotoSansKR",
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  DateFormat('MM.dd').format(notice.createdAt),
                  style: TextStyle(
                    color: Palette.grey600,
                    fontFamily: "NotoSansKR",
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              preview,
              style: TextStyle(
                color: Palette.grey700,
                fontFamily: "NotoSansKR",
                fontSize: 13,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQList() {
    return StreamBuilder<List<FAQ>>(
      stream: FAQService.getFAQsStreamSorted(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            color: Colors.white,
            padding: EdgeInsets.all(20),
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
            color: Colors.white,
            padding: EdgeInsets.all(20),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Palette.primary),
              ),
            ),
          );
        }

        List<FAQ> faqs = snapshot.data ?? [];
        // 최대 5개까지만 표시
        List<FAQ> displayFAQs = faqs.take(5).toList();

        if (displayFAQs.isEmpty) {
          return Container(
            color: Colors.white,
            padding: EdgeInsets.all(20),
            child: Center(
              child: Text(
                '등록된 FAQ가 없습니다.',
                style: TextStyle(
                  fontSize: 14,
                  color: Palette.grey600,
                  fontFamily: "NotoSansKR",
                ),
              ),
            ),
          );
        }

        return Container(
          color: Colors.white,
          child: ListView.separated(
            padding: EdgeInsets.all(0),
            itemCount: displayFAQs.length,
            separatorBuilder: (context, index) => Container(
              height: 1,
              color: Palette.grey200,
            ),
            itemBuilder: (context, index) {
              FAQ faq = displayFAQs[index];
              return _buildFAQItem(faq);
            },
          ),
        );
      },
    );
  }

  Widget _buildFAQItem(FAQ faq) {
    // 미리보기 텍스트 생성 (50자 제한)
    String preview = faq.answer.length > 50
        ? '${faq.answer.substring(0, 50)}...'
        : faq.answer;

    return InkWell(
      onTap: () {
        MenuUtil.push(context, SchoolCommunityBoardPage());
      },
      child: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: faq.isImportant ? Palette.primary : Palette.grey300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    faq.category,
                    style: TextStyle(
                      color: faq.isImportant ? Colors.white : Palette.grey700,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: "NotoSansKR",
                    ),
                  ),
                ),
                SizedBox(width: 8),
                if (faq.isImportant) ...[
                  Icon(Icons.star, color: Palette.primary, size: 14),
                  SizedBox(width: 4),
                ],
              ],
            ),
            SizedBox(height: 8),
            Text(
              "Q: ${faq.question}",
              style: TextStyle(
                color: Palette.black,
                fontFamily: "NotoSansKR",
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 6),
            Text(
              "A: $preview",
              style: TextStyle(
                color: Palette.grey700,
                fontFamily: "NotoSansKR",
                fontSize: 13,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget scrollView() {
    return SingleChildScrollView(
      child: Container(
        color: Palette.background,
        child: Column(
          children: [
            mainImage(),
            SizedBox(height: 100, child: urlMenu()),
            InkWell(
              child: Image.asset(
                "assets/mainBannerOpening.png",
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              onTap: () async {
                UrlUtil.open(
                    'https://blog.naver.com/gleam-island-paju/223029184863');
              },
            ),
            bulletinBoard(),
            ModernWidgets.modernFooter(),
          ],
        ),
      ),
    );
  }

  // mobile

  Widget mobileScrollView() {
    return SingleChildScrollView(
      child: Container(
        child: Column(
          children: [
            mobileMainImage(),
            InkWell(
              child: Image.asset("assets/mainBannerOpening.png"),
              onTap: () async {
                UrlUtil.open(
                    'https://blog.naver.com/gleam-island-paju/223029184863');
              },
            ),
            // mobileMenuList(),
            mobileUrlMenu(),
            mobileBulletinBoard(),
            ModernWidgets.modernMobileFooter()
          ],
        ),
      ),
    );
  }

  Widget mobileMainImage() {
    final screen = MediaQuery.sizeOf(context);
    final heroHeight = (screen.height - 108).clamp(320.0, 560.0);
    return SizedBox(
      width: double.infinity,
      height: heroHeight,
      child: Image.asset(
        "assets/mainGateImageMiddleSchool.png",
        fit: BoxFit.cover,
        alignment: Alignment.center,
      ),
    );
  }

  Widget mobileUrlMenu() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      color: Palette.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                  onTap: () async {
                    UrlUtil.open(
                        'https://www.instagram.com/gleam_island_school/');
                  },
                  child: Image.asset("assets/instaLogo.png")),
              Spacer(),
              Container(
                margin: EdgeInsets.all(5),
                width: 1,
                height: 40,
                color: Colors.black54,
              ),
              Spacer(),
              Container(
                  width: 40,
                  child: InkWell(
                      onTap: () async {
                        UrlUtil.open(
                            'https://blog.naver.com/gleam-island-paju');
                      },
                      child: Image.asset("assets/naverBlogLogo.png"))),
              Spacer(),
              Container(
                margin: EdgeInsets.all(5),
                width: 1,
                height: 40,
                color: Colors.black54,
              ),
              Spacer(),
              Container(
                  width: 70, child: Image.asset("assets/giAppDownload.png")),
              Spacer(),
              Container(
                margin: EdgeInsets.all(5),
                width: 1,
                height: 40,
                color: Colors.black54,
              ),
              Spacer(),
              Container(
                width: 80,
                height: 50,
                child: ElevatedButton(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "상담",
                        style: TextStyle(
                            fontFamily: "Jalnan",
                            fontSize: 10,
                            color: Palette.white),
                      ),
                      Text(
                        "신청",
                        style: TextStyle(
                            fontFamily: "Jalnan",
                            fontSize: 10,
                            color: Palette.white),
                      ),
                    ],
                  ),
                  onPressed: () {
                    MenuUtil.push(context, SchoolConsultationPage());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Palette.secondaryDark,
                    foregroundColor: Palette.black,
                  ),
                ),
              )
            ],
          ),
          SizedBox(
            height: 10,
          ),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: InkWell(
                  child: Container(
                      height: 55,
                      child: Image.asset("assets/middleOnlineLink.png")),
                  onTap: () async {
                    UrlUtil.open('http://gienglish.theclip.net/');
                  },
                ),
              ),
              Container(
                margin: EdgeInsets.all(5),
                width: 0.5,
                height: 40,
                color: Palette.grey500,
              ),
              Expanded(
                flex: 3,
                child: InkWell(
                  child: Container(
                      height: 55,
                      child: Image.asset("assets/eleOnlineLink.png")),
                  onTap: () async {
                    UrlUtil.open(
                        'https://www.trophy9.com/account/account.do?stdcmd=sign&url=%2Fdefault%2Edo%3F');
                  },
                ),
              ),
              SizedBox(
                width: 20,
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget mobileBulletinBoard() {
    return Container(
      color: Colors.white,
      margin: EdgeInsets.only(left: 20, right: 20),
      child: Column(
        children: [
          // Notice Board Section
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Palette.grey100, width: 3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  child: TextButton(
                    child: Text(
                      "Notice Board",
                      style:
                          TextStyle(color: Palette.black, fontFamily: "Jalnan"),
                    ),
                    onPressed: () {
                      MenuUtil.push(context, SchoolCommunityNoticePage());
                    },
                  ),
                  height: 50,
                  decoration: BoxDecoration(
                    color: Palette.grey100,
                    border: Border.all(color: Palette.grey100, width: 3),
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18)),
                  ),
                ),
                Container(
                  height: 350, // 공지 5개 표시 시 스크롤 가능한 높이
                  child: _buildMobileNoticeList(),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          // FAQ Section
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Palette.grey100, width: 3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  child: TextButton(
                    child: Text(
                      "FAQ",
                      style:
                          TextStyle(color: Palette.black, fontFamily: "Jalnan"),
                    ),
                    onPressed: () {
                      MenuUtil.push(context, SchoolCommunityBoardPage());
                    },
                  ),
                  height: 50,
                  decoration: BoxDecoration(
                    color: Palette.grey100,
                    border: Border.all(color: Palette.grey100, width: 3),
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18)),
                  ),
                ),
                Container(
                  height: 350, // FAQ 5개 표시 시 스크롤 가능한 높이
                  child: _buildMobileFAQList(),
                ),
              ],
            ),
          ),
          Container(height: 20)
        ],
      ),
    );
  }

  Widget _buildMobileNoticeList() {
    return StreamBuilder<List<Notice>>(
      stream: NoticeService.getNoticesStreamSorted(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            color: Colors.white,
            padding: EdgeInsets.all(20),
            child: Center(
              child: Text(
                '공지사항을 불러오는데 오류가 발생했습니다.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                  fontFamily: "NotoSansKR",
                ),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: Colors.white,
            padding: EdgeInsets.all(20),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Palette.primary),
                strokeWidth: 2,
              ),
            ),
          );
        }

        List<Notice> notices = snapshot.data ?? [];
        // 최대 5개까지만 표시
        List<Notice> displayNotices = notices.take(5).toList();

        if (displayNotices.isEmpty) {
          return Container(
            color: Colors.white,
            padding: EdgeInsets.all(20),
            child: Center(
              child: Text(
                '등록된 공지사항이 없습니다.',
                style: TextStyle(
                  fontSize: 12,
                  color: Palette.grey600,
                  fontFamily: "NotoSansKR",
                ),
              ),
            ),
          );
        }

        return Container(
          color: Colors.white,
          child: ListView.separated(
            padding: EdgeInsets.all(0),
            itemCount: displayNotices.length,
            separatorBuilder: (context, index) => Container(
              height: 1,
              color: Palette.grey200,
            ),
            itemBuilder: (context, index) {
              Notice notice = displayNotices[index];
              return _buildMobileNoticeItem(notice);
            },
          ),
        );
      },
    );
  }

  Widget _buildMobileNoticeItem(Notice notice) {
    // 미리보기 텍스트 생성 (40자 제한 - 모바일에서는 더 짧게)
    String preview = notice.content.length > 40
        ? '${notice.content.substring(0, 40)}...'
        : notice.content;

    return InkWell(
      onTap: () {
        if (notice.id != null) {
          MenuUtil.push(context, NoticeDetailPage(noticeId: notice.id!));
        }
      },
      child: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (notice.isImportant) ...[
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      "중요",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        fontFamily: "NotoSansKR",
                      ),
                    ),
                  ),
                  SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    notice.title,
                    style: TextStyle(
                      color: Palette.black,
                      fontFamily: "NotoSansKR",
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  DateFormat('MM.dd').format(notice.createdAt),
                  style: TextStyle(
                    color: Palette.grey600,
                    fontFamily: "NotoSansKR",
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6),
            Text(
              preview,
              style: TextStyle(
                color: Palette.grey700,
                fontFamily: "NotoSansKR",
                fontSize: 12,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileFAQList() {
    return StreamBuilder<List<FAQ>>(
      stream: FAQService.getFAQsStreamSorted(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            color: Colors.white,
            padding: EdgeInsets.all(20),
            child: Center(
              child: Text(
                'FAQ를 불러오는데 오류가 발생했습니다.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                  fontFamily: "NotoSansKR",
                ),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: Colors.white,
            padding: EdgeInsets.all(20),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Palette.primary),
                strokeWidth: 2,
              ),
            ),
          );
        }

        List<FAQ> faqs = snapshot.data ?? [];
        // 최대 5개까지만 표시
        List<FAQ> displayFAQs = faqs.take(5).toList();

        if (displayFAQs.isEmpty) {
          return Container(
            color: Colors.white,
            padding: EdgeInsets.all(20),
            child: Center(
              child: Text(
                '등록된 FAQ가 없습니다.',
                style: TextStyle(
                  fontSize: 12,
                  color: Palette.grey600,
                  fontFamily: "NotoSansKR",
                ),
              ),
            ),
          );
        }

        return Container(
          color: Colors.white,
          child: ListView.separated(
            padding: EdgeInsets.all(0),
            itemCount: displayFAQs.length,
            separatorBuilder: (context, index) => Container(
              height: 1,
              color: Palette.grey200,
            ),
            itemBuilder: (context, index) {
              FAQ faq = displayFAQs[index];
              return _buildMobileFAQItem(faq);
            },
          ),
        );
      },
    );
  }

  Widget _buildMobileFAQItem(FAQ faq) {
    // 미리보기 텍스트 생성 (30자 제한 - 모바일에서는 더 짧게)
    String preview = faq.answer.length > 30
        ? '${faq.answer.substring(0, 30)}...'
        : faq.answer;

    return InkWell(
      onTap: () {
        MenuUtil.push(context, SchoolCommunityBoardPage());
      },
      child: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: faq.isImportant ? Palette.primary : Palette.grey300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    faq.category,
                    style: TextStyle(
                      color: faq.isImportant ? Colors.white : Palette.grey700,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      fontFamily: "NotoSansKR",
                    ),
                  ),
                ),
                SizedBox(width: 6),
                if (faq.isImportant) ...[
                  Icon(Icons.star, color: Palette.primary, size: 12),
                  SizedBox(width: 4),
                ],
              ],
            ),
            SizedBox(height: 6),
            Text(
              "Q: ${faq.question}",
              style: TextStyle(
                color: Palette.black,
                fontFamily: "NotoSansKR",
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
            Text(
              "A: $preview",
              style: TextStyle(
                color: Palette.grey700,
                fontFamily: "NotoSansKR",
                fontSize: 12,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

// Widget menuListTile(String menu) {
//   return ListTile(
//     leading: Icon(Icons.event_note),
//     title: Text(menu),
//     trailing: Icon(
//       Icons.info_outline,
//       color: Palette.white,
//       size: 20,
//     ),
//     tileColor: Palette.accent,
//   );
// }

// Widget mobileMenuList() {
//   return Column(
//     children: [
//       menuListTile("About Gi어학원"),
//       menuListTile("Program"),
//       menuListTile("Curriculum"),
//       menuListTile("Community"),
//     ],
//   );
// }
}
