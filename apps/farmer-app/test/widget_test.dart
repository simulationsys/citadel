import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:citadel_farmer_app/app.dart';
import 'package:citadel_farmer_app/core/config/app_settings_provider.dart';
import 'package:citadel_farmer_app/core/config/edge_config.dart';
import 'package:citadel_farmer_app/data/repositories/farm_state_repository.dart';
import 'package:citadel_farmer_app/data/repositories/mock_farm_state_repository.dart';

void main() {
  testWidgets('Home screen renders app title', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppSettingsProvider()),
          ChangeNotifierProvider(create: (_) => EdgeConfig()),
          ChangeNotifierProvider(
            create: (_) => FarmStateProvider(MockFarmStateRepository()),
          ),
        ],
        child: const CitadelApp(),
      ),
    );
    // Flush mock fetch delay (800ms).
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Citadel Farm'), findsWidgets);

    // Dispose home (cancels 30s poll timer) so no timers leak.
    await tester.pumpWidget(Container());
  });
}
