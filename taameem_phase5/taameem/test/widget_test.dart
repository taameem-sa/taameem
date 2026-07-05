import 'package:flutter_test/flutter_test.dart';

import 'package:taameem/main.dart';

void main() {
  test('TaameemApp can be created', () {
    const app = TaameemApp(showOnboarding: true);
    expect(app, isNotNull);
  });
}
