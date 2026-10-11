import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/config/edge_config.dart';
import 'core/config/app_settings_provider.dart';
import 'data/repositories/farm_state_repository.dart';
import 'data/repositories/http_farm_state_repository.dart';
import 'data/repositories/hybrid_farm_state_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final edge = EdgeConfig();
  await edge.load();
  final appSettings = AppSettingsProvider();
  await appSettings.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appSettings),
        ChangeNotifierProvider.value(value: edge),
        // Live edge API only. There is deliberately no silent mock fallback:
        // an unreachable node must look unreachable, not like a healthy farm.
        // Offline is handled by the repository's own cache, which returns state
        // marked `fromCache` so the UI can label it stale.
        ChangeNotifierProxyProvider<EdgeConfig, FarmStateProvider>(
          create: (_) => FarmStateProvider(
            HybridFarmStateRepository(
              live: HttpFarmStateRepository(
                baseUrl: edge.baseUrl,
                zoneId: edge.zoneId,
              ),
            ),
          ),
          update: (_, edge, provider) {
            provider!.updateRepository(
              HybridFarmStateRepository(
                live: HttpFarmStateRepository(
                  baseUrl: edge.baseUrl,
                  zoneId: edge.zoneId,
                ),
              ),
            );
            return provider;
          },
        ),
      ],
      child: const CitadelApp(),
    ),
  );
}
