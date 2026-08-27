import 'package:app_maps_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'showcase proves the missing-key state without native map setup',
    (tester) async {
      await tester.pumpWidget(const MapsExampleApp());
      await tester.pump();
      expect(
        find.text('Maps configuration is intentionally absent.'),
        findsOne,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
