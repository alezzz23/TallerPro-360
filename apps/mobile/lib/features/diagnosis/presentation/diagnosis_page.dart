import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../application/diagnosis_providers.dart';
import 'widgets/finding_card.dart';
import 'widgets/finding_form_sheet.dart';

class DiagnosisPage extends ConsumerWidget {
  const DiagnosisPage({super.key, required this.orderId});

  final String orderId;

  Future<void> _openCreateSheet(BuildContext context, WidgetRef ref) async {
    final controller =
        ref.read(diagnosisControllerProvider(orderId).notifier);

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) {
        final isSaving = ref.watch(diagnosisControllerProvider(orderId)
            .select((s) => s.isSaving));
        return FindingFormSheet(
          isSaving: isSaving,
          onCreate: ({
            required motivoIngreso,
            descripcion,
            tiempoEstimado,
            esHallazgoAdicional = false,
            esCriticoSeguridad = false,
          }) =>
              controller.createFinding(
            motivoIngreso: motivoIngreso,
            descripcion: descripcion,
            tiempoEstimado: tiempoEstimado,
            esHallazgoAdicional: esHallazgoAdicional,
            esCriticoSeguridad: esCriticoSeguridad,
          ),
          onEdit: ({descripcion, tiempoEstimado, esCriticoSeguridad}) async =>
              false,
          onAddPart: ({
            required nombre,
            required origen,
            required costo,
            required margen,
            proveedor,
          }) async =>
              false,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(diagnosisControllerProvider(orderId));
    final controller =
        ref.read(diagnosisControllerProvider(orderId).notifier);

    // Show snackbar on error
    ref.listen(
      diagnosisControllerProvider(orderId).select((s) => s.errorMessage),
      (_, error) {
        if (error != null && context.mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(error),
                backgroundColor: AppColors.statusRejected,
                action: SnackBarAction(
                  label: 'OK',
                  textColor: Colors.white,
                  onPressed: controller.clearError,
                ),
              ),
            );
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Diagnóstico — Orden #${orderId.substring(0, 8).toUpperCase()}'),
        actions: [
          if (state.isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh_outlined),
              tooltip: 'Recargar hallazgos',
              onPressed: controller.reload,
            ),
        ],
      ),
      body: state.findings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, __) => _ErrorBanner(
          message: error.toString(),
          onRetry: controller.reload,
        ),
        data: (findings) => findings.isEmpty
            ? _EmptyState(
                onAddFinding: () => _openCreateSheet(context, ref),
              )
            : RefreshIndicator(
                onRefresh: controller.reload,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: findings.length,
                  itemBuilder: (context, index) {
                    final finding = findings[index];
                    final isExpanded =
                        state.expandedCards[finding.id] ?? false;
                    final isUploadingPhoto =
                        state.uploadingPhotoForFindingId == finding.id;

                    return FindingCard(
                      finding: finding,
                      isExpanded: isExpanded,
                      isUploadingPhoto: isUploadingPhoto,
                      technicians: state.technicians,
                      techniciansLoaded: state.techniciansLoaded,
                      isSaving: state.isSaving,
                      onToggleExpanded: () =>
                          controller.toggleExpanded(finding.id),
                      onEdit: ({
                        descripcion,
                        tiempoEstimado,
                        esCriticoSeguridad,
                      }) =>
                          controller.updateFinding(
                        finding.id,
                        descripcion: descripcion,
                        tiempoEstimado: tiempoEstimado,
                        esCriticoSeguridad: esCriticoSeguridad,
                      ),
                      onAddPhoto: (File file) =>
                          controller.uploadAndAddPhoto(finding.id, file),
                      onAddPart: ({
                        required nombre,
                        required origen,
                        required costo,
                        required margen,
                        proveedor,
                      }) =>
                          controller.addPart(
                        finding.id,
                        nombre: nombre,
                        origen: origen,
                        costo: costo,
                        margen: margen,
                        proveedor: proveedor,
                      ),
                      onLoadTechnicians: controller.loadTechnicians,
                      onReassign: (technicianId) => controller.updateFinding(
                        finding.id,
                        technicianId: technicianId,
                      ),
                    );
                  },
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateSheet(context, ref),
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Reportar Hallazgo Adicional'),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.statusRejected),
            const SizedBox(height: 16),
            Text(
              'No se pudieron cargar los hallazgos',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAddFinding});

  final VoidCallback onAddFinding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Sin hallazgos aún',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Reporta el primer hallazgo técnico de esta orden.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAddFinding,
              icon: const Icon(Icons.add),
              label: const Text('Reportar Hallazgo Adicional'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
