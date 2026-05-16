import 'package:flutter/material.dart';
import 'constants.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class UIUtils {
  static void showAddProductDialog(BuildContext context,
      {VoidCallback? onProductAdded}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddProductSheet(onProductAdded: onProductAdded),
    );
  }

  static Color parseColor(String hex) {
    try {
      if (hex.startsWith('#')) hex = hex.substring(1);
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }
}

class AddProductSheet extends StatefulWidget {
  final VoidCallback? onProductAdded;
  const AddProductSheet({super.key, this.onProductAdded});

  @override
  State<AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends State<AddProductSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();

  List<Category> _categories = [];
  List<Market> _markets = [];
  Category? _selectedCategory;
  Market? _selectedMarket;
  String _selectedUnit = 'kg';
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ApiService.getCategories(),
        ApiService.getMarkets(),
      ]);
      setState(() {
        _categories = results[0] as List<Category>;
        _markets = results[1] as List<Market>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur de chargement: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!ApiService.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez vous connecter pour ajouter un produit'),
            backgroundColor: AppColors.error),
      );
      return;
    }

    if (!_formKey.currentState!.validate() ||
        _selectedCategory == null ||
        _selectedMarket == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez remplir tous les champs obligatoires'),
            backgroundColor: AppColors.warning),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final productData = {
        'name': _nameController.text.trim(),
        'category': _selectedCategory!.id,
        'unit': _selectedUnit,
        'description': _descController.text.trim(),
        'is_active': true,
      };

      final newProduct = await ApiService.createProduct(productData);

      // Ajout du prix initial
      final priceValue = double.tryParse(_priceController.text) ?? 0.0;
      if (priceValue > 0) {
        await ApiService.addPrice(
          productId: newProduct.id,
          marketId: _selectedMarket!.id,
          price: priceValue,
          date: DateTime.now().toIso8601String().split('T')[0],
          source: 'Creation mobile',
        );
      }

      if (mounted) {
        widget.onProductAdded?.call();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Produit ajouté avec succès ! Actualisez pour voir les changements.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur lors de l\'ajout: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
      child: Stack(
        children: [
          // Background Gradient subtle
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.08),
                    Colors.white
                  ],
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(32)),
              ),
            ),
          ),

          Column(
            children: [
              const SizedBox(height: 12),
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.add_business_rounded,
                          color: AppColors.primary, size: 28),
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nouveau Produit',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.5,
                                fontFamily: 'Outfit')),
                        Text('Ajoutez un article au catalogue',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded,
                          color: AppColors.textTertiary),
                      style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[100]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Expanded(
                child: _isLoading
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: AppColors.primary))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        physics: const BouncingScrollPhysics(),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('Informations Générales'),
                              _buildTextField(
                                controller: _nameController,
                                label: 'Nom du produit',
                                hint: 'Ex: Riz Basmati Local',
                                icon: Icons.shopping_bag_outlined,
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Champ obligatoire'
                                    : null,
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildDropdownField<Category>(
                                      label: 'Catégorie',
                                      value: _selectedCategory,
                                      items: _categories,
                                      onChanged: (v) =>
                                          setState(() => _selectedCategory = v),
                                      itemLabel: (c) => c.name,
                                      icon: Icons.category_outlined,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                              _buildSectionTitle('Vente & Marché'),
                              _buildDropdownField<Market>(
                                label: 'Marché d\'origine',
                                value: _selectedMarket,
                                items: _markets,
                                onChanged: (v) =>
                                    setState(() => _selectedMarket = v),
                                itemLabel: (m) => m.name,
                                icon: Icons.storefront_rounded,
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: _buildTextField(
                                      controller: _priceController,
                                      label: 'Prix indicatif (XOF)',
                                      hint: '0.00',
                                      icon: Icons.payments_outlined,
                                      isNumber: true,
                                      validator: (v) => v == null || v.isEmpty
                                          ? 'Obligatoire'
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 1,
                                    child: _buildDropdownField<String>(
                                      label: 'Unité',
                                      value: _selectedUnit,
                                      items: const [
                                        'kg',
                                        'sac',
                                        'tonne',
                                        'litre',
                                        'unite',
                                        'panier',
                                        'botte'
                                      ],
                                      onChanged: (v) =>
                                          setState(() => _selectedUnit = v!),
                                      itemLabel: (u) {
                                        switch (u) {
                                          case 'unite':
                                            return 'Unité';
                                          case 'botte':
                                            return 'Botte';
                                          case 'panier':
                                            return 'Panier';
                                          case 'tonne':
                                            return 'Tonne';
                                          default:
                                            return u;
                                        }
                                      },
                                      icon: Icons.scale_outlined,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                              _buildSectionTitle('Description (Optionnel)'),
                              _buildTextField(
                                controller: _descController,
                                label: 'Détails supplémentaires',
                                hint: 'Qualité, provenance, saisonnalité...',
                                icon: Icons.description_outlined,
                                maxLines: 3,
                              ),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
              ),

              // Footer Action
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 20,
                        offset: const Offset(0, -5))
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline_rounded),
                              SizedBox(width: 12),
                              Text('Confirmer l\'ajout',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5)),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title.toUpperCase(),
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: 1.2)),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isNumber = false,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFamily: 'Outfit')),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(fontSize: 14, color: AppColors.textTertiary),
            prefixIcon: Icon(icon,
                size: 20, color: AppColors.primary.withValues(alpha: 0.6)),
            filled: true,
            fillColor: AppColors.surfaceVariant.withValues(alpha: 0.5),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<T> items,
    required void Function(T?) onChanged,
    required String Function(T) itemLabel,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFamily: 'Outfit')),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          onChanged: onChanged,
          isExpanded: true,
          validator: (v) => v == null ? 'Sélection requise' : null,
          decoration: InputDecoration(
            prefixIcon: Icon(icon,
                size: 20, color: AppColors.primary.withValues(alpha: 0.6)),
            filled: true,
            fillColor: AppColors.surfaceVariant.withValues(alpha: 0.5),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textTertiary),
          items: items
              .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(itemLabel(e),
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500))))
              .toList(),
        ),
      ],
    );
  }
}
