import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  // 로그아웃
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      // SharedPreferences에서 로그인 상태 제거
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isAdminLoggedIn');
      await prefs.remove('adminEmail');
      await prefs.remove('adminName');
    } catch (e) {
      print('로그아웃 오류: $e');
    }
  }

  // 현재 사용자가 관리자인지 확인
  static Future<bool> isAdmin() async {
    try {
      // 먼저 SharedPreferences에서 로그인 상태 확인
      final prefs = await SharedPreferences.getInstance();
      bool isLoggedIn = prefs.getBool('isAdminLoggedIn') ?? false;

      if (isLoggedIn) {
        return true; // SharedPreferences에 관리자 로그인 상태가 저장되어 있으면 true
      }

      // Firebase Auth 확인
      User? user = currentUser;
      if (user == null) return false;

      // Firestore의 admins 컬렉션에서 현재 사용자 확인
      DocumentSnapshot adminDoc =
          await _firestore.collection('admins').doc(user.uid).get();

      if (adminDoc.exists) {
        Map<String, dynamic> data = adminDoc.data() as Map<String, dynamic>;
        return data['isActive'] ?? false;
      }

      // 백업: 특정 이메일로 관리자 권한 확인
      const List<String> adminEmails = [
        'admin@gleamisland.com',
        'namhee@gleamisland.com',
        // 필요에 따라 추가 관리자 이메일
      ];

      return adminEmails.contains(user.email);
    } catch (e) {
      print('관리자 권한 확인 오류: $e');
      return false;
    }
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
        // Firestore에 관리자 정보 저장
        await _firestore.collection('admins').doc(result.user!.uid).set({
          'email': email,
          'name': name,
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

  // 로그인된 사용자 이름 가져오기
  static Future<String> getAdminName() async {
    try {
      // 먼저 SharedPreferences에서 저장된 관리자 이름 확인
      final prefs = await SharedPreferences.getInstance();
      String? savedName = prefs.getString('adminName');
      if (savedName != null && savedName.isNotEmpty) {
        return savedName;
      }

      // SharedPreferences에 이메일이 저장되어 있으면 이를 반환
      String? savedEmail = prefs.getString('adminEmail');
      if (savedEmail != null && savedEmail.isNotEmpty) {
        return savedEmail;
      }

      // Firebase Auth 확인 (백업)
      User? user = currentUser;
      if (user == null) return '관리자';

      DocumentSnapshot adminDoc =
          await _firestore.collection('admins').doc(user.uid).get();

      if (adminDoc.exists) {
        Map<String, dynamic> data = adminDoc.data() as Map<String, dynamic>;
        String name = data['name'] ?? user.email ?? '관리자';
        // 가져온 이름을 SharedPreferences에 저장
        await prefs.setString('adminName', name);
        return name;
      }

      return user.email ?? '관리자';
    } catch (e) {
      print('관리자 이름 가져오기 오류: $e');
      // 오류 발생시 SharedPreferences에서 이메일이라도 반환
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('adminEmail') ?? '관리자';
    }
  }

  // 관리자 로그인 세션 저장 (WorkingAdminLoginPage에서 사용)
  static Future<void> saveAdminSession(String email, {String? name}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isAdminLoggedIn', true);
      await prefs.setString('adminEmail', email);
      if (name != null && name.isNotEmpty) {
        await prefs.setString('adminName', name);
      }
    } catch (e) {
      print('관리자 세션 저장 오류: $e');
    }
  }

  /// Firebase 로그인 후 Firestore admins 문서가 있도록 보장 (FAQ/공지 저장 권한용)
  static Future<bool> ensureAdminDoc(String email, String name) async {
    try {
      User? user = currentUser;
      if (user == null) return false;
      await _firestore.collection('admins').doc(user.uid).set({
        'email': email,
        'name': name,
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
