import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:orama_admin/stores/comanda_store.dart';
import 'package:orama_admin/utils/show_snackbar.dart';
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
          title: Text('${comanda.pdv} - ${comanda.name} (${comanda.periodo})'),
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
                          color: Colors.green,
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            comandaStore.copyComandaToFirebase(comanda);
                            ShowSnackBar(context,
                                'Relatório copiado com sucesso!', Colors.green);
                          }),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                comanda.pdv,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                  color: Colors.red,
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    _deleteComanda(context);
                  }),
            ],
          ),
          if (comanda.caixaInicial != null && comanda.caixaInicial!.isNotEmpty)
            Text(
              'Caixa Inicial: R\$ ${comanda.caixaInicial}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          if (comanda.caixaFinal != null && comanda.caixaFinal!.isNotEmpty)
            Text(
              'Caixa Final: R\$ ${comanda.caixaFinal}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          //PIX
          if (comanda.pixInicial != null && comanda.pixInicial!.isNotEmpty)
            Text(
              'Pix Inicial: R\$ ${comanda.pixInicial}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          if (comanda.pixFinal != null && comanda.pixFinal!.isNotEmpty)
            Text(
              'Pix Final: R\$ ${comanda.pixFinal}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
      ShowSnackBar(context, 'Relatório deletado com sucesso!', Colors.red);
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

        final isMassa = categoria.key == 'Massas';
        final isManteiga = saborEntry.key == 'Manteiga';
        final isBolacha = categoria.key == 'Bolachas';
        final unidade = isManteiga
            ? 'Pote'
            : (isMassa ? 'Tubos' : (isBolacha ? 'Pacotes' : 'Cubas'));
        final saborNome = isManteiga
            ? "Manteiga"
            : (isMassa ? "Massa de ${saborEntry.key}" : saborEntry.key);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isBolacha ? "Bolacha de ${saborEntry.key}" : saborNome,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              ...opcoesValidas.map((quantidadeEntry) {
                String textoExibicao;
                if (isManteiga) {
                  textoExibicao = "- ${quantidadeEntry.key} $unidade";
                } else if (isMassa) {
                  textoExibicao = "- ${quantidadeEntry.key} $unidade";
                } else if (isBolacha) {
                  final quantidade = int.tryParse(quantidadeEntry.key) ?? 1;
                  final unidadePlural = quantidade > 1 ? 'Pacotes' : 'Pacote';
                  textoExibicao = "- ${quantidadeEntry.key} $unidadePlural";
                } else {
                  final unidadePlural =
                      quantidadeEntry.value > 1 ? 'Cubas' : 'Cuba';
                  textoExibicao =
                      "- ${quantidadeEntry.value} $unidadePlural ${quantidadeEntry.key}";
                }
                return Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Text(textoExibicao),
                );
              }).toList(),
            ],
          ),
        );
      }).toList();
    }).toList();
  }
}
