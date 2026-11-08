import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../widgets/action_principale.dart';
import '../widgets/lien_fleche.dart';
import 'invitation_push.dart';

/// La fenetre de premiere connexion (NOTIF-DEFAUT) : « Recevoir les
/// notifications ? », « Activer » (le geste qui ouvre la demande du systeme),
/// « Plus tard ». Rien tant qu'il n'y a rien a demander.
class BandeauInvitationPush extends ConsumerWidget {
  /// Cree la fenetre.
  const BandeauInvitationPush({super.key});

  /// La cle du bouton « Activer », pour les tests.
  static const ValueKey<String> cleActiver = ValueKey<String>(
    'invitation-push-activer',
  );

  /// La cle du lien « Plus tard », pour les tests.
  static const ValueKey<String> clePlusTard = ValueKey<String>(
    'invitation-push-plus-tard',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(veilleInvitationPushProvider);
    final EtatInvitationPush etat = ref.watch(invitationPushProvider);
    if (!etat.visible) return const SizedBox.shrink();
    final InvitationPush invitation = ref.read(invitationPushProvider.notifier);
    final AppPalette palette = AppPalette.of(context);
    final AppColorPair paire = palette.washWarning;
    final TextTheme textes = Theme.of(context).textTheme;
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: paire.background,
          border: Border(bottom: palette.borderStrong.asBorderSide()),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  IconTheme(
                    data: IconThemeData(
                      color: paire.onBackground,
                      size: AppSpacing.xl,
                    ),
                    child: Icon(AppIcons.notifications.repos),
                  ),
                  Ecart.hSm,
                  Expanded(
                    child: Text(
                      t.push1.invitation.titre,
                      style: paire.applyTo(
                        textes.titleSmall ?? const TextStyle(),
                      ),
                    ),
                  ),
                ],
              ),
              Ecart.vXs,
              Text(
                t.push1.invitation.phrase,
                style: paire.applyTo(textes.bodySmall ?? const TextStyle()),
              ),
              Ecart.vMd,
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.sm,
                  children: <Widget>[
                    LienFleche(
                      key: clePlusTard,
                      libelle: t.push1.invitation.plusTard,
                      fleche: false,
                      encre: paire.applyTo,
                      onPress: invitation.plusTard,
                    ),
                    ActionPrincipale(
                      key: cleActiver,
                      libelle: t.push1.invitation.activer,
                      pleineLargeur: false,
                      compacte: true,
                      enCours: etat.enCours,
                      onPress: invitation.activer,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
