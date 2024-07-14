import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:orama_admin/others/descartaveis.dart';
import 'package:orama_admin/stores/comanda_store.dart';
import 'package:orama_admin/widgets/cards/comanda_utils.dart';

class AdminDescartavelCard extends StatelessWidget {
  final ComandaDescartaveis comanda;
  final box = GetStorage();
  final Function(String comandaId) onDelete;
  final bool isExpanded;
  final ValueChanged<bool> onExpansionChanged;

  AdminDescartavelCard({
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
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Card(
        elevation: 2,
        child: ExpansionTile(
          initiallyExpanded: isExpanded,
          onExpansionChanged: onExpansionChanged,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(comanda.pdv),
              Text(
                comanda.name,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
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
                  _buildDateRow(),
                  const SizedBox(height: 8.0),
                  _buildDescartaveisList(),
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

  Widget _buildDateRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          DateFormat('dd/MM/yyyy').format(comanda.data),
          style: TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildDescartaveisList() {
    if (comanda.quantidades.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Text("Nenhum descartável selecionado."),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(comanda.quantidades.length, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                descartaveis[index].name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('- Quantidade: ${comanda.quantidades[index]}'),
                    Text('- Observação: ${comanda.observacoes[index]}'),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
