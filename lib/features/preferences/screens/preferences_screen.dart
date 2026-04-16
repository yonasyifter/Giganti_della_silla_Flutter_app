import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../models/user_preferences_model.dart';
import '../providers/user_preferences_provider.dart';
import '../../map/providers/trail_recommender_provider.dart';

// ── Immutable option model ────────────────────────────────────────────────────

class _Opt {
  final String value;
  final String label;
  final String desc;
  const _Opt(this.value, this.label, [this.desc = '']);
}

// ── Option definitions ────────────────────────────────────────────────────────

const _difficulties = [
  _Opt('easy',     '🟢 Easy',     'Minimal elevation, relaxed pace'),
  _Opt('moderate', '🟡 Moderate', 'Some challenging sections'),
  _Opt('hard',     '🔴 Hard',     'Demanding climbs and descents'),
];

const _noiseOptions = [
  _Opt('very_quiet',  'Very Quiet 🌲',   'Peaceful and serene environment'),
  _Opt('comfortable', 'Comfortable 🎵',  'Natural sounds and ambiance'),
  _Opt('noticeable',  'Noticeable 🔊',   'Some noticeable sounds and activity'),
];

const _slopeOptions = [
  _Opt('steep',    'Steep ⛰️',    'Demanding climbs and descents'),
  _Opt('moderate', 'Moderate 🥾', 'Some challenging sections'),
  _Opt('flat',     'Flat 🌾',     'Minimal elevation change'),
];

const _vibeOptions = [
  _Opt('frosty',       'Frosty 🥶'),
  _Opt('moody',        'Moody 🌩️'),
  _Opt('brisk',        'Brisk 💨'),
  _Opt('serene_mild',  'Serene, Mild 😌'),
  _Opt('crisp_clear',  'Crisp, Clear 🍃'),
  _Opt('sun_drenched', 'Sun-Drenched ☀️'),
];

const _widthOptions = [
  _Opt('narrow',   'Narrow 🌿',   'Intimate single-track paths'),
  _Opt('moderate', 'Moderate 🛤️', 'Standard trail width'),
  _Opt('wide',     'Wide 🛣️',     'Spacious paths, accessible'),
];

const _interestOptions = [
  _Opt('history', '🏛️ History', 'Historical sites and heritage'),
  _Opt('botany',  '🌿 Botany',  'Flora, wildlife and nature'),
];

const _languageOptions = [
  _Opt('en', '🇬🇧 English'),
  _Opt('it', '🇮🇹 Italiano'),
  _Opt('fr', '🇫🇷 Français'),
  _Opt('de', '🇩🇪 Deutsch'),
  _Opt('es', '🇪🇸 Español'),
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
    Future.microtask(() async {
      await ref.read(preferencesProvider.notifier).load();
      final prefs = ref.read(preferencesProvider).valueOrNull;
      if (prefs != null) {
        await ref.read(trailRecommenderProvider.notifier).load(prefs);
      }
    });
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

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final current = ref.read(preferencesProvider).valueOrNull;
    if (current == null) {
      setState(() => _isSaving = false);
      return;
    }
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
    await ref.read(trailRecommenderProvider.notifier).load(updated);
    setState(() => _isSaving = false);
    if (mounted) {
      // Show a brief confirmation then immediately navigate to trail picker
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(children: [
            Icon(Icons.cloud_done, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text('Preferences saved! Showing your trails…'),
          ]),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: Duration(milliseconds: 1200),
        ),
      );
      // Navigate to the dedicated recommended trails screen
      context.push('/recommended-trails');
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefsAsync  = ref.watch(preferencesProvider);
    ref.listen(preferencesProvider, (_, next) {
      if (next.hasValue) _syncFromPrefs(next.value!);
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: prefsAsync.isLoading && !_loaded
              ? const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primaryLight))
              : Column(
                  children: [
                    // ── Header ─────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Row(children: [
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('My Preferences',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium),
                              const Text(
                                  'Saved to Firebase · powers trail AI',
                                  style: TextStyle(
                                      color: AppColors.textHint,
                                      fontSize: 11)),
                            ]),
                        const Spacer(),
                        _FirebaseBadge(),
                      ]),
                    ),
                    const SizedBox(height: 8),

                    // ── Scrollable body ────────────────────────────────────
                    Expanded(
                      child: SingleChildScrollView(
                        padding:
                            const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Dropdowns ───────────────────────────────────
                            _DropdownField(
                              label: 'Trail Difficulty',
                              value: _difficulty,
                              options: _difficulties,
                              onChanged: (v) =>
                                  setState(() => _difficulty = v),
                            ),
                            const SizedBox(height: 14),
                            _DropdownField(
                              label: 'Noise Preference',
                              subtitle:
                                  'Very Quiet = 🌲 quiet forest  ·  Others = ☀️ bright open',
                              value: _noise,
                              options: _noiseOptions,
                              onChanged: (v) =>
                                  setState(() => _noise = v),
                            ),
                            const SizedBox(height: 14),
                            _DropdownField(
                              label: 'Primary Interest',
                              value: _interest,
                              options: _interestOptions,
                              onChanged: (v) =>
                                  setState(() => _interest = v),
                            ),
                            const SizedBox(height: 14),
                            _DropdownField(
                              label: 'Slope Preference',
                              value: _slope,
                              options: _slopeOptions,
                              onChanged: (v) =>
                                  setState(() => _slope = v),
                            ),
                            const SizedBox(height: 14),
                            _DropdownField(
                              label: 'Trail Width',
                              value: _width,
                              options: _widthOptions,
                              onChanged: (v) =>
                                  setState(() => _width = v),
                            ),
                            const SizedBox(height: 14),
                            _DropdownField(
                              label: 'Preferred Vibe',
                              value: _vibe,
                              options: _vibeOptions,
                              onChanged: (v) =>
                                  setState(() => _vibe = v),
                            ),
                            const SizedBox(height: 14),
                            _DropdownField(
                              label: 'App Language',
                              value: _language,
                              options: _languageOptions,
                              onChanged: (v) =>
                                  setState(() => _language = v),
                            ),
                            const SizedBox(height: 14),

                            // ── Voice Guide ─────────────────────────────────
                            _VoiceToggle(
                              value: _voiceGuide,
                              onChanged: (v) =>
                                  setState(() => _voiceGuide = v),
                            ),
                            const SizedBox(height: 22),

                            // ── Save button ─────────────────────────────────
                            ElevatedButton(
                              onPressed: _isSaving ? null : _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                minimumSize:
                                    const Size.fromHeight(54),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(14)),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2))
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.cloud_done,
                                            color: Colors.white,
                                            size: 20),
                                        SizedBox(width: 10),
                                        Text('Save Preferences',
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight:
                                                    FontWeight.w600,
                                                color: Colors.white)),
                                      ],
                                    ),
                            ),
                            const SizedBox(height: 40),
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

// ── Dropdown Field ────────────────────────────────────────────────────────────

class _DropdownField extends StatelessWidget {
  final String label;
  final String? subtitle;
  final String value;
  final List<_Opt> options;
  final void Function(String) onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle!,
              style: const TextStyle(
                  color: AppColors.textHint,
                  fontSize: 10,
                  height: 1.4)),
        ],
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: AppColors.surface,
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: AppColors.textSecondary),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              borderRadius: BorderRadius.circular(12),
              selectedItemBuilder: (ctx) => options
                  .map((o) => Align(
                        alignment: Alignment.centerLeft,
                        child: Text(o.label,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500)),
                      ))
                  .toList(),
              items: options
                  .map((o) => DropdownMenuItem(
                        value: o.value,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(o.label,
                                style: TextStyle(
                                    color: o.value == value
                                        ? AppColors.primaryLight
                                        : AppColors.textPrimary,
                                    fontWeight: o.value == value
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    fontSize: 14)),
                            if (o.desc.isNotEmpty)
                              Text(o.desc,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11)),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ── Voice Toggle ──────────────────────────────────────────────────────────────

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
        const Icon(Icons.record_voice_over,
            color: AppColors.primaryLight, size: 22),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Voice Guide',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600)),
                Text('AI reads trail info aloud',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
              ]),
        ),
        Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primaryLight),
      ]),
    );
  }
}

// ── Firebase Badge ────────────────────────────────────────────────────────────

class _FirebaseBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6F00).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: const Color(0xFFFF6F00).withValues(alpha: 0.4)),
      ),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.local_fire_department,
            color: Color(0xFFFF6F00), size: 13),
        SizedBox(width: 4),
        Text('Firestore',
            style: TextStyle(
                color: Color(0xFFFF6F00),
                fontSize: 10,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
