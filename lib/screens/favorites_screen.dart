import 'package:flutter/material.dart';

import '../models/provider_model.dart';
import '../services/favorites_service.dart';
import '../widgets/provider_card.dart';
import 'provider_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Future<List<ProviderModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = FavoritesService.instance.fetchFavorites();
  }

  Future<void> _refresh() async {
    final next = FavoritesService.instance.fetchFavorites();
    setState(() {
      _future = next;
    });
    await next;
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
        title: const Text('Favorites'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: FutureBuilder<List<ProviderModel>>(
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
          final favorites = snapshot.data ?? const <ProviderModel>[];
          return RefreshIndicator(
            onRefresh: _refresh,
            child: favorites.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 120),
                      Icon(
                        Icons.favorite_border,
                        size: 56,
                        color: Colors.black26,
                      ),
                      SizedBox(height: 12),
                      Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'No favorites yet.\nTap the heart on a provider to save them here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                      ),
                    ],
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    physics: const AlwaysScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: favorites.length,
                    itemBuilder: (context, i) => ProviderCard(
                      provider: favorites[i],
                      onTap: () => _openDetail(favorites[i]),
                    ),
                  ),
          );
        },
      ),
    );
  }
}
