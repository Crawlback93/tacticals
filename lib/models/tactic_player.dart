import 'package:flutter/material.dart';

/// Represents a player on the tactics board
class TacticPlayer {
  final String id;
  final String name;
  final String shortName;
  final int number;
  final Color color;
  final String positionRole;
  final bool isInSquad;
  final bool isCustom; // Custom-created player
  Offset? position; // null = on bench, otherwise field position

  TacticPlayer({
    required this.id,
    required this.name,
    required this.shortName,
    required this.number,
    required this.color,
    this.positionRole = 'Unknown',
    this.isInSquad = true,
    this.isCustom = false,
    this.position,
  });

  TacticPlayer copyWith({
    String? id,
    String? name,
    String? shortName,
    int? number,
    Color? color,
    String? positionRole,
    bool? isInSquad,
    bool? isCustom,
    Offset? position,
    bool clearPosition = false,
  }) {
    return TacticPlayer(
      id: id ?? this.id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      number: number ?? this.number,
      color: color ?? this.color,
      positionRole: positionRole ?? this.positionRole,
      isInSquad: isInSquad ?? this.isInSquad,
      isCustom: isCustom ?? this.isCustom,
      position: clearPosition ? null : (position ?? this.position),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'shortName': shortName,
    'number': number,
    'color': color.toARGB32(),
    'positionRole': positionRole,
    'isInSquad': isInSquad,
    'isCustom': isCustom,
    'position': position != null
        ? {'dx': position!.dx, 'dy': position!.dy}
        : null,
  };

  factory TacticPlayer.fromJson(Map<String, dynamic> json) {
    return TacticPlayer(
      id: json['id'] as String,
      name: json['name'] as String,
      shortName: json['shortName'] as String? ?? json['name'] as String,
      number: json['number'] as int,
      color: Color(json['color'] as int),
      positionRole: json['positionRole'] as String? ?? 'Unknown',
      isInSquad: json['isInSquad'] as bool? ?? true,
      isCustom: json['isCustom'] as bool? ?? false,
      position: json['position'] != null
          ? Offset(
              (json['position']['dx'] as num).toDouble(),
              (json['position']['dy'] as num).toDouble(),
            )
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TacticPlayer &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
