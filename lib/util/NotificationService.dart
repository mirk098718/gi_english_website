import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gi_english_website/util/AuthService.dart';

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final String bookingId;
  final bool read;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.bookingId = '',
    this.read = false,
    required this.createdAt,
  });

  factory AppNotification.fromMap(String id, Map<String, dynamic> data) {
    return AppNotification(
      id: id,
      userId: data['userId']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      body: data['body']?.toString() ?? '',
      type: data['type']?.toString() ?? '',
      bookingId: data['bookingId']?.toString() ?? '',
      read: data['read'] == true,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      userId: userId,
      title: title,
      body: body,
      type: type,
      bookingId: bookingId,
      read: read ?? this.read,
      createdAt: createdAt,
    );
  }
}

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Stream<List<AppNotification>> watchMine({
    String? userId,
    int limit = 40,
  }) {
    final uid = userId ?? AuthService.currentUser?.uid ?? '';
    if (uid.isEmpty) return Stream.value(const []);
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => AppNotification.fromMap(doc.id, doc.data()))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  static Future<List<AppNotification>> listMine({int limit = 20}) async {
    final user = AuthService.currentUser;
    if (user == null) return [];
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .limit(limit)
          .get();
      final list = snapshot.docs
          .map((doc) => AppNotification.fromMap(doc.id, doc.data()))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      print('알림 조회 오류: $e');
      return [];
    }
  }

  static Future<bool> notifyUser({
    required String userId,
    required String title,
    required String body,
    required String type,
    String bookingId = '',
  }) async {
    if (userId.isEmpty) return false;
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'bookingId': bookingId,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('알림 생성 오류: $e');
      return false;
    }
  }

  static Future<void> markRead(String id) async {
    if (id.isEmpty) return;
    try {
      await _firestore.collection('notifications').doc(id).set(
        {'read': true, 'readAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    } catch (e) {
      print('알림 읽음 처리 오류: $e');
    }
  }
}
