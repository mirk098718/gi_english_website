import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gi_english_website/class/TalkCopy.dart';
import 'package:gi_english_website/util/Palette.dart';

/// 렛츠토크 히어로에서 카페 캐릭터가 안내 문구를 말풍선으로 말한다.
class TalkHeroSpeech extends StatelessWidget {
  final bool compact;

  const TalkHeroSpeech({Key? key, required this.compact}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mascotW = compact ? 104.0 : 136.0;
    final gap = compact ? 4.0 : 8.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TalkCafeMascot(width: mascotW),
            SizedBox(width: gap),
            Expanded(
              child: TalkSpeechBubble(
                body: TalkCopy.lead,
                emphasized: true,
                showTail: true,
                accent: Palette.talkCoral,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class TalkSpeechBubble extends StatelessWidget {
  final String? title;
  final String body;
  final bool emphasized;
  final bool showTail;
  final Color accent;
  final Color? titleColor;

  const TalkSpeechBubble({
    Key? key,
    this.title,
    required this.body,
    this.emphasized = false,
    this.showTail = false,
    required this.accent,
    this.titleColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fill = const Color(0xFFFFFCF9);
    final border = accent.withValues(alpha: emphasized ? 0.55 : 0.38);
    return CustomPaint(
      painter: _BubblePainter(
        fill: fill,
        border: border,
        shadow: accent.withValues(alpha: 0.16),
        showTail: showTail,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          showTail ? 26 : 14,
          emphasized ? 13 : 11,
          14,
          emphasized ? 13 : 11,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: TextStyle(
                  fontFamily: 'Jalnan',
                  fontSize: 13,
                  height: 1.25,
                  color: titleColor ?? accent,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              body,
              style: TextStyle(
                fontFamily: 'NotoSansKR',
                fontSize: emphasized ? 15.5 : 13,
                height: 1.45,
                fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
                color: emphasized
                    ? Palette.talkInk
                    : Palette.talkInk.withValues(alpha: 0.78),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  final Color fill;
  final Color border;
  final Color shadow;
  final bool showTail;

  const _BubblePainter({
    required this.fill,
    required this.border,
    required this.shadow,
    required this.showTail,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final tailW = showTail ? 12.0 : 0.0;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        tailW,
        1,
        math.max(0, size.width - tailW - 1),
        size.height - 2,
      ),
      const Radius.circular(18),
    );
    var path = Path()..addRRect(rect);
    if (showTail && size.height > 24) {
      final mid = size.height / 2;
      final tail = Path()
        ..moveTo(tailW + 2, mid - 11)
        ..lineTo(1.5, mid)
        ..lineTo(tailW + 2, mid + 11)
        ..close();
      path = Path.combine(PathOperation.union, path, tail);
    }
    canvas.drawShadow(path, shadow, 3, true);
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeJoin = StrokeJoin.round
        ..color = border,
    );
  }

  @override
  bool shouldRepaint(_BubblePainter oldDelegate) {
    return oldDelegate.fill != fill ||
        oldDelegate.border != border ||
        oldDelegate.shadow != shadow ||
        oldDelegate.showTail != showTail;
  }
}

class TalkCafeMascot extends StatefulWidget {
  final double width;

  const TalkCafeMascot({Key? key, required this.width}) : super(key: key);

  @override
  State<TalkCafeMascot> createState() => _TalkCafeMascotState();
}

class _TalkCafeMascotState extends State<TalkCafeMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce) {
      _ctrl.stop();
    } else if (!_ctrl.isAnimating) {
      _ctrl.repeat();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.width * (156 / 132);
    return Semantics(
      label: '영어 카페 안내 캐릭터',
      image: true,
      child: SizedBox(
        width: widget.width,
        height: height,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            final t = _ctrl.value;
            final reduce = MediaQuery.disableAnimationsOf(context);
            final wave = reduce ? 0.0 : math.sin(t * math.pi * 2);
            final blink = !reduce && t > 0.73 && t < 0.79 ? 0.0 : 1.0;
            final bob = reduce ? 0.0 : wave * 2.2;
            return Transform.translate(
              offset: Offset(0, bob),
              child: CustomPaint(
                painter: _MascotPainter(wave: wave, eyes: blink),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MascotPainter extends CustomPainter {
  final double wave;
  final double eyes;

  const _MascotPainter({required this.wave, required this.eyes});

  static const _ink = Color(0xFF3A2430);
  static const _cream = Color(0xFFFFF8F3);
  static const _coral = Color(0xFFFF5B6B);
  static const _coralDeep = Color(0xFFE23B55);
  static const _mango = Color(0xFFFFB020);
  static const _shoe = Color(0xFF4A3040);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    double dx(double u) => u * w;
    double dy(double v) => v * h;
    Offset p(double u, double v) => Offset(dx(u), dy(v));

    canvas.drawOval(
      Rect.fromCenter(
        center: p(0.50, 0.95),
        width: dx(0.42),
        height: dy(0.045),
      ),
      Paint()..color = _ink.withValues(alpha: 0.10),
    );

    _arm(
      canvas,
      shoulder: p(0.30, 0.66),
      hand: p(0.16, 0.78),
      thickness: dx(0.075),
    );

    final shoulder = p(0.72, 0.62);
    final angle = -1.05 + wave * 0.28;
    final hand = shoulder + Offset(math.cos(angle), math.sin(angle)) * dx(0.24);
    _arm(canvas, shoulder: shoulder, hand: hand, thickness: dx(0.075));

    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: p(0.50, 0.74), width: dx(0.46), height: dy(0.30)),
      Radius.circular(dx(0.16)),
    );
    canvas.drawRRect(body, Paint()..color = _coral);
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = dx(0.016)
        ..color = _ink,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: p(0.50, 0.76),
          width: dx(0.22),
          height: dy(0.11),
        ),
        Radius.circular(dx(0.06)),
      ),
      Paint()..color = _cream,
    );
    _star(canvas, p(0.50, 0.755), dx(0.038), _mango);

    canvas.drawOval(
      Rect.fromCenter(
        center: p(0.40, 0.885),
        width: dx(0.13),
        height: dy(0.055),
      ),
      Paint()..color = _shoe,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: p(0.60, 0.885),
        width: dx(0.13),
        height: dy(0.055),
      ),
      Paint()..color = _shoe,
    );

    final head = p(0.50, 0.40);
    final hr = dx(0.33);
    canvas.drawCircle(head, hr, Paint()..color = _cream);
    _hair(canvas, head, hr);

    canvas.drawCircle(
      head,
      hr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = dx(0.018)
        ..color = _ink,
    );
    _tuft(canvas, p(0.58, 0.12), dx(0.07));

    _eye(canvas, p(0.40, 0.42), dx(0.055), dy(0.07));
    _eye(canvas, p(0.60, 0.42), dx(0.055), dy(0.07));

    final blush = Paint()..color = _coral.withValues(alpha: 0.38);
    canvas.drawCircle(p(0.29, 0.50), dx(0.045), blush);
    canvas.drawCircle(p(0.71, 0.50), dx(0.045), blush);

    final smile = Path()
      ..moveTo(dx(0.44), dy(0.52))
      ..quadraticBezierTo(dx(0.50), dy(0.60), dx(0.56), dy(0.52));
    canvas.drawPath(
      smile,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = dx(0.018)
        ..strokeCap = StrokeCap.round
        ..color = _ink,
    );

    _star(canvas, p(0.80, 0.16), dx(0.045), _mango);
    _star(canvas, p(0.18, 0.22), dx(0.026), const Color(0xFFFFD56A));
  }

  void _hair(Canvas canvas, Offset head, double hr) {
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: head, radius: hr - 0.5)),
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(head.dx, head.dy - hr * 0.42),
        width: hr * 2.2,
        height: hr * 1.15,
      ),
      Paint()..color = _coral,
    );
    final cream = Paint()..color = _cream;
    final bangY = head.dy - hr * 0.02;
    canvas.drawCircle(Offset(head.dx - hr * 0.48, bangY), hr * 0.42, cream);
    canvas.drawCircle(Offset(head.dx + hr * 0.48, bangY), hr * 0.42, cream);
    canvas.drawCircle(Offset(head.dx, bangY + hr * 0.22), hr * 0.24, cream);
    canvas.restore();
  }

  void _tuft(Canvas canvas, Offset root, double s) {
    final path = Path()
      ..moveTo(root.dx - s * 0.2, root.dy + s)
      ..quadraticBezierTo(
        root.dx + s * 0.1,
        root.dy - s * 1.6,
        root.dx + s * 1.15,
        root.dy + s * 0.15,
      )
      ..quadraticBezierTo(
        root.dx + s * 0.35,
        root.dy + s * 0.15,
        root.dx - s * 0.05,
        root.dy + s * 1.05,
      )
      ..close();
    canvas.drawPath(path, Paint()..color = _coralDeep);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.18
        ..strokeJoin = StrokeJoin.round
        ..color = _ink,
    );
  }

  void _eye(Canvas canvas, Offset c, double rx, double ry) {
    if (eyes < 0.5) {
      final closed = Path()
        ..moveTo(c.dx - rx, c.dy)
        ..quadraticBezierTo(c.dx, c.dy + ry * 0.35, c.dx + rx, c.dy);
      canvas.drawPath(
        closed,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = rx * 0.38
          ..strokeCap = StrokeCap.round
          ..color = _ink,
      );
      return;
    }
    canvas.drawOval(
      Rect.fromCenter(center: c, width: rx * 2, height: ry * 2),
      Paint()..color = _ink,
    );
    canvas.drawCircle(
      c + Offset(rx * 0.28, -ry * 0.28),
      rx * 0.38,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      c + Offset(-rx * 0.22, ry * 0.22),
      rx * 0.16,
      Paint()..color = Colors.white.withValues(alpha: 0.7),
    );
  }

  void _arm(
    Canvas canvas, {
    required Offset shoulder,
    required Offset hand,
    required double thickness,
  }) {
    canvas.drawLine(
      shoulder,
      hand,
      Paint()
        ..color = _coral
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(hand, thickness * 0.62, Paint()..color = _cream);
    canvas.drawCircle(
      hand,
      thickness * 0.62,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness * 0.16
        ..color = _ink,
    );
  }

  void _star(Canvas canvas, Offset c, double r, Color color) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final radius = i.isEven ? r : r * 0.4;
      final a = -math.pi / 2 + i * math.pi / 4;
      final point = c + Offset(math.cos(a) * radius, math.sin(a) * radius);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_MascotPainter oldDelegate) {
    return oldDelegate.wave != wave || oldDelegate.eyes != eyes;
  }
}
