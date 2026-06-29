import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/food_product.dart';

/// Поиск продуктов через Open Food Facts API.
class OpenFoodFactsService {
  OpenFoodFactsService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _baseUrl = 'https://world.openfoodfacts.org';
  static const _userAgent = 'SugarBalance/1.0 (Flutter; diabetes diary)';

  /// Поиск по названию (рус/англ). Минимум 2 символа.
  Future<List<FoodProductSearchHit>> search(String query) async {
    final q = query.trim();
    if (q.length < 2) return [];

    final uri = Uri.parse('$_baseUrl/cgi/search.pl').replace(
      queryParameters: {
        'search_terms': q,
        'search_simple': '1',
        'action': 'process',
        'json': '1',
        'page_size': '20',
        'fields': 'code,product_name,nutriments',
        'lc': 'ru',
      },
    );

    final response = await _client.get(
      uri,
      headers: {'User-Agent': _userAgent, 'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw OpenFoodFactsException(
        'Сервер вернул код ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw OpenFoodFactsException('Некорректный ответ API');
    }

    final products = decoded['products'];
    if (products is! List) return [];

    final hits = <FoodProductSearchHit>[];
    for (final raw in products) {
      if (raw is! Map<String, dynamic>) continue;
      final hit = _parseProduct(raw);
      if (hit != null) hits.add(hit);
    }
    return hits;
  }

  FoodProductSearchHit? _parseProduct(Map<String, dynamic> raw) {
    final name = (raw['product_name'] as String?)?.trim();
    if (name == null || name.isEmpty) return null;

    final code = raw['code']?.toString() ?? '';
    double? carbs;
    final nutriments = raw['nutriments'];
    if (nutriments is Map<String, dynamic>) {
      carbs = _readNum(nutriments['carbohydrates_100g']) ??
          _readNum(nutriments['carbohydrates']);
    }

    return FoodProductSearchHit(
      code: code,
      name: name,
      carbsPer100g: carbs,
    );
  }

  double? _readNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '.'));
    return null;
  }

  void dispose() => _client.close();
}

class OpenFoodFactsException implements Exception {
  OpenFoodFactsException(this.message);
  final String message;

  @override
  String toString() => message;
}
