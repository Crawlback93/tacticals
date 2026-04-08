class BoardModel {
  final String id;
  final String ownerId;
  final String title;
  final String? competitionId;
  final String? homeTeamId;
  final String? awayTeamId;
  final String? formationHome;
  final String? formationAway;
  final Map<String, dynamic> snapshot;
  final String? thumbnailUrl;
  final bool isTemplate;
  final bool isArchived;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BoardModel({
    required this.id,
    required this.ownerId,
    required this.title,
    this.competitionId,
    this.homeTeamId,
    this.awayTeamId,
    this.formationHome,
    this.formationAway,
    this.snapshot = const {},
    this.thumbnailUrl,
    this.isTemplate = false,
    this.isArchived = false,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BoardModel.fromJson(Map<String, dynamic> json) {
    return BoardModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      title: json['title'] as String,
      competitionId: json['competition_id'] as String?,
      homeTeamId: json['home_team_id'] as String?,
      awayTeamId: json['away_team_id'] as String?,
      formationHome: json['formation_home'] as String?,
      formationAway: json['formation_away'] as String?,
      snapshot: (json['snapshot'] as Map<String, dynamic>?) ?? {},
      thumbnailUrl: json['thumbnail_url'] as String?,
      isTemplate: json['is_template'] as bool? ?? false,
      isArchived: json['is_archived'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'owner_id': ownerId,
    'title': title,
    'competition_id': competitionId,
    'home_team_id': homeTeamId,
    'away_team_id': awayTeamId,
    'formation_home': formationHome,
    'formation_away': formationAway,
    'snapshot': snapshot,
    'thumbnail_url': thumbnailUrl,
    'is_template': isTemplate,
    'is_archived': isArchived,
    'sort_order': sortOrder,
  };

  /// Relative time label for display: "2H AGO", "YESTERDAY", etc.
  String get timeLabel {
    final diff = DateTime.now().difference(updatedAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}M AGO';
    if (diff.inHours < 24) return '${diff.inHours}H AGO';
    if (diff.inDays == 1) return 'YESTERDAY';
    if (diff.inDays < 7) return '${diff.inDays}D AGO';
    return '${(diff.inDays / 7).floor()}W AGO';
  }
}
