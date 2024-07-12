import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:orama_admin/pages/admin_page.dart';
import 'package:orama_admin/pages/estoque_page.dart';
import 'package:orama_admin/stores/comanda_store.dart';
import 'package:orama_admin/widgets/BottomNavigationBar.dart';
import 'package:orama_admin/widgets/cards/admin_relatorios_card.dart';
import 'package:rxdart/rxdart.dart';

class RelatoriosSorvetePage extends StatefulWidget {
  @override
  _RelatoriosSorvetePageState createState() => _RelatoriosSorvetePageState();
}

class _RelatoriosSorvetePageState extends State<RelatoriosSorvetePage> {
  List<bool> _selectedComandas = [];
  int _currentIndex = 2;
  final box = GetStorage();
  DateTime _selectedDate = DateTime.now();
  Future<List<String>>? _userIdsFuture;

  @override
  void initState() {
    super.initState();
    _userIdsFuture = _getUserIdsWithUserRole();
  }

  void onTabTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AdminPage()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => EstoqueAdminPage()),
      );
    } else if (index == 2) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  void _updateSelectedDate(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
    });
  }

  Future<void> _refreshComandas() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTabTapped: onTabTapped,
      ),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          "Relatórios Sorvete",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        elevation: 4,
        backgroundColor: const Color(0xff60C03D),
      ),
      body: FutureBuilder<List<String>>(
        future: _userIdsFuture,
        builder: (context, userIdsSnapshot) {
          if (userIdsSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (userIdsSnapshot.hasError) {
            return Center(child: Text("Erro ao carregar usuários"));
          }

          final userIds = userIdsSnapshot.data ?? [];

          if (userIds.isEmpty) {
            return Center(child: Text("Nenhum usuário com role 'user' encontrado."));
          }

          return StreamBuilder<List<QuerySnapshot>>(
            stream: CombineLatestStream.list(
              userIds.map(
                (userId) => FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('comandas')
                    .snapshots(),
              ),
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text("Erro ao carregar comandas"));
              }

              final comandas = snapshot.data
                      ?.expand((querySnapshot) => querySnapshot.docs)
                      .map((doc) =>
                          Comanda.fromJson(doc.data() as Map<String, dynamic>))
                      .toList() ??
                  [];

              if (comandas.isEmpty) {
                return Center(child: Text("Nenhuma comanda disponível."));
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: ListView.builder(
                  itemCount: comandas.length,
                  itemBuilder: (context, index) {
                    final comanda = comandas[index];
                    return AdminRelatoriosCard(comanda: comanda);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<List<String>> _getUserIdsWithUserRole() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'user')
        .get();
    return querySnapshot.docs.map((doc) => doc.id).toList();
  }
}
