import 'dart:typed_data';

/// 기기 카메라로 찍은 한 장. 사용자가 닫으면 [bytes]와 [error]가 모두 비어 있다.
class CameraShot {
  final Uint8List? bytes;
  final String? error;

  const CameraShot({this.bytes, this.error});
}
