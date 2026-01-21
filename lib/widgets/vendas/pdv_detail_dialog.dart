import 'package:flutter/material.dart';
import 'package:orama_admin/vendas/models/vendas_data_model.dart';
import 'package:orama_admin/vendas/constants/pdv_constants.dart';
import 'meta_progress_bar.dart';

class PdvDetailDialog extends StatelessWidget {
  final VendaPDV venda;

  const PdvDetailDialog({
    super.key,
    required this.venda,
  });

  String _formatarValor(double valor) {
    final partes = valor.toStringAsFixed(2).split('.');
    final inteiro = partes[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    final decimal = partes[1];
    return 'R\$ $inteiro,$decimal';
  }

  @override
  Widget build(BuildContext context) {
    final cor = getCorPDV(venda.storeId);
    final categoria = getCategoria(venda.storeId);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: cor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        venda.storeName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        nomeCategoria[categoria] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Venda do Dia', _formatarValor(venda.valor)),
            const SizedBox(height: 12),
            _buildInfoRow('Total do Mês', _formatarValor(venda.totalMes)),
            const SizedBox(height: 12),
            _buildInfoRow('Meta Mensal', _formatarValor(venda.meta)),
            const SizedBox(height: 16),
            const Text(
              'Progresso da Meta',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: MetaProgressBar(
                percentual: venda.percentualMeta,
                color: cor,
                height: 10,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              venda.percentualMeta >= 100
                  ? 'Meta atingida!'
                  : 'Faltam ${_formatarValor(venda.meta - venda.totalMes)} para a meta',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color:
                    venda.percentualMeta >= 100 ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

void showPdvDetailDialog(BuildContext context, VendaPDV venda) {
  showDialog(
    context: context,
    builder: (context) => PdvDetailDialog(venda: venda),
  );
}
