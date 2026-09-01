import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/advisory.dart';

/// History screen — chronological list of past advisories.
/// Currently populated with static mock data.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: _mockHistory.length,
        itemBuilder: (context, index) {
          final entry = _mockHistory[index];
          return _HistoryTile(entry: entry);
        },
      ),
    );
  }
}

class _HistoryEntry {
  final Advisory advisory;
  final DateTime timestamp;
  final bool acknowledged;

  const _HistoryEntry({
    required this.advisory,
    required this.timestamp,
    this.acknowledged = false,
  });
}

final List<_HistoryEntry> _mockHistory = [
  _HistoryEntry(
    advisory: const Advisory(
      type: 'irrigation',
      severity: 'warning',
      title: 'Irrigate now',
      message: 'Low soil moisture detected. Irrigate this zone for 15 minutes.',
      action: 'START_IRRIGATION',
    ),
    timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
    acknowledged: true,
  ),
  _HistoryEntry(
    advisory: const Advisory(
      type: 'heat',
      severity: 'warning',
      title: 'Heat-stress risk',
      message: 'High temperature and dry soil. Irrigate during cooler hours.',
      action: 'SCHEDULE_EVENING_IRRIGATION',
    ),
    timestamp: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  _HistoryEntry(
    advisory: const Advisory(
      type: 'flood',
      severity: 'critical',
      title: 'Flood-risk alert',
      message: 'High water level or intense rainfall detected. Check drainage immediately.',
      action: 'CHECK_DRAINAGE',
    ),
    timestamp: DateTime.now().subtract(const Duration(hours: 6)),
    acknowledged: true,
  ),
  _HistoryEntry(
    advisory: const Advisory(
      type: 'disease',
      severity: 'warning',
      title: 'Possible early blight',
      message: 'Leaf scan detected possible early blight on tomato crop.',
      action: 'INSPECT_CROP',
    ),
    timestamp: DateTime.now().subtract(const Duration(days: 1)),
  ),
  _HistoryEntry(
    advisory: const Advisory(
      type: 'pest',
      severity: 'info',
      title: 'Low pest activity',
      message: 'Routine scan shows minimal pest presence. Continue monitoring.',
      action: 'MONITOR',
    ),
    timestamp: DateTime.now().subtract(const Duration(days: 2)),
    acknowledged: true,
  ),
];

class _HistoryTile extends StatefulWidget {
  final _HistoryEntry entry;
  const _HistoryTile({required this.entry});

  @override
  State<_HistoryTile> createState() => _HistoryTileState();
}

class _HistoryTileState extends State<_HistoryTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    return Card(
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_typeIcon(entry.advisory.type), size: 20, color: _severityColor(entry.advisory.severity)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      entry.advisory.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (entry.acknowledged)
                    const Icon(Icons.check_circle, size: 16, color: AppColors.severityOk),
                  const SizedBox(width: 8),
                  Text(
                    _timeAgo(entry.timestamp),
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 12),
                Text(
                  entry.advisory.message,
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'irrigation': return Icons.water_drop;
      case 'disease': return Icons.local_florist;
      case 'pest': return Icons.bug_report;
      case 'heat': return Icons.thermostat;
      case 'flood': return Icons.flood;
      default: return Icons.info_outline;
    }
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'critical': return AppColors.severityCritical;
      case 'warning': return AppColors.severityWarning;
      default: return AppColors.severityInfo;
    }
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
