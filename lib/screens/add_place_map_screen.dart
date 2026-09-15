import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/place.dart';
import 'services/place_service.dart';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/places_autocomplete_service.dart';
import 'add_tracker_screen.dart';


class AddPlaceMapScreen extends StatefulWidget {
  final PlaceType type;
  final PlaceService placeService;
  final int? enfantId;
  // Si fourni, l'écran s'ouvre en mode "modification" pré-rempli avec ce lieu
  final Place? existingPlace;

  const AddPlaceMapScreen({
    super.key,
    required this.type,
    required this.placeService,
    this.enfantId,
    this.existingPlace,
  });


  @override
  State<AddPlaceMapScreen> createState() => _AddPlaceMapScreenState();
}

class _AddPlaceMapScreenState extends State<AddPlaceMapScreen> {
  static const Color darkBlue = Color(0xFF0A1A6B);
  static const Color accentBlue = Color(0xFF4A6FE3);

  GoogleMapController? _mapController;
  LatLng _center = const LatLng(6.4315, 2.3624); // Cotonou par défaut
  double _radius = 100;
  bool _isSaving = false;

  // Zone de sécurité : alerte si le traceur quitte ce lieu
  bool _alerteSortie = false;
  int _delaiGrace = 15; // en minutes
  static const List<int> _delaisDisponibles = [5, 10, 15, 20, 30, 45, 60];

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

   late final PlacesAutocompleteService _autocompleteService;
   List<Map<String, String>> _suggestions = [];
Timer? _debounce;
bool _isSearching = false;

  bool get _isEditing => widget.existingPlace != null;

  @override
  void initState() {
  super.initState();
  print('Clé API chargée: "${dotenv.env['GOOGLE_PLACES_API_KEY']}"');
  _autocompleteService = PlacesAutocompleteService(
    apiKey: dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '',
  );

  final existing = widget.existingPlace;
  if (existing != null) {
    // Mode modification : on pré-remplit avec les valeurs existantes
    _nameController.text = existing.nom;
    _center = LatLng(existing.latitude, existing.longitude);
    _radius = existing.rayon.toDouble();
    _alerteSortie = existing.alerteSortie;
    _delaiGrace = existing.delaiGrace ?? 15;
  } else {
    _nameController.text = widget.type.defaultLabel;
    _getCurrentLocation();
  }
}

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _center = LatLng(position.latitude, position.longitude);
      });
      _mapController?.animateCamera(CameraUpdate.newLatLng(_center));
    } catch (_) {
      // position par défaut conservée si le GPS n'est pas dispo
    }
  }

  Future<void> _save() async {
  if (_nameController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Merci de donner un nom au lieu')),
    );
    return;
  }

  final draftData = {
    'type': widget.type,
    'nom': _nameController.text.trim(),
    'latitude': _center.latitude,
    'longitude': _center.longitude,
    'rayon': _radius.round(),
    'alerteSortie': _alerteSortie,
    'delaiGrace': _alerteSortie ? _delaiGrace : null,
  };

  // Mode brouillon : l'enfant n'existe pas encore, on renvoie juste les données
  if (widget.enfantId == null) {
    Navigator.pop(context, draftData);
    return;
  }

  // Mode normal : enfant déjà créé, on enregistre directement
  setState(() => _isSaving = true);
  try {
    final place = Place(
      enfantId: widget.enfantId!,
      type: widget.type,
      nom: _nameController.text.trim(),
      latitude: _center.latitude,
      longitude: _center.longitude,
      rayon: _radius.round(),
      alerteSortie: _alerteSortie,
      delaiGrace: _alerteSortie ? _delaiGrace : null,
    );
    if (_isEditing && widget.existingPlace?.id != null) {
      await widget.placeService.updatePlace(widget.existingPlace!.id!, place);
    } else {
      await widget.placeService.createPlace(widget.enfantId!, place);
    }
    if (mounted) Navigator.pop(context, true);
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  } finally {
    if (mounted) setState(() => _isSaving = false);
  }
}

  @override
void dispose() {
  _debounce?.cancel();
  _searchController.dispose();
  _nameController.dispose();
  super.dispose();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Carte
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _center, zoom: 16),
            onMapCreated: (controller) => _mapController = controller,
            onCameraMove: (position) => _center = position.target,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            circles: {
              Circle(
                circleId: const CircleId('radius'),
                center: _center,
                radius: _radius,
                fillColor: accentBlue.withOpacity(0.2),
                strokeColor: accentBlue,
                strokeWidth: 2,
              ),
            },
          ),

          // Marker central fixe (le cercle bouge avec la carte)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40),
              child: Icon(Icons.location_pin, color: darkBlue, size: 40),
            ),
          ),

          // Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.arrow_back_ios_new,
                              size: 18, color: darkBlue),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isEditing ? 'Modifier : ${widget.type.title}' : widget.type.title,
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: darkBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Barre de recherche (glassmorphism)
                  Container(
  decoration: BoxDecoration(
    color: Colors.white.withOpacity(0.95),
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10),
    ],
  ),
  child: Column(
    children: [
      TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: const TextStyle(fontFamily: 'Montserrat'),
        decoration: InputDecoration(
          hintText: 'Rechercher une adresse',
          hintStyle: const TextStyle(fontFamily: 'Montserrat', color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: accentBlue),
          suffixIcon: _isSearching
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : (_searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _suggestions = []);
                      },
                    )
                  : null),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        ),
      ),
      if (_suggestions.isNotEmpty)
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _suggestions.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final s = _suggestions[index];
            return ListTile(
              dense: true,
              leading: const Icon(Icons.location_on_outlined, color: accentBlue),
              title: Text(
                s['description']!,
                style: const TextStyle(fontFamily: 'Montserrat', fontSize: 13),
              ),
              onTap: () => _onSuggestionTap(s['place_id']!, s['description']!),
            );
          },
        ),
    ],
  ),
),
                ],
              ),
            ),
          ),

          // Panneau bas (glassmorphism) : nom du lieu (si "autre") + rayon + enregistrer
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 16),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                 ...[
const Text(
  'Nom du lieu',
  style: TextStyle(
    fontFamily: 'Montserrat',
    fontWeight: FontWeight.w600,
    color: darkBlue,
  ),
),
const SizedBox(height: 8),
TextField(
  controller: _nameController,
  style: const TextStyle(fontFamily: 'Montserrat'),
  decoration: InputDecoration(
    hintText: widget.type.defaultLabel.isNotEmpty
        ? widget.type.defaultLabel
        : 'Ex : Chez Mamie, Salle de sport...',
    filled: true,
    fillColor: Colors.grey.shade100,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  ),
),
const SizedBox(height: 16),
                  ],

                  Text(
                    'Rayon de la zone : ${_radius.round()} m',
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w600,
                      color: darkBlue,
                    ),
                  ),
                  Slider(
                    value: _radius,
                    min: 50,
                    max: 1000,
                    divisions: 19,
                    activeColor: accentBlue,
                    inactiveColor: accentBlue.withOpacity(0.2),
                    onChanged: (value) => setState(() => _radius = value),
                  ),
                  const SizedBox(height: 4),

                  // Zone de sécurité : alerte si le traceur quitte ce lieu
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: _alerteSortie
                          ? accentBlue.withOpacity(0.08)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _alerteSortie
                            ? accentBlue.withOpacity(0.4)
                            : Colors.transparent,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _alerteSortie
                                  ? Icons.notifications_active_rounded
                                  : Icons.notifications_none_rounded,
                              color: _alerteSortie ? accentBlue : Colors.black45,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Alerter si le traceur quitte ce lieu',
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: darkBlue,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Ce lieu devient une zone de sécurité',
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 11,
                                      color: Colors.black.withOpacity(0.45),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: _alerteSortie,
                              activeColor: accentBlue,
                              onChanged: (value) => setState(() => _alerteSortie = value),
                            ),
                          ],
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          child: _alerteSortie
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Délai de grâce avant l\'alerte',
                                        style: TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black.withOpacity(0.55),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: _delaisDisponibles.map((minutes) {
                                          final selected = _delaiGrace == minutes;
                                          return GestureDetector(
                                            onTap: () => setState(() => _delaiGrace = minutes),
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 150),
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 14, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: selected ? accentBlue : Colors.white,
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: selected
                                                      ? accentBlue
                                                      : Colors.black12,
                                                ),
                                              ),
                                              child: Text(
                                                '$minutes min',
                                                style: TextStyle(
                                                  fontFamily: 'Montserrat',
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: selected
                                                      ? Colors.white
                                                      : Colors.black54,
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Enregistrer',
                              style: TextStyle(
                                fontFamily: 'Encode Sans Semi Expanded',
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.white,
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
    );
  }

  void _onSearchChanged(String value) {
  _debounce?.cancel();
  _debounce = Timer(const Duration(milliseconds: 400), () async {
    if (value.trim().isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    setState(() => _isSearching = true);
    final results = await _autocompleteService.search(value);
    if (mounted) {
      setState(() {
        _suggestions = results;
        _isSearching = false;
      });
    }
  });
}

Future<void> _onSuggestionTap(String placeId, String description) async {
  final latLng = await _autocompleteService.getLatLng(placeId);
  if (latLng == null) return;

  setState(() {
    _center = LatLng(latLng['lat']!, latLng['lng']!);
    _searchController.text = description;
    _suggestions = [];
  });
  _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_center, 17));
  FocusScope.of(context).unfocus();
}
}