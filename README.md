# Nightingale

This package is meant to manage migrations for you. 
It does NOT generate the migrations, you have to write those yourself. As well as the reverse of the operation.

## Setup

1. Add the dependency `nightingale` and optionally also depend on one of the default implementations:
  - postgres_nightingale

2. Create a file at the location `tool/nightingale.dart` containing a main function that executes the runner with the commands, like so:

```dart
Future<void> main(List<String> arguments) async {	
  final runner = MigrationRunner<T>(
    database: /* <provide T> */,
	  contextGenerator: /* <provide context generator> */,
    migrations: /* <provide migrations> */,
	  history: /* <provide MigrationHistory<T> implementation> */,
  );
  await runner.execute(arguments);
}
```

3. Create implementations for database, history and context generator.
4. Decide on a structure to adhere to for the migrations (e.g.: `$cwd/migrations/N`) and pass those to the runner.

# How to use

Running `dart run nightingale` will give you the available commands.

For now those are

- `dart run nightingale status`
- `dart run nightingale migrate [--from 0 --until 5]`
- `dart run nightingale rollback [--until 0]`
