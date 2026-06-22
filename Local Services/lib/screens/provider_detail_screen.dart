import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/booking_model.dart';
import '../models/provider_model.dart';
import '../widgets/booking_card.dart';
import '../models/review_model.dart';
import '../services/favorites_service.dart';
import '../services/profile_service.dart';
import '../services/review_service.dart';
import '../services/supabase_service.dart';
import '../utils/service_visuals.dart';

class ProviderDetailScreen extends StatefulWidget {
  const ProviderDetailScreen({
    required this.provider,
    this.booking,
    super.key,
  });

  final ProviderModel provider;
  final BookingModel? booking;

  @override
  State<ProviderDetailScreen> createState() => _ProviderDetailScreenState();
}

class _ProviderDetailScreenState extends State<ProviderDetailScreen> {
  ProviderModel get provider => widget.provider;

  late Future<ProviderReviewSummary> _summaryFuture;

  @override
  void initState() {
    super.initState();
    ProfileService.instance.incrementProviderView(provider.id);
    _summaryFuture = ReviewService.instance.fetchSummary(provider.id);
  }

  Future<void> _refreshSummary() async {
    final next = ReviewService.instance.fetchSummary(provider.id);
    setState(() {
      _summaryFuture = next;
    });
    await next;
  }

  bool get _isOwner =>
      provider.userId != null &&
      provider.userId == Supabase.instance.client.auth.currentUser?.id;

  String _sanitizePhone(String phone) =>
      phone.replaceAll(RegExp(r'[^0-9+]'), '');

  Future<void> _call() async {
    final uri = Uri(scheme: 'tel', path: _sanitizePhone(provider.phone));
    final ok = await launchUrl(uri);
    if (!ok && mounted) _snack('Could not open dialer');
  }

  Future<void> _whatsapp() async {
    final number = _sanitizePhone(provider.phone).replaceAll('+', '');
    final uri = Uri.parse('https://wa.me/$number');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) _snack('Could not open WhatsApp');
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openReviewSheet() async {
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WriteReviewSheet(providerId: provider.id),
    );
    if (submitted == true) await _refreshSummary();
  }

  Future<void> _openBookingSheet() async {
    final booked = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookingSheet(provider: provider),
    );
    if (booked == true && mounted) {
      _snack('Booking confirmed! Check My Bookings for details.');
    }
  }

@override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final name = provider.name.isNotEmpty ? provider.name : 'Unnamed provider';
    final serviceType =
        provider.serviceType.isNotEmpty ? provider.serviceType : 'Service';
    final hasPhone = provider.phone.isNotEmpty;
    final hasAddress = provider.address?.isNotEmpty ?? false;
    final hasDescription = provider.description?.isNotEmpty ?? false;
    final distance = provider.distance;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          ValueListenableBuilder<Set<String>>(
            valueListenable: FavoritesService.instance.ids,
            builder: (context, ids, _) {
              final isFav = ids.contains(provider.id);
              return IconButton(
                tooltip: isFav ? 'Remove from favorites' : 'Add to favorites',
                onPressed: () => FavoritesService.instance.toggle(provider.id),
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.redAccent : Colors.black87,
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: FutureBuilder<ProviderReviewSummary>(
        future: _summaryFuture,
        builder: (context, snapshot) {
          final summary = snapshot.data ?? ProviderReviewSummary.empty;
          final loading =
              snapshot.connectionState == ConnectionState.waiting;

          return RefreshIndicator(
            onRefresh: _refreshSummary,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                _Hero(provider: provider),
                const SizedBox(height: 20),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F0FF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        serviceType,
                        style: TextStyle(
                          color: primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (distance != null) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${distance.toStringAsFixed(1)} km away',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                _StatsRow(
                  rating: summary.averageRating,
                  ratingCount: summary.reviewCount,
                  favoritesCount: summary.favoritesCount,
                  lastSeenAt: provider.lastSeenAt,
                  createdAt: provider.createdAt,
                  loading: loading,
                ),
                if (hasDescription) ...[
                  const SizedBox(height: 24),
                  const _SectionTitle('About'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _cardDecoration(),
                    child: Text(
                      provider.description!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                const _SectionTitle('Contact'),
                const SizedBox(height: 8),
                _DetailTile(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: hasPhone ? provider.phone : 'Not provided',
                ),
                if (hasAddress) ...[
                  const SizedBox(height: 12),
                  _DetailTile(
                    icon: Icons.location_on_outlined,
                    label: 'Address',
                    value: provider.address!,
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(child: _SectionTitle('Reviews')),
                    if (!_isOwner)
                      TextButton.icon(
                        onPressed: _openReviewSheet,
                        icon: const Icon(Icons.rate_review_outlined, size: 16),
                        label: const Text('Write a review'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (loading && summary.recentReviews.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (summary.recentReviews.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: _cardDecoration(),
                    child: const Text(
                      'No reviews yet. Be the first to share your experience.',
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  )
                else
                  Column(
                    children: [
                      for (final r in summary.recentReviews) ...[
                        _ReviewTile(review: r),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                const SizedBox(height: 28),
                if (widget.booking != null) ...[
                  _BookingDetailsCard(booking: widget.booking!),
                  const SizedBox(height: 10),
                ] else if (!_isOwner) ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _openBookingSheet,
                      icon: const Icon(Icons.calendar_today),
                      label: const Text('Book Now'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: hasPhone ? _call : null,
                    icon: const Icon(Icons.call),
                    label: const Text('Call'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: hasPhone ? _whatsapp : null,
                    icon: const Icon(Icons.chat),
                    label: const Text('WhatsApp'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/* --------------------------- Hero --------------------------- */

class _Hero extends StatelessWidget {
  const _Hero({required this.provider});

  final ProviderModel provider;

  @override
  Widget build(BuildContext context) {
    final hasAvatar = provider.avatarUrl?.isNotEmpty ?? false;

    // When an avatar exists we leave 40px of overhang for the circular badge
    // so the photo straddles the bottom edge of the tinted hero.
    return SizedBox(
      height: hasAvatar ? 280 : 240,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 240,
            width: double.infinity,
            decoration: BoxDecoration(
              color: tintForService(provider.serviceType),
              borderRadius: BorderRadius.circular(28),
            ),
            alignment: Alignment.center,
            child: Icon(
              iconForService(provider.serviceType),
              size: 88,
              color: iconColorForService(provider.serviceType),
            ),
          ),
          if (hasAvatar)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.white, width: 4),
                    image: DecorationImage(
                      image: NetworkImage(provider.avatarUrl!),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/* --------------------------- Stats row --------------------------- */

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.rating,
    required this.ratingCount,
    required this.favoritesCount,
    required this.lastSeenAt,
    required this.createdAt,
    required this.loading,
  });

  final double rating;
  final int ratingCount;
  final int favoritesCount;
  final DateTime? lastSeenAt;
  final DateTime? createdAt;
  final bool loading;

  static String _lastActiveLabel(DateTime? dt) {
    if (dt == null) return '—';
    final diff = DateTime.now().difference(dt);
    if (diff.inHours < 24) return 'today';
    if (diff.inDays == 1) return '1d ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    final months = (diff.inDays / 30).round();
    if (months < 12) return '${months}mo ago';
    return '${(diff.inDays / 365).round()}y ago';
  }

  static String _joinedLabel(DateTime? dt) {
    if (dt == null) return 'New';
    final days = DateTime.now().difference(dt).inDays;
    if (days < 1) return 'today';
    if (days < 30) return '${days}d';
    final months = (days / 30).round();
    if (months < 12) return '${months}mo';
    return '${(days / 365).round()}y';
  }

  @override
  Widget build(BuildContext context) {
    final ratingValue = ratingCount == 0 ? '—' : rating.toStringAsFixed(1);
    final ratingLabel = ratingCount == 0
        ? 'no reviews'
        : '$ratingCount ${ratingCount == 1 ? "review" : "reviews"}';
    final isActiveToday = lastSeenAt != null &&
        DateTime.now().difference(lastSeenAt!).inHours < 24;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.star_rounded,
                iconColor: const Color(0xFFFFA928),
                value: ratingValue,
                label: ratingLabel,
                loading: loading,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                icon: Icons.favorite_rounded,
                iconColor: Colors.redAccent,
                value: favoritesCount == 0 ? '—' : '$favoritesCount',
                label: 'saved',
                loading: loading,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.circle,
                iconColor: isActiveToday
                    ? const Color(0xFF1F7A3D)
                    : Colors.black38,
                value: _lastActiveLabel(lastSeenAt),
                label: 'last active',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                icon: Icons.calendar_month_outlined,
                iconColor: Theme.of(context).colorScheme.primary,
                value: _joinedLabel(createdAt),
                label: 'on app',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.loading = false,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 6),
          loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

/* --------------------------- Section + tiles --------------------------- */

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: Colors.black54,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final ReviewModel review;

  String _agoLabel(DateTime created) {
    final diff = DateTime.now().difference(created);
    if (diff.inDays == 0) return 'today';
    if (diff.inDays == 1) return '1d ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    final months = (diff.inDays / 30).round();
    if (months < 12) return '${months}mo ago';
    final years = (diff.inDays / 365).round();
    return '${years}y ago';
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final initial = review.reviewerName.isNotEmpty
        ? review.reviewerName[0].toUpperCase()
        : '?';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFE8F0FF),
                child: Text(
                  initial,
                  style: TextStyle(
                    color: primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  review.reviewerName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                _agoLabel(review.createdAt),
                style: const TextStyle(color: Colors.black45, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (i) {
              return Icon(
                i < review.rating
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                size: 16,
                color: const Color(0xFFFFA928),
              );
            }),
          ),
          if (review.comment != null) ...[
            const SizedBox(height: 6),
            Text(
              review.comment!,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/* --------------------------- Write review sheet --------------------------- */

class _WriteReviewSheet extends StatefulWidget {
  const _WriteReviewSheet({required this.providerId});

  final String providerId;

  @override
  State<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<_WriteReviewSheet> {
  final _commentController = TextEditingController();
  int _rating = 0;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      setState(() => _error = 'Pick a star rating.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ReviewService.instance.submitReview(
        providerId: widget.providerId,
        rating: _rating,
        comment: _commentController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF6F8FB),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Write a review',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final star = i + 1;
                final filled = star <= _rating;
                return IconButton(
                  iconSize: 36,
                  onPressed: _submitting
                      ? null
                      : () => setState(() => _rating = star),
                  icon: Icon(
                    filled ? Icons.star_rounded : Icons.star_border_rounded,
                    color: const Color(0xFFFFA928),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 4,
              enabled: !_submitting,
              decoration: InputDecoration(
                hintText: 'Share your experience (optional)',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.2,
                  ),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Submit review',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
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

/* --------------------------- Booking details card --------------------------- */

class _BookingDetailsCard extends StatelessWidget {
  const _BookingDetailsCard({required this.booking});

  final BookingModel booking;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  String _formatDate(DateTime dt) =>
      '${_weekdays[dt.weekday - 1]}, ${_months[dt.month - 1]} ${dt.day}, ${dt.year}';

  String _formatTime(DateTime dt) {
    final h = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusFg, statusBg) = switch (booking.status) {
      BookingStatus.upcoming => ('Upcoming', const Color(0xFF1E5BD9), const Color(0xFFE8F0FF)),
      BookingStatus.completed => ('Completed', const Color(0xFF1F7A3D), const Color(0xFFE7F8EF)),
      BookingStatus.cancelled => ('Cancelled', const Color(0xFFB42323), const Color(0xFFFCE8E8)),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Your Booking',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusFg,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _DetailRow(
            icon: Icons.calendar_today_outlined,
            text: _formatDate(booking.scheduledFor),
          ),
          const SizedBox(height: 10),
          _DetailRow(
            icon: Icons.access_time,
            text: _formatTime(booking.scheduledFor),
          ),
          if (booking.notes != null && booking.notes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _DetailRow(
              icon: Icons.notes_outlined,
              text: booking.notes!,
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

/* --------------------------- Booking sheet --------------------------- */

class _BookingSheet extends StatefulWidget {
  const _BookingSheet({required this.provider});

  final ProviderModel provider;

  @override
  State<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<_BookingSheet> {
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 10, minute: 0);
  final _notesController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _confirm() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final scheduledFor = DateTime(
        _date.year, _date.month, _date.day,
        _time.hour, _time.minute,
      );
      debugPrint('[Booking] Attempting to create booking...');
      debugPrint('[Booking] provider_id: ${widget.provider.id}');
      debugPrint('[Booking] scheduled_for: $scheduledFor');
      debugPrint('[Booking] notes: "${_notesController.text}"');

      await SupabaseService.instance.createBooking(
        providerId: widget.provider.id,
        scheduledFor: scheduledFor,
        notes: _notesController.text,
      );

      debugPrint('[Booking] ✅ Booking created successfully');
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('[Booking] ❌ Error creating booking: $e');
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _formatDate(DateTime dt) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${days[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF6F8FB),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Book ${widget.provider.name}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              widget.provider.serviceType,
              style: TextStyle(
                color: primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            _PickerTile(
              icon: Icons.calendar_today_outlined,
              label: 'Date',
              value: _formatDate(_date),
              onTap: _submitting ? null : _pickDate,
            ),
            const SizedBox(height: 10),
            _PickerTile(
              icon: Icons.access_time,
              label: 'Time',
              value: _time.format(context),
              onTap: _submitting ? null : _pickTime,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _notesController,
              maxLines: 3,
              enabled: !_submitting,
              decoration: InputDecoration(
                hintText: 'Notes for the provider (optional)',
                hintStyle: const TextStyle(color: Colors.black38),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: primary, width: 1.2),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCE8E8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Color(0xFFB42323),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: Color(0xFFB42323),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: _submitting ? null : _confirm,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Confirm Booking',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
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

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.black45,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}

/* --------------------------- Shared --------------------------- */

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: const [
      BoxShadow(
        color: Color(0x0A000000),
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ],
  );
}
