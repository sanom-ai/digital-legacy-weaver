import 'package:flutter/material.dart';

enum AppStateTone {
  info,
  success,
  loading,
  empty,
  error,
  offline,
}

enum AppStateLayout {
  inline,
  centered,
}

bool appStateLooksOfflineMessage(String text) {
  final lower = text.toLowerCase();
  return lower.contains('offline') ||
      lower.contains('network') ||
      lower.contains('internet') ||
      lower.contains('ออฟไลน์') ||
      lower.contains('อินเทอร์เน็ต') ||
      lower.contains('เครือข่าย') ||
      lower.contains('สัญญาณ');
}

class AppStatePanel extends StatelessWidget {
  const AppStatePanel({
    super.key,
    required this.message,
    this.title,
    this.tone = AppStateTone.info,
    this.layout = AppStateLayout.inline,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final String message;
  final String? title;
  final AppStateTone tone;
  final AppStateLayout layout;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final styling = _resolveStyling(scheme);
    final horizontal = compact ? 14.0 : 16.0;
    final vertical = compact ? 12.0 : 16.0;

    final panel = Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
      decoration: BoxDecoration(
        color: styling.background,
        borderRadius: BorderRadius.circular(compact ? 16 : 18),
        border: Border.all(
          color: styling.border,
          width: 1,
        ),
      ),
      child: layout == AppStateLayout.centered
          ? _buildCenteredContent(context, styling)
          : _buildInlineContent(context, styling),
    );

    if (layout == AppStateLayout.centered) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: panel,
      );
    }
    return panel;
  }

  Widget _buildInlineContent(BuildContext context, _AppStateStyling styling) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StateIconBadge(
              tone: tone,
              icon: styling.icon,
              iconColor: styling.iconColor,
              background: styling.iconBackground,
              compact: compact,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null) ...[
                    Text(
                      title!,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(message),
                ],
              ),
            ),
          ],
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onAction,
            child: Text(actionLabel!),
          ),
        ],
      ],
    );
  }

  Widget _buildCenteredContent(BuildContext context, _AppStateStyling styling) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StateIconBadge(
          tone: tone,
          icon: styling.icon,
          iconColor: styling.iconColor,
          background: styling.iconBackground,
          compact: false,
          centered: true,
        ),
        const SizedBox(height: 14),
        if (title != null) ...[
          Text(
            title!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
        ],
        Text(
          message,
          textAlign: TextAlign.center,
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: onAction,
            child: Text(actionLabel!),
          ),
        ],
      ],
    );
  }

  _AppStateStyling _resolveStyling(ColorScheme scheme) {
    switch (tone) {
      case AppStateTone.loading:
        return _AppStateStyling(
          background: scheme.surfaceContainerHighest.withValues(alpha: 0.58),
          border: scheme.outlineVariant.withValues(alpha: 0.52),
          iconBackground: Colors.white.withValues(alpha: 0.74),
          iconColor: scheme.primary,
          icon: Icons.sync_rounded,
        );
      case AppStateTone.empty:
        return _AppStateStyling(
          background: scheme.primaryContainer.withValues(alpha: 0.34),
          border: scheme.primary.withValues(alpha: 0.14),
          iconBackground: Colors.white.withValues(alpha: 0.72),
          iconColor: scheme.primary,
          icon: Icons.inventory_2_outlined,
        );
      case AppStateTone.error:
        return _AppStateStyling(
          background: scheme.errorContainer.withValues(alpha: 0.34),
          border: scheme.error.withValues(alpha: 0.16),
          iconBackground: Colors.white.withValues(alpha: 0.78),
          iconColor: scheme.error,
          icon: Icons.warning_amber_rounded,
        );
      case AppStateTone.offline:
        return _AppStateStyling(
          background: scheme.tertiaryContainer.withValues(alpha: 0.32),
          border: scheme.tertiary.withValues(alpha: 0.16),
          iconBackground: Colors.white.withValues(alpha: 0.78),
          iconColor: scheme.tertiary,
          icon: Icons.wifi_off_rounded,
        );
      case AppStateTone.success:
        return _AppStateStyling(
          background: scheme.secondaryContainer.withValues(alpha: 0.3),
          border: scheme.secondary.withValues(alpha: 0.16),
          iconBackground: Colors.white.withValues(alpha: 0.76),
          iconColor: scheme.secondary,
          icon: Icons.check_circle_outline_rounded,
        );
      case AppStateTone.info:
        return _AppStateStyling(
          background: scheme.surfaceContainerHighest.withValues(alpha: 0.52),
          border: scheme.outlineVariant.withValues(alpha: 0.52),
          iconBackground: Colors.white.withValues(alpha: 0.74),
          iconColor: scheme.onSurfaceVariant,
          icon: Icons.info_outline_rounded,
        );
    }
  }
}

class _StateIconBadge extends StatelessWidget {
  const _StateIconBadge({
    required this.tone,
    required this.icon,
    required this.iconColor,
    required this.background,
    required this.compact,
    this.centered = false,
  });

  final AppStateTone tone;
  final IconData icon;
  final Color iconColor;
  final Color background;
  final bool compact;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final size = centered ? 52.0 : (compact ? 34.0 : 38.0);
    final iconSize = centered ? 24.0 : 20.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(centered ? 18 : 14),
      ),
      alignment: Alignment.center,
      child: tone == AppStateTone.loading
          ? SizedBox(
              width: centered ? 22 : 18,
              height: centered ? 22 : 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(iconColor),
              ),
            )
          : Icon(icon, size: iconSize, color: iconColor),
    );
  }
}

class _AppStateStyling {
  const _AppStateStyling({
    required this.background,
    required this.border,
    required this.iconBackground,
    required this.iconColor,
    required this.icon,
  });

  final Color background;
  final Color border;
  final Color iconBackground;
  final Color iconColor;
  final IconData icon;
}

