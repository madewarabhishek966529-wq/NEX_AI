import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../../app/theme.dart';
import '../../../../core/constants.dart';
import '../../../conversation/presentation/providers/conversation_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _urlController;
  late CompanionTone _selectedTone;
  late bool _autoSpeak;
  late double _speechRate;
  late double _speechPitch;

  bool _isTestingConnection = false;
  String? _connectionStatus;
  bool _isConnectionSuccess = false;

  final FlutterTts _testTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(sharedPreferencesProvider);
    final convState = ref.read(conversationProvider);

    _nameController = TextEditingController(text: convState.companionName);
    _urlController = TextEditingController(
      text: prefs.getString(AppConstants.keyBaseUrl) ?? AppConstants.defaultBaseUrl,
    );

    _selectedTone = convState.companionTone;
    _autoSpeak = convState.isTtsEnabled;
    _speechRate = prefs.getDouble(AppConstants.keyTtsRate) ?? AppConstants.defaultTtsRate;
    _speechPitch = prefs.getDouble(AppConstants.keyTtsPitch) ?? AppConstants.defaultTtsPitch;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _testTts.stop();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final newName = _nameController.text.trim().isEmpty ? AppConstants.defaultCompanionName : _nameController.text.trim();
    final newUrl = _urlController.text.trim();

    await prefs.setString(AppConstants.keyCompanionName, newName);
    await prefs.setString(AppConstants.keyCompanionTone, _selectedTone.value);
    await prefs.setBool(AppConstants.keyAutoSpeak, _autoSpeak);
    await prefs.setDouble(AppConstants.keyTtsRate, _speechRate);
    await prefs.setDouble(AppConstants.keyTtsPitch, _speechPitch);

    if (newUrl.isNotEmpty) {
      await prefs.setString(AppConstants.keyBaseUrl, newUrl);
      ref.read(dioClientProvider).updateBaseUrl(newUrl);
    }

    ref.read(conversationProvider.notifier).updateCompanionSettings(
      name: newName,
      tone: _selectedTone,
      ttsEnabled: _autoSpeak,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.accentGreen,
          content: Text('Settings saved successfully!'),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTestingConnection = true;
      _connectionStatus = null;
    });

    try {
      final dio = ref.read(dioClientProvider).dio;
      final tempUrl = _urlController.text.trim();
      final response = await dio.get('$tempUrl/health');
      if (response.statusCode == 200) {
        setState(() {
          _isConnectionSuccess = true;
          _connectionStatus = 'Connected! Server is healthy.';
        });
      } else {
        setState(() {
          _isConnectionSuccess = false;
          _connectionStatus = 'Server error (${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _isConnectionSuccess = false;
        _connectionStatus = 'Connection failed. Ensure FastAPI is running.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isTestingConnection = false;
        });
      }
    }
  }

  Future<void> _playVoiceSample() async {
    try {
      await _testTts.setSpeechRate(_speechRate);
      await _testTts.setPitch(_speechPitch);
      await _testTts.speak('Hello! I am ${_nameController.text.trim()}, your voice companion.');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Companion Settings'),
        actions: [
          IconButton(
            tooltip: 'Save',
            icon: const Icon(Icons.check_rounded, color: AppTheme.primaryNeon),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Section: Companion Identity
          _buildSectionHeader('COMPANION IDENTITY', Icons.person_pin_rounded),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Companion Name',
              hintText: 'e.g. Aura, Jarvis, Nova',
              prefixIcon: Icon(Icons.badge_rounded, color: AppTheme.primaryNeon),
            ),
          ),
          const SizedBox(height: 16),

          // Tone Selector Cards
          const Text(
            'Personality Tone',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          ...CompanionTone.values.map((tone) {
            final isSelected = _selectedTone == tone;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedTone = tone;
                  });
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.surfaceElevated : AppTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryNeon : AppTheme.surfaceBorder,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: isSelected ? AppTheme.primaryNeon : AppTheme.textMuted,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tone.displayName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tone.description,
                              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 24),

          // Section: Voice & Speech (TTS)
          _buildSectionHeader('VOICE & AUDIO (TTS)', Icons.volume_up_rounded),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Auto-Speak Responses', style: TextStyle(fontSize: 14)),
            subtitle: const Text('Speak response aloud when received', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            value: _autoSpeak,
            activeTrackColor: AppTheme.primaryNeon,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) {
              setState(() {
                _autoSpeak = val;
              });
            },
          ),
          const SizedBox(height: 8),

          // Speech Rate
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Speech Rate', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              Text('${(_speechRate * 2).toStringAsFixed(1)}x', style: const TextStyle(fontSize: 12, color: AppTheme.primaryNeon)),
            ],
          ),
          Slider(
            value: _speechRate,
            min: 0.2,
            max: 0.8,
            divisions: 6,
            activeColor: AppTheme.primaryNeon,
            inactiveColor: AppTheme.surfaceBorder,
            onChanged: (val) {
              setState(() {
                _speechRate = val;
              });
            },
          ),

          // Speech Pitch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Speech Pitch', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              Text(_speechPitch.toStringAsFixed(1), style: const TextStyle(fontSize: 12, color: AppTheme.primaryNeon)),
            ],
          ),
          Slider(
            value: _speechPitch,
            min: 0.5,
            max: 1.5,
            divisions: 10,
            activeColor: AppTheme.primaryNeon,
            inactiveColor: AppTheme.surfaceBorder,
            onChanged: (val) {
              setState(() {
                _speechPitch = val;
              });
            },
          ),

          // Voice Sample Button
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _playVoiceSample,
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('Test Voice Sample'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accentCyan,
                side: const BorderSide(color: AppTheme.accentCyan),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Section: Backend Connection
          _buildSectionHeader('SERVER CONNECTION', Icons.dns_rounded),
          const SizedBox(height: 12),
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'FastAPI Backend URL',
              hintText: 'http://localhost:8000',
              prefixIcon: Icon(Icons.link_rounded, color: AppTheme.secondaryNeon),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _isTestingConnection ? null : _testConnection,
                icon: _isTestingConnection
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Icon(Icons.wifi_tethering_rounded, size: 16),
                label: const Text('Test Connection'),
              ),
              const SizedBox(width: 12),
              if (_connectionStatus != null)
                Expanded(
                  child: Text(
                    _connectionStatus!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _isConnectionSuccess ? AppTheme.accentGreen : const Color(0xFFEF4444),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 36),

          // Save Button
          ElevatedButton(
            onPressed: _saveSettings,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: AppTheme.primaryNeon,
            ),
            child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryNeon),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: AppTheme.primaryNeon,
          ),
        ),
      ],
    );
  }
}
