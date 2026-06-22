import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/provider_model.dart';

class FavoritesService {
  FavoritesService._();

  static final FavoritesService instance = FavoritesService._();

  final ValueNotifier<Set<String>> ids = ValueNotifier(<String>{});

  SupabaseClient get _client => Supabase.instance.client;
  String? get _userId => _client.auth.currentUser?.id;

  Future<void> loadIds() async {
    final uid = _userId;
    if (uid == null) {
      ids.value = <String>{};
      return;
    }
    final rows = await _client
        .from('favorites')
        .select('provider_id')
        .eq('user_id', uid);
    ids.value = (rows as List)
        .map((r) => (r as Map<String, dynamic>)['provider_id'] as String)
        .toSet();
  }

  void clear() {
    ids.value = <String>{};
  }

  bool isFavorite(String providerId) => ids.value.contains(providerId);

  Future<void> addFavorite(String providerId) async {
    final uid = _userId;
    if (uid == null || ids.value.contains(providerId)) return;

    ids.value = {...ids.value, providerId};
    try {
      await _client.from('favorites').insert({
        'user_id': uid,
        'provider_id': providerId,
      });
    } catch (_) {
      ids.value = {...ids.value}..remove(providerId);
      rethrow;
    }
  }

  Future<void> removeFavorite(String providerId) async {
    final uid = _userId;
    if (uid == null || !ids.value.contains(providerId)) return;

    ids.value = {...ids.value}..remove(providerId);
    try {
      await _client.from('favorites').delete().match({
        'user_id': uid,
        'provider_id': providerId,
      });
    } catch (_) {
      ids.value = {...ids.value, providerId};
      rethrow;
    }
  }

  Future<void> toggle(String providerId) {
    return ids.value.contains(providerId)
        ? removeFavorite(providerId)
        : addFavorite(providerId);
  }

  Future<List<ProviderModel>> getUserFavorites() async {
    final uid = _userId;
    if (uid == null) return const [];
    final rows = await _client
        .from('favorites')
        .select('providers(*)')
        .eq('user_id', uid);
    return (rows as List)
        .map((r) => (r as Map<String, dynamic>)['providers'])
        .whereType<Map<String, dynamic>>()
        .map(ProviderModel.fromJson)
        .toList();
  }

  Future<List<ProviderModel>> fetchFavorites() => getUserFavorites();
}
