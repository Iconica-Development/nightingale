import "package:args/args.dart";

ArgParser getNightingaleArgsParser() {
  final parser = ArgParser(usageLineLength: 80);

  parser.addCommand("status");

  final migrate = parser.addCommand("migrate");
  migrate.addOption(
    "from",
    abbr: "f",
    help: "Start migration from version",
    valueHelp: "N",
  );
  migrate.addOption(
    "until",
    abbr: "u",
    help: "Run migrations until version",
    valueHelp: "N",
  );

  final rollback = parser.addCommand("rollback");
  rollback.addOption(
    "until",
    abbr: "u",
    help: "Rollback until version",
    valueHelp: "N",
  );

  return parser;
}
