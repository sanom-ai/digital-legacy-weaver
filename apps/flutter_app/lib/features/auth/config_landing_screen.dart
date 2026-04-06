import 'package:digital_legacy_weaver/features/auth/demo_scenarios.dart';
import 'package:digital_legacy_weaver/features/intent_builder/intent_builder_screen.dart';
import 'package:digital_legacy_weaver/features/profile/profile_model.dart';
import 'package:digital_legacy_weaver/features/settings/safety_settings_model.dart';
import 'package:flutter/material.dart';

class ConfigLandingScreen extends StatefulWidget {
  const ConfigLandingScreen({
    super.key,
    this.unlockAttempt = false,
  });

  final bool unlockAttempt;

  @override
  State<ConfigLandingScreen> createState() => _ConfigLandingScreenState();
}

class _ConfigLandingScreenState extends State<ConfigLandingScreen> {
  bool? _thaiMode;
  bool _localStepsExpanded = false;

  static final ProfileModel _demoProfile = ProfileModel(
    id: 'demo-owner',
    backupEmail: 'owner@example.com',
    beneficiaryEmail: 'beneficiary@example.com',
    beneficiaryName: 'Demo Beneficiary',
    beneficiaryPhone: '+66-800-000-000',
    beneficiaryVerificationHint: 'Shared family phrase from setup',
    beneficiaryVerificationPhraseHash: 'demo-seeded-hash',
    legacyInactivityDays: 180,
    selfRecoveryInactivityDays: 45,
    lastActiveAt: DateTime.utc(2026, 1, 1),
  );

  static const SafetySettingsModel _demoSettings = SafetySettingsModel(
    remindersEnabled: true,
    reminderOffsetsDays: [14, 7, 1],
    gracePeriodDays: 7,
    proofOfLifeCheckMode: 'biometric_tap',
    proofOfLifeFallbackChannels: ['email', 'sms'],
    serverHeartbeatFallbackEnabled: true,
    iosBackgroundRiskAcknowledged: true,
    legalDisclaimerAccepted: true,
    emergencyPauseUntil: null,
    requireTotpUnlock: false,
    privateFirstMode: true,
    tracePrivacyProfile: 'minimal',
  );

  bool get _isThai => _thaiMode ?? false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_thaiMode != null) return;
    final locale = Localizations.localeOf(context);
    _thaiMode = locale.languageCode.toLowerCase().startsWith('th');
  }

  String _tr(String th, String en) => _isThai ? th : en;

  void _openScenario(BuildContext context, DemoScenario scenario) {
    final profile = scenario.buildProfile(_demoProfile);
    final document = scenario.buildDocument(
      profile: profile,
      settings: _demoSettings,
      ownerRefOverride: scenario.ownerRef,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IntentBuilderScreen(
          profile: profile,
          settings: _demoSettings,
          initialDocument: document,
          storageOwnerRef: scenario.ownerRef,
          screenTitle: _scenarioTitle(scenario),
          screenSubtitle: _scenarioSummary(scenario),
        ),
      ),
    );
  }

  void _openWorkspaceQuick(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IntentBuilderScreen(
          profile: _demoProfile,
          settings: _demoSettings,
          screenTitle: _tr('พื้นที่ทำงานส่วนตัว', 'Private workspace'),
          screenSubtitle: _tr(
            'ข้ามเดโมแล้วเริ่มจัดเส้นทางของคุณได้ทันที',
            'Skip demo and start shaping your own flow immediately.',
          ),
        ),
      ),
    );
  }

  void _showBackendSetupSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _tr(
                  'เชื่อมต่อคลาวด์ภายหลัง (ไม่บังคับ)',
                  'Connect a live backend later (optional)',
                ),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _tr(
                  'ตอนนี้คุณใช้โหมดในเครื่องต่อได้เลย ถ้าทีมพร้อมค่อยเชื่อมต่อคลาวด์สำหรับการซิงก์บัญชี',
                  'You can continue in local mode now. Connect cloud runtime only when your team is ready for account sync.',
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: const Color(0xFFF7F1E8),
                ),
                child: const SelectableText(
                  'flutter run --dart-define=SUPABASE_URL=<url> --dart-define=SUPABASE_ANON_KEY=<anon_key>',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _tr(
                  'เชื่อมต่อเสร็จแล้ว ระบบล็อกอินและโหมดคลาวด์จะเปิดใช้งานอัตโนมัติ',
                  'After connection, sign-in and cloud-backed runtime flows will activate automatically.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _scenarioTitle(DemoScenario scenario) {
    switch (scenario.id) {
      case 'family_handoff':
        return _tr(
          'เส้นทางมอบมรดกดิจิทัลให้คนที่คุณรัก',
          'Digital Legacy Handoff',
        );
      case 'self_recovery':
        return _tr('กู้คืนบัญชีเจ้าของ', 'Owner Self-Recovery');
      case 'private_archive':
        return _tr('คลังส่วนตัวเข้มงวด', 'Private-first Archive');
      default:
        return scenario.title;
    }
  }

  String _scenarioSummary(DemoScenario scenario) {
    switch (scenario.id) {
      case 'family_handoff':
        return _tr(
          'เดโมหลักที่เห็นเส้นทางครบ ตั้งแต่เตรียมจนถึงมอบให้ผู้รับ',
          'Best first demo with full end-to-end handoff flow.',
        );
      case 'self_recovery':
        return _tr(
          'เริ่มจากการให้เจ้าของกู้คืนได้ก่อน เพื่อลดการส่งต่อผิดพลาด',
          'Start with owner recovery first to reduce accidental handoff.',
        );
      case 'private_archive':
        return _tr(
          'เดโมเน้นความเป็นส่วนตัวสูงสุด เหมาะกับข้อมูลอ่อนไหว',
          'Confidentiality-heavy route for the strictest privacy posture.',
        );
      default:
        return scenario.summary;
    }
  }

  String _scenarioBadge(DemoScenario scenario) {
    if (scenario.id == 'family_handoff') {
      return _tr('เดโมแรกที่แนะนำ', 'Best first demo');
    }
    if (scenario.id == 'self_recovery') {
      return _tr('เส้นทางกู้คืน', 'Recovery path');
    }
    return _tr('ความเป็นส่วนตัวสูง', 'Highest privacy');
  }

  String _scenarioAction(DemoScenario scenario) {
    if (scenario.id == 'family_handoff') {
      return _tr('ลองเดโมนี้ก่อนเลย', 'Start this demo first');
    }
    if (scenario.id == 'self_recovery') {
      return _tr('เริ่มเดโมกู้คืน', 'Start self-recovery demo');
    }
    return _tr('เริ่มเดโมคลังส่วนตัว', 'Start private archive demo');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compact = MediaQuery.of(context).size.width < 920;
    final title = widget.unlockAttempt
        ? _tr(
            'เปิดลิงก์มาแล้ว เริ่มโหมดส่วนตัวต่อได้ทันที',
            'Receipt opened. Continue safely in private local mode.',
          )
        : _tr(
            'เริ่มเลย โหมดส่วนตัวในเครื่อง',
            'Start now with private-first local mode',
          );
    final summary = widget.unlockAttempt
        ? _tr(
            'ลิงก์นี้เปิดได้แล้ว แต่การปลดล็อกจริงต้องมี runtime เชื่อมต่อ คุณยังทดลองเส้นทางหลักแบบ local ได้ทันที',
            'This receipt link opened, but secure unlock needs a connected runtime. You can still try the complete product flow in local mode now.',
          )
        : _tr(
            'เริ่มใช้งานได้ทันที ไม่ต้องตั้งค่าคลาวด์ก่อน',
            'Start immediately without backend setup.',
          );

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHero(theme, title, summary),
                const SizedBox(height: 16),
                Card(
                  color: const Color(0xFFF7F1E8),
                  child: ListTile(
                    leading: const Icon(Icons.flag_circle_outlined),
                    title: Text(_tr('Step 1 of 3: เลือกเส้นทางแรก', 'Step 1 of 3: Choose your first journey')),
                    subtitle: Text(_tr(
                      'เริ่มจากเดโมที่ใกล้เคสจริงที่สุด',
                      'Start with one concrete path before deeper setup.',
                    )),
                  ),
                ),
                const SizedBox(height: 16),
                if (compact) ...[
                  _buildJourneyCard(theme),
                  const SizedBox(height: 12),
                  _buildLocalModeSteps(theme, collapsible: true),
                ] else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildJourneyCard(theme)),
                      const SizedBox(width: 16),
                      Expanded(flex: 2, child: _buildLocalModeSteps(theme)),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Card(
                  color: const Color(0xFFFFF7ED),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _tr(
                        'ขอบเขตผลิตภัณฑ์: แอปนี้ช่วยจัดการเส้นทางส่งต่อการเข้าถึงอย่างปลอดภัย แต่ไม่แทนกระบวนการทางกฎหมาย',
                        'Product boundary: this app coordinates secure access handoff. It does not replace legal processes.',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(ThemeData theme, String title, String summary) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF201812), Color(0xFF4A382B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9DDCC),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _tr('พื้นที่ทำงานแบบ private-first', 'Private-first product workspace'),
                ),
              ),
              const Spacer(),
              _LanguageToggle(
                isThai: _isThai,
                onChanged: (isThai) => setState(() => _thaiMode = isThai),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            summary,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _LandingBadge(
                label: _tr(
                  'เส้นทางมอบมรดกดิจิทัลให้คนที่คุณรัก',
                  'Digital Legacy Handoff',
                ),
              ),
              _LandingBadge(
                label: _tr(
                  'บันทึกฉบับร่างเข้ารหัสลับในเครื่อง',
                  'Private Encrypted Drafts',
                ),
              ),
              _LandingBadge(
                label: _tr(
                  'เริ่มเลย ไม่ต้องตั้งค่าคลาวด์',
                  'Start in Private Local Mode',
                ),
                highlighted: true,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Center(
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF6A34B),
                foregroundColor: const Color(0xFF22160E),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              onPressed: () => _openScenario(context, demoScenarios.first),
              child: Text(_tr('เริ่มโหมดส่วนตัวทันที', 'Start in Private Local Mode')),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                TextButton(
                  onPressed: () => _openWorkspaceQuick(context),
                  child: Text(_tr('รู้แล้ว ข้ามไปหน้าแดชบอร์ด', 'I already know, go to dashboard')),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFFD5AC),
                    side: const BorderSide(color: Color(0xFFFFD5AC)),
                  ),
                  onPressed: () => _showBackendSetupSheet(context),
                  child: Text(_tr('ดูวิธีเชื่อมต่อคลาวด์', 'Cloud setup later')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _tr('เลือกเส้นทางแรกที่ใช้งานจริง', 'Choose your first real user journey'),
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _tr(
                'เริ่มจากเคสเดียวที่ใกล้ชีวิตจริงที่สุด แล้วค่อยขยายต่อ',
                'Pick one concrete path and move straight to outcomes.',
              ),
            ),
            const SizedBox(height: 14),
            ...demoScenarios.map(
              (scenario) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ScenarioCard(
                  title: _scenarioTitle(scenario),
                  summary: _scenarioSummary(scenario),
                  badge: _scenarioBadge(scenario),
                  actionLabel: _scenarioAction(scenario),
                  highlighted: scenario.id == 'family_handoff',
                  onOpen: () => _openScenario(context, scenario),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalModeSteps(ThemeData theme, {bool collapsible = false}) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        _ModeMiniCard(
          icon: Icons.smartphone_rounded,
          title: _tr('เริ่มจากเดโมที่พร้อมใช้', 'Start with a ready demo'),
        ),
        _ModeMiniCard(
          icon: Icons.visibility_rounded,
          title: _tr('ตรวจความปลอดภัยและเวอร์ชันได้ทันที', 'Review safety and version history'),
        ),
        _ModeMiniCard(
          icon: Icons.check_circle_rounded,
          title: _tr('เช็กความพร้อมก่อนค่อยเชื่อมต่อคลาวด์', 'Confirm readiness before cloud setup'),
        ),
      ],
    );

    if (collapsible) {
      return Card(
        child: ExpansionTile(
          initiallyExpanded: _localStepsExpanded,
          onExpansionChanged: (expanded) =>
              setState(() => _localStepsExpanded = expanded),
          title: Text(_tr('ในโหมด local จะเกิดอะไรขึ้น', 'What happens in local mode')),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          children: [content],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _tr('ในโหมด local จะเกิดอะไรขึ้น', 'What happens in local mode'),
              style: theme.textTheme.titleMedium,
            ),
            content,
          ],
        ),
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({
    required this.title,
    required this.summary,
    required this.badge,
    required this.actionLabel,
    required this.highlighted,
    required this.onOpen,
  });

  final String title;
  final String summary;
  final String badge;
  final String actionLabel;
  final bool highlighted;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlighted ? const Color(0xFFF6A34B) : const Color(0xFFE5D7C5),
          width: highlighted ? 2 : 1,
        ),
        color: highlighted ? const Color(0xFFFFFAF4) : null,
      ),
      padding: EdgeInsets.all(highlighted ? 20 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (highlighted) ...[
            const Row(
              children: [
                Icon(Icons.family_restroom_rounded, color: Color(0xFF7A4B22)),
                SizedBox(width: 6),
                Icon(Icons.lock_rounded, color: Color(0xFF7A4B22)),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: const Color(0xFFF7F1E8),
                ),
                child: Text(badge),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(summary),
          const SizedBox(height: 14),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor:
                  highlighted ? const Color(0xFFF6A34B) : const Color(0xFF2E2218),
              foregroundColor: highlighted ? const Color(0xFF21170F) : Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: highlighted ? 18 : 14,
                vertical: highlighted ? 14 : 10,
              ),
            ),
            onPressed: onOpen,
            child: Text(
              actionLabel,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: highlighted ? 16 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LandingBadge extends StatelessWidget {
  const _LandingBadge({
    required this.label,
    this.highlighted = false,
  });

  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: highlighted
            ? const Color(0xFFF6A34B).withValues(alpha: 0.35)
            : Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}

class _ModeMiniCard extends StatelessWidget {
  const _ModeMiniCard({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFF7F1E8),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6A4629)),
          const SizedBox(width: 10),
          Expanded(child: Text(title)),
        ],
      ),
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle({
    required this.isThai,
    required this.onChanged,
  });

  final bool isThai;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LangChip(
              label: 'ไทย',
              selected: isThai,
              onTap: () => onChanged(true),
            ),
            const SizedBox(width: 4),
            _LangChip(
              label: 'EN',
              selected: !isThai,
              onTap: () => onChanged(false),
            ),
          ],
        ),
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  const _LangChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: selected ? const Color(0xFFF6A34B) : Colors.transparent,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF25190F) : Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
