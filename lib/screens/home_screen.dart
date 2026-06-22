import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/category_model.dart';
import '../models/provider_model.dart';
import '../services/favorites_service.dart';
import '../services/location_service.dart';
import '../services/supabase_service.dart';
import '../widgets/provider_card.dart';
import 'all_providers_screen.dart';
import 'bookings_screen.dart';
import 'favorites_screen.dart';
import 'map_screen.dart';
import 'profile_screen.dart';
import 'provider_detail_screen.dart';

const double _kNearRadiusKm = 5;
const double _kWideRadiusKm = 20;

enum _RadiusBand { near, wide, all, none }

enum _SortOption { nearest, mostSaved, newest }

class _HomeData {
  const _HomeData({
    required this.providers,
    required this.locationAvailable,
    required this.categories,
  });

  // All providers with distance pre-computed when location is available.
  // Filtering by radius happens at render time so search/category filters
  // can interact with the fallback (5km → 20km → all).
  final List<ProviderModel> providers;
  final bool locationAvailable;
  final List<CategoryModel> categories;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<_HomeData> _dataFuture;
  final TextEditingController _searchController = TextEditingController();
  final _bookingsKey = GlobalKey<BookingsScreenState>();
  String _query = '';
  String _selectedCategorySlug = 'all';
  _SortOption _sortOption = _SortOption.nearest;
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    _dataFuture = _load();
    FavoritesService.instance.loadIds();
    _searchController.addListener(() {
      final next = _searchController.text.trim().toLowerCase();
      if (next != _query) setState(() => _query = next);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<_HomeData> _load() async {
    final results = await Future.wait([
      LocationService.instance.getCurrentLocation(),
      SupabaseService.instance.fetchProviders(),
      SupabaseService.instance.fetchCategories(),
    ]);
    final position = results[0] as Position?;
    final providers = results[1] as List<ProviderModel>;
    final categories = results[2] as List<CategoryModel>;

    debugPrint(
      '[Home] location=${position == null ? 'unavailable' : '${position.latitude},${position.longitude}'} '
      'providers=${providers.length} categories=${categories.length}',
    );

    if (position == null) {
      return _HomeData(
        providers: providers,
        locationAvailable: false,
        categories: categories,
      );
    }

    final withDistance = <ProviderModel>[];
    for (final p in providers) {
      if (p.latitude == null || p.longitude == null) {
        debugPrint('[Home] skip "${p.name}" — missing coordinates');
        withDistance.add(p);
        continue;
      }
      final meters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        p.latitude!,
        p.longitude!,
      );
      final km = meters / 1000;
      debugPrint('[Home] "${p.name}" → ${km.toStringAsFixed(2)} km');
      withDistance.add(p.copyWithDistance(km));
    }

    withDistance.sort((a, b) {
      final da = a.distance ?? double.infinity;
      final db = b.distance ?? double.infinity;
      return da.compareTo(db);
    });

    return _HomeData(
      providers: withDistance,
      locationAvailable: true,
      categories: categories,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _dataFuture = _load();
    });
    await _dataFuture;
  }

  List<ProviderModel> _filter(List<ProviderModel> all) {
    return all.where((p) {
      if (_selectedCategorySlug != 'all' &&
          p.serviceType.toLowerCase() != _selectedCategorySlug.toLowerCase()) {
        return false;
      }
      if (_query.isEmpty) return true;
      return p.name.toLowerCase().contains(_query) ||
          p.serviceType.toLowerCase().contains(_query);
    }).toList();
  }

  // Try 5 km, then 20 km, then everything. Returns the visible list and the
  // band that produced it so the UI can show a hint when we expanded.
  (List<ProviderModel>, _RadiusBand) _applyRadiusFallback(
    List<ProviderModel> filtered,
    bool locationAvailable,
  ) {
    if (filtered.isEmpty) return (const [], _RadiusBand.none);
    if (!locationAvailable) return (filtered, _RadiusBand.all);

    final near = filtered
        .where((p) => p.distance != null && p.distance! <= _kNearRadiusKm)
        .toList();
    if (near.isNotEmpty) return (near, _RadiusBand.near);

    final wide = filtered
        .where((p) => p.distance != null && p.distance! <= _kWideRadiusKm)
        .toList();
    if (wide.isNotEmpty) return (wide, _RadiusBand.wide);

    return (filtered, _RadiusBand.all);
  }

  List<ProviderModel> _sort(List<ProviderModel> list) {
    final copy = [...list];
    switch (_sortOption) {
      case _SortOption.nearest:
        copy.sort((a, b) {
          final da = a.distance ?? double.infinity;
          final db = b.distance ?? double.infinity;
          return da.compareTo(db);
        });
      case _SortOption.mostSaved:
        copy.sort((a, b) => b.savesCount.compareTo(a.savesCount));
      case _SortOption.newest:
        copy.sort((a, b) {
          final ta = a.createdAt ?? DateTime(2000);
          final tb = b.createdAt ?? DateTime(2000);
          return tb.compareTo(ta);
        });
    }
    return copy;
  }

  void _openDetail(ProviderModel p) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProviderDetailScreen(provider: p)),
    );
  }

  Future<void> _enableLocation() async {
    await Geolocator.openAppSettings();
    await _refresh();
  }

  void _openFavorites() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FavoritesScreen()),
    );
  }

  void _openAllProviders(String initialCategorySlug) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AllProvidersScreen(
          initialCategorySlug: initialCategorySlug,
        ),
      ),
    );
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You can sign back in any time.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await Supabase.instance.client.auth.signOut();
    FavoritesService.instance.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _navIndex,
        children: [
          _buildHomeTab(),
          BookingsScreen(key: _bookingsKey),
          const MapScreen(),
          ProfileScreen(
            onGoToFavorites: _openFavorites,
            onGoToBookings: () {
              setState(() => _navIndex = 1);
              _bookingsKey.currentState?.reload();
            },
            onLogout: _confirmSignOut,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) {
          if (i == 1) _bookingsKey.currentState?.reload();
          setState(() => _navIndex = i);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return SafeArea(
      bottom: false,
      child: FutureBuilder<_HomeData>(
        future: _dataFuture,
        builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _ErrorView(
                message: snapshot.error.toString(),
                onRetry: _refresh,
              );
            }
            final data = snapshot.data ?? const _HomeData(
              providers: [],
              locationAvailable: false,
              categories: [],
            );
            final filtered = _filter(data.providers);
            final (rawVisible, band) = _applyRadiusFallback(
              filtered,
              data.locationAvailable,
            );
            final visible = _sort(rawVisible);

            return RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _Header(onOpenFavorites: _openFavorites),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
                      child: _SearchField(controller: _searchController),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _PromoBanner(
                        onTap: () => _openAllProviders('all'),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _SectionHeader(
                      title: 'Categories',
                      onSeeAll: () => _openAllProviders('all'),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _CategoryChips(
                      categories: data.categories,
                      selectedSlug: _selectedCategorySlug,
                      onSelected: (slug) =>
                          setState(() => _selectedCategorySlug = slug),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _SectionHeader(
                      title: 'Near You',
                      onSeeAll: () =>
                          _openAllProviders(_selectedCategorySlug),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _SortBar(
                      selected: _sortOption,
                      locationAvailable: data.locationAvailable,
                      onSelected: (opt) =>
                          setState(() => _sortOption = opt),
                    ),
                  ),
                  if (!data.locationAvailable)
                    SliverToBoxAdapter(
                      child: _LocationDeniedView(onEnable: _enableLocation),
                    ),
                  if (data.locationAvailable && band != _RadiusBand.near &&
                      visible.isNotEmpty)
                    SliverToBoxAdapter(child: _RadiusHint(band: band)),
                  if (visible.isEmpty)
                    const SliverToBoxAdapter(child: _EmptyView())
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.78,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => ProviderCard(
                            provider: visible[i],
                            onTap: () => _openDetail(visible[i]),
                          ),
                          childCount: visible.length,
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

class _Header extends StatelessWidget {
  const _Header({required this.onOpenFavorites});

  final VoidCallback onOpenFavorites;

  static String? _firstName(String? email) {
    if (email == null || email.isEmpty) return null;
    final local = email.split('@').first;
    final first = local.split(RegExp(r'[._+\-]')).first;
    if (first.isEmpty) return null;
    return first[0].toUpperCase() + first.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final email = Supabase.instance.client.auth.currentUser?.email;
    final firstName = _firstName(email);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2F6BFF), Color(0xFF1240C7)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x402F6BFF),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  firstName != null ? 'Hello, $firstName' : 'Hello there',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Find a Service',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          ValueListenableBuilder<Set<String>>(
            valueListenable: FavoritesService.instance.ids,
            builder: (context, ids, _) {
              final hasFavs = ids.isNotEmpty;
              return GestureDetector(
                onTap: onOpenFavorites,
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    hasFavs ? Icons.favorite : Icons.favorite_border,
                    color: hasFavs ? Colors.redAccent : Colors.black87,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Search service or provider',
        hintStyle: const TextStyle(color: Colors.black45),
        prefixIcon: const Icon(Icons.search, color: Colors.black45),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.2,
          ),
        ),
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2F6BFF), Color(0xFF1240C7)],
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -24,
              right: 48,
              child: Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  color: Color(0x12FFFFFF),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -32,
              right: -12,
              child: Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  color: Color(0x0DFFFFFF),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Special Offer',
                        style: TextStyle(
                          color: Color(0xCCFFFFFF),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '30% off your\nfirst booking',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Get Now',
                          style: TextStyle(
                            color: Color(0xFF2F6BFF),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.local_offer,
                  size: 84,
                  color: Color(0x55FFFFFF),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    );
  }
}

class _SortBar extends StatelessWidget {
  const _SortBar({
    required this.selected,
    required this.locationAvailable,
    required this.onSelected,
  });

  final _SortOption selected;
  final bool locationAvailable;
  final ValueChanged<_SortOption> onSelected;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final options = [
      if (locationAvailable)
        (_SortOption.nearest, Icons.near_me_outlined, 'Nearest'),
      (_SortOption.mostSaved, Icons.favorite_outline, 'Most Saved'),
      (_SortOption.newest, Icons.schedule, 'Newest'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Wrap(
        spacing: 8,
        children: options.map((opt) {
          final (value, icon, label) = opt;
          final isSelected = selected == value;
          return GestureDetector(
            onTap: () => onSelected(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? primary : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected ? primary : const Color(0xFFE3E7EE),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0x282F6BFF),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 13,
                    color: isSelected ? Colors.white : Colors.black54,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onSeeAll});

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (onSeeAll != null)
            InkWell(
              onTap: onSeeAll,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 4,
                ),
                child: Text(
                  'See all',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selectedSlug,
    required this.onSelected,
  });

  final List<CategoryModel> categories;
  final String selectedSlug;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final items = <({String slug, String label})>[
      (slug: 'all', label: 'All'),
      ...categories.map((c) => (slug: c.slug, label: c.displayName)),
    ];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final item = items[i];
          final isSelected = selectedSlug == item.slug;
          return ChoiceChip(
            label: Text(item.label),
            selected: isSelected,
            onSelected: (_) => onSelected(item.slug),
            showCheckmark: false,
            backgroundColor: Colors.white,
            selectedColor: primary,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
              side: BorderSide(
                color: isSelected ? primary : const Color(0xFFE3E7EE),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          );
        },
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 48, 24, 48),
      child: Center(
        child: Text(
          'No providers match your filters.\nTry a different category or pull down to refresh.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
      ),
    );
  }
}

class _LocationDeniedView extends StatelessWidget {
  const _LocationDeniedView({required this.onEnable});

  final Future<void> Function() onEnable;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Container(
        padding: const EdgeInsets.all(20),
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
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.location_off_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Location is off',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Enable location to see service providers near you.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onEnable,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Enable location'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ),
      ],
    );
  }
}

class _RadiusHint extends StatelessWidget {
  const _RadiusHint({required this.band});

  final _RadiusBand band;

  @override
  Widget build(BuildContext context) {
    final message = switch (band) {
      _RadiusBand.wide => 'No matches within 5 km — showing within 20 km.',
      _RadiusBand.all => 'No matches nearby — showing all providers.',
      _ => '',
    };
    if (message.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5E0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 16, color: Color(0xFFB07A1B)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Color(0xFFB07A1B),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
