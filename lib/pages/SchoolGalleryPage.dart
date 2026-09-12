import 'dart:async';
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
import 'package:gi_english_website/widget/AcademyHeroBanner.dart';
import 'package:gi_english_website/widget/WebSchoolLayout.dart';
import 'package:gi_english_website/widget/ImageViewer.dart';
import 'package:gi_english_website/widget/AdminImageUploadDialog.dart';
import 'package:gi_english_website/widget/AdminImageEditDialog.dart';
import 'package:gi_english_website/class/GalleryImage.dart';

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
  ];

  bool isAdmin = false;
  StreamSubscription? _roleSub;

  @override
  void initState() {
    super.initState();
    _roleSub = AuthService.listenRole((role) {
      if (!mounted) return;
      setState(() {
        isAdmin = role == AdminRole.owner;
      });
    });
  }

  @override
  void dispose() {
    _roleSub?.cancel();
    super.dispose();
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      color: Palette.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _galleryHeader(compact: false),
          const SizedBox(height: 16),
          _galleryBody(compact: false),
        ],
      ),
    );
  }

  Widget mobileContent() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      color: Palette.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _galleryHeader(compact: true),
          const SizedBox(height: 14),
          _galleryBody(compact: true),
        ],
      ),
    );
  }

  Widget _galleryHeader({required bool compact}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 3, height: 16, color: Palette.navy),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '갤러리',
                style: TextStyle(
                  fontFamily: 'NotoSansKR',
                  fontWeight: FontWeight.w800,
                  fontSize: compact ? 18 : 20,
                  color: Palette.navy,
                ),
              ),
            ),
            if (isAdmin)
              TextButton.icon(
                onPressed: _showUploadDialog,
                icon: Icon(Icons.add, size: compact ? 16 : 18),
                label: Text(compact ? '업로드' : '사진 올리기'),
                style: TextButton.styleFrom(
                  foregroundColor: Palette.navy,
                  textStyle: TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 13 : 14,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(height: 1, color: Palette.grey200),
      ],
    );
  }

  Widget _galleryBody({required bool compact}) {
    return StreamBuilder<List<GalleryImage>>(
      stream: GalleryService.getImagesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Palette.darkTeal),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                '갤러리를 불러오는 중 오류가 발생했습니다.',
                style: TextStyle(fontFamily: 'NotoSansKR'),
              ),
            ),
          );
        }

        final images = snapshot.data ?? [];
        if (images.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.photo_library_outlined,
                      size: 40, color: Palette.grey400),
                  const SizedBox(height: 10),
                  Text(
                    '아직 올라온 사진이 없습니다.',
                    style: TextStyle(
                      fontFamily: 'NotoSansKR',
                      fontSize: 14,
                      color: Palette.grey600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return _galleryMasonry(images, compact: compact);
      },
    );
  }

  Widget _galleryMasonry(List<GalleryImage> images, {required bool compact}) {
    const ratios = [0.82, 1.12, 0.94, 1.05, 0.76, 1.0];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = compact
            ? 2
            : (constraints.maxWidth >= 980
                ? 4
                : constraints.maxWidth >= 680
                    ? 3
                    : 2);
        final gap = compact ? 6.0 : 8.0;
        final buckets = List.generate(columns, (_) => <int>[]);
        for (var i = 0; i < images.length; i++) {
          buckets[i % columns].add(i);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var c = 0; c < columns; c++) ...[
              if (c > 0) SizedBox(width: gap),
              Expanded(
                child: Column(
                  children: [
                    for (var j = 0; j < buckets[c].length; j++) ...[
                      if (j > 0) SizedBox(height: gap),
                      AspectRatio(
                        aspectRatio: ratios[buckets[c][j] % ratios.length],
                        child: _GalleryTile(
                          image: images[buckets[c][j]],
                          compact: compact,
                          onOpen: () =>
                              _openImageViewer(images, buckets[c][j]),
                          onEdit: isAdmin
                              ? () => _showEditDialog(images[buckets[c][j]])
                              : null,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget scrollView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          mainImage(),
          contentGroup(),
          MyWidget.footer(),
        ],
      ),
    );
  }

  Widget mainImage() {
    return Container(
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          AcademyHeroBanner.photo(AcademyHeroBanner.community),
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
    return SingleChildScrollView(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            mobileLeftMenu(),
            mobileContent(),
          ],
        ),
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
          color: Palette.grey300,
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
          AcademyHeroBanner.photo(AcademyHeroBanner.community),
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


class _GalleryTile extends StatefulWidget {
  final GalleryImage image;
  final bool compact;
  final VoidCallback onOpen;
  final VoidCallback? onEdit;

  const _GalleryTile({
    required this.image,
    required this.compact,
    required this.onOpen,
    this.onEdit,
  });

  @override
  State<_GalleryTile> createState() => _GalleryTileState();
}

class _GalleryTileState extends State<_GalleryTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final showCaption = widget.image.description.isNotEmpty &&
        (_hover || widget.compact);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onOpen,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Hero(
                tag: widget.image.id,
                child: Image.memory(
                  base64Decode(widget.image.imageData),
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) {
                    return ColoredBox(
                      color: Palette.grey200,
                      child: Icon(Icons.broken_image, color: Palette.grey400),
                    );
                  },
                ),
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 160),
                opacity: showCaption ? 1 : 0,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Color(0x99000000),
                      ],
                    ),
                  ),
                ),
              ),
              if (showCaption)
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 24, 10, 10),
                    child: Text(
                      widget.image.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'NotoSansKR',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              if (widget.onEdit != null && (_hover || widget.compact))
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: widget.onEdit,
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.edit, size: 14, color: Colors.white),
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
}
