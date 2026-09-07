import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/app_bottom_nav.dart';

class AdvisoryDetailScreen extends StatefulWidget {
  const AdvisoryDetailScreen({super.key});

  @override
  State<AdvisoryDetailScreen> createState() => _AdvisoryDetailScreenState();
}

class _AdvisoryDetailScreenState extends State<AdvisoryDetailScreen> {
  bool _isApproved = false;

  void _showMicDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
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
              'Ask any advisory question: "Should I approve irrigation for Plot A?"',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _showNodeDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.grid_view, color: AppColors.primaryGreen),
            SizedBox(width: 8),
            Text('Telemetry Node #04'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('• Location: Field 1: Plot A Cotton'),
            Text('• Sensor Depth: 15cm Root Zone'),
            Text('• Signal Strength: Excellent (-62 dBm)'),
            Text('• Valve Controller: Drip Valve #3 Ready'),
          ],
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  void _handleApprove() {
    setState(() => _isApproved = true);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: AppColors.primaryGreen),
            SizedBox(width: 8),
            Text('Irrigation Approved'),
          ],
        ),
        content: const Text(
          'Drip Valve #3 scheduled to open at 05:30 PM for 45 minutes (1,200 Liters). Command sent to edge controller.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Return to Dashboard'),
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
                const Text(
                  'Citadel Farm',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.primaryGreen, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Text(
                        'Online • Synced',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
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
                  const Expanded(
                    child: Text(
                      'LIVE SOIL TELEMETRY',
                      style: TextStyle(color: Color(0xFFC78446), fontSize: 10, fontWeight: FontWeight.bold),
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
                child: const Text('Node #04', style: TextStyle(color: AppColors.textPrimary, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Irrigation Advisory Detail',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: const [
            Icon(Icons.location_on_outlined, color: AppColors.primaryGreen, size: 16),
            SizedBox(width: 4),
            Expanded(
              child: Text(
                'Field 1: Plot A Cotton',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
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
            children: const [
              Text('Soil Moisture Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              Text('Deficit Detected', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFC78446))),
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
                    children: const [
                      Text('42%', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      Text('Current Moisture', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFC78446))),
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
                children: const [
                  Text('Threshold', style: TextStyle(color: Color(0xFFC78446), fontSize: 12, fontWeight: FontWeight.bold)),
                  Text('< 50% Critical', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
              Container(width: 1, height: 24, color: Colors.grey[300]),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text('Target', style: TextStyle(color: AppColors.primaryGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                  Text('65% (Optimal)', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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
                    children: const [
                      Text('High Evaporation Forecast', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      SizedBox(height: 2),
                      Text('0% Rain expected in 48h • Soil dries rapidly', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
            children: const [
              Icon(Icons.psychology_outlined, color: AppColors.primaryGreen, size: 20),
              SizedBox(width: 8),
              Text('Agronomic Reason', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Moisture level is below the 55% root threshold during flowering stage. Watering today protects bloom retention.',
            style: TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.4),
          ),
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(color: const Color(0xFFF4F6FF), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: const [
                      Icon(Icons.timer_outlined, color: AppColors.primaryGreen, size: 16),
                      SizedBox(height: 6),
                      Text('Duration', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      Text('45 mins', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      Text('Drip line', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
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
                    children: const [
                      Icon(Icons.water_drop_outlined, color: AppColors.primaryGreen, size: 16),
                      SizedBox(height: 6),
                      Text('Volume', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      Text('1,200 L', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                      Text('Calculated', style: TextStyle(fontSize: 10, color: AppColors.primaryGreen)),
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
                    children: const [
                      Icon(Icons.savings_outlined, color: Color(0xFFC78446), size: 16),
                      SizedBox(height: 6),
                      Text('Savings', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      Text('30% Off', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFC78446))),
                      Text('Night rate', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
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
                        _isApproved ? 'Irrigation APPROVED' : 'Irrigation has NOT started',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _isApproved ? AppColors.primaryGreen : const Color(0xFFC78446),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isApproved
                            ? 'Valves will automatically trigger at 05:30 PM.'
                            : 'Awaiting manual confirmation before system can open valves.',
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
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Advisory declined.')),
                    );
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close),
                  label: const Text('Decline'),
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
                  onPressed: _handleApprove,
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(_isApproved ? 'Approved' : 'Approve'),
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
                children: const [
                  Icon(Icons.account_tree_outlined, color: AppColors.textPrimary, size: 20),
                  SizedBox(width: 8),
                  Text('Execution\nSequence', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.1)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFDDE4FB), borderRadius: BorderRadius.circular(16)),
                child: const Text('SCHEDULE\nPREVIEW', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, height: 1.1)),
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
                              const Text('Drip Valve #3', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
                                child: Text(
                                  _isApproved ? 'Armed' : 'Standby',
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
                          const Text('Scheduled Start: 05:30 PM (Today)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Active Duration', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    Text('45 min Run', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Valve Hardware\nState', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    Text(
                      _isApproved ? 'Armed • Ready for 05:30 PM' : 'Closed • Awaiting\nCommand',
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
                      ? 'Water flow is authorized. Valve opens at 05:30 PM.'
                      : 'No water is flowing. Water starts strictly at 05:30 PM when authorized.',
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
