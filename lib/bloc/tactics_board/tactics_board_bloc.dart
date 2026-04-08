import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:flutter/material.dart';
import 'tactics_board_event.dart';
import 'tactics_board_state.dart';

class TacticsBoardBloc
    extends HydratedBloc<TacticsBoardEvent, TacticsBoardState> {
  TacticsBoardBloc() : super(const TacticsBoardState()) {
    on<SelectCompetition>(_onSelectCompetition);
    on<SelectTeam>(_onSelectTeam);
    on<TeamsLoaded>(_onTeamsLoaded);
    on<SquadLoaded>(_onSquadLoaded);
    on<SelectFormation>(_onSelectFormation);
    on<ToggleOrientation>(_onToggleOrientation);
    on<ToggleSnapPoints>(_onToggleSnapPoints);
    on<ToggleMagnetize>(_onToggleMagnetize);
    on<TogglePlayerNames>(_onTogglePlayerNames);
    on<SetFieldScale>(_onSetFieldScale);
    on<SetFieldStyle>(_onSetFieldStyle);
    on<AddPlayerToField>(_onAddPlayerToField);
    on<MovePlayer>(_onMovePlayer);
    on<RemovePlayerFromField>(_onRemovePlayerFromField);
    on<ClearField>(_onClearField);
    on<SetLoading>(_onSetLoading);
    on<SetDraggingPlayer>(_onSetDraggingPlayer);
  }

  void _onSelectCompetition(
    SelectCompetition event,
    Emitter<TacticsBoardState> emit,
  ) {
    emit(
      state.copyWith(
        selectedCompetition: event.competition,
        clearCompetition: event.competition == null,
        clearTeamId: true,
        teams: [],
        allPlayers: [],
      ),
    );
  }

  void _onSelectTeam(SelectTeam event, Emitter<TacticsBoardState> emit) {
    emit(
      state.copyWith(
        selectedTeamId: event.teamId,
        clearTeamId: event.teamId == null,
      ),
    );
  }

  void _onTeamsLoaded(TeamsLoaded event, Emitter<TacticsBoardState> emit) {
    emit(state.copyWith(teams: event.teams, status: TacticsBoardStatus.loaded));
  }

  void _onSquadLoaded(SquadLoaded event, Emitter<TacticsBoardState> emit) {
    emit(
      state.copyWith(
        allPlayers: event.players,
        status: TacticsBoardStatus.loaded,
      ),
    );
  }

  void _onSelectFormation(
    SelectFormation event,
    Emitter<TacticsBoardState> emit,
  ) {
    emit(
      state.copyWith(
        settings: state.settings.copyWith(selectedFormation: event.formation),
      ),
    );
  }

  void _onToggleOrientation(
    ToggleOrientation event,
    Emitter<TacticsBoardState> emit,
  ) {
    emit(
      state.copyWith(
        settings: state.settings.copyWith(
          isVertical: !state.settings.isVertical,
        ),
      ),
    );
  }

  void _onToggleSnapPoints(
    ToggleSnapPoints event,
    Emitter<TacticsBoardState> emit,
  ) {
    emit(
      state.copyWith(
        settings: state.settings.copyWith(
          showSnapPoints: !state.settings.showSnapPoints,
        ),
      ),
    );
  }

  void _onToggleMagnetize(
    ToggleMagnetize event,
    Emitter<TacticsBoardState> emit,
  ) {
    emit(
      state.copyWith(
        settings: state.settings.copyWith(magnetize: !state.settings.magnetize),
      ),
    );
  }

  void _onTogglePlayerNames(
    TogglePlayerNames event,
    Emitter<TacticsBoardState> emit,
  ) {
    emit(
      state.copyWith(
        settings: state.settings.copyWith(
          showPlayerNames: !state.settings.showPlayerNames,
        ),
      ),
    );
  }

  void _onSetFieldScale(SetFieldScale event, Emitter<TacticsBoardState> emit) {
    emit(
      state.copyWith(
        settings: state.settings.copyWith(fieldScale: event.scale),
      ),
    );
  }

  void _onSetFieldStyle(SetFieldStyle event, Emitter<TacticsBoardState> emit) {
    emit(
      state.copyWith(
        settings: state.settings.copyWith(fieldStyle: event.fieldStyle),
      ),
    );
  }

  void _onAddPlayerToField(
    AddPlayerToField event,
    Emitter<TacticsBoardState> emit,
  ) {
    final updatedPlayers = state.allPlayers.map((p) {
      if (p.id == event.player.id) {
        return p.copyWith(position: event.position);
      }
      return p;
    }).toList();

    emit(state.copyWith(allPlayers: updatedPlayers));
  }

  void _onMovePlayer(MovePlayer event, Emitter<TacticsBoardState> emit) {
    final updatedPlayers = state.allPlayers.map((p) {
      if (p.id == event.playerId) {
        return p.copyWith(position: event.position);
      }
      return p;
    }).toList();

    emit(state.copyWith(allPlayers: updatedPlayers));
  }

  void _onRemovePlayerFromField(
    RemovePlayerFromField event,
    Emitter<TacticsBoardState> emit,
  ) {
    final updatedPlayers = state.allPlayers.map((p) {
      if (p.id == event.playerId) {
        return p.copyWith(clearPosition: true);
      }
      return p;
    }).toList();

    emit(state.copyWith(allPlayers: updatedPlayers));
  }

  void _onClearField(ClearField event, Emitter<TacticsBoardState> emit) {
    final updatedPlayers = state.allPlayers
        .map((p) => p.copyWith(clearPosition: true))
        .toList();

    emit(state.copyWith(allPlayers: updatedPlayers));
  }

  void _onSetLoading(SetLoading event, Emitter<TacticsBoardState> emit) {
    emit(
      state.copyWith(
        status: event.isLoading
            ? TacticsBoardStatus.loading
            : TacticsBoardStatus.loaded,
      ),
    );
  }

  void _onSetDraggingPlayer(
    SetDraggingPlayer event,
    Emitter<TacticsBoardState> emit,
  ) {
    emit(
      state.copyWith(
        draggingPlayer: event.player,
        clearDraggingPlayer: event.player == null,
      ),
    );
  }

  @override
  TacticsBoardState? fromJson(Map<String, dynamic> json) {
    try {
      return TacticsBoardState.fromJson(json);
    } catch (e) {
      debugPrint('Error restoring TacticsBoardState: $e');
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(TacticsBoardState state) {
    try {
      return state.toJson();
    } catch (e) {
      debugPrint('Error saving TacticsBoardState: $e');
      return null;
    }
  }
}
