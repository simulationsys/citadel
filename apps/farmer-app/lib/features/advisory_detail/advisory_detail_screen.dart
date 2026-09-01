import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/advisory.dart';
import '../../data/repositories/farm_state_repository.dart';

/// Detail screen for a single advisory — shows full info and action buttons.
class AdvisoryDetailScreen extends StatelessWidget {
  const AdvisoryDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final advisory = ModalRoute.of(context)!.settings.arguments as Advisory;

    return Scaffold(
      appBar: AppBar(title: const Text('Advisory Detail')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type + severity header.
            _TypeHeader(advisory: advisory),
            const SizedBox(height: 20),

            // Title.
            Text(
              advisory.title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Message.
            Text(
              advisory.message,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // Supporting sensor readings (from current farm state).
            Consumer<FarmStateProvider>(
              builder: (context, provider, _) {
                if (provider.farmState == null) return const SizedBox.shrink();
                final r = provider.farmState!.reading;
                return _SupportingReadings(
                  soilMoisture: r.soilMoisturePct,
                  temperature: r.temperatureC,
                  humidity: r.humidityPct,
                  rainfall: r.rainfallMm,
                  waterLevel: r.waterLevelPct,
                );
              },
            ),
            const SizedBox(height: 32),

            // Action buttons.
            _ActionButtons(advisory: advisory),
          ],
        ),
      ),
    );
  }
}

class _TypeHeader extends StatelessWidget {
  final Advisory advisory;
  const _TypeHeader({required this.advisory});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _severityBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_typeIcon, size: 16, color: _severityColor),
              const SizedBox(width: 6),
              Text(
                advisory.type.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _severityColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _severityBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            advisory.severity.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _severityColor,
            ),
          ),
        ),
      ],
    );
  }

  Color get _severityColor {
    switch (advisory.severity) {
      case 'critical':
        return AppColors.severityCritical;
      case 'warning':
        return AppColors.severityWarning;
      default:
        return AppColors.severityInfo;
    }
  }

  Color get _severityBg {
    switch (advisory.severity) {
      case 'critical':
        return AppColors.severityCriticalBg;
      case 'warning':
        return AppColors.severityWarningBg;
      default:
        return AppColors.severityInfoBg;
    }
  }

  IconData get _typeIcon {
    switch (advisory.type) {
      case 'irrigation':
        return Icons.water_drop;
      case 'disease':
        return Icons.local_florist;
      case 'pest':
        return Icons.bug_report;
      case 'heat':
        return Icons.thermostat;
      case 'flood':
        return Icons.flood;
      default:
        return Icons.info_outline;
    }
  }
}

class _SupportingReadings extends StatelessWidget {
  final double soilMoisture;
  final double temperature;
  final double humidity;
  final double rainfall;
  final double waterLevel;

  const _SupportingReadings({
    required this.soilMoisture,
    required this.temperature,
    required this.humidity,
    required this.rainfall,
    required this.waterLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Supporting Readings',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          _ReadingRow('Soil Moisture', '${soilMoisture.toStringAsFixed(0)}%'),
          _ReadingRow('Temperature', '${temperature.toStringAsFixed(0)}°C'),
          _ReadingRow('Humidity', '${humidity.toStringAsFixed(0)}%'),
          _ReadingRow('Rainfall', '${rainfall.toStringAsFixed(0)} mm'),
          _ReadingRow('Water Level', '${waterLevel.toStringAsFixed(0)}%'),
        ],
      ),
    );
  }
}

class _ReadingRow extends StatelessWidget {
  final String label;
  final String value;
  const _ReadingRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatefulWidget {
  final Advisory advisory;
  const _ActionButtons({required this.advisory});

  @override
  State<_ActionButtons> createState() => _ActionButtonsState();
}

class _ActionButtonsState extends State<_ActionButtons> {
  bool _acted = false;

  @override
  Widget build(BuildContext context) {
    if (_acted) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.severityOkBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: AppColors.severityOk),
            SizedBox(width: 8),
            Text(
              'Response recorded',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.severityOk,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary action.
        ElevatedButton.icon(
          onPressed: () => _handleAction(approved: true),
          icon: Icon(_actionIcon),
          label: Text(_actionLabel),
        ),
        const SizedBox(height: 8),
        // Decline.
        OutlinedButton(
          onPressed: () => _handleAction(approved: false),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Decline'),
        ),

        // Disclaimer.
        const SizedBox(height: 16),
        const Text(
          'Note: This is a recommendation, not an automatic action. '
          'Irrigation will not start unless physically approved.',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _handleAction({required bool approved}) {
    context
        .read<FarmStateProvider>()
        .handleIrrigation(widget.advisory.action, approved: approved);
    setState(() => _acted = true);
  }

  String get _actionLabel {
    switch (widget.advisory.action) {
      case 'START_IRRIGATION':
        return 'Approve Irrigation';
      case 'SCHEDULE_EVENING_IRRIGATION':
        return 'Remind me at 6 PM';
      case 'CHECK_DRAINAGE':
        return 'Mark as Checked';
      default:
        return 'Acknowledge';
    }
  }

  IconData get _actionIcon {
    switch (widget.advisory.action) {
      case 'START_IRRIGATION':
        return Icons.water_drop;
      case 'SCHEDULE_EVENING_IRRIGATION':
        return Icons.schedule;
      case 'CHECK_DRAINAGE':
        return Icons.check_circle_outline;
      default:
        return Icons.done;
    }
  }
}
