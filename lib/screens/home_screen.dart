import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'settings_screen.dart';
import 'add_tracker_screen.dart';
import 'notifications_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _initLocation();
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
            top: 60,
            left: 16,
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