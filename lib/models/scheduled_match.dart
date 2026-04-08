import '../data/competitions_data.dart';

class ScheduledMatch {
  final int fixtureId;
  final int homeTeamId;
  final String homeTeamName;
  final String? homeTeamLogo;
  final int awayTeamId;
  final String awayTeamName;
  final String? awayTeamLogo;
  final DateTime date;
  final String status;
  final int? homeGoals;
  final int? awayGoals;
  final Competition competition;
  final String round;

  ScheduledMatch({
    required this.fixtureId,
    required this.homeTeamId,
    required this.homeTeamName,
    this.homeTeamLogo,
    required this.awayTeamId,
    required this.awayTeamName,
    this.awayTeamLogo,
    required this.date,
    required this.status,
    this.homeGoals,
    this.awayGoals,
    required this.competition,
    required this.round,
  });

  factory ScheduledMatch.fromApiResponse(
    Map<String, dynamic> json,
    Competition competition,
    String round,
  ) {
    final fixture = json['fixture'];
    final teams = json['teams'];
    final goals = json['goals'];

    return ScheduledMatch(
      fixtureId: fixture['id'],
      homeTeamId: teams['home']['id'],
      homeTeamName: teams['home']['name'],
      homeTeamLogo: teams['home']['logo'],
      awayTeamId: teams['away']['id'],
      awayTeamName: teams['away']['name'],
      awayTeamLogo: teams['away']['logo'],
      date: DateTime.parse(fixture['date']),
      status: fixture['status']['short'],
      homeGoals: goals['home'],
      awayGoals: goals['away'],
      competition: competition,
      round: round,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fixtureId': fixtureId,
      'homeTeamId': homeTeamId,
      'homeTeamName': homeTeamName,
      'homeTeamLogo': homeTeamLogo,
      'awayTeamId': awayTeamId,
      'awayTeamName': awayTeamName,
      'awayTeamLogo': awayTeamLogo,
      'date': date.toIso8601String(),
      'status': status,
      'homeGoals': homeGoals,
      'awayGoals': awayGoals,
      'competitionCode': competition.code,
      'round': round,
    };
  }

  factory ScheduledMatch.fromJson(
    Map<String, dynamic> json,
    List<Competition> competitions,
  ) {
    final competition = competitions.firstWhere(
      (c) => c.code == json['competitionCode'],
      orElse: () => competitions.first,
    );

    return ScheduledMatch(
      fixtureId: json['fixtureId'],
      homeTeamId: json['homeTeamId'],
      homeTeamName: json['homeTeamName'],
      homeTeamLogo: json['homeTeamLogo'],
      awayTeamId: json['awayTeamId'],
      awayTeamName: json['awayTeamName'],
      awayTeamLogo: json['awayTeamLogo'],
      date: DateTime.parse(json['date']),
      status: json['status'],
      homeGoals: json['homeGoals'],
      awayGoals: json['awayGoals'],
      competition: competition,
      round: json['round'],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScheduledMatch && other.fixtureId == fixtureId;
  }

  @override
  int get hashCode => fixtureId.hashCode;
}
