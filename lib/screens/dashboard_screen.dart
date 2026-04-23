// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:image_picker/image_picker.dart';
import '../app_colors.dart';
import '../user_session.dart';
import '../meal_store.dart';
import 'edit_meal_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _HomePage(),
      const _GlycemiePage(),
      const _RepasPage(),
      _ProfilPage(onRefresh: () => setState(() {})),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: AppColors.c6,
        elevation: 0,
        title: const Text('CalmSugar',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontStyle: FontStyle.italic,
                fontSize: 22,
                letterSpacing: 0.5)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white, size: 26),
            onPressed: () async {
              await UserSession().clear();
              if (mounted) Navigator.pushReplacementNamed(context, '/welcome');
            },
          ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: CurvedNavigationBar(
        index: _currentIndex,
        height: 70,
        color: AppColors.c6,
        backgroundColor: Colors.transparent,
        buttonBackgroundColor: AppColors.c5,
        animationDuration: const Duration(milliseconds: 300),
        animationCurve: Curves.easeInOut,
        items: const [
          Icon(Icons.home_rounded,         size: 32, color: Colors.white),
          Icon(Icons.monitor_heart_rounded, size: 32, color: Colors.white),
          Icon(Icons.restaurant_rounded,    size: 32, color: Colors.white),
          Icon(Icons.person_rounded,        size: 32, color: Colors.white),
        ],
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ══════════════════════════════════════════
// PAGE 1 : Accueil
// ══════════════════════════════════════════
class _HomePage extends StatelessWidget {
  const _HomePage();
  @override
  Widget build(BuildContext context) {
    final name = UserSession().fullName.isNotEmpty ? UserSession().fullName : 'Utilisateur';
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Hero card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.c6,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: AppColors.c6.withOpacity(0.3), blurRadius: 14, offset: const Offset(0, 6))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Bonjour, $name 👋',
                style: const TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 6),
            const Text('Bienvenue sur CalmSugar',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 18),
            Row(children: [
              _StatCard(label: 'Glycémie',     value: '5.4', unit: 'mmol/L', color: AppColors.c3),
              const SizedBox(width: 12),
              _StatCard(label: 'Dernier repas', value: '2h',  unit: 'ago',    color: AppColors.c4),
            ]),
          ]),
        ),

        const SizedBox(height: 30),
        const Text('Actions rapides',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
        const SizedBox(height: 14),

        _ActionCard(
          icon: Icons.person_add_outlined,
          title: 'Ajouter un accompagnant',
          subtitle: 'Inviter un proche à vous suivre',
          onTap: () => Navigator.pushNamed(context, '/add-companion')),
        const SizedBox(height: 12),
        _ActionCard(
          icon: Icons.monitor_heart_outlined,
          title: 'Saisir ma glycémie',
          subtitle: 'Enregistrer une nouvelle mesure',
          onTap: () {}),
        const SizedBox(height: 12),
        _ActionCard(
          icon: Icons.restaurant_outlined,
          title: 'Journal alimentaire',
          subtitle: 'Suivre vos repas',
          onTap: () {}),
        const SizedBox(height: 12),
        _ActionCard(
          icon: Icons.bar_chart_outlined,
          title: 'Mes statistiques',
          subtitle: "Voir l'évolution de ma santé",
          onTap: () {}),
      ]),
    );
  }
}

// ══════════════════════════════════════════
// PAGE 2 : Glycémie
// ══════════════════════════════════════════
class _GlycemiePage extends StatelessWidget {
  const _GlycemiePage();
  @override
  Widget build(BuildContext context) {
    final entries = [
      {'time': '08:00', 'value': 5.4, 'status': 'Normal'},
      {'time': '12:30', 'value': 7.8, 'status': 'Élevé'},
      {'time': '15:00', 'value': 4.9, 'status': 'Normal'},
      {'time': '19:00', 'value': 6.2, 'status': 'Normal'},
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Header card
        Container(
          width: double.infinity, padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.c5, AppColors.c6]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: AppColors.c6.withOpacity(0.3), blurRadius: 14, offset: const Offset(0, 6))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("Glycémie aujourd'hui",
                style: TextStyle(color: Colors.white70, fontSize: 15)),
            const SizedBox(height: 8),
            const Text('5.4 mmol/L',
                style: TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20)),
              child: const Text('✅ Dans la plage normale',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ]),
        ),

        const SizedBox(height: 28),
        const Text('Historique du jour',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
        const SizedBox(height: 14),

        ...entries.map((e) {
          final isHigh = (e['value'] as double) > 7.0;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isHigh ? Colors.orange.shade200 : AppColors.c3, width: 1.5),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Row(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: isHigh ? Colors.orange.shade50 : AppColors.c2,
                  borderRadius: BorderRadius.circular(14)),
                child: Icon(Icons.water_drop_rounded,
                    color: isHigh ? Colors.orange : AppColors.c6, size: 26)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e['time'] as String,
                    style: const TextStyle(fontSize: 13, color: AppColors.textGrey, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text('${e['value']} mmol/L',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isHigh ? Colors.orange.shade100 : AppColors.c2,
                  borderRadius: BorderRadius.circular(20)),
                child: Text(e['status'] as String,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isHigh ? Colors.orange.shade800 : AppColors.c6)),
              ),
            ]),
          );
        }),

        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.c6,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 3),
            onPressed: () {},
            icon: const Icon(Icons.add_rounded, size: 24),
            label: const Text('Nouvelle mesure',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          )),
      ]),
    );
  }
}

// ══════════════════════════════════════════
// PAGE 3 : Repas + Calendrier
// ══════════════════════════════════════════
class _RepasPage extends StatefulWidget {
  const _RepasPage();
  @override
  State<_RepasPage> createState() => _RepasPageState();
}

class _RepasPageState extends State<_RepasPage> {
  final _store = MealStore.instance;
  late DateTime _selectedDay;
  late DateTime _focusedMonth;
  late ScrollController _calScroll;

  static const int _daysRange = 30; // 30 jours dans le calendrier

  @override
  void initState() {
    super.initState();
    _selectedDay   = _today;
    _focusedMonth  = _today;
    _calScroll     = ScrollController();
    // scroll vers aujourd'hui après le build
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday());
  }

  @override
  void dispose() {
    _calScroll.dispose();
    super.dispose();
  }

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  void _scrollToToday() {
    final idx = _daysRange ~/ 2; // aujourd'hui est au milieu
    final offset = idx * 72.0 - 100;
    if (_calScroll.hasClients) {
      _calScroll.animateTo(offset.clamp(0, double.infinity),
          duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
    }
  }

  Future<void> _goAddMeal() async {
    final added = await Navigator.pushNamed(context, '/add-meal');
    if (added == true && mounted) setState(() {});
  }

  String _dayName(DateTime d) {
    const names = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return names[d.weekday - 1];
  }

  String _monthLabel(DateTime d) {
    const months = ['Jan','Fév','Mar','Avr','Mai','Juin','Juil','Aoû','Sep','Oct','Nov','Déc'];
    return '${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final selKey  = MealStore.keyOf(_selectedDay);
    final meals   = _store.forDate(selKey);
    final cal     = _store.caloriesForDate(selKey);
    const objectif = 1800;
    final restantes = (objectif - cal).clamp(0, objectif);
    final isToday   = _selectedDay == _today;

    return Column(children: [
      // ════════════════════════════
      // CALENDRIER HORIZONTAL
      // ════════════════════════════
      Container(
        color: AppColors.c6,
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(children: [
          // Mois label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(_monthLabel(_selectedDay),
                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
              if (!isToday)
                GestureDetector(
                  onTap: () => setState(() { _selectedDay = _today; _scrollToToday(); }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20)),
                    child: const Text("Aujourd'hui",
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
            ]),
          ),
          // Jours scrollables
          SizedBox(
            height: 80,
            child: ListView.builder(
              controller: _calScroll,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _daysRange,
              itemBuilder: (_, i) {
                final day = _today.subtract(Duration(days: _daysRange ~/ 2 - i));
                final key = MealStore.keyOf(day);
                final hasMeals = _store.forDate(key).isNotEmpty;
                final isSelected = day == _selectedDay;
                final isTodayDay = day == _today;

                return GestureDetector(
                  onTap: () => setState(() => _selectedDay = day),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isTodayDay && !isSelected
                            ? Colors.white.withOpacity(0.6)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(_dayName(day),
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? AppColors.c6 : Colors.white70)),
                      const SizedBox(height: 4),
                      Text('${day.day}',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: isSelected ? AppColors.c6 : Colors.white)),
                      const SizedBox(height: 4),
                      // Point si repas enregistrés
                      Container(
                        width: 6, height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: hasMeals
                              ? (isSelected ? AppColors.c5 : Colors.white)
                              : Colors.transparent,
                        ),
                      ),
                    ]),
                  ),
                );
              },
            ),
          ),
        ]),
      ),

      // ════════════════════════════
      // CONTENU DU JOUR SÉLECTIONNÉ
      // ════════════════════════════
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Résumé calories du jour
            Container(
              width: double.infinity, padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: AppColors.c6,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: AppColors.c6.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4))]),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _CalInfo(label: 'Consommées', value: '$cal',       unit: 'kcal'),
                Container(width: 1, height: 44, color: Colors.white30),
                _CalInfo(label: 'Objectif',   value: '$objectif',  unit: 'kcal'),
                Container(width: 1, height: 44, color: Colors.white30),
                _CalInfo(label: 'Restantes',  value: '$restantes', unit: 'kcal'),
              ]),
            ),

            const SizedBox(height: 24),

            // Titre du jour
            Row(children: [
              Text(
                isToday ? "🍽️ Aujourd'hui" : '🍽️ ${_dayLabel(_selectedDay)}',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textDark),
              ),
              const SizedBox(width: 10),
              if (meals.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.c2, borderRadius: BorderRadius.circular(20)),
                  child: Text('${meals.length} repas',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                ),
            ]),

            const SizedBox(height: 14),

            // Liste repas ou état vide
            if (meals.isEmpty)
              _EmptyMeals(isToday: isToday)
            else
              ...meals.map((m) => _MealCard(meal: m, onRefresh: () => setState(() {}))),

            const SizedBox(height: 20),

            // ── Section Eau
            const Text('💧 Hydratation',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textDark)),
            const SizedBox(height: 12),
            _WaterSection(dateKey: selKey),

            const SizedBox(height: 16),

            // Bouton ajouter (seulement pour aujourd'hui)
            if (isToday)
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.c6,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 3),
                  onPressed: _goAddMeal,
                  icon: const Icon(Icons.add_rounded, size: 24),
                  label: const Text('Ajouter un repas',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                )),
          ]),
        ),
      ),
    ]);
  }

  String _dayLabel(DateTime d) {
    const months = ['Jan','Fév','Mar','Avr','Mai','Juin','Juil','Aoû','Sep','Oct','Nov','Déc'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class _MealCard extends StatelessWidget {
  final MealEntry meal;
  final VoidCallback onRefresh;
  const _MealCard({required this.meal, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(meal.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
            color: Colors.red.shade400, borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.delete_rounded, color: Colors.white, size: 28),
          SizedBox(height: 4),
          Text('Supprimer', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Text('Supprimer ce repas ?',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textDark)),
            content: Text('${meal.platEmoji} ${meal.platName} — ${meal.type}',
                style: const TextStyle(fontSize: 15, color: AppColors.textGrey)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler',
                    style: TextStyle(color: AppColors.c5, fontWeight: FontWeight.w700))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Supprimer', style: TextStyle(fontWeight: FontWeight.w700))),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) async {
        await MealStore.instance.delete(meal.id);
        onRefresh();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.c3, width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(children: [
              Container(width: 52, height: 52,
                  decoration: BoxDecoration(color: AppColors.c2, borderRadius: BorderRadius.circular(14)),
                  child: Center(child: Text(meal.platEmoji, style: const TextStyle(fontSize: 26)))),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(meal.type,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                const SizedBox(height: 3),
                Row(children: [
                  Text(meal.timeLabel,
                      style: const TextStyle(fontSize: 13, color: AppColors.textGrey, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 6),
                  Container(width: 4, height: 4,
                      decoration: const BoxDecoration(color: AppColors.c3, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Flexible(child: Text(meal.platName,
                      style: const TextStyle(fontSize: 13, color: AppColors.textGrey, fontStyle: FontStyle.italic),
                      overflow: TextOverflow.ellipsis)),
                ]),
                const SizedBox(height: 5),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.c2, borderRadius: BorderRadius.circular(20)),
                    child: Text('🍚 ${meal.glucides.toStringAsFixed(1)} g glucides',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  ),
                  const SizedBox(width: 8),
                  Text('${meal.calories} kcal',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.c6)),
                ]),
              ])),
            ]),
          ),
          // Actions bar
          Container(
            decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.c2, width: 1))),
            child: Row(children: [
              // ✏️ Modifier
              Expanded(child: TextButton.icon(
                onPressed: () async {
                  final edited = await Navigator.push<bool>(context,
                      MaterialPageRoute(builder: (_) => EditMealScreen(meal: meal)));
                  if (edited == true) onRefresh();
                },
                icon: const Icon(Icons.edit_rounded, size: 16, color: AppColors.c5),
                label: const Text('Modifier',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.c5)),
              )),
              Container(width: 1, height: 36, color: AppColors.c2),
              // 🗑️ Supprimer
              Expanded(child: TextButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      title: const Text('Supprimer ce repas ?',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                      content: Text('${meal.platEmoji} ${meal.platName}',
                          style: const TextStyle(fontSize: 15, color: AppColors.textGrey)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false),
                            child: const Text('Annuler',
                                style: TextStyle(color: AppColors.c5, fontWeight: FontWeight.w700))),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red, foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Supprimer', style: TextStyle(fontWeight: FontWeight.w700))),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await MealStore.instance.delete(meal.id);
                    onRefresh();
                  }
                },
                icon: const Icon(Icons.delete_rounded, size: 16, color: Colors.red),
                label: const Text('Supprimer',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.red)),
              )),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Water Card pour la page Repas
class _WaterSection extends StatefulWidget {
  final String dateKey;
  const _WaterSection({required this.dateKey});
  @override
  State<_WaterSection> createState() => _WaterSectionState();
}
class _WaterSectionState extends State<_WaterSection> {
  static const int _max = 8;

  int get _glasses => MealStore.instance.glassesForDate(widget.dateKey);

  @override
  Widget build(BuildContext context) {
    final glasses = _glasses;
    final ml  = glasses * 250;
    final pct = glasses / _max;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBDEFB), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 46, height: 46,
              decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.water_drop_rounded, color: Color(0xFF1565C0), size: 24)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Eau', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
            Text('$glasses/$_max verres — $ml ml',
                style: const TextStyle(fontSize: 13, color: AppColors.textGrey)),
          ])),
          Text(
            glasses >= _max ? '🎉 Objectif!' : '${_max - glasses} restants',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                color: glasses >= _max ? AppColors.c5 : AppColors.textGrey),
          ),
        ]),
        const SizedBox(height: 12),
        ClipRRect(borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(value: pct, minHeight: 8,
              backgroundColor: const Color(0xFFE3F2FD),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)))),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_max, (i) {
            final filled = i < glasses;
            return GestureDetector(
              onTap: () async {
                final newVal = (i + 1 == glasses) ? 0 : i + 1;
                await MealStore.instance.setWater(widget.dateKey, newVal);
                setState(() {});
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 34, height: 40,
                decoration: BoxDecoration(
                  color: filled ? const Color(0xFFBBDEFB) : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: filled ? const Color(0xFF1976D2) : AppColors.c3, width: 1.5),
                ),
                child: Center(child: Text('💧', style: TextStyle(fontSize: filled ? 17 : 13))),
              ),
            );
          }),
        ),
      ]),
    );
  }
}

class _EmptyMeals extends StatelessWidget {
  final bool isToday;
  const _EmptyMeals({this.isToday = false});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 48),
    child: Column(children: [
      Text(isToday ? '🍽️' : '📭', style: const TextStyle(fontSize: 52)),
      const SizedBox(height: 14),
      Text(
        isToday ? 'Aucun repas enregistré aujourd\'hui' : 'Aucun repas ce jour-là',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
      const SizedBox(height: 6),
      Text(
        isToday ? "Appuyez sur 'Ajouter un repas'" : 'Sélectionnez un autre jour',
        style: const TextStyle(fontSize: 14, color: AppColors.textGrey)),
    ]),
  );
}

class _CalInfo extends StatelessWidget {
  final String label, value, unit;
  const _CalInfo({required this.label, required this.value, required this.unit});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
    const SizedBox(height: 6),
    Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
    Text(unit,  style: const TextStyle(color: Colors.white60, fontSize: 11)),
  ]);
}

// ══════════════════════════════════════════
// PAGE 4 : Profil
// ══════════════════════════════════════════
class _ProfilPage extends StatefulWidget {
  final VoidCallback onRefresh;
  const _ProfilPage({required this.onRefresh});
  @override
  State<_ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<_ProfilPage> {
  final _session = UserSession();
  bool _pickingImage = false;
  XFile? _pickedFile;

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(color: AppColors.c3, borderRadius: BorderRadius.circular(2))),
          const Text('Photo de profil',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          const SizedBox(height: 16),
          if (!kIsWeb) _PhotoOption(
              icon: Icons.camera_alt_rounded, label: 'Prendre une photo',
              onTap: () => Navigator.pop(context, ImageSource.camera)),
          if (!kIsWeb) const Divider(height: 1, color: AppColors.c2),
          _PhotoOption(
              icon: Icons.photo_library_rounded, label: 'Choisir depuis la galerie',
              onTap: () => Navigator.pop(context, ImageSource.gallery)),
          if (_pickedFile != null) ...[
            const Divider(height: 1, color: AppColors.c2),
            _PhotoOption(icon: Icons.delete_outline_rounded, label: 'Supprimer la photo',
                color: Colors.red, onTap: () => Navigator.pop(context, null)),
          ],
          const SizedBox(height: 16),
        ]),
      ),
    );

    if (!mounted) return;
    if (source == null && _pickedFile != null) {
      setState(() => _pickedFile = null);
      await _session.save(photoPath: '');
      widget.onRefresh();
      return;
    }
    if (source == null) return;

    setState(() => _pickingImage = true);
    try {
      final picked = await ImagePicker().pickImage(source: source, imageQuality: 85, maxWidth: 600);
      if (picked != null && mounted) {
        setState(() => _pickedFile = picked);
        await _session.save(photoPath: picked.path);
        widget.onRefresh();
      }
    } catch (_) {}
    if (mounted) setState(() => _pickingImage = false);
  }

  @override
  Widget build(BuildContext context) {
    final name  = _session.fullName.isNotEmpty ? _session.fullName : 'Utilisateur';
    final email = _session.email.isNotEmpty ? _session.email : 'email@exemple.com';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      child: Column(children: [

        // ── Hero card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [AppColors.c6, AppColors.c5],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: AppColors.c6.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 8))],
          ),
          child: Column(children: [
            const SizedBox(height: 32),
            Stack(alignment: Alignment.bottomRight, children: [
              Container(
                width: 110, height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  color: AppColors.c4,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12)],
                ),
                child: ClipOval(
                  child: _pickedFile != null
                      ? _XFileImage(file: _pickedFile!, size: 110)
                      : _AvatarInitials(name: name),
                ),
              ),
              GestureDetector(
                onTap: _pickingImage ? null : _pickPhoto,
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6)]),
                  child: _pickingImage
                      ? const Padding(padding: EdgeInsets.all(7),
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.c6))
                      : const Icon(Icons.camera_alt_rounded, size: 19, color: AppColors.c6),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            Text(name,
                style: const TextStyle(color: Colors.white, fontSize: 22,
                    fontWeight: FontWeight.w800, letterSpacing: 0.3)),
            const SizedBox(height: 5),
            Text(email, style: const TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.verified_rounded, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text('Type 2 — Suivi actif',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
              ]),
            ),
            const SizedBox(height: 22),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                _ProfileStat(value: '12', label: 'Semaines'),
                _HDivider(),
                _ProfileStat(value: '84', label: 'Mesures'),
                _HDivider(),
                _ProfileStat(value: '5.4', label: 'Moy. mmol'),
              ]),
            ),
            const SizedBox(height: 22),
          ]),
        ),

        const SizedBox(height: 28),
        _SectionTitle(label: 'MON COMPTE'),
        const SizedBox(height: 12),
        _ProfilItem(icon: Icons.person_outline_rounded, title: 'Informations personnelles',
            subtitle: name, onTap: () {}),
        _ProfilItem(icon: Icons.monitor_heart_outlined, title: 'Paramètres de santé',
            subtitle: 'Type, poids, glycémie cible',
            onTap: () => Navigator.pushNamed(context, '/health-info')),
        _ProfilItem(icon: Icons.group_outlined, title: 'Mes accompagnants',
            subtitle: 'Gérer vos proches',
            onTap: () => Navigator.pushNamed(context, '/add-companion')),

        const SizedBox(height: 20),
        _SectionTitle(label: 'PRÉFÉRENCES'),
        const SizedBox(height: 12),
        _ProfilItem(icon: Icons.notifications_outlined, title: 'Notifications',
            subtitle: 'Rappels, alertes glycémie', onTap: () {}),
        _ProfilItem(icon: Icons.language_outlined, title: 'Langue',
            subtitle: 'Français', onTap: () {}),
        _ProfilItem(icon: Icons.lock_outline_rounded, title: 'Sécurité',
            subtitle: 'Mot de passe, 2FA', onTap: () {}),

        const SizedBox(height: 20),
        GestureDetector(
          onTap: () async {
            await _session.clear();
            if (context.mounted) Navigator.pushReplacementNamed(context, '/welcome');
          },
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade100)),
            child: Row(children: [
              Container(width: 48, height: 48,
                  decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.logout_rounded, color: Colors.red, size: 24)),
              const SizedBox(width: 16),
              const Expanded(child: Text('Se déconnecter',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.red))),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.red.shade300),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ── XFile image
class _XFileImage extends StatefulWidget {
  final XFile file;
  final double size;
  const _XFileImage({required this.file, required this.size});
  @override
  State<_XFileImage> createState() => _XFileImageState();
}
class _XFileImageState extends State<_XFileImage> {
  late Future<Uint8List> _bytesFuture;
  @override
  void initState() { super.initState(); _bytesFuture = widget.file.readAsBytes(); }
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _bytesFuture,
      builder: (ctx, snap) {
        if (snap.hasData) return Image.memory(snap.data!, fit: BoxFit.cover, width: widget.size, height: widget.size);
        return Container(color: AppColors.c4, child: const Icon(Icons.person_rounded, color: Colors.white, size: 40));
      },
    );
  }
}

// ── Avatar initials
class _AvatarInitials extends StatelessWidget {
  final String name;
  const _AvatarInitials({required this.name});
  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.c4,
    child: Center(child: Text(_initials,
        style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800))),
  );
}

class _ProfileStat extends StatelessWidget {
  final String value, label;
  const _ProfileStat({required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [
    Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
    const SizedBox(height: 3),
    Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
  ]));
}

class _HDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 36, color: Colors.white24);
}

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Text(label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
            color: AppColors.textGrey, letterSpacing: 1.2)),
  );
}

class _ProfilItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  const _ProfilItem({required this.icon, required this.title, this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.c2),
        boxShadow: [BoxShadow(color: AppColors.c2.withOpacity(0.4), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(width: 48, height: 48,
            decoration: BoxDecoration(color: AppColors.c2, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppColors.c6, size: 24)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ])),
        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.c4),
      ]),
    ),
  );
}

class _PhotoOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _PhotoOption({required this.icon, required this.label, required this.onTap, this.color});
  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textDark;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(children: [
          Icon(icon, color: c, size: 24),
          const SizedBox(width: 16),
          Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c)),
        ]),
      ),
    );
  }
}

// ── Shared widgets
class _StatCard extends StatelessWidget {
  final String label, value, unit;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.unit, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      const SizedBox(height: 6),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
        const SizedBox(width: 5),
        Padding(padding: const EdgeInsets.only(bottom: 3),
            child: Text(unit, style: const TextStyle(color: Colors.white70, fontSize: 12))),
      ]),
    ]),
  ));
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.c3, width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))]),
      child: Row(children: [
        Container(width: 52, height: 52,
            decoration: BoxDecoration(color: AppColors.c2, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: AppColors.c6, size: 26)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textGrey)),
        ])),
        const Icon(Icons.arrow_forward_ios_rounded, size: 15, color: AppColors.c4),
      ]),
    ),
  );
}
