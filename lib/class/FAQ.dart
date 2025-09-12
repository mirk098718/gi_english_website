import 'package:cloud_firestore/cloud_firestore.dart';

class FAQ {
  String id;
  String question;
  String answer;
  String category;
  DateTime createdAt;
  DateTime updatedAt;
  bool isImportant;

  FAQ({
    required this.id,
    required this.question,
    required this.answer,
    this.category = '일반',
    required this.createdAt,
    required this.updatedAt,
    this.isImportant = false,
  });

  // Firestore에 저장할 데이터로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'question': question,
      'answer': answer,
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isImportant': isImportant,
    };
  }

  // Firestore 데이터에서 FAQ 객체로 변환
  factory FAQ.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return FAQ(
      id: doc.id,
      question: data['question'] ?? '',
      answer: data['answer'] ?? '',
      category: data['category'] ?? '일반',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isImportant: data['isImportant'] ?? false,
    );
  }

  // 복사 생성자
  FAQ copyWith({
    String? id,
    String? question,
    String? answer,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isImportant,
  }) {
    return FAQ(
      id: id ?? this.id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isImportant: isImportant ?? this.isImportant,
    );
  }

  @override
  String toString() {
    return 'FAQ(id: $id, question: $question, category: $category, isImportant: $isImportant)';
  }
}


