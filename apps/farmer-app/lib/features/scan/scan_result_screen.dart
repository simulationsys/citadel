import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class ScanResultScreen extends StatelessWidget {
  const ScanResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: _buildTopBar(context),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const SizedBox(height: 12),
                  _buildSummaryPills(),
                  const SizedBox(height: 16),
                  _buildImagePreview(),
                  const SizedBox(height: 24),
                  _buildAlertHeader(),
                  const SizedBox(height: 16),
                  _buildSpreadLevelCard(),
                  const SizedBox(height: 16),
                  _buildInfoBlock(),
                  const SizedBox(height: 16),
                  _buildDosageButton(),
                  const SizedBox(height: 32),
                  _buildTreatmentHeader(),
                  const SizedBox(height: 16),
                  _buildTreatmentCard(
                    title: 'Neem Oil 1500 ppm',
                    subtitle: 'Target: Nymphs & Adult\nWhiteflies',
                    type: 'ORGANIC',
                    typeColor: AppColors.primaryGreen,
                    typeBg: AppColors.primaryGreenLight,
                    icon: Icons.eco,
                    iconBg: AppColors.primaryGreenLight,
                    dosage: '5 ml per liter of water',
                    note: 'Safe for beneficial insects. Spray in late\nafternoon on underside of foliage.',
                  ),
                  const SizedBox(height: 16),
                  _buildTreatmentCard(
                    title: 'Acetamiprid 20% SP',
                    subtitle: 'Systemic Fast-Acting\nControl',
                    type: 'CHEMICAL',
                    typeColor: AppColors.textSecondary,
                    typeBg: AppColors.surfaceMuted,
                    icon: Icons.science_outlined,
                    iconBg: AppColors.cardPurpleLight,
                    dosage: '0.5 g per liter of water',
                    note: 'Apply only if pest infestation exceeds 15 insects\nper leaf. Observe 14-day pre-harvest interval.',
                  ),
                  const SizedBox(height: 24),
                  _buildHelplineCard(),
                  const SizedBox(height: 24),
                  _buildActionButtons(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Scan Result Details',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.textPrimary),
          ),
        ),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text('img', style: TextStyle(color: Colors.grey, fontSize: 10)),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryPills() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.cardPurpleLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              Icon(Icons.volume_up_outlined, size: 16, color: AppColors.textPrimary),
              SizedBox(width: 8),
              Text('Listen to Summary - 15s', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textPrimary)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF69F0AE),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              Icon(Icons.bolt, size: 16, color: AppColors.primaryGreenDark),
              SizedBox(width: 4),
              Text('0.8s Scan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.primaryGreenDark)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Column(
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const Center(child: Icon(Icons.eco, size: 48, color: Colors.grey)), // Placeholder for image
              // Mocking the bounding boxes from the design
              Positioned(
                top: 20,
                left: 40,
                child: Container(
                  width: 120,
                  height: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.severityCritical, width: 2),
                  ),
                ),
              ),
              Positioned(
                top: 110,
                left: 40,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.severityCritical,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('+ Whitefly Colony (96%)', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ),
              Positioned(
                top: 140,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Chlorosis / Yellowing', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 12),
                      SizedBox(width: 4),
                      Text('Diagnosis completed in 0.8s', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.zoom_in, size: 16, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Field A • South Sector', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            Text('Analyzed Today, 10:45 AM', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  Widget _buildAlertHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppColors.severityCriticalBg, borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 12, color: AppColors.severityCritical),
                  SizedBox(width: 4),
                  Text('HIGH SEVERITY', style: TextStyle(color: AppColors.severityCritical, fontSize: 10, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const Text('Pest Alert #402', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 8),
        const Text('Whitefly Pest Infestation', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const Text('Bemisia tabaci', style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildSpreadLevelCard() {
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
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.bug_report_outlined, size: 16, color: AppColors.severityCritical),
                  SizedBox(width: 8),
                  Text('Infection Spread Level', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                ],
              ),
              Text('78%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.severityCritical)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.78,
              backgroundColor: Colors.grey.shade200,
              color: AppColors.severityCritical,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Mild (<20%)', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              Text('Moderate', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              Text('Critical (78%)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.severityCritical)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBlock() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardPurpleLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info, color: AppColors.soilMoistureBrown, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Sap-sucking pest cluster\ndetected on leaf undersides. Treat\nbefore sundown to prevent leaf\ncurling and yield drop.',
              style: TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDosageButton() {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('View Dosage & Treatment Plan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          SizedBox(width: 8),
          Icon(Icons.arrow_forward, size: 18),
        ],
      ),
    );
  }

  Widget _buildTreatmentHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
            Icon(Icons.eco, color: AppColors.primaryGreen, size: 18),
            SizedBox(width: 8),
            Text('Recommended\nTreatment', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, height: 1.2)),
          ],
        ),
        Text('2 Solutions\nAvailable', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primaryGreen, height: 1.2), textAlign: TextAlign.right),
      ],
    );
  }

  Widget _buildTreatmentCard({
    required String title,
    required String subtitle,
    required String type,
    required Color typeColor,
    required Color typeBg,
    required IconData icon,
    required Color iconBg,
    required String dosage,
    required String note,
  }) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(icon, color: AppColors.textPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: typeBg, borderRadius: BorderRadius.circular(12)),
                          child: Text(type, style: TextStyle(color: typeColor, fontSize: 9, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: AppColors.cardPurpleLight, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(Icons.science_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                const Text('Dosage', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text(dosage, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(note, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3)),
        ],
      ),
    );
  }

  Widget _buildHelplineCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardPurpleLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.primaryGreen, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.support_agent, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TOLL-FREE AGRICULTURAL\nSUPPORT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.primaryGreen)),
                SizedBox(height: 2),
                Text('Call Kisan Helpline', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary)),
                SizedBox(height: 2),
                Text('Direct agronomist assistance\n(1800-180-1551)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.call, color: AppColors.primaryGreen, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            side: BorderSide(color: Colors.grey.shade300),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: Colors.white,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt_outlined, color: AppColors.primaryGreen, size: 18),
              SizedBox(width: 8),
              Text('Scan Another Leaf', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.home_outlined, color: AppColors.textSecondary, size: 16),
              SizedBox(width: 8),
              Text('Back to Farm Overview', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}
