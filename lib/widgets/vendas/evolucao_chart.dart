import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:orama_admin/vendas/models/vendas_data_model.dart';

class EvolucaoChart extends StatelessWidget {
  final List<EvolucaoDia> evolucao;
  final int diaSelecionado;
  final String? mesNome;
  final ValueChanged<int>? onDiaTap;
  final VoidCallback? onChartTap;

  const EvolucaoChart({
    super.key,
    required this.evolucao,
    required this.diaSelecionado,
    this.mesNome,
    this.onDiaTap,
    this.onChartTap,
  });

  @override
  Widget build(BuildContext context) {
    if (evolucao.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('Sem dados para exibir')),
        ),
      );
    }

    String formatarValor(double valor) {
      final partes = valor.toStringAsFixed(2).split('.');
      final inteiro = partes[0].replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]}.',
      );
      final decimal = partes[1];
      return 'R\$ $inteiro,$decimal';
    }

    final maxY = evolucao.map((e) => e.total).reduce((a, b) => a > b ? a : b);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onChartTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Evolução de ${mesNome ?? 'Mês'}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(Icons.info_outline,
                      size: 20, color: Colors.black54), // Ícone de gráfico
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY * 1.1,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => Colors.black87,
                        tooltipPadding: const EdgeInsets.all(8),
                        tooltipMargin: 8,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final dia = evolucao[groupIndex].dia;
                          final valor = evolucao[groupIndex].total;
                          return BarTooltipItem(
                            'Dia $dia\nR\$ ${formatarValor(valor)}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                      touchCallback: (event, response) {
                        if (event.isInterestedForInteractions &&
                            response?.spot != null &&
                            onDiaTap != null) {
                          final index = response!.spot!.touchedBarGroupIndex;
                          if (index >= 0 && index < evolucao.length) {
                            onDiaTap!(evolucao[index].dia);
                          }
                        }
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < evolucao.length) {
                              // Mostrar apenas alguns dias para evitar sobreposição
                              if (evolucao.length <= 10 ||
                                  index % (evolucao.length ~/ 10 + 1) == 0) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    '${evolucao[index].dia}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                );
                              }
                            }
                            return const SizedBox.shrink();
                          },
                          reservedSize: 28,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 45,
                          getTitlesWidget: (value, meta) {
                            if (value == 0) return const SizedBox.shrink();
                            String text;
                            if (value >= 1000) {
                              text = '${(value / 1000).toStringAsFixed(0)}k';
                            } else {
                              text = value.toStringAsFixed(0);
                            }
                            return Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Text(
                                text,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxY / 4,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.grey[200],
                        strokeWidth: 1,
                      ),
                    ),
                    barGroups: evolucao.asMap().entries.map((entry) {
                      final isSelected = entry.value.dia == diaSelecionado;
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value.total,
                            color: isSelected
                                ? const Color(0xFFEC4899)
                                : Colors.grey.withOpacity(0.4),
                            width: evolucao.length > 20 ? 8 : 16,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
