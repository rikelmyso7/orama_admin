import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:orama_admin/vendas/vendas_store.dart';

class StoreMonthsPage extends StatelessWidget {
  final String storeId;
  final String storeName;
  final Color storeColor;
  final VendasStore store;

  static const _monthColors = [
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

  static const _monthIcons = [
    Icons.calendar_today,
    Icons.calendar_today,
    Icons.wb_sunny_outlined,
    Icons.wb_sunny_outlined,
    Icons.wb_sunny_outlined,
    Icons.beach_access_outlined,
    Icons.beach_access_outlined,
    Icons.beach_access_outlined,
    Icons.cloud_outlined,
    Icons.cloud_outlined,
    Icons.cloud_outlined,
    Icons.ac_unit_outlined,
  ];

  static const _monthNames = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  const StoreMonthsPage({
    super.key,
    required this.storeId,
    required this.storeName,
    required this.storeColor,
    required this.store,
  });

  List<Map<String, dynamic>> _calcularMesesDaLoja() {
    if (store.data == null) return [];

    final Map<String, Map<String, dynamic>> meses = {};

    for (final entry in store.data!.vendasPorMes.entries) {
      for (final dia in entry.value) {
        for (final sale in dia.sales) {
          if (sale.storeId != storeId) continue;
          final key = entry.key;
          if (meses.containsKey(key)) {
            meses[key]!['total'] =
                (meses[key]!['total'] as double) + sale.valor;
          } else {
            meses[key] = {
              'key': key,
              'year': dia.year,
              'month': dia.month,
              'total': sale.valor,
            };
          }
        }
      }
    }

    return meses.values.toList()
      ..sort((a, b) {
        final da = DateTime(a['year'] as int, a['month'] as int);
        final db = DateTime(b['year'] as int, b['month'] as int);
        return da.compareTo(db);
      });
  }

  @override
  Widget build(BuildContext context) {
    final meses = _calcularMesesDaLoja();
    final grandTotal =
        meses.fold(0.0, (sum, m) => sum + (m['total'] as double));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Histórico de $storeName',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: storeColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: meses.isEmpty
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
                              'Vendas por Mês',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              storeName,
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
                              'Total geral',
                              style:
                                  TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            Text(
                              store.formatarValor(grandTotal),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: storeColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Divider(
                      height: 24, thickness: 1, color: Colors.grey.shade300),
                  _StoreChart(
                      meses: meses,
                      storeColor: storeColor,
                      store: store,
                      storeName: storeName),
                  Divider(
                      height: 24, thickness: 1, color: Colors.grey.shade300),
                  _buildMonthList(meses.reversed.toList()),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  static const _monthAbbr = [
    'Jan',
    'Fev',
    'Mar',
    'Abr',
    'Mai',
    'Jun',
    'Jul',
    'Ago',
    'Set',
    'Out',
    'Nov',
    'Dez',
  ];

  Widget _buildMonthList(List<Map<String, dynamic>> meses) {
    return Column(
      children: List.generate(meses.length, (i) {
        final item = meses[i];
        final idx = (item['month'] as int) - 1;
        final color = _monthColors[idx];
        final total = item['total'] as double;
        final year = item['year'] as int;

        return Column(
          children: [
            ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _monthIcons[idx],
                  color: Colors.white,
                  size: 22,
                ),
              ),
              title: Text(
                _monthNames[idx],
                style: const TextStyle(fontSize: 15),
              ),
              subtitle: Text(
                '$year',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              trailing: Text(
                store.formatarValor(total),
                style: const TextStyle(fontSize: 15),
              ),
            ),
            if (i < meses.length - 1)
              Divider(height: 1, color: Colors.grey.shade200),
          ],
        );
      }),
    );
  }
}

class _ChartData {
  final String label;
  final double value;

  const _ChartData({required this.label, required this.value});
}

class _StoreChart extends StatefulWidget {
  final List<Map<String, dynamic>> meses;
  final Color storeColor;
  final VendasStore store;
  final String storeName;

  const _StoreChart({
    super.key,
    required this.meses,
    required this.storeColor,
    required this.store,
    required this.storeName,
  });

  @override
  State<_StoreChart> createState() => _StoreChartState();
}

class _StoreChartState extends State<_StoreChart> {
  int? _touchedIndex;

  static const _monthAbbr = [
    'Jan',
    'Fev',
    'Mar',
    'Abr',
    'Mai',
    'Jun',
    'Jul',
    'Ago',
    'Set',
    'Out',
    'Nov',
    'Dez',
  ];

  List<_ChartData> _buildChartData() {
    return widget.meses.map((m) {
      final idx = (m['month'] as int) - 1;
      final year = (m['year'] as int) % 100;
      final label = '${_monthAbbr[idx]}/${year.toString().padLeft(2, '0')}';
      return _ChartData(label: label, value: m['total'] as double);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final chartData = _buildChartData();

    return Stack(
      children: [
        SizedBox(
          height: 240,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
            child: _LineChartWidget(
              chartData: chartData,
              storeColor: widget.storeColor,
              store: widget.store,
              touchedIndex: _touchedIndex,
              onTouch: (i) => setState(() => _touchedIndex = i),
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 10,
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => _ChartFullscreenPage(
                  chartData: chartData,
                  storeColor: widget.storeColor,
                  store: widget.store,
                  storeName: widget.storeName,
                ),
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.fullscreen, size: 20, color: widget.storeColor),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChartFullscreenPage extends StatefulWidget {
  final List<_ChartData> chartData;
  final Color storeColor;
  final VendasStore store;
  final String storeName;

  const _ChartFullscreenPage({
    super.key,
    required this.chartData,
    required this.storeColor,
    required this.store,
    required this.storeName,
  });

  @override
  State<_ChartFullscreenPage> createState() => _ChartFullscreenPageState();
}

class _ChartFullscreenPageState extends State<_ChartFullscreenPage> {
  int? _touchedIndex;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: widget.storeColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Histórico de Vendas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _LineChartWidget(
          chartData: widget.chartData,
          storeColor: widget.storeColor,
          store: widget.store,
          touchedIndex: _touchedIndex,
          onTouch: (i) => setState(() => _touchedIndex = i),
        ),
      ),
    );
  }
}

// ─── fl_chart widget ─────────────────────────────────────────────────────────

class _LineChartWidget extends StatelessWidget {
  final List<_ChartData> chartData;
  final Color storeColor;
  final VendasStore store;
  final int? touchedIndex;
  final ValueChanged<int?> onTouch;

  const _LineChartWidget({
    required this.chartData,
    required this.storeColor,
    required this.store,
    required this.touchedIndex,
    required this.onTouch,
  });

  String _formatYLabel(double value) {
    if (value >= 1000000) return 'R\$${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return 'R\$${(value / 1000).toStringAsFixed(0)}K';
    return 'R\$${value.toStringAsFixed(0)}';
  }

  double _getLeftInterval() {
    if (chartData.isEmpty) return 1;
    final values = chartData.map((d) => d.value).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final range = max - min;
    if (range <= 0) return 1000;
    if (range <= 5000) return 1000;
    if (range <= 20000) return 5000;
    if (range <= 100000) return 20000;
    return 50000;
  }

  @override
  Widget build(BuildContext context) {
    if (chartData.isEmpty) {
      return const Center(child: Text('Sem dados'));
    }

    final spots = List.generate(
      chartData.length,
      (i) => FlSpot(i.toDouble(), chartData[i].value),
    );

    final values = chartData.map((d) => d.value).toList();
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) * 0.15;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          verticalInterval: 1,
          getDrawingVerticalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          ),
          horizontalInterval: _getLeftInterval(),
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final i = value.round();
                if (i < 0 || i >= chartData.length)
                  return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    chartData[i].label,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: _getLeftInterval(),
              getTitlesWidget: (value, meta) {
                final formatted = _formatYLabel(value);
                return Text(
                  formatted,
                  style: const TextStyle(
                    color: Colors.black45,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.left,
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          enabled: true,
          touchCallback: (event, response) {
            if (!event.isInterestedForInteractions ||
                response == null ||
                response.lineBarSpots == null) {
              onTouch(null);
              return;
            }
            onTouch(response.lineBarSpots!.first.spotIndex);
          },
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 8,
            tooltipPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            getTooltipColor: (_) => const Color(0xFF1E1E2E),
            getTooltipItems: (barSpots) => barSpots.map((barSpot) {
              final d = chartData[barSpot.spotIndex];
              return LineTooltipItem(
                '${d.label}\n${store.formatarValor(d.value)}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              );
            }).toList(),
          ),
          handleBuiltInTouches: true,
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: storeColor,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final isSelected = index == touchedIndex;
                return FlDotCirclePainter(
                  radius: isSelected ? 6 : 4,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: storeColor,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  storeColor.withOpacity(0.18),
                  storeColor.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        minX: 0,
        maxX: (chartData.length - 1).toDouble(),
        minY: minY - padding,
        maxY: maxY + padding,
      ),
    );
  }
}
