import 'package:equatable/equatable.dart';
import '../../models/models.dart';
import '../../data/competitions_data.dart';

enum TacticsBoardStatus { initial, loading, loaded, error }

class TacticsBoardState extends Equatable {
  final TacticsBoardStatus status;
  final BoardSettings settings;
  final Competition? selectedCompetition;
  final String? selectedTeamId;
  final List<dynamic> teams;
  final List<TacticPlayer> allPlayers; // All players from squad
  final TacticPlayer? draggingPlayer;
  final String? errorMessage;

  const TacticsBoardState({
    this.status = TacticsBoardStatus.initial,
    this.settings = const BoardSettings(),
    this.selectedCompetition,
    this.selectedTeamId,
    this.teams = const [],
    this.allPlayers = const [],
    this.draggingPlayer,
    this.errorMessage,
  });

  /// Players currently on the field (have position)
  List<TacticPlayer> get fieldPlayers =>
      allPlayers.where((p) => p.position != null).toList();

  /// Players on the bench (no position)
  List<TacticPlayer> get benchPlayers =>
      allPlayers.where((p) => p.position == null).toList();

  /// Main squad players (on bench)
  List<TacticPlayer> get mainSquadBench =>
      benchPlayers.where((p) => p.isInSquad).toList();

  /// Reserve players (on bench)
  List<TacticPlayer> get reservesBench =>
      benchPlayers.where((p) => !p.isInSquad).toList();

  bool get isLoading => status == TacticsBoardStatus.loading;

  TacticsBoardState copyWith({
    TacticsBoardStatus? status,
    BoardSettings? settings,
    Competition? selectedCompetition,
    bool clearCompetition = false,
    String? selectedTeamId,
    bool clearTeamId = false,
    List<dynamic>? teams,
    List<TacticPlayer>? allPlayers,
    TacticPlayer? draggingPlayer,
    bool clearDraggingPlayer = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TacticsBoardState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      selectedCompetition: clearCompetition
          ? null
          : (selectedCompetition ?? this.selectedCompetition),
      selectedTeamId: clearTeamId
          ? null
          : (selectedTeamId ?? this.selectedTeamId),
      teams: teams ?? this.teams,
      allPlayers: allPlayers ?? this.allPlayers,
      draggingPlayer: clearDraggingPlayer
          ? null
          : (draggingPlayer ?? this.draggingPlayer),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  Map<String, dynamic> toJson() => {
    'settings': settings.toJson(),
    'selectedCompetitionId': selectedCompetition?.apiId,
    'selectedTeamId': selectedTeamId,
    'allPlayers': allPlayers.map((p) => p.toJson()).toList(),
  };

  factory TacticsBoardState.fromJson(Map<String, dynamic> json) {
    // Find competition by apiId
    Competition? competition;
    if (json['selectedCompetitionId'] != null) {
      try {
        competition = competitions.firstWhere(
          (c) => c.apiId == json['selectedCompetitionId'],
        );
      } catch (_) {
        competition = null;
      }
    }

    return TacticsBoardState(
      status: TacticsBoardStatus.loaded,
      settings: json['settings'] != null
          ? BoardSettings.fromJson(json['settings'] as Map<String, dynamic>)
          : const BoardSettings(),
      selectedCompetition: competition,
      selectedTeamId: json['selectedTeamId'] as String?,
      allPlayers:
          (json['allPlayers'] as List<dynamic>?)
              ?.map((p) => TacticPlayer.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [
    status,
    settings,
    selectedCompetition,
    selectedTeamId,
    teams,
    allPlayers,
    draggingPlayer,
    errorMessage,
  ];
}
