import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/LessonRatingService.dart';
import 'package:gi_english_website/util/Palette.dart';

/// 로그인 수강생에게 미완료 강사 평가 팝업을 띄운다.
class LessonRatingPromptHost extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const LessonRatingPromptHost({
    Key? key,
    required this.child,
    required this.enabled,
  }) : super(key: key);

  @override
  State<LessonRatingPromptHost> createState() => _LessonRatingPromptHostState();
}

class _LessonRatingPromptHostState extends State<LessonRatingPromptHost> {
  StreamSubscription<User?>? _authSub;
  StreamSubscription<List<LessonRating>>? _ratingSub;
  bool _dialogOpen = false;
  final Set<String> _snoozed = {};

  @override
  void initState() {
    super.initState();
    _authSub = AuthService.authStateChanges.listen((_) => _bind());
    _bind();
  }

  @override
  void didUpdateWidget(covariant LessonRatingPromptHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) _bind();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _ratingSub?.cancel();
    super.dispose();
  }

  Future<void> _bind() async {
    await _ratingSub?.cancel();
    _ratingSub = null;
    if (!widget.enabled) return;
    final uid = AuthService.currentUser?.uid ?? '';
    if (uid.isEmpty) return;
    if (await AuthService.isStaff()) return;
    _ratingSub = LessonRatingService.watchMinePending(userId: uid).listen(
      _onPending,
      onError: (_) {},
    );
  }

  void _onPending(List<LessonRating> pending) {
    if (!mounted || _dialogOpen) return;
    LessonRating? next;
    for (final item in pending) {
      if (_snoozed.contains(item.id)) continue;
      next = item;
      break;
    }
    if (next == null) return;
    _dialogOpen = true;
    final rating = next;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        _dialogOpen = false;
        return;
      }
      final saved = await LessonRatingService.showPrompt(
        context: context,
        rating: rating,
      );
      _dialogOpen = false;
      if (saved != true) _snoozed.add(rating.id);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class LessonRatingStatusChip extends StatelessWidget {
  final LessonRating? rating;

  const LessonRatingStatusChip({Key? key, this.rating}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (rating == null) {
      return _chip('평가 없음', Palette.grey200, Palette.grey600);
    }
    if (rating!.isRated) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LessonStarView(stars: rating!.stars, size: 14),
          SizedBox(width: 4),
          Text(
            rating!.starsLabel,
            style: TextStyle(
              fontFamily: "NotoSansKR",
              fontSize: 11,
              color: Palette.grey700,
            ),
          ),
        ],
      );
    }
    if (rating!.isPendingStudent) {
      return _chip('학생 평가 대기', Palette.warning.withValues(alpha: 0.16), Palette.warning);
    }
    return _chip('강사 피드백 대기', Palette.grey200, Palette.grey600);
  }

  Widget _chip(String label, Color background, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: "NotoSansKR",
          fontSize: 11,
          color: color,
        ),
      ),
    );
  }
}
