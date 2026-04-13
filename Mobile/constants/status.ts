import type { ServiceOrderStatus } from '@/types/api';

export const STATUS_LABELS: Record<ServiceOrderStatus, string> = {
  RECEPCION: 'Recepción',
  DIAGNOSTICO: 'Diagnóstico',
  APROBACION: 'Aprobación',
  REPARACION: 'Reparación',
  QC: 'Control de Calidad',
  ENTREGA: 'Entrega',
  CERRADA: 'Cerrada',
};

/** Columns shown in the Kanban board (excludes CERRADA) */
export const KANBAN_STATUSES: ServiceOrderStatus[] = [
  'RECEPCION',
  'DIAGNOSTICO',
  'APROBACION',
  'REPARACION',
  'QC',
  'ENTREGA',
];
