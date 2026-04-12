import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../shared/widgets/loading_widget.dart';
import '../application/reception_controller.dart';
import '../application/reception_providers.dart';
import '../domain/reception_models.dart';
import '../domain/reception_state.dart';
import '../domain/reception_validator.dart';
import 'widgets/vehicle_damage_map.dart';

class ReceptionPage extends ConsumerStatefulWidget {
  const ReceptionPage({super.key, this.initialOrderId});

  final String? initialOrderId;

  @override
  ConsumerState<ReceptionPage> createState() => _ReceptionPageState();
}

class _ReceptionPageState extends ConsumerState<ReceptionPage> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  final _speech = stt.SpeechToText();

  late final TextEditingController _vehicleLookupController;
  late final TextEditingController _customerLookupController;
  late final TextEditingController _marcaController;
  late final TextEditingController _modeloController;
  late final TextEditingController _placaController;
  late final TextEditingController _vinController;
  late final TextEditingController _kilometrajeController;
  late final TextEditingController _nombreController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _emailController;
  late final TextEditingController _whatsappController;
  late final TextEditingController _direccionController;
  late final TextEditingController _motivoController;
  late final TextEditingController _documentosController;
  late final SignatureController _signatureController;

  bool _speechReady = false;
  String _dictationSeed = '';

    AutoDisposeStateNotifierProvider<ReceptionController, ReceptionState>
      get _provider =>
      receptionControllerProvider(widget.initialOrderId);

  @override
  void initState() {
    super.initState();
    _vehicleLookupController = TextEditingController();
    _customerLookupController = TextEditingController();
    _marcaController = TextEditingController();
    _modeloController = TextEditingController();
    _placaController = TextEditingController();
    _vinController = TextEditingController();
    _kilometrajeController = TextEditingController();
    _nombreController = TextEditingController();
    _telefonoController = TextEditingController();
    _emailController = TextEditingController();
    _whatsappController = TextEditingController();
    _direccionController = TextEditingController();
    _motivoController = TextEditingController();
    _documentosController = TextEditingController();
    _signatureController = SignatureController(
      penStrokeWidth: 2.4,
      penColor: Colors.black87,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _vehicleLookupController.dispose();
    _customerLookupController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    _placaController.dispose();
    _vinController.dispose();
    _kilometrajeController.dispose();
    _nombreController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _whatsappController.dispose();
    _direccionController.dispose();
    _motivoController.dispose();
    _documentosController.dispose();
    _signatureController.dispose();
    _speech.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ReceptionState>(_provider, (previous, next) {
      _syncControllers(next);
      if (previous?.successMessage != next.successMessage &&
          next.successMessage != null) {
        _showSnackBar(next.successMessage!);
        ref.read(_provider.notifier).clearFeedback();
      }
    });

    final state = ref.watch(_provider);
    final controller = ref.read(_provider.notifier);
    final theme = Theme.of(context);
    final canEditLockedOrderFields = state.orderId == null;
    final hasPendingSignature = _signatureController.isNotEmpty;
    final draftIssues = ReceptionValidator.draftIssues(state);
    final advanceIssues = ReceptionValidator.advanceIssues(
      state,
      hasPendingSignature: hasPendingSignature,
    );

    if (state.isInitialLoading) {
      return const Scaffold(
        body: SafeArea(
          child: LoadingWidget(message: 'Cargando recepcion activa...'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recepcion activa'),
        actions: [
          if (state.orderId != null)
            IconButton(
              tooltip: 'Recargar recepcion',
              onPressed: state.isBusy ? null : controller.reload,
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
      bottomNavigationBar: _ActionBar(
        state: state,
        draftIssues: draftIssues,
        advanceIssues: advanceIssues,
        hasPendingSignature: hasPendingSignature,
        onSaveDraft: state.isSubmitting || !state.canManageReception || draftIssues.isNotEmpty
            ? null
            : () => _handlePersist(advance: false),
        onAdvance: state.isSubmitting || !state.canManageReception || advanceIssues.isNotEmpty
            ? null
            : () => _handlePersist(advance: true),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.reload,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 180),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1080),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HeroCard(
                        orderId: state.orderId,
                        photoCount: state.capturedPerimeterCount,
                        damagesCount: state.damages.length,
                        hasSignature:
                            state.hasStoredSignature || hasPendingSignature,
                        progressMessage: state.progressMessage,
                      ),
                      const SizedBox(height: 16),
                      if (!state.canManageReception)
                        _InlineBanner(
                          color: theme.colorScheme.errorContainer,
                          icon: Icons.lock_outline_rounded,
                          title: 'Solo asesor o jefatura puede registrar recepcion',
                          message:
                              'Puedes revisar la informacion, pero los cambios no se podran guardar con tu rol actual.',
                        ),
                      if (state.orderId != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: _InlineBanner(
                            color: theme.colorScheme.primaryContainer,
                            icon: Icons.info_outline_rounded,
                            title: 'Orden ya creada',
                            message:
                                'El kilometraje y el motivo quedan fijados al crear la OS. Completa checklist, danos, fotos y firma para avanzar.',
                          ),
                        ),
                      if (state.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: _InlineBanner(
                            color: theme.colorScheme.errorContainer,
                            icon: Icons.error_outline_rounded,
                            title: 'No se pudo completar la recepcion',
                            message: state.errorMessage!,
                          ),
                        ),
                      const SizedBox(height: 16),
                      Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _SectionCard(
                              title: 'Vehiculo y cliente',
                              subtitle:
                                  'Busca primero por placa o VIN para reutilizar historial y autocompletar el propietario.',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextFormField(
                                    controller: _vehicleLookupController,
                                    textInputAction: TextInputAction.search,
                                    decoration: InputDecoration(
                                      labelText: 'Buscar placa o VIN',
                                      hintText: 'ABC123 o 1HGCM82633A...',
                                      prefixIcon:
                                          const Icon(Icons.directions_car_filled_rounded),
                                      suffixIcon: state.isVehicleLookupLoading
                                          ? const Padding(
                                              padding: EdgeInsets.all(12),
                                              child: SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(strokeWidth: 2),
                                              ),
                                            )
                                          : (state.vehicleLookupQuery.isEmpty
                                              ? null
                                              : IconButton(
                                                  tooltip: 'Limpiar busqueda',
                                                  onPressed: () {
                                                    _vehicleLookupController.clear();
                                                    controller.updateVehicleLookupQuery('');
                                                  },
                                                  icon: const Icon(Icons.close_rounded),
                                                )),
                                    ),
                                    onChanged: controller.updateVehicleLookupQuery,
                                  ),
                                  if (state.vehicle.isExisting)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: _SelectionChip(
                                        icon: Icons.history_toggle_off_rounded,
                                        label:
                                            'Vehiculo existente vinculado: ${state.vehicle.placa}',
                                        actionLabel: 'Registrar como nuevo',
                                        onAction: controller.detachVehicleSelection,
                                      ),
                                    ),
                                  if (state.vehicleSuggestions.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: _SuggestionList(
                                        children: [
                                          for (final suggestion in state.vehicleSuggestions)
                                            _SuggestionTile(
                                              icon:
                                                  Icons.directions_car_filled_outlined,
                                              title:
                                                  '${suggestion.placa} · ${suggestion.vehicleLabel}',
                                              subtitle:
                                                  '${suggestion.customerName}${suggestion.customerContact.isEmpty ? '' : ' · ${suggestion.customerContact}'}${suggestion.vin.isEmpty ? '' : ' · VIN ${suggestion.vin}'}',
                                              onTap: () => controller
                                                  .selectVehicleSuggestion(suggestion),
                                            ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 20),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final twoColumns = constraints.maxWidth >= 820;
                                      if (!twoColumns) {
                                        return Column(
                                          children: [
                                            _buildVehicleFields(
                                              controller: controller,
                                              canEditLockedOrderFields:
                                                  canEditLockedOrderFields,
                                            ),
                                            const SizedBox(height: 16),
                                            _buildCustomerFields(controller),
                                          ],
                                        );
                                      }
                                      return Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: _buildVehicleFields(
                                              controller: controller,
                                              canEditLockedOrderFields:
                                                  canEditLockedOrderFields,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: _buildCustomerFields(controller),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _SectionCard(
                              title: 'Motivo de visita',
                              subtitle:
                                  'Usa dictado por voz para capturar rapido la queja principal del cliente.',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextFormField(
                                    controller: _motivoController,
                                    minLines: 3,
                                    maxLines: 5,
                                    enabled: canEditLockedOrderFields,
                                    decoration: InputDecoration(
                                      labelText: 'Motivo reportado',
                                      hintText:
                                          'Ej. Golpeteo en suspension delantera y testigo de frenos encendido.',
                                      prefixIcon: const Padding(
                                        padding: EdgeInsets.only(bottom: 64),
                                        child: Icon(Icons.record_voice_over_rounded),
                                      ),
                                      suffixIcon: IconButton(
                                        tooltip: state.isListening
                                            ? 'Detener dictado'
                                            : 'Iniciar dictado',
                                        onPressed: canEditLockedOrderFields
                                            ? _toggleDictation
                                            : null,
                                        icon: Icon(
                                          state.isListening
                                              ? Icons.stop_circle_outlined
                                              : Icons.mic_none_rounded,
                                        ),
                                      ),
                                    ),
                                    validator: (value) {
                                      if ((value ?? '').trim().isEmpty) {
                                        return 'Describe el motivo de visita.';
                                      }
                                      return null;
                                    },
                                    onChanged: controller.setMotivoVisita,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    state.isListening
                                        ? 'Escuchando... toca el microfono para detener.'
                                        : 'Consejo: guarda borrador si la conexion esta inestable antes de mover la orden.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _SectionCard(
                              title: 'Checklist de recepcion',
                              subtitle:
                                  'Documenta fluidos, pertenencias y documentos entregados para blindaje legal.',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _FluidSelector(
                                    label: 'Aceite',
                                    value: state.checklist.nivelAceite,
                                    onChanged: (value) => controller.updateChecklist(
                                      nivelAceite: value,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _FluidSelector(
                                    label: 'Refrigerante',
                                    value: state.checklist.nivelRefrigerante,
                                    onChanged: (value) => controller.updateChecklist(
                                      nivelRefrigerante: value,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _FluidSelector(
                                    label: 'Liquido de frenos',
                                    value: state.checklist.nivelFrenos,
                                    onChanged: (value) => controller.updateChecklist(
                                      nivelFrenos: value,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'Pertenencias y seguridad',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      _BooleanChip(
                                        label: 'Llanta de repuesto',
                                        selected: state.checklist.llantaRepuesto,
                                        icon: Icons.tire_repair_rounded,
                                        onSelected: (value) => controller.updateChecklist(
                                          llantaRepuesto: value,
                                        ),
                                      ),
                                      _BooleanChip(
                                        label: 'Kit de carretera',
                                        selected: state.checklist.kitCarretera,
                                        icon: Icons.car_rental_rounded,
                                        onSelected: (value) => controller.updateChecklist(
                                          kitCarretera: value,
                                        ),
                                      ),
                                      _BooleanChip(
                                        label: 'Botiquin',
                                        selected: state.checklist.botiquin,
                                        icon: Icons.medical_services_outlined,
                                        onSelected: (value) => controller.updateChecklist(
                                          botiquin: value,
                                        ),
                                      ),
                                      _BooleanChip(
                                        label: 'Extintor',
                                        selected: state.checklist.extintor,
                                        icon: Icons.local_fire_department_outlined,
                                        onSelected: (value) => controller.updateChecklist(
                                          extintor: value,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  TextFormField(
                                    controller: _documentosController,
                                    minLines: 2,
                                    maxLines: 3,
                                    decoration: const InputDecoration(
                                      labelText: 'Documentos recibidos',
                                      hintText:
                                          'Ej. Tarjeta de propiedad, SOAT, poliza. Escribe "ninguno" si aplica.',
                                      prefixIcon: Padding(
                                        padding: EdgeInsets.only(bottom: 44),
                                        child: Icon(Icons.description_outlined),
                                      ),
                                    ),
                                    validator: (value) {
                                      if ((value ?? '').trim().isEmpty) {
                                        return 'Registra los documentos recibidos o escribe "ninguno".';
                                      }
                                      return null;
                                    },
                                    onChanged: (value) => controller.updateChecklist(
                                      documentosRecibidos: value,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      for (final tag in const [
                                        'Tarjeta de propiedad',
                                        'SOAT',
                                        'Seguro',
                                        'Ninguno',
                                      ])
                                        ActionChip(
                                          label: Text(tag),
                                          onPressed: () {
                                            final current = _documentosController.text.trim();
                                            final next = current.isEmpty
                                                ? tag
                                                : '$current, $tag';
                                            _documentosController.text = next;
                                            _documentosController.selection =
                                                TextSelection.collapsed(
                                              offset: next.length,
                                            );
                                            controller.updateChecklist(
                                              documentosRecibidos: next,
                                            );
                                          },
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _SectionCard(
                              title: 'Danos preexistentes',
                              subtitle:
                                  'Marca visualmente el punto afectado y agrega una nota corta por cada hallazgo.',
                              child: Column(
                                children: [
                                  AspectRatio(
                                    aspectRatio: 1.12,
                                    child: VehicleDamageMap(
                                      damages: state.damages,
                                      onZoneTap: _openDamageSheet,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  if (state.damages.isEmpty)
                                    Text(
                                      'Sin danos registrados. Si el vehiculo entra sin novedad, deja este bloque vacio.',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    )
                                  else
                                    Column(
                                      children: [
                                        for (final damage in state.damages)
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 10),
                                            child: _DamageTile(
                                              damage: damage,
                                              onRecognitionChanged:
                                                  damage.isPersisted
                                                      ? null
                                                      : (value) => controller
                                                          .updateDamageRecognition(
                                                        damage.localId,
                                                        value,
                                                      ),
                                              onRemove: damage.isPersisted
                                                  ? null
                                                  : () => controller
                                                      .removeDamage(damage.localId),
                                            ),
                                          ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _SectionCard(
                              title: 'Fotos de perimetro',
                              subtitle:
                                  'Las 4 vistas son obligatorias para avanzar. Puedes usar camara o galeria.',
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final tileWidth = constraints.maxWidth > 700
                                      ? (constraints.maxWidth - 12) / 2
                                      : constraints.maxWidth;
                                  return Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: [
                                      for (final angle in ReceptionPerimeterAngle.values)
                                        SizedBox(
                                          width: tileWidth,
                                          child: _PerimeterPhotoTile(
                                            angle: angle,
                                            photo: state.photoFor(angle),
                                            onCapture: () => _pickPerimeterPhoto(angle),
                                            onClear: state.photoFor(angle).remoteUrl != null
                                                ? null
                                                : () => controller.clearPerimeterPhoto(angle),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            _SectionCard(
                              title: 'Firma del cliente',
                              subtitle:
                                  'La firma se carga al nuevo endpoint y habilita el avance seguro de la orden.',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (state.signatureUrl != null &&
                                      state.signatureUrl!.isNotEmpty &&
                                      _signatureController.isEmpty)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color:
                                            theme.colorScheme.primaryContainer.withValues(alpha: 0.65),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.verified_rounded),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              'Ya existe una firma guardada para esta recepcion. Si dibujas una nueva, la reemplazaremos.',
                                              style: theme.textTheme.bodySmall,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  Container(
                                    height: 220,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: theme.colorScheme.outlineVariant,
                                      ),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Signature(
                                      controller: _signatureController,
                                      backgroundColor: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          _signatureController.clear();
                                          setState(() {});
                                        },
                                        icon: const Icon(Icons.restart_alt_rounded),
                                        label: const Text('Limpiar firma'),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          hasPendingSignature ||
                                                  (state.signatureUrl?.isNotEmpty ?? false)
                                              ? 'Firma lista para guardar.'
                                              : 'La firma es obligatoria para enviar la orden a diagnostico.',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleFields({
    required dynamic controller,
    required bool canEditLockedOrderFields,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _marcaController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Marca',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
          validator: (value) {
            if ((value ?? '').trim().isEmpty) {
              return 'Ingresa la marca.';
            }
            return null;
          },
          onChanged: (value) => controller.updateVehicleDraft(marca: value),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _modeloController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Modelo',
            prefixIcon: Icon(Icons.view_in_ar_outlined),
          ),
          validator: (value) {
            if ((value ?? '').trim().isEmpty) {
              return 'Ingresa el modelo.';
            }
            return null;
          },
          onChanged: (value) => controller.updateVehicleDraft(modelo: value),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _placaController,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Placa',
            prefixIcon: Icon(Icons.confirmation_number_outlined),
          ),
          validator: (value) {
            if ((value ?? '').trim().isEmpty) {
              return 'Ingresa la placa.';
            }
            return null;
          },
          onChanged: (value) => controller.updateVehicleDraft(
            placa: value.toUpperCase(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _vinController,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'VIN',
            prefixIcon: Icon(Icons.pin_outlined),
          ),
          onChanged: (value) => controller.updateVehicleDraft(
            vin: value.toUpperCase(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _kilometrajeController,
          keyboardType: const TextInputType.numberWithOptions(),
          textInputAction: TextInputAction.next,
          enabled: canEditLockedOrderFields,
          decoration: const InputDecoration(
            labelText: 'Kilometraje',
            prefixIcon: Icon(Icons.speed_rounded),
          ),
          validator: (value) {
            final parsed = int.tryParse((value ?? '').trim());
            if (parsed == null || parsed <= 0) {
              return 'Ingresa un kilometraje valido.';
            }
            return null;
          },
          onChanged: (value) => controller.updateVehicleDraft(
            kilometraje: int.tryParse(value.trim()),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerFields(dynamic controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _customerLookupController,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            labelText: 'Buscar cliente existente',
            hintText: 'Nombre, telefono o WhatsApp',
            prefixIcon: const Icon(Icons.person_search_outlined),
            suffixIcon: ref.watch(_provider).isCustomerLookupLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : (_customerLookupController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpiar busqueda',
                        onPressed: () {
                          _customerLookupController.clear();
                          controller.updateCustomerLookupQuery('');
                        },
                        icon: const Icon(Icons.close_rounded),
                      )),
          ),
          onChanged: controller.updateCustomerLookupQuery,
        ),
        if (ref.watch(_provider).customer.isExisting)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _SelectionChip(
              icon: Icons.person_pin_circle_outlined,
              label:
                  'Cliente existente vinculado: ${ref.watch(_provider).customer.nombre}',
              actionLabel: 'Registrar como nuevo',
              onAction: controller.detachCustomerSelection,
            ),
          ),
        if (ref.watch(_provider).customerSuggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _SuggestionList(
              children: [
                for (final suggestion in ref.watch(_provider).customerSuggestions)
                  _SuggestionTile(
                    icon: Icons.person_outline_rounded,
                    title: suggestion.nombre,
                    subtitle:
                        [suggestion.contactLabel, suggestion.email]
                            .where((item) => item.isNotEmpty)
                            .join(' · '),
                    onTap: () => controller.selectCustomerSuggestion(suggestion),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _nombreController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Nombre del cliente',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
          validator: (value) {
            if ((value ?? '').trim().isEmpty) {
              return 'Ingresa el nombre del cliente.';
            }
            return null;
          },
          onChanged: (value) => controller.updateCustomerDraft(nombre: value),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _telefonoController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Telefono',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
          onChanged: (value) => controller.updateCustomerDraft(telefono: value),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _whatsappController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'WhatsApp',
            prefixIcon: Icon(Icons.chat_bubble_outline_rounded),
          ),
          onChanged: (value) => controller.updateCustomerDraft(whatsapp: value),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Correo',
            prefixIcon: Icon(Icons.alternate_email_rounded),
          ),
          onChanged: (value) => controller.updateCustomerDraft(email: value),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _direccionController,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Direccion',
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
          onChanged: (value) => controller.updateCustomerDraft(direccion: value),
        ),
      ],
    );
  }

  Future<void> _toggleDictation() async {
    final controller = ref.read(_provider.notifier);
    final state = ref.read(_provider);

    if (state.isListening) {
      await _speech.stop();
      _dictationSeed = '';
      controller.setListening(false);
      return;
    }

    if (!_speechReady) {
      _speechReady = await _speech.initialize(
        onStatus: (status) {
          if (!mounted) {
            return;
          }
          if (status == 'done' || status == 'notListening') {
            ref.read(_provider.notifier).setListening(false);
            _dictationSeed = '';
          }
        },
        onError: (error) {
          if (!mounted) {
            return;
          }
          ref.read(_provider.notifier).setListening(false);
          _dictationSeed = '';
          _showSnackBar('No se pudo iniciar el dictado: ${error.errorMsg}.');
        },
      );
    }

    if (!_speechReady) {
      _showSnackBar('El dictado por voz no esta disponible en este dispositivo.');
      return;
    }

    _dictationSeed = _motivoController.text.trim();
    await _speech.listen(
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
        cancelOnError: true,
      ),
      onResult: (result) {
        final transcript = result.recognizedWords.trim();
        final next = _dictationSeed.isEmpty
            ? transcript
            : transcript.isEmpty
                ? _dictationSeed
                : '$_dictationSeed. $transcript';
        _motivoController.value = TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: next.length),
        );
        ref.read(_provider.notifier).setMotivoVisita(next);
      },
    );
    controller.setListening(true);
  }

  Future<void> _pickPerimeterPhoto(ReceptionPerimeterAngle angle) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de galeria'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) {
      return;
    }

    final file = await _imagePicker.pickImage(
      source: source,
      imageQuality: 84,
      maxWidth: 1800,
    );
    if (file == null) {
      return;
    }

    ref.read(_provider.notifier).setPerimeterPhoto(angle, file.path);
  }

  Future<void> _openDamageSheet(DamageZoneSpec zone) async {
    final noteController = TextEditingController();
    var reconocido = true;

    final result = await showModalBottomSheet<_DamageDraftResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 18,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Registrar dano en ${zone.label.toLowerCase()}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Describe el detalle visible para que quede soportado en el ingreso.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  minLines: 3,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Nota del dano',
                    hintText: 'Ej. Rayon profundo y golpe leve sobre el borde.',
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: reconocido,
                  onChanged: (value) {
                    setModalState(() {
                      reconocido = value;
                    });
                  },
                  title: const Text('Cliente reconoce este dano'),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    final description = noteController.text.trim();
                    if (description.isEmpty) {
                      return;
                    }
                    Navigator.of(context).pop(
                      _DamageDraftResult(
                        description: description,
                        reconocidoPorCliente: reconocido,
                      ),
                    );
                  },
                  child: const Text('Agregar dano'),
                ),
              ],
            ),
          ),
        );
      },
    );

    noteController.dispose();
    if (result == null) {
      return;
    }
    ref.read(_provider.notifier).addDamage(
          zoneKey: zone.key,
          zoneLabel: zone.label,
          description: result.description,
          reconocidoPorCliente: result.reconocidoPorCliente,
        );
  }

  Future<void> _handlePersist({required bool advance}) async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    Uint8List? signatureBytes;
    if (_signatureController.isNotEmpty) {
      signatureBytes = await _signatureController.toPngBytes();
      if (signatureBytes == null) {
        _showSnackBar('No se pudo capturar la firma. Intenta dibujarla de nuevo.');
        return;
      }
    }

    final success = advance
        ? await ref.read(_provider.notifier).saveAndAdvance(
              signatureBytes: signatureBytes,
            )
        : await ref.read(_provider.notifier).saveDraft(
              signatureBytes: signatureBytes,
            );

    if (!mounted || !success) {
      return;
    }

    if (_signatureController.isNotEmpty) {
      _signatureController.clear();
      setState(() {});
    }

    if (advance) {
      context.goNamed('dashboard');
    }
  }

  void _syncControllers(ReceptionState state) {
    _syncText(_vehicleLookupController, state.vehicleLookupQuery);
    _syncText(_customerLookupController, state.customerLookupQuery);
    _syncText(_marcaController, state.vehicle.marca);
    _syncText(_modeloController, state.vehicle.modelo);
    _syncText(_placaController, state.vehicle.placa);
    _syncText(_vinController, state.vehicle.vin);
    _syncText(
      _kilometrajeController,
      state.vehicle.kilometraje?.toString() ?? '',
    );
    _syncText(_nombreController, state.customer.nombre);
    _syncText(_telefonoController, state.customer.telefono);
    _syncText(_emailController, state.customer.email);
    _syncText(_whatsappController, state.customer.whatsapp);
    _syncText(_direccionController, state.customer.direccion);
    _syncText(_motivoController, state.motivoVisita);
    _syncText(_documentosController, state.checklist.documentosRecibidos);
  }

  void _syncText(TextEditingController controller, String value) {
    if (controller.text == value) {
      return;
    }
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _showSnackBar(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.orderId,
    required this.photoCount,
    required this.damagesCount,
    required this.hasSignature,
    required this.progressMessage,
  });

  final String? orderId;
  final int photoCount;
  final int damagesCount;
  final bool hasSignature;
  final String? progressMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            Color.alphaBlend(
              theme.colorScheme.tertiary.withValues(alpha: 0.32),
              theme.colorScheme.secondary,
            ),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroPill(
                icon: Icons.receipt_long_rounded,
                label: orderId == null
                    ? 'Walk-in nuevo'
                  : 'OS ${orderId!.substring(0, 8).toUpperCase()}',
              ),
              _HeroPill(
                icon: Icons.photo_camera_back_outlined,
                label: '$photoCount/4 fotos',
              ),
              _HeroPill(
                icon: Icons.car_crash_outlined,
                label: '$damagesCount danos',
              ),
              _HeroPill(
                icon: hasSignature
                    ? Icons.verified_user_outlined
                    : Icons.draw_outlined,
                label: hasSignature ? 'Firma lista' : 'Firma pendiente',
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Recepcion activa con evidencia completa',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Captura datos clave, checklist legal, danos visibles, perimetro y firma en un solo flujo operativo.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.86),
              height: 1.45,
            ),
          ),
          if (progressMessage != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    progressMessage!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _InlineBanner extends StatelessWidget {
  const _InlineBanner({
    required this.color,
    required this.icon,
    required this.title,
    required this.message,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(message, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionChip extends StatelessWidget {
  const _SelectionChip({
    required this.icon,
    required this.label,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String label;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          TextButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _SuggestionList extends StatelessWidget {
  const _SuggestionList({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(children: children),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle.isEmpty ? null : Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _FluidSelector extends StatelessWidget {
  const _FluidSelector({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final ReceptionFluidLevel? value;
  final ValueChanged<ReceptionFluidLevel> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 10),
        SegmentedButton<ReceptionFluidLevel>(
          showSelectedIcon: false,
          segments: [
            for (final level in ReceptionFluidLevel.values)
              ButtonSegment<ReceptionFluidLevel>(
                value: level,
                label: Text(level.label),
              ),
          ],
          selected: value == null ? const {} : {value!},
          onSelectionChanged: (selection) {
            if (selection.isNotEmpty) {
              onChanged(selection.first);
            }
          },
        ),
      ],
    );
  }
}

class _BooleanChip extends StatelessWidget {
  const _BooleanChip({
    required this.label,
    required this.selected,
    required this.icon,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final IconData icon;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      onSelected: onSelected,
      avatar: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _DamageTile extends StatelessWidget {
  const _DamageTile({
    required this.damage,
    required this.onRecognitionChanged,
    required this.onRemove,
  });

  final ReceptionDamageDraft damage;
  final ValueChanged<bool>? onRecognitionChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  damage.zoneLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (damage.isPersisted)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Guardado',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (onRemove != null)
                IconButton(
                  tooltip: 'Quitar dano',
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
            ],
          ),
          Text(
            damage.description,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                damage.reconocidoPorCliente
                    ? Icons.verified_outlined
                    : Icons.warning_amber_rounded,
                size: 18,
                color: damage.reconocidoPorCliente
                    ? Colors.green.shade700
                    : theme.colorScheme.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  damage.reconocidoPorCliente
                      ? 'Cliente reconoce el dano.'
                      : 'Pendiente confirmar con el cliente.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              if (onRecognitionChanged != null)
                Switch.adaptive(
                  value: damage.reconocidoPorCliente,
                  onChanged: onRecognitionChanged,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PerimeterPhotoTile extends StatelessWidget {
  const _PerimeterPhotoTile({
    required this.angle,
    required this.photo,
    required this.onCapture,
    required this.onClear,
  });

  final ReceptionPerimeterAngle angle;
  final ReceptionPerimeterPhotoDraft photo;
  final VoidCallback onCapture;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget preview;
    if (photo.localPath != null && photo.localPath!.isNotEmpty) {
      preview = Image.file(
        File(photo.localPath!),
        fit: BoxFit.cover,
        width: double.infinity,
      );
    } else if (photo.remoteUrl != null && photo.remoteUrl!.isNotEmpty) {
      preview = Image.network(
        photo.remoteUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
      );
    } else {
      preview = Container(
        color: theme.colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_camera_back_outlined,
              size: 36,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              'Captura ${angle.label.toLowerCase()}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            color: theme.colorScheme.surfaceContainerLow,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    angle.label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (photo.hasImage)
                  const Icon(Icons.check_circle_outline_rounded, size: 18),
              ],
            ),
          ),
          SizedBox(height: 180, child: preview),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: onCapture,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(photo.hasImage ? 'Reemplazar' : 'Agregar'),
                  ),
                ),
                if (onClear != null) ...[
                  const SizedBox(width: 10),
                  IconButton(
                    tooltip: 'Quitar foto',
                    onPressed: onClear,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.state,
    required this.draftIssues,
    required this.advanceIssues,
    required this.hasPendingSignature,
    required this.onSaveDraft,
    required this.onAdvance,
  });

  final ReceptionState state;
  final List<String> draftIssues;
  final List<String> advanceIssues;
  final bool hasPendingSignature;
  final VoidCallback? onSaveDraft;
  final VoidCallback? onAdvance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final issuesToShow = advanceIssues.take(4).toList(growable: false);

    return Material(
      elevation: 14,
      color: theme.colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.isSubmitting) const LinearProgressIndicator(),
              if (!state.isSubmitting && advanceIssues.isNotEmpty) ...[
                Text(
                  'Pendientes para avanzar',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final issue in issuesToShow)
                      Chip(
                        avatar: const Icon(Icons.error_outline_rounded, size: 16),
                        label: Text(issue),
                      ),
                    if (advanceIssues.length > issuesToShow.length)
                      Chip(
                        label: Text(
                          '+${advanceIssues.length - issuesToShow.length} mas',
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              if (!state.isSubmitting && advanceIssues.isEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.task_alt_rounded, color: Colors.green.shade700),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          hasPendingSignature || state.hasStoredSignature
                              ? 'Todo listo para enviar a diagnostico.'
                              : 'Checklist completo. Solo falta la firma.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onSaveDraft,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Guardar borrador'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onAdvance,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('Enviar a diagnostico'),
                    ),
                  ),
                ],
              ),
              if (draftIssues.isNotEmpty && onSaveDraft == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Para guardar el borrador completa: ${draftIssues.join(', ')}.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DamageDraftResult {
  const _DamageDraftResult({
    required this.description,
    required this.reconocidoPorCliente,
  });

  final String description;
  final bool reconocidoPorCliente;
}
