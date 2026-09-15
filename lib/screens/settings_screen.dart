import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'services/auth_service.dart';
import 'account_screen.dart';
import 'edit_space_screen.dart';
import 'places_overview_screen.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _partagePosition = false;
  bool _chargementPreference = true;
  String? _erreurChargement;

  @override
  void initState() {
    super.initState();
    _chargerPreferences();
  }

  Future<void> _chargerPreferences() async {
    print('🔵 Chargement des préférences...');
    
    setState(() {
      _chargementPreference = true;
      _erreurChargement = null;
    });

    try {
      // D'abord essayer le cache pour un affichage rapide
      final cachedUser = await AuthService.getCachedUser();
      if (cachedUser != null) {
        print('🟢 Utilisateur chargé depuis le cache');
        if (mounted) {
          setState(() {
            final value = cachedUser['partage_position'];
          _partagePosition = value is bool ? value : (value == 1 || value == true);
          _chargementPreference = false;
          });
        }
      }
      
      // Puis rafraîchir depuis l'API en arrière-plan
      final user = await AuthService.getUser();
      if (mounted && user != null) {
        print('🟢 Utilisateur chargé depuis l\'API');
        setState(() {
         final value = user['partage_position'];
        _partagePosition = value is bool ? value : (value == 1 || value == true);
        _chargementPreference = false;
        });
      } else if (mounted && cachedUser == null) {
        // Si l'API échoue et qu'on n'a pas de cache
        setState(() {
          _erreurChargement = 'Impossible de charger les préférences';
          _chargementPreference = false;
        });
      }
    } catch (e) {
      print('🔴 Erreur lors du chargement: $e');
      if (mounted) {
        setState(() {
          _erreurChargement = 'Erreur de connexion au serveur';
          _chargementPreference = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar avec bouton de rafraîchissement
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
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Color(0xFF0185FF), size: 24),
                    onPressed: _chargerPreferences,
                    tooltip: 'Rafraîchir',
                  ),
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
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditSpaceScreen()),
    );
  },
),

                    _settingsTile(
                      icon: Icons.account_balance_outlined,
                      iconColor: const Color(0xFF0185FF),
                      title: 'Lieux sur la carte',
                      subtitle: 'Ajoutez d\'autres lieux pour savoir quand\nvos proches s\'y rendent.',
                      titleWeight: FontWeight.w700,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PlacesOverviewScreen()),
                        );
                      },
                    ),

                    const SizedBox(height: 8),
                    const Divider(indent: 16, endIndent: 16, color: Color(0xFFE0E0E0)),
                    const SizedBox(height: 8),

                    // Section Confidentialité
                    _sectionLabel('Confidentialité'),
                    const SizedBox(height: 4),

                    // État de chargement
                    if (_chargementPreference) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ] else if (_erreurChargement != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _erreurChargement!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 14,
                                      fontFamily: 'Montserrat',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _chargerPreferences,
                              child: const Text(
                                'Réessayer',
                                style: TextStyle(color: Color(0xFF0185FF)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Switch de partage de position
                      SwitchListTile(
                        title: const Text(
                          'Partager ma position',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text(
                          'Les autres membres de la famille pourront voir\nvotre position en temps réel.',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 12,
                            color: Colors.black45,
                          ),
                        ),
                        value: _partagePosition,
                        activeColor: const Color(0xFF0185FF),
                        onChanged: _onTogglePositionSharing,
                      ),
                    ],

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
                        // TODO: Naviguer vers Notifications
                      },
                    ),

                    _settingsTile(
                      icon: Icons.info_outline_rounded,
                      iconColor: const Color(0xFF0185FF),
                      title: 'A propos de l\'application',
                      titleWeight: FontWeight.w700,
                      onTap: () {
                        // TODO: Naviguer vers À propos
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
                      onTap: _onLogout,
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

  // Méthode pour gérer le toggle de partage de position
  Future<void> _onTogglePositionSharing(bool newValue) async {
    // Optimistic update pour une meilleure UX
    setState(() {
      _partagePosition = newValue;
    });

    try {
      final result = await AuthService.togglePositionSharing();
      
      if (result['success'] == true && mounted) {
        // Mise à jour réussie
        setState(() {
          _partagePosition = result['partage_position'] ?? false;
        });
        
        // Afficher un message de confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _partagePosition 
                ? ' Position partagée avec la famille' 
                : '🔒 Partage de position désactivé',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: _partagePosition ? const Color.fromARGB(255, 63, 92, 186) : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        // Erreur - on recharge la vraie valeur
        await _chargerPreferences();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Impossible de modifier ce paramètre. Réessaie.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        await _chargerPreferences();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Erreur de connexion. Réessaie plus tard.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Méthode pour la déconnexion
  Future<void> _onLogout() async {
    try {
      await AuthService.clearToken();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la déconnexion'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
      borderRadius: BorderRadius.circular(8),
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
            const Icon(Icons.chevron_right, color: Colors.black26, size: 20),
          ],
        ),
      ),
    );
  }
}