import 'package:flutter/material.dart';
import 'dart:ui';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fond ciel
          Image.asset(
            'assets/images/bg_sky.png',
            fit: BoxFit.cover,
          ),

          // ✅ AJOUTER CE CONTAINER POUR ASSOMBRIR
        Container(
          color: Colors.black.withOpacity(0.2), // Ajustez l'opacité (0.2 à 0.5)
        ),

          SafeArea(
            child: Stack(
              children: [
                // Carte glassmorphism (291x448, left:49, top:186)
                Align(
  alignment: Alignment.topCenter,
  child: Padding(
    padding: const EdgeInsets.only(top: 120),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 291,
          height: 475,
          decoration: BoxDecoration(
            color: const Color(0xFF6DA6D1).withOpacity(0.2),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'TRACER77',
                style: TextStyle(
                  fontFamily: 'AkiraExpanded',
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 20),
              Image.asset(
                'assets/images/globe.png',
                height: 290,
              ),
              const SizedBox(height: 20),
              const Text(
                'Localiser, protéger.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 16, right: 16),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    'Version 1.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                    ),
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

                // Bouton CONNEXION (left:32, top:662, w:144, h:48)
                Positioned(
  bottom: 100,
  left: 0,
  right: 0,
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 32),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildButton('Connexion', () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }),
        _buildButton('Inscription', () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegisterScreen()),
          );
        }),
      ],
    ),
  ),
),

                // Bouton INSCRIPTION (left:213, top:662, w:144, h:48)
                Positioned(
  bottom: 100,
  left: 0,
  right: 0,
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 32),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildButton('Connexion', () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }),
        _buildButton('Inscription', () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegisterScreen()),
          );
        }),
      ],
    ),
  ),
),
              ],
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildButton(String label, VoidCallback onPressed) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(23),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 144,
          height: 48,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 2, 106, 216),
            borderRadius: BorderRadius.circular(23),
          ),
          child: Stack(
            children: [
              // Highlight en haut (inset top white)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 24,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(23),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.25),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Ombre en bas (inset bottom dark)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 24,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(23),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Texte centré
              Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'AkiraExpanded',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}