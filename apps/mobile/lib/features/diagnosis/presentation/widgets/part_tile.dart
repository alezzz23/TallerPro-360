import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/diagnosis_models.dart';

class PartTile extends StatelessWidget {
  const PartTile({super.key, required this.part});

  final DiagnosisPart part;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: part.origen == 'STOCK'
                  ? AppColors.secondary.withValues(alpha: 0.15)
                  : AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              part.origen,
              style: textTheme.labelSmall?.copyWith(
                color: part.origen == 'STOCK'
                    ? AppColors.secondary
                    : AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              part.nombre,
              style: textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${part.precioVenta.toStringAsFixed(2)}',
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              if (part.proveedor != null && part.proveedor!.isNotEmpty)
                Text(
                  part.proveedor!,
                  style: textTheme.labelSmall
                      ?.copyWith(color: Colors.grey.shade600),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
