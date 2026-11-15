// La barre d'une conversation ouverte (MESSAGERIE-PLEIN-ECRAN, directeur,
// 15/11/2026).
//
// Une seule barre compacte d'environ 56 points : le retour, un petit avatar,
// le nom, le role sur une ligne fine, et (i) qui ouvre le dossier ou la fiche
// (panneau a droite sur ordinateur, feuille ailleurs : le meme geste que le
// reste des Messages, `EspaceTravailAdaptatif`). Ni titre de page, ni
// onglets, ni cloche : la conversation est une page a elle. Composants du
// core seulement (`BoutonIcone`, `AvatarNom`), jetons seuls, aucun mot
// nouveau (`t.com.socle.composants.espace`).

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/avatar_nom.dart';
import '../../core/widgets/bouton_icone.dart';
import '../../core/widgets/espace_travail_adaptatif.dart';
import 'avatar_participant.dart';
import 'entete_fil_contexte.dart';
import 'port_messages_metier.dart';

/// La barre compacte d'une conversation ouverte.
class BarreConversation extends StatelessWidget {
  /// Cree la barre du fil [fil]. [onRetour] : le retour vers la liste, ou
  /// `null` (ordinateur : la liste est deja a cote).
  const BarreConversation({required this.fil, super.key, this.onRetour});

  /// Le fil ouvert.
  final FilMetier fil;

  /// Le retour vers la liste des conversations.
  final VoidCallback? onRetour;

  /// La hauteur de la barre.
  static const double hauteur = 56;

  /// La cle de la barre, pour les tests.
  static const ValueKey<String> cle = ValueKey<String>('barre-conversation');

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final x = t.com.socle.composants.espace;
    final String objets = libelleObjets(<ObjetLie>[
      for (final ElementContexteFil e in fil.contexte) e.objet,
    ]);
    final String noms = titreFil(fil.interlocuteurs, objets);
    // Le nom seul en titre ; le role (fonction, ou objets du fil) sur UNE
    // ligne fine, coupee par une ellipse : la phrase entiere est lue (barre)
    // et ecrite dans le dossier (i).
    final String nomCourt = fil.interlocuteurs.length == 1
        ? fil.interlocuteurs.single.nomAffiche
        : noms;
    final String role = fil.interlocuteurs.length == 1
        ? (fil.interlocuteurs.single.fonction ?? '')
        : '';
    final String ligneRole = role.isNotEmpty ? role : objets;
    final String prenom = fil.interlocuteurs.isEmpty
        ? objets
        : fil.interlocuteurs.first.nomAffiche;
    final VoidCallback? ouvrirContexte =
        EspaceTravailAdaptatif.ouvrirContexteDe(context);
    final VoidCallback? retour = onRetour;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: palette.borderHairline.asBorderSide()),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: hauteur),
        child: Semantics(
          key: cle,
          container: true,
          header: true,
          label: noms,
          child: Row(
            children: <Widget>[
              if (retour != null)
                BoutonIcone(
                  key: EspaceTravailAdaptatif.cleRetourListe,
                  icone: AppIcons.retour,
                  libelle: x.retourListe,
                  infobulle: x.retourListe,
                  onPress: retour,
                )
              else
                Ecart.hSm,
              Expanded(
                child: ExcludeSemantics(
                  child: AvatarNom.enLigne(
                    prenom: prenom,
                    nom: nomCourt.replaceAll('-', '‑'),
                    roleWidget: ligneRole.isEmpty || fil.interlocuteurs.isEmpty
                        ? null
                        : Text(
                            ligneRole,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: palette.inkMuted.applyTo(
                              textes.bodySmall ?? const TextStyle(),
                            ),
                          ),
                    avatar: AvatarParticipant(
                      participant: fil.interlocuteurs.isEmpty
                          ? null
                          : fil.interlocuteurs.first,
                      repli: prenom,
                      diametre: AppAvatar.petit,
                    ),
                    diametre: AppAvatar.petit,
                    styleNom: palette.inkStrong.applyTo(
                      textes.titleSmall ?? const TextStyle(),
                    ),
                  ),
                ),
              ),
              if (ouvrirContexte != null)
                BoutonIcone(
                  key: EspaceTravailAdaptatif.cleOuvrirContexte,
                  icone: AppIcons.info,
                  libelle: x.ouvrirPanneau,
                  infobulle: x.ouvrirPanneau,
                  onPress: ouvrirContexte,
                )
              else
                Ecart.hSm,
            ],
          ),
        ),
      ),
    );
  }
}

/// La barre d'une conversation qui n'a pas de fil a montrer (chargement,
/// erreur, fil inaccessible) : le retour seul, pour ne jamais enfermer la
/// personne sur une page sans sortie.
class BarreRetourConversation extends StatelessWidget {
  /// Cree la barre.
  const BarreRetourConversation({super.key, this.onRetour});

  /// Le retour vers la liste.
  final VoidCallback? onRetour;

  @override
  Widget build(BuildContext context) {
    final x = t.com.socle.composants.espace;
    final VoidCallback? retour = onRetour;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: BarreConversation.hauteur),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: retour == null
            ? const SizedBox.shrink()
            : BoutonIcone(
                key: EspaceTravailAdaptatif.cleRetourListe,
                icone: AppIcons.retour,
                libelle: x.retourListe,
                infobulle: x.retourListe,
                onPress: retour,
              ),
      ),
    );
  }
}
