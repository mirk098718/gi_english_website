import 'package:flutter/services.dart';
import 'package:gi_english_website/util/GalleryService.dart';

class InitializeGallery {
  static Future<void> addDefaultImages() async {
    print('🔄 기본 이미지 복구 시작...');

    // 기존 갤러리에서 사용하던 이미지들을 복구
    List<Map<String, String>> defaultImages = [
      {
        'path': 'assets/lobby1.jpeg',
        'description': '글림아일랜드 로비 1층 - 밝고 쾌적한 학습 환경',
        'fileName': 'lobby1.jpeg'
      },
      {
        'path': 'assets/lobby2.jpeg',
        'description': '로비 휴게 공간 - 학생들이 편안하게 쉴 수 있는 공간',
        'fileName': 'lobby2.jpeg'
      },
      {
        'path': 'assets/lobby.jpeg',
        'description': '메인 로비 - 깔끔하고 현대적인 인테리어',
        'fileName': 'lobby.jpeg'
      },
      {
        'path': 'assets/doors.jpeg',
        'description': '교실 입구 - 체계적으로 구성된 학습 공간',
        'fileName': 'doors.jpeg'
      },
      {
        'path': 'assets/classroom.jpeg',
        'description': '교실 내부 - 소수정예 수업을 위한 최적의 학습 환경',
        'fileName': 'classroom.jpeg'
      },
      {
        'path': 'assets/mainEnterance.jpeg',
        'description': '글림아일랜드 정문 - 따뜻한 느낌의 메인 입구',
        'fileName': 'mainEnterance.jpeg'
      },
      {
        'path': 'assets/gleamIslandLogo.jpeg',
        'description': '글림아일랜드 로고 - 브랜드 아이덴티티',
        'fileName': 'gleamIslandLogo.jpeg'
      },
      {
        'path': 'assets/car1.jpeg',
        'description': '글림아일랜드 셔틀버스 - 안전한 통학 서비스',
        'fileName': 'car1.jpeg'
      },
      {
        'path': 'assets/car2.jpeg',
        'description': '셔틀버스 내부 - 편안하고 안전한 통학 환경',
        'fileName': 'car2.jpeg'
      },
      {
        'path': 'assets/scienceday.jpeg',
        'description': '과학의 날 행사 - 체험형 학습 프로그램',
        'fileName': 'scienceday.jpeg'
      },
      {
        'path': 'assets/projectart.jpeg',
        'description': '프로젝트 아트 전시 - 학생들의 창작 활동 결과물',
        'fileName': 'projectart.jpeg'
      },
    ];

    int successCount = 0;
    int totalCount = defaultImages.length;

    try {
      for (int i = 0; i < defaultImages.length; i++) {
        Map<String, String> imageInfo = defaultImages[i];

        try {
          print('📤 [${i + 1}/$totalCount] ${imageInfo['fileName']} 업로드 중...');

          // assets에서 이미지 데이터 읽기
          ByteData byteData = await rootBundle.load(imageInfo['path']!);
          Uint8List imageData = byteData.buffer.asUint8List();

          // Firebase Storage에 업로드
          await GalleryService.addImage(
            imageData: imageData,
            fileName: imageInfo['fileName']!,
            description: imageInfo['description']!,
          );

          successCount++;
          print('✅ [${i + 1}/$totalCount] ${imageInfo['fileName']} 업로드 완료');

          // 업로드 간 딜레이 (Firebase Storage 부하 방지)
          await Future.delayed(Duration(milliseconds: 500));
        } catch (e) {
          print('❌ ${imageInfo['fileName']} 업로드 실패: $e');
          // 개별 이미지 실패해도 계속 진행
        }
      }

      print('🎉 기본 이미지 복구 완료! ($successCount/$totalCount 성공)');

      if (successCount < totalCount) {
        print('⚠️  일부 이미지 업로드에 실패했습니다. ($successCount/$totalCount)');
      }
    } catch (e) {
      print('❌ 기본 이미지 복구 중 전체 오류: $e');
      throw Exception('이미지 복구 실패: 총 $successCount개 성공');
    }
  }
}
