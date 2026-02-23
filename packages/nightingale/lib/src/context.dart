abstract class MigrationContext<T> {
  const MigrationContext(this.value);

  final T value;

  Future<void> executeCommand(String sql);
  Future<void> executeFile(String file);
  Future<void> runTransaction(SessionExecutor<T> executor);
}

typedef SessionExecutor<T> = Future<void> Function(MigrationContext<T> session);
