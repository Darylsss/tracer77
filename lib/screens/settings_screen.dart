import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'services/auth_service.dart';
import 'account_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
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
                      'Paramètres',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFE0E0E0)),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const SizedBox(height: 24),

                    // Section Espace famille
                    _sectionLabel('Paramètres de votre espace - famille'),

                    const SizedBox(height: 12),

                    _settingsTile(
                      icon: Icons.circle_outlined,
                      iconColor: const Color(0xFF0185FF),
                      title: 'Modifier votre espace',
                      titleWeight: FontWeight.w700,
                      onTap: () {},
                    ),

                    _settingsTile(
                      icon: Icons.account_balance_outlined,
                      iconColor: const Color(0xFF0185FF),
                      title: 'Lieux sur la carte',
                      subtitle: 'Ajoutez d\'autres lieux pour savoir quand\nvos proches s\'y rendent.',
                      titleWeight: FontWeight.w700,
                      onTap: () {},
                    ),

                    const SizedBox(height: 8),
                    const Divider(indent: 16, endIndent: 16, color: Color(0xFFE0E0E0)),
                    const SizedBox(height: 8),

                    // Section Paramètres généraux
                    _sectionLabel('Paramètres généraux'),

                    const SizedBox(height: 12),

                    _settingsTile(
                      icon: Icons.person_outline_rounded,
                      iconColor: const Color(0xFF0185FF),
                      title: 'Mon compte',
                      titleWeight: FontWeight.w700,
                      onTap: () {
                        Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AccountScreen()),
    );
                      },
                    ),

                    _settingsTile(
                      icon: Icons.notifications_outlined,
                      iconColor: const Color(0xFF0185FF),
                      title: 'Paramètres des notifications',
                      titleWeight: FontWeight.w700,
                      onTap: () {
                        // TODO: naviguer vers Notifications
                      },
                    ),

                    _settingsTile(
                      icon: Icons.info_outline_rounded,
                      iconColor: const Color(0xFF0185FF),
                      title: 'A propos de l\'application',
                      titleWeight: FontWeight.w700,
                      onTap: () {
                        // TODO: naviguer vers À propos
                      },
                    ),

                    const SizedBox(height: 4),

                    // Déconnexion
                    _settingsTile(
                      icon: Icons.logout_rounded,
                      iconColor: Colors.red,
                      title: 'Se déconnecter',
                      titleColor: Colors.red,
                      titleWeight: FontWeight.w700,
                      onTap: () async {
                        await AuthService.clearToken();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Color? titleColor,
    FontWeight titleWeight = FontWeight.w600,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 15,
                      fontWeight: titleWeight,
                      color: titleColor ?? Colors.black87,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.black45,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}