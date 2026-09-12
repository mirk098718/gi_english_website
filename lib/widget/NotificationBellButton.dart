import 'package:flutter/material.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/NotificationService.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/SiteAlertCenter.dart';

/// 오른쪽 위 종. 안 읽은 알림이 있으면 빨간 점과 흔들림, 새 알림은 소리.
class NotificationBellButton extends StatefulWidget {
  final bool light;

  const NotificationBellButton({Key? key, this.light = false}) : super(key: key);

  @override
  State<NotificationBellButton> createState() => _NotificationBellButtonState();
}

class _NotificationBellButtonState extends State<NotificationBellButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ring;
  late final Animation<double> _angle;
  bool _visible = AuthService.currentUser != null;

  @override
  void initState() {
    super.initState();
    _resolveVisible();
    _ring = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _angle = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.28), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.28, end: -0.28), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.28, end: 0.2), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.2, end: -0.14), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.14, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _ring, curve: Curves.easeInOut));
    SiteAlertCenter.instance.addListener(_onAlerts);
    SiteAlertCenter.instance.start();
    _syncRing();
  }

  Future<void> _resolveVisible() async {
    if (AuthService.currentUser != null) {
      if (mounted) setState(() => _visible = true);
      return;
    }
    final uid = await AuthService.currentStaffUid();
    if (!mounted) return;
    setState(() => _visible = uid.isNotEmpty);
  }

  @override
  void dispose() {
    SiteAlertCenter.instance.removeListener(_onAlerts);
    _ring.dispose();
    super.dispose();
  }

  void _onAlerts() {
    if (!mounted) return;
    if (!_visible) {
      _resolveVisible();
    }
    setState(() {});
    _syncRing();
  }

  void _syncRing() {
    if (SiteAlertCenter.instance.hasUnread) {
      if (!_ring.isAnimating) _ring.repeat();
    } else {
      _ring
        ..stop()
        ..reset();
    }
  }

  Future<void> _openPanel() async {
    SiteAlertCenter.instance.unlockAudio();
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black26,
      builder: (dialogContext) {
        return AnimatedBuilder(
          animation: SiteAlertCenter.instance,
          builder: (context, _) {
            final items = SiteAlertCenter.instance.unread;
            return Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
                child: Material(
                  color: Palette.white,
                  elevation: 10,
                  borderRadius: BorderRadius.circular(14),
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxWidth: 360, maxHeight: 460),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                          child: Row(
                            children: [
                              Text('알림',
                                  style: TextStyle(
                                      fontFamily: "Jalnan", fontSize: 16)),
                              const Spacer(),
                              IconButton(
                                tooltip: '닫기',
                                onPressed: () =>
                                    Navigator.pop(dialogContext),
                                icon: Icon(Icons.close, color: Palette.grey600),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: items.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 8, 16, 24),
                                  child: Text(
                                    '새 알림이 없습니다.',
                                    style: TextStyle(
                                      fontFamily: "NotoSansKR",
                                      fontSize: 13,
                                      color: Palette.grey600,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  padding: const EdgeInsets.fromLTRB(
                                      8, 0, 8, 12),
                                  itemCount: items.length,
                                  separatorBuilder: (_, __) =>
                                      Divider(height: 1, color: Palette.grey200),
                                  itemBuilder: (context, index) =>
                                      _tile(items[index]),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _tile(AppNotification item) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 4, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6, right: 8),
            decoration: BoxDecoration(
              color: Palette.danger,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: TextStyle(
                        fontFamily: "NotoSansKR",
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                const SizedBox(height: 4),
                Text(item.body,
                    style: TextStyle(
                        fontFamily: "NotoSansKR",
                        fontSize: 13,
                        height: 1.45,
                        color: Palette.grey700)),
                const SizedBox(height: 4),
                Text(_timeLabel(item.createdAt),
                    style: TextStyle(
                        fontFamily: "NotoSansKR",
                        fontSize: 11,
                        color: Palette.grey500)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => SiteAlertCenter.instance.dismiss(item),
            child: Text('확인',
                style: TextStyle(
                    fontFamily: "NotoSansKR", color: Palette.secondaryDark)),
          ),
        ],
      ),
    );
  }

  String _timeLabel(DateTime at) {
    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 1) return '방금';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${at.month}/${at.day}';
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    final color = widget.light ? Palette.white : Palette.navy;
    final count = SiteAlertCenter.instance.unreadCount;
    return IconButton(
      tooltip: count > 0 ? '알림 $count건' : '알림',
      onPressed: _openPanel,
      icon: SizedBox(
        width: 28,
        height: 28,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: AnimatedBuilder(
                animation: _angle,
                builder: (context, child) => Transform.rotate(
                  angle: _angle.value,
                  alignment: Alignment.topCenter,
                  child: child,
                ),
                child: Icon(
                  count > 0
                      ? Icons.notifications_active
                      : Icons.notifications_none,
                  color: color,
                  size: 24,
                ),
              ),
            ),
            if (count > 0)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: Palette.danger,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.light
                          ? Palette.secondaryDark
                          : Palette.white,
                      width: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
