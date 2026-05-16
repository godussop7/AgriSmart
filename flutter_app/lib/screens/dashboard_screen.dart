import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';

import 'map_screen.dart';
import 'products_screen.dart';
import 'predictions_screen.dart';
import 'price_heatmap_screen.dart';
import 'agricultural_calendar_screen.dart';
import 'chatbot_screen.dart';
import 'farmer_dashboard_screen.dart';
import 'alerts_screen.dart';
import 'profile_screen.dart';
import '../widgets/weather_banner.dart';
import '../widgets/agri_tips_carousel.dart';
import '../widgets/dashboard_widgets.dart';
import '../utils/ui_utils.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  DashboardData? _data;
  bool _isLoading = true;
  String? _error;
  bool _chartIsEstimated = false;
  late AnimationController _animController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _loadDashboard();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ApiService.getDashboard();
      setState(() {
        _data = data;
        _isLoading = false;
      });
      _animController.forward(from: 0.0);
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Impossible de charger les données. Vérifiez votre connexion.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        color: AppColors.primary,
        backgroundColor: Colors.white,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            if (_isLoading)
              const SliverFillRemaining(
                  child: Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary)))
            else if (_error != null)
              SliverFillRemaining(
                child: DashboardErrorWidget(message: _error!, onRetry: _loadDashboard),
              )
            else if (_data != null) ...[
              SliverToBoxAdapter(
                child: AnimatedDashboardItem(
                  animation: _animController,
                  index: 0,
                  child: _buildTopSection(),
                ),
              ),
              SliverToBoxAdapter(
                child: AnimatedDashboardItem(
                  animation: _animController,
                  index: 1,
                  child: _buildSearchBar(),
                ),
              ),
              SliverToBoxAdapter(
                child: Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    if (auth.isAuthenticated) {
                      return AnimatedDashboardItem(
                        animation: _animController,
                        index: 2,
                        child: _buildFarmerDashboard(),
                      );
                    }
                    return AnimatedDashboardItem(
                      animation: _animController,
                      index: 2,
                      child: _buildGuestLoginCta(),
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: AnimatedDashboardItem(
                  animation: _animController,
                  index: 3,
                  child: _buildQuickActions(),
                ),
              ),
              SliverToBoxAdapter(
                child: AnimatedDashboardItem(
                  animation: _animController,
                  index: 4,
                  child: _buildStatsGrid(),
                ),
              ),
              SliverToBoxAdapter(
                child: AnimatedDashboardItem(
                  animation: _animController,
                  index: 5,
                  child: _buildPriceChart(),
                ),
              ),
              SliverToBoxAdapter(
                child: AnimatedDashboardItem(
                  animation: _animController,
                  index: 6,
                  child: _buildCategoriesRow(),
                ),
              ),
              SliverToBoxAdapter(
                child: AnimatedDashboardItem(
                  animation: _animController,
                  index: 7,
                  child: _buildFeaturedProducts(),
                ),
              ),
              SliverToBoxAdapter(
                child: AnimatedDashboardItem(
                  animation: _animController,
                  index: 8,
                  child: _buildActiveMarkets(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final user = auth.user;
        final hour = DateTime.now().hour;
        final greeting =
            hour < 12 ? 'Bonjour' : (hour < 18 ? 'Bon après-midi' : 'Bonsoir');
        final firstName = user != null && user.firstName.isNotEmpty
            ? user.firstName
            : (user?.username ?? 'Visiteur');
        final region = user?.regionName ?? 'Sénégal';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Text(
                        'AgriSmart',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Outfit',
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (auth.isAuthenticated)
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  IconButton(
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const AlertsScreen()),
                                    ),
                                    icon: const Icon(
                                        Icons.notifications_outlined,
                                        color: AppColors.textPrimary),
                                  ),
                                  if ((_data?.activeAlerts ?? 0) > 0)
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: AppColors.error,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '${_data!.activeAlerts}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            Flexible(
                              child: Text(
                                '$greeting, $firstName !',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Outfit',
                                  color: AppColors.textPrimary,
                                ),
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on_rounded,
                                size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              region,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            WeatherBanner(regionName: region),
            const AgriTipsCarousel(),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.35), width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: TextField(
            onSubmitted: (query) {
              if (query.isNotEmpty) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ProductsScreen(initialSearch: query)));
              }
            },
            decoration: InputDecoration(
              hintText: 'Rechercher un produit, un marché...',
              hintStyle: TextStyle(
                  color: AppColors.textTertiary.withValues(alpha: 0.6),
                  fontSize: 15,
                  fontWeight: FontWeight.w500),
              prefixIcon: const Icon(Icons.search_rounded,
                  color: AppColors.primary, size: 26),
              suffixIcon: IconButton(
                icon: const Icon(Icons.tune_rounded, color: AppColors.primary),
                onPressed: _showSearchFilters,
              ),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 20),
            ),
          ),
        ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestLoginCta() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_open_rounded,
              color: AppColors.primary, size: 32),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mon Dashboard',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Outfit',
                        fontSize: 16)),
                Text(
                  'Connectez-vous pour voir vos stats, stock et alertes.',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
            child: const Text('Connexion',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _showSearchFilters() {
    final categories = _data?.categories ?? [];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filtrer par catégorie',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Outfit')),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((cat) {
                return ActionChip(
                  label: Text('${cat.icon} ${cat.name}'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ProductsScreen(initialCategoryId: cat.id),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProductsScreen()),
                  );
                },
                icon: const Icon(Icons.grass_rounded),
                label: const Text('Voir tous les produits'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTrendPercent(List<double> prices) {
    if (prices.length < 2 || prices.first <= 0) return '—';
    final pct = (prices.last - prices.first) / prices.first * 100;
    return '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%';
  }

  Widget _buildFarmerDashboard() {
    final stockCount = _data?.userStockCount ?? 0;
    final userProducts = _data?.userProducts ?? [];
    final productCount =
        stockCount > 0 ? stockCount : userProducts.length;
    final alerts = _data?.activeAlerts ?? 0;
    final trendPrices = _resolveChartPrices(_data!.priceTrends);
    final trendLabel = _formatTrendPercent(trendPrices);
    final trendUp = trendPrices.length >= 2 && trendPrices.last >= trendPrices.first;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FarmerDashboardScreen(dashboardData: _data),
        ),
      ),
      child: Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.agriculture_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mon Dashboard',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Outfit',
                      ),
                    ),
                    Text(
                      'Voir toutes vos statistiques →',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 18, color: AppColors.textTertiary),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.inventory_2_rounded,
                  value: '$productCount',
                  label: 'Mon stock',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.notifications_active_rounded,
                  value: '$alerts',
                  label: 'Alertes',
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: trendUp
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  value: trendLabel,
                  label: 'Tendance 7j',
                  color: trendUp ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Actions Rapides',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                  fontFamily: 'Outfit')),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ActionItem(
                  icon: Icons.auto_awesome_rounded,
                  label: 'IA Prédict',
                  color: AppColors.secondary,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => PredictionsScreen()))),
              ActionItem(
                  icon: Icons.calendar_today_rounded,
                  label: 'Calendrier',
                  color: const Color(0xFF8B5CF6),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AgriculturalCalendarScreen()))),
              ActionItem(
                  icon: Icons.grid_on_rounded,
                  label: 'Heatmap',
                  color: const Color(0xFF10B981),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PriceHeatmapScreen()))),
              ActionItem(
                  icon: Icons.smart_toy_rounded,
                  label: 'Chatbot',
                  color: const Color(0xFFF43F5E),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ChatbotScreen()))),
              ActionItem(
                  icon: Icons.map_rounded,
                  label: 'Carte',
                  color: const Color(0xFF0EA5E9),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const MapScreen()))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final data = _data!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Aperçu Global',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                  fontFamily: 'Outfit')),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: StatTile(
                      title: 'Produits',
                      value: '${data.totalProducts}',
                      icon: Icons.shopping_basket_rounded,
                      color: AppColors.primary)),
              const SizedBox(width: 12),
              Expanded(
                  child: StatTile(
                      title: 'Analyses',
                      value: '${data.totalPricesToday}',
                      icon: Icons.insights_rounded,
                      color: const Color(0xFF0EA5E9))),
              const SizedBox(width: 12),
              Expanded(
                  child: StatTile(
                      title: 'Alertes',
                      value: '${data.activeAlerts}',
                      icon: Icons.notifications_active_rounded,
                      color: const Color(0xFFF43F5E))),
            ],
          ),
        ],
      ),
    );
  }

  double _parseTrendPrice(Map<String, dynamic> e) {
    final v = e['avg_price'] ?? e['avgPrice'] ?? 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  List<double> _resolveChartPrices(List<Map<String, dynamic>> trends) {
    final prices = trends.map(_parseTrendPrice).toList();
    _chartIsEstimated = trends.any((t) => t['has_data'] != true);
    if (prices.every((p) => p <= 0)) {
      _chartIsEstimated = true;
      return [];
    }
    return prices;
  }

  String _weekdayLabel(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
      const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      return days[d.weekday - 1];
    } catch (_) {
      return dateStr;
    }
  }

  Widget _buildPriceChart() {
    final trends = _data!.priceTrends;
    if (trends.isEmpty) return const SizedBox.shrink();

    final prices = _resolveChartPrices(trends);
    if (prices.isEmpty) {
      return Container(
        margin: const EdgeInsets.fromLTRB(24, 32, 24, 0),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          children: [
            Icon(Icons.show_chart_rounded,
                size: 48, color: AppColors.textTertiary),
            SizedBox(height: 12),
            Text('Indice Global des Prix',
                style: TextStyle(
                    fontWeight: FontWeight.w900, fontFamily: 'Outfit')),
            SizedBox(height: 8),
            Text(
              'Aucune donnée de prix sur les 7 derniers jours.\nAjoutez des prix via l\'API ou le back-office.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
          ],
        ),
      );
    }
    final spots = List.generate(
        prices.length, (i) => FlSpot(i.toDouble(), prices[i]));
    final rawMin = prices.reduce((a, b) => a < b ? a : b);
    final rawMax = prices.reduce((a, b) => a > b ? a : b);
    var minY = (rawMin * 0.95).floorToDouble();
    var maxY = (rawMax * 1.05).ceilToDouble();
    if (maxY <= minY) maxY = minY + 100;
    final horizontalInterval = (maxY - minY) / 4;
    final trendPct = prices.length >= 2 && prices.first > 0
        ? ((prices.last - prices.first) / prices.first * 100)
        : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Indice Global des Prix',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          fontFamily: 'Outfit')),
                  Text('Moyenne nationale sur 7 jours',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w500)),
                ],
              ),
              if (_chartIsEstimated)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warningBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Partiel',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.warning)),
                ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: (trendPct >= 0 ? AppColors.success : AppColors.error)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Text(
                    '${trendPct >= 0 ? '+' : ''}${trendPct.toStringAsFixed(1)}%',
                    style: TextStyle(
                        color: trendPct >= 0
                            ? AppColors.success
                            : AppColors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: horizontalInterval,
                    getDrawingHorizontalLine: (v) =>
                        FlLine(color: AppColors.divider, strokeWidth: 1)),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 48,
                          interval: horizontalInterval,
                          getTitlesWidget: (v, meta) => Text(
                              '${(v / 1000).toStringAsFixed(1)}k',
                              style: const TextStyle(
                                  color: AppColors.textTertiary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)))),
                  bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (v, meta) {
                            final i = v.toInt();
                            if (i >= 0 && i < trends.length) {
                              final label = _weekdayLabel(
                                  trends[i]['date']?.toString() ?? '');
                              return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(label,
                                      style: const TextStyle(
                                          color: AppColors.textTertiary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold)));
                            }
                            return const SizedBox.shrink();
                          })),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minY: minY,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) =>
                            FlDotCirclePainter(
                                radius: 4,
                                color: Colors.white,
                                strokeWidth: 2,
                                strokeColor: AppColors.primary)),
                    belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.primary.withValues(alpha: 0.2),
                              AppColors.primary.withValues(alpha: 0.01)
                            ])),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesRow() {
    final categories = _data!.categories;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 32, 24, 16),
          child: Text('Parcourir par Catégorie',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  fontFamily: 'Outfit')),
        ),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, i) {
              final cat = categories[i];
              final color = UIUtils.parseColor(cat.color);
              return GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            ProductsScreen(initialCategoryId: cat.id))),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppColors.textPrimary.withValues(alpha: 0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                          BoxShadow(
                            color: color.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                          child: Text(cat.icon,
                              style: const TextStyle(fontSize: 34))),
                    ),
                    const SizedBox(height: 10),
                    Text(cat.name,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontFamily: 'Outfit')),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedProducts() {
    final products = _data!.featuredProducts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Produits Vedettes',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      fontFamily: 'Outfit')),
              TextButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ProductsScreen())),
                  child: const Text('Voir tout',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900))),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, i) =>
                PremiumProductCard(product: products[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveMarkets() {
    final markets = _data!.activeMarkets;
    if (markets.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Marchés Actifs',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      fontFamily: 'Outfit')),
              TextButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const MapScreen())),
                  child: const Text('Carte',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900))),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: markets.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, i) => ActiveMarketCard(market: markets[i]),
          ),
        ),
      ],
    );
  }


}

