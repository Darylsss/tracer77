import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'services/auth_service.dart';
import 'enfant_places_screen.dart';

// Fiche détail d'un enfant : voir/modifier le prénom et la photo,
// et accéder à ses lieux enregistrés. Accessible depuis "Modifier votre espace".
class EnfantDetailScreen extends StatefulWidget {
  final Map<String, dynamic> enfant;
  final bool isAdmin;

  const EnfantDetailScreen({super.key, required this.enfant, required this.isAdmin});

  @override
  State<EnfantDetailScreen> createState() => _EnfantDetailScreenState();
}

class _EnfantDetailScreenState extends State<EnfantDetailScreen> {
  static const Color blue = Color(0xFF0185FF);

  late final TextEditingController _prenomController;
  File? _selectedImage;
  bool _saving = false;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _prenomController = TextEditingController(text: widget.enfant['prenom'] ?? '');
    _photoUrl = widget.enfant['photo'];
  }

  @override
  void dispose() {
    _prenomController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
    if (picked != null) setState(() => _selectedImage = File(picked.path));
  }

  Future<void> _save() async {
    final prenom = _prenomController.text.trim();
    if (prenom.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le prénom est requis')),
      );
      return;
    }

    setState(() => _saving = true);
    final result = await AuthService.updateEnfant(
      enfantId: widget.enfant['id'],
      prenom: prenom,
      photo: _selectedImage,
    );
    if (!mounted) return;
    setState(() => _saving = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Modifications enregistrées')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Erreur lors de la modification.')),
      );
    }
  }

  void _confirmDelete() {
    final nom = _prenomController.text.trim();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Retirer cet enfant',
          style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Text(
          '${nom.isEmpty ? "Cet enfant" : nom} et tous ses lieux enregistrés seront définitivement supprimés. Continuer ?',
          style: const TextStyle(fontFamily: 'Montserrat', fontSize: 13, color: Colors.black54, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Annuler',
              style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w600, color: Colors.black54),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _saving = true);
              final result = await AuthService.deleteEnfant(widget.enfant['id']);
              if (!mounted) return;
              setState(() => _saving = false);
              if (result['success'] == true) {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result['message'] ?? 'Erreur lors de la suppression.')),
                );
              }
            },
            child: const Text(
              'Retirer',
              style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w700, color: Colors.red),
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
                      "Détails de l'enfant",
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
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
                child: Column(
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: widget.isAdmin ? _pickImage : null,
                        child: SizedBox(
                          width: 88,
                          height: 88,
                          child: Stack(
                            children: [
                              Center(
                                child: CircleAvatar(
                                  radius: 44,
                                  backgroundColor: const Color(0xFFFFF1EC),
                                  backgroundImage: _selectedImage != null
                                      ? FileImage(_selectedImage!) as ImageProvider
                                      : (_photoUrl != null ? NetworkImage(_photoUrl!) : null),
                                  child: _selectedImage == null && _photoUrl == null
                                      ? Text(
                                          _prenomController.text.isNotEmpty
                                              ? _prenomController.text[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                              fontFamily: 'Montserrat',
                                              fontSize: 28,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.deepOrange),
                                        )
                                      : null,
                                ),
                              ),
                              if (widget.isAdmin)
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
                    ),
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE8E8E8)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Prénom',
                              style: TextStyle(fontFamily: 'Montserrat', fontSize: 11, color: Colors.black45)),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _prenomController,
                            enabled: widget.isAdmin,
                            style: const TextStyle(fontFamily: 'Montserrat', fontSize: 15, fontWeight: FontWeight.w600),
                            decoration:
                                const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                          ),
                        ],
                      ),
                    ),
                    if (widget.enfant['identifiant_boitier'] != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE8E8E8)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ID du boîtier',
                                style: TextStyle(fontFamily: 'Montserrat', fontSize: 11, color: Colors.black45)),
                            const SizedBox(height: 4),
                            Text(
                              widget.enfant['identifiant_boitier'].toString(),
                              style: const TextStyle(fontFamily: 'Montserrat', fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EnfantPlacesScreen(enfant: widget.enfant, isAdmin: widget.isAdmin),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE8E8E8)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.map_outlined, color: blue, size: 22),
                            SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                'Voir les lieux enregistrés',
                                style: TextStyle(fontFamily: 'Montserrat', fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                            ),
                            Icon(Icons.chevron_right, color: Colors.black26, size: 20),
                          ],
                        ),
                      ),
                    ),
                    if (widget.isAdmin) ...[
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('Enregistrer',
                                  style: TextStyle(fontFamily: 'Montserrat', fontSize: 15, fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: TextButton.icon(
                          onPressed: _saving ? null : _confirmDelete,
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                          label: const Text(
                            'Retirer cet enfant',
                            style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w700, color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}