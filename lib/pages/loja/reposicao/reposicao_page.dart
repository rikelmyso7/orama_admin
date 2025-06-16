import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:orama_admin/pages/loja/reposicao/DataReposicaoView.dart';
import 'package:orama_admin/pages/loja/reposicao/add_reposicao_info.dart';
import 'package:orama_admin/pages/loja/relatorios/relatorios_page.dart';
import 'package:orama_admin/pages/loja/reposicao/editar_reposicao_page.dart';
import 'package:orama_admin/routes/routes.dart';
import 'package:orama_admin/stores/stock_store.dart';
import 'package:orama_admin/utils/exit_dialog_utils.dart';
import 'package:orama_admin/utils/gerar_excel.dart';
import 'package:orama_admin/utils/gerar_romaneio.dart';
import 'package:orama_admin/widgets/date_picker_widget.dart';
import 'package:orama_admin/widgets/my_styles/my_drawer.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ReposicaoPage extends StatefulWidget {
  @override
  _ReposicaoPageState createState() => _ReposicaoPageState();
}

class _ReposicaoPageState extends State<ReposicaoPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<String> stores = [];
  Map<String, List<Map<String, dynamic>>> storeReports = {};
  Map<String, List<Map<String, dynamic>>> allReportsByStore = {};
  bool isLoading = true;
  bool isLoadingReports = false;
  String? selectedStore;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadStoresAndReports();
    final store = Provider.of<StockStore>(context, listen: false);
    store.fetchReports();
  }

  Future<List<String>> fetchAllowedStores() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('lojas').get();

      List<String> storesList = [];
      for (var doc in snapshot.docs) {
        // Assumindo que o nome da loja está no campo 'name' ou use doc.id
        final storeName = doc.data()['name'] ?? doc.id;
        storesList.add(storeName);
      }

      return storesList;
    } catch (e) {
      print("Erro ao buscar lojas permitidas: $e");
      throw e;
    }
  }

  Future<void> _loadStoresAndReports() async {
    setState(() {
      isLoading = true;
    });

    try {
      final store = Provider.of<StockStore>(context, listen: false);

      // Carrega lista de lojas
      await _loadStores(store);

      if (stores.isNotEmpty) {
        _setupTabController();
        // Carrega todos os relatórios de reposição
        await _loadAllReports(store);
      }
    } catch (e) {
      print("Erro ao carregar dados: $e");
      // Tenta carregar do cache em caso de erro
      await _loadStoresFromCache();
      if (stores.isNotEmpty) {
        _setupTabController();
        final store = Provider.of<StockStore>(context, listen: false);
        await _loadReportsFromCache(store);
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadStores(StockStore store) async {
    try {
      List<String> fetchedStores = await _fetchStoresFromFirebase(store);

      // Salva no cache
      await _saveStoresToCache(fetchedStores);

      setState(() {
        stores = fetchedStores;
      });
    } catch (e) {
      print("Erro ao carregar lojas do Firebase: $e");
      throw e;
    }
  }

  Future<List<String>> _fetchStoresFromFirebase(StockStore store) async {
    // Busca os relatórios de reposição
    await store.fetchReports();

    Set<String> uniqueStores = {};
    for (var report in store.reports) {
      final storeName = report['Loja'];
      if (storeName != null && storeName.isNotEmpty) {
        uniqueStores.add(storeName);
      }
    }

    return uniqueStores.toList()..sort();
  }

  Future<void> _saveStoresToCache(List<String> storesList) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_reposicao_stores', json.encode(storesList));
      await prefs.setInt('reposicao_stores_cache_timestamp',
          DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print("Erro ao salvar lojas no cache: $e");
    }
  }

  Future<void> _loadStoresFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedStoresJson = prefs.getString('cached_reposicao_stores');

      if (cachedStoresJson != null) {
        final cachedStores = List<String>.from(json.decode(cachedStoresJson));
        setState(() {
          stores = cachedStores;
        });
        print("Lojas carregadas do cache local: ${stores.length} lojas");
      } else {
        print("Nenhuma loja no cache local.");
      }
    } catch (e) {
      print("Erro ao carregar lojas do cache local: $e");
    }
  }

  void _setupTabController() {
    _tabController = TabController(
      length: stores.length,
      vsync: this,
    );

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final currentStore = stores[_tabController.index];
        if (selectedStore != currentStore) {
          _loadReportsForStore(currentStore);
        }
      }
    });

    // Carrega relatórios da primeira loja
    if (stores.isNotEmpty) {
      _loadReportsForStore(stores[0]);
    }
  }

  Future<void> _loadAllReports(StockStore store) async {
    try {
      await store.fetchReports();

      _groupReportsByStore(store.reports);

      // Salva relatórios no cache
      await _saveReportsToCache(store.reports);
    } catch (e) {
      print("Erro ao carregar relatórios online: $e");
      throw e;
    }
  }

  Future<void> _loadReportsFromCache(StockStore store) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedReportsJson = prefs.getString('cached_reposicao_reports');

      if (cachedReportsJson != null) {
        final cachedReports = List<Map<String, dynamic>>.from(json
            .decode(cachedReportsJson)
            .map((x) => Map<String, dynamic>.from(x)));
        _groupReportsByStore(cachedReports);
        print("Relatórios de reposição carregados do cache local.");
      } else {
        print("Nenhum relatório de reposição no cache local.");
      }
    } catch (e) {
      print("Erro ao carregar relatórios do cache local: $e");
    }
  }

  Future<void> _saveReportsToCache(List<Map<String, dynamic>> reports) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_reposicao_reports', json.encode(reports));
      await prefs.setInt('reposicao_reports_cache_timestamp',
          DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print("Erro ao salvar relatórios no cache: $e");
    }
  }

  void _groupReportsByStore(List<Map<String, dynamic>> reports) {
    allReportsByStore = {};
    for (var report in reports) {
      final storeName = report['Loja'];
      if (storeName != null && storeName.isNotEmpty) {
        if (!allReportsByStore.containsKey(storeName)) {
          allReportsByStore[storeName] = [];
        }
        allReportsByStore[storeName]!.add(report);
      }
    }

    // Ordena relatórios por data (mais recentes primeiro)
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    allReportsByStore.forEach((storeName, reports) {
      reports.sort((a, b) {
        try {
          final dateA = dateFormat.parse(a['Data'] ?? '');
          final dateB = dateFormat.parse(b['Data'] ?? '');
          return dateB.compareTo(dateA);
        } catch (e) {
          return 0;
        }
      });
    });
  }

  void _loadReportsForStore(String storeName) {
    setState(() {
      isLoadingReports = true;
      selectedStore = storeName;
    });

    // Simula um pequeno delay para mostrar o loading
    Future.delayed(Duration(milliseconds: 300), () {
      final allStoreReports = allReportsByStore[storeName] ?? [];

      // Filtra relatórios por data selecionada
      final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
      final filteredReports = allStoreReports.where((report) {
        final dateStr = report['Data'];
        if (dateStr == null) return false;
        try {
          final reportDate = dateFormat.parse(dateStr, true).toLocal();
          return reportDate.year == selectedDate.year &&
              reportDate.month == selectedDate.month &&
              reportDate.day == selectedDate.day;
        } catch (e) {
          return false;
        }
      }).toList();

      setState(() {
        storeReports = {storeName: filteredReports};
        isLoadingReports = false;
      });
    });
  }

  void goToPreviousDay() {
    setState(() {
      selectedDate = selectedDate.subtract(Duration(days: 1));
    });
    if (selectedStore != null) {
      _loadReportsForStore(selectedStore!);
    }
  }

  void goToNextDay() {
    setState(() {
      selectedDate = selectedDate.add(Duration(days: 1));
    });
    if (selectedStore != null) {
      _loadReportsForStore(selectedStore!);
    }
  }

  String getFormattedDate(DateTime date) {
    return DateFormat("dd 'de' MMMM yyyy", 'pt_BR').format(date);
  }

  Future<void> _refreshData() async {
    await _loadStoresAndReports();
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<StockStore>(context);

    return Observer(builder: (_) {
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
          appBar: AppBar(
            automaticallyImplyLeading: false,
            elevation: 4,
            leading: Builder(
              builder: (BuildContext context) {
                return IconButton(
                  icon: Icon(Icons.menu),
                  color: Colors.white,
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                );
              },
            ),
            title: Text(
              "Reposições Lojas",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: const Color(0xff60C03D),
            bottom: stores.isNotEmpty
                ? TabBar(
                    labelColor: Colors.white,
                    indicatorColor: Colors.amber,
                    controller: _tabController,
                    isScrollable: stores.length > 3,
                    tabs: stores.map((store) {
                      return Tab(text: store);
                    }).toList(),
                  )
                : null,
          ),
          drawer: MyDrawer(
            title: 'Admin',
            menuItems: [
              DrawerMenuItem(
                label: 'Relatórios',
                icon: Icons.create_new_folder_outlined,
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => RelatoriosPage()),
                  );
                },
              ),
              DrawerMenuItem(
                label: 'Fábrica',
                icon: Icons.add_home_work_outlined,
                onTap: () {
                  Navigator.of(context).pushNamed(RouteName.fabrica);
                },
              ),
              DrawerMenuItem(
                label: 'Tela Inicial',
                icon: Icons.home_outlined,
                onTap: () {
                  Navigator.of(context)
                      .pushReplacementNamed(RouteName.admin_page);
                },
              ),
            ],
          ),
          body: isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Color(0xff60C03D)),
                      SizedBox(height: 16),
                      Text("Carregando lojas...",
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : stores.isNotEmpty
                  ? Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_back),
                              onPressed: goToPreviousDay,
                            ),
                            DatePickerWidget(
                              key: ValueKey(selectedDate),
                              initialDate: selectedDate,
                              onDateSelected: (newDate) {
                                setState(() {
                                  selectedDate = newDate;
                                });
                                if (selectedStore != null) {
                                  _loadReportsForStore(selectedStore!);
                                }
                              },
                              dateFormat:
                                  DateFormat("dd 'de' MMMM yyyy", 'pt_BR'),
                              textStyle: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff60C03D),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.arrow_forward),
                              onPressed: goToNextDay,
                            ),
                          ],
                        ),
                        // TabBarView
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: stores.map((store) {
                              return RefreshIndicator(
                                onRefresh: _refreshData,
                                child: _buildStoreReportsView(store),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    )
                  : RefreshIndicator(
                      onRefresh: _refreshData,
                      child: ListView(
                        children: [
                          Container(
                            height: MediaQuery.of(context).size.height * 0.7,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.store_outlined,
                                      size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    "Nenhuma loja disponível",
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.grey),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "Puxe para atualizar",
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey[400]),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: const Color(0xff60C03D),
            icon: Icon(Icons.add, color: Colors.white),
            label: Text('Adicionar', style: TextStyle(color: Colors.white)),
            onPressed: () {
              store.clearRepoFields();
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => AddReposicaoInfo()));
            },
          ),
        ),
      );
    });
  }

  Widget _buildStoreReportsView(String storeName) {
    if (isLoadingReports && selectedStore == storeName) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xff60C03D)),
            SizedBox(height: 16),
            Text("Carregando reposições de $storeName...",
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final reports = allReportsByStore[storeName] ?? [];

    // Filtra relatórios por data selecionada
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final filteredReports = reports.where((report) {
      final dateStr = report['Data'];
      if (dateStr == null) return false;
      try {
        final reportDate = dateFormat.parse(dateStr, true).toLocal();
        return reportDate.year == selectedDate.year &&
            reportDate.month == selectedDate.month &&
            reportDate.day == selectedDate.day;
      } catch (e) {
        return false;
      }
    }).toList();

    if (filteredReports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "Nenhuma reposição disponível",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              "para $storeName em ${getFormattedDate(selectedDate)}",
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: filteredReports.length,
      itemBuilder: (context, index) {
        final report = filteredReports[index];
        return _buildReportCard(report);
      },
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final date = report['Data'] ?? '';
    final name = report['Nome do usuario'] ?? '';
    final loja = report['Loja'] ?? '';
    final city = report['Cidade'] ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DataReposicaoView(report: report),
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 6, horizontal: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "Reposição - $loja",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditarReposicaoPage(
                                nome: name,
                                data: date,
                                loja: loja,
                                city: city,
                                reportData: report,
                                reportId: report['ID'],
                              ),
                            ),
                          );
                        },
                        child: Icon(Icons.edit, size: 26),
                      ),
                      SizedBox(width: 8),
                      IconButton(
                        onPressed: () async {
                          final store =
                              Provider.of<StockStore>(context, listen: false);
                          final message =
                              store.formatReportForWhatsAppRepo(report);
                          await Share.share(message);
                        },
                        icon: FaIcon(FontAwesomeIcons.whatsapp),
                      ),
                      IconButton(
                        onPressed: () async {
                          try {
                            await gerarRomaneioPDF(context, report);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text("Erro ao compartilhar: $e")),
                            );
                          }
                        },
                        icon: Icon(Icons.share, size: 26),
                      )
                    ],
                  )
                ],
              ),
              SizedBox(height: 8),
              if (city.isNotEmpty)
                Text(
                  "Cidade: $city",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              SizedBox(height: 4),
              Text(
                "Responsável: $name",
                style: TextStyle(fontSize: 16),
              ),
              Text(
                "Data: $date",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
