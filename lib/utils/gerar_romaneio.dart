import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orama_admin/utils/show_snackbar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

// Função para converter frações para double

// Função para formatar número conforme frações específicas

Future<void> gerarRomaneioPDF(
    BuildContext context, Map<String, dynamic> report) async {
  try {
    final pdf = pw.Document();
    final categorias = report['Categorias'] as List;
    final dataSolicitacao = DateTime.now();
    final dataFormatada =
        DateFormat('dd/MM/yyyy HH:mm').format(dataSolicitacao);
    final solicitante = report['Nome do usuario'] ?? "";
    final loja = report['Loja'] ?? "";
    final cidade = report['Cidade'] ?? "";

    pw.Widget buildConteudoRomaneio({bool incluirAssinatura = false}) {
      List<pw.Widget> conteudo = [
        pw.Text(
          'Romaneio de Reposição $loja - $cidade',
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 5),
        pw.Text('Data da solicitação: $dataFormatada',
            style: pw.TextStyle(fontSize: 14)),
        pw.Text('Operador: $solicitante', style: pw.TextStyle(fontSize: 14)),
        pw.SizedBox(height: 10),
      ];

      for (var categoria in categorias) {
        final itens = categoria['Itens'] as List;

        if (itens.isNotEmpty) {
          conteudo.add(
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(height: 10),
                pw.Text(
                  categoria['Categoria'],
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 5),
              ],
            ),
          );

          // Checa se a categoria é BALDES para decidir se inclui a coluna "Peso"
          final isBaldes =
              categoria['Categoria'].toString().toUpperCase() == "BALDES";

          conteudo.add(
            pw.Table.fromTextArray(
              headers: isBaldes
                  ? ["Item", "Reposição", "Peso (g)"]
                  : ["Item", "Reposição"],
              data: itens.map((item) {
                final quantidade = item['Quantidade'].toString();
                final tipo = item['Tipo'];
                final peso = item['Peso']?.toString() ?? '';

                return isBaldes
                    ? [item['Item'] ?? '', "$quantidade $tipo", "$peso g"]
                    : [item['Item'] ?? '', "$quantidade $tipo"];
              }).toList(),
            ),
          );

          conteudo.add(pw.SizedBox(height: 30));
        }
      }

      String formattedDate =
          DateFormat("d 'de' MMMM 'de' y", 'pt_BR').format(DateTime.now());
      conteudo.add(
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.center, children: [
          pw.Text("$cidade, $formattedDate", style: pw.TextStyle(fontSize: 12)),
        ]),
      );

      if (incluirAssinatura) {
        conteudo.add(
          pw.SizedBox(height: 30),
        );
        conteudo.add(
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              pw.Column(
                children: [
                  pw.Container(width: 200, height: 1, color: PdfColors.black),
                  pw.SizedBox(height: 5),
                  pw.Text("Assinatura do Solicitante",
                      style: pw.TextStyle(fontSize: 12)),
                ],
              ),
              pw.Column(
                children: [
                  pw.Container(width: 200, height: 1, color: PdfColors.black),
                  pw.SizedBox(height: 5),
                  pw.Text("Assinatura do Entregador",
                      style: pw.TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
        );
      }

      return pw.Column(children: conteudo);
    }

    // Primeira página - Via com assinatura
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a3,
        build: (pw.Context context) {
          return [buildConteudoRomaneio(incluirAssinatura: true)];
        },
      ),
    );

    // Segunda página - Via sem assinatura
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a3,
        build: (pw.Context context) {
          return [
            pw.Text(
              "2ª Via - Loja",
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            buildConteudoRomaneio(incluirAssinatura: false),
          ];
        },
      ),
    );

    final dataCompleta = report['Data'] ?? "";
    final partesData = dataCompleta.split('/');
    final diaMes = "${partesData[0]}_${partesData[1]}";

    final output = await getTemporaryDirectory();
    final filePath = "${output.path}/romaneio_${loja}_${diaMes}.pdf";
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Romaneio salvo em: $filePath"),
        action: SnackBarAction(
          label: 'Abrir',
          onPressed: () {
            OpenFilex.open(filePath);
          },
        ),
      ),
    );

    // Compartilhar no WhatsApp
    await Share.shareXFiles(
      [XFile(filePath)],
      text: 'Romaneio de solicitação de produtos',
    );
  } catch (e) {
    ShowSnackBar(context, "Erro ao gerar o romaneio: $e", Colors.red);
  }
}
