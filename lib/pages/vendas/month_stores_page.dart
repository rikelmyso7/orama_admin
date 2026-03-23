import 'package:flutter/material.dart';
import 'package:orama_admin/vendas/models/venda_diaria_model.dart';
import 'package:orama_admin/vendas/vendas_store.dart';
import 'store_months_page.dart';

class MonthStoresPage extends StatelessWidget {
  final String monthName;
  final int year;
  final Color monthColor;
  final List<VendaDiaria> vendasDoMes;
  final VendasStore store;

  static const _storeColors = [
    Color(0xFF60C03D),
    Color(0xFF06B6D4),
    Color(0xFFF97316),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFFEA9E13),
    Color(0xFF0EA5A0),
    Color(0xFFE53935),
    Color(0xFF1E88E5),
    Color(0xFF43A047),
    Color(0xFFD81B60),
    Color(0xFF6D4C41),
  ];

  const MonthStoresPage({
    super.key,
    required this.monthName,
    required this.year,
    required this.monthColor,
    required this.vendasDoMes,
    required this.store,
  });

  List<Map<String, dynamic>> _calcularTotaisPorLoja() {
    final Map<String, Map<String, dynamic>> totais = {};

    for (final dia in vendasDoMes) {
      for (final sale in dia.sales) {
        if (totais.containsKey(sale.storeId)) {
          totais[sale.storeId]!['total'] =
              (totais[sale.storeId]!['total'] as double) + sale.valor;
        } else {
          totais[sale.storeId] = {
            'storeId': sale.storeId,
            'storeName': sale.storeName,
            'total': sale.valor,
          };
        }
      }
    }

    return totais.values.toList()
      ..sort((a, b) => (b['total'] as double).compareTo(a['total'] as double));
  }

  @override
  Widget build(BuildContext context) {
    final lojas = _calcularTotaisPorLoja();
    final grandTotal =
        lojas.fold(0.0, (sum, l) => sum + (l['total'] as double));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '$monthName $year',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: monthColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: lojas.isEmpty
          ? const Center(child: Text('Nenhum dado disponível'))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Vendas por Loja',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              '$monthName $year',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Total do mês',
                              style:
                                  TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            Text(
                              store.formatarValor(grandTotal),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: monthColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(
                      height: 24, thickness: 1, color: Color(0xFFEEEEEE)),
                  _buildStoreList(context, lojas),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildStoreList(
      BuildContext context, List<Map<String, dynamic>> lojas) {
    return Column(
      children: List.generate(lojas.length, (i) {
        final loja = lojas[i];
        final color = _storeColors[i % _storeColors.length];
        final total = loja['total'] as double;

        return Column(
          children: [
            ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StoreMonthsPage(
                      storeId: loja['storeId'] as String,
                      storeName: loja['storeName'] as String,
                      storeColor: color,
                      store: store,
                    ),
                  ),
                );
              },
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.storefront_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              title: Text(
                loja['storeName'] as String,
                style: const TextStyle(fontSize: 15),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    store.formatarValor(total),
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                ],
              ),
            ),
            if (i < lojas.length - 1)
              const Divider(height: 1, indent: 72, color: Color(0xFFEEEEEE)),
          ],
        );
      }),
    );
  }
}
