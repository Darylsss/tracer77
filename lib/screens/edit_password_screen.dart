import 'package:flutter/material.dart';
import 'services/auth_service.dart';

class EditPasswordScreen extends StatefulWidget {
  const EditPasswordScreen({super.key});

  @override
  State<EditPasswordScreen> createState() => _EditPasswordScreenState();
}

class _EditPasswordScreenState extends State<EditPasswordScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _error;
  bool _success = false;

  static const Color blue = Color(0xFF0185FF);

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_currentController.text.isEmpty ||
        _newController.text.isEmpty ||
        _confirmController.text.isEmpty) {
      setState(() => _error = 'Tous les champs sont requis');
      return;
    }
    if (_newController.text.length < 6) {
      setState(() => _error = 'Le nouveau mot de passe doit contenir au moins 6 caractères');
      return;
    }
    if (_newController.text != _confirmController.text) {
      setState(() => _error = 'Les mots de passe ne correspondent pas');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await AuthService.updatePassword(
      currentPassword: _currentController.text,
      newPassword: _newController.text,
    );

    setState(() => _loading = false);

    if (result['success'] == true) {
      setState(() => _success = true);
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context);
    } else {
      setState(() => _error = result['message'] ?? 'Erreur lors de la mise à jour');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.black54, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Modifier le mot de passe',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            const Divider(height: 1),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.red, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 12,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (_success) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Mot de passe mis à jour avec succès !',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 12,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE8E8E8)),
                      ),
                      child: Column(
                        children: [
                          _passwordField(
                            label: 'Mot de passe actuel',
                            controller: _currentController,
                            obscure: _obscureCurrent,
                            onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                          ),
                          const Divider(height: 1),
                          _passwordField(
                            label: 'Nouveau mot de passe',
                            controller: _newController,
                            obscure: _obscureNew,
                            onToggle: () => setState(() => _obscureNew = !_obscureNew),
                          ),
                          const Divider(height: 1),
                          _passwordField(
                            label: 'Confirmer le nouveau mot de passe',
                            controller: _confirmController,
                            obscure: _obscureConfirm,
                            onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                            isLast: true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Mettre à jour',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _passwordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(top: 12, bottom: isLast ? 12 : 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 11,
              color: Colors.black45,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscure,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onToggle,
                child: Icon(
                  obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.black26,
                  size: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}