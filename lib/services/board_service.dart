import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/board_model.dart';

class BoardService {
  static final _db = Supabase.instance.client;

  static String get _uid => _db.auth.currentUser!.id;

  // ─── Fetch ─────────────────────────────────────────────────────────────────

  static Future<List<BoardModel>> fetchBoards({bool archived = false}) async {
    final rows = await _db
        .from('boards')
        .select()
        .eq('owner_id', _uid)
        .eq('is_archived', archived)
        .order('sort_order', ascending: true)
        .order('updated_at', ascending: false);
    return (rows as List).map((r) => BoardModel.fromJson(r)).toList();
  }

  static Future<BoardModel> fetchBoardById(String boardId) async {
    final row = await _db
        .from('boards')
        .select()
        .eq('id', boardId)
        .eq('owner_id', _uid)
        .single();
    return BoardModel.fromJson(row);
  }

  // ─── Create ────────────────────────────────────────────────────────────────

  static Future<BoardModel> createBoard({required String title}) async {
    final row = await _db
        .from('boards')
        .insert({'owner_id': _uid, 'title': title, 'snapshot': {}})
        .select()
        .single();
    return BoardModel.fromJson(row);
  }

  // ─── Update title ──────────────────────────────────────────────────────────

  static Future<void> updateTitle(String boardId, String title) async {
    await _db.from('boards').update({'title': title}).eq('id', boardId);
  }

  // ─── Save snapshot ─────────────────────────────────────────────────────────

  static Future<void> saveSnapshot(
    String boardId,
    Map<String, dynamic> snapshot, {
    String? formationHome,
    String? formationAway,
  }) async {
    await _db.from('boards').update({
      'snapshot': snapshot,
      'formation_home': formationHome,
      'formation_away': formationAway,
    }).eq('id', boardId);
  }

  // ─── Archive / Delete ──────────────────────────────────────────────────────

  static Future<void> archiveBoard(String boardId) async {
    await _db
        .from('boards')
        .update({'is_archived': true})
        .eq('id', boardId);
  }

  static Future<void> deleteBoard(String boardId) async {
    await _db.from('boards').delete().eq('id', boardId);
  }
}
