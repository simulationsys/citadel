import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/crop_health_result.dart';
import '../../widgets/profile_avatar_button.dart';

class ScanResultScreen extends StatelessWidget {
  final File? imageFile;
  final CropHealthResult result;

  const ScanResultScreen({super.key, this.imageFile, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Scan Result Details', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: const [
          ProfileAvatarButton(size: 32),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: const Color(0xFFE8F0FE), borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: const [
                      Icon(Icons.volume_up, color: AppColors.primaryGreen, size: 16),
                      SizedBox(width: 6),
                      Text('Listen to Summary - 15s', style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.cardGreenBg, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: const [
                      Icon(Icons.bolt, color: AppColors.primaryGreen, size: 16),
                      SizedBox(width: 4),
                      Text('0.8s Scan', style: TextStyle(color: AppColors.primaryGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Image with bounding boxes
            _buildAnalyzedImage(),
            
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Field A • South Sector', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                Text('Analyzed Today, 10:45 AM', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 24),
            
            // Result Summary
            _buildResultSummary(context),
            
            const SizedBox(height: 24),
            
            // Recommended Treatment
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.eco, color: AppColors.primaryGreen),
                    SizedBox(width: 8),
                    Text('Recommended\nTreatment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.2)),
                  ],
                ),
                const Text('2 Solutions\nAvailable', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryGreen, height: 1.2)),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildTreatmentCard(
              title: 'Neem Oil 1500 ppm',
              subtitle: 'Target: Nymphs & Adult Whiteflies',
              tag: 'ORGANIC',
              tagColor: AppColors.primaryGreen,
              tagBg: AppColors.cardGreenBg,
              dosage: '5 ml per liter of water',
              notes: 'Safe for beneficial insects. Spray in late afternoon on underside of foliage.',
              iconBg: AppColors.cardGreenBg,
              iconColor: AppColors.primaryGreen,
            ),
            const SizedBox(height: 16),
            
            _buildTreatmentCard(
              title: 'Acetamiprid 20% SP',
              subtitle: 'Systemic Fast-Acting Control',
              tag: 'CHEMICAL',
              tagColor: AppColors.textSecondary,
              tagBg: Colors.grey[200]!,
              dosage: '0.5 g per liter of water',
              notes: 'Apply only if pest infestation exceeds 15 insects per leaf. Observe 14-day pre-harvest interval.',
              iconBg: const Color(0xFFE8F0FE),
              iconColor: AppColors.severityInfo,
            ),
            const SizedBox(height: 24),
            
            _buildSupportCard(),
            const SizedBox(height: 32),
            
            // Bottom Actions
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Scan Another Leaf'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryGreen,
                side: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              icon: const Icon(Icons.home_outlined),
              label: const Text('Back to Farm Overview'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzedImage() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: imageFile != null
                  ? Image.file(imageFile!, fit: BoxFit.cover)
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.green[700]!, Colors.green[900]!],
                        ),
                      ),
                    ),
            ),
          ),
          // Bounding Box
          Positioned(
            top: 40,
            left: 40,
            right: 80,
            bottom: 40,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.severityCritical, width: 2),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -2, left: -2,
                    child: Container(width: 8, height: 8, color: AppColors.severityCritical),
                  ),
                  Positioned(
                    top: -2, right: -2,
                    child: Container(width: 8, height: 8, color: AppColors.severityCritical),
                  ),
                  Positioned(
                    bottom: -2, left: -2,
                    child: Container(width: 8, height: 8, color: AppColors.severityCritical),
                  ),
                  Positioned(
                    bottom: -2, right: -2,
                    child: Container(width: 8, height: 8, color: AppColors.severityCritical),
                  ),
                ],
              ),
            ),
          ),
          // Tooltips
          Positioned(
            top: 100,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFF2C3248), borderRadius: BorderRadius.circular(4)),
              child: const Text('Chlorosis / Yellowing', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 30,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppColors.severityCritical, borderRadius: BorderRadius.circular(4)),
              child: Row(
                children: const [
                  Icon(Icons.circle, color: Colors.white, size: 8),
                  SizedBox(width: 4),
                  Text('Whitefly Colony (96%)', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          // Diagnosis completed chip
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: const [
                  Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 14),
                  SizedBox(width: 4),
                  Text('Diagnosis completed in 0.8s', style: TextStyle(color: AppColors.textPrimary, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          // Zoom icon
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.zoom_in, color: AppColors.textPrimary, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultSummary(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppColors.severityCriticalBg, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: const [
                  Icon(Icons.warning_amber_rounded, color: AppColors.severityCritical, size: 14),
                  SizedBox(width: 4),
                  Text('HIGH SEVERITY', style: TextStyle(color: AppColors.severityCritical, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ],
              ),
            ),
            const Text('Pest Alert #402', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 12),
        const Text('Whitefly Pest Infestation', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const Text('Bemisia tabaci', style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        
        // Infection Spread Level
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Row(
              children: [
                Icon(Icons.coronavirus_outlined, color: AppColors.severityCritical, size: 16),
                SizedBox(width: 8),
                Text('Infection Spread Level', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
            Text('78%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.severityCritical)),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(height: 8, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4))),
            Container(height: 8, width: 250, decoration: BoxDecoration(color: AppColors.severityCritical, borderRadius: BorderRadius.circular(4))),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('Mild (<20%)', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            Text('Moderate', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            Text('Critical (78%)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.severityCritical)),
          ],
        ),
        const SizedBox(height: 20),
        
        // Info card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFF4F6FF), borderRadius: BorderRadius.circular(12)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.info, color: Color(0xFF8B5CF6), size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Sap-sucking pest cluster detected on leaf undersides. Treat before sundown to prevent leaf curling and yield drop.',
                  style: TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Action logged'))),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text('View Dosage & Treatment Plan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTreatmentCard({
    required String title,
    required String subtitle,
    required String tag,
    required Color tagColor,
    required Color tagBg,
    required String dosage,
    required String notes,
    required Color iconBg,
    required Color iconColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                  child: Icon(Icons.eco, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: tagBg, borderRadius: BorderRadius.circular(12)),
                            child: Text(tag, style: TextStyle(color: tagColor, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.science_outlined, color: AppColors.primaryGreen, size: 18),
                const SizedBox(width: 8),
                const Text('Dosage', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const Spacer(),
                Text(dosage, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(notes, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: AppColors.primaryGreen, shape: BoxShape.circle),
            child: const Icon(Icons.headset_mic, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('TOLL-FREE AGRICULTURAL SUPPORT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                SizedBox(height: 4),
                Text('Call Kisan Helpline', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                SizedBox(height: 4),
                Text('Direct agronomist assistance\n(1800-180-1551)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.phone_in_talk, color: AppColors.primaryGreen, size: 20),
          ),
        ],
      ),
    );
  }
}
