import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

// ignore: deprecated_member_use
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:gi_english_website/util/Palette.dart';

class TeacherPhotoCropDialog extends StatefulWidget {
  final Uint8List bytes;

  const TeacherPhotoCropDialog({Key? key, required this.bytes})
      : super(key: key);

  static Future<Uint8List?> show(BuildContext context, Uint8List bytes) {
    return showDialog<Uint8List>(
      context: context,
      barrierDismissible: false,
      builder: (_) => TeacherPhotoCropDialog(bytes: bytes),
    );
  }

  @override
  State<TeacherPhotoCropDialog> createState() => _TeacherPhotoCropDialogState();
}

class _TeacherPhotoCropDialogState extends State<TeacherPhotoCropDialog> {
  static const double _frame = 280;
  double _imgW = 0;
  double _imgH = 0;
  double _containScale = 1;
  double _userZoom = 1;
  Offset _offset = Offset.zero;
  bool _ready = false;
  bool _saving = false;
  String? _loadError;
  String? _saveError;

  double get _scale => _containScale * _userZoom;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    try {
      final loaded = await _HtmlImage.load(widget.bytes);
      loaded.dispose();
      if (!mounted) return;
      if (loaded.width <= 0 || loaded.height <= 0) {
        setState(() => _loadError = '사진을 읽지 못했습니다. JPG 또는 PNG로 올려 주세요.');
        return;
      }
      setState(() {
        _imgW = loaded.width;
        _imgH = loaded.height;
        _resetContain();
        _ready = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadError = '사진을 읽지 못했습니다. JPG 또는 PNG로 올려 주세요.');
    }
  }

  void _resetContain() {
    _containScale = math.min(_frame / _imgW, _frame / _imgH);
    _userZoom = 1;
    _offset = Offset(
      (_frame - _imgW * _scale) / 2,
      (_frame - _imgH * _scale) / 2,
    );
  }

  void _setZoom(double zoom) {
    final focal = Offset(_frame / 2, _frame / 2);
    final imagePoint = Offset(
      (focal.dx - _offset.dx) / _scale,
      (focal.dy - _offset.dy) / _scale,
    );
    _userZoom = zoom.clamp(1.0, 5.0);
    _offset = Offset(
      focal.dx - imagePoint.dx * _scale,
      focal.dy - imagePoint.dy * _scale,
    );
  }

  Future<void> _confirm() async {
    if (_saving || !_ready) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    late final Uint8List cropped;
    try {
      cropped = await _exportJpeg();
      if (cropped.isEmpty) throw Exception('empty jpeg');
    } catch (e) {
      print('강사 사진 자르기 실패: $e');
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = '사진을 자르지 못했습니다. 위치를 다시 맞춘 뒤 시도해 주세요.';
      });
      return;
    }
    if (!mounted) return;
    FocusManager.instance.primaryFocus?.unfocus();
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    Navigator.of(context).pop(cropped);
  }

  Future<Uint8List> _exportJpeg() async {
    final loaded = await _HtmlImage.load(widget.bytes);
    try {
      const out = 400.0;
      final canvas = html.CanvasElement(width: out.toInt(), height: out.toInt());
      final ctx = canvas.context2D;
      ctx.imageSmoothingEnabled = true;
      ctx.fillStyle = '#ffffff';
      ctx.fillRect(0, 0, out, out);
      final viewScale = out / _frame;
      ctx.translate(_offset.dx * viewScale, _offset.dy * viewScale);
      ctx.scale(_scale * viewScale, _scale * viewScale);
      ctx.drawImage(loaded.element, 0, 0);
      final dataUrl = canvas.toDataUrl('image/jpeg', 0.88);
      final base64 = dataUrl.split(',').last;
      if (base64.isEmpty) throw Exception('empty jpeg');
      return base64Decode(base64);
    } finally {
      loaded.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Palette.white,
      surfaceTintColor: Palette.white,
      title: Text('사진 위치 조정', style: TextStyle(fontFamily: "Jalnan")),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '처음에는 사진 전체가 보입니다. 얼굴을 원 안으로 끌어오고, 슬라이더로 확대하세요.',
              style: TextStyle(
                fontFamily: "NotoSansKR",
                fontSize: 13,
                color: Palette.grey600,
                height: 1.45,
              ),
            ),
            SizedBox(height: 16),
            if (_loadError != null)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text(_loadError!,
                    style: TextStyle(
                        fontFamily: "NotoSansKR", color: Palette.danger)),
              )
            else if (!_ready)
              SizedBox(
                height: _frame,
                child: Center(child: CircularProgressIndicator()),
              )
            else
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (details) {
                  setState(() => _offset += details.delta);
                },
                child: SizedBox(
                  width: _frame,
                  height: _frame,
                  child: Stack(
                    children: [
                      Container(
                        width: _frame,
                        height: _frame,
                        color: Palette.grey100,
                      ),
                      ClipOval(
                        child: SizedBox(
                          width: _frame,
                          height: _frame,
                          child: Stack(
                            clipBehavior: Clip.hardEdge,
                            children: [
                              Positioned(
                                left: _offset.dx,
                                top: _offset.dy,
                                width: _imgW * _scale,
                                height: _imgH * _scale,
                                child: Image.memory(
                                  widget.bytes,
                                  fit: BoxFit.fill,
                                  gaplessPlayback: true,
                                  filterQuality: FilterQuality.high,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IgnorePointer(
                        child: Container(
                          width: _frame,
                          height: _frame,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Palette.darkTeal, width: 3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.zoom_out, size: 18, color: Palette.grey500),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      showValueIndicator: ShowValueIndicator.never,
                    ),
                    child: Slider(
                      value: _userZoom,
                      min: 1.0,
                      max: 5.0,
                      activeColor: Palette.darkTeal,
                      onChanged: !_ready
                          ? null
                          : (value) => setState(() => _setZoom(value)),
                    ),
                  ),
                ),
                Icon(Icons.zoom_in, size: 18, color: Palette.grey500),
              ],
            ),
            if (_saveError != null)
              Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  _saveError!,
                  style: TextStyle(
                      fontFamily: "NotoSansKR", color: Palette.danger),
                ),
              ),
            TextButton(
              onPressed: !_ready ? null : () => setState(_resetContain),
              child: Text('사진 전체 보기',
                  style: TextStyle(
                      fontFamily: "NotoSansKR", color: Palette.darkTeal)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text('취소', style: TextStyle(fontFamily: "NotoSansKR")),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Palette.secondaryDark,
            foregroundColor: Palette.white,
          ),
          onPressed: (_saving || !_ready) ? null : _confirm,
          child: _saving
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Palette.white),
                )
              : Text('이 구도로 사용', style: TextStyle(fontFamily: "Jalnan")),
        ),
      ],
    );
  }
}

class _HtmlImage {
  final html.ImageElement element;
  final String url;

  _HtmlImage(this.element, this.url);

  double get width => element.naturalWidth.toDouble();
  double get height => element.naturalHeight.toDouble();

  static Future<_HtmlImage> load(Uint8List bytes) async {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrl(blob);
    final img = html.ImageElement();
    img.src = url;
    try {
      if (img.complete != true || img.naturalWidth == 0) {
        await Future.any([
          img.onLoad.first,
          img.onError.first.then((_) => throw Exception('image load error')),
        ]).timeout(const Duration(seconds: 8));
      }
      if (img.naturalWidth <= 0 || img.naturalHeight <= 0) {
        throw Exception('invalid image size');
      }
      return _HtmlImage(img, url);
    } catch (e) {
      html.Url.revokeObjectUrl(url);
      rethrow;
    }
  }

  void dispose() {
    html.Url.revokeObjectUrl(url);
  }
}
