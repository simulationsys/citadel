import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/advisory.dart';

/// A card that displays a single advisory with severity colour strip.
class AdvisoryCard extends StatelessWidget {
  final Advisory advisory;
  final VoidCallback? onTap;

  const AdvisoryCard({
    super.key,
    required this.advisory,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Severity colour strip.
              Container(
                width: 6,
                color: _severityColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(_typeIcon, color: _severityColor, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              advisory.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          _SeverityBadge(severity: advisory.severity),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        advisory.message,
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
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

class _SeverityBadge extends StatelessWidget {
  final String severity;

  const _SeverityBadge({required this.severity});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    switch (severity) {
      case 'critical':
        bg = AppColors.severityCriticalBg;
        fg = AppColors.severityCritical;
        break;
      case 'warning':
        bg = AppColors.severityWarningBg;
        fg = AppColors.severityWarning;
        break;
      default:
        bg = AppColors.severityInfoBg;
        fg = AppColors.severityInfo;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        severity.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
