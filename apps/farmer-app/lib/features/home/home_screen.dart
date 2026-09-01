import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/advisory.dart';
import '../../data/repositories/farm_state_repository.dart';
import '../../widgets/advisory_card.dart';
import '../../widgets/freshness_banner.dart';
import '../../widgets/sensor_tile.dart';

/// Main home screen — the farmer's primary action surface.
/// Shows urgent advisories first, then sensor readings.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch farm state on first load.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<FarmStateProvider>().refreshFarmState();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Citadel Farm'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: Consumer<FarmStateProvider>(
        builder: (context, provider, _) {
          return RefreshIndicator(
            onRefresh: provider.refreshFarmState,
            color: AppColors.primaryGreen,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                // Freshness banner.
                FreshnessBanner(
                  freshness: provider.freshness,
                  lastFetchTime: provider.lastFetchTime,
                ),

                // Loading indicator.
                if (provider.isLoading && provider.farmState == null)
                  const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (provider.farmState != null) ...[
                  // Zone & status header.
                  _ZoneHeader(provider: provider),

                  // Advisory cards — urgent first.
                  if (provider.farmState!.sortedAdvisories.isNotEmpty) ...[
                    const _SectionTitle(text: 'Alerts'),
                    ...provider.farmState!.sortedAdvisories.map(
                      (advisory) => AdvisoryCard(
                        advisory: advisory,
                        onTap: () => _openAdvisoryDetail(context, advisory),
                      ),
                    ),
                  ] else
                    const _NoAlertsCard(),

                  // Sensor readings strip.
                  const _SectionTitle(text: 'Field Readings'),
                  _SensorStrip(provider: provider),

                  const SizedBox(height: 16),

                  // Quick actions.
                  _QuickActions(),

                  const SizedBox(height: 24),
                ] else if (provider.error != null)
                  _ErrorCard(error: provider.error!),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openAdvisoryDetail(BuildContext context, Advisory advisory) {
    Navigator.pushNamed(context, '/advisory-detail', arguments: advisory);
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _ZoneHeader extends StatelessWidget {
  final FarmStateProvider provider;
  const _ZoneHeader({required this.provider});

  @override
  Widget build(BuildContext context) {
    final reading = provider.farmState!.reading;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on, size: 16, color: AppColors.primaryGreen),
                const SizedBox(width: 4),
                Text(
                  reading.zoneId.replaceAll('-', ' ').toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _FreshnessChip(freshness: provider.freshness),
          const Spacer(),
          Text(
            reading.deviceId,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _FreshnessChip extends StatelessWidget {
  final DataFreshness freshness;
  const _FreshnessChip({required this.freshness});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    switch (freshness) {
      case DataFreshness.live:
        color = AppColors.statusLive;
        label = 'LIVE';
        break;
      case DataFreshness.stale:
        color = AppColors.statusStale;
        label = 'STALE';
        break;
      case DataFreshness.offline:
        color = AppColors.statusOffline;
        label = 'OFFLINE';
        break;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _NoAlertsCard extends StatelessWidget {
  const _NoAlertsCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.severityOkBg,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.severityOk, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'All clear',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'No alerts right now. Field conditions look good.',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SensorStrip extends StatelessWidget {
  final FarmStateProvider provider;
  const _SensorStrip({required this.provider});

  @override
  Widget build(BuildContext context) {
    final r = provider.farmState!.reading;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SensorTile(
              icon: Icons.water_drop,
              label: 'Soil',
              value: r.soilMoisturePct.toStringAsFixed(0),
              unit: '%',
              valueColor: r.soilMoisturePct < 30 ? AppColors.severityWarning : null,
            ),
            SensorTile(
              icon: Icons.thermostat,
              label: 'Temp',
              value: r.temperatureC.toStringAsFixed(0),
              unit: '°C',
              valueColor: r.temperatureC >= 38 ? AppColors.severityCritical : null,
            ),
            SensorTile(
              icon: Icons.air,
              label: 'Humidity',
              value: r.humidityPct.toStringAsFixed(0),
              unit: '%',
            ),
            SensorTile(
              icon: Icons.grain,
              label: 'Rain',
              value: r.rainfallMm.toStringAsFixed(0),
              unit: 'mm',
            ),
            SensorTile(
              icon: Icons.waves,
              label: 'Water',
              value: r.waterLevelPct.toStringAsFixed(0),
              unit: '%',
              valueColor: r.waterLevelPct >= 75 ? AppColors.severityCritical : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/scan'),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Scan Crop'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/history'),
              icon: const Icon(Icons.history),
              label: const Text('History'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryGreen,
                side: const BorderSide(color: AppColors.primaryGreen),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String error;
  const _ErrorCard({required this.error});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.severityCriticalBg,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: AppColors.severityCritical, size: 32),
            const SizedBox(height: 8),
            const Text(
              'Could not fetch farm data',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              error,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
