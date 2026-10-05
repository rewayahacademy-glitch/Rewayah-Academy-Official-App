import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/tc_classe/roster_classe_vm.dart';
import '../../core/tc_classe/teacher_student_projection.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/status_pill.dart';

/// Le mot qui nomme un etat projete.
///
/// **Toujours un mot** (invariant J7) : une pastille sans libelle ne dit rien a
/// qui ne distingue pas les couleurs, et rien du tout a qui ecoute l'ecran.
String libelleEtatProjete(EtatPresenceProjete etat) => switch (etat) {
  EtatPresenceProjete.inconnu => t.tc.classe.etat.inconnu,
  EtatPresenceProjete.attendu => t.tc.classe.etat.attendu,
  EtatPresenceProjete.enConnexion => t.tc.classe.etat.enConnexion,
  EtatPresenceProjete.present => t.tc.classe.etat.present,
  EtatPresenceProjete.enRetard => t.tc.classe.etat.enRetard,
  EtatPresenceProjete.deconnecte => t.tc.classe.etat.deconnecte,
  EtatPresenceProjete.enReconnexion => t.tc.classe.etat.enReconnexion,
  EtatPresenceProjete.sorti => t.tc.classe.etat.sorti,
  EtatPresenceProjete.absent => t.tc.classe.etat.absent,
};

/// La famille semantique d'un etat projete.
///
/// [EtatPresenceProjete.inconnu] est **neutre**, et ce n'est pas une
/// negligence : le peindre en alerte le ferait lire comme une absence, alors que
/// l'invariant J3 dit exactement l'inverse -- ne pas savoir n'est pas un fait.
/// Le mot « Etat inconnu » porte l'information ; la couleur ne doit pas la
/// contredire.
TonEtat tonEtatProjete(EtatPresenceProjete etat) => switch (etat) {
  EtatPresenceProjete.present => TonEtat.succes,
  EtatPresenceProjete.enConnexion => TonEtat.accent,
  EtatPresenceProjete.enRetard ||
  EtatPresenceProjete.enReconnexion => TonEtat.avertissement,
  EtatPresenceProjete.deconnecte || EtatPresenceProjete.absent => TonEtat.alerte,
  EtatPresenceProjete.attendu ||
  EtatPresenceProjete.sorti ||
  EtatPresenceProjete.inconnu => TonEtat.neutre,
};

/// Une ligne de roster : un eleve, son identifiant, son etat.
///
/// **Elle ne rend que des champs de [TeacherStudentProjection].** C'est
/// l'invariant de confidentialite du lot, et il se verifie d'un coup d'oeil sur
/// ce fichier : il n'y a aucun autre type d'eleve dans la classe.
///
/// L'identifiant d'academie est affiche **a cote** du prenom, et non a la place
/// d'un nom de famille absent : c'est lui qui desambiguise deux homonymes
/// (decision D-08), exactement comme le fait deja `journee_page.dart`.
class LigneRoster extends StatelessWidget {
  /// Cree une ligne.
  const LigneRoster({
    required this.eleve,
    super.key,
    this.recite = false,
    this.onOuvrirFiche,
  });

  /// L'eleve projete.
  final TeacherStudentProjection eleve;

  /// Vrai quand cet eleve a la parole.
  final bool recite;

  /// Ouvre la fiche pedagogique. Sans elle, la ligne n'est pas pressable.
  final VoidCallback? onOuvrirFiche;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;

    final Widget corps = MergeSemantics(
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  eleve.firstName,
                  overflow: TextOverflow.ellipsis,
                  style: textes.titleSmall ?? const TextStyle(),
                ),
                Text(
                  eleve.academyId,
                  overflow: TextOverflow.ellipsis,
                  style: textes.labelSmall ?? const TextStyle(),
                ),
              ],
            ),
          ),
          Ecart.hSm,
          // **Les pastilles passent a la ligne plutot que de deborder.** La
          // colonne de roster fait 256 points : deux pastilles cote a cote --
          // « Recite » et l'etat de presence -- depassaient de 102 points, et
          // c'est une mesure, pas une precaution.
          Flexible(
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: <Widget>[
                // La recitation se dit par un MOT, comme tout le reste : un
                // lisere ou un fond colore seul serait invisible a qui ecoute
                // l'ecran.
                if (recite)
                  StatusPill(
                    libelle: t.tc.classe.recitation.pastille,
                    ton: TonEtat.accent,
                  ),
                StatusPill(
                  libelle: libelleEtatProjete(eleve.liveStatus),
                  ton: tonEtatProjete(eleve.liveStatus),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onOuvrirFiche == null) {
      return corps;
    }
    return Pressable(
      onPress: onOuvrirFiche,
      libelleSemantique: t.tc.classe.roster.ouvrirFiche(
        prenom: eleve.firstName,
      ),
      child: corps,
    );
  }
}

/// Le roster, en colonne ou en feuille.
///
/// **Le meme corps dans les deux places.** Deux rendus d'une meme liste
/// finiraient par ne plus dire la meme chose -- c'est precisement ce que le lot
/// N3 a evite en refusant trois ecrans de salle.
class PanneauRoster extends StatelessWidget {
  /// Cree le panneau.
  const PanneauRoster({
    required this.roster,
    super.key,
    this.entete = false,
    this.onOuvrirFiche,
  });

  /// Le roster a montrer.
  final RosterClasseVM roster;

  /// L'en-tete de section, en colonne seulement : la feuille a deja son titre.
  final bool entete;

  /// Ouvre la fiche d'un eleve, par son identifiant d'academie.
  final void Function(String academyId)? onOuvrirFiche;

  @override
  Widget build(BuildContext context) {
    // **Indisponible n'est pas vide, et c'est l'invariant J3.** Une liste vide
    // dit « personne n'est inscrit » ; l'indisponibilite dit « je ne sais pas ».
    // Les confondre ferait croire a un enseignant que sa classe est deserte.
    if (!roster.disponible) {
      return _RosterVide(
        message: t.tc.classe.roster.indisponible,
        invitation: t.tc.classe.roster.indisponibleDetail,
      );
    }
    if (roster.eleves.isEmpty) {
      return _RosterVide(
        message: t.tc.classe.roster.vide,
        invitation: t.tc.classe.roster.videDetail,
      );
    }

    final void Function(String)? ouvrir = onOuvrirFiche;

    return ListView(
      shrinkWrap: true,
      children: <Widget>[
        if (entete) ...<Widget>[
          SectionHeader(
            titre: t.tc.classe.roster.titre,
            compteur: roster.eleves.length,
          ),
          // **Le plafond vient du serveur, jamais d'une constante.** Il vaut 5
          // pour un groupe d'enfants et 6 pour un groupe d'adultes, et un
          // administrateur peut le changer : ecrire « 5 » ici en poserait un
          // second, et deux plafonds finissent par ne plus dire la meme chose.
          if (roster.seuilMax case final int plafond)
            Text(
              t.tc.classe.roster.places(
                inscrits: roster.attendus,
                plafond: plafond,
              ),
              style: Theme.of(context).textTheme.labelSmall ??
                  const TextStyle(),
            ),
          Ecart.vMd,
        ],
        for (final TeacherStudentProjection eleve in roster.eleves) ...<Widget>[
          LigneRoster(
            key: ValueKey<String>(eleve.academyId),
            eleve: eleve,
            recite: roster.file.actif == eleve.academyId,
            onOuvrirFiche: ouvrir == null
                ? null
                : () => ouvrir(eleve.academyId),
          ),
          Ecart.vMd,
        ],
      ],
    );
  }
}

/// Un roster sans ligne : indisponible, ou reellement vide.
///
/// **Il defile**, et ce n'est pas un detail : `EmptyState` pose une icone de
/// 64 points, un titre et une invitation, et la colonne de roster ne fait que
/// 256 points de large. Sur une tablette en paysage, l'invitation passe a
/// quatre lignes et le bloc depasse la hauteur offerte -- **mesure**, pas
/// suppose : `RenderFlex overflowed by 64 pixels`. Le defilement rend la place
/// au texte au lieu de le rogner.
class _RosterVide extends StatelessWidget {
  const _RosterVide({required this.message, required this.invitation});

  final String message;
  final String invitation;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: EmptyState(
      message: message,
      invitation: invitation,
      registre: RegistreVide.subi,
    ),
  );
}

/// Le bouton compact qui ouvre le roster replie, « 4/4 ».
///
/// Il n'existe **que la ou le roster est replie** : a cote d'une colonne qui
/// montre les cinq lignes, il ferait doublon, et un doublon finit par diverger.
/// La decision est prise par `VueClasseLive`, pas ici.
class BoutonRoster extends StatelessWidget {
  /// Cree le bouton.
  const BoutonRoster({
    required this.compteur,
    required this.presents,
    required this.attendus,
    required this.onOuvrir,
    super.key,
  });

  /// Le compteur deja compose, par exemple « 4/4 ».
  final String compteur;

  /// Combien sont en salle, pour le libelle parle.
  final int presents;

  /// Combien sont attendus, pour le libelle parle.
  final int attendus;

  /// Ouvre la feuille de roster.
  final VoidCallback onOuvrir;

  @override
  Widget build(BuildContext context) {
    // **Un chiffre visible, une phrase parlee.** « 4/4 » tient dans un en-tete
    // de telephone ; « Eleves : 4 presents sur 4 attendus » est ce qu'un lecteur
    // d'ecran doit annoncer. Le premier sans le second serait illisible.
    return LienFleche(
      libelle: compteur,
      libelleSemantique: t.tc.classe.roster.compteur(
        presents: presents,
        attendus: attendus,
      ),
      onPress: onOuvrir,
      fleche: false,
    );
  }
}
