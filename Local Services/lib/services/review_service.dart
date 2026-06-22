import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/review_model.dart';

class ProviderReviewSummary {
  const ProviderReviewSummary({
    required this.averageRating,
    required this.reviewCount,
    required this.favoritesCount,
    required this.recentReviews,
  });

  final double averageRating;
  final int reviewCount;
  final int favoritesCount;
  final List<ReviewModel> recentReviews;

  static const empty = ProviderReviewSummary(
    averageRating: 0,
    reviewCount: 0,
    favoritesCount: 0,
    recentReviews: [],
  );
}

class ReviewService {
  ReviewService._();

  static final ReviewService instance = ReviewService._();

  SupabaseClient get _client => Supabase.instance.client;
  String? get _uid => _client.auth.currentUser?.id;

  Future<ProviderReviewSummary> fetchSummary(String providerId) async {
    final reviewRows = await _client
        .from('reviews')
        .select()
        .eq('provider_id', providerId)
        .order('created_at', ascending: false)
        .limit(20);
    final reviews = (reviewRows as List)
        .map((r) => ReviewModel.fromJson(r as Map<String, dynamic>))
        .toList();

    final favRows = await _client
        .from('favorites')
        .select('provider_id')
        .eq('provider_id', providerId);
    final favoritesCount = (favRows as List).length;

    final avg = reviews.isEmpty
        ? 0.0
        : reviews.map((r) => r.rating).reduce((a, b) => a + b) /
            reviews.length;

    return ProviderReviewSummary(
      averageRating: avg,
      reviewCount: reviews.length,
      favoritesCount: favoritesCount,
      recentReviews: reviews,
    );
  }

  Future<void> submitReview({
    required String providerId,
    required int rating,
    String? comment,
  }) async {
    final uid = _uid;
    if (uid == null) {
      throw StateError('Not signed in');
    }
    final email = _client.auth.currentUser?.email;
    final profile = await _client
        .from('profiles')
        .select('display_name')
        .eq('user_id', uid)
        .maybeSingle();
    final displayName = (profile?['display_name'] as String?)?.trim();
    final reviewerName = (displayName != null && displayName.isNotEmpty)
        ? displayName
        : _deriveNameFromEmail(email);

    await _client.from('reviews').insert({
      'provider_id': providerId,
      'user_id': uid,
      'reviewer_name': reviewerName,
      'rating': rating,
      'comment': (comment == null || comment.trim().isEmpty)
          ? null
          : comment.trim(),
    });
  }

  String _deriveNameFromEmail(String? email) {
    if (email == null || email.isEmpty) return 'Anonymous';
    final local = email.split('@').first;
    if (local.isEmpty) return 'Anonymous';
    return local
        .split(RegExp(r'[._-]'))
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
        .join(' ');
  }
}
