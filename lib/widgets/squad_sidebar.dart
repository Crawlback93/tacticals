import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/models.dart';
import '../data/competitions_data.dart' show Competition;
import '../elements/custom_dropdown.dart';
import '../elements/custom_input.dart';

const Color _accentColor = Color(0xFFFDD329);

/// Animated sidebar panel with squad selection and player list.
class SquadSidebar extends StatelessWidget {
  const SquadSidebar({
    super.key,
    required this.sidebarController,
    required this.sidebarFade,
    required this.fieldPlayerCount,
    required this.benchPlayers,
    required this.selectedCompetition,
    required this.selectedTeamId,
    required this.teams,
    required this.isLoading,
    required this.playerSearchQuery,
    required this.draggingPlayer,
    required this.returningPlayer,
    required this.competitions,
    required this.onCompetitionChanged,
    required this.onTeamChanged,
    required this.onSearchChanged,
    required this.onAddPlayer,
    required this.onDragStarted,
    required this.onDragEnded,
    required this.buildPlayerToken,
  });

  final AnimationController sidebarController;
  final Animation<double> sidebarFade;
  final int fieldPlayerCount;
  final List<TacticPlayer> benchPlayers;
  final Competition? selectedCompetition;
  final String? selectedTeamId;
  final List<dynamic> teams;
  final bool isLoading;
  final String playerSearchQuery;
  final TacticPlayer? draggingPlayer;
  final TacticPlayer? returningPlayer;
  final List<Competition> competitions;
  final ValueChanged<Competition?> onCompetitionChanged;
  final Future<void> Function(String val) onTeamChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onAddPlayer;
  final ValueChanged<TacticPlayer> onDragStarted;
  final VoidCallback onDragEnded;

  /// Builds a player token widget. Signature: (player, scale) → Widget.
  final Widget Function(TacticPlayer player, double scale) buildPlayerToken;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: sidebarController,
        builder: (context, child) {
          return ClipRect(
            child: SizedBox(
              width: 300 * sidebarController.value,
              child: OverflowBox(
                alignment: Alignment.centerRight,
                maxWidth: 300,
                minWidth: 300,
                child: child,
              ),
            ),
          );
        },
        child: FadeTransition(
          opacity: sidebarFade,
          child: Container(
            width: 300,
            margin: const EdgeInsets.only(left: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(24),
            ),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 12),
                  _buildCompetitionDropdown(),
                  const SizedBox(height: 10),
                  _buildTeamDropdown(),
                  const SizedBox(height: 16),
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _buildBody(),
                  ),
                  const SizedBox(height: 12),
                  _buildSearchAndAddRow(context),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Squad',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w300,
          ),
        ),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$fieldPlayerCount',
                style: const TextStyle(
                  fontFamily: 'Raleway',
                  color: _accentColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const TextSpan(
                text: '/11',
                style: TextStyle(
                  fontFamily: 'Raleway',
                  color: Colors.white54,
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompetitionDropdown() {
    return CustomDropdown<Competition>(
      label: 'Competition',
      value: selectedCompetition,
      hint: 'Select Competition',
      items: competitions
          .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
          .toList(),
      onChanged: (val) {
        debugPrint('Competition dropdown onChanged: $val');
        if (val != null) {
          debugPrint('Competition selected: ${val.name} (apiId: ${val.apiId})');
          onCompetitionChanged(val);
        } else {
          debugPrint('Competition onChanged: val is null');
        }
      },
    );
  }

  Widget _buildTeamDropdown() {
    final enabled = selectedCompetition != null && teams.isNotEmpty;
    return Opacity(
      opacity: selectedCompetition == null ? 0.4 : 1.0,
      child: IgnorePointer(
        ignoring: !enabled,
        child: CustomDropdown<String>(
          label: 'Team',
          value: selectedTeamId,
          hint: selectedCompetition == null
              ? 'Select competition first'
              : teams.isEmpty
              ? 'No teams available'
              : 'Select Team',
          items: teams.map<DropdownMenuItem<String>>((t) {
            return DropdownMenuItem(
              value: t['team']['id'] as String,
              child: Text(t['team']['name']),
            );
          }).toList(),
          onChanged: (val) async {
            if (val != null && val != selectedTeamId) {
              await onTeamChanged(val);
            }
          },
        ),
      ),
    );
  }

  Widget _buildBody() {
    // No competition selected
    if (selectedCompetition == null) {
      return _buildEmptyState(
        icon: LucideIcons.trophy,
        message: 'Select a competition\nto get started',
      );
    }

    // Competition selected but no teams loaded yet (and not loading)
    if (teams.isEmpty) {
      return _buildEmptyState(
        icon: LucideIcons.users,
        message: 'No teams found\nfor this competition',
      );
    }

    // Teams loaded but no team selected
    if (selectedTeamId == null) {
      return _buildEmptyState(
        icon: LucideIcons.shieldHalf,
        message: 'Select a team\nto view the squad',
      );
    }

    // Team selected but no players
    if (benchPlayers.isEmpty) {
      return _buildEmptyState(
        icon: LucideIcons.userX,
        message: 'No players available\nfor this team',
      );
    }

    return _buildPlayerList();
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white24, size: 36),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerList() {
    // Sort: custom first, then by squad/position/number
    final sortedPlayers = List<TacticPlayer>.from(benchPlayers);
    sortedPlayers.sort((a, b) {
      if (a.isCustom != b.isCustom) return a.isCustom ? -1 : 1;
      if (a.isInSquad != b.isInSquad) return a.isInSquad ? -1 : 1;
      const posOrder = {
        'Goalkeeper': 0,
        'Defender': 1,
        'Midfielder': 2,
        'Attacker': 3,
      };
      final orderA = posOrder[a.positionRole] ?? 4;
      final orderB = posOrder[b.positionRole] ?? 4;
      if (orderA != orderB) return orderA.compareTo(orderB);
      return a.number.compareTo(b.number);
    });

    final filteredPlayers = playerSearchQuery.isEmpty
        ? sortedPlayers
        : sortedPlayers.where((p) {
            final query = playerSearchQuery.toLowerCase();
            return p.name.toLowerCase().contains(query) ||
                p.shortName.toLowerCase().contains(query) ||
                p.number.toString().contains(query);
          }).toList();

    if (filteredPlayers.isEmpty && benchPlayers.isNotEmpty) {
      return const Center(
        child: Text(
          'No players found',
          style: TextStyle(color: Colors.white38),
        ),
      );
    }

    return Stack(
      children: [
        RawScrollbar(
          thumbColor: Colors.white24,
          radius: const Radius.circular(2),
          thickness: 4,
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            itemCount: filteredPlayers.length,
            itemBuilder: (context, index) =>
                _buildListItem(filteredPlayers, index),
          ),
        ),
        // Top gradient fade
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 16,
          child: IgnorePointer(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1E1E1E), Color(0x001E1E1E)],
                ),
              ),
            ),
          ),
        ),
        // Bottom gradient fade
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 16,
          child: IgnorePointer(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xFF1E1E1E), Color(0x001E1E1E)],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListItem(List<TacticPlayer> players, int index) {
    final player = players[index];

    bool showCustomHeader = false;
    bool showSquadHeader = false;
    bool showReservesHeader = false;
    bool showPositionHeader = false;

    if (playerSearchQuery.isEmpty) {
      if (index == 0 && player.isCustom) showCustomHeader = true;

      if (player.isInSquad && !player.isCustom) {
        if (index == 0 || players[index - 1].isCustom) showSquadHeader = true;
      }

      if (!player.isInSquad && !player.isCustom) {
        if (index == 0 ||
            players[index - 1].isInSquad ||
            players[index - 1].isCustom) {
          showReservesHeader = true;
        }
      }

      if (!player.isCustom) {
        if (index == 0) {
          showPositionHeader = true;
        } else {
          final prev = players[index - 1];
          if (!prev.isCustom &&
              (prev.positionRole != player.positionRole ||
                  prev.isInSquad != player.isInSquad)) {
            showPositionHeader = true;
          }
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showCustomHeader) _buildSectionDivider('Custom players'),
        if (showSquadHeader) _buildSectionDivider('Main squad'),
        if (showReservesHeader)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _buildSectionDivider('Reserves'),
          ),
        if (showPositionHeader)
          Padding(
            padding: EdgeInsets.only(
              top: (showSquadHeader || showReservesHeader) ? 4.0 : 8.0,
              bottom: 8.0,
            ),
            child: Text(
              player.positionRole,
              style: const TextStyle(
                color: _accentColor,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        Draggable<TacticPlayer>(
          data: player,
          feedback: buildPlayerToken(player, 1.2),
          dragAnchorStrategy: (draggable, context, position) =>
              const Offset(24 * 1.2, 24 * 1.2),
          childWhenDragging: Opacity(
            opacity: 0.5,
            child: _buildPlayerListItem(player),
          ),
          onDragStarted: () => onDragStarted(player),
          onDragEnd: (_) => onDragEnded(),
          onDraggableCanceled: (_, _) => onDragEnded(),
          child: _buildPlayerListItem(player),
        ),
      ],
    );
  }

  Widget _buildSectionDivider(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Colors.white24, height: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
          const Expanded(child: Divider(color: Colors.white24, height: 1)),
        ],
      ),
    );
  }

  Widget _buildPlayerListItem(TacticPlayer player) {
    final isReturning = returningPlayer?.id == player.id;
    return _PlayerListItemHover(
      player: player,
      isReturning: isReturning,
      child: Row(
        children: [
          buildPlayerToken(player, 0.6),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              player.name,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndAddRow(BuildContext context) {
    final hasPlayers = benchPlayers.isNotEmpty;
    final hasCustomPlayers = benchPlayers.any((p) => p.isCustom);
    final isSearchEnabled = hasPlayers || hasCustomPlayers;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: IgnorePointer(
            ignoring: !isSearchEnabled,
            child: Opacity(
              opacity: isSearchEnabled ? 1.0 : 0.5,
              child: CustomInput(
                hint: 'Search player',
                leadingIcon: LucideIcons.search,
                accentColor: _accentColor,
                onChanged: isSearchEnabled ? onSearchChanged : null,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Add custom player',
          child: Material(
            color: _accentColor,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: onAddPlayer,
              child: Container(
                height: 44,
                width: 44,
                alignment: Alignment.center,
                child: const Icon(
                  LucideIcons.plus,
                  color: Colors.black,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Player List Item Hover ───────────────────────────────────────────────────

class _PlayerListItemHover extends StatefulWidget {
  final TacticPlayer player;
  final bool isReturning;
  final Widget child;

  const _PlayerListItemHover({
    required this.player,
    required this.isReturning,
    required this.child,
  });

  @override
  State<_PlayerListItemHover> createState() => _PlayerListItemHoverState();
}

class _PlayerListItemHoverState extends State<_PlayerListItemHover> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final player = widget.player;
    final isReturning = widget.isReturning;

    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 44,
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isReturning
              ? Colors.green.withValues(alpha: 0.3)
              : _isHovered
              ? player.color.withValues(alpha: 0.15)
              : player.isCustom
              ? Colors.blue.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: isReturning
              ? Border.all(color: Colors.green, width: 2)
              : null,
          boxShadow: isReturning
              ? [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: widget.child,
      ),
    );
  }
}
