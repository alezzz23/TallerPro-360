import { z } from 'zod';

export const findingFormSchema = z.object({
  motivo_ingreso: z.string().min(1, 'El motivo de ingreso es requerido'),
  descripcion: z.string().optional(),
  tiempo_estimado: z
    .number({ invalid_type_error: 'Ingrese un número válido' })
    .min(0, 'El tiempo no puede ser negativo')
    .optional(),
  technician_id: z.string().uuid('Seleccione un técnico'),
  es_hallazgo_adicional: z.boolean(),
  es_critico_seguridad: z.boolean(),
});

export type FindingFormData = z.infer<typeof findingFormSchema>;

export const partFormSchema = z.object({
  nombre: z.string().min(1, 'El nombre del repuesto es requerido'),
  origen: z.enum(['STOCK', 'PEDIDO']),
  costo: z
    .number({ invalid_type_error: 'Ingrese un costo válido' })
    .positive('El costo debe ser mayor a 0'),
  margen: z
    .number({ invalid_type_error: 'Ingrese un margen válido' })
    .min(0, 'El margen no puede ser negativo')
    .max(0.99, 'El margen debe ser menor a 100%'),
  proveedor: z.string().optional(),
});

export type PartFormData = z.infer<typeof partFormSchema>;
