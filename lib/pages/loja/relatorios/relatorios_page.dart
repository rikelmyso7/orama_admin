import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orama_admin/main.dart';
import 'package:orama_admin/pages/loja/relatorios/Dataespecificoview.dart';
import 'package:provider/provider.dart';
import 'package:orama_admin/routes/routes.dart';
import 'package:orama_admin/stores/stock_store.dart';
import 'package:orama_admin/widgets/my_styles/my_drawer.dart';
import 'package:orama_admin/utils/copyReportDialog.dart';
import 'package:orama_admin/widgets/date_picker_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class RelatoriosPage extends StatefulWidget {
  @override
  _RelatoriosPageState createState() => _RelatoriosPageState();
}

class _RelatoriosPageState extends State<RelatoriosPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<String> stores = [];
  Map<String, List<Map<String, dynamic>>> reportsByStore = {}; // Cache de relatórios por loja
  Map<String, bool> loadingByStore = {}; // Estado de loading por loja
  bool isLoading = true;
  String? selectedStore;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  /// Carrega apenas as lojas da coleção configuracoes_loja
  Future<void> _loadStores() async {
    setState(() {
      isLoading = true;
    });

    try {
      final firestore = secondaryFirestore;
      final snapshot = await firestore.collection('configuracoes_loja').get();

      final fetchedStores = snapshot.docs.map((doc) => doc.id).toList()..sort();

      // Salva no cache
      await _saveStoresToCache(fetchedStores);

      setState(() {
        stores = fetchedStores;
        // Inicializa estado de loading para cada loja
        for (var store in fetchedStores) {
          loadingByStore[store] = false;
        }
      });

      if (stores.isNotEmpty) {
        _setupTabController();
        // Carrega relatórios apenas da primeira loja
        _loadReportsForStore(stores[0]);
      }
    } catch (e) {
      print("Erro ao carregar lojas: $e");
      // Tenta carregar do cache em caso de erro
      await _loadStoresFromCache();
      if (stores.isNotEmpty) {
        _setupTabController();
        _loadReportsForStore(stores[0]);
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveStoresToCache(List<String> storesList) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_stores', json.encode(storesList));
      await prefs.setInt(
          'stores_cache_timestamp', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print("Erro ao salvar lojas no cache: $e");
    }
  }

  Future<void> _loadStoresFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedStoresJson = prefs.getString('cached_stores');

      if (cachedStoresJson != null) {
        final cachedStores = List<String>.from(json.decode(cachedStoresJson));
        setState(() {
          stores = cachedStores;
          for (var store in cachedStores) {
            loadingByStore[store] = false;
          }
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

    if (stores.isNotEmpty) {
      selectedStore = stores[0];
    }
  }

  /// Carrega relatórios apenas da loja selecionada (lazy loading)
  Future<void> _loadReportsForStore(String storeName) async {
    setState(() {
      selectedStore = storeName;
      loadingByStore[storeName] = true;
    });

    // Se já tem cache dessa loja, não precisa recarregar
    if (reportsByStore.containsKey(storeName)) {
      setState(() {
        loadingByStore[storeName] = false;
      });
      return;
    }

    try {
      final firestore = secondaryFirestore;
      final List<Map<String, dynamic>> storeReports = [];

      // Busca relatórios de todos os usuários, filtrando por loja
      final usuariosSnapshot = await firestore.collection('users').get();

      for (var userDoc in usuariosSnapshot.docs) {
        // Pula o usuário específico
        if (userDoc.id == 'Db4XIYcNMhUgYXvF6JDJJxbc3h82') continue;

        // Busca relatórios normais da loja
        final relatoriosSnapshot = await userDoc.reference
            .collection('relatorio')
            .where('Loja', isEqualTo: storeName)
            .get();

        for (var doc in relatoriosSnapshot.docs) {
          storeReports.add({
            ...doc.data(),
            'ID': doc.id,
            'UsuarioId': userDoc.id,
          });
        }

        // Busca relatórios específicos da loja
        final relatoriosEspecificosSnapshot = await userDoc.reference
            .collection('relatorio_especifico')
            .where('Loja', isEqualTo: storeName)
            .get();

        for (var doc in relatoriosEspecificosSnapshot.docs) {
          storeReports.add({
            ...doc.data(),
            'ID': doc.id,
            'UsuarioId': userDoc.id,
          });
        }
      }

      // Ordena por data (mais recentes primeiro)
      _sortReportsByDate(storeReports);

      setState(() {
        reportsByStore[storeName] = storeReports;
        loadingByStore[storeName] = false;
      });
    } catch (e) {
      print("Erro ao carregar relatórios de $storeName: $e");
      setState(() {
        reportsByStore[storeName] = [];
        loadingByStore[storeName] = false;
      });
    }
  }

  void _sortReportsByDate(List<Map<String, dynamic>> reports) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    reports.sort((a, b) {
      try {
        final dateA = dateFormat.parse(a['Data'] ?? '');
        final dateB = dateFormat.parse(b['Data'] ?? '');
        return dateB.compareTo(dateA);
      } catch (e) {
        return 0;
      }
    });
  }

  /// Força recarregar os relatórios da loja (limpa o cache)
  Future<void> _reloadReportsForStore(String storeName) async {
    reportsByStore.remove(storeName);
    await _loadReportsForStore(storeName);
  }

  void goToPreviousDay() {
    setState(() {
      selectedDate = selectedDate.subtract(Duration(days: 1));
    });
  }

  void goToNextDay() {
    setState(() {
      selectedDate = selectedDate.add(Duration(days: 1));
    });
  }

  String getFormattedDate(DateTime date) {
    return DateFormat("dd 'de' MMMM yyyy", 'pt_BR').format(date);
  }

  Future<void> _refreshData() async {
    // Limpa cache e recarrega a loja atual
    if (selectedStore != null) {
      await _reloadReportsForStore(selectedStore!);
    }
  }

  Future<void> _refreshAllData() async {
    // Limpa todos os caches e recarrega tudo
    reportsByStore.clear();
    await _loadStores();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          "Relatórios Lojas",
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
            label: 'Reposição',
            icon: Icons.add_business_outlined,
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed(RouteName.reposicao);
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
              Navigator.of(context).pushReplacementNamed(RouteName.admin_page);
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
                          dateFormat: DateFormat("dd 'de' MMMM yyyy", 'pt_BR'),
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
                                style:
                                    TextStyle(fontSize: 18, color: Colors.grey),
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
    );
  }

  Widget _buildStoreReportsView(String storeName) {
    final isLoadingThis = loadingByStore[storeName] ?? false;

    if (isLoadingThis) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xff60C03D)),
            SizedBox(height: 16),
            Text("Carregando relatórios de $storeName...",
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final reports = reportsByStore[storeName] ?? [];

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
            Icon(Icons.description_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "Nenhum relatório disponível",
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
    final dateString = report['Data'] ?? '';
    DateTime? parsedDate;

    try {
      parsedDate = DateFormat('dd/MM/yyyy HH:mm').parse(dateString);
    } catch (e) {
      print("Erro ao converter a data: $e");
    }

    final dayOfWeek = parsedDate != null
        ? DateFormat('EEEE', 'pt_BR').format(parsedDate)
        : '';

    final date = report['Data'] ?? '';
    final name = report['Nome do usuario'] ?? '';
    final storeName = report['Loja'] ?? '';
    final city = report['Cidade'] ?? '';
    final tipoRelatorio = report['Tipo Relatorio'] ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Dataespecificoview(report: report),
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
                      "Relatório - $storeName",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    color: Color(0xff60C03D),
                    icon: Icon(Icons.copy),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return CopyReportDialog(
                            report: report,
                            store: Provider.of<StockStore>(context),
                          );
                        },
                      );
                    },
                  ),
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
                "Tipo: $tipoRelatorio",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              Text(
                "Data: $date",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              if (dayOfWeek.isNotEmpty)
                Text(
                  "Dia da Semana: $dayOfWeek",
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    color: Colors.grey[600],
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
