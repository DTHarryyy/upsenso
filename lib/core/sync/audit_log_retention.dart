/// How much audit log history stays mirrored on-device. Older entries live
/// only on the server (kept forever there) and are fetched on demand when a
/// user filters or scrolls past this window — see AuditLogBloc/Repository.
const auditLogLocalWindowDays = 90;
