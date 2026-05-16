import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/constants.dart';
import '../utils/ui_utils.dart';
import '../services/api_service.dart';
import 'stock_management_screen.dart';
import 'alerts_screen.dart';
import 'price_comparison_screen.dart';
import 'chatbot_screen.dart';
import 'price_heatmap_screen.dart';
import 'agricultural_calendar_screen.dart';

class PredictionDetailScreen extends StatefulWidget {
  final Prediction prediction;
  const PredictionDetailScreen({super.key, required this.prediction});

  @override
  State<PredictionDetailScreen> createState() => _PredictionDetailScreenState();
}

class _PredictionDetailScreenState extends State<PredictionDetailScreen> {
  bool _loadingStock = true;
  dynamic _userStock;

  @override
  void initState() {
    super.initState();
    _loadUserStock();
  }

  Future<void> _loadUserStock() async {
    try {
      final stocks = await ApiService.getStocks();
      if (stocks.isNotEmpty) {
        setState(() {
          _userStock = stocks.firstWhere(
            (s) => s['product'] == widget.prediction.product,
            orElse: () => null,
          );
        });
      }
    } catch (_) {} finally {
      setState(() => _loadingStock = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prediction = widget.prediction;
    final currentTrendColor = AppFormatters.trendColor(prediction.trend);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(prediction, currentTrendColor),
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProductInfoCard(prediction, currentTrendColor),
                  const SizedBox(height: 24),
                  _buildRecommendationCard(prediction),
                  const SizedBox(height: 24),
                  if (prediction.analysis.isNotEmpty) ...[
                    _buildExpertAnalysisCard(prediction),
                    const SizedBox(height: 24),
                  ],
                  _buildSectionHeader('Votre Stock Actuel', Icons.inventory_2_rounded),
                  const SizedBox(height: 16),
                  _buildStockCard(prediction),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Actions Stratégiques', Icons.bolt_rounded),
                  const SizedBox(height: 16),
                  _buildQuickActions(prediction),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(Prediction prediction, Color trendColor) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primaryDark,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('Analyse Détaillée',
            style: TextStyle(
                fontWeight: FontWeight.w900,
                fontFamily: 'Outfit',
                color: Colors.white)),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                trendColor.withValues(alpha: 0.8),
                AppColors.primary,
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                  top: -50,
                  right: -50,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  )),
              Positioned(
                  bottom: -30,
                  left: -30,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  )),
              Center(
                child: Icon(
                    prediction.trend == 'up'
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    size: 100,
                    color: Colors.white.withValues(alpha: 0.2)),
              ),
            ],
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
              icon: const Icon(Icons.share_rounded, color: Colors.white),
              onPressed: () {}),
        ),
      ],
    );
  }

  Widget _buildProductInfoCard(Prediction prediction, Color trendColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(prediction.productName,
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Outfit',
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(prediction.marketName,
                        style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textTertiary,
                            fontWeight: FontWeight.w600))
                  ]),
              _ConfidenceIndicator(level: prediction.confidenceLevel),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _LargePrice(label: 'Actuel', value: prediction.currentPrice),
                Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: trendColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle),
                    child: Icon(
                        prediction.trend == 'up'
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        color: trendColor,
                        size: 32)),
                _LargePrice(
                    label: prediction.horizonDisplay,
                    value: prediction.predictedPrice,
                    color: trendColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(Prediction prediction) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Recommandation IA', Icons.auto_awesome_rounded),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: 0.05),
                Colors.white,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.lightbulb_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(prediction.recommendation,
                    style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textPrimary,
                        height: 1.6,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpertAnalysisCard(Prediction prediction) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Analyse Expert', Icons.analytics_rounded),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(prediction.analysis,
              style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.6,
                  fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  Widget _buildStockCard(Prediction prediction) {
    if (_loadingStock) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final hasStock = _userStock != null;
    final quantity = hasStock ? double.tryParse(_userStock['quantity'].toString()) ?? 0.0 : 0.0;
    final unit = hasStock ? _userStock['unit'] ?? prediction.productUnit : prediction.productUnit;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (hasStock ? AppColors.success : AppColors.textTertiary).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasStock ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
                  color: hasStock ? AppColors.success : AppColors.textTertiary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasStock ? 'Quantité en stock' : 'Aucun stock enregistré',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (hasStock)
                      Text(
                        '$quantity $unit',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          fontFamily: 'Outfit',
                        ),
                      ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StockManagementScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: const Text('Gérer', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(Prediction prediction) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        _buildActionButton(
          'Créer Alerte',
          Icons.notifications_active_rounded,
          AppColors.primary,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsScreen())),
        ),
        _buildActionButton(
          'Comparer Prix',
          Icons.compare_arrows_rounded,
          Colors.orange,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PriceComparisonScreen(
                product: Product(
                  id: prediction.product,
                  name: prediction.productName,
                  localName: '',
                  category: 1, // Default fallback
                  categoryName: prediction.productCategory,
                  categoryIcon: '🌾',
                  categoryColor: '#4CAF50',
                  unit: prediction.productUnit,
                  unitDisplay: prediction.productUnit,
                  avgPrice: prediction.currentPrice,
                  trend: prediction.trend,
                  availability: 'medium', // Default
                  trendDisplay: prediction.trend == 'up' ? 'En hausse' : 'Stable',
                  availabilityDisplay: 'Normal',
                  minPrice: prediction.currentPrice * 0.9,
                  maxPrice: prediction.currentPrice * 1.1,
                  priceChangePercent: prediction.priceChangePercent,
                  isFeatured: false,
                ),
              ),
            ),
          ),
        ),
        _buildActionButton(
          'Aide IA',
          Icons.chat_bubble_rounded,
          Colors.blue,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatbotScreen())),
        ),
        _buildActionButton(
          'Heatmap',
          Icons.map_rounded,
          Colors.redAccent,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PriceHeatmapScreen())),
        ),
        _buildActionButton(
          'Calendrier',
          Icons.calendar_today_rounded,
          Colors.green,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AgriculturalCalendarScreen())),
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    fontFamily: 'Outfit',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Text(title,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                fontFamily: 'Outfit',
                color: AppColors.textPrimary)),
      ],
    );
  }
}

class _ConfidenceIndicator extends StatelessWidget {
  final String level;
  const _ConfidenceIndicator({required this.level});
  @override
  Widget build(BuildContext context) {
    final color = level == 'high'
        ? AppColors.success
        : level == 'medium'
            ? AppColors.warning
            : AppColors.error;
    final text = level == 'high'
        ? 'ÉLEVÉ'
        : level == 'medium'
            ? 'MOYEN'
            : 'FAIBLE';
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Text(text,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: 1)));
  }
}

class _LargePrice extends StatelessWidget {
  final String label;
  final double value;
  final Color? color;
  const _LargePrice({required this.label, required this.value, this.color});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(label,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.textTertiary)),
      Text('${value.toInt()}F',
          style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: color ?? AppColors.textPrimary,
              fontFamily: 'Outfit',
              letterSpacing: -1))
    ]);
  }
}
