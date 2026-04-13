import { z } from 'zod';

const fluidLevel = z.enum(['BAJO', 'MEDIO', 'ALTO']);

export const qcFormSchema = z.object({
  items_verificados: z.record(z.string(), z.boolean()),
  kilometraje_salida: z
    .number({ invalid_type_error: 'Ingrese un número válido' })
    .min(0, 'El kilometraje no puede ser negativo')
    .nullable()
    .optional(),
  nivel_aceite_salida: fluidLevel.nullable().optional(),
  nivel_refrigerante_salida: fluidLevel.nullable().optional(),
  nivel_frenos_salida: fluidLevel.nullable().optional(),
});

export type QCFormData = z.infer<typeof qcFormSchema>;

export const FLUID_LEVELS = ['BAJO', 'MEDIO', 'ALTO'] as const;
export type FluidLevel = (typeof FLUID_LEVELS)[number];
