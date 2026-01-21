import 'package:flutter/material.dart';

class DiaNavigator extends StatelessWidget {
  final int diaSelecionado;
  final bool hasPrevious;
  final bool hasNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const DiaNavigator({
    super.key,
    required this.diaSelecionado,
    required this.hasPrevious,
    required this.hasNext,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: hasPrevious ? onPrevious : null,
          icon: const Icon(Icons.chevron_left),
          style: IconButton.styleFrom(
            backgroundColor: hasPrevious ? Colors.white : Colors.grey[100],
            foregroundColor: hasPrevious ? Colors.black87 : Colors.grey[400],
          ),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          iconSize: 20,
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF60C03D),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Dia $diaSelecionado',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        IconButton(
          onPressed: hasNext ? onNext : null,
          icon: const Icon(Icons.chevron_right),
          style: IconButton.styleFrom(
            backgroundColor: hasNext ? Colors.white : Colors.grey[100],
            foregroundColor: hasNext ? Colors.black87 : Colors.grey[400],
          ),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          iconSize: 20,
        ),
      ],
    );
  }
}
