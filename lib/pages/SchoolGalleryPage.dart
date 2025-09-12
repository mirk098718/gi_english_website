import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gi_english_website/pages/SchoolConsultationPage.dart';
import 'package:gi_english_website/pages/SchoolCommunityNoticePage.dart';
import 'package:gi_english_website/pages/SchoolCommunityBoardPage.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/GalleryService.dart';
import 'package:gi_english_website/widget/ButtonState.dart';
import 'package:gi_english_website/widget/MobileSchoolLayout.dart';
import 'package:gi_english_website/widget/WebSchoolLayout.dart';
import 'package:gi_english_website/widget/ImageViewer.dart';
import 'package:gi_english_website/widget/AdminImageUploadDialog.dart';
import 'package:gi_english_website/widget/AdminImageEditDialog.dart';
import 'package:gi_english_website/class/GalleryImage.dart';

import '../util/WidgetUtil.dart';

class SchoolGalleryPage extends StatefulWidget {
  const SchoolGalleryPage({Key? key}) : super(key: key);

  @override
  _SchoolGalleryPageState createState() => _SchoolGalleryPageState();
}

class _SchoolGalleryPageState extends State<SchoolGalleryPage> {
  List<ButtonState> buttonStateList = [
    ButtonState("Notice Board", BehaviorColor.colorOnDefault,
        SchoolCommunityNoticePage()),
    ButtonState(
        "FAQ", BehaviorColor.colorOnDefault, SchoolCommunityBoardPage()),
    ButtonState("Gallery", BehaviorColor.colorOnClick, SchoolGalleryPage()),
    ButtonState("입학상담", BehaviorColor.colorOnDefault, SchoolConsultationPage()),
  ];

  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    bool adminStatus = await AuthService.isAdmin();
    print('🔧 갤러리 페이지 - 관리자 권한: $adminStatus');
    setState(() {
      isAdmin = adminStatus;
    });
  }

  Future<void> _showUploadDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AdminImageUploadDialog(),
    );

    if (result == true) {
      // 업로드 성공시 필요한 경우 UI 새로고침
      setState(() {});
    }
  }

  Future<void> _showEditDialog(GalleryImage image) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AdminImageEditDialog(image: image),
    );

    if (result == true) {
      // 수정/삭제 성공시 필요한 경우 UI 새로고침
      setState(() {});
    }
  }

  void _openImageViewer(List<GalleryImage> images, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImageViewer(
          images: images,
          initialIndex: initialIndex,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    MediaQueryData mediaQueryData = MediaQuery.of(context);
    Size size = mediaQueryData.size;
    double width = size.width;
    if (width > 768) {
      return desktopUi(context);
    } else {
      return mobileUi(context);
    }
  }

  Widget desktopUi(context) {
    return WebSchoolLayout(content: scrollView());
  }

  Widget mobileUi(context) {
    return MobileSchoolLayout(content: mobileScrollView());
  }

  Widget contentGroup() {
    return Container(
        color: Palette.white,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 232, child: leftAboutMenu()),
            Expanded(child: content()),
          ],
        ));
  }

  Widget leftAboutMenu() {
    List<Widget> children = [];
    for (int i = 0; i < buttonStateList.length; i++) {
      ButtonState buttonState = buttonStateList[i];

      bool isFirst = (i == 0);
      bool isLast = (i == buttonStateList.length - 1);

      Widget child;
      if (isFirst) {
        child = MyWidget.leftMenuTop(buttonState.color, buttonState.label);
      } else if (isLast) {
        //last
        child = MyWidget.leftMenuBottom(buttonState.color, buttonState.label);
      } else {
        child = MyWidget.leftMenuMiddle(buttonState.color, buttonState.label);
      }

      children.add(InkWell(
        child: child,
        onHover: (value) {
          buttonState.color = value
              ? BehaviorColor.colorOnHover
              : (i == 2
                  ? BehaviorColor.colorOnClick
                  : BehaviorColor.colorOnDefault);
          setState(() {});
        },
        onTap: () {
          MenuUtil.push(context, buttonState.nextPage);
        },
      ));

      if (!isLast) {
        children.add(Divider(height: 1));
      }
    }

    return Container(
      padding: EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            width: 1,
            color: Palette.black,
          ),
        ),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget content() {
    return Container(
      padding: EdgeInsets.all(20),
      color: Palette.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목과 업로드 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Gallery",
                style: TextStyle(fontFamily: "Jalnan", fontSize: 20),
              ),
              if (isAdmin)
                ElevatedButton.icon(
                  onPressed: _showUploadDialog,
                  icon: Icon(Icons.cloud_upload, size: 18),
                  label: Text(
                    "이미지 업로드",
                    style: TextStyle(
                      fontFamily: "NotoSansKR",
                      fontSize: 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Palette.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
            ],
          ),
          WidgetUtil.myDivider(),
          SizedBox(height: 30),

          // 갤러리 이미지 그리드
          StreamBuilder<List<GalleryImage>>(
            stream: GalleryService.getImagesStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Palette.primary),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    '갤러리를 불러오는 중 오류가 발생했습니다.',
                    style: TextStyle(fontFamily: "NotoSansKR"),
                  ),
                );
              }

              List<GalleryImage> images = snapshot.data ?? [];

              if (images.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 64,
                        color: Palette.grey400,
                      ),
                      SizedBox(height: 16),
                      Text(
                        '아직 업로드된 이미지가 없습니다.',
                        style: TextStyle(
                          fontFamily: "NotoSansKR",
                          fontSize: 16,
                          color: Palette.grey600,
                        ),
                      ),
                      if (isAdmin) ...[
                        SizedBox(height: 8),
                        Text(
                          '상단의 "이미지 업로드" 버튼을 클릭하여 이미지를 추가해보세요.',
                          style: TextStyle(
                            fontFamily: "NotoSansKR",
                            fontSize: 14,
                            color: Palette.grey500,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                      MediaQuery.of(context).size.width > 1200 ? 4 : 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1,
                ),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  GalleryImage image = images[index];
                  return _buildImageCard(image, images, index);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard(
      GalleryImage image, List<GalleryImage> allImages, int index) {
    return InkWell(
      onTap: () => _openImageViewer(allImages, index),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 이미지
              Hero(
                tag: image.id,
                child: Image.memory(
                  base64Decode(image.imageData),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Palette.grey200,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image,
                              color: Palette.grey400, size: 32),
                          SizedBox(height: 8),
                          Text(
                            '이미지를 불러올 수 없습니다',
                            style: TextStyle(
                              color: Palette.grey600,
                              fontSize: 12,
                              fontFamily: "NotoSansKR",
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // 호버 오버레이
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openImageViewer(allImages, index),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: [0.6, 1.0],
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (image.description.isNotEmpty)
                            Text(
                              image.description,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontFamily: "NotoSansKR",
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 확대 아이콘
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.zoom_in,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),

              // 관리자용 수정/삭제 버튼
              if (isAdmin)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: InkWell(
                          onTap: () => _showEditDialog(image),
                          child: Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget mobileContent() {
    return Container(
      padding: EdgeInsets.all(20),
      color: Palette.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목과 업로드 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Gallery",
                style: TextStyle(fontFamily: "Jalnan", fontSize: 20),
              ),
              if (isAdmin)
                ElevatedButton.icon(
                  onPressed: _showUploadDialog,
                  icon: Icon(Icons.cloud_upload, size: 16),
                  label: Text(
                    "업로드",
                    style: TextStyle(
                      fontFamily: "NotoSansKR",
                      fontSize: 12,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Palette.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
            ],
          ),
          WidgetUtil.myDivider(),
          SizedBox(height: 20),

          // 모바일 갤러리 그리드
          StreamBuilder<List<GalleryImage>>(
            stream: GalleryService.getImagesStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Palette.primary),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    '갤러리를 불러오는 중 오류가 발생했습니다.',
                    style: TextStyle(fontFamily: "NotoSansKR"),
                  ),
                );
              }

              List<GalleryImage> images = snapshot.data ?? [];

              if (images.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 48,
                        color: Palette.grey400,
                      ),
                      SizedBox(height: 12),
                      Text(
                        '아직 업로드된 이미지가 없습니다.',
                        style: TextStyle(
                          fontFamily: "NotoSansKR",
                          fontSize: 14,
                          color: Palette.grey600,
                        ),
                      ),
                      if (isAdmin) ...[
                        SizedBox(height: 6),
                        Text(
                          '"업로드" 버튼을 눌러 이미지를 추가해보세요.',
                          style: TextStyle(
                            fontFamily: "NotoSansKR",
                            fontSize: 12,
                            color: Palette.grey500,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  GalleryImage image = images[index];
                  return _buildMobileImageCard(image, images, index);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMobileImageCard(
      GalleryImage image, List<GalleryImage> allImages, int index) {
    return InkWell(
      onTap: () => _openImageViewer(allImages, index),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Hero(
                tag: image.id,
                child: Image.memory(
                  base64Decode(image.imageData),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Palette.grey200,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image,
                              color: Palette.grey400, size: 24),
                          SizedBox(height: 4),
                          Text(
                            '이미지 오류',
                            style: TextStyle(
                              color: Palette.grey600,
                              fontSize: 10,
                              fontFamily: "NotoSansKR",
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // 확대 아이콘
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Icon(
                    Icons.zoom_in,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),

              // 관리자용 수정 버튼
              if (isAdmin)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: InkWell(
                      onTap: () => _showEditDialog(image),
                      child: Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget scrollView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          mainImage(),
          contentGroup(),
          SizedBox(height: 213, child: MyWidget.footer()),
        ],
      ),
    );
  }

  Widget mainImage() {
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
                  "Community",
                  style: TextStyle(
                      color: Palette.white,
                      fontSize: 30,
                      fontFamily: "LucidaCalligraphy"),
                ),
                SizedBox(
                  height: 20,
                ),
                Container(
                  width: 150,
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Palette.black,
                      backgroundColor: Palette.black,
                    ),
                    onPressed: () {
                      MenuUtil.push(context, SchoolConsultationPage());
                    },
                    child: Text("상담신청",
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

  //mobile

  Widget mobileScrollView() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              // mobileMainImage(),
              mobileLeftMenu(),
              mobileContent(),
              SizedBox(height: 100), // 여백 추가
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 51,
        child: MyWidget.mobileSchoolFooter(),
      ),
    );
  }

  Widget mobileLeftMenu() {
    List<Widget> children = [];
    for (int i = 0; i < buttonStateList.length; i++) {
      ButtonState buttonState = buttonStateList[i];

      bool isFirst = (i == 0);
      bool isLast = (i == buttonStateList.length - 1);

      Widget child;
      if (isFirst) {
        child =
            MyWidget.mobileLeftMenuStart(buttonState.color, buttonState.label);
      } else if (isLast) {
        //last
        child =
            MyWidget.mobileLeftMenuEnd(buttonState.color, buttonState.label);
      } else {
        child =
            MyWidget.mobileLeftMenuMiddle(buttonState.color, buttonState.label);
      }

      children.add(InkWell(
        child: child,
        onHover: (value) {
          buttonState.color = value
              ? BehaviorColor.colorOnHover
              : (i == 2
                  ? BehaviorColor.colorOnClick
                  : BehaviorColor.colorOnDefault);
          setState(() {});
        },
        onTap: () {
          MenuUtil.push(context, buttonState.nextPage);
        },
      ));

      if (!isLast) {
        children.add(Container(
          width: 1,
          height: 40,
          color: Palette.primaryLight,
        ));
      }
    }

    return Container(
      alignment: Alignment.center,
      width: MediaQuery.of(context).size.width,
      color: Palette.white,
      padding: EdgeInsets.all(20),
      child: Container(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: children,
          ),
        ),
      ),
    );
  }

  Widget mobileMainImage() {
    return Container(
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Image.asset("assets/communityMainImage.png"),
          Container(
            padding: EdgeInsets.only(left: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Community",
                  style: TextStyle(
                      color: Palette.white,
                      fontSize: 20,
                      fontFamily: "LucidaCalligraphy"),
                ),
                SizedBox(
                  height: 10,
                ),
                Container(
                  width: 150,
                  height: 40,
                  child: ElevatedButton(
                    child: Text(
                      "상담신청",
                      style:
                          TextStyle(fontFamily: "Jalnan", color: Palette.white),
                    ),
                    onPressed: () {
                      MenuUtil.push(context, SchoolConsultationPage());
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Palette.black,
                      backgroundColor: Palette.accent,
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
