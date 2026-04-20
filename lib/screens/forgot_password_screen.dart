import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../widgets/common_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl    = TextEditingController();
  final _codeCtrl     = TextEditingController();
  final _newPassCtrl  = TextEditingController();
  final _confirmCtrl  = TextEditingController();

  // Étapes : 0 = saisir email, 1 = saisir code, 2 = nouveau mot de passe, 3 = succès
  int _step = 0;
  bool _loading = false;
  bool _obscureNew     = true;
  bool _obscureConfirm = true;
  String? _error;

  // ── Étape 0 : envoyer le code ─────────────────────────────
  void _sendCode() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Veuillez saisir une adresse e-mail valide.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() { _loading = false; _step = 1; });
  }

  // ── Étape 1 : vérifier le code ────────────────────────────
  void _verifyCode() async {
    final code = _codeCtrl.text.trim();
    if (code.length < 4) {
      setState(() => _error = 'Code invalide. Vérifiez votre e-mail.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() { _loading = false; _step = 2; });
  }

  // ── Étape 2 : enregistrer le nouveau mot de passe ─────────
  void _savePassword() async {
    final np = _newPassCtrl.text;
    final cp = _confirmCtrl.text;
    if (np.length < 6) {
      setState(() => _error = 'Le mot de passe doit contenir au moins 6 caractères.');
      return;
    }
    if (np != cp) {
      setState(() => _error = 'Les mots de passe ne correspondent pas.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() { _loading = false; _step = 3; });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ── Helper : barre de progression ─────────────────────────
  Widget _stepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
      child: Row(
        children: List.generate(3, (i) {
          final done    = i < _step;
          final current = i == _step;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 4,
                    decoration: BoxDecoration(
                      color: done || current ? AppColors.c6 : AppColors.c3,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                if (i < 2) const SizedBox(width: 6),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Étape 0 : formulaire e-mail ───────────────────────────
  Widget _buildStepEmail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Saisissez votre adresse e-mail et nous vous enverrons un code de vérification.',
          style: TextStyle(fontSize: 13, color: AppColors.textGrey, height: 1.5),
        ),
        const SizedBox(height: 24),
        AuthField(
          label: 'E-mail',
          controller: _emailCtrl,
          hint: 'exemple@gmail.com',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
        ),
        const SizedBox(height: 32),
        PrimaryButton(
          label: 'Envoyer le code',
          onPressed: _sendCode,
          loading: _loading,
        ),
      ],
    );
  }

  // ── Étape 1 : formulaire code ─────────────────────────────
  Widget _buildStepCode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 13, color: AppColors.textGrey, height: 1.5),
            children: [
              const TextSpan(text: 'Un code a été envoyé à '),
              TextSpan(
                text: _emailCtrl.text.trim(),
                style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AuthField(
          label: 'Code de vérification',
          controller: _codeCtrl,
          hint: '1234',
          keyboardType: TextInputType.number,
          prefixIcon: Icons.pin_outlined,
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () => setState(() { _step = 0; _codeCtrl.clear(); _error = null; }),
            child: const Text(
              'Renvoyer le code',
              style: TextStyle(color: AppColors.c6, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 28),
        PrimaryButton(
          label: 'Vérifier le code',
          onPressed: _verifyCode,
          loading: _loading,
        ),
      ],
    );
  }

  // ── Étape 2 : nouveau mot de passe ────────────────────────
  Widget _buildStepNewPassword() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choisissez un nouveau mot de passe sécurisé.',
          style: TextStyle(fontSize: 13, color: AppColors.textGrey, height: 1.5),
        ),
        const SizedBox(height: 24),
        AuthField(
          label: 'Nouveau mot de passe',
          controller: _newPassCtrl,
          hint: '••••••••',
          obscure: _obscureNew,
          prefixIcon: Icons.lock_outline,
          suffix: IconButton(
            icon: Icon(
              _obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: AppColors.textGrey, size: 20,
            ),
            onPressed: () => setState(() => _obscureNew = !_obscureNew),
          ),
        ),
        const SizedBox(height: 14),
        AuthField(
          label: 'Confirmer le mot de passe',
          controller: _confirmCtrl,
          hint: '••••••••',
          obscure: _obscureConfirm,
          prefixIcon: Icons.lock_outline,
          suffix: IconButton(
            icon: Icon(
              _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: AppColors.textGrey, size: 20,
            ),
            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
        ),
        const SizedBox(height: 32),
        PrimaryButton(
          label: 'Enregistrer',
          onPressed: _savePassword,
          loading: _loading,
        ),
      ],
    );
  }

  // ── Étape 3 : succès ──────────────────────────────────────
  Widget _buildStepSuccess() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.c2,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: AppColors.c6, size: 44),
          ),
          const SizedBox(height: 24),
          const Text(
            'Mot de passe modifié !',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark),
          ),
          const SizedBox(height: 10),
          const Text(
            'Votre mot de passe a été réinitialisé avec succès.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textGrey, height: 1.5),
          ),
          const SizedBox(height: 40),
          PrimaryButton(
            label: 'Se connecter',
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            loading: false,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Mot de passe oublié', 'Vérification', 'Nouveau mot de passe', 'Succès'];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WaveHeader(
            title: titles[_step],
            onBack: () {
              if (_step == 0) {
                Navigator.pop(context);
              } else {
                setState(() { _step--; _error = null; });
              }
            },
          ),

          // Barre de progression (visible seulement sur étapes 0-2)
          if (_step < 3) _stepIndicator(),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message d'erreur
                  if (_error != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.error.withOpacity(0.4)),
                      ),
                      child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                    ),
                  ],

                  // Contenu selon l'étape
                  if (_step == 0) _buildStepEmail(),
                  if (_step == 1) _buildStepCode(),
                  if (_step == 2) _buildStepNewPassword(),
                  if (_step == 3) _buildStepSuccess(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}