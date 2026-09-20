import 'dart:async';
import 'services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'settings_screen.dart';
import 'add_tracker_screen.dart';
import 'notifications_screen.dart';
import 'services/auth_service.dart';
import 'family_choice_screen.dart';
import 'invite_member_screen.dart';
import '../models/place.dart';
import '../models/position.dart' as models;
import 'services/place_service.dart';
import 'services/position_service.dart';
import 'trip_history_builder.dart';
import 'trip_route_map.dart';

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
  String? _nomFamille;
  String? _monRole;
  String? _maPhoto;
  bool get _estAdmin => _monRole == 'admin_famille';
  List<dynamic> _enfants = [];
  Timer? _alertTimer;
  int? _lastAlertId;

  // --- Historique / trajet ---
  late final PlaceService _placeService = PlaceService(baseUrl: AuthService.baseUrl);
  late final PositionService _positionService = PositionService(baseUrl: AuthService.baseUrl);
  int? _selectedEnfantId;
  String _periode = 'aujourdhui';
  bool _histLoading = false;
  List<models.Position> _histPositions = [];
  List<TripEvent> _histEvents = [];

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
    _monRole = user['role'];
    _nomFamille = user['family']?['nom'] ?? user['family_nom'];
    _maPhoto = user['photo'];
  });
  _initLocation(); // seulement si l'utilisateur a bien une famille
  _chargerEnfants();
  _startAlertPolling();
}

    @override
  void dispose() {
    _alertTimer?.cancel();
    super.dispose();
  }

  Future<void> _startAlertPolling() async {
    _lastAlertId = await AuthService.getLastAlertId();
    _checkAlerts();
    _alertTimer = Timer.periodic(const Duration(seconds: 15), (_) => _checkAlerts());
  }

  Future<void> _checkAlerts() async {
    final result = await AuthService.getAlerts();
    if (result['success'] != true) return;
    final List alertes = result['alertes'] ?? [];
    if (alertes.isEmpty) return;

    final int newestId = alertes.first['id'];

    if (_lastAlertId == null) {
      _lastAlertId = newestId;
      await AuthService.setLastAlertId(newestId);
      return;
    }

        if (newestId > _lastAlertId!) {
      for (var a in alertes) {
        if (a['id'] > _lastAlertId!) {
          await NotificationService.showSosAlert(a['message'] ?? 'Notification Tracer77');
        }
      }
      _lastAlertId = newestId;
      await AuthService.setLastAlertId(newestId);
    }
  }

  // Récupérer les enfants de la famille et leur dernière position
  Future<void> _chargerEnfants() async {
    final result = await AuthService.getFamilyMembers();
    if (!mounted) return;
    if (result['success'] != false) {
      setState(() {
        _enfants = result['enfants'] ?? [];
      });
      _majMarqueurs();
    }
  }

  void _selectEnfant(int enfantId) {
    setState(() {
      _selectedEnfantId = enfantId;
      _periode = 'aujourdhui';
    });
    _loadHistorique();
  }

  void _changerPeriode(String periode) {
    setState(() => _periode = periode);
    _loadHistorique();
  }

  Future<void> _loadHistorique() async {
    final enfantId = _selectedEnfantId;
    if (enfantId == null) return;

    setState(() => _histLoading = true);

    try {
      final places = await _placeService.getPlaces(enfantId);
      final positions = await _positionService.getHistorique(enfantId, _periode);
      final alertesResult = await AuthService.getAlerts();
      final List alertesTout = (alertesResult['alertes'] as List?) ?? [];
      final alertesEnfant = alertesTout.where((a) => a['enfant_id'] == enfantId).toList();

      final events = await TripHistoryBuilder.build(
        positions: positions,
        places: places,
        alertes: alertesEnfant,
        resolveUnknown: (lat, lng) => _positionService.reverseGeocode(lat, lng),
      );

      if (!mounted) return;
      setState(() {
        _histPositions = positions;
        _histEvents = events.reversed.toList(); // plus récent en premier
        _histLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _histPositions = [];
        _histEvents = [];
        _histLoading = false;
      });
    }
  }

  void _showAlerteDetail(Map<String, dynamic> alerte) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Alerte',
          style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Text(
          alerte['message'] ?? 'Détails non disponibles.',
          style: const TextStyle(fontFamily: 'Montserrat', fontSize: 13, color: Colors.black54, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Fermer',
              style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w700, color: Color(0xFF1A6FE3)),
            ),
          ),
        ],
      ),
    );
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

  // Mettre à jour les marqueurs sur la carte
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

    // Marqueurs des enfants suivis
    for (var enfant in _enfants) {
      final pos = enfant['position'];
      if (pos != null && pos['lat'] != null && pos['lng'] != null) {
        final lat = double.tryParse(pos['lat'].toString());
        final lng = double.tryParse(pos['lng'].toString());
        if (lat != null && lng != null) {
          nouveauxMarqueurs.add(
            Marker(
              markerId: MarkerId('enfant_${enfant['id']}'),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(
                title: '${enfant['prenom'] ?? ''} ${enfant['nom'] ?? ''}'.trim(),
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange,
              ),
            ),
          );
        }
      }
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

          // Panel bas — défilant : liste des personnes puis historique
          DraggableScrollableSheet(
            initialChildSize: 0.32,
            minChildSize: 0.18,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
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
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.zero,
                  children: [
                    // Handle
                    Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 8),
                      width: 40,
                      height: 4,
                      alignment: Alignment.center,
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
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
                              image: _maPhoto != null
                                  ? DecorationImage(
                                      image: NetworkImage(_maPhoto!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _maPhoto == null
                                ? const Icon(Icons.person, color: Colors.grey, size: 28)
                                : null,
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Vous',
                                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      'Localisation\nen direct',
                                      style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.2),
                                    ),
                                    SizedBox(width: 4),
                                    _LiveDot(),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Enfants suivis
                    ..._enfants.map((e) => _enfantTile(e)),

                    const Divider(height: 1, indent: 16, endIndent: 16),

                    // Ajouter un traceur
                    InkWell(
                      onTap: () {
                        if (!_estAdmin) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Seul un admin peut ajouter un traceur .')),
                          );
                          return;
                        }
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
                                border: Border.all(color: const Color(0xFF1A6FE3), width: 1.5),
                              ),
                              child: const Icon(Icons.person_add_alt_outlined, color: Color(0xFF1A6FE3), size: 22),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'Ajouter un traceur',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A6FE3)),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Historique du trajet de l'enfant sélectionné
                    if (_selectedEnfantId != null) ...[
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      const SizedBox(height: 12),
                      _buildPeriodeTabs(),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TripRouteMap(positions: _histPositions),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          _periodeTitre(),
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.black54,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_histLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 30),
                          child: Center(child: CircularProgressIndicator(color: Color(0xFF1A6FE3))),
                        )
                      else if (_histEvents.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          child: Text(
                            'Aucun trajet enregistré pour cette période.',
                            style: TextStyle(fontFamily: 'Montserrat', fontSize: 12, color: Colors.black38),
                          ),
                        )
                      else
                        ..._histEvents.map((ev) => _eventTile(ev)),
                      const SizedBox(height: 20),
                    ],

                    SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
                  ],
                ),
              );
            },
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
                if (_estAdmin) ...[
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

  Widget _enfantTile(Map<String, dynamic> e) {
    final int enfantId = e['id'];
    final bool selected = _selectedEnfantId == enfantId;
    final position = e['position'];

    return InkWell(
      onTap: () => _selectEnfant(enfantId),
      child: Container(
        color: selected ? const Color(0xFF1A6FE3).withOpacity(0.06) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFFFFF1EC),
              backgroundImage: e['photo'] != null ? NetworkImage(e['photo']) : null,
              child: e['photo'] == null
                  ? Text(
                      (e['prenom'] ?? '?').toString().isNotEmpty ? e['prenom'][0].toUpperCase() : '?',
                      style: const TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w700, color: Colors.deepOrange),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${e['prenom'] ?? ''} ${e['nom'] ?? ''}'.trim(),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        position != null ? 'Localisation\nen direct' : 'Pas de position\nreçue',
                        style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.2),
                      ),
                      if (position != null) ...const [SizedBox(width: 4), _LiveDot()],
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A6FE3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                selected ? 'Historique ▾' : 'Voir plus',
                style: const TextStyle(fontFamily: 'Montserrat', fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodeTabs() {
    final options = const [
      {'key': 'aujourdhui', 'label': "Aujourd'hui"},
      {'key': 'hier', 'label': 'Hier'},
      {'key': 'avant_hier', 'label': 'Avant-hier'},
      {'key': 'semaine', 'label': 'Cette semaine'},
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final opt = options[i];
          final selected = _periode == opt['key'];
          return GestureDetector(
            onTap: () => _changerPeriode(opt['key']!),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF1A6FE3) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? const Color(0xFF1A6FE3) : Colors.black12),
              ),
              child: Text(
                opt['label']!,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : Colors.black87,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _periodeTitre() {
    final now = DateTime.now();
    switch (_periode) {
      case 'hier':
        return 'HIER';
      case 'avant_hier':
        return 'AVANT-HIER';
      case 'semaine':
        return 'CETTE SEMAINE';
      default:
        return "AUJOURD'HUI - ${now.day}/${now.month}/${now.year}";
    }
  }

  Widget _eventTile(TripEvent ev) {
    final heureDebut = '${ev.start.hour.toString().padLeft(2, '0')}:${ev.start.minute.toString().padLeft(2, '0')}';
    final heureFin = ev.end != null
        ? '${ev.end!.hour.toString().padLeft(2, '0')}:${ev.end!.minute.toString().padLeft(2, '0')}'
        : null;
    final duree = ev.end != null ? ev.end!.difference(ev.start) : null;

    if (ev.type == TripEventType.trajet) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8E8E8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.alt_route_rounded, color: Color(0xFF1A6FE3), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ev.title, style: const TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w700, fontSize: 13)),
                      Text(
                        heureFin != null ? '$heureDebut - $heureFin' : heureDebut,
                        style: const TextStyle(fontFamily: 'Montserrat', fontSize: 11, color: Colors.black45),
                      ),
                    ],
                  ),
                ),
                if (duree != null)
                  Text('${duree.inMinutes} min', style: const TextStyle(fontFamily: 'Montserrat', fontSize: 11, color: Colors.black45)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.map_outlined, size: 14, color: Colors.black45),
                const SizedBox(width: 6),
                Text('${ev.distanceKm?.toStringAsFixed(1) ?? '0'} km', style: const TextStyle(fontFamily: 'Montserrat', fontSize: 12, color: Colors.black54)),
                const SizedBox(width: 16),
                const Icon(Icons.verified_user_outlined, size: 14, color: Colors.green),
                const SizedBox(width: 6),
                const Text('Sécurisé', style: TextStyle(fontFamily: 'Montserrat', fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      );
    }

    // Arrivée
    final secure = ev.secure ?? true;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: secure ? const Color(0xFFE8E8E8) : Colors.red.shade100),
      ),
      child: Row(
        children: [
          Icon(
            secure ? Icons.home_rounded : Icons.warning_amber_rounded,
            color: secure ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ev.title, style: const TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      heureFin != null ? '$heureDebut - Zone ${secure ? 'autorisée' : 'non autorisée'}' : heureDebut,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 11,
                        color: secure ? Colors.black45 : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!secure && ev.alerte != null)
            GestureDetector(
              onTap: () => _showAlerteDetail(ev.alerte!),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Voir alerte',
                  style: TextStyle(fontFamily: 'Montserrat', fontSize: 11, fontWeight: FontWeight.w700, color: Colors.red),
                ),
              ),
            )
          else if (duree != null)
            Text('${duree.inMinutes} min', style: const TextStyle(fontFamily: 'Montserrat', fontSize: 11, color: Colors.black45)),
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

class _LiveDot extends StatelessWidget {
  const _LiveDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      margin: const EdgeInsets.only(top: 2),
      decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
    );
  }
}