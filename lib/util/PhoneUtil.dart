class PhoneUtil {
  static String digits(String raw) =>
      raw.replaceAll(RegExp(r'[^0-9]'), '');

  static String normalize(String raw) {
    var value = digits(raw);
    if (value.startsWith('82') && value.length >= 12) {
      value = '0${value.substring(2)}';
    }
    return value;
  }

  static bool isValid(String raw) {
    final value = normalize(raw);
    return RegExp(r'^01[016789]\d{7,8}$').hasMatch(value);
  }

  static String? validate(String raw, {bool required = true}) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return required ? '휴대폰 번호를 입력해주세요.' : null;
    }
    if (!isValid(trimmed)) {
      return '휴대폰 번호 형식이 올바르지 않습니다. (예: 010-1234-5678)';
    }
    return null;
  }

  static String display(String raw) {
    final value = normalize(raw);
    if (value.length == 11) {
      return '${value.substring(0, 3)}-${value.substring(3, 7)}-${value.substring(7)}';
    }
    if (value.length == 10) {
      return '${value.substring(0, 3)}-${value.substring(3, 6)}-${value.substring(6)}';
    }
    return raw.trim();
  }
}
