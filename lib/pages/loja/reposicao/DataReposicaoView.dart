import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:orama_admin/utils/gerar_excel.dart';
import 'package:orama_admin/utils/gerar_romaneio.dart';

class DataReposicaoView extends StatelessWidget {
  final Map<String, dynamic> report;

  DataReposicaoView({required this.report});

  @override
  Widget build(BuildContext context) {
    final isRelatorioEspecifico =
        report['Tipo Relatorio'] == "Relatório Específico";

    final categoriasFiltradas =
        (report['Categorias'] as List).where((categoria) {
      if (!isRelatorioEspecifico) return true;

      final itens = (categoria['Itens'] as List).map((item) {
        String quantidade = item['Quantidade']?.toString() ?? '';
        if (quantidade.contains('/4/4')) {
          quantidade = quantidade.replaceAll('/4/4', '/4');
        }
        if (quantidade.contains('/4/4/4')) {
          quantidade = quantidade.replaceAll('/4/4/4', '/4');
        }

        return {
          ...item,
          'Quantidade': quantidade,
        };
      }).where((item) {
        final quantidade = item['Quantidade']?.toString() ?? '';
        return quantidade.isNotEmpty;
      }).toList();

      categoria['Itens'] = itens;
      return categoria['Categoria'] == 'BALDES' || itens.isNotEmpty;
    }).toList();

    // ✅ Ordena as categorias em ordem alfabética
    categoriasFiltradas.sort((a, b) => (a['Categoria'] ?? '')
        .toString()
        .compareTo((b['Categoria'] ?? '').toString()));

    return Scaffold(
      appBar: AppBar(
        elevation: 4,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Vizualizar Reposição",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        backgroundColor: const Color(0xff60C03D),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.share),
                  onPressed: () async {
                    try {
                      final caminho = await gerarRomaneioPDF(context, report);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Erro ao compartilhar: $e")),
                      );
                    }
                  },
                ),
              ],
            ),
          )
        ],
      ),
      body: Observer(builder: (_) {
        return ListView.builder(
          itemCount: categoriasFiltradas.length * 2,
          itemBuilder: (context, index) {
            if (index.isOdd) {
              return Divider(thickness: 1, height: 1);
            }

            final actualIndex = index ~/ 2;
            final categoria = categoriasFiltradas[actualIndex];
            final itens = List<Map<String, dynamic>>.from(categoria['Itens']);

            // ✅ Ordena os itens por nome
            itens.sort((a, b) => (a['Item'] ?? '')
                .toString()
                .compareTo((b['Item'] ?? '').toString()));

            return ExpansionTile(
              title: Text(categoria['Categoria']),
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text("Item")),
                      DataColumn(label: Text("Quantidade")),
                      DataColumn(label: Text("Peso (Gr)")),
                      DataColumn(label: Text("Qtd na Loja")),
                      DataColumn(label: Text("Estoque Fábrica")),
                      DataColumn(label: Text("Tipo")),
                    ],
                    rows: itens.map<DataRow>((item) {
                      return DataRow(cells: [
                        DataCell(Text(item['Item'] ?? "")),
                        DataCell(Text(item['Quantidade'] ?? "")),
                        DataCell(Text("${item['Peso']}g" ?? "")),
                        DataCell(Text(item['Qtd Anterior'] ?? "")),
                        DataCell(Text(item['Estoque Fábrica'] ?? "")),
                        DataCell(Text(item['Tipo'] ?? "")),
                      ]);
                    }).toList(),
                  ),
                ),
              ],
            );
          },
        );
      }),
    );
  }
}
