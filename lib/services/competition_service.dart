import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/competitions_data.dart';

class CompetitionService {
  static final _db = Supabase.instance.client;

  static Future<List<Competition>> fetchCompetitions() async {
    final rows = await _db
        .from('competitions')
        .select('id, external_id, slug, name, short_name, color_hex, logo_url, sort_order')
        .eq('is_active', true)
        .order('sort_order', ascending: true);
    return (rows as List)
        .map((r) => Competition.fromSupabaseJson(r as Map<String, dynamic>))
        .toList();
  }
}
