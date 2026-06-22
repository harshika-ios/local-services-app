import 'package:flutter/material.dart';

import '../models/provider_model.dart';
import '../services/location_service.dart';
import '../services/profile_service.dart';
import 'provider_edit_profile_screen.dart';

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() =>
      _ProviderDashboardScreenState();
}

class _DashboardData {
  const _DashboardData({required this.provider, required this.stats});
  final ProviderModel provider;
  final ProviderStats stats;
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  late Future<_DashboardData?> _future;
  bool? _activeOverride;
  bool _toggling = false;
  bool _updatingLocation = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DashboardData?> _load() async {
    final p = await ProfileService.instance.fetchMyProvider();
    if (p == null) return null;
    final stats = await ProfileService.instance.fetchProviderStats(p.id);
    return _DashboardData(provider: p, stats: stats);
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() {
      _future = next;
      _activeOverride = null;
    });
    await next;
  }

  Future<void> _toggleActive(ProviderModel p) async {
    final desired = !(_activeOverride ?? p.isActive);
    setState(() {
      _activeOverride = desired;
      _toggling = true;
    });
    try {
      await ProfileService.instance.setProviderActive(p.id, desired);
    } catch (e) {
      if (!mounted) return;
      setState(() => _activeOverride = !desired);
      _snack('Could not update: $e');
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  Future<void> _updateLocation(ProviderModel p) async {
    setState(() => _updatingLocation = true);
    try {
      final pos = await LocationService.instance.getCurrentLocation();
      if (pos == null) {
        _snack('Could not read your location.');
        return;
      }
      await ProfileService.instance.setProviderLocation(
        p.id,
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
      _snack('Location updated.');
      await _refresh();
    } catch (e) {
      _snack('Update failed: $e');
    } finally {
      if (mounted) setState(() => _updatingLocation = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.black87,
        titleTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      body: FutureBuilder<_DashboardData?>(
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
          final data = snapshot.data;
          if (data == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No provider profile found.',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            );
          }
          final p = data.provider;
          final stats = data.stats;
          final active = _activeOverride ?? p.isActive;
          final greeting = _greeting();
          final firstName = p.name.split(' ').first;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                // Greeting (no avatar duplication — that's on Profile)
                Text(
                  '$greeting, $firstName',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  active
                      ? "Here's how your listing is doing."
                      : 'Your listing is paused right now.',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 18),

                _StatsRow(
                  views: stats.views,
                  favorites: stats.favorites,
                  upcomingBookings: stats.upcomingBookings,
                ),
                const SizedBox(height: 20),

                _AvailabilityCard(
                  active: active,
                  busy: _toggling,
                  onChanged: (_) => _toggleActive(p),
                ),
                const SizedBox(height: 20),

                const _SectionLabel('Quick Actions'),
                const SizedBox(height: 8),
                _QuickActionsRow(
                  onEditProfile: () async {
                    final updated = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => const ProviderEditProfileScreen(),
                      ),
                    );
                    if (updated == true) await _refresh();
                  },
                  onUpdateLocation: _updatingLocation
                      ? null
                      : () => _updateLocation(p),
                  onToggleAvailability: _toggling ? null : () => _toggleActive(p),
                  active: active,
                  updatingLocation: _updatingLocation,
                ),
                const SizedBox(height: 20),

                const _SectionLabel('Service Area'),
                const SizedBox(height: 8),
                _ServiceAreaCard(
                  address: p.address,
                  hasCoords: p.latitude != null && p.longitude != null,
                ),
                const SizedBox(height: 20),

                const _SectionLabel('Activity'),
                const SizedBox(height: 8),
                _ActivityCard(
                  active: active,
                  upcomingBookings: stats.upcomingBookings,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

/* --------------------------- Stats --------------------------- */

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.views,
    required this.favorites,
    required this.upcomingBookings,
  });

  final int views;
  final int favorites;
  final int upcomingBookings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.visibility_outlined,
            iconColor: Theme.of(context).colorScheme.primary,
            value: '$views',
            label: 'profile views',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.favorite_outline,
            iconColor: Colors.redAccent,
            value: '$favorites',
            label: 'favorites',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.calendar_month_outlined,
            iconColor: const Color(0xFF1F7A3D),
            value: '$upcomingBookings',
            label: 'upcoming',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/* --------------------------- Availability --------------------------- */

class _AvailabilityCard extends StatelessWidget {
  const _AvailabilityCard({
    required this.active,
    required this.busy,
    required this.onChanged,
  });

  final bool active;
  final bool busy;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? const Color(0xFFE7F8EF) : const Color(0xFFFCE8E8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              active ? Icons.check_circle : Icons.pause_circle,
              color: active ? const Color(0xFF1F7A3D) : const Color(0xFFB42323),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  active ? "You're online" : "You're offline",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  active
                      ? 'You are visible to nearby users.'
                      : 'You are currently hidden from search.',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: active,
            onChanged: busy ? null : onChanged,
          ),
        ],
      ),
    );
  }
}

/* --------------------------- Quick Actions --------------------------- */

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({
    required this.onEditProfile,
    required this.onUpdateLocation,
    required this.onToggleAvailability,
    required this.active,
    required this.updatingLocation,
  });

  final VoidCallback? onEditProfile;
  final VoidCallback? onUpdateLocation;
  final VoidCallback? onToggleAvailability;
  final bool active;
  final bool updatingLocation;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionTile(
            icon: Icons.edit_outlined,
            label: 'Edit\nProfile',
            onTap: onEditProfile,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionTile(
            icon: Icons.my_location,
            label: updatingLocation ? 'Updating…' : 'Update\nLocation',
            onTap: onUpdateLocation,
            busy: updatingLocation,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionTile(
            icon: active ? Icons.pause_circle_outline : Icons.play_circle_outline,
            label: active ? 'Pause\nListing' : 'Resume\nListing',
            onTap: onToggleAvailability,
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.busy = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
        decoration: _cardDecoration(),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(icon, color: primary, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* --------------------------- Service Area --------------------------- */

class _ServiceAreaCard extends StatelessWidget {
  const _ServiceAreaCard({required this.address, required this.hasCoords});

  final String? address;
  final bool hasCoords;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final hasAddress = address != null && address!.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.location_on_outlined, color: primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasAddress
                      ? 'Serving users near $address'
                      : hasCoords
                          ? 'Serving users near your saved location'
                          : 'No service location set',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  "Tap 'Update Location' to refresh your area.",
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* --------------------------- Activity --------------------------- */

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.active,
    required this.upcomingBookings,
  });

  final bool active;
  final int upcomingBookings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _ActivityRow(
            icon: active ? Icons.check_circle : Icons.pause_circle,
            iconColor: active
                ? const Color(0xFF1F7A3D)
                : const Color(0xFFB42323),
            text: active
                ? 'Your profile is active'
                : 'Your profile is paused',
          ),
          const Divider(
            height: 1,
            thickness: 1,
            indent: 56,
            color: Color(0xFFEEF1F5),
          ),
          _ActivityRow(
            icon: Icons.calendar_month_outlined,
            iconColor: Colors.black54,
            text: upcomingBookings == 0
                ? 'No bookings yet'
                : '$upcomingBookings upcoming '
                    '${upcomingBookings == 1 ? "booking" : "bookings"}',
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  final IconData icon;
  final Color iconColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F4F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* --------------------------- Shared --------------------------- */

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

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
