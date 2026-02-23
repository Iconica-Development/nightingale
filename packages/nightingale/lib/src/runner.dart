import "dart:async";
import "dart:io";

import "package:nightingale/src/argument_parser.dart";
import "package:nightingale/src/context.dart";
import "package:nightingale/src/history.dart";
import "package:nightingale/src/migration.dart";

const instructions = """
Usage: dart run bin/migrate.dart <command> [options]

Commands:
  migrate   [--from N] [--until N]  Run forward migrations
  rollback  [--until N]             Run reverse migrations
  status                            Show migration status
""";

final _nightingaleArgsParser = getNightingaleArgsParser();

class MigrationRunner<T> {
  const MigrationRunner({
    required this.database,
    required this.contextGenerator,
    required this.migrations,
    required this.history,
  });

  final T database;
  final FutureOr<MigrationContext<T>> Function(T value) contextGenerator;
  final List<Migration<T>> migrations;
  final MigrationHistory<T> history;

  Future<void> migrate({int? from, int? until}) async {
    await history.init(database);

    final last = await history.lastVersion(database);
    final start = from ?? (last != null ? last + 1 : 0);
    final end = until ?? migrations.length;

    if (start >= migrations.length) return;

    final databaseContext = await contextGenerator(database);
    for (var i = start; i < end && i < migrations.length; i++) {
      await databaseContext.runTransaction((session) async {
        final migration = migrations[i];
        await migration.forward(session);
        await history.record(session.value, i, migration.name);
      });
    }
  }

  Future<void> rollback({int? until}) async {
    await history.init(database);

    final last = await history.lastVersion(database);
    if (last == null) return;

    final end = until ?? -1;

    final databaseContext = await contextGenerator(database);
    for (var i = last; i > end && i >= 0; i--) {
      await databaseContext.runTransaction((session) async {
        final migration = migrations[i];
        if (migration.backward != null) {
          await migration.backward!.call(session);
        }
        await history.remove(session.value, i, migration.name);
      });
    }
  }

  Future<List<Map<String, dynamic>>> getStatus() async {
    await history.init(database);
    final last = await history.lastVersion(database) ?? -1;

    return [
      for (var i = 0; i < migrations.length; i++) ...[
        {
          "index": i,
          "name": migrations[i].name,
          "applied": i <= last,
        },
      ],
    ];
  }

  Future<void> execute(List<String> arguments) async {
    if (arguments.isEmpty) {
      stdout.writeln(instructions);
      exit(0);
    }

    try {
      final results = _nightingaleArgsParser.parse(arguments);
      switch (results.command?.name) {
        case "migrate":
          final from = int.tryParse(results.command!["from"] ?? "");
          final until = int.tryParse(results.command!["until"] ?? "");
          await migrate(from: from, until: until);
          return;

        case "rollback":
          final until = int.tryParse(results.command!["until"] ?? "");
          await rollback(until: until);
          return;

        case "status":
          final status = await getStatus();
          for (final row in status) {
            final {
              "index": int index,
              "name": String name,
              "applied": bool applied,
            } = row;
            stdout.writeln('[${applied ? "×" : " "}]\t$index: $name');
          }
          return;

        default:
          stderr.writeln(instructions);
          exit(1);
      }
    } on Exception catch (e) {
      stderr.writeln("Error: $e");
      exit(1);
    }
  }
}
