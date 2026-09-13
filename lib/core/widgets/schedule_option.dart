import 'package:flutter/material.dart';

import '../icons/app_icons.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'pressable.dart';

/// Presentation-only administrative schedule proposal.
///
/// It deliberately has no free date/time inputs and no reservation action.
/// A caller owns the selected value and may only offer backend-provided slots.
class ScheduleOption extends StatelessWidget {
  const ScheduleOption({
    required this.day,
    required this.hours,
    required this.onSelected,
    super.key,
    this.timeZone,
    this.recurrence,
    this.selected = false,
    this.enabled = true,
  });

  final String day;
  final String hours;
  final String? timeZone;
  final String? recurrence;
  final VoidCallback? onSelected;
  final bool selected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Semantics(
      selected: selected,
      button: true,
      child: Pressable.selon(
        onPress: enabled ? onSelected : null,
        actif: enabled,
        libelleSemantique: '$day, $hours',
        respecterCibleTactile: false,
        arrondiFocus: AppRadius.arrondiMd,
        constructeur: (context, etat) {
          final surface = selected ? palette.washAccent : palette.surfaceRaised;
          return Container(
            constraints: const BoxConstraints(minHeight: AppPage.hauteurChoix),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: etat.survole || etat.presse
                  ? Color.alphaBlend(
                      palette.calqueInteraction(presse: etat.presse),
                      surface.background,
                    )
                  : surface.background,
              borderRadius: AppRadius.arrondiMd,
              border: Border.fromBorderSide(
                selected
                    ? palette.inkAccent.asBorderSide(width: 2)
                    : palette.contourCarte.asBorderSide(),
              ),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(day, style: Theme.of(context).textTheme.titleMedium),
                      Ecart.vXs,
                      Text(
                        hours,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (timeZone != null) ...<Widget>[
                        Ecart.vXs,
                        Text(
                          timeZone!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                      if (recurrence != null) ...<Widget>[
                        Ecart.vXs,
                        Text(
                          recurrence!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
                if (selected)
                  IconTheme(
                    data: IconThemeData(
                      color: surface.onBackground,
                      size: AppSpacing.xxl,
                    ),
                    child: Icon(AppIcons.succes.actif),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
