import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../core/config/app_settings_provider.dart';
import '../../core/config/app_strings.dart';
import '../../core/config/edge_config.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/reading.dart';
import '../../data/repositories/farm_state_repository.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/freshness_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _pollTimer;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<FarmStateProvider>().refreshFarmState();
      }
    });
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) context.read<FarmStateProvider>().refreshFarmState();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _speech.stop();
    super.dispose();
  }

  void _showMicDialog(BuildContext context) {
    final queryController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(sheetContext).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mic, color: AppColors.primaryGreen, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Voice Assistant Active',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Listening to your farm query… Say "What is the soil moisture level?" or "Show weather forecast".',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: queryController,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submitVoiceQuery(sheetContext, queryController.text),
              decoration: InputDecoration(
                hintText: 'Ask your farm question',
                prefixIcon: IconButton(
                  tooltip: 'Start voice input',
                  icon: Icon(_isListening ? Icons.mic_rounded : Icons.mic_none_rounded, color: AppColors.primaryGreen),
                  onPressed: () => _listenForQuery(queryController),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _submitVoiceQuery(sheetContext, queryController.text),
                icon: const Icon(Icons.send_rounded),
                label: const Text('Ask Assistant'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _listenForQuery(TextEditingController controller) async {
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    final available = await _speech.initialize(
      onStatus: (status) {
        if (mounted && (status == 'done' || status == 'notListening')) {
          setState(() => _isListening = false);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _isListening = false);
      },
    );
    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Voice input is unavailable. Check microphone permission.')));
      }
      return;
    }
    if (mounted) setState(() => _isListening = true);
    await _speech.listen(
      onResult: (result) {
        controller.value = controller.value.copyWith(
          text: result.recognizedWords,
          selection: TextSelection.collapsed(offset: result.recognizedWords.length),
        );
      },
    );
  }

  void _submitVoiceQuery(BuildContext context, String query) {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a farm question first.')));
      return;
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text('Assistant received: $normalizedQuery')));
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

  void _showSensorDetailDialog(BuildContext context, String title, String value, String status) {
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
            const Text('Node ID: Node #04 (Plot A)'),
            const Text('Battery: 98% (Solar Powered)'),
            const Text('Last Transmitted: 1 min ago'),
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.agriculture, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppStrings.translate('Citadel Farm', settings.isHindi),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.primaryGreen, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        AppStrings.translate('Online • Synced', settings.isHindi),
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
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.mic, color: AppColors.primaryGreen, size: 20),
            onPressed: () => _showMicDialog(context),
          ),
        ),
        InkWell(
          onTap: () => Navigator.pushNamed(context, '/profile'),
          child: Container(
            margin: const EdgeInsets.only(right: 16, left: 12),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: const Text('img', style: TextStyle(fontSize: 10, color: Colors.black54)),
          ),
        ),
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
                AppStrings.translate('Real-time Sensors', settings.isHindi),
                actionText: 'Field A Live',
                onActionTap: () => _showSensorDetailDialog(context, 'Field A Overview', '4 Active Nodes', 'All Operational'),
              ),
              const SizedBox(height: 12),
              _buildSensorsGrid(reading),
              const SizedBox(height: 24),
              _buildSectionTitle(
                AppStrings.translate('Active Crop Track', settings.isHindi),
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
    final temp = reading != null ? '${reading.temperatureC.toStringAsFixed(0)}°C' : '34°C';
    final greeting = settings.isHindi ? 'सुप्रभात,\n${settings.userName}' : 'Good\nMorning,\n${settings.userName}';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 100,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Center(child: Text('img', style: TextStyle(fontSize: 12, color: Colors.black54))),
              Positioned(
                bottom: -4,
                right: -4,
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
                '${AppStrings.translate('Wednesday', settings.isHindi)}, 28 ${AppStrings.translate('May', settings.isHindi)}\n${AppStrings.translate(settings.farmingCycle, settings.isHindi)}',
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
        ? AppStrings.translate('Live • Synced just now', settings.isHindi)
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
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _showMicDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              icon: const Icon(Icons.mic, size: 16),
              label: Text(AppStrings.translate('Ask AI', settings.isHindi), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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
      title = topAlert.title as String;
      message = topAlert.message as String;
      tag = '${topAlert.severity.toString().toUpperCase()} • ${topAlert.type.toString().toUpperCase()} ALERT';
    } else {
      title = 'Whitefly Infestation Detected Nearby';
      message = 'Active in North Cotton field — apply organic neem spray before 5:00 PM to secure boll formation.';
      tag = 'HIGH SEVERITY • PEST ALERT';
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
              const Text('20 mins ago', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
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
                children: const [
                  Icon(Icons.medical_services_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('View Treatment Plan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 18),
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
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        if (actionText != null)
          InkWell(
            onTap: onActionTap,
            child: Text(actionText, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryGreen)),
          ),
      ],
    );
  }

  Widget _buildSensorsGrid(Reading? reading) {
    final moisture = reading != null ? '${reading.soilMoisturePct.toStringAsFixed(0)}%' : '64%';
    final temp = reading != null ? '${reading.temperatureC.toStringAsFixed(0)}°C' : '31°C';
    final humidity = reading != null ? '${reading.humidityPct.toStringAsFixed(0)}%' : '58%';
    final moistureOk = reading == null || reading.soilMoisturePct >= 40;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildSensorCard(
          title: 'Moisture',
          value: moisture,
          statusText: moistureOk ? 'Root Optimal' : 'Needs Water',
          statusColor: moistureOk ? AppColors.primaryGreen : AppColors.severityCritical,
          statusBgColor: moistureOk ? AppColors.cardGreenBg : AppColors.severityCriticalBg,
          iconData: Icons.water_drop,
          iconColor: Colors.blue[300]!,
          iconBg: Colors.blue[50]!,
          onTap: () => _showSensorDetailDialog(context, 'Soil Moisture', moisture, moistureOk ? 'Optimal' : 'Deficit'),
        ),
        _buildSensorCard(
          title: 'Temp',
          value: temp,
          statusText: 'Clear Skies',
          statusColor: AppColors.textSecondary,
          statusBgColor: Colors.grey[200]!,
          iconData: Icons.thermostat,
          iconColor: Colors.orange[700]!,
          iconBg: Colors.orange[50]!,
          onTap: () => _showSensorDetailDialog(context, 'Air Temperature', temp, 'Normal'),
        ),
        _buildSensorCard(
          title: 'Humidity',
          value: humidity,
          statusText: 'Good Spray',
          statusColor: Colors.white,
          statusBgColor: const Color(0xFF5EE085),
          iconData: Icons.air,
          iconColor: AppColors.primaryGreen,
          iconBg: AppColors.cardGreenBg,
          onTap: () => _showSensorDetailDialog(context, 'Air Humidity', humidity, 'Ideal Spray Conditions'),
        ),
        _buildSensorCard(
          title: 'Irrigation',
          value: '6:00 PM',
          statusText: '45m Cycle',
          statusColor: AppColors.textSecondary,
          statusBgColor: const Color(0xFFE8F0FE),
          iconData: Icons.water,
          iconColor: AppColors.primaryGreen,
          iconBg: AppColors.cardGreenBg,
          statusIcon: Icons.history,
          onTap: () => Navigator.pushNamed(context, '/advisory-detail'),
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
                  child: Icon(iconData, color: iconColor, size: 20),
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
              ),
              child: Stack(
                children: [
                  const Center(child: Icon(Icons.image, color: Colors.white70)),
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
                            AppStrings.translate(settings.userCrops.isNotEmpty ? settings.userCrops.first : 'Cotton Field Plot A', settings.isHindi),
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
                Text(AppStrings.translate('Scheduled Irrigation', settings.isHindi), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
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
