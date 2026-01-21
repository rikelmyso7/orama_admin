import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:orama_admin/vendas/vendas_store.dart';
import 'package:orama_admin/vendas/constants/pdv_constants.dart';
import 'package:orama_admin/widgets/vendas/stats_card.dart';
import 'package:orama_admin/widgets/vendas/evolucao_chart.dart';
import 'package:orama_admin/widgets/vendas/categoria_section.dart';
import 'package:orama_admin/widgets/vendas/pdv_detail_dialog.dart';
import 'package:orama_admin/widgets/date_picker_widget.dart';
import 'package:orama_admin/pages/vendas/monthly_breakdown_page.dart';
import 'package:orama_admin/pages/vendas/pdv_monthly_breakdown_page.dart';

class DashboardVendasPage extends StatefulWidget {
  const DashboardVendasPage({super.key});

  @override
  State<DashboardVendasPage> createState() => _DashboardVendasPageState();
}

class _DashboardVendasPageState extends State<DashboardVendasPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final store = Provider.of<VendasStore>(context, listen: false);
      store.fetchData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<VendasStore>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard Vendas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF60C03D),
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Observer(
        builder: (_) {
          if (store.isLoading && store.data == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF60C03D)),
                  SizedBox(height: 16),
                  Text('Carregando dados...'),
                ],
              ),
            );
          }

          if (store.error != null && store.data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Erro ao carregar dados',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      store.error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => store.fetchData(forceRefresh: true),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar novamente'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF60C03D),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (store.data == null || store.mesSelecionado == null) {
            return const Center(child: Text('Nenhum dado disponível'));
          }

          return RefreshIndicator(
            onRefresh: () => store.fetchData(forceRefresh: true),
            color: const Color(0xFF60C03D),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header com seletores
                  _buildHeader(store),

                  // Cards de estatísticas
                  _buildStatsCards(store),

                  // Gráfico de evolução
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: EvolucaoChart(
                      evolucao: store.evolucaoMes,
                      diaSelecionado: store.diaSelecionado,
                      mesNome: store.mesSelecionado?.formattedMonth,
                      onDiaTap: store.selecionarDia,
                      onChartTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PdvMonthlyBreakdownPage(),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Seções por categoria
                  CategoriaSection(
                    categoria: CategoriaPDV.loja,
                    vendas: store.vendasPorCategoria[CategoriaPDV.loja] ?? [],
                    totalDia: store.totalDiaLojas,
                    onPdvTap: (venda) => showPdvDetailDialog(context, venda),
                  ),

                  CategoriaSection(
                    categoria: CategoriaPDV.turismo,
                    vendas:
                        store.vendasPorCategoria[CategoriaPDV.turismo] ?? [],
                    totalDia: store.totalDiaTurismo,
                    onPdvTap: (venda) => showPdvDetailDialog(context, venda),
                  ),

                  CategoriaSection(
                    categoria: CategoriaPDV.evento,
                    vendas: store.vendasPorCategoria[CategoriaPDV.evento] ?? [],
                    totalDia: store.totalDiaEventos,
                    onPdvTap: (venda) => showPdvDetailDialog(context, venda),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(VendasStore store) {
    return Container(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: store.hasPreviousDay
                    ? () => store.navegarDia(DirecaoNavegacao.anterior)
                    : null,
              ),
              DatePickerWidget(
                key: ValueKey(store.dataSelecionada),
                initialDate: store.dataSelecionada,
                onDateSelected: (newDate) {
                  store.selecionarData(newDate);
                },
                dateFormat: DateFormat('dd MMMM yyyy', 'pt_BR'),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: store.hasNextDay
                    ? () => store.navegarDia(DirecaoNavegacao.proximo)
                    : null,
              ),
            ],
          ),
          if (store.error != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      store.error!,
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsCards(VendasStore store) {
    final stats = store.estatisticasDia;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 360;
        final isMediumScreen = constraints.maxWidth < 400;

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 8 : 12,
            vertical: 8,
          ),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio:
                isSmallScreen ? 1.0 : (isMediumScreen ? 1.15 : 1.3),
            mainAxisSpacing: isSmallScreen ? 6 : 8,
            crossAxisSpacing: isSmallScreen ? 6 : 8,
            children: [
              StatsCard(
                title: 'Total do Dia',
                value: store.formatarValor(stats.totalVendido),
                icon: Icons.attach_money,
                variacao: stats.variacao,
                iconColor: const Color(0xFF60C03D),
              ),
              StatsCard(
                title: 'PDVs com Vendas',
                value: '${stats.pdvsComVenda}',
                icon: Icons.store,
                subtitle: 'de ${store.data?.pdvs.length ?? 0} PDVs',
                iconColor: const Color(0xFF06B6D4),
              ),
              StatsCard(
                title: 'Ticket Médio',
                value: store.formatarValor(stats.ticketMedio),
                icon: Icons.receipt_long,
                subtitle: 'por PDV',
                iconColor: const Color(0xFFF97316),
              ),
              StatsCard(
                title: 'Total do Mês',
                value: store.formatarValor(store.totalMes),
                icon: Icons.calendar_month,
                subtitle: '${store.evolucaoMes.length} dias',
                iconColor: const Color(0xFF8B5CF6),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MonthlyBreakdownPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
