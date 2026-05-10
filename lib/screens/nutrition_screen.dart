import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../app_colors.dart';
import 'nutrition_service.dart';
import 'add_meal_screen.dart';

// ═══════════════════════════════════════════
//  NUTRITION SCREEN — 4 tabs
//  📅 Agenda  |  ➕ Ajouter  |  🔍 Recherche  |  📷 Scanner
// ═══════════════════════════════════════════
class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});
  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _searchCtrl = TextEditingController();
  String _query = '';
  bool _searching = false;
  List<FoodProduct> _results = [];
  String? _searchError;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _doSearch() async {
    if (_query.trim().isEmpty) return;
    setState(() {
      _searching = true;
      _searchError = null;
      _results = [];
    });
    final list = await NutritionService.searchByName(_query.trim());
    if (!mounted) return;
    setState(() {
      _searching = false;
      _results = list;
      if (list.isEmpty) _searchError = 'Aucun résultat pour "$_query"';
    });
  }

  void _openProduct(FoodProduct p) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.c6,
        elevation: 0,
        title: const Text('Nutrition 🍎',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 20,
                fontStyle: FontStyle.italic)),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.calendar_today_rounded, size: 17), text: 'Agenda'),
            Tab(icon: Icon(Icons.add_circle_rounded, size: 17), text: 'Ajouter'),
            Tab(icon: Icon(Icons.search_rounded, size: 17), text: 'Recherche'),
            Tab(icon: Icon(Icons.qr_code_scanner_rounded, size: 17), text: 'Scanner'),
          ],
        ),
      ),
      body: TabBarView(controller: _tab, children: [
        // Tab 1: Agenda
        _AgendaTab(),
        // Tab 2: Ajouter repas
        _AddMealInlineTab(onSaved: () => _tab.animateTo(0)),
        // Tab 3: Recherche OpenFoodFacts
        _SearchTab(
          controller: _searchCtrl,
          query: _query,
          searching: _searching,
          results: _results,
          error: _searchError,
          onQueryChanged: (v) => setState(() => _query = v),
          onSearch: _doSearch,
          onProductTap: _openProduct,
        ),
        // Tab 4: Scanner
        _ScanTab(onScanned: (barcode) async {
          _tab.animateTo(2);
          setState(() {
            _searching = true;
            _results = [];
            _searchError = null;
          });
          final product = await NutritionService.searchByBarcode(barcode);
          if (!mounted) return;
          setState(() => _searching = false);
          if (product != null) {
            _openProduct(product);
          } else {
            setState(() => _searchError = 'Produit introuvable (code: $barcode)');
          }
        }),
      ]),
    );
  }
}

// ──────────────────────────────────────────
//  TAB 1 — Agenda du jour
// ──────────────────────────────────────────
class _AgendaTab extends StatefulWidget {
  @override
  State<_AgendaTab> createState() => _AgendaTabState();
}

class _AgendaTabState extends State<_AgendaTab> {
  DateTime _day = DateTime.now();

  bool get _isToday {
    final n = DateTime.now();
    return _day.year == n.year && _day.month == n.month && _day.day == n.day;
  }

  String get _dayLabel {
    if (_isToday) return "Aujourd'hui";
    final now = DateTime.now();
    if (_day.year == now.year &&
        _day.month == now.month &&
        _day.day == now.day - 1) return 'Hier';
    const months = [
      'Jan','Fév','Mar','Avr','Mai','Jun',
      'Jul','Aoû','Sep','Oct','Nov','Déc'
    ];
    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return '${days[_day.weekday - 1]} ${_day.day} ${months[_day.month - 1]} ${_day.year}';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('Non connecté'));

    final start = DateTime(_day.year, _day.month, _day.day);
    final end = start.add(const Duration(days: 1));

    return Column(children: [
      // Date selector
      Container(
        color: AppColors.c6,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 28),
            onPressed: () =>
                setState(() => _day = _day.subtract(const Duration(days: 1))),
          ),
          Expanded(
            child: Center(
              child: Text(_dayLabel,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right_rounded,
                color: _isToday ? Colors.white30 : Colors.white, size: 28),
            onPressed: _isToday
                ? null
                : () => setState(() => _day = _day.add(const Duration(days: 1))),
          ),
        ]),
      ),
      // Meal list
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('meals')
              .where('userId', isEqualTo: user.uid)
              .where('timestamp',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(start))
              .where('timestamp', isLessThan: Timestamp.fromDate(end))
              .orderBy('timestamp')
              .snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: AppColors.c6));
            }
            if (!snap.hasData || snap.data!.docs.isEmpty) {
              return _EmptyDay(isToday: _isToday);
            }

            final docs = snap.data!.docs;
            int totalCal = 0;
            double totalGluc = 0, totalSugar = 0;
            for (final d in docs) {
              final data = d.data() as Map<String, dynamic>;
              totalCal += (data['calories'] as num?)?.toInt() ?? 0;
              totalGluc += (data['glucides'] as num?)?.toDouble() ?? 0;
              totalSugar += (data['sugar'] as num?)?.toDouble() ?? 0;
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                _DayBilan(
                    calories: totalCal,
                    glucides: totalGluc,
                    sugar: totalSugar,
                    count: docs.length),
                const SizedBox(height: 16),
                const Text('Repas de la journée',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark)),
                const SizedBox(height: 10),
                ...docs.asMap().entries.map((e) {
                  final data = e.value.data() as Map<String, dynamic>;
                  final ts = (data['timestamp'] as Timestamp?)?.toDate();
                  return _TimelineCard(
                      data: data, time: ts, isLast: e.key == docs.length - 1);
                }),
              ],
            );
          },
        ),
      ),
    ]);
  }
}

class _DayBilan extends StatelessWidget {
  final int calories, count;
  final double glucides, sugar;
  const _DayBilan(
      {required this.calories,
      required this.glucides,
      required this.sugar,
      required this.count});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [AppColors.c6, AppColors.c5],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: AppColors.c6.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.bar_chart_rounded, color: Colors.white70, size: 16),
            const SizedBox(width: 6),
            Text('Bilan ($count repas)',
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _BChip('🔥', 'Calories', '$calories kcal')),
            const SizedBox(width: 8),
            Expanded(
                child: _BChip(
                    '🌾', 'Glucides', '${glucides.toStringAsFixed(0)} g')),
            const SizedBox(width: 8),
            Expanded(
                child: _BChip('🍬', 'Sucres', '${sugar.toStringAsFixed(0)} g')),
          ]),
          if (sugar > 50) ...[
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: Colors.red.shade400,
                  borderRadius: BorderRadius.circular(10)),
              child: const Row(children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.white, size: 15),
                SizedBox(width: 6),
                Flexible(
                    child: Text('Sucres > 50g — surveillez votre glycémie',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600))),
              ]),
            ),
          ],
        ]),
      );
}

class _BChip extends StatelessWidget {
  final String em, label, value;
  const _BChip(this.em, this.label, this.value);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Text(em, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800)),
          Text(label,
              style:
                  const TextStyle(color: Colors.white70, fontSize: 10)),
        ]),
      );
}

class _TimelineCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final DateTime? time;
  final bool isLast;
  const _TimelineCard(
      {required this.data, required this.time, required this.isLast});

  String get _h => time != null
      ? '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}'
      : '--:--';

  Color get _col => switch (data['type'] as String? ?? '') {
        'Petit-déjeuner' => const Color(0xFFF57C00),
        'Déjeuner' => AppColors.c5,
        'Goûter' => Colors.purple,
        'Dîner' => const Color(0xFF1565C0),
        _ => AppColors.c4,
      };

  IconData get _ico => switch (data['type'] as String? ?? '') {
        'Petit-déjeuner' => Icons.free_breakfast_rounded,
        'Déjeuner' => Icons.lunch_dining_rounded,
        'Goûter' => Icons.cookie_rounded,
        'Dîner' => Icons.dinner_dining_rounded,
        _ => Icons.restaurant_rounded,
      };

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(
              width: 52,
              child: Column(children: [
                Text(_h,
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700, color: _col)),
                const SizedBox(height: 4),
                Container(
                    width: 10,
                    height: 10,
                    decoration:
                        BoxDecoration(color: _col, shape: BoxShape.circle)),
                if (!isLast)
                  Expanded(
                      child: Center(
                          child: Container(width: 2, color: AppColors.c3))),
              ])),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.c3, width: 1.5),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Row(children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                      color: _col.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(_ico, color: _col, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(
                          data['name'] ?? data['platName'] ?? 'Repas',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(data['type'] ?? '',
                          style: TextStyle(
                              fontSize: 11,
                              color: _col,
                              fontWeight: FontWeight.w600)),
                    ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(
                      '${(data['calories'] as num?)?.toInt() ?? 0} kcal',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.deepOrange)),
                  Text(
                      '🍬 ${((data['sugar'] as num?)?.toDouble() ?? 0).toStringAsFixed(1)}g',
                      style:
                          const TextStyle(fontSize: 10, color: Colors.blue)),
                ]),
              ]),
            ),
          ),
        ]),
      );
}

class _EmptyDay extends StatelessWidget {
  final bool isToday;
  const _EmptyDay({required this.isToday});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 70,
              height: 70,
              decoration:
                  const BoxDecoration(color: AppColors.c2, shape: BoxShape.circle),
              child: const Icon(Icons.no_meals_rounded,
                  color: AppColors.c5, size: 34),
            ),
            const SizedBox(height: 14),
            const Text('Aucun repas pour ce jour',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark)),
            const SizedBox(height: 6),
            if (isToday)
              const Text(
                  'Allez dans l\'onglet "Ajouter" pour enregistrer votre repas',
                  style:
                      TextStyle(color: AppColors.textGrey, fontSize: 13),
                  textAlign: TextAlign.center),
          ]),
        ),
      );
}

// ──────────────────────────────────────────
//  TAB 2 — Ajouter un repas (inline)
// ──────────────────────────────────────────
class _AddMealInlineTab extends StatelessWidget {
  final VoidCallback onSaved;
  const _AddMealInlineTab({required this.onSaved});

  @override
  Widget build(BuildContext context) => AddMealScreenContent(
        onSaved: onSaved,
        showAppBar: false,
      );
}

// ──────────────────────────────────────────
//  TAB 3 — Recherche OpenFoodFacts
// ──────────────────────────────────────────
class _SearchTab extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final bool searching;
  final List<FoodProduct> results;
  final String? error;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onSearch;
  final ValueChanged<FoodProduct> onProductTap;

  const _SearchTab({
    required this.controller,
    required this.query,
    required this.searching,
    required this.results,
    required this.error,
    required this.onQueryChanged,
    required this.onSearch,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) => Column(children: [
        Container(
          color: AppColors.c6,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onQueryChanged,
                onSubmitted: (_) => onSearch(),
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Ex: Nutella, lait, yaourt...',
                  hintStyle:
                      TextStyle(color: Colors.white.withOpacity(0.5)),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: Colors.white70, size: 22),
                  suffixIcon: query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: Colors.white70, size: 20),
                          onPressed: () {
                            controller.clear();
                            onQueryChanged('');
                          })
                      : null,
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.15),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: onSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.c6,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                elevation: 0,
              ),
              child: const Text('Chercher',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
        Expanded(
          child: searching
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.c6))
              : error != null
                  ? _EmptyState(message: error!)
                  : results.isEmpty
                      ? const _EmptyState(
                          icon: Icons.search_rounded,
                          message:
                              'Recherchez un produit alimentaire\npour voir ses informations nutritionnelles')
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          itemCount: results.length,
                          itemBuilder: (_, i) => _ProductCard(
                              product: results[i],
                              onTap: () => onProductTap(results[i]))),
        ),
      ]);
}

// ──────────────────────────────────────────
//  TAB 4 — Scanner
// ──────────────────────────────────────────
class _ScanTab extends StatefulWidget {
  final ValueChanged<String> onScanned;
  const _ScanTab({required this.onScanned});
  @override
  State<_ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends State<_ScanTab> {
  final MobileScannerController _ctrl = MobileScannerController();
  bool _scanned = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(children: [
        MobileScanner(
            controller: _ctrl,
            onDetect: (cap) {
              if (_scanned) return;
              final b = cap.barcodes.firstOrNull?.rawValue;
              if (b != null && b.isNotEmpty) {
                setState(() => _scanned = true);
                widget.onScanned(b);
                Future.delayed(const Duration(seconds: 2), () {
                  if (mounted) setState(() => _scanned = false);
                });
              }
            }),
        CustomPaint(
            painter: _OverlayPainter(), child: const SizedBox.expand()),
        Positioned(
          top: 40,
          left: 0,
          right: 0,
          child: Text('Pointez vers un code-barres',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  shadows: const [
                    Shadow(blurRadius: 8, color: Colors.black45)
                  ])),
        ),
        Positioned(
          bottom: 50,
          left: 0,
          right: 0,
          child: Center(
              child: IconButton(
                  onPressed: () => _ctrl.toggleTorch(),
                  icon: const Icon(Icons.flash_on_rounded,
                      color: Colors.white, size: 36))),
        ),
        if (_scanned)
          Container(
              color: Colors.black54,
              child: const Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 64),
                SizedBox(height: 12),
                Text('Code scanné !',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
              ]))),
      ]);
}

class _OverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dim = size.width * 0.65;
    final l = (size.width - dim) / 2;
    final t = (size.height - dim) / 2;
    final rect = Rect.fromLTWH(l, t, dim, dim);
    canvas.drawPath(
        Path.combine(
          PathOperation.difference,
          Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
          Path()
            ..addRRect(
                RRect.fromRectAndRadius(rect, const Radius.circular(16))),
        ),
        Paint()..color = Colors.black54);
    final p = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    const len = 30.0;
    for (final c in [
      [Offset(l, t), Offset(l + len, t), Offset(l, t + len)],
      [Offset(l + dim, t), Offset(l + dim - len, t), Offset(l + dim, t + len)],
      [Offset(l, t + dim), Offset(l + len, t + dim), Offset(l, t + dim - len)],
      [
        Offset(l + dim, t + dim),
        Offset(l + dim - len, t + dim),
        Offset(l + dim, t + dim - len)
      ],
    ]) {
      canvas.drawLine(c[1], c[0], p);
      canvas.drawLine(c[0], c[2], p);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ──────────────────────────────────────────
//  Shared: Product card / detail
// ──────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final FoodProduct product;
  final VoidCallback onTap;
  const _ProductCard({required this.product, required this.onTap});

  Color get _rc => product.glycemicRisk == 2
      ? const Color(0xFFE53935)
      : (product.glycemicRisk == 1
          ? const Color(0xFFF57C00)
          : AppColors.c5);

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.c3, width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: product.imageUrl.isNotEmpty
                  ? Image.network(product.imageUrl,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _ImgFallback())
                  : _ImgFallback(),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(
                    product.name.isNotEmpty ? product.name : 'Produit inconnu',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                if (product.brand.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(product.brand,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textGrey))
                ],
                const SizedBox(height: 8),
                Row(children: [
                  _Chip('${product.calories.round()} kcal', AppColors.c2,
                      AppColors.textDark),
                  const SizedBox(width: 6),
                  _Chip(
                      '🍬 ${product.sugars.toStringAsFixed(1)}g',
                      const Color(0xFFFFF9C4),
                      const Color(0xFF7B6000)),
                  const SizedBox(width: 6),
                  _Chip(product.glycemicLabel, _rc.withOpacity(0.12), _rc),
                ]),
              ]),
            ),
            if (product.nutriScore != null) ...[
              const SizedBox(width: 8),
              _NutriScoreBadge(grade: product.nutriScore!)
            ],
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.c4),
          ]),
        ),
      );
}

class _ImgFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
          color: AppColors.c2, borderRadius: BorderRadius.circular(10)),
      child: const Icon(Icons.fastfood_rounded, color: AppColors.c5, size: 30));
}

class _Chip extends StatelessWidget {
  final String label;
  final Color bg, fg;
  const _Chip(this.label, this.bg, this.fg);
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: fg)));
}

class _NutriScoreBadge extends StatelessWidget {
  final String grade;
  const _NutriScoreBadge({required this.grade});
  Color get _bg => switch (grade) {
        'A' => const Color(0xFF1E8F4E),
        'B' => const Color(0xFF88B931),
        'C' => const Color(0xFFF0C30F),
        'D' => const Color(0xFFE77D25),
        _ => const Color(0xFFE63E11)
      };
  @override
  Widget build(BuildContext context) => Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
          color: _bg, borderRadius: BorderRadius.circular(8)),
      child: Center(
          child: Text(grade,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900))));
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState(
      {this.icon = Icons.search_off_rounded, required this.message});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child:
              Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                  color: AppColors.c2, shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.c5, size: 40),
            ),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textGrey, fontSize: 15, height: 1.5)),
          ]),
        ),
      );
}

// ── Product Detail Screen
class ProductDetailScreen extends StatelessWidget {
  final FoodProduct product;
  const ProductDetailScreen({super.key, required this.product});

  Color get _rc => product.glycemicRisk == 2
      ? const Color(0xFFE53935)
      : (product.glycemicRisk == 1
          ? const Color(0xFFF57C00)
          : AppColors.c5);
  Color get _rb => product.glycemicRisk == 2
      ? const Color(0xFFFFEBEE)
      : (product.glycemicRisk == 1
          ? const Color(0xFFFFF8E1)
          : const Color(0xFFE8F5E9));

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: AppColors.c6,
          elevation: 0,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
              onPressed: () => Navigator.pop(context)),
          title: Text(
              product.name.isNotEmpty ? product.name : 'Produit',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Hero
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.c3, width: 1.5),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: product.imageUrl.isNotEmpty
                      ? Image.network(product.imageUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _HeroFallback())
                      : _HeroFallback(),
                ),
                const SizedBox(width: 16),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                  Text(
                      product.name.isNotEmpty
                          ? product.name
                          : 'Produit inconnu',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark)),
                  if (product.brand.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(product.brand,
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.textGrey))
                  ],
                  const SizedBox(height: 12),
                  if (product.nutriScore != null)
                    Row(children: [
                      const Text('Nutri-Score : ',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textGrey,
                              fontWeight: FontWeight.w600)),
                      _NutriScoreBadge(grade: product.nutriScore!),
                    ]),
                ])),
              ]),
            ),
            const SizedBox(height: 20),
            // IG Alert
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _rb,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: _rc.withOpacity(0.3), width: 1.5),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                        color: _rc.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.monitor_heart_rounded,
                        color: _rc, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text('Indice Glycémique estimé',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textGrey,
                            fontWeight: FontWeight.w500)),
                    Text(product.glycemicLabel,
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: _rc)),
                  ]),
                ]),
                const SizedBox(height: 10),
                Text(product.glycemicAdvice,
                    style: TextStyle(
                        fontSize: 14,
                        color: _rc.withOpacity(0.8),
                        height: 1.4)),
              ]),
            ),
            const SizedBox(height: 24),
            // Tableau nutritionnel
            _SLbl(
                icon: Icons.pie_chart_rounded,
                label: 'Valeurs nutritionnelles / 100g'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.c3, width: 1.5),
              ),
              child: Column(children: [
                _NRow(
                    label: '🔥 Calories',
                    value: '${product.calories.round()} kcal',
                    isFirst: true),
                _NRow(
                    label: '🌾 Glucides',
                    value:
                        '${product.carbohydrates.toStringAsFixed(1)} g'),
                _NRow(
                    label: '🍬 dont Sucres',
                    value: '${product.sugars.toStringAsFixed(1)} g',
                    indent: true),
                _NRow(
                    label: '🥑 Graisses',
                    value: '${product.fat.toStringAsFixed(1)} g'),
                _NRow(
                    label: '💪 Protéines',
                    value: '${product.proteins.toStringAsFixed(1)} g',
                    isLast: true),
              ]),
            ),
            const SizedBox(height: 24),
            _SLbl(
                icon: Icons.tips_and_updates_rounded,
                label: 'Conseils diabète'),
            const SizedBox(height: 12),
            _TipCard(
                icon: Icons.info_outline_rounded,
                color: AppColors.c6,
                text:
                    'Informations pour 100g. Adaptez selon votre portion réelle.'),
            const SizedBox(height: 8),
            if (product.sugars > 15)
              _TipCard(
                  icon: Icons.warning_amber_rounded,
                  color: const Color(0xFFE53935),
                  text:
                      'Teneur en sucres élevée (${product.sugars.toStringAsFixed(1)}g/100g). Surveillez votre glycémie.'),
            if (product.sugars <= 5)
              _TipCard(
                  icon: Icons.check_circle_outline_rounded,
                  color: AppColors.c5,
                  text:
                      'Teneur en sucres faible. Produit adapté aux diabétiques en portions normales.'),
            const SizedBox(height: 8),
            _TipCard(
                icon: Icons.access_time_rounded,
                color: const Color(0xFF1565C0),
                text:
                    'Mesurez votre glycémie 1h30 à 2h après le repas pour suivre l\'impact réel.'),
          ]),
        ),
      );
}

class _HeroFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
          color: AppColors.c2, borderRadius: BorderRadius.circular(14)),
      child:
          const Icon(Icons.fastfood_rounded, color: AppColors.c5, size: 48));
}

class _SLbl extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SLbl({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 18, color: AppColors.c6),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark)),
      ]);
}

class _NRow extends StatelessWidget {
  final String label, value;
  final bool isFirst, isLast, indent;
  const _NRow(
      {required this.label,
      required this.value,
      this.isFirst = false,
      this.isLast = false,
      this.indent = false});
  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.fromLTRB(indent ? 32 : 16, 14, 16, 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: AppColors.c2, width: 1)),
          borderRadius: isFirst
              ? const BorderRadius.vertical(top: Radius.circular(14))
              : (isLast
                  ? const BorderRadius.vertical(bottom: Radius.circular(14))
                  : BorderRadius.zero),
        ),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
          Text(label,
              style: TextStyle(
                  fontSize: 14,
                  color: indent ? AppColors.textGrey : AppColors.textDark,
                  fontWeight:
                      indent ? FontWeight.w500 : FontWeight.w700)),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark)),
        ]),
      );
}

class _TipCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _TipCard(
      {required this.icon, required this.color, required this.text});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 13,
                      color: color,
                      height: 1.4,
                      fontWeight: FontWeight.w500))),
        ]),
      );
}