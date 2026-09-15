import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'settings_screen.dart';
import 'add_tracker_screen.dart';
import 'notifications_screen.dart';
import 'services/auth_service.dart';
import 'family_choice_screen.dart';
import 'invite_member_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  Set<Marker> _markers = {};
  bool _loading = true;
  bool _checkingFamily = true;
  bool _isAdmin = false;
  String? _nomFamille;

  @override
void initState() {
  super.initState();
  _checkFamilyStatus();
}

Future<void> _checkFamilyStatus() async {
  final user = await AuthService.getUser();

  if (!mounted) return;

  if (user == null || user['family_id'] == null) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const FamilyChoiceScreen()),
      (route) => false,
    );
    return; // on arrête ici, pas besoin de charger la carte
  }

  setState(() {
    _checkingFamily = false;
    _isAdmin = user['role'] == 'admin_famille';
    _nomFamille = user['family']?['nom'] ?? user['family_nom'];
  });
  _initLocation(); // seulement si l'utilisateur a bien une famille
}

  @override
  void dispose() {
    super.dispose();
  }

  // Position GPS du téléphone
  Future<void> _initLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() => _loading = false);
      return;
    }
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    final latLng = LatLng(position.latitude, position.longitude);
    setState(() {
      _currentPosition = latLng;
      _loading = false;
    });
    _majMarqueurs();
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(latLng, 16),
    );
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((pos) {
      setState(() {
        _currentPosition = LatLng(pos.latitude, pos.longitude);
      });
      _majMarqueurs();
    });
  }

  // Mettre à jour le marqueur sur la carte
  void _majMarqueurs() {
    final Set<Marker> nouveauxMarqueurs = {};

    // Marqueur de l'utilisateur
    if (_currentPosition != null) {
      nouveauxMarqueurs.add(
        Marker(
          markerId: const MarkerId('vous'),
          position: _currentPosition!,
          infoWindow: const InfoWindow(title: 'Vous'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue,
          ),
        ),
      );
    }

    setState(() => _markers = nouveauxMarqueurs);
  }

  @override
Widget build(BuildContext context) {
  if (_checkingFamily) {
    return const Scaffold(
      backgroundColor: Color(0xFFF4F6FA),
      body: Center(child: CircularProgressIndicator()),
    );
  }

  return Scaffold(
    body: Stack(
        children: [
          // Carte Google Maps
          _loading
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition ?? const LatLng(6.3654, 2.4183),
                    zoom: 16,
                  ),
                  markers: _markers,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                ),

          // Boutons haut gauche
          Positioned(
            top: 130,
            left: 10,
            child: Column(
              children: [
                _buildIconButton(Icons.settings_outlined, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                }),
                const SizedBox(height: 10),
                _buildIconButton(Icons.notifications_outlined, () {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
  );
}),

              ],
            ),
          ),

          // Pastille "Famille" en haut, centrée et adaptée à son contenu
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _openFamilleSheet,
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(19),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _nomFamille != null ? '$_nomFamille' : 'Famille',
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black54, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bouton recentrer sur ma position
          Positioned(
            bottom: 250,
            right: 16,
            child: _buildIconButton(Icons.my_location, () {
              if (_currentPosition != null) {
                _mapController?.animateCamera(
                  CameraUpdate.newLatLng(_currentPosition!),
                );
              }
            }),
          ),

          // Panel bas
Positioned(
  left: 0,
  right: 0,
  bottom: 0,
  child: Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 10,
          offset: Offset(0, -2),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Handle
        Container(
          margin: const EdgeInsets.only(top: 10, bottom: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(10),
          ),
        ),

                  // Vous
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[200],
                  border: Border.all(color: Colors.grey[300]!, width: 1.5),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.grey,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vous',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text(
                          'Localisation\nen direct',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1, indent: 16, endIndent: 16),

                  // Ajouter un traceur
                  InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddTrackerScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF1A6FE3),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.person_add_alt_outlined,
                    color: Color(0xFF1A6FE3),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Ajouter un traceur',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A6FE3),
                  ),
                ),
              ],
            ),
          ),
        ),

                  SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Feuille "Famille" ouverte depuis la pastille du haut
  void _openFamilleSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FutureBuilder<Map<String, dynamic>>(
        future: AuthService.getFamilyMembers(),
        builder: (context, snapshot) {
          final membres = (snapshot.data?['membres'] as List?) ?? [];
          final enfants = (snapshot.data?['enfants'] as List?) ?? [];
          final totalPersonnes = membres.length + enfants.length;

          return Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Text(
                  _nomFamille != null ? '$_nomFamille' : 'Famille',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator(color: Color(0xFF1A6FE3))),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F6FA),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A6FE3).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.family_restroom_rounded, color: Color(0xFF1A6FE3)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Votre famille',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$totalPersonnes membre(s) suivi(s)',
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 12,
                                  color: Colors.black45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_isAdmin) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const InviteMemberScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A6FE3),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 20),
                      label: const Text(
                        'Ajouter un membre',
                        style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget bouton icône
  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF1A6FE3),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}