import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:orama_admin/main.dart';
import 'package:orama_admin/utils/show_snackbar.dart';

class RemoveUsuarioPage extends StatefulWidget {
  const RemoveUsuarioPage({super.key});

  @override
  State<RemoveUsuarioPage> createState() => _RemoveUsuarioPageState();
}

class _RemoveUsuarioPageState extends State<RemoveUsuarioPage>
    with TickerProviderStateMixin {
  final FirebaseFirestore firestore = primaryFirestore;
  late FirebaseFunctions functions;

  final TextEditingController searchController = TextEditingController();

  List<QueryDocumentSnapshot<Map<String, dynamic>>> users = [];
  bool isLoading = true;

  late AnimationController _fadeCtrl;
  late AnimationController _slideCtrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    functions = FirebaseFunctions.instanceFor(
        app: Firebase.app(),
        region: 'us-central1' // a mesma da sua Cloud Function
        );
    _fadeCtrl = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideCtrl = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
    _slide = Tween(begin: const Offset(0, .3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutBack),
    );

    _carregarUsuarios();
  }

  Future<void> _carregarUsuarios() async {
    setState(() => isLoading = true);
    try {
      final snap = await firestore.collection('users').get();
      users = snap.docs;
      _fadeCtrl.forward();
      _slideCtrl.forward();
    } catch (e) {
      ShowSnackBar(context, 'Erro ao carregar usuários: $e', Colors.red);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _removerUsuario(String uid, String email) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[600]),
            const SizedBox(width: 8),
            const Text('Confirmar remoção'),
          ],
        ),
        content: Text(
          'Deseja remover "$email"?\n\nEsta ação é irreversível.',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Remover',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // 1. Remove documento em Firestore
      await firestore.collection('users').doc(uid).delete();

      // 2. Remove usuário no Auth via Cloud Function (admin.auth().deleteUser)
      final callable = functions.httpsCallable('deleteUserByUid');
      await callable.call(<String, dynamic>{'uid': uid});

      ShowSnackBar(context, 'Usuário removido com sucesso!', Colors.red);
      _fadeCtrl.reset();
      _slideCtrl.reset();
      await _carregarUsuarios();
    } catch (e) {
      ShowSnackBar(context, 'Erro ao remover usuário: $e', Colors.red);
      print(e);
    }
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> get _filteredUsers {
    final query = searchController.text.trim().toLowerCase();
    if (query.isEmpty) return users;
    return users
        .where((u) =>
            (u['email'] as String).toLowerCase().contains(query) ||
            (u['role'] as String?)?.toLowerCase().contains(query) == true)
        .toList();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Remover Usuário'),
        backgroundColor: const Color(0xff60C03D),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Campo de busca
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por e-mail ou role...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(.2)),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),

            // Lista de usuários
            Expanded(
              child: isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xff60C03D)))
                  : _filteredUsers.isEmpty
                      ? const Center(
                          child: Text('Nenhum usuário encontrado'),
                        )
                      : FadeTransition(
                          opacity: _fade,
                          child: SlideTransition(
                            position: _slide,
                            child: ListView.separated(
                              itemCount: _filteredUsers.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (_, i) {
                                final doc = _filteredUsers[i];
                                final email = doc['email'] ?? '—';
                                final role = doc['role'] ?? '—';
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.grey.withOpacity(.2)),
                                  ),
                                  child: ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xff60C03D)
                                            .withOpacity(.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.person,
                                          color: Color(0xff60C03D)),
                                    ),
                                    title: Text(email,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    subtitle: Text(role),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.red),
                                      onPressed: () =>
                                          _removerUsuario(doc.id, email),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
