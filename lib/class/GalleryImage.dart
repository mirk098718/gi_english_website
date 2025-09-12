import 'package:cloud_firestore/cloud_firestore.dart';

class GalleryImage {
  final String id;
  final String imageData; // Base64 인코딩된 이미지 데이터
  final String description;
  final DateTime uploadedAt;
  final String fileName;
  final int imageSize;
  final String mimeType;

  GalleryImage({
    required this.id,
    required this.imageData,
    required this.description,
    required this.uploadedAt,
    required this.fileName,
    required this.imageSize,
    required this.mimeType,
  });

  // Firestore에 저장할 Map으로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'imageData': imageData,
      'description': description,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'fileName': fileName,
      'imageSize': imageSize,
      'mimeType': mimeType,
    };
  }

  // Firestore 문서에서 GalleryImage 객체 생성
  factory GalleryImage.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return GalleryImage(
      id: data['id'] ?? doc.id,
      imageData: data['imageData'] ?? '',
      description: data['description'] ?? '',
      uploadedAt:
          (data['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fileName: data['fileName'] ?? '',
      imageSize: data['imageSize'] ?? 0,
      mimeType: data['mimeType'] ?? 'image/jpeg',
    );
  }

  // Base64 데이터를 Data URL로 변환 (이미지 표시용)
  String get dataUrl {
    return 'data:$mimeType;base64,$imageData';
  }

  @override
  String toString() {
    return 'GalleryImage(id: $id, fileName: $fileName, description: $description, uploadedAt: $uploadedAt)';
  }
}
