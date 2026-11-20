/// 공지 첨부 이미지의 형식, 크기, 저장 경로.
class NoticeImages {
  static const int maxBytes = 20 * 1024 * 1024;
  static const int maxStoredBytes = 500 * 1024;
  static const int maxCount = 10;
  static const String imageRefPrefix = 'notice-image:';
  static const List<String> extensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];

  static String extensionOf(String fileName) {
    final name = fileName.trim().toLowerCase();
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return '';
    return name.substring(dot + 1);
  }

  /// 올릴 수 없으면 사용자에게 보여줄 이유를 반환한다.
  static String? rejectionReason({
    required String fileName,
    required int byteLength,
  }) {
    final ext = extensionOf(fileName);
    if (!extensions.contains(ext)) {
      return 'jpg, png, gif, webp 이미지만 첨부할 수 있습니다.';
    }
    if (byteLength <= 0) {
      return '이미지 파일이 비어 있습니다.';
    }
    if (byteLength > maxBytes) {
      return '사진이 너무 큽니다. 20MB 이하 파일로 올려 주세요.';
    }
    return null;
  }

  static String contentTypeOf(String fileName) {
    switch (extensionOf(fileName)) {
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  static String storagePath(String fileName, String unique) {
    final ext = extensionOf(fileName);
    final safe = unique.replaceAll(RegExp(r'[^0-9A-Za-z_-]'), '');
    return 'notices/images/$safe.$ext';
  }

  static bool isStorageUrl(String url) {
    final trimmed = url.trim();
    return trimmed.contains('firebasestorage.googleapis.com') ||
        trimmed.contains('.firebasestorage.app');
  }

  static String refFor(String id) => '$imageRefPrefix$id';

  static String? idFromRef(String ref) {
    final trimmed = ref.trim();
    if (!trimmed.startsWith(imageRefPrefix)) return null;
    final id = trimmed.substring(imageRefPrefix.length).trim();
    if (id.isEmpty) return null;
    return id;
  }

  static bool isNetworkUrl(String ref) {
    final trimmed = ref.trim();
    return trimmed.startsWith('https://') || trimmed.startsWith('http://');
  }
}
