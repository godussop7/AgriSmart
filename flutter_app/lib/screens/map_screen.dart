// lib/screens/map_screen.dart
// Carte interactive des marchés avec Google Maps

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import 'predictions_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with AutomaticKeepAliveClientMixin {
  GoogleMapController? _mapController;
  List<Market> _markets = [];
  List<Region> _regions = [];
  Set<Marker> _markers = {};
  bool _isLoading = true;
  int? _selectedRegionId;
  Market? _selectedMarket;

  static const _senegalCenter = LatLng(14.4974, -14.4524);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getMarkets(regionId: _selectedRegionId),
        ApiService.getRegions(),
      ]);
      _markets = results[0] as List<Market>;
      _regions = results[1] as List<Region>;
      _buildMarkers();
    } catch (_) {
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _filterByRegion(int? regionId) async {
    setState(() {
      _selectedRegionId = regionId;
      _selectedMarket = null;
    });
    final markets = await ApiService.getMarkets(regionId: regionId);
    setState(() {
      _markets = markets;
    });
    _buildMarkers();
    if (regionId != null) {
      final region = _regions.firstWhere((r) => r.id == regionId);
      if (region.latitude != null && region.longitude != null) {
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
              LatLng(region.latitude!, region.longitude!), 10),
        );
      }
    } else {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_senegalCenter, 7),
      );
    }
  }

  void _buildMarkers() {
    final markers = _markets.map((market) {
      final priceLevelColor = market.priceLevel == 'low'
          ? const Color(0xFF22C55E)
          : market.priceLevel == 'high'
              ? const Color(0xFFEF4444)
              : const Color(0xFFF59E0B);

      return Marker(
        markerId: MarkerId(market.id.toString()),
        position: LatLng(market.latitude, market.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          market.priceLevel == 'low'
              ? BitmapDescriptor.hueGreen
              : market.priceLevel == 'high'
                  ? BitmapDescriptor.hueRed
                  : BitmapDescriptor.hueYellow,
        ),
        infoWindow: InfoWindow(
          title: market.name,
          snippet:
              '${market.regionName} · ⭐ ${market.rating.toStringAsFixed(1)}',
        ),
        onTap: () => _selectMarket(market),
      );
    }).toSet();

    setState(() => _markers = markers);
  }

  void _selectMarket(Market market) {
    setState(() => _selectedMarket = market);
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(market.latitude, market.longitude), 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Carte des Marchés'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded),
            onPressed: () {
              _mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(_senegalCenter, 7),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition:
                const CameraPosition(target: _senegalCenter, zoom: 7),
            markers: _markers,
            onMapCreated: (controller) {
              _mapController = controller;
              controller.setMapStyle(_mapStyle);
            },
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
            ),

          // Region filter chips
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Container(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _RegionChip(
                    label: '🗺️ Toutes',
                    selected: _selectedRegionId == null,
                    onTap: () => _filterByRegion(null),
                  ),
                  ..._regions.map((r) => _RegionChip(
                        label: r.name,
                        selected: _selectedRegionId == r.id,
                        onTap: () => _filterByRegion(r.id),
                      )),
                ],
              ),
            ),
          ),

          // Stats badge
          Positioned(
            bottom: _selectedMarket != null ? 220 : 24,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10)
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.store_rounded,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text('${_markets.length} marchés',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFamily: 'Nunito',
                      )),
                ],
              ),
            ),
          ),

          // Market detail card
          if (_selectedMarket != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _MarketDetailCard(
                market: _selectedMarket!,
                onClose: () => setState(() => _selectedMarket = null),
              ),
            ),
        ],
      ),
    );
  }

  // Custom map style (minimal, green tones)
  final String _mapStyle = '''[
    {"featureType": "water", "stylers": [{"color": "#c8e6f5"}]},
    {"featureType": "landscape", "stylers": [{"color": "#f0f4f0"}]},
    {"featureType": "road", "stylers": [{"visibility": "simplified"}]},
    {"featureType": "administrative.country", "elementType": "geometry.stroke",
      "stylers": [{"color": "#1B8A3E"}, {"weight": 1.5}]}
  ]''';
}

class _RegionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RegionChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.08), blurRadius: 6)
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textPrimary,
            fontFamily: 'Nunito',
          ),
        ),
      ),
    );
  }
}

class _MarketDetailCard extends StatelessWidget {
  final Market market;
  final VoidCallback onClose;

  const _MarketDetailCard({required this.market, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 30,
              offset: const Offset(0, -5)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(10))),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(market.name,
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            letterSpacing: -1)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const _RatingStars(rating: 4.5),
                        const SizedBox(width: 8),
                        Text('4.5 (${market.rating.toStringAsFixed(1)})',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              _GlassIconButton(icon: Icons.close_rounded, onTap: onClose),
            ],
          ),
          const SizedBox(height: 24),

          // Trend & Status
          Row(
            children: [
              _StatusBadge(
                  icon: Icons.trending_down_rounded,
                  label: 'Prix en baisse',
                  color: AppColors.primary),
              const SizedBox(width: 12),
              _StatusBadge(
                  icon: Icons.check_circle_rounded,
                  label: 'Ouvert',
                  color: AppColors.success),
            ],
          ),
          const SizedBox(height: 24),

          const Text('À propos du marché',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5)),
          const SizedBox(height: 8),
          Text(
            market.description.isNotEmpty
                ? market.description
                : "Ce marché est l'un des points d'échange majeurs de la région, accueillant des centaines de producteurs locaux chaque jour.",
            style: const TextStyle(
                fontSize: 14, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 24),

          // Info Tiles
          Row(
            children: [
              _InfoTile(
                  label: 'Région',
                  value: market.regionName,
                  icon: Icons.location_on_rounded),
              const SizedBox(width: 12),
              _InfoTile(
                  label: 'Produits',
                  value: '${market.productsCount}',
                  icon: Icons.inventory_2_rounded),
              const SizedBox(width: 12),
              _InfoTile(
                  label: 'Prix Moy.',
                  value: '450F',
                  icon: Icons.payments_rounded),
            ],
          ),
          const SizedBox(height: 32),

          // AI Prediction Button
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.deepPurple.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8)),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => PredictionsScreen())),
              icon: const Icon(Icons.auto_awesome_rounded, size: 22),
              label: const Text('ANALYSE PRÉDICTIVE IA',
                  style:
                      TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 24),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatusBadge(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _InfoTile(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(height: 12),
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _RatingStars extends StatelessWidget {
  final double rating;
  const _RatingStars({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
            index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
            color: Colors.amber,
            size: 16);
      }),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isLast;
  const _InfoRow(
      {required this.label,
      required this.value,
      this.valueColor,
      this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w600)),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: valueColor ?? AppColors.textPrimary,
                  fontFamily: 'Nunito')),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
            fontFamily: 'Nunito',
          )),
    );
  }
}
