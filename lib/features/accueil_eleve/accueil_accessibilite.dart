// MA-3 : l'Accueil de l'eleve en Mode Accessibilite (doc 06 §5, MA18,
// planches 1 et 3 rectifiees).
//
// Dans l'ordre : une salutation d'une ligne, « Prochaine seance » (la carte
// de seance CL-4 et son emplacement d'entree unique, R4), un seul bouton
// contextuel, « Avant le prochain cours » (3 au plus), « Lire le Coran »,
// « Besoin d'aide ? » en dernier (MA14). Retires : cloche, decor, pastille
// « Aujourd'hui », age, statistiques, phrase de promesse. Aucune couleur
// nouvelle (K-37), aucun appel serveur (K-28).

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/tc_groupe/group_home_vm.dart';
import '../../core/tc_groupe/group_summary_vm.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/avatar_nom.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/section_header.dart';
import '../tc_espace_groupe/carte_session.dart';
import '../tc_espace_groupe/emplacements_groupe.dart';
import '../tc_mes_groupes/photo_enseignant.dart';

/// Largeur utile, divisee par le facteur de texte, a partir de laquelle
/// l'Accueil passe en deux colonnes (K-42 point 6, MA15).
const double seuilDeuxColonnesAccueil = 840;

/// L'Accueil de l'eleve en Mode Accessibilite.
///
/// Le seul bouton dominant est celui de la carte de seance : « Rejoindre »
/// quand l'emplacement d'entree en est un, sinon « Voir ma classe » sous la
/// ligne d'etat (jamais les deux, R4). Tout le reste est une ligne d'une
/// seule cible.
class AccueilAccessibilite extends StatelessWidget {
  /// Cree l'Accueil.
  const AccueilAccessibilite({
    required this.prenom,
    required this.espace,
    required this.onVoirClasse,
    required this.onCoran,
    required this.onAide,
    required this.tutoiement,
    super.key,
    this.onRejoindre,
    this.onTache,
  });

  /// Le prenom de l'eleve, jamais son age.
  final String prenom;

  /// La Classe et sa prochaine seance, avec au plus trois actions.
  final GroupHomeVM espace;

  /// Vrai pour l'eleve mineur : l'Accueil le tutoie (« Ton heure ») ; un
  /// adulte est vouvoye (MA4). Suit l'age legal, jamais la presentation.
  final bool tutoiement;

  /// « Voir ma classe » : le bouton quand on ne peut pas encore entrer.
  final VoidCallback onVoirClasse;

  /// « Rejoindre », porte par l'emplacement d'entree.
  final VoidCallback? onRejoindre;

  /// Une ligne de « Avant le prochain cours ».
  final VoidCallback? onTache;

  /// « Lire le Coran ».
  final VoidCallback onCoran;

  /// « Besoin d'aide ? ».
  final VoidCallback onAide;

  /// Cle du bouton « Voir ma classe ».
  static const Key cleVoirClasse = ValueKey<String>('ma3-voir-classe');

  /// Cle de la mise en deux colonnes.
  static const Key cleDeuxColonnes = ValueKey<String>('ma3-deux-colonnes');

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final bool mobile = AppGabarit.de(context) == Gabarit.mobile;
    final double facteur = MediaQuery.textScalerOf(context).scale(1);

    final Widget salutation = Semantics(
      header: true,
      child: Text(
        t.accessibilite.accueil.salutation(prenom: prenom),
        style: palette.inkStrong.applyTo(
          textes.headlineSmall ?? const TextStyle(),
        ),
      ),
    );

    final Widget voirClasse = ActionPrincipale(
      key: cleVoirClasse,
      libelle: t.accessibilite.accueil.voirMaClasse,
      onPress: onVoirClasse,
      fleche: true,
      pleineLargeur: mobile,
    );

    final Widget seance = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SectionHeader(titre: t.accessibilite.accueil.prochaineSeance),
        Ecart.vMd,
        CarteSession(
          espace: espace,
          onRejoindre: onRejoindre,
          tutoiement: tutoiement,
          identite: _IdentiteClasse(identite: espace.identite),
          actionHorsEntree: mobile
              ? voirClasse
              : Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[voirClasse],
                ),
        ),
      ],
    );

    final Widget taches = _Taches(espace: espace, onTache: onTache);

    final Widget coranEtAide = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        GroupeReglages(
          lignes: <LigneRubrique>[
            LigneRubrique(
              libelle: t.accessibilite.accueil.lireCoran,
              legende: t.accessibilite.accueil.lireCoranDetail,
              icone: AppIcons.coran,
              onPress: onCoran,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        // L'aide, dernier bloc du contenu sur chaque ecran eleve (MA14).
        GroupeReglages(
          lignes: <LigneRubrique>[
            LigneRubrique(
              libelle: t.accessibilite.accueil.aide,
              icone: AppIcons.info,
              onPress: onAide,
            ),
          ],
        ),
      ],
    );

    return PageShell(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints contraintes) {
          final bool deuxColonnes =
              contraintes.maxWidth / facteur >= seuilDeuxColonnesAccueil;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              salutation,
              const SizedBox(height: AppSpacing.xxxl),
              seance,
              const SizedBox(height: AppSpacing.section),
              if (deuxColonnes)
                // Par rangee : le focus suit la lecture (tâches, puis Coran
                // et aide).
                Row(
                  key: cleDeuxColonnes,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(child: taches),
                    const SizedBox(width: AppSpacing.xxl),
                    Expanded(child: coranEtAide),
                  ],
                )
              else ...<Widget>[
                taches,
                const SizedBox(height: AppSpacing.section),
                coranEtAide,
              ],
            ],
          );
        },
      ),
    );
  }
}

/// La Classe, son enseignant et sa photo, au-dessus des heures.
class _IdentiteClasse extends StatelessWidget {
  const _IdentiteClasse({required this.identite});

  final GroupSummaryVM identite;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    // AVATAR-1 : le nom de la Classe est le titre ; l'enseignant est un couple
    // avatar + nom du composant partage, centre verticalement sur le cercle.
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            identite.libelle,
            style: palette.inkStrong.applyTo(
              textes.titleMedium ?? const TextStyle(),
            ),
          ),
          Ecart.vSm,
          AvatarNom.enLigne(
            prenom: identite.enseignant.nomAffichage,
            nom: t.accessibilite.accueil.avec(
              nomme: LibellesGroupe.enseignantNomme(identite.enseignant),
            ),
            ecart: AppSpacing.lg,
            styleNom: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
            avatar: PhotoEnseignant(
              enseignant: identite.enseignant,
              diametre: AppAvatar.moyen,
              // Un eleve ne voit jamais d'avertissement pour une photo
              // manquante : les initiales en repli (MA-3).
              repliInitiales: true,
            ),
          ),
        ],
      ),
    );
  }
}

/// « Avant le prochain cours » : trois lignes au plus, chacune une cible.
class _Taches extends StatelessWidget {
  const _Taches({required this.espace, required this.onTache});

  final GroupHomeVM espace;
  final VoidCallback? onTache;

  @override
  Widget build(BuildContext context) {
    if (espace.avantProchainCours.isEmpty) {
      return EmplacementAvantProchainCours(
        actions: espace.avantProchainCours,
        portBranche: true,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SectionHeader(titre: LibellesGroupe.avantProchainCours),
        Ecart.vMd,
        GroupeReglages(
          lignes: <LigneRubrique>[
            for (final SlotAction action in espace.avantProchainCours.take(3))
              LigneRubrique(
                libelle: action.libelle,
                icone: AppIcons.cours,
                onPress: onTache,
              ),
          ],
        ),
      ],
    );
  }
}
