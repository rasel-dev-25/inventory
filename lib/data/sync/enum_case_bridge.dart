import 'enum_column_registry.dart';

/// Converts the enum-typed columns in a row between Drift's local
/// storage format (`enum.name`, camelCase — e.g. `"mobileBanking"`) and
/// Postgres's storage format (the enum type's own labels, snake_case —
/// e.g. `"mobile_banking"`). See [EnumColumnRegistry]'s doc comment for
/// why this conversion exists at all and why it is scoped to an explicit
/// column allow-list rather than applied to every string value.
abstract final class EnumCaseBridge {
  static Map<String, Object?> toRemote(String table, Map<String, Object?> row) {
    return _convert(table, row, _camelToSnake);
  }

  static Map<String, Object?> toLocal(String table, Map<String, Object?> row) {
    return _convert(table, row, _snakeToCamel);
  }

  static Map<String, Object?> _convert(
    String table,
    Map<String, Object?> row,
    String Function(String) convert,
  ) {
    final enumColumns = EnumColumnRegistry.enumColumnsFor(table);
    if (enumColumns.isEmpty) return row;

    final result = Map<String, Object?>.from(row);
    for (final column in enumColumns) {
      final value = result[column];
      if (value is String) {
        result[column] = convert(value);
      }
    }
    return result;
  }

  static String _camelToSnake(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      final char = String.fromCharCode(rune);
      final isUpper = char != char.toLowerCase();
      if (isUpper) buffer.write('_');
      buffer.write(char.toLowerCase());
    }
    return buffer.toString();
  }

  static String _snakeToCamel(String input) {
    final parts = input.split('_');
    if (parts.isEmpty) return input;
    final buffer = StringBuffer(parts.first);
    for (final part in parts.skip(1)) {
      if (part.isEmpty) continue;
      buffer.write(part[0].toUpperCase());
      buffer.write(part.substring(1));
    }
    return buffer.toString();
  }
}
