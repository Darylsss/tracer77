import 'package:flutter/material.dart';
import 'edit_name_screen.dart';
import 'edit_password_screen.dart';
import 'login_screen.dart';
import 'services/auth_service.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String _nom = '';
  String _email = '';
  bool _loading = true;

  static const Color blue = Color(0xFF0185FF);

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = await AuthService.getUser();
    setState(() {
      _nom = user?['nom'] ?? '';
      _email = user?['email'] ?? '';
      _loading = false;
    });
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Supprimer le compte',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        content: const Text(
          'Cette action est irréversible. Toutes vos données seront supprimées définitivement.',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 13,
            color: Colors.black54,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Annuler',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.deleteAccount();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text(
              'Supprimer',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w700,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

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
                      'Mon compte',
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

            _loading
                ? const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 28),

                          // Avatar
                          CircleAvatar(
                            radius: 42,
                            backgroundColor: const Color(0xFFECF6FF),
                            child: Text(
                              _nom.isNotEmpty ? _nom[0].toUpperCase() : '?',
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                                color: blue,
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          Text(
                            _nom,
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            _email,
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: Colors.black45,
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Section Informations
                          _sectionLabel('Informations personnelles'),
                          const SizedBox(height: 10),

                          _accountTile(
                            icon: Icons.person_outline_rounded,
                            label: 'Nom',
                            value: _nom,
                            onTap: () async {
                              final updated = await Navigator.push<String>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditNameScreen(currentName: _nom),
                                ),
                              );
                              if (updated != null) {
                                setState(() => _nom = updated);
                              }
                            },
                          ),

                          _accountTile(
                            icon: Icons.alternate_email_rounded,
                            label: 'Email',
                            value: _email,
                            showChevron: false,
                          ),

                          const SizedBox(height: 24),

                          // Section Sécurité
                          _sectionLabel('Sécurité'),
                          const SizedBox(height: 10),

                          _accountTile(
                            icon: Icons.lock_outline_rounded,
                            label: 'Modifier le mot de passe',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const EditPasswordScreen(),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 24),

                          // Section Danger
                          _sectionLabel('Zone de danger'),
                          const SizedBox(height: 10),

                          _accountTile(
                            icon: Icons.delete_outline_rounded,
                            label: 'Supprimer mon compte',
                            labelColor: Colors.red,
                            iconColor: Colors.red,
                            showChevron: false,
                            onTap: _confirmDeleteAccount,
                          ),

                          const SizedBox(height: 40),
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
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: blue,
          ),
        ),
      ),
    );
  }

  Widget _accountTile({
    required IconData icon,
    required String label,
    String? value,
    Color? labelColor,
    Color? iconColor,
    bool showChevron = true,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8E8E8)),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? const Color(0xFF0185FF), size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: labelColor ?? Colors.black87,
                    ),
                  ),
                  if (value != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showChevron)
              const Icon(Icons.chevron_right, color: Colors.black26, size: 20),
          ],
        ),
      ),
    );
  }
}