import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/diagnosis_models.dart';
import '../widgets/finding_form_sheet.dart';
import '../widgets/part_tile.dart';
import '../widgets/photo_gallery_widget.dart';

class FindingCard extends ConsumerWidget {
  const FindingCard({
    super.key,
    required this.finding,
    required this.isExpanded,
    required this.isUploadingPhoto,
    required this.technicians,
    required this.techniciansLoaded,
    required this.isSaving,
    required this.onToggleExpanded,
    required this.onEdit,
    required this.onAddPhoto,
    required this.onAddPart,
    required this.onLoadTechnicians,
    required this.onReassign,
  });

  final DiagnosisFinding finding;
  final bool isExpanded;
  final bool isUploadingPhoto;
  final List<DiagnosisTechnician> technicians;
  final bool techniciansLoaded;
  final bool isSaving;

  final VoidCallback onToggleExpanded;
  final Future<bool> Function({
    String? descripcion,
    double? tiempoEstimado,
    bool? esCriticoSeguridad,
  }) onEdit;
  final Future<void> Function(File file) onAddPhoto;
  final Future<bool> Function({
    required String nombre,
    required String origen,
    required double costo,
    required double margen,
    String? proveedor,
  }) onAddPart;
  final Future<void> Function() onLoadTechnicians;
  final Future<void> Function(String technicianId) onReassign;

  String _technicianName() {
    if (technicians.isEmpty) return 'Técnico asignado';
    final match = technicians
        .where((t) => t.id == finding.technicianId)
        .firstOrNull;
    return match?.nombre ?? 'Técnico asignado';
  }

  Future<void> _openEditSheet(BuildContext context) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => FindingFormSheet(
        finding: finding,
        isSaving: isSaving,
        onCreate: ({
          required motivoIngreso,
          descripcion,
          tiempoEstimado,
          esHallazgoAdicional = false,
          esCriticoSeguridad = false,
        }) async =>
            false, // not called in edit mode
        onEdit: onEdit,
        onAddPart: onAddPart,
      ),
    );
  }

  Future<void> _openReassignDialog(BuildContext context) async {
    await onLoadTechnicians();

    if (!context.mounted) return;

    String? selected = finding.technicianId;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Reasignar hallazgo'),
          content: SizedBox(
            width: double.maxFinite,
            child: technicians.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : ListView(
                    shrinkWrap: true,
                    children: technicians
                        .map(
                          (t) => RadioListTile<String>(
                            value: t.id,
                            groupValue: selected,
                            title: Text(t.nombre),
                            onChanged: (v) => setState(() => selected = v),
                            activeColor: AppColors.primary,
                            dense: true,
                          ),
                        )
                        .toList(),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: selected == null || selected == finding.technicianId
                  ? null
                  : () {
                      Navigator.pop(ctx);
                      onReassign(selected!);
                    },
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          InkWell(
            onTap: onToggleExpanded,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Additional finding badge
                            if (finding.esHallazgoAdicional) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'ADICIONAL',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Expanded(
                              child: Text(
                                finding.motivoIngreso,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (finding.esCriticoSeguridad) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  size: 14,
                                  color: AppColors.statusRejected),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  finding.safetyWarning ??
                                      'Crítico de seguridad',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.statusRejected,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 4),
                        // Stats row
                        Row(
                          children: [
                            _StatChip(
                              icon: Icons.access_time,
                              label: finding.tiempoEstimado != null
                                  ? '${finding.tiempoEstimado!.toStringAsFixed(1)} h'
                                  : '— h',
                            ),
                            const SizedBox(width: 8),
                            _StatChip(
                              icon: Icons.build_outlined,
                              label: '${finding.parts.length} repuesto(s)',
                            ),
                            const SizedBox(width: 8),
                            _StatChip(
                              icon: Icons.photo_outlined,
                              label: '${finding.fotos.length} foto(s)',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 4),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            size: 20, color: AppColors.primary),
                        tooltip: 'Editar hallazgo',
                        onPressed: () => _openEditSheet(context),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expandable body
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: _ExpandedBody(
              finding: finding,
              isUploadingPhoto: isUploadingPhoto,
              technicianName: _technicianName(),
              onAddPhoto: onAddPhoto,
              onReassign: () => _openReassignDialog(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandedBody extends StatelessWidget {
  const _ExpandedBody({
    required this.finding,
    required this.isUploadingPhoto,
    required this.technicianName,
    required this.onAddPhoto,
    required this.onReassign,
  });

  final DiagnosisFinding finding;
  final bool isUploadingPhoto;
  final String technicianName;
  final Future<void> Function(File file) onAddPhoto;
  final VoidCallback onReassign;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(),

          // Descripción
          if (finding.descripcion != null &&
              finding.descripcion!.isNotEmpty) ...[
            Text(
              'Descripción',
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(finding.descripcion!, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
          ],

          // Técnico asignado
          Row(
            children: [
              const Icon(Icons.person_outline,
                  size: 16, color: AppColors.secondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Técnico: $technicianName',
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton.icon(
                onPressed: onReassign,
                icon: const Icon(Icons.swap_horiz, size: 16),
                label: const Text('Reasignar'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),

          // Parts
          if (finding.parts.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Repuestos',
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            ...finding.parts.map((p) => PartTile(part: p)),
          ],

          // Photos
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fotos (${finding.fotos.length}/${PhotoGalleryWidget.maxPhotos})',
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          PhotoGalleryWidget(
            photos: finding.fotos,
            isUploading: isUploadingPhoto,
            onAddPhoto: onAddPhoto,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.grey.shade600),
        const SizedBox(width: 3),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
