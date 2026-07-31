import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'invite_member_screen.dart';
import 'add_tracker_screen.dart';

class EditSpaceScreen extends StatefulWidget {
  const EditSpaceScreen({super.key});

  @override
  State<EditSpaceScreen> createState() => _EditSpaceScreenState();
}

class _EditSpaceScreenState extends State<EditSpaceScreen> {
  static const Color blue = Color(0xFF0185FF);

  bool _loading = true;
  List<dynamic> _membres = [];
  List<dynamic> _enfants = [];
  String? _monRole;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final userResult = await AuthService.getUser();
    final result = await AuthService.getFamilyMembers();

    setState(() {
      _monRole = userResult?['role'];
      if (result['success'] == true) {
        _membres = result['membres'] ?? [];
        _enfants = result['enfants'] ?? [];
      }
      _loading = false;
    });
  }

  bool get _estAdmin => _monRole == 'admin_famille';

  void _confirmRemoveMember(int id, String nom) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Retirer ce membre',
          style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Text(
          '$nom ne pourra plus voir les positions de la famille. Continuer ?',
          style: const TextStyle(fontFamily: 'Montserrat', fontSize: 13, color: Colors.black54, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Annuler',
              style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w600, color: Colors.black54),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await AuthService.removeMember(id);
              if (result['success'] == true) {
                _load();
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result['message'] ?? 'Erreur.')),
                );
              }
            },
            child: const Text(
              'Retirer',
              style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w700, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

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
                    icon: const Icon(Icons.chevron_left, color: Colors.black54, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Modifier votre espace',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 17,
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

            _loading
                ? const Expanded(child: Center(child: CircularProgressIndicator()))
                : Expanded(
                    child: RefreshIndicator(
                      onRefresh: _load,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),

                            // Section Membres
                            _sectionHeader(
                              title: 'Membres (${_membres.length})',
                              actionLabel: _estAdmin ? 'Inviter' : null,
                              onAction: _estAdmin
                                  ? () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const InviteMemberScreen()),
                                      );
                                      _load();
                                    }
                                  : null,
                            ),
                            const SizedBox(height: 10),
                            if (_membres.isEmpty)
                              _emptyState('Aucun membre pour le moment.')
                            else
                              ..._membres.map((m) => _membreTile(m)),

                            const SizedBox(height: 28),

                            // Section Enfants
                            _sectionHeader(
                              title: 'Enfants suivis (${_enfants.length})',
                              actionLabel: 'Ajouter',
                              onAction: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const AddTrackerScreen()),
                                );
                                _load();
                              },
                            ),
                            const SizedBox(height: 10),
                            if (_enfants.isEmpty)
                              _emptyState('Aucun enfant suivi pour le moment.')
                            else
                              ..._enfants.map((e) => _enfantTile(e)),

                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader({required String title, String? actionLabel, VoidCallback? onAction}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: blue,
            ),
          ),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Row(
                children: [
                  const Icon(Icons.add_circle_outline_rounded, color: blue, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    actionLabel,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: blue,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyState(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Text(
        text,
        style: const TextStyle(fontFamily: 'Montserrat', fontSize: 13, color: Colors.black38),
      ),
    );
  }

  Widget _membreTile(Map<String, dynamic> m) {
    final bool estMoi = false; // TODO: comparer avec l'id de l'utilisateur connecté si besoin
    final bool partage = m['partage_position'] == true || m['partage_position'] == 1;
    final position = m['position'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
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
            backgroundColor: const Color(0xFFECF6FF),
            child: Text(
              (m['nom'] ?? '?').toString().isNotEmpty ? m['nom'][0].toUpperCase() : '?',
              style: const TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w700, color: blue),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      m['nom'] ?? '',
                      style: const TextStyle(fontFamily: 'Montserrat', fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 6),
                    if (m['role'] == 'admin_famille')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Admin',
                          style: TextStyle(fontFamily: 'Montserrat', fontSize: 10, fontWeight: FontWeight.w700, color: blue),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  partage
                      ? (position != null ? 'Position partagée' : 'Partage activé — en attente de position')
                      : 'Ne partage pas sa position',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 11,
                    color: partage ? Colors.green : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
          if (_estAdmin && m['role'] != 'admin_famille')
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.black26, size: 20),
              onPressed: () => _confirmRemoveMember(m['id'], m['nom'] ?? ''),
            ),
        ],
      ),
    );
  }

  Widget _enfantTile(Map<String, dynamic> e) {
    final position = e['position'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
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
                  '${e['prenom'] ?? ''} ${e['nom'] ?? ''}',
                  style: const TextStyle(fontFamily: 'Montserrat', fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  position != null ? 'Dernière position reçue' : 'Aucune position reçue',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 11,
                    color: position != null ? Colors.green : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}