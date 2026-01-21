import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:orama_admin/others/insumos.dart';
import 'package:orama_admin/pages/loja/reposicao/reposicao_page.dart';
import 'package:orama_admin/routes/routes.dart';
import 'package:orama_admin/stores/stock_store.dart';
import 'package:orama_admin/utils/addItemDialog.dart';
import 'package:orama_admin/utils/extensions.dart';
import 'package:orama_admin/utils/offline_model.dart';
import 'package:orama_admin/utils/scroll_hide_fab.dart';
import 'package:orama_admin/utils/show_snackbar.dart';
import 'package:orama_admin/widgets/my_styles/my_input_field.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

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
  State<ReposicaoFormularioPage> createState() =>
      _ReposicaoFormularioPageState();
}

class _ReposicaoFormularioPageState extends State<ReposicaoFormularioPage> {
  Map<String, TextEditingController> _quantityControllers = {};
  Map<String, TextEditingController> _pesoControllers = {};
  List<String> categoriasVisiveis = [];
  Map<String, List<Map<String, dynamic>>> insumosFiltrados = {};
  bool isLoading = true;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _loadInsumosFromFirestore();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _quantityControllers.forEach((_, controller) => controller.dispose());
    _pesoControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  void _initializeControllers() {
    final store = Provider.of<StockStore>(context, listen: false);

    if (widget.reportData != null) {
      store.populateFieldsWithReport2(widget.reportData!);
    }

    for (final category in categoriasVisiveis) {
      final items = insumosFiltrados[category]!;
      for (var item in items) {
        final key = store.generateKey(category, item['nome']);
        _quantityControllers[key] =
            TextEditingController(text: store.quantityValuesRepo[key] ?? '');
        _pesoControllers[key] =
            TextEditingController(text: store.pesoValuesRepo[key] ?? '');
      }
    }
  }

  Future<void> _loadInsumosFromFirestore() async {
  final store = Provider.of<StockStore>(context, listen: false);
  final box = GetStorage();
  const cacheKey = 'insumos_repo_fabrica';

  try {
    final doc = await store.firestore
        .collection('configuracoes_loja')
        .doc('Repo Fabrica')
        .get();

    if (!doc.exists) {
      if (context.mounted) {
        ShowSnackBar(context, 'Fábrica não encontrada no Firestore', Colors.red);
      }
      setState(() => isLoading = false);
      return;
    }

    final data = doc.data()!;
    final categorias = List<String>.from(data['categorias'] ?? []);
    final rawInsumos = data['insumos'] as Map<String, dynamic>? ?? {};

    final Map<String, List<Map<String, dynamic>>> parsedInsumos = {};
    for (final entry in rawInsumos.entries) {
      final categoria = entry.key;
      final items = List<Map<String, dynamic>>.from(entry.value);
      parsedInsumos[categoria] = items;
    }

    // Verificação de diferença com o cache
    final cachedRaw = box.read(cacheKey);
    final cachedData = cachedRaw is Map<String, dynamic>
        ? cachedRaw.map((k, v) => MapEntry(k, List<Map<String, dynamic>>.from(v)))
        : {};

    final hasChanged = !const DeepCollectionEquality().equals(parsedInsumos, cachedData);

    if (hasChanged) {
      await box.write(cacheKey, parsedInsumos);
      print('Insumos atualizados no cache local.');
    } else {
      print('Nenhuma mudança nos insumos detectada.');
    }

    setState(() {
      categoriasVisiveis = categorias;
      insumosFiltrados = parsedInsumos;
      isLoading = false;
    });

    _initializeControllers();
  } catch (e) {
    if (context.mounted) {
      ShowSnackBar(context, 'Erro ao carregar insumos: $e', Colors.red);
    }

    // Tenta carregar do cache em caso de erro
    final fallback = box.read(cacheKey);
    if (fallback is Map<String, dynamic>) {
      final cachedParsed = fallback.map((k, v) => MapEntry(k, List<Map<String, dynamic>>.from(v)));
      setState(() {
        categoriasVisiveis = cachedParsed.keys.toList();
        insumosFiltrados = cachedParsed;
        isLoading = false;
      });
      _initializeControllers();
    } else {
      setState(() => isLoading = false);
    }
  }
}

  Future<void> saveDataToAdminReposicao(
      String nome, String data, String city, String loja,
      {String? reportId}) async {
        final dataFormat = DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now());
              final comandaId = '${dataFormat} - ${widget.loja}';
    final store = Provider.of<StockStore>(context, listen: false);
    final uuid =
        widget.reportId.isNotEmpty ? widget.reportId : comandaId;
    final DateTime now = DateTime.now().toUtc().add(const Duration(hours: -3));
    final String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(now);

    final categorias = categoriasVisiveis
        .map((categoria) {
          final items = insumosFiltrados[categoria]!
              .map((item) {
                final itemName = item['nome'];
                final tipo = item['tipo'] ?? '';
                final key = store.generateKey(categoria, itemName);
                final peso = _pesoControllers[key]?.text.trim() ?? '';
                final quantidade = _quantityControllers[key]?.text.trim() ?? '';

                if (quantidade.isNotEmpty) {
                  return {
                    'Item': itemName,
                    'Quantidade': quantidade,
                    'Peso': peso,
                    'Tipo': tipo,
                  };
                }
                return null;
              })
              .where((item) => item != null)
              .cast<Map<String, dynamic>>()
              .toList();

          if (items.isNotEmpty) {
            return {'Categoria': categoria, 'Itens': items};
          }
          return null;
        })
        .where((categoria) => categoria != null)
        .cast<Map<String, dynamic>>()
        .toList();

    if (categorias.isEmpty) {
      print("Nenhum item foi preenchido. O relatório não será salvo.");
      return;
    }

    final report = {
      'ID': uuid,
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
          .doc(uuid)
          .set(report);

      print("Relatório salvo com sucesso: $report");
    } catch (e) {
     final offlineDoc = OfflineData(
        data: report,
        collectionPath: 'users/Db4XIYcNMhUgYXvF6JDJJxbc3h82/reposicao',
        docId: widget.reportId,
        isUpdate: true,
      );
      await store.addToOfflineQueue(offlineDoc);
    
    }
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
        length: categoriasVisiveis.length,
        child: Scaffold(
          appBar: AppBar(
            iconTheme: const IconThemeData(color: Colors.white),
            bottom: TabBar(
              isScrollable: true,
              labelColor: Colors.white,
              indicatorColor: Colors.amber,
              tabs: categoriasVisiveis
                  .map((category) => Tab(text: category))
                  .toList(),
            ),
            title: const Text(
              'Reposição',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
            backgroundColor: const Color(0xff60C03D),
          ),
          body: Observer(
            builder: (_) => TabBarView(
              children: categoriasVisiveis.map((category) {
                final items = insumosFiltrados[category]!
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
                                      suffixIcon:
                                          Icon(Icons.add_shopping_cart_rounded),
                                      suffixIconColor: Colors.grey[500],
                                    ),
                                    onChanged: (value) {},
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
          floatingActionButton: ScrollHideFab(
              scrollController: _scrollController,
              child: FloatingActionButton(
                  backgroundColor: const Color(0xff60C03D),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    saveDataToAdminReposicao(
                        widget.nome, widget.data, widget.city, widget.loja);
                    store.clearFields();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => ReposicaoPage()),
                      (route) => false,
                    );
                  })),
        ),
      ),
    );
  }
}
