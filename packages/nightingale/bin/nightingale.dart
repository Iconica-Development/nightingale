import "dart:io";

Future<void> main(List<String> args) async {
  final projectDir = Directory.current.path;
  final path = "$projectDir/tool/nightingale.dart";
  if (!File(path).existsSync()) {
    stderr.writeln(
      "Error: tool/nightingale.dart not found in $projectDir",
    );
    stderr.writeln(
      "Create this file to provide migrations and database connection.",
    );
    exit(2);
  }

  final process = await Process.start(
    "dart",
    ["run", path, ...args],
    runInShell: true,
    workingDirectory: projectDir,
  );

  await stdout.addStream(process.stdout);
  await stderr.addStream(process.stderr);

  final code = await process.exitCode;
  exit(code);
}
