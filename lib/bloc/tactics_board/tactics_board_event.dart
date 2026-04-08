import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../data/competitions_data.dart';

abstract class TacticsBoardEvent extends Equatable {
  const TacticsBoardEvent();

  @override
  List<Object?> get props => [];
}

/// Competition selection
class SelectCompetition extends TacticsBoardEvent {
  final Competition? competition;
  const SelectCompetition(this.competition);

  @override
  List<Object?> get props => [competition];
}

/// Team selection
class SelectTeam extends TacticsBoardEvent {
  final String? teamId;
  const SelectTeam(this.teamId);

  @override
  List<Object?> get props => [teamId];
}

/// Teams loaded from API
class TeamsLoaded extends TacticsBoardEvent {
  final List<dynamic> teams;
  const TeamsLoaded(this.teams);

  @override
  List<Object?> get props => [teams];
}

/// Squad loaded from Supabase
class SquadLoaded extends TacticsBoardEvent {
  final List<TacticPlayer> players;
  const SquadLoaded(this.players);

  @override
  List<Object?> get props => [players];
}

/// Formation change
class SelectFormation extends TacticsBoardEvent {
  final String formation;
  const SelectFormation(this.formation);

  @override
  List<Object?> get props => [formation];
}

/// Toggle board orientation
class ToggleOrientation extends TacticsBoardEvent {
  const ToggleOrientation();
}

/// Toggle snap points visibility
class ToggleSnapPoints extends TacticsBoardEvent {
  const ToggleSnapPoints();
}

/// Toggle magnetize
class ToggleMagnetize extends TacticsBoardEvent {
  const ToggleMagnetize();
}

/// Toggle player names
class TogglePlayerNames extends TacticsBoardEvent {
  const TogglePlayerNames();
}

/// Change field scale
class SetFieldScale extends TacticsBoardEvent {
  final double scale;
  const SetFieldScale(this.scale);

  @override
  List<Object?> get props => [scale];
}

/// Change field style
class SetFieldStyle extends TacticsBoardEvent {
  final String fieldStyle;
  const SetFieldStyle(this.fieldStyle);

  @override
  List<Object?> get props => [fieldStyle];
}

/// Add player to field
class AddPlayerToField extends TacticsBoardEvent {
  final TacticPlayer player;
  final Offset position;
  const AddPlayerToField(this.player, this.position);

  @override
  List<Object?> get props => [player, position];
}

/// Move player on field
class MovePlayer extends TacticsBoardEvent {
  final String playerId;
  final Offset position;
  const MovePlayer(this.playerId, this.position);

  @override
  List<Object?> get props => [playerId, position];
}

/// Remove player from field (back to bench)
class RemovePlayerFromField extends TacticsBoardEvent {
  final String playerId;
  const RemovePlayerFromField(this.playerId);

  @override
  List<Object?> get props => [playerId];
}

/// Clear all players from field
class ClearField extends TacticsBoardEvent {
  const ClearField();
}

/// Set loading state
class SetLoading extends TacticsBoardEvent {
  final bool isLoading;
  const SetLoading(this.isLoading);

  @override
  List<Object?> get props => [isLoading];
}

/// Set dragging player (for visual feedback)
class SetDraggingPlayer extends TacticsBoardEvent {
  final TacticPlayer? player;
  const SetDraggingPlayer(this.player);

  @override
  List<Object?> get props => [player];
}

/// Restore state from storage
class RestoreState extends TacticsBoardEvent {
  const RestoreState();
}
