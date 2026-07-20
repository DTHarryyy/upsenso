# UPSENSO — Data Flow Diagrams

Two data flow diagrams (DFDs) of the UPSENSO offline-first POS & business-management
system, in classic Gane–Sarson / Yourdon notation. Sources are Mermaid (`.mmd`);
rendered vector figures are the matching `.svg` files.

| File | Figure |
|---|---|
| `upsenso_context_diagram.mmd` / `.svg` | **Fig. 1** — Context Diagram (DFD Level 0) |
| `upsenso_level1_dfd.mmd` / `.svg` | **Fig. 2** — Level-1 Data Flow Diagram |

## Notation legend
- **Rectangle** — external entity (source/sink of data): users, customer, supplier, and
  the Supabase cloud backend.
- **Circle** — process (numbered): a transformation the system performs on data.
- **Open cylinder `Dn`** — data store: a persistent collection. Each `Dn` lists the real
  backing tables (Drift/SQLite locally, mirrored to Supabase/Postgres).
- **Labeled arrow** — a data flow; the label names the data in motion. Dashed arrows mark
  control/permission decisions and background sync reconciliation.

## Fig. 1 — Context Diagram (caption)
> **Figure 1. Context diagram of the UPSENSO system.** UPSENSO is modelled as a single
> process exchanging data with six external entities. POS staff, branch managers, and
> owners interact through role-scoped flows; customers exchange orders/payments for
> receipts; suppliers receive purchase orders and return goods-received notices. The
> Supabase cloud backend is the sole external system, capturing UPSENSO's offline-first
> boundary: the client operates locally and exchanges a sync queue and RLS-validated
> deltas with the backend when connectivity is available.

## Fig. 2 — Level-1 DFD (caption)
> **Figure 2. Level-1 data flow diagram of UPSENSO.** The system decomposes into eight
> processes — Point of Sale (1), Inventory & Stock Control (2), Procurement (3), Expense
> Management (4), Access Control (5), Audit & Fraud Detection (6), the Offline Sync Engine
> (7), and Reporting & AI Assistant (8) — over seven data stores (D1–D7). Every
> transactional process writes its local store first, emits a hash-chained audit event to
> process 6, and enqueues a change for process 7, which is the only process that
> communicates with the Supabase cloud backend. Access Control (5) gates the transactional
> and reporting processes via grant/deny decisions resolved from roles, per-employee
> overrides, and module state (D5), realising UPSENSO's two-layer RBAC + module-gate model.

## Regenerating the figures
The `.svg` files were produced from the `.mmd` sources via the Mermaid Chart renderer.
To regenerate locally with the Mermaid CLI:

```bash
npx @mermaid-js/mermaid-cli -i upsenso_context_diagram.mmd -o upsenso_context_diagram.svg
npx @mermaid-js/mermaid-cli -i upsenso_level1_dfd.mmd     -o upsenso_level1_dfd.svg
```

## Note on stale docs
`docs/UPSENSO_ARCHITECTURE.md` refers to Riverpod + Hive; the shipped codebase uses
**flutter_bloc + Drift/SQLite** (see `.claude/CLAUDE.md`). These diagrams reflect the
actual implementation.
