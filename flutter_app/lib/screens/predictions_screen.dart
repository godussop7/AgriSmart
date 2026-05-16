import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../providers/auth_provider.dart';
import '../widgets/prediction_widgets.dart';
import 'prediction_detail_screen.dart';

class PredictionsScreen extends StatefulWidget {
  const PredictionsScreen({super.key});

  @override
  State<PredictionsScreen> createState() => _PredictionsScreenState();
}

class _PredictionsScreenState extends State<PredictionsScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Prediction> _predictions = [];
  bool _isLoading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPredictions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPredictions() async {
    if (!Provider.of<AuthProvider>(context, listen: false).isAuthenticated) {
      setState(() {
        _predictions = [];
        _isLoading = false;
        _error = 'Veuillez vous connecter pour voir vos prédictions.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final predictions = await ApiService.getPredictions();
      setState(() {
        _predictions = predictions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement des prédictions.';
        _isLoading = false;
      });
    }
  }

  void _openGeneratePrediction() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GeneratePredictionSheet(onGenerated: (p) {
        setState(() => _predictions.insert(0, p));
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Historique'),
                Tab(text: 'Fonctionnement')
              ],
              labelColor: AppColors.primary,
              indicatorColor: AppColors.primary,
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildHistoryTab(),
                _buildAboutTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: auth.isAuthenticated 
        ? FloatingActionButton.extended(
            onPressed: _openGeneratePrediction,
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
            label: const Text('Générer IA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        : null,
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: AppColors.primaryDark,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('Analyse IA', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    if (_predictions.isEmpty) return const Center(child: Text('Aucune prédiction générée.'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _predictions.length,
      itemBuilder: (context, index) {
        final prediction = _predictions[index];
        return PredictionCard(
          prediction: prediction,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PredictionDetailScreen(prediction: prediction),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAboutTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Comment ça marche ?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildInfoItem(Icons.data_usage_rounded, 'Analyse de données', 'Notre IA analyse les prix historiques de plus de 50 marchés au Sénégal.'),
        _buildInfoItem(Icons.cloud_sync_rounded, 'Météo & Saisons', 'Les facteurs climatiques sont pris en compte pour anticiper les variations.'),
        _buildInfoItem(Icons.psychology_rounded, 'Modèles Avancés', 'Nous utilisons des modèles de machine learning spécialisés pour l\'agriculture.'),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
