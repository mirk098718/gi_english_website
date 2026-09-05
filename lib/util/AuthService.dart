import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gi_english_website/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 관리 스태프 역할.
/// - [owner]: 메인 관리자 (전체 회원·결제·강사·강의 관리)
/// - [teacher]: 서브 강사 (배정된 회원에 대한 수업 배정·차감만)
enum AdminRole { owner, teacher, none }

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  /// 온라인 프로그램 회원 가입.
  /// 성공 시 null, 실패 시 사용자에게 보여줄 오류 메시지를 반환한다.
  static Future<String?> registerMember({
    required String email,
    required String password,
    required String name,
    String phone = '',
  }) async {
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
        'phone': phone,
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
  static Future<List<Map<String, dynamic>>> listMembers({
    int limit = 100,
    String? teacherId,
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
        final aRaw = a['createdAt'];
        final bRaw = b['createdAt'];
        final aTime = aRaw is Timestamp
            ? aRaw.toDate()
            : DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = bRaw is Timestamp
            ? bRaw.toDate()
            : DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return list;
    } catch (e) {
      print('회원 목록 조회 오류: $e');
      return [];
    }
  }

  /// 회원을 강사에게 배정하거나 배정을 해제한다. teacherId가 빈 문자열이면 해제.
  static Future<String?> assignMemberToTeacher({
    required String memberId,
    required String teacherId,
  }) async {
    try {
      await _firestore.collection('members').doc(memberId).update({
        'teacherId': teacherId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isAdminLoggedIn');
      await prefs.remove('adminEmail');
      await prefs.remove('adminName');
      await prefs.remove('adminRole');
      await prefs.remove('adminUid');
    } catch (e) {
      print('로그아웃 오류: $e');
    }
  }

  /// 메인 관리자(소유자)인지 — 게시판/갤러리/강의 업로드/강사 관리용.
  static Future<bool> isAdmin() async =>
      (await getAdminRole()) == AdminRole.owner;

  /// 메인 관리자 또는 서브 강사인지 — 온라인 프로그램 허브 접근용.
  static Future<bool> isStaff() async {
    final role = await getAdminRole();
    return role == AdminRole.owner || role == AdminRole.teacher;
  }

  static Future<bool> isTeacher() async =>
      (await getAdminRole()) == AdminRole.teacher;

  static Future<AdminRole> getAdminRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final roleStr = prefs.getString('adminRole');
      if (roleStr == 'owner') return AdminRole.owner;
      if (roleStr == 'teacher') return AdminRole.teacher;

      // 레거시: 역할 없이 로그인되어 있으면 메인 관리자로 취급
      final isLoggedIn = prefs.getBool('isAdminLoggedIn') ?? false;
      if (isLoggedIn) return AdminRole.owner;

      final user = currentUser;
      if (user == null) return AdminRole.none;

      final adminDoc =
          await _firestore.collection('admins').doc(user.uid).get();
      if (adminDoc.exists) {
        final data = adminDoc.data() as Map<String, dynamic>;
        if (data['isActive'] == false) return AdminRole.none;
        final role = data['role']?.toString() ?? 'owner';
        if (role == 'teacher') return AdminRole.teacher;
        return AdminRole.owner;
      }

      if ((user.email ?? '').toLowerCase() == ownerEmail) {
        return AdminRole.owner;
      }
      return AdminRole.none;
    } catch (e) {
      print('관리자 역할 확인 오류: $e');
      return AdminRole.none;
    }
  }

  /// 현재 스태프 세션의 uid (강사 필터용).
  static Future<String?> getStaffUid() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('adminUid');
    if (saved != null && saved.isNotEmpty) return saved;
    return currentUser?.uid;
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
  static Future<String?> registerTeacher({
    required String email,
    required String password,
    required String name,
  }) async {
    FirebaseApp? secondaryApp;
    try {
      if (email.trim().toLowerCase() == ownerEmail) {
        return '메인 관리자 이메일로는 강사를 등록할 수 없습니다.';
      }
      if (password.trim().length < 6) {
        return '비밀번호는 6자 이상으로 설정해주세요.';
      }

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

      // Firestore 쓰기는 기본 앱(메인 관리자) 인증으로 수행된다.
      await _firestore.collection('admins').doc(user.uid).set({
        'email': email.trim(),
        'name': name.trim(),
        'role': 'teacher',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await secondaryAuth.signOut();
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
        try {
          await secondaryApp.delete();
        } catch (_) {}
      }
    }
  }

  /// 강사 목록 (메인 관리자용).
  static Future<List<Map<String, dynamic>>> listTeachers() async {
    try {
      final snapshot = await _firestore
          .collection('admins')
          .where('role', isEqualTo: 'teacher')
          .get();

      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        data['uid'] = doc.id;
        return data;
      }).toList();

      list.sort((a, b) {
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

  static Future<String?> setTeacherActive(
      String teacherId, bool isActive) async {
    try {
      await _firestore.collection('admins').doc(teacherId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      print('강사 상태 변경 오류: $e');
      return '강사 상태 변경에 실패했습니다.';
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
      final adminDoc = await _firestore.collection('admins').doc(uid).get();
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
