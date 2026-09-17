import 'package:flutter/material.dart';
import 'add_place_map_screen.dart';
import '../models/place.dart';
import 'services/place_service.dart';
import 'add_tracker_screen.dart';
import 'services/auth_service.dart';

class AddPlaceScreen extends StatefulWidget {
  final List<Map<String, dynamic>> initialDrafts;
  // Si fourni, les lieux sont enregistrés directement sur cet enfant
  // (mode brouillon désactivé) — utilisé depuis la fiche d'un enfant existant.
  final int? enfantId;

  const AddPlaceScreen({super.key, this.initialDrafts = const [], this.enfantId});

  @override
  State<AddPlaceScreen> createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends State<AddPlaceScreen> {
  late List<Map<String, dynamic>> _draftPlaces;

  @override
  void initState() {
    super.initState();
    _draftPlaces = List.from(widget.initialDrafts);
  }

  bool _hasDraft(PlaceType type) {
    return _draftPlaces.any((d) => d['type'] == type);
  }

  Future<void> _openMap(PlaceType type) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddPlaceMapScreen(
          type: type,
          placeService: PlaceService(baseUrl: AuthService.baseUrl),
          enfantId: widget.enfantId, // null → mode brouillon, sinon enregistrement direct
        ),
      ),
    );

    // Mode direct : le lieu est déjà enregistré côté serveur par AddPlaceMapScreen.
    // On remonte juste l'info à l'appelant pour qu'il rafraîchisse sa liste.
    if (widget.enfantId != null) {
      if (result == true && mounted) {
        Navigator.pop(context, true);
      }
      return;
    }

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        // remplace le brouillon existant du même type s'il y en avait un
        _draftPlaces.removeWhere((d) => d['type'] == type);
        _draftPlaces.add(result);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${result['nom']} ajouté (sera enregistré avec le traceur)')),
        );
      }
    }
  }

 @override
Widget build(BuildContext context) {
  return WillPopScope(
    onWillPop: () async {
      Navigator.pop(context, _draftPlaces);
      return false;
    },
    child: Scaffold(
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
                    onPressed: () => Navigator.pop(context, _draftPlaces),
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

            // Tout le contenu scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 16, bottom: 24),
                child: Column(
                  children: [
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
                              added: _hasDraft(PlaceType.domicile),
                              onTap: () => _openMap(PlaceType.domicile),
                            ),
                            const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFE0E0E0)),
                            _placeTile(
                              imagePath: 'assets/images/ecole.png',
                              title: 'Ajouter une école',
                              subtitle: 'Ou lycées, collèges, universités',
                              added: _hasDraft(PlaceType.ecole),
                              onTap: () => _openMap(PlaceType.ecole),
                            ),
                            const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFE0E0E0)),
                            _placeTile(
                              imagePath: 'assets/images/Team.png',
                              title: "Ajouter le domicile d'un proche",
                              subtitle: 'Lieu où vivent vos proches',
                              added: _hasDraft(PlaceType.proche),
                              onTap: () => _openMap(PlaceType.proche),
                            ),
                            const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFE0E0E0)),
                            _autrelieuTile(onTap: () => _openMap(PlaceType.autre)),
                          ],
                        ),
                      ),
                    ),

                    if (_draftPlaces.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          '${_draftPlaces.length} lieu(x) prêt(s) à être enregistré(s) avec le traceur',
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 12,
                            color: Colors.black54,
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
    ),
  );
}
  Widget _placeTile({
    required String imagePath,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isFirst = false,
    bool added = false,
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
            Image.asset(imagePath, width: 42, height: 42, fit: BoxFit.contain),
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
            if (added) const Icon(Icons.check_circle, color: Color(0xFF0185FF), size: 20),
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
                  child: const Icon(Icons.location_on_outlined, color: Color(0xFF0185FF), size: 24),
                ),
                Positioned(
                  bottom: -4,
                  right: -4,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                    child: const Icon(Icons.add, color: Colors.white, size: 12),
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