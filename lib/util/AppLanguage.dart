import 'package:flutter/material.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/en_translations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Site language. Korean is the source text; English comes from [enTranslations].
class AppLanguage extends ChangeNotifier {
  AppLanguage._();

  static final AppLanguage instance = AppLanguage._();
  static const _prefKey = 'gi_site_language';

  String code = 'ko';

  bool get isEnglish => code == 'en';

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved == 'en' || saved == 'ko') {
        code = saved!;
      }
    } catch (_) {}
  }

  Future<void> useKorean() => _set('ko');

  Future<void> useEnglish() => _set('en');

  Future<void> _set(String next) async {
    if (next == code) return;
    code = next;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, code);
    } catch (_) {}
  }

  String translate(String source) {
    if (!isEnglish || source.isEmpty) return source;
    final direct = enTranslations[source];
    if (direct != null) return direct;
    final trimmed = source.trim();
    if (trimmed != source) {
      final hit = enTranslations[trimmed];
      if (hit != null) return hit;
    }
    return source;
  }
}

class LangScope extends InheritedNotifier<AppLanguage> {
  LangScope({Key? key, required Widget child})
      : super(key: key, notifier: AppLanguage.instance, child: child);
}

/// Translates [source] and rebuilds when the site language changes.
String tr(BuildContext context, String source) {
  context.dependOnInheritedWidgetOfExactType<LangScope>();
  return AppLanguage.instance.translate(source);
}

/// Korean / English control for the top bar.
class LanguageToggle extends StatelessWidget {
  final bool compact;

  const LanguageToggle({Key? key, this.compact = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    context.dependOnInheritedWidgetOfExactType<LangScope>();
    final english = AppLanguage.instance.isEnglish;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment(
            label: 'Korean',
            selected: !english,
            onTap: AppLanguage.instance.useKorean,
          ),
          _segment(
            label: 'English',
            selected: english,
            onTap: AppLanguage.instance.useEnglish,
          ),
        ],
      ),
    );
  }

  Widget _segment({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 12,
            vertical: compact ? 5 : 6,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? const Color(0xFF022C22) : Palette.white,
              fontFamily: 'NotoSansKR',
              fontWeight: FontWeight.w700,
              fontSize: compact ? 11 : 13,
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}
