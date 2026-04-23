import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────
// MealEntry model
// ─────────────────────────────────────────
class MealEntry {
  final String   id;        // unique key
  final String   type;
  final String   iconName;
  final String   platName;
  final String   platEmoji;
  final double   glucides;
  final double   quantite;
  final int      calories;
  final DateTime addedAt;

  MealEntry({
    String? id,
    required this.type,
    required this.iconName,
    required this.platName,
    required this.platEmoji,
    required this.glucides,
    required this.quantite,
    required this.calories,
    required this.addedAt,
  }) : id = id ?? '${addedAt.millisecondsSinceEpoch}';

  static const _iconMap = <String, IconData>{
    'free_breakfast': Icons.free_breakfast_rounded,
    'lunch_dining':   Icons.lunch_dining_rounded,
    'cookie':         Icons.cookie_rounded,
    'dinner_dining':  Icons.dinner_dining_rounded,
    'apple':          Icons.apple_rounded,
  };

  IconData get icon => _iconMap[iconName] ?? Icons.restaurant_rounded;

  static String iconNameOf(IconData icon) =>
      _iconMap.entries.firstWhere(
        (e) => e.value == icon,
        orElse: () => const MapEntry('restaurant', Icons.restaurant_rounded),
      ).key;

  String get timeLabel {
    final h = addedAt.hour.toString().padLeft(2, '0');
    final m = addedAt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get dateKey =>
      '${addedAt.year}-${addedAt.month.toString().padLeft(2,'0')}-${addedAt.day.toString().padLeft(2,'0')}';

  MealEntry copyWith({
    String? type, String? iconName, String? platName, String? platEmoji,
    double? glucides, double? quantite, int? calories,
  }) => MealEntry(
    id: id, addedAt: addedAt,
    type:      type      ?? this.type,
    iconName:  iconName  ?? this.iconName,
    platName:  platName  ?? this.platName,
    platEmoji: platEmoji ?? this.platEmoji,
    glucides:  glucides  ?? this.glucides,
    quantite:  quantite  ?? this.quantite,
    calories:  calories  ?? this.calories,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'type': type, 'iconName': iconName,
    'platName': platName, 'platEmoji': platEmoji,
    'glucides': glucides, 'quantite': quantite,
    'calories': calories, 'addedAt': addedAt.toIso8601String(),
  };

  factory MealEntry.fromJson(Map<String, dynamic> j) => MealEntry(
    id:        j['id']        as String?,
    type:      j['type']      as String,
    iconName:  j['iconName']  as String,
    platName:  j['platName']  as String,
    platEmoji: j['platEmoji'] as String,
    glucides:  (j['glucides'] as num).toDouble(),
    quantite:  (j['quantite'] as num).toDouble(),
    calories:  j['calories']  as int,
    addedAt:   DateTime.parse(j['addedAt'] as String),
  );
}

// ─────────────────────────────────────────
// WaterEntry model — كاسات الماء
// ─────────────────────────────────────────
class WaterEntry {
  final String dateKey;
  final int    glasses; // 0-8

  const WaterEntry({required this.dateKey, required this.glasses});

  Map<String, dynamic> toJson() => {'dateKey': dateKey, 'glasses': glasses};
  factory WaterEntry.fromJson(Map<String, dynamic> j) =>
      WaterEntry(dateKey: j['dateKey'] as String, glasses: j['glasses'] as int);
}

// ─────────────────────────────────────────
// MealStore — persistant via SharedPreferences
// ─────────────────────────────────────────
class MealStore {
  MealStore._();
  static final MealStore instance = MealStore._();

  static const _mealsKey = 'meal_entries_v2';
  static const _waterKey = 'water_entries_v1';

  final List<MealEntry>          _meals  = [];
  final Map<String, WaterEntry>  _water  = {};
  bool _loaded = false;

  // ── Load
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();

      // meals
      final rawMeals = prefs.getString(_mealsKey);
      if (rawMeals != null && rawMeals.isNotEmpty) {
        final list = jsonDecode(rawMeals) as List<dynamic>;
        _meals.addAll(list.map((e) => MealEntry.fromJson(e as Map<String, dynamic>)));
      }

      // water
      final rawWater = prefs.getString(_waterKey);
      if (rawWater != null && rawWater.isNotEmpty) {
        final list = jsonDecode(rawWater) as List<dynamic>;
        for (final e in list) {
          final w = WaterEntry.fromJson(e as Map<String, dynamic>);
          _water[w.dateKey] = w;
        }
      }
    } catch (_) {}
  }

  Future<void> _saveMeals() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mealsKey, jsonEncode(_meals.map((m) => m.toJson()).toList()));
  }

  Future<void> _saveWater() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_waterKey, jsonEncode(_water.values.map((w) => w.toJson()).toList()));
  }

  // ── CRUD Meals
  Future<void> add(MealEntry entry) async {
    _meals.add(entry);
    await _saveMeals();
  }

  Future<void> update(MealEntry updated) async {
    final idx = _meals.indexWhere((m) => m.id == updated.id);
    if (idx != -1) { _meals[idx] = updated; await _saveMeals(); }
  }

  Future<void> delete(String id) async {
    _meals.removeWhere((m) => m.id == id);
    await _saveMeals();
  }

  // ── Water
  int glassesForDate(String dateKey) => _water[dateKey]?.glasses ?? 0;

  Future<void> setWater(String dateKey, int glasses) async {
    _water[dateKey] = WaterEntry(dateKey: dateKey, glasses: glasses);
    await _saveWater();
  }

  // ── Queries
  List<MealEntry> get all => List.unmodifiable(_meals);

  List<MealEntry> forDate(String dateKey) {
    final list = _meals.where((m) => m.dateKey == dateKey).toList();
    list.sort((a, b) => a.addedAt.compareTo(b.addedAt));
    return list;
  }

  int caloriesForDate(String dateKey) =>
      forDate(dateKey).fold(0, (s, m) => s + m.calories);

  static String keyOf(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
}
