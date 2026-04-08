import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/board_model.dart';
import 'services/auth_service.dart';
import 'services/board_service.dart';
import 'widgets/notifications_bell.dart';


// ── Design System Tokens ──────────────────────────────────────────────────────
const _kBackground = Color(0xFF131313);
const _kPrimary = Color(0xFF00FF41);
const _kOnPrimary = Color(0xFF003907);
const _kSurfaceContainer = Color(0xFF201F1F);
const _kSurfaceContainerLow = Color(0xFF1C1B1B);
const _kSurfaceContainerHigh = Color(0xFF2A2A2A);
const _kOnSurface = Color(0xFFE5E2E1);
const _kOnSurfaceVariant = Color(0xFFB9CCB2);
const _kOutlineVariant = Color(0xFF3B4B37);

// ── Dashboard Page ────────────────────────────────────────────────────────────
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedFilter = 0;
  List<BoardModel> _boards = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBoards();
  }

  Future<void> _loadBoards() async {
    setState(() => _loading = true);
    try {
      final boards = await BoardService.fetchBoards();
      if (mounted) setState(() => _boards = boards);
    } catch (_) {
      // no-op: stay empty
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showCreateDialog() async {
    final title = _nextBoardTitle();
    try {
      final board = await BoardService.createBoard(title: title);
      if (!mounted) return;
      context.go(
        '/board/${board.id}',
        extra: {'title': board.title, 'snapshot': board.snapshot},
      );
    } catch (_) {
      // no-op
    }
  }

  String _nextBoardTitle() {
    const base = 'My Board';
    final existing = _boards.map((b) => b.title).toSet();
    if (!existing.contains(base)) return base;
    int i = 1;
    while (existing.contains('$base $i')) {
      i++;
    }
    return '$base $i';
  }

  void _openBoard(BoardModel board) {
    context.go(
      '/board/${board.id}',
      extra: {'title': board.title, 'snapshot': board.snapshot},
    );
  }

  List<BoardModel> get _filteredBoards {
    final currentUserId =
        Supabase.instance.client.auth.currentUser?.id ?? '';
    switch (_selectedFilter) {
      case 1: // Recent — sorted by last opened/edited
        return [..._boards]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case 2: // Shared — boards owned by others
        return _boards.where((b) => b.ownerId != currentUserId).toList();
      default: // All — sorted by creation date, newest first
        return [..._boards]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TopBar(onNewBoard: _showCreateDialog),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final isDesktop = w >= 1024;
                  final isTablet = w >= 600;
                  final hPadding = isDesktop ? 64.0 : 20.0;
                  final crossAxisCount = isDesktop ? 5 : (isTablet ? 3 : 2);

                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(hPadding, 24, hPadding, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeroSection(
                          selectedFilter: _selectedFilter,
                          onFilterChanged: (i) =>
                              setState(() => _selectedFilter = i),
                        ),
                        const SizedBox(height: 32),
                        if (_loading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(48),
                              child: CircularProgressIndicator(
                                color: _kPrimary,
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        else
                          _BoardsGrid(
                            boards: _filteredBoards,
                            crossAxisCount: crossAxisCount,
                            onTapBoard: _openBoard,
                            onNewBoard: _showCreateDialog,
                            selectedFilter: _selectedFilter,
                          ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Top Bar ───────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final VoidCallback onNewBoard;
  const _TopBar({required this.onNewBoard});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: _kBackground.withValues(alpha: 0.9),
            border: Border(
              bottom: BorderSide(
                color: _kOutlineVariant.withValues(alpha: 0.15),
              ),
            ),
          ),
          child: Row(
            children: [
              // Logo
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _kPrimary,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: _kPrimary.withValues(alpha: 0.3),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.grid_view_rounded,
                  color: _kOnPrimary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'TACTICALS',
                style: TextStyle(
                  color: _kPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              // New board CTA (pill)
              GestureDetector(
                onTap: onNewBoard,
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: _kPrimary,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: _kPrimary.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.add, color: _kOnPrimary, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'NEW BOARD',
                        style: TextStyle(
                          color: _kOnPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const NotificationsBell(),
              const SizedBox(width: 8),
              _ProfileButton(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Profile Button + Popover ──────────────────────────────────────────────────
class _ProfileButton extends StatefulWidget {
  const _ProfileButton();

  @override
  State<_ProfileButton> createState() => _ProfileButtonState();
}

class _ProfileButtonState extends State<_ProfileButton> {
  final _key = GlobalKey();
  OverlayEntry? _overlay;

  static String _initials() {
    final user = Supabase.instance.client.auth.currentUser;
    final name = user?.userMetadata?['name'] as String? ??
        user?.userMetadata?['full_name'] as String?;
    if (name != null && name.isNotEmpty) {
      final parts = name.trim().split(' ');
      if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      return parts[0][0].toUpperCase();
    }
    final email = user?.email ?? '';
    final local = email.split('@').first;
    final parts = local.split(RegExp(r'[._\-+]')).where((s) => s.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return local.isNotEmpty ? local[0].toUpperCase() : '?';
  }

  void _togglePopover() {
    if (_overlay != null) {
      _closePopover();
      return;
    }
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(Offset.zero);
    final size = box.size;

    _overlay = OverlayEntry(
      builder: (_) => _ProfilePopover(
        anchorRight: MediaQuery.of(context).size.width - pos.dx - size.width,
        anchorTop: pos.dy + size.height + 8,
        onClose: _closePopover,
      ),
    );
    Overlay.of(context).insert(_overlay!);
  }

  void _closePopover() {
    _overlay?.remove();
    _overlay = null;
  }

  @override
  void dispose() {
    _closePopover();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final url = Supabase.instance.client.auth.currentUser
        ?.userMetadata?['avatar_url'] as String?;
    return GestureDetector(
      key: _key,
      onTap: _togglePopover,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _kPrimary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: _kPrimary.withValues(alpha: 0.3), width: 1.5),
          ),
          child: ClipOval(
            child: url != null
                ? Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => _AvatarFallback(_initials()),
                  )
                : _AvatarFallback(_initials()),
          ),
        ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final String initials;
  const _AvatarFallback(this.initials);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kSurfaceContainerHigh,
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: _kPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ProfilePopover extends StatelessWidget {
  final double anchorRight;
  final double anchorTop;
  final VoidCallback onClose;

  const _ProfilePopover({
    required this.anchorRight,
    required this.anchorTop,
    required this.onClose,
  });

  static String _displayName() {
    final user = Supabase.instance.client.auth.currentUser;
    final name = user?.userMetadata?['name'] as String? ??
        user?.userMetadata?['full_name'] as String?;
    if (name != null && name.isNotEmpty) return name;
    return user?.email?.split('@').first ?? '—';
  }

  static String _email() =>
      Supabase.instance.client.auth.currentUser?.email ?? '—';

  static String _provider() {
    final identities =
        Supabase.instance.client.auth.currentUser?.identities ?? [];
    if (identities.isEmpty) return 'Email';
    final provider = identities.first.provider;
    return provider[0].toUpperCase() + provider.substring(1);
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kSurfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Sign out?',
          style: TextStyle(color: _kOnSurface, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'You will need to sign in again to access your boards.',
          style: TextStyle(color: _kOnSurfaceVariant, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: _kOnSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'SIGN OUT',
              style: TextStyle(color: Color(0xFFFF4444), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      onClose();
      await AuthService.signOut();
      if (context.mounted) {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dismiss tap outside
        Positioned.fill(
          child: GestureDetector(
            onTap: onClose,
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),
        ),
        Positioned(
          right: anchorRight,
          top: anchorTop,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 260,
              decoration: BoxDecoration(
                color: _kSurfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _kOutlineVariant.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _kPrimary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(color: _kPrimary.withValues(alpha: 0.3), width: 1.5),
                          ),
                          child: ClipOval(
                            child: () {
                              final url = Supabase.instance.client.auth
                                  .currentUser?.userMetadata?['avatar_url'] as String?;
                              return url != null
                                  ? Image.network(url, fit: BoxFit.cover,
                                      errorBuilder: (context, error, stack) => _AvatarFallback(
                                          _displayName().isNotEmpty ? _displayName()[0].toUpperCase() : '?'))
                                  : _AvatarFallback(
                                      _displayName().isNotEmpty ? _displayName()[0].toUpperCase() : '?');
                            }(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _displayName(),
                                style: const TextStyle(
                                  color: _kOnSurface,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _email(),
                                style: TextStyle(
                                  color: _kOnSurfaceVariant.withValues(alpha: 0.7),
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: _kOutlineVariant.withValues(alpha: 0.2)),
                  // Provider row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        Icon(LucideIcons.shieldCheck, size: 14, color: _kOnSurfaceVariant.withValues(alpha: 0.5)),
                        const SizedBox(width: 8),
                        Text(
                          'Signed in via ${_provider()}',
                          style: TextStyle(
                            color: _kOnSurfaceVariant.withValues(alpha: 0.6),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: _kOutlineVariant.withValues(alpha: 0.2)),
                  // Sign out
                  InkWell(
                    onTap: () => _confirmSignOut(context),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.logOut, size: 14, color: Color(0xFFFF4444)),
                          const SizedBox(width: 8),
                          const Text(
                            'Sign out',
                            style: TextStyle(
                              color: Color(0xFFFF4444),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Hero Section ──────────────────────────────────────────────────────────────
class _HeroSection extends StatelessWidget {
  final int selectedFilter;
  final ValueChanged<int> onFilterChanged;

  const _HeroSection({
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  static const _filters = ['ALL BOARDS', 'RECENT', 'SHARED'];

  static String _userName() {
    final user = Supabase.instance.client.auth.currentUser;
    final name = user?.userMetadata?['name'] as String? ??
        user?.userMetadata?['full_name'] as String?;
    if (name != null && name.isNotEmpty) return name.split(' ').first;
    final email = user?.email ?? '';
    return email.split('@').first;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Left: headline + description
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HELLO\n${_userName().toUpperCase()}',
                style: const TextStyle(
                  color: _kOnSurface,
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  height: 0.92,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 2,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Manage your elite scouting reports and complex formation '
                      'data. High-density tactical planning for professional units.',
                      style: TextStyle(
                        color: _kOnSurfaceVariant,
                        fontSize: 13,
                        fontWeight: FontWeight.w300,
                        height: 1.7,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 40),
        // Right: filter tabs
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _kSurfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kOutlineVariant.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_filters.length, (i) {
              final selected = selectedFilter == i;
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => onFilterChanged(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? _kSurfaceContainerHigh
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _filters[i],
                      style: TextStyle(
                        color: selected ? _kPrimary : _kOnSurfaceVariant,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ── Boards Grid ───────────────────────────────────────────────────────────────
class _BoardsGrid extends StatelessWidget {
  final List<BoardModel> boards;
  final int crossAxisCount;
  final void Function(BoardModel) onTapBoard;
  final VoidCallback onNewBoard;
  final int selectedFilter;

  const _BoardsGrid({
    required this.boards,
    required this.crossAxisCount,
    required this.onTapBoard,
    required this.onNewBoard,
    required this.selectedFilter,
  });

  @override
  Widget build(BuildContext context) {
    final isShared = selectedFilter == 2;

    if (boards.isEmpty) {
      return _EmptyState(filter: selectedFilter);
    }

    final extraItems = isShared ? 0 : 2; // no locked/new-board for shared
    final totalItems = boards.length + extraItems;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.88,
      ),
      itemCount: totalItems,
      itemBuilder: (context, index) {
        if (index < boards.length) {
          return _BoardCardWidget(
            board: boards[index],
            onTap: () => onTapBoard(boards[index]),
          );
        } else if (index == boards.length) {
          return const _LockedCardWidget();
        } else {
          return _NewBoardCardWidget(onTap: onNewBoard);
        }
      },
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final int filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    final icon = filter == 1 ? LucideIcons.clock : LucideIcons.users;
    final label = filter == 1 ? 'NO RECENT BOARDS' : 'NO SHARED BOARDS';
    final sub = filter == 1
        ? 'Boards you edit will appear here.'
        : 'Boards shared with you will appear here.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: _kOutlineVariant),
            const SizedBox(height: 16),
            Text(
              label,
              style: const TextStyle(
                color: _kOnSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              sub,
              style: TextStyle(
                color: _kOnSurfaceVariant.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pitch Grid Painter ────────────────────────────────────────────────────────
class _PitchGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _kPrimary.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    const spacing = 24.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Board Card ────────────────────────────────────────────────────────────────
class _BoardCardWidget extends StatefulWidget {
  final BoardModel board;
  final VoidCallback onTap;

  const _BoardCardWidget({required this.board, required this.onTap});

  @override
  State<_BoardCardWidget> createState() => _BoardCardWidgetState();
}

class _BoardCardWidgetState extends State<_BoardCardWidget> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final formation = widget.board.formationHome;
    final hasFormation = formation != null && formation.isNotEmpty;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: _hovered
              ? (Matrix4.identity()..translateByDouble(-2.0, -2.0, 0, 1))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: _kSurfaceContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: _kOutlineVariant.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: _kPrimary.withValues(
                    alpha: _hovered ? 0.2 : 0.1),
                offset: Offset(_hovered ? 6 : 4, _hovered ? 6 : 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                          color: Colors.black.withValues(alpha: 0.4)),
                      CustomPaint(painter: _PitchGridPainter()),
                      // Center circle
                      Center(
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _kPrimary.withValues(alpha: 0.15),
                            ),
                          ),
                        ),
                      ),
                      // Halfway line
                      Center(
                        child: Container(
                          height: 1,
                          color: _kPrimary.withValues(alpha: 0.1),
                        ),
                      ),
                      if (hasFormation)
                        Center(
                          child: Text(
                            formation,
                            style: TextStyle(
                              color: _kPrimary.withValues(alpha: 0.15),
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                      if (_hovered)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: _kBackground.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    _kOutlineVariant.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Icon(
                              LucideIcons.pencil,
                              size: 13,
                              color: _kOnSurface.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formation ?? '—',
                          style: TextStyle(
                            color: _kPrimary.withValues(alpha: 0.7),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          widget.board.timeLabel,
                          style: TextStyle(
                            color: _kOnSurfaceVariant.withValues(alpha: 0.5),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.board.title,
                      style: TextStyle(
                        color: _hovered ? _kPrimary : _kOnSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Locked Card ───────────────────────────────────────────────────────────────
class _LockedCardWidget extends StatefulWidget {
  const _LockedCardWidget();

  @override
  State<_LockedCardWidget> createState() => _LockedCardWidgetState();
}

class _LockedCardWidgetState extends State<_LockedCardWidget> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        decoration: BoxDecoration(
          color: _kSurfaceContainer.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kOutlineVariant.withValues(alpha: 0.35)),
        ),
        child: Stack(
          children: [
            Opacity(
              opacity: 0.3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Center(
                      child: Icon(
                        LucideIcons.lock,
                        size: 32,
                        color: _kOutlineVariant,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'LOCKED',
                              style: TextStyle(
                                color: _kOnSurface,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                            Text(
                              '—',
                              style: TextStyle(
                                color: _kOnSurface,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Expand Portfolio',
                          style: TextStyle(
                            color: _kOnSurface,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_hovered)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                  child: Container(
                    color: _kBackground.withValues(alpha: 0.5),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'PRO SLOT',
                            style: TextStyle(
                              color: _kPrimary,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _kPrimary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _kPrimary.withValues(alpha: 0.4),
                              ),
                            ),
                            child: const Text(
                              'UNLOCK',
                              style: TextStyle(
                                color: _kPrimary,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── New Board Card ────────────────────────────────────────────────────────────
class _NewBoardCardWidget extends StatefulWidget {
  final VoidCallback onTap;
  const _NewBoardCardWidget({required this.onTap});

  @override
  State<_NewBoardCardWidget> createState() => _NewBoardCardWidgetState();
}

class _NewBoardCardWidgetState extends State<_NewBoardCardWidget> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: _hovered
              ? (Matrix4.identity()..translateByDouble(-2.0, -2.0, 0, 1))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: _hovered
                ? _kPrimary.withValues(alpha: 0.05)
                : _kSurfaceContainerHigh.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered
                  ? _kPrimary.withValues(alpha: 0.5)
                  : _kPrimary.withValues(alpha: 0.2),
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: _kPrimary.withValues(alpha: 0.1),
                      offset: const Offset(4, 4),
                      blurRadius: 0,
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _hovered ? 60 : 52,
                  height: _hovered ? 60 : 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kPrimary.withValues(alpha: 0.1),
                  ),
                  child: const Icon(
                    LucideIcons.plus,
                    color: _kPrimary,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'INITIALIZE NEW BOARD',
                  style: TextStyle(
                    color: _kOnSurface,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
