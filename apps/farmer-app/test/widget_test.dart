import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:citadel_farmer_app/app.dart';
import 'package:citadel_farmer_app/data/repositories/farm_state_repository.dart';
import 'package:citadel_farmer_app/data/repositories/mock_farm_state_repository.dart';

void main() {
  testWidgets('Home screen renders app title', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => FarmStateProvider(MockFarmStateRepository()),
        child: const CitadelApp(),
      ),
    );

    expect(find.text('Citadel Farm'), findsOneWidget);
  });
}
