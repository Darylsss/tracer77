import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'settings_screen.dart';
import 'dart:async';
import '../api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  LatLng? _boitierPosition;
  Set<Marker> _markers = {};
  bool _loading = true;
  bool _sosActif = false;
  double _vitesse = 0.0;
  double _batterie = 100.0;
  Timer? _timer;
  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _initLocation();
    _recupererPositionBoitier();
    // Actualiser la position du boîtier toutes les 30 secondes
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _recupererPositionBoitier(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Position GPS du téléphone du parent (code original de D4ryl)
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

  // Position du boîtier depuis le serveur Laravel
  Future<void> _recupererPositionBoitier() async {
    try {
      final data = await _api.get('derniere');
      if (data['status'] == 'success' && data['data'] != null) {
        final pos = data['data'];
        setState(() {
          _boitierPosition = LatLng(
            double.parse(pos['lat'].toString()),
            double.parse(pos['lng'].toString()),
          );
          _vitesse   = double.parse(pos['vitesse'].toString());
          _batterie  = double.parse(pos['batterie'].toString());
          _sosActif  = pos['sos'] == 1;
        });
        _majMarqueurs();
      }
    } catch (e) {
      debugPrint('Erreur récupération position boîtier : $e');
    }
  }

  // Mettre à jour les marqueurs sur la carte
  void _majMarqueurs() {
    final Set<Marker> nouveauxMarqueurs = {};

    // Marqueur du parent (téléphone)
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

    // Marqueur du boîtier (enfant)
    if (_boitierPosition != null) {
      nouveauxMarqueurs.add(
        Marker(
          markerId: const MarkerId('boitier'),
          position: _boitierPosition!,
          infoWindow: InfoWindow(
            title: _sosActif ? '🚨 ALERTE SOS !' : '📍 Enfant localisé',
            snippet: 'Vitesse : ${_vitesse.toStringAsFixed(1)} km/h',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _sosActif
                ? BitmapDescriptor.hueRed
                : BitmapDescriptor.hueGreen,
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

          // Bandeau SOS rouge en haut
          if (_sosActif)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.red,
                padding: const EdgeInsets.only(top: 50, bottom: 12),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.warning, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      '🚨 ALERTE SOS DÉCLENCHÉE !',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Boutons haut gauche (code original D4ryl)
          Positioned(
            top: _sosActif ? 110 : 60,
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
                _buildIconButton(Icons.notifications_outlined, () {}),
              ],
            ),
          ),

          // Bouton recentrer sur le boîtier
          Positioned(
            bottom: 210,
            right: 16,
            child: Column(
              children: [
                // Recentrer sur boîtier
                if (_boitierPosition != null)
                  _buildIconButton(Icons.child_care, () {
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLng(_boitierPosition!),
                    );
                  }),
                const SizedBox(height: 10),
                // Recentrer sur moi
                _buildIconButton(Icons.my_location, () {
                  if (_currentPosition != null) {
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLng(_currentPosition!),
                    );
                  }
                }),
              ],
            ),
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

                  // Infos boîtier si disponible
                  if (_boitierPosition != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildInfoCard(
                            Icons.speed,
                            '${_vitesse.toStringAsFixed(1)} km/h',
                            'Vitesse',
                            Colors.blue,
                          ),
                          _buildInfoCard(
                            _batterie < 20
                                ? Icons.battery_alert
                                : Icons.battery_full,
                            '${_batterie.toStringAsFixed(0)}%',
                            'Batterie',
                            _batterie < 20 ? Colors.orange : Colors.green,
                          ),
                          _buildInfoCard(
                            _sosActif
                                ? Icons.warning
                                : Icons.check_circle,
                            _sosActif ? 'DANGER' : 'Normal',
                            'Statut',
                            _sosActif ? Colors.red : Colors.green,
                          ),
                        ],
                      ),
                    ),

                  const Divider(height: 1, indent: 16, endIndent: 16),

                  // Vous (code original D4ryl)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.grey[200],
                          child: const Icon(
                            Icons.person,
                            color: Colors.grey,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Vous',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Text(
                                  'Localisation en direct',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, indent: 16, endIndent: 16),

                  // Ajouter un traceur (code original D4ryl)
                  InkWell(
                    onTap: () {},
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F0FE),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.person_add_outlined,
                              color: Color(0xFF1A6FE3),
                              size: 24,
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

                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget carte info (vitesse, batterie, statut)
  Widget _buildInfoCard(
    IconData icon,
    String valeur,
    String label,
    Color couleur,
  ) {
    return Column(
      children: [
        Icon(icon, color: couleur, size: 22),
        const SizedBox(height: 2),
        Text(
          valeur,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: couleur,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  // Widget bouton icône (code original D4ryl)
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