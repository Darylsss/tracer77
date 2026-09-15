import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'enfant_places_screen.dart';

// Point d'entrée de "Lieux sur la carte" depuis les Paramètres.
// Liste les enfants de la famille ; on choisit un enfant pour voir/gérer ses lieux.
class PlacesOverviewScreen extends StatefulWidget {
  const PlacesOverviewScreen({super.key});

  @override
  State<PlacesOverviewScreen> createState() => _PlacesOverviewScreenState();
}

class _PlacesOverviewScreenState extends State<PlacesOverviewScreen> {
  static const Color blue = Color(0xFF0185FF);

  bool _loading = true;
  String? _error;
  List<dynamic> _enfants = [];
  bool _isAdmin = false;

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

    final userResult = await AuthService.getUser();
    final result = await AuthService.getFamilyMembers();

    if (!mounted) return;
    setState(() {
      _isAdmin = userResult?['role'] == 'admin_famille';
      if (result['success'] == true) {
        _enfants = result['enfants'] ?? [];
      } else {
        _error = result['message'] ?? 'Impossible de charger les enfants';
      }
      _loading = false;
    });
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
                  const Expanded(
                    child: Text(
                      'Lieux sur la carte',
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
            const Divider(height: 1, color: Color(0xFFE0E0E0)),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Choisissez un enfant pour voir ou gérer ses lieux enregistrés.',
                  style: TextStyle(fontFamily: 'Montserrat', fontSize: 12, color: Colors.black45, height: 1.4),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _errorState()
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: _enfants.isEmpty
                              ? ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  children: const [_EmptyState()],
                                )
                              : ListView.builder(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  itemCount: _enfants.length,
                                  itemBuilder: (ctx, i) => _enfantTile(_enfants[i]),
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

  Widget _enfantTile(Map<String, dynamic> e) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EnfantPlacesScreen(enfant: e, isAdmin: _isAdmin),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8E8E8)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFFFF1EC),
              backgroundImage: e['photo'] != null ? NetworkImage(e['photo']) : null,
              child: e['photo'] == null
                  ? Text(
                      (e['prenom'] ?? '?').toString().isNotEmpty ? e['prenom'][0].toUpperCase() : '?',
                      style: const TextStyle(
                          fontFamily: 'Montserrat', fontWeight: FontWeight.w700, color: Colors.deepOrange),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                '${e['prenom'] ?? ''} ${e['nom'] ?? ''}',
                style: const TextStyle(fontFamily: 'Montserrat', fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black26, size: 20),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Column(
        children: [
          Icon(Icons.family_restroom_rounded, color: Colors.black26, size: 40),
          SizedBox(height: 12),
          Text(
            'Aucun enfant suivi pour le moment.\nAjoutez-en un depuis "Modifier votre espace".',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Montserrat', fontSize: 13, color: Colors.black45, height: 1.5),
          ),
        ],
      ),
    );
  }
}