import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:crypto/crypto.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'bloc/tactics_board/tactics_board.dart';
import 'services/board_service.dart';
import 'services/competition_service.dart';
import 'utils/web_utils_stub.dart'
    // ignore: uri_does_not_exist
    if (dart.library.html) 'utils/web_utils_web.dart';
import 'models/models.dart';
import 'data/competitions_data.dart';
import 'data/formations_data.dart';
import 'widgets/drawing_layer.dart';
import 'widgets/field_controls_toolbar.dart';
import 'widgets/football_pitch_painter.dart';
import 'widgets/add_player_dialog.dart';
import 'widgets/drawing_toolbar_drop_zones.dart';
import 'widgets/squad_sidebar.dart';

class TacticsBoardPage extends StatefulWidget {
  final String? boardId;
  final String? boardTitle;
  final Map<String, dynamic>? initialSnapshot;

  const TacticsBoardPage({super.key, this.boardId, this.boardTitle, this.initialSnapshot});

  @override
  State<TacticsBoardPage> createState() => _TacticsBoardPageState();
}

class _TacticsBoardPageState extends State<TacticsBoardPage>
    with TickerProviderStateMixin {
  bool _isVertical = false;
  FieldStyle _fieldStyle = FieldStyle.classic;
  bool _showSnapPoints = true;

  // Board name
  String _boardName = 'My Board';
  bool _isEditingName = false;
  late final TextEditingController _nameController;
  bool _magnetize = false;
  bool _showPlayerNames = false;
  String _selectedFormation = '4-4-2';
  double _fieldScale = 1.0;
  bool _isLoading = false;
  String _playerSearchQuery = '';

  // Orientation transition animation
  double _fieldOpacity = 1.0;
  bool _isTransitioning = false;

  // Sidebar visibility and animation
  bool _showSidebar = true;
  late final AnimationController _sidebarController;
  late final Animation<double> _sidebarFade;
  late final AnimationController _headerController;
  late final Animation<double> _headerSlide;
  late final Animation<double> _headerFade;

  List<Competition> _competitions = [];
  Competition? _selectedCompetition;
  int? _pendingRestoreCompetitionApiId;
  List<dynamic> _teams = [];
  String? _selectedTeamId;

  // Players on the field
  final List<TacticPlayer> _fieldPlayers = [];

  // Players in the list (bench)
  List<TacticPlayer> _benchPlayers = [];

  // Currently dragging player (for highlighting snap points)
  TacticPlayer? _draggingPlayer;

  // Player returning to bench (for animation)
  TacticPlayer? _returningPlayer;

  // Flag to prevent multiple restore dialogs
  bool _hasCheckedSavedState = false;

  // Auto-save state
  Timer? _saveDebounceTimer;
  String? _lastSavedHash;
  DateTime? _lastSavedAt;
  bool _isSaving = false;
  void Function()? _removeBeforeUnload;

  // Last known pixel size of the football field (updated each build)
  Size _lastFieldSize = Size.zero;
  // Last known max container size (maxWidth*0.9, maxHeight*0.9) from LayoutBuilder
  Size _lastFieldContainerSize = Size.zero;

  // Drawing layer key and state for external toolbar
  final GlobalKey<DrawingLayerState> _drawingLayerKey =
      GlobalKey<DrawingLayerState>();
  bool _drawingToolbarVisible = false;
  ToolbarSide _drawingToolbarSide = ToolbarSide.bottom;
  bool _isDrawingBarDragging = false;
  ToolbarSide _liveDragSide = ToolbarSide.bottom;
  OverlayEntry? _floatingToolbarOverlay;
  final _floatingToolbarPos = ValueNotifier<Offset>(Offset.zero);
  final _isDrawingBarDraggingNotifier = ValueNotifier<bool>(false);
  final _drawingBarDragPosNotifier = ValueNotifier<Offset>(Offset.zero);

  @override
  void initState() {
    super.initState();

    // Sidebar animation controller
    _sidebarController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _sidebarFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _sidebarController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
        reverseCurve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    // Header bar entrance animation
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _headerSlide = Tween<double>(begin: -100.0, end: 0.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutBack),
    );

    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOut),
    );

    if (widget.boardTitle != null) {
      _boardName = widget.boardTitle!;
    }
    _nameController = TextEditingController(text: _boardName);

    // Apply persisted settings from Supabase snapshot immediately
    final snap = widget.initialSnapshot;
    if (snap != null && snap.isNotEmpty) {
      _applySnapshotSettings(snap);
    }

    // Start with sidebar visible
    if (_showSidebar) {
      _sidebarController.value = 1.0;
    }

    // Animate header bar in on load (300ms delay mirrors drawing toolbar timing)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _headerController.forward();
      });
    });

    // Register beforeunload — only prompt if there are unsaved changes
    if (widget.boardId != null) {
      _removeBeforeUnload = registerBeforeUnload(() => _hasUnsavedChanges());
    }

    // Load competitions from Supabase
    _loadCompetitions();

    // If opened via URL (/board/:id) without pre-loaded snapshot — fetch it
    if (widget.boardId != null && widget.initialSnapshot == null) {
      _loadBoardIfNeeded();
    }

    // Check for saved state and restore drawings after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForSavedState();
      // Apply drawing elements from initialSnapshot
      final drawingJson =
          widget.initialSnapshot?['drawing'] as Map<String, dynamic>?;
      if (drawingJson != null) {
        _drawingLayerKey.currentState?.loadFromSnapshot(drawingJson);
      }
    });
  }

  @override
  void dispose() {
    _saveDebounceTimer?.cancel();
    _removeBeforeUnload?.call();
    _floatingToolbarOverlay?.remove();
    _floatingToolbarPos.dispose();
    _isDrawingBarDraggingNotifier.dispose();
    _drawingBarDragPosNotifier.dispose();
    _sidebarController.dispose();
    _headerController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    if (_showSidebar) {
      _sidebarController.reverse();
    } else {
      setState(() => _showSidebar = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sidebarController.forward();
      });
    }
    if (_showSidebar) {
      _sidebarController.addStatusListener(_onSidebarAnimationStatus);
    }
  }

  void _onSidebarAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) {
      setState(() => _showSidebar = false);
      _sidebarController.removeStatusListener(_onSidebarAnimationStatus);
    }
  }

  void _checkForSavedState() {
    if (_hasCheckedSavedState) return;
    _hasCheckedSavedState = true;

    final bloc = context.read<TacticsBoardBloc>();
    final savedState = bloc.state;

    // Check if there's meaningful saved data
    final hasPlayers = savedState.allPlayers.isNotEmpty;
    final hasFieldPlayers = savedState.fieldPlayers.isNotEmpty;
    final hasCompetition = savedState.selectedCompetition != null;

    debugPrint(
      'Checking saved state: hasPlayers=$hasPlayers, hasFieldPlayers=$hasFieldPlayers, hasCompetition=$hasCompetition',
    );

    // Only show restore dialog for new boards (no boardId) — existing boards
    // load their data directly from Supabase without prompting.
    if (widget.boardId == null && (hasPlayers || hasFieldPlayers || hasCompetition)) {
      _showRestoreDialog(savedState);
    }
  }

  void _showRestoreDialog(TacticsBoardState savedState) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF222222),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title row
              Row(
                children: [
                  const Icon(
                    LucideIcons.history,
                    color: Color(0xFFFDD329),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Restore Session?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _startFresh();
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Icon(
                        LucideIcons.x,
                        color: Colors.white.withValues(alpha: 0.35),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'We found a previously saved session.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),

              // Info rows
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
                ),
                child: Column(
                  children: [
                    if (savedState.selectedCompetition != null)
                      _buildSavedInfo(LucideIcons.trophy, 'Competition', savedState.selectedCompetition!.name),
                    if (savedState.fieldPlayers.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildSavedInfo(LucideIcons.users, 'Players on field', '${savedState.fieldPlayers.length}'),
                    ],
                    if (savedState.allPlayers.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildSavedInfo(LucideIcons.userCheck, 'Squad size', '${savedState.allPlayers.length}'),
                    ],
                    const SizedBox(height: 8),
                    _buildSavedInfo(LucideIcons.layoutGrid, 'Formation', savedState.settings.selectedFormation),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: _RestoreDialogButton(
                      label: 'Start Fresh',
                      isSecondary: true,
                      onTap: () {
                        Navigator.pop(ctx);
                        _startFresh();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _RestoreDialogButton(
                      label: 'Restore',
                      onTap: () {
                        Navigator.pop(ctx);
                        _restoreFromBloc(savedState);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSavedInfo(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.35), size: 14),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 12,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _startFresh() {
    // Clear BLoC state
    context.read<TacticsBoardBloc>().add(ClearField());
    // Local state is already empty from initState
  }

  void _restoreFromBloc(TacticsBoardState savedState) {
    // Match saved competition to an already-loaded list item by apiId.
    // If the list isn't ready yet, _resolveRestoredCompetition() will fix it
    // once _loadCompetitions() finishes.
    Competition? resolvedCompetition;
    final savedComp = savedState.selectedCompetition;
    if (savedComp != null) {
      resolvedCompetition = _competitions.firstWhere(
        (c) => c.apiId == savedComp.apiId,
        orElse: () => savedComp,
      );
    }

    setState(() {
      _selectedCompetition = resolvedCompetition;
      _pendingRestoreCompetitionApiId =
          (resolvedCompetition != null && _competitions.isEmpty)
              ? savedComp?.apiId
              : null;
      _selectedTeamId = savedState.selectedTeamId;
      _isVertical = savedState.settings.isVertical;
      _showSnapPoints = savedState.settings.showSnapPoints;
      _magnetize = savedState.settings.magnetize;
      _showPlayerNames = savedState.settings.showPlayerNames;
      _fieldScale = savedState.settings.fieldScale;
      _selectedFormation = savedState.settings.selectedFormation;
      _fieldStyle = FieldStyle.values.firstWhere(
        (s) => s.name == savedState.settings.fieldStyle,
        orElse: () => FieldStyle.classic,
      );

      // Restore players (ensure no duplicates)
      _fieldPlayers.clear();
      _benchPlayers = [];
      final seenIds = <String>{};

      for (final player in savedState.allPlayers) {
        if (!seenIds.add(player.id)) continue; // Skip duplicates
        if (player.position != null) {
          _fieldPlayers.add(player);
        } else {
          _benchPlayers.add(player);
        }
      }
    });

    // Fetch teams if competition is selected
    if (_selectedCompetition != null) {
      _fetchTeams();
    }

    // Load drawing elements from Supabase snapshot (not stored in BLoC)
    if (widget.boardId != null) {
      _restoreDrawingsFromSupabase();
    }
  }

  Future<void> _restoreDrawingsFromSupabase() async {
    try {
      final board = await BoardService.fetchBoardById(widget.boardId!);
      if (!mounted) return;
      final drawingJson =
          board.snapshot['drawing'] as Map<String, dynamic>?;
      if (drawingJson != null) {
        _drawingLayerKey.currentState?.loadFromSnapshot(drawingJson);
      }
    } catch (e) {
      debugPrint('_restoreDrawingsFromSupabase error: $e');
    }
  }

  void _saveToBloc() {
    final bloc = context.read<TacticsBoardBloc>();

    // Update settings
    bloc.add(SelectCompetition(_selectedCompetition));
    bloc.add(SelectTeam(_selectedTeamId));

    // Combine field and bench players, ensuring no duplicates
    final seenIds = <String>{};
    final allPlayers = <TacticPlayer>[];
    for (final player in [..._fieldPlayers, ..._benchPlayers]) {
      if (seenIds.add(player.id)) {
        allPlayers.add(player);
      }
    }
    bloc.add(SquadLoaded(allPlayers));

    // Update settings through events
    if (_isVertical != bloc.state.settings.isVertical) {
      bloc.add(ToggleOrientation());
    }
    if (_showSnapPoints != bloc.state.settings.showSnapPoints) {
      bloc.add(ToggleSnapPoints());
    }
    if (_magnetize != bloc.state.settings.magnetize) {
      bloc.add(ToggleMagnetize());
    }
    if (_showPlayerNames != bloc.state.settings.showPlayerNames) {
      bloc.add(TogglePlayerNames());
    }
    bloc.add(SetFieldScale(_fieldScale));
    bloc.add(SelectFormation(_selectedFormation));
    bloc.add(SetFieldStyle(_fieldStyle.name));

    debugPrint(
      'Saved to BLoC: ${allPlayers.length} players, competition: ${_selectedCompetition?.name}',
    );
  }

  /// Build a snapshot map (without undo/redo to keep it small)
  Map<String, dynamic> _buildSnapshot() {
    final boardState = context.read<TacticsBoardBloc>().state;
    final drawingElements =
        _drawingLayerKey.currentState?.state.elements ?? [];

    // Merge local state that lives outside the bloc (fieldStyle, formation)
    final boardJson = boardState.toJson();
    final settings = Map<String, dynamic>.from(
      boardJson['settings'] as Map<String, dynamic>? ?? {},
    );
    settings['fieldStyle'] = _fieldStyle.name;
    settings['selectedFormation'] = _selectedFormation;
    boardJson['settings'] = settings;

    return {
      'board': boardJson,
      'drawing': {
        'elements': drawingElements.map((e) => e.toJson()).toList(),
      },
    };
  }

  /// Compute a stable hash string from a snapshot map
  String _computeHash(Map<String, dynamic> snapshot) {
    final encoded = jsonEncode(snapshot);
    final bytes = utf8.encode(encoded);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Persist snapshot to Supabase if it changed since last save
  Future<void> _saveToSupabase() async {
    final boardId = widget.boardId;
    if (boardId == null || !mounted) return;

    final snapshot = _buildSnapshot();
    final hash = _computeHash(snapshot);

    if (hash == _lastSavedHash) return; // Nothing changed

    if (!mounted) return;
    setState(() => _isSaving = true);

    try {
      await BoardService.saveSnapshot(
        boardId,
        snapshot,
        formationHome: _selectedFormation,
      );
      if (mounted) {
        setState(() {
          _lastSavedHash = hash;
          _lastSavedAt = DateTime.now();
          _isSaving = false;
        });
      }
    } catch (e) {
      debugPrint('Auto-save error: $e');
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Schedule a debounced save (10 seconds after last change)
  void _scheduleSave() {
    _saveToBloc();
    if (widget.boardId == null) return;
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(const Duration(seconds: 10), _saveToSupabase);
  }

  /// Returns true if there are changes not yet saved to Supabase
  bool _hasUnsavedChanges() {
    if (widget.boardId == null) return false;
    try {
      final snapshot = _buildSnapshot();
      final hash = _computeHash(snapshot);
      return hash != _lastSavedHash;
    } catch (_) {
      return false;
    }
  }

  /// Force immediate save (used on back/close)
  Future<void> _forceSave() async {
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = null;
    await _saveToSupabase();
  }

  Future<void> _loadBoardIfNeeded() async {
    try {
      final board = await BoardService.fetchBoardById(widget.boardId!);
      if (!mounted) return;
      setState(() {
        _boardName = board.title;
        _nameController.text = board.title;
        final snap = board.snapshot;
        if (snap.isNotEmpty) {
          _applySnapshotSettings(snap);
          final drawingJson = snap['drawing'] as Map<String, dynamic>?;
          if (drawingJson != null) {
            _drawingLayerKey.currentState?.loadFromSnapshot(drawingJson);
          }
        }
      });
    } catch (e) {
      debugPrint('_loadBoardIfNeeded error: $e');
    }
  }

  /// Reads all persisted fields from a snapshot map and applies them to local state.
  /// Must be called inside setState or synchronously in initState.
  void _applySnapshotSettings(Map<String, dynamic> snap) {
    final boardJson = snap['board'] as Map<String, dynamic>?;
    final settings = boardJson?['settings'] as Map<String, dynamic>?;

    if (settings != null) {
      final styleStr = settings['fieldStyle'] as String?;
      if (styleStr != null) {
        _fieldStyle = FieldStyle.values.firstWhere(
          (s) => s.name == styleStr,
          orElse: () => FieldStyle.classic,
        );
      }
      final formation = settings['selectedFormation'] as String?;
      if (formation != null) _selectedFormation = formation;
      final isVertical = settings['isVertical'] as bool?;
      if (isVertical != null) _isVertical = isVertical;
      final scale = (settings['fieldScale'] as num?)?.toDouble();
      if (scale != null) _fieldScale = scale;
      final showSnap = settings['showSnapPoints'] as bool?;
      if (showSnap != null) _showSnapPoints = showSnap;
      final magnetize = settings['magnetize'] as bool?;
      if (magnetize != null) _magnetize = magnetize;
      final showNames = settings['showPlayerNames'] as bool?;
      if (showNames != null) _showPlayerNames = showNames;
    }

    // Restore competition and team — store as pending until competitions list loads
    final competitionApiId = boardJson?['selectedCompetitionId'] as int?;
    final teamId = boardJson?['selectedTeamId'] as String?;

    if (competitionApiId != null) {
      // Try to resolve immediately if competitions already loaded
      final found = _competitions.where((c) => c.apiId == competitionApiId);
      if (found.isNotEmpty) {
        _selectedCompetition = found.first;
      } else {
        _pendingRestoreCompetitionApiId = competitionApiId;
      }
    }
    if (teamId != null) {
      // Apply immediately — teams will be fetched after competition resolves
      _selectedTeamId = teamId;
    }
  }

  Future<void> _loadCompetitions() async {
    try {
      final list = await CompetitionService.fetchCompetitions();
      if (!mounted) return;
      setState(() {
        _competitions = list;
        // Resolve pending competition from snapshot restore
        if (_pendingRestoreCompetitionApiId != null) {
          final found = list.where(
            (c) => c.apiId == _pendingRestoreCompetitionApiId,
          );
          if (found.isNotEmpty) _selectedCompetition = found.first;
          _pendingRestoreCompetitionApiId = null;
        }
      });
      // Fetch teams now that competition is resolved
      if (_selectedCompetition != null) {
        await _fetchTeams();
      }
    } catch (e) {
      debugPrint('_loadCompetitions error: $e');
    }
  }

  Future<void> _fetchTeams() async {
    if (_selectedCompetition == null) return;

    setState(() => _isLoading = true);
    debugPrint(
      '_fetchTeams: loading from Supabase for ${_selectedCompetition!.name}',
    );

    try {
      final supabase = Supabase.instance.client;

      // Find competition in DB by external_id (apiId)
      final compRows = await supabase
          .from('competitions')
          .select('id')
          .eq('external_id', _selectedCompetition!.apiId)
          .limit(1);

      if ((compRows as List).isEmpty) {
        debugPrint('_fetchTeams: competition not found in DB');
        setState(() => _teams = []);
        return;
      }

      final competitionId = compRows.first['id'] as String;

      // Get teams for this competition via competition_teams
      final rows = await supabase
          .from('competition_teams')
          .select('teams(id, name, short_name, slug, color_primary)')
          .eq('competition_id', competitionId)
          .eq('is_active', true);

      final teams = <Map<String, dynamic>>[];
      for (final row in rows as List) {
        final team = row['teams'] as Map<String, dynamic>?;
        if (team == null) continue;
        teams.add({
          'team': {
            'id': team['slug'],   // use slug as id for routing
            'name': team['name'],
            'short_name': team['short_name'],
            'color': team['color_primary'],
          },
        });
      }

      teams.sort(
        (a, b) => (a['team']['name'] as String).compareTo(
          b['team']['name'] as String,
        ),
      );

      setState(() => _teams = teams);
      debugPrint('_fetchTeams: loaded ${_teams.length} teams');
    } catch (e) {
      debugPrint('_fetchTeams error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Pre-fetch all players for the current competition and cache them

  /// Get players for a team from cache, or fetch if not cached
  Future<void> _fetchSquad(String teamSlug) async {
    // Players table not yet available in DB — bench stays empty
    debugPrint('_fetchSquad: team=$teamSlug (players table not yet populated)');
    setState(() {
      _fieldPlayers.clear();
      _benchPlayers = [];
    });
    _scheduleSave();
  }



  /// Load players from cached data (used when switching teams)

  /// Check if there are any elements on the field (players or drawings)
  bool _hasFieldElements() {
    // Check for players on field
    if (_fieldPlayers.isNotEmpty) return true;

    // Check for drawing elements
    final drawingState = _drawingLayerKey.currentState?.state;
    if (drawingState != null && drawingState.elements.isNotEmpty) return true;

    return false;
  }

  /// Show confirmation dialog when switching teams with elements on field
  Future<bool> _confirmTeamChange() async {
    if (!_hasFieldElements()) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Clear Field?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Switching teams will clear all players and drawings from the field. Do you want to continue?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear & Switch'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Clear all field elements (players and drawings)
  void _clearFieldElements() {
    setState(() {
      _fieldPlayers.clear();
    });
    // Clear drawing elements
    _drawingLayerKey.currentState?.state.clearAll();
  }

  /// Show dialog to add a custom player
  Future<void> _showAddPlayerDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => const AddPlayerDialog(),
    );

    if (result != null) {
      final customPlayer = TacticPlayer(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        name: result['name'] as String,
        shortName: result['name'] as String,
        number: result['number'] as int,
        positionRole: result['position'] as String,
        isCustom: true,
        isInSquad: true,
        color: result['position'] == 'Goalkeeper'
            ? Colors.yellow[700]!
            : Colors.blue,
      );

      setState(() {
        _benchPlayers.insert(0, customPlayer);
      });
      _scheduleSave();
    }
  }

  /// Animate orientation change with fade out/in
  Future<void> _animateOrientationChange(bool toVertical) async {
    if (_isTransitioning) return;
    _isTransitioning = true;

    // Fade out
    setState(() => _fieldOpacity = 0.0);

    // Wait for fade out
    await Future.delayed(const Duration(milliseconds: 150));

    // Compute new field size after rotation (aspect ratio flips)
    final oldSize = _lastFieldSize;
    final container = _lastFieldContainerSize;
    Size newSize = Size.zero;
    if (!oldSize.isEmpty && !container.isEmpty) {
      final double newAspect = toVertical ? (2 / 3) : (3 / 2);
      double newW, newH;
      if (container.width / container.height > newAspect) {
        newH = container.height;
        newW = newH * newAspect;
      } else {
        newW = container.width;
        newH = newW / newAspect;
      }
      newW *= _fieldScale;
      newH *= _fieldScale;
      newSize = Size(newW, newH);
    }

    // Rotate drawing elements to match the new field orientation
    if (!oldSize.isEmpty && !newSize.isEmpty) {
      _drawingLayerKey.currentState?.rotateElements(toVertical, oldSize, newSize);
    }

    // Change orientation
    setState(() {
      _isVertical = toVertical;
      _rotatePlayers(toVertical);
    });

    // Fade in
    setState(() => _fieldOpacity = 1.0);

    _isTransitioning = false;
    _scheduleSave();
  }

  void _clearField() {
    setState(() {
      for (final player in _fieldPlayers) {
        player.position = null;
      }
      _benchPlayers.addAll(_fieldPlayers);
      _fieldPlayers.clear();
      _benchPlayers.sort((a, b) {
        if (a.isInSquad != b.isInSquad) return a.isInSquad ? -1 : 1;
        final posOrder = {
          'Goalkeeper': 0,
          'Defender': 1,
          'Midfielder': 2,
          'Attacker': 3,
        };
        int orderA = posOrder[a.positionRole] ?? 4;
        int orderB = posOrder[b.positionRole] ?? 4;
        if (orderA != orderB) return orderA.compareTo(orderB);
        return a.number.compareTo(b.number);
      });
    });
    _scheduleSave();
  }


  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _forceSave();
        if (context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
      backgroundColor: const Color(0xFF171717),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            // Main Field Area
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF222222),
                  borderRadius: BorderRadius.circular(24),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    // Pitch
                    Center(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          double maxWidth = constraints.maxWidth * 0.9;
                          double maxHeight = constraints.maxHeight * 0.9;
                          _lastFieldContainerSize = Size(maxWidth, maxHeight);
                          final double fieldAspectRatio = _isVertical
                              ? 2 / 3
                              : 3 / 2;
                          double width, height;
                          if (maxWidth / maxHeight > fieldAspectRatio) {
                            height = maxHeight;
                            width = height * fieldAspectRatio;
                          } else {
                            width = maxWidth;
                            height = width / fieldAspectRatio;
                          }
                          width *= _fieldScale;
                          height *= _fieldScale;
                          _lastFieldSize = Size(width, height);
                          return AnimatedOpacity(
                            opacity: _fieldOpacity,
                            duration: const Duration(milliseconds: 150),
                            child: SizedBox(
                              width: width,
                              height: height,
                              child: _buildFootballField(width, height),
                            ),
                          );
                        },
                      ),
                    ),

                    // Header Bar - floats over the field, top-center, wraps content
                    Positioned(
                      top: 12,
                      left: 0,
                      right: 0,
                      child: AnimatedBuilder(
                        animation: _headerController,
                        builder: (context, child) => Transform.translate(
                          offset: Offset(0, _headerSlide.value),
                          child: Opacity(opacity: _headerFade.value, child: child),
                        ),
                        child: Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minWidth: 680),
                              child: Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _HeaderIconButton(
                                      icon: LucideIcons.arrowLeft,
                                      tooltip: 'Back',
                                      onPressed: () async {
                                        await _forceSave();
                                        if (context.mounted) context.go('/dashboard');
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 1,
                                      height: 24,
                                      color: Colors.white24,
                                    ),
                                    const SizedBox(width: 8),
                                    _isEditingName
                                        ? IntrinsicWidth(
                                            child: ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                minWidth: 120,
                                              ),
                                              child: TextField(
                                                controller: _nameController,
                                                autofocus: true,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                decoration: InputDecoration(
                                                  isDense: true,
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 8,
                                                      ),
                                                  filled: true,
                                                  fillColor: Colors.white
                                                      .withValues(alpha: 0.08),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                    borderSide: BorderSide.none,
                                                  ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                        borderSide:
                                                            const BorderSide(
                                                              color: Colors
                                                                  .white38,
                                                            ),
                                                      ),
                                                ),
                                                onSubmitted: (val) {
                                                  final newName = val.trim().isEmpty ? 'My Board' : val.trim();
                                                  setState(() {
                                                    _boardName = newName;
                                                    _nameController.text = _boardName;
                                                    _isEditingName = false;
                                                  });
                                                  _scheduleSave();
                                                  if (widget.boardId != null) {
                                                    BoardService.updateTitle(widget.boardId!, newName);
                                                  }
                                                },
                                                onTapOutside: (_) {
                                                  final newName = _nameController.text.trim().isEmpty ? 'My Board' : _nameController.text.trim();
                                                  setState(() {
                                                    _boardName = newName;
                                                    _nameController.text = _boardName;
                                                    _isEditingName = false;
                                                  });
                                                  _scheduleSave();
                                                  if (widget.boardId != null) {
                                                    BoardService.updateTitle(widget.boardId!, newName);
                                                  }
                                                },
                                              ),
                                            ),
                                          )
                                        : _NameButton(
                                            name: _boardName,
                                            onTap: () => setState(
                                              () => _isEditingName = true,
                                            ),
                                          ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 1,
                                      height: 24,
                                      color: Colors.white24,
                                    ),
                                    const SizedBox(width: 8),
                                    FieldControlsRow(
                                      isVertical: _isVertical,
                                      isTransitioning: _isTransitioning,
                                      onOrientationChange:
                                          _animateOrientationChange,
                                      fieldScale: _fieldScale,
                                      onScaleChange: (scale) {
                                        setState(() => _fieldScale = scale);
                                        _scheduleSave();
                                      },
                                      showSnapPoints: _showSnapPoints,
                                      onSnapPointsToggle: () {
                                        setState(
                                          () => _showSnapPoints =
                                              !_showSnapPoints,
                                        );
                                        _scheduleSave();
                                      },
                                      magnetize: _magnetize,
                                      onMagnetizeToggle: () {
                                        setState(
                                          () => _magnetize = !_magnetize,
                                        );
                                        _scheduleSave();
                                      },
                                      selectedFormation: _selectedFormation,
                                      formations: formations.keys.toList(),
                                      onFormationChanged: (val) {
                                        setState(
                                          () => _selectedFormation = val,
                                        );
                                        _scheduleSave();
                                      },
                                      showPlayerNames: _showPlayerNames,
                                      onPlayerNamesToggle: () {
                                        setState(
                                          () => _showPlayerNames =
                                              !_showPlayerNames,
                                        );
                                        _scheduleSave();
                                      },
                                      onClearField: _clearField,
                                      fieldStyle: _fieldStyle,
                                      onFieldStyleChanged: (style) {
                                        setState(() => _fieldStyle = style);
                                        _scheduleSave();
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 1,
                                      height: 24,
                                      color: Colors.white24,
                                    ),
                                    const SizedBox(width: 8),
                                    _HeaderIconButton(
                                      icon: LucideIcons.externalLink,
                                      tooltip: 'Open in New Window',
                                      onPressed: () {
                                        _scheduleSave();
                                        openPopupWindow(Uri.base.toString());
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    ),
                    // Drop zone previews when dragging the drawing toolbar
                    DrawingToolbarDropZones(
                      isDraggingNotifier: _isDrawingBarDraggingNotifier,
                      dragPosNotifier: _drawingBarDragPosNotifier,
                      sideResolver: _determineToolbarSide,
                    ),

                    // Drawing Toolbar (invisible while dragging but kept in tree so GestureDetector receives pan events)
                    if (_drawingToolbarVisible)
                      if (_drawingToolbarSide == ToolbarSide.bottom)
                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: ValueListenableBuilder<bool>(
                              valueListenable: _isDrawingBarDraggingNotifier,
                              builder: (_, isDragging, child) => Opacity(
                                opacity: isDragging ? 0.0 : 1.0,
                                child: child,
                              ),
                              child: Builder(
                                builder: (context) {
                                  // ignore: unused_local_variable
                                  final _ = _drawingToolbarVisible;
                                  return _drawingLayerKey.currentState
                                          ?.buildToolbarOnly() ??
                                      const SizedBox.shrink();
                                },
                              ),
                            ),
                          ),
                        )
                      else
                        Positioned(
                          left: 16,
                          top: 0,
                          bottom: 0,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: ValueListenableBuilder<bool>(
                              valueListenable: _isDrawingBarDraggingNotifier,
                              builder: (_, isDragging, child) => Opacity(
                                opacity: isDragging ? 0.0 : 1.0,
                                child: child,
                              ),
                              child: Builder(
                                builder: (context) {
                                  // ignore: unused_local_variable
                                  final _ = _drawingToolbarVisible;
                                  return _drawingLayerKey.currentState
                                          ?.buildToolbarOnly() ??
                                      const SizedBox.shrink();
                                },
                              ),
                            ),
                          ),
                        ),

                    // Save status indicator — anchored bottom-left on grey background
                    if (widget.boardId != null)
                      Positioned(
                        left: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF222222),
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_isSaving)
                                const SizedBox(
                                  width: 10,
                                  height: 10,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: Colors.white38,
                                  ),
                                )
                              else
                                Icon(
                                  LucideIcons.check,
                                  size: 11,
                                  color: _lastSavedAt != null ? Colors.white38 : Colors.white24,
                                ),
                              const SizedBox(width: 6),
                              Text(
                                _isSaving
                                    ? 'Saving...'
                                    : _lastSavedAt != null
                                        ? 'Saved at ${_lastSavedAt!.hour.toString().padLeft(2, '0')}:${_lastSavedAt!.minute.toString().padLeft(2, '0')}'
                                        : 'Not saved yet',
                                style: TextStyle(
                                  color: _lastSavedAt != null ? Colors.white38 : Colors.white24,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Drawing Toggle Button вЂ” always at bottom-left
                    Positioned(
                      left: 16,
                      bottom: 16,
                      child: Builder(
                        builder: (context) {
                          // ignore: unused_local_variable
                          final _ = _drawingToolbarVisible;
                          if (_drawingToolbarVisible) {
                            return const SizedBox.shrink();
                          }
                          return _drawingLayerKey.currentState
                                  ?.buildToggleButton() ??
                              DrawingToggleButtonPlaceholder(
                                key: const ValueKey(
                                  'drawing_toggle_placeholder',
                                ),
                                onPressed: () {
                                  _drawingLayerKey.currentState
                                      ?.toggleToolbar();
                                },
                              );
                        },
                      ),
                    ),
                    // Sidebar Toggle Button (top right)
                    Positioned(
                      right: 16,
                      top: 16,
                      child: SidebarToggleButton(
                        isOpen: _showSidebar,
                        onPressed: _toggleSidebar,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Sidebar Controls with smooth animation
            if (_showSidebar)
              SquadSidebar(
                sidebarController: _sidebarController,
                sidebarFade: _sidebarFade,
                fieldPlayerCount: _fieldPlayers.length,
                benchPlayers: _benchPlayers,
                selectedCompetition: _selectedCompetition,
                selectedTeamId: _selectedTeamId,
                teams: _teams,
                isLoading: _isLoading,
                playerSearchQuery: _playerSearchQuery,
                draggingPlayer: _draggingPlayer,
                returningPlayer: _returningPlayer,
                competitions: _competitions,
                onCompetitionChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedCompetition = val;
                      _teams = [];
                      _selectedTeamId = null;
                      _benchPlayers = [];
                      _fieldPlayers.clear();
                      _playerSearchQuery = '';
                    });
                    _fetchTeams();
                    _scheduleSave();
                  }
                },
                onTeamChanged: (val) async {
                  final confirmed = await _confirmTeamChange();
                  if (!confirmed) return;
                  _clearFieldElements();
                  setState(() {
                    _selectedTeamId = val;
                    _playerSearchQuery = '';
                  });
                  _fetchSquad(val);
                  _scheduleSave();
                },
                onSearchChanged: (value) =>
                    setState(() => _playerSearchQuery = value),
                onAddPlayer: _showAddPlayerDialog,
                onDragStarted: (player) =>
                    setState(() => _draggingPlayer = player),
                onDragEnded: () => setState(() => _draggingPlayer = null),
                buildPlayerToken: (player, scale) =>
                    _buildPlayerToken(player, scale),
              ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildFootballField(double width, double height) {
    return Stack(
      key: _fieldKey,
      clipBehavior: Clip.none,
      children: [
        // The Pitch Drawing
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: FootballPitchPainter(
                isVertical: _isVertical,
                fieldStyle: _fieldStyle,
              ),
            ),
          ),
        ),

        // Field Drop Zone (Invisible layer to catch drops for free movement)
        Positioned.fill(
          child: DragTarget<TacticPlayer>(
            onWillAcceptWithDetails: (details) => true,
            onAcceptWithDetails: (details) {
              // This handles new players coming from the sidebar or moving freely
              _handlePlayerDrop(details.data, details.offset, width, height);
            },
            builder: (ctx, candidates, rejects) => const SizedBox.shrink(),
          ),
        ),

        // Snap Points (if enabled)
        if (_showSnapPoints) ..._buildSnapPoints(width, height),

        // Drawing Layer (below players so players can be easily grabbed)
        Positioned.fill(
          child: DrawingLayer(
            key: _drawingLayerKey,
            width: width,
            height: height,
            renderToolbarInternally: false,
            onChanged: _scheduleSave,
            onToolbarVisibilityChanged: (visible) {
              setState(() => _drawingToolbarVisible = visible);
            },
            onBarDragChanged: (isDragging, pos) {
              if (isDragging != _isDrawingBarDragging) {
                _isDrawingBarDragging = isDragging;
                _isDrawingBarDraggingNotifier.value = isDragging;
              }
              if (pos != null) _drawingBarDragPosNotifier.value = pos;

              if (isDragging && pos != null) {
                final liveSide = _determineToolbarSide(pos);
                if (liveSide != _liveDragSide) {
                  _liveDragSide = liveSide;
                  _drawingLayerKey.currentState?.setToolbarSide(liveSide);
                }
                _showFloatingToolbar(pos);
              } else if (!isDragging) {
                _hideFloatingToolbar();
                if (pos != null) {
                  final side = _determineToolbarSide(pos);
                  setState(() => _drawingToolbarSide = side);
                  _drawingLayerKey.currentState?.setToolbarSide(side);
                }
              }
            },
          ),
        ),

        // Players on Field
        ..._fieldPlayers.where((p) => p.position != null).map((player) {
          final pos = player.position!;
          const hitAreaSize = 120.0;
          // When dragging this player, ignore its own DragTarget so drops go to field
          final isDraggingSelf = _draggingPlayer?.id == player.id;
          return Positioned(
            key: ValueKey('field_player_${player.id}'),
            left: pos.dx * width - hitAreaSize / 2,
            top: pos.dy * height - hitAreaSize / 2,
            child: IgnorePointer(
              ignoring: isDraggingSelf,
              child: SizedBox(
                width: hitAreaSize,
                height: hitAreaSize,
                child: DragTarget<TacticPlayer>(
                  onWillAcceptWithDetails: (details) =>
                      details.data.id != player.id,
                  onAcceptWithDetails: (details) {
                    final droppedPlayer = details.data;
                    setState(() {
                      // Check if dropped player was on field or from bench
                      final wasOnField =
                          _fieldPlayers.contains(droppedPlayer) &&
                          droppedPlayer.position != null;
                      final oldPosition = droppedPlayer.position;

                      if (wasOnField && oldPosition != null) {
                        // Swap positions
                        droppedPlayer.position = player.position;
                        player.position = oldPosition;
                      } else {
                        // From bench: this player goes to bench, dropped takes position
                        final targetPosition = player.position;
                        _fieldPlayers.remove(player);
                        player.position = null;
                        _benchPlayers.add(player);

                        // Sort bench
                        _benchPlayers.sort((a, b) {
                          if (a.isInSquad != b.isInSquad) {
                            return a.isInSquad ? -1 : 1;
                          }
                          final posOrder = {
                            'Goalkeeper': 0,
                            'Defender': 1,
                            'Midfielder': 2,
                            'Attacker': 3,
                          };
                          int orderA = posOrder[a.positionRole] ?? 4;
                          int orderB = posOrder[b.positionRole] ?? 4;
                          if (orderA != orderB) return orderA.compareTo(orderB);
                          return a.number.compareTo(b.number);
                        });

                        // Place dropped player
                        _benchPlayers.removeWhere(
                          (p) => p.id == droppedPlayer.id,
                        );
                        droppedPlayer.position = targetPosition;
                        if (!_fieldPlayers.contains(droppedPlayer)) {
                          _fieldPlayers.add(droppedPlayer);
                        }
                      }
                    });
                    _scheduleSave();
                  },
                  builder: (context, candidateData, rejectedData) {
                    final isHovering = candidateData.isNotEmpty;
                    final isDragging = _draggingPlayer?.id == player.id;
                    return Center(
                      child: MouseRegion(
                        cursor: SystemMouseCursors.grab,
                        child: Draggable<TacticPlayer>(
                          data: player,
                          feedback: _buildPlayerToken(player, 1.15),
                          childWhenDragging: Opacity(
                            opacity: 0.3,
                            child: _buildPlayerToken(player),
                          ),
                          onDragStarted: () {
                            setState(() => _draggingPlayer = player);
                          },
                          onDragEnd: (details) {
                            setState(() => _draggingPlayer = null);
                            // Check if dropped outside the field
                            _checkIfDroppedOutside(player, details.offset);
                          },
                          onDraggableCanceled: (_, _) {
                            setState(() => _draggingPlayer = null);
                          },
                          child: AnimatedScale(
                            scale: isDragging ? 0.9 : (isHovering ? 1.1 : 1.0),
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: isHovering
                                    ? [
                                        BoxShadow(
                                          color: Colors.amber.withValues(
                                            alpha: 0.7,
                                          ),
                                          blurRadius: 16,
                                          spreadRadius: 6,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  _buildPlayerToken(player),
                                  // Show swap icon when another player is being dragged over this one
                                  if (isHovering)
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.amber.withValues(
                                            alpha: 0.85,
                                          ),
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.swap_horiz,
                                            color: Colors.black87,
                                            size: 28,
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (_showPlayerNames && !isHovering)
                                    Positioned(
                                      top: 52,
                                      left: -100,
                                      right: -100,
                                      child: Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            player.shortName,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              decoration: TextDecoration.none,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  List<Widget> _buildSnapPoints(double width, double height) {
    final points = formations[_selectedFormation] ?? [];
    final positionIndices = getPositionIndices(_selectedFormation);

    return points.asMap().entries.map((entry) {
      final index = entry.key;
      final relOffset = entry.value;

      // Determine which position this index belongs to
      String? pointPosition;
      for (final posEntry in positionIndices.entries) {
        if (posEntry.value.contains(index)) {
          pointPosition = posEntry.key;
          break;
        }
      }

      // Check if this point should be highlighted for the dragging player
      bool shouldHighlight =
          _draggingPlayer != null &&
          _draggingPlayer!.positionRole == pointPosition;

      // Rotate points if vertical
      Offset pos = relOffset;
      if (!_isVertical) {
        // In horizontal, we swap x and y
        pos = Offset(relOffset.dy, relOffset.dx);
        pos = Offset(1.0 - relOffset.dy, relOffset.dx);
      }

      // Size 20x20, so offset is 10
      return Positioned(
        left: pos.dx * width - 10,
        top: pos.dy * height - 10,
        child: IgnorePointer(
          ignoring: !_magnetize,
          child: DragTarget<TacticPlayer>(
            onWillAcceptWithDetails: (details) => true,
            onAcceptWithDetails: (details) {
              final data = details.data;

              // Check if this snap point is occupied by another player
              TacticPlayer? occupyingPlayer;
              for (var player in _fieldPlayers) {
                if (player.id == data.id) continue;
                final pPos = player.position;
                if (pPos == null) continue;

                // Check if player is on this snap point (within small tolerance)
                double dx = (pPos.dx - pos.dx) * width;
                double dy = (pPos.dy - pos.dy) * height;
                if (dx * dx + dy * dy < 100) {
                  // Within ~10 pixels
                  occupyingPlayer = player;
                  break;
                }
              }

              setState(() {
                _draggingPlayer = null;

                if (occupyingPlayer != null) {
                  // Check if dragged player was on the field (has position)
                  final wasOnField =
                      _fieldPlayers.contains(data) && data.position != null;
                  final oldPosition = data.position;

                  if (wasOnField && oldPosition != null) {
                    // Swap positions: occupying player goes to dragged player's old position
                    occupyingPlayer.position = oldPosition;
                  } else {
                    // Dragged from bench: occupying player returns to bench
                    _fieldPlayers.remove(occupyingPlayer);
                    occupyingPlayer.position = null;
                    _benchPlayers.add(occupyingPlayer);

                    // Sort bench
                    _benchPlayers.sort((a, b) {
                      if (a.isInSquad != b.isInSquad) {
                        return a.isInSquad ? -1 : 1;
                      }
                      final posOrder = {
                        'Goalkeeper': 0,
                        'Defender': 1,
                        'Midfielder': 2,
                        'Attacker': 3,
                      };
                      int orderA = posOrder[a.positionRole] ?? 4;
                      int orderB = posOrder[b.positionRole] ?? 4;
                      if (orderA != orderB) return orderA.compareTo(orderB);
                      return a.number.compareTo(b.number);
                    });
                  }
                }

                // Place dragged player on the snap point
                _benchPlayers.removeWhere((p) => p.id == data.id);
                data.position = pos;
                if (!_fieldPlayers.contains(data)) {
                  _fieldPlayers.add(data);
                }
              });
              _scheduleSave();
            },
            builder: (context, candidateData, rejectedData) {
              final isHovering = candidateData.isNotEmpty;
              const highlightColor = Colors.amber;
              final baseSize = 20.0;
              final highlightSize = 28.0;
              final currentSize = shouldHighlight ? highlightSize : baseSize;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: currentSize,
                height: currentSize,
                transform: Matrix4.translationValues(
                  -(currentSize - baseSize) / 2,
                  -(currentSize - baseSize) / 2,
                  0,
                ),
                decoration: BoxDecoration(
                  color: shouldHighlight
                      ? highlightColor.withValues(alpha: 0.3)
                      : const Color(0xFF595959),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isHovering
                        ? const Color(0xFF00FF94)
                        : shouldHighlight
                        ? highlightColor
                        : const Color(0xFF343434).withValues(alpha: 0.5),
                    width: shouldHighlight ? 2 : 1,
                  ),
                  boxShadow: shouldHighlight
                      ? [
                          BoxShadow(
                            color: highlightColor.withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
              );
            },
          ),
        ),
      );
    }).toList();
  }

  void _rotatePlayers(bool toVertical) {
    for (var player in _fieldPlayers) {
      final pos = player.position;
      if (pos == null) continue;
      if (toVertical) {
        // Horizontal -> Vertical: (x, y) -> (y, 1-x)
        player.position = Offset(pos.dy, 1.0 - pos.dx);
      } else {
        // Vertical -> Horizontal: (x, y) -> (1-y, x)
        player.position = Offset(1.0 - pos.dy, pos.dx);
      }
    }
  }

  void _handlePlayerDrop(
    TacticPlayer player,
    Offset globalPos,
    double fieldWidth,
    double fieldHeight,
  ) {
    final RenderBox? box =
        _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      // Adjust for the feedback size (48x48) to get the center
      // globalPos is the top-left of the feedback
      final Offset localPos =
          box.globalToLocal(globalPos) + const Offset(24, 24);

      // Normalize to 0.0 - 1.0
      double dx = localPos.dx / fieldWidth;
      double dy = localPos.dy / fieldHeight;

      // Clamp to field boundaries
      dx = dx.clamp(0.0, 1.0);
      dy = dy.clamp(0.0, 1.0);

      Offset finalPosition = Offset(dx, dy);

      if (_magnetize) {
        // Find nearest snap point
        final points = formations[_selectedFormation] ?? [];
        double minDistance = double.infinity;
        Offset? nearestPoint;

        for (var relOffset in points) {
          Offset snapPos = relOffset;
          if (!_isVertical) {
            // In horizontal, we swap x and y
            snapPos = Offset(1.0 - relOffset.dy, relOffset.dx);
          }

          double dist = (snapPos - finalPosition).distance;
          if (dist < minDistance) {
            minDistance = dist;
            nearestPoint = snapPos;
          }
        }

        if (nearestPoint != null) {
          final nearest = nearestPoint;
          // Check if occupied by another player within reasonable distance
          TacticPlayer? occupyingPlayer;
          for (var p in _fieldPlayers) {
            if (p.id == player.id) continue;
            final pPos = p.position;
            if (pPos == null) continue;

            double distX = (pPos.dx - nearest.dx) * fieldWidth;
            double distY = (pPos.dy - nearest.dy) * fieldHeight;
            // Check if within 20 pixels (approx radius of player token)
            if ((distX * distX + distY * distY) < 400) {
              occupyingPlayer = p;
              break;
            }
          }

          if (occupyingPlayer == null) {
            // Not occupied, just snap
            finalPosition = nearestPoint;
          } else {
            // Occupied - handle swap/replace
            final wasOnField =
                _fieldPlayers.contains(player) && player.position != null;
            final oldPosition = player.position;

            if (wasOnField && oldPosition != null) {
              // Swap: occupying player goes to dragged player's old position
              occupyingPlayer.position = oldPosition;
            } else {
              // From bench: occupying player returns to bench
              _fieldPlayers.remove(occupyingPlayer);
              occupyingPlayer.position = null;
              _benchPlayers.add(occupyingPlayer);

              // Sort bench
              _benchPlayers.sort((a, b) {
                if (a.isInSquad != b.isInSquad) {
                  return a.isInSquad ? -1 : 1;
                }
                final posOrder = {
                  'Goalkeeper': 0,
                  'Defender': 1,
                  'Midfielder': 2,
                  'Attacker': 3,
                };
                int orderA = posOrder[a.positionRole] ?? 4;
                int orderB = posOrder[b.positionRole] ?? 4;
                if (orderA != orderB) return orderA.compareTo(orderB);
                return a.number.compareTo(b.number);
              });
            }

            finalPosition = nearestPoint;
          }
        }
      }

      setState(() {
        // Remove from bench if it was there
        _benchPlayers.removeWhere((p) => p.id == player.id);

        // Update position
        player.position = finalPosition;

        // Add to field if not already there (it might be moving within the field)
        if (!_fieldPlayers.contains(player)) {
          _fieldPlayers.add(player);
        }
      });
      _scheduleSave();
    }
  }

  void _checkIfDroppedOutside(TacticPlayer player, Offset globalPos) {
    final RenderBox? box =
        _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      final Offset localPos =
          box.globalToLocal(globalPos) + const Offset(24, 24);
      final Size fieldSize = box.size;

      // Check if dropped outside field boundaries (with some margin)
      const margin = -20.0; // Allow some tolerance
      bool isOutside =
          localPos.dx < margin ||
          localPos.dy < margin ||
          localPos.dx > fieldSize.width - margin ||
          localPos.dy > fieldSize.height - margin;

      if (isOutside && _fieldPlayers.contains(player)) {
        _returnPlayerToBench(player);
      }
    }
  }

  void _returnPlayerToBench(TacticPlayer player) {
    setState(() {
      _returningPlayer = player;
      _fieldPlayers.remove(player);
      player.position = null; // Clear position so it's not restored to field

      // Add back to bench in correct position (sorted by position then number)
      _benchPlayers.add(player);
      _benchPlayers.sort((a, b) {
        // First sort by squad status
        if (a.isInSquad != b.isInSquad) {
          return a.isInSquad ? -1 : 1;
        }
        final posOrder = {
          'Goalkeeper': 0,
          'Defender': 1,
          'Midfielder': 2,
          'Attacker': 3,
        };
        int orderA = posOrder[a.positionRole] ?? 4;
        int orderB = posOrder[b.positionRole] ?? 4;
        if (orderA != orderB) return orderA.compareTo(orderB);
        return a.number.compareTo(b.number);
      });
    });

    // Clear the returning player after animation
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _returningPlayer = null);
      }
    });

    _scheduleSave();
  }

  // We need a key for the field to get local coordinates correctly
  final GlobalKey _fieldKey = GlobalKey();

  /// Decide toolbar side based on where the drag was released (global coords)
  ToolbarSide _determineToolbarSide(Offset globalPos) {
    final box = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return ToolbarSide.bottom;
    final local = box.globalToLocal(globalPos);
    final size = box.size;
    // Left zone: left 30% of the field
    if (local.dx < size.width * 0.3) return ToolbarSide.left;
    return ToolbarSide.bottom;
  }

  void _showFloatingToolbar(Offset globalPos) {
    _floatingToolbarPos.value = globalPos;
    if (_floatingToolbarOverlay == null) {
      _floatingToolbarOverlay = OverlayEntry(
        builder: (_) => ValueListenableBuilder<Offset>(
          valueListenable: _floatingToolbarPos,
          builder: (_, pos, _) {
            final drawingState = _drawingLayerKey.currentState?.state;
            if (drawingState == null) return const SizedBox.shrink();
            return Positioned(
              left: pos.dx,
              top: pos.dy,
              child: IgnorePointer(
                child: FractionalTranslation(
                  translation: const Offset(-0.5, -0.5),
                  child: Opacity(
                    opacity: 0.8,
                    child: DrawingToolbar(
                      state: drawingState,
                      side: _liveDragSide,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
      Overlay.of(context).insert(_floatingToolbarOverlay!);
    }
  }

  void _hideFloatingToolbar() {
    _floatingToolbarOverlay?.remove();
    _floatingToolbarOverlay = null;
  }

  Widget _buildPlayerToken(TacticPlayer player, [double scale = 1.0]) {
    final token = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: player.color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 1),
          child: Text(
            player.number.toString(),
            style: const TextStyle(
              fontFamily: 'Raleway',
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 28,
              height: 1.0,
              leadingDistribution: TextLeadingDistribution.even,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );

    if (scale == 1.0) return token;

    return Transform.scale(
      scale: scale,
      alignment: Alignment.center,
      child: token,
    );
  }
}

class _HeaderIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  State<_HeaderIconButton> createState() => _HeaderIconButtonState();
}

class _HeaderIconButtonState extends State<_HeaderIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: _isHovered ? 1.0 : 0.0),
            duration: const Duration(milliseconds: 150),
            builder: (_, v, child) => Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Color.lerp(
                  Colors.white.withValues(alpha: 0.05),
                  Colors.white.withValues(alpha: 0.12),
                  v,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: child,
            ),
            child: Center(
              child: Icon(widget.icon, size: 16, color: Colors.white60),
            ),
          ),
        ),
      ),
    );
  }
}

class _NameButton extends StatefulWidget {
  final String name;
  final VoidCallback onTap;

  const _NameButton({required this.name, required this.onTap});

  @override
  State<_NameButton> createState() => _NameButtonState();
}

class _NameButtonState extends State<_NameButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: _isHovered ? 1.0 : 0.0),
          duration: const Duration(milliseconds: 150),
          builder: (_, v, child) => Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Color.lerp(
                Colors.transparent,
                Colors.white.withValues(alpha: 0.07),
                v,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: child,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                LucideIcons.pencil,
                size: 12,
                color: _isHovered ? Colors.white54 : Colors.white24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RestoreDialogButton extends StatefulWidget {
  const _RestoreDialogButton({
    required this.label,
    required this.onTap,
    this.isSecondary = false,
  });
  final String label;
  final VoidCallback onTap;
  final bool isSecondary;

  @override
  State<_RestoreDialogButton> createState() => _RestoreDialogButtonState();
}

class _RestoreDialogButtonState extends State<_RestoreDialogButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 44,
          decoration: BoxDecoration(
            color: widget.isSecondary
                ? Colors.white.withValues(alpha: _hovered ? 0.08 : 0.05)
                : _hovered
                ? const Color(0xFFFDD329)
                : const Color(0xFFFDD329).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(24),
            border: widget.isSecondary
                ? Border.all(color: Colors.white.withValues(alpha: 0.12))
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: widget.isSecondary
                  ? Colors.white.withValues(alpha: 0.6)
                  : const Color(0xFF003907),
            ),
          ),
        ),
      ),
    );
  }
}
