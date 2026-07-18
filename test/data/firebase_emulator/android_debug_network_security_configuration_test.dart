import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android debug cleartext traffic is limited to the emulator host', () {
    final manifest = File(
      'android/app/src/debug/AndroidManifest.xml',
    ).readAsStringSync();
    final networkSecurityConfiguration = File(
      'android/app/src/debug/res/xml/network_security_config.xml',
    ).readAsStringSync();

    expect(
      manifest,
      contains(
        'android:networkSecurityConfig="@xml/network_security_config"',
      ),
    );
    expect(manifest, isNot(contains('usesCleartextTraffic')));
    expect(
      networkSecurityConfiguration,
      contains('cleartextTrafficPermitted="true"'),
    );
    expect(
      RegExp(r'<domain[^>]*>([^<]+)</domain>')
          .allMatches(networkSecurityConfiguration)
          .map((match) => match.group(1))
          .toList(),
      ['10.0.2.2'],
    );
  });
}
