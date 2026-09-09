import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_settings_provider.dart';
import '../../core/config/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/crop_health_result.dart';
import '../../data/repositories/farm_state_repository.dart';
import '../../widgets/profile_avatar_button.dart';
import 'scan_result_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isAnalysing = false;
  bool _isSingleLeafMode = true;
  bool _isFlashOn = false;
  String _selectedCrop = 'Wheat (Plot B - North)';

  void _toggleScanMode(bool singleLeaf) {
    setState(() => _isSingleLeafMode = singleLeaf);
  }

  void _toggleFlash() {
    setState(() => _isFlashOn = !_isFlashOn);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isFlashOn ? 'Camera Flash Enabled' : 'Camera Flash Disabled'), duration: const Duration(seconds: 1)),
    );
  }

  void _showCropPicker() {
    final settings = context.read<AppSettingsProvider>();
    final cropsList = settings.userCrops.isNotEmpty
        ? settings.userCrops
        : AppSettingsProvider.availableIndianCrops;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.translate('Select Active Crop', settings.language),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: cropsList.length,
                itemBuilder: (context, index) {
                  final cropName = cropsList[index];
                  final translatedCrop = AppStrings.translate(cropName, settings.language);
                  return ListTile(
                    leading: const Icon(Icons.eco, color: AppColors.primaryGreen),
                    title: Text(translatedCrop),
                    selected: _selectedCrop == cropName,
                    onTap: () {
                      setState(() => _selectedCrop = cropName);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTipsDialog() {
    final settings = context.read<AppSettingsProvider>();
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Row(children: [const Icon(Icons.lightbulb_rounded, color: Colors.amber), const SizedBox(width: 10), Expanded(child: Text(AppStrings.translate('Scanning Best Practices', settings.language), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))]),
          const SizedBox(height: 16),
          Text(AppStrings.translate('1. Focus on affected leaves showing discoloration or spots.', settings.language)),
          const SizedBox(height: 10),
          Text(AppStrings.translate('2. Keep distance at 15-20 cm from plant surface.', settings.language)),
          const SizedBox(height: 10),
          Text(AppStrings.translate('3. Ensure clear daylight or turn on Flash in low light.', settings.language)),
          const SizedBox(height: 10),
          Text(AppStrings.translate('4. Keep camera steady for accurate AI confidence rating.', settings.language)),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: () => Navigator.pop(sheetContext), child: Text(AppStrings.translate('Got it!', settings.language))),
        ]),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (picked == null) return;

      setState(() => _isAnalysing = true);

      if (!mounted) return;
      final provider = context.read<FarmStateProvider>();
      await provider.scanImage(File(picked.path));

      if (!mounted) return;
      setState(() => _isAnalysing = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScanResultScreen(
            imageFile: File(picked.path),
            result: provider.lastScanResult!,
          ),
        ),
      );
    } catch (e) {
      setState(() => _isAnalysing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera Access Error: $e'),
            action: SnackBarAction(
              label: 'Sample Scan',
              onPressed: _simulateCapture,
            ),
          ),
        );
      }
    }
  }

  void _simulateCapture() {
    setState(() => _isAnalysing = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _isAnalysing = false);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScanResultScreen(
            imageFile: null,
            result: CropHealthResult(
              crop: _selectedCrop.split(' ').first,
              label: 'rust',
              confidence: 0.94,
              imageQuality: 'acceptable',
            ),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTopControls(),
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: const BoxDecoration(color: Colors.black),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.green[800]!, Colors.green[900]!],
                      ),
                    ),
                  ),
                ),
                _buildViewfinderOverlay(),
              ],
            ),
          ),
          _buildBottomControls(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    final lang = context.read<AppSettingsProvider>().language;
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        AppStrings.translate('Crop Scanner', lang),
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      actions: const [
        ProfileAvatarButton(size: 32),
      ],
    );
  }

  Widget _buildTopControls() {
    final settings = context.watch<AppSettingsProvider>();
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FE),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => _toggleScanMode(true),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _isSingleLeafMode ? AppColors.primaryGreen : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.energy_savings_leaf,
                              color: _isSingleLeafMode ? Colors.white : AppColors.textSecondary,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              AppStrings.translate('Single Leaf', settings.language),
                              style: TextStyle(
                                color: _isSingleLeafMode ? Colors.white : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => _toggleScanMode(false),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: !_isSingleLeafMode ? AppColors.primaryGreen : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.landscape,
                              color: !_isSingleLeafMode ? Colors.white : AppColors.textSecondary,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              AppStrings.translate('Field Spot', settings.language),
                              style: TextStyle(
                                color: !_isSingleLeafMode ? Colors.white : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: _toggleFlash,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isFlashOn ? Colors.amber[100] : const Color(0xFFE8F0FE),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isFlashOn ? Icons.flash_on : Icons.flash_off,
                    color: _isFlashOn ? Colors.orange[800] : AppColors.textPrimary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppStrings.translate('ACTIVE CROP:', settings.language),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppStrings.translate(_selectedCrop, settings.language),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: _showCropPicker,
                  child: Text(
                    AppStrings.translate('Change', settings.language),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewfinderOverlay() {
    return Stack(
      children: [
        Positioned(
          top: 24,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2C3248).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF5EE085),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.translate(
                      _isSingleLeafMode ? 'AI Scanner Ready • Good Lighting' : 'Field Spot Mode Active',
                      context.read<AppSettingsProvider>().language,
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Center(
          child: SizedBox(
            width: 250,
            height: 250,
            child: Stack(
              children: [
                Positioned(top: 0, left: 0, child: _buildCorner(0)),
                Positioned(top: 0, right: 0, child: _buildCorner(1)),
                Positioned(bottom: 0, left: 0, child: _buildCorner(2)),
                Positioned(bottom: 0, right: 0, child: _buildCorner(3)),
                Positioned(
                  top: 70,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.severityCritical,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          AppStrings.translate('Spot Found', context.read<AppSettingsProvider>().language),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: Icon(
                    Icons.filter_center_focus,
                    color: const Color(0xFF5EE085).withValues(alpha: 0.8),
                    size: 48,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 24,
          left: 24,
          right: 24,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.cardGreenBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.bug_report_outlined,
                    color: AppColors.primaryGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppStrings.translate(
                      _isSingleLeafMode ? 'Align damaged leaf area inside frame' : 'Align field crop section inside frame',
                      context.read<AppSettingsProvider>().language,
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 4,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              AppStrings.translate('Hold steady for instant diagnosis', context.read<AppSettingsProvider>().language),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
          ),
        ),
        if (_isAnalysing)
          Container(
            color: Colors.black.withValues(alpha: 0.5),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            ),
          ),
      ],
    );
  }

  Widget _buildCorner(int index) {
    return RotatedBox(
      quarterTurns: index,
      child: Container(
        width: 30,
        height: 30,
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFF5EE085), width: 4),
            left: BorderSide(color: Color(0xFF5EE085), width: 4),
          ),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.only(top: 24, bottom: 32, left: 24, right: 24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildControlButton(
                Icons.photo_library,
                AppStrings.translate('Gallery', context.read<AppSettingsProvider>().language),
                () => _pickImage(ImageSource.gallery),
              )),
              Expanded(child: Center(child: GestureDetector(
                onTap: () => _pickImage(ImageSource.camera),
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryGreen, width: 3),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ))),
              Expanded(child: _buildControlButton(Icons.lightbulb_outline, AppStrings.translate('Tips', context.read<AppSettingsProvider>().language), _showTipsDialog)),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.wb_sunny,
                    color: Colors.orange[800],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.translate('Field Tip: Natural Sun Angle', context.read<AppSettingsProvider>().language),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppStrings.translate('Keep the sun behind your phone for optimal clarity.', context.read<AppSettingsProvider>().language),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
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

  Widget _buildControlButton(IconData icon, String label, VoidCallback onTap) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F0FE),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.textPrimary, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      ),
    );
  }
}
