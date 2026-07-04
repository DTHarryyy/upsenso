/// Native / non-web: a single app instance means the in-process write queue is
/// already the only serialization needed — run the body directly.
Future<T> runWithChainLock<T>(String name, Future<T> Function() body) => body();
