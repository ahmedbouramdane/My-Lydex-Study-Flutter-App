import 'package:flutter_test/flutter_test.dart';

import 'package:bac_archive/core/settings_controller.dart';
import 'package:bac_archive/main.dart';

void main() {
  testWidgets('Shows verification gate when access is not granted',
      (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(settings: SettingsController()));
    await tester.pump();

    expect(find.text('Accès Privé'), findsOneWidget);
    expect(find.text('Code de vérification'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
  });
}