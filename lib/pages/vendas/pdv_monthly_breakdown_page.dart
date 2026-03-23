import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:orama_admin/vendas/vendas_store.dart';

class PdvMonthlyBreakdownPage extends StatelessWidget {
  const PdvMonthlyBreakdownPage({super.key});

  static const _primaryColor = Color(0xFF60C03D);

  static const _pdvColors = [
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

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<VendasStore>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
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
          if (pdvData.isEmpty) return const _EmptyState();

          final grandTotal =
              pdvData.fold(0.0, (sum, item) => sum + (item['total'] as double));

          final chartData = pdvData.asMap().entries.map((e) {
            final color = _pdvColors[e.key % _pdvColors.length];
            return _ChartData(
              label: e.value['name'] as String,
              value: e.value['total'] as double,
              color: color,
            );
          }).toList();

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
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
                            'Vendas por PDV',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            store.mesSelecionado?.formattedMonth ?? 'Mês',
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
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          Text(
                            store.formatarValor(grandTotal),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: _primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(
                    height: 24, thickness: 1, color: Color(0xFFEEEEEE)),
                _PdvBarChart(
                  chartData: chartData,
                  store: store,
                ),
                const Divider(
                    height: 24, thickness: 1, color: Color(0xFFEEEEEE)),
                const SizedBox(height: 8),
              ],
            ),
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

    return pdvTotals.values.toList()
      ..sort((a, b) => (b['total'] as double).compareTo(a['total'] as double));
  }
}

// Widget separado com StatefulWidget para isolar o ciclo de vida do gráfico
class _PdvBarChart extends StatefulWidget {
  final List<_ChartData> chartData;
  final VendasStore store;

  const _PdvBarChart({
    super.key,
    required this.chartData,
    required this.store,
  });

  @override
  State<_PdvBarChart> createState() => _PdvBarChartState();
}

class _PdvBarChartState extends State<_PdvBarChart> {
  @override
  Widget build(BuildContext context) {
    final chartHeight = (widget.chartData.length * 56.0).clamp(200.0, 500.0);

    return SizedBox(
      height: chartHeight,
      child: SfCartesianChart(
        margin: const EdgeInsets.fromLTRB(8, 8, 16, 8),
        plotAreaBorderWidth: 0,
        enableAxisAnimation: false,
        primaryXAxis: CategoryAxis(
          axisLine: const AxisLine(width: 0),
          majorTickLines: const MajorTickLines(size: 0),
          majorGridLines: const MajorGridLines(width: 0),
          labelStyle: const TextStyle(fontSize: 12, color: Colors.black87),
          maximumLabels: widget.chartData.length,
          labelIntersectAction: AxisLabelIntersectAction.none,
        ),
        primaryYAxis: NumericAxis(isVisible: false),
        series: [
          BarSeries<_ChartData, String>(
            dataSource: widget.chartData,
            xValueMapper: (d, _) => d.label,
            yValueMapper: (d, _) => d.value,
            pointColorMapper: (d, _) => d.color,
            borderRadius: BorderRadius.circular(6),
            spacing: 0.3,
            animationDuration: 0,
            dataLabelSettings: DataLabelSettings(
              isVisible: true,
              labelAlignment: ChartDataLabelAlignment.outer,
              builder: (data, point, series, pointIndex, seriesIndex) {
                final d = data as _ChartData;
                return Text(
                  widget.store.formatarValor(d.value),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartData {
  final String label;
  final double value;
  final Color color;

  const _ChartData({
    required this.label,
    required this.value,
    required this.color,
  });
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Nenhum dado disponível'));
  }
}
