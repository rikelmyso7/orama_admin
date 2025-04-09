import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:orama_admin/others/insumos.dart';
import 'package:orama_admin/pages/loja/reposicao/reposicao_page.dart';
import 'package:orama_admin/routes/routes.dart';
import 'package:orama_admin/stores/stock_store.dart';
import 'package:orama_admin/utils/addItemDialog.dart';
import 'package:orama_admin/utils/extensions.dart';
import 'package:orama_admin/widgets/my_styles/my_input_field.dart';
import 'package:provider/provider.dart';

class ReposicaoFormularioPage extends StatefulWidget {
  final String nome;
  final String data;
  final String city;
  final String loja;
  final Map<String, dynamic>? reportData;
  final String reportId;

  const ReposicaoFormularioPage({
    Key? key,
    required this.nome,
    required this.data,
    required this.reportData,
    required this.reportId,
    required this.city,
    required this.loja,
  }) : super(key: key);

  @override
  State<ReposicaoFormularioPage> createState() => _ReposicaoFormularioPageState();
}

class _ReposicaoFormularioPageState extends State<ReposicaoFormularioPage> {
  Map<String, TextEditingController> _quantityControllers = {};
  Map<String, TextEditingController> _pesoControllers = {};

 @override
  void initState() {
    super.initState();
    final store = Provider.of<StockStore>(context, listen: false);
    if (widget.reportData != null) {
      store.populateFieldsWithReport2(widget.reportData!);
    }
    insumos.forEach((category, items) {
      for (var item in items) {
        final key = store.generateKey(category, item['nome']);
        _quantityControllers[key] =
            TextEditingController(text: store.quantityValuesRepo[key] ?? '');
        _pesoControllers[key] =
            TextEditingController(text: store.pesoValuesRepo[key] ?? '');
      }
    });
  }

  @override
  void dispose() {
    _quantityControllers.forEach((_, controller) => controller.dispose());
    _pesoControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<StockStore>(context);

    if (widget.reportData != null) {
      store.populateFieldsWithReport2(widget.reportData!);
    } else {
      store.clearFields();
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;
        if (context.mounted) {
          store.clearFields();
          Navigator.pop(context);
        }
      },
      child: DefaultTabController(
        length: insumos.keys.length,
        child: Scaffold(
          appBar: AppBar(
            iconTheme: const IconThemeData(color: Colors.white),
            bottom: TabBar(
              isScrollable: true,
              labelColor: Colors.white,
              indicatorColor: Colors.amber,
              tabs: insumos.keys.map((category) => Tab(text: category)).toList(),
            ),
            title: const Text(
              'Reposição',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
            actions: [
              IconButton(
                color: Colors.white,
                icon: const Icon(Icons.save),
                onPressed: () async {
                  await store.saveDataToAdminReposicao(
                      widget.nome, widget.data, widget.city, widget.loja);
                  store.clearFields();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => ReposicaoPage()),
                    (route) => false,
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
            backgroundColor: const Color(0xff60C03D),
          ),
          body: Observer(
            builder: (_) => TabBarView(
              children: insumos.entries.map((entry) {
                final category = entry.key;
                final items = List.from(insumos[category]!)
                  ..sort((a, b) => a['nome'].compareTo(b['nome']));

                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final itemName = item['nome'];
                    final tipo = item['tipo'];
                    final key = (category == 'BALDES' || category == 'POTES')
                        ? '${category}_$itemName'
                        : itemName;

                    final quantityController = _quantityControllers[key]!;
          final pesoController = _pesoControllers[key]!;


                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              itemName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: quantityController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Quantidade',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      suffixIcon: Icon(
                                        Icons.production_quantity_limits,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                    onChanged: (value) {
                                      final quantity = int.tryParse(value) ?? 0;
                                      store.updateQuantityReposicao(key, value);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: pesoController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Peso (Gr)',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      suffixIcon: Icon(Icons.add_shopping_cart_rounded),
                                      suffixIconColor: Colors.grey[500],
                                    ),
                                    onChanged: (value) {
                                      // não é necessário atualizar o estado aqui
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}