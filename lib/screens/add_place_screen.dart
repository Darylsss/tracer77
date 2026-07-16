import 'package:flutter/material.dart';

class AddPlaceScreen extends StatelessWidget {
  const AddPlaceScreen({super.key});

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
                    icon: const Icon(Icons.chevron_left,
                        color: Colors.black54, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Ajouter des lieux',
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

            const SizedBox(height: 16),

            // Liste des options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF0185FF), width: 1),
                ),
                child: Column(
                  children: [
                    _placeTile(
                      imagePath: 'assets/images/domicile.png',
                      title: 'Ajouter un domicile',
                      subtitle: 'Lieu où vous vivez',
                      isFirst: true,
                      onTap: () {},
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16,
                        color: Color(0xFFE0E0E0)),
                    _placeTile(
                      imagePath: 'assets/images/ecole.png',
                      title: 'Ajouter une école',
                      subtitle: 'Ou lycées, collèges, universités',
                      onTap: () {},
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16,
                        color: Color(0xFFE0E0E0)),
                    _placeTile(
                      imagePath: 'assets/images/team.png',
                      title: "Ajouter le domicile d'un proche",
                      subtitle: 'Lieu où vivent vos proches',
                      onTap: () {},
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16,
                        color: Color(0xFFE0E0E0)),
                    _autrelieuTile(onTap: () {}),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeTile({
    required String imagePath,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isFirst = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: isFirst
          ? const BorderRadius.vertical(top: Radius.circular(20))
          : BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Image.asset(
              imagePath,
              width: 42,
              height: 42,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _autrelieuTile({required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.location_on_outlined,
                    color: Color(0xFF0185FF),
                    size: 24,
                  ),
                ),
                Positioned(
                  bottom: -4,
                  right: -4,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Colors.black87,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            const Text(
              'Ajouter un autre lieu',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0185FF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}