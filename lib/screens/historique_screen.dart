import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_colors.dart';

// ═══════════════════════════════════════════
//  HISTORIQUE SCREEN — 3 tabs
//  📊 Nutrition  |  🏃 Sport  |  🩸 Glycémie
// ═══════════════════════════════════════════
class HistoriqueScreen extends StatefulWidget {
  const HistoriqueScreen({super.key});
  @override
  State<HistoriqueScreen> createState() => _HistoriqueScreenState();
}

class _HistoriqueScreenState extends State<HistoriqueScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Historique 📋',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 20,
              fontStyle: FontStyle.italic),
        ),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.restaurant_rounded, size: 17), text: 'Nutrition'),
            Tab(icon: Icon(Icons.directions_run_rounded, size: 17), text: 'Sport'),
            Tab(icon: Icon(Icons.bloodtype_rounded, size: 17), text: 'Glycémie'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _NutritionHistTab(),
          _SportHistTab(),
          _GlycemieHistTab(),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────
//  TAB 1 — Historique Nutrition
// ──────────────────────────────────────────
class _NutritionHistTab extends StatelessWidget {
  const _NutritionHistTab();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Non connecté'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('meals')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(60)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return _EmptyHist(
            icon: Icons.no_meals_rounded,
            message: 'Aucun repas enregistré',
            color: AppColors.primary,
          );
        }

        final docs = snap.data!.docs;

        // Group by date
        final Map<String, List<QueryDocumentSnapshot>> grouped = {};
        for (final d in docs) {
          final data = d.data() as Map<String, dynamic>;
          final ts = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
          final key =
              '${ts.year}-${ts.month.toString().padLeft(2, '0')}-${ts.day.toString().padLeft(2, '0')}';
          grouped.putIfAbsent(key, () => []).add(d);
        }

        final keys = grouped.keys.toList();

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: keys.length,
          itemBuilder: (context, i) {
            final key = keys[i];
            final dayDocs = grouped[key]!;
            int totalCal = 0;
            double totalGluc = 0, totalSugar = 0;
            for (final d in dayDocs) {
              final data = d.data() as Map<String, dynamic>;
              totalCal += (data['calories'] as num?)?.toInt() ?? 0;
              totalGluc += (data['glucides'] as num?)?.toDouble() ?? 0;
              totalSugar += (data['sugar'] as num?)?.toDouble() ?? 0;
            }

            final parts = key.split('-');
            final dt =
                DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
            final dateLabel = _dateLabel(dt);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date header
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, top: 4),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(dateLabel,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Divider(color: AppColors.primary.withOpacity(0.2))),
                  ]),
                ),
                // Day summary
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.08),
                        AppColors.primary.withOpacity(0.03)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppColors.primary.withOpacity(0.15)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _SummChip('🔥', '$totalCal', 'kcal'),
                      _VSep(),
                      _SummChip('🌾', '${totalGluc.toStringAsFixed(0)}g', 'glucides'),
                      _VSep(),
                      _SummChip('🍬', '${totalSugar.toStringAsFixed(0)}g', 'sucres'),
                      _VSep(),
                      _SummChip('🍽️', '${dayDocs.length}', 'repas'),
                    ],
                  ),
                ),
                // Meal cards
                ...dayDocs.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final ts = (data['timestamp'] as Timestamp?)?.toDate();
                  final timeStr = ts != null
                      ? '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}'
                      : '--:--';
                  return _NutrMealCard(data: data, time: timeStr);
                }),
                const SizedBox(height: 12),
              ],
            );
          },
        );
      },
    );
  }

  String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return "Aujourd'hui";
    }
    if (dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day - 1) {
      return 'Hier';
    }
    const months = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
      'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

class _NutrMealCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String time;
  const _NutrMealCard({required this.data, required this.time});

  Color get _typeColor => switch (data['type'] as String? ?? '') {
        'Petit-déjeuner' => const Color(0xFFF57C00),
        'Déjeuner' => AppColors.darkMoss,
        'Goûter' => Colors.purple,
        'Dîner' => const Color(0xFF1565C0),
        _ => AppColors.primary,
      };

  IconData get _typeIcon => switch (data['type'] as String? ?? '') {
        'Petit-déjeuner' => Icons.free_breakfast_rounded,
        'Déjeuner' => Icons.lunch_dining_rounded,
        'Goûter' => Icons.cookie_rounded,
        'Dîner' => Icons.dinner_dining_rounded,
        _ => Icons.restaurant_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_typeIcon, color: _typeColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name'] ?? data['platName'] ?? 'Repas',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.textDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(children: [
                  Text(data['type'] ?? '',
                      style: TextStyle(
                          fontSize: 10,
                          color: _typeColor,
                          fontWeight: FontWeight.w600)),
                  const Text(' · ',
                      style:
                          TextStyle(fontSize: 10, color: AppColors.textGrey)),
                  Text(time,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textGrey)),
                ]),
              ],
            ),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${(data['calories'] as num?)?.toInt() ?? 0} kcal',
                style: const TextStyle(
                    color: Colors.deepOrange,
                    fontWeight: FontWeight.w800,
                    fontSize: 12)),
            Text('🍬 ${((data['sugar'] as num?)?.toDouble() ?? 0).toStringAsFixed(1)}g',
                style:
                    const TextStyle(fontSize: 10, color: Colors.blue)),
          ]),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────
//  TAB 2 — Historique Sport
// ──────────────────────────────────────────
class _SportHistTab extends StatelessWidget {
  const _SportHistTab();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('Non connecté'));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sport_sessions')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.green));
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return _EmptyHist(
            icon: Icons.directions_run_rounded,
            message: 'Aucune séance de sport enregistrée',
            color: Colors.green,
          );
        }

        final docs = snap.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final ts = (data['timestamp'] as Timestamp?)?.toDate();
            return _SportCard(data: data, date: ts);
          },
        );
      },
    );
  }
}

class _SportCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final DateTime? date;
  const _SportCard({required this.data, required this.date});

  String get _dateStr {
    if (date == null) return '';
    const months = ['Jan','Fév','Mar','Avr','Mai','Jun','Jul','Aoû','Sep','Oct','Nov','Déc'];
    return '${date!.day} ${months[date!.month - 1]} · ${date!.hour.toString().padLeft(2, '0')}:${date!.minute.toString().padLeft(2, '0')}';
  }

  IconData get _sportIcon => switch (data['type'] as String? ?? '') {
        'Marche' => Icons.directions_walk_rounded,
        'Course' => Icons.directions_run_rounded,
        'Vélo' => Icons.directions_bike_rounded,
        'Natation' => Icons.pool_rounded,
        'Gym' => Icons.fitness_center_rounded,
        _ => Icons.sports_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final duration = (data['duration'] as num?)?.toInt() ?? 0;
    final calories = (data['calories'] as num?)?.toInt() ?? 0;
    final type = data['type'] as String? ?? 'Activité';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.green.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Row(children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(_sportIcon, color: Colors.green.shade600, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(type,
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppColors.textDark)),
          const SizedBox(height: 3),
          Text(_dateStr,
              style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
          const SizedBox(height: 6),
          Row(children: [
            _SportChip(Icons.timer_rounded, '$duration min', Colors.blue),
            const SizedBox(width: 6),
            _SportChip(Icons.local_fire_department_rounded, '$calories kcal',
                Colors.deepOrange),
          ]),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: [
            Text('${(data['distance'] as num?)?.toStringAsFixed(1) ?? '0.0'}',
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: Colors.green.shade700)),
            Text('km', style: TextStyle(fontSize: 10, color: Colors.green.shade400)),
          ]),
        ),
      ]),
    );
  }
}

class _SportChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SportChip(this.icon, this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 3),
      Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    ]),
  );
}

// ──────────────────────────────────────────
//  TAB 3 — Historique Glycémie
// ──────────────────────────────────────────
class _GlycemieHistTab extends StatelessWidget {
  const _GlycemieHistTab();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('Non connecté'));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('glycemie')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.red));
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return _EmptyHist(
            icon: Icons.bloodtype_rounded,
            message: 'Aucune mesure de glycémie enregistrée',
            color: Colors.red,
          );
        }

        final docs = snap.data!.docs;

        // Stats globales
        double total = 0;
        double minVal = double.infinity;
        double maxVal = 0;
        int countHigh = 0, countLow = 0, countNormal = 0;

        for (final d in docs) {
          final data = d.data() as Map<String, dynamic>;
          final val = (data['value'] as num?)?.toDouble() ?? 0;
          total += val;
          if (val < minVal) minVal = val;
          if (val > maxVal) maxVal = val;
          if (val > 1.8) countHigh++;
          else if (val < 0.7) countLow++;
          else countNormal++;
        }
        final avg = total / docs.length;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: [
            // Stats banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFB71C1C), Color(0xFFE53935)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Column(children: [
                const Text('Statistiques glycémie',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _GlyChip('📊', 'Moyenne', '${avg.toStringAsFixed(2)} g/L')),
                  _GlyDivider(),
                  Expanded(child: _GlyChip('⬇️', 'Min', '${minVal.toStringAsFixed(2)} g/L')),
                  _GlyDivider(),
                  Expanded(child: _GlyChip('⬆️', 'Max', '${maxVal.toStringAsFixed(2)} g/L')),
                ]),
                const SizedBox(height: 14),
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  _GlyStatus('🟢 Normal', countNormal, Colors.green.shade200),
                  _GlyStatus('🟡 Élevé', countHigh, Colors.orange.shade200),
                  _GlyStatus('🔴 Bas', countLow, Colors.red.shade200),
                ]),
              ]),
            ),
            const SizedBox(height: 20),
            const Text('Mesures récentes',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark)),
            const SizedBox(height: 10),
            ...docs.map((d) {
              final data = d.data() as Map<String, dynamic>;
              final ts = (data['timestamp'] as Timestamp?)?.toDate();
              return _GlycemieCard(data: data, date: ts);
            }),
          ],
        );
      },
    );
  }
}

class _GlycemieCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final DateTime? date;
  const _GlycemieCard({required this.data, required this.date});

  String get _dateStr {
    if (date == null) return '';
    const months = ['Jan','Fév','Mar','Avr','Mai','Jun','Jul','Aoû','Sep','Oct','Nov','Déc'];
    return '${date!.day} ${months[date!.month - 1]} ${date!.year} — ${date!.hour.toString().padLeft(2, '0')}:${date!.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final val = (data['value'] as num?)?.toDouble() ?? 0;
    final isHigh = val > 1.8;
    final isLow = val < 0.7;
    final statusColor = isHigh ? Colors.red : (isLow ? Colors.orange : Colors.green);
    final statusLabel = isHigh ? 'Élevé' : (isLow ? 'Bas' : 'Normal');
    final statusIcon = isHigh ? Icons.arrow_upward_rounded : (isLow ? Icons.arrow_downward_rounded : Icons.check_rounded);
    final moment = data['moment'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: statusColor.withOpacity(0.07),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              val.toStringAsFixed(2),
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: statusColor),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(statusIcon, size: 12, color: statusColor),
                const SizedBox(width: 4),
                Text(statusLabel,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor)),
              ]),
            ),
            if (moment.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(moment,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textGrey)),
            ],
          ]),
          const SizedBox(height: 4),
          Text(_dateStr,
              style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
          if ((data['note'] as String? ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(data['note'] as String,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textDark,
                    fontStyle: FontStyle.italic),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ])),
        Column(children: [
          Text('g/L', style: TextStyle(fontSize: 11, color: statusColor.withOpacity(0.6))),
          const SizedBox(height: 2),
          Icon(Icons.bloodtype_rounded, color: statusColor.withOpacity(0.4), size: 18),
        ]),
      ]),
    );
  }
}

class _GlyChip extends StatelessWidget {
  final String em, label, value;
  const _GlyChip(this.em, this.label, this.value);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(em, style: const TextStyle(fontSize: 18)),
    const SizedBox(height: 3),
    Text(value,
        style: const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
    Text(label,
        style: const TextStyle(color: Colors.white60, fontSize: 10)),
  ]);
}

class _GlyDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(height: 40, width: 1, color: Colors.white24,
          margin: const EdgeInsets.symmetric(horizontal: 4));
}

class _GlyStatus extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _GlyStatus(this.label, this.count, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
        color: color.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20)),
    child: Text('$label: $count',
        style: const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
  );
}

// ──────────────────────────────────────────
//  Shared widgets
// ──────────────────────────────────────────
class _SummChip extends StatelessWidget {
  final String em, value, label;
  const _SummChip(this.em, this.value, this.label);
  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
    Text(em, style: const TextStyle(fontSize: 14)),
    Text(value,
        style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textDark)),
    Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textGrey)),
  ]);
}

class _VSep extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      height: 30, width: 1, color: AppColors.primary.withOpacity(0.2));
}

class _EmptyHist extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;
  const _EmptyHist(
      {required this.icon, required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
                color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 40),
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
}