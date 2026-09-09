import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_settings_provider.dart';
import '../../core/config/app_strings.dart';
import '../../core/config/edge_config.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/reading.dart';
import '../../data/repositories/farm_state_repository.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/citadel_logo.dart';
import '../../widgets/freshness_banner.dart';
import '../../widgets/profile_avatar_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<FarmStateProvider>().refreshFarmState();
      }
    });
    _pollTimer = Timer.periodic(AppConstants.pollInterval, (_) {
      if (mounted) context.read<FarmStateProvider>().refreshFarmState();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _showWeatherForecastDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.wb_sunny, color: Colors.orange),
            SizedBox(width: 8),
            Text('Rohtak Weather (5-Day)'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('• Today: 34°C, Clear Skies, Humid'),
            Text('• Tomorrow: 33°C, Partly Cloudy'),
            Text('• Day 3: 31°C, Moderate Rain Expected (15mm)'),
            Text('• Day 4: 29°C, Heavy Rain Expected (25mm)'),
            Text('• Day 5: 32°C, Sunny'),
          ],
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showSensorDetailDialog(BuildContext context, String title, String value,
      String status, {Reading? reading}) {
    final sampledAt = reading?.receivedAt ?? reading?.capturedAt;
    final transmitted = sampledAt == null ? 'Not reported' : sampledAt.toLocal().toString();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('$title Sensor Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Reading: $value', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Status: $status', style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Text('Device: ${reading?.deviceId ?? 'Not connected'}'),
            Text('Zone: ${reading?.zoneId ?? 'Not reported'}'),
            Text('Last received: $transmitted'),
          ],
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showCropTrackDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.agriculture, color: AppColors.primaryGreen),
            SizedBox(width: 8),
            Text('Cotton Plot A Details'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('• Total Area: 4.5 hectares'),
            Text('• Crop Stage: Day 78 (Boll Opening)'),
            Text('• Health Score: 96% Healthy'),
            Text('• Estimated Harvest: 22 days remaining'),
            Text('• Expected Yield: 3.2 Tonnes/ha'),
          ],
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: _buildBody(),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      titleSpacing: 16,
      title: Row(
        children: [
          const CitadelLogo(size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppStrings.translate('Citadel Farm', settings.language),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.primaryGreen, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        AppStrings.translate('Local edge monitoring', settings.language),
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        const ProfileAvatarButton(margin: EdgeInsets.only(right: 16, left: 12)),
      ],
    );
  }

  Widget _buildBody() {
    return Consumer3<FarmStateProvider, EdgeConfig, AppSettingsProvider>(
      builder: (context, provider, edge, settings, _) {
        final Reading? reading = provider.farmState?.reading;
        final advisories = provider.farmState?.sortedAdvisories ?? const [];
        final critical = advisories.where((a) => a.severity == 'critical').toList();
        final topAlert = critical.isNotEmpty
            ? critical.first
            : (advisories.isNotEmpty ? advisories.first : null);
        return RefreshIndicator(
          onRefresh: provider.refreshFarmState,
          color: AppColors.primaryGreen,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              FreshnessBanner(freshness: provider.freshness, lastFetchTime: provider.lastFetchTime),
              const SizedBox(height: 8),
              _buildGreetingSection(reading, settings),
              const SizedBox(height: 16),
              _buildStatusPill(provider, edge, settings),
              const SizedBox(height: 24),
              _buildHighSeverityAlert(topAlert),
              const SizedBox(height: 24),
              _buildSectionTitle(
                AppStrings.translate('Real-time Sensors', settings.language),
                actionText: reading == null
                    ? 'Waiting for node'
                    : '${reading.zoneId} • ${reading.reportedMetricCount}/5 reporting',
                onActionTap: () => _showSensorDetailDialog(
                  context,
                  'Field Node',
                  reading == null ? '--' : '${reading.reportedMetricCount}/5 metrics',
                  provider.freshness.name,
                  reading: reading,
                ),
              ),
              const SizedBox(height: 12),
              _buildSensorsGrid(reading),
              const SizedBox(height: 24),
              _buildSectionTitle(
                AppStrings.translate('Active Crop Track', settings.language),
                actionText: 'All Plots',
                onActionTap: () => _showCropTrackDialog(context),
              ),
              const SizedBox(height: 12),
              _buildCropTrackCard(settings),
              const SizedBox(height: 16),
              _buildScheduledIrrigationCard(settings),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGreetingSection(Reading? reading, AppSettingsProvider settings) {
    final temp = '${Reading.display(reading?.temperatureC)}°C';
    final greeting = '${AppStrings.translate('Good Morning', settings.language)},\n${settings.userName}';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/profile'),
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primaryGreen.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(4),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: settings.profileImagePath != null
                        ? Image.file(
                            File(settings.profileImagePath!),
                            fit: BoxFit.cover,
                            width: 76,
                            height: 76,
                          )
                        : Image.asset(
                            'assets/images/farmer_avatar.png',
                            fit: BoxFit.contain,
                            width: 76,
                            height: 76,
                          ),
                  ),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.1, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                '${AppStrings.translate('Wednesday', settings.language)}, 28 ${AppStrings.translate('May', settings.language)}\n${AppStrings.translate(settings.farmingCycle, settings.language)}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () => _showWeatherForecastDialog(context),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wb_sunny, color: Color(0xFFF57C00), size: 16),
                const SizedBox(width: 4),
                Text(
                  'Rohtak\n$temp',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusPill(FarmStateProvider provider, EdgeConfig edge, AppSettingsProvider settings) {
    final freshness = provider.freshness;
    final ago = provider.lastFetchTime == null
        ? 'never'
        : '${DateTime.now().difference(provider.lastFetchTime!).inMinutes}m ago';
    final label = freshness == DataFreshness.live
        ? AppStrings.translate('Live • Synced just now', settings.language)
        : freshness == DataFreshness.stale
            ? 'Stale • Synced $ago'
            : 'Offline Ready • Synced $ago';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: freshness == DataFreshness.live
                                ? AppColors.primaryGreen
                                : freshness == DataFreshness.stale
                                    ? Colors.amber
                                    : Colors.red,
                            shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(label,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text('Edge: ${edge.normalizedBaseUrl} • ${edge.zoneId}',
            style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
      ],
    );
  }

  Widget _buildHighSeverityAlert(dynamic topAlert) {
    final String title;
    final String message;
    final String tag;
    if (topAlert != null) {
      title = AppStrings.translate(topAlert.title as String, context.read<AppSettingsProvider>().language);
      message = AppStrings.translate(topAlert.message as String, context.read<AppSettingsProvider>().language);
      tag = AppStrings.translate('${topAlert.severity.toString().toUpperCase()} • ${topAlert.type.toString().toUpperCase()} ALERT', context.read<AppSettingsProvider>().language);
    } else {
      title = AppStrings.translate('Whitefly Infestation Detected Nearby', context.read<AppSettingsProvider>().language);
      message = AppStrings.translate('Active in North Cotton field — apply organic neem spray before 5:00 PM to secure boll formation.', context.read<AppSettingsProvider>().language);
      tag = AppStrings.translate('HIGH SEVERITY • PEST ALERT', context.read<AppSettingsProvider>().language);
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.severityCriticalBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.severityCritical, size: 14),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          tag,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.severityCritical, letterSpacing: 0.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(AppStrings.translate('20 mins ago', context.read<AppSettingsProvider>().language), style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (topAlert != null && topAlert.type == 'irrigation') {
                  Navigator.pushNamed(context, '/advisory-detail');
                } else {
                  Navigator.pushNamed(context, '/scan');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.severityCritical,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.medical_services_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text(AppStrings.translate('View Treatment Plan', context.read<AppSettingsProvider>().language), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {String? actionText, VoidCallback? onActionTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(AppStrings.translate(title, context.read<AppSettingsProvider>().language), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        if (actionText != null)
          InkWell(
            onTap: onActionTap,
            child: Text(AppStrings.translate(actionText, context.read<AppSettingsProvider>().language), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryGreen)),
          ),
      ],
    );
  }

  Widget _buildSensorsGrid(Reading? reading) {
    final lang = context.read<AppSettingsProvider>().language;
    final moisture = '${Reading.display(reading?.soilMoisturePct)}%';
    final temp = '${Reading.display(reading?.temperatureC)}°C';
    final humidity = '${Reading.display(reading?.humidityPct)}%';
    final rainfall = '${Reading.display(reading?.rainfallMm, decimals: 1)} mm';
    final waterLevel = '${Reading.display(reading?.waterLevelPct)}%';

    ({String text, Color color, Color background}) status(
      double? value, String normal, bool Function(double) isWarning, String warning) {
      if (value == null) {
        return (text: 'Not reporting', color: AppColors.textSecondary,
          background: Colors.grey[200]!);
      }
      if (isWarning(value)) {
        return (text: warning, color: AppColors.severityCritical,
          background: AppColors.severityCriticalBg);
      }
      return (text: normal, color: AppColors.primaryGreen,
        background: AppColors.cardGreenBg);
    }

    final moistureStatus = status(reading?.soilMoisturePct, 'Sensor live',
        (value) => value < 30, 'Low moisture');
    final temperatureStatus = status(reading?.temperatureC, 'Sensor live',
        (value) => value >= 38, 'High heat');
    final humidityStatus = status(reading?.humidityPct, 'Sensor live',
        (value) => value >= 85, 'High humidity');
    final rainfallStatus = status(reading?.rainfallMm, 'No rain detected',
        (value) => value > 0, 'Rain detected');
    final waterStatus = status(reading?.waterLevelPct, 'Sensor live',
        (value) => value >= 75, 'High water');

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildSensorCard(
          title: AppStrings.translate('Moisture', lang),
          value: moisture,
          statusText: AppStrings.translate(moistureStatus.text, lang),
          statusColor: moistureStatus.color,
          statusBgColor: moistureStatus.background,
          iconData: Icons.water_drop,
          assetPath: 'assets/water_on_soil_for_irrigation.png',
          iconColor: Colors.blue[300]!,
          iconBg: Colors.blue[50]!,
          onTap: () => _showSensorDetailDialog(context,
              AppStrings.translate('Soil Moisture', lang), moisture,
              AppStrings.translate(moistureStatus.text, lang), reading: reading),
        ),
        _buildSensorCard(
          title: AppStrings.translate('Temp', lang),
          value: temp,
          statusText: AppStrings.translate(temperatureStatus.text, lang),
          statusColor: temperatureStatus.color,
          statusBgColor: temperatureStatus.background,
          iconData: Icons.thermostat,
          assetPath: 'assets/temp_scale.png',
          iconColor: Colors.orange[700]!,
          iconBg: Colors.orange[50]!,
          onTap: () => _showSensorDetailDialog(context,
              AppStrings.translate('Air Temperature', lang), temp,
              AppStrings.translate(temperatureStatus.text, lang), reading: reading),
        ),
        _buildSensorCard(
          title: AppStrings.translate('Humidity', lang),
          value: humidity,
          statusText: AppStrings.translate(humidityStatus.text, lang),
          statusColor: humidityStatus.color,
          statusBgColor: humidityStatus.background,
          iconData: Icons.air,
          assetPath: 'assets/humidity.png',
          iconColor: AppColors.primaryGreen,
          iconBg: AppColors.cardGreenBg,
          onTap: () => _showSensorDetailDialog(context,
              AppStrings.translate('Air Humidity', lang), humidity,
              AppStrings.translate(humidityStatus.text, lang), reading: reading),
        ),
        _buildSensorCard(
          title: AppStrings.translate('Rainfall', lang),
          value: rainfall,
          statusText: AppStrings.translate(rainfallStatus.text, lang),
          statusColor: rainfallStatus.color,
          statusBgColor: rainfallStatus.background,
          iconData: Icons.grain,
          assetPath: 'assets/rainfall.png',
          iconColor: Colors.blueGrey,
          iconBg: Colors.blueGrey[50]!,
          onTap: () => _showSensorDetailDialog(context, 'Rainfall', rainfall,
              rainfallStatus.text, reading: reading),
        ),
        _buildSensorCard(
          title: AppStrings.translate('Water Level', lang),
          value: waterLevel,
          statusText: AppStrings.translate(waterStatus.text, lang),
          statusColor: waterStatus.color,
          statusBgColor: waterStatus.background,
          iconData: Icons.water,
          assetPath: 'assets/water_droplet.png',
          iconColor: Colors.blue[700]!,
          iconBg: Colors.blue[50]!,
          onTap: () => _showSensorDetailDialog(context, 'Water Level', waterLevel,
              waterStatus.text, reading: reading),
        ),
      ],
    );
  }

  Widget _buildSensorCard({
    required String title,
    required String value,
    required String statusText,
    required Color statusColor,
    required Color statusBgColor,
    required IconData iconData,
    String? assetPath,
    required Color iconColor,
    required Color iconBg,
    IconData? statusIcon,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                  child: assetPath == null
                      ? Icon(iconData, color: iconColor, size: 20)
                      : Image.asset(
                          assetPath,
                          width: 28,
                          height: 28,
                          cacheWidth: 84,
                          cacheHeight: 84,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                ),
                Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
              ],
            ),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (statusIcon != null) ...[
                    Icon(statusIcon, color: statusColor, size: 12),
                    const SizedBox(width: 4),
                  ] else ...[
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: Text(
                      statusText,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropTrackCard(AppSettingsProvider settings) {
    return InkWell(
      onTap: () => _showCropTrackDialog(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                image: DecorationImage(
                  image: AssetImage('assets/images/wheat_crop.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(4)),
                      child: const Text('4.5 ha', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            AppStrings.translate(settings.userCrops.isNotEmpty ? settings.userCrops.first : 'Cotton Field Plot A', settings.language),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFF5EE085), borderRadius: BorderRadius.circular(12)),
                          child: const Text('• 96% Healthy', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: const [
                        Icon(Icons.calendar_today, size: 12, color: AppColors.textSecondary),
                        SizedBox(width: 4),
                        Text('Day 78', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        SizedBox(width: 6),
                        Text('•', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text('Boll Opening', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryGreen), overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Stack(
                      children: [
                        Container(height: 6, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(3))),
                        Container(height: 6, width: 140, decoration: BoxDecoration(color: AppColors.primaryGreen, borderRadius: BorderRadius.circular(3))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Harvest window in 22 days', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                        Text('72%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduledIrrigationCard(AppSettingsProvider settings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: AppColors.primaryGreen, shape: BoxShape.circle),
            child: const Icon(Icons.water_drop, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.translate('Scheduled Irrigation', settings.language), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                const Text('Next cycle at 05:30 PM (Zone 2)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/advisory-detail'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primaryGreen,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Adjust', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
