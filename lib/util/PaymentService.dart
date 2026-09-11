import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:gi_english_website/class/OnlineCourse.dart';
import 'package:gi_english_website/class/OnlineNativeTeacher.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/EnrollmentService.dart';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:js' as js;

/// 토스페이먼츠 결제 + 수강 신청 서비스.
///
/// Firestore: payments/{orderId}
class PaymentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 토스 문서용 테스트 클라이언트 키.
  /// 실제 상점 키로 교체하려면 [TossConfig]를 수정하세요.
  static const String tossClientKey = 'test_ck_D5GePWvyJnrK0W0k6q8gLzN97Eoq';

  /// 결제 주문을 생성하고 orderId를 반환한다.
  static Future<PaymentOrder?> createOrder({
    required OnlineCourse course,
    OnlineNativeTeacher? nativeTeacher,
    int? totalSessions,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) return null;

    final sessions = totalSessions ?? course.defaultSessions;
    final orderId = _generateOrderId();
    final amount = course.price;
    var teacherUid = nativeTeacher?.accountUid ?? '';
    if (teacherUid.isEmpty && nativeTeacher != null) {
      teacherUid = await AuthService.uidForNativeProfile(nativeTeacher.id);
    }

    final order = PaymentOrder(
      orderId: orderId,
      userId: user.uid,
      email: user.email ?? '',
      memberName: user.displayName ?? '',
      courseId: course.id,
      courseTitle: course.title,
      amount: amount,
      totalSessions: sessions,
      status: 'pending',
      nativeTeacherId: nativeTeacher?.id ?? '',
      nativeTeacherName: nativeTeacher?.name ?? '',
      nativeTeacherUid: teacherUid,
    );

    await _firestore.collection('payments').doc(orderId).set({
      'orderId': orderId,
      'userId': order.userId,
      'email': order.email,
      'memberName': order.memberName,
      'courseId': order.courseId,
      'courseTitle': order.courseTitle,
      'amount': order.amount,
      'totalSessions': order.totalSessions,
      'status': 'pending',
      'nativeTeacherId': order.nativeTeacherId,
      'nativeTeacherName': order.nativeTeacherName,
      'nativeTeacherUid': order.nativeTeacherUid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return order;
  }

  /// 토스 결제창을 연다. (Flutter Web 전용)
  static Future<String?> requestTossPayment(PaymentOrder order) async {
    if (!kIsWeb) {
      return '결제는 웹에서만 지원됩니다.';
    }

    try {
      final origin = Uri.base.origin;
      final customerKey = 'member_${order.userId}'
          .replaceAll(RegExp(r'[^a-zA-Z0-9\-_=.]'), '_');

      // index.html 의 window.gleamTossPay 호출
      final promise = js.context.callMethod('gleamTossPay', [
        js.JsObject.jsify({
          'clientKey': tossClientKey,
          'customerKey': customerKey,
          'amount': order.amount,
          'orderId': order.orderId,
          'orderName': '${order.courseTitle} (${order.totalSessions}회)',
          'customerEmail': order.email,
          'customerName': order.memberName.isEmpty ? '온라인회원' : order.memberName,
          'successUrl': '$origin/payment/success',
          'failUrl': '$origin/payment/fail',
        }),
      ]);

      // JS Promise가 실패하면 메시지를 받을 수 있음
      if (promise != null) {
        // requestPayment는 보통 리다이렉트되므로 여기서 대기하지 않음
      }
      return null;
    } catch (e) {
      print('토스 결제창 호출 오류: $e');
      return '결제창을 열지 못했습니다. 페이지를 새로고침 후 다시 시도해주세요.';
    }
  }

  /// Cloud Function으로 결제 승인 + 수강 배정.
  static Future<String?> confirmPayment({
    required String paymentKey,
    required String orderId,
    required int amount,
  }) async {
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'asia-northeast3')
          .httpsCallable('confirmTossPayment');
      final result = await callable.call(<String, dynamic>{
        'paymentKey': paymentKey,
        'orderId': orderId,
        'amount': amount,
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      if (data['ok'] == true) return null;
      return data['message']?.toString() ?? '결제 승인에 실패했습니다.';
    } on FirebaseFunctionsException catch (e) {
      print('결제 승인 Functions 오류: ${e.code} ${e.message}');
      // Blaze 미전환 등으로 Functions가 없을 때: 인증 정보만 저장
      await _saveAuthorizedPending(
        orderId: orderId,
        paymentKey: paymentKey,
        amount: amount,
        reason: e.message ?? e.code,
      );
      return 'CLOUD_FUNCTIONS_UNAVAILABLE:${e.message ?? e.code}';
    } catch (e) {
      print('결제 승인 오류: $e');
      await _saveAuthorizedPending(
        orderId: orderId,
        paymentKey: paymentKey,
        amount: amount,
        reason: e.toString(),
      );
      return 'CLOUD_FUNCTIONS_UNAVAILABLE:$e';
    }
  }

  /// Functions 없이도 토스 인증 결과를 남겨 관리자가 확인할 수 있게 한다.
  static Future<void> _saveAuthorizedPending({
    required String orderId,
    required String paymentKey,
    required int amount,
    String reason = '',
  }) async {
    try {
      final ref = _firestore.collection('payments').doc(orderId);
      final snap = await ref.get();
      if (!snap.exists) return;
      final data = snap.data()!;
      if (data['userId'] != AuthService.currentUser?.uid) return;
      if (data['status'] == 'paid') return;

      await ref.update({
        'status': 'authorized',
        'paymentKey': paymentKey,
        'authorizedAmount': amount,
        'awaitingServerConfirm': true,
        'confirmError': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('인증 결과 저장 오류: $e');
    }
  }

  /// 관리자가 결제완료 + 수강 배정을 수동으로 확정한다.
  /// (Cloud Functions 배포 전 임시용 / 이체 확인 후 처리용)
  static Future<String?> adminFulfillPayment(String orderId) async {
    try {
      final ref = _firestore.collection('payments').doc(orderId);
      final snap = await ref.get();
      if (!snap.exists) return '주문을 찾을 수 없습니다.';
      final payment = snap.data()!;
      if (payment['status'] == 'paid') return '이미 결제 완료된 주문입니다.';

      final courseId = payment['courseId']?.toString() ?? '';
      final userId = payment['userId']?.toString() ?? '';
      final email = payment['email']?.toString() ?? '';
      final memberName = payment['memberName']?.toString() ?? '';
      final totalSessions = (payment['totalSessions'] is int)
          ? payment['totalSessions'] as int
          : int.tryParse(payment['totalSessions']?.toString() ?? '') ?? 8;
      final amount = (payment['amount'] is int)
          ? payment['amount'] as int
          : int.tryParse(payment['amount']?.toString() ?? '') ?? 0;

      if (courseId.isEmpty || userId.isEmpty) {
        return '주문 정보가 올바르지 않습니다.';
      }

      final existing = await _firestore
          .collection('enrollments')
          .where('userId', isEqualTo: userId)
          .get();

      DocumentReference? enrollmentRef;
      for (final doc in existing.docs) {
        if (doc.data()['courseId']?.toString() == courseId) {
          enrollmentRef = doc.reference;
          break;
        }
      }

      final enrollmentPayload = <String, dynamic>{
        'userId': userId,
        'email': email,
        'memberName': memberName,
        'courseId': courseId,
        'isActive': true,
        'totalSessions': totalSessions,
        'isPaid': true,
        'paidAmount': amount,
        'paymentNote': '관리자 수동확정 / 토스 인증',
        'nativeTeacherId': payment['nativeTeacherId']?.toString() ?? '',
        'nativeTeacherName': payment['nativeTeacherName']?.toString() ?? '',
        'nativeTeacherUid': payment['nativeTeacherUid']?.toString() ?? '',
        'paidAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (enrollmentRef != null) {
        final prev = (await enrollmentRef.get()).data() as Map<String, dynamic>;
        final completed = (prev['completedSessions'] is int)
            ? prev['completedSessions'] as int
            : 0;
        final createdRaw = prev['createdAt'];
        final start = createdRaw is Timestamp
            ? createdRaw.toDate()
            : DateTime.now();
        final payload = <String, dynamic>{
          ...enrollmentPayload,
          'completedSessions': completed,
          'remainingSessions':
              (totalSessions - completed).clamp(0, totalSessions),
        };
        if (prev['expiresAt'] == null) {
          payload['expiresAt'] = Timestamp.fromDate(
            EnrollmentService.expiresAtFromStart(start, totalSessions),
          );
        }
        await enrollmentRef.update(payload);
      } else {
        await _firestore.collection('enrollments').add({
          ...enrollmentPayload,
          'completedSessions': 0,
          'remainingSessions': totalSessions,
          'expiresAt': Timestamp.fromDate(
            EnrollmentService.expiresAtFromStart(
              DateTime.now(),
              totalSessions,
            ),
          ),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await ref.update({
        'status': 'paid',
        'awaitingServerConfirm': false,
        'fulfilledByAdmin': true,
        'paidAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final nativeTeacherId = payment['nativeTeacherId']?.toString() ?? '';
      final nativeTeacherName = payment['nativeTeacherName']?.toString() ?? '';
      final nativeTeacherUid = payment['nativeTeacherUid']?.toString() ?? '';
      if (nativeTeacherId.isNotEmpty) {
        await _firestore.collection('members').doc(userId).set({
          'teacherId': nativeTeacherUid,
          'nativeTeacherId': nativeTeacherId,
          'nativeTeacherName': nativeTeacherName,
          'nativeTeacherUid': nativeTeacherUid,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      return null;
    } catch (e) {
      print('관리자 결제 확정 오류: $e');
      return '결제 확정에 실패했습니다.';
    }
  }

  /// 관리자용 결제 목록.
  static Future<List<PaymentOrder>> listPayments({int limit = 100}) async {
    try {
      final snapshot =
          await _firestore.collection('payments').limit(limit).get();
      final list = snapshot.docs
          .map((d) => PaymentOrder.fromMap(d.id, d.data()))
          .toList();
      list.sort((a, b) {
        final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bt.compareTo(at);
      });
      return list;
    } catch (e) {
      print('결제 목록 조회 오류: $e');
      return [];
    }
  }

  /// 내 결제 목록.
  static Future<List<PaymentOrder>> myPayments() async {
    final user = AuthService.currentUser;
    if (user == null) return [];
    try {
      final snapshot = await _firestore
          .collection('payments')
          .where('userId', isEqualTo: user.uid)
          .get();
      final list = snapshot.docs
          .map((d) => PaymentOrder.fromMap(d.id, d.data()))
          .toList();
      list.sort((a, b) {
        final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bt.compareTo(at);
      });
      return list;
    } catch (e) {
      print('내 결제 조회 오류: $e');
      return [];
    }
  }

  static Future<PaymentOrder?> findByOrderId(String orderId) async {
    try {
      final doc = await _firestore.collection('payments').doc(orderId).get();
      if (!doc.exists) return null;
      return PaymentOrder.fromMap(doc.id, doc.data()!);
    } catch (e) {
      print('결제 조회 오류: $e');
      return null;
    }
  }

  static String _generateOrderId() {
    final rand = Random.secure();
    final bytes = List<int>.generate(12, (_) => rand.nextInt(256));
    final suffix = base64Url.encode(bytes).replaceAll('=', '');
    return 'GI${DateTime.now().millisecondsSinceEpoch}$suffix';
  }
}

class PaymentOrder {
  final String orderId;
  final String userId;
  final String email;
  final String memberName;
  final String courseId;
  final String courseTitle;
  final int amount;
  final int totalSessions;
  final String status; // pending | paid | failed | cancelled
  final String? paymentKey;
  final String? method;
  final DateTime? createdAt;
  final DateTime? paidAt;
  final String nativeTeacherId;
  final String nativeTeacherName;
  final String nativeTeacherUid;

  PaymentOrder({
    required this.orderId,
    required this.userId,
    required this.email,
    required this.memberName,
    required this.courseId,
    required this.courseTitle,
    required this.amount,
    required this.totalSessions,
    required this.status,
    this.paymentKey,
    this.method,
    this.createdAt,
    this.paidAt,
    this.nativeTeacherId = '',
    this.nativeTeacherName = '',
    this.nativeTeacherUid = '',
  });

  OnlineCourse? get course => OnlineCourse.findById(courseId);

  String get amountLabel {
    final s = amount.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '${buf.toString()}원';
  }

  String get statusLabel {
    switch (status) {
      case 'paid':
        return '결제완료';
      case 'authorized':
        return '인증완료(승인대기)';
      case 'failed':
        return '실패';
      case 'cancelled':
        return '취소';
      default:
        return '결제대기';
    }
  }

  factory PaymentOrder.fromMap(String id, Map<String, dynamic> data) {
    DateTime? toDate(dynamic raw) => raw is Timestamp ? raw.toDate() : null;
    return PaymentOrder(
      orderId: data['orderId']?.toString() ?? id,
      userId: data['userId']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      memberName: data['memberName']?.toString() ?? '',
      courseId: data['courseId']?.toString() ?? '',
      courseTitle: data['courseTitle']?.toString() ?? '',
      amount: (data['amount'] is int)
          ? data['amount'] as int
          : int.tryParse(data['amount']?.toString() ?? '') ?? 0,
      totalSessions: (data['totalSessions'] is int)
          ? data['totalSessions'] as int
          : int.tryParse(data['totalSessions']?.toString() ?? '') ?? 0,
      status: data['status']?.toString() ?? 'pending',
      paymentKey: data['paymentKey']?.toString(),
      method: data['method']?.toString(),
      createdAt: toDate(data['createdAt']),
      paidAt: toDate(data['paidAt']),
      nativeTeacherId: data['nativeTeacherId']?.toString() ?? '',
      nativeTeacherName: data['nativeTeacherName']?.toString() ?? '',
      nativeTeacherUid: data['nativeTeacherUid']?.toString() ?? '',
    );
  }
}
