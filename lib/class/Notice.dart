import 'package:cloud_firestore/cloud_firestore.dart';

class Notice {
  String? id;
  String title;
  String content;
  String author;
  DateTime createdAt;
  DateTime? updatedAt;
  bool isImportant;
  List<String> imageUrls;

  Notice({
    this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.createdAt,
    this.updatedAt,
    this.isImportant = false,
    this.imageUrls = const [],
  });

  factory Notice.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Notice.fromMap(doc.id, data);
  }

  factory Notice.fromMap(String? id, Map<String, dynamic> data) {
    return Notice(
      id: id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      author: data['author'] ?? '',
      createdAt: _requireDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
      isImportant: data['isImportant'] ?? false,
      imageUrls: imageUrlsFrom(data['imageUrls']),
    );
  }

  static List<String> imageUrlsFrom(dynamic value) {
    if (value is! List) return <String>[];
    final urls = <String>[];
    for (final item in value) {
      final url = item?.toString().trim() ?? '';
      if (url.isNotEmpty) urls.add(url);
    }
    return urls;
  }

  static DateTime _requireDate(dynamic value) {
    final date = _readDate(value);
    if (date == null) {
      throw StateError('날짜 값이 없습니다.');
    }
    return date;
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'author': author,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isImportant': isImportant,
      'imageUrls': imageUrls,
    };
  }

  Notice copyWith({
    String? id,
    String? title,
    String? content,
    String? author,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isImportant,
    List<String>? imageUrls,
  }) {
    return Notice(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isImportant: isImportant ?? this.isImportant,
      imageUrls: imageUrls ?? this.imageUrls,
    );
  }
}
