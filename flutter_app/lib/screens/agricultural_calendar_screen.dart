import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import 'chatbot_screen.dart';
import 'predictions_screen.dart';
import 'products_screen.dart';

class CropCalendarInfo {
  final int sowStartMonth;
  final int sowEndMonth;
  final int harvestStartMonth;
  final int harvestEndMonth;
  final String sowingTip;
  final String harvestTip;
  final String storageTip;

  const CropCalendarInfo({
    required this.sowStartMonth,
    required this.sowEndMonth,
    required this.harvestStartMonth,
    required this.harvestEndMonth,
    required this.sowingTip,
    required this.harvestTip,
    required this.storageTip,
  });
}

CropCalendarInfo _calendarForProduct(Product p) {
  final m = p.seasonStart ?? ((p.id % 12) + 1);
  return CropCalendarInfo(
    sowStartMonth: m,
    sowEndMonth: (m % 12) + 1,
    harvestStartMonth: ((m + 2) % 12) + 1,
    harvestEndMonth: ((m + 4) % 12) + 1,
    sowingTip:
        'Semez ${p.name} en sol bien préparé, espacement régulier et arrosage modéré les 15 premiers jours.',
    harvestTip:
        'Récoltez lorsque les organes sont matures et secs. Évitez les heures les plus chaudes.',
    storageTip:
        'Stockez dans un lieu sec et ventilé. Surveillez l\'humidité pour limiter les pertes post-récolte.',
  );
}

class AgriculturalCalendarScreen extends StatefulWidget {
  const AgriculturalCalendarScreen({super.key});

  @override
  State<AgriculturalCalendarScreen> createState() =>
      _AgriculturalCalendarScreenState();
}

class _AgriculturalCalendarScreenState extends State<AgriculturalCalendarScreen> {
  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  List<Product> _products = [];
  List<Product> _filtered = [];
  Product? _selectedProduct;
  final _searchCtrl = TextEditingController();
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchCtrl.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _filterProducts() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _products
          : _products
              .where((p) =>
                  p.name.toLowerCase().contains(q) ||
                  p.categoryName.toLowerCase().contains(q))
              .toList();
    });
  }

  Future<void> _loadData() async {
    try {
      final products = await ApiService.getProducts();
      setState(() {
        _products = products;
        _filtered = products;
        _selectedProduct = products.isNotEmpty ? products.first : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<String> _eventsForDay(DateTime day) {
    if (_selectedProduct == null) return [];
    final info = _calendarForProduct(_selectedProduct!);
    final events = <String>[];
    final m = day.month;
    if (m >= info.sowStartMonth && m <= info.sowEndMonth) {
      events.add('🌱 Semence: ${_selectedProduct!.name}');
    }
    if (m >= info.harvestStartMonth && m <= info.harvestEndMonth) {
      events.add('🌾 Récolte: ${_selectedProduct!.name}');
    }
    return events;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Text(_error!))
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      pinned: true,
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.textPrimary,
                      elevation: 0,
                      title: const Text('Calendrier Agricole',
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Outfit')),
                    ),
                    SliverToBoxAdapter(child: _buildSearch()),
                    SliverToBoxAdapter(child: _buildProductChips()),
                    SliverToBoxAdapter(child: _buildSelectedProductCard()),
                    SliverToBoxAdapter(child: _buildCalendar()),
                    SliverToBoxAdapter(child: _buildDayActivities()),
                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  ],
                ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: 'Rechercher un produit...',
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.border),
          ),
        ),
      ),
    );
  }

  Widget _buildProductChips() {
    if (_filtered.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text('Aucun produit trouvé',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filtered.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final p = _filtered[i];
          final selected = _selectedProduct?.id == p.id;
          return FilterChip(
            selected: selected,
            label: Text('${p.categoryIcon} ${p.name}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.textPrimary,
                )),
            selectedColor: AppColors.primary,
            backgroundColor: Colors.white,
            onSelected: (_) => setState(() => _selectedProduct = p),
          );
        },
      ),
    );
  }

  Widget _buildSelectedProductCard() {
    final p = _selectedProduct;
    if (p == null) return const SizedBox.shrink();
    final info = _calendarForProduct(p);
    return GestureDetector(
      onTap: () => _showProductDetail(p, info),
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.08),
              AppColors.secondary.withValues(alpha: 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Text(p.categoryIcon, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Outfit',
                      )),
                  Text('${p.avgPrice.toInt()} FCFA • ${p.categoryName}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      )),
                  const SizedBox(height: 6),
                  Text(
                    'Semence: ${_monthName(info.sowStartMonth)}-${_monthName(info.sowEndMonth)} • Récolte: ${_monthName(info.harvestStartMonth)}-${_monthName(info.harvestEndMonth)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.info_outline_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final firstWeekday = firstDay.weekday;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => setState(() {
                  _focusedMonth =
                      DateTime(_focusedMonth.year, _focusedMonth.month - 1);
                }),
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                DateFormat.yMMMM('fr_FR').format(_focusedMonth),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Outfit',
                ),
              ),
              IconButton(
                onPressed: () => setState(() {
                  _focusedMonth =
                      DateTime(_focusedMonth.year, _focusedMonth.month + 1);
                }),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          Row(
            children: ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textTertiary,
                            )),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            children: [
              for (int i = 0; i < firstWeekday - 1; i++)
                const SizedBox(),
              for (int day = 1; day <= lastDay.day; day++)
                _dayCell(DateTime(_focusedMonth.year, _focusedMonth.month, day)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dayCell(DateTime date) {
    final selected = _selectedDay.year == date.year &&
        _selectedDay.month == date.month &&
        _selectedDay.day == date.day;
    final events = _eventsForDay(date);
    final hasSow = events.any((e) => e.contains('Semence'));
    final hasHarvest = events.any((e) => e.contains('Récolte'));

    return GestureDetector(
      onTap: () => setState(() => _selectedDay = date),
      child: Container(
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : hasSow
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : hasHarvest
                      ? AppColors.secondary.withValues(alpha: 0.12)
                      : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            if (hasSow || hasHarvest)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (hasSow)
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.all(1),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (hasHarvest)
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.all(1),
                      decoration: const BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayActivities() {
    final events = _eventsForDay(_selectedDay);
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activités du ${DateFormat('d MMMM', 'fr_FR').format(_selectedDay)}',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 12),
          if (events.isEmpty)
            const Text('Aucune activité pour ce produit ce jour-là.',
                style: TextStyle(color: AppColors.textSecondary))
          else
            ...events.map((e) => ListTile(
                  leading: Text(e.split(':').first,
                      style: const TextStyle(fontSize: 22)),
                  title: Text(e.split(':').last.trim(),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                )),
        ],
      ),
    );
  }

  void _showProductDetail(Product p, CropCalendarInfo info) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scroll) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scroll,
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(p.categoryIcon, style: const TextStyle(fontSize: 48)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Outfit',
                            )),
                        Text('${p.avgPrice.toInt()} FCFA/${p.unitDisplay}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            )),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _detailSection('Description', p.description ??
                  'Produit agricole de la catégorie ${p.categoryName}. Disponibilité: ${p.availabilityDisplay}.'),
              _detailSection('Période de semence',
                  '${_monthName(info.sowStartMonth)} à ${_monthName(info.sowEndMonth)}'),
              _detailSection('Période de récolte',
                  '${_monthName(info.harvestStartMonth)} à ${_monthName(info.harvestEndMonth)}'),
              _detailSection('Conseil semence', info.sowingTip),
              _detailSection('Conseil récolte', info.harvestTip),
              _detailSection('Stockage', info.storageTip),
              const SizedBox(height: 16),
              const Text('Actions rapides',
                  style: TextStyle(
                      fontWeight: FontWeight.w900, fontFamily: 'Outfit')),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const PredictionsScreen()));
                      },
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: const Text('Prédiction IA'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ChatbotScreen()));
                      },
                      icon: const Icon(Icons.smart_toy_rounded),
                      label: const Text('Chatbot'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                ProductsScreen(initialSearch: p.name)));
                  },
                  icon: const Icon(Icons.grass_rounded),
                  label: const Text('Voir sur le marché'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailSection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                fontSize: 13,
              )),
          const SizedBox(height: 6),
          Text(body,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: AppColors.textPrimary,
              )),
        ],
      ),
    );
  }

  String _monthName(int m) {
    const months = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return months[(m - 1).clamp(0, 11)];
  }
}
