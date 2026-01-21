import 'package:flutter/material.dart';
import 'package:orama_admin/vendas/models/mes_disponivel_model.dart';

class MesSelector extends StatelessWidget {
  final MesDisponivel? mesSelecionado;
  final List<MesDisponivel> mesesDisponiveis;
  final ValueChanged<MesDisponivel> onMesSelecionado;

  const MesSelector({
    super.key,
    required this.mesSelecionado,
    required this.mesesDisponiveis,
    required this.onMesSelecionado,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<MesDisponivel>(
          value: mesSelecionado,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: mesesDisponiveis.map((mes) {
            return DropdownMenuItem(
              value: mes,
              child: Text(
                mes.formattedMonth,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
          onChanged: (mes) {
            if (mes != null) {
              onMesSelecionado(mes);
            }
          },
        ),
      ),
    );
  }
}
