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
  late AuraTheme _selectedAura;
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
    _selectedAura = convState.auraTheme;
    _autoSpeak = convState.isTtsEnabled;
    _speechRate = prefs.getDouble(AppConstants.keyTtsRate) ?? AppConstants.defaultTtsRate;
    _speechPitch = prefs.getDouble(AppConstants.keyTtsPitch) ?? AppConstants.defaultTtsPitch;

    _loadMemories();
  }

  List<Map<String, dynamic>> _memories = [];
  bool _isLoadingMemories = false;

  Future<void> _loadMemories() async {
    final userId = ref.read(conversationProvider).userId;
    if (userId == null) return;
    setState(() => _isLoadingMemories = true);
    try {
      final dio = ref.read(dioClientProvider).dio;
      final response = await dio.get('/memories/$userId');
      if (response.data is Map && response.data['memories'] is List) {
        final list = (response.data['memories'] as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        setState(() => _memories = list);
      }
    } catch (_) {
      // offline or server not ready
    } finally {
      if (mounted) setState(() => _isLoadingMemories = false);
    }
  }

  Future<void> _deleteMemory(String memoryId) async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.delete('/memories/$memoryId');
      _loadMemories();
    } catch (_) {}
  }

  Future<void> _addMemory(String key, String value) async {
    final userId = ref.read(conversationProvider).userId;
    if (userId == null || key.trim().isEmpty || value.trim().isEmpty) return;
    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.post('/memories', data: {
        'user_id': userId,
        'key': key.trim(),
        'value': value.trim(),
      });
      _loadMemories();
    } catch (_) {}
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
    ref.read(conversationProvider.notifier).updateAuraTheme(_selectedAura);

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

  void _showAddMemoryDialog() {
    final keyController = TextEditingController();
    final valueController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        title: const Text('Add Memory Fact', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keyController,
              decoration: const InputDecoration(
                labelText: 'Fact Category / Topic',
                hintText: 'e.g. Occupation, Hobbies, Location',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: valueController,
              decoration: const InputDecoration(
                labelText: 'Fact Detail',
                hintText: 'e.g. Senior Flutter Developer',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _addMemory(keyController.text, valueController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryNeon),
            child: const Text('Save Fact'),
          ),
        ],
      ),
    );
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

          // Section: Holographic Avatar Aura
          _buildSectionHeader('HOLOGRAPHIC AVATAR AURA', Icons.auto_awesome_rounded),
          const SizedBox(height: 8),
          const Text(
            'Customize the celestial neon aura energy radiated by your holographic companion.',
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 98,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: AuraTheme.values.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final aura = AuraTheme.values[index];
                final auraColor = Color(aura.colorValue);
                final isSelected = _selectedAura == aura;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedAura = aura);
                    ref.read(conversationProvider.notifier).updateAuraTheme(aura);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 86,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? auraColor.withValues(alpha: 0.18) : AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? auraColor : AppTheme.surfaceBorder,
                        width: isSelected ? 2.0 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: auraColor.withValues(alpha: 0.35),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: auraColor,
                            boxShadow: [
                              BoxShadow(
                                color: auraColor.withValues(alpha: 0.6),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: isSelected
                              ? const Icon(Icons.check_rounded, size: 18, color: Colors.black)
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          aura.displayName,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
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

          // Section: Personal Memory Vault
          _buildSectionHeader('PERSONAL MEMORY VAULT (CROSS-SESSION)', Icons.psychology_rounded),
          const SizedBox(height: 8),
          const Text(
            'Facts your companion permanently remembers across all past and future sessions.',
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 12),
          if (_isLoadingMemories)
            const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryNeon)))
          else if (_memories.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: const Text(
                'No personal facts saved yet. Add your name, job, or hobbies so your companion always remembers!',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            )
          else
            ..._memories.map((mem) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.surfaceBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bookmark_added_rounded, color: AppTheme.accentCyan, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mem['key']?.toString() ?? '',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryNeon),
                            ),
                            Text(
                              mem['value']?.toString() ?? '',
                              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 16, color: AppTheme.textMuted),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _deleteMemory(mem['memory_id']?.toString() ?? ''),
                      ),
                    ],
                  ),
                )),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _showAddMemoryDialog,
              icon: const Icon(Icons.add_rounded, size: 16, color: AppTheme.primaryNeon),
              label: const Text('Add Personal Fact', style: TextStyle(color: AppTheme.primaryNeon, fontSize: 13, fontWeight: FontWeight.w600)),
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
          const SizedBox(height: 20),

          // About Card with App Logo
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.surfaceBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryNeon.withValues(alpha: 0.35),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/icons/app_logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NEX_AI',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Voice AI Companion • v1.0.0+1',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
