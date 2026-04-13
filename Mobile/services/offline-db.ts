import { Platform } from 'react-native';
import type { ServiceOrder, Vehicle, Customer, DiagnosticFinding } from '@/types/api';

// ── Types ──────────────────────────────────────────────────

export interface SyncQueueItem {
  id: number;
  mutation_key: string;
  endpoint: string;
  method: string;
  payload: string;
  created_at: number;
  retries: number;
  status: 'pending' | 'syncing' | 'failed' | 'done';
}

// ── Lazy DB reference (only on native) ─────────────────────

let db: import('expo-sqlite').SQLiteDatabase | null = null;

function getDb() {
  if (Platform.OS === 'web') return null;
  if (!db) throw new Error('Database not initialized — call initDatabase() first');
  return db;
}

// ── Init ───────────────────────────────────────────────────

export async function initDatabase(): Promise<void> {
  if (Platform.OS === 'web') return;

  const SQLite = await import('expo-sqlite');
  db = SQLite.openDatabaseSync('tallerpro360.db');

  db.execSync(`
    CREATE TABLE IF NOT EXISTS orders (
      id TEXT PRIMARY KEY,
      data TEXT NOT NULL,
      updated_at INTEGER NOT NULL
    );

    CREATE TABLE IF NOT EXISTS vehicles (
      id TEXT PRIMARY KEY,
      data TEXT NOT NULL,
      updated_at INTEGER NOT NULL
    );

    CREATE TABLE IF NOT EXISTS customers (
      id TEXT PRIMARY KEY,
      data TEXT NOT NULL,
      updated_at INTEGER NOT NULL
    );

    CREATE TABLE IF NOT EXISTS findings (
      id TEXT PRIMARY KEY,
      order_id TEXT NOT NULL,
      data TEXT NOT NULL,
      updated_at INTEGER NOT NULL
    );

    CREATE TABLE IF NOT EXISTS sync_queue (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      mutation_key TEXT NOT NULL,
      endpoint TEXT NOT NULL,
      method TEXT NOT NULL,
      payload TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      retries INTEGER DEFAULT 0,
      status TEXT DEFAULT 'pending'
    );
  `);
}

// ── Orders ─────────────────────────────────────────────────

export function cacheOrder(order: ServiceOrder): void {
  const d = getDb();
  if (!d) return;
  d.runSync(
    `INSERT OR REPLACE INTO orders (id, data, updated_at) VALUES (?, ?, ?)`,
    order.id,
    JSON.stringify(order),
    Date.now(),
  );
}

export function cacheOrders(orders: ServiceOrder[]): void {
  const d = getDb();
  if (!d) return;
  const stmt = d.prepareSync(
    `INSERT OR REPLACE INTO orders (id, data, updated_at) VALUES (?, ?, ?)`,
  );
  try {
    const now = Date.now();
    for (const order of orders) {
      stmt.executeSync(order.id, JSON.stringify(order), now);
    }
  } finally {
    stmt.finalizeSync();
  }
}

export function getCachedOrders(): ServiceOrder[] {
  const d = getDb();
  if (!d) return [];
  const rows = d.getAllSync<{ data: string }>(
    `SELECT data FROM orders ORDER BY updated_at DESC`,
  );
  return rows.map((r) => JSON.parse(r.data) as ServiceOrder);
}

export function getCachedOrder(id: string): ServiceOrder | null {
  const d = getDb();
  if (!d) return null;
  const row = d.getFirstSync<{ data: string }>(
    `SELECT data FROM orders WHERE id = ?`,
    id,
  );
  return row ? (JSON.parse(row.data) as ServiceOrder) : null;
}

// ── Vehicles ───────────────────────────────────────────────

export function cacheVehicle(vehicle: Vehicle): void {
  const d = getDb();
  if (!d) return;
  d.runSync(
    `INSERT OR REPLACE INTO vehicles (id, data, updated_at) VALUES (?, ?, ?)`,
    vehicle.id,
    JSON.stringify(vehicle),
    Date.now(),
  );
}

export function getCachedVehicle(id: string): Vehicle | null {
  const d = getDb();
  if (!d) return null;
  const row = d.getFirstSync<{ data: string }>(
    `SELECT data FROM vehicles WHERE id = ?`,
    id,
  );
  return row ? (JSON.parse(row.data) as Vehicle) : null;
}

// ── Customers ──────────────────────────────────────────────

export function cacheCustomer(customer: Customer): void {
  const d = getDb();
  if (!d) return;
  d.runSync(
    `INSERT OR REPLACE INTO customers (id, data, updated_at) VALUES (?, ?, ?)`,
    customer.id,
    JSON.stringify(customer),
    Date.now(),
  );
}

export function getCachedCustomer(id: string): Customer | null {
  const d = getDb();
  if (!d) return null;
  const row = d.getFirstSync<{ data: string }>(
    `SELECT data FROM customers WHERE id = ?`,
    id,
  );
  return row ? (JSON.parse(row.data) as Customer) : null;
}

// ── Findings ───────────────────────────────────────────────

export function cacheFinding(finding: DiagnosticFinding): void {
  const d = getDb();
  if (!d) return;
  d.runSync(
    `INSERT OR REPLACE INTO findings (id, order_id, data, updated_at) VALUES (?, ?, ?, ?)`,
    finding.id,
    finding.order_id,
    JSON.stringify(finding),
    Date.now(),
  );
}

export function cacheFindings(findings: DiagnosticFinding[]): void {
  const d = getDb();
  if (!d) return;
  const stmt = d.prepareSync(
    `INSERT OR REPLACE INTO findings (id, order_id, data, updated_at) VALUES (?, ?, ?, ?)`,
  );
  try {
    const now = Date.now();
    for (const f of findings) {
      stmt.executeSync(f.id, f.order_id, JSON.stringify(f), now);
    }
  } finally {
    stmt.finalizeSync();
  }
}

export function getCachedFindings(orderId: string): DiagnosticFinding[] {
  const d = getDb();
  if (!d) return [];
  const rows = d.getAllSync<{ data: string }>(
    `SELECT data FROM findings WHERE order_id = ? ORDER BY updated_at DESC`,
    orderId,
  );
  return rows.map((r) => JSON.parse(r.data) as DiagnosticFinding);
}

// ── Sync Queue ─────────────────────────────────────────────

export function addToSyncQueue(
  mutationKey: string,
  endpoint: string,
  method: string,
  payload: unknown,
): void {
  const d = getDb();
  if (!d) return;
  d.runSync(
    `INSERT INTO sync_queue (mutation_key, endpoint, method, payload, created_at) VALUES (?, ?, ?, ?, ?)`,
    mutationKey,
    endpoint,
    method,
    JSON.stringify(payload),
    Date.now(),
  );
}

export function getPendingSyncItems(): SyncQueueItem[] {
  const d = getDb();
  if (!d) return [];
  return d.getAllSync<SyncQueueItem>(
    `SELECT * FROM sync_queue WHERE status IN ('pending', 'failed') ORDER BY created_at ASC`,
  );
}

export function getSyncQueueCount(): number {
  const d = getDb();
  if (!d) return 0;
  const row = d.getFirstSync<{ count: number }>(
    `SELECT COUNT(*) as count FROM sync_queue WHERE status IN ('pending', 'failed')`,
  );
  return row?.count ?? 0;
}

export function markSyncing(id: number): void {
  getDb()?.runSync(`UPDATE sync_queue SET status = 'syncing' WHERE id = ?`, id);
}

export function markSynced(id: number): void {
  getDb()?.runSync(`UPDATE sync_queue SET status = 'done' WHERE id = ?`, id);
}

export function markFailed(id: number): void {
  getDb()?.runSync(
    `UPDATE sync_queue SET status = 'failed', retries = retries + 1 WHERE id = ?`,
    id,
  );
}

export function removeSynced(): void {
  getDb()?.runSync(`DELETE FROM sync_queue WHERE status = 'done'`);
}

// ── Cleanup / Logout ───────────────────────────────────────

export function clearCache(): void {
  const d = getDb();
  if (!d) return;
  d.execSync(`
    DELETE FROM orders;
    DELETE FROM vehicles;
    DELETE FROM customers;
    DELETE FROM findings;
    DELETE FROM sync_queue;
  `);
}
