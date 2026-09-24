import 'package:flutter/material.dart';

import '../../format.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key, required this.label, required this.amountPaise, required this.color});

  final String label;
  final int amountPaise;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        color: color.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(
                Fmt.rupees(amountPaise),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
