import 'package:flutter_test/flutter_test.dart';
import 'package:gi_english_website/class/TalkCopy.dart';
import 'package:gi_english_website/class/TalkRoom.dart';
import 'package:gi_english_website/util/JitsiJoin.dart';
import 'package:gi_english_website/util/TalkSafety.dart';
import 'package:gi_english_website/util/TalkService.dart';

void main() {
  group('TalkLevel', () {
    test('uses the four casual labels', () {
      expect(TalkLevel.beginner.label, '왕초보');
      expect(TalkLevel.elementary.label, '초급');
      expect(TalkLevel.intermediate.label, '중급');
      expect(TalkLevel.advanced.label, '고급');
    });
  });

  group('TalkService helpers', () {
    test('orders contact ids so both members share one document', () {
      expect(TalkService.contactId('b', 'a'), TalkService.contactId('a', 'b'));
      expect(TalkService.contactId('z', 'a'), 'a_z');
    });

    test('clamps group size to 2–6', () {
      expect(TalkService.clampMaxPeople(1), 2);
      expect(TalkService.clampMaxPeople(4), 4);
      expect(TalkService.clampMaxPeople(9), 6);
    });

    test('rejects empty or too-long topics', () {
      expect(TalkService.validateTopic('  '), isNotNull);
      expect(TalkService.validateTopic('Free talk'), isNull);
      expect(TalkService.validateTopic('a' * 41), isNotNull);
    });

    test('builds a GleamTalk Jitsi url', () {
      expect(TalkService.roomUrl('abc'), 'https://meet.jit.si/GleamTalk-abc');
      expect(
        TalkService.joinUrl('abc', displayName: 'Sunny'),
        contains('GleamTalk-abc'),
      );
      expect(
        TalkService.joinUrl('abc', displayName: 'Sunny'),
        contains('userInfo.displayName'),
      );
      expect(
        TalkService.joinUrl('abc', asHost: true),
        contains('signin.html'),
      );
    });

    test('keeps directional block document ids', () {
      expect(TalkService.blockDocId('a', 'b'), 'a_b');
      expect(
        TalkService.blockDocId('a', 'b'),
        isNot(TalkService.blockDocId('b', 'a')),
      );
    });

    test('rejects empty or too-long messages', () {
      expect(TalkService.validateMessage('  '), isNotNull);
      expect(TalkService.validateMessage('Hi there'), isNull);
      expect(
        TalkService.validateMessage('a' * (TalkService.maxMessageLength + 1)),
        isNotNull,
      );
    });

    test('hides rooms that include a blocked peer', () {
      final room = TalkRoom(
        id: 'r1',
        type: TalkRoomType.group,
        topic: 'Free talk',
        level: TalkLevel.beginner,
        maxPeople: 4,
        hostId: 'host',
        hostName: 'Host',
        hostPhotoUrl: '',
        memberIds: const ['host', 'mean'],
        memberNames: const {},
        memberPhotos: const {},
        meetingUrl: TalkService.roomUrl('r1'),
        status: 'open',
      );
      expect(
        TalkService.roomHasHiddenPeer(room, 'me', {'mean'}),
        isTrue,
      );
      expect(
        TalkService.roomHasHiddenPeer(room, 'me', {'other'}),
        isFalse,
      );
    });
  });

  group('TalkRoom join rules', () {
    TalkRoom room({
      List<String> members = const ['host'],
      int max = 4,
      String status = 'open',
    }) {
      return TalkRoom(
        id: 'r1',
        type: TalkRoomType.group,
        topic: 'Free talk',
        level: TalkLevel.beginner,
        maxPeople: max,
        hostId: 'host',
        hostName: 'Host',
        hostPhotoUrl: '',
        memberIds: members,
        memberNames: const {},
        memberPhotos: const {},
        meetingUrl: TalkService.roomUrl('r1'),
        status: status,
      );
    }

    test('lets a new member join an open seat', () {
      expect(TalkService.canJoin(room(), 'guest'), isTrue);
    });

    test('lets an existing member re-enter even when full', () {
      expect(
        TalkService.canJoin(
          room(members: ['host', 'a'], max: 2, status: 'full'),
          'a',
        ),
        isTrue,
      );
    });

    test('blocks outsiders when the room is full', () {
      expect(
        TalkService.canJoin(
          room(members: ['host', 'a'], max: 2, status: 'full'),
          'guest',
        ),
        isFalse,
      );
    });
  });

  group('TalkCopy', () {
    test('keeps the cafe hero copy', () {
      expect(TalkCopy.headline, "Let's talk!");
      expect(TalkCopy.lead, contains('GLEAMER'));
      expect(TalkCopy.ruleTitle, contains('영어로 대화해보기'));
      expect(TalkCopy.groupTitle, '그룹 채팅');
      expect(TalkCopy.oneToOneTitle, '1:1 대화방');
      expect(TalkCopy.contactsTitle, '내가 대화한 회원');
      expect(TalkCopy.leaveHint, contains('나가기'));
      expect(TalkCopy.safetyTitle, contains('존중'));
    });
  });

  group('TalkService freshness', () {
    TalkRoom room({
      List<String> members = const ['host'],
      String status = 'open',
      DateTime? createdAt,
      DateTime? updatedAt,
    }) {
      return TalkRoom(
        id: 'r1',
        type: TalkRoomType.group,
        topic: 'Free talk',
        level: TalkLevel.beginner,
        maxPeople: 4,
        hostId: 'host',
        hostName: 'Host',
        hostPhotoUrl: '',
        memberIds: members,
        memberNames: const {},
        memberPhotos: const {},
        meetingUrl: TalkService.roomUrl('r1'),
        status: status,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    }

    final now = DateTime(2026, 9, 21, 19, 0);

    test('hides closed rooms immediately', () {
      expect(
        TalkService.isFresh(room(status: 'closed', createdAt: now), now: now),
        isFalse,
      );
    });

    test('drops a solo waiting room after 20 minutes', () {
      expect(
        TalkService.isFresh(
          room(createdAt: now.subtract(const Duration(minutes: 19))),
          now: now,
        ),
        isTrue,
      );
      expect(
        TalkService.isFresh(
          room(createdAt: now.subtract(const Duration(minutes: 21))),
          now: now,
        ),
        isFalse,
      );
    });

    test('uses the last leave time for a solo waiting room', () {
      expect(
        TalkService.isFresh(
          room(
            createdAt: now.subtract(const Duration(hours: 2)),
            updatedAt: now.subtract(const Duration(minutes: 5)),
          ),
          now: now,
        ),
        isTrue,
      );
    });

    test('keeps occupied rooms for 12 hours from create time', () {
      expect(
        TalkService.isFresh(
          room(
            members: const ['host', 'guest'],
            createdAt: now.subtract(const Duration(hours: 11)),
          ),
          now: now,
        ),
        isTrue,
      );
      expect(
        TalkService.isFresh(
          room(
            members: const ['host', 'guest'],
            createdAt: now.subtract(const Duration(hours: 13)),
          ),
          now: now,
        ),
        isFalse,
      );
    });
  });

  group('JitsiJoin', () {
    test('sends the room opener through Jitsi Google sign-in', () {
      final url = JitsiJoin.hostUrl('https://meet.jit.si/GleamTalk-abc');
      expect(url, contains('signin.html'));
      expect(url, contains('GleamTalk-abc'));
      expect(url, contains('prejoinConfig.enabled'));
    });

    test('lets guests skip the prejoin screen with a display name', () {
      final url = JitsiJoin.guestUrl(
        'https://meet.jit.si/GleamIsland-c1-b1',
        displayName: 'Mina',
      );
      expect(url, contains('GleamIsland-c1-b1#'));
      expect(url, contains('prejoinConfig.enabled=false'));
      expect(url, contains('Mina'));
    });

    test('leaves Zoom and Google Meet links unchanged', () {
      expect(
        JitsiJoin.prepare('https://zoom.us/j/123', asHost: true),
        'https://zoom.us/j/123',
      );
    });
  });

  group('TalkSafety', () {
    test('lets a normal cafe message through', () {
      expect(TalkSafety.scan('How was your weekend?'), isNull);
      expect(TalkSafety.scan('오늘 날씨 좋네요'), isNull);
    });

    test('blocks swearing even with spaces', () {
      expect(TalkSafety.scan('f u c k this'), isNotNull);
      expect(TalkSafety.scan('시 발'), isNotNull);
    });

    test('blocks sexual content', () {
      expect(TalkSafety.scan('onlyfans'), isNotNull);
      expect(TalkSafety.scan('야동 볼래'), isNotNull);
    });
  });
}
