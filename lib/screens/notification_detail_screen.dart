import 'package:flutter/material.dart';

class NotificationDetailScreen extends StatelessWidget {
  final Map<String, dynamic> alerte;

  const NotificationDetailScreen({super.key, required this.alerte});

  static const Color blue = Color(0xFF0185FF);

  IconData get _icon {
    switch (alerte['type']) {
      case 'sos':
        return Icons.warning_amber_rounded;
      case 'sortie_zone':
        return Icons.logout_rounded;
      case 'entree_zone':
        return Icons.login_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color get _color {
    switch (alerte['type']) {
      case 'sos':
        return Colors.red;
      case 'sortie_zone':
        return Colors.orange;
      case 'entree_zone':
        return Colors.green;
      default:
        return blue;
    }
  }

  String get _titre {
    switch (alerte['type']) {
      case 'sos':
        return 'Alerte SOS';
      case 'sortie_zone':
        return 'Sortie de zone';
      case 'entree_zone':
        return 'Retour dans la zone';
      default:
        return 'Notification';
    }
  }

  String _formatDateComplete(String? iso) {
    if (iso == null) return '';
    try {
      final date = DateTime.parse(iso).toLocal();
      const jours = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
      final jour = jours[date.weekday - 1];
      final heure = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$jour ${date.day}/${date.month}/${date.year} à $heure:$minute';
    } catch (e) {
      return '';
    }
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
                  Expanded(
                    child: Text(
                      _titre,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: _color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_icon, color: _color, size: 34),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      alerte['message'] ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _formatDateComplete(alerte['created_at']),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 13,
                        color: Colors.black45,
                      ),
                    ),
                    if (alerte['enfant'] != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE8E8E8)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.child_care_rounded, color: blue, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              'Concerne : ${alerte['enfant']}',
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
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