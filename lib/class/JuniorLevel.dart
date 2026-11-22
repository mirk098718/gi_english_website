/// 주니어 현재 레벨. 초등부·중등부 각각 1부터 6까지.
class JuniorLevel {
  static const int minLevel = 1;
  static const int maxLevel = 6;
  static const String elementary = 'elementary';
  static const String middle = 'middle';

  final String band;
  final int level;

  const JuniorLevel({required this.band, required this.level});

  static bool isBand(String band) => band == elementary || band == middle;

  static bool isLevel(int level) => level >= minLevel && level <= maxLevel;

  static JuniorLevel? parse({required String band, required int level}) {
    if (!isBand(band) || !isLevel(level)) return null;
    return JuniorLevel(band: band, level: level);
  }

  static JuniorLevel? fromMap(Map<String, dynamic>? data) {
    if (data == null) return null;
    final band = data['juniorLevelBand']?.toString() ?? '';
    final raw = data['juniorLevel'];
    final level = raw is int ? raw : int.tryParse('${raw ?? ''}') ?? 0;
    return parse(band: band, level: level);
  }

  String get bandLabel => band == middle ? '중등부' : '초등부';

  String get label => '$bandLabel 레벨 $level';

  Map<String, dynamic> toMap() => {
        'juniorLevel': level,
        'juniorLevelBand': band,
      };
}
