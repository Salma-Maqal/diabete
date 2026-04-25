import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../meal_store.dart';

// ─────────────────────────────────────────
// Data model (avec imageUrl)
// ─────────────────────────────────────────
class _Plat2 {
  final String name;
  final String emoji;
  final String imageUrl;
  final double glucidesPer100g;
  const _Plat2(this.name, this.emoji, this.imageUrl, this.glucidesPer100g);
}

const _platsMarocains2 = [
  _Plat2('Couscous',         '🫕', 'assets/images/couscous.jpg',      23.2),
  _Plat2('Tajine de poulet', '🍲', 'assets/images/tajine_poulet.jpg', 8.5),
  _Plat2('Harira',           '🥣', 'assets/images/harira.jpg',        12.4),
  _Plat2('Pastilla',         '🥧', 'assets/images/pastilla.jpg',      28.6),
  _Plat2('Msemen',           '🫓', 'assets/images/msemen.jpg',        41.0),
  _Plat2('Briouates',        '🥟', 'assets/images/briouates.jpg',     22.0),
  _Plat2('Rfissa',           '🍛', 'assets/images/rfissa.jpg',        19.8),
  _Plat2('Zaalouk',          '🍆', 'assets/images/zaalouk.jpg',       7.3),
  _Plat2('Pain marocain',    '🍞', 'assets/images/pain_marocain.jpg', 49.5),
  _Plat2('Sellou',           '🍯', 'assets/images/sellou.jpg',        55.0),
];

const _typeRepas2 = [
  ('Petit-déjeuner', Icons.free_breakfast_rounded),
  ('Déjeuner',       Icons.lunch_dining_rounded),
  ('Goûter',         Icons.cookie_rounded),
  ('Dîner',          Icons.dinner_dining_rounded),
];

// ─────────────────────────────────────────
// Screen
// ─────────────────────────────────────────
class EditMealScreen extends StatefulWidget {
  final MealEntry meal;
  const EditMealScreen({super.key, required this.meal});
  @override
  State<EditMealScreen> createState() => _EditMealScreenState();
}

class _EditMealScreenState extends State<EditMealScreen> {
  late int     _typeIndex;
  late _Plat2  _selectedPlat;
  late TextEditingController _qtyController;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Retrouver l'index du type
    _typeIndex = _typeRepas2.indexWhere((t) => t.$1 == widget.meal.type);
    if (_typeIndex < 0) _typeIndex = 0;
    // Retrouver le plat
    _selectedPlat = _platsMarocains2.firstWhere(
      (p) => p.name == widget.meal.platName,
      orElse: () => _platsMarocains2.first,
    );
    _qtyController = TextEditingController(
        text: widget.meal.quantite.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  double get _quantite      => double.tryParse(_qtyController.text) ?? 0;
  double get _glucidesTotal => _selectedPlat.glucidesPer100g * _quantite / 100;
  bool   get _isHighCarb    => _glucidesTotal > 60;

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final (typeLabel, typeIcon) = _typeRepas2[_typeIndex];
    final calories = (_selectedPlat.glucidesPer100g * 4 * _quantite / 100 +
                      _quantite * 1.5).round();

    final updated = widget.meal.copyWith(
      type:      typeLabel,
      iconName:  MealEntry.iconNameOf(typeIcon),
      platName:  _selectedPlat.name,
      platEmoji: _selectedPlat.emoji,
      glucides:  _glucidesTotal,
      quantite:  _quantite,
      calories:  calories,
    );

    await MealStore.instance.update(updated);
    if (mounted) Navigator.pop(context, true);
  }

  // ─────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.c6,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Modifier le repas',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
              fontSize: 20),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Glucides card
            _buildGlucidesCard(),
            const SizedBox(height: 24),

            // ── Type de repas
            _sectionLabel(Icons.schedule_rounded, 'Type de repas'),
            const SizedBox(height: 10),
            _buildTypeSelector(),
            const SizedBox(height: 24),

            // ── Plat marocain (avec recherche + images)
            _sectionLabel(Icons.restaurant_rounded, 'Plat marocain'),
            const SizedBox(height: 10),
            _PlatSelectorEdit(
              selected: _selectedPlat,
              // Pré-remplir la search avec le plat actuel
              initialQuery: _selectedPlat.name,
              onSelect: (p) => setState(() => _selectedPlat = p),
            ),
            const SizedBox(height: 24),

            // ── Quantité
            _sectionLabel(Icons.scale_rounded, 'Quantité (grammes)'),
            const SizedBox(height: 10),
            _buildQtyField(),
            const SizedBox(height: 32),

            // ── Bouton Enregistrer
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.c6,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 3),
                onPressed: _saving ? null : _handleSave,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : const Icon(Icons.check_rounded, size: 22),
                label: Text(
                    _saving
                        ? 'Enregistrement...'
                        : 'Enregistrer les modifications',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Glucides card
  Widget _buildGlucidesCard() {
    final color = _isHighCarb ? const Color(0xFFE65100) : AppColors.c6;
    final pct   = (_glucidesTotal / 60).clamp(0.0, 1.0);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _isHighCarb ? const Color(0xFFFFF3E0) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: _isHighCarb ? const Color(0xFFFFCC80) : AppColors.c3,
            width: 1.5),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.local_fire_department_rounded, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Glucides estimés',
                  style: TextStyle(
                      fontSize: 13,
                      color: color.withOpacity(0.7),
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              RichText(
                text: TextSpan(children: [
                  TextSpan(
                      text: _glucidesTotal.toStringAsFixed(1),
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: color)),
                  TextSpan(
                      text: ' g',
                      style: TextStyle(
                          fontSize: 16, color: color.withOpacity(0.6))),
                ]),
              ),
            ]),
          ),
          if (_isHighCarb)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: const Color(0xFFFFCC80),
                  borderRadius: BorderRadius.circular(20)),
              child: const Text('⚠️ Élevé',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE65100))),
            ),
        ]),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: color.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('0 g',
              style: TextStyle(fontSize: 12, color: color.withOpacity(0.5))),
          Text('Seuil : 60 g',
              style: TextStyle(
                  fontSize: 12,
                  color: color.withOpacity(0.6),
                  fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }

  // ── Section label
  Widget _sectionLabel(IconData icon, String label) => Row(children: [
        Icon(icon, size: 16, color: AppColors.c6),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark)),
      ]);

  // ── Type selector
  Widget _buildTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(_typeRepas2.length, (i) {
        final (label, icon) = _typeRepas2[i];
        final active = i == _typeIndex;
        return GestureDetector(
          onTap: () => setState(() => _typeIndex = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: (MediaQuery.of(context).size.width - 56) / 3,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: active ? AppColors.c6 : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: active ? AppColors.c6 : AppColors.c3, width: 1.5),
              boxShadow: active
                  ? [
                      BoxShadow(
                          color: AppColors.c6.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3))
                    ]
                  : [],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon,
                  size: 22, color: active ? Colors.white : AppColors.c5),
              const SizedBox(height: 4),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: active ? Colors.white : AppColors.textGrey)),
            ]),
          ),
        );
      }),
    );
  }

  // ── Quantité field
  Widget _buildQtyField() {
    return TextFormField(
      controller: _qtyController,
      keyboardType: const TextInputType.numberWithOptions(decimal: false),
      onChanged: (_) => setState(() {}),
      style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: 'Ex : 200',
        suffixText: 'g',
        suffixStyle: const TextStyle(
            fontWeight: FontWeight.w700, color: AppColors.c5, fontSize: 16),
        prefixIcon:
            const Icon(Icons.scale_rounded, color: AppColors.c5, size: 20),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.c3)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.c3, width: 1.5)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.c6, width: 2)),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Entrez une quantité';
        final n = double.tryParse(v);
        if (n == null || n <= 0) return 'Quantité invalide';
        return null;
      },
    );
  }
}

// ─────────────────────────────────────────
// Plat Selector avec recherche + images
// (identique à add_meal_screen mais avec initialQuery
//  pour pré-remplir le plat existant)
// ─────────────────────────────────────────
class _PlatSelectorEdit extends StatefulWidget {
  final _Plat2          selected;
  final String          initialQuery;
  final ValueChanged<_Plat2> onSelect;
  const _PlatSelectorEdit({
    required this.selected,
    required this.initialQuery,
    required this.onSelect,
  });

  @override
  State<_PlatSelectorEdit> createState() => _PlatSelectorEditState();
}

class _PlatSelectorEditState extends State<_PlatSelectorEdit> {
  late TextEditingController _searchController;
  late String _query;

  @override
  void initState() {
    super.initState();
    // Pré-remplir avec le nom du plat actuel
    _query = widget.initialQuery;
    _searchController = TextEditingController(text: _query);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Liste vide si rien tapé, filtrée sinon
    final filtered = _query.trim().isEmpty
        ? <_Plat2>[]
        : _platsMarocains2
            .where((p) =>
                p.name.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return Column(
      children: [
        // ── Barre de recherche
        TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _query = v),
          style:
              const TextStyle(fontSize: 15, color: AppColors.textDark),
          decoration: InputDecoration(
            hintText: 'Rechercher un plat...',
            hintStyle: const TextStyle(color: AppColors.textGrey),
            prefixIcon: const Icon(Icons.search_rounded,
                color: AppColors.c5, size: 22),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textGrey, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.c3),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.c3, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.c6, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── Affichage conditionnel
        if (_query.trim().isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                      color: AppColors.c2, shape: BoxShape.circle),
                  child: const Icon(Icons.search_rounded,
                      color: AppColors.c5, size: 36),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Recherchez un plat pour voir les résultats',
                  style: TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Ex: Couscous, Harira, Tajine...',
                  style: TextStyle(
                      color: AppColors.textGrey, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                const Icon(Icons.search_off_rounded,
                    color: AppColors.textGrey, size: 40),
                const SizedBox(height: 8),
                Text(
                  'Aucun plat trouvé pour "$_query"',
                  style: const TextStyle(
                      color: AppColors.textGrey, fontSize: 14),
                ),
              ],
            ),
          )
        else
          ...filtered.map((p) {
            final active = widget.selected.name == p.name;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => widget.onSelect(p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: active ? AppColors.c6 : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: active ? AppColors.c6 : AppColors.c3,
                        width: active ? 2.5 : 1.5),
                    boxShadow: active
                        ? [
                            BoxShadow(
                                color: AppColors.c6.withOpacity(0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4))
                          ]
                        : [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 6,
                                offset: const Offset(0, 2))
                          ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Image du plat
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
                        child: Stack(
                          children: [
                            Image.asset(
                              p.imageUrl,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 180,
                                color: AppColors.c2,
                                child: Center(
                                  child: Text(p.emoji,
                                      style: const TextStyle(
                                          fontSize: 36)),
                                ),
                              ),
                            ),
                            if (active)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle),
                                  child: const Icon(
                                      Icons.check_circle_rounded,
                                      color: AppColors.c6,
                                      size: 22),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Infos du plat
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(p.name,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: active
                                        ? Colors.white
                                        : AppColors.textDark)),
                            Text('${p.glucidesPer100g} g/100g',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: active
                                        ? Colors.white.withOpacity(0.75)
                                        : AppColors.textGrey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}