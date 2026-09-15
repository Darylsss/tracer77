import 'package:flutter/material.dart';
import 'dart:ui';
import 'add_place_screen.dart';
import 'services/auth_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'services/auth_service.dart';
import 'add_place_screen.dart';
import 'services/place_service.dart';
import '../models/place.dart';

class AddTrackerScreen extends StatefulWidget {
  const AddTrackerScreen({super.key});
  

  @override
  State<AddTrackerScreen> createState() => _AddTrackerScreenState();
  
}

class _AddTrackerScreenState extends State<AddTrackerScreen> {
  final _nomController = TextEditingController();
  final _deviceIdController = TextEditingController();
  List<Map<String, dynamic>> _draftPlaces = [];

  String _selectedRole = 'Enfant';
  bool _loading = false;
  File? _selectedImage;

  static const Color blue = Color(0xFF0185FF);
  static const Color blueLight = Color(0xFFECF6FF);
  static const Color blueDark = Color(0xFF0070D7);
  static const Color enregistrerBlue = Color(0xFF017CFF);

  @override
  void dispose() {
    _nomController.dispose();
    _deviceIdController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
  final nom = _nomController.text.trim();
  final deviceId = _deviceIdController.text.trim();

  if (nom.isEmpty || deviceId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Le nom et l\'ID du device sont requis')),
    );
    return;
  }

  setState(() => _loading = true);

  final result = await AuthService.addEnfantWithPhoto(
    prenom: nom,
    identifiantBoitier: deviceId,
    photo: _selectedImage,
  );

  if (result['success'] == true) {
    final enfantId = result['enfant']['id']; // vérifie que ta réponse a bien cette structure

    final placeService = PlaceService(baseUrl: 'http://192.168.100.7:8000/api');
    for (final draft in _draftPlaces) {
      try {
        await placeService.createPlace(enfantId, Place(
          enfantId: enfantId,
          type: draft['type'],
          nom: draft['nom'],
          latitude: draft['latitude'],
          longitude: draft['longitude'],
          rayon: draft['rayon'],
          alerteSortie: draft['alerteSortie'] ?? false,
          delaiGrace: draft['delaiGrace'],
        ));
      } catch (e) {
        debugPrint('Erreur enregistrement lieu brouillon: $e');
      }
    }

    setState(() => _loading = false);
    if (mounted) Navigator.pop(context);
  } else {
    setState(() => _loading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Erreur lors de l\'ajout.')),
      );
    }
  }
}

Future<void> _pickImage() async {
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
  if (picked != null) {
    setState(() => _selectedImage = File(picked.path));
  }
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.black54),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Ajouter un traceur',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // équilibre la flèche
                ],
              ),
            ),
            const Divider(height: 1),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(25, 20, 25, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Photo
                
                   Center(
  child: GestureDetector(
    onTap: _pickImage,
    child: SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        children: [
          Center(
            child: _selectedImage != null
                ? CircleAvatar(
                    radius: 40,
                    backgroundImage: FileImage(_selectedImage!),
                  )
                : DottedBorderCircle(
                    size: 80,
                    color: blue,
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: blue,
                      size: 34,
                    ),
                  ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(color: blue, shape: BoxShape.circle),
              child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 14),
            ),
          ),
        ],
      ),
    ),
  ),
),

                    const SizedBox(height: 24),

                    // INFORMATIONS
                    const Text(
                      'INFORMATIONS',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: blue,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0x69000000)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nom',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                          TextField(
                            controller: _nomController,
                            decoration: const InputDecoration(
                              hintText: 'Ex : Dante',
                              hintStyle: TextStyle(
                                fontFamily: 'Montserrat',
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: const TextStyle(fontFamily: 'Montserrat', fontSize: 14),
                          ),
                          const SizedBox(height: 10),
                          const Divider(height: 1),
                          const SizedBox(height: 10),
                          const Text(
                            'Rôle (pour vous repérer)',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _rolePill('Enfant'),
                              const SizedBox(width: 8),
                              _rolePill('Proche adulte'),
                              const SizedBox(width: 8),
                              _rolePill('Objet / bien'),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // DEVICE ESP32
                    const Text(
                      'DEVICE ESP32',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: blue,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Bandeau jaune
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF3E0),
                        border: Border.all(color: const Color(0x0D000000)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "L'ID est inscrit sur l'étiquette du boitier ou visible dans le moniteur série Arduino.",
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 11,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0x69000000)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ID du device',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                          TextField(
                            controller: _deviceIdController,
                            decoration: const InputDecoration(
                              hintText: 'EX : TRC-0045',
                              hintStyle: TextStyle(
                                fontFamily: 'Montserrat',
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: const TextStyle(fontFamily: 'Montserrat', fontSize: 14),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // LIEUX et ZONE DE SECURITE
                    Row(
                      children: [
                        const Text(
                          'LIEUX et ZONE DE SECURITE',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: blue,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '· facultatif',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 11,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF3E0),
                        border: Border.all(color: const Color(0x0D000000)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Ajoutez les lieux importants (domicile, école...). Pour chacun, vous pouvez activer une alerte si le traceur le quitte, avec un délai de grâce pour éviter les fausses alertes en trajet.',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 11,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    SizedBox(
                      width: double.infinity,
                      child: _outlineButton(
                        icon: Icons.account_balance_outlined,
                        label: _draftPlaces.isEmpty
                            ? 'Ajouter des lieux'
                            : '${_draftPlaces.length} lieu(x) ajouté(s) — modifier',
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddPlaceScreen(initialDrafts: _draftPlaces),
                            ),
                          );
                          if (result != null && result is List<Map<String, dynamic>>) {
                            setState(() => _draftPlaces = result);
                          }
                        },
                      ),
                    ),
                    if (_draftPlaces.any((d) => d['alerteSortie'] == true)) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.shield_rounded, color: blue, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            '${_draftPlaces.where((d) => d['alerteSortie'] == true).length} zone(s) de sécurité active(s)',
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: blue,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 28),

                    // Bouton ENREGISTRER
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(23),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: GestureDetector(
                            onTap: _loading ? null : _submit,
                            child: Container(
                              width: 135,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: enregistrerBlue,
                                borderRadius: BorderRadius.circular(23),
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
                              child: _loading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'ENREGISTRER',
                                      style: TextStyle(
                                        fontFamily: 'AkiraExpanded',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
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
          ],
        ),
      ),
    );
  }

  Widget _rolePill(String role) {
    final selected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
        decoration: BoxDecoration(
          color: blueLight,
          borderRadius: BorderRadius.circular(23),
          border: selected ? Border.all(color: blue, width: 1.2) : null,
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              offset: Offset(0, -2),
              blurRadius: 4,
            ),
            BoxShadow(
              color: Color(0x66FFFFFF),
              offset: Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Text(
          role,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: blue,
          ),
        ),
      ),
    );
  }

  Widget _outlineButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: blueLight,
          borderRadius: BorderRadius.circular(23),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              offset: Offset(0, -2),
              blurRadius: 4,
            ),
            BoxShadow(
              color: Color(0x66FFFFFF),
              offset: Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: blueDark),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: blueDark,
                ),
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget pour le cercle en pointillés autour de l'icône photo
class DottedBorderCircle extends StatelessWidget {
  final double size;
  final Color color;
  final Widget child;

  const DottedBorderCircle({
    super.key,
    required this.size,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DottedCirclePainter(color: color),
      child: SizedBox(
        width: size,
        height: size,
        child: Center(child: child),
      ),
    );
  }
}

class _DottedCirclePainter extends CustomPainter {
  final Color color;
  _DottedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    final radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final circumference = 2 * 3.14159 * radius;
    final dashCount = (circumference / (dashWidth + dashSpace)).floor();
    final angleStep = (2 * 3.14159) / dashCount;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * angleStep;
      final endAngle = startAngle + (angleStep * (dashWidth / (dashWidth + dashSpace)));
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        endAngle - startAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}