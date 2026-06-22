import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/booking_model.dart';
import '../services/profile_service.dart';
import '../services/supabase_service.dart';
import '../widgets/booking_card.dart';

class ProviderBookingsScreen extends StatefulWidget {
  const ProviderBookingsScreen({super.key});

  @override
  State<ProviderBookingsScreen> createState() => _ProviderBookingsScreenState();
}

class _ProviderBookingsScreenState extends State<ProviderBookingsScreen> {
  late Future<List<BookingModel>> _future;
  RealtimeChannel? _channel;
  String? _providerId;
  String _serviceType = '';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<BookingModel>> _load() async {
    if (_providerId == null) {
      final provider = await ProfileService.instance.fetchMyProvider();
      if (provider == null) return [];
      _providerId = provider.id;
      _serviceType = provider.serviceType;
      _subscribeRealtime(provider.id);
    }
    return SupabaseService.instance.fetchProviderBookings(_providerId!);
  }

  void _subscribeRealtime(String providerId) {
    if (_channel != null) return;
    _channel = Supabase.instance.client
        .channel('provider_bookings_$providerId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bookings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'provider_id',
            value: providerId,
          ),
          callback: (_) {
            if (mounted) {
              setState(() {
                _future =
                    SupabaseService.instance.fetchProviderBookings(providerId);
              });
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    if (_channel != null) {
      Supabase.instance.client.removeChannel(_channel!);
    }
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incoming Bookings'),
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
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
                      _EmptyIncoming(),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: bookings.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final b = bookings[i];
                      return BookingCard(
                        providerName: b.customerName ?? 'Customer',
                        serviceType: _serviceType,
                        scheduledFor: b.scheduledFor,
                        status: b.status,
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}

class _EmptyIncoming extends StatelessWidget {
  const _EmptyIncoming();

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
              child: Icon(Icons.inbox_outlined, size: 40, color: primary),
            ),
            const SizedBox(height: 20),
            const Text(
              'No bookings yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              "When customers book your services, they'll appear here instantly.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
