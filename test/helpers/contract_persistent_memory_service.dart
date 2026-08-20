import 'dart:async';

import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/persistent_memory_service.dart';

/// Runs before a queued write becomes durable in
/// [ContractPersistentMemoryService].
typedef ContractPersistentMemoryPersistHook =
    FutureOr<void> Function(
      String key,
      PersistentMemoryType type,
      Object value,
    );

/// Runs before a direct read in [ContractPersistentMemoryService].
typedef ContractPersistentMemoryReadHook =
    FutureOr<void> Function(String key, PersistentMemoryType type);

/// Runs when [ContractPersistentMemoryService] reaches its queued reset.
typedef ContractPersistentMemoryResetHook = FutureOr<void> Function();

/// Resolves a missing direct read in [ContractPersistentMemoryService].
typedef ContractPersistentMemoryMissingValueResolver =
    dynamic Function(String key, PersistentMemoryType type);

/// Observes a successful durable write in [ContractPersistentMemoryService].
typedef ContractPersistentMemoryCompletionObserver =
    FutureOr<void> Function(
      String key,
      PersistentMemoryType type,
      Object value,
    );

/// An immutable record of a write accepted by a contract persistence fake.
final class ContractPersistentMemoryWrite {
  /// Creates a record for [key], [type], and [value].
  ContractPersistentMemoryWrite(this.key, this.type, Object value)
    : _value = _copyValue(type, value);

  /// The persisted key.
  final String key;

  /// The value type used by the write.
  final PersistentMemoryType type;

  final Object _value;

  /// A defensive copy of the persisted value.
  Object get value => _copyValue(type, _value);
}

/// An in-memory [PersistentMemoryService] that follows its public contract.
///
/// [store] is the visible cache and remains mutable by reference so tests can
/// seed or inspect it directly. [durableStore] only changes after a queued
/// persistence operation succeeds. The default hooks complete immediately;
/// tests can use the hooks or override the queued methods to hold, reject, or
/// observe particular operations without bypassing serialization.
class ContractPersistentMemoryService implements PersistentMemoryService {
  /// Creates a service using [store] or a copy of [initialValues].
  ///
  /// A supplied [store] remains the service's visible cache by reference. An
  /// initial value map can only seed a service that owns its cache.
  ContractPersistentMemoryService({
    Map<String, dynamic>? store,
    Map<String, Object?>? initialValues,
    this.ignoreInvalidWrites = false,
  }) : store = store ?? _copyInitialValues(initialValues) {
    if (store != null && initialValues != null) {
      throw ArgumentError.value(
        initialValues,
        'initialValues',
        'Cannot provide initialValues with a caller-owned store.',
      );
    }
    for (final MapEntry<String, dynamic> entry in this.store.entries) {
      final dynamic value = entry.value;
      if (value == null) {
        continue;
      }
      _durableStore[entry.key] = _copyUntypedValue(value);
    }
  }

  /// The directly readable, mutable cache used by test callers.
  final Map<String, dynamic> store;

  /// Whether invalid writes complete without changing test state.
  ///
  /// This preserves legacy no-op fixtures while all accepted writes still use
  /// the serialized contract below.
  final bool ignoreInvalidWrites;

  final Map<String, Object> _durableStore = <String, Object>{};
  Future<void>? _pendingOperation;
  Future<void>? _activeReset;
  bool _resetFenceActive = false;

  /// Runs inside the serialized write operation before the write is durable.
  ///
  /// Assign this hook to delay or fail a specific write while retaining the
  /// queue and reset-fence behavior.
  ContractPersistentMemoryPersistHook? onPersist;

  /// Runs before a direct, non-serialized read.
  ContractPersistentMemoryReadHook? onRead;

  /// Runs inside the serialized reset operation before durable state clears.
  ContractPersistentMemoryResetHook? onReset;

  /// Resolves an absent key before [missingValueFor] supplies its default.
  ///
  /// Unlike a null sentinel, a present resolver may intentionally return null.
  ContractPersistentMemoryMissingValueResolver? onMissingRead;

  /// Runs after a write has become durable and before its future completes.
  ContractPersistentMemoryCompletionObserver? onSetItemCompleted;

  /// Records queued writes that started persistence, including failed writes.
  final List<ContractPersistentMemoryWrite> attemptedWrites =
      <ContractPersistentMemoryWrite>[];

  /// Records successful durable writes in completion order.
  final List<ContractPersistentMemoryWrite> completedWrites =
      <ContractPersistentMemoryWrite>[];

  /// A defensive snapshot of values that completed persistence.
  Map<String, Object> get durableStore =>
      Map<String, Object>.unmodifiable(_copyStore(_durableStore));

  @override
  Future<void> setItem(String key, PersistentMemoryType type, dynamic value) {
    if (key.isEmpty || value == null) {
      if (ignoreInvalidWrites) {
        return Future<void>.value();
      }
      return Future<void>.error(
        ArgumentError(
          'Persistent memory requires a non-empty key and non-null value.',
        ),
      );
    }
    if (_resetFenceActive) {
      return Future<void>.error(
        StateError(
          'Persistent memory cannot write while reset is in progress.',
        ),
      );
    }

    late final Object copiedValue;
    try {
      copiedValue = _copyValue(type, value as Object);
    } catch (error, stackTrace) {
      return Future<void>.error(error, stackTrace);
    }

    return _enqueue(() async {
      final Object visibleValue = _copyValue(type, copiedValue);
      store[key] = visibleValue;
      final ContractPersistentMemoryWrite write = ContractPersistentMemoryWrite(
        key,
        type,
        visibleValue,
      );
      attemptedWrites.add(write);

      await persistQueuedItem(key, type, write.value);

      _durableStore[key] = _copyValue(type, write.value);
      completedWrites.add(write);
      await onSetItemCompleted?.call(key, type, write.value);
    });
  }

  /// Persists a queued write after it is visible and before it is durable.
  ///
  /// Subclasses can override this method to model persistence behavior while
  /// retaining the service's queue and reset fence.
  Future<void> persistQueuedItem(
    String key,
    PersistentMemoryType type,
    Object value,
  ) async {
    await onPersist?.call(key, type, value);
  }

  @override
  Future<dynamic> getItem(String key, PersistentMemoryType type) async {
    await onRead?.call(key, type);
    if (!store.containsKey(key)) {
      final ContractPersistentMemoryMissingValueResolver? resolver =
          onMissingRead;
      if (resolver != null) {
        return resolver(key, type);
      }
      return missingValueFor(key, type);
    }
    final dynamic value = store[key];
    if (value == null) {
      return null;
    }
    return _copyValue(type, value as Object);
  }

  /// Returns the value for a missing [key] with [type].
  ///
  /// Subclasses can override this to match a test's existing missing-read
  /// behavior without replacing the direct-read implementation.
  dynamic missingValueFor(String key, PersistentMemoryType type) {
    switch (type) {
      case PersistentMemoryType.String:
        return '';
      case PersistentMemoryType.Int:
        return null;
      case PersistentMemoryType.Double:
        return 0.0;
      case PersistentMemoryType.Bool:
        return false;
      case PersistentMemoryType.StringList:
        return <String>[];
    }
  }

  @override
  Future<void> reset() {
    final Future<void>? activeReset = _activeReset;
    if (activeReset != null) {
      return activeReset;
    }

    _resetFenceActive = true;
    late final Future<void> resetOperation;
    resetOperation =
        _enqueue(() async {
          store.clear();
          await resetQueuedStore();
          _durableStore.clear();
        }).whenComplete(() {
          if (identical(_activeReset, resetOperation)) {
            _activeReset = null;
            _resetFenceActive = false;
          }
        });
    _activeReset = resetOperation;
    return resetOperation;
  }

  /// Clears the durable backing store from inside the serialized reset.
  ///
  /// Subclasses can override this method to model reset behavior while
  /// retaining the service's queue and reset fence.
  Future<void> resetQueuedStore() async {
    await onReset?.call();
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final Future<void>? previousOperation = _pendingOperation;
    final Completer<void> queueSlot = Completer<void>();
    _pendingOperation = queueSlot.future;

    final Future<void> queuedOperation = previousOperation == null
        ? Future<void>.sync(operation)
        : previousOperation.then<void>((_) => operation());
    queuedOperation.then<void>(
      (_) {
        queueSlot.complete();
      },
      onError: (Object _, StackTrace _) {
        queueSlot.complete();
      },
    );
    queueSlot.future.whenComplete(() {
      if (identical(_pendingOperation, queueSlot.future)) {
        _pendingOperation = null;
      }
    });
    return queuedOperation;
  }
}

Map<String, Object> _copyStore(Map<String, Object> values) {
  return Map<String, Object>.fromEntries(
    values.entries.map(
      (MapEntry<String, Object> entry) =>
          MapEntry<String, Object>(entry.key, _copyUntypedValue(entry.value)),
    ),
  );
}

Map<String, dynamic> _copyInitialValues(Map<String, Object?>? values) {
  if (values == null) {
    return <String, dynamic>{};
  }
  return Map<String, dynamic>.fromEntries(
    values.entries.map(
      (MapEntry<String, Object?> entry) => MapEntry<String, dynamic>(
        entry.key,
        entry.value == null ? null : _copyUntypedValue(entry.value!),
      ),
    ),
  );
}

Object _copyUntypedValue(Object value) {
  if (value is List) {
    return List<dynamic>.from(value);
  }
  return value;
}

Object _copyValue(PersistentMemoryType type, Object value) {
  switch (type) {
    case PersistentMemoryType.String:
      return value as String;
    case PersistentMemoryType.Int:
      return value as int;
    case PersistentMemoryType.Double:
      return value as double;
    case PersistentMemoryType.Bool:
      return value as bool;
    case PersistentMemoryType.StringList:
      return List<String>.from(value as Iterable);
  }
}
