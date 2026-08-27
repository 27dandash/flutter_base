import 'package:app_remote_config_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('disabled example uses defaults without Firebase startup', (
    tester,
  ) async {
    await tester.pumpWidget(const RemoteConfigExampleApp());
    await tester.pumpAndSettle();

    expect(
      find.text('Remote Config disabled; local defaults are active.'),
      findsOneWidget,
    );
    expect(find.text('Default value'), findsOneWidget);
  });
}
