import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/repositories/farm_state_repository.dart';
import 'data/repositories/mock_farm_state_repository.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => FarmStateProvider(MockFarmStateRepository()),
        ),
      ],
      child: const CitadelApp(),
    ),
  );
}
