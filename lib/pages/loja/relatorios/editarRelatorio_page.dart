import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:orama_admin/routes/routes.dart';
import 'package:provider/provider.dart';
import 'package:orama_admin/others/insumos.dart';
import 'package:orama_admin/stores/stock_store.dart';

class EditarRelatoriosPage extends StatelessWidget {
  final String nome;
  final String data;
  final String city;
  final String loja;
  final Map<String, dynamic> reportData;
  final String reportId;

  const EditarRelatoriosPage({
    Key? key,
    required this.nome,
    required this.data,
    required this.city,
    required this.loja,
    required this.reportData,
    required this.reportId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<StockStore>(context);

    // Popula os campos com os dados do relatório
    store.populateFieldsWithReport2(reportData);

    return DefaultTabController(
      length: insumos.keys.length,
      child: WillPopScope(
        onWillPop: () async {
          // Limpa os dados apenas ao sair explicitamente da página
          store.clearFields();
          return true; // Permite sair da página
        },
        child: Scaffold(
          appBar: AppBar(
            iconTheme: const IconThemeData(color: Colors.white),
            bottom: TabBar(
              isScrollable: true,
              labelColor: Colors.white,
              indicatorColor: Colors.amber,
              tabs:
                  insumos.keys.map((category) => Tab(text: category)).toList(),
            ),
            title: Text(
              'Editar - $loja',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w500),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: IconButton(
                  color: Colors.white,
                  icon: const Icon(Icons.delete),
                  iconSize: 26,
                  onPressed: () async {
                    await store.deleteReport(reportId);
                    Navigator.pop(context);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: IconButton(
                  color: Colors.white,
                  icon: const Icon(Icons.save),
                  iconSize: 26,
                  onPressed: () async {
                    await store.updateReport(reportId, nome, city, loja, data);
                    store.fetchReports();
                    Navigator.pushReplacementNamed(
                        context, RouteName.reposicao);
                  },
                ),
              ),
            ],
            backgroundColor: const Color(0xff60C03D),
          ),
          body: Observer(builder: (_) {
            return TabBarView(
              children: insumos.entries.map((entry) {
                final category = entry.key;
                final items = entry.value;

                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: 1,
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: '0',
                                labelText: false ? 'Peso (kg)' : 'Quantidade',
                              ),
                              onChanged: (value) {},
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }).toList(),
            );
          }),
        ),
      ),
    );
  }
}
