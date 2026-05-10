import 'dart:convert';
import 'package:http/http.dart' as http;

// ═══════════════════════════════════════════════════════════
//  NUTRITION SERVICE
//  • OpenFoodFacts API  (barcode + search by name)
//  • IG estimation logic
//  • Sugar / risk classification
//  • Diabetes advice system
// ═══════════════════════════════════════════════════════════

// ───────────────────────────────────────────────────────────
//  Data model
// ───────────────────────────────────────────────────────────
class FoodProduct {
  final String name;
  final String brand;
  final String imageUrl;
  final double calories;       // kcal / 100g
  final double carbohydrates;  // g / 100g
  final double sugars;         // g / 100g
  final double fat;            // g / 100g
  final double proteins;       // g / 100g
  final String? nutriScore;    // A B C D E
  final String barcode;

  const FoodProduct({
    required this.name,
    required this.brand,
    required this.imageUrl,
    required this.calories,
    required this.carbohydrates,
    required this.sugars,
    required this.fat,
    required this.proteins,
    this.nutriScore,
    this.barcode = '',
  });

  // ── Glycemic Risk  0 = low  1 = medium  2 = high
  int get glycemicRisk => NutritionLogic.estimateGlycemicRisk(
        sugars: sugars,
        carbohydrates: carbohydrates,
        nutriScore: nutriScore,
      );

  String get glycemicLabel => switch (glycemicRisk) {
        0 => '🟢 IG Faible',
        1 => '🟡 IG Modéré',
        _ => '🔴 IG Élevé',
      };

  String get glycemicAdvice => NutritionLogic.getGlycemicAdvice(glycemicRisk);

  // ── Sugar risk label
  String get sugarRiskLabel {
    if (sugars <= 5)  return '✅ Sucres faibles';
    if (sugars <= 12) return '⚠️ Sucres modérés';
    return '🚨 Sucres élevés';
  }

  // ── Convert to/from Map (Firestore)
  Map<String, dynamic> toMap() => {
        'name': name,
        'brand': brand,
        'imageUrl': imageUrl,
        'calories': calories,
        'carbohydrates': carbohydrates,
        'sugars': sugars,
        'fat': fat,
        'proteins': proteins,
        'nutriScore': nutriScore,
        'barcode': barcode,
      };

  factory FoodProduct.fromMap(Map<String, dynamic> m) => FoodProduct(
        name: m['name'] ?? '',
        brand: m['brand'] ?? '',
        imageUrl: m['imageUrl'] ?? '',
        calories: (m['calories'] as num?)?.toDouble() ?? 0,
        carbohydrates: (m['carbohydrates'] as num?)?.toDouble() ?? 0,
        sugars: (m['sugars'] as num?)?.toDouble() ?? 0,
        fat: (m['fat'] as num?)?.toDouble() ?? 0,
        proteins: (m['proteins'] as num?)?.toDouble() ?? 0,
        nutriScore: m['nutriScore'],
        barcode: m['barcode'] ?? '',
      );

  // ── Parse from OpenFoodFacts JSON product node
  factory FoodProduct.fromOFF(Map<String, dynamic> p) {
    final nutriments = p['nutriments'] as Map<String, dynamic>? ?? {};
    return FoodProduct(
      name:          _str(p['product_name']) ?? _str(p['product_name_fr']) ?? '',
      brand:         _str(p['brands']) ?? '',
      imageUrl:      _str(p['image_url']) ?? _str(p['image_front_url']) ?? '',
      calories:      _num(nutriments['energy-kcal_100g'])
                      ?? _num(nutriments['energy-kcal'])
                      ?? (_num(nutriments['energy_100g']) ?? 0) / 4.184,
      carbohydrates: _num(nutriments['carbohydrates_100g'])
                      ?? _num(nutriments['carbohydrates']) ?? 0,
      sugars:        _num(nutriments['sugars_100g'])
                      ?? _num(nutriments['sugars']) ?? 0,
      fat:           _num(nutriments['fat_100g'])
                      ?? _num(nutriments['fat']) ?? 0,
      proteins:      _num(nutriments['proteins_100g'])
                      ?? _num(nutriments['proteins']) ?? 0,
      nutriScore:    (_str(p['nutriscore_grade']) ?? _str(p['nutrition_grade_fr']))
                      ?.toUpperCase(),
      barcode:       _str(p['code']) ?? _str(p['id']) ?? '',
    );
  }

  static String? _str(dynamic v) =>
      v != null && v.toString().isNotEmpty ? v.toString().trim() : null;
  static double? _num(dynamic v) =>
      v != null ? double.tryParse(v.toString()) : null;
}

// ───────────────────────────────────────────────────────────
//  API Service  —  OpenFoodFacts
// ───────────────────────────────────────────────────────────
class NutritionService {
  static const _baseUrl = 'https://world.openfoodfacts.org';
  static const _searchUrl = 'https://world.openfoodfacts.net';
  static const _timeout = Duration(seconds: 12);

  static const _headers = {
    'User-Agent':
        'DiabeteApp/1.0 (contact@diabete-app.ma)',
  };

  // ── 1) Search by BARCODE
  static Future<FoodProduct?> searchByBarcode(String barcode) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/v0/product/$barcode.json');
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode != 200) return null;

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (json['status'] != 1) return null;

      final product = json['product'] as Map<String, dynamic>?;
      if (product == null) return null;

      return FoodProduct.fromOFF({...product, 'code': barcode});
    } catch (_) {
      return null;
    }
  }

  // ── 2) Search by NAME
  static Future<List<FoodProduct>> searchByName(String query,
      {int pageSize = 20}) async {
    try {
      final uri = Uri.parse(
        '$_searchUrl/cgi/search.pl'
        '?search_terms=${Uri.encodeComponent(query)}'
        '&search_simple=1'
        '&action=process'
        '&json=1'
        '&page_size=$pageSize'
        '&fields=product_name,product_name_fr,brands,image_url,image_front_url,'
        'nutriments,nutriscore_grade,nutrition_grade_fr,code',
      );

      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode != 200) return [];

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final products = json['products'] as List<dynamic>? ?? [];

      return products
          .whereType<Map<String, dynamic>>()
          .map(FoodProduct.fromOFF)
          .where((p) => p.name.isNotEmpty)           // skip unnamed
          .where((p) => p.calories > 0 || p.sugars > 0) // skip empty nutrition
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── 3) Search Moroccan products (language filter)
  static Future<List<FoodProduct>> searchMoroccan(String query) async {
    try {
      final uri = Uri.parse(
        '$_searchUrl/cgi/search.pl'
        '?search_terms=${Uri.encodeComponent(query)}'
        '&tagtype_0=countries&tag_contains_0=contains&tag_0=maroc'
        '&action=process&json=1&page_size=15'
        '&fields=product_name,product_name_fr,brands,image_url,'
        'nutriments,nutriscore_grade,code',
      );
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode != 200) return [];

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final products = json['products'] as List<dynamic>? ?? [];

      return products
          .whereType<Map<String, dynamic>>()
          .map(FoodProduct.fromOFF)
          .where((p) => p.name.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }
}

// ───────────────────────────────────────────────────────────
//  Nutrition Logic  —  IG estimation + diabetes analysis
// ───────────────────────────────────────────────────────────
class NutritionLogic {
  // ────────────────────────────────────────────
  //  IG Estimation (simplified algorithm)
  //
  //  Sources de référence utilisées :
  //  • Table IG internationale (Atkinson et al. 2008)
  //  • NutriScore → corrélation qualité nutritionnelle
  //  • Teneur en sucres simples / glucides totaux
  // ────────────────────────────────────────────

  /// Returns  0 = low  |  1 = medium  |  2 = high
  static int estimateGlycemicRisk({
    required double sugars,
    required double carbohydrates,
    String? nutriScore,
  }) {
    // NutriScore D/E → risque élevé
    if (nutriScore == 'D' || nutriScore == 'E') return 2;

    // Ratio sucres / glucides totaux
    final ratio = carbohydrates > 0 ? sugars / carbohydrates : 0.0;

    // Sucres absolus > 20g/100g → élevé
    if (sugars > 20) return 2;

    // Sucres 10-20g ET ratio > 60% → élevé
    if (sugars > 10 && ratio > 0.6) return 2;

    // Sucres 5-10g OU ratio 30-60% → modéré
    if (sugars > 5 || (carbohydrates > 15 && ratio > 0.3)) return 1;

    // NutriScore A/B → plutôt faible
    if (nutriScore == 'A' || nutriScore == 'B') return 0;

    // Sucres ≤ 5g → faible
    return 0;
  }

  /// Detailed IG advice for diabetics
  static String getGlycemicAdvice(int risk) => switch (risk) {
        0 => 'Ce produit a un faible impact sur la glycémie. '
            'Il peut être consommé en quantités raisonnables.',
        1 => 'Impact glycémique modéré. Consommez avec modération '
            'et combinez avec des fibres ou protéines.',
        _ => 'Impact glycémique élevé. Ce produit peut faire monter '
            'rapidement votre glycémie. À éviter ou consommer en très petite quantité.',
      };

  // ────────────────────────────────────────────
  //  Sugar analysis per portion (not per 100g)
  // ────────────────────────────────────────────

  /// Analyse sugar for a given portion (grams)
  static SugarAnalysis analyzeSugar({
    required double sugarPer100g,
    required double portionGrams,
  }) {
    final totalSugar = sugarPer100g * portionGrams / 100;

    // WHO daily limit for diabetics: ~25g added sugar
    final percentDaily = (totalSugar / 25 * 100).clamp(0, 200).toDouble();

    WarningLevel level;
    String message;

    if (totalSugar <= 5) {
      level = WarningLevel.green;
      message = 'Faible teneur en sucres pour cette portion.';
    } else if (totalSugar <= 12) {
      level = WarningLevel.yellow;
      message = 'Teneur modérée. Tenez compte dans votre suivi quotidien.';
    } else if (totalSugar <= 20) {
      level = WarningLevel.orange;
      message = 'Teneur élevée. Surveillez votre glycémie après consommation.';
    } else {
      level = WarningLevel.red;
      message = 'Teneur très élevée ! Vérifiez votre glycémie 1h30 après.';
    }

    return SugarAnalysis(
      totalSugarGrams: totalSugar,
      percentDailyLimit: percentDaily,
      level: level,
      message: message,
    );
  }

  // ────────────────────────────────────────────
  //  Daily sugar tracker
  // ────────────────────────────────────────────

  /// Check if daily sugar intake is safe
  static DailySugarStatus checkDailySugar(double totalSugarToday) {
    if (totalSugarToday < 15) {
      return DailySugarStatus(
        level: WarningLevel.green,
        message: 'Excellent ! Consommation de sucre bien contrôlée aujourd\'hui.',
        totalGrams: totalSugarToday,
      );
    } else if (totalSugarToday < 25) {
      return DailySugarStatus(
        level: WarningLevel.yellow,
        message: 'Dans les limites recommandées. Continuez à surveiller.',
        totalGrams: totalSugarToday,
      );
    } else if (totalSugarToday < 40) {
      return DailySugarStatus(
        level: WarningLevel.orange,
        message: 'Limite quotidienne dépassée. Évitez les sucreries ce soir.',
        totalGrams: totalSugarToday,
      );
    } else {
      return DailySugarStatus(
        level: WarningLevel.red,
        message: 'Consommation excessive ! Vérifiez votre glycémie et consultez si nécessaire.',
        totalGrams: totalSugarToday,
      );
    }
  }

  // ────────────────────────────────────────────
  //  Meal carb analysis (for add_meal_screen)
  // ────────────────────────────────────────────

  /// Returns true if glucides > safe threshold for diabetics
  static bool isCarbHigh(double glucidesGrams) => glucidesGrams > 60;

  /// Safe carb threshold label
  static String carbAdvice(double glucidesGrams) {
    if (glucidesGrams <= 30) return '✅ Glucides faibles — adapté pour diabétiques';
    if (glucidesGrams <= 60) return '⚠️ Glucides modérés — consommez avec précaution';
    return '🚨 Glucides élevés — surveillez votre glycémie après ce repas';
  }

  // ────────────────────────────────────────────
  //  Healthy alternatives suggestions
  // ────────────────────────────────────────────
  static List<String> getSuggestions(FoodProduct product) {
    final suggestions = <String>[];

    if (product.sugars > 15) {
      suggestions.add('🍎 Préférez des fruits frais (pomme, poire) comme alternative sucrée naturelle.');
    }
    if (product.carbohydrates > 50) {
      suggestions.add('🌾 Choisissez des céréales complètes à IG plus bas (avoine, orge).');
    }
    if (product.fat > 20) {
      suggestions.add('🥑 Optez pour des bonnes graisses : avocat, noix, huile d\'olive.');
    }
    if (product.glycemicRisk == 2) {
      suggestions.add('💧 Buvez un verre d\'eau avant de consommer ce produit pour ralentir l\'absorption du sucre.');
      suggestions.add('🥗 Associez ce produit avec des légumes verts pour réduire l\'impact glycémique.');
    }
    if (suggestions.isEmpty) {
      suggestions.add('✅ Ce produit semble adapté à une alimentation équilibrée pour diabétiques.');
    }

    return suggestions;
  }
}

// ───────────────────────────────────────────────────────────
//  Data classes
// ───────────────────────────────────────────────────────────
enum WarningLevel { green, yellow, orange, red }

class SugarAnalysis {
  final double totalSugarGrams;
  final double percentDailyLimit;
  final WarningLevel level;
  final String message;

  const SugarAnalysis({
    required this.totalSugarGrams,
    required this.percentDailyLimit,
    required this.level,
    required this.message,
  });
}

class DailySugarStatus {
  final WarningLevel level;
  final String message;
  final double totalGrams;

  const DailySugarStatus({
    required this.level,
    required this.message,
    required this.totalGrams,
  });
}