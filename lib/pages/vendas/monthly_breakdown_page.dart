import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';
import 'package:orama_admin/vendas/vendas_store.dart';

class MonthlyBreakdownPage extends StatelessWidget {
  const MonthlyBreakdownPage({super.key});

  static const _primaryColor = Color(0xFF60C03D);
  static const _barColor = Color(0xFFEA9E13);
  static const _backgroundColor = Color(0xFFF5F5F5);

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<VendasStore>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Vendas por Mês',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Observer(
        builder: (_) {
          if (store.data == null) return const _EmptyState();

          // 1. Cálculo O(N) executado uma vez antes da renderização
          final monthlyData = _calculateMonthlyTotals(store);

          if (monthlyData.isEmpty) return const _EmptyState();

          final maxTotal =
              monthlyData.map((e) => e['total'] as double).fold(0.0, max);

          final grandTotal = monthlyData.fold(
              0.0, (sum, item) => sum + (item['total'] as double));

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: monthlyData.length + 1, // +1 para o footer
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              // Footer com totais
              if (index == monthlyData.length) {
                return _TotalFooter(
                    total: grandTotal, store: store, color: _primaryColor);
              }

              // Barras de progresso
              final data = monthlyData[index];
              return _MonthBar(
                monthName: data['month'] as String,
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

  // Lógica movida para método puro, mas idealmente estaria no Store como @computed
  List<Map<String, dynamic>> _calculateMonthlyTotals(VendasStore store) {
    if (store.data == null) return [];

    final sortedMonths = store.data!.mesesDisponiveis.toList()
      ..sort((a, b) =>
          DateTime(a.year, a.month).compareTo(DateTime(b.year, b.month)));

    return sortedMonths
        .map((mes) {
          final vendasMes = store.data!.vendasPorMes[mes.key];
          final total = vendasMes?.fold(0.0, (sum, v) => sum + v.total) ?? 0.0;

          return {
            'month': mes.formattedMonth,
            'total': total,
            'key': mes.key,
          };
        })
        .where((e) => (e['total'] as double) > 0)
        .toList();
  }
}

class _MonthBar extends StatelessWidget {
  final String monthName;
  final double value;
  final double maxValue;
  final VendasStore store;
  final Color barColor;
  final Color primaryColor;

  const _MonthBar({
    required this.monthName,
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
            Text(
              monthName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            Text(
              store.formatarValor(value),
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: primaryColor),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight:
                24, // Altura reduzida para estética mais moderna (era 40)
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
          'Total das vendas filtradas',
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
        const SizedBox(height: 32), // Padding inferior extra para scroll
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
