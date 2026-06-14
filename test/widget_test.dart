import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:configedit/controllers/config_controller.dart';
import 'package:configedit/main.dart';

void main() {
  testWidgets('Smoke test - App loads', (WidgetTester tester) async {
    // Register the dependency controller required by GetX inside MyApp build.
    Get.put(ConfigController());

    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify that our main screens load.
    expect(find.text('Announce'), findsOneWidget);
    expect(find.text('Config Editor'), findsOneWidget);
  });
}
