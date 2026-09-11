import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// 온라인 화상수업용 원어민 강사.
/// 수강생이 고르는 프로필은 Firestore `native_teacher_accounts`에 저장하고,
/// 아래 더미 목록은 사진/소개가 없을 때의 기본값으로만 쓴다.
class OnlineNativeTeacher {
  final String id;
  final String name;
  final String nationality;
  final String intro;
  final String imageAsset;
  final String photoUrl;

  /// 메인 관리자가 연결한 실제 강사 계정(admins uid). 없으면 빈 문자열.
  final String accountUid;

  const OnlineNativeTeacher({
    required this.id,
    required this.name,
    required this.nationality,
    required this.intro,
    required this.imageAsset,
    this.photoUrl = '',
    this.accountUid = '',
  });

  static const String ownerProfileId = 'native_owner_gi';
  static const String fallbackAsset = 'assets/nativeTeacherPortrait.png';

  static final Map<String, OnlineNativeTeacher> _cache = {};

  static const List<OnlineNativeTeacher> all = [
    OnlineNativeTeacher(
      id: ownerProfileId,
      name: 'Namhee Kim',
      nationality: 'Korea',
      intro: '글림아일랜드 원장. 화상수업 스케줄을 관리하고 예약을 확인합니다.',
      imageAsset: 'assets/directorPhoto.jpeg',
    ),
    OnlineNativeTeacher(
      id: 'native_temp_emma',
      name: 'Emma',
      nationality: 'USA',
      intro: '밝은 톤으로 기초·중급 회화를 이끌어 주는 선생님입니다.',
      imageAsset: 'assets/nativeTeacher01.png',
    ),
    OnlineNativeTeacher(
      id: 'native_temp_james',
      name: 'James',
      nationality: 'Canada',
      intro: '문법 설명과 실전 대화를 균형 있게 진행합니다.',
      imageAsset: 'assets/nativeTeacher02.png',
    ),
    OnlineNativeTeacher(
      id: 'native_temp_sophie',
      name: 'Sophie',
      nationality: 'UK',
      intro: '비즈니스·격식 표현을 차분하게 코칭합니다.',
      imageAsset: 'assets/nativeTeacher03.png',
    ),
    OnlineNativeTeacher(
      id: 'native_temp_daniel',
      name: 'Daniel',
      nationality: 'USA',
      intro: '시사·토론 주제로 자연스러운 고급 회화를 연습합니다.',
      imageAsset: 'assets/nativeTeacher04.png',
    ),
  ];

  String get displayLabel {
    if (nationality.trim().isEmpty) return name;
    return '$name ($nationality)';
  }

  bool get hasAccount => accountUid.isNotEmpty;

  String get resolvedAsset =>
      imageAsset.isNotEmpty ? imageAsset : fallbackAsset;

  OnlineNativeTeacher withAccount(String uid) {
    return copyWith(accountUid: uid);
  }

  OnlineNativeTeacher copyWith({
    String? name,
    String? nationality,
    String? intro,
    String? imageAsset,
    String? photoUrl,
    String? accountUid,
  }) {
    return OnlineNativeTeacher(
      id: id,
      name: name ?? this.name,
      nationality: nationality ?? this.nationality,
      intro: intro ?? this.intro,
      imageAsset: imageAsset ?? this.imageAsset,
      photoUrl: photoUrl ?? this.photoUrl,
      accountUid: accountUid ?? this.accountUid,
    );
  }

  Widget photo({
    double width = 88,
    double height = 88,
    BoxFit fit = BoxFit.cover,
  }) {
    final provider = imageProviderOf(photoUrl);
    final fallback = Image.asset(
      resolvedAsset,
      width: width,
      height: height,
      fit: fit,
    );
    if (provider != null) {
      return Image(
        image: provider,
        width: width,
        height: height,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => fallback,
      );
    }
    return fallback;
  }

  Widget photoFill({BoxFit fit = BoxFit.cover}) {
    final provider = imageProviderOf(photoUrl);
    final fallback = Image.asset(resolvedAsset, fit: fit);
    final image = provider == null
        ? fallback
        : Image(
            image: provider,
            fit: fit,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => fallback,
          );
    return SizedBox.expand(child: image);
  }

  static ImageProvider? imageProviderOf(String url, [Uint8List? bytes]) {
    if (bytes != null && bytes.isNotEmpty) return MemoryImage(bytes);
    final value = url.trim();
    if (value.startsWith('data:image')) {
      final comma = value.indexOf(',');
      if (comma > 0) {
        try {
          return MemoryImage(base64Decode(value.substring(comma + 1)));
        } catch (_) {}
      }
    }
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return NetworkImage(value);
    }
    return null;
  }

  static void cacheAll(Iterable<OnlineNativeTeacher> teachers) {
    for (final teacher in teachers) {
      _cache[teacher.id] = teacher;
      if (teacher.accountUid.isNotEmpty) {
        _cache[teacher.accountUid] = teacher;
      }
    }
  }

  static bool isDummyProfile(String id) => id.startsWith('native_temp_');

  static OnlineNativeTeacher? dummyById(String id) {
    if (id.isEmpty) return null;
    for (final teacher in all) {
      if (teacher.id == id) return teacher;
    }
    return null;
  }

  static OnlineNativeTeacher? findById(String id) {
    if (id.isEmpty) return null;
    final cached = _cache[id];
    if (cached != null) return cached;
    for (final teacher in _cache.values) {
      if (teacher.id == id || teacher.accountUid == id) return teacher;
    }
    return dummyById(id);
  }

  /// 수강생 화면에 보여줄 실제 배정 강사. Emma/James 더미 사진은 쓰지 않는다.
  static OnlineNativeTeacher? findAssigned({
    String profileId = '',
    String accountUid = '',
  }) {
    if (accountUid.isNotEmpty) {
      final byUid = findById(accountUid);
      if (byUid != null && !isDummyProfile(byUid.id)) return byUid;
    }
    if (profileId.isNotEmpty && !isDummyProfile(profileId)) {
      final byProfile = findById(profileId);
      if (byProfile != null && !isDummyProfile(byProfile.id)) return byProfile;
    }
    return null;
  }

  static String profileIdFor({
    required String uid,
    required bool isOwner,
    String existing = '',
  }) {
    if (existing.isNotEmpty) return existing;
    if (isOwner) return ownerProfileId;
    return 'native_$uid';
  }

  factory OnlineNativeTeacher.fromAccountDoc(
    String id,
    Map<String, dynamic> data,
  ) {
    final dummy = dummyById(id);
    final name = (data['name'] ?? dummy?.name ?? '').toString().trim();
    final nationality =
        (data['nationality'] ?? dummy?.nationality ?? '').toString().trim();
    final intro = (data['intro'] ?? dummy?.intro ?? '').toString().trim();
    final photoUrl = (data['photoUrl'] ?? '').toString().trim();
    var accountUid = (data['teacherUid'] ?? '').toString().trim();
    if (accountUid.isEmpty && id.startsWith('native_') && id != ownerProfileId) {
      accountUid = id.substring('native_'.length);
    }
    return OnlineNativeTeacher(
      id: id,
      name: name.isEmpty ? (dummy?.name ?? '') : name,
      nationality: nationality,
      intro: intro,
      imageAsset: dummy?.imageAsset ?? fallbackAsset,
      photoUrl: photoUrl,
      accountUid: accountUid,
    );
  }
}
