import 'package:flutter/material.dart';
import 'dart:ui';
import 'register_screen.dart';
import 'services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  
  // ✅ Variables d'erreur
  String? _globalError;
  String? _emailError;
  String? _passwordError;

  // ✅ Validation des champs
  bool _validateFields() {
    setState(() {
      _globalError = null;
      _emailError = null;
      _passwordError = null;
    });

    bool isValid = true;
    String? firstError;

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _emailError = "L'email est requis";
      firstError ??= _emailError;
      isValid = false;
    } else if (!email.contains('@') || !email.contains('.')) {
      _emailError = "Email invalide";
      firstError ??= _emailError;
      isValid = false;
    }

    final password = _passwordController.text;
    if (password.isEmpty) {
      _passwordError = "Le mot de passe est requis";
      firstError ??= _passwordError;
      isValid = false;
    }

    setState(() => _globalError = firstError);

    return isValid;
  }

  // ✅ BANDEAU D'ERREUR GLOBAL (style glassmorphism)
  Widget _buildErrorBanner(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color.fromARGB(255, 229, 24, 24).withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontFamily: 'EncodeSansSemiExpanded',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Champ avec style adouci (même que RegisterScreen)
  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool obscure = false,
    VoidCallback? onToggle,
    TextInputType keyboardType = TextInputType.text,
    String? errorText,
  }) {
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'EncodeSansSemiExpanded',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(hasError ? 0.7 : 1),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                obscureText: obscure,
                keyboardType: keyboardType,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  hintText: '',
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -4),
              child: GestureDetector(
                onTap: onToggle,
                child: Icon(icon, color: Colors.white, size: 24),
              ),
            ),
          ],
        ),
        Container(
          height: hasError ? 2 : 1,
          color: Colors.white.withOpacity(hasError ? 0.9 : 1),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              // Fond blanc avec illustration en haut
              Column(
                children: [
                  // Flèche retour
                  SafeArea(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  // Illustration
                  Image.asset(
                    'assets/images/login_illustration.png',
                    height: 280,
                    fit: BoxFit.contain,
                  ),
                ],
              ),

              // Cadre bleu connexion en bas
              Positioned(
                left: 0,
                right: 0,
                top: 400,
                bottom: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(23),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0085C2),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(23),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            offset: const Offset(0, -2),
                            blurRadius: 4,
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(0.4),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Titre CONNEXION centré
                          Center(
                            child: Text(
                              'CONNEXION',
                              style: TextStyle(
                                fontFamily: 'AkiraExpanded',
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Ligne séparatrice
                          Container(
                            height: 1,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 24),

                          // ✅ BANDEAU D'ERREUR GLOBAL
                          if (_globalError != null) _buildErrorBanner(_globalError!),

                          // Champ Email
                          _buildField(
                            label: 'Email',
                            controller: _emailController,
                            icon: Icons.alternate_email,
                            keyboardType: TextInputType.emailAddress,
                            errorText: _emailError,
                          ),
                          const SizedBox(height: 20),

                          // Champ Mot de passe
                          _buildField(
                            label: 'Mot de passe',
                            controller: _passwordController,
                            icon: _obscurePassword
                                ? Icons.lock_outline
                                : Icons.lock_open_outlined,
                            obscure: _obscurePassword,
                            onToggle: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            errorText: _passwordError,
                          ),
                          const SizedBox(height: 28),

                          // Bouton Suivant
                          Center(
                            child: GestureDetector(
                              onTap: () async {
                                // ✅ Validation avant d'appeler l'API
                                if (!_validateFields()) {
                                  return;
                                }

                                final result = await AuthService.login(
                                  email: _emailController.text.trim(),
                                  password: _passwordController.text,
                                );

                                if (!mounted) return;

                                if (result['success'] == true) {
                                  Navigator.pushReplacementNamed(context, '/home');
                                } else {
                                  // ✅ Gestion élégante des erreurs serveur
                                  String errorMessage = result['message'] ?? 'Email ou mot de passe incorrect';
                                  setState(() => _globalError = errorMessage);

                                  if (errorMessage.toLowerCase().contains('email')) {
                                    setState(() => _emailError = errorMessage);
                                  } else if (errorMessage.toLowerCase().contains('mot de passe') ||
                                      errorMessage.toLowerCase().contains('password')) {
                                    setState(() => _passwordError = errorMessage);
                                  }
                                }
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(100),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                  child: Container(
                                    width: 133,
                                    height: 37,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'Suivant',
                                        style: TextStyle(
                                          fontFamily: 'EncodeSansSemiExpanded',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Pas de compte
                          Center(
                            child: Column(
                              children: [
                                const Text(
                                  'Pas de compte?',
                                  style: TextStyle(
                                    fontFamily: 'EncodeSansSemiExpanded',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const RegisterScreen(),
                                    ),
                                  ),
                                  child: const Text(
                                    "S'inscrire.",
                                    style: TextStyle(
                                      fontFamily: 'EncodeSansSemiExpanded',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      decoration: TextDecoration.underline,
                                      decorationColor: Colors.white,
                                      decorationThickness: 2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}