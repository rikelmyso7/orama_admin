import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:orama_admin/main.dart';
import 'package:orama_admin/others/constants.dart';
import 'package:orama_admin/pages/loja/gerenciamento/removerItemEstoquePage.dart';
import 'package:orama_admin/utils/show_snackbar.dart';

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
  bool algumaLojaSelecionada() {
    return locaisSelecionados.values.any((selecionado) => selecionado);
  }

  Map<String, bool> locaisSelecionados = {
    'Orama Itupeva': false,
    'Orama Paineiras': false,
    'Orama Retiro': false,
    'Platz': false,
    'Repo Fabrica': false,
  };

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
        print('Categoria: $categoriaSelecionada');
        print('Item: $novoItem');
        print('Destino: $lojas');

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
    categorias = categoriasPadrao;
    tipoController.text = '';
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
              DropdownButtonFormField<String>(
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
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Tipo'),
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
                validator: (value) => value!.isEmpty ? 'Informe o nome' : null,
              ),
              SizedBox(height: 24),
              Text('Adicionar em:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
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
                onPressed: () => Navigator.push(
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
