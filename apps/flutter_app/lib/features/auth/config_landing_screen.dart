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
  bool _localGuideExpanded = false;
  String _selectedScenarioId = demoScenarios.first.id;

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
    proofOfLifeCheckMode: 'half_life_soft_checkin',
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

  DemoScenario get _selectedScenario {
    return demoScenarioById(_selectedScenarioId) ?? demoScenarios.first;
  }

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
            'ข้ามเดโม แล้วเริ่มสร้างแผนจริงของคุณได้ทันที',
            'Skip demo and start shaping your own plan immediately.',
          ),
        ),
      ),
    );
  }

  void _showBackendSetupSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF7EFE3), Color(0xFFFDF8F2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: const Color(0xFFE4D3BC)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F1EF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.cloud_outlined,
                        color: Color(0xFF1E6C77),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _tr(
                          'คุณเริ่มในโหมดส่วนตัวบนเครื่องได้ก่อน แล้วค่อยเพิ่มการเชื่อมคลาวด์เมื่อทีมพร้อม',
                          'You can begin in private local mode first, then add cloud connectivity later when your team is ready.',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _tr('เชื่อมคลาวด์ทีหลังได้ (ไม่บังคับ)',
                    'Connect cloud later (optional)'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _tr(
                  'เริ่มใช้งานได้ทันทีในโหมดส่วนตัวบนเครื่อง แล้วค่อยเชื่อมคลาวด์เมื่อทีมพร้อม',
                  'You can start now in private local mode. Connect cloud later when your team needs sync.',
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: const Color(0xFFFFFCF8),
                  border: Border.all(color: const Color(0xFFE2D4C2)),
                ),
                child: const SelectableText(
                  'flutter run --dart-define=SUPABASE_URL=<url> --dart-define=SUPABASE_ANON_KEY=<publishable_key>',
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
            'เส้นทางมอบมรดกดิจิทัลให้คนที่คุณรัก', 'Digital Legacy Handoff');
      case 'self_recovery':
        return _tr('กู้คืนบัญชีของฉัน', 'Owner Self-Recovery');
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
          'เดโมแนะนำที่เห็นภาพครบตั้งแต่เริ่มตั้งค่าไปจนถึงการส่งต่อ',
          'Best first demo with full handoff flow from setup to recipient.',
        );
      case 'self_recovery':
        return _tr(
          'เริ่มจากป้องกันและกู้คืนบัญชีเจ้าของก่อน ลดความเสี่ยงส่งผิดคน',
          'Start with owner account recovery before legacy handoff.',
        );
      case 'private_archive':
        return _tr(
          'เหมาะกับข้อมูลอ่อนไหวสูง เน้นความเป็นส่วนตัวมากที่สุด',
          'Confidentiality-heavy path for highly sensitive information.',
        );
      default:
        return scenario.summary;
    }
  }

  String _scenarioBadge(DemoScenario scenario) {
    if (scenario.id == 'family_handoff') {
      return _tr('แนะนำเริ่มจากอันนี้', 'Best first demo');
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
      return _tr('เริ่มเดโมกู้คืน', 'Start recovery demo');
    }
    return _tr('เริ่มเดโมคลังส่วนตัว', 'Start private vault demo');
  }

  String _scenarioDetail(DemoScenario scenario) {
    switch (scenario.id) {
      case 'family_handoff':
        return _tr(
          'เหมาะกับเจ้าของที่ต้องการส่งต่อบัญชีสำคัญและข้อมูลครอบครัวอย่างปลอดภัย พร้อมขั้นตอนยืนยันตัวตนก่อนเปิดข้อมูล',
          'For secure family handoff with identity checks before final reveal.',
        );
      case 'self_recovery':
        return _tr(
          'เน้นกู้คืนสิทธิ์การเข้าถึงของเจ้าของก่อน โดยเจ้าของยังคุมสิทธิ์ทั้งหมด',
          'For owner-first account recovery while keeping full control.',
        );
      case 'private_archive':
        return _tr(
          'เหมาะกับข้อมูลที่ต้องจำกัดการมองเห็นสูง และเปิดเผยเฉพาะเมื่อถึงเงื่อนไขจริง',
          'For strict private archive routes with minimal visibility.',
        );
      default:
        return scenario.summary;
    }
  }

  IconData _scenarioIcon(DemoScenario scenario) {
    switch (scenario.id) {
      case 'family_handoff':
        return Icons.family_restroom_rounded;
      case 'self_recovery':
        return Icons.health_and_safety_rounded;
      case 'private_archive':
        return Icons.shield_rounded;
      default:
        return Icons.route_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compact = MediaQuery.of(context).size.width < 920;

    final title = widget.unlockAttempt
        ? _tr('เปิดคำขอแล้ว ดำเนินการต่ออย่างปลอดภัย',
            'Receipt opened. Continue safely now.')
        : _tr('เริ่มเลยในโหมดส่วนตัวบนเครื่อง',
            'Start now in private local mode');

    final summary = widget.unlockAttempt
        ? _tr(
            'คุณไม่จำเป็นต้องรีบ ให้เลือกเส้นทางที่เหมาะสมแล้วทำตามขั้นตอนในแอปเท่านั้น',
            'No rush. Choose one guided path and continue inside the app only.',
          )
        : _tr(
            'ไม่ต้องตั้งค่าคลาวด์ก่อน เริ่มวางแผนได้ทันทีแบบ 3 ขั้นตอนเข้าใจง่าย',
            'No cloud setup needed. Start with a clear 3-step guided flow.',
          );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroCard(
                    title: title,
                    summary: summary,
                    isThai: _isThai,
                    onLanguageChanged: (isThai) =>
                        setState(() => _thaiMode = isThai),
                    primaryActionLabel:
                        _tr('เริ่มโหมดส่วนตัวทันที', 'Start in private mode'),
                    onPrimaryAction: () =>
                        _openScenario(context, _selectedScenario),
                    secondaryActionLabel: _tr('ฉันพร้อมแล้ว ไปหน้าใช้งานหลัก',
                        'I already know, go to dashboard'),
                    onSecondaryAction: () => _openWorkspaceQuick(context),
                    tertiaryActionLabel:
                        _tr('ดูวิธีเชื่อมคลาวด์', 'Cloud setup later'),
                    onTertiaryAction: () => _showBackendSetupSheet(context),
                    stepTitle: _tr('ขั้นตอน 1 จาก 3: เลือกเส้นทางแรก',
                        'Step 1 of 3: Choose your first journey'),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.security_rounded,
                              color: Color(0xFF0E7C86)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _tr(
                                'ความปลอดภัย: แอปจะไม่ขอรหัสผ่าน ไม่ขอให้โอนเงิน และไม่ให้กดลิงก์จากข้อความ ให้เปิดแอปแล้วกรอกรหัสด้วยตัวเองเท่านั้น',
                                'Security notice: We never ask for passwords, transfers, or message links. Open the app and enter your code directly.',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (compact) ...[
                    _buildJourneySection(theme),
                    const SizedBox(height: 12),
                    _LocalExplanationCard(
                      title: _tr('ในโหมด local จะเกิดอะไรขึ้น',
                          'What happens in local mode'),
                      expanded: _localGuideExpanded,
                      collapsible: true,
                      onExpandedChanged: (value) =>
                          setState(() => _localGuideExpanded = value),
                      items: _localGuideItems(),
                    ),
                  ] else ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildJourneySection(theme)),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: _LocalExplanationCard(
                            title: _tr('ในโหมด local จะเกิดอะไรขึ้น',
                                'What happens in local mode'),
                            expanded: true,
                            collapsible: false,
                            items: _localGuideItems(),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.gpp_good_rounded,
                              color: Color(0xFF0E7C86)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _tr(
                                'แอปนี้ช่วยประสานการส่งต่อสิทธิ์เข้าถึงอย่างปลอดภัย แต่ไม่แทนกระบวนการทางกฎหมาย',
                                'This app coordinates secure access handoff, but does not replace legal processes.',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJourneySection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _tr('เลือกเส้นทางแรกของคุณ', 'Choose your first journey'),
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _tr('เลือก 1 เส้นทางที่ใกล้ชีวิตจริงที่สุด แล้วค่อยปรับรายละเอียดภายหลัง',
                  'Pick one concrete path now, then tune details later.'),
            ),
            const SizedBox(height: 14),
            ...demoScenarios.map((scenario) {
              final selected = _selectedScenarioId == scenario.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PathCard(
                  icon: _scenarioIcon(scenario),
                  title: _scenarioTitle(scenario),
                  summary: _scenarioSummary(scenario),
                  badge: _scenarioBadge(scenario),
                  actionLabel: _scenarioAction(scenario),
                  detailLabel: _tr('ดูรายละเอียด', 'View details'),
                  detail: _scenarioDetail(scenario),
                  selected: selected,
                  highlighted: scenario.id == 'family_handoff',
                  onSelect: () =>
                      setState(() => _selectedScenarioId = scenario.id),
                  onStart: () => _openScenario(context, scenario),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  List<_LocalGuideItemData> _localGuideItems() {
    return [
      _LocalGuideItemData(
        icon: Icons.smartphone_rounded,
        title: _tr(
            'เริ่มจากเดโมที่พร้อมใช้ทันที', 'Start with a ready-to-use demo'),
      ),
      _LocalGuideItemData(
        icon: Icons.visibility_rounded,
        title: _tr('ตรวจแผนและความปลอดภัยได้บนเครื่องของคุณ',
            'Review plan and safety directly on your device'),
      ),
      _LocalGuideItemData(
        icon: Icons.verified_user_rounded,
        title: _tr('เช็กความพร้อมก่อนเชื่อมคลาวด์ทีหลัง',
            'Confirm readiness before optional cloud setup'),
      ),
    ];
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.title,
    required this.summary,
    required this.isThai,
    required this.onLanguageChanged,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    required this.secondaryActionLabel,
    required this.onSecondaryAction,
    required this.tertiaryActionLabel,
    required this.onTertiaryAction,
    required this.stepTitle,
  });

  final String title;
  final String summary;
  final bool isThai;
  final ValueChanged<bool> onLanguageChanged;
  final String primaryActionLabel;
  final VoidCallback onPrimaryAction;
  final String secondaryActionLabel;
  final VoidCallback onSecondaryAction;
  final String tertiaryActionLabel;
  final VoidCallback onTertiaryAction;
  final String stepTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF0E4F61), Color(0xFF2A6A74), Color(0xFF4A7E7A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18040A0C),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -28,
            right: -16,
            child: Container(
              width: 138,
              height: 138,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -34,
            left: -22,
            child: Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: Colors.white.withValues(alpha: 0.12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Text(
                          stepTitle,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _LanguageToggle(
                      isThai: isThai,
                      onChanged: onLanguageChanged,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: const LinearProgressIndicator(
                    value: 1 / 3,
                    minHeight: 7,
                    backgroundColor: Color(0x3387C3CE),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFFFFE7B8)),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  summary,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.93),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: onPrimaryAction,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(primaryActionLabel),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFE0A6),
                    foregroundColor: const Color(0xFF183743),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    TextButton(
                      onPressed: onSecondaryAction,
                      child: Text(
                        secondaryActionLabel,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: onTertiaryAction,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(tertiaryActionLabel),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PathCard extends StatefulWidget {
  const _PathCard({
    required this.icon,
    required this.title,
    required this.summary,
    required this.badge,
    required this.actionLabel,
    required this.detailLabel,
    required this.detail,
    required this.selected,
    required this.highlighted,
    required this.onSelect,
    required this.onStart,
  });

  final IconData icon;
  final String title;
  final String summary;
  final String badge;
  final String actionLabel;
  final String detailLabel;
  final String detail;
  final bool selected;
  final bool highlighted;
  final VoidCallback onSelect;
  final VoidCallback onStart;

  @override
  State<_PathCard> createState() => _PathCardState();
}

class _PathCardState extends State<_PathCard> {
  bool _showDetail = false;

  @override
  Widget build(BuildContext context) {
    final selectedColor =
        widget.highlighted ? const Color(0xFFEBA44E) : const Color(0xFF2A7F88);

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: widget.onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: widget.selected
              ? const Color(0xFFFFFBF5)
              : const Color(0xFFFFFDF9),
          border: Border.all(
            color: widget.selected ? selectedColor : const Color(0xFFE6DDD1),
            width: widget.selected ? 2 : 1,
          ),
          boxShadow: widget.selected
              ? const [
                  BoxShadow(
                    color: Color(0x16000000),
                    blurRadius: 26,
                    offset: Offset(0, 12),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: selectedColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selectedColor.withValues(alpha: 0.16),
                    ),
                  ),
                  child: Icon(widget.icon, color: selectedColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: const Color(0xFFF8F0E5),
                border: Border.all(color: const Color(0xFFE9DAC3)),
              ),
              child: Text(widget.badge),
            ),
            const SizedBox(height: 10),
            Text(widget.summary),
            AnimatedCrossFade(
              crossFadeState: _showDetail
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 170),
              firstChild: const SizedBox(height: 0),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  widget.detail,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF4A4038),
                      ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: widget.onStart,
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.highlighted
                        ? const Color(0xFFF2A64D)
                        : const Color(0xFF1E6A79),
                    foregroundColor: widget.highlighted
                        ? const Color(0xFF2A1808)
                        : Colors.white,
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                  ),
                  child: Text(widget.actionLabel),
                ),
                TextButton(
                  onPressed: () => setState(() => _showDetail = !_showDetail),
                  child: Text(widget.detailLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LocalExplanationCard extends StatelessWidget {
  const _LocalExplanationCard({
    required this.title,
    required this.expanded,
    required this.collapsible,
    this.onExpandedChanged,
    required this.items,
  });

  final String title;
  final bool expanded;
  final bool collapsible;
  final ValueChanged<bool>? onExpandedChanged;
  final List<_LocalGuideItemData> items;

  @override
  Widget build(BuildContext context) {
    final listContent = Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBF0EF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item.icon,
                          size: 20, color: const Color(0xFF1E6C77)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(item.title)),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );

    if (collapsible) {
      return Card(
        child: ExpansionTile(
          title: Text(title),
          initiallyExpanded: expanded,
          onExpansionChanged: onExpandedChanged,
          children: [listContent],
        ),
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          listContent,
        ],
      ),
    );
  }
}

class _LocalGuideItemData {
  const _LocalGuideItemData({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;
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
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment<bool>(value: true, label: Text('TH')),
        ButtonSegment<bool>(value: false, label: Text('EN')),
      ],
      selected: {isThai},
      onSelectionChanged: (selection) => onChanged(selection.first),
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFFFFE0A6);
          }
          return Colors.white.withValues(alpha: 0.2);
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF233C46);
          }
          return Colors.white;
        }),
      ),
    );
  }
}
