import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_settings_provider.dart';
import '../../core/config/app_strings.dart';
import '../../core/config/edge_config.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/farm_state_repository.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/freshness_banner.dart';

/// Farmer profile — allows editing farmer info, location, profile picture,
/// and adding/managing Indian regional crops.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _pickProfileImage(BuildContext context, AppSettingsProvider settings, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        await settings.updateProfile(imagePath: picked.path);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.translate('Profile Photo Updated', settings.isHindi))),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating photo: $e')),
        );
      }
    }
  }

  void _showImagePickerSheet(BuildContext context, AppSettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.translate('Change Profile Photo', settings.isHindi),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primaryGreen),
                title: Text(AppStrings.translate('Take Photo', settings.isHindi)),
                onTap: () {
                  Navigator.pop(context);
                  _pickProfileImage(context, settings, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primaryGreen),
                title: Text(AppStrings.translate('Choose from Gallery', settings.isHindi)),
                onTap: () {
                  Navigator.pop(context);
                  _pickProfileImage(context, settings, ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditProfileDialog(BuildContext context, AppSettingsProvider settings) {
    final nameController = TextEditingController(text: settings.userName);
    final locationController = TextEditingController(text: settings.userLocation);
    final cycleController = TextEditingController(text: settings.farmingCycle);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(AppStrings.translate('Edit Profile', settings.isHindi)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: AppStrings.translate('Farmer Name', settings.isHindi),
                    prefixIcon: const Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationController,
                  decoration: InputDecoration(
                    labelText: AppStrings.translate('Location / Place', settings.isHindi),
                    prefixIcon: const Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cycleController,
                  decoration: InputDecoration(
                    labelText: AppStrings.translate('Farming Cycle', settings.isHindi),
                    prefixIcon: const Icon(Icons.grass),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppStrings.translate('Cancel', settings.isHindi)),
            ),
            ElevatedButton(
              onPressed: () {
                settings.updateProfile(
                  name: nameController.text,
                  location: locationController.text,
                  cycle: cycleController.text,
                );
                Navigator.pop(context);
              },
              child: Text(AppStrings.translate('Save', settings.isHindi)),
            ),
          ],
        );
      },
    );
  }

  void _showAddCropDialog(BuildContext context, AppSettingsProvider settings) {
    final customCropController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppStrings.translate('Select Crops', settings.isHindi),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.translate('Select Indian Regional Crops', settings.isHindi),
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 220,
                    child: ListView.builder(
                      itemCount: AppSettingsProvider.availableIndianCrops.length,
                      itemBuilder: (context, index) {
                        final cropName = AppSettingsProvider.availableIndianCrops[index];
                        final isSelected = settings.userCrops.any((c) => c.contains(cropName));
                        return CheckboxListTile(
                          dense: true,
                          activeColor: AppColors.primaryGreen,
                          title: Text(
                            AppStrings.translate(cropName, settings.isHindi),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          value: isSelected,
                          onChanged: (val) {
                            if (val == true) {
                              settings.addUserCrop(cropName);
                            } else {
                              settings.removeUserCrop(cropName);
                            }
                            setSheetState(() {});
                          },
                        );
                      },
                    ),
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: customCropController,
                          decoration: InputDecoration(
                            hintText: AppStrings.translate('Enter crop name', settings.isHindi),
                            isDense: true,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          if (customCropController.text.isNotEmpty) {
                            settings.addUserCrop(customCropController.text);
                            customCropController.clear();
                            setSheetState(() {});
                          }
                        },
                        child: Text(AppStrings.translate('Add New Crop', settings.isHindi)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditZoneDialog(BuildContext context, EdgeConfig edge, AppSettingsProvider settings) {
    final controller = TextEditingController(text: edge.zoneId);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppStrings.translate('Zone', settings.isHindi)),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Zone ID', hintText: 'zone-a'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppStrings.translate('Cancel', settings.isHindi)),
            ),
            ElevatedButton(
              onPressed: () {
                edge.setZoneId(controller.text.isEmpty ? 'zone-a' : controller.text);
                Navigator.pop(context);
              },
              child: Text(AppStrings.translate('Save', settings.isHindi)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final edge = context.watch<EdgeConfig>();
    final provider = context.watch<FarmStateProvider>();
    final settings = context.watch<AppSettingsProvider>();
    final freshness = provider.freshness;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          AppStrings.translate('Profile', settings.isHindi),
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          FreshnessBanner(freshness: freshness, lastFetchTime: provider.lastFetchTime),
          const SizedBox(height: 12),

          // Farmer Identity Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Profile Image / Avatar Picker
                    GestureDetector(
                      onTap: () => _showImagePickerSheet(context, settings),
                      child: Stack(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              image: settings.profileImagePath != null
                                  ? DecorationImage(
                                      image: FileImage(File(settings.profileImagePath!)),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: settings.profileImagePath == null
                                ? Text(
                                    settings.userName.isNotEmpty ? settings.userName[0].toUpperCase() : 'U',
                                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt, size: 14, color: AppColors.primaryGreen),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  AppStrings.translate(settings.userName, settings.isHindi),
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.white70, size: 18),
                                onPressed: () => _showEditProfileDialog(context, settings),
                              ),
                            ],
                          ),
                          Text(
                            '${AppStrings.translate(settings.userLocation, settings.isHindi)} • ${AppStrings.translate(settings.farmingCycle, settings.isHindi)}',
                            style: const TextStyle(fontSize: 13, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Types of Crops Section
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Row(
                        children: [
                          const Icon(Icons.eco, color: AppColors.primaryGreen, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(
                            AppStrings.translate('Type of Crops Grown', settings.isHindi),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          )),
                        ],
                      )),
                      const SizedBox(width: 4),
                      TextButton.icon(
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                        onPressed: () => _showAddCropDialog(context, settings),
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(AppStrings.translate('Add Crop', settings.isHindi), overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: settings.userCrops.map((crop) {
                      final translatedCrop = AppStrings.translate(crop, settings.isHindi);
                      return Chip(
                        avatar: const Icon(Icons.grass, size: 16, color: AppColors.primaryGreen),
                        label: Text(
                          translatedCrop,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        backgroundColor: const Color(0xFFE8F5E9),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () => settings.removeUserCrop(crop),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          _row(
            AppStrings.translate('Edge connection', settings.isHindi),
            edge.normalizedBaseUrl,
            Icons.link,
            () => Navigator.pushNamed(context, '/settings'),
          ),
          _row(
            AppStrings.translate('Zone', settings.isHindi),
            edge.zoneId,
            Icons.grid_view,
            () => _showEditZoneDialog(context, edge, settings),
          ),
          _row(
            AppStrings.translate('Data status', settings.isHindi),
            '${freshness.name} • last sync ${_ago(provider.lastFetchTime)}',
            Icons.cloud_done_outlined,
            () => context.read<FarmStateProvider>().refreshFarmState(),
          ),
          _row(
            AppStrings.translate('Language', settings.isHindi),
            settings.isHindi ? 'हिन्दी (Hindi)' : 'English',
            Icons.language,
            () => settings.toggleLanguage(),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            icon: const Icon(Icons.settings_outlined),
            label: Text(AppStrings.translate('Connection & Settings', settings.isHindi)),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text('Citadel Farmer App v0.1.0 • offline-first',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ),
          const SizedBox(height: 48),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }

  Widget _row(String title, String subtitle, IconData icon, VoidCallback? onTap) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryGreen),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: onTap == null ? null : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  String _ago(DateTime? t) {
    if (t == null) return 'never';
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    return '${d.inHours}h ago';
  }
}
