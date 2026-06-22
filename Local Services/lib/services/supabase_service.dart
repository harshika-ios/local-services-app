import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/booking_model.dart';
import '../models/category_model.dart';
import '../models/provider_model.dart';

class SupabaseService {
  SupabaseService._();

  static final SupabaseService instance = SupabaseService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<ProviderModel>> fetchProviders() async {
    final results = await Future.wait([
      _client.from('providers').select().order('created_at', ascending: false),
      _client.from('favorites').select('provider_id'),
      _client.from('profiles').select('user_id, last_seen_at'),
    ]);

    final rows = (results[0] as List).cast<Map<String, dynamic>>();
    final favRows = (results[1] as List).cast<Map<String, dynamic>>();
    final profileRows = (results[2] as List).cast<Map<String, dynamic>>();

    final savesMap = <String, int>{};
    for (final r in favRows) {
      final id = r['provider_id'] as String;
      savesMap[id] = (savesMap[id] ?? 0) + 1;
    }

    final lastSeenMap = <String, DateTime?>{};
    for (final r in profileRows) {
      final uid = r['user_id'] as String?;
      final raw = r['last_seen_at'] as String?;
      if (uid != null) lastSeenMap[uid] = raw != null ? DateTime.tryParse(raw) : null;
    }

    return rows.map(ProviderModel.fromJson).map((p) {
      return p
          .copyWithSaves(savesMap[p.id] ?? 0)
          .copyWithLastSeen(p.userId != null ? lastSeenMap[p.userId] : null);
    }).toList();
  }

  Future<List<CategoryModel>> fetchCategories() async {
    final response = await _client
        .from('categories')
        .select()
        .order('sort_order', ascending: true);

    final rows = (response as List).cast<Map<String, dynamic>>();
    return rows.map(CategoryModel.fromJson).toList();
  }

  Future<List<BookingModel>> fetchBookings() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return const [];

    final response = await _client
        .from('bookings')
        .select('id, scheduled_for, status, notes, customer_name, providers(*)')
        .eq('user_id', uid)
        .order('scheduled_for', ascending: false);

    final rows = (response as List).cast<Map<String, dynamic>>();
    return rows.map(BookingModel.fromJson).toList();
  }

  Future<List<BookingModel>> fetchProviderBookings(String providerId) async {
    final response = await _client
        .from('bookings')
        .select('id, scheduled_for, status, notes, customer_name')
        .eq('provider_id', providerId)
        .order('scheduled_for', ascending: false);

    final rows = (response as List).cast<Map<String, dynamic>>();
    return rows.map(BookingModel.fromProviderJson).toList();
  }

  Future<void> createBooking({
    required String providerId,
    required DateTime scheduledFor,
    String? notes,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw StateError('Not signed in');

    final email = _client.auth.currentUser?.email;
    final customerName = _nameFromEmail(email);

    await _client.from('bookings').insert({
      'user_id': uid,
      'provider_id': providerId,
      'scheduled_for': scheduledFor.toUtc().toIso8601String(),
      'status': 'upcoming',
      'customer_name': customerName,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    });
  }

  static String _nameFromEmail(String? email) {
    if (email == null || email.isEmpty) return 'Customer';
    final local = email.split('@').first;
    if (local.isEmpty) return 'Customer';
    return local
        .split(RegExp(r'[._+\-]'))
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
        .join(' ');
  }
}
