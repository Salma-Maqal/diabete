import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_colors.dart';
import '../meal_store.dart';

class _Plat {
  final String name, emoji, imageUrl;
  final double glucidesPer100g, sugarPer100g;
  final int caloriesPer100g;
  const _Plat(this.name, this.emoji, this.imageUrl, this.glucidesPer100g, this.caloriesPer100g, this.sugarPer100g);
}

const _platsMarocains = [
  _Plat('Couscous','🫕','assets/images/couscous.jpg',23.2,112,1.5),
  _Plat('Tajine de poulet','🍲','assets/images/tajine_poulet.jpg',8.5,185,2.0),
  _Plat('Harira','🥣','assets/images/harira.jpg',12.4,75,3.0),
  _Plat('Pastilla','🥧','assets/images/pastilla.jpg',28.6,250,8.0),
  _Plat('Msemen','🫓','assets/images/msemen.jpg',41.0,320,1.0),
  _Plat('Briouates','🥟','assets/images/briouates.jpg',22.0,290,2.5),
  _Plat('Rfissa','🍛','assets/images/rfissa.jpg',19.8,200,1.0),
  _Plat('Zaalouk','🍆','assets/images/zaalouk.jpg',7.3,60,4.0),
  _Plat('Pain marocain','🍞','assets/images/pain_marocain.jpg',49.5,260,2.0),
  _Plat('Sellou','🍯','assets/images/sellou.jpg',55.0,480,20.0),
];

const _typeRepas = [
  ('Petit-déjeuner', Icons.free_breakfast_rounded),
  ('Déjeuner',       Icons.lunch_dining_rounded),
  ('Goûter',         Icons.cookie_rounded),
  ('Dîner',          Icons.dinner_dining_rounded),
];

// ── Standalone screen (route /add-meal)
class AddMealScreen extends StatelessWidget {
  const AddMealScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    appBar: AppBar(
      backgroundColor: AppColors.c6, elevation: 0,
      leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context)),
      title: const Text('Ajouter un repas',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic)),
    ),
    body: AddMealScreenContent(onSaved: () => Navigator.pop(context, true), showAppBar: false),
  );
}

// ── Reusable content (used in Nutrition tab too)
class AddMealScreenContent extends StatefulWidget {
  final VoidCallback onSaved;
  final bool showAppBar;
  const AddMealScreenContent({super.key, required this.onSaved, this.showAppBar = true});
  @override State<AddMealScreenContent> createState() => _AddMealScreenContentState();
}

class _AddMealScreenContentState extends State<AddMealScreenContent> {
  int _typeIndex = 0;
  _Plat? _selectedPlat;
  final _qtyCtrl  = TextEditingController(text: '200');
  final _nameCtrl = TextEditingController();
  final _formKey  = GlobalKey<FormState>();
  DateTime _dt    = DateTime.now();
  bool _saving = false, _saved = false;
  int  _glasses = 0;

  double get _qty    => double.tryParse(_qtyCtrl.text) ?? 0;
  double get _gluc   => _selectedPlat != null ? (_selectedPlat!.glucidesPer100g * _qty / 100) : 0;
  double get _sugar  => _selectedPlat != null ? (_selectedPlat!.sugarPer100g    * _qty / 100) : 0;
  int    get _cal    => _selectedPlat != null ? (_selectedPlat!.caloriesPer100g * _qty / 100).round() : 0;
  bool   get _isHigh => _gluc > 60;

  Future<void> _pickDate() async {
    final p = await showDatePicker(context: context, initialDate: _dt, firstDate: DateTime(2020),
        lastDate: DateTime.now().add(const Duration(days:1)),
        builder: (c,w) => Theme(data: Theme.of(c).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.c6)), child: w!));
    if (p != null) setState(() => _dt = DateTime(p.year,p.month,p.day,_dt.hour,_dt.minute));
  }

  Future<void> _pickTime() async {
    final p = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_dt),
        builder: (c,w) => Theme(data: Theme.of(c).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.c6)), child: w!));
    if (p != null) setState(() => _dt = DateTime(_dt.year,_dt.month,_dt.day,p.hour,p.minute));
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPlat == null) { _snack('Veuillez sélectionner un plat.', isError: true); return; }
    if (_isHigh) {
      final ok = await showDialog<bool>(context: context, barrierDismissible: false,
          builder: (_) => _HighCarbDialog(platName: _selectedPlat!.name, glucides: _gluc)) ?? false;
      if (!mounted || !ok) return;
    }
    setState(() => _saving = true);
    final name = _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : _selectedPlat!.name;
    final (typeLabel, typeIcon) = _typeRepas[_typeIndex];
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('meals').add({
          'userId': user.uid, 'name': name, 'platName': _selectedPlat!.name,
          'platEmoji': _selectedPlat!.emoji, 'type': typeLabel,
          'glucides': _gluc, 'sugar': _sugar, 'calories': _cal,
          'quantite': _qty, 'glasses': _glasses,
          'timestamp': Timestamp.fromDate(_dt),
        });
      }
    } catch (_) {}
    await MealStore.instance.add(MealEntry(
      type: typeLabel, iconName: MealEntry.iconNameOf(typeIcon), platName: name,
      platEmoji: _selectedPlat!.emoji, glucides: _gluc, quantite: _qty, calories: _cal, addedAt: _dt,
    ));
    if (!mounted) return;
    setState(() { _saving = false; _saved = true; });
    _snack('✅ Repas enregistré avec succès !');
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) { widget.onSaved(); setState(() => _resetForm()); }
  }

  void _resetForm() {
    _typeIndex = 0; _selectedPlat = null; _qtyCtrl.text = '200';
    _nameCtrl.clear(); _dt = DateTime.now(); _glasses = 0; _saved = false;
  }

  void _snack(String msg, {bool isError = false}) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
    backgroundColor: isError ? AppColors.error : AppColors.c6,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: const EdgeInsets.all(16),
  ));

  @override
  void dispose() { _qtyCtrl.dispose(); _nameCtrl.dispose(); super.dispose(); }

  String get _dateLabel { final d=_dt; const m=['Jan','Fév','Mar','Avr','Mai','Jun','Jul','Aoû','Sep','Oct','Nov','Déc']; return '${d.day} ${m[d.month-1]} ${d.year}'; }
  String get _timeLabel => '${_dt.hour.toString().padLeft(2,'0')}:${_dt.minute.toString().padLeft(2,'0')}';

  @override
  Widget build(BuildContext context) {
    return Form(key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Résumé nutritionnel
          _NutrCard(gluc: _gluc, cal: _cal, sugar: _sugar, isHigh: _isHigh),
          const SizedBox(height: 20),
          // Nom
          _SL(icon: Icons.edit_note_rounded, label: 'Nom du repas (optionnel)'),
          const SizedBox(height: 8),
          TextFormField(controller: _nameCtrl,
            style: const TextStyle(fontSize: 15, color: AppColors.textDark),
            decoration: _deco('Ex: Déjeuner chez mama, Iftar...', Icons.restaurant_menu_rounded)),
          const SizedBox(height: 20),
          // Date + Heure
          _SL(icon: Icons.calendar_today_rounded, label: 'Date et heure'),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: GestureDetector(onTap: _pickDate,
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.c3, width: 1.5)),
                child: Row(children: [
                  const Icon(Icons.calendar_month_rounded, color: AppColors.c5, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_dateLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark))),
                  const Icon(Icons.edit_rounded, color: AppColors.c4, size: 13),
                ])))),
            const SizedBox(width: 10),
            GestureDetector(onTap: _pickTime,
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(color: AppColors.c6, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Icon(Icons.access_time_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(_timeLabel, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                ]))),
          ]),
          const SizedBox(height: 20),
          // Type
          _SL(icon: Icons.schedule_rounded, label: 'Type de repas'),
          const SizedBox(height: 8),
          _TypeSelector(selected: _typeIndex, onSelect: (i) => setState(() => _typeIndex = i)),
          const SizedBox(height: 20),
          // Plat
          _SL(icon: Icons.restaurant_rounded, label: 'Plat marocain'),
          const SizedBox(height: 8),
          _PlatSelector(selected: _selectedPlat, onSelect: (p) => setState(() => _selectedPlat = p)),
          const SizedBox(height: 20),
          // Quantité
          _SL(icon: Icons.scale_rounded, label: 'Quantité (grammes)'),
          const SizedBox(height: 8),
          TextFormField(controller: _qtyCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark),
            decoration: _deco('Ex : 200', Icons.scale_rounded, suffix: 'g'),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Entrez une quantité';
              final n = double.tryParse(v);
              if (n == null || n <= 0) return 'Quantité invalide';
              if (n > 2000) return 'Trop grande';
              return null;
            }),
          const SizedBox(height: 20),
          // Eau
          _SL(icon: Icons.water_drop_rounded, label: 'Eau consommée'),
          const SizedBox(height: 8),
          _EauSelector(glasses: _glasses, onChanged: (v) => setState(() => _glasses = v)),
          const SizedBox(height: 28),
          // Save
          SizedBox(width: double.infinity, height: 54,
            child: ElevatedButton(
              onPressed: (_saving || _saved) ? null : _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: _saved ? AppColors.c5 : AppColors.c6, foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.c4, disabledForegroundColor: Colors.white70,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: _saving || _saved ? 0 : 3),
              child: _saving ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(_saved ? Icons.check_circle_rounded : Icons.save_rounded, size: 20), const SizedBox(width: 8),
                      Text(_saved ? 'Enregistré !' : 'Enregistrer le repas',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    ]),
            )),
        ]),
      ),
    );
  }

  InputDecoration _deco(String hint, IconData icon, {String? suffix}) => InputDecoration(
    hintText: hint, hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 13),
    prefixIcon: Icon(icon, color: AppColors.c5, size: 19),
    suffixText: suffix, suffixStyle: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.c5, fontSize: 16),
    filled: true, fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.c3)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.c3, width: 1.5)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.c6, width: 2)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
  );
}

// ── Nutrition summary card
class _NutrCard extends StatelessWidget {
  final double gluc, sugar; final int cal; final bool isHigh;
  const _NutrCard({required this.gluc, required this.cal, required this.sugar, required this.isHigh});
  @override
  Widget build(BuildContext context) {
    final color = isHigh ? const Color(0xFFE65100) : AppColors.c6;
    return AnimatedContainer(duration: const Duration(milliseconds: 300), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: isHigh ? const Color(0xFFFFF3E0) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isHigh ? const Color(0xFFFFCC80) : AppColors.c3, width: 1.5),
          boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0,4))]),
      child: Column(children: [
        Row(children: [
          Expanded(child: _MChip(Icons.local_fire_department_rounded, 'Glucides', '${gluc.toStringAsFixed(1)} g', color)),
          const SizedBox(width: 8),
          Expanded(child: _MChip(Icons.whatshot_rounded, 'Calories', '$cal kcal', Colors.deepOrange)),
          const SizedBox(width: 8),
          Expanded(child: _MChip(Icons.water_drop_rounded, 'Sucres', '${sugar.toStringAsFixed(1)} g', Colors.blue.shade600)),
        ]),
        const SizedBox(height: 10),
        ClipRRect(borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(value: (gluc/60).clamp(0.0,1.0), minHeight: 7,
              backgroundColor: color.withOpacity(0.12), valueColor: AlwaysStoppedAnimation<Color>(color))),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('0 g', style: TextStyle(fontSize: 11, color: color.withOpacity(0.5))),
          if (isHigh) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: const Color(0xFFFFCC80), borderRadius: BorderRadius.circular(10)),
            child: const Text('⚠️ Élevé', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFE65100)))),
          Text('Seuil 60 g', style: TextStyle(fontSize: 11, color: color.withOpacity(0.6), fontWeight: FontWeight.w600)),
        ]),
      ]));
  }
}

class _MChip extends StatelessWidget {
  final IconData icon; final String label, value; final Color color;
  const _MChip(this.icon, this.label, this.value, this.color);
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
    decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
    child: Column(children: [
      Icon(icon, color: color, size: 17), const SizedBox(height: 3),
      Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: TextStyle(fontSize: 10, color: color.withOpacity(0.7))),
    ]));
}

class _SL extends StatelessWidget {
  final IconData icon; final String label;
  const _SL({required this.icon, required this.label});
  @override Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 15, color: AppColors.c6), const SizedBox(width: 6),
    Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
  ]);
}

class _TypeSelector extends StatelessWidget {
  final int selected; final ValueChanged<int> onSelect;
  const _TypeSelector({required this.selected, required this.onSelect});
  @override Widget build(BuildContext context) => Wrap(spacing: 8, runSpacing: 8,
    children: List.generate(_typeRepas.length, (i) {
      final (label, icon) = _typeRepas[i]; final active = i == selected;
      return GestureDetector(onTap: () => onSelect(i),
        child: AnimatedContainer(duration: const Duration(milliseconds: 200),
          width: (MediaQuery.of(context).size.width - 56) / 3,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(color: active ? AppColors.c6 : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: active ? AppColors.c6 : AppColors.c3, width: 1.5),
              boxShadow: active ? [BoxShadow(color: AppColors.c6.withOpacity(0.25), blurRadius: 8, offset: const Offset(0,3))] : []),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 20, color: active ? Colors.white : AppColors.c5),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: active ? Colors.white : AppColors.textGrey)),
          ])));
    }));
}

class _PlatSelector extends StatefulWidget {
  final _Plat? selected; final ValueChanged<_Plat> onSelect;
  const _PlatSelector({required this.selected, required this.onSelect});
  @override State<_PlatSelector> createState() => _PlatSelectorState();
}
class _PlatSelectorState extends State<_PlatSelector> {
  final _ctrl = TextEditingController(); String _q = '';
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final filtered = _q.trim().isEmpty ? <_Plat>[] : _platsMarocains.where((p) => p.name.toLowerCase().contains(_q.toLowerCase())).toList();
    return Column(children: [
      TextField(controller: _ctrl, onChanged: (v) => setState(() => _q = v),
        style: const TextStyle(fontSize: 15, color: AppColors.textDark),
        decoration: InputDecoration(
          hintText: 'Rechercher un plat...', hintStyle: const TextStyle(color: AppColors.textGrey),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.c5, size: 20),
          suffixIcon: _q.isNotEmpty ? IconButton(icon: const Icon(Icons.close_rounded, color: AppColors.textGrey, size: 18),
              onPressed: () { _ctrl.clear(); setState(() => _q = ''); }) : null,
          filled: true, fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.c3)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.c3, width: 1.5)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.c6, width: 2)),
        )),
      const SizedBox(height: 10),
      if (_q.trim().isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(children: [
          Container(width: 56, height: 56, decoration: const BoxDecoration(color: AppColors.c2, shape: BoxShape.circle),
            child: const Icon(Icons.search_rounded, color: AppColors.c5, size: 28)),
          const SizedBox(height: 8),
          const Text('Recherchez un plat', style: TextStyle(color: AppColors.textGrey, fontSize: 13), textAlign: TextAlign.center),
          const Text('Ex: Couscous, Harira, Tajine...', style: TextStyle(color: AppColors.textGrey, fontSize: 11), textAlign: TextAlign.center),
        ]))
      else if (filtered.isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.search_off_rounded, color: AppColors.textGrey, size: 28), const SizedBox(width: 8),
          Text('Aucun plat pour "$_q"', style: const TextStyle(color: AppColors.textGrey, fontSize: 13)),
        ]))
      else ...filtered.map((p) {
        final active = widget.selected?.name == p.name;
        return Padding(padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(onTap: () => widget.onSelect(p),
            child: AnimatedContainer(duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(color: active ? AppColors.c6 : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: active ? AppColors.c6 : AppColors.c3, width: active ? 2.5 : 1.5),
                  boxShadow: [BoxShadow(color: (active ? AppColors.c6 : Colors.black).withOpacity(active ? 0.3 : 0.05), blurRadius: active ? 10 : 6, offset: const Offset(0,3))]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Stack(children: [
                    Image.asset(p.imageUrl, height: 140, width: double.infinity, fit: BoxFit.cover,
                        errorBuilder: (_,__,___) => Container(height: 140, color: AppColors.c2,
                            child: Center(child: Text(p.emoji, style: const TextStyle(fontSize: 40))))),
                    if (active) Positioned(top: 6, right: 6, child: Container(width: 22, height: 22,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.check_circle_rounded, color: AppColors.c6, size: 22))),
                    Positioned(bottom: 0, left: 0, right: 0, child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), color: Colors.black45,
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                          Text('${p.glucidesPer100g}g glucides/100g', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                          Text('${p.caloriesPer100g} kcal', style: const TextStyle(color: Colors.white70, fontSize: 10)),
                        ]))),
                  ])),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(p.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: active ? Colors.white : AppColors.textDark)),
                    Text('🍬 ${p.sugarPer100g}g/100g', style: TextStyle(fontSize: 11, color: active ? Colors.white70 : AppColors.textGrey)),
                  ])),
              ]))));
      }),
    ]);
  }
}

class _EauSelector extends StatelessWidget {
  final int glasses; final ValueChanged<int> onChanged;
  const _EauSelector({required this.glasses, required this.onChanged});
  static const _max = 8;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.c3, width: 1.5)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(_max, (i) {
          final filled = i < glasses;
          return GestureDetector(onTap: () => onChanged(i + 1 == glasses ? 0 : i + 1),
            child: AnimatedContainer(duration: const Duration(milliseconds: 150), width: 30, height: 32,
              decoration: BoxDecoration(color: filled ? AppColors.c5.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6), border: Border.all(color: filled ? AppColors.c5 : AppColors.c3, width: 1.5)),
              child: Center(child: Text('💧', style: TextStyle(fontSize: filled ? 14 : 11, color: filled ? null : Colors.grey.shade300)))));
        })),
      const SizedBox(height: 8),
      Row(children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: glasses > 0 ? AppColors.c2 : const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(20)),
          child: Text(glasses == 0 ? 'Appuyez sur un verre 💧' : '$glasses verre${glasses > 1 ? "s" : ""} — ${glasses * 250} ml',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: glasses > 0 ? AppColors.textDark : AppColors.textGrey))),
        const Spacer(),
        if (glasses > 0) Text(glasses >= 8 ? '🎉 Objectif atteint !' : '${8 - glasses} restants',
            style: TextStyle(fontSize: 12, color: glasses >= 8 ? AppColors.c5 : AppColors.textGrey, fontWeight: FontWeight.w600)),
      ]),
    ]));
}

class _HighCarbDialog extends StatelessWidget {
  final String platName; final double glucides;
  const _HighCarbDialog({required this.platName, required this.glucides});
  @override
  Widget build(BuildContext context) => Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), backgroundColor: Colors.white,
    child: Padding(padding: const EdgeInsets.all(22), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 56, height: 56, decoration: BoxDecoration(color: const Color(0xFFFFF3E0), shape: BoxShape.circle, border: Border.all(color: const Color(0xFFFFCC80), width: 2)),
        child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFE65100), size: 28)),
      const SizedBox(height: 14),
      const Text('Repas riche en glucides', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
      const SizedBox(height: 10),
      RichText(textAlign: TextAlign.center, text: TextSpan(style: const TextStyle(fontSize: 14, color: AppColors.textGrey, height: 1.5), children: [
        const TextSpan(text: 'Ce repas ('),
        TextSpan(text: platName, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark)),
        const TextSpan(text: ') contient '),
        TextSpan(text: '${glucides.toStringAsFixed(1)} g glucides', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFE65100))),
        const TextSpan(text: ', dépasse le seuil de 60 g.\n\nVoulez-vous quand même enregistrer ?'),
      ])),
      const SizedBox(height: 12),
      Container(width: double.infinity, padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: const Color(0xFFF1F8E9), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.c3)),
        child: const Text('💡 Surveillez votre glycémie 2h après ce repas.', style: TextStyle(fontSize: 12, color: AppColors.textGrey, fontStyle: FontStyle.italic))),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context, false),
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.c6, side: const BorderSide(color: AppColors.c4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 11)),
          child: const Text('Modifier', style: TextStyle(fontWeight: FontWeight.w700)))),
        const SizedBox(width: 12),
        Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE65100), foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 11)),
          child: const Text('Confirmer', style: TextStyle(fontWeight: FontWeight.w700)))),
      ]),
    ])));
}