import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';

/// Settings screen — language toggle, edge API URL, connection test.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _urlController = TextEditingController(
    text: AppConstants.defaultEdgeApiUrl,
  );
  String _language = 'English';
  String? _connectionStatus;
  bool _isTesting = false;

  @override
  void dispose() {
    _urlController.dispose();
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
              child: RadioGroup<String>(
                groupValue: _language,
                onChanged: (String? v) { if (v != null) setState(() => _language = v); },
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('English'),
                      value: 'English',
                      toggleable: false,
                    ),
                    RadioListTile<String>(
                      title: const Text('हिन्दी (Hindi)'),
                      value: 'Hindi',
                      toggleable: false,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Edge API URL.
          const _SectionLabel(text: 'Edge API Connection'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                  ElevatedButton.icon(
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
                children: const [
                  Text(
                    'Citadel Farmer App',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'v0.1.0 · Phase 1 MVP',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Offline-first smart farming assistant for Indian farms. '
                    'Provides real-time advisories for irrigation, crop health, '
                    'and environmental risk.',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _connectionStatus = null;
    });

    try {
      final url = Uri.parse('${_urlController.text}/health');
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        setState(() {
          _connectionStatus = '✅ Connected — ${body['service']} (${body['mode']})';
        });
      } else {
        setState(() {
          _connectionStatus = '❌ Responded with status ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _connectionStatus = '❌ Could not reach server: $e';
      });
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
