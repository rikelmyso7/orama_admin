import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:orama_admin/vendas/vendas_store.dart';
import 'month_stores_page.dart';

class MonthlyBreakdownPage extends StatefulWidget {
  const MonthlyBreakdownPage({super.key});

  @override
  State<MonthlyBreakdownPage> createState() => _MonthlyBreakdownPageState();
}

class _MonthlyBreakdownPageState extends State<MonthlyBreakdownPage> {
  static const _primaryColor = Color(0xFF60C03D);

  static const _monthColors = [
    Color(0xFF60C03D), // Janeiro  - verde primário
    Color(0xFF06B6D4), // Fevereiro - ciano
    Color(0xFFF97316), // Março    - laranja
    Color(0xFF8B5CF6), // Abril    - roxo
    Color(0xFFEC4899), // Maio     - rosa
    Color(0xFFEA9E13), // Junho    - âmbar
    Color(0xFF0EA5A0), // Julho    - teal
    Color(0xFFE53935), // Agosto   - vermelho
    Color(0xFF1E88E5), // Setembro - azul
    Color(0xFF43A047), // Outubro  - verde escuro
    Color(0xFFD81B60), // Novembro - magenta
    Color(0xFF6D4C41), // Dezembro - marrom
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

  int? _selectedYear;
  int? _selectedSegmentIndex;
  late TooltipBehavior _tooltipBehavior;

  @override
  void initState() {
    super.initState();
    _tooltipBehavior = TooltipBehavior(
      enable: true,
      decimalPlaces: 2,
      color: const Color(0xFF1E1E2E),
      textStyle: const TextStyle(color: Colors.white, fontSize: 13),
      format: 'point.x\nR\$ point.y',
      header: '',
      borderWidth: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<VendasStore>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Vendas por Ano',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Observer(
        builder: (_) {
          if (store.data == null) return const _EmptyState();

          final allMonths = _calculateMonthlyTotals(store);
          if (allMonths.isEmpty) return const _EmptyState();

          final availableYears =
              allMonths.map((e) => e['year'] as int).toSet().toList()..sort();

          if (_selectedYear == null ||
              !availableYears.contains(_selectedYear)) {
            _selectedYear = availableYears.last;
            _selectedSegmentIndex = null;
          }

          final yearIndex = availableYears.indexOf(_selectedYear!);

          final monthsForYear =
              allMonths.where((e) => e['year'] == _selectedYear).toList();

          final grandTotal = monthsForYear.fold(
              0.0, (sum, item) => sum + (item['total'] as double));

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildYearHeader(availableYears, yearIndex),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Text(
                    'Vendas por Ano',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const Divider(
                    height: 24, thickness: 1, color: Color(0xFFEEEEEE)),
                _buildDonutChart(monthsForYear, grandTotal, store),
                const SizedBox(height: 8),
                _buildMonthList(monthsForYear, store),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildYearHeader(List<int> years, int yearIndex) {
    final canGoBack = yearIndex > 0;
    final canGoForward = yearIndex < years.length - 1;

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              Icons.chevron_left,
              color: canGoBack ? _primaryColor : Colors.grey[300],
              size: 28,
            ),
            onPressed: canGoBack
                ? () => setState(() {
                      _selectedYear = years[yearIndex - 1];
                      _selectedSegmentIndex = null;
                    })
                : null,
          ),
          Text(
            '$_selectedYear',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              color: canGoForward ? _primaryColor : Colors.grey[300],
              size: 28,
            ),
            onPressed: canGoForward
                ? () => setState(() {
                      _selectedYear = years[yearIndex + 1];
                      _selectedSegmentIndex = null;
                    })
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDonutChart(
    List<Map<String, dynamic>> months,
    double grandTotal,
    VendasStore store,
  ) {
    final chartData = months.map((m) {
      final idx = (m['month'] as int) - 1;
      return _ChartData(
        label: _monthNames[idx],
        value: m['total'] as double,
        color: _monthColors[idx],
      );
    }).toList();

    final selected = _selectedSegmentIndex != null &&
            _selectedSegmentIndex! < chartData.length
        ? chartData[_selectedSegmentIndex!]
        : null;

    final centerLabel = selected?.label ?? 'total';
    final centerValue = selected != null
        ? store.formatarValor(selected.value)
        : store.formatarValor(grandTotal);
    final centerPercent = selected != null && grandTotal > 0
        ? '${(selected.value / grandTotal * 100).toStringAsFixed(1)}%'
        : null;

    return SizedBox(
      height: 300,
      child: SfCircularChart(
        tooltipBehavior: _tooltipBehavior,
        annotations: [
          CircularChartAnnotation(
            widget: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected != null)
                  Text(
                    centerLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: selected.color,
                    ),
                  ),
                Text(
                  centerValue,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (centerPercent != null)
                  Text(
                    centerPercent,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  )
                else
                  const Text(
                    'total anual',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ],
        onSelectionChanged: (args) {
          setState(() {
            if (_selectedSegmentIndex == args.pointIndex) {
              _selectedSegmentIndex = null; // deseleciona
            } else {
              _selectedSegmentIndex = args.pointIndex;
            }
          });
        },
        series: [
          DoughnutSeries<_ChartData, String>(
            dataSource: chartData,
            xValueMapper: (d, _) => d.label,
            yValueMapper: (d, _) => d.value,
            pointColorMapper: (d, _) => d.color,
            innerRadius: '80%',
            radius: '90%',
            strokeWidth: 4,
            strokeColor: Colors.white,
            cornerStyle: CornerStyle.bothCurve,
            animationDuration: 0,
            enableTooltip: true,
            selectionBehavior: SelectionBehavior(
              enable: true,
              selectedOpacity: 1.0,
              unselectedOpacity: 0.4,
              selectedBorderWidth: 0,
            ),
            dataLabelSettings: const DataLabelSettings(isVisible: false),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthList(List<Map<String, dynamic>> months, VendasStore store) {
    return Column(
      children: List.generate(months.length, (i) {
        final item = months[i];
        final idx = (item['month'] as int) - 1;
        final color = _monthColors[idx];
        final total = item['total'] as double;

        return Column(
          children: [
            ListTile(
              onTap: () {
                final mesKey = item['key'] as String;
                final vendasDoMes = store.data!.vendasPorMes[mesKey] ?? [];
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MonthStoresPage(
                      monthName: _monthNames[idx],
                      year: item['year'] as int,
                      monthColor: color,
                      vendasDoMes: vendasDoMes,
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
            if (i < months.length - 1)
              const Divider(height: 1, indent: 72, color: Color(0xFFEEEEEE)),
          ],
        );
      }),
    );
  }

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
            'month': mes.month,
            'year': mes.year,
            'total': total,
            'key': mes.key,
          };
        })
        .where((e) => (e['total'] as double) > 0)
        .toList();
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
