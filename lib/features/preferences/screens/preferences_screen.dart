import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../models/user_preferences_model.dart';
import '../providers/user_preferences_provider.dart';
import '../../map/providers/trail_recommender_provider.dart';

// ── Option definitions — mirror TRAIL_PREFERENCES from constants.js ─────────

const _difficulties = [
  {'value': 'easy',     'label': '🟢 Easy',     'desc': 'Minimal elevation, relaxed pace'},
  {'value': 'moderate', 'label': '🟡 Moderate', 'desc': 'Some challenging sections'},
  {'value': 'hard',     'label': '🔴 Hard',     'desc': 'Demanding climbs and descents'},
];

const _noiseOptions = [
  {'value': 'very_quiet',   'label': 'Very Quiet 🌲',   'desc': 'Peaceful and serene environment'},
  {'value': 'comfortable',  'label': 'Comfortable 🎵',  'desc': 'Natural sounds and ambiance'},
  {'value': 'noticeable',   'label': 'Noticeable 🔊',   'desc': 'Some noticeable sounds and activity'},
];

const _slopeOptions = [
  {'value': 'steep',    'label': 'Steep ⛰️',    'desc': 'Demanding climbs and descents'},
  {'value': 'moderate', 'label': 'Moderate 🥾', 'desc': 'Some challenging sections'},
  {'value': 'flat',     'label': 'Flat 🌾',     'desc': 'Minimal elevation change'},
];

const _vibeOptions = [
  {'value': 'frosty',       'label': 'Frosty 🥶'},
  {'value': 'moody',        'label': 'Moody 🌩️'},
  {'value': 'brisk',        'label': 'Brisk 💨'},
  {'value': 'serene_mild',  'label': 'Serene, Mild 😌'},
  {'value': 'crisp_clear',  'label': 'Crisp, Clear 🍃'},
  {'value': 'sun_drenched', 'label': 'Sun-Drenched ☀️'},
];

const _widthOptions = [
  {'value': 'narrow',   'label': 'Narrow 🌿',   'desc': 'Intimate single-track paths'},
  {'value': 'moderate', 'label': 'Moderate 🛤️', 'desc': 'Standard trail width'},
  {'value': 'wide',     'label': 'Wide 🛣️',     'desc': 'Spacious paths, accessible'},
];

const _interestOptions = [
  {'value': 'history', 'label': '🏛️ History',  'desc': 'Historical sites and heritage'},
  {'value': 'botany',  'label': '🌿 Botany',   'desc': 'Flora, wildlife and nature'},
];

// ─────────────────────────────────────────────────────────────────────────────

class PreferencesScreen extends ConsumerStatefulWidget {
  const PreferencesScreen({super.key});

  @override
  ConsumerState<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends ConsumerState<PreferencesScreen> {
  String _difficulty = 'moderate';
  String _noise      = 'comfortable';
  String _slope      = 'moderate';
  String _vibe       = 'serene_mild';
  String _width      = 'moderate';
  String _interest   = 'history';
  String _language   = 'en';
  bool   _voiceGuide = true;
  bool   _isSaving   = false;
  bool   _loaded     = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(preferencesProvider.notifier).load());
  }

  void _syncFromPrefs(UserPreferences p) {
    if (_loaded) return;
    setState(() {
      _difficulty = p.difficulty;
      _noise      = p.noise;
      _slope      = p.slope;
      _vibe       = p.vibe;
      _width      = p.width;
      _interest   = p.interest;
      _language   = p.language;
      _voiceGuide = p.voiceGuideEnabled;
      _loaded     = true;
    });
  }

  // Build preview of which trail will be recommended
  String _previewKey() {
    final env = _noise == 'very_quiet' ? 'quiet' : 'bright';
    return '${_difficulty}_${env}_$_interest';
  }

  static const _keyToName = {
    'easy_quiet_history':    'The Silent Giant Path',
    'easy_quiet_botany':     'The Silent Giant Path',
    'easy_bright_history':   'The Sunlit Glade',
    'easy_bright_botany':    'The Sunlit Glade',
    'moderate_quiet_history':'Ancient Forest Loop',
    'moderate_quiet_botany': 'Ancient Forest Loop',
    'moderate_bright_history':'Main Park Loop',
    'moderate_bright_botany': 'Main Park Loop',
    'hard_quiet_history':    'Deep Sila Ridge',
    'hard_quiet_botany':     'Deep Sila Ridge',
    'hard_bright_history':   'Peak of the Giants',
    'hard_bright_botany':    'Peak of the Giants',
  };

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final current = ref.read(preferencesProvider).valueOrNull;
    if (current == null) { setState(() => _isSaving = false); return; }

    final updated = current.copyWith(
      difficulty:        _difficulty,
      noise:             _noise,
      slope:             _slope,
      vibe:              _vibe,
      width:             _width,
      interest:          _interest,
      language:          _language,
      voiceGuideEnabled: _voiceGuide,
    );

    await ref.read(preferencesProvider.notifier).save(updated);
    // Refresh trail recommendation
    await ref.read(trailRecommenderProvider.notifier).load(updated);
    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.cloud_done, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text('Saved! Trail: ${_keyToName[_previewKey()] ?? "—"}'),
          ]),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefsAsync = ref.watch(preferencesProvider);

    ref.listen(preferencesProvider, (_, next) {
      if (next.hasValue) _syncFromPrefs(next.value!);
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: prefsAsync.isLoading && !_loaded
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryLight))
              : Column(
                  children: [
                    // ── Header ────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('My Preferences',
                                  style: Theme.of(context).textTheme.headlineMedium),
                              const Text('Saved to Firebase · powers trail AI',
                                  style: TextStyle(color: AppColors.textHint, fontSize: 11)),
                            ],
                          ),
                          const Spacer(),
                          _FirebaseBadge(),
                        ],
                      ),
                    ),

                    // ── Live recommendation preview ────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: _RecommendationPreview(
                        trailName: _keyToName[_previewKey()] ?? '—',
                        previewKey: _previewKey(),
                      ),
                    ),

                    const SizedBox(height: 4),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // ── Difficulty ────────────────────────────────
                            const _SectionTitle('Trail Difficulty'),
                            const SizedBox(height: 10),
                            ..._difficulties.map((opt) => _RadioCard(
                              value:    opt['value']!,
                              label:    opt['label']!,
                              desc:     opt['desc']!,
                              selected: _difficulty,
                              onTap:    (v) => setState(() => _difficulty = v),
                            )),
                            const SizedBox(height: 22),

                            // ── Noise preference (also sets environment) ──
                            const _SectionTitle('Noise Preference'),
                            const _SubTitle('Sets your environment: Very Quiet = 🌲 quiet forest · Others = ☀️ bright open'),
                            const SizedBox(height: 10),
                            ..._noiseOptions.map((opt) => _RadioCard(
                              value:    opt['value']!,
                              label:    opt['label']!,
                              desc:     opt['desc']!,
                              selected: _noise,
                              onTap:    (v) => setState(() => _noise = v),
                            )),
                            const SizedBox(height: 22),

                            // ── Interest ──────────────────────────────────
                            const _SectionTitle('Primary Interest'),
                            const SizedBox(height: 10),
                            ..._interestOptions.map((opt) => _RadioCard(
                              value:    opt['value']!,
                              label:    opt['label']!,
                              desc:     opt['desc']!,
                              selected: _interest,
                              onTap:    (v) => setState(() => _interest = v),
                            )),
                            const SizedBox(height: 22),

                            // ── Slope ─────────────────────────────────────
                            const _SectionTitle('Slope Preference'),
                            const SizedBox(height: 10),
                            Row(
                              children: _slopeOptions.map((opt) => Expanded(
                                child: _ChipCard(
                                  value:    opt['value']!,
                                  label:    opt['label']!,
                                  selected: _slope == opt['value'],
                                  onTap:    () => setState(() => _slope = opt['value']!),
                                ),
                              )).toList(),
                            ),
                            const SizedBox(height: 22),

                            // ── Vibe ──────────────────────────────────────
                            const _SectionTitle('Preferred Vibe'),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8, runSpacing: 8,
                              children: _vibeOptions.map((opt) => _ChipCard(
                                value:    opt['value']!,
                                label:    opt['label']!,
                                selected: _vibe == opt['value'],
                                onTap:    () => setState(() => _vibe = opt['value']!),
                              )).toList(),
                            ),
                            const SizedBox(height: 22),

                            // ── Width ─────────────────────────────────────
                            const _SectionTitle('Trail Width'),
                            const SizedBox(height: 10),
                            Row(
                              children: _widthOptions.map((opt) => Expanded(
                                child: _ChipCard(
                                  value:    opt['value']!,
                                  label:    opt['label']!,
                                  selected: _width == opt['value'],
                                  onTap:    () => setState(() => _width = opt['value']!),
                                ),
                              )).toList(),
                            ),
                            const SizedBox(height: 22),

                            // ── Language & Voice ──────────────────────────
                            const _SectionTitle('AI Guide Settings'),
                            const SizedBox(height: 10),
                            Row(children: [
                              Expanded(child: _ChipCard(
                                value: 'en', label: '🇬🇧 English',
                                selected: _language == 'en',
                                onTap: () => setState(() => _language = 'en'),
                              )),
                              const SizedBox(width: 8),
                              Expanded(child: _ChipCard(
                                value: 'it', label: '🇮🇹 Italiano',
                                selected: _language == 'it',
                                onTap: () => setState(() => _language = 'it'),
                              )),
                            ]),
                            const SizedBox(height: 12),
                            _VoiceToggle(
                              value: _voiceGuide,
                              onChanged: (v) => setState(() => _voiceGuide = v),
                            ),
                            const SizedBox(height: 28),

                            // ── Save button ───────────────────────────────
                            ElevatedButton(
                              onPressed: _isSaving ? null : _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                minimumSize: const Size.fromHeight(54),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              child: _isSaving
                                  ? const SizedBox(height: 22, width: 22,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.cloud_done, color: Colors.white, size: 20),
                                        SizedBox(width: 10),
                                        Text('Save to Firebase',
                                            style: TextStyle(fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white)),
                                      ],
                                    ),
                            ),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _FirebaseBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6F00).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFF6F00).withValues(alpha: 0.4)),
      ),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.local_fire_department, color: Color(0xFFFF6F00), size: 13),
        SizedBox(width: 4),
        Text('Firestore', style: TextStyle(color: Color(0xFFFF6F00),
            fontSize: 10, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _RecommendationPreview extends StatelessWidget {
  final String trailName;
  final String previewKey;
  const _RecommendationPreview({required this.trailName, required this.previewKey});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        const Icon(Icons.recommend, color: AppColors.primaryLight, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your trail recommendation:',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            Text(trailName,
                style: const TextStyle(color: AppColors.primaryLight,
                    fontWeight: FontWeight.w700, fontSize: 14)),
            Text('key: $previewKey',
                style: const TextStyle(color: AppColors.textHint,
                    fontSize: 9, fontFamily: 'monospace')),
          ],
        )),
      ]),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(color: AppColors.textPrimary,
          fontSize: 15, fontWeight: FontWeight.w600));
}

class _SubTitle extends StatelessWidget {
  final String text;
  const _SubTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(text, style: const TextStyle(
        color: AppColors.textHint, fontSize: 10, height: 1.4)),
  );
}

class _RadioCard extends StatelessWidget {
  final String value, label, desc, selected;
  final void Function(String) onTap;
  const _RadioCard({required this.value, required this.label,
    required this.desc, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryLight : AppColors.surfaceLight,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Container(
            width: 20, height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: isSelected ? AppColors.primaryLight : AppColors.textHint,
                  width: 2),
              color: isSelected ? AppColors.primaryLight : Colors.transparent,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 12)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w600, fontSize: 13)),
              Text(desc, style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11)),
            ],
          )),
        ]),
      ),
    );
  }
}

class _ChipCard extends StatelessWidget {
  final String value, label;
  final bool selected;
  final VoidCallback onTap;
  const _ChipCard({required this.value, required this.label,
    required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primaryLight : AppColors.surfaceLight,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(label, textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            )),
      ),
    );
  }
}

class _VoiceToggle extends StatelessWidget {
  final bool value;
  final void Function(bool) onChanged;
  const _VoiceToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Row(children: [
        const Icon(Icons.record_voice_over, color: AppColors.primaryLight, size: 22),
        const SizedBox(width: 12),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Voice Guide', style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
            Text('AI reads trail info aloud', style: TextStyle(
                color: AppColors.textSecondary, fontSize: 11)),
          ],
        )),
        Switch(value: value, onChanged: onChanged, activeThumbColor: AppColors.primaryLight),
      ]),
    );
  }
}
