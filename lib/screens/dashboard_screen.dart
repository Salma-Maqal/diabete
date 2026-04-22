// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:image_picker/image_picker.dart';
import '../app_colors.dart';
import '../user_session.dart';

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
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
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
        height: 65,
        color: AppColors.c6,
        backgroundColor: Colors.transparent,
        buttonBackgroundColor: AppColors.c5,
        animationDuration: const Duration(milliseconds: 300),
        animationCurve: Curves.easeInOut,
        items: const [
          Icon(Icons.home_rounded, size: 28, color: Colors.white),
          Icon(Icons.monitor_heart_rounded, size: 28, color: Colors.white),
          Icon(Icons.restaurant_rounded, size: 28, color: Colors.white),
          Icon(Icons.person_rounded, size: 28, color: Colors.white),
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: double.infinity, padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.c6, borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Bonjour, $name 👋', style: const TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 4),
            const Text('Bienvenue sur CalmSugar',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Row(children: [
              _StatCard(label: 'Glycémie', value: '5.4', unit: 'mmol/L', color: AppColors.c3),
              const SizedBox(width: 10),
              _StatCard(label: 'Dernier repas', value: '2h', unit: 'ago', color: AppColors.c4),
            ]),
          ]),
        ),
        const SizedBox(height: 24),
        const Text('Actions rapides',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        const SizedBox(height: 12),
        _ActionCard(icon: Icons.person_add_outlined, title: 'Ajouter un accompagnant',
            subtitle: 'Inviter un proche à vous suivre',
            onTap: () => Navigator.pushNamed(context, '/add-companion')),
        const SizedBox(height: 10),
        _ActionCard(icon: Icons.monitor_heart_outlined, title: 'Saisir ma glycémie',
            subtitle: 'Enregistrer une nouvelle mesure', onTap: () {}),
        const SizedBox(height: 10),
        _ActionCard(icon: Icons.restaurant_outlined, title: 'Journal alimentaire',
            subtitle: 'Suivre vos repas', onTap: () {}),
        const SizedBox(height: 10),
        _ActionCard(icon: Icons.bar_chart_outlined, title: 'Mes statistiques',
            subtitle: "Voir l'évolution de ma santé", onTap: () {}),
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: double.infinity, padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.c5, AppColors.c6]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("Glycémie aujourd'hui", style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 6),
            const Text('5.4 mmol/L',
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
              child: const Text('✅ Dans la plage normale', style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ]),
        ),
        const SizedBox(height: 24),
        const Text('Historique du jour',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        const SizedBox(height: 12),
        ...entries.map((e) {
          final isHigh = (e['value'] as double) > 7.0;
          return Container(
            margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isHigh ? Colors.orange.shade200 : AppColors.c3),
            ),
            child: Row(children: [
              Container(width: 44, height: 44,
                decoration: BoxDecoration(
                  color: isHigh ? Colors.orange.shade50 : AppColors.c2,
                  borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.water_drop_rounded, color: isHigh ? Colors.orange : AppColors.c6)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e['time'] as String, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                Text('${e['value']} mmol/L',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isHigh ? Colors.orange.shade100 : AppColors.c2,
                  borderRadius: BorderRadius.circular(20)),
                child: Text(e['status'] as String,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                        color: isHigh ? Colors.orange.shade800 : AppColors.c6)),
              ),
            ]),
          );
        }),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.c6, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {},
            icon: const Icon(Icons.add_rounded),
            label: const Text('Nouvelle mesure', style: TextStyle(fontWeight: FontWeight.w700)),
          )),
      ]),
    );
  }
}

// ══════════════════════════════════════════
// PAGE 3 : Repas
// ══════════════════════════════════════════
class _RepasPage extends StatelessWidget {
  const _RepasPage();
  @override
  Widget build(BuildContext context) {
    final meals = [
      {'title': 'Petit-déjeuner', 'icon': Icons.free_breakfast_rounded, 'calories': '320 kcal', 'time': '07:30', 'plat': 'Msemen',   'glucides': '24.6 g'},
      {'title': 'Déjeuner',       'icon': Icons.lunch_dining_rounded,    'calories': '580 kcal', 'time': '12:30', 'plat': 'Couscous', 'glucides': '46.4 g'},
      {'title': 'Goûter',         'icon': Icons.cookie_rounded,          'calories': '150 kcal', 'time': '16:00', 'plat': 'Sellou',   'glucides': '13.8 g'},
      {'title': 'Collation',      'icon': Icons.apple_rounded,           'calories': '120 kcal', 'time': '18:00', 'plat': 'Zaalouk', 'glucides': '7.3 g'},
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: double.infinity, padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.c6, borderRadius: BorderRadius.circular(16)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _CalInfo(label: 'Consommées', value: '1020', unit: 'kcal'),
            Container(width: 1, height: 40, color: Colors.white30),
            _CalInfo(label: 'Objectif',   value: '1800', unit: 'kcal'),
            Container(width: 1, height: 40, color: Colors.white30),
            _CalInfo(label: 'Restantes',  value: '780',  unit: 'kcal'),
          ]),
        ),
        const SizedBox(height: 24),
        const Text("Repas d'aujourd'hui",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        const SizedBox(height: 12),
        ...meals.map((m) => Container(
          margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.c3)),
          child: Row(children: [
            Container(width: 44, height: 44,
                decoration: BoxDecoration(color: AppColors.c2, borderRadius: BorderRadius.circular(10)),
                child: Icon(m['icon'] as IconData, color: AppColors.c6)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(m['title'] as String,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              const SizedBox(height: 2),
              Row(children: [
                Text(m['time'] as String, style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
                const SizedBox(width: 8),
                Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.c3, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(m['plat'] as String, style: const TextStyle(fontSize: 11, color: AppColors.textGrey, fontStyle: FontStyle.italic)),
              ]),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.c2, borderRadius: BorderRadius.circular(20)),
                child: Text('🍚 ${m['glucides']} glucides',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textDark)),
              ),
            ])),
            const SizedBox(width: 8),
            Text(m['calories'] as String,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.c6)),
          ]),
        )),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.c6, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () => Navigator.pushNamed(context, '/add-meal'),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Ajouter un repas', style: TextStyle(fontWeight: FontWeight.w700)),
          )),
      ]),
    );
  }
}

class _CalInfo extends StatelessWidget {
  final String label, value, unit;
  const _CalInfo({required this.label, required this.value, required this.unit});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
    const SizedBox(height: 4),
    Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
    Text(unit,  style: const TextStyle(color: Colors.white60, fontSize: 10)),
  ]);
}

// ── Water Card (stateful pour interaction)
class _WaterCard extends StatefulWidget {
  @override
  State<_WaterCard> createState() => _WaterCardState();
}
class _WaterCardState extends State<_WaterCard> {
  int _glasses = 3; // valeur initiale démo
  static const int _max = 8;

  @override
  Widget build(BuildContext context) {
    final ml = _glasses * 250;
    final pct = _glasses / _max;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.c3, width: 1.5),
        boxShadow: [BoxShadow(color: AppColors.c3.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.water_drop_rounded, color: Color(0xFF1565C0), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Eau', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            Text('$_glasses/$_max verres — $ml ml',
                style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
          ])),
          Text(
            _glasses >= _max ? '🎉 Objectif!' : '${_max - _glasses} restants',
            style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: _glasses >= _max ? AppColors.c5 : AppColors.textGrey,
            ),
          ),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct, minHeight: 7,
            backgroundColor: const Color(0xFFE3F2FD),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_max, (i) {
            final filled = i < _glasses;
            return GestureDetector(
              onTap: () => setState(() => _glasses = (i + 1 == _glasses) ? 0 : i + 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 32, height: 38,
                decoration: BoxDecoration(
                  color: filled ? const Color(0xFFBBDEFB) : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: filled ? const Color(0xFF1976D2) : AppColors.c3, width: 1.5),
                ),
                child: Center(child: Text('💧', style: TextStyle(fontSize: filled ? 16 : 12))),
              ),
            );
          }),
        ),
      ]),
    );
  }
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

  // Stored XFile from image_picker — works on both web & mobile
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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
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

    // Delete
    if (source == null && _pickedFile != null) {
      setState(() => _pickedFile = null);
      await _session.save(photoPath: '');
      widget.onRefresh();
      return;
    }
    if (source == null) return;

    setState(() => _pickingImage = true);
    try {
      final picked = await ImagePicker().pickImage(
          source: source, imageQuality: 85, maxWidth: 600);
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
      child: Column(children: [

        // ── Hero card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [AppColors.c6, AppColors.c5],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: AppColors.c6.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Column(children: [
            const SizedBox(height: 28),

            // Avatar + edit button
            Stack(alignment: Alignment.bottomRight, children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  color: AppColors.c4,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12)],
                ),
                child: ClipOval(
                  child: _pickedFile != null
                      ? _XFileImage(file: _pickedFile!, size: 100)
                      : _AvatarInitials(name: name),
                ),
              ),
              GestureDetector(
                onTap: _pickingImage ? null : _pickPhoto,
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6)]),
                  child: _pickingImage
                      ? const Padding(padding: EdgeInsets.all(6),
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.c6))
                      : const Icon(Icons.camera_alt_rounded, size: 17, color: AppColors.c6),
                ),
              ),
            ]),

            const SizedBox(height: 14),
            Text(name,
                style: const TextStyle(color: Colors.white, fontSize: 20,
                    fontWeight: FontWeight.w800, letterSpacing: 0.3)),
            const SizedBox(height: 4),
            Text(email, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.verified_rounded, color: Colors.white, size: 14),
                SizedBox(width: 5),
                Text('Type 2 — Suivi actif',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ),
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                _ProfileStat(value: '12', label: 'Semaines'),
                _HDivider(),
                _ProfileStat(value: '84', label: 'Mesures'),
                _HDivider(),
                _ProfileStat(value: '5.4', label: 'Moy. mmol'),
              ]),
            ),
            const SizedBox(height: 20),
          ]),
        ),

        const SizedBox(height: 24),
        _SectionTitle(label: 'Mon compte'),
        const SizedBox(height: 10),
        _ProfilItem(icon: Icons.person_outline_rounded, title: 'Informations personnelles',
            subtitle: name, onTap: () {}),
        _ProfilItem(icon: Icons.monitor_heart_outlined, title: 'Paramètres de santé',
            subtitle: 'Type, poids, glycémie cible',
            onTap: () => Navigator.pushNamed(context, '/health-info')),
        _ProfilItem(icon: Icons.group_outlined, title: 'Mes accompagnants',
            subtitle: 'Gérer vos proches',
            onTap: () => Navigator.pushNamed(context, '/add-companion')),

        const SizedBox(height: 16),
        _SectionTitle(label: 'Préférences'),
        const SizedBox(height: 10),
        _ProfilItem(icon: Icons.notifications_outlined, title: 'Notifications',
            subtitle: 'Rappels, alertes glycémie', onTap: () {}),
        _ProfilItem(icon: Icons.language_outlined, title: 'Langue',
            subtitle: 'Français', onTap: () {}),
        _ProfilItem(icon: Icons.lock_outline_rounded, title: 'Sécurité',
            subtitle: 'Mot de passe, 2FA', onTap: () {}),

        const SizedBox(height: 16),
        GestureDetector(
          onTap: () async {
            await _session.clear();
            if (context.mounted) Navigator.pushReplacementNamed(context, '/welcome');
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.shade100)),
            child: Row(children: [
              Container(width: 42, height: 42,
                  decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.logout_rounded, color: Colors.red, size: 20)),
              const SizedBox(width: 14),
              const Expanded(child: Text('Se déconnecter',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.red))),
              Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Colors.red.shade300),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ── XFile image — works on BOTH web and mobile via readAsBytes
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
  void initState() {
    super.initState();
    _bytesFuture = widget.file.readAsBytes();
  }
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _bytesFuture,
      builder: (ctx, snap) {
        if (snap.hasData) {
          return Image.memory(snap.data!, fit: BoxFit.cover,
              width: widget.size, height: widget.size);
        }
        return Container(color: AppColors.c4,
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 36));
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
        style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800))),
  );
}

class _ProfileStat extends StatelessWidget {
  final String value, label;
  const _ProfileStat({required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [
    Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
  ]));
}

class _HDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 32, color: Colors.white24);
}

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Text(label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
            color: AppColors.textGrey, letterSpacing: 0.5)),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.c2),
        boxShadow: [BoxShadow(color: AppColors.c2.withOpacity(0.4), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(width: 42, height: 42,
            decoration: BoxDecoration(color: AppColors.c2, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.c6, size: 20)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          if (subtitle != null) ...[
            const SizedBox(height: 1),
            Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ])),
        const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: AppColors.c4),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(children: [
          Icon(icon, color: c, size: 22),
          const SizedBox(width: 16),
          Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c)),
        ]),
      ),
    );
  }
}

// Shared widgets
class _StatCard extends StatelessWidget {
  final String label, value, unit;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.unit, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.c3, width: 1)),
      child: Row(children: [
        Container(width: 44, height: 44,
            decoration: BoxDecoration(color: AppColors.c2, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.c6, size: 22)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
        ])),
        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.c4),
      ]),
    ),
  );
}
