import 'package:flutter/material.dart';
import '../app_colors.dart';

// ─────────────────────────────────────────
// Data model
// ─────────────────────────────────────────
class _Plat {
  final String name;
  final String emoji;
  final double glucidesPer100g; // g de glucides / 100 g
  const _Plat(this.name, this.emoji, this.glucidesPer100g);
}

const _platsMarocains = [
  _Plat('Couscous',         '🫕', 23.2),
  _Plat('Tajine de poulet', '🍲', 8.5),
  _Plat('Harira',           '🥣', 12.4),
  _Plat('Pastilla',         '🥧', 28.6),
  _Plat('Msemen',           '🫓', 41.0),
  _Plat('Briouates',        '🥟', 22.0),
  _Plat('Rfissa',           '🍛', 19.8),
  _Plat('Zaalouk',          '🍆', 7.3),
  _Plat('Pain marocain',    '🍞', 49.5),
  _Plat('Sellou',           '🍯', 55.0),
];

const _typeRepas = [
  ('Petit-déjeuner', Icons.free_breakfast_rounded),
  ('Déjeuner',       Icons.lunch_dining_rounded),
  ('Goûter',         Icons.cookie_rounded),
  ('Dîner',          Icons.dinner_dining_rounded),
];

// ─────────────────────────────────────────
// Screen
// ─────────────────────────────────────────
class AddMealScreen extends StatefulWidget {
  const AddMealScreen({super.key});
  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen>
    with SingleTickerProviderStateMixin {
  // form state
  int _typeIndex = 0;
  _Plat? _selectedPlat;
  final _qtyController = TextEditingController(text: '200');
  final _formKey = GlobalKey<FormState>();

  // UI state
  bool _saving = false;
  bool _saved = false;
  int  _glasses = 0;

  // computed
  double get _quantite => double.tryParse(_qtyController.text) ?? 0;
  double get _glucidesTotal =>
      _selectedPlat != null ? (_selectedPlat!.glucidesPer100g * _quantite / 100) : 0;
  bool get _isHighCarb => _glucidesTotal > 60;

  // ── Step 7 → 8 : save after optional confirmation
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPlat == null) {
      _snack('Veuillez sélectionner un plat.', isError: true);
      return;
    }

    // Step I : alert if > 60 g glucides
    if (_isHighCarb) {
      final confirmed = await _showHighCarbDialog();
      if (!mounted) return;
      if (!confirmed) return; // user cancelled → back to form
    }

    // Step M : save
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 900)); // simulate DB write
    if (!mounted) return;
    setState(() {
      _saving = false;
      _saved  = true;
    });

    // Step O : success message
    _snack('✅ Repas enregistré avec succès !');

    // Step Q : go back to dashboard (update history)
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) Navigator.pop(context, true); // pass true → dashboard refreshes
  }

  Future<bool> _showHighCarbDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => _HighCarbDialog(
            platName: _selectedPlat!.name,
            glucides: _glucidesTotal,
          ),
        ) ??
        false;
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: isError ? AppColors.error : AppColors.c6,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
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
          'Ajouter un repas',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── Glucides summary card (live)
            _GlucidesCard(
              glucides: _glucidesTotal,
              platName: _selectedPlat?.name,
              quantite: _quantite,
              isHigh: _isHighCarb,
            ),

            const SizedBox(height: 28),

            // ── Step D : Type de repas
            _SectionLabel(
              icon: Icons.schedule_rounded,
              label: 'Type de repas',
            ),
            const SizedBox(height: 10),
            _MealTypeSelector(
              selected: _typeIndex,
              onSelect: (i) => setState(() => _typeIndex = i),
            ),

            const SizedBox(height: 24),

            // ── Step E : Plat marocain
            _SectionLabel(
              icon: Icons.restaurant_rounded,
              label: 'Plat marocain',
            ),
            const SizedBox(height: 10),
            _PlatSelector(
              selected: _selectedPlat,
              onSelect: (p) => setState(() => _selectedPlat = p),
            ),

            const SizedBox(height: 24),

            // ── Step F : Quantité
            _SectionLabel(
              icon: Icons.scale_rounded,
              label: 'Quantité (grammes)',
            ),
            const SizedBox(height: 10),
            _QuantiteField(
              controller: _qtyController,
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 36),

            // ── Eau
            _SectionLabel(
              icon: Icons.water_drop_rounded,
              label: 'Eau consommée',
            ),
            const SizedBox(height: 10),
            _EauSelector(
              glasses: _glasses,
              onChanged: (v) => setState(() => _glasses = v),
            ),

            const SizedBox(height: 28),

            // ── Step G : Bouton Enregistrer
            _SaveButton(
              saving: _saving,
              saved: _saved,
              onTap: _handleSave,
            ),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Live Glucides Summary Card
// ─────────────────────────────────────────
class _GlucidesCard extends StatelessWidget {
  final double glucides;
  final String? platName;
  final double quantite;
  final bool isHigh;
  const _GlucidesCard({
    required this.glucides,
    required this.platName,
    required this.quantite,
    required this.isHigh,
  });

  @override
  Widget build(BuildContext context) {
    final color = isHigh ? const Color(0xFFE65100) : AppColors.c6;
    final bgColor = isHigh ? const Color(0xFFFFF3E0) : Colors.white;
    final borderColor = isHigh ? const Color(0xFFFFCC80) : AppColors.c3;
    final pct = (glucides / 60).clamp(0.0, 1.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.5),
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
            width: 42,
            height: 42,
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
                      fontSize: 12,
                      color: color.withOpacity(0.7),
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: glucides.toStringAsFixed(1),
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: color),
                    ),
                    TextSpan(
                      text: ' g',
                      style: TextStyle(
                          fontSize: 14, color: color.withOpacity(0.6)),
                    ),
                  ],
                ),
              ),
            ]),
          ),
          if (isHigh)
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
        // Progress bar
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
              style: TextStyle(fontSize: 10, color: color.withOpacity(0.5))),
          Text('Seuil : 60 g',
              style: TextStyle(
                  fontSize: 10,
                  color: color.withOpacity(0.6),
                  fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────
// Section label
// ─────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionLabel({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 16, color: AppColors.c6),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark)),
      ]);
}

// ─────────────────────────────────────────
// Meal type selector
// ─────────────────────────────────────────
class _MealTypeSelector extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  const _MealTypeSelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(_typeRepas.length, (i) {
        final (label, icon) = _typeRepas[i];
        final active = i == selected;
        return GestureDetector(
          onTap: () => onSelect(i),
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
              Icon(icon, size: 22, color: active ? Colors.white : AppColors.c5),
              const SizedBox(height: 4),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: active ? Colors.white : AppColors.textGrey)),
            ]),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────
// Plat selector (scrollable chip grid)
// ─────────────────────────────────────────
class _PlatSelector extends StatelessWidget {
  final _Plat? selected;
  final ValueChanged<_Plat> onSelect;
  const _PlatSelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _platsMarocains.map((p) {
        final active = selected?.name == p.name;
        return GestureDetector(
          onTap: () => onSelect(p),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: active ? AppColors.c6 : Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                  color: active ? AppColors.c6 : AppColors.c3, width: 1.5),
              boxShadow: active
                  ? [
                      BoxShadow(
                          color: AppColors.c6.withOpacity(0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2))
                    ]
                  : [],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(p.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(p.name,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: active ? Colors.white : AppColors.textDark)),
              const SizedBox(width: 6),
              Text('${p.glucidesPer100g}g/100g',
                  style: TextStyle(
                      fontSize: 10,
                      color: active
                          ? Colors.white.withOpacity(0.7)
                          : AppColors.textGrey)),
            ]),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────
// Quantité field
// ─────────────────────────────────────────
class _QuantiteField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _QuantiteField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: false),
      onChanged: onChanged,
      style: const TextStyle(
          fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: 'Ex : 200',
        hintStyle: const TextStyle(color: AppColors.textGrey),
        suffixText: 'g',
        suffixStyle: const TextStyle(
            fontWeight: FontWeight.w700, color: AppColors.c5, fontSize: 16),
        prefixIcon:
            const Icon(Icons.scale_rounded, color: AppColors.c5, size: 20),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.c3),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.c3, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.c6, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Entrez une quantité';
        final n = double.tryParse(v);
        if (n == null || n <= 0) return 'Quantité invalide';
        if (n > 2000) return 'Quantité trop grande';
        return null;
      },
    );
  }
}

// ─────────────────────────────────────────
// Glucides hint below field
// ─────────────────────────────────────────
class _GlucidesHint extends StatelessWidget {
  final _Plat plat;
  final double quantite;
  final double glucides;
  final bool isHigh;
  const _GlucidesHint({
    required this.plat,
    required this.quantite,
    required this.glucides,
    required this.isHigh,
  });

  @override
  Widget build(BuildContext context) {
    final color = isHigh ? const Color(0xFFE65100) : AppColors.c6;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(children: [
        Icon(Icons.calculate_outlined, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${plat.glucidesPer100g} g/100g × ${quantite.toStringAsFixed(0)} g = '
            '${glucides.toStringAsFixed(1)} g de glucides',
            style: TextStyle(
                fontSize: 12, color: color, fontWeight: FontWeight.w600),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────
// Save button
// ─────────────────────────────────────────
class _SaveButton extends StatelessWidget {
  final bool saving;
  final bool saved;
  final VoidCallback onTap;
  const _SaveButton(
      {required this.saving, required this.saved, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: (saving || saved) ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: saved ? AppColors.c5 : AppColors.c6,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.c4,
          disabledForegroundColor: Colors.white70,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: saving || saved ? 0 : 3,
          shadowColor: AppColors.c6.withOpacity(0.3),
        ),
        child: saving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(saved ? Icons.check_circle_rounded : Icons.save_rounded,
                    size: 20),
                const SizedBox(width: 8),
                Text(
                  saved ? 'Enregistré !' : 'Enregistrer le repas',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ]),
      ),
    );
  }
}

// ─────────────────────────────────────────
// High-carb confirmation dialog (Step J-L)
// ─────────────────────────────────────────
class _HighCarbDialog extends StatelessWidget {
  final String platName;
  final double glucides;
  const _HighCarbDialog({required this.platName, required this.glucides});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Warning icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFCC80), width: 2),
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: Color(0xFFE65100), size: 32),
          ),
          const SizedBox(height: 16),

          const Text('Repas riche en glucides',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark)),
          const SizedBox(height: 10),

          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textGrey, height: 1.5),
              children: [
                const TextSpan(text: 'Ce repas ('),
                TextSpan(
                    text: platName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark)),
                const TextSpan(text: ') contient '),
                TextSpan(
                    text: '${glucides.toStringAsFixed(1)} g de glucides',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE65100))),
                const TextSpan(
                    text:
                        ', ce qui dépasse le seuil recommandé de 60 g.\n\nVoulez-vous quand même l\'enregistrer ?'),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Tip box
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.c3),
            ),
            child: const Text(
              '💡 Conseil : pensez à surveiller votre glycémie dans les 2h après ce repas.',
              style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textGrey,
                  fontStyle: FontStyle.italic),
            ),
          ),

          const SizedBox(height: 20),

          // Buttons
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.c6,
                  side: const BorderSide(color: AppColors.c4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Modifier',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE65100),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Confirmer',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Eau Selector — verres d'eau
// ─────────────────────────────────────────
class _EauSelector extends StatelessWidget {
  final int glasses;
  final ValueChanged<int> onChanged;
  const _EauSelector({required this.glasses, required this.onChanged});

  static const int _max = 8;

  @override
  Widget build(BuildContext context) {
    final ml = glasses * 250;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.c3, width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Verres cliquables
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_max, (i) {
            final filled = i < glasses;
            return GestureDetector(
              onTap: () => onChanged(i + 1 == glasses ? 0 : i + 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 30, height: 36,
                decoration: BoxDecoration(
                  color: filled ? AppColors.c5.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: filled ? AppColors.c5 : AppColors.c3,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    '💧',
                    style: TextStyle(
                      fontSize: filled ? 16 : 13,
                      color: filled ? null : Colors.grey.shade300,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        // Info
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: glasses > 0 ? AppColors.c2 : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              glasses == 0
                  ? 'Appuyez sur un verre 💧'
                  : '$glasses verre${glasses > 1 ? 's' : ''} — $ml ml',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: glasses > 0 ? AppColors.textDark : AppColors.textGrey,
              ),
            ),
          ),
          const Spacer(),
          if (glasses > 0)
            Text(
              glasses >= 8 ? '🎉 Objectif atteint !' : '${8 - glasses} restants',
              style: TextStyle(
                fontSize: 11,
                color: glasses >= 8 ? AppColors.c5 : AppColors.textGrey,
                fontWeight: FontWeight.w600,
              ),
            ),
        ]),
      ]),
    );
  }
}
