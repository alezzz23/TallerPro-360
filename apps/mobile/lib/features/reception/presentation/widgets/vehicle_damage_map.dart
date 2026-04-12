import 'package:flutter/material.dart';

import '../../domain/reception_models.dart';

class DamageZoneSpec {
  const DamageZoneSpec({
    required this.key,
    required this.label,
    required this.alignment,
    required this.widthFactor,
    required this.heightFactor,
  });

  final String key;
  final String label;
  final Alignment alignment;
  final double widthFactor;
  final double heightFactor;
}

const vehicleDamageZones = <DamageZoneSpec>[
  DamageZoneSpec(
    key: 'frontal',
    label: 'Frontal',
    alignment: Alignment(0, -0.9),
    widthFactor: 0.26,
    heightFactor: 0.12,
  ),
  DamageZoneSpec(
    key: 'capot',
    label: 'Capot',
    alignment: Alignment(0, -0.56),
    widthFactor: 0.34,
    heightFactor: 0.14,
  ),
  DamageZoneSpec(
    key: 'parabrisas',
    label: 'Parabrisas',
    alignment: Alignment(0, -0.3),
    widthFactor: 0.32,
    heightFactor: 0.12,
  ),
  DamageZoneSpec(
    key: 'techo',
    label: 'Techo',
    alignment: Alignment(0, 0),
    widthFactor: 0.34,
    heightFactor: 0.18,
  ),
  DamageZoneSpec(
    key: 'lateral_izquierdo',
    label: 'Lateral izq.',
    alignment: Alignment(-0.86, 0),
    widthFactor: 0.24,
    heightFactor: 0.38,
  ),
  DamageZoneSpec(
    key: 'lateral_derecho',
    label: 'Lateral der.',
    alignment: Alignment(0.86, 0),
    widthFactor: 0.24,
    heightFactor: 0.38,
  ),
  DamageZoneSpec(
    key: 'baul',
    label: 'Baul',
    alignment: Alignment(0, 0.52),
    widthFactor: 0.34,
    heightFactor: 0.14,
  ),
  DamageZoneSpec(
    key: 'trasero',
    label: 'Trasero',
    alignment: Alignment(0, 0.9),
    widthFactor: 0.26,
    heightFactor: 0.12,
  ),
];

class VehicleDamageMap extends StatelessWidget {
  const VehicleDamageMap({
    super.key,
    required this.damages,
    required this.onZoneTap,
  });

  final List<ReceptionDamageDraft> damages;
  final ValueChanged<DamageZoneSpec> onZoneTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final counts = <String, int>{};
    for (final damage in damages) {
      counts.update(damage.zoneKey, (value) => value + 1, ifAbsent: () => 1);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return Stack(
          children: [
            CustomPaint(
              size: Size(width, height),
              painter: _VehicleSilhouettePainter(
                bodyColor: colorScheme.surfaceContainerHighest,
                strokeColor: colorScheme.primary.withValues(alpha: 0.5),
                accentColor: colorScheme.primary.withValues(alpha: 0.12),
              ),
            ),
            for (final zone in vehicleDamageZones)
              _DamageZoneButton(
                spec: zone,
                width: width,
                height: height,
                count: counts[zone.key] ?? 0,
                onTap: () => onZoneTap(zone),
              ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Toca una zona para registrar un dano visible',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DamageZoneButton extends StatelessWidget {
  const _DamageZoneButton({
    required this.spec,
    required this.width,
    required this.height,
    required this.count,
    required this.onTap,
  });

  final DamageZoneSpec spec;
  final double width;
  final double height;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasDamage = count > 0;
    final badgeColor = hasDamage ? colorScheme.error : colorScheme.primary;
    final left = (spec.alignment.x + 1) / 2 * width - (width * spec.widthFactor) / 2;
    final top = (spec.alignment.y + 1) / 2 * height - (height * spec.heightFactor) / 2;

    return Positioned(
      left: left,
      top: top,
      width: width * spec.widthFactor,
      height: height * spec.heightFactor,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: hasDamage ? 0.16 : 0.1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: badgeColor.withValues(alpha: hasDamage ? 0.75 : 0.35),
              ),
              boxShadow: hasDamage
                  ? [
                      BoxShadow(
                        color: badgeColor.withValues(alpha: 0.16),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        spec.label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: badgeColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (hasDamage) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$count',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onError,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VehicleSilhouettePainter extends CustomPainter {
  const _VehicleSilhouettePainter({
    required this.bodyColor,
    required this.strokeColor,
    required this.accentColor,
  });

  final Color bodyColor;
  final Color strokeColor;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final accent = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width * 0.42,
        height: size.height * 0.62,
      ),
      const Radius.circular(38),
    );
    final hoodRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.22),
        width: size.width * 0.32,
        height: size.height * 0.16,
      ),
      const Radius.circular(32),
    );
    final trunkRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.78),
        width: size.width * 0.32,
        height: size.height * 0.16,
      ),
      const Radius.circular(32),
    );

    canvas.drawRRect(bodyRect, paint);
    canvas.drawRRect(bodyRect, stroke);
    canvas.drawRRect(hoodRect, paint);
    canvas.drawRRect(hoodRect, stroke);
    canvas.drawRRect(trunkRect, paint);
    canvas.drawRRect(trunkRect, stroke);

    final cabinRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width * 0.28,
        height: size.height * 0.3,
      ),
      const Radius.circular(24),
    );
    canvas.drawRRect(cabinRect, accent);
    canvas.drawRRect(cabinRect, stroke);

    final wheelPaint = Paint()..color = strokeColor.withValues(alpha: 0.9);
    for (final center in [
      Offset(size.width * 0.28, size.height * 0.32),
      Offset(size.width * 0.72, size.height * 0.32),
      Offset(size.width * 0.28, size.height * 0.68),
      Offset(size.width * 0.72, size.height * 0.68),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: center, width: size.width * 0.09, height: size.height * 0.16),
          const Radius.circular(18),
        ),
        wheelPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VehicleSilhouettePainter oldDelegate) {
    return oldDelegate.bodyColor != bodyColor ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.accentColor != accentColor;
  }
}