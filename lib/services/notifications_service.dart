import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsService {
  static SupabaseClient get _db => Supabase.instance.client;

  /// Returns all unread + up to 20 recent personal notifications for current user
  static Future<List<Map<String, dynamic>>> fetchPersonal() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return [];

    final rows = await _db
        .from('notifications')
        .select('*, actor:actor_id(id, name, avatar_url), board:board_id(id, title)')
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .limit(30);

    return List<Map<String, dynamic>>.from(rows as List);
  }

  /// Returns active broadcasts not yet seen by current user
  static Future<List<Map<String, dynamic>>> fetchUnseenBroadcasts() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return [];

    // All active broadcasts
    final broadcasts = await _db
        .from('notifications_broadcast')
        .select()
        .order('created_at', ascending: false);

    if ((broadcasts as List).isEmpty) return [];

    // IDs already seen by this user
    final seenRows = await _db
        .from('notifications_broadcast_seen')
        .select('broadcast_id')
        .eq('user_id', uid);

    final seenIds = (seenRows as List)
        .map((r) => r['broadcast_id'] as String)
        .toSet();

    return broadcasts
        .where((b) => !seenIds.contains(b['id'] as String))
        .map((b) => Map<String, dynamic>.from(b))
        .toList();
  }

  /// Mark personal notification as read
  static Future<void> markRead(String notificationId) async {
    await _db
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  /// Mark all personal notifications as read
  static Future<void> markAllRead() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;
    await _db
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', uid)
        .eq('is_read', false);
  }

  /// Mark broadcast as seen
  static Future<void> markBroadcastSeen(String broadcastId) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;
    await _db.from('notifications_broadcast_seen').upsert({
      'user_id': uid,
      'broadcast_id': broadcastId,
    });
  }

  /// Total unread count (personal unread + unseen broadcasts)
  static Future<int> fetchUnreadCount() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return 0;

    final results = await Future.wait([
      _db
          .from('notifications')
          .select('id')
          .eq('user_id', uid)
          .eq('is_read', false),
      fetchUnseenBroadcasts(),
    ]);

    final personalUnread = (results[0] as List).length;
    final unseenBroadcasts = (results[1] as List).length;
    return personalUnread + unseenBroadcasts;
  }
}
