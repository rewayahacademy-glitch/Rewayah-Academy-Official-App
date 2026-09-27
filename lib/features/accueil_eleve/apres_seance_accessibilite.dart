// MA-6 : apres la seance, pour l'eleve en Mode Accessibilite (doc 06 §6,
// MA21, planche 2 rectifiee).
//
// Dans l'ordre (UX_REVIEW ligne 9) : le resultat (« La seance est
// terminee. ») et la prochaine action, seul bouton dominant (« Retour a la
// Classe ») ; le travail pour la prochaine fois (3 au plus) ; « Revoir le
// support du cours » ; la prochaine seance ; « Besoin d'aide ? » en dernier
// (MA14). Retires : « Tres bien ! », confettis, « Message de votre
// enseignante » (Q8, BR-1). Aucune couleur nouvelle (K-37), aucun serveur.

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/tc_groupe/group_home_vm.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/section_header.dart';
import '../accueil_famille/bloc_seance.dart' show dateDeLAppareil;

/// L'ecran « apres la seance » de l'eleve en Mode Accessibilite.
class ApresSeanceAccessibilite extends StatelessWidget {
  /// Cree l'ecran.
  const ApresSeanceAccessibilite({
    required this.espace,
    required this.prochaineSeance,
    required this.tutoiement,
    required this.onRetourClasse,
    required this.onSupport,
    required this.onAide,
    super.key,
    this.onTache,
  });

  /// La Classe et le travail pour la prochaine fois (3 au plus).
  final GroupHomeVM espace;

  /// Le debut de la prochaine seance (UTC), ou `null`.
  final DateTime? prochaineSeance;

  /// Vrai pour l'eleve mineur (MA4) ; un adulte est vouvoye.
  final bool tutoiement;

  /// La prochaine action, seul bouton dominant.
  final VoidCallback onRetourClasse;

  /// « Revoir le support du cours ».
  final VoidCallback onSupport;

  /// Une ligne du travail.
  final VoidCallback? onTache;

  /// « Besoin d'aide ? ».
  final VoidCallback onAide;

  /// Cle du bouton dominant.
  static const Key cleRetourClasse = ValueKey<String>('ma6-retour-classe');

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final bool mobile = AppGabarit.de(context) == Gabarit.mobile;

    final Widget retour = ActionPrincipale(
      key: cleRetourClasse,
      libelle: t.salle.fin.retourClasse,
      onPress: onRetourClasse,
      fleche: true,
      pleineLargeur: mobile,
    );

    // Contrat B : le rectangle de resultat, 16 au-dessus du bouton, bouton
    // au bord de fin hors telephone.
    final Widget resultat = DecoratedBox(
      key: const ValueKey<String>('ma6-resultat'),
      decoration: palette.surfaceRaised.decoration(
        borderRadius: AppRadius.arrondiLg,
        side: palette.borderHairline.asBorderSide(),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(
                t.salle.fin.titreGuidee,
                style: palette.inkStrong.applyTo(
                  textes.headlineSmall ?? const TextStyle(),
                ),
              ),
            ),
            Ecart.vSm,
            Text(
              tutoiement
                  ? t.accessibilite.tutoiement.finPhrase
                  : t.salle.fin.phrase,
              style: palette.inkMuted.applyTo(
                textes.bodyLarge ?? const TextStyle(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (mobile)
              retour
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[retour],
              ),
          ],
        ),
      ),
    );

    final List<SlotAction> travail = espace.avantProchainCours.take(3).toList();
    final DateTime? suivante = prochaineSeance;

    return PageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          resultat,
          if (travail.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.section),
            SectionHeader(titre: LibellesGroupe.avantProchainCours),
            Ecart.vMd,
            GroupeReglages(
              lignes: <LigneRubrique>[
                for (final SlotAction action in travail)
                  LigneRubrique(
                    libelle: action.libelle,
                    icone: AppIcons.cours,
                    onPress: onTache,
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.section),
          GroupeReglages(
            lignes: <LigneRubrique>[
              LigneRubrique(
                libelle: t.accessibilite.apres.revoirSupport,
                legende: tutoiement
                    ? t.accessibilite.apres.revoirSupportDetail
                    : t.accessibilite.apres.revoirSupportDetailVous,
                icone: AppIcons.supports,
                onPress: onSupport,
              ),
            ],
          ),
          if (suivante != null) ...<Widget>[
            const SizedBox(height: AppSpacing.section),
            SectionHeader(titre: t.accessibilite.accueil.prochaineSeance),
            Ecart.vMd,
            GroupeReglages(
              lignes: <LigneRubrique>[
                LigneRubrique(
                  libelle: dateDeLAppareil(suivante.toLocal()),
                  legende: t.accessibilite.accueil.avec(
                    nomme: LibellesGroupe.enseignantNomme(
                      espace.identite.enseignant,
                    ),
                  ),
                  icone: AppIcons.journee,
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.section),
          // L'aide, dernier bloc du contenu (MA14).
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
      ),
    );
  }
}
