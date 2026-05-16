// lib/screens/products_screen.dart
// Écran de liste des produits agricoles avec recherche et filtres

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../utils/ui_utils.dart';
import 'predictions_screen.dart';
import 'price_heatmap_screen.dart';
import 'agricultural_calendar_screen.dart';
import 'price_comparison_screen.dart';
import 'alerts_screen.dart';
import 'prediction_detail_screen.dart';
import '../widgets/product_widgets.dart';

class ProductsScreen extends StatefulWidget {
  final String? initialSearch;
  final int? initialCategoryId;
  const ProductsScreen({super.key, this.initialSearch, this.initialCategoryId});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen>
    with AutomaticKeepAliveClientMixin {
  List<Product> _products = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  bool _isGrid = false;
  String? _error;
  final _searchController = TextEditingController();
  int? _selectedCategoryId;
  String? _selectedTrend;
  String? _selectedAvailability;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.initialSearch != null) {
      _searchController.text = widget.initialSearch!;
    }
    _selectedCategoryId = widget.initialCategoryId;
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text.length >= 2 || _searchController.text.isEmpty) {
      _loadProducts();
    }
  }

  Future<void> _loadData() async {
    try {
      final cats = await ApiService.getCategories();
      setState(() => _categories = cats);
    } catch (_) {}
    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final products = await ApiService.getProducts(
        categoryId: _selectedCategoryId,
        search: _searchController.text.trim(),
        trend: _selectedTrend,
        availability: _selectedAvailability,
      );
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Impossible de charger les produits.';
        _isLoading = false;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedCategoryId = null;
      _selectedTrend = null;
      _selectedAvailability = null;
    });
    _loadProducts();
  }

  bool get _hasFilters =>
      _selectedCategoryId != null ||
      _selectedTrend != null ||
      _selectedAvailability != null;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Produits Agricoles'),
        actions: [
          IconButton(
            icon: Icon(_isGrid ? Icons.list_rounded : Icons.grid_view_rounded),
            onPressed: () => setState(() => _isGrid = !_isGrid),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFiltersBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildError()
                    : _products.isEmpty
                        ? _buildEmpty()
                        : RefreshIndicator(
                            onRefresh: _loadProducts,
                            child: _isGrid ? _buildGrid() : _buildList(),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => UIUtils.showAddProductDialog(context,
            onProductAdded: _loadProducts),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Ajouter Produit',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit')),
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Scanner un produit',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
          ],
        ),
        content: const Text(
          'L\'appareil photo va s\'ouvrir pour scanner le code-barre ou reconnaître visuellement le produit agricole via l\'IA AgriSmart.',
          style: TextStyle(fontFamily: 'Nunito', fontSize: 14),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler',
                  style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Reconnaissance IA en cours de développement...'),
                    backgroundColor: AppColors.primary),
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('Ouvrir la caméra',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher un produit...',
          prefixIcon:
              const Icon(Icons.search_rounded, color: AppColors.textTertiary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded,
                      color: AppColors.textTertiary, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    _loadProducts();
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildFiltersBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            if (_hasFilters)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: const Text('Effacer'),
                  avatar: const Icon(Icons.close_rounded, size: 14),
                  onPressed: _clearFilters,
                  backgroundColor: AppColors.errorBg,
                  labelStyle: const TextStyle(
                      color: AppColors.error, fontFamily: 'Nunito'),
                ),
              ),
            // Category filter
            ..._categories.map((cat) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text('${cat.icon} ${cat.name}'),
                    selected: _selectedCategoryId == cat.id,
                    onSelected: (selected) {
                      setState(
                          () => _selectedCategoryId = selected ? cat.id : null);
                      _loadProducts();
                    },
                    labelStyle:
                        const TextStyle(fontFamily: 'Nunito', fontSize: 12),
                  ),
                )),
            // Trend filters
            _buildFilterChip('📈 Hausse', 'up', _selectedTrend, (v) {
              setState(() => _selectedTrend = v);
              _loadProducts();
            }),
            const SizedBox(width: 8),
            _buildFilterChip('📉 Baisse', 'down', _selectedTrend, (v) {
              setState(() => _selectedTrend = v);
              _loadProducts();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String? current,
      Function(String?) onChanged) {
    return FilterChip(
      label: Text(label),
      selected: current == value,
      onSelected: (selected) => onChanged(selected ? value : null),
      labelStyle: const TextStyle(fontFamily: 'Nunito', fontSize: 12),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return ProductListItem(
          product: product,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PredictionDetailScreen(
                prediction: Prediction.fromProduct(product),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return ProductGridItem(
          product: product,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PredictionDetailScreen(
                prediction: Prediction.fromProduct(product),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔍', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          const Text('Aucun produit trouvé',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFamily: 'Nunito',
              )),
          const SizedBox(height: 8),
          const Text('Modifiez vos filtres ou votre recherche',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontFamily: 'Nunito',
              )),
          const SizedBox(height: 20),
          if (_hasFilters)
            TextButton(
                onPressed: _clearFilters,
                child: const Text('Effacer les filtres')),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text(_error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontFamily: 'Nunito',
              )),
          const SizedBox(height: 20),
          ElevatedButton(
              onPressed: _loadProducts, child: const Text('Réessayer')),
        ],
      ),
    );
  }

  void _openProductDetail(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PredictionDetailScreen(
          prediction: Prediction.fromProduct(product),
        ),
      ),
    ).then((_) => _loadProducts());
  }
}
