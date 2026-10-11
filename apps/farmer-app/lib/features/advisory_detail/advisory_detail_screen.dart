import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_settings_provider.dart';
import '../../core/config/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/farm_state_repository.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/citadel_logo.dart';
import '../../widgets/profile_avatar_button.dart';

class AdvisoryDetailScreen extends StatefulWidget {
  const AdvisoryDetailScreen({super.key});

  @override
  State<AdvisoryDetailScreen> createState() => _AdvisoryDetailScreenState();
}
class _AdvisoryDetailScreenState extends State<AdvisoryDetailScreen> {
  bool _isApproved = false;
  bool _isSubmitting = false;

  String _t(String key) =>
      AppStrings.translate(key, context.read<AppSettingsProvider>().language);

  void _showNodeDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.grid_view, color: AppColors.primaryGreen),
            const SizedBox(width: 8),
            Expanded(child: Text('${_t('Telemetry Node')} #04')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• ${_t('Location')}: ${_t('Field 1: Plot A Cotton')}'),
            Text('• ${_t('Sensor Depth: 15cm Root Zone')}'),
            Text('• ${_t('Signal Strength: Excellent (-62 dBm)')}'),
            Text('• ${_t('Valve Controller: Drip Valve #3 Ready')}'),
          ],
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(context), child: Text(_t('OK'))),
        ],
      ),
    );
  }

  /// Approve irrigation.
  ///
  /// This used to be `setState(() => _isApproved = true)` and nothing else —
  /// the screen reported "Irrigation Approved" without ever contacting the
  /// edge node. The banner now flips only after the backend confirms the
  /// approval and hands back the standing relay command.
  Future<void> _handleDecision({required bool approved}) async {
    final provider = context.read<FarmStateProvider>();
    if (provider.isIrrigationBusy) return; // no double-taps

    setState(() => _isSubmitting = true);
    final ok = await provider.handleIrrigation(approved: approved);
    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _isApproved = ok && approved;
    });

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.severityCritical,
        content: Text(provider.irrigationError ??
            _t('Irrigation was NOT approved — the field node did not confirm.')),
      ));
      return;
    }

    if (!approved) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_t('Declined. The pump was not commanded.')),
      ));
      Navigator.pop(context);
      return;
    }

    final command = provider.lastIrrigationOutcome?.command;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.primaryGreen),
            const SizedBox(width: 8),
            Expanded(child: Text(_t('Irrigation Approved'))),
          ],
        ),
        // Deliberately precise: the approval is recorded and a command is
        // waiting. The pump has not run until the node collects that command
        // and acknowledges it on its next reading.
        content: Text(command == null
            ? _t('Approval recorded by the field node.')
            : '${_t('Approval recorded. The field node will start')} '
              '${command.actuatorId} ${_t('for up to')} '
              '${(command.maxRuntimeSec / 60).round()} '
              '${_t('minutes when it next checks in, and will report back once the relay is on.')}'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(_t('Return to Dashboard')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      titleSpacing: 16,
      automaticallyImplyLeading: false,
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
                  _t('Citadel Farm'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.primaryGreen, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _t('Online • Synced'),
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
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFC78446), shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _t('LIVE SOIL TELEMETRY'),
                      style: const TextStyle(color: Color(0xFFC78446), fontSize: 10, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _showNodeDetails(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFE8F0FE), borderRadius: BorderRadius.circular(12)),
                child: Text('${_t('Node')} #04', style: const TextStyle(color: AppColors.textPrimary, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _t('Irrigation Advisory Detail'),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.location_on_outlined, color: AppColors.primaryGreen, size: 16),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                _t('Field 1: Plot A Cotton'),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        _buildSoilMoistureProfile(),
        const SizedBox(height: 16),
        _buildAgronomicReason(),
        const SizedBox(height: 16),
        _buildExecutionSequence(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSoilMoistureProfile() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_t('Soil Moisture Profile'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              Text(_t('Deficit Detected'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFC78446))),
            ],
          ),
          const SizedBox(height: 24),
          
          Center(
            child: SizedBox(
              width: 200,
              height: 120,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  CustomPaint(
                    size: const Size(200, 100),
                    painter: _ArcPainter(percentage: 0.42),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('42%', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      Text(_t('Current Moisture'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFC78446))),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_t('Threshold'), style: const TextStyle(color: Color(0xFFC78446), fontSize: 12, fontWeight: FontWeight.bold)),
                  Text('< 50% ${_t('Critical')}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
              Container(width: 1, height: 24, color: Colors.grey[300]),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_t('Target'), style: const TextStyle(color: AppColors.primaryGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                  Text('65% (${_t('Optimal')})', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF4F6FF), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.wb_sunny_outlined, color: Colors.orange[700], size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_t('High Evaporation Forecast'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text(_t('0% Rain expected in 48h • Soil dries rapidly'), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgronomicReason() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_outlined, color: AppColors.primaryGreen, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(_t('Agronomic Reason'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _t('Moisture level is below the 55% root threshold during flowering stage. Watering today protects bloom retention.'),
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.4),
          ),
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(color: const Color(0xFFF4F6FF), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      const Icon(Icons.timer_outlined, color: AppColors.primaryGreen, size: 16),
                      const SizedBox(height: 6),
                      Text(_t('Duration'), style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      Text('45 ${_t('mins')}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      Text(_t('Drip line'), style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(color: AppColors.cardGreenBg, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      const Icon(Icons.water_drop_outlined, color: AppColors.primaryGreen, size: 16),
                      const SizedBox(height: 6),
                      Text(_t('Volume'), style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      const Text('1,200 L', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                      Text(_t('Calculated'), style: const TextStyle(fontSize: 10, color: AppColors.primaryGreen)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(color: const Color(0xFFFDF7F1), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      const Icon(Icons.savings_outlined, color: Color(0xFFC78446), size: 16),
                      const SizedBox(height: 6),
                      Text(_t('Savings'), style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      Text('30% ${_t('Off')}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFC78446))),
                      Text(_t('Night rate'), style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isApproved ? AppColors.cardGreenBg : const Color(0xFFFAF1E6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _isApproved ? Icons.check_circle : Icons.warning_amber_rounded,
                  color: _isApproved ? AppColors.primaryGreen : const Color(0xFFC78446),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isApproved ? _t('Irrigation APPROVED') : _t('Irrigation has NOT started'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _isApproved ? AppColors.primaryGreen : const Color(0xFFC78446),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isApproved
                            ? _t('Valves will automatically trigger at 05:30 PM.')
                            : _t('Awaiting manual confirmation before system can open valves.'),
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSubmitting
                      ? null
                      : () => _handleDecision(approved: false),
                  icon: const Icon(Icons.close),
                  label: Text(_t('Decline')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting
                      ? null
                      : () => _handleDecision(approved: true),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_outline),
                  label: Text(_isSubmitting
                      ? _t('Sending...')
                      : _isApproved
                          ? _t('Approved')
                          : _t('Approve')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreenDark,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExecutionSequence() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_tree_outlined, color: AppColors.textPrimary, size: 20),
                  const SizedBox(width: 8),
                  Text(_t('Execution\nSequence'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.1)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFDDE4FB), borderRadius: BorderRadius.circular(16)),
                child: Text(_t('SCHEDULE\nPREVIEW'), textAlign: TextAlign.right, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, height: 1.1)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFFF4F6FF), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.water_damage_outlined, color: AppColors.textPrimary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('${_t('Drip Valve')} #3', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
                                child: Text(
                                  _isApproved ? _t('Armed') : _t('Standby'),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _isApproved ? AppColors.primaryGreen : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text('${_t('Scheduled Start')}: 05:30 PM (${_t('Today')})', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_t('Active Duration'), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    Text('45 ${_t('min Run')}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_t('Valve Hardware\nState'), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    Text(
                      _isApproved ? _t('Armed • Ready for 05:30 PM') : _t('Closed • Awaiting\nCommand'),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _isApproved ? AppColors.primaryGreen : const Color(0xFFC78446),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_isApproved ? Icons.check_circle_outline : Icons.info_outline, color: _isApproved ? AppColors.primaryGreen : const Color(0xFFC78446), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isApproved
                      ? _t('Water flow is authorized. Valve opens at 05:30 PM.')
                      : _t('No water is flowing. Water starts strictly at 05:30 PM when authorized.'),
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}
class _ArcPainter extends CustomPainter {
  final double percentage; // 0.0 to 1.0

  _ArcPainter({required this.percentage});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    
    // Background arc (light color)
    final bgPaint = Paint()
      ..color = const Color(0xFFE8F0FE) // Light blueish
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
      
    // Draw background arc from PI (180 deg) to 0
    canvas.drawArc(rect, pi, pi, false, bgPaint);
    
    // Foreground arc
    final fgPaint = Paint()
      ..color = const Color(0xFF8B5A2B) // Brown color for moisture deficit
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
      
    // Draw foreground arc based on percentage
    canvas.drawArc(rect, pi, pi * percentage, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
