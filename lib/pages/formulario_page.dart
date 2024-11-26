import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:orama_admin/others/insumos.dart';
import 'package:orama_admin/pages/relatorios_page.dart';
import 'package:orama_admin/pages/stock_tab.dart';
import 'package:orama_admin/stores/stock_store.dart';
import 'package:orama_admin/utils/exit_dialog_utils.dart';
import 'package:provider/provider.dart';

class FormularioPage extends StatelessWidget {
  final String nome;
  final String data;
  final String city;
  final String loja;
  final Map<String, dynamic>?
      reportData; // Novo parâmetro para os dados do relatório
  final String? reportId; // Add reportId parameter

  const FormularioPage({
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

    // Carrega os valores apenas se `reportData` não for nulo (edição de relatório)
    if (reportData != null) {
      store.populateFieldsWithReport(reportData!);
    } else {
      store.clearFields(); // Limpa os campos para novo relatório
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = constraints.maxWidth < 600;

          return DefaultTabController(
            length: insumos.keys.length,
            child: Scaffold(
              appBar: AppBar(
                automaticallyImplyLeading: false,
                leading: isMobile
                    ? Builder(
                        builder: (BuildContext context) {
                          return IconButton(
                            icon: Icon(Icons.menu),
                            color: Colors.white,
                            onPressed: () {
                              Scaffold.of(context).openDrawer();
                            },
                          );
                        },
                      )
                    : null, // Remove o ícone do menu para telas maiores
                bottom: TabBar(
                  isScrollable: true,
                  labelColor: Colors.white,
                  indicatorColor: Colors.amber,
                  tabs: insumos.keys
                      .map((category) => Tab(text: category))
                      .toList(),
                ),
                title: Text(
                  'Estoque - $storeName',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w500),
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
                          MaterialPageRoute(
                              builder: (context) => RelatoriosPage()),
                          (route) => false,
                        );
                      },
                    ),
                  ),
                ],
                backgroundColor: const Color(0xff60C03D),
              ),
              drawer: isMobile
                  ? Drawer(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: _buildDrawerItems(storeName),
                      ),
                    )
                  : null, // Remove o drawer para telas maiores
              body: Row(
                children: [
                  if (!isMobile)
                    Container(
                      width: 250,
                      color: const Color(0xfff4f4f4),
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: _buildDrawerItems(storeName),
                      ),
                    ),
                  Expanded(
                    child: TabBarView(
                      children: insumos.entries.map((entry) {
                        final category = entry.key;
                        final items = entry.value;
                        return StockTab(category: category, items: items);
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildDrawerItems(String storeName) {
    return [
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
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
            ),
            SizedBox(width: 5),
            Icon(Icons.post_add),
          ],
        ),
        onTap: () async {
          await FirebaseAuth.instance.signOut();
        },
      ),
      Divider(),
      ListTile(
        title: Row(
          children: [
            Text(
              'Trocar Conta',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
            ),
            SizedBox(width: 5),
            Icon(Icons.logout_sharp),
          ],
        ),
        onTap: () async {
          await FirebaseAuth.instance.signOut();
        },
      ),
      Divider(),
    ];
  }
}
