import 'package:flutter/material.dart';

import '../icons/app_icons.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'pressable.dart';

/// A grouped settings line. It contains presentation only: no profile write,
/// provider, or navigation contract is coupled to this primitive.
class SettingRow extends StatelessWidget {
  const SettingRow({
    required this.title,
    required this.icon,
    super.key,
    this.description,
    this.value,
    this.controle,
    this.onPress,
    this.enabled = true,
  });

  final String title;
  final String? description;
  final String? value;

  /// Controle natif place en fin de ligne, sans enveloppe interactive.
  ///
  /// Un [Switch] ou un [Radio] conserve ainsi sa gestion de focus et de geste.
  final Widget? controle;
  final AppIcon icon;
  final VoidCallback? onPress;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final active = enabled && onPress != null;
    return Pressable.selon(
      onPress: active ? onPress : null,
      actif: enabled,
      libelleSemantique: title,
      respecterCibleTactile: false,
      arrondiFocus: AppRadius.arrondiMd,
      constructeur: (context, etat) => Container(
        constraints: const BoxConstraints(minHeight: AppPage.hauteurReglage),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: etat.survole || etat.presse
              ? Color.alphaBlend(
                  palette.calqueInteraction(presse: etat.presse),
                  palette.surfaceRaised.background,
                )
              : palette.surfaceRaised.background,
          borderRadius: AppRadius.arrondiMd,
          border: Border(bottom: palette.contourCarte.asBorderSide()),
        ),
        child: Row(
          children: <Widget>[
            IconTheme(
              data: palette.inkMuted.asIconTheme(size: AppSpacing.xxl),
              child: Icon(icon.repos),
            ),
            Ecart.hMd,
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  if (description != null) ...<Widget>[
                    Ecart.vXs,
                    Text(
                      description!,
                      style: palette.inkMuted.applyTo(
                        Theme.of(context).textTheme.bodyMedium ??
                            const TextStyle(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (value != null) ...<Widget>[
              Ecart.hMd,
              Flexible(
                child: Text(
                  value!,
                  textAlign: TextAlign.end,
                  style: palette.inkMuted.applyTo(
                    Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
                  ),
                ),
              ),
            ],
            if (controle != null) ...<Widget>[Ecart.hSm, controle!],
            if (onPress != null) ...<Widget>[
              Ecart.hSm,
              IconTheme(
                data: palette.inkMuted.asIconTheme(size: AppSpacing.xl),
                child: Icon(AppIcons.chevron.repos),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
