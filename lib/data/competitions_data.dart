import 'package:flutter/material.dart';

class Competition {
  final String code;
  final String name;
  final String nameRu;
  final String logoPath;
  final Color accentColor;
  final int championsLeagueSlots;
  final int europaLeagueSlots;
  final int conferenceLeagueSlots;
  final int roundOf16Slots;
  final int roundOf32Slots;
  final int relegationSlots;
  final int apiId;
  final String logoPathColorful;
  final int numberOfRounds;

  const Competition({
    required this.code,
    required this.name,
    this.nameRu = '',
    this.logoPath = '',
    this.accentColor = const Color(0xFF38003C),
    this.championsLeagueSlots = 0,
    this.europaLeagueSlots = 0,
    this.conferenceLeagueSlots = 0,
    this.roundOf16Slots = 0,
    this.roundOf32Slots = 0,
    this.relegationSlots = 0,
    this.apiId = 0,
    this.logoPathColorful = '',
    this.numberOfRounds = 0,
  });

  factory Competition.fromSupabaseJson(Map<String, dynamic> json) {
    Color accentColor = const Color(0xFF38003C);
    final colorHex = json['color_hex'] as String?;
    if (colorHex != null && colorHex.startsWith('#') && colorHex.length == 7) {
      accentColor = Color(int.parse('FF${colorHex.substring(1)}', radix: 16));
    }
    return Competition(
      code: (json['slug'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      nameRu: '',
      logoPath: (json['logo_url'] as String?) ?? '',
      logoPathColorful: (json['logo_url'] as String?) ?? '',
      accentColor: accentColor,
      apiId: (json['external_id'] as int?) ?? 0,
    );
  }
}

const List<Competition> competitions = [
  Competition(
    code: 'PL',
    name: 'Premier League',
    nameRu: 'АПЛ',
    logoPath: 'assets/icons/Premier League.svg',
    logoPathColorful: 'assets/icons/Premier League (original).svg',
    accentColor: Color(0xFF38003C),
    championsLeagueSlots: 4,
    europaLeagueSlots: 2,
    conferenceLeagueSlots: 1,
    relegationSlots: 3,
    apiId: 39,
    numberOfRounds: 38,
  ),
  Competition(
    code: 'PD',
    name: 'La Liga',
    nameRu: 'Ла Лига',
    logoPath: 'assets/icons/La liga/La Liga.svg',
    accentColor: Color(0xFFFF4B44),
    championsLeagueSlots: 5,
    europaLeagueSlots: 2,
    conferenceLeagueSlots: 1,
    relegationSlots: 3,
    apiId: 140,
    numberOfRounds: 38,
  ),
  Competition(
    code: 'BL1',
    name: 'Bundesliga',
    nameRu: 'Бундеслига',
    logoPath: 'assets/icons/Bundesliga/Bundesliga.svg',
    accentColor: Color(0xFFD3010C),
    championsLeagueSlots: 4,
    europaLeagueSlots: 2,
    conferenceLeagueSlots: 1,
    relegationSlots: 3,
    apiId: 78,
    numberOfRounds: 34,
  ),
  Competition(
    code: 'SA',
    name: 'Serie A',
    nameRu: 'Серия А',
    logoPath: 'assets/icons/Seria A/Seria A.svg',
    accentColor: Color(0xFF008FD7),
    championsLeagueSlots: 5,
    europaLeagueSlots: 2,
    conferenceLeagueSlots: 1,
    relegationSlots: 3,
    apiId: 135,
    numberOfRounds: 38,
  ),
  Competition(
    code: 'FL1',
    name: 'Ligue 1',
    nameRu: 'Лига 1',
    logoPath: 'assets/icons/Ligue 1/Ligue 1.svg',
    accentColor: Color(0xFF085FFF),
    championsLeagueSlots: 3,
    europaLeagueSlots: 2,
    conferenceLeagueSlots: 1,
    relegationSlots: 3,
    apiId: 61,
    numberOfRounds: 34,
  ),
  Competition(
    code: 'CL',
    name: 'UEFA Champions League',
    nameRu: 'Лига Чемпионов',
    logoPath: 'assets/icons/Others/UCL.svg',
    accentColor: Color(0xFF3562A6),
    roundOf16Slots: 8,
    roundOf32Slots: 16,
    apiId: 2,
  ),
  Competition(
    code: 'EL',
    name: 'UEFA Europa League',
    nameRu: 'Лига Европы',
    accentColor: Color(0xFFF68E21),
    roundOf16Slots: 8,
    roundOf32Slots: 16,
    apiId: 3,
  ),
  Competition(
    code: 'UECL',
    name: 'UEFA Conference League',
    nameRu: 'Лига Конференций',
    accentColor: Color(0xFF00B140),
    roundOf16Slots: 8,
    roundOf32Slots: 16,
    apiId: 848,
  ),
  Competition(
    code: 'WC',
    name: 'FIFA World Cup',
    nameRu: 'Чемпионат Мира',
    apiId: 1,
  ),
  Competition(
    code: 'EC',
    name: 'European Championship',
    nameRu: 'Чемпионат Европы',
    apiId: 4,
  ),
];
