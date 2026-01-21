import 'package:flutter/material.dart';

class MetaProgressBar extends StatelessWidget {
  final double percentual;
  final Color color;
  final double height;

  const MetaProgressBar({
    super.key,
    required this.percentual,
    required this.color,
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) {
    final clampedPercentual = percentual.clamp(0.0, 100.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${percentual.toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: clampedPercentual / 100,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
