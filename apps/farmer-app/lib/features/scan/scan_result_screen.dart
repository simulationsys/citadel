import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_settings_provider.dart';
import '../../core/config/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/crop_health_result.dart';
import '../../widgets/profile_avatar_button.dart';
import '../../widgets/citadel_logo.dart';

/// Presents only values returned by the crop-health pipeline. The current
/// model is a tomato-leaf classifier, not a detector or prescription engine.
class ScanResultScreen extends StatelessWidget {
  final File? imageFile;
  final CropHealthResult result;

  const ScanResultScreen({super.key, this.imageFile, required this.result});

  String _titleFor(BuildContext context) {
    String t(String k) => AppStrings.translate(k, context.read<AppSettingsProvider>().language);
    if (result.isRejectedImage) return t('Retake the photo');
    if (result.isInconclusive) return t('Result inconclusive');
    if (result.isHealthy) return t('Leaf appears healthy');
    return '${t('Possible')} ${t(result.displayLabel)}';
  }

  Color get _resultColor {
    if (result.isHealthy) return AppColors.primaryGreen;
    if (result.isRejectedImage || result.isInconclusive) return Colors.orange;
    return AppColors.severityCritical;
  }

  String _nextStepFor(BuildContext context) {
    String t(String k) => AppStrings.translate(k, context.read<AppSettingsProvider>().language);
    if (result.isRejectedImage) {
      return result.limitation ??
          t('Use a clear, well-lit close-up containing one tomato leaf.');
    }
    if (result.isInconclusive) {
      return result.limitation ??
          t('Capture another clear close-up and inspect the plant directly.');
    }
    if (result.isHealthy) {
      return t('Continue regular monitoring. Scan again if visible symptoms develop.');
    }
    return t('Inspect nearby plants and consult a qualified agricultural advisor before applying treatment.');
  }

  @override
  Widget build(BuildContext context) {
    final confidence = '${(result.confidence * 100).toStringAsFixed(1)}%';
    String t(String k) => AppStrings.translate(k, context.read<AppSettingsProvider>().language);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CitadelLogo(size: 34),
            const SizedBox(width: 8),
            Text(t('Crop-health result'), style: const TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        centerTitle: true,
        actions: const [ProfileAvatarButton(size: 32)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 260,
              color: Colors.grey[200],
              child: imageFile == null
                  ? const Center(child: Icon(Icons.image_not_supported_outlined, size: 48))
                  : Image.file(
                      imageFile!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image_outlined, size: 48),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _resultColor.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      result.isHealthy
                          ? Icons.check_circle
                          : result.isRejectedImage
                              ? Icons.camera_alt_outlined
                              : Icons.eco_outlined,
                      color: _resultColor,
                      size: 30,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _titleFor(context),
                        style: TextStyle(
                          color: _resultColor,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _row(t('Crop model'), t(result.crop)),
                _row(t('Model label'), t(result.displayLabel)),
                _row(t('Confidence'), confidence),
                _row(t('Image quality'), t(result.imageQuality)),
                if (result.runtime != null) _row(t('AI runtime'), result.runtime!),
                if (result.latencyMs != null)
                  _row(t('Inference time'), '${result.latencyMs!.toStringAsFixed(0)} ms'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.fact_check_outlined, color: AppColors.primaryGreen),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t('Recommended next step'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(_nextStepFor(context), style: const TextStyle(height: 1.45)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            t('Citadel provides decision support, not a final diagnosis. Confirm visible disease with a qualified agricultural professional before treatment.'),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.camera_alt),
            label: Text(t('Scan another tomato leaf')),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryGreen,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            icon: const Icon(Icons.home_outlined),
            label: Text(t('Back to farm overview')),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
