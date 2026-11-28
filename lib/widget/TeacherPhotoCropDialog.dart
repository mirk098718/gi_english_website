import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

// ignore: deprecated_member_use
import 'package:gi_english_website/util/html_stub.dart'
    if (dart.library.html) 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:gi_english_website/util/AppLanguage.dart';
import 'package:gi_english_website/util/Palette.dart';

class TeacherPhotoCropDialog extends StatefulWidget {
  final Uint8List bytes;

  const TeacherPhotoCropDialog({Key? key, required this.bytes})
      : super(key: key);

  static Future<Uint8List?> show(BuildContext context, Uint8List bytes) {
    // 강사 등록/수정 다이얼로그 위에서 열리므로 rootNavigator를 쓴다.
    // 안 쓰면 웹에서 슬라이더 포인터가 아래 다이얼로그에 먹히는 경우가 있다.
    return showDialog<Uint8List>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (_) => TeacherPhotoCropDialog(bytes: bytes),
    );
  }

  @override
  State<TeacherPhotoCropDialog> createState() => _TeacherPhotoCropDialogState();
}

class _TeacherPhotoCropDialogState extends State<TeacherPhotoCropDialog> {
  static const double _frame = 280;
  static const double _minZoom = 1.0;
  static const double _maxZoom = 5.0;
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
      final size = await _decodeSize(widget.bytes);
      if (!mounted) return;
      if (size.width <= 0 || size.height <= 0) {
        setState(() =>
            _loadError = tr(context, '사진을 읽지 못했습니다. JPG 또는 PNG로 올려 주세요.'));
        return;
      }
      setState(() {
        _imgW = size.width;
        _imgH = size.height;
        _resetContain();
        _ready = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() =>
          _loadError = tr(context, '사진을 읽지 못했습니다. JPG 또는 PNG로 올려 주세요.'));
    }
  }

  Future<Size> _decodeSize(Uint8List bytes) async {
    if (kIsWeb) {
      final loaded = await _HtmlImage.load(bytes);
      final size = Size(loaded.width, loaded.height);
      loaded.dispose();
      return size;
    }
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final size = Size(
      frame.image.width.toDouble(),
      frame.image.height.toDouble(),
    );
    frame.image.dispose();
    codec.dispose();
    return size;
  }

  void _resetContain() {
    _containScale = math.min(_frame / _imgW, _frame / _imgH);
    _userZoom = _minZoom;
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
    _userZoom = zoom.clamp(_minZoom, _maxZoom);
    _offset = Offset(
      focal.dx - imagePoint.dx * _scale,
      focal.dy - imagePoint.dy * _scale,
    );
  }

  void _nudgeZoom(double delta) {
    setState(() => _setZoom(_userZoom + delta));
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
      print(tf(context, '강사 사진 자르기 실패: {p0}', {'p0': e}));
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError =
            tr(context, '사진을 자르지 못했습니다. 위치를 다시 맞춘 뒤 시도해 주세요.');
      });
      return;
    }
    if (!mounted) return;
    FocusManager.instance.primaryFocus?.unfocus();
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(cropped);
  }

  Future<Uint8List> _exportJpeg() async {
    if (!kIsWeb) return _exportPng();
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

  Future<Uint8List> _exportPng() async {
    const out = 400;
    final codec = await ui.instantiateImageCodec(widget.bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, out.toDouble(), out.toDouble()),
      Paint()..color = const Color(0xFFFFFFFF),
    );
    final viewScale = out / _frame;
    canvas.save();
    canvas.translate(_offset.dx * viewScale, _offset.dy * viewScale);
    canvas.scale(_scale * viewScale, _scale * viewScale);
    canvas.drawImage(
      image,
      Offset.zero,
      Paint()..filterQuality = FilterQuality.high,
    );
    canvas.restore();
    final rendered = await recorder.endRecording().toImage(out, out);
    final data = await rendered.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    rendered.dispose();
    codec.dispose();
    if (data == null || data.lengthInBytes == 0) {
      throw Exception('empty image');
    }
    return data.buffer.asUint8List();
  }

  Widget _preview() {
    return Listener(
      onPointerSignal: (event) {
        if (!_ready || event is! PointerScrollEvent) return;
        final next = _userZoom - event.scrollDelta.dy * 0.005;
        setState(() => _setZoom(next));
      },
      child: GestureDetector(
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
                          key: ValueKey(
                            'crop-${_userZoom.toStringAsFixed(3)}-'
                            '${_offset.dx.toStringAsFixed(1)}-'
                            '${_offset.dy.toStringAsFixed(1)}',
                          ),
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
                    border: Border.all(color: Palette.darkTeal, width: 3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _zoomControls() {
    return Material(
      type: MaterialType.transparency,
      child: Row(
        children: [
          IconButton(
            tooltip: tr(context, '축소'),
            onPressed: !_ready ? null : () => _nudgeZoom(-0.25),
            icon: Icon(Icons.zoom_out, color: Palette.grey600),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
                showValueIndicator: ShowValueIndicator.never,
              ),
              child: Slider(
                value: _userZoom.clamp(_minZoom, _maxZoom),
                min: _minZoom,
                max: _maxZoom,
                divisions: 40,
                activeColor: Palette.darkTeal,
                inactiveColor: Palette.grey300,
                onChanged: !_ready
                    ? null
                    : (value) {
                        setState(() => _setZoom(value));
                      },
              ),
            ),
          ),
          IconButton(
            tooltip: tr(context, '확대'),
            onPressed: !_ready ? null : () => _nudgeZoom(0.25),
            icon: Icon(Icons.zoom_in, color: Palette.grey600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Palette.white,
      surfaceTintColor: Palette.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  tr(context, "사진 위치 조정"),
                  style: TextStyle(fontFamily: "Jalnan", fontSize: 18),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                tr(context, "처음에는 사진 전체가 보입니다. 얼굴을 원 안으로 끌어오고, 슬라이더로 확대하세요."),
                style: TextStyle(
                  fontFamily: "NotoSansKR",
                  fontSize: 13,
                  color: Palette.grey600,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              if (_loadError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    _loadError!,
                    style: TextStyle(
                        fontFamily: "NotoSansKR", color: Palette.danger),
                  ),
                )
              else if (!_ready)
                SizedBox(
                  height: _frame,
                  child: const Center(child: CircularProgressIndicator()),
                )
              else
                _preview(),
              const SizedBox(height: 4),
              _zoomControls(),
              if (_saveError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _saveError!,
                    style: TextStyle(
                        fontFamily: "NotoSansKR", color: Palette.danger),
                  ),
                ),
              TextButton(
                onPressed: !_ready ? null : () => setState(_resetContain),
                child: Text(
                  tr(context, "사진 전체 보기"),
                  style: TextStyle(
                      fontFamily: "NotoSansKR", color: Palette.darkTeal),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context, rootNavigator: true).pop(),
                    child: Text(tr(context, "취소"),
                        style: TextStyle(fontFamily: "NotoSansKR")),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Palette.secondaryDark,
                      foregroundColor: Palette.white,
                    ),
                    onPressed: (_saving || !_ready) ? null : _confirm,
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Palette.white),
                          )
                        : Text(tr(context, "이 구도로 사용"),
                            style: TextStyle(fontFamily: "Jalnan")),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
