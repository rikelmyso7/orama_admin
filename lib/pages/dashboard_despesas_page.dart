import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:orama_admin/despesas/despesas_store.dart';
import 'package:orama_admin/despesas/models/despesa_lancamento.dart';
import 'package:orama_admin/widgets/vendas/stats_card.dart';

class DashboardDespesasPage extends StatefulWidget {
  const DashboardDespesasPage({super.key});

  @override
  State<DashboardDespesasPage> createState() => _DashboardDespesasPageState();
}

class _DashboardDespesasPageState extends State<DashboardDespesasPage> {
  static const _red = Color(0xFFEF4444);
  static const _orange = Color(0xFFF97316);
  static const _purple = Color(0xFF8B5CF6);
  static const _cyan = Color(0xFF06B6D4);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final store = Provider.of<DespesasStore>(context, listen: false);
      store.fetchData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Análise de Despesas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _red,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Consumer<DespesasStore>(
        builder: (context, store, _) {
          if (store.isLoading && store.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: _red),
                  SizedBox(height: 16),
                  Text('Carregando dados...'),
                ],
              ),
            );
          }

          if (store.error != null && store.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: _red),
                    const SizedBox(height: 16),
                    Text('Erro ao carregar dados',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(store.error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => store.fetchData(forceRefresh: true),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar novamente'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (store.isEmpty) {
            return const Center(child: Text('Nenhum dado disponível'));
          }

          // Modo drill-down: dia selecionado
          if (store.diaSelecionado != null) {
            return _buildDrillDown(store);
          }

          return RefreshIndicator(
            onRefresh: () => store.fetchData(forceRefresh: true),
            color: _red,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMesHeader(store),
                  _buildStatsCards(store),
                  _buildComparativoMensal(store),
                  _buildEvolucaoDiaria(store),
                  _buildTopCategorias(store),
                  _buildUnidades(store),
                  if (store.gastosFuturos.isNotEmpty)
                    _buildGastosFuturos(store),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Header de mês ──────────────────────────────────────────────────────────

  Widget _buildMesHeader(DespesasStore store) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed:
                store.hasPreviousMes ? () => store.navegarMes(true) : null,
          ),
          Text(
            store.mesNome,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: store.hasNextMes ? () => store.navegarMes(false) : null,
          ),
        ],
      ),
    );
  }

  // ── Cards de stats ─────────────────────────────────────────────────────────

  Widget _buildStatsCards(DespesasStore store) {
    final variacao = store.variacaoVsMesAnterior;
    final maiorMesNome = store.mesComMaiorGastoKey != null
        ? store.nomeDoMesKey(store.mesComMaiorGastoKey!)
        : '-';

    return LayoutBuilder(builder: (context, constraints) {
      final small = constraints.maxWidth < 360;
      final medium = constraints.maxWidth < 400;
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: small ? 8 : 12, vertical: 8),
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: small ? 1.0 : (medium ? 1.15 : 1.3),
          mainAxisSpacing: small ? 6 : 8,
          crossAxisSpacing: small ? 6 : 8,
          children: [
            StatsCard(
              title: 'Total do Mês',
              value: store.formatarValor(store.totalMesSelecionado),
              icon: Icons.calendar_month,
              variacao: variacao,
              iconColor: _red,
            ),
            StatsCard(
              title: 'Vs Mês Anterior',
              value: variacao != null
                  ? '${variacao >= 0 ? '+' : ''}${variacao.toStringAsFixed(1)}%'
                  : '-',
              icon: Icons.compare_arrows,
              subtitle: store.formatarValor(store.totalMesAnterior),
              iconColor:
                  (variacao != null && variacao < 0) ? Colors.green : _orange,
            ),
            StatsCard(
              title: 'Média Mensal',
              value: store.formatarValor(store.mediaHistorica),
              icon: Icons.show_chart,
              subtitle: '${store.mesesDisponiveis.length} meses',
              iconColor: _cyan,
            ),
            StatsCard(
              title: 'Maior Gasto',
              value: store.formatarValor(store.totalMesComMaiorGasto),
              icon: Icons.trending_up,
              subtitle: maiorMesNome,
              iconColor: _purple,
            ),
          ],
        ),
      );
    });
  }

  // ── Comparativo mensal (barras) ────────────────────────────────────────────

  Widget _buildComparativoMensal(DespesasStore store) {
    final evolucao = store.evolucaoMensal;
    if (evolucao.isEmpty) return const SizedBox.shrink();

    final maxY = evolucao.map((e) => e.total).reduce((a, b) => a > b ? a : b);
    final media = store.mediaHistorica;
    final maiorKey = store.mesComMaiorGastoKey;

    return _sectionCard(
      title: 'Comparativo Mensal',
      icon: Icons.bar_chart,
      child: SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY * 1.15,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => Colors.black87,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final item = evolucao[groupIndex];
                  return BarTooltipItem(
                    '${store.nomeDoMesKey(item.mesKey)}\n${store.formatarValor(item.total)}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= evolucao.length) {
                      return const SizedBox.shrink();
                    }
                    final parts = evolucao[idx].mesKey.split('-');
                    final label = parts.length == 2
                        ? '${_mesAbrev(int.tryParse(parts[1]) ?? 0)}\n${parts[0]}'
                        : evolucao[idx].mesKey;
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9,
                          color: evolucao[idx].mesKey == store.mesSelecionado
                              ? _red
                              : Colors.grey[600],
                          fontWeight:
                              evolucao[idx].mesKey == store.mesSelecionado
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 48,
                  getTitlesWidget: (value, meta) {
                    if (value == 0) return const SizedBox.shrink();
                    final text = value >= 1000
                        ? '${(value / 1000).toStringAsFixed(0)}k'
                        : value.toStringAsFixed(0);
                    return Text(text,
                        style: TextStyle(fontSize: 9, color: Colors.grey[600]));
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY / 4,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: Colors.grey[200], strokeWidth: 1),
            ),
            extraLinesData: ExtraLinesData(
              horizontalLines: [
                HorizontalLine(
                  y: media,
                  color: _cyan.withOpacity(0.6),
                  strokeWidth: 1.5,
                  dashArray: [6, 4],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    labelResolver: (_) => 'média',
                    style: TextStyle(
                      fontSize: 9,
                      color: _cyan,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            barGroups: evolucao.asMap().entries.map((entry) {
              final isSelecionado = entry.value.mesKey == store.mesSelecionado;
              final isMaior = entry.value.mesKey == maiorKey;
              Color cor;
              if (isMaior) {
                cor = _purple;
              } else if (isSelecionado) {
                cor = _red;
              } else {
                cor = Colors.grey.withOpacity(0.4);
              }
              return BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: entry.value.total,
                    color: cor,
                    width: 22,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ── Evolução diária do mês ─────────────────────────────────────────────────

  Widget _buildEvolucaoDiaria(DespesasStore store) {
    final evolucao = store.evolucaoDiariaMes;
    if (evolucao.isEmpty) return const SizedBox.shrink();

    final maxY = evolucao.map((e) => e.total).reduce((a, b) => a > b ? a : b);

    return _sectionCard(
      title: 'Evolução Diária — ${store.mesNome}',
      icon: Icons.calendar_view_day,
      subtitle: 'Toque em um dia para ver detalhes',
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY * 1.1,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => Colors.black87,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final item = evolucao[groupIndex];
                  return BarTooltipItem(
                    'Dia ${item.dia}\n${store.formatarValor(item.total)}',
                    const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11),
                  );
                },
              ),
              touchCallback: (event, response) {
                if (event.isInterestedForInteractions &&
                    response?.spot != null) {
                  final idx = response!.spot!.touchedBarGroupIndex;
                  if (idx >= 0 && idx < evolucao.length) {
                    store.selecionarDia(evolucao[idx].dia);
                  }
                }
              },
            ),
            titlesData: FlTitlesData(
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= evolucao.length) {
                      return const SizedBox.shrink();
                    }
                    if (evolucao.length <= 10 ||
                        idx % (evolucao.length ~/ 10 + 1) == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('${evolucao[idx].dia}',
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[600])),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 45,
                  getTitlesWidget: (value, meta) {
                    if (value == 0) return const SizedBox.shrink();
                    final text = value >= 1000
                        ? '${(value / 1000).toStringAsFixed(0)}k'
                        : value.toStringAsFixed(0);
                    return Text(text,
                        style: TextStyle(fontSize: 9, color: Colors.grey[600]));
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY / 4,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: Colors.grey[200], strokeWidth: 1),
            ),
            barGroups: evolucao.asMap().entries.map((entry) {
              return BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: entry.value.total,
                    color: _red.withOpacity(0.75),
                    width: evolucao.length > 20 ? 8 : 14,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ── Top categorias ─────────────────────────────────────────────────────────

  Widget _buildTopCategorias(DespesasStore store) {
    final cats = store.topCategoriasMes;
    if (cats.isEmpty) return const SizedBox.shrink();

    final total = store.totalMesSelecionado;

    return _sectionCard(
      title: 'Top Categorias do Mês',
      icon: Icons.category,
      child: Column(
        children: cats.map((entry) {
          final pct = total > 0 ? entry.value / total : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(entry.key,
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Text(store.formatarValor(entry.value),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: _red)),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 36,
                      child: Text(
                        '${(pct * 100).toStringAsFixed(0)}%',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: pct.clamp(0.0, 1.0),
                  backgroundColor: Colors.grey[200],
                  color: _orange,
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Unidades ───────────────────────────────────────────────────────────────

  Widget _buildUnidades(DespesasStore store) {
    final unidades = store.despesasPorUnidadeMes;
    if (unidades.isEmpty) return const SizedBox.shrink();

    final total = store.totalMesSelecionado;

    return _sectionCard(
      title: 'Despesas por Unidade',
      icon: Icons.store,
      child: Column(
        children: unidades.map((entry) {
          final pct = total > 0 ? entry.value / total : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(entry.key,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Text(store.formatarValor(entry.value),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: _red)),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 36,
                      child: Text(
                        '${(pct * 100).toStringAsFixed(0)}%',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: pct.clamp(0.0, 1.0),
                  backgroundColor: Colors.grey[200],
                  color: _purple,
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Gastos futuros ─────────────────────────────────────────────────────────

  Widget _buildGastosFuturos(DespesasStore store) {
    final futuros = store.gastosFuturos;

    return _sectionCard(
      title: 'Gastos Futuros Registrados',
      icon: Icons.schedule,
      subtitle:
          'Total comprometido: ${store.formatarValor(store.totalGastosFuturos)}',
      child: Column(
        children: futuros.take(10).map((l) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.event, size: 16, color: _orange),
            ),
            title: Text(l.categoria,
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis),
            subtitle: Text('${l.unidade} · ${l.data}',
                style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            trailing: Text(store.formatarValor(l.valor),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: _orange, fontSize: 13)),
          );
        }).toList(),
      ),
    );
  }

  // ── Drill-down dia ─────────────────────────────────────────────────────────

  Widget _buildDrillDown(DespesasStore store) {
    final dia = store.diaSelecionado!;
    final categorias = store.despesasPorCategoriaDia;
    final total = store.totalDiaSelecionado;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Despesas — Dia $dia de ${store.mesNome}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        backgroundColor: _red,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: store.limparDia,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total do dia
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.money_off, color: _red, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total do Dia',
                            style: TextStyle(fontSize: 13, color: Colors.grey)),
                        Text(store.formatarValor(total),
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: _red)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Lista por categoria
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.list_alt, size: 18, color: _orange),
                        SizedBox(width: 8),
                        Text('Despesas por Categoria',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (categorias.isEmpty)
                      const Text('Nenhuma despesa neste dia.')
                    else ...[
                      ...categorias.entries.map((entry) {
                        final pct = total > 0 ? entry.value / total : 0.0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(entry.key,
                                        style: const TextStyle(fontSize: 13),
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(store.formatarValor(entry.value),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: _red)),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 36,
                                    child: Text(
                                      '${(pct * 100).toStringAsFixed(0)}%',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[500]),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: pct.clamp(0.0, 1.0),
                                backgroundColor: Colors.grey[200],
                                color: _orange,
                                minHeight: 4,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ],
                          ),
                        );
                      }),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(store.formatarValor(total),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _red,
                                  fontSize: 16)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers de UI ──────────────────────────────────────────────────────────

  Widget _sectionCard({
    required String title,
    required IconData icon,
    String? subtitle,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: _red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ],
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }

  String _mesAbrev(int mes) {
    const abrevs = [
      '',
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
    return mes >= 1 && mes <= 12 ? abrevs[mes] : '';
  }
}
