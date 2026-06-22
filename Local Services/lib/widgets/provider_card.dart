import 'package:flutter/material.dart';

import '../models/provider_model.dart';
import '../services/favorites_service.dart';
import '../utils/service_visuals.dart';

class ProviderCard extends StatelessWidget {
  const ProviderCard({
    required this.provider,
    required this.onTap,
    this.showFavorite = true,
    super.key,
  });

  final ProviderModel provider;
  final VoidCallback onTap;
  final bool showFavorite;

  @override
  Widget build(BuildContext context) {
    final serviceIconColor = iconColorForService(provider.serviceType);
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.5,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: tintForService(provider.serviceType),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Icon(
                          iconForService(provider.serviceType),
                          color: serviceIconColor,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                  if (showFavorite)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: _FavoriteHeart(providerId: provider.id),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              provider.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              provider.serviceType,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: serviceIconColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
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
                    provider.distance == null
                        ? provider.phone
                        : '${provider.distance!.toStringAsFixed(1)} km away',
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
        ),
      ),
    );
  }
}

class _FavoriteHeart extends StatelessWidget {
  const _FavoriteHeart({required this.providerId});

  final String providerId;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: FavoritesService.instance.ids,
      builder: (context, ids, _) {
        final isFav = ids.contains(providerId);
        return GestureDetector(
          onTap: () => FavoritesService.instance.toggle(providerId),
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Color(0x14000000), blurRadius: 6),
              ],
            ),
            child: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? Colors.redAccent : Colors.black54,
              size: 17,
            ),
          ),
        );
      },
    );
  }
}
