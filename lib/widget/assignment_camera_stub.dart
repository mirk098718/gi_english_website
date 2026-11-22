import 'package:flutter/widgets.dart';
import 'package:gi_english_website/widget/assignment_camera_result.dart';

export 'package:gi_english_website/widget/assignment_camera_result.dart';

Future<CameraShot> captureFromDeviceCamera(BuildContext context) async {
  return const CameraShot(error: '카메라를 열지 못했습니다. 브라우저에서 카메라 권한을 허용해 주세요.');
}
