import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:orama_admin/stores/comanda_store.dart';
import 'package:provider/provider.dart';

class AdminRelatoriosCard extends StatelessWidget {
  final Comanda comanda;
  final box = GetStorage();
  final Function(String comandaId) onDelete;
  final bool isExpanded;
  final ValueChanged<bool> onExpansionChanged;

  AdminRelatoriosCard({
    required this.comanda,
    required this.onDelete,
    Key? key,
    required this.isExpanded,
    required this.onExpansionChanged,
    required bool isSelected,
    required Null Function(dynamic value) onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final comandaStore = Provider.of<ComandaStore>(context);

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Card(
        elevation: 2,
        child: ExpansionTile(
          initiallyExpanded: isExpanded,
          onExpansionChanged: onExpansionChanged,
          title: Text('${comanda.pdv} - ${comanda.name}'),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Atendente - ${comanda.name}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  _buildHeader(context),
                  const SizedBox(height: 8.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('dd/MM/yyyy').format(comanda.data),
                        style: TextStyle(fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () =>
                            comandaStore.copyComandaToFirebase(comanda),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  ..._buildSaborList(comanda.sabores),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            comanda.pdv,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteComanda(context),
          ),
        ],
      ),
    );
  }

  void _deleteComanda(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirmação'),
          content: Text('Você tem certeza que deseja excluir esta comanda?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      onDelete(comanda.id);
    }
  }

  List<Widget> _buildSaborList(
      Map<String, Map<String, Map<String, int>>> sabores) {
    if (sabores.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text("Nenhum sabor selecionado."),
        ),
      ];
    }

    return sabores.entries.expand((categoria) {
      return categoria.value.entries.map((saborEntry) {
        final opcoesValidas = saborEntry.value.entries
            .where((quantidadeEntry) => quantidadeEntry.value > 0)
            .toList();

        if (opcoesValidas.isEmpty) {
          return Container();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                saborEntry.key,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...opcoesValidas.map((quantidadeEntry) {
                return Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Text(
                      "- ${quantidadeEntry.value} Cuba ${quantidadeEntry.key}"),
                );
              }).toList(),
            ],
          ),
        );
      }).toList();
    }).toList();
  }
}
