import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PeriodSelectorDialog extends StatefulWidget {
  const PeriodSelectorDialog({super.key});

  @override
  State<PeriodSelectorDialog> createState() => _PeriodSelectorDialogState();
}

class _PeriodSelectorDialogState extends State<PeriodSelectorDialog> {
  DateTime? _dataInicial;
  DateTime? _dataFinal;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  Future<void> _selecionarData(bool isDataInicial) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF60C03D),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isDataInicial) {
          _dataInicial = picked;
          // Se a data final já está definida e é anterior à inicial, ajustar
          if (_dataFinal != null && _dataFinal!.isBefore(_dataInicial!)) {
            _dataFinal = null;
          }
        } else {
          // Garantir que data final não seja anterior à inicial
          if (_dataInicial != null && picked.isBefore(_dataInicial!)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Data final não pode ser anterior à data inicial'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }
          _dataFinal = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.calendar_month,
                  color: Color(0xFF60C03D),
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Selecionar Período',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Data Inicial
            const Text(
              'Data Inicial',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _selecionarData(true),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today,
                      size: 20,
                      color: _dataInicial != null
                        ? const Color(0xFF60C03D)
                        : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _dataInicial != null
                        ? _dateFormat.format(_dataInicial!)
                        : 'Selecione a data inicial',
                      style: TextStyle(
                        fontSize: 16,
                        color: _dataInicial != null
                          ? Colors.black
                          : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Data Final
            const Text(
              'Data Final',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _selecionarData(false),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today,
                      size: 20,
                      color: _dataFinal != null
                        ? const Color(0xFF60C03D)
                        : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _dataFinal != null
                        ? _dateFormat.format(_dataFinal!)
                        : 'Selecione a data final',
                      style: TextStyle(
                        fontSize: 16,
                        color: _dataFinal != null
                          ? Colors.black
                          : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_dataInicial != null && _dataFinal != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF60C03D).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Color(0xFF60C03D),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Período: ${_dataFinal!.difference(_dataInicial!).inDays + 1} dias',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF60C03D),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Botões
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _dataInicial != null && _dataFinal != null
                    ? () {
                        Navigator.of(context).pop({
                          'dataInicial': _dataInicial!,
                          'dataFinal': _dataFinal!,
                        });
                      }
                    : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF60C03D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: const Text('Gerar Relatório'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Mostra o diálogo de seleção de período
Future<Map<String, DateTime>?> showPeriodSelectorDialog(BuildContext context) async {
  return await showDialog<Map<String, DateTime>>(
    context: context,
    builder: (context) => const PeriodSelectorDialog(),
  );
}
