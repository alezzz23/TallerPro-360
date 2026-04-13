import { z } from 'zod';

export const vehicleSearchSchema = z.object({
  vehicle_id: z.string().uuid('Seleccione un vehículo'),
  kilometraje_ingreso: z
    .number({ invalid_type_error: 'Ingrese un número válido' })
    .int()
    .min(0, 'El kilometraje no puede ser negativo')
    .optional(),
  motivo_ingreso: z.string().min(1, 'Ingrese el motivo de ingreso'),
});

export type VehicleSearchFormData = z.infer<typeof vehicleSearchSchema>;

export const checklistSchema = z.object({
  nivel_aceite: z.enum(['BAJO', 'MEDIO', 'ALTO']).optional(),
  nivel_refrigerante: z.enum(['BAJO', 'MEDIO', 'ALTO']).optional(),
  nivel_frenos: z.enum(['BAJO', 'MEDIO', 'ALTO']).optional(),
  llanta_repuesto: z.boolean(),
  kit_carretera: z.boolean(),
  botiquin: z.boolean(),
  extintor: z.boolean(),
  documentos_recibidos: z.string().optional(),
});

export type ChecklistFormData = z.infer<typeof checklistSchema>;

export const damageSchema = z.object({
  ubicacion: z.string().min(1, 'Seleccione una zona'),
  descripcion: z.string().optional(),
  reconocido_por_cliente: z.boolean(),
});

export type DamageFormData = z.infer<typeof damageSchema>;
