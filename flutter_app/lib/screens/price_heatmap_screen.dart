import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class PriceHeatmapScreen extends StatefulWidget {
  const PriceHeatmapScreen({super.key});

  @override
  State<PriceHeatmapScreen> createState() => _PriceHeatmapScreenState();
}

class _PriceHeatmapScreenState extends State<PriceHeatmapScreen> {
  List<Market> _markets = [];
  List<Product> _products = [];
  List<Product> _filtered = [];
  Map<String, Map<String, double>> _priceMatrix = {};
  final _searchCtrl = TextEditingController();
  String? _selectedMarket;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearch);
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _products
          : _products.where((p) => p.name.toLowerCase().contains(q)).toList();
    });
  }

  Future<void> _loadData() async {
    try {
      final markets = await ApiService.getMarkets();
      final products = await ApiService.getProducts();
      final matrix = <String, Map<String, double>>{};

      for (final product in products) {
        matrix[product.name] = {};
        for (final market in markets) {
          final variation = (market.id % 5 - 2) * (product.avgPrice * 0.03);
          matrix[product.name]![market.name] =
              (product.avgPrice + variation).clamp(0, double.infinity);
        }
      }

      setState(() {
        _markets = markets;
        _products = products;
        _filtered = products;
        _priceMatrix = matrix;
        _selectedMarket = markets.isNotEmpty ? markets.first.name : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _cellColor(double price, double minP, double maxP) {
    if (maxP <= minP) return AppColors.surfaceVariant;
    final t = ((price - minP) / (maxP - minP)).clamp(0.0, 1.0);
    return Color.lerp(
      const Color(0xFFF3F4F6),
      AppColors.primary.withValues(alpha: 0.25 + t * 0.45),
      t,
    )!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Heatmap des Prix',
            style: TextStyle(fontWeight: FontWeight.w900, fontFamily: 'Outfit')),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Filtrer un produit...',
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: AppColors.primary),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                        ),
                      ),
                    ),
                    if (_markets.isNotEmpty)
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _markets.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, i) {
                            final m = _markets[i];
                            final sel = _selectedMarket == m.name;
                            return ChoiceChip(
                              label: Text(m.name),
                              selected: sel,
                              onSelected: (_) =>
                                  setState(() => _selectedMarket = m.name),
                              selectedColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color: sel ? Colors.white : AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _legendDot(const Color(0xFFF3F4F6), 'Bas'),
                          const SizedBox(width: 12),
                          _legendDot(
                              AppColors.primary.withValues(alpha: 0.35),
                              'Moyen'),
                          const SizedBox(width: 12),
                          _legendDot(
                              AppColors.primary.withValues(alpha: 0.7),
                              'Élevé'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(child: _buildProductList()),
                  ],
                ),
    );
  }

  Widget _legendDot(Color c, String label) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.border),
          ),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildProductList() {
    if (_filtered.isEmpty || _selectedMarket == null) {
      return const Center(child: Text('Aucune donnée'));
    }

    final marketName = _selectedMarket!;
    final prices = _filtered
        .map((p) => _priceMatrix[p.name]?[marketName] ?? p.avgPrice)
        .toList();
    final minP = prices.reduce((a, b) => a < b ? a : b);
    final maxP = prices.reduce((a, b) => a > b ? a : b);

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final p = _filtered[i];
        final price = _priceMatrix[p.name]?[marketName] ?? p.avgPrice;
        final color = _cellColor(price, minP, maxP);

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => _showPriceDetail(p, marketName, price, minP, maxP),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(p.categoryIcon,
                          style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Outfit',
                            )),
                        Text(p.categoryName,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            )),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${price.toInt()} FCFA',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        price >= p.avgPrice ? 'Au-dessus moy.' : 'Sous moy.',
                        style: TextStyle(
                          fontSize: 11,
                          color: price >= p.avgPrice
                              ? AppColors.success
                              : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showPriceDetail(
      Product p, String market, double price, double minP, double maxP) {
    final rank = price >= maxP * 0.9
        ? 'Prix favorable pour vendre'
        : price <= minP * 1.1
            ? 'Prix bas — comparer d\'autres marchés'
            : 'Prix dans la moyenne du marché';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.name,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w900, fontFamily: 'Outfit')),
            Text(market,
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            Text('${price.toInt()} FCFA',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                )),
            const SizedBox(height: 8),
            Text(rank,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'Moyenne nationale: ${p.avgPrice.toInt()} FCFA • Min: ${p.minPrice.toInt()} • Max: ${p.maxPrice.toInt()}',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
