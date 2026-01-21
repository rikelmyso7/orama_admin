import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orama_admin/vendas/constants/pdv_constants.dart';

class ReportData {
  final DateTime dataInicial;
  final DateTime dataFinal;
  final double totalVendas;
  final int totalPdvsComVenda;
  final int totalPdvs;
  final double ticketMedio;
  final Map<CategoriaPDV, double> totalPorCategoria;
  final List<ReportDayData> vendasPorDia;

  ReportData({
    required this.dataInicial,
    required this.dataFinal,
    required this.totalVendas,
    required this.totalPdvsComVenda,
    required this.totalPdvs,
    required this.ticketMedio,
    required this.totalPorCategoria,
    required this.vendasPorDia,
  });

  int get diasNoPeriodo => dataFinal.difference(dataInicial).inDays + 1;
}

class ReportDayData {
  final DateTime data;
  final double total;

  ReportDayData({
    required this.data,
    required this.total,
  });
}

class ReportPreviewWidget extends StatelessWidget {
  final ReportData reportData;

  const ReportPreviewWidget({
    super.key,
    required this.reportData,
  });

  String _formatCurrency(double value) {
    final formatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    );
    return formatter.format(value);
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 800,
      color: Colors.white,
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cabeçalho
          _buildHeader(),
          const SizedBox(height: 32),

          // Cards de estatísticas
          _buildStatsCards(),
          const SizedBox(height: 32),

          // Vendas por categoria
          _buildCategorySection(),
          const SizedBox(height: 32),

          // Tabela de vendas por dia (últimos 10 dias ou todos se menor)
          _buildDailySalesTable(),
          const SizedBox(height: 24),

          // Rodapé
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Relatório de Vendas',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF60C03D),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Período: ${_formatDate(reportData.dataInicial)} - ${_formatDate(reportData.dataFinal)}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${reportData.diasNoPeriodo} dias',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF60C03D).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.assessment,
                size: 48,
                color: Color(0xFF60C03D),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 4,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF60C03D), Color(0xFF4CAF50)],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Vendas',
            _formatCurrency(reportData.totalVendas),
            Icons.attach_money,
            const Color(0xFF60C03D),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'PDVs com Vendas',
            '${reportData.totalPdvsComVenda}/${reportData.totalPdvs}',
            Icons.store,
            const Color(0xFF06B6D4),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Ticket Médio',
            _formatCurrency(reportData.ticketMedio),
            Icons.receipt_long,
            const Color(0xFFF97316),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vendas por Categoria',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        ...reportData.totalPorCategoria.entries.map((entry) {
          final categoria = entry.key;
          final total = entry.value;
          final percentual = (total / reportData.totalVendas) * 100;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: getCategoriaColor(categoria),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          getCategoriaLabel(categoria),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${_formatCurrency(total)} (${percentual.toStringAsFixed(1)}%)',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentual / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      getCategoriaColor(categoria),
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDailySalesTable() {
    final diasParaMostrar = reportData.vendasPorDia.length > 10
        ? reportData.vendasPorDia.sublist(reportData.vendasPorDia.length - 10)
        : reportData.vendasPorDia;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vendas Diárias${reportData.vendasPorDia.length > 10 ? ' (últimos 10 dias)' : ''}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: const Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Data',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Total Vendido',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
              ...diasParaMostrar.asMap().entries.map((entry) {
                final index = entry.key;
                final dayData = entry.value;
                final isLast = index == diasParaMostrar.length - 1;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: isLast
                          ? BorderSide.none
                          : BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          _formatDate(dayData.data),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          _formatCurrency(dayData.total),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Container(
          height: 1,
          color: Colors.grey.shade300,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Gerado em: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const Text(
              'Orama Admin',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF60C03D),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String getCategoriaLabel(CategoriaPDV categoria) {
    switch (categoria) {
      case CategoriaPDV.loja:
        return 'Lojas';
      case CategoriaPDV.turismo:
        return 'Turismo';
      case CategoriaPDV.evento:
        return 'Eventos';
    }
  }

  Color getCategoriaColor(CategoriaPDV categoria) {
    switch (categoria) {
      case CategoriaPDV.loja:
        return const Color(0xFF60C03D);
      case CategoriaPDV.turismo:
        return const Color(0xFF06B6D4);
      case CategoriaPDV.evento:
        return const Color(0xFF8B5CF6);
    }
  }
}
