import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:orama_admin/pages/admin_page.dart';
import 'package:orama_admin/pages/estoque_page.dart';
import 'package:orama_admin/pages/relatorios_descartaveis_page.dart';
import 'package:orama_admin/stores/comanda_store.dart';
import 'package:orama_admin/utils/exit_dialog_utils.dart';
import 'package:orama_admin/widgets/BottomNavigationBar.dart';
import 'package:orama_admin/widgets/cards/admin_relatorios_card.dart';
import 'package:orama_admin/widgets/date_picker_widget.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

class RelatoriosSorvetePage extends StatefulWidget {
  @override
  _RelatoriosSorvetePageState createState() => _RelatoriosSorvetePageState();
}

class _RelatoriosSorvetePageState extends State<RelatoriosSorvetePage>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 2;
  final box = GetStorage();
  DateTime _selectedDate = DateTime.now();
  Future<List<String>>? _userIdsFuture;
  List<bool> _selectedComandas = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _userIdsFuture = _getUserIdsWithUserRole();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _selectedComandas = [];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final comandaStore = Provider.of<ComandaStore>(context, listen: false);
      setState(() {
        _selectedComandas = List.filled(comandaStore.comandas.length, false);
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void onTabTapped(int index) {
    Widget page;
    switch (index) {
      case 0:
        page = AdminPage();
        break;
      case 1:
        page = EstoqueAdminPage();
        break;
      case 2:
        setState(() {
          _currentIndex = index;
        });
        return;
      case 3:
        page = RelatoriosDescartaveisPage();
        break;
      default:
        return;
    }
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => page));
  }

  void _updateSelectedDate(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
    });
  }

  void _deleteComanda(String userId, String comandaId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('comandas')
          .doc(comandaId)
          .delete();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Comanda excluída com sucesso')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir a comanda')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final comandaStore = Provider.of<ComandaStore>(context);

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;

        final bool shouldPop = await DialogUtils.showConfirmationDialog(
              context: context,
              title: 'Confirmação de Saída',
              content: 'Você deseja cancelar?',
              confirmText: 'Sim',
              cancelText: 'Não',
              onConfirm: () {
                Navigator.pop(context);
              },
            ) ??
            false;
      },
      child: Scaffold(
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
          bottom: TabBar(
            labelColor: Colors.white,
            indicatorColor: Colors.amber,
            controller: _tabController,
            tabs: [
              Tab(text: "INICIO"),
              Tab(text: "FINAL"),
            ],
          ),
        ),
        body: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    _updateSelectedDate(
                        _selectedDate.subtract(Duration(days: 1)));
                  },
                ),
                DatePickerWidget(
                  key: UniqueKey(),
                  initialDate: _selectedDate,
                  onDateSelected: (newDate) {
                    _updateSelectedDate(newDate);
                  },
                  dateFormat: DateFormat('dd MMMM yyyy', 'pt_BR'),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () {
                    _updateSelectedDate(_selectedDate.add(Duration(days: 1)));
                  },
                ),
              ],
            ),
            Expanded(
              child: FutureBuilder<List<String>>(
                future: _userIdsFuture,
                builder: (context, userIdsSnapshot) {
                  if (userIdsSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (userIdsSnapshot.hasError) {
                    return Center(child: Text("Erro ao carregar usuários"));
                  }

                  final userIds = userIdsSnapshot.data ?? [];

                  if (userIds.isEmpty) {
                    return Center(
                        child:
                            Text("Nenhum usuário com role 'user' encontrado."));
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

                      final selectedTab =
                          _tabController.index == 0 ? "INICIO" : "FINAL";

                      final comandas = snapshot.data
                              ?.expand((querySnapshot) => querySnapshot.docs)
                              .where((doc) {
                                final comandaDate = DateTime.parse(doc['data']);
                                final comandaName = doc['name']
                                    as String; // Obtenha o campo name
                                final isInicio = comandaName
                                    .contains("(INICIO)"); // Verifica a aba
                                return comandaDate.year == _selectedDate.year &&
                                    comandaDate.month == _selectedDate.month &&
                                    comandaDate.day == _selectedDate.day &&
                                    ((selectedTab == "INICIO" && isInicio) ||
                                        (selectedTab == "FINAL" &&
                                            !isInicio)); // Filtra pela aba selecionada
                              })
                              .map((doc) => Comanda.fromJson(
                                  doc.data() as Map<String, dynamic>))
                              .toList() ??
                          [];

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_selectedComandas.length != comandas.length) {
                          _selectedComandas =
                              List.filled(comandas.length, false);
                        }
                      });

                      if (comandas.isEmpty) {
                        final noComandasMessage = selectedTab == "INICIO"
                            ? "Nenhuma comanda disponível para INICIO"
                            : "Nenhuma comanda disponível para FINAL";
                        return Center(child: Text(noComandasMessage));
                      }

                      return ListView.builder(
                        itemCount: comandas.length,
                        itemBuilder: (context, index) {
                          final comanda = comandas[index];
                          return AdminRelatoriosCard(
                            comanda: comanda,
                            onDelete: (comandaId) =>
                                _deleteComanda(comanda.userId, comandaId),
                            isSelected: index < _selectedComandas.length
                                ? _selectedComandas[index]
                                : false,
                            onChanged: (value) {
                              setState(() {
                                _selectedComandas[index] = value!;
                              });
                            },
                            isExpanded:
                                comandaStore.getExpansionState(comanda.id),
                            onExpansionChanged: (isExpanded) {
                              comandaStore.setExpansionState(
                                  comanda.id, isExpanded);
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
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
