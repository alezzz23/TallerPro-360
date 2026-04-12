import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../domain/billing_models.dart';

/// Reusable slider widget for one NPS category (1–10).
class NpsScoreSlider extends StatelessWidget {
  const NpsScoreSlider({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.isNpsSlider = false,
  });

  final String label;
  final int value;
  final bool isNpsSlider;
  final ValueChanged<int> onChanged;

  Color _activeColor() {
    if (!isNpsSlider) return AppColors.primary;
    if (value <= 6) return Colors.red.shade600;
    if (value <= 8) return Colors.amber.shade700;
    return Colors.green.shade600;
  }

  @override
  Widget build(BuildContext context) {
    final color = _activeColor();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        )),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: color,
                    thumbColor: color,
                    overlayColor: color.withAlpha(30),
                    inactiveTrackColor: color.withAlpha(60),
                  ),
                  child: Slider(
                    value: value.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    onChanged: (v) => onChanged(v.round()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '$value',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact score display chip used in completed NPS view.
class NpsScoreChip extends StatelessWidget {
  const NpsScoreChip({
    super.key,
    required this.label,
    required this.value,
    this.isNps = false,
  });

  final String label;
  final int value;
  final bool isNps;

  Color _color() {
    if (!isNps) return AppColors.primary;
    if (value <= 6) return Colors.red.shade600;
    if (value <= 8) return Colors.amber.shade700;
    return Colors.green.shade600;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style:
                Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11)),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _color().withAlpha(20),
            border: Border.all(color: _color().withAlpha(100)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$value/10',
            style: TextStyle(
              color: _color(),
              fontWeight: FontWeight.bold,
              fontSize: isNps ? 18 : 14,
            ),
          ),
        ),
      ],
    );
  }
}

/// Payment method radio tile.
class MetodoPagoTile extends StatelessWidget {
  const MetodoPagoTile({
    super.key,
    required this.metodo,
    required this.selected,
    required this.onTap,
  });

  final MetodoPago metodo;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          border: Border.all(
            color: selected ? AppColors.primary : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 18,
              color: selected ? Colors.white : Colors.grey.shade500,
            ),
            const SizedBox(width: 6),
            Text(
              metodo.label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.onSurface,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
