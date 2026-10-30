import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/demo_account.dart';

part 'demo_accounts_provider.g.dart';

const _demoAccountsDefine = 'DEMO_ACCOUNTS';

/// Demo accounts baked into this build by `--dart-define-from-file`.
/// Empty on a normal build, so the login page offers no quick login.
@Riverpod(keepAlive: true)
List<DemoAccount> demoAccounts(Ref ref) =>
    parseDemoAccounts(const String.fromEnvironment(_demoAccountsDefine));
