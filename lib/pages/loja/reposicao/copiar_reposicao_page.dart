import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:orama_admin/others/insumos.dart';
import 'package:orama_admin/routes/routes.dart';
import 'package:orama_admin/stores/stock_store.dart';
import 'package:orama_admin/utils/addItemDialog.dart';
import 'package:orama_admin/widgets/my_styles/my_input_field.dart';
import 'package:provider/provider.dart';

class CopiarReposicaoPage extends StatefulWidget {
  final String nome;
  final String data;
  final String city;
  final String loja;
  final Map<String, dynamic> reportData;
  final String reportId;

  const CopiarReposicaoPage({
    Key? key,
    required this.nome,
    required this.data,
    required this.city,
    required this.loja,
    required this.reportData,
    required this.reportId,
  }) : super(key: key);

  @override
  _CopiarReposicaoPageState createState() => _CopiarReposicaoPageState();
}

class _CopiarReposicaoPageState extends State<CopiarReposicaoPage> {
  late StockStore store;
  bool isDataLoaded = false;
  Map<String, TextEditingController> _quantityControllers = {};
  Map<String, TextEditingController> _pesoControllers = {};

  @override
  void initState() {
    super.initState();
    store = Provider.of<StockStore>(context, listen: false);
    _initializeControllers(); // <- depois cria os controllers com os dados preenchidos
    isDataLoaded = true;
    print(widget.reportData);
  }

  void _initializeControllers() {
    // NÃO preencher com valores do relatório anterior!
    insumos.forEach((category, items) {
      for (var item in items) {
        final itemName = item['nome'];
        final key = (category == 'BALDES' || category == 'POTES')
            ? '${category}_$itemName'
            : itemName;

        // Inicializa os campos vazios para o usuário digitar
        _quantityControllers[key] = TextEditingController();
        _pesoControllers[key] = TextEditingController();
      }
    });
  }

  @override
  void dispose() {
    // Descarta todos os controladores locais
    _quantityControllers.forEach((_, controller) => controller.dispose());
    _pesoControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!isDataLoaded) {
      store = Provider.of<StockStore>(context, listen: false);
      store.populateFieldsWithRepo(widget.reportData);

      isDataLoaded = true;
    }
  }

  String _getCopiedValue(String field, String itemName, String category) {
    for (var cat in widget.reportData['Categorias'] ?? []) {
      if (cat['Categoria'] == category) {
        for (var item in cat['Itens'] ?? []) {
          if (item['Item'] == itemName) {
            return item[field]?.toString() ?? '';
          }
        }
      }
    }
    return '';
  }

  Future<void> updateEditReposicaoLocal() async {
    final DateTime now = DateTime.now().toUtc().add(const Duration(hours: -3));
    final String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(now);

    final categorias = insumos.entries
        .map((entry) {
          final category = entry.key;
          final items = <Map<String, dynamic>>[];

          for (var item in entry.value) {
            final itemName = item['nome'];
            final tipo = item['tipo'] ?? '';
            final key = (category == 'BALDES' || category == 'POTES')
                ? '${category}_$itemName'
                : itemName;

            final quantidadeAtual =
                _quantityControllers[key]?.text.trim() ?? '';
            final peso = _pesoControllers[key]?.text.trim() ?? '';
            final qtdAnterior =
                _getCopiedValue('Quantidade', itemName, category);

            // Salvar só se o usuário digitou algo novo
            if (quantidadeAtual.isNotEmpty || peso.isNotEmpty) {
              items.add({
                'Item': itemName,
                'Quantidade': quantidadeAtual,
                'Qtd Anterior': qtdAnterior,
                'Peso': peso,
                'Tipo': tipo,
              });
            }
          }

          return items.isNotEmpty
              ? {'Categoria': category, 'Itens': items}
              : null;
        })
        .where((categoria) => categoria != null)
        .cast<Map<String, dynamic>>()
        .toList();

    final updatedData = {
      'ID': widget.reportId,
      'Nome do usuario': widget.nome,
      'Data': formattedDate,
      'Cidade': widget.city,
      'Loja': widget.loja,
      'Categorias': categorias,
    };

    try {
      await store.firestore
          .collection('users')
          .doc('Db4XIYcNMhUgYXvF6JDJJxbc3h82')
          .collection('reposicao')
          .doc(widget.reportId)
          .set(updatedData, SetOptions(merge: true));
      store.clearRepoFields();
      await store.fetchReports();
    } catch (e) {
      print("Erro ao atualizar reposição: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsForReport = store.getItemsForReport(widget.reportId);

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) {
          return;
        }
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, RouteName.reposicao);
        }
      },
      child: DefaultTabController(
        length: itemsForReport.keys.length,
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
            title: const Text(
              'Editar Reposição',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
            actions: [
              IconButton(
                color: Colors.white,
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  await store.deleteReposicao(widget.reportId);
                  Navigator.pushReplacementNamed(context, RouteName.reposicao);
                },
              ),
              IconButton(
                color: Colors.white,
                icon: const Icon(Icons.save),
                onPressed: () async {
                  // Atualiza os valores no store antes de salvar
                  _quantityControllers.forEach((key, controller) {
                    store.updateQuantityEdit(key, controller.text);
                  });
                  await updateEditReposicaoLocal();

                  store.fetchReports();
                  store.clearRepoFields();
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
              ),
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

                    return Observer(
                      builder: (_) {
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        itemName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: InputField(
                                        label: 'Quantidade',
                                        controller: quantityController,
                                        inputType: TextInputType
                                            .number, // Corrigido para número
                                        onChanged: (value) {
                                          store.updateQuantityEdit(key, value);
                                        },
                                        icon: Icon(
                                          Icons.production_quantity_limits,
                                          color: Colors.grey[500],
                                        ),
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
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          suffix: Text(tipo ?? ''),
                                        ),
                                        onChanged: (value) {
                                          store.updatePesoReposicao(key, value);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                "Qtd Mínima",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              Text(
                                                _getCopiedValue('Qtd Minima',
                                                    itemName, category),
                                                style: const TextStyle(
                                                    fontSize: 16),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                "Qtd na Loja",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              Text(
                                                _getCopiedValue('Quantidade',
                                                    itemName, category),
                                                style: const TextStyle(
                                                    fontSize: 16),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                "Tipo",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              Text(
                                                _getCopiedValue(
                                                    'Tipo', itemName, category),
                                                style: const TextStyle(
                                                    fontSize: 16),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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
