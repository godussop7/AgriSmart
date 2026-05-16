// lib/services/api_service.dart
// Service API centralisé pour toutes les requêtes HTTP

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';
import '../models/models.dart';

class ApiService {
  static const _storage = FlutterSecureStorage();
  static String? _accessToken;
  static String? _refreshToken;

  // ── Token Management ───────────────────────────────────────────────────────
  static Future<void> saveTokens(String access, String refresh) async {
    _accessToken = access;
    _refreshToken = refresh;
    await _storage.write(key: AppConstants.accessTokenKey, value: access);
    await _storage.write(key: AppConstants.refreshTokenKey, value: refresh);
  }

  static Future<void> loadTokens() async {
    _accessToken = await _storage.read(key: AppConstants.accessTokenKey);
    _refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
  }

  static Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    await _storage.deleteAll();
  }

  static bool get isAuthenticated => _accessToken != null;

  // ── HTTP Headers ──────────────────────────────────────────────────────────
  static Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  // ── Generic HTTP Methods ───────────────────────────────────────────────────
  static Future<Map<String, dynamic>> _get(String endpoint) async {
    await loadTokens();
    final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
    final response = await http
        .get(uri, headers: _headers)
        .timeout(AppConstants.receiveTimeout);

    if (response.statusCode == 401) {
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        final retryResponse = await http
            .get(uri, headers: _headers)
            .timeout(AppConstants.receiveTimeout);
        return _parseResponse(retryResponse);
      }
      throw ApiException('Session expirée. Veuillez vous reconnecter.', 401);
    }
    return _parseResponse(response);
  }

  static Future<dynamic> _getList(String endpoint) async {
    await loadTokens();
    final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
    final response = await http
        .get(uri, headers: _headers)
        .timeout(AppConstants.receiveTimeout);

    if (response.statusCode == 200) {
      final decoded = json.decode(utf8.decode(response.bodyBytes));
      if (decoded is List) return decoded;
      if (decoded is Map && decoded.containsKey('results'))
        return decoded['results'];
      return decoded;
    }
    throw ApiException('Erreur de chargement des données', response.statusCode);
  }

  static Future<Map<String, dynamic>> _post(
      String endpoint, Map<String, dynamic> body) async {
    await loadTokens();
    final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
    final response = await http
        .post(
          uri,
          headers: _headers,
          body: json.encode(body),
        )
        .timeout(AppConstants.receiveTimeout);
    return _parseResponse(response);
  }

  static Future<Map<String, dynamic>> _put(
      String endpoint, Map<String, dynamic> body) async {
    await loadTokens();
    final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
    final response = await http
        .put(
          uri,
          headers: _headers,
          body: json.encode(body),
        )
        .timeout(AppConstants.receiveTimeout);
    return _parseResponse(response);
  }

  static Future<bool> _delete(String endpoint) async {
    await loadTokens();
    final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
    debugPrint('DELETE request to: $uri');
    final response = await http
        .delete(uri, headers: _headers)
        .timeout(AppConstants.receiveTimeout);

    debugPrint('DELETE response status: ${response.statusCode}');
    if (response.statusCode >= 200 && response.statusCode < 300) return true;

    debugPrint('DELETE error body: ${response.body}');
    throw ApiException(
        'Échec de la suppression: ${response.statusCode}', response.statusCode);
  }

  static Future<void> deleteProduct(int id) => _delete('/products/$id/');
  static Future<void> deleteAlert(int id) => _delete('/alerts/$id/');
  static Future<void> deletePrediction(int id) => _delete('/predictions/$id/');

  static Map<String, dynamic> _parseResponse(http.Response response) {
    final decoded = json.decode(utf8.decode(response.bodyBytes));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded is Map<String, dynamic> ? decoded : {'data': decoded};
    }

    String message = 'Erreur API';
    if (decoded is Map) {
      if (decoded.containsKey('detail')) {
        message = decoded['detail'].toString();
      } else if (decoded.containsKey('error')) {
        message = decoded['error'].toString();
      } else {
        // Handle field-specific errors (e.g., {"unit": ["..."]})
        final errors = <String>[];
        decoded.forEach((key, value) {
          if (value is List) {
            errors.add('$key: ${value.join(", ")}');
          } else {
            errors.add('$key: $value');
          }
        });
        if (errors.isNotEmpty) message = errors.join("\n");
      }
    }
    throw ApiException(message, response.statusCode);
  }

  static Future<bool> _refreshAccessToken() async {
    try {
      if (_refreshToken == null) return false;
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refresh': _refreshToken}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['access'];
        await _storage.write(
            key: AppConstants.accessTokenKey, value: _accessToken);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ── Auth Endpoints ─────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login(
      String username, String password) async {
    final result = await _post(
        '/auth/login/', {'username': username, 'password': password});
    await saveTokens(result['access'], result['refresh']);
    return result;
  }

  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirm,
    required String firstName,
    required String lastName,
    required String role,
    String? phone,
    int? region,
  }) async {
    final body = {
      'username': username,
      'email': email,
      'password': password,
      'password_confirm': passwordConfirm,
      'first_name': firstName,
      'last_name': lastName,
      'role': role,
      if (phone != null) 'phone': phone,
      if (region != null) 'region': region,
    };
    final result = await _post('/auth/register/', body);
    await saveTokens(result['access'], result['refresh']);
    return result;
  }

  static Future<void> logout() async {
    await clearTokens();
  }

  static Future<UserData> getProfile() async {
    final data = await _get('/auth/profile/');
    return UserData.fromJson(data);
  }

  static Future<UserData> updateProfile(Map<String, dynamic> updates) async {
    final data = await _put('/auth/profile/', updates);
    return UserData.fromJson(data);
  }

  // ── Dashboard ─────────────────────────────────────────────────────────────
  static Future<DashboardData> getDashboard() async {
    final data = await _get('/dashboard/');
    return DashboardData.fromJson(data);
  }

  /// Météo backend (nécessite connexion + région profil). Retourne null si indisponible.
  static Future<Map<String, dynamic>?> getBackendWeather() async {
    if (!isAuthenticated) return null;
    try {
      return await _get('/weather/');
    } catch (_) {
      return null;
    }
  }

  // ── Products ──────────────────────────────────────────────────────────────
  static Future<List<Product>> getProducts({
    int? categoryId,
    String? search,
    String? trend,
    String? availability,
    bool? isFeatured,
    int page = 1,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      if (categoryId != null) 'category': categoryId.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
      if (trend != null) 'trend': trend,
      if (availability != null) 'availability': availability,
      if (isFeatured != null) 'is_featured': isFeatured.toString(),
    };
    final query = Uri(queryParameters: params).query;
    final data = await _getList('/products/?$query');
    return (data as List).map((p) => Product.fromJson(p)).toList();
  }

  static Future<Product> getProduct(int id) async {
    final data = await _get('/products/$id/');
    return Product.fromJson(data);
  }

  static Future<Product> createProduct(Map<String, dynamic> productData) async {
    final data = await _post('/products/', productData);
    return Product.fromJson(data);
  }

  static Future<List<Map<String, dynamic>>> getProductPriceHistory(int id,
      {int days = 30}) async {
    final data = await _getList('/products/$id/price_history/?days=$days');
    return (data as List).map((p) => Map<String, dynamic>.from(p)).toList();
  }

  // ── Markets ───────────────────────────────────────────────────────────────
  static Future<List<Market>> getMarkets(
      {int? regionId, String? priceLevel}) async {
    final params = <String, String>{
      if (regionId != null) 'region': regionId.toString(),
      if (priceLevel != null) 'price_level': priceLevel,
    };
    final query = Uri(queryParameters: params).query;
    final data = await _getList('/markets/?$query');
    return (data as List).map((m) => Market.fromJson(m)).toList();
  }

  // ── Categories ────────────────────────────────────────────────────────────
  static Future<List<Category>> getCategories() async {
    final data = await _getList('/categories/');
    return (data as List).map((c) => Category.fromJson(c)).toList();
  }

  // ── Regions ───────────────────────────────────────────────────────────────
  static Future<List<Region>> getRegions() async {
    final data = await _getList('/regions/');
    return (data as List).map((r) => Region.fromJson(r)).toList();
  }

  // ── Prices ────────────────────────────────────────────────────────────────
  static Future<bool> addPrice({
    required int productId,
    required int marketId,
    required double price,
    required String date,
    String source = 'mobile',
    String? notes,
  }) async {
    await _post('/prices/', {
      'product': productId,
      'market': marketId,
      'price': price,
      'date': date,
      'source': source,
      if (notes != null) 'notes': notes,
    });
    return true;
  }

  // ── Predictions ───────────────────────────────────────────────────────────
  static Future<List<Prediction>> getPredictions(
      {int? productId, String? horizon}) async {
    final params = <String, String>{
      if (productId != null) 'product': productId.toString(),
      if (horizon != null) 'horizon': horizon,
    };
    final query = Uri(queryParameters: params).query;
    final data = await _getList('/predictions/?$query');
    return (data as List).map((p) => Prediction.fromJson(p)).toList();
  }

  static Future<Prediction> createPrediction({
    required int productId,
    int? marketId,
    String horizon = '7d',
  }) async {
    final data = await _post('/predictions/', {
      'product': productId,
      if (marketId != null) 'market': marketId,
      'horizon': horizon,
    });
    return Prediction.fromJson(data);
  }

  // ── Alerts ────────────────────────────────────────────────────────────────
  static Future<List<Alert>> getAlerts({String? status}) async {
    final params = <String, String>{
      if (status != null) 'status': status,
    };
    final query = Uri(queryParameters: params).query;
    final data = await _getList('/alerts/?$query');
    return (data as List).map((a) => Alert.fromJson(a)).toList();
  }

  static Future<Alert> createAlert({
    required int productId,
    int? marketId,
    required String alertType,
    required double thresholdPrice,
    double? changePercent,
    String? notes,
  }) async {
    final data = await _post('/alerts/', {
      'product': productId,
      if (marketId != null) 'market': marketId,
      'alert_type': alertType,
      'threshold_price': thresholdPrice,
      if (changePercent != null) 'change_percent': changePercent,
      if (notes != null) 'notes': notes,
    });
    return Alert.fromJson(data);
  }

  static Future<bool> toggleAlert(int id) async {
    await _post('/alerts/$id/toggle/', {});
    return true;
  }

  // ── Price Comparison ───────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> comparePrices(
      int productId, List<int> marketIds) async {
    final params = <String, String>{
      'product': productId.toString(),
      'markets': marketIds.join(','),
    };
    final query = Uri(queryParameters: params).query;
    final data = await _getList('/products/$productId/compare/?$query');
    return (data as List).map((p) => Map<String, dynamic>.from(p)).toList();
  }

  // ── Chatbot ─────────────────────────────────────────────────────────────────
  static Future<String> sendChatbotMessage(String message) async {
    final data = await _post('/chatbot/', {'message': message});
    return data['response'] as String;
  }

  // ── Stock Management ───────────────────────────────────────────────────────
  static Future<List<dynamic>> getStocks() async {
    final data = await _getList('/stock/');
    return data as List<dynamic>;
  }

  static Future<dynamic> createStock({
    required int productId,
    required double quantity,
    required String unit,
    String? storageLocation,
    String? purchaseDate,
    String? expiryDate,
    String? notes,
  }) async {
    final data = await _post('/stock/', {
      'product': productId,
      'quantity': quantity,
      'unit': unit,
      if (storageLocation != null) 'storage_location': storageLocation,
      if (purchaseDate != null) 'purchase_date': purchaseDate,
      if (expiryDate != null) 'expiry_date': expiryDate,
      if (notes != null) 'notes': notes,
    });
    return data;
  }

  static Future<dynamic> updateStock(int id, Map<String, dynamic> data) async {
    return await _put('/stock/$id/', data);
  }

  static Future<bool> deleteStock(int id) async {
    await _delete('/stock/$id/');
    return true;
  }

  static Future<List<dynamic>> getLowStock({double threshold = 10}) async {
    final data = await _getList('/stock/low_stock/?threshold=$threshold');
    return data as List<dynamic>;
  }

  static Future<List<dynamic>> getExpiringSoon({int days = 7}) async {
    final data = await _getList('/stock/expiring_soon/?days=$days');
    return data as List<dynamic>;
  }

  // ── Sales Management ──────────────────────────────────────────────────────
  static Future<List<dynamic>> getSales() async {
    final data = await _getList('/sales/');
    return data as List<dynamic>;
  }

  static Future<dynamic> createSale({
    required int productId,
    required double quantity,
    required String unit,
    required double unitPrice,
    required String saleDate,
    int? marketId,
    String? buyerName,
    String? paymentMethod,
    String? notes,
  }) async {
    final data = await _post('/sales/', {
      'product': productId,
      'quantity': quantity,
      'unit': unit,
      'unit_price': unitPrice,
      'sale_date': saleDate,
      if (marketId != null) 'market': marketId,
      if (buyerName != null) 'buyer_name': buyerName,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (notes != null) 'notes': notes,
    });
    return data;
  }

  static Future<bool> deleteSale(int id) async {
    await _delete('/sales/$id/');
    return true;
  }

  static Future<Map<String, dynamic>> getSalesStatistics(
      {String period = 'week'}) async {
    final data = await _getList('/sales/statistics/?period=$period');
    return data as Map<String, dynamic>;
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
