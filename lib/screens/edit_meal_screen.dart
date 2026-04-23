import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../meal_store.dart';

const _platsMarocains2 = [
  ('Couscous',         '🫕', 23.2),
  ('Tajine de poulet', '🍲', 8.5),
  ('Harira',           '🥣', 12.4),
  ('Pastilla',         '🥧', 28.6),
  ('Msemen',           '🫓', 41.0),
  ('Briouates',        '🥟', 22.0),
  ('Rfissa',           '🍛', 19.8),
  ('Zaalouk',          '🍆', 7.3),
  ('Pain marocain',    '🍞', 49.5),
  ('Sellou',           '🍯', 55.0),
];

const _typeRepas2 = [
  ('Petit-déjeuner', Icons.free_breakfast_rounded),
  ('Déjeuner',       Icons.lunch_dining_rounded),
  ('Goûter',         Icons.cookie_rounded),
  ('Dîner',          Icons.dinner_dining_rounded),
];

class EditMealScreen extends StatefulWidget {
  final MealEntry meal;
  const EditMealScreen({super.key, required this.meal});
  @override
  State<EditMealScreen> createState() => _EditMealScreenState();
}

class _EditMealScreenState extends State<EditMealScreen> {
  late int    _typeIndex;
  late String _platName;
  late String _platEmoji;
  late double _glucidesPer100g;
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
    final plat = _platsMarocains2.firstWhere(
      (p) => p.$1 == widget.meal.platName,
      orElse: () => _platsMarocains2.first,
    );
    _platName       = plat.$1;
    _platEmoji      = plat.$2;
    _glucidesPer100g = plat.$3;
    _qtyController  = TextEditingController(text: widget.meal.quantite.toStringAsFixed(0));
  }

  @override
  void dispose() { _qtyController.dispose(); super.dispose(); }

  double get _quantite    => double.tryParse(_qtyController.text) ?? 0;
  double get _glucidesTotal => _glucidesPer100g * _quantite / 100;
  bool   get _isHighCarb   => _glucidesTotal > 60;

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final (typeLabel, typeIcon) = _typeRepas2[_typeIndex];
    final calories = (_glucidesPer100g * 4 * _quantite / 100 + _quantite * 1.5).round();

    final updated = widget.meal.copyWith(
      type:      typeLabel,
      iconName:  MealEntry.iconNameOf(typeIcon),
      platName:  _platName,
      platEmoji: _platEmoji,
      glucides:  _glucidesTotal,
      quantite:  _quantite,
      calories:  calories,
    );

    await MealStore.instance.update(updated);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.c6, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Modifier le repas',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic, fontSize: 20)),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Glucides card
            _buildGlucidesCard(),
            const SizedBox(height: 24),

            // Type
            _sectionLabel(Icons.schedule_rounded, 'Type de repas'),
            const SizedBox(height: 10),
            _buildTypeSelector(),
            const SizedBox(height: 24),

            // Plat
            _sectionLabel(Icons.restaurant_rounded, 'Plat marocain'),
            const SizedBox(height: 10),
            _buildPlatSelector(),
            const SizedBox(height: 24),

            // Quantité
            _sectionLabel(Icons.scale_rounded, 'Quantité (grammes)'),
            const SizedBox(height: 10),
            _buildQtyField(),
            const SizedBox(height: 32),

            // Bouton
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.c6, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 3),
                onPressed: _saving ? null : _handleSave,
                icon: _saving
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Icon(Icons.check_rounded, size: 22),
                label: Text(_saving ? 'Enregistrement...' : 'Enregistrer les modifications',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              )),
          ]),
        ),
      ),
    );
  }

  Widget _buildGlucidesCard() {
    final color = _isHighCarb ? const Color(0xFFE65100) : AppColors.c6;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _isHighCarb ? const Color(0xFFFFCC80) : AppColors.c3, width: 1.5),
      ),
      child: Row(children: [
        Container(width: 46, height: 46,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.local_fire_department_rounded, color: color, size: 24)),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Glucides estimés', style: TextStyle(fontSize: 13, color: color.withOpacity(0.7))),
          Text('${_glucidesTotal.toStringAsFixed(1)} g',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: color)),
        ]),
        const Spacer(),
        if (_isHighCarb)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: const Color(0xFFFFCC80), borderRadius: BorderRadius.circular(20)),
            child: const Text('⚠️ Élevé',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFE65100))),
          ),
      ]),
    );
  }

  Widget _sectionLabel(IconData icon, String label) => Row(children: [
    Icon(icon, size: 16, color: AppColors.c6),
    const SizedBox(width: 6),
    Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
  ]);

  Widget _buildTypeSelector() {
    return Wrap(spacing: 8, runSpacing: 8,
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
              border: Border.all(color: active ? AppColors.c6 : AppColors.c3, width: 1.5),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 22, color: active ? Colors.white : AppColors.c5),
              const SizedBox(height: 4),
              Text(label, textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      color: active ? Colors.white : AppColors.textGrey)),
            ]),
          ),
        );
      }),
    );
  }

  Widget _buildPlatSelector() {
    return Wrap(spacing: 8, runSpacing: 8,
      children: _platsMarocains2.map((p) {
        final active = p.$1 == _platName;
        return GestureDetector(
          onTap: () => setState(() {
            _platName        = p.$1;
            _platEmoji       = p.$2;
            _glucidesPer100g = p.$3;
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: active ? AppColors.c6 : Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: active ? AppColors.c6 : AppColors.c3, width: 1.5),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(p.$2, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(p.$1, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: active ? Colors.white : AppColors.textDark)),
              const SizedBox(width: 6),
              Text('${p.$3}g/100g', style: TextStyle(fontSize: 10,
                  color: active ? Colors.white.withOpacity(0.7) : AppColors.textGrey)),
            ]),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQtyField() {
    return TextFormField(
      controller: _qtyController,
      keyboardType: const TextInputType.numberWithOptions(decimal: false),
      onChanged: (_) => setState(() {}),
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark),
      decoration: InputDecoration(
        filled: true, fillColor: Colors.white,
        hintText: 'Ex : 200',
        suffixText: 'g',
        suffixStyle: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.c5, fontSize: 16),
        prefixIcon: const Icon(Icons.scale_rounded, color: AppColors.c5, size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.c3)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.c3, width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
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
