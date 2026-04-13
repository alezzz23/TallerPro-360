import { z } from 'zod';

export const quotationItemSchema = z.object({
  finding_id: z.string().uuid(),
  part_id: z.string().uuid().nullable().optional(),
  descripcion: z.string().min(1, 'Descripción es requerida'),
  mano_obra: z
    .number({ invalid_type_error: 'Ingrese un valor válido' })
    .min(0, 'No puede ser negativo'),
  costo_repuesto: z
    .number({ invalid_type_error: 'Ingrese un valor válido' })
    .min(0, 'No puede ser negativo'),
});

export type QuotationItemFormData = z.infer<typeof quotationItemSchema>;

export const quotationCreateSchema = z.object({
  items: z.array(quotationItemSchema).min(1, 'Agregue al menos un ítem'),
  impuestos_pct: z
    .number()
    .min(0, 'Mínimo 0%')
    .max(1, 'Máximo 100%')
    .default(0.16),
  shop_supplies_pct: z
    .number()
    .min(0, 'Mínimo 0%')
    .max(1, 'Máximo 100%')
    .default(0.015),
  descuento: z
    .number()
    .min(0, 'No puede ser negativo')
    .default(0),
});

export type QuotationCreateFormData = z.infer<typeof quotationCreateSchema>;

export const discountSchema = z.object({
  descuento: z
    .number({ invalid_type_error: 'Ingrese un valor válido' })
    .min(0, 'No puede ser negativo'),
  razon: z.string().optional(),
});

export type DiscountFormData = z.infer<typeof discountSchema>;
