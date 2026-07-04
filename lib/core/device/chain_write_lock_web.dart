// Web: serialize a device chain's writes across tabs with the Web Locks API,
// so two tabs sharing one localStorage device_uid can't allocate the same seq
// concurrently. Best-effort — any failure runs the body unguarded (the
// reconcile path stays the correctness backstop) and the body is never run
// twice.
import 'dart:js_interop';

@JS('navigator')
external JSObject get _navigator;

extension type _Navigator._(JSObject _) implements JSObject {
  external _LockManager? get locks;
}

extension type _LockManager._(JSObject _) implements JSObject {
  external JSPromise request(String name, JSFunction callback);
}

Future<T> runWithChainLock<T>(String name, Future<T> Function() body) async {
  _LockManager? locks;
  try {
    locks = _Navigator._(_navigator).locks;
  } catch (_) {
    locks = null;
  }
  if (locks == null) return body();

  var ran = false;
  T? result;
  Object? error;
  StackTrace? stack;

  JSPromise callback(JSAny? lock) {
    final work = () async {
      ran = true;
      try {
        result = await body();
      } catch (e, st) {
        error = e;
        stack = st;
      }
    }();
    // Holding the lock until this promise settles is what serializes writers.
    return work.toJS;
  }

  try {
    await locks.request(name, callback.toJS).toDart;
  } catch (_) {
    // The lock could not even be requested — run once, unguarded.
    if (!ran) return body();
  }

  if (error != null) {
    Error.throwWithStackTrace(error!, stack ?? StackTrace.current);
  }
  return result as T;
}
