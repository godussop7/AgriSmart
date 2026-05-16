import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/constants.dart';
import '../services/api_service.dart';

class PredictionCard extends StatelessWidget {
  final Prediction prediction;
  final VoidCallback onTap;

  const PredictionCard({
    super.key,
    required this.prediction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final trendColor = AppFormatters.trendColor(prediction.trend);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  prediction.trend == 'up'
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: trendColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prediction.productName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Outfit',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${prediction.marketName} • ${prediction.horizonDisplay}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${prediction.predictedPrice.toInt()}F',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: trendColor,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const SizedBox(height: 4),
                  _ConfidenceBadge(level: prediction.confidenceLevel),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  final String level;
  const _ConfidenceBadge({required this.level});
  @override
  Widget build(BuildContext context) {
    final color = level == 'high'
        ? AppColors.success
        : level == 'medium'
            ? AppColors.warning
            : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        level.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

class GeneratePredictionSheet extends StatefulWidget {
  final Function(Prediction) onGenerated;
  const GeneratePredictionSheet({super.key, required this.onGenerated});
  @override
  State<GeneratePredictionSheet> createState() =>
      _GeneratePredictionSheetState();
}

class _GeneratePredictionSheetState extends State<GeneratePredictionSheet> {
  Product? _selectedProduct;
  Market? _selectedMarket;
  String _selectedHorizon = '7d';
  bool _isLoading = false;
  List<Product> _products = [];
  List<Market> _markets = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ApiService.getProducts(),
        ApiService.getMarkets()
      ]);
      setState(() {
        _products = results[0] as List<Product>;
        _markets = results[1] as List<Market>;
      });
    } catch (_) {}
  }

  Future<void> _generate() async {
    if (_selectedProduct == null) return;
    setState(() => _isLoading = true);
    try {
      final p = await ApiService.createPrediction(
          productId: _selectedProduct!.id,
          marketId: _selectedMarket?.id,
          horizon: _selectedHorizon);
      widget.onGenerated(p);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur: $e'), backgroundColor: AppColors.error));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildLabel('Produit à analyser'),
                  const SizedBox(height: 12),
                  _buildDropdown<Product>(
                    value: _selectedProduct,
                    hint: 'Choisir un produit...',
                    items: _products.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                    onChanged: (p) => setState(() => _selectedProduct = p),
                  ),
                  const SizedBox(height: 24),
                  _buildLabel('Marché spécifique (Optionnel)'),
                  const SizedBox(height: 12),
                  _buildDropdown<Market>(
                    value: _selectedMarket,
                    hint: 'Tous les marchés',
                    items: _markets.map((m) => DropdownMenuItem(value: m, child: Text(m.name))).toList(),
                    onChanged: (m) => setState(() => _selectedMarket = m),
                  ),
                  const SizedBox(height: 24),
                  _buildLabel('Durée de la prédiction'),
                  const SizedBox(height: 16),
                  _buildHorizonSelector(),
                  const SizedBox(height: 32),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF065F46), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Nouvelle Analyse IA',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Outfit',
                      color: Colors.white)),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'L\'IA analyse les tendances de prix pour optimiser vos revenus agricoles.',
            style: TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textSecondary));
  }

  Widget _buildDropdown<T>({T? value, required String hint, required List<DropdownMenuItem<T>> items, required Function(T?) onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          hint: Text(hint),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildHorizonSelector() {
    final horizons = [
      {'val': '7d', 'label': '7 Jours'},
      {'val': '30d', 'label': '30 Jours'},
      {'val': '90d', 'label': '90 Jours'},
    ];
    return Row(
      children: horizons.map((h) {
        final isSelected = _selectedHorizon == h['val'];
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: ChoiceChip(
            label: Text(h['label']!),
            selected: isSelected,
            onSelected: (_) => setState(() => _selectedHorizon = h['val']!),
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.bold),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isLoading || _selectedProduct == null ? null : _generate,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Lancer l\'Analyse', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white)),
      ),
    );
  }
}
