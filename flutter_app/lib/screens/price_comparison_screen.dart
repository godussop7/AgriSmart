import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/export_service.dart';
import '../utils/constants.dart';
import 'map_screen.dart';

/// Écran de comparaison des prix pour agriculteurs
/// Permet de trouver où vendre son produit au meilleur prix
class PriceComparisonScreen extends StatefulWidget {
  final Product product;
  const PriceComparisonScreen({super.key, required this.product});

  @override
  State<PriceComparisonScreen> createState() => _PriceComparisonScreenState();
}

class _PriceComparisonScreenState extends State<PriceComparisonScreen>
    with SingleTickerProviderStateMixin {
  List<Market> _markets = [];
  List<MarketPrice> _marketPrices = [];
  List<Market> _selectedMarkets = [];
  bool _isLoading = true;
  bool _isLoadingPrices = false;
  String? _error;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadMarkets();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadMarkets() async {
    try {
      final markets = await ApiService.getMarkets();
      setState(() {
        _markets = markets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur de chargement des marchés';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadComparisonData() async {
    if (_selectedMarkets.isEmpty) return;

    setState(() => _isLoadingPrices = true);

    try {
      final prices = await ApiService.comparePrices(
        widget.product.id,
        _selectedMarkets.map((m) => m.id).toList(),
      );
      setState(() {
        _marketPrices = prices.map((p) => MarketPrice.fromJson(p)).toList();
        _isLoadingPrices = false;
      });
      _animationController.forward(from: 0);
    } catch (e) {
      setState(() {
        _isLoadingPrices = false;
      });
      debugPrint('Erreur chargement comparaison: $e');
    }
  }

  void _toggleMarket(Market market) {
    setState(() {
      if (_selectedMarkets.any((m) => m.id == market.id)) {
        _selectedMarkets.removeWhere((m) => m.id == market.id);
        _marketPrices.removeWhere((p) => p.marketId == market.id);
      } else if (_selectedMarkets.length < 3) {
        _selectedMarkets.add(market);
      } else {
        _showMaxMarketsSnackBar();
        return;
      }
    });
    if (_selectedMarkets.isNotEmpty) {
      _loadComparisonData();
    } else {
      setState(() => _marketPrices = []);
    }
  }

  void _showMaxMarketsSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white),
            SizedBox(width: 12),
            Text('Maximum 3 marchés pour une comparaison claire'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  /// Pour un agriculteur: on cherche le PRIX LE PLUS HAUT (meilleur revenu)
  MarketPrice? _getBestMarketToSell() {
    if (_marketPrices.isEmpty) return null;
    // Filtrer les prix nulls
    final validPrices = _marketPrices.where((p) => p.price > 0).toList();
    if (validPrices.isEmpty) return null;
    // Retourne le prix le PLUS HAUX (meilleur pour vendre)
    return validPrices.reduce((a, b) => a.price > b.price ? a : b);
  }

  /// Calcul du potentiel de gain
  double _getProfitPotential() {
    if (_marketPrices.length < 2) return 0;
    final validPrices =
        _marketPrices.where((p) => p.price > 0).map((p) => p.price).toList();
    if (validPrices.length < 2) return 0;
    final max = validPrices.reduce((a, b) => a > b ? a : b);
    final min = validPrices.reduce((a, b) => a < b ? a : b);
    return ((max - min) / min) * 100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : CustomScrollView(
                  slivers: [
                    // Header moderne avec dégradé
                    _buildSliverHeader(),

                    // Sélecteur de marchés
                    SliverToBoxAdapter(
                      child: _buildMarketSelector(),
                    ),

                    // Résultats de comparaison
                    SliverPadding(
                      padding: const EdgeInsets.all(20),
                      sliver: _isLoadingPrices
                          ? const SliverToBoxAdapter(
                              child: Center(
                                child: Padding(
                                  padding: EdgeInsets.all(40),
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            )
                          : _marketPrices.isEmpty
                              ? _buildEmptyState()
                              : SliverList(
                                  delegate: SliverChildListDelegate([
                                    _buildBestMarketCard(),
                                    const SizedBox(height: 20),
                                    _buildPriceComparisonBars(),
                                    const SizedBox(height: 20),
                                    _buildTrendChart(),
                                    const SizedBox(height: 20),
                                    _buildActionButtons(),
                                    const SizedBox(height: 40),
                                  ]),
                                ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 80,
            color: AppColors.error.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadMarkets,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.primary,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF065F46),
                Color(0xFF10B981),
                Color(0xFF34D399),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Cercles décoratifs
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -50,
                left: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              // Contenu
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.trending_up_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.product.name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    fontFamily: 'Outfit',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Trouvez le meilleur marché pour vendre',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.storefront_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_markets.length} marchés disponibles',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarketSelector() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sélectionnez les marchés',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Outfit',
                ),
              ),
              if (_selectedMarkets.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedMarkets.clear();
                      _marketPrices.clear();
                    });
                  },
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Réinitialiser'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Comparez jusqu\'à 3 marchés pour trouver le meilleur prix de vente',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _markets.map((market) {
              final isSelected = _selectedMarkets.any((m) => m.id == market.id);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: FilterChip(
                  selected: isSelected,
                  onSelected: (_) => _toggleMarket(market),
                  label: Text(market.name),
                  avatar: isSelected
                      ? const Icon(Icons.check_circle, size: 18)
                      : const Icon(Icons.store_outlined, size: 18),
                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  checkmarkColor: AppColors.primary,
                  labelStyle: TextStyle(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color:
                        isSelected ? AppColors.primary : AppColors.textPrimary,
                  ),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(40),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.compare_arrows_rounded,
                size: 60,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sélectionnez des marchés',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                fontFamily: 'Outfit',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choisissez au moins 2 marchés pour\ncomparer les prix de vente',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBestMarketCard() {
    final best = _getBestMarketToSell();
    final profit = _getProfitPotential();

    if (best == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF065F46),
            Color(0xFF10B981),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'MEILLEUR MARCHÉ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            best.marketName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${best.price.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontFamily: 'Outfit',
                ),
              ),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(
                  'FCFA',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (profit > 0)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.monetization_on_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '+${profit.toStringAsFixed(1)}% vs marché le moins cher',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
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

  Widget _buildPriceComparisonBars() {
    if (_marketPrices.isEmpty) return const SizedBox.shrink();

    // Filtrer les prix valides (> 0)
    final validPrices = _marketPrices.where((p) => p.price > 0).toList();

    // Vérifier qu'il y a des prix valides
    if (validPrices.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: Text(
            'Aucun prix valide disponible pour ces marchés',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final maxPrice =
        validPrices.map((p) => p.price).reduce((a, b) => a > b ? a : b);
    final minPrice =
        validPrices.map((p) => p.price).reduce((a, b) => a < b ? a : b);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bar_chart_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Comparaison des prix',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Outfit',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._marketPrices.asMap().entries.map((entry) {
            final index = entry.key;
            final mp = entry.value;
            final percentage = mp.price / maxPrice;
            final isHighest = mp.price == maxPrice;
            final isLowest = mp.price == minPrice;

            return AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                final delayedAnimation = CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    index * 0.1,
                    0.5 + index * 0.1,
                    curve: Curves.easeOut,
                  ),
                );

                return FadeTransition(
                  opacity: delayedAnimation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(delayedAnimation),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: isHighest
                                          ? AppColors.primary
                                          : isLowest
                                              ? AppColors.warning
                                              : AppColors.secondary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    mp.marketName,
                                    style: TextStyle(
                                      fontWeight: isHighest
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      fontSize: 15,
                                      color: isHighest
                                          ? AppColors.primary
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  if (isHighest) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'MEILLEUR',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                '${mp.price.toStringAsFixed(0)} FCFA',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: isHighest
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: percentage * delayedAnimation.value,
                              backgroundColor: AppColors.surfaceVariant,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isHighest
                                    ? AppColors.primary
                                    : isLowest
                                        ? AppColors.warning
                                            .withValues(alpha: 0.7)
                                        : AppColors.secondary
                                            .withValues(alpha: 0.7),
                              ),
                              minHeight: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTrendChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Évolution sur 7 jours',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textTertiary,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: _marketPrices.asMap().entries.map((entry) {
                  final index = entry.key;
                  final mp = entry.value;
                  final colors = [
                    AppColors.primary,
                    AppColors.secondary,
                    AppColors.success
                  ];

                  return LineChartBarData(
                    spots: mp.priceHistory.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value);
                    }).toList(),
                    isCurved: true,
                    color: colors[index % colors.length],
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color:
                          colors[index % colors.length].withValues(alpha: 0.1),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Legend
          Wrap(
            spacing: 16,
            children: _marketPrices.asMap().entries.map((entry) {
              final index = entry.key;
              final mp = entry.value;
              final colors = [
                AppColors.primary,
                AppColors.secondary,
                AppColors.success
              ];

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors[index % colors.length],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    mp.marketName,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final best = _getBestMarketToSell();

    return Container(
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          if (best != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MapScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.directions_rounded),
                label: const Text(
                  'VOIR SUR LA CARTE',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: AppColors.success.withValues(alpha: 0.4),
                ),
              ),
            ),
          // Boutons de partage et export
          Row(
            children: [
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      final marketData = _marketPrices
                          .map((p) => {
                                'market_name': p.marketName,
                                'price': p.price,
                              })
                          .toList();

                      await ExportService.shareViaWhatsApp(
                        productName: widget.product.name,
                        marketPrices: marketData,
                      );
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erreur partage: $e')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text(
                    'WHATSAPP',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.success,
                    side: BorderSide(color: AppColors.success, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      final marketData = _marketPrices
                          .map((p) => {
                                'market_name': p.marketName,
                                'price': p.price,
                              })
                          .toList();

                      await ExportService.exportComparison(
                        productName: widget.product.name,
                        marketPrices: marketData,
                      );
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erreur export: $e')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                  label: const Text('PDF'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MarketPrice {
  final int marketId;
  final String marketName;
  final double price;
  final List<double> priceHistory;

  MarketPrice({
    required this.marketId,
    required this.marketName,
    required this.price,
    required this.priceHistory,
  });

  factory MarketPrice.fromJson(Map<String, dynamic> json) {
    // Gérer le cas où current_price est null ou 'None'
    double parsedPrice = 0.0;
    if (json['current_price'] != null && json['current_price'] != 'None') {
      try {
        parsedPrice = double.parse(json['current_price'].toString());
      } catch (_) {
        parsedPrice = 0.0;
      }
    }

    return MarketPrice(
      marketId: json['market_id'] ?? 0,
      marketName: json['market_name'] ?? 'Inconnu',
      price: parsedPrice,
      priceHistory: (json['price_history'] as List? ?? []).map((e) {
        try {
          return double.parse(e.toString());
        } catch (_) {
          return 0.0;
        }
      }).toList(),
    );
  }
}
