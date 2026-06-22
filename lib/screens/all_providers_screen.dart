import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/category_model.dart';
import '../models/provider_model.dart';
import '../services/favorites_service.dart';
import '../services/location_service.dart';
import '../services/supabase_service.dart';
import '../utils/service_visuals.dart';
import 'provider_detail_screen.dart';

class _AllProvidersData {
  const _AllProvidersData({
    required this.providers,
    required this.categories,
  });

  final List<ProviderModel> providers;
  final List<CategoryModel> categories;
}

class AllProvidersScreen extends StatefulWidget {
  const AllProvidersScreen({
    this.initialCategorySlug = 'all',
    super.key,
  });

  final String initialCategorySlug;

  @override
  State<AllProvidersScreen> createState() => _AllProvidersScreenState();
}

class _AllProvidersScreenState extends State<AllProvidersScreen> {
  late Future<_AllProvidersData> _future;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  late String _selectedCategorySlug;

  @override
  void initState() {
    super.initState();
    _selectedCategorySlug = widget.initialCategorySlug;
    _future = _load();
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

  Future<_AllProvidersData> _load() async {
    final results = await Future.wait([
      LocationService.instance.getCurrentLocation(),
      SupabaseService.instance.fetchProviders(),
      SupabaseService.instance.fetchCategories(),
    ]);
    final pos = results[0] as Position?;
    final providers = results[1] as List<ProviderModel>;
    final categories = results[2] as List<CategoryModel>;

    final withDistance = providers.map((p) {
      if (pos == null || p.latitude == null || p.longitude == null) return p;
      final meters = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        p.latitude!,
        p.longitude!,
      );
      return p.copyWithDistance(meters / 1000);
    }).toList()
      ..sort((a, b) {
        final da = a.distance ?? double.infinity;
        final db = b.distance ?? double.infinity;
        if (da != db) return da.compareTo(db);
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    return _AllProvidersData(providers: withDistance, categories: categories);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
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

  void _openDetail(ProviderModel p) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProviderDetailScreen(provider: p)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Providers'),
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
      body: FutureBuilder<_AllProvidersData>(
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
          final data = snapshot.data ?? const _AllProvidersData(
            providers: [],
            categories: [],
          );
          final filtered = _filter(data.providers);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: _SearchField(controller: _searchController),
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
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                if (filtered.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyView(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => _ProviderRow(
                        provider: filtered[i],
                        onTap: () => _openDetail(filtered[i]),
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

class _ProviderRow extends StatelessWidget {
  const _ProviderRow({required this.provider, required this.onTap});

  final ProviderModel provider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final distance = provider.distance;
    final secondary = distance != null
        ? '${provider.serviceType}  •  ${distance.toStringAsFixed(1)} km away'
        : provider.serviceType;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
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
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tintForService(provider.serviceType),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                iconForService(provider.serviceType),
                color: primary,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    secondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (provider.address?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: Colors.black45,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            provider.address!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            _FavoriteToggle(providerId: provider.id),
          ],
        ),
      ),
    );
  }
}

class _FavoriteToggle extends StatelessWidget {
  const _FavoriteToggle({required this.providerId});

  final String providerId;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: FavoritesService.instance.ids,
      builder: (context, ids, _) {
        final isFav = ids.contains(providerId);
        return IconButton(
          tooltip: isFav ? 'Remove from favorites' : 'Add to favorites',
          onPressed: () => FavoritesService.instance.toggle(providerId),
          icon: Icon(
            isFav ? Icons.favorite : Icons.favorite_border,
            color: isFav ? Colors.redAccent : Colors.black45,
            size: 20,
          ),
        );
      },
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
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'No providers match your filters.\nTry a different category or search.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
      ),
    );
  }
}
