import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../services/notifications_service.dart';

// ─── Icon map for broadcast types ────────────────────────────────────────────
const _broadcastIcons = {
  'new_version': LucideIcons.sparkles,
  'promo': LucideIcons.tag,
  'maintenance': LucideIcons.wrench,
  'announcement': LucideIcons.megaphone,
};

const _broadcastColors = {
  'new_version': Color(0xFF00FF41),
  'promo': Color(0xFFFDD329),
  'maintenance': Color(0xFFFF9500),
  'announcement': Color(0xFF5B8DEF),
};

// ─── Personal notification icons ─────────────────────────────────────────────
const _personalIcons = {
  'board_shared': LucideIcons.share2,
  'board_updated': LucideIcons.pencil,
  'board_commented': LucideIcons.messageCircle,
};

const _kAccent = Color(0xFF00FF41);
const _kBorder = Color(0xFF2E2E2E);

// ─── NotificationsBell ───────────────────────────────────────────────────────

class NotificationsBell extends StatefulWidget {
  const NotificationsBell({super.key});

  @override
  State<NotificationsBell> createState() => _NotificationsBellState();
}

class _NotificationsBellState extends State<NotificationsBell> {
  final _overlayController = OverlayPortalController();
  final _buttonKey = GlobalKey();

  int _unreadCount = 0;
  bool _loading = true;
  List<Map<String, dynamic>> _personal = [];
  List<Map<String, dynamic>> _broadcasts = [];

  @override
  void initState() {
    super.initState();
    _loadCount();
  }

  Future<void> _loadCount() async {
    final count = await NotificationsService.fetchUnreadCount();
    if (mounted) setState(() => _unreadCount = count);
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      NotificationsService.fetchPersonal(),
      NotificationsService.fetchUnseenBroadcasts(),
    ]);
    if (mounted) {
      setState(() {
        _personal = results[0];
        _broadcasts = results[1];
        _loading = false;
      });
    }
  }

  void _toggle() {
    if (_overlayController.isShowing) {
      _overlayController.hide();
    } else {
      _loadAll();
      _overlayController.show();
    }
  }

  Future<void> _markAllRead() async {
    await NotificationsService.markAllRead();
    setState(() {
      for (final n in _personal) {
        n['is_read'] = true;
      }
      _unreadCount = _broadcasts.length;
    });
  }

  Future<void> _dismissBroadcast(String id) async {
    await NotificationsService.markBroadcastSeen(id);
    setState(() {
      _broadcasts.removeWhere((b) => b['id'] == id);
      _unreadCount = (_unreadCount - 1).clamp(0, 999);
    });
  }

  Future<void> _markPersonalRead(String id) async {
    await NotificationsService.markRead(id);
    setState(() {
      final n = _personal.firstWhere((n) => n['id'] == id, orElse: () => {});
      if (n.isNotEmpty && n['is_read'] == false) {
        n['is_read'] = true;
        _unreadCount = (_unreadCount - 1).clamp(0, 999);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _overlayController,
      overlayChildBuilder: (_) => _NotificationsDropdown(
        buttonKey: _buttonKey,
        loading: _loading,
        personal: _personal,
        broadcasts: _broadcasts,
        onClose: _overlayController.hide,
        onMarkAllRead: _markAllRead,
        onDismissBroadcast: _dismissBroadcast,
        onMarkPersonalRead: _markPersonalRead,
      ),
      child: _BellButton(
        key: _buttonKey,
        unreadCount: _unreadCount,
        isOpen: _overlayController.isShowing,
        onTap: _toggle,
      ),
    );
  }
}

// ─── Bell Button ─────────────────────────────────────────────────────────────

class _BellButton extends StatefulWidget {
  const _BellButton({
    super.key,
    required this.unreadCount,
    required this.isOpen,
    required this.onTap,
  });
  final int unreadCount;
  final bool isOpen;
  final VoidCallback onTap;

  @override
  State<_BellButton> createState() => _BellButtonState();
}

class _BellButtonState extends State<_BellButton> {
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
          duration: const Duration(milliseconds: 150),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: widget.isOpen
                ? Colors.white.withValues(alpha: 0.12)
                : _hovered
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                LucideIcons.bell,
                size: 18,
                color: widget.isOpen
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.6),
              ),
              if (widget.unreadCount > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _kAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF131313), width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.unreadCount > 9 ? '9+' : '${widget.unreadCount}',
                      style: const TextStyle(
                        color: Color(0xFF003907),
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Dropdown Panel ───────────────────────────────────────────────────────────

class _NotificationsDropdown extends StatelessWidget {
  const _NotificationsDropdown({
    required this.buttonKey,
    required this.loading,
    required this.personal,
    required this.broadcasts,
    required this.onClose,
    required this.onMarkAllRead,
    required this.onDismissBroadcast,
    required this.onMarkPersonalRead,
  });

  final GlobalKey buttonKey;
  final bool loading;
  final List<Map<String, dynamic>> personal;
  final List<Map<String, dynamic>> broadcasts;
  final VoidCallback onClose;
  final VoidCallback onMarkAllRead;
  final void Function(String id) onDismissBroadcast;
  final void Function(String id) onMarkPersonalRead;

  Offset _getDropdownOffset() {
    final box = buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return Offset.zero;
    final pos = box.localToGlobal(Offset.zero);
    // Align right edge of dropdown with right edge of button
    return Offset(pos.dx + box.size.width - 360, pos.dy + box.size.height + 8);
  }

  bool get _hasUnread => personal.any((n) => n['is_read'] == false);
  bool get _isEmpty => personal.isEmpty && broadcasts.isEmpty;

  @override
  Widget build(BuildContext context) {
    final offset = _getDropdownOffset();

    return Stack(
      children: [
        // Backdrop to close on outside tap
        Positioned.fill(
          child: GestureDetector(
            onTap: onClose,
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),
        ),

        Positioned(
          left: offset.dx,
          top: offset.dy,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: 360,
                constraints: const BoxConstraints(maxHeight: 520),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A).withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _kBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 32,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    const Divider(height: 1, color: _kBorder),
                    Flexible(child: _buildBody()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          const Text(
            'Notifications',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
          const Spacer(),
          if (_hasUnread)
            GestureDetector(
              onTap: onMarkAllRead,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Text(
                  'Mark all read',
                  style: TextStyle(
                    color: _kAccent.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (loading) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(
            color: _kAccent,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_isEmpty) {
      return SizedBox(
        height: 160,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.bellOff, size: 28, color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Text(
              'All caught up',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 8),
      shrinkWrap: true,
      children: [
        // Broadcasts first
        if (broadcasts.isNotEmpty) ...[
          _SectionLabel(label: 'Announcements'),
          ...broadcasts.map((b) => _BroadcastItem(
            data: b,
            onDismiss: () => onDismissBroadcast(b['id'] as String),
          )),
          if (personal.isNotEmpty) const Divider(height: 1, color: _kBorder),
        ],

        // Personal
        if (personal.isNotEmpty) ...[
          _SectionLabel(
            label: personal.any((n) => n['is_read'] == false) ? 'New' : 'Recent',
          ),
          ...personal.map((n) => _PersonalItem(
            data: n,
            onTap: () => onMarkPersonalRead(n['id'] as String),
          )),
        ],
      ],
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.3),
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ─── Broadcast Item ───────────────────────────────────────────────────────────

class _BroadcastItem extends StatefulWidget {
  const _BroadcastItem({required this.data, required this.onDismiss});
  final Map<String, dynamic> data;
  final VoidCallback onDismiss;

  @override
  State<_BroadcastItem> createState() => _BroadcastItemState();
}

class _BroadcastItemState extends State<_BroadcastItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final type = widget.data['type'] as String? ?? 'announcement';
    final icon = _broadcastIcons[type] ?? LucideIcons.megaphone;
    final color = _broadcastColors[type] ?? const Color(0xFF5B8DEF);
    final title = widget.data['title'] as String? ?? '';
    final body = widget.data['body'] as String? ?? '';
    final actionLabel = widget.data['action_label'] as String?;
    final createdAt = widget.data['created_at'] != null
        ? DateTime.tryParse(widget.data['created_at'] as String)
        : null;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.fromLTRB(12, 2, 12, 2),
        decoration: BoxDecoration(
          color: _hovered
              ? color.withValues(alpha: 0.08)
              : color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 15, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (createdAt != null)
                          Text(
                            timeago.format(createdAt),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                    if (body.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        body,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                    if (actionLabel != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        actionLabel,
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: widget.onDismiss,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Icon(
                    LucideIcons.x,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Personal Item ────────────────────────────────────────────────────────────

class _PersonalItem extends StatefulWidget {
  const _PersonalItem({required this.data, required this.onTap});
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  @override
  State<_PersonalItem> createState() => _PersonalItemState();
}

class _PersonalItemState extends State<_PersonalItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isRead = widget.data['is_read'] as bool? ?? true;
    final type = widget.data['type'] as String? ?? 'board_updated';
    final icon = _personalIcons[type] ?? LucideIcons.bell;
    final title = widget.data['title'] as String? ?? '';
    final body = widget.data['body'] as String?;
    final actor = widget.data['actor'] as Map<String, dynamic>?;
    final actorName = actor?['name'] as String?;
    final createdAt = widget.data['created_at'] != null
        ? DateTime.tryParse(widget.data['created_at'] as String)
        : null;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.fromLTRB(12, 2, 12, 2),
          decoration: BoxDecoration(
            color: _hovered
                ? Colors.white.withValues(alpha: 0.07)
                : isRead
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Unread dot
                Padding(
                  padding: const EdgeInsets.only(top: 6, right: 8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isRead ? Colors.transparent : _kAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // Icon
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 14,
                    color: Colors.white.withValues(alpha: isRead ? 0.4 : 0.8),
                  ),
                ),
                const SizedBox(width: 10),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 13,
                                  color: Colors.white.withValues(
                                    alpha: isRead ? 0.6 : 0.9,
                                  ),
                                  height: 1.3,
                                ),
                                children: [
                                  if (actorName != null)
                                    TextSpan(
                                      text: '$actorName ',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  TextSpan(text: title),
                                ],
                              ),
                            ),
                          ),
                          if (createdAt != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                timeago.format(createdAt),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  fontSize: 11,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (body != null && body.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          body,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
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
