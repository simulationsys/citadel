import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_settings_provider.dart';
import '../../core/config/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/citadel_logo.dart';
import '../../widgets/profile_avatar_button.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}
class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'All';

  void _showDosageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.bug_report, color: AppColors.severityCritical),
            SizedBox(width: 8),
            Text('Whitefly Dosage Plan'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Recommended Organic Treatment:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('• Neem Oil (10,000 PPM): 5 ml per Liter water'),
            Text('• Spray Schedule: Early morning or post 5:00 PM'),
            Text('• Coverage: Underside of leaves in North Plot'),
            SizedBox(height: 12),
            Text('Status: 100L batch ready for field application.', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Dismiss')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Dosage applied & logged to farm register!')),
              );
            },
            child: const Text('Apply Dosage'),
          ),
        ],
      ),
    );
  }

  void _showSensorLogDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.water_drop, color: AppColors.primaryGreen),
            SizedBox(width: 8),
            Text('Plot A Sensor Log'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Soil Moisture Telemetry (Last 24h):', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('• 06:15 PM Yesterday: 42% (Low Moisture Alert)'),
            Text('• 06:30 PM Yesterday: Drip Irrigation Started (45m)'),
            Text('• 07:15 PM Yesterday: Drip Cycle Completed'),
            Text('• Current Level: 68% (Optimal Root Zone)'),
          ],
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showWeatherRadarDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.cloudy_snowing, color: AppColors.primaryGreen),
            SizedBox(width: 8),
            Text('Weather Radar'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Rohtak Zone Radar Overview:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('• Precipitation: 40mm expected in next 3 days'),
            Text('• Wind: 14 km/h North-East'),
            Text('• Recommendation: Hold off chemical spray to prevent wash-off'),
          ],
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showNutrientLogDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.eco, color: AppColors.primaryGreen),
            SizedBox(width: 8),
            Text('Nutrient Batch #N-204'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Application Summary:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('• Applied: Neem-coated Urea (45 kg/ha)'),
            Text('• Area Covered: 4.2 hectares'),
            Text('• Satellite NDVI Response: +8% vigor increase'),
          ],
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: _buildBody(context),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
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
                const Text(
                  'Citadel Farm',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.primaryGreen, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        AppStrings.translate('Online • Synced', context.read<AppSettingsProvider>().language),
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

  Widget _buildBody(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        // Title and History icon
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.translate('Alerts & Advisory History', settings.language),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.translate('Farm decisions and action log', settings.language),
                      style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Log refreshed.')),
                ),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(color: Color(0xFFE8F0FE), shape: BoxShape.circle),
                  child: const Icon(Icons.history, color: AppColors.primaryGreen, size: 20),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Summary Chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedFilter = 'High Severity'),
                  child: _buildSummaryChip(
                    count: '3',
                    label: AppStrings.translate('Active Alerts', settings.language),
                    color: AppColors.severityCritical,
                    bgColor: AppColors.severityCriticalBg,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedFilter = 'All'),
                  child: _buildSummaryChip(
                    count: '14',
                    label: AppStrings.translate('Resolved', settings.language),
                    color: AppColors.primaryGreen,
                    bgColor: AppColors.cardGreenBg,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedFilter = 'All'),
                  child: _buildSummaryChip(
                    icon: Icons.verified_user_outlined,
                    label: AppStrings.translate('Protected', settings.language),
                    color: AppColors.textPrimary,
                    bgColor: const Color(0xFFE8F0FE),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildFilterChip(AppStrings.translate('All', settings.language), Icons.done_all, AppColors.primaryGreen, Colors.white, _selectedFilter == 'All'),
              const SizedBox(width: 8),
              _buildFilterChip(AppStrings.translate('High Severity', settings.language), Icons.warning_amber_rounded, AppColors.severityCritical, AppColors.textPrimary, _selectedFilter == 'High Severity'),
              const SizedBox(width: 8),
              _buildFilterChip(AppStrings.translate('Irrigation', settings.language), Icons.water_drop_outlined, Colors.blue, AppColors.textPrimary, _selectedFilter == 'Irrigation'),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // List of advisories according to filter
        if (_selectedFilter == 'All' || _selectedFilter == 'High Severity') ...[
          _buildPestAlertCard(context, settings),
          const SizedBox(height: 16),
        ],
        if (_selectedFilter == 'All' || _selectedFilter == 'Irrigation') ...[
          _buildIrrigationAlertCard(context),
          const SizedBox(height: 16),
        ],
        if (_selectedFilter == 'All') ...[
          _buildWeatherAlertCard(context),
          const SizedBox(height: 16),
          _buildNutrientAlertCard(context),
          const SizedBox(height: 32),
        ],
        const Center(child: Text('All past advisories up to date', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))),
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildSummaryChip({String? count, IconData? icon, required String label, required Color color, required Color bgColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          if (count != null)
            Text(count, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color))
          else if (icon != null)
            Icon(icon, color: AppColors.primaryGreen, size: 22),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon, Color iconColor, Color textColor, bool isSelected) {
    return InkWell(
      onTap: () => setState(() => _selectedFilter = label),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primaryGreen : Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : iconColor),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : textColor)),
          ],
        ),
      ),
    );
  }

  // --- Specialized Cards ---

  Widget _buildPestAlertCard(BuildContext context, AppSettingsProvider settings) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.severityCriticalBg, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.bug_report, color: AppColors.severityCritical, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.severityCritical, borderRadius: BorderRadius.circular(4)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 10),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    AppStrings.translate('High Severity', settings.language),
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(AppStrings.translate('Today 8:30 AM', settings.language), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.translate('Whitefly Outbreak (North Plot)', settings.language),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(AppStrings.translate('Action Pending', settings.language), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.severityCritical)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showDosageDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreenDark,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(AppStrings.translate('View Dosage', settings.language), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIrrigationAlertCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(color: Color(0xFF5EE085), shape: BoxShape.circle),
                child: const Icon(Icons.water_drop, color: AppColors.primaryGreenDark, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFFE8F0FE), borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.water_drop_outlined, color: AppColors.primaryGreen, size: 12),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    AppStrings.translate('Irrigation Required', context.read<AppSettingsProvider>().language),
                                    style: const TextStyle(color: AppColors.primaryGreen, fontSize: 10, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          AppStrings.translate('Yesterday 6:15 PM', context.read<AppSettingsProvider>().language),
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.translate('Low Soil Moisture (Plot A)', context.read<AppSettingsProvider>().language),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.check_circle_outline, color: AppColors.primaryGreen, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            AppStrings.translate('Approved & Completed (45m drip)', context.read<AppSettingsProvider>().language),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
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
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _showSensorLogDialog(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(color: const Color(0xFFF4F6FF), borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.translate('Plot moisture restored to 68%\noptimal', context.read<AppSettingsProvider>().language),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.translate('Sensor\nLog', context.read<AppSettingsProvider>().language),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherAlertCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFE8F0FE), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.cloudy_snowing, color: AppColors.textPrimary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.severityWarningBg, borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.cloud, color: AppColors.severityWarning, size: 12),
                              const SizedBox(width: 4),
                              Text(AppStrings.translate('Weather Alert', context.read<AppSettingsProvider>().language), style: const TextStyle(color: AppColors.severityWarning, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Text(AppStrings.translate('3 days ago', context.read<AppSettingsProvider>().language), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(AppStrings.translate('Heavy Rain Forecast (40mm)', context.read<AppSettingsProvider>().language), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.savings_outlined, color: AppColors.severityWarning, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            AppStrings.translate('Chemical spray postponed • Saved \$45', context.read<AppSettingsProvider>().language),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () => _showWeatherRadarDialog(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(color: const Color(0xFFF4F6FF), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(AppStrings.translate('View Weather Radar', context.read<AppSettingsProvider>().language), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(width: 6),
                    const Icon(Icons.open_in_new, size: 14, color: AppColors.textPrimary),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientAlertCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.cardGreenBg, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.eco_outlined, color: AppColors.primaryGreen, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFF4F6FF), borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.science, color: AppColors.textSecondary, size: 12),
                              const SizedBox(width: 4),
                              Text(AppStrings.translate('Nutrient Management', context.read<AppSettingsProvider>().language), style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Text(AppStrings.translate('5 days ago', context.read<AppSettingsProvider>().language), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(AppStrings.translate('Nitrogen Top Dressing', context.read<AppSettingsProvider>().language), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.trending_up, color: AppColors.primaryGreen, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            AppStrings.translate('Completed (Urea applied) • NDVI +8%', context.read<AppSettingsProvider>().language),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
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
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _showNutrientLogDialog(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(color: const Color(0xFFF4F6FF), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: Colors.green[800], borderRadius: BorderRadius.circular(4)),
                    child: const Icon(Icons.grass, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Batch #N-204 applied across 4.2 hec...', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ),
                  const Icon(Icons.chevron_right, size: 16, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
