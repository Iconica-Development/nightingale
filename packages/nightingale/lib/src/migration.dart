import "dart:async";

import "package:nightingale/src/context.dart";

typedef MigrationDirection<T> =
    FutureOr<void> Function(
      MigrationContext<T> database,
    );

class Migration<T> {
  const Migration(
    this.name, {
    required this.forward,
    this.backward,
  });

  factory Migration.multi(
    String name, {
    required List<Migration> migrations,
  }) => Migration(
    name,
    forward: (database) async {
      for (final migration in migrations) {
        await migration.forward(database);
      }
    },
    backward: (database) async {
      for (final migration in migrations.reversed) {
        await migration.backward?.call(database);
      }
    },
  );

  factory Migration.command(
    String name, {
    required String forward,
    required String backward,
  }) => Migration(
    name,
    forward: (database) => database.executeCommand(forward),
    backward: (database) => database.executeCommand(backward),
  );

  factory Migration.file(
    String name, {
    required String forward,
    required String backward,
  }) => Migration(
    name,
    forward: (database) => database.executeFile(forward),
    backward: (database) => database.executeFile(backward),
  );

  final String name;
  final MigrationDirection<T> forward;
  final MigrationDirection<T>? backward;
}
