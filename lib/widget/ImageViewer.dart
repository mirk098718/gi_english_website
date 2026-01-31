import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:gi_english_website/class/GalleryImage.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/widget/AdminImageEditDialog.dart';

class ImageViewer extends StatefulWidget {
  final List<GalleryImage> images;
  final int initialIndex;

  const ImageViewer({
    Key? key,
    required this.images,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  _ImageViewerState createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  late PageController pageController;
  late int currentIndex;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    pageController = PageController(initialPage: widget.initialIndex);
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    bool adminStatus = await AuthService.isAdmin();
    setState(() {
      isAdmin = adminStatus;
    });
  }

  Future<void> _showEditDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) =>
          AdminImageEditDialog(image: widget.images[currentIndex]),
    );

    if (result == true) {
      // 수정/삭제 성공시 이전 페이지로 돌아가기
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 이미지 갤러리
          PhotoViewGallery.builder(
            pageController: pageController,
            itemCount: widget.images.length,
            builder: (context, index) {
              return PhotoViewGalleryPageOptions(
                imageProvider:
                    MemoryImage(base64Decode(widget.images[index].imageData)),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
                heroAttributes: PhotoViewHeroAttributes(
                  tag: widget.images[index].id,
                ),
              );
            },
            scrollPhysics: const BouncingScrollPhysics(),
            backgroundDecoration: const BoxDecoration(
              color: Colors.black,
            ),
            onPageChanged: (index) {
              setState(() {
                currentIndex = index;
              });
            },
          ),

          // 상단 앱바
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha:0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.white, size: 30),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Text(
                      '${currentIndex + 1} / ${widget.images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    // 관리자용 수정 버튼
                    if (isAdmin)
                      IconButton(
                        icon: const Icon(Icons.edit,
                            color: Colors.white, size: 24),
                        onPressed: _showEditDialog,
                        tooltip: '이미지 수정/삭제',
                      )
                    else
                      const SizedBox(width: 48), // 균형을 위한 공간
                  ],
                ),
              ),
            ),
          ),

          // 하단 설명 텍스트
          if (widget.images[currentIndex].description.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha:0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.images[currentIndex].description,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: "NotoSansKR",
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.images[currentIndex].fileName,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha:0.7),
                          fontSize: 12,
                          fontFamily: "NotoSansKR",
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 좌측 네비게이션 화살표
          if (widget.images.length > 1 && currentIndex > 0)
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha:0.5),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.chevron_left,
                        color: Colors.white, size: 30),
                    onPressed: () {
                      if (currentIndex > 0) {
                        pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                  ),
                ),
              ),
            ),

          // 우측 네비게이션 화살표
          if (widget.images.length > 1 &&
              currentIndex < widget.images.length - 1)
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha:0.5),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.chevron_right,
                        color: Colors.white, size: 30),
                    onPressed: () {
                      if (currentIndex < widget.images.length - 1) {
                        pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
