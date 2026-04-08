/// Board display settings
class BoardSettings {
  final bool isVertical;
  final bool showSnapPoints;
  final bool magnetize;
  final bool showPlayerNames;
  final double fieldScale;
  final String selectedFormation;
  final String fieldStyle;

  const BoardSettings({
    this.isVertical = false,
    this.showSnapPoints = true,
    this.magnetize = true,
    this.showPlayerNames = false,
    this.fieldScale = 1.0,
    this.selectedFormation = '4-4-2',
    this.fieldStyle = 'classic',
  });

  BoardSettings copyWith({
    bool? isVertical,
    bool? showSnapPoints,
    bool? magnetize,
    bool? showPlayerNames,
    double? fieldScale,
    String? selectedFormation,
    String? fieldStyle,
  }) {
    return BoardSettings(
      isVertical: isVertical ?? this.isVertical,
      showSnapPoints: showSnapPoints ?? this.showSnapPoints,
      magnetize: magnetize ?? this.magnetize,
      showPlayerNames: showPlayerNames ?? this.showPlayerNames,
      fieldScale: fieldScale ?? this.fieldScale,
      selectedFormation: selectedFormation ?? this.selectedFormation,
      fieldStyle: fieldStyle ?? this.fieldStyle,
    );
  }

  Map<String, dynamic> toJson() => {
    'isVertical': isVertical,
    'showSnapPoints': showSnapPoints,
    'magnetize': magnetize,
    'showPlayerNames': showPlayerNames,
    'fieldScale': fieldScale,
    'selectedFormation': selectedFormation,
    'fieldStyle': fieldStyle,
  };

  factory BoardSettings.fromJson(Map<String, dynamic> json) {
    return BoardSettings(
      isVertical: json['isVertical'] as bool? ?? false,
      showSnapPoints: json['showSnapPoints'] as bool? ?? true,
      magnetize: json['magnetize'] as bool? ?? true,
      showPlayerNames: json['showPlayerNames'] as bool? ?? false,
      fieldScale: (json['fieldScale'] as num?)?.toDouble() ?? 1.0,
      selectedFormation: json['selectedFormation'] as String? ?? '4-4-2',
      fieldStyle: json['fieldStyle'] as String? ?? 'classic',
    );
  }
}
