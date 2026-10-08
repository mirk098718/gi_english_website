import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gi_english_website/class/TalkCopy.dart';
import 'package:gi_english_website/class/TalkRoom.dart';
import 'package:gi_english_website/pages/MemberLoginPage.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/TalkService.dart';
import 'package:gi_english_website/widget/MobileSchoolLayout.dart';
import 'package:gi_english_website/widget/ProfileAvatar.dart';
import 'package:gi_english_website/widget/WebSchoolLayout.dart';

class SchoolLetsTalkPage extends StatefulWidget {
  const SchoolLetsTalkPage({Key? key}) : super(key: key);

  @override
  State<SchoolLetsTalkPage> createState() => _SchoolLetsTalkPageState();
}

class _SchoolLetsTalkPageState extends State<SchoolLetsTalkPage> {
  final _auth = AuthService.authStateChanges;
  String? _busyRoomId;

  bool get _loggedIn => AuthService.currentUser != null;

  Future<bool> _requireLogin() async {
    if (_loggedIn) return true;
    MenuUtil.push(context, const MemberLoginPage());
    return false;
  }

  Future<void> _createRoom(TalkRoomType type) async {
    if (!await _requireLogin()) return;
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => _CreateTalkRoomDialog(
        type: type,
        onCreated: () {
          if (!mounted) return;
          ScaffoldMessenger.of(this.context).showSnackBar(
            SnackBar(
              content: Text(
                'Jitsi 대화방이 열렸어요. Speak English here!',
                style: TextStyle(fontFamily: 'NotoSansKR'),
              ),
              backgroundColor: Palette.talkCoralDark,
            ),
          );
        },
      ),
    );
  }

  Future<void> _join(TalkRoom room) async {
    if (!await _requireLogin()) return;
    setState(() => _busyRoomId = room.id);
    try {
      await TalkService.joinRoom(room.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
            style: TextStyle(fontFamily: 'NotoSansKR'),
          ),
          backgroundColor: Palette.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _busyRoomId = null);
    }
  }

  Future<void> _leave(TalkRoom room) async {
    final uid = AuthService.currentUser?.uid ?? '';
    final peers = room.memberIds.where((id) => id != uid).toList();
    setState(() => _busyRoomId = room.id);
    try {
      final result = await TalkService.leaveRoom(room.id);
      if (!mounted) return;
      String message;
      switch (result) {
        case TalkLeaveResult.closed:
          message = '방을 닫았어요.';
          break;
        case TalkLeaveResult.transferred:
          message = '방장을 넘기고 나갔어요.';
          break;
        case TalkLeaveResult.left:
          message = '방에서 나갔어요.';
          break;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(fontFamily: 'NotoSansKR'),
          ),
          backgroundColor: Palette.talkCoralDark,
        ),
      );
      if (peers.isNotEmpty) {
        await _offerSafetyCheck(room);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
            style: TextStyle(fontFamily: 'NotoSansKR'),
          ),
          backgroundColor: Palette.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _busyRoomId = null);
    }
  }

  Future<void> _message(TalkContact contact) async {
    final sent = await showDialog<bool>(
      context: context,
      builder: (context) => _TalkMessageDialog(contact: contact),
    );
    if (!mounted || sent != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${contact.name}님에게 메시지를 보냈어요. 상대 화면 오른쪽 위 알림에도 뜹니다.',
          style: TextStyle(fontFamily: 'NotoSansKR'),
        ),
        backgroundColor: Palette.talkCoralDark,
      ),
    );
  }

  Future<void> _toggleBlock(TalkContact contact, {required bool blocked}) async {
    if (blocked) {
      await TalkService.unblockUser(contact.otherUserId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${contact.name}님 차단을 해제했어요.',
            style: TextStyle(fontFamily: 'NotoSansKR'),
          ),
          backgroundColor: Palette.success,
        ),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Palette.white,
        title: const Text('이 회원을 차단할까요?',
            style: TextStyle(fontFamily: 'Jalnan')),
        content: Text(
          '${contact.name}님과 같은 방에 들어가거나 메시지를 보낼 수 없게 됩니다.',
          style: const TextStyle(fontFamily: 'NotoSansKR', height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('닫기'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Palette.danger),
            child: const Text('차단'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await TalkService.blockUser(contact);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${contact.name}님을 차단했어요.',
            style: TextStyle(fontFamily: 'NotoSansKR'),
          ),
          backgroundColor: Palette.grey700,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString(), style: TextStyle(fontFamily: 'NotoSansKR')),
          backgroundColor: Palette.danger,
        ),
      );
    }
  }

  Future<void> _report(TalkContact contact) async {
    await _reportPeer(
      targetId: contact.otherUserId,
      targetName: contact.name,
      lastTopic: contact.lastTopic,
    );
  }

  Future<void> _reportRoom(TalkRoom room) async {
    final uid = AuthService.currentUser?.uid ?? '';
    final others = room.memberIds.where((id) => id != uid).toList();
    if (others.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '아직 함께 있는 상대가 없어요.',
            style: TextStyle(fontFamily: 'NotoSansKR'),
          ),
        ),
      );
      return;
    }
    String? targetId = others.first;
    if (others.length > 1) {
      targetId = await showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('누구를 신고할까요?',
              style: TextStyle(fontFamily: 'Jalnan')),
          children: [
            for (final id in others)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, id),
                child: Text(
                  room.displayNameOf(id),
                  style: const TextStyle(fontFamily: 'NotoSansKR'),
                ),
              ),
          ],
        ),
      );
    }
    if (!mounted || targetId == null || targetId.isEmpty) return;
    await _reportPeer(
      targetId: targetId,
      targetName: room.displayNameOf(targetId),
      lastTopic: room.topic,
    );
  }

  Future<void> _reportPeer({
    required String targetId,
    required String targetName,
    String lastTopic = '',
  }) async {
    final sent = await showDialog<bool>(
      context: context,
      builder: (context) => _TalkReportDialog(
        targetId: targetId,
        targetName: targetName,
        lastTopic: lastTopic,
      ),
    );
    if (!mounted || sent != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '신고를 접수했어요. 운영자가 확인합니다.',
          style: TextStyle(fontFamily: 'NotoSansKR'),
        ),
        backgroundColor: Palette.talkCoralDark,
      ),
    );
  }

  Future<void> _offerSafetyCheck(TalkRoom room) async {
    if (!mounted) return;
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Palette.white,
        title: const Text('대화는 괜찮았나요?',
            style: TextStyle(fontFamily: 'Jalnan')),
        content: const Text(
          '욕설이나 불편한 이야기가 있었다면 지금 신고해 주세요. 운영자가 확인합니다.',
          style: TextStyle(fontFamily: 'NotoSansKR', height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'ok'),
            child: const Text('괜찮았어요'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'report'),
            style: FilledButton.styleFrom(backgroundColor: Palette.danger),
            child: const Text('신고하기'),
          ),
        ],
      ),
    );
    if (!mounted || action != 'report') return;
    await _reportRoom(room);
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width > 768;
    final body = SingleChildScrollView(
      child: Column(
        children: [
          _hero(compact: !wide),
          _body(compact: !wide),
          if (wide) MyWidget.footer(),
        ],
      ),
    );
    return wide ? WebSchoolLayout(content: body) : MobileSchoolLayout(content: body);
  }

  Widget _hero({required bool compact}) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF3EA),
            Color(0xFFFFD9C8),
            Color(0xFFFFF8F1),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: compact ? -40 : 60,
            child: _blob(120, Palette.talkCoral.withValues(alpha: 0.16)),
          ),
          Positioned(
            bottom: -40,
            left: compact ? -30 : 24,
            child: _blob(90, Palette.talkMango.withValues(alpha: 0.24)),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 20 : 56,
              compact ? 20 : 28,
              compact ? 20 : 56,
              compact ? 18 : 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Palette.white.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Palette.talkCoral.withValues(alpha: 0.35)),
                    ),
                    child: const Text(
                      TalkCopy.eyebrow,
                      style: TextStyle(
                        fontFamily: 'NotoSansKR',
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: Palette.talkCoralDark,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    TalkCopy.headline,
                    style: TextStyle(
                      fontFamily: 'Jalnan',
                      fontSize: compact ? 32 : 42,
                      height: 1.05,
                      color: Palette.talkInk,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    TalkCopy.lead,
                    style: TextStyle(
                      fontFamily: 'NotoSansKR',
                      fontSize: compact ? 15 : 17,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                      color: Palette.talkInk,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final two = constraints.maxWidth >= 720;
                      final noteW = two
                          ? (constraints.maxWidth - 10) / 2
                          : constraints.maxWidth;
                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          SizedBox(
                            width: noteW,
                            child: _heroNote(
                              TalkCopy.ruleTitle,
                              TalkCopy.ruleBody,
                              Palette.talkCoralDark,
                              Palette.talkCoral,
                            ),
                          ),
                          SizedBox(
                            width: noteW,
                            child: _heroNote(
                              TalkCopy.safetyTitle,
                              TalkCopy.safetyBody,
                              Palette.danger,
                              Palette.danger,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroNote(String title, String body, Color titleColor, Color border) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Palette.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Jalnan',
              fontSize: 13,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: const TextStyle(
              fontFamily: 'NotoSansKR',
              fontSize: 12,
              height: 1.4,
              color: Palette.grey700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }

  Widget _body({required bool compact}) {
    return Container(
      width: double.infinity,
      color: Palette.white,
      padding: EdgeInsets.fromLTRB(
        compact ? 20 : 56,
        compact ? 18 : 22,
        compact ? 20 : 56,
        compact ? 40 : 64,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080),
        child: StreamBuilder<User?>(
          stream: _auth,
          initialData: AuthService.currentUser,
          builder: (context, authSnap) {
            final loggedIn =
                authSnap.data != null || AuthService.currentUser != null;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _createRow(compact: compact),
                const SizedBox(height: 36),
                if (!loggedIn) _loginHint() else ...[
                  _roomsBlock(),
                  const SizedBox(height: 40),
                  _contactsBlock(),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _createRow({required bool compact}) {
    final cards = [
      _CreateLaunchCard(
        eyebrow: 'Group Chat',
        title: '그룹 채팅 열기',
        body: '주제와 레벨을 고르고, 2~6명까지 인원을 정해요.',
        icon: Icons.groups_2_rounded,
        onTap: () => _createRoom(TalkRoomType.group),
      ),
      _CreateLaunchCard(
        eyebrow: '1:1 Chat',
        title: '일대일 대화방 열기',
        body: '주제와 레벨만 정하면 바로 짝을 기다릴 수 있어요.',
        icon: Icons.chat_bubble_rounded,
        mango: true,
        onTap: () => _createRoom(TalkRoomType.oneToOne),
      ),
    ];
    if (compact) {
      return Column(
        children: [
          cards[0],
          const SizedBox(height: 12),
          cards[1],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 16),
        Expanded(child: cards[1]),
      ],
    );
  }

  Widget _loginHint() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Palette.talkCream,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Palette.talkCoral.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '로그인하면 바로 Cafe에 들어갈 수 있어요',
            style: TextStyle(
              fontFamily: 'Jalnan',
              fontSize: 16,
              color: Palette.talkInk,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '방을 열거나, 이미 열린 대화에 참여하려면 수강생 로그인이 필요해요.',
            style: TextStyle(
              fontFamily: 'NotoSansKR',
              fontSize: 13,
              height: 1.5,
              color: Palette.grey700,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: () => MenuUtil.push(context, const MemberLoginPage()),
            style: FilledButton.styleFrom(
              backgroundColor: Palette.talkCoral,
              foregroundColor: Palette.white,
            ),
            child: const Text('수강생 로그인', style: TextStyle(fontFamily: 'NotoSansKR')),
          ),
        ],
      ),
    );
  }

  Widget _roomsBlock() {
    return StreamBuilder<Set<String>>(
      stream: TalkService.watchHiddenPeerIds(),
      builder: (context, hideSnap) {
        final hidden = hideSnap.data ?? const <String>{};
        return StreamBuilder<List<TalkRoom>>(
          stream: TalkService.watchRooms(),
          builder: (context, snap) {
            final uid = AuthService.currentUser?.uid ?? '';
            final rooms = (snap.data ?? const <TalkRoom>[])
                .where((room) =>
                    !TalkService.roomHasHiddenPeer(room, uid, hidden))
                .toList();
            if (snap.hasError) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionKicker(
                    'Live rooms',
                    '지금 열려 있는 대화방',
                    hint: TalkCopy.leaveHint,
                  ),
                  const SizedBox(height: 16),
                  _emptyNote(
                    '대화방을 불러오지 못했어요. 로그인 상태와 네트워크를 확인한 뒤 다시 열어 주세요.',
                  ),
                ],
              );
            }
            final waiting =
                snap.connectionState == ConnectionState.waiting &&
                    rooms.isEmpty &&
                    (snap.data == null);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionKicker(
                  'Live rooms',
                  '지금 열려 있는 대화방',
                  hint: TalkCopy.leaveHint,
                ),
                const SizedBox(height: 16),
                if (waiting)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: LinearProgressIndicator(color: Palette.talkCoral),
                  )
                else if (rooms.isEmpty)
                  _emptyNote('아직 열린 방이 없어요. 첫 Cafe를 열어볼까요?')
                else
                  SizedBox(
                    width: double.infinity,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const gap = 12.0;
                        final maxW = constraints.maxWidth;
                        final columns = maxW >= 980
                            ? 3
                            : maxW >= 620
                                ? 2
                                : 1;
                        final cardW = columns == 1
                            ? maxW
                            : (maxW - gap * (columns - 1)) / columns;
                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            for (final room in rooms)
                              SizedBox(
                                width: cardW,
                                child: _RoomCard(
                                  room: room,
                                  uid: uid,
                                  busy: _busyRoomId == room.id,
                                  onJoin: () => _join(room),
                                  onLeave: room.contains(uid)
                                      ? () => _leave(room)
                                      : null,
                                  onReport: room.contains(uid) &&
                                          room.memberIds.any((id) => id != uid)
                                      ? () => _reportRoom(room)
                                      : null,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _contactsBlock() {
    return StreamBuilder<Set<String>>(
      stream: TalkService.watchMyBlockIds(),
      builder: (context, blockSnap) {
        final blockedIds = blockSnap.data ?? const <String>{};
        return StreamBuilder<List<TalkContact>>(
          stream: TalkService.watchContacts(),
          builder: (context, snap) {
            final contacts = snap.data ?? const <TalkContact>[];
            if (snap.hasError) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionKicker('People I talked with', '내가 대화한 회원'),
                  const SizedBox(height: 16),
                  _emptyNote('대화한 회원 명단을 불러오지 못했어요. 잠시 후 다시 시도해 주세요.'),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionKicker('People I talked with', '내가 대화한 회원'),
                const SizedBox(height: 16),
                if (snap.connectionState == ConnectionState.waiting &&
                    contacts.isEmpty)
                  const LinearProgressIndicator(color: Palette.talkCoral)
                else if (contacts.isEmpty)
                  _emptyNote(
                      '아직 대화한 회원이 없어요. 방에 들어가 영어 수다를 시작하면 여기에 남아요.')
                else
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final contact in contacts)
                        _ContactChip(
                          contact: contact,
                          blocked: blockedIds.contains(contact.otherUserId),
                          onMessage: () => _message(contact),
                          onBlock: () => _toggleBlock(
                            contact,
                            blocked: blockedIds.contains(contact.otherUserId),
                          ),
                          onReport: () => _report(contact),
                        ),
                    ],
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _sectionKicker(String en, String ko, {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          en,
          style: const TextStyle(
            fontFamily: 'NotoSansKR',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Palette.talkCoralDark,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          ko,
          style: const TextStyle(
            fontFamily: 'Jalnan',
            fontSize: 22,
            color: Palette.talkInk,
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: 8),
          Text(
            hint,
            style: const TextStyle(
              fontFamily: 'NotoSansKR',
              fontSize: 13,
              height: 1.45,
              color: Palette.grey600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _emptyNote(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Palette.talkCream,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'NotoSansKR',
          fontSize: 13,
          height: 1.5,
          color: Palette.grey700,
        ),
      ),
    );
  }
}

class _CreateLaunchCard extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String body;
  final IconData icon;
  final VoidCallback onTap;
  final bool mango;

  const _CreateLaunchCard({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.icon,
    required this.onTap,
    this.mango = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = mango ? Palette.talkMango : Palette.talkCoral;
    return Material(
      color: Palette.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.12),
                Palette.white,
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Palette.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow,
                      style: TextStyle(
                        fontFamily: 'NotoSansKR',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: mango ? Palette.grey700 : Palette.talkCoralDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Jalnan',
                        fontSize: 18,
                        color: Palette.talkInk,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      body,
                      style: const TextStyle(
                        fontFamily: 'NotoSansKR',
                        fontSize: 13,
                        height: 1.45,
                        color: Palette.grey700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final TalkRoom room;
  final String uid;
  final bool busy;
  final VoidCallback onJoin;
  final VoidCallback? onLeave;
  final VoidCallback? onReport;

  const _RoomCard({
    required this.room,
    required this.uid,
    required this.busy,
    required this.onJoin,
    this.onLeave,
    this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    final mine = room.contains(uid);
    final joinable = TalkService.canJoin(room, uid);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Palette.grey200),
        boxShadow: [
          BoxShadow(
            color: Palette.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _pill(
                room.type.label,
                room.isGroup ? Palette.talkCoral : Palette.talkMango,
              ),
              const SizedBox(width: 6),
              _pill(room.level.label, Palette.talkInk),
              const Spacer(),
              Text(
                room.seatsLabel,
                style: const TextStyle(
                  fontFamily: 'NotoSansKR',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Palette.grey600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            room.topic,
            style: const TextStyle(
              fontFamily: 'Jalnan',
              fontSize: 16,
              color: Palette.talkInk,
            ),
          ),
          if (!room.isGroup && room.memberIds.length == 1) ...[
            const SizedBox(height: 6),
            const Text(
              '짝을 기다리는 중',
              style: TextStyle(
                fontFamily: 'NotoSansKR',
                fontSize: 12,
                color: Palette.talkCoralDark,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              ProfileAvatar(
                photoUrl: room.hostPhotoUrl,
                label: room.hostName,
                size: 32,
                backgroundColor: Palette.talkCoral,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${room.hostName} · host',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontSize: 13,
                    color: Palette.grey700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: busy || !joinable ? null : onJoin,
                  style: FilledButton.styleFrom(
                    backgroundColor: Palette.talkCoral,
                    foregroundColor: Palette.white,
                    disabledBackgroundColor: Palette.grey200,
                  ),
                  child: busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          mine
                              ? '다시 입장'
                              : room.isFull
                                  ? '가득 참'
                                  : '들어가기',
                          style: const TextStyle(fontFamily: 'NotoSansKR'),
                        ),
                ),
              ),
              if (onLeave != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: busy ? null : onLeave,
                  child: const Text(
                    '나가기',
                    style: TextStyle(fontFamily: 'NotoSansKR', color: Palette.grey600),
                  ),
                ),
              ],
              if (onReport != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  tooltip: '신고',
                  onPressed: busy ? null : onReport,
                  icon: const Icon(Icons.flag_outlined, size: 20, color: Palette.grey600),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'NotoSansKR',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _ContactChip extends StatelessWidget {
  final TalkContact contact;
  final bool blocked;
  final VoidCallback onMessage;
  final VoidCallback onBlock;
  final VoidCallback onReport;

  const _ContactChip({
    required this.contact,
    required this.blocked,
    required this.onMessage,
    required this.onBlock,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    final topic = contact.lastTopic.trim();
    return Container(
      width: 320,
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
      decoration: BoxDecoration(
        color: blocked ? Palette.grey100 : Palette.talkCream,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          ProfileAvatar(
            photoUrl: contact.photoUrl,
            label: contact.name,
            size: 42,
            backgroundColor:
                blocked ? Palette.grey500 : Palette.talkCoralDark,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        contact.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Jalnan',
                          fontSize: 14,
                          color: Palette.talkInk,
                        ),
                      ),
                    ),
                    if (topic.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '·',
                          style: TextStyle(
                            fontFamily: 'NotoSansKR',
                            fontSize: 12,
                            color: Palette.grey400,
                          ),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          topic,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'NotoSansKR',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Palette.talkCoralDark,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  blocked
                      ? '차단한 회원'
                      : '${contact.lastRoomType.koLabel} · ${contact.lastLevel.label}',
                  style: TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontSize: 11,
                    color: blocked ? Palette.danger : Palette.grey600,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: '메시지 · 차단 · 신고',
            onSelected: (value) {
              if (value == 'message') onMessage();
              if (value == 'block') onBlock();
              if (value == 'report') onReport();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'message',
                enabled: !blocked,
                child: const Text('메시지 보내기',
                    style: TextStyle(fontFamily: 'NotoSansKR')),
              ),
              PopupMenuItem(
                value: 'block',
                child: Text(
                  blocked ? '차단 해제' : '차단',
                  style: const TextStyle(fontFamily: 'NotoSansKR'),
                ),
              ),
              const PopupMenuItem(
                value: 'report',
                child: Text('신고', style: TextStyle(fontFamily: 'NotoSansKR')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CreateTalkRoomDialog extends StatefulWidget {
  final TalkRoomType type;
  final VoidCallback onCreated;

  const _CreateTalkRoomDialog({
    required this.type,
    required this.onCreated,
  });

  @override
  State<_CreateTalkRoomDialog> createState() => _CreateTalkRoomDialogState();
}

class _CreateTalkRoomDialogState extends State<_CreateTalkRoomDialog> {
  final _topic = TextEditingController();
  TalkLevel _level = TalkLevel.beginner;
  int _maxPeople = 4;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _topic.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await TalkService.createRoom(
        type: widget.type,
        topic: _topic.text,
        level: _level,
        maxPeople: _maxPeople,
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onCreated();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.type == TalkRoomType.group;
    return AlertDialog(
      backgroundColor: Palette.white,
      surfaceTintColor: Palette.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        group ? '그룹 채팅 열기' : '1:1 대화방 열기',
        style: const TextStyle(fontFamily: 'Jalnan', color: Palette.talkInk),
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _topic,
                maxLength: TalkService.maxTopicLength,
                decoration: const InputDecoration(
                  labelText: '주제',
                  hintText: '예: Free talk, Weekend plans',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final topic in TalkService.topicSuggestions)
                    ActionChip(
                      label: Text(topic, style: const TextStyle(fontSize: 12)),
                      onPressed: () => setState(() => _topic.text = topic),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                '레벨',
                style: TextStyle(
                  fontFamily: 'NotoSansKR',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final level in TalkLevel.all)
                    ChoiceChip(
                      label: Text(level.label),
                      selected: _level == level,
                      selectedColor: Palette.talkCoral.withValues(alpha: 0.2),
                      onSelected: (_) => setState(() => _level = level),
                    ),
                ],
              ),
              if (group) ...[
                const SizedBox(height: 18),
                const Text(
                  '인원 (최대 6명)',
                  style: TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (var n = TalkService.minPeople; n <= TalkService.maxPeople; n++)
                      ChoiceChip(
                        label: Text('$n명'),
                        selected: _maxPeople == n,
                        selectedColor: Palette.talkMango.withValues(alpha: 0.35),
                        onSelected: (_) => setState(() => _maxPeople = n),
                      ),
                  ],
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(
                    fontFamily: 'NotoSansKR',
                    color: Palette.danger,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('닫기'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: Palette.talkCoral,
            foregroundColor: Palette.white,
          ),
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Palette.white,
                  ),
                )
              : const Text('방 만들고 입장'),
        ),
      ],
    );
  }
}

class _TalkMessageDialog extends StatefulWidget {
  final TalkContact contact;

  const _TalkMessageDialog({required this.contact});

  @override
  State<_TalkMessageDialog> createState() => _TalkMessageDialogState();
}

class _TalkMessageDialogState extends State<_TalkMessageDialog> {
  final _text = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await TalkService.sendMessage(
        contact: widget.contact,
        text: _text.text,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Palette.white,
      surfaceTintColor: Palette.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        '${widget.contact.name}님에게 메시지',
        style: const TextStyle(fontFamily: 'Jalnan', color: Palette.talkInk),
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '상대 화면 오른쪽 위 알림 종에도 바로 뜹니다.',
              style: TextStyle(
                fontFamily: 'NotoSansKR',
                fontSize: 13,
                color: Palette.grey600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _text,
              maxLength: TalkService.maxMessageLength,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: '짧은 메시지를 적어 주세요.',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null)
              Text(
                _error!,
                style: const TextStyle(
                  fontFamily: 'NotoSansKR',
                  color: Palette.danger,
                  fontSize: 13,
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('닫기'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: Palette.talkCoral,
            foregroundColor: Palette.white,
          ),
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Palette.white,
                  ),
                )
              : const Text('보내기'),
        ),
      ],
    );
  }
}

class _TalkReportDialog extends StatefulWidget {
  final String targetId;
  final String targetName;
  final String lastTopic;

  const _TalkReportDialog({
    required this.targetId,
    required this.targetName,
    this.lastTopic = '',
  });

  @override
  State<_TalkReportDialog> createState() => _TalkReportDialogState();
}

class _TalkReportDialogState extends State<_TalkReportDialog> {
  String _reason = TalkService.reportReasons.first;
  final _detail = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _detail.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await TalkService.reportPeer(
        targetId: widget.targetId,
        targetName: widget.targetName,
        reason: _reason,
        detail: _detail.text,
        lastTopic: widget.lastTopic,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Palette.white,
      surfaceTintColor: Palette.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        '${widget.targetName}님 신고',
        style: const TextStyle(fontFamily: 'Jalnan', color: Palette.talkInk),
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '사유',
              style: TextStyle(
                fontFamily: 'NotoSansKR',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final reason in TalkService.reportReasons)
                  ChoiceChip(
                    label: Text(reason),
                    selected: _reason == reason,
                    selectedColor: Palette.talkCoral.withValues(alpha: 0.2),
                    onSelected: (_) => setState(() => _reason = reason),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _detail,
              maxLength: TalkService.maxReportDetailLength,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '자세한 내용 (선택)',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null)
              Text(
                _error!,
                style: const TextStyle(
                  fontFamily: 'NotoSansKR',
                  color: Palette.danger,
                  fontSize: 13,
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('닫기'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: Palette.danger,
            foregroundColor: Palette.white,
          ),
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Palette.white,
                  ),
                )
              : const Text('신고하기'),
        ),
      ],
    );
  }
}
