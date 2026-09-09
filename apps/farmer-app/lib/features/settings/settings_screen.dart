import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_language.dart';
import '../../core/config/app_settings_provider.dart';
import '../../core/config/edge_config.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/http_farm_state_repository.dart';

/// Settings screen — language toggle, edge API URL, connection test.
///
/// The Edge API URL is persisted via [EdgeConfig] so a physical phone can
/// point at the laptop on the same Wi-Fi, e.g. `http://192.168.1.10:3001`.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _urlController;
  late TextEditingController _zoneController;
  AppLanguage _language = AppLanguage.english;
  String? _connectionStatus;
  bool _isTesting = false;
  bool _isSaving = false;
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_init) {
      final edge = context.read<EdgeConfig>();
      _urlController = TextEditingController(text: edge.baseUrl);
      _zoneController = TextEditingController(text: edge.zoneId);
      _language = context.read<AppSettingsProvider>().language;
      _init = true;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _zoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Language toggle.
          const _SectionLabel(text: 'Language'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: RadioGroup<AppLanguage>(
                groupValue: _language,
                onChanged: (AppLanguage? v) {
                  if (v != null) {
                    setState(() => _language = v);
                    context.read<AppSettingsProvider>().setLanguage(v);
                  }
                },
                child: Column(
                  children: [
                    for (final lang in AppLanguage.values)
                      RadioListTile<AppLanguage>(
                        title: Text(lang.displayLabel),
                        value: lang,
                        toggleable: false,
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Edge API URL.
          const _SectionLabel(text: 'Edge API Connection (phone → farm)'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Phone and Raspberry Pi must be on the same Wi-Fi. Use the Pi\'s IPv4, e.g. http://192.168.1.31:3001',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      labelText: 'Edge API URL',
                      hintText: 'http://192.168.1.x:3001',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.link),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _zoneController,
                    decoration: InputDecoration(
                      labelText: 'Zone ID',
                      hintText: 'zone-a',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.grid_view),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _save,
                          icon: const Icon(Icons.save_outlined),
                          label: Text(_isSaving ? 'Saving…' : 'Save'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isTesting ? null : _testConnection,
                          icon: _isTesting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.wifi_find),
                          label: Text(_isTesting ? 'Testing…' : 'Test Connection'),
                        ),
                      ),
                    ],
                  ),
                  if (_connectionStatus != null) ...[
                    const SizedBox(height: 12),
                    _ConnectionStatusCard(status: _connectionStatus!),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // About.
          const _SectionLabel(text: 'About'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Citadel Farmer App',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'v0.1.0 · Phase 1 MVP',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Offline-first smart farming assistant for Indian farms. '
                    'Default edge URL: ${AppConstants.defaultEdgeApiUrl}. '
                    'Provides real-time advisories for irrigation, crop health, '
                    'and environmental risk.',
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final edge = context.read<EdgeConfig>();
      await edge.setBaseUrl(_urlController.text);
      await edge.setZoneId(_zoneController.text.isEmpty ? 'zone-a' : _zoneController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved — ${edge.normalizedBaseUrl} • ${edge.zoneId}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _connectionStatus = null;
    });

    try {
      final repo = HttpFarmStateRepository(
        baseUrl: _urlController.text,
        zoneId: _zoneController.text.isEmpty ? 'zone-a' : _zoneController.text,
      );
      final msg = await repo.testConnection();
      setState(() => _connectionStatus = '✅ $msg');
    } catch (e) {
      setState(() => _connectionStatus = '❌ Could not reach server: $e');
    } finally {
      setState(() => _isTesting = false);
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ConnectionStatusCard extends StatelessWidget {
  final String status;
  const _ConnectionStatusCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final isOk = status.startsWith('✅');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOk ? AppColors.severityOkBg : AppColors.severityCriticalBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 13,
          color: isOk ? AppColors.severityOk : AppColors.severityCritical,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
