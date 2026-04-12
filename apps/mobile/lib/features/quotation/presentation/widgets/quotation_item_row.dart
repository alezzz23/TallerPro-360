import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/quotation_models.dart';

class QuotationItemRow extends StatelessWidget {
  const QuotationItemRow({super.key, required this.item});

  final QuotationItemModel item;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.descripcion,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (item.partId != null)
                  Text(
                    'Repuesto incluido',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'MO: ₡ ${fmt.format(item.manoObra)}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey[700]),
              ),
              Text(
                'Rep: ₡ ${fmt.format(item.costoRepuesto)}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey[700]),
              ),
              Text(
                '₡ ${fmt.format(item.precioFinal)}',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
