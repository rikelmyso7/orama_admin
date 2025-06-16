import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:orama_admin/utils/gerar_excel.dart';

class Dataespecificoview extends StatelessWidget {
  final Map<String, dynamic> report;

  Dataespecificoview({required this.report});

  @override
  Widget build(BuildContext context) {
    // Verifica se o relatório é do tipo "Relatório Específico"
    final isRelatorioEspecifico =
        report['Tipo Relatorio'] == "Relatório Específico";

    // Filtra categorias e itens apenas para "Relatório Específico"
    final categoriasFiltradas =
        (report['Categorias'] as List).where((categoria) {
      if (!isRelatorioEspecifico) {
        // Para outros tipos de relatório, mantém todas as categorias
        return true;
      }

      // Filtra e normaliza itens dentro da categoria
      final itens = (categoria['Itens'] as List).map((item) {
        String quantidade = item['Quantidade']?.toString() ?? '';

        // Normaliza "valor/4/4" para "valor/4"
        if (quantidade.contains('/4/4')) {
          quantidade = quantidade.replaceAll('/4/4', '/4');
        }

        if (quantidade.contains('/4/4/4')) {
          quantidade = quantidade.replaceAll('/4/4/4', '/4');
        }

        // Atualiza o valor no item
        return {
          ...item,
          'Quantidade': quantidade,
        };
      }).where((item) {
        final quantidade = item['Quantidade']?.toString() ?? '';
        // Exibe apenas itens com quantidade não vazia
        return quantidade.isNotEmpty;
      }).toList();

      // Atualiza a lista de itens filtrados na categoria
      categoria['Itens'] = itens;

      // Garante que "BALDES" seja incluído mesmo que não tenha itens
      return categoria['Categoria'] == 'BALDES' || itens.isNotEmpty;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        elevation: 4,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Vizualizar",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        backgroundColor: const Color(0xff60C03D),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.download),
                  onPressed: () async {
                    try {
                      final caminho = await gerarExcel(report);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Arquivo Excel salvo em: $caminho"),
                          action: SnackBarAction(
                            label: 'Abrir',
                            onPressed: () {
                              abrirExcel(caminho);
                            },
                          ),
                        ),
                      );

                      await abrirExcel(caminho);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Erro ao gerar Excel: $e")),
                      );
                    }
                  },
                ),
                IconButton(
                  icon: Icon(Icons.share),
                  onPressed: () async {
                    try {
                      final caminho = await gerarExcel(report);
                      await compartilharExcel(caminho);
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
          itemCount: categoriasFiltradas.length *
              2, // Conta os Dividers entre os itens
          itemBuilder: (context, index) {
            if (index.isOdd) {
              // Insere um Divider entre os ExpansionTiles
              return Divider(
                thickness: 1,
                height: 1,
              );
            }

            final actualIndex = index ~/ 2;
            final categoria = categoriasFiltradas[actualIndex];
            final itens = categoria['Itens'];

            return ExpansionTile(
              title: Text(categoria['Categoria']),
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text("Item")),
                      DataColumn(label: Text("Quantidade")),
                      DataColumn(label: Text("Qtd Minima")),
                      DataColumn(label: Text("Tipo")),
                    ],
                    rows: itens.map<DataRow>((item) {
                      return DataRow(cells: [
                        DataCell(Text(item['Item'] ?? "")),
                        DataCell(Text(item['Quantidade'] ?? "")),
                        DataCell(Text(item['Qtd Minima'] ?? "")),
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
