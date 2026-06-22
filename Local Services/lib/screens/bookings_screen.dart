import 'package:flutter/material.dart';

import '../models/booking_model.dart';
import '../services/supabase_service.dart';
import '../widgets/booking_card.dart';
import 'provider_detail_screen.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => BookingsScreenState();
}

class BookingsScreenState extends State<BookingsScreen> {
  late Future<List<BookingModel>> _future;

  @override
  void initState() {
    super.initState();
    debugPrint('[BookingsScreen] initState — fetching bookings');
    _future = _fetch();
  }

  void reload() {
    debugPrint('[BookingsScreen] reload() called');
    setState(() { _future = _fetch(); });
  }

  Future<void> _refresh() async {
    debugPrint('[BookingsScreen] pull-to-refresh triggered');
    setState(() { _future = _fetch(); });
    await _future;
  }

  Future<List<BookingModel>> _fetch() async {
    debugPrint('[BookingsScreen] fetching from Supabase...');
    try {
      final results = await SupabaseService.instance.fetchBookings();
      debugPrint('[BookingsScreen] ✅ got ${results.length} booking(s)');
      for (final b in results) {
        debugPrint('[BookingsScreen]   → id=${b.id} provider=${b.provider?.name} status=${b.status}');
      }
      return results;
    } catch (e) {
      debugPrint('[BookingsScreen] ❌ fetch error: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.black87,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      body: FutureBuilder<List<BookingModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 80),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ),
                ),
              ],
            );
          }
          final bookings = snapshot.data ?? [];
          return RefreshIndicator(
            onRefresh: _refresh,
            child: bookings.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 80),
                      _EmptyBookings(),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: bookings.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final b = bookings[i];
                      final p = b.provider;
                      return BookingCard(
                        providerName: p?.name ?? 'Provider unavailable',
                        serviceType: p?.serviceType ?? '—',
                        scheduledFor: b.scheduledFor,
                        status: b.status,
                        onTap: p == null
                            ? null
                            : () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ProviderDetailScreen(
                                      provider: p,
                                      booking: b,
                                    ),
                                  ),
                                ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}

class _EmptyBookings extends StatelessWidget {
  const _EmptyBookings();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0FF),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.calendar_month_outlined,
                size: 40,
                color: primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No bookings yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Book a service provider and your appointments will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
