import 'package:flutter/material.dart';
import '../models/place.dart';
import 'services/place_service.dart';
import 'add_place_screen.dart';
import 'add_place_map_screen.dart';

// Liste des lieux enregistrés pour un enfant donné.
// Lecture seule pour un membre, gestion complète (ajout/modif/suppr) pour l'admin.
class EnfantPlacesScreen extends StatefulWidget {
  final Map<String, dynamic> enfant;
  final bool isAdmin;

  const EnfantPlacesScreen({super.key, required this.enfant, required this.isAdmin});

  @override
  State<EnfantPlacesScreen> createState() => _EnfantPlacesScreenState();
}

class _EnfantPlacesScreenState extends State<EnfantPlacesScreen> {
  static const Color blue = Color(0xFF0185FF);
  final _placeService = PlaceService(baseUrl: 'https://tracer77.duckdns.org/api');

  bool _loading = true;
  String? _error;
  List<Place> _places = [];

  int get _enfantId => widget.enfant['id'];
  String get _prenom => widget.enfant['prenom'] ?? '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final places = await _placeService.getPlaces(_enfantId);
      if (!mounted) return;
      setState(() {
        _places = places;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger les lieux';
        _loading = false;
      });
    }
  }

  Future<void> _addPlace() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddPlaceScreen(enfantId: _enfantId)),
    );
    if (result == true) _load();
  }

  Future<void> _editPlace(Place place) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddPlaceMapScreen(
          type: place.type,
          placeService: _placeService,
          enfantId: _enfantId,
          existingPlace: place,
        ),
      ),
    );
    if (result == true) _load();
  }

  void _confirmDelete(Place place) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Supprimer ce lieu',
          style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Text(
          '"${place.nom}" sera définitivement supprimé. Continuer ?',
          style: const TextStyle(fontFamily: 'Montserrat', fontSize: 13, color: Colors.black54, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler',
                style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w600, color: Colors.black54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (place.id == null) return;
              try {
                await _placeService.deletePlace(place.id!);
                _load();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur lors de la suppression : $e')),
                  );
                }
              }
            },
            child: const Text('Supprimer',
                style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w700, color: Colors.red)),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(PlaceType type) {
    switch (type) {
      case PlaceType.domicile:
        return Icons.home_rounded;
      case PlaceType.ecole:
        return Icons.school_rounded;
      case PlaceType.proche:
        return Icons.people_alt_rounded;
      default:
        return Icons.location_on_rounded;
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
                      'Lieux de $_prenom',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    child: widget.isAdmin
                        ? IconButton(
                            icon: const Icon(Icons.add_circle_rounded, color: blue, size: 26),
                            onPressed: _addPlace,
                            tooltip: 'Ajouter un lieu',
                          )
                        : null,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE0E0E0)),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _errorState()
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: _places.isEmpty
                              ? ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  children: [_emptyState()],
                                )
                              : ListView.builder(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  itemCount: _places.length,
                                  itemBuilder: (ctx, i) => _placeTile(_places[i]),
                                ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        const Icon(Icons.wifi_off_rounded, color: Colors.black26, size: 40),
        const SizedBox(height: 12),
        Center(
          child: Text(_error!, style: const TextStyle(fontFamily: 'Montserrat', color: Colors.black45)),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: _load,
            child: const Text('Réessayer',
                style: TextStyle(color: blue, fontFamily: 'Montserrat', fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Column(
        children: [
          const Icon(Icons.pin_drop_outlined, color: Colors.black26, size: 40),
          const SizedBox(height: 12),
          Text(
            widget.isAdmin
                ? 'Aucun lieu enregistré pour $_prenom.\nAppuyez sur + pour en ajouter un.'
                : 'Aucun lieu enregistré pour $_prenom.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Montserrat', fontSize: 13, color: Colors.black45, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _placeTile(Place place) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFECF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_iconForType(place.type), color: blue, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(place.nom,
                    style: const TextStyle(fontFamily: 'Montserrat', fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('Rayon ${place.rayon} m',
                        style: const TextStyle(fontFamily: 'Montserrat', fontSize: 11, color: Colors.black45)),
                    if (place.alerteSortie)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.shield_rounded, color: blue, size: 12),
                          SizedBox(width: 3),
                          Text('Zone de sécurité',
                              style: TextStyle(
                                  fontFamily: 'Montserrat', fontSize: 11, color: blue, fontWeight: FontWeight.w600)),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (widget.isAdmin) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.black38, size: 20),
              onPressed: () => _editPlace(place),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
              onPressed: () => _confirmDelete(place),
            ),
          ],
        ],
      ),
    );
  }
}