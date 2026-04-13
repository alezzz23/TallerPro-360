import { z } from 'zod';

export const METODO_PAGO_OPTIONS = [
  { value: 'EFECTIVO', label: 'Efectivo', icon: 'cash-outline' },
  { value: 'TARJETA', label: 'Tarjeta', icon: 'card-outline' },
  { value: 'TRANSFERENCIA', label: 'Transferencia', icon: 'business-outline' },
  { value: 'CREDITO', label: 'Crédito', icon: 'clipboard-outline' },
] as const;

export const invoiceFormSchema = z
  .object({
    metodo_pago: z.enum(['EFECTIVO', 'TARJETA', 'TRANSFERENCIA', 'CREDITO'], {
      required_error: 'Seleccione un método de pago',
    }),
    es_credito: z.boolean(),
    saldo_pendiente: z
      .number({ invalid_type_error: 'Ingrese un monto válido' })
      .min(0, 'El saldo no puede ser negativo')
      .default(0),
  })
  .refine(
    (d) => !d.es_credito || d.saldo_pendiente > 0,
    { message: 'Ingrese el saldo pendiente para crédito', path: ['saldo_pendiente'] },
  );

export type InvoiceFormData = z.infer<typeof invoiceFormSchema>;

const npsRating = z
  .number({ required_error: 'Requerido', invalid_type_error: 'Seleccione un valor' })
  .int('Debe ser un número entero')
  .min(1, 'Mínimo 1')
  .max(10, 'Máximo 10');

export const npsFormSchema = z.object({
  atencion: npsRating,
  instalaciones: npsRating,
  tiempos: npsRating,
  precios: npsRating,
  recomendacion: npsRating,
  comentarios: z.string().optional(),
});

export type NPSFormData = z.infer<typeof npsFormSchema>;

export const NPS_CATEGORIES = [
  { key: 'atencion', label: 'Atención al cliente', icon: 'people-outline' },
  { key: 'instalaciones', label: 'Instalaciones', icon: 'storefront-outline' },
  { key: 'tiempos', label: 'Tiempos de entrega', icon: 'timer-outline' },
  { key: 'precios', label: 'Precios', icon: 'cash-outline' },
  { key: 'recomendacion', label: '¿Nos recomendaría?', icon: 'megaphone-outline' },
] as const;
