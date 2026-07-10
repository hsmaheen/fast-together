import 'package:fasting_app/application/app_account_session.dart';
import 'package:fasting_app/application/personal_fasting_activity_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('App Account session exposes the application account identity', () {
    final session = AppAccountSession(AppAccountId('demo-account'));

    expect(session.accountId, AppAccountId('demo-account'));
  });
}
