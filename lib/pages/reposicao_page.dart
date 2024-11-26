import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:orama_admin/others/insumos.dart';
import 'package:orama_admin/pages/relatorios_page.dart';
import 'package:orama_admin/pages/stock_tab.dart';
import 'package:orama_admin/routes/routes.dart';
import 'package:orama_admin/stores/stock_store.dart';
import 'package:orama_admin/utils/exit_dialog_utils.dart';
import 'package:provider/provider.dart';

class ReposicaoPage extends StatelessWidget {
  final String nome;
  final String data;
  final String city;
  final String loja;
  final Map<String, dynamic>? reportData;
  final String? reportId;

  const ReposicaoPage({
    Key? key,
    required this.nome,
    required this.data,
    required this.reportData,
    this.reportId,
    required this.city,
    required this.loja,
  }) : super(key: key);

  String getStoreName() {
    final userId = GetStorage().read('userId');

    switch (userId) {
      case "h0g6nwqiRKcM3VSFk6Wu4JFWe9k2":
        return "Orama Paineiras";
      case "gwYkGevTSZUuGpMQsKLQSlFHZpm2":
        return "Orama Itupeva";
      case "VNlSNV0SKEOACk9Cxcxwe4E2Rtm2":
        return "Orama Retiro";
      default:
        return "Loja";
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<StockStore>(context);
    final storeName = getStoreName();
    final isMobile = false;

    if (reportData != null) {
      store.populateFieldsWithReport(reportData!);
    } else {
      store.clearFields();
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) {
          return;
        }
        final bool shouldPop =
            await DialogUtils.showBackDialog(context) ?? false;
        if (context.mounted && shouldPop) {
          Navigator.pop(context);
        }
      },
      child: DefaultTabController(
        length: insumos.keys.length,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
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
            bottom: TabBar(
              isScrollable: true,
              labelColor: Colors.white,
              indicatorColor: Colors.amber,
              tabs:
                  insumos.keys.map((category) => Tab(text: category)).toList(),
            ),
            title: Text(
              'Estoque - $storeName',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: IconButton(
                  color: Colors.white,
                  icon: Icon(Icons.save),
                  onPressed: () async {
                    await store.saveData(nome, data, city, loja);

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => RelatoriosPage()),
                      (route) => false,
                    );
                  },
                ),
              ),
            ],
            backgroundColor: const Color(0xff60C03D),
          ),
          drawer: Container(
            width: MediaQuery.of(context).size.width / 1.4,
            child: Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Container(
                    height: 100,
                    child: DrawerHeader(
                      decoration: BoxDecoration(
                        color: const Color(0xff60C03D),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Loja $storeName',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 26,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ListTile(
                    title: Row(
                      children: [
                        Text(
                          'Relatórios',
                          style: TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 18),
                        ),
                        SizedBox(width: 5),
                        Icon(Icons.post_add),
                      ],
                    ),
                    onTap: () async {
                      Navigator.of(context)
                          .pushReplacementNamed(RouteName.relatorios);
                    },
                  ),
                  Divider(),
                  ListTile(
                    title: const Align(
                        alignment: Alignment.bottomLeft,
                        child: Row(
                          children: [
                            Text(
                              'Tela Inicial',
                              style: TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 18),
                            ),
                            SizedBox(
                              width: 5,
                            ),
                            Icon(Icons.home_outlined)
                          ],
                        )),
                    onTap: () async {
                      Navigator.of(context)
                          .pushReplacementNamed(RouteName.admin_page);
                    },
                  ),
                  Divider(),
                ],
              ),
            ),
          ),
          body: TabBarView(
            children: insumos.entries.map((entry) {
              final category = entry.key;
              final items = entry.value;
              return StockTab(category: category, items: items);
            }).toList(),
          ),
        ),
      ),
    );
  }
}
