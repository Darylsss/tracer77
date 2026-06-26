import 'package:flutter/material.dart';
import 'dart:ui';
import 'login_screen.dart';
import 'services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  
  // ✅ Une seule variable d'erreur globale + erreurs par champ
  String? _globalError;
  String? _nomError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  // ✅ 2. MODIFICATION DE _validateFields()
  bool _validateFields() {
    setState(() {
      _globalError = null;
      _nomError = null;
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
    });

    bool isValid = true;
    String? firstError;

    if (_nomController.text.trim().isEmpty) {
      _nomError = 'Le nom est requis';
      firstError ??= _nomError;
      isValid = false;
    }

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
    } else if (password.length < 6) {
      _passwordError = "Le mot de passe doit contenir au moins 6 caractères";
      firstError ??= _passwordError;
      isValid = false;
    }

    final confirmPassword = _confirmPasswordController.text;
    if (confirmPassword.isEmpty) {
      _confirmPasswordError = "Veuillez confirmer le mot de passe";
      firstError ??= _confirmPasswordError;
      isValid = false;
    } else if (password != confirmPassword) {
      _confirmPasswordError = "Les mots de passe ne correspondent pas";
      firstError ??= _confirmPasswordError;
      isValid = false;
    }

    setState(() => _globalError = firstError);

    return isValid;
  }

  // ✅ 3. WIDGET BANDEAU D'ERREUR GLOBAL
  Widget _buildErrorBanner(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.4),
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

  // ✅ 4. _buildField ADOUCI (plus de rouge agressif)
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

  // ✅ NOTIFICATION MODERNE
  void _showSuccessNotification(String message) {
    if (!mounted) return;
    
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 60,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF00C853).withOpacity(0.9),
                      const Color(0xFF00E676).withOpacity(0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF00C853),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Félicitations !',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              fontFamily: 'EncodeSansSemiExpanded',
                              letterSpacing: 0.3,
                            ),
                          ),
                          Text(
                            message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontFamily: 'EncodeSansSemiExpanded',
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
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
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
              Column(
                children: [
                  SafeArea(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  Image.asset(
                    'assets/images/register_illustration.png',
                    height: 190,
                    fit: BoxFit.contain,
                  ),
                  const Spacer(),
                ],
              ),

              Positioned(
                left: 0,
                right: 0,
                top: 310,
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
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'INSCRIPTION',
                              style: TextStyle(
                                fontFamily: 'AkiraExpanded',
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Créer un compte pour commencer',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Container(height: 1, color: Colors.white),
                            const SizedBox(height: 24),

                            // ✅ 5. BANDEAU D'ERREUR GLOBAL (affiché en haut des champs)
                            if (_globalError != null) _buildErrorBanner(_globalError!),

                            _buildField(
                              label: 'Nom',
                              controller: _nomController,
                              icon: Icons.badge_outlined,
                              errorText: _nomError,
                            ),
                            const SizedBox(height: 20),

                            _buildField(
                              label: 'Email',
                              controller: _emailController,
                              icon: Icons.alternate_email,
                              keyboardType: TextInputType.emailAddress,
                              errorText: _emailError,
                            ),
                            const SizedBox(height: 20),

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
                            const SizedBox(height: 20),

                            _buildField(
                              label: 'Confirmer mot de passe',
                              controller: _confirmPasswordController,
                              icon: _obscureConfirm
                                  ? Icons.check_circle_outline
                                  : Icons.check_circle,
                              obscure: _obscureConfirm,
                              onToggle: () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              ),
                              errorText: _confirmPasswordError,
                            ),
                            const SizedBox(height: 32),

                            ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                child: GestureDetector(
                                  onTap: () async {
                                    if (!_validateFields()) {
                                      return;
                                    }

                                    final result = await AuthService.register(
                                      nom: _nomController.text.trim(),
                                      email: _emailController.text.trim(),
                                      password: _passwordController.text,
                                    );

                                    if (!mounted) return;

                                    if (result['success'] == true) {
                                      _showSuccessNotification(
                                        'Inscription réussie ! Veuillez vous connecter.'
                                      );
                                      
                                      Future.delayed(const Duration(seconds: 2), () {
                                        if (mounted) {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => const LoginScreen(),
                                            ),
                                          );
                                        }
                                      });
                                    } else {
                                      // ✅ 6. GESTION DES ERREURS SERVEUR
                                      String errorMessage = result['message'] ?? 'Erreur lors de l\'inscription';
                                      setState(() => _globalError = errorMessage);

                                      if (errorMessage.toLowerCase().contains('email')) {
                                        setState(() => _emailError = errorMessage);
                                      } else if (errorMessage.toLowerCase().contains('nom')) {
                                        setState(() => _nomError = errorMessage);
                                      } else if (errorMessage.toLowerCase().contains('mot de passe') ||
                                          errorMessage.toLowerCase().contains('password')) {
                                        setState(() => _passwordError = errorMessage);
                                      }
                                    }
                                  },
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
                            const SizedBox(height: 20),

                            const Text(
                              'Vous avez déjà un compte?',
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
                                  builder: (_) => const LoginScreen(),
                                ),
                              ),
                              child: const Text(
                                'Se connecter.',
                                style: TextStyle(
                                  fontFamily: 'EncodeSansSemiExpanded',
                                  fontSize: 15,
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
    _nomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}