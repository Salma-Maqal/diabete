import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_colors.dart';
import '../widgets/common_widgets.dart';

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});
  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final List<TextEditingController> _ctrls = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(4, (_) => FocusNode());
  bool _loading = false;

  void _verify() async {
    final code = _ctrls.map((c) => c.text).join();
    if (code.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Veuillez entrer le code complet'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Compte vérifié avec succès ✓'),
      backgroundColor: AppColors.c5,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    for (final n in _nodes) n.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          WaveHeader(title: 'Vérification', onBack: () => Navigator.pop(context)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(children: [
                const SizedBox(height: 16),
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(color: AppColors.c2, shape: BoxShape.circle),
                  child: Icon(Icons.mark_email_read_outlined, color: AppColors.c6, size: 38),
                ),
                const SizedBox(height: 24),
                const Text('Code de vérification',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                const SizedBox(height: 10),
                Text('Code envoyé à votre adresse email.\nVeuillez le saisir ci-dessous.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppColors.textGrey, height: 1.5)),
                const SizedBox(height: 36),
                // 4 code boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) => _CodeBox(
                    controller: _ctrls[i], focusNode: _nodes[i],
                    onChanged: (val) {
                      if (val.isNotEmpty && i < 3) _nodes[i + 1].requestFocus();
                      else if (val.isEmpty && i > 0) _nodes[i - 1].requestFocus();
                    },
                  )),
                ),
                const SizedBox(height: 36),
                PrimaryButton(label: 'Vérifier', onPressed: _verify, loading: _loading),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: const Text('Code renvoyé !'),
                      backgroundColor: AppColors.c5,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ));
                  },
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 13, color: AppColors.textGrey),
                      children: [
                        const TextSpan(text: "Pas reçu le code ? "),
                        TextSpan(text: 'Renvoyer',
                            style: TextStyle(color: AppColors.c6, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  const _CodeBox({required this.controller, required this.focusNode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58, height: 64,
      margin: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.c3, width: 1.5),
      ),
      child: TextField(
        controller: controller, focusNode: focusNode, onChanged: onChanged,
        keyboardType: TextInputType.number, textAlign: TextAlign.center,
        maxLength: 1, inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textDark),
        decoration: const InputDecoration(counterText: '', border: InputBorder.none),
      ),
    );
  }
}
