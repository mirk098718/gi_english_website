import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';
import 'package:gi_english_website/util/AppLanguage.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/widget/assignment_camera_result.dart';

export 'package:gi_english_website/widget/assignment_camera_result.dart';

/// 파일 선택창 없이 브라우저 카메라를 바로 연다.
Future<CameraShot> captureFromDeviceCamera(BuildContext context) async {
  html.MediaStream? stream;
  try {
    stream = await _openCamera();
  } catch (_) {
    return const CameraShot(
      error: '카메라를 열지 못했습니다. 브라우저에서 카메라 권한을 허용해 주세요.',
    );
  }

  final video = html.VideoElement()
    ..autoplay = true
    ..muted = true
    ..style.width = '100%'
    ..style.height = '100%'
    ..style.objectFit = 'cover'
    ..style.backgroundColor = '#111111';
  video.setAttribute('playsinline', 'true');
  video.srcObject = stream;

  try {
    await video.play();
  } catch (_) {
    _stop(stream);
    return const CameraShot(
      error: '카메라를 열지 못했습니다. 브라우저에서 카메라 권한을 허용해 주세요.',
    );
  }

  if (!context.mounted) {
    _stop(stream);
    return const CameraShot();
  }

  final viewType = 'assignment-camera-${DateTime.now().microsecondsSinceEpoch}';
  ui.platformViewRegistry.registerViewFactory(viewType, (int viewId) => video);

  final bytes = await showDialog<Uint8List>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _CameraDialog(
      viewType: viewType,
      onShoot: () => _frame(video),
    ),
  );
  _stop(stream);
  return CameraShot(bytes: bytes);
}

Future<html.MediaStream> _openCamera() async {
  final devices = html.window.navigator.mediaDevices;
  if (devices == null) {
    throw StateError('mediaDevices unavailable');
  }
  try {
    return await devices.getUserMedia({
      'audio': false,
      'video': {'facingMode': 'environment'},
    });
  } catch (_) {
    return devices.getUserMedia({
      'audio': false,
      'video': true,
    });
  }
}

void _stop(html.MediaStream stream) {
  for (final track in stream.getTracks()) {
    track.stop();
  }
}

Future<Uint8List?> _frame(html.VideoElement video) async {
  if (video.videoWidth == 0) {
    try {
      await video.onLoadedMetadata.first.timeout(const Duration(seconds: 2));
    } catch (_) {}
  }
  var width = video.videoWidth;
  var height = video.videoHeight;
  if (width <= 0 || height <= 0) return null;
  if (width > 1600) {
    height = (height * 1600 / width).round();
    width = 1600;
  }
  final canvas = html.CanvasElement(width: width, height: height);
  canvas.context2D.drawImageScaled(video, 0, 0, width, height);
  final blob = await canvas.toBlob('image/jpeg', 0.85);
  final reader = html.FileReader();
  final done = reader.onLoadEnd.first;
  reader.readAsArrayBuffer(blob);
  await done;
  final data = reader.result;
  if (data is Uint8List) return data;
  if (data is ByteBuffer) return data.asUint8List();
  return null;
}

class _CameraDialog extends StatelessWidget {
  final String viewType;
  final Future<Uint8List?> Function() onShoot;

  const _CameraDialog({
    required this.viewType,
    required this.onShoot,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Palette.white,
      surfaceTintColor: Palette.white,
      title: Text(tr(context, '사진 찍기'), style: TextStyle(fontFamily: 'Jalnan')),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 480,
                height: 360,
                child: HtmlElementView(viewType: viewType),
              ),
            ),
            SizedBox(height: 12),
            Text(
              tr(context, '카메라 화면이 보이면 찍기를 누르세요.'),
              style: TextStyle(
                fontFamily: 'NotoSansKR',
                fontSize: 13,
                color: Palette.grey600,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(tr(context, '닫기'), style: TextStyle(fontFamily: 'NotoSansKR')),
        ),
        ElevatedButton(
          onPressed: () async {
            final bytes = await onShoot();
            if (!context.mounted) return;
            Navigator.pop(context, bytes);
          },
          child: Text(tr(context, '찍기'), style: TextStyle(fontFamily: 'NotoSansKR')),
        ),
      ],
    );
  }
}
