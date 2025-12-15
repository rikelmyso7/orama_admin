import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orama_admin/pages/loja/reposicao/copiar_reposicao_page.dart';
import 'package:orama_admin/routes/routes.dart';
import 'package:orama_admin/stores/stock_store.dart';

class CopyReportDialog extends StatefulWidget {
  final Map<String, dynamic> report;
  final StockStore store;

  const CopyReportDialog({
    Key? key,
    required this.report,
    required this.store,
  }) : super(key: key);

  @override
  _CopyReportDialogState createState() => _CopyReportDialogState();
}

class _CopyReportDialogState extends State<CopyReportDialog> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    // Inicializa o controlador de texto com o nome do responsável do relatório
    _nameController = TextEditingController(
      text: widget.report['Nome do usuario'] ?? '',
    );
  }

  @override
  void dispose() {
    // Libera o controlador de texto quando o widget for descartado
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _copyReport() async {
    final newName = _nameController.text.trim();
    if (newName.isNotEmpty) {
      final newReportId =
          await widget.store.copyReportToReposicao(widget.report, newName);

      // Faz uma cópia profunda do relatório original
      final modifiedReport = Map<String, dynamic>.from(widget.report);

      final categorias =
          Map<String, dynamic>.from(modifiedReport['Categoria'] ?? {});

      categorias.forEach((categoria, itens) {
        final itemMap = Map<String, dynamic>.from(itens);
        itemMap.forEach((itemName, itemData) {
          final item = Map<String, dynamic>.from(itemData);

          // Transfere a quantidade original para 'Qtd loja'
          item['Qtd loja'] = item['Quantidade'];

          // Limpa o campo de Quantidade para o usuário preencher
          item['Quantidade'] = '';

          // Atualiza o item
          itemMap[itemName] = item;
        });

        // Atualiza a categoria
        categorias[categoria] = itemMap;
      });

      // Atualiza o relatório com as categorias modificadas
      modifiedReport['Categoria'] = categorias;

      Navigator.pop(context); // Fecha o diálogo

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CopiarReposicaoPage(
            nome: newName,
            data: DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
            city: widget.report['Cidade'] ?? '',
            loja: widget.report['Loja'] ?? '',
            reportData: modifiedReport,
            reportId: newReportId,
          ),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Relatório copiado e pronto para edição."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Responsável pela reposição"),
      content: TextField(
        controller: _nameController,
        decoration: InputDecoration(
          hintText: "Responsável",
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context); // Fecha o diálogo
          },
          child: Text("Cancelar"),
        ),
        TextButton(
          onPressed: _copyReport,
          child: Text("Confirmar"),
        ),
      ],
    );
  }
}
