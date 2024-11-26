import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:orama_admin/pages/relatorios_page.dart';
import 'package:orama_admin/routes/routes.dart';
import 'package:orama_admin/stores/stock_store.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class EditarRelatorioPage extends StatefulWidget {
  final String nome;
  final String data;
  final String city;
  final Map<String, dynamic> reportData;
  final String? reportId;

  EditarRelatorioPage({
    required this.nome,
    required this.data,
    required this.reportData,
    required this.city,
    this.reportId,
  });

  @override
  _EditarRelatorioPageState createState() => _EditarRelatorioPageState();
}

class _EditarRelatorioPageState extends State<EditarRelatorioPage> {
  String? pdfPath;

  @override
  void initState() {
    super.initState();
    _generatePdf(); // Gera o PDF ao inicializar a página
  }

  Future<void> _generatePdf() async {
    final pdfDocument = PdfDocument();
    var page = pdfDocument.pages.add();
    double currentPosition = 20; // Posição inicial no topo da página

    // Adiciona o título e as informações do relatório no PDF
    page.graphics.drawString(
      'Relatório de Estoque - ${widget.reportData['Loja']}',
      PdfStandardFont(PdfFontFamily.helvetica, 18, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(0, currentPosition, 500, 30),
    );
    currentPosition += 40; // Avança a posição após o título

    page.graphics.drawString(
      'Data: ${widget.data}\n',
      PdfStandardFont(PdfFontFamily.helvetica, 14),
      bounds: Rect.fromLTWH(0, currentPosition, 500, 20),
    );
    currentPosition += 30; // Avança a posição após as informações do relatório

    page.graphics.drawString(
      'Responsável: ${widget.nome}\n',
      PdfStandardFont(PdfFontFamily.helvetica, 14),
      bounds: Rect.fromLTWH(0, currentPosition, 500, 20),
    );
    currentPosition += 30; // Avança a posição após as informações do relatório

    // Adiciona categorias e itens do relatório com espaçamento entre cada um
    for (var category in widget.reportData['Categorias'] ?? []) {
      final categoryName = category['Categoria'];
      final items = category['Itens'] ?? [];

      page.graphics.drawString(
        categoryName,
        PdfStandardFont(PdfFontFamily.helvetica, 16, style: PdfFontStyle.bold),
        bounds: Rect.fromLTWH(0, currentPosition, 500, 20),
      );
      currentPosition += 25;

      for (var item in items) {
        final itemName = item['Item'];
        final peso = item['Peso'];
        final quantidade = item['Quantidade'];

        page.graphics.drawString(
          '$itemName',
          PdfStandardFont(PdfFontFamily.helvetica, 12),
          bounds: Rect.fromLTWH(0, currentPosition, 500, 15),
        );
        currentPosition += 20; // Avança a posição após cada item

        page.graphics.drawString(
          'Peso: $peso kg - Quantidade: $quantidade',
          PdfStandardFont(PdfFontFamily.helvetica, 12),
          bounds: Rect.fromLTWH(20, currentPosition, 500, 15),
        );
        currentPosition += 20; // Avança a posição após cada item

        // Verifica se está no fim da página e adiciona uma nova página se necessário
        if (currentPosition > page.getClientSize().height - 40) {
          page = pdfDocument.pages.add();
          currentPosition = 20; // Reinicia a posição no topo da nova página
        }
      }
      currentPosition += 10; // Espaço adicional entre categorias
    }

    // Salva o PDF no diretório temporário do dispositivo
    List<int> bytes = await pdfDocument.save();
    pdfDocument.dispose();

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/relatorio.pdf");
    await file.writeAsBytes(bytes, flush: true);

    setState(() {
      pdfPath = file.path; // Define o caminho do PDF para exibição
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<StockStore>(context, listen: false);

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) {
          return;
        }
        if (context.mounted) {
          Navigator.popAndPushNamed(context, RouteName.relatorios);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Visualizar Relatório",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
          backgroundColor: const Color(0xff60C03D),
          iconTheme: IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: Icon(Icons.delete, color: Colors.white),
              onPressed: () async {
                final shouldDelete = await _confirmDelete(context);
                if (shouldDelete && widget.reportId != null) {
                  await store.deleteReport(
                      widget.reportData['userId'], widget.reportId!);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => RelatoriosPage()),
                  );
                }
              },
            ),
            IconButton(
              icon: Icon(Icons.download, color: Colors.white),
              onPressed: pdfPath != null ? _downloadPdf : null,
            ),
          ],
        ),
        body: pdfPath != null
            ? SfPdfViewer.file(File(pdfPath!))
            : Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Future<void> _downloadPdf() async {
    if (pdfPath != null) {
      final directory = await getTemporaryDirectory();
      final storeName = widget.reportData['Loja'] ?? 'Loja';
      final date = DateFormat('dd-MM').format(DateTime.now());
      final newFileName = 'Relatório_${storeName}_$date.pdf';

      final newPath = '${directory.path}/$newFileName';
      final file = File(pdfPath!);
      final newFile = await file.copy(newPath); // Copia e renomeia o arquivo

      await OpenFilex.open(newFile.path); // Abre o arquivo renomeado
    }
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Excluir relatório'),
            content:
                Text('Você tem certeza de que deseja excluir este relatório?'),
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
          ),
        ) ??
        false;
  }
}
