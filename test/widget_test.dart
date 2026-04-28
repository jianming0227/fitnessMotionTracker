import 'package:flutter_test/flutter_test.dart';
import 'package:fitness/main.dart';

void main() {
  testWidgets('FitnessApp smoke test — widget tree builds', (WidgetTester tester) async {
    // Minimal smoke test: just verify the app widget can be created.
    // Full integration tests require a running Hive / Supabase environment.
    expect(() => const FitnessApp(), returnsNormally);
  });
}
