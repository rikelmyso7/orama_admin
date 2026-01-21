import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';
import 'package:orama_admin/vendas/vendas_store.dart';

class PdvMonthlyBreakdownPage extends StatelessWidget {
  const PdvMonthlyBreakdownPage({super.key});

  static const _primaryColor = Color(0xFF60C03D);
  static const _barColor = Color(0xFFEA9E13);

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<VendasStore>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Observer(
          builder: (_) => Text(
            'PDVs - ${store.mesSelecionado?.formattedMonth ?? "Mês"}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Observer(
        builder: (_) {
          if (store.data == null || store.mesSelecionado == null) {
            return const _EmptyState();
          }

          final pdvData = _calculatePdvTotals(store);

          if (pdvData.isEmpty) {
            return const _EmptyState();
          }

          final maxTotal =
              pdvData.map((e) => e['total'] as double).fold(0.0, max);
          final grandTotal =
              pdvData.fold(0.0, (sum, item) => sum + (item['total'] as double));

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: pdvData.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              if (index == pdvData.length) {
                return _TotalFooter(
                  total: grandTotal,
                  store: store,
                  color: _primaryColor,
                );
              }

              final data = pdvData[index];
              return _PdvBar(
                pdvName: data['name'] as String,
                value: data['total'] as double,
                maxValue: maxTotal,
                store: store,
                barColor: _barColor,
                primaryColor: _primaryColor,
              );
            },
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _calculatePdvTotals(VendasStore store) {
    if (store.data == null || store.mesSelecionado == null) return [];

    final mesKey = store.mesSelecionado!.key;
    final vendasMes = store.data!.vendasPorMes[mesKey];

    if (vendasMes == null) return [];

    // Calcular total por PDV no mês
    final Map<String, Map<String, dynamic>> pdvTotals = {};

    for (final venda in vendasMes) {
      for (final sale in venda.sales) {
        if (!pdvTotals.containsKey(sale.storeId)) {
          pdvTotals[sale.storeId] = {
            'id': sale.storeId,
            'name': sale.storeName,
            'total': 0.0,
          };
        }
        pdvTotals[sale.storeId]!['total'] =
            (pdvTotals[sale.storeId]!['total'] as double) + sale.valor;
      }
    }

    // Converter para lista e ordenar por valor (maior para menor)
    final result = pdvTotals.values.toList()
      ..sort((a, b) => (b['total'] as double).compareTo(a['total'] as double));

    return result;
  }
}

class _PdvBar extends StatelessWidget {
  final String pdvName;
  final double value;
  final double maxValue;
  final VendasStore store;
  final Color barColor;
  final Color primaryColor;

  const _PdvBar({
    required this.pdvName,
    required this.value,
    required this.maxValue,
    required this.store,
    required this.barColor,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = maxValue > 0 ? value / maxValue : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                pdvName,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              store.formatarValor(value),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 24,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }
}

class _TotalFooter extends StatelessWidget {
  final double total;
  final VendasStore store;
  final Color color;

  const _TotalFooter({
    required this.total,
    required this.store,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        const Divider(thickness: 2),
        const SizedBox(height: 16),
        Text(
          'Total do mês',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        Text(
          store.formatarValor(total),
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Nenhum dado disponível'));
  }
}
