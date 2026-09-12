import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:gi_english_website/class/OnlineNativeTeacher.dart';
import 'package:gi_english_website/firebase_options.dart';
import 'package:gi_english_website/util/PhoneUtil.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 관리 스태프 역할.
/// - [owner]: 메인 관리자 (전체 회원·결제·강사·강의 관리)
/// - [teacher]: 서브 강사 (배정된 회원의 스케줄·피드백·화상수업)
enum AdminRole { owner, teacher, none }

/// 수강생이 강사를 고르는 화면.
enum TeacherPickKind { checkout, coteach }

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// 메인 관리자 이메일 (기존 계정).
  static const String ownerEmail = 'gienglish.paju@gmail.com';

  // 현재 로그인된 사용자 가져오기
  static User? get currentUser => _auth.currentUser;

  // 로그인 상태 스트림
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 이메일로 로그인
  static Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } catch (e) {
      print('로그인 오류: $e');
      return null;
    }
  }

  static const String academyPhone = '031 942 0908';
  static const String academyEmail = 'gienglish.paju@gmail.com';

  /// 비밀번호 재설정 메일을 보낸다.
  /// 성공(또는 계정 존재 여부를 숨긴 경우) 시 null, 형식/요청 제한 오류만 메시지를 반환한다.
  static Future<String?> sendPasswordResetEmail(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return '이메일을 입력해주세요.';
    if (!trimmed.contains('@') || !trimmed.contains('.')) {
      return '이메일 형식이 올바르지 않습니다.';
    }
    try {
      await _auth.sendPasswordResetEmail(email: trimmed);
      return null;
    } on FirebaseAuthException catch (e) {
      print('비밀번호 재설정 오류: $e');
      switch (e.code) {
        case 'invalid-email':
          return '이메일 형식이 올바르지 않습니다.';
        case 'too-many-requests':
          return '요청이 너무 많습니다. 잠시 후 다시 시도해주세요.';
        default:
          return null;
      }
    } catch (e) {
      print('비밀번호 재설정 오류: $e');
      return null;
    }
  }

  /// 온라인 프로그램 회원 가입.
  /// 성공 시 null, 실패 시 사용자에게 보여줄 오류 메시지를 반환한다.
  static Future<String?> registerMember({
    required String email,
    required String password,
    required String name,
    String phone = '',
  }) async {
    final phoneError = PhoneUtil.validate(phone);
    if (phoneError != null) return phoneError;
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = result.user;
      if (user == null) return '회원가입에 실패했습니다. 다시 시도해주세요.';

      await user.updateDisplayName(name);
      await _firestore.collection('members').doc(user.uid).set({
        'email': email,
        'name': name,
        'phone': PhoneUtil.normalize(phone),
        'role': 'member',
        'isActive': true,
        'teacherId': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null;
    } on FirebaseAuthException catch (e) {
      print('회원가입 Auth 오류: $e');
      switch (e.code) {
        case 'email-already-in-use':
          return '이미 사용 중인 이메일입니다.';
        case 'invalid-email':
          return '이메일 형식이 올바르지 않습니다.';
        case 'weak-password':
          return '비밀번호는 6자 이상으로 설정해주세요.';
        default:
          return '회원가입에 실패했습니다. (${e.code})';
      }
    } catch (e) {
      print('회원가입 오류: $e');
      return '회원가입 중 오류가 발생했습니다.';
    }
  }

  /// 이메일로 회원 문서 조회 (관리자 수강 배정용).
  static Future<Map<String, dynamic>?> findMemberByEmail(String email) async {
    try {
      final snapshot = await _firestore
          .collection('members')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      final data = doc.data();
      data['uid'] = doc.id;
      return data;
    } catch (e) {
      print('회원 조회 오류: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> currentMemberDoc() async {
    final user = currentUser;
    if (user == null) return null;
    try {
      final doc = await _firestore.collection('members').doc(user.uid).get();
      if (!doc.exists) return null;
      final data = doc.data() ?? {};
      data['uid'] = doc.id;
      return data;
    } catch (e) {
      print('내 회원 정보 조회 오류: $e');
      return null;
    }
  }

  /// 회원 목록 (관리자용).
  /// [teacherId]가 있으면 해당 강사에게 배정된 회원만 반환한다.
  /// [oldestFirst]가 true면 가입 시각이 오래된 회원부터 반환한다.
  static Future<List<Map<String, dynamic>>> listMembers({
    int limit = 100,
    String? teacherId,
    bool oldestFirst = false,
  }) async {
    try {
      Query query = _firestore.collection('members');
      if (teacherId != null && teacherId.isNotEmpty) {
        query = query.where('teacherId', isEqualTo: teacherId);
      }
      final snapshot = await query.limit(limit).get();

      final list = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['uid'] = doc.id;
        return data;
      }).toList();

      list.sort((a, b) {
        final aTime = memberCreatedAt(a) ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = memberCreatedAt(b) ?? DateTime.fromMillisecondsSinceEpoch(0);
        return oldestFirst ? aTime.compareTo(bTime) : bTime.compareTo(aTime);
      });
      return list;
    } catch (e) {
      print('회원 목록 조회 오류: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getMember(String uid) async {
    if (uid.isEmpty) return null;
    try {
      final doc = await _firestore.collection('members').doc(uid).get();
      if (!doc.exists) return null;
      final data = Map<String, dynamic>.from(doc.data() ?? {});
      data['uid'] = doc.id;
      return data;
    } catch (e) {
      print('회원 단건 조회 오류: $e');
      return null;
    }
  }

  static DateTime? memberCreatedAt(Map<String, dynamic> member) {
    final raw = member['createdAt'];
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return null;
  }

  static String memberTeacherName(
    Map<String, dynamic> member, {
    Map<String, String> teacherNames = const {},
  }) {
    final named = member['nativeTeacherName']?.toString().trim() ?? '';
    if (named.isNotEmpty) return named;
    final id = member['teacherId']?.toString().trim() ??
        member['nativeTeacherUid']?.toString().trim() ??
        '';
    if (id.isEmpty) return '';
    return teacherNames[id]?.trim() ?? '';
  }

  /// 회원이 본인 휴대폰 번호를 저장한다.
  static Future<String?> updateMemberPhone({
    required String memberId,
    required String phone,
  }) async {
    final error = PhoneUtil.validate(phone);
    if (error != null) return error;
    try {
      await _firestore.collection('members').doc(memberId).set({
        'phone': PhoneUtil.normalize(phone),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return null;
    } catch (e) {
      print('회원 연락처 저장 오류: $e');
      return '연락처 저장에 실패했습니다.';
    }
  }

  /// 강사/관리자가 본인 휴대폰 번호를 저장한다.
  static Future<String?> updateOwnStaffPhone(String phone) async {
    final error = PhoneUtil.validate(phone);
    if (error != null) return error;
    final uid = await currentStaffUid();
    if (uid.isEmpty) return '로그인 정보가 없습니다.';
    try {
      await _firestore.collection('admins').doc(uid).set({
        'phone': PhoneUtil.normalize(phone),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return null;
    } catch (e) {
      print('강사 연락처 저장 오류: $e');
      return '연락처 저장에 실패했습니다.';
    }
  }
  /// 회원을 강사에게 배정하거나 배정을 해제한다. teacherId가 빈 문자열이면 해제.
  /// 수강생 내 강의실이 보는 nativeTeacher* 필드와 수강 배정 문서도 함께 맞춘다.
  static Future<String?> assignMemberToTeacher({
    required String memberId,
    required String teacherId,
  }) async {
    try {
      String profileId = '';
      String name = '';
      String email = '';
      String nationality = '';
      String intro = '';
      String photoUrl = '';
      if (teacherId.isNotEmpty) {
        final admin = await _firestore.collection('admins').doc(teacherId).get();
        final data = admin.data() ?? {};
        name = data['name']?.toString() ?? '';
        email = data['email']?.toString() ?? '';
        nationality = data['nationality']?.toString() ?? '';
        intro = data['intro']?.toString() ?? '';
        photoUrl = data['photoUrl']?.toString() ?? '';
        var existing = data['nativeProfileId']?.toString() ?? '';
        if (existing.startsWith('native_temp_')) existing = '';
        profileId = OnlineNativeTeacher.profileIdFor(
          uid: teacherId,
          isOwner: data['role']?.toString() != 'teacher',
          existing: existing,
        );
        await _upsertNativeProfile(
          teacherUid: teacherId,
          profileId: profileId,
          name: name,
          email: email,
          nationality: nationality,
          intro: intro,
          photoUrl: photoUrl,
          isActive: data['isActive'] != false,
        );
        OnlineNativeTeacher.cacheAll([
          OnlineNativeTeacher.fromAccountDoc(profileId, {
            'teacherUid': teacherId,
            'name': name,
            'nationality': nationality,
            'intro': intro,
            'photoUrl': photoUrl,
          }),
        ]);
      }

      final teacherFields = <String, dynamic>{
        'teacherId': teacherId,
        'nativeTeacherId': profileId,
        'nativeTeacherName': name,
        'nativeTeacherUid': teacherId,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _firestore.collection('members').doc(memberId).set(
            teacherFields,
            SetOptions(merge: true),
          );

      final enrollments = await _firestore
          .collection('enrollments')
          .where('userId', isEqualTo: memberId)
          .get();
      for (final doc in enrollments.docs) {
        await doc.reference.set({
          'nativeTeacherId': profileId,
          'nativeTeacherName': name,
          'nativeTeacherUid': teacherId,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      return null;
    } catch (e) {
      print('회원-강사 배정 오류: $e');
      return '회원 배정에 실패했습니다.';
    }
  }

  // 로그아웃
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _clearAdminPrefs();
    } catch (e) {
      print('로그아웃 오류: $e');
    }
  }

  static Future<void> _clearAdminPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isAdminLoggedIn');
    await prefs.remove('adminEmail');
    await prefs.remove('adminName');
    await prefs.remove('adminRole');
    await prefs.remove('adminUid');
  }

  static bool isOwnerEmail(String? email) =>
      (email ?? '').trim().toLowerCase() == ownerEmail;

  /// 메인 관리자(소유자)인지 — 학원 갤러리/공지/FAQ 와 온라인 전체 관리.
  /// Firebase Auth 세션이 있어야 한다. prefs-only 로그인은 인정하지 않는다.
  static Future<bool> isAdmin() async =>
      (await getAdminRole()) == AdminRole.owner;

  /// 메인 관리자 또는 서브 강사인지 — 온라인 프로그램 허브 접근용.
  static Future<bool> isStaff() async {
    final role = await getAdminRole();
    return role == AdminRole.owner || role == AdminRole.teacher;
  }

  static Future<bool> isTeacher() async =>
      (await getAdminRole()) == AdminRole.teacher;

  /// Firebase 로그인 상태가 바뀔 때마다 역할을 다시 읽는다.
  /// 학원 갤러리처럼 로그인 전에 열린 페이지가 버튼을 갱신할 때 사용.
  static StreamSubscription<User?> listenRole(
      void Function(AdminRole role) onRole) {
    Future<void> emit() async => onRole(await getAdminRole());
    unawaited(emit());
    return authStateChanges.listen((_) => unawaited(emit()));
  }

  static Future<AdminRole> getAdminRole() async {
    try {
      final user = currentUser;
      if (user == null) {
        // Firestore 쓰기는 request.auth 가 필요하다.
        // 예전에 남긴 SharedPreferences 세션만으로는 owner 가 아니다.
        return AdminRole.none;
      }

      // 학원/온라인 메인 관리자 이메일은 항상 owner.
      // 강사 등록 과정에서 role 이 teacher 로 덮여도 갤러리 쓰기가 막히지 않게 한다.
      if (isOwnerEmail(user.email)) {
        await _persistResolvedRole(AdminRole.owner, user);
        return AdminRole.owner;
      }

      final adminDoc =
          await _firestore.collection('admins').doc(user.uid).get();
      if (adminDoc.exists) {
        final data = adminDoc.data() as Map<String, dynamic>;
        if (data['isActive'] == false) {
          await _clearAdminPrefs();
          return AdminRole.none;
        }
        final role = data['role']?.toString() ?? 'owner';
        final resolved =
            role == 'teacher' ? AdminRole.teacher : AdminRole.owner;
        await _persistResolvedRole(resolved, user);
        return resolved;
      }

      await _clearAdminPrefs();
      return AdminRole.none;
    } catch (e) {
      print('관리자 역할 확인 오류: $e');
      return AdminRole.none;
    }
  }

  static Future<void> _persistResolvedRole(AdminRole role, User user) async {
    await saveAdminSession(
      user.email ?? '',
      role: role,
      uid: user.uid,
    );
  }

  /// 현재 스태프 세션의 uid (강사 필터용).
  static Future<String?> getStaffUid() async {
    final uid = currentUser?.uid;
    if (uid != null && uid.isNotEmpty) return uid;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('adminUid');
    if (saved != null && saved.isNotEmpty) return saved;
    return null;
  }

  // 관리자 등록 (최초 설정용)
  static Future<bool> registerAdmin(
      String email, String password, String name) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        await _firestore.collection('admins').doc(result.user!.uid).set({
          'email': email,
          'name': name,
          'role': 'owner',
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        });

        return true;
      }
      return false;
    } catch (e) {
      print('관리자 등록 오류: $e');
      return false;
    }
  }

  /// 서브 강사 계정 생성.
  /// 메인 관리자 세션을 유지하기 위해 보조 Firebase 앱으로 Auth 계정을 만든다.
  static String bankLabel(Map<String, dynamic>? data) {
    final bank = data?['bankName']?.toString().trim() ?? '';
    final account = data?['bankAccount']?.toString().trim() ?? '';
    final holder = data?['accountHolder']?.toString().trim() ?? '';
    if (bank.isEmpty && account.isEmpty) return '';
    return [
      if (bank.isNotEmpty) bank,
      if (account.isNotEmpty) account,
      if (holder.isNotEmpty) '예금주 $holder',
    ].join(' · ');
  }

  static Future<String?> registerTeacher({
    required String email,
    required String password,
    required String name,
    String phone = '',
    String nationality = '',
    String intro = '',
    String bankName = '',
    String bankAccount = '',
    String accountHolder = '',
    Uint8List? photoBytes,
    String? photoFileName,
  }) async {
    FirebaseApp? secondaryApp;
    try {
      if (email.trim().toLowerCase() == ownerEmail) {
        return '메인 관리자 이메일로는 강사를 등록할 수 없습니다.';
      }
      if (password.trim().length < 6) {
        return '비밀번호는 6자 이상으로 설정해주세요.';
      }
      final phoneError = PhoneUtil.validate(phone);
      if (phoneError != null) return phoneError;

      secondaryApp = await Firebase.initializeApp(
        name: 'TeacherRegistration',
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final result = await secondaryAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = result.user;
      if (user == null) return '강사 계정 생성에 실패했습니다.';

      await user.updateDisplayName(name.trim());

      String photoUrl = '';
      String? photoError;
      if (photoBytes != null && photoBytes.isNotEmpty) {
        try {
          photoUrl = await uploadTeacherPhoto(
            teacherUid: user.uid,
            bytes: photoBytes,
            fileName: photoFileName ?? 'photo.jpg',
          );
        } catch (e) {
          photoError = _uploadErrorMessage(e);
        }
      }

      final profileId = OnlineNativeTeacher.profileIdFor(
        uid: user.uid,
        isOwner: false,
      );

      // Firestore 쓰기는 기본 앱(메인 관리자) 인증으로 수행된다.
      await _firestore.collection('admins').doc(user.uid).set({
        'email': email.trim(),
        'name': name.trim(),
        'phone': PhoneUtil.normalize(phone),
        'nationality': nationality.trim(),
        'intro': intro.trim(),
        'bankName': bankName.trim(),
        'bankAccount': bankAccount.trim(),
        'accountHolder': accountHolder.trim(),
        'photoUrl': photoUrl,
        'nativeProfileId': profileId,
        'role': 'teacher',
        'isActive': true,
        'hasLoginPassword': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      try {
        await _upsertNativeProfile(
          teacherUid: user.uid,
          profileId: profileId,
          name: name.trim(),
          email: email.trim(),
          nationality: nationality.trim(),
          intro: intro.trim(),
          photoUrl: photoUrl,
          isActive: true,
        );
      } catch (e) {
        print('원어민 프로필 동기화 오류: $e');
      }

      await secondaryAuth.signOut();
      if (photoError != null) {
        return '강사는 등록됐지만 사진을 올리지 못했습니다. $photoError '
            '목록의 수정에서 다시 올려 주세요.';
      }
      return null;
    } on FirebaseAuthException catch (e) {
      print('강사 등록 Auth 오류: $e');
      switch (e.code) {
        case 'email-already-in-use':
          return '이미 사용 중인 이메일입니다.';
        case 'invalid-email':
          return '이메일 형식이 올바르지 않습니다.';
        case 'weak-password':
          return '비밀번호는 6자 이상으로 설정해주세요.';
        default:
          return '강사 등록에 실패했습니다. (${e.code})';
      }
    } catch (e) {
      print('강사 등록 오류: $e');
      return '강사 등록 중 오류가 발생했습니다.';
    } finally {
      if (secondaryApp != null) {
        // 웹에서 delete() 대기를 하면 등록은 됐는데 실패 알림이 난다.
        unawaited(secondaryApp.delete());
      }
    }
  }

  /// 강사 목록 (메인 관리자용). 메인 관리자 본인도 강사로 포함한다.
  /// 예전 로그인으로 남은 owner 문서가 있어도 하나만 보여 준다.
  static Future<List<Map<String, dynamic>>> listTeachers() async {
    try {
      final snapshot = await _firestore.collection('admins').get();

      final owners = <Map<String, dynamic>>[];
      final teachers = <Map<String, dynamic>>[];
      for (final doc in snapshot.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        data['uid'] = doc.id;
        if (data['role']?.toString() == 'teacher') {
          teachers.add(data);
        } else {
          owners.add(data);
        }
      }

      final owner = _pickOwnerRecord(owners);
      final list = <Map<String, dynamic>>[
        if (owner != null) owner,
        ...teachers,
      ];
      list.sort((a, b) {
        final aOwner = a['role']?.toString() != 'teacher';
        final bOwner = b['role']?.toString() != 'teacher';
        if (aOwner && !bOwner) return -1;
        if (!aOwner && bOwner) return 1;
        final aName = a['name']?.toString() ?? '';
        final bName = b['name']?.toString() ?? '';
        return aName.compareTo(bName);
      });
      return list;
    } catch (e) {
      print('강사 목록 조회 오류: $e');
      return [];
    }
  }

  static Map<String, dynamic>? _pickOwnerRecord(
      List<Map<String, dynamic>> owners) {
    if (owners.isEmpty) return null;
    Map<String, dynamic>? picked;
    var best = -1;
    for (final owner in owners) {
      var score = 0;
      final email = (owner['email']?.toString() ?? '').toLowerCase();
      if (email == ownerEmail) score += 100;
      if (owner['role']?.toString() == 'owner') score += 20;
      if (currentUser != null && owner['uid'] == currentUser!.uid) score += 10;
      if ((owner['phone']?.toString() ?? '').trim().isNotEmpty) score += 5;
      if ((owner['name']?.toString() ?? '').trim().isNotEmpty) score += 2;
      if (score > best) {
        best = score;
        picked = owner;
      }
    }
    return picked ?? owners.first;
  }

  static Future<String> currentStaffUid() async {
    if (currentUser?.uid != null) return currentUser!.uid;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('adminUid') ?? '';
  }

  /// 현재 로그인한 관리자/강사 본인 프로필.
  static Future<Map<String, dynamic>?> currentStaffProfile() async {
    final uid = await currentStaffUid();
    if (uid.isEmpty) return null;
    try {
      final doc = await _firestore.collection('admins').doc(uid).get();
      if (!doc.exists) {
        final prefs = await SharedPreferences.getInstance();
        return {
          'uid': uid,
          'name': prefs.getString('adminName') ?? '',
          'email': prefs.getString('adminEmail') ?? currentUser?.email ?? '',
          'role': prefs.getString('adminRole') ?? '',
        };
      }
      final data = Map<String, dynamic>.from(doc.data() ?? {});
      data['uid'] = doc.id;
      return data;
    } catch (e) {
      print('스태프 프로필 조회 오류: $e');
      return {
        'uid': uid,
        'name': await getAdminName(),
        'email': currentUser?.email ?? '',
      };
    }
  }

  static Future<Map<String, dynamic>?> staffProfile(String uid) async {
    if (uid.isEmpty) return currentStaffProfile();
    try {
      final doc = await _firestore.collection('admins').doc(uid).get();
      if (!doc.exists) return null;
      final data = Map<String, dynamic>.from(doc.data() ?? {});
      data['uid'] = doc.id;
      return data;
    } catch (e) {
      print('강사 프로필 조회 오류: $e');
      return null;
    }
  }

  static Future<String?> setTeacherActive(
      String teacherId, bool isActive) async {
    try {
      final admin = await _firestore.collection('admins').doc(teacherId).get();
      if (!admin.exists) return '강사 계정을 찾을 수 없습니다.';
      final role = admin.data()?['role']?.toString() ?? 'owner';
      if (role != 'teacher') {
        return '메인 관리자는 비활성화할 수 없습니다.';
      }
      await _firestore.collection('admins').doc(teacherId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final profileId = admin.data()?['nativeProfileId']?.toString() ?? '';
      if (profileId.isNotEmpty) {
        await _firestore.collection('native_teacher_accounts').doc(profileId).set({
          'teacherUid': teacherId,
          'isActive': isActive,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      return null;
    } catch (e) {
      print('강사 상태 변경 오류: $e');
      return '강사 상태 변경에 실패했습니다.';
    }
  }

  static String _uploadErrorMessage(Object e) {
    if (e is FirebaseException) {
      final code = e.code;
      if (code == 'unauthorized' ||
          code == 'permission-denied' ||
          code == 'storage/unauthorized') {
        return '저장 권한이 없습니다.';
      }
      if (code == 'canceled' || code == 'storage/canceled') {
        return '업로드가 취소되었습니다.';
      }
      final message = e.message?.trim() ?? '';
      if (message.isNotEmpty) return message;
      return code;
    }
    return e.toString().replaceFirst('Exception: ', '');
  }

  static Future<String> uploadTeacherPhoto({
    required String teacherUid,
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (bytes.isEmpty) {
      throw Exception('사진 파일이 비어 있습니다.');
    }
    if (bytes.length > 10 * 1024 * 1024) {
      throw Exception('사진이 너무 큽니다. 10MB 이하 파일로 올려 주세요.');
    }

    // 자른 프로필 사진은 작고, 웹 Storage 업로드가 멈추는 경우가 있어 Firestore에 바로 넣는다.
    if (bytes.length <= 500 * 1024) {
      return _encodeTeacherPhotoDataUrl(bytes);
    }

    try {
      return await _uploadTeacherPhotoToStorage(
        teacherUid: teacherUid,
        bytes: bytes,
        fileName: fileName,
      ).timeout(const Duration(seconds: 12));
    } catch (e) {
      print('Storage 사진 업로드 실패, Firestore로 저장합니다: $e');
      return _encodeTeacherPhotoDataUrl(bytes);
    }
  }

  static Future<String> _uploadTeacherPhotoToStorage({
    required String teacherUid,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final path =
        'teacher_photos/$teacherUid/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child(path);
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return await ref.getDownloadURL();
  }

  static String _encodeTeacherPhotoDataUrl(Uint8List bytes) {
    if (bytes.length > 700 * 1024) {
      throw Exception('사진이 너무 큽니다. 자르기 화면에서 얼굴을 맞춘 뒤 다시 저장해주세요.');
    }
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }

  static Future<void> _upsertNativeProfile({
    required String teacherUid,
    required String profileId,
    required String name,
    required String email,
    String nationality = '',
    String intro = '',
    String photoUrl = '',
    required bool isActive,
    String? bookingOffer,
  }) async {
    final data = <String, dynamic>{
      'teacherUid': teacherUid,
      'name': name,
      'email': email,
      'nationality': nationality,
      'intro': intro,
      'photoUrl': photoUrl,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (bookingOffer != null && bookingOffer.isNotEmpty) {
      data['bookingOffer'] = bookingOffer;
      data['selectableAtCheckout'] =
          TeacherBookingOffer.shownAtCheckout(bookingOffer);
      data['acceptsCoTeaching'] =
          TeacherBookingOffer.shownAsCoteach(bookingOffer);
    }
    await _firestore
        .collection('native_teacher_accounts')
        .doc(profileId)
        .set(data, SetOptions(merge: true));
  }

  /// 메인 관리자(또는 강사)의 결제 선택·코티칭 수신 설정.
  static Future<String?> updateBookingOffer({
    required String teacherUid,
    required String offer,
  }) async {
    if (offer != TeacherBookingOffer.both &&
        offer != TeacherBookingOffer.coteach &&
        offer != TeacherBookingOffer.off) {
      return '올바르지 않은 수업 받기 설정입니다.';
    }
    try {
      final adminRef = _firestore.collection('admins').doc(teacherUid);
      final adminSnap = await adminRef.get();
      if (!adminSnap.exists) return '강사 계정을 찾을 수 없습니다.';
      final data = adminSnap.data() ?? {};
      final isOwnerTeacher = data['role']?.toString() != 'teacher';
      var existing = data['nativeProfileId']?.toString() ?? '';
      if (existing.startsWith('native_temp_')) existing = '';
      final profileId = OnlineNativeTeacher.profileIdFor(
        uid: teacherUid,
        isOwner: isOwnerTeacher,
        existing: existing,
      );
      await adminRef.set({
        'bookingOffer': offer,
        'selectableAtCheckout': TeacherBookingOffer.shownAtCheckout(offer),
        'acceptsCoTeaching': TeacherBookingOffer.shownAsCoteach(offer),
        'nativeProfileId': profileId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await _upsertNativeProfile(
        teacherUid: teacherUid,
        profileId: profileId,
        name: data['name']?.toString() ?? '',
        email: data['email']?.toString() ?? '',
        nationality: data['nationality']?.toString() ?? '',
        intro: data['intro']?.toString() ?? '',
        photoUrl: data['photoUrl']?.toString() ?? '',
        isActive: data['isActive'] != false,
        bookingOffer: offer,
      );
      return null;
    } catch (e) {
      print('수업 받기 설정 오류: $e');
      return '수업 받기 설정을 저장하지 못했습니다.';
    }
  }

  /// 이미 등록된 강사에게 로그인 비밀번호를 만들거나 바꾼다.
  static Future<String?> setTeacherPassword({
    required String teacherUid,
    required String password,
  }) async {
    final trimmed = password.trim();
    if (trimmed.length < 6) {
      return '비밀번호는 6자 이상으로 설정해주세요.';
    }
    try {
      final callable =
          FirebaseFunctions.instanceFor(region: 'asia-northeast3')
              .httpsCallable('setTeacherPassword');
      await callable.call(<String, dynamic>{
        'teacherUid': teacherUid,
        'password': trimmed,
      });
      return null;
    } on FirebaseFunctionsException catch (e) {
      print('강사 비밀번호 설정 오류: ${e.code} ${e.message}');
      return e.message?.trim().isNotEmpty == true
          ? e.message
          : '비밀번호 설정에 실패했습니다.';
    } catch (e) {
      print('강사 비밀번호 설정 오류: $e');
      return '비밀번호 설정에 실패했습니다.';
    }
  }

  /// 이미 등록된 강사(메인 관리자 포함)의 이름·소개·사진 수정.
  static Future<String?> updateTeacherProfile({
    required String teacherUid,
    required String name,
    String phone = '',
    String nationality = '',
    String intro = '',
    String bankName = '',
    String bankAccount = '',
    String accountHolder = '',
    Uint8List? photoBytes,
    String? photoFileName,
    String? password,
  }) async {
    try {
      final trimmed = name.trim();
      if (trimmed.isEmpty) return '강사 이름을 입력해주세요.';
      final phoneError = PhoneUtil.validate(phone);
      if (phoneError != null) return phoneError;

      final adminRef = _firestore.collection('admins').doc(teacherUid);
      final adminSnap = await adminRef.get();
      if (!adminSnap.exists) return '강사 계정을 찾을 수 없습니다.';

      final data = adminSnap.data() ?? {};
      final isOwnerTeacher = data['role']?.toString() != 'teacher';
      final email = data['email']?.toString() ?? '';
      final isActive = data['isActive'] != false;
      var photoUrl = data['photoUrl']?.toString() ?? '';
      final profileId = OnlineNativeTeacher.profileIdFor(
        uid: teacherUid,
        isOwner: isOwnerTeacher,
        existing: data['nativeProfileId']?.toString() ?? '',
      );

      if (photoBytes != null && photoBytes.isNotEmpty) {
        try {
          photoUrl = await uploadTeacherPhoto(
            teacherUid: teacherUid,
            bytes: photoBytes,
            fileName: photoFileName ?? 'photo.jpg',
          );
        } catch (e) {
          return '사진 업로드에 실패했습니다. ${_uploadErrorMessage(e)}';
        }
      }

      await adminRef.set({
        'name': trimmed,
        'phone': PhoneUtil.normalize(phone),
        'nationality': nationality.trim(),
        'intro': intro.trim(),
        'bankName': bankName.trim(),
        'bankAccount': bankAccount.trim(),
        'accountHolder': accountHolder.trim(),
        'photoUrl': photoUrl,
        'nativeProfileId': profileId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      try {
        await _upsertNativeProfile(
          teacherUid: teacherUid,
          profileId: profileId,
          name: trimmed,
          email: email,
          nationality: nationality.trim(),
          intro: intro.trim(),
          photoUrl: photoUrl,
          isActive: isActive,
          bookingOffer: TeacherBookingOffer.resolve(
            data,
            isOwner: isOwnerTeacher,
          ),
        );
      } catch (e) {
        print('원어민 프로필 동기화 오류: $e');
      }

      if (!isOwnerTeacher &&
          password != null &&
          password.trim().isNotEmpty) {
        final pwError = await setTeacherPassword(
          teacherUid: teacherUid,
          password: password,
        );
        if (pwError != null) {
          return '프로필은 저장됐지만 비밀번호 설정에 실패했습니다. $pwError';
        }
      }
      return null;
    } catch (e) {
      print('강사 프로필 수정 오류: $e');
      return '강사 정보 수정에 실패했습니다. ${_uploadErrorMessage(e)}';
    }
  }

  /// profileId -> 강사 uid. 로그인 회원이 원어민 선택·예약에 사용한다.
  static Future<Map<String, String>> nativeTeacherAccountMap() async {
    try {
      final snapshot =
          await _firestore.collection('native_teacher_accounts').get();
      final map = <String, String>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['isActive'] == false) continue;
        final uid = data['teacherUid']?.toString() ?? '';
        if (uid.isNotEmpty) map[doc.id] = uid;
      }
      return map;
    } catch (e) {
      print('원어민 강사 계정 조회 오류: $e');
      return {};
    }
  }

  static Future<String> uidForNativeProfile(String profileId) async {
    if (profileId.isEmpty) return '';
    final cached = OnlineNativeTeacher.findById(profileId);
    if (cached != null && cached.accountUid.isNotEmpty) {
      return cached.accountUid;
    }
    final map = await nativeTeacherAccountMap();
    return map[profileId] ?? '';
  }

  /// 수강생 화면에 배정 강사 사진/이름이 비지 않도록 공개 프로필을 캐시에 넣는다.
  static Future<void> ensureTeacherCached(String teacherUid) async {
    if (teacherUid.isEmpty) return;
    if (OnlineNativeTeacher.findAssigned(accountUid: teacherUid) != null) {
      return;
    }
    try {
      final byUid = await _firestore
          .collection('native_teacher_accounts')
          .where('teacherUid', isEqualTo: teacherUid)
          .limit(1)
          .get();
      if (byUid.docs.isNotEmpty) {
        final teacher = OnlineNativeTeacher.fromAccountDoc(
          byUid.docs.first.id,
          byUid.docs.first.data(),
        );
        OnlineNativeTeacher.cacheAll([teacher]);
        return;
      }
      final byId = await _firestore
          .collection('native_teacher_accounts')
          .doc('native_$teacherUid')
          .get();
      if (byId.exists) {
        OnlineNativeTeacher.cacheAll([
          OnlineNativeTeacher.fromAccountDoc(byId.id, byId.data() ?? {}),
        ]);
      }
    } catch (e) {
      print('배정 강사 프로필 조회 오류: $e');
    }
  }

  /// 관리자 화면에 있는 강사 프로필을 수강생이 볼 수 있는 목록으로 공개한다.
  static Future<void> publishTeacherProfiles() async {
    try {
      final snapshot = await _firestore.collection('admins').get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final isOwnerTeacher = data['role']?.toString() != 'teacher';
        var existing = data['nativeProfileId']?.toString() ?? '';
        if (existing.startsWith('native_temp_')) existing = '';
        final profileId = OnlineNativeTeacher.profileIdFor(
          uid: doc.id,
          isOwner: isOwnerTeacher,
          existing: existing,
        );
        await _upsertNativeProfile(
          teacherUid: doc.id,
          profileId: profileId,
          name: data['name']?.toString() ?? '',
          email: data['email']?.toString() ?? '',
          nationality: data['nationality']?.toString() ?? '',
          intro: data['intro']?.toString() ?? '',
          photoUrl: data['photoUrl']?.toString() ?? '',
          isActive: data['isActive'] != false,
          bookingOffer: TeacherBookingOffer.resolve(
            data,
            isOwner: isOwnerTeacher,
          ),
        );
        await _firestore.collection('admins').doc(doc.id).set({
          'nativeProfileId': profileId,
          'bookingOffer': TeacherBookingOffer.resolve(
            data,
            isOwner: isOwnerTeacher,
          ),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('강사 프로필 공개 오류: $e');
    }
  }

  static Future<List<OnlineNativeTeacher>> selectableNativeTeachers({
    TeacherPickKind? kind,
  }) async {
    final teachers = await _loadPublicTeachers();
    if (kind == TeacherPickKind.checkout) {
      return teachers.where((t) => t.selectableAtCheckout).toList();
    }
    if (kind == TeacherPickKind.coteach) {
      return teachers.where((t) => t.acceptsCoTeaching).toList();
    }
    return teachers;
  }

  static Future<List<OnlineNativeTeacher>> _loadPublicTeachers() async {
    var teachers = <OnlineNativeTeacher>[];
    try {
      teachers = await _selectableTeachersFromServer();
    } catch (e) {
      print('선택 가능 강사 Functions 조회 오류: $e');
    }
    if (teachers.isEmpty) {
      teachers = await _teachersFromStore();
    } else {
      teachers = await _applyStoredBookingOffers(teachers);
    }
    OnlineNativeTeacher.cacheAll(teachers);
    return teachers;
  }

  static Future<List<OnlineNativeTeacher>> _teachersFromStore() async {
    try {
      final snapshot =
          await _firestore.collection('native_teacher_accounts').get();
      final fromStore = <OnlineNativeTeacher>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['isActive'] == false) continue;
        final teacher = OnlineNativeTeacher.fromAccountDoc(doc.id, data);
        if (teacher.name.trim().isEmpty) continue;
        fromStore.add(teacher);
      }
      fromStore.sort((a, b) {
        final aOwner = a.id == OnlineNativeTeacher.ownerProfileId ? 0 : 1;
        final bOwner = b.id == OnlineNativeTeacher.ownerProfileId ? 0 : 1;
        if (aOwner != bOwner) return aOwner.compareTo(bOwner);
        return a.name.compareTo(b.name);
      });
      return fromStore;
    } catch (e) {
      print('선택 가능 원어민 강사 조회 오류: $e');
      return [];
    }
  }

  static Future<List<OnlineNativeTeacher>> _applyStoredBookingOffers(
    List<OnlineNativeTeacher> teachers,
  ) async {
    try {
      final snapshot =
          await _firestore.collection('native_teacher_accounts').get();
      final byKey = <String, String>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final isOwner = doc.id == OnlineNativeTeacher.ownerProfileId;
        final offer = TeacherBookingOffer.resolve(data, isOwner: isOwner);
        byKey[doc.id] = offer;
        final uid = data['teacherUid']?.toString() ?? '';
        if (uid.isNotEmpty) byKey[uid] = offer;
      }
      return teachers.map((teacher) {
        final offer = byKey[teacher.id] ??
            byKey[teacher.accountUid] ??
            TeacherBookingOffer.resolve(
              null,
              isOwner: teacher.id == OnlineNativeTeacher.ownerProfileId,
            );
        return teacher.copyWith(
          selectableAtCheckout: TeacherBookingOffer.shownAtCheckout(offer),
          acceptsCoTeaching: TeacherBookingOffer.shownAsCoteach(offer),
        );
      }).toList();
    } catch (e) {
      print('강사 수업 받기 설정 조회 오류: $e');
      return teachers
          .map((teacher) {
            final isOwner = teacher.id == OnlineNativeTeacher.ownerProfileId;
            final offer =
                TeacherBookingOffer.resolve(null, isOwner: isOwner);
            return teacher.copyWith(
              selectableAtCheckout:
                  TeacherBookingOffer.shownAtCheckout(offer),
              acceptsCoTeaching: TeacherBookingOffer.shownAsCoteach(offer),
            );
          })
          .toList();
    }
  }

  static Future<bool> teacherAcceptsCoTeaching(String teacherUid) async {
    if (teacherUid.isEmpty) return false;
    try {
      final byUid = await _firestore
          .collection('native_teacher_accounts')
          .where('teacherUid', isEqualTo: teacherUid)
          .limit(1)
          .get();
      if (byUid.docs.isEmpty) {
        return teacherUid.isNotEmpty;
      }
      final doc = byUid.docs.first;
      final offer = TeacherBookingOffer.resolve(
        doc.data(),
        isOwner: doc.id == OnlineNativeTeacher.ownerProfileId,
      );
      return TeacherBookingOffer.shownAsCoteach(offer);
    } catch (e) {
      print('코티칭 가능 여부 조회 오류: $e');
      return true;
    }
  }

  static Future<List<OnlineNativeTeacher>> _selectableTeachersFromServer() async {
    final callable =
        FirebaseFunctions.instanceFor(region: 'asia-northeast3')
            .httpsCallable('listSelectableTeachers');
    final result = await callable.call();
    final raw = result.data;
    if (raw is! Map) return [];
    final data = Map<String, dynamic>.from(raw);
    final list = data['teachers'];
    if (list is! List) return [];
    final teachers = <OnlineNativeTeacher>[];
    for (final item in list) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final name = map['name']?.toString().trim() ?? '';
      if (name.isEmpty) continue;
      final isOwner = map['isOwner'] == true;
      final offer = TeacherBookingOffer.resolve(map, isOwner: isOwner);
      teachers.add(OnlineNativeTeacher(
        id: map['id']?.toString() ?? '',
        name: name,
        nationality: map['nationality']?.toString() ?? '',
        intro: map['intro']?.toString() ?? '',
        imageAsset: isOwner
            ? 'assets/directorPhoto.jpeg'
            : OnlineNativeTeacher.fallbackAsset,
        photoUrl: map['photoUrl']?.toString() ?? '',
        accountUid: map['accountUid']?.toString() ?? '',
        selectableAtCheckout: TeacherBookingOffer.shownAtCheckout(offer),
        acceptsCoTeaching: TeacherBookingOffer.shownAsCoteach(offer),
      ));
    }
    return teachers;
  }

  /// 메인 관리자가 강사 계정을 원어민 프로필(Emma 등)에 연결한다.
  static Future<String?> linkNativeProfile({
    required String teacherUid,
    required String profileId,
  }) async {
    try {
      final adminRef = _firestore.collection('admins').doc(teacherUid);
      final adminSnap = await adminRef.get();
      if (!adminSnap.exists) return '강사 계정을 찾을 수 없습니다.';
      final prevProfile =
          adminSnap.data()?['nativeProfileId']?.toString() ?? '';
      final teacherName = adminSnap.data()?['name']?.toString() ?? '';
      final teacherEmail = adminSnap.data()?['email']?.toString() ?? '';
      final isActive = adminSnap.data()?['isActive'] != false;

      if (prevProfile.isNotEmpty && prevProfile != profileId) {
        await _firestore
            .collection('native_teacher_accounts')
            .doc(prevProfile)
            .delete();
      }

      if (profileId.isEmpty) {
        await adminRef.update({
          'nativeProfileId': '',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return null;
      }

      final existing =
          await _firestore.collection('native_teacher_accounts').doc(profileId).get();
      final previousUid = existing.data()?['teacherUid']?.toString() ?? '';
      if (previousUid.isNotEmpty && previousUid != teacherUid) {
        await _firestore.collection('admins').doc(previousUid).set({
          'nativeProfileId': '',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await adminRef.update({
        'nativeProfileId': profileId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _upsertNativeProfile(
        teacherUid: teacherUid,
        profileId: profileId,
        name: teacherName,
        email: teacherEmail,
        nationality: adminSnap.data()?['nationality']?.toString() ?? '',
        intro: adminSnap.data()?['intro']?.toString() ?? '',
        photoUrl: adminSnap.data()?['photoUrl']?.toString() ?? '',
        isActive: isActive,
      );
      return null;
    } catch (e) {
      print('원어민 프로필 연결 오류: $e');
      return '원어민 프로필 연결에 실패했습니다.';
    }
  }

  /// 메인 관리자를 모든 회원·수강·예약의 담당 원어민으로 연결한다.
  static Future<String?> assignOwnerNativeTeacherToAllStudents() async {
    try {
      String ownerUid = '';
      if ((currentUser?.email ?? '').toLowerCase() == ownerEmail) {
        ownerUid = currentUser!.uid;
      } else {
        final byEmail = await _firestore
            .collection('admins')
            .where('email', isEqualTo: ownerEmail)
            .limit(1)
            .get();
        if (byEmail.docs.isNotEmpty) {
          ownerUid = byEmail.docs.first.id;
        }
      }
      if (ownerUid.isEmpty) {
        return '메인 관리자 계정을 찾을 수 없습니다. 관리자 이메일로 로그인해 주세요.';
      }

      final profileId = OnlineNativeTeacher.ownerProfileId;
      final profileName =
          OnlineNativeTeacher.findById(profileId)?.name ?? 'Namhee Kim';
      final adminRef = _firestore.collection('admins').doc(ownerUid);
      final adminSnap = await adminRef.get();
      if (!adminSnap.exists) {
        await adminRef.set({
          'email': ownerEmail,
          'name': profileName,
          'role': 'owner',
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      final linkError = await linkNativeProfile(
        teacherUid: ownerUid,
        profileId: profileId,
      );
      if (linkError != null) return linkError;

      final enrollments = await _firestore.collection('enrollments').get();
      final members = await _firestore.collection('members').get();
      final bookings = await _firestore.collection('week_bookings').get();

      var batch = _firestore.batch();
      var ops = 0;
      Future<void> flush() async {
        if (ops == 0) return;
        await batch.commit();
        batch = _firestore.batch();
        ops = 0;
      }

      Future<void> merge(
          DocumentReference<Map<String, dynamic>> ref,
          Map<String, dynamic> data) async {
        batch.set(ref, data, SetOptions(merge: true));
        ops++;
        if (ops >= 400) await flush();
      }

      for (final doc in enrollments.docs) {
        if (doc.data()['isActive'] == false) continue;
        await merge(doc.reference, {
          'nativeTeacherId': profileId,
          'nativeTeacherName': profileName,
          'nativeTeacherUid': ownerUid,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      for (final doc in members.docs) {
        await merge(doc.reference, {
          'teacherId': ownerUid,
          'nativeTeacherId': profileId,
          'nativeTeacherName': profileName,
          'nativeTeacherUid': ownerUid,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      for (final doc in bookings.docs) {
        if (doc.data()['status'] == 'rejected') continue;
        await merge(doc.reference, {
          'teacherId': ownerUid,
          'nativeTeacherId': profileId,
          'nativeTeacherName': profileName,
          'nativeTeacherUid': ownerUid,
        });
      }
      await flush();
      return null;
    } catch (e) {
      print('메인 관리자 일괄 배정 오류: $e');
      return '수강생 일괄 배정에 실패했습니다.';
    }
  }

  /// 강사 Firebase Auth 로그인 후 역할 검증.
  /// 성공 시 null, 실패 시 오류 메시지.
  static Future<String?> signInAsStaff({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await signInWithEmailAndPassword(email.trim(), password);
      if (cred == null || cred.user == null) {
        return '로그인에 실패했습니다. 이메일과 비밀번호를 확인해주세요.';
      }

      final uid = cred.user!.uid;
      final signedEmail = cred.user!.email ?? email.trim();
      final adminDoc = await _firestore.collection('admins').doc(uid).get();

      // 메인 관리자 이메일은 admins 문서가 없거나 role 이 teacher 여도 owner.
      if (isOwnerEmail(signedEmail) || isOwnerEmail(email)) {
        final name = adminDoc.data()?['name']?.toString() ??
            cred.user!.displayName ??
            '관리자';
        await ensureAdminDoc(signedEmail, name, role: 'owner');
        await saveAdminSession(
          signedEmail,
          name: name,
          role: AdminRole.owner,
          uid: uid,
        );
        return null;
      }

      if (!adminDoc.exists) {
        await _auth.signOut();
        return '등록된 관리/강사 계정이 아닙니다.';
      }

      final data = adminDoc.data() as Map<String, dynamic>;
      if (data['isActive'] == false) {
        await _auth.signOut();
        return '비활성화된 계정입니다. 메인 관리자에게 문의하세요.';
      }

      final roleStr = data['role']?.toString() ?? 'owner';
      final role = roleStr == 'teacher' ? AdminRole.teacher : AdminRole.owner;
      final name =
          data['name']?.toString() ?? cred.user!.displayName ?? email.trim();

      await saveAdminSession(
        email.trim(),
        name: name,
        role: role,
        uid: uid,
      );
      return null;
    } catch (e) {
      print('스태프 로그인 오류: $e');
      return '로그인 중 오류가 발생했습니다.';
    }
  }

  // 로그인된 사용자 이름 가져오기
  static Future<String> getAdminName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? savedName = prefs.getString('adminName');
      if (savedName != null && savedName.isNotEmpty) {
        return savedName;
      }

      String? savedEmail = prefs.getString('adminEmail');
      if (savedEmail != null && savedEmail.isNotEmpty) {
        return savedEmail;
      }

      User? user = currentUser;
      if (user == null) return '관리자';

      DocumentSnapshot adminDoc =
          await _firestore.collection('admins').doc(user.uid).get();

      if (adminDoc.exists) {
        Map<String, dynamic> data = adminDoc.data() as Map<String, dynamic>;
        String name = data['name'] ?? user.email ?? '관리자';
        await prefs.setString('adminName', name);
        return name;
      }

      return user.email ?? '관리자';
    } catch (e) {
      print('관리자 이름 가져오기 오류: $e');
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('adminEmail') ?? '관리자';
    }
  }

  // 관리자/강사 로그인 세션 저장
  static Future<void> saveAdminSession(
    String email, {
    String? name,
    AdminRole role = AdminRole.owner,
    String? uid,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isAdminLoggedIn', true);
      await prefs.setString('adminEmail', email);
      await prefs.setString(
          'adminRole', role == AdminRole.teacher ? 'teacher' : 'owner');
      if (name != null && name.isNotEmpty) {
        await prefs.setString('adminName', name);
      }
      if (uid != null && uid.isNotEmpty) {
        await prefs.setString('adminUid', uid);
      } else if (currentUser?.uid != null) {
        await prefs.setString('adminUid', currentUser!.uid);
      }
    } catch (e) {
      print('관리자 세션 저장 오류: $e');
    }
  }

  /// Firebase 로그인 후 Firestore admins 문서가 있도록 보장 (FAQ/공지 저장 권한용)
  static Future<bool> ensureAdminDoc(String email, String name,
      {String role = 'owner'}) async {
    try {
      User? user = currentUser;
      if (user == null) return false;
      await _firestore.collection('admins').doc(user.uid).set({
        'email': email,
        'name': name,
        'role': role,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      print('관리자 문서 설정 오류: $e');
      return false;
    }
  }
}
