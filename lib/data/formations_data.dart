import 'package:flutter/material.dart';

const Map<String, List<Offset>> formations = {
  '4-4-2': [
    Offset(0.5, 0.9), // GK
    // Back 4
    Offset(0.14, 0.7),
    Offset(0.38, 0.7),
    Offset(0.62, 0.7),
    Offset(0.86, 0.7),

    // Midfield 4
    Offset(0.14, 0.45),
    Offset(0.38, 0.45),
    Offset(0.62, 0.45),
    Offset(0.86, 0.45),

    // Strikers 2
    Offset(0.38, 0.2),
    Offset(0.62, 0.2),
  ],
  '4-3-3': [
    Offset(0.5, 0.9),
    Offset(0.14, 0.7),
    Offset(0.38, 0.7),
    Offset(0.62, 0.7),
    Offset(0.86, 0.7),
    Offset(0.26, 0.45),
    Offset(0.5, 0.5),
    Offset(0.74, 0.45),
    Offset(0.14, 0.2),
    Offset(0.5, 0.15),
    Offset(0.86, 0.2),
  ],
  '3-5-2': [
    Offset(0.5, 0.9),
    Offset(0.26, 0.75),
    Offset(0.5, 0.75),
    Offset(0.74, 0.75),
    Offset(0.1, 0.5),
    Offset(0.32, 0.5),
    Offset(0.5, 0.55),
    Offset(0.68, 0.5),
    Offset(0.9, 0.5),
    Offset(0.38, 0.2),
    Offset(0.62, 0.2),
  ],
  '4-2-3-1': [
    Offset(0.5, 0.9),
    Offset(0.14, 0.75),
    Offset(0.38, 0.75),
    Offset(0.62, 0.75),
    Offset(0.86, 0.75),
    Offset(0.32, 0.6),
    Offset(0.68, 0.6),
    Offset(0.2, 0.45),
    Offset(0.5, 0.45),
    Offset(0.8, 0.45),
    Offset(0.5, 0.25),
  ],
  '4-1-4-1': [
    Offset(0.5, 0.9),
    Offset(0.14, 0.75),
    Offset(0.38, 0.75),
    Offset(0.62, 0.75),
    Offset(0.86, 0.75),
    Offset(0.5, 0.6),
    Offset(0.1, 0.45),
    Offset(0.32, 0.45),
    Offset(0.68, 0.45),
    Offset(0.9, 0.45),
    Offset(0.5, 0.25),
  ],
  '4-4-1-1': [
    Offset(0.5, 0.9),
    Offset(0.14, 0.75),
    Offset(0.38, 0.75),
    Offset(0.62, 0.75),
    Offset(0.86, 0.75),
    Offset(0.14, 0.5),
    Offset(0.38, 0.5),
    Offset(0.62, 0.5),
    Offset(0.86, 0.5),
    Offset(0.5, 0.33),
    Offset(0.5, 0.2),
  ],
  '4-3-1-2': [
    Offset(0.5, 0.9),
    Offset(0.14, 0.71),
    Offset(0.38, 0.75),
    Offset(0.62, 0.75),
    Offset(0.86, 0.71),
    Offset(0.26, 0.55),
    Offset(0.5, 0.58),
    Offset(0.74, 0.55),
    Offset(0.5, 0.4),
    Offset(0.38, 0.23),
    Offset(0.62, 0.23),
  ],
  '4-3-2-1': [
    Offset(0.5, 0.9),
    Offset(0.14, 0.78),
    Offset(0.38, 0.78),
    Offset(0.62, 0.78),
    Offset(0.86, 0.78),
    Offset(0.26, 0.62),
    Offset(0.5, 0.62),
    Offset(0.74, 0.62),
    Offset(0.38, 0.45),
    Offset(0.62, 0.45),
    Offset(0.5, 0.25),
  ],
  '4-2-2-2': [
    Offset(0.5, 0.9),
    Offset(0.14, 0.75),
    Offset(0.38, 0.75),
    Offset(0.62, 0.75),
    Offset(0.86, 0.75),
    Offset(0.32, 0.6),
    Offset(0.68, 0.6),
    Offset(0.26, 0.45),
    Offset(0.74, 0.45),
    Offset(0.38, 0.25),
    Offset(0.62, 0.25),
  ],
  '3-4-3': [
    Offset(0.5, 0.9),
    Offset(0.26, 0.78),
    Offset(0.5, 0.78),
    Offset(0.74, 0.78),
    Offset(0.1, 0.58),
    Offset(0.32, 0.58),
    Offset(0.68, 0.58),
    Offset(0.9, 0.58),
    Offset(0.2, 0.28),
    Offset(0.5, 0.22),
    Offset(0.8, 0.28),
  ],
  '3-4-2-1': [
    Offset(0.5, 0.9),
    Offset(0.26, 0.8),
    Offset(0.5, 0.8),
    Offset(0.74, 0.8),
    Offset(0.1, 0.62),
    Offset(0.32, 0.62),
    Offset(0.68, 0.62),
    Offset(0.9, 0.62),
    Offset(0.38, 0.42),
    Offset(0.62, 0.42),
    Offset(0.5, 0.24),
  ],
  '3-4-1-2': [
    Offset(0.5, 0.9),
    Offset(0.26, 0.8),
    Offset(0.5, 0.8),
    Offset(0.74, 0.8),
    Offset(0.1, 0.62),
    Offset(0.32, 0.62),
    Offset(0.68, 0.62),
    Offset(0.9, 0.62),
    Offset(0.5, 0.42),
    Offset(0.38, 0.25),
    Offset(0.62, 0.25),
  ],
  '3-2-4-1': [
    Offset(0.5, 0.9),
    Offset(0.26, 0.82),
    Offset(0.5, 0.82),
    Offset(0.74, 0.82),
    Offset(0.38, 0.68),
    Offset(0.62, 0.68),
    Offset(0.1, 0.5),
    Offset(0.32, 0.5),
    Offset(0.68, 0.5),
    Offset(0.9, 0.5),
    Offset(0.5, 0.28),
  ],
  '5-3-2': [
    Offset(0.5, 0.9),
    Offset(0.1, 0.8),
    Offset(0.26, 0.78),
    Offset(0.5, 0.8),
    Offset(0.74, 0.78),
    Offset(0.9, 0.8),
    Offset(0.26, 0.58),
    Offset(0.5, 0.6),
    Offset(0.74, 0.58),
    Offset(0.38, 0.25),
    Offset(0.62, 0.25),
  ],
  '5-4-1': [
    Offset(0.5, 0.9),
    Offset(0.1, 0.8),
    Offset(0.26, 0.78),
    Offset(0.5, 0.8),
    Offset(0.74, 0.78),
    Offset(0.9, 0.8),
    Offset(0.14, 0.6),
    Offset(0.38, 0.6),
    Offset(0.62, 0.6),
    Offset(0.86, 0.6),
    Offset(0.5, 0.28),
  ],
  '5-2-3': [
    Offset(0.5, 0.9),
    Offset(0.1, 0.8),
    Offset(0.26, 0.78),
    Offset(0.5, 0.8),
    Offset(0.74, 0.78),
    Offset(0.9, 0.8),
    Offset(0.38, 0.62),
    Offset(0.62, 0.62),
    Offset(0.2, 0.28),
    Offset(0.5, 0.22),
    Offset(0.8, 0.28),
  ],
};

/// Get position indices for a formation based on its name
/// e.g., "4-4-2" -> {GK: [0], DEF: [1-4], MID: [5-8], ATT: [9-10]}
Map<String, List<int>> getPositionIndices(String formation) {
  final parts = formation.split('-').map((e) => int.tryParse(e) ?? 0).toList();
  final result = <String, List<int>>{
    'Goalkeeper': [0],
    'Defender': [],
    'Midfielder': [],
    'Attacker': [],
  };

  int currentIndex = 1; // Start after goalkeeper

  if (parts.length >= 3) {
    // First number is defenders
    for (int i = 0; i < parts[0]; i++) {
      result['Defender']!.add(currentIndex++);
    }

    // Middle numbers are midfielders
    for (int i = 1; i < parts.length - 1; i++) {
      for (int j = 0; j < parts[i]; j++) {
        result['Midfielder']!.add(currentIndex++);
      }
    }

    // Last number is attackers
    for (int i = 0; i < parts[parts.length - 1]; i++) {
      result['Attacker']!.add(currentIndex++);
    }
  }

  return result;
}

/// Get color for position
Color getPositionColor(String? position) {
  switch (position) {
    case 'Goalkeeper':
      return Colors.yellow;
    case 'Defender':
      return Colors.blue;
    case 'Midfielder':
      return Colors.green;
    case 'Attacker':
      return Colors.red;
    default:
      return Colors.grey;
  }
}
