import "dart:async";
import "dart:io";

import "package:nightingale/nightingale.dart";
import "package:postgres/postgres.dart";

class PostgresMigrationContext extends MigrationContext<Session> {
  const PostgresMigrationContext(super.value);

  @override
  Future<void> executeCommand(String sql) async => value.execute(sql);

  @override
  Future<void> executeFile(String file) async {
    final result = await Process.run("psql", ["-f", file]);
    if (result.exitCode != 0) {
      throw Exception("PSQL execution failure\n${result.stdout}");
    }
  }

  @override
  Future<void> runTransaction(
    Future<void> Function(MigrationContext<Session> session) executor,
  ) async {
    final value = this.value;
    return (value is Connection)
        ? await value.runTx((value) async => executor(withValue(value)))
        : await executor(this);
  }

  PostgresMigrationContext withValue(Session value) =>
      PostgresMigrationContext(value);
}

class PostgresMigrationRunner extends MigrationRunner<Session> {
  factory PostgresMigrationRunner({
    required Session database,
    required List<Migration<Session>> migrations,
  }) => PostgresMigrationRunner._(
    database: database,
    contextGenerator: (database) async => PostgresMigrationContext(database),
    migrations: migrations,
    history: const PostgresMigrationHistory(),
  );

  const PostgresMigrationRunner._({
    required super.database,
    required super.contextGenerator,
    required super.migrations,
    required super.history,
  });
}

class PostgresMigrationHistory extends MigrationHistory<Session> {
  const PostgresMigrationHistory();

  @override
  Future<void> init(Session database) async {
    await database.execute("""
CREATE TABLE IF NOT EXISTS public.migration_history(
  id SERIAL PRIMARY KEY,
  version integer NOT NULL UNIQUE,
  name text NOT NULL,
  applied_at timestamp DEFAULT CURRENT_TIMESTAMP
)
""");
  }

  @override
  Future<int?> lastVersion(Session database) async {
    final result = await database.execute(
      """SELECT version FROM public.migration_history ORDER BY version DESC LIMIT 1""",
    );
    if (result.isEmpty) return null;
    return result.first.first as int?;
  }

  @override
  Future<void> record(Session database, int version, String name) async {
    await database.execute(
      Sql.named("""
INSERT INTO public.migration_history (version, name) VALUES (@version, @name)
"""),
      parameters: {"version": version, "name": name},
    );
    await super.record(database, version, name);
  }

  @override
  Future<void> remove(Session database, int version, String name) async {
    await database.execute(
      Sql.named("""
DELETE FROM public.migration_history WHERE version = @version
      """),
      parameters: {"version": version},
    );
    await super.remove(database, version, name);
  }
}
