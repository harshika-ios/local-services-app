import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile_model.dart';
import '../models/provider_model.dart';

const String _kAvatarBucket = 'avatars';

class ProviderStats {
  const ProviderStats({
    required this.views,
    required this.favorites,
    required this.upcomingBookings,
  });

  final int views;
  final int favorites;
  final int upcomingBookings;

  static const empty = ProviderStats(
    views: 0,
    favorites: 0,
    upcomingBookings: 0,
  );
}

class ProfileService {
  ProfileService._();

  static final ProfileService instance = ProfileService._();

  SupabaseClient get _client => Supabase.instance.client;
  String? get _uid => _client.auth.currentUser?.id;

  Future<ProfileModel?> fetchMyProfile() async {
    final uid = _uid;
    if (uid == null) return null;
    final row = await _client
        .from('profiles')
        .select()
        .eq('user_id', uid)
        .maybeSingle();
    if (row == null) return null;
    return ProfileModel.fromJson(row);
  }

  Future<void> setRole(UserRole role) async {
    final uid = _uid;
    if (uid == null) return;
    // The handle_new_user trigger creates the row at signup, so update is enough.
    // Upsert keeps it safe if the trigger didn't fire for some reason.
    await _client.from('profiles').upsert({
      'user_id': uid,
      'role': role.name,
    });
  }

  Future<void> updateMyProfile({
    String? displayName,
    String? phone,
    String? avatarUrl,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    final patch = <String, dynamic>{
      'user_id': uid,
      'display_name': ?displayName,
      'phone': ?phone,
      'avatar_url': ?avatarUrl,
    };
    await _client.from('profiles').upsert(patch);
  }

  Future<ProviderModel?> fetchMyProvider() async {
    final uid = _uid;
    if (uid == null) return null;
    final row = await _client
        .from('providers')
        .select()
        .eq('user_id', uid)
        .maybeSingle();
    if (row == null) return null;
    return ProviderModel.fromJson(row);
  }

  Future<ProviderModel> createMyProvider({
    required String name,
    required String phone,
    required String serviceType,
    required double latitude,
    required double longitude,
    String? address,
    String? description,
    String? avatarUrl,
  }) async {
    final uid = _uid;
    if (uid == null) {
      throw StateError('Not signed in');
    }
    final row = await _client
        .from('providers')
        .insert({
          'user_id': uid,
          'name': name,
          'phone': phone,
          'service_type': serviceType,
          'latitude': latitude,
          'longitude': longitude,
          'address': address,
          'description': description,
          'avatar_url': avatarUrl,
          'is_active': true,
        })
        .select()
        .single();
    return ProviderModel.fromJson(row);
  }

  Future<void> updateMyProvider({
    required String providerId,
    String? name,
    String? phone,
    String? serviceType,
    String? address,
    String? description,
    String? avatarUrl,
  }) async {
    final patch = <String, dynamic>{
      'name': ?name,
      'phone': ?phone,
      'service_type': ?serviceType,
      'address': ?address,
      'description': ?description,
      'avatar_url': ?avatarUrl,
    };
    if (patch.isEmpty) return;
    await _client.from('providers').update(patch).eq('id', providerId);
  }

  Future<void> setProviderActive(String providerId, bool isActive) async {
    await _client
        .from('providers')
        .update({'is_active': isActive})
        .eq('id', providerId);
  }

  Future<ProviderStats> fetchProviderStats(String providerId) async {
    final providerRow = await _client
        .from('providers')
        .select('view_count')
        .eq('id', providerId)
        .maybeSingle();
    final favRows = await _client
        .from('favorites')
        .select('provider_id')
        .eq('provider_id', providerId);
    final bookingRows = await _client
        .from('bookings')
        .select('id')
        .eq('provider_id', providerId)
        .eq('status', 'upcoming');
    return ProviderStats(
      views: (providerRow?['view_count'] as int?) ?? 0,
      favorites: (favRows as List).length,
      upcomingBookings: (bookingRows as List).length,
    );
  }

  Future<void> updateLastSeen() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _client.from('profiles').upsert({
        'user_id': uid,
        'last_seen_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {
      // Best-effort — never block app startup on this.
    }
  }

  // Fire-and-forget — bumps view_count via the security-definer RPC.
  // The function ignores the call when the viewer owns the listing.
  Future<void> incrementProviderView(String providerId) async {
    try {
      await _client.rpc(
        'increment_provider_view',
        params: {'p_id': providerId},
      );
    } catch (_) {
      // View tracking is best-effort; never block the UI on it.
    }
  }

  Future<void> setProviderLocation(
    String providerId, {
    required double latitude,
    required double longitude,
  }) async {
    await _client
        .from('providers')
        .update({'latitude': latitude, 'longitude': longitude})
        .eq('id', providerId);
  }

  // Uploads a local image to the provider-avatars bucket under {uid}/{ts}.jpg
  // and returns the resulting public URL. Caller is responsible for saving
  // the URL to the providers row.
  Future<String> uploadAvatar(File file) async {
    final uid = _uid;
    if (uid == null) {
      throw StateError('Not signed in');
    }
    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = '$uid/$ts.jpg';
    await _client.storage.from(_kAvatarBucket).upload(
          path,
          file,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/jpeg',
          ),
        );
    return _client.storage.from(_kAvatarBucket).getPublicUrl(path);
  }

  Future<void> setProviderAvatar(String providerId, String avatarUrl) async {
    await _client
        .from('providers')
        .update({'avatar_url': avatarUrl})
        .eq('id', providerId);
  }
}
