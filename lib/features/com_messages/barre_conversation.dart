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

import '../../core/accessibilite/texte_agrandi.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/mouvement/mouvement.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/avatar_nom.dart';
import '../../core/widgets/bouton_icone.dart';
import '../../core/widgets/espace_travail_adaptatif.dart';
import '../../core/widgets/raccourci_tactile.dart';
import 'avatar_participant.dart';
import 'entete_fil_contexte.dart';
import 'port_messages_metier.dart';

/// La barre compacte d'une conversation ouverte.
class BarreConversation extends StatelessWidget {
  /// Cree la barre du fil [fil]. [onRetour] : le retour vers la liste, ou
  /// `null` (ordinateur : la liste est deja a cote).
  const BarreConversation({
    required FilMetier this.fil,
    super.key,
    this.onRetour,
    this.replie = false,
    this.libelleRetour,
    this.iconeRetour,
    this.onOuvrirMessages,
    this.onFermer,
  }) : titre = null,
       ligne = null;

  /// La barre d'une conversation qui n'est pas un fil de Messages (les
  /// echanges du controleur sur une mission, le canal du Studio) : le meme
  /// geste, la meme hauteur, le retour, un titre et une ligne fine dessous,
  /// sans personne a montrer (CONVERSATIONS-PARTOUT, 16/11/2026).
  const BarreConversation.libre({
    required String this.titre,
    super.key,
    this.ligne,
    this.onRetour,
    this.replie = false,
    this.libelleRetour,
    this.iconeRetour,
  }) : fil = null,
       onOuvrirMessages = null,
       onFermer = null;

  /// Le fil ouvert, ou `null` pour la barre libre.
  final FilMetier? fil;

  /// Barre libre : le titre, et la ligne fine dessous.
  final String? titre;
  final String? ligne;

  /// Le retour vers la liste des conversations.
  final VoidCallback? onRetour;

  /// CONVERSATIONS-PARTOUT : le mot du retour quand ce n'est pas « Retour a la
  /// liste » (« Replier la conversation » dans un dossier) ; `null` : celui de
  /// la liste.
  final String? libelleRetour;

  /// L'icone du retour ; `null` : la fleche de retour.
  final AppIcon? iconeRetour;

  /// « Ouvrir dans Messages », en bouton d'icone au bout de la barre, quand la
  /// conversation vit dans une autre page (le dossier d'un candidat) ; `null` :
  /// aucun.
  final VoidCallback? onOuvrirMessages;

  /// MESSAGERIE-COULEURS (pilote, 16/11/2026, regression de #540 : « la croix a
  /// disparu ») : la conversation vit dans un VOLET de cote (ordinateur) ; sa
  /// croix « Fermer la conversation » se pose au bord de FIN de la barre, apres
  /// les autres boutons d'icone, en LTR comme en RTL. Elle remplace le retour
  /// du bord de debut (qui reste la fleche de la page plein ecran). `null` :
  /// aucune croix.
  final VoidCallback? onFermer;

  /// Vrai quand la barre se replie : on remonte vers les anciens messages.
  final bool replie;

  /// La hauteur de la barre.
  static const double hauteur = 56;

  /// La hauteur de la barre minimale, clavier ouvert : retour et nom.
  static const double hauteurMinimale = 48;

  /// La cle du bouton « Ouvrir dans Messages », pour les tests.
  static const ValueKey<String> cleOuvrirMessages = ValueKey<String>(
    'barre-conversation-messages',
  );

  /// La cle de la barre, pour les tests.
  static const ValueKey<String> cle = ValueKey<String>('barre-conversation');

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final x = t.com.socle.composants.espace;
    final FilMetier? f = fil;
    final List<Participant> gens = f?.interlocuteurs ?? const <Participant>[];
    final String objets = f == null
        ? ''
        : libelleObjets(<ObjetLie>[
            for (final ElementContexteFil e in f.contexte) e.objet,
          ]);
    final String noms = f == null ? titre! : titreFil(gens, objets);
    // Le nom seul en titre ; le role (fonction, ou objets du fil) sur UNE
    // ligne fine, coupee par une ellipse : la phrase entiere est lue (barre)
    // et ecrite dans le dossier (i).
    final String nomCourt = f == null
        ? titre!
        : gens.length == 1
        ? gens.single.nomMarque
        : noms;
    final String role = gens.length == 1 ? (gens.single.fonction ?? '') : '';
    final String ligneRole = f == null
        ? (ligne ?? '')
        : role.isNotEmpty
        ? role
        : objets;
    final String prenom = f == null
        ? titre!
        : gens.isEmpty
        ? objets
        : gens.first.nomAffiche;
    final VoidCallback? ouvrirContexte =
        EspaceTravailAdaptatif.ouvrirContexteDe(context);
    final VoidCallback? retour = onRetour;
    // Clavier ouvert : seule une barre minimale (retour et nom) reste, pour
    // ne laisser que le fil et le champ.
    // Lu sur la vue : le `Scaffold` retire le clavier de la `MediaQuery`.
    final bool clavier = View.of(context).viewInsets.bottom > 0;
    final bool minimale = clavier;
    final Widget barre = DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: palette.borderHairline.asBorderSide()),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: minimale ? hauteurMinimale : hauteur,
        ),
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
                  icone: iconeRetour ?? AppIcons.retour,
                  libelle: libelleRetour ?? x.retourListe,
                  infobulle: libelleRetour ?? x.retourListe,
                  onPress: retour,
                  forme: FormeBoutonIcone.nue,
                )
              else
                Ecart.hSm,
              Expanded(
                child: ExcludeSemantics(
                  child: _raccourci(
                    ouvrirContexte,
                    AvatarNom.enLigne(
                      prenom: prenom,
                      nom: nomCourt.replaceAll('-', '‑'),
                      roleWidget:
                          minimale ||
                              ligneRole.isEmpty ||
                              (f != null && gens.isEmpty)
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
                        participant: gens.isEmpty ? null : gens.first,
                        repli: prenom,
                        diametre: AppAvatar.moyen,
                      ),
                      diametre: AppAvatar.moyen,
                      styleNom: palette.inkStrong.applyTo(
                        textes.titleSmall ?? const TextStyle(),
                      ),
                    ),
                  ),
                ),
              ),
              if (onOuvrirMessages != null && !minimale)
                BoutonIcone(
                  key: cleOuvrirMessages,
                  icone: AppIcons.lienExterne,
                  libelle: t.com.messages.entree.ouvrirDansMessages,
                  infobulle: t.com.messages.entree.ouvrirDansMessages,
                  onPress: onOuvrirMessages!,
                  forme: FormeBoutonIcone.nue,
                ),
              if (ouvrirContexte != null && !minimale)
                BoutonIcone(
                  key: EspaceTravailAdaptatif.cleOuvrirContexte,
                  icone: AppIcons.info,
                  libelle: x.ouvrirPanneau,
                  infobulle: x.ouvrirPanneau,
                  onPress: ouvrirContexte,
                  forme: FormeBoutonIcone.nue,
                )
              else
                Ecart.hSm,
              // La croix du volet : dernier controle de la barre, au bord de
              // fin, toujours atteignable (la barre d'un volet ne se replie
              // jamais). Meme cle que le retour de la page Messages.
              if (onFermer != null) ...<Widget>[
                BoutonIcone(
                  key: EspaceTravailAdaptatif.cleRetourListe,
                  icone: AppIcons.fermer,
                  libelle: t.com.messages.entree.fermer,
                  infobulle: t.com.messages.entree.fermer,
                  onPress: onFermer!,
                  forme: FormeBoutonIcone.nue,
                ),
                Ecart.hSm,
              ],
            ],
          ),
        ),
      ),
    );
    // Repliee (on lit les anciens messages) : la barre se range, et revient
    // des qu'on redescend.
    return ClipRect(
      child: AnimatedAlign(
        alignment: AlignmentDirectional.topStart,
        heightFactor: replie ? 0 : 1,
        duration: Mouvement.duree(context, Mouvement.moyen),
        curve: Mouvement.entree,
        // Une barre qui ne grandit pas au-dela de 150 % : a texte double, elle
        // prenait le quart de l'ecran a 320. Le nom entier reste lu (semantique).
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: SeuilsTexteAgrandi.echelle,
          child: barre,
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
  const BarreRetourConversation({
    super.key,
    this.onRetour,
    this.libelle,
    this.onFermer,
  });

  /// La conversation vit dans un volet : une croix « Fermer la conversation »
  /// au bord de fin, au lieu de la fleche de retour du bord de debut.
  final VoidCallback? onFermer;

  /// Le retour vers la liste.
  final VoidCallback? onRetour;

  /// Le mot du retour quand ce n'est pas « Retour a la liste ».
  final String? libelle;

  @override
  Widget build(BuildContext context) {
    final x = t.com.socle.composants.espace;
    final VoidCallback? retour = onRetour;
    final VoidCallback? fermer = onFermer;
    if (fermer != null) {
      return ConstrainedBox(
        constraints: const BoxConstraints(minHeight: BarreConversation.hauteur),
        child: Align(
          alignment: AlignmentDirectional.centerEnd,
          child: BoutonIcone(
            key: EspaceTravailAdaptatif.cleRetourListe,
            icone: AppIcons.fermer,
            libelle: t.com.messages.entree.fermer,
            infobulle: t.com.messages.entree.fermer,
            onPress: fermer,
            forme: FormeBoutonIcone.nue,
          ),
        ),
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: BarreConversation.hauteur),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: retour == null
            ? const SizedBox.shrink()
            : BoutonIcone(
                key: EspaceTravailAdaptatif.cleRetourListe,
                icone: AppIcons.retour,
                libelle: libelle ?? x.retourListe,
                infobulle: libelle ?? x.retourListe,
                onPress: retour,
                forme: FormeBoutonIcone.nue,
              ),
      ),
    );
  }
}

/// Apercu du profil : toucher la photo ou le nom ouvre le contexte, le meme
/// geste que (i), qui reste le controle lu et atteint au clavier.
Widget _raccourci(VoidCallback? ouvrir, Widget identite) => ouvrir == null
    ? identite
    : RaccourciTactile(
        key: EnteteFilContexte.cleRaccourci,
        onPress: ouvrir,
        child: identite,
      );
