import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
// ignore: deprecated_member_use
import 'dart:html' as html;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gi_english_website/class/GalleryImage.dart';
import 'package:gi_english_website/util/AuthService.dart';

class GalleryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'gallery_images';

  // 이미지 압축 함수 (웹용)
  static Future<Uint8List> _compressImage(
      Uint8List imageData, String fileName) async {
    print('🔄 이미지 압축 시작...');
    final originalSize = imageData.length;
    print('📏 원본 크기: ${(originalSize / 1024 / 1024).toStringAsFixed(2)} MB');

    // 이미지가 너무 크면 압축하지 않고 원본 사용
    if (originalSize > 5 * 1024 * 1024) {
      print('⚠️ 이미지가 너무 큽니다 (5MB 초과). 원본 사용');
      return imageData;
    }

    try {
      // 더 짧은 타임아웃 (3초)
      final compressedData = await _performImageCompression(imageData).timeout(
        Duration(seconds: 3),
        onTimeout: () {
          print('⏰ 압축 타임아웃, 원본 사용');
          return imageData;
        },
      );

      final compressedSize = compressedData.length;
      final compressionRatio =
          ((originalSize - compressedSize) / originalSize * 100);

      print('✅ 압축 완료');
      print(
          '📏 압축 후 크기: ${(compressedSize / 1024 / 1024).toStringAsFixed(2)} MB');
      print('📉 압축률: ${compressionRatio.toStringAsFixed(1)}%');

      return compressedData;
    } catch (e) {
      print('❌ 이미지 압축 실패: $e');
      print('📤 원본 이미지 사용');
      return imageData;
    }
  }

  // 실제 이미지 압축 수행 - 단순화된 버전
  static Future<Uint8List> _performImageCompression(Uint8List imageData) async {
    try {
      // Canvas를 사용한 이미지 리사이징
      final blob = html.Blob([imageData]);
      final url = html.Url.createObjectUrl(blob);

      try {
        final img = html.ImageElement();
        img.src = url;

        // 이미지 로드 대기 (타임아웃 2초로 단축)
        await img.onLoad.first.timeout(Duration(seconds: 2));

        final canvas = html.CanvasElement();
        final ctx = canvas.context2D;

        // 최대 크기 설정 (1280x1280으로 축소)
        const maxSize = 1280;
        double ratio = 1.0;

        if (img.width! > maxSize || img.height! > maxSize) {
          ratio =
              maxSize / (img.width! > img.height! ? img.width! : img.height!);
        }

        final newWidth = (img.width! * ratio).round();
        final newHeight = (img.height! * ratio).round();

        canvas.width = newWidth;
        canvas.height = newHeight;

        ctx.drawImageScaled(img, 0, 0, newWidth, newHeight);

        // JPEG로 압축 (품질 0.7로 낮춤)
        final dataUrl = canvas.toDataUrl('image/jpeg', 0.7);
        final base64 = dataUrl.split(',')[1];
        final compressedData = html.window.atob(base64);

        final result = Uint8List.fromList(compressedData.codeUnits);

        return result;
      } finally {
        html.Url.revokeObjectUrl(url);
      }
    } catch (e) {
      print('❌ 압축 과정에서 오류: $e');
      // 압축 실패 시 원본 반환
      return imageData;
    }
  }

  // 갤러리 이미지 추가 (Firestore 기반)
  static Future<void> addImage({
    required Uint8List imageData,
    required String fileName,
    required String description,
  }) async {
    try {
      print('🔧 GalleryService.addImage 시작 (Firestore 기반)');
      print('📁 파일명: $fileName');
      print(
          '📏 데이터 크기: ${(imageData.length / 1024 / 1024).toStringAsFixed(2)} MB');

      if (AuthService.currentUser == null || !await AuthService.isAdmin()) {
        throw Exception(
          '학원 갤러리 업로드는 메인 관리자 계정으로 로그인한 뒤에만 가능합니다. '
          '강사 계정으로는 사진을 올릴 수 없습니다.',
        );
      }

      // 이미지 크기 제한 (5MB - Firestore 문서 크기 제한 고려)
      if (imageData.length > 5 * 1024 * 1024) {
        throw Exception('이미지가 너무 큽니다. 5MB 이하의 이미지를 업로드해주세요.');
      }

      // 이미지 압축 (1MB 이상인 경우)
      Uint8List finalImageData = imageData;
      if (imageData.length > 1 * 1024 * 1024) {
        print('⚠️ 이미지가 1MB를 초과합니다. 압축을 시도합니다...');
        try {
          finalImageData = await _compressImage(imageData, fileName).timeout(
            Duration(seconds: 3),
            onTimeout: () {
              print('⏰ 압축 타임아웃, 원본 사용');
              return imageData;
            },
          );
        } catch (e) {
          print('❌ 압축 실패, 원본 사용: $e');
          finalImageData = imageData;
        }
      } else {
        print('✅ 이미지 크기가 적절합니다. 압축하지 않습니다.');
      }

      // Base64로 인코딩
      print('🔄 이미지를 Base64로 인코딩 중...');
      String base64Image = base64Encode(finalImageData);
      print('✅ Base64 인코딩 완료 (${base64Image.length} 문자)');

      // Firestore에 이미지 데이터 저장
      String imageId = DateTime.now().millisecondsSinceEpoch.toString();
      print('📋 Firestore에 이미지 데이터 저장 중...');

      Map<String, dynamic> imageDocData = {
        'id': imageId,
        'fileName': fileName,
        'description': description,
        'uploadedAt': Timestamp.fromDate(DateTime.now()),
        'imageData': base64Image, // Base64 인코딩된 이미지 데이터
        'imageSize': finalImageData.length,
        'mimeType': 'image/jpeg', // 압축된 이미지는 JPEG로 저장
      };

      await _firestore
          .collection(_collection)
          .doc(imageId)
          .set(imageDocData)
          .timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Firestore 저장 타임아웃', Duration(seconds: 30));
        },
      );

      print('✅ Firestore 저장 완료');
      print('🎉 갤러리 이미지 추가 성공! (Firestore 기반)');
    } catch (e) {
      print('❌ 갤러리 이미지 추가 오류: $e');
      print('🔍 오류 타입: ${e.runtimeType}');

      // 사용자 친화적인 에러 메시지
      if (e is TimeoutException) {
        throw Exception('업로드 시간이 초과되었습니다. 네트워크 연결을 확인해주세요.');
      } else if (e.toString().contains('permission')) {
        throw Exception(
          '업로드 권한이 없습니다. 메인 관리자(학원 운영자)로 다시 로그인해 주세요. '
          '강사 계정으로는 학원 갤러리에 사진을 올릴 수 없습니다.',
        );
      } else if (e.toString().contains('quota')) {
        throw Exception('저장 공간이 부족합니다. 관리자에게 문의해주세요.');
      } else {
        throw Exception('업로드 중 오류가 발생했습니다: ${e.toString()}');
      }
    }
  }

  // 갤러리 이미지 목록 실시간 스트림 (최신순) - Firestore 기반
  static Stream<List<GalleryImage>> getImagesStream() {
    print('🔄 GalleryService: 스트림 시작 (Firestore 기반)');

    return _firestore
        .collection(_collection)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      print('📊 GalleryService: 데이터 수신 - ${snapshot.docs.length}개 문서');

      List<GalleryImage> images = snapshot.docs
          .map((doc) {
            try {
              return GalleryImage.fromFirestore(doc);
            } catch (e) {
              print('❌ 갤러리 이미지 파싱 오류 (${doc.id}): $e');
              return null;
            }
          })
          .where((image) => image != null)
          .cast<GalleryImage>()
          .toList();

      print('✅ GalleryService: 파싱된 이미지 ${images.length}개');
      return images;
    });
  }

  // 이미지 삭제 (Firestore 기반)
  static Future<void> deleteImage(String imageId) async {
    try {
      print('🗑️ 갤러리 이미지 삭제 시작: $imageId');

      // Firestore에서 삭제
      await _firestore.collection(_collection).doc(imageId).delete();

      print('✅ 갤러리 이미지 삭제 완료');
    } catch (e) {
      print('❌ 갤러리 이미지 삭제 오류: $e');
      throw e;
    }
  }

  // 이미지 설명 업데이트
  static Future<void> updateImageDescription(
      String imageId, String newDescription) async {
    try {
      await _firestore.collection(_collection).doc(imageId).update({
        'description': newDescription,
      });
    } catch (e) {
      print('갤러리 이미지 설명 업데이트 오류: $e');
      throw e;
    }
  }

  // Firestore 연결 테스트 (간소화)
  static Future<bool> testFirestoreConnection() async {
    try {
      print('🔍 Firestore 연결 테스트 시작...');

      // 간단한 읽기 테스트
      await _firestore.collection(_collection).limit(1).get().timeout(
        Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Firestore 연결 타임아웃', Duration(seconds: 5));
        },
      );

      print('✅ Firestore 연결 성공!');
      return true;
    } catch (e) {
      print('❌ Firestore 연결 실패: $e');
      return false;
    }
  }
}
