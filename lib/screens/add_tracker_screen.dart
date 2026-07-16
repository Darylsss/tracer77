import 'package:flutter/material.dart';
import 'dart:ui';
import 'add_place_screen.dart';

class AddTrackerScreen extends StatefulWidget {
  const AddTrackerScreen({super.key});

  @override
  State<AddTrackerScreen> createState() => _AddTrackerScreenState();
}

class _AddTrackerScreenState extends State<AddTrackerScreen> {
  final _nomController = TextEditingController();
  final _deviceIdController = TextEditingController();

  String _selectedRole = 'Enfant';
  bool _loading = false;

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
    setState(() => _loading = true);
    // TODO: brancher sur la route Laravel /devices
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _loading = false);
    if (mounted) Navigator.pop(context);
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
                      child: Column(
                        children: [ 
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: Stack(
                              children: [
                                Center(
                                  child: DottedBorderCircle(
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
                                    decoration: const BoxDecoration(
                                      color: blue,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_outlined,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Photo (facultatif)',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0x9C000000),
                            ),
                          ),
                        ],
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
                        'Vous pouvez configurez des lieux et une zone de sécurité qui est un périmètre que vous définissez sur la carte. Si le traceur le quitte, vous recevez une alerte immédiatement.',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 11,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: _outlineButton(
                            icon: Icons.account_balance_outlined,
                            label: 'Ajouter des lieux',
                            onTap: () {
                              Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddPlaceScreen()),
    );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _outlineButton(
                            icon: Icons.map_outlined,
                            label: 'Définir une zone sur la carte',
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),

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