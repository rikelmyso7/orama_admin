import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:orama_admin/main.dart';
import 'package:orama_admin/others/constants.dart';
import 'package:orama_admin/pages/loja/gerenciamento/removerItemEstoquePage.dart';
import 'package:orama_admin/utils/show_snackbar.dart';
import 'package:orama_admin/stores/stock_store.dart';
import 'package:provider/provider.dart';

class AddItemEstoquePage extends StatefulWidget {
  const AddItemEstoquePage({super.key});

  @override
  State<AddItemEstoquePage> createState() => _AddItemEstoquePageState();
}

class _AddItemEstoquePageState extends State<AddItemEstoquePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController minimoController = TextEditingController();
  final TextEditingController tipoController = TextEditingController();
  final TextEditingController categoriaController = TextEditingController();
  List<String> categorias = [];
  String? categoriaSelecionada;
  bool isLoading = false;
  bool isLoadingLojas = true;

  bool algumaLojaSelecionada() {
    return locaisSelecionados.values.any((selecionado) => selecionado);
  }

  Map<String, bool> locaisSelecionados = {};

  Future<void> varrerItensComEspacoFinal({bool corrigir = false}) async {
    final fs = secondaryFirestore; // usa a instância já usada no app

    final lojas = await fs.collection('configuracoes_loja').get();
    for (final lojaDoc in lojas.docs) {
      final insumosRaw =
          Map<String, dynamic>.from(lojaDoc.data()['insumos'] ?? {});
      final insumosNovo = <String, List<Map<String, dynamic>>>{};
      var precisaAtualizar = false;

      insumosRaw.forEach((categoria, lista) {
        final novaLista = <Map<String, dynamic>>[];
        for (final item in List<Map<String, dynamic>>.from(lista)) {
          final nome = (item['nome'] ?? '') as String;
          if (nome.endsWith(' ')) {
            precisaAtualizar = true;
            novaLista.add({...item, 'nome': nome.trimRight()});
            debugPrint('Corrigir ${lojaDoc.id}/$categoria → "$nome"');
          } else {
            novaLista.add(item);
          }
        }
        insumosNovo[categoria] = novaLista;
      });

      if (precisaAtualizar && corrigir) {
        await lojaDoc.reference.update({'insumos': insumosNovo});
        debugPrint('Atualizado: ${lojaDoc.id}');
      }
    }
  }

  Future<void> adicionarItemEmInsumosDeLojas(List<String> lojas) async {
    final firestore = secondaryFirestore;
    print('Usando Firestore: ${firestore.app.name}');

    final Map<String, dynamic> novoItem = {
      'nome': nomeController.text.trim(),
      'minimo': minimoController.text.trim(),
      'tipo': tipoController.text.trim(),
    };

    try {
      for (String loja in lojas) {

        final path = categoriaSelecionada;

        await firestore.collection('configuracoes_loja').doc(loja).set({
          'insumos': {
            categoriaSelecionada!: FieldValue.arrayUnion([novoItem])
          }
        }, SetOptions(merge: true));
      }

      ShowSnackBar(
          context, "Item adicionado com sucesso!", const Color(0xff60C03D));
      Navigator.pop(context);
    } catch (e) {
      print("Erro ao adicionar item: $e");
      ShowSnackBar(context, "Erro ao adicionar: $e", Colors.red);
    }
  }

  void salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final destinos = locaisSelecionados.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (destinos.isEmpty) {
      ShowSnackBar(context, "Não foi possível adicionar", Colors.red);
      return;
    }

    setState(() => isLoading = true);
    await adicionarItemEmInsumosDeLojas(destinos);
    setState(() => isLoading = false);
  }

  @override
  void initState() {
    super.initState();
    tipoController.text = '';
    _loadLojas();
    _loadCategorias();
  }

  Future<void> _loadLojas() async {
    try {
      final firestore = secondaryFirestore;
      final snapshot = await firestore.collection('configuracoes_loja').get();

      setState(() {
        locaisSelecionados = {
          for (var doc in snapshot.docs) doc.id: false
        };
        isLoadingLojas = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar lojas: $e');
      setState(() {
        isLoadingLojas = false;
      });
    }
  }

  Future<void> _loadCategorias() async {
    // Carrega categorias da Repo Fabrica
    final stockStore = Provider.of<StockStore>(context, listen: false);
    await stockStore.fetchCategorias();

    setState(() {
      categorias = stockStore.categorias.toList();
    });
  }

  Future<void> _showAddCategoriaDialog() async {
    final lojasSelecionadas = locaisSelecionados.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    // Não precisa mais verificar lojas selecionadas, pois as categorias são globais

    final TextEditingController novaCategoriaController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Adicionar Nova Categoria'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Categoria será adicionada ao sistema global'),
              SizedBox(height: 16),
              TextField(
                controller: novaCategoriaController,
                decoration: InputDecoration(
                  labelText: 'Nome da Categoria',
                  hintText: 'Ex: NOVOS PRODUTOS',
                ),
                textCapitalization: TextCapitalization.characters,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Adicionar'),
              onPressed: () async {
                final novaCategoria = novaCategoriaController.text.trim().toUpperCase();
                if (novaCategoria.isNotEmpty) {
                  try {
                    final stockStore = Provider.of<StockStore>(context, listen: false);

                    // Adiciona a categoria na Repo Fabrica
                    await stockStore.addCategoria(novaCategoria);

                    await _loadCategorias();
                    setState(() {
                      categoriaSelecionada = novaCategoria;
                    });
                    Navigator.of(context).pop();
                    ShowSnackBar(context, 'Categoria "$novaCategoria" adicionada com sucesso!',
                        const Color(0xff60C03D));
                  } catch (e) {
                    ShowSnackBar(context, 'Erro ao adicionar categoria: $e', Colors.red);
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Adicionar Item ao Estoque',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        backgroundColor: Color(0xff60C03D),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: 'Categoria'),
                      value: categoriaSelecionada,
                      items: categorias
                          .map((categoria) => DropdownMenuItem(
                                value: categoria,
                                child: Text(categoria),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          categoriaSelecionada = value;

                          switch (value) {
                            case "BALDES":
                              minimoController.text = "2/4";
                              tipoController.text = "Balde";
                              break;
                            case "POTES":
                              minimoController.text = "";
                              tipoController.text = "Pote";
                              break;
                            default:
                              minimoController.clear();
                              tipoController.clear();
                          }
                        });
                      },
                      validator: (value) => value == null || value.isEmpty
                          ? 'Selecione uma categoria'
                          : null,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: _showAddCategoriaDialog,
                    tooltip: 'Adicionar nova categoria',
                  ),
                ],
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Tipo'),
                value:
                    tipoController.text.isNotEmpty ? tipoController.text : null,
                items: tiposPadrao
                    .map((tipo) => DropdownMenuItem(
                          value: tipo,
                          child: Text(tipo),
                        ))
                    .toList(),
                onChanged: categoriaSelecionada == "BALDES"
                    ? null
                    : (value) {
                        setState(() {
                          tipoController.text = value ?? '';
                        });
                      },
                validator: (value) =>
                    value == null || value.isEmpty ? 'Selecione um tipo' : null,
              ),
              TextFormField(
                controller: minimoController,
                decoration: InputDecoration(labelText: 'Minimo'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? 'Informe a quantidade' : null,
              ),
              TextFormField(
                controller: nomeController,
                decoration: InputDecoration(labelText: 'Nome do insumo'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty)
                    return 'Informe o nome';
                  if (value.endsWith(' ')) return 'Não deixe espaço no final';
                  return null;
                },
              ),
              SizedBox(height: 24),
              Text('Adicionar em:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              if (isLoadingLojas)
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (locaisSelecionados.isEmpty)
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Nenhuma loja encontrada'),
                )
              else
                ...locaisSelecionados.keys.map((lojaId) {
                  return CheckboxListTile(
                    title: Text(lojaId),
                    value: locaisSelecionados[lojaId],
                    onChanged: (bool? value) {
                      setState(() {
                        locaisSelecionados[lojaId] = value ?? false;
                      });
                    },
                  );
                }).toList(),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed:
                    isLoading || !algumaLojaSelecionada() ? null : salvar,
                icon: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 18,
                ),
                label: Text(
                  'Adicionar',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff60C03D),
                  padding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 22),
              ElevatedButton.icon(
                label: const Text(
                  'Remover Item do Estoque',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () async => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RemoveItemEstoquePage()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
