import 'package:flutter/material.dart';
import 'package:orama_admin/vendas/models/vendas_data_model.dart';
import 'package:orama_admin/vendas/constants/pdv_constants.dart';
import 'pdv_card.dart';

class CategoriaSection extends StatelessWidget {
  final CategoriaPDV categoria;
  final List<VendaPDV> vendas;
  final double totalDia;
  final Function(VendaPDV)? onPdvTap;

  const CategoriaSection({
    super.key,
    required this.categoria,
    required this.vendas,
    required this.totalDia,
    this.onPdvTap,
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
    if (vendas.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                nomeCategoria[categoria] ?? '',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF60C03D).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _formatarValor(totalDia),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF60C03D),
                  ),
                ),
              ),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: vendas.length,
          itemBuilder: (context, index) {
            final venda = vendas[index];
            return PdvCard(
              venda: venda,
              onTap: onPdvTap != null ? () => onPdvTap!(venda) : null,
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
