import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
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
  String? _photoUrl;
  String _telephone = '';
  File? _localPhoto;
  bool _loading = true;
  bool _uploadingPhoto = false;
  String? _errorMessage;

  static const Color blue = Color(0xFF0185FF);

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    print('🔵 Chargement des infos utilisateur...');

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final cachedUser = await AuthService.getCachedUser();
      if (cachedUser != null) {
        print('🟢 Utilisateur chargé depuis le cache');
        setState(() {
          _nom = cachedUser['nom']?.toString() ?? 'Sans nom';
          _email = cachedUser['email']?.toString() ?? 'Email non disponible';
          _photoUrl = cachedUser['photo']?.toString();
          _telephone = cachedUser['telephone']?.toString() ?? '';
          _loading = false;
        });
      }

      final user = await AuthService.getUser();
      if (user != null) {
        print('🟢 Utilisateur chargé depuis l\'API');
        setState(() {
          _nom = user['nom']?.toString() ?? 'Sans nom';
          _email = user['email']?.toString() ?? 'Email non disponible';
          _photoUrl = user['photo']?.toString();
          _telephone = user['telephone']?.toString() ?? '';
          _loading = false;
        });
      } else if (cachedUser == null) {
        setState(() {
          _errorMessage = 'Impossible de charger vos informations';
          _loading = false;
        });
      }
    } catch (e) {
      print('🔴 Erreur chargement compte: $e');
      setState(() {
        _errorMessage = 'Erreur de connexion au serveur';
        _loading = false;
      });
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: blue),
              title: const Text('Choisir depuis la galerie', style: TextStyle(fontFamily: 'Montserrat')),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: blue),
              title: const Text('Prendre une photo', style: TextStyle(fontFamily: 'Montserrat')),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await picker.pickImage(source: source, imageQuality: 80, maxWidth: 800);
    if (picked == null) return;

    final file = File(picked.path);
    setState(() {
      _localPhoto = file;
      _uploadingPhoto = true;
    });

    final result = await AuthService.updatePhoto(file);

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _photoUrl = result['photo'];
        _localPhoto = null;
        _uploadingPhoto = false;
      });
    } else {
      setState(() {
        _localPhoto = null;
        _uploadingPhoto = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Erreur lors de l\'envoi de la photo.')),
      );
    }
  }

  void _editPhone() {
    final controller = TextEditingController(text: _telephone);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Numéro de téléphone',
          style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(hintText: '+229...'),
          style: const TextStyle(fontFamily: 'Montserrat'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler', style: TextStyle(fontFamily: 'Montserrat', color: Colors.black54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await AuthService.updatePhone(controller.text.trim());
              if (result['success'] == true && mounted) {
                setState(() => _telephone = controller.text.trim());
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result['message'] ?? 'Erreur.')),
                );
              }
            },
            child: const Text('Enregistrer', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w700, color: blue)),
          ),
        ],
      ),
    );
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
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Color(0xFF0185FF), size: 24),
                    onPressed: _loadUserInfo,
                    tooltip: 'Rafraîchir',
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFE0E0E0)),

            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF0185FF),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 16,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUserInfo,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0185FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Réessayer',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 28),

          // Avatar avec sélection de photo
          GestureDetector(
            onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
            child: SizedBox(
              width: 84,
              height: 84,
              child: Stack(
                children: [
                  Center(
                    child: _uploadingPhoto
                        ? const CircleAvatar(
                            radius: 42,
                            backgroundColor: Color(0xFFECF6FF),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: blue),
                            ),
                          )
                        : _localPhoto != null
                            ? CircleAvatar(
                                radius: 42,
                                backgroundImage: FileImage(_localPhoto!),
                              )
                            : (_photoUrl != null && _photoUrl!.isNotEmpty)
                                ? CircleAvatar(
                                    radius: 42,
                                    backgroundImage: NetworkImage(_photoUrl!),
                                  )
                                : CircleAvatar(
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
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(color: blue, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 15),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            _nom.isNotEmpty ? _nom : 'Sans nom',
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            _email.isNotEmpty ? _email : 'Email non disponible',
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Colors.black45,
            ),
          ),

          const SizedBox(height: 32),

          _sectionLabel('Informations personnelles'),
          const SizedBox(height: 10),

          _accountTile(
            icon: Icons.person_outline_rounded,
            label: 'Nom',
            value: _nom.isNotEmpty ? _nom : 'Non défini',
            onTap: () async {
              final updated = await Navigator.push<String>(
                context,
                MaterialPageRoute(
                  builder: (_) => EditNameScreen(currentName: _nom),
                ),
              );
              if (updated != null && updated.isNotEmpty) {
                setState(() => _nom = updated);
                await AuthService.getUser();
              }
            },
          ),

          _accountTile(
            icon: Icons.alternate_email_rounded,
            label: 'Email',
            value: _email.isNotEmpty ? _email : 'Non défini',
            showChevron: false,
          ),

          _accountTile(
            icon: Icons.phone_outlined,
            label: 'Téléphone (appel SOS)',
            value: _telephone.isNotEmpty ? _telephone : 'Non défini',
            onTap: _editPhone,
          ),

          const SizedBox(height: 24),

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
      borderRadius: BorderRadius.circular(16),
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
                  if (value != null && value.isNotEmpty) ...[
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