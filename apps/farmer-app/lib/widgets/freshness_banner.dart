import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/repositories/farm_state_repository.dart';

/// Banner showing data freshness (Live / Stale / Offline).
class FreshnessBanner extends StatelessWidget {
  final DataFreshness freshness;
  final DateTime? lastFetchTime;

  const FreshnessBanner({
    super.key,
    required this.freshness,
    this.lastFetchTime,
  });

  @override
  Widget build(BuildContext context) {
    if (freshness == DataFreshness.live) return const SizedBox.shrink();

    final Color bg;
    final Color fg;
    final IconData icon;
    final String text;

    switch (freshness) {
      case DataFreshness.stale:
        bg = AppColors.severityWarningBg;
        fg = AppColors.severityWarning;
        icon = Icons.access_time;
        text = lastFetchTime != null
            ? 'Data may be outdated · Last sync: ${_timeAgo(lastFetchTime!)}'
            : 'Data may be outdated';
        break;
      case DataFreshness.offline:
        bg = AppColors.severityCriticalBg;
        fg = AppColors.severityCritical;
        icon = Icons.cloud_off;
        text = lastFetchTime != null
            ? 'Offline · Last sync: ${_timeAgo(lastFetchTime!)}'
            : 'Offline · No data yet';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: bg,
      child: Row(
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: fg, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    return '${diff.inHours}h ago';
  }
}
