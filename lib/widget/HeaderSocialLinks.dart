import 'package:flutter/material.dart';
import 'package:gi_english_website/util/UrlIUtil.dart';

class HeaderSocialLinks extends StatelessWidget {
  final bool compact;

  const HeaderSocialLinks({Key? key, this.compact = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 22.0 : 24.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _iconButton(
          label: 'Instagram',
          url: 'https://www.instagram.com/gleam_island_school/',
          icon: _instagramIcon(iconSize),
        ),
        SizedBox(width: compact ? 4 : 6),
        _iconButton(
          label: 'Naver Blog',
          url: 'https://blog.naver.com/gleam-island-paju',
          icon: _naverBlogIcon(iconSize),
        ),
      ],
    );
  }

  Widget _iconButton({
    required String label,
    required String url,
    required Widget icon,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: () => UrlUtil.open(url),
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: icon,
          ),
        ),
      ),
    );
  }

  Widget _instagramIcon(double size) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.28),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: [
                    Color(0xFFF58529),
                    Color(0xFFDD2A7B),
                    Color(0xFF8134AF),
                    Color(0xFF515BD4),
                  ],
                ),
              ),
              child: SizedBox.expand(),
            ),
            Center(
              child: Container(
                width: size * 0.40,
                height: size * 0.40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: (size * 0.085).clamp(1.5, 2.5),
                  ),
                ),
              ),
            ),
            Positioned(
              top: size * 0.16,
              right: size * 0.16,
              child: Container(
                width: size * 0.13,
                height: size * 0.13,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _naverBlogIcon(double size) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF03C75A),
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: Text(
        'N',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.68,
          fontWeight: FontWeight.w800,
          height: 1,
          letterSpacing: -0.4,
        ),
      ),
    );
  }
}
