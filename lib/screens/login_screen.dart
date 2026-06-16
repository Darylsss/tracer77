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
                          // Label Email
                          const Text(
                            'Email',
                            style: TextStyle(
                              fontFamily: 'EncodeSansSemiExpanded',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Champ Email
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    hintText: '',
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.alternate_email,
                                color: Colors.white,
                                size: 24,
                              ),
                            ],
                          ),
                          // Ligne sous email
                          Container(height: 1, color: Colors.white),
                          const SizedBox(height: 20),
                          // Label Mot de passe
                          const Text(
                            'Mot de passe',
                            style: TextStyle(
                              fontFamily: 'EncodeSansSemiExpanded',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Champ Mot de passe
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    hintText: '',
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                                child: Icon(
                                  _obscurePassword
                                      ? Icons.lock_outline
                                      : Icons.lock_open_outlined,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                          // Ligne sous mot de passe
                          Container(height: 1, color: Colors.white),
                          const SizedBox(height: 28),
                          // Bouton Suivant
                          Center(
                            child: GestureDetector(
                              onTap: () async {
  final result = await AuthService.login(
    email: _emailController.text.trim(),
    password: _passwordController.text,
  );

  if (!mounted) return;

  if (result['success'] == true) {
    Navigator.pushReplacementNamed(context, '/home');
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'] ?? 'Email ou mot de passe incorrect')),
    );
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
        child: Text(
          "S'inscrire.",
          style: const TextStyle(
            fontFamily: 'EncodeSansSemiExpanded',
            fontSize: 18,              // Taille augmentée (14 -> 18)
            fontWeight: FontWeight.w900, // Déjà en gras max
            color: Colors.white,
            decoration: TextDecoration.underline, // Ajout du soulignement
            decorationColor: Colors.white, // Couleur du soulignement
            decorationThickness: 2,     // Épaisseur du soulignement
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