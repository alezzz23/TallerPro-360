export type UserRole = 'TECNICO' | 'ASESOR' | 'JEFE_TALLER' | 'ADMIN';

export type ServiceOrderStatus =
  | 'RECEPCION'
  | 'DIAGNOSTICO'
  | 'APROBACION'
  | 'REPARACION'
  | 'QC'
  | 'ENTREGA'
  | 'CERRADA';

export interface User {
  id: string;
  nombre: string;
  email: string;
  rol: UserRole;
  activo: boolean;
}

export interface AuthTokens {
  access_token: string;
  token_type: string;
}

export interface LoginRequest {
  email: string;
  password: string;
}

export interface ApiError {
  detail: string;
}

export interface PaginatedResponse<T> {
  items: T[];
  total: number;
  limit: number;
  offset: number;
}

export interface ServiceOrder {
  id: string;
  vehicle_id: string;
  advisor_id: string;
  estado: ServiceOrderStatus;
  fecha_ingreso: string;
  fecha_salida: string | null;
  kilometraje_ingreso: number | null;
  kilometraje_salida: number | null;
  motivo_ingreso: string | null;
  reception_complete: boolean;
}

export interface Vehicle {
  id: string;
  customer_id: string;
  marca: string;
  modelo: string;
  placa: string;
  vin: string | null;
  kilometraje: number | null;
  color: string | null;
  created_at: string;
}

export interface Customer {
  id: string;
  nombre: string;
  telefono: string | null;
  email: string | null;
  direccion: string | null;
  whatsapp: string | null;
}

export type AnguloFoto = 'FRONTAL' | 'TRASERO' | 'IZQUIERDO' | 'DERECHO';

export interface ReceptionChecklist {
  id: string;
  order_id: string;
  nivel_aceite: string | null;
  nivel_refrigerante: string | null;
  nivel_frenos: string | null;
  llanta_repuesto: boolean;
  kit_carretera: boolean;
  botiquin: boolean;
  extintor: boolean;
  documentos_recibidos: string | null;
  firma_cliente_url: string | null;
}

export interface DamageRecord {
  id: string;
  order_id: string;
  ubicacion: string;
  descripcion: string | null;
  foto_url: string | null;
  reconocido_por_cliente: boolean;
}

export interface PerimeterPhoto {
  id: string;
  order_id: string;
  angulo: AnguloFoto;
  foto_url: string;
}

export interface MediaUploadResponse {
  url: string;
  relative_url: string;
  category: string;
  filename: string;
  content_type: string;
  size_bytes: number;
}

// ── Diagnosis (Phase 5.5) ──────────────────────────────────

export type PartOrigen = 'STOCK' | 'PEDIDO';

export interface DiagnosticFinding {
  id: string;
  order_id: string;
  technician_id: string;
  motivo_ingreso: string;
  descripcion: string | null;
  tiempo_estimado: number | null;
  fotos: string[];
  es_hallazgo_adicional: boolean;
  es_critico_seguridad: boolean;
  parts: Part[];
  safety_warning: string | null;
}

export interface Part {
  id: string;
  finding_id: string;
  nombre: string;
  origen: PartOrigen;
  costo: number;
  margen: number;
  precio_venta: number;
  proveedor: string | null;
}

export interface Technician {
  id: string;
  nombre: string;
}

// ── Quotation (Phase 5.6) ──────────────────────────────────

export type QuotationEstado = 'PENDIENTE' | 'APROBADA' | 'RECHAZADA';

export interface QuotationItem {
  id: string;
  quotation_id: string;
  finding_id: string;
  part_id: string | null;
  descripcion: string;
  mano_obra: number;
  costo_repuesto: number;
  precio_final: number;
}

export interface Quotation {
  id: string;
  order_id: string;
  subtotal: number;
  impuestos: number;
  shop_supplies: number;
  descuento: number;
  total: number;
  estado: QuotationEstado;
  fecha_envio: string | null;
  items: QuotationItem[];
}

// ── Quality Control (Phase 5.7) ────────────────────────────

export interface QualityCheck {
  id: string;
  order_id: string;
  inspector_id: string;
  items_verificados: Record<string, boolean>;
  kilometraje_salida: number | null;
  nivel_aceite_salida: string | null;
  nivel_refrigerante_salida: string | null;
  nivel_frenos_salida: string | null;
  aprobado: boolean;
  fecha: string;
  km_delta: number | null;
}

// ── Billing & NPS (Phase 5.8) ──────────────────────────────

export type MetodoPago = 'EFECTIVO' | 'TARJETA' | 'TRANSFERENCIA' | 'CREDITO';

export interface Invoice {
  id: string;
  order_id: string;
  monto_total: number;
  metodo_pago: MetodoPago;
  es_credito: boolean;
  saldo_pendiente: number;
  fecha: string;
}

export interface NPSSurvey {
  id: string;
  order_id: string;
  atencion: number;
  instalaciones: number;
  tiempos: number;
  precios: number;
  recomendacion: number;
  comentarios: string | null;
  fecha: string;
}
