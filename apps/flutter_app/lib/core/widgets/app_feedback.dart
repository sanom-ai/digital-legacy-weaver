import 'package:digital_legacy_weaver/core/widgets/app_state_panel.dart';
import 'package:flutter/material.dart';

enum AppFeedbackTone {
  info,
  success,
  warning,
  error,
  offline,
}

class AppFeedback {
  const AppFeedback._();

  static void showInfo(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      tone: AppFeedbackTone.info,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void showSuccess(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      tone: AppFeedbackTone.success,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void showWarning(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      tone: AppFeedbackTone.warning,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final tone = appStateLooksOfflineMessage(message)
        ? AppFeedbackTone.offline
        : AppFeedbackTone.error;
    show(
      context,
      message: message,
      tone: tone,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void show(
    BuildContext context, {
    required String message,
    AppFeedbackTone tone = AppFeedbackTone.info,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    final style = _styleForTone(tone);

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: style.background,
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: style.actionColor,
                onPressed: onAction,
              )
            : null,
        content: Text(
          '${_tonePrefix(tone)}$message',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  static String _tonePrefix(AppFeedbackTone tone) {
    return '';
  }

  static Future<bool> confirmAction({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'ยืนยัน',
    String cancelLabel = 'ยกเลิก',
    bool destructive = false,
    IconData? icon,
  }) async {
    final scheme = Theme.of(context).colorScheme;
    final iconColor = destructive ? scheme.error : scheme.primary;
    final iconBackground =
        (destructive ? scheme.errorContainer : scheme.primaryContainer)
            .withValues(alpha: 0.6);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          titlePadding: const EdgeInsets.fromLTRB(22, 18, 22, 10),
          contentPadding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
          actionsPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon ??
                      (destructive
                          ? Icons.delete_outline_rounded
                          : Icons.help_outline_rounded),
                  size: 19,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(title)),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(cancelLabel),
            ),
            FilledButton(
              style: destructive
                  ? FilledButton.styleFrom(
                      backgroundColor: scheme.error,
                      foregroundColor: scheme.onError,
                    )
                  : null,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );

    return confirmed == true;
  }

  static _SnackStyle _styleForTone(AppFeedbackTone tone) {
    switch (tone) {
      case AppFeedbackTone.success:
        return const _SnackStyle(
          background: Color(0xFF1D3A2C),
          actionColor: Color(0xFFE4F8EC),
        );
      case AppFeedbackTone.warning:
        return const _SnackStyle(
          background: Color(0xFF4A3212),
          actionColor: Color(0xFFFFE9C1),
        );
      case AppFeedbackTone.error:
        return const _SnackStyle(
          background: Color(0xFF4A2125),
          actionColor: Color(0xFFFFE0E3),
        );
      case AppFeedbackTone.offline:
        return const _SnackStyle(
          background: Color(0xFF2D2E43),
          actionColor: Color(0xFFE4E9FF),
        );
      case AppFeedbackTone.info:
        return const _SnackStyle(
          background: Color(0xFF2F241C),
          actionColor: Color(0xFFFFE7D4),
        );
    }
  }
}

class _SnackStyle {
  const _SnackStyle({
    required this.background,
    required this.actionColor,
  });

  final Color background;
  final Color actionColor;
}
