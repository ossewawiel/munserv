import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'demo_account.freezed.dart';

/// The demo account groups the app offers. Admin groups are web only.
enum DemoAccountGroup {
  member,
  groundAdmin;

  /// Parses the wire value (`member`, `ground_admin`); null for any other.
  static DemoAccountGroup? fromWire(String value) => switch (value) {
    'member' => member,
    'ground_admin' => groundAdmin,
    _ => null,
  };
}

/// A dev account offered on the login page of demo and dev builds.
@freezed
abstract class DemoAccount with _$DemoAccount {
  const DemoAccount._();

  const factory DemoAccount({
    required DemoAccountGroup group,
    required String name,
    required String email,
    required String password,
  }) = _DemoAccount;
}

/// Parses the `DEMO_ACCOUNTS` build define: a JSON array of account objects.
///
/// Returns no accounts for a blank string, invalid JSON or a non-list value.
/// Entries without a known group or without three string fields are dropped.
List<DemoAccount> parseDemoAccounts(String raw) {
  if (raw.trim().isEmpty) return const [];

  final Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException {
    return const [];
  }
  if (decoded is! List<Object?>) return const [];

  return [for (final entry in decoded) ?_parseEntry(entry)];
}

DemoAccount? _parseEntry(Object? entry) {
  if (entry is! Map<String, Object?>) return null;
  final group = entry['group'];
  final name = entry['name'];
  final email = entry['email'];
  final password = entry['password'];
  if (group is! String ||
      name is! String ||
      email is! String ||
      password is! String) {
    return null;
  }
  final parsedGroup = DemoAccountGroup.fromWire(group);
  if (parsedGroup == null) return null;
  return DemoAccount(
    group: parsedGroup,
    name: name,
    email: email,
    password: password,
  );
}
