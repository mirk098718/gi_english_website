import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:gi_english_website/util/Palette.dart';

/// 공지 본문 입력칸.
///
/// 페이지 스크롤이 휠을 가져가면 긴 글을 붙여넣어도 일부만 보이고,
/// 글자를 드래그해 고를 수도 없다. 칸 안에 더 보일 내용이 있을 때는
/// 이 칸이 휠을 가져가고, 글자 선택은 입력칸이 직접 처리한다.
class NoticeBodyField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final double height;

  const NoticeBodyField({
    Key? key,
    required this.controller,
    this.focusNode,
    this.hintText = '공지사항 내용을 입력하세요',
    this.height = 420,
  }) : super(key: key);

  @override
  State<NoticeBodyField> createState() => _NoticeBodyFieldState();
}

class _NoticeBodyFieldState extends State<NoticeBodyField> {
  final ScrollController _scrollController = ScrollController();
  late final FocusNode _focusNode;
  late final bool _ownsFocus;

  @override
  void initState() {
    super.initState();
    _ownsFocus = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    if (_ownsFocus) _focusNode.dispose();
    super.dispose();
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (!position.hasContentDimensions) return;
    if (event.scrollDelta.dy == 0) return;

    final next = (position.pixels + event.scrollDelta.dy).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (next == position.pixels) return;

    GestureBinding.instance.pointerSignalResolver.register(event, (signal) {
      if (!_scrollController.hasClients) return;
      final scroll = signal as PointerScrollEvent;
      final current = _scrollController.position;
      final target = (current.pixels + scroll.scrollDelta.dy).clamp(
        current.minScrollExtent,
        current.maxScrollExtent,
      );
      if (target != current.pixels) {
        _scrollController.jumpTo(target);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(8);
    return SizedBox(
      height: widget.height,
      child: Listener(
        onPointerSignal: _onPointerSignal,
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          interactive: true,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(
              context,
            ).copyWith(scrollbars: false),
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              scrollController: _scrollController,
              keyboardType: TextInputType.multiline,
              textAlignVertical: TextAlignVertical.top,
              textInputAction: TextInputAction.newline,
              expands: true,
              maxLines: null,
              enableInteractiveSelection: true,
              cursorColor: Palette.primary,
              style: const TextStyle(
                fontFamily: 'NotoSansKR',
                fontSize: 16,
                height: 1.55,
                color: Palette.black,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: const TextStyle(
                  fontFamily: 'NotoSansKR',
                  fontSize: 16,
                  color: Palette.grey400,
                ),
                filled: true,
                fillColor: Palette.white,
                contentPadding: const EdgeInsets.fromLTRB(16, 16, 28, 16),
                border: OutlineInputBorder(borderRadius: borderRadius),
                enabledBorder: OutlineInputBorder(
                  borderRadius: borderRadius,
                  borderSide: const BorderSide(color: Palette.grey300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: borderRadius,
                  borderSide: const BorderSide(
                    color: Palette.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
