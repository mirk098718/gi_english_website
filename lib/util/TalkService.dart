import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gi_english_website/class/TalkRoom.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/NotificationService.dart';
import 'package:gi_english_website/util/JitsiJoin.dart';
import 'package:gi_english_website/util/TalkSafety.dart';

class TalkException implements Exception {
  final String message;
  TalkException(this.message);

  @override
  String toString() => message;
}

enum TalkLeaveResult { closed, transferred, left }

class TalkService {
  static const String jitsiBaseUrl = 'https://meet.jit.si';
  static const int minPeople = 2;
  static const int maxPeople = 6;
  static const int maxTopicLength = 40;
  static const int maxMessageLength = 200;
  static const int maxReportDetailLength = 300;
  static const Duration roomTtl = Duration(hours: 12);
  static const Duration waitingTtl = Duration(minutes: 20);
  static const List<String> reportReasons = [
    '불쾌한 대화',
    '욕설 · 괴롭힘',
    '부적절한 행동',
    '기타',
  ];

  static const List<String> topicSuggestions = [
    'Free talk',
    'Daily life',
    'Hobbies',
    'Movies & music',
    'Travel',
    'Food',
    'Weekend plans',
    'Work & school',
  ];

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static String contactId(String a, String b) {
    final ids = [a, b]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  static String blockDocId(String blockerId, String blockedId) =>
      '${blockerId}_$blockedId';

  static String? validateMessage(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return '메시지를 적어 주세요.';
    if (text.length > maxMessageLength) {
      return '메시지는 $maxMessageLength자 이하로 적어 주세요.';
    }
    return null;
  }

  static bool roomHasHiddenPeer(
    TalkRoom room,
    String uid,
    Set<String> hiddenPeerIds,
  ) {
    return room.memberIds.any(
      (id) => id != uid && hiddenPeerIds.contains(id),
    );
  }

  static int clampMaxPeople(int value) {
    if (value < minPeople) return minPeople;
    if (value > maxPeople) return maxPeople;
    return value;
  }

  static String? validateTopic(String raw) {
    final topic = raw.trim();
    if (topic.isEmpty) return '주제를 정해주세요.';
    if (topic.length > maxTopicLength) {
      return '주제는 $maxTopicLength자 이하로 적어주세요.';
    }
    return null;
  }

  static String roomUrl(String roomId) => '$jitsiBaseUrl/GleamTalk-$roomId';

  static String joinUrl(
    String roomId, {
    String displayName = '',
    bool asHost = false,
  }) {
    return JitsiJoin.prepare(
      roomUrl(roomId),
      asHost: asHost,
      displayName: displayName,
    );
  }

  static bool canJoin(TalkRoom room, String uid) {
    if (uid.isEmpty) return false;
    if (room.contains(uid)) return true;
    return room.isOpen && !room.isFull;
  }

  static bool isFresh(TalkRoom room, {DateTime? now}) {
    if (room.isClosed) return false;
    final clock = now ?? DateTime.now();
    if (room.memberIds.length <= 1) {
      final anchor = room.updatedAt ?? room.createdAt;
      if (anchor == null) return true;
      return clock.difference(anchor) <= waitingTtl;
    }
    final createdAt = room.createdAt;
    if (createdAt == null) return true;
    return clock.difference(createdAt) <= roomTtl;
  }

  static Future<TalkRoom> createRoom({
    required TalkRoomType type,
    required String topic,
    required TalkLevel level,
    int maxPeople = TalkService.maxPeople,
  }) async {
    final profile = await _myProfile();
    final topicError = validateTopic(topic);
    if (topicError != null) throw TalkException(topicError);

    final seats = type == TalkRoomType.oneToOne
        ? 2
        : clampMaxPeople(maxPeople);
    final ref = _firestore.collection('talk_rooms').doc();
    final room = TalkRoom(
      id: ref.id,
      type: type,
      topic: topic.trim(),
      level: level,
      maxPeople: seats,
      hostId: profile.uid,
      hostName: profile.name,
      hostPhotoUrl: profile.photoUrl,
      memberIds: [profile.uid],
      memberNames: {profile.uid: profile.name},
      memberPhotos: {profile.uid: profile.photoUrl},
      meetingUrl: roomUrl(ref.id),
      status: 'open',
    );

    await ref.set({
      'type': room.type.id,
      'topic': room.topic,
      'level': room.level.id,
      'maxPeople': room.maxPeople,
      'hostId': room.hostId,
      'hostName': room.hostName,
      'hostPhotoUrl': room.hostPhotoUrl,
      'memberIds': room.memberIds,
      'memberNames': room.memberNames,
      'memberPhotos': room.memberPhotos,
      'meetingUrl': room.meetingUrl,
      'status': room.status,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await JitsiJoin.open(
      room.meetingUrl,
      asHost: true,
      displayName: profile.name,
    );
    return room;
  }

  static Future<TalkRoom> joinRoom(String roomId) async {
    final profile = await _myProfile();
    final ref = _firestore.collection('talk_rooms').doc(roomId);
    late TalkRoom joined;
    final others = <String>[];

    final preview = await ref.get();
    if (!preview.exists) {
      throw TalkException('방을 찾을 수 없어요.');
    }
    final previewRoom = _roomFrom(preview);
    if (!previewRoom.contains(profile.uid) &&
        await _hasBlockWithAny(profile.uid, previewRoom.memberIds)) {
      throw TalkException('차단한 상대와는 같은 방에 들어갈 수 없어요.');
    }

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) {
        throw TalkException('방을 찾을 수 없어요.');
      }
      final room = _roomFrom(snap);
      if (!isFresh(room)) {
        throw TalkException('이미 끝난 방이에요.');
      }
      if (room.contains(profile.uid)) {
        joined = room;
        return;
      }
      if (!room.isOpen || room.isFull) {
        throw TalkException('이미 가득 찬 방이에요.');
      }
      others.addAll(room.memberIds);
      final ids = [...room.memberIds, profile.uid];
      final names = {...room.memberNames, profile.uid: profile.name};
      final photos = {...room.memberPhotos, profile.uid: profile.photoUrl};
      final status = ids.length >= room.maxPeople ? 'full' : 'open';
      tx.update(ref, {
        'memberIds': ids,
        'memberNames': names,
        'memberPhotos': photos,
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      joined = room.copyWith(
        memberIds: ids,
        memberNames: names,
        memberPhotos: photos,
        status: status,
      );
    });

    if (others.isNotEmpty) {
      await _recordContacts(
        room: joined,
        myId: profile.uid,
        myName: profile.name,
        myPhotoUrl: profile.photoUrl,
        otherIds: others,
      );
    }

    await JitsiJoin.open(
      joined.meetingUrl,
      asHost: joined.hostId == profile.uid,
      displayName: profile.name,
    );
    return joined;
  }

  static Future<TalkLeaveResult> leaveRoom(String roomId) async {
    final uid = AuthService.currentUser?.uid ?? '';
    if (uid.isEmpty) throw TalkException('로그인 후 이용할 수 있어요.');
    final ref = _firestore.collection('talk_rooms').doc(roomId);
    late TalkLeaveResult result;

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) {
        throw TalkException('방을 찾을 수 없어요.');
      }
      final room = _roomFrom(snap);
      if (room.isClosed) {
        result = TalkLeaveResult.closed;
        return;
      }
      if (!room.contains(uid)) {
        throw TalkException('이 방에 들어가 있지 않아요.');
      }

      final remaining = room.memberIds.where((id) => id != uid).toList();
      if (remaining.isEmpty) {
        tx.update(ref, {
          'status': 'closed',
          'memberIds': remaining,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        result = TalkLeaveResult.closed;
        return;
      }

      final payload = <String, dynamic>{
        'memberIds': remaining,
        'status': remaining.length >= room.maxPeople ? 'full' : 'open',
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (room.hostId == uid) {
        final nextId = remaining.first;
        payload['hostId'] = nextId;
        payload['hostName'] = room.displayNameOf(nextId);
        payload['hostPhotoUrl'] = room.photoUrlOf(nextId);
        result = TalkLeaveResult.transferred;
      } else {
        result = TalkLeaveResult.left;
      }
      tx.update(ref, payload);
    });

    return result;
  }

  static Future<void> closeRoom(String roomId) async {
    final uid = AuthService.currentUser?.uid ?? '';
    if (uid.isEmpty) throw TalkException('로그인 후 이용할 수 있어요.');
    final ref = _firestore.collection('talk_rooms').doc(roomId);
    final snap = await ref.get();
    if (!snap.exists) throw TalkException('방을 찾을 수 없어요.');
    final room = _roomFrom(snap);
    if (room.hostId != uid) {
      throw TalkException('방을 만든 사람만 닫을 수 있어요.');
    }
    await ref.update({
      'status': 'closed',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<List<TalkRoom>> watchRooms() {
    return _firestore
        .collection('talk_rooms')
        .where('status', whereIn: ['open', 'full'])
        .snapshots()
        .map((snap) {
          final rooms = snap.docs
              .map(_roomFrom)
              .where((room) => isFresh(room))
              .toList();
          rooms.sort((a, b) {
            final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });
          return rooms;
        });
  }

  static Stream<List<TalkContact>> watchContacts() {
    final uid = AuthService.currentUser?.uid ?? '';
    if (uid.isEmpty) return Stream.value(const []);
    return _firestore
        .collection('talk_contacts')
        .where('userIds', arrayContains: uid)
        .snapshots()
        .map((snap) {
          final contacts = snap.docs
              .map((doc) => _contactFrom(doc, uid))
              .whereType<TalkContact>()
              .toList();
          contacts.sort((a, b) {
            final aTime = a.lastTalkAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime = b.lastTalkAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });
          return contacts;
        });
  }

  static Stream<Set<String>> watchMyBlockIds() {
    final uid = AuthService.currentUser?.uid ?? '';
    if (uid.isEmpty) return Stream.value(const {});
    return _firestore
        .collection('talk_blocks')
        .where('blockerId', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => doc.data()['blockedId']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toSet());
  }

  static Stream<Set<String>> watchHiddenPeerIds() {
    final uid = AuthService.currentUser?.uid ?? '';
    if (uid.isEmpty) return Stream.value(const {});
    final controller = StreamController<Set<String>>();
    var mine = <String>{};
    var theirs = <String>{};
    void emit() {
      if (!controller.isClosed) controller.add({...mine, ...theirs});
    }

    final a = _firestore
        .collection('talk_blocks')
        .where('blockerId', isEqualTo: uid)
        .snapshots()
        .listen((snap) {
      mine = snap.docs
          .map((doc) => doc.data()['blockedId']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
      emit();
    }, onError: controller.addError);
    final b = _firestore
        .collection('talk_blocks')
        .where('blockedId', isEqualTo: uid)
        .snapshots()
        .listen((snap) {
      theirs = snap.docs
          .map((doc) => doc.data()['blockerId']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
      emit();
    }, onError: controller.addError);
    controller.onCancel = () {
      a.cancel();
      b.cancel();
    };
    return controller.stream;
  }

  static Stream<List<TalkReport>> watchReports() {
    return _firestore.collection('talk_reports').snapshots().map((snap) {
      final reports = snap.docs.map(_reportFrom).toList();
      reports.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return reports;
    });
  }

  static Future<void> blockUser(TalkContact contact) async {
    final profile = await _myProfile();
    if (contact.otherUserId.isEmpty || contact.otherUserId == profile.uid) {
      throw TalkException('이 회원은 차단할 수 없어요.');
    }
    await _firestore
        .collection('talk_blocks')
        .doc(blockDocId(profile.uid, contact.otherUserId))
        .set({
      'blockerId': profile.uid,
      'blockedId': contact.otherUserId,
      'blockedName': contact.name,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> unblockUser(String otherUserId) async {
    final uid = AuthService.currentUser?.uid ?? '';
    if (uid.isEmpty || otherUserId.isEmpty) return;
    await _firestore
        .collection('talk_blocks')
        .doc(blockDocId(uid, otherUserId))
        .delete();
  }

  static Future<void> sendMessage({
    required TalkContact contact,
    required String text,
  }) async {
    final profile = await _myProfile();
    final error = validateMessage(text);
    if (error != null) throw TalkException(error);
    if (contact.otherUserId.isEmpty || contact.otherUserId == profile.uid) {
      throw TalkException('메시지를 보낼 수 없는 상대예요.');
    }
    if (await _hasBlockWithAny(profile.uid, [contact.otherUserId])) {
      throw TalkException('차단된 상대에게는 메시지를 보낼 수 없어요.');
    }
    final hit = TalkSafety.scan(text);
    if (hit != null) {
      await _flagBlockedMessage(
        profile: profile,
        contact: contact,
        kind: hit.kind,
        text: text,
      );
      throw TalkException(hit.userMessage);
    }
    final sent = await NotificationService.notifyUser(
      userId: contact.otherUserId,
      title: "Let's Talk 메시지",
      body: '${profile.name}: ${text.trim()}',
      type: 'talk_message',
      senderId: profile.uid,
    );
    if (!sent) {
      throw TalkException('메시지를 보내지 못했어요. 잠시 후 다시 시도해 주세요.');
    }
  }

  static Future<void> reportUser({
    required TalkContact contact,
    required String reason,
    String detail = '',
  }) {
    return reportPeer(
      targetId: contact.otherUserId,
      targetName: contact.name,
      reason: reason,
      detail: detail,
      lastTopic: contact.lastTopic,
    );
  }

  static Future<void> reportPeer({
    required String targetId,
    required String targetName,
    required String reason,
    String detail = '',
    String lastTopic = '',
    String source = 'user',
  }) async {
    final profile = await _myProfile();
    final picked = reason.trim();
    if (picked.isEmpty) throw TalkException('신고 사유를 선택해 주세요.');
    final note = detail.trim();
    if (note.length > maxReportDetailLength) {
      throw TalkException('자세한 내용은 $maxReportDetailLength자 이하로 적어 주세요.');
    }
    if (targetId.isEmpty || targetId == profile.uid) {
      throw TalkException('이 회원은 신고할 수 없어요.');
    }
    await _firestore.collection('talk_reports').add({
      'reporterId': profile.uid,
      'reporterName': profile.name,
      'targetId': targetId,
      'targetName': targetName.trim().isEmpty ? 'Gleamer' : targetName.trim(),
      'reason': picked,
      'detail': note,
      'lastTopic': lastTopic.trim(),
      'source': source.trim().isEmpty ? 'user' : source.trim(),
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> _flagBlockedMessage({
    required _TalkProfile profile,
    required TalkContact contact,
    required String kind,
    required String text,
  }) async {
    try {
      final snippet = text.trim();
      final clipped = snippet.length > 80
          ? '${snippet.substring(0, 80)}…'
          : snippet;
      await _firestore.collection('talk_reports').add({
        'reporterId': profile.uid,
        'reporterName': profile.name,
        'targetId': contact.otherUserId,
        'targetName': contact.name,
        'reason': kind == 'sexual' ? '자동 필터 · 성적 내용' : '자동 필터 · 욕설',
        'detail': '전송이 차단된 메시지: $clipped',
        'lastTopic': contact.lastTopic,
        'source': 'auto_message',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  static Future<void> markReportReviewed(String reportId) async {
    if (reportId.isEmpty) return;
    await _firestore.collection('talk_reports').doc(reportId).update({
      'status': 'reviewed',
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewerId': AuthService.currentUser?.uid ?? '',
    });
  }

  static Future<bool> _hasBlockWithAny(String uid, List<String> otherIds) async {
    for (final otherId in otherIds) {
      if (otherId.isEmpty || otherId == uid) continue;
      final mine = await _firestore
          .collection('talk_blocks')
          .doc(blockDocId(uid, otherId))
          .get();
      if (mine.exists) return true;
      final theirs = await _firestore
          .collection('talk_blocks')
          .doc(blockDocId(otherId, uid))
          .get();
      if (theirs.exists) return true;
    }
    return false;
  }

  static Future<_TalkProfile> _myProfile() async {
    final user = AuthService.currentUser;
    if (user == null) {
      throw TalkException('로그인 후 Cafe에 들어올 수 있어요.');
    }
    final member = await AuthService.currentMemberDoc();
    final name = AuthService.profileDisplayName(
      member,
      fallback: user.email ?? 'Gleamer',
    );
    return _TalkProfile(
      uid: user.uid,
      name: name.trim().isEmpty ? 'Gleamer' : name.trim(),
      photoUrl: AuthService.profilePhotoUrl(member),
    );
  }

  static Future<void> _recordContacts({
    required TalkRoom room,
    required String myId,
    required String myName,
    required String myPhotoUrl,
    required List<String> otherIds,
  }) async {
    final batch = _firestore.batch();
    for (final otherId in otherIds) {
      if (otherId == myId || otherId.isEmpty) continue;
      final id = contactId(myId, otherId);
      batch.set(
        _firestore.collection('talk_contacts').doc(id),
        {
          'userIds': [myId, otherId]..sort(),
          'profiles': {
            myId: {'name': myName, 'photoUrl': myPhotoUrl},
            otherId: {
              'name': room.displayNameOf(otherId),
              'photoUrl': room.photoUrlOf(otherId),
            },
          },
          'lastTopic': room.topic,
          'lastLevel': room.level.id,
          'lastRoomType': room.type.id,
          'lastRoomId': room.id,
          'lastTalkAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  static TalkRoom _roomFrom(DocumentSnapshot doc) {
    final raw = doc.data();
    final data = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
    return TalkRoom(
      id: doc.id,
      type: TalkRoomType.fromId(data['type']?.toString() ?? ''),
      topic: data['topic']?.toString() ?? '',
      level: TalkLevel.fromId(data['level']?.toString() ?? ''),
      maxPeople: clampMaxPeople(
        int.tryParse(data['maxPeople']?.toString() ?? '') ?? maxPeople,
      ),
      hostId: data['hostId']?.toString() ?? '',
      hostName: data['hostName']?.toString() ?? '',
      hostPhotoUrl: data['hostPhotoUrl']?.toString() ?? '',
      memberIds: _stringList(data['memberIds']),
      memberNames: _stringMap(data['memberNames']),
      memberPhotos: _stringMap(data['memberPhotos']),
      meetingUrl: data['meetingUrl']?.toString() ?? roomUrl(doc.id),
      status: data['status']?.toString() ?? 'open',
      createdAt: _date(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
    );
  }

  static TalkContact? _contactFrom(DocumentSnapshot doc, String myId) {
    final raw = doc.data();
    final data = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
    final userIds = _stringList(data['userIds']);
    final otherId = userIds.firstWhere(
      (id) => id != myId,
      orElse: () => '',
    );
    if (otherId.isEmpty) return null;
    final profiles = data['profiles'];
    Map<String, dynamic> profile = const {};
    if (profiles is Map && profiles[otherId] is Map) {
      profile = Map<String, dynamic>.from(profiles[otherId] as Map);
    }
    return TalkContact(
      id: doc.id,
      otherUserId: otherId,
      name: profile['name']?.toString().trim().isNotEmpty == true
          ? profile['name'].toString().trim()
          : 'Gleamer',
      photoUrl: profile['photoUrl']?.toString() ?? '',
      lastTopic: data['lastTopic']?.toString() ?? '',
      lastLevel: TalkLevel.fromId(data['lastLevel']?.toString() ?? ''),
      lastRoomType: TalkRoomType.fromId(data['lastRoomType']?.toString() ?? ''),
      lastTalkAt: _date(data['lastTalkAt']),
    );
  }

  static TalkReport _reportFrom(DocumentSnapshot doc) {
    final raw = doc.data();
    final data = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
    return TalkReport(
      id: doc.id,
      reporterId: data['reporterId']?.toString() ?? '',
      reporterName: data['reporterName']?.toString() ?? '',
      targetId: data['targetId']?.toString() ?? '',
      targetName: data['targetName']?.toString() ?? '',
      reason: data['reason']?.toString() ?? '',
      detail: data['detail']?.toString() ?? '',
      lastTopic: data['lastTopic']?.toString() ?? '',
      status: data['status']?.toString() ?? 'pending',
      source: data['source']?.toString() ?? 'user',
      createdAt: _date(data['createdAt']),
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value.map((item) => item.toString()).toList();
  }

  static Map<String, String> _stringMap(dynamic value) {
    if (value is! Map) return const {};
    return value.map(
      (key, item) => MapEntry(key.toString(), item?.toString() ?? ''),
    );
  }

  static DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

class _TalkProfile {
  final String uid;
  final String name;
  final String photoUrl;

  const _TalkProfile({
    required this.uid,
    required this.name,
    required this.photoUrl,
  });
}
