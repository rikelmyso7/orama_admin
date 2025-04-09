import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:orama_admin/routes/routes.dart';
import 'package:orama_admin/stores/stock_store.dart';
import 'package:orama_admin/widgets/my_styles/my_drawer.dart';
import 'package:orama_admin/utils/copyReportDialog.dart';
import 'package:orama_admin/pages/loja/Dataespecificoview.dart';

class RelatoriosPage extends StatefulWidget {
  String city;

  RelatoriosPage({this.city = "Jundiaí"});

  @override
  _RelatoriosPageState createState() => _RelatoriosPageState();
}

class _RelatoriosPageState extends State<RelatoriosPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<String> stores = [];
  Map<String, List<Map<String, dynamic>>> cityReports = {};
  Map<String, List<Map<String, dynamic>>> allReportsByCity = {};
  bool isLoading = true;

  @override
void initState() {
  super.initState();
  final store = Provider.of<StockStore>(context, listen: false);
  // Defina Jundiaí como cidade inicial
  widget.city = "Jundiaí"; 
  _filterReportsByCity(widget.city); 
  _loadAllReports(store); 
}


  Future<void> _loadAllReports(StockStore store) async {
    setState(() {
      isLoading = true;
    });

    try {
      // Tenta carregar relatórios do Firestore
      await store.fetchReportsUser('Db4XIYcNMhUgYXvF6JDJJxbc3h82');

      // Filtra relatórios removendo os do usuário especificado
      final allReports = [
        ...store.reports.where(
            (report) => report['UsuarioId'] != 'Db4XIYcNMhUgYXvF6JDJJxbc3h82'),
        ...store.specificReports.where(
            (report) => report['UsuarioId'] != 'Db4XIYcNMhUgYXvF6JDJJxbc3h82'),
      ];

      // Agrupa relatórios por cidade
      _groupReportsByCity(allReports);
      _filterReportsByCity(widget.city);
    } catch (e) {
      print("Erro ao carregar relatórios online: $e");
      // Carrega relatórios do cache local caso haja erro
      await _loadReportsFromCache(store);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadReportsFromCache(StockStore store) async {
    try {
      final cachedReports =
          store.loadCachedReports('Db4XIYcNMhUgYXvF6JDJJxbc3h82');
      if (cachedReports.isNotEmpty) {
        _groupReportsByCity(cachedReports);
        _filterReportsByCity(widget.city);
        print("Relatórios carregados do cache local.");
      } else {
        print("Nenhum relatório no cache local.");
      }
    } catch (e) {
      print("Erro ao carregar relatórios do cache local: $e");
    }
  }

  void _groupReportsByCity(List<Map<String, dynamic>> reports) {
    allReportsByCity = {};
    for (var report in reports) {
      final city = report['Cidade'];
      if (!allReportsByCity.containsKey(city)) {
        allReportsByCity[city] = [];
      }
      allReportsByCity[city]!.add(report);
    }
  }

  void _filterReportsByCity(String city) {
    final reportsForCity = allReportsByCity[city] ?? [];

    // Agrupa os relatórios por loja
    cityReports = {};
    for (var report in reportsForCity) {
      final loja = report['Loja'];
      if (!cityReports.containsKey(loja)) {
        cityReports[loja] = [];
      }
      cityReports[loja]!.add(report);
    }

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    cityReports.forEach((loja, reports) {
      reports.sort((a, b) {
        final dateA = dateFormat.parse(a['Data']);
        final dateB = dateFormat.parse(b['Data']);
        return dateB.compareTo(dateA); // Mais recentes primeiro
      });
    });

    setState(() {
      stores = cityReports.keys.toList();
      if (stores.isNotEmpty) {
        _tabController = TabController(
          length: stores.length,
          vsync: this,
        );
      }
    });
  }

  Future<void> _refreshReports() async {
    final store = Provider.of<StockStore>(context, listen: false);
    await _loadAllReports(store);
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
        title: const Text(
          "Relatórios",
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
            label: 'Jundiaí',
            icon: Icons.post_add,
            onTap: () {
              _filterReportsByCity('Jundiaí');
              Navigator.pop(context);
            },
          ),
          DrawerMenuItem(
            label: 'Itupeva',
            icon: Icons.post_add,
            onTap: () {
              _filterReportsByCity('Itupeva');
              Navigator.pop(context);
            },
          ),
          DrawerMenuItem(
            label: 'Campinas',
            icon: Icons.post_add,
            onTap: () {
              _filterReportsByCity('Campinas');
              Navigator.pop(context);
            },
          ),
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
          ? Center(child: CircularProgressIndicator())
          : stores.isNotEmpty
              ? TabBarView(
                  controller: _tabController,
                  children: stores.map((store) {
                    final reports = cityReports[store] ?? [];
                    return RefreshIndicator(
                      onRefresh: _refreshReports,
                      child: reports.isEmpty
                          ? Center(
                              child: Text(
                                "Nenhum relatório disponível para $store",
                                style:
                                    TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            )
                          : Observer(builder: (_) {
                              return ListView.builder(
                                itemCount: reports.length,
                                itemBuilder: (context, index) {
                                  final report = reports[index];
                                  return _buildReportCard(report);
                                },
                              );
                            }),
                    );
                  }).toList(),
                )
              : Center(
                  child: Text(
                    "Nenhum relatório disponível",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
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
        margin: EdgeInsets.all(8),
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
                  Text(
                    "Relatório - $storeName",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  IconButton(
                    color: Colors.green,
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
              Text(
                "Responsável: $name",
                style: TextStyle(fontSize: 16),
              ),
              Text(
                "Tipo: $tipoRelatorio",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              Text(
                "Data: $date",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              Text(
                "Dia da Semana: $dayOfWeek",
                style: TextStyle(
                  fontWeight: FontWeight.w400,
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
