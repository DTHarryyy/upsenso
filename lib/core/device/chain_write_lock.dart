// Cross-instance lock around a device chain's write critical section.
//
// Native platforms run a single app instance, so the in-process write queue in
// AuditLogService already serializes writes — the no-op is correct there. On
// web, two tabs share one localStorage device_uid and each has its own
// in-process queue, so they can allocate the same seq concurrently (the
// 2026-07-03 chain-conflict → TIME_REVERSAL false positive). The web
// implementation serializes them with the Web Locks API.
//
// STRICTLY best-effort: if the lock API is missing or throws, the body runs
// anyway. The reconcile path (AuditLogService.reconcileConflictedTail) remains
// the correctness backstop; this only avoids the churn.
export 'chain_write_lock_noop.dart'
    if (dart.library.js_interop) 'chain_write_lock_web.dart';
