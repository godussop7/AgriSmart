import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/export_service.dart';
import '../utils/constants.dart';
import 'predictions_screen.dart';
import 'alerts_screen.dart';
import 'products_screen.dart';
import 'chatbot_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'stock_management_screen.dart';
import 'sales_statistics_screen.dart';

class FarmerDashboardScreen extends StatefulWidget {
  final DashboardData? dashboardData;

  const FarmerDashboardScreen({super.key, this.dashboardData});

  @override
  State<FarmerDashboardScreen> createState() => _FarmerDashboardScreenState();
}

class _FarmerDashboardScreenState extends State<FarmerDashboardScreen> {
  DashboardData? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _data = widget.dashboardData;
    if (_data == null) _load();
    else _loading = false;
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getDashboard();
      if (mounted) setState(() { _data = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mon Dashboard',
            style: TextStyle(fontWeight: FontWeight.w900, fontFamily: 'Outfit')),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildProfileCard(user),
                  const SizedBox(height: 20),
                  _buildStatsRow(context),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('Revenus (7 jours)'),
                      TextButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SalesStatisticsScreen())),
                        icon: const Icon(Icons.bar_chart_rounded, size: 18),
                        label: const Text('Statistiques', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildRevenueChart(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Mes produits en stock'),
                  const SizedBox(height: 12),
                  ...(_userProductList().isEmpty
                      ? [
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              'Aucun produit en stock. Ajoutez du stock depuis votre profil.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          )
                        ]
                      : _userProductList().take(8).map(_buildProductRow)),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Actions rapides'),
                  const SizedBox(height: 12),
                  _buildQuickActions(context),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Export des données'),
                  const SizedBox(height: 12),
                  _buildExportButtons(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileCard(UserData? user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.emeraldGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            child: Text(
              user?.initials ?? 'U',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.fullName ?? 'Utilisateur',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Outfit',
                  ),
                ),
                Text(
                  user?.roleDisplay ?? 'Agriculteur',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (user?.regionName != null)
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.9)),
                      const SizedBox(width: 4),
                      Text(
                        user!.regionName!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Product> _userProductList() {
    final user = _data?.userProducts ?? [];
    if (user.isNotEmpty) return user;
    return _data?.featuredProducts ?? [];
  }

  Widget _buildStatsRow(BuildContext context) {
    final d = _data;
    final stats = [
      ('Mon stock', '${d?.userStockCount ?? _userProductList().length}',
          Icons.inventory_2_rounded, AppColors.primary, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StockManagementScreen()))),
      ('Alertes', '${d?.activeAlerts ?? 0}', Icons.notifications_active_rounded,
          AppColors.secondary, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsScreen()))),
      ('Analyses', '${d?.totalPricesToday ?? 0}', Icons.insights_rounded,
          const Color(0xFF0EA5E9), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PredictionsScreen()))),
      ('Marchés', '${d?.totalMarkets ?? 0}', Icons.storefront_rounded,
          const Color(0xFF8B5CF6), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductsScreen()))),
    ];
    return Row(
      children: stats
          .map((s) => Expanded(
                child: GestureDetector(
                  onTap: s.$5,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Icon(s.$3, color: s.$4, size: 24),
                        const SizedBox(height: 8),
                        Text(s.$2,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: s.$4,
                              fontFamily: 'Outfit',
                            )),
                        Text(s.$1,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            )),
                      ],
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildRevenueChart() {
    final List<double> revenues = [120000, 150000, 90000, 210000, 180000, 250000, 310000];
    const double maxRevenue = 350000;

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxRevenue,
          minY: 0,
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      days[value.toInt() % 7],
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: revenues.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value,
                  color: AppColors.primary,
                  width: 16,
                  borderRadius: BorderRadius.circular(6),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxRevenue,
                    color: AppColors.primary.withValues(alpha: 0.1),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          fontFamily: 'Outfit',
        ));
  }

  Widget _buildProductRow(Product p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Text(p.categoryIcon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontFamily: 'Outfit')),
                Text('${p.avgPrice.toInt()} FCFA/${p.unitDisplay}',
                    style: const TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Icon(
            p.trend == 'up' ? Icons.trending_up : Icons.trending_down,
            color: p.trend == 'up' ? AppColors.success : AppColors.error,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      (Icons.auto_awesome_rounded, 'Prédictions IA', AppColors.secondary,
          () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const PredictionsScreen()))),
      (Icons.notifications_rounded, 'Mes alertes', AppColors.error, () =>
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AlertsScreen()))),
      (Icons.grass_rounded, 'Mes produits', AppColors.primary, () =>
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ProductsScreen()))),
      (Icons.smart_toy_rounded, 'Chatbot', const Color(0xFFF43F5E), () =>
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ChatbotScreen()))),
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: actions
          .map((a) => SizedBox(
                width: (MediaQuery.of(context).size.width - 60) / 2,
                child: Material(
                  color: a.$3.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: a.$4,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(a.$1, color: a.$3),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(a.$2,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: a.$3,
                                  fontSize: 13,
                                )),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildExportButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              try {
                await ExportService.exportToPDF(
                  title: 'Mon Dashboard - AgriSmart',
                  data: _userProductList()
                      .map((p) => {
                            'Produit': p.name,
                            'Prix': '${p.avgPrice.toInt()} FCFA',
                            'Catégorie': p.categoryName,
                          })
                      .toList(),
                  headers: ['Produit', 'Prix', 'Catégorie'],
                );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('$e')));
                }
              }
            },
            icon: const Icon(Icons.picture_as_pdf_rounded),
            label: const Text('PDF'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              try {
                await ExportService.exportToCSV(
                  title: 'Mon Dashboard',
                  data: _userProductList()
                      .map((p) => {
                            'Produit': p.name,
                            'Prix': p.avgPrice,
                            'Catégorie': p.categoryName,
                          })
                      .toList(),
                  headers: ['Produit', 'Prix', 'Catégorie'],
                );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('$e')));
                }
              }
            },
            icon: const Icon(Icons.table_chart_rounded),
            label: const Text('CSV'),
          ),
        ),
      ],
    );
  }
}
