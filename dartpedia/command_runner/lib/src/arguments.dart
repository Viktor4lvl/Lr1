import 'dart:async';
import 'dart:collection';

import 'command_runner_base.dart';

enum OptionType { flag, option }

/// Holds the results of parsing command-line arguments.
class ArgResults {
  Command? command;
  String? commandArg;
  Map<Option, Object?>? _options;

  ArgResults({this.command, this.commandArg, Map<Option, Object?>? options}) {
    _options = options;
  }

  /// Checks if a flag (boolean option) was set.
  bool flag(String name) {
    final option = _findOption(name);
    if (option == null || option.type != OptionType.flag) return false;
    return _options?[option] == true;
  }

  /// Checks if an option (with a value) was provided.
  bool hasOption(String name) {
    final option = _findOption(name);
    if (option == null || option.type != OptionType.option) return false;
    return _options?.containsKey(option) ?? false;
  }

  /// Returns a record containing the [Option] object and its value.
  ({Option option, Object? input}) getOption(String name) {
    final option = _findOption(name);
    if (option == null) {
      throw ArgumentError('Option "$name" not found');
    }
    final value = _options?[option];
    return (option: option, input: value);
  }

  Option? _findOption(String name) {
    // Search by name or abbreviation
    for (final option in _options?.keys ?? <Option>[]) {
      if (option.name == name || option.abbr == name) {
        return option;
      }
    }
    return null;
  }
}

// The rest of the file (Argument, Command, Option) stays exactly as before.
// (I'll include it for completeness, but it's unchanged.)

abstract class Argument {
  String get name;
  String? get help;
  Object? get defaultValue;
  String? get valueHelp;
  String get usage;
}

abstract class Command extends Argument {
  @override
  String get name;
  String get description;
  bool get requiresArgument => false;
  late CommandRunner runner;
  @override
  String? help;
  @override
  String? defaultValue;
  @override
  String? valueHelp;
  final List<Option> _options = [];
  UnmodifiableSetView<Option> get options =>
      UnmodifiableSetView(_options.toSet());

  void addFlag(String name,
      {String? help, String? abbr, String? valueHelp}) {
    _options.add(Option(
      name,
      help: help,
      abbr: abbr,
      defaultValue: false,
      valueHelp: valueHelp,
      type: OptionType.flag,
    ));
  }

  void addOption(String name,
      {String? help,
      String? abbr,
      String? defaultValue,
      String? valueHelp}) {
    _options.add(Option(
      name,
      help: help,
      abbr: abbr,
      defaultValue: defaultValue,
      valueHelp: valueHelp,
      type: OptionType.option,
    ));
  }

  FutureOr<Object?> run(ArgResults args);
  @override
  String get usage => '$name:  $description';
}

class Option extends Argument {
  Option(
    this.name, {
    required this.type,
    this.help,
    this.abbr,
    this.defaultValue,
    this.valueHelp,
  });

  @override
  final String name;
  final OptionType type;
  @override
  final String? help;
  final String? abbr;
  @override
  final Object? defaultValue;
  @override
  final String? valueHelp;

  @override
  String get usage {
    if (abbr != null) {
      return '-$abbr,--$name: $help';
    }
    return '--$name: $help';
  }
}