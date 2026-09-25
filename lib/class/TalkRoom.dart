enum TalkLevel {
  beginner,
  elementary,
  intermediate,
  advanced;

  String get id => name;

  String get label {
    switch (this) {
      case TalkLevel.beginner:
        return '왕초보';
      case TalkLevel.elementary:
        return '초급';
      case TalkLevel.intermediate:
        return '중급';
      case TalkLevel.advanced:
        return '고급';
    }
  }

  static TalkLevel fromId(String raw) {
    return TalkLevel.values.firstWhere(
      (item) => item.name == raw.trim(),
      orElse: () => TalkLevel.beginner,
    );
  }

  static const List<TalkLevel> all = TalkLevel.values;
}

enum TalkRoomType {
  group,
  oneToOne;

  String get id => name;

  String get label =>
      this == TalkRoomType.group ? 'Group Chat' : '1:1 Chat';

  String get koLabel =>
      this == TalkRoomType.group ? '그룹 채팅' : '1:1 대화방';

  static TalkRoomType fromId(String raw) {
    return raw.trim() == TalkRoomType.oneToOne.id
        ? TalkRoomType.oneToOne
        : TalkRoomType.group;
  }
}

class TalkRoom {
  final String id;
  final TalkRoomType type;
  final String topic;
  final TalkLevel level;
  final int maxPeople;
  final String hostId;
  final String hostName;
  final String hostPhotoUrl;
  final List<String> memberIds;
  final Map<String, String> memberNames;
  final Map<String, String> memberPhotos;
  final String meetingUrl;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TalkRoom({
    required this.id,
    required this.type,
    required this.topic,
    required this.level,
    required this.maxPeople,
    required this.hostId,
    required this.hostName,
    required this.hostPhotoUrl,
    required this.memberIds,
    required this.memberNames,
    required this.memberPhotos,
    required this.meetingUrl,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  bool get isGroup => type == TalkRoomType.group;
  bool get isOpen => status == 'open';
  bool get isFull => status == 'full' || memberIds.length >= maxPeople;
  bool get isClosed => status == 'closed';

  int get seatsLeft => (maxPeople - memberIds.length).clamp(0, maxPeople);

  String get seatsLabel => '${memberIds.length} / $maxPeople';

  String displayNameOf(String uid) {
    if (uid == hostId && hostName.trim().isNotEmpty) return hostName.trim();
    final name = memberNames[uid]?.trim() ?? '';
    if (name.isNotEmpty) return name;
    return 'Gleamer';
  }

  String photoUrlOf(String uid) {
    if (uid == hostId && hostPhotoUrl.trim().isNotEmpty) {
      return hostPhotoUrl.trim();
    }
    return memberPhotos[uid]?.trim() ?? '';
  }

  bool contains(String uid) => memberIds.contains(uid);

  TalkRoom copyWith({
    String? hostId,
    String? hostName,
    String? hostPhotoUrl,
    List<String>? memberIds,
    Map<String, String>? memberNames,
    Map<String, String>? memberPhotos,
    String? status,
    DateTime? updatedAt,
  }) {
    return TalkRoom(
      id: id,
      type: type,
      topic: topic,
      level: level,
      maxPeople: maxPeople,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      hostPhotoUrl: hostPhotoUrl ?? this.hostPhotoUrl,
      memberIds: memberIds ?? this.memberIds,
      memberNames: memberNames ?? this.memberNames,
      memberPhotos: memberPhotos ?? this.memberPhotos,
      meetingUrl: meetingUrl,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class TalkReport {
  final String id;
  final String reporterId;
  final String reporterName;
  final String targetId;
  final String targetName;
  final String reason;
  final String detail;
  final String lastTopic;
  final String status;
  final String source;
  final DateTime? createdAt;

  const TalkReport({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    required this.targetId,
    required this.targetName,
    required this.reason,
    required this.detail,
    required this.lastTopic,
    required this.status,
    this.source = 'user',
    this.createdAt,
  });

  bool get isPending => status != 'reviewed';
  bool get isAuto => source.startsWith('auto');
}

class TalkContact {
  final String id;
  final String otherUserId;
  final String name;
  final String photoUrl;
  final String lastTopic;
  final TalkLevel lastLevel;
  final TalkRoomType lastRoomType;
  final DateTime? lastTalkAt;

  const TalkContact({
    required this.id,
    required this.otherUserId,
    required this.name,
    required this.photoUrl,
    required this.lastTopic,
    required this.lastLevel,
    required this.lastRoomType,
    this.lastTalkAt,
  });
}
