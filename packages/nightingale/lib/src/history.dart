import "dart:io";

import "package:meta/meta.dart";

abstract class MigrationHistory<T> {
  const MigrationHistory();

  Future<void> init(T database);
  Future<int?> lastVersion(T database);

  @mustCallSuper
  Future<void> record(T database, int version, String name) async =>
      stdout.writeln("Applied migration <$version:$name>.");

  @mustCallSuper
  Future<void> remove(T database, int version, String name) async =>
      stdout.writeln("Undid migration <$version:$name>.");
}
