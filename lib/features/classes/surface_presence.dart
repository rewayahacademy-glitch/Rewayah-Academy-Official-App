import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/presence/service_presence.dart';
import '../../core/presence/vue_presence.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/ligne_presence.dart';

/// La presence d'une seance, telle que le serveur la rend.
///
/// **Aucun calcul de presence ici.** Chaque ligne porte l'etat derive par
/// `etat_presence()` a partir des evenements LiveKit verifies ; l'ecran le
/// nomme et le date, il ne le decide pas. Un timer Flutter n'est jamais une
/// preuve : `maintenant` ne sert qu'a dire « depuis 12 min », jamais a
/// basculer un etat.
///
/// Une presence indisponible s'affiche indisponible, **jamais absente**
/// (invariant J3) : ne pas savoir ne compte pour rien.
class SurfacePresence extends StatelessWidget {
  /// Cree la surface.
  const SurfacePresence({
    required this.lignes,
    required this.maintenant,
    super.key,
    this.monProfilId,
  });

  /// Les lignes rendues par le serveur. `null` : indisponible.
  final List<PresenceParticipant>? lignes;

  /// L'instant de reference pour dater, jamais pour decider.
  final DateTime maintenant;

  /// Le profil de la personne qui regarde, pour dire « Votre presence ».
  final String? monProfilId;

  @override
  Widget build(BuildContext context) {
    final List<PresenceParticipant>? source = lignes;
    if (source == null) {
      return EmptyState(
        message: t.classes.presence.indisponible,
        invitation: t.classes.presence.indisponibleDetail,
        icone: AppIcons.rienAAfficher,
        registre: RegistreVide.subi,
      );
    }
    if (source.isEmpty) {
      return EmptyState(
        message: t.admin.groupes.detailAucunMembre,
        icone: AppIcons.rienAAfficher,
        registre: RegistreVide.subi,
      );
    }

    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final PresenceParticipant ligne in tableauDePresence(source))
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: LignePresence(
              nom: ligne.profilId == monProfilId
                  ? t.presence.mienne
                  : ligne.prenom.isEmpty
                  ? ligne.identifiantImmuable
                  : ligne.prenom,
              vue: VuePresence.depuis(ligne: ligne, maintenant: maintenant),
              role: ligne.estEnseignant ? t.admin.comptes.roleEnseignant : null,
            ),
          ),
        Text(
          t.classes.presence.source,
          style: palette.inkMuted.applyTo(
            textes.bodySmall ?? const TextStyle(),
          ),
        ),
      ],
    );
  }
}
