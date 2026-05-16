// lib/models/models.dart
// Modèles de données Flutter pour AgriSmart

class Region {
  final int id;
  final String name;
  final String code;
  final double? latitude;
  final double? longitude;
  final int population;
  final int marketsCount;

  Region({
    required this.id,
    required this.name,
    required this.code,
    this.latitude,
    this.longitude,
    required this.population,
    required this.marketsCount,
  });

  factory Region.fromJson(Map<String, dynamic> json) => Region(
    id: json['id'],
    name: json['name'],
    code: json['code'],
    latitude: json['latitude']?.toDouble(),
    longitude: json['longitude']?.toDouble(),
    population: json['population'] ?? 0,
    marketsCount: json['markets_count'] ?? 0,
  );
}

class Market {
  final int id;
  final String name;
  final int region;
  final String regionName;
  final String address;
  final double latitude;
  final double longitude;
  final double rating;
  final String priceLevel;
  final String priceLevelDisplay;
  final String status;
  final String marketDays;
  final String description;
  final int productsCount;

  Market({
    required this.id,
    required this.name,
    required this.region,
    required this.regionName,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.priceLevel,
    required this.priceLevelDisplay,
    required this.status,
    required this.marketDays,
    required this.description,
    required this.productsCount,
  });

  factory Market.fromJson(Map<String, dynamic> json) => Market(
    id: json['id'],
    name: json['name'],
    region: json['region'],
    regionName: json['region_name'] ?? '',
    address: json['address'] ?? '',
    latitude: double.tryParse(json['latitude'].toString()) ?? 0.0,
    longitude: double.tryParse(json['longitude'].toString()) ?? 0.0,
    rating: double.tryParse(json['rating'].toString()) ?? 0.0,
    priceLevel: json['price_level'] ?? 'medium',
    priceLevelDisplay: json['price_level_display'] ?? 'Moyen',
    status: json['status'] ?? 'active',
    marketDays: json['market_days'] ?? '',
    description: json['description'] ?? '',
    productsCount: json['products_count'] ?? 0,
  );
}

class Category {
  final int id;
  final String name;
  final String icon;
  final String color;
  final String description;
  final int productsCount;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
    required this.productsCount,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'],
    name: json['name'],
    icon: json['icon'] ?? '🌾',
    color: json['color'] ?? '#4CAF50',
    description: json['description'] ?? '',
    productsCount: json['products_count'] ?? 0,
  );
}

class Product {
  final int id;
  final String name;
  final String localName;
  final int category;
  final String categoryName;
  final String categoryIcon;
  final String categoryColor;
  final String unit;
  final String unitDisplay;
  final String? imageUrl;
  final String trend;
  final String trendDisplay;
  final String availability;
  final String availabilityDisplay;
  final double minPrice;
  final double maxPrice;
  final double avgPrice;
  final double priceChangePercent;
  final bool isFeatured;
  final int? seasonStart;
  final int? seasonEnd;
  final String? description;
  final List<Map<String, dynamic>>? priceHistory;
  final List<Map<String, dynamic>>? latestPrices;

  Product({
    required this.id,
    required this.name,
    required this.localName,
    required this.category,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.unit,
    required this.unitDisplay,
    this.imageUrl,
    required this.trend,
    required this.trendDisplay,
    required this.availability,
    required this.availabilityDisplay,
    required this.minPrice,
    required this.maxPrice,
    required this.avgPrice,
    required this.priceChangePercent,
    required this.isFeatured,
    this.seasonStart,
    this.seasonEnd,
    this.description,
    this.priceHistory,
    this.latestPrices,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'],
    name: json['name'],
    localName: json['local_name'] ?? '',
    category: json['category'],
    categoryName: json['category_name'] ?? '',
    categoryIcon: json['category_icon'] ?? '🌾',
    categoryColor: json['category_color'] ?? '#4CAF50',
    unit: json['unit'] ?? 'kg',
    unitDisplay: json['unit_display'] ?? 'kg',
    imageUrl: json['image_url'],
    trend: json['trend'] ?? 'stable',
    trendDisplay: json['trend_display'] ?? 'Stable',
    availability: json['availability'] ?? 'normal',
    availabilityDisplay: json['availability_display'] ?? 'Normal',
    minPrice: double.tryParse(json['min_price'].toString()) ?? 0.0,
    maxPrice: double.tryParse(json['max_price'].toString()) ?? 0.0,
    avgPrice: double.tryParse(json['avg_price'].toString()) ?? 0.0,
    priceChangePercent: double.tryParse(json['price_change_percent'].toString()) ?? 0.0,
    isFeatured: json['is_featured'] ?? false,
    seasonStart: json['season_start'],
    seasonEnd: json['season_end'],
    description: json['description'],
    priceHistory: json['price_history'] != null
        ? List<Map<String, dynamic>>.from(json['price_history'])
        : null,
    latestPrices: json['latest_prices'] != null
        ? List<Map<String, dynamic>>.from(json['latest_prices'])
        : null,
  );
}

class Price {
  final int id;
  final int product;
  final String productName;
  final String productUnit;
  final int market;
  final String marketName;
  final String marketRegion;
  final double price;
  final String date;
  final String source;
  final bool isVerified;

  Price({
    required this.id,
    required this.product,
    required this.productName,
    required this.productUnit,
    required this.market,
    required this.marketName,
    required this.marketRegion,
    required this.price,
    required this.date,
    required this.source,
    required this.isVerified,
  });

  factory Price.fromJson(Map<String, dynamic> json) => Price(
    id: json['id'],
    product: json['product'],
    productName: json['product_name'] ?? '',
    productUnit: json['product_unit'] ?? 'kg',
    market: json['market'],
    marketName: json['market_name'] ?? '',
    marketRegion: json['market_region'] ?? '',
    price: double.tryParse(json['price'].toString()) ?? 0.0,
    date: json['date'] ?? '',
    source: json['source'] ?? '',
    isVerified: json['is_verified'] ?? false,
  );
}

class Prediction {
  final int id;
  final int product;
  final String productName;
  final String productUnit;
  final String productCategory;
  final int? market;
  final String marketName;
  final String horizon;
  final String horizonDisplay;
  final double currentPrice;
  final double predictedPrice;
  final double priceChangePercent;
  final String confidenceLevel;
  final String confidenceLevelDisplay;
  final double confidenceScore;
  final String trend;
  final String trendDisplay;
  final String recommendation;
  final String analysis;
  final List<String> factors;
  final List<double> predictedPricesSeries;
  final String createdAt;

  Prediction({
    required this.id,
    required this.product,
    required this.productName,
    required this.productUnit,
    required this.productCategory,
    this.market,
    required this.marketName,
    required this.horizon,
    required this.horizonDisplay,
    required this.currentPrice,
    required this.predictedPrice,
    required this.priceChangePercent,
    required this.confidenceLevel,
    required this.confidenceLevelDisplay,
    required this.confidenceScore,
    required this.trend,
    required this.trendDisplay,
    required this.recommendation,
    required this.analysis,
    required this.factors,
    required this.predictedPricesSeries,
    required this.createdAt,
  });

  factory Prediction.fromJson(Map<String, dynamic> json) => Prediction(
    id: json['id'],
    product: json['product'],
    productName: json['product_name'] ?? '',
    productUnit: json['product_unit'] ?? 'kg',
    productCategory: json['product_category'] ?? '',
    market: json['market'],
    marketName: json['market_name'] ?? 'Tous les marchés',
    horizon: json['horizon'] ?? '7d',
    horizonDisplay: json['horizon_display'] ?? '7 jours',
    currentPrice: double.tryParse(json['current_price'].toString()) ?? 0.0,
    predictedPrice: double.tryParse(json['predicted_price'].toString()) ?? 0.0,
    priceChangePercent: double.tryParse(json['price_change_percent'].toString()) ?? 0.0,
    confidenceLevel: json['confidence_level'] ?? 'medium',
    confidenceLevelDisplay: json['confidence_level_display'] ?? 'Modéré',
    confidenceScore: double.tryParse(json['confidence_score'].toString()) ?? 0.7,
    trend: json['trend'] ?? 'stable',
    trendDisplay: json['trend_display'] ?? 'Stable',
    recommendation: json['recommendation'] ?? '',
    analysis: json['analysis'] ?? '',
    factors: json['factors'] != null ? List<String>.from(json['factors']) : [],
    predictedPricesSeries: json['predicted_prices_series'] != null
        ? List<double>.from(json['predicted_prices_series'].map((e) => double.tryParse(e.toString()) ?? 0.0))
        : [],
    createdAt: json['created_at'] ?? '',
  );

  factory Prediction.fromProduct(Product product) => Prediction(
    id: 0,
    product: product.id,
    productName: product.name,
    productUnit: product.unitDisplay,
    productCategory: product.categoryName,
    marketName: 'Sénégal (Moyenne)',
    horizon: '7d',
    horizonDisplay: '7 jours',
    currentPrice: product.avgPrice,
    predictedPrice: product.avgPrice * (1 + (product.priceChangePercent / 100)),
    priceChangePercent: product.priceChangePercent,
    confidenceLevel: 'medium',
    confidenceLevelDisplay: 'Modéré',
    confidenceScore: 0.8,
    trend: product.trend,
    trendDisplay: product.trendDisplay,
    recommendation: product.trend == 'up' 
        ? 'Les prix sont en hausse. Envisagez de vendre une partie de votre stock maintenant.'
        : 'Les prix sont stables ou en baisse. Surveillez le marché avant de vendre.',
    analysis: 'Analyse basée sur les tendances récentes du marché pour le produit ${product.name}.',
    factors: ['Saisonnalité', 'Disponibilité locale', 'Transport'],
    predictedPricesSeries: [product.avgPrice * 0.95, product.avgPrice * 0.98, product.avgPrice, product.avgPrice * 1.02, product.avgPrice * 1.05],
    createdAt: DateTime.now().toIso8601String(),
  );
}

class Alert {
  final int id;
  final int product;
  final String productName;
  final String productUnit;
  final int? market;
  final String marketName;
  final String alertType;
  final String alertTypeDisplay;
  final double thresholdPrice;
  final double? changePercent;
  final String status;
  final String statusDisplay;
  final String? triggeredAt;
  final double? triggeredPrice;
  final String notes;
  final String createdAt;

  Alert({
    required this.id,
    required this.product,
    required this.productName,
    required this.productUnit,
    this.market,
    required this.marketName,
    required this.alertType,
    required this.alertTypeDisplay,
    required this.thresholdPrice,
    this.changePercent,
    required this.status,
    required this.statusDisplay,
    this.triggeredAt,
    this.triggeredPrice,
    required this.notes,
    required this.createdAt,
  });

  factory Alert.fromJson(Map<String, dynamic> json) => Alert(
    id: json['id'],
    product: json['product'],
    productName: json['product_name'] ?? '',
    productUnit: json['product_unit'] ?? 'kg',
    market: json['market'],
    marketName: json['market_name'] ?? 'Tous les marchés',
    alertType: json['alert_type'] ?? 'above',
    alertTypeDisplay: json['alert_type_display'] ?? '',
    thresholdPrice: double.tryParse(json['threshold_price'].toString()) ?? 0.0,
    changePercent: json['change_percent'] != null
        ? double.tryParse(json['change_percent'].toString())
        : null,
    status: json['status'] ?? 'active',
    statusDisplay: json['status_display'] ?? 'Active',
    triggeredAt: json['triggered_at'],
    triggeredPrice: json['triggered_price'] != null
        ? double.tryParse(json['triggered_price'].toString())
        : null,
    notes: json['notes'] ?? '',
    createdAt: json['created_at'] ?? '',
  );
}

class UserData {
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String roleDisplay;
  final String? phone;
  final int? region;
  final String? regionName;
  final String? avatarUrl;
  final bool notificationsEnabled;
  final int alertsCount;
  final int predictionsCount;

  UserData({
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.roleDisplay,
    this.phone,
    this.region,
    this.regionName,
    this.avatarUrl,
    required this.notificationsEnabled,
    required this.alertsCount,
    required this.predictionsCount,
  });

  factory UserData.fromJson(Map<String, dynamic> json) => UserData(
    username: json['username'] ?? '',
    email: json['email'] ?? '',
    firstName: json['first_name'] ?? '',
    lastName: json['last_name'] ?? '',
    role: json['role'] ?? 'consumer',
    roleDisplay: json['role_display'] ?? 'Consommateur',
    phone: json['phone'],
    region: json['region'],
    regionName: json['region_name'],
    avatarUrl: json['avatar_url'],
    notificationsEnabled: json['notifications_enabled'] ?? true,
    alertsCount: json['alerts_count'] ?? 0,
    predictionsCount: json['predictions_count'] ?? 0,
  );

  String get fullName => '$firstName $lastName'.trim().isEmpty ? username : '$firstName $lastName'.trim();

  String get initials {
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '${firstName[0]}${lastName[0]}'.toUpperCase();
    }
    return username.isNotEmpty ? username[0].toUpperCase() : 'U';
  }
}

class DashboardData {
  final int totalProducts;
  final int totalMarkets;
  final int totalPricesToday;
  final int activeAlerts;
  final List<Product> featuredProducts;
  final List<Market> activeMarkets;
  final List<Price> recentPrices;
  final List<Map<String, dynamic>> priceTrends;
  final List<Category> categories;
  final int userStockCount;
  final List<Product> userProducts;

  DashboardData({
    required this.totalProducts,
    required this.totalMarkets,
    required this.totalPricesToday,
    required this.activeAlerts,
    required this.featuredProducts,
    required this.activeMarkets,
    required this.recentPrices,
    required this.priceTrends,
    required this.categories,
    this.userStockCount = 0,
    this.userProducts = const [],
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) => DashboardData(
    totalProducts: json['total_products'] ?? 0,
    totalMarkets: json['total_markets'] ?? 0,
    totalPricesToday: json['total_prices_today'] ?? 0,
    activeAlerts: json['active_alerts'] ?? 0,
    featuredProducts: (json['featured_products'] as List? ?? [])
        .map((p) => Product.fromJson(p))
        .toList(),
    activeMarkets: (json['active_markets'] as List? ?? [])
        .map((m) => Market.fromJson(m))
        .toList(),
    recentPrices: (json['recent_prices'] as List? ?? [])
        .map((p) => Price.fromJson(p))
        .toList(),
    priceTrends: List<Map<String, dynamic>>.from(json['price_trends'] ?? []),
    categories: (json['categories'] as List? ?? [])
        .map((c) => Category.fromJson(c))
        .toList(),
    userStockCount: json['user_stock_count'] ?? 0,
    userProducts: (json['user_products'] as List? ?? [])
        .map((p) => Product.fromJson(p))
        .toList(),
  );
}
