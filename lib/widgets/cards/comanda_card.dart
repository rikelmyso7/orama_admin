import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:orama_admin/pages/sabores_edit_page.dart';
import 'package:orama_admin/stores/comanda_store.dart';
import 'package:orama_admin/widgets/date_picker_widget.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class ComandaCard extends StatefulWidget {
  final Comanda comanda;
  final bool isSelected;
  final ValueChanged<bool?> onChanged;
  final bool isExpanded;
  final ValueChanged<bool> onExpansionChanged;

  ComandaCard({
    required this.comanda,
    required this.isSelected,
    required this.isExpanded,
    required this.onChanged,
    required this.onExpansionChanged,
    Key? key,
  }) : super(key: key ?? ValueKey(comanda.id));

  @override
  _ComandaCardState createState() => _ComandaCardState();
}

class _ComandaCardState extends State<ComandaCard> {
  late TextEditingController _pdvController;
  late Map<String, Map<String, Map<String, int>>> _saboresSelecionados;
  bool _isEditing = false;
  late DateTime _selectedDate;
  final box = GetStorage();
  Set<String> _selectedItems = {};

  final List<String> _categorias = ['Ao Leite', 'Veganos', 'Zero Açúcar'];
  final List<String> _opcoes = ['0', '1/4', '2/4', '3/4', '4/4'];

  @override
  void initState() {
    super.initState();
    _pdvController = TextEditingController(text: widget.comanda.pdv);
    _saboresSelecionados = Map.from(widget.comanda.sabores);
    _selectedDate = widget.comanda.data;

    // Load saved selected items
    final savedItems = box.read<List>('selectedItems') ?? [];
    _selectedItems = savedItems.map((item) => item.toString()).toSet();
  }

  @override
  void dispose() {
    _pdvController.dispose();
    super.dispose();
  }

  void _updateSabor(
      String categoria, String sabor, String opcao, int quantidade) {
    setState(() {
      if (!_saboresSelecionados.containsKey(categoria)) {
        _saboresSelecionados[categoria] = {};
      }
      if (!_saboresSelecionados[categoria]!.containsKey(sabor)) {
        _saboresSelecionados[categoria]![sabor] = {};
      }
      _saboresSelecionados[categoria]![sabor]![opcao] = quantidade;
    });
  }

  void _saveChanges() {
    final comandaStore = Provider.of<ComandaStore>(context, listen: false);
    setState(() {
      widget.comanda.pdv = _pdvController.text;
      widget.comanda.sabores = Map.from(_saboresSelecionados);
      widget.comanda.data = _selectedDate;
      comandaStore.addOrUpdateCard(widget.comanda);
      _isEditing = false;
    });

    // Save selected items
    box.write('selectedItems', _selectedItems.toList());
  }

  void _copyComanda() {
    final comandaStore = Provider.of<ComandaStore>(context, listen: false);

    final newSabores = widget.comanda.sabores.map((categoria, sabores) {
      return MapEntry<String, Map<String, Map<String, int>>>(
        categoria,
        sabores.map((sabor, opcoes) {
          return MapEntry<String, Map<String, int>>(
            sabor,
            Map<String, int>.from(opcoes),
          );
        }),
      );
    });

    final newComanda = Comanda(
      id: Uuid().v4(),
      pdv: widget.comanda.pdv,
      sabores: Map<String, Map<String, Map<String, int>>>.from(
          newSabores),
      data: DateTime.now(), name: '', userId: '',
    );

    comandaStore.addOrUpdateCard(newComanda);
  }

  void _deleteComanda() {
    final comandaStore = Provider.of<ComandaStore>(context, listen: false);
    final index = comandaStore.comandas.indexOf(widget.comanda);
    if (index != -1) {
      comandaStore.removeComanda(index);
    }
  }

  void _navigateToSaboresEditPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SaboresEditPage(comanda: widget.comanda),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Card(
        elevation: 2,
        child: ExpansionTile(
          initiallyExpanded: widget.isExpanded,
          onExpansionChanged: widget.onExpansionChanged,
          title: Text(widget.comanda.pdv),
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  _buildDateRow(),
                  const SizedBox(height: 8.0),
                  ..._buildSaborList(),
                  if (_isEditing)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          ElevatedButton(
                            onPressed: _navigateToSaboresEditPage,
                            child: const Text(
                              'Adicionar Sabor',
                              style: TextStyle(color: Color(0xff60C03D)),
                            ),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          ElevatedButton(
                            onPressed: () {
                              _showAddSaborDialog();
                            },
                            child: const Text(
                              'Escrever Sabor',
                              style: TextStyle(
                                  color: Color.fromARGB(255, 61, 151, 192)),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _isEditing
            ? Expanded(
                child: TextField(
                  controller: _pdvController,
                  decoration: const InputDecoration(labelText: "PDV"),
                ),
              )
            : Text(
                widget.comanda.pdv,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
        Row(
          children: [
            if (_isEditing)
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveChanges,
              )
            else
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                  });
                },
              ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteComanda,
            ),
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: _copyComanda,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateRow() {
    return Row(
      children: [
        _isEditing
            ? DatePickerWidget(
                initialDate: _selectedDate,
                onDateSelected: (date) {
                  setState(() {
                    _selectedDate = date;
                  });
                },
              )
            : Text(DateFormat('dd/MM/yyyy').format(widget.comanda.data)),
      ],
    );
  }

  List<Widget> _buildSaborList() {
    return _saboresSelecionados.entries.expand((categoria) {
      return categoria.value.entries.map((saborEntry) {
        final opcoesValidas = saborEntry.value.entries
            .where((quantidadeEntry) => quantidadeEntry.value > 0)
            .toList();

        if (opcoesValidas.isEmpty) {
          return Container();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(saborEntry.key,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                if (_isEditing)
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        _saboresSelecionados[categoria.key]!
                            .remove(saborEntry.key);
                        if (_saboresSelecionados[categoria.key]!.isEmpty) {
                          _saboresSelecionados.remove(categoria.key);
                        }
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 2),
            ...opcoesValidas.map((quantidadeEntry) {
              final itemKey =
                  '${categoria.key}-${saborEntry.key}-${quantidadeEntry.key}';
              return Row(
                children: [
                  Text(
                    "- ${quantidadeEntry.value} Cuba ${quantidadeEntry.key}",
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "${_selectedItems.contains(itemKey) ? 'Reposição' : ''}",
                    style: TextStyle(
                        color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                  if (_isEditing)
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  _updateSabor(
                                    categoria.key,
                                    saborEntry.key,
                                    quantidadeEntry.key,
                                    quantidadeEntry.value + 1,
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () {
                                  _updateSabor(
                                    categoria.key,
                                    saborEntry.key,
                                    quantidadeEntry.key,
                                    quantidadeEntry.value - 1,
                                  );
                                },
                              ),
                            ],
                          ),
                          Checkbox(
                            value: _selectedItems.contains(itemKey),
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedItems.add(itemKey);
                                } else {
                                  _selectedItems.remove(itemKey);
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              );
            }).toList(),
          ],
        );
      }).toList();
    }).toList();
  }

  void _showAddSaborDialog() {
    String? categoriaSelecionada;
    String? saborSelecionado;
    String? opcaoSelecionada;
    int quantidadeSelecionada = 0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('Adicionar Sabor'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  value: categoriaSelecionada,
                  hint: Text(categoriaSelecionada ?? 'Selecione a Categoria'),
                  isExpanded: true,
                  items: _categorias.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      categoriaSelecionada = newValue;
                    });
                  },
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Sabor'),
                  onChanged: (value) {
                    saborSelecionado = value;
                  },
                ),
                DropdownButton<String>(
                  value: opcaoSelecionada,
                  hint: Text(opcaoSelecionada ?? 'Selecione a Opção'),
                  isExpanded: true,
                  items: _opcoes.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      opcaoSelecionada = newValue;
                    });
                  },
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Quantidade'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    quantidadeSelecionada = int.tryParse(value) ?? 0;
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  if (categoriaSelecionada != null &&
                      saborSelecionado != null &&
                      opcaoSelecionada != null) {
                    _updateSabor(categoriaSelecionada!, saborSelecionado!,
                        opcaoSelecionada!, quantidadeSelecionada);
                  }
                  Navigator.of(context).pop();
                },
                child: const Text('Adicionar'),
              ),
            ],
          );
        });
      },
    );
  }
}
