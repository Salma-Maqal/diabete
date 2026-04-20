import 'package:flutter/material.dart';
import '../app_colors.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.c6,
        elevation: 0,
        title: const Text('CalmSugar',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => Navigator.pushReplacementNamed(context, '/welcome'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.c6,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bonjour 👋',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 4),
                  const Text('Bienvenue sur CalmSugar',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  Row(children: [
                    _StatCard(label: 'Glycémie', value: '5.4', unit: 'mmol/L', color: AppColors.c3),
                    const SizedBox(width: 10),
                    _StatCard(label: 'Dernier repas', value: '2h', unit: 'ago', color: AppColors.c4),
                  ]),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Diagramme: Ajouter accompagnant ? → Oui → /add-companion
            const Text('Actions rapides',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 12),

            _ActionCard(
              icon: Icons.person_add_outlined,
              title: 'Ajouter un accompagnant',
              subtitle: 'Inviter un proche à vous suivre',
              onTap: () {
                // Diagramme: Ajouter accompagnant ? → Oui
                Navigator.pushNamed(context, '/add-companion');
              },
            ),
            const SizedBox(height: 10),
            _ActionCard(
              icon: Icons.monitor_heart_outlined,
              title: 'Saisir ma glycémie',
              subtitle: 'Enregistrer une nouvelle mesure',
              onTap: () {},
            ),
            const SizedBox(height: 10),
            _ActionCard(
              icon: Icons.restaurant_outlined,
              title: 'Journal alimentaire',
              subtitle: 'Suivre vos repas',
              onTap: () {},
            ),
            const SizedBox(height: 10),
            _ActionCard(
              icon: Icons.bar_chart_outlined,
              title: 'Mes statistiques',
              subtitle: 'Voir l\'évolution de ma santé',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value, unit;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.unit, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 4),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(width: 4),
            Padding(padding: const EdgeInsets.only(bottom: 2),
                child: Text(unit, style: const TextStyle(color: Colors.white70, fontSize: 11))),
          ]),
        ]),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.c3, width: 1),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: AppColors.c2, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.c6, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
          ])),
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.c4),
        ]),
      ),
    );
  }
}
