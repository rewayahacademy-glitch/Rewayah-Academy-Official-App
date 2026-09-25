// La fin de seance, cote eleve (CLV-09).
//
// Un etat resultat centre (grammaire `EcranResultat`, largeur
// `largeurEtatVide`) : titre, phrase, action pleine. Aucun recapitulatif,
// aucune presence, aucune mention d'enregistrement : la seance est finie
// pour cet appareil. L'Interface guidee se lit dans le theme
// (`AppMetriques.of(context)`), jamais en parametre.

import 'package:flutter/material.dart';

import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/ecran_resultat.dart';
import '../../core/widgets/status_pill.dart';

/// Pourquoi l'eleve quitte la salle.
enum IssueSeance {
  /// La seance est finie (fin serveur).
  terminee,

  /// L'eleve est sorti avant la fin, apres confirmation.
  quittee,
}

/// L'ecran de fin de l'eleve : standard ou guide, fin ou sortie.
class ResultatSeance extends StatelessWidget {
  const ResultatSeance({
    required this.issue,
    required this.onRetour,
    super.key,
  });

  final IssueSeance issue;

  /// Retour a la Classe (standard) ou a l'accueil (guidee).
  final VoidCallback onRetour;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final bool guidee = AppMetriques.of(context).mode == InterfaceMode.enfant;
    final bool large = AppGabarit.de(context) == Gabarit.desktop;
    final bool fin = guidee || issue == IssueSeance.terminee;
    // Guidee : une phrase courte, sans suite (S CLV-09, moins de 10 mots).
    final String titre = guidee
        ? t.salle.fin.titreGuidee
        : switch (issue) {
            IssueSeance.terminee => t.salle.fin.titre,
            IssueSeance.quittee => t.salle.fin.quitteTitre,
          };
    final String? phrase = guidee
        ? null
        : switch (issue) {
            IssueSeance.terminee => t.salle.fin.phrase,
            IssueSeance.quittee => t.salle.fin.quittePhrase,
          };
    return Material(
      key: const ValueKey<String>('resultat-seance'),
      color: palette.surfaceCanvas.background,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints contraintes) =>
              SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: large
                      ? AppPage.gouttiereDesktop
                      : AppPage.gouttiereMobile,
                  vertical: AppSpacing.xxl,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: contraintes.maxHeight - 2 * AppSpacing.xxl,
                  ),
                  child: Center(
                    child: EcranResultat(
                      // Guidee : un seul ecran de fin (« La seance est
                      // terminee. »), donc la coche au ton succes, meme apres
                      // Quitter : l'icone ne contredit jamais le texte.
                      icone: fin ? AppIcons.succes : AppIcons.sortie,
                      ton: fin ? TonEtat.succes : TonEtat.neutre,
                      titre: titre,
                      phrase: phrase,
                      libelleAction: guidee
                          ? t.salle.fin.retourAccueil
                          : t.salle.fin.retourClasse,
                      onAction: onRetour,
                    ),
                  ),
                ),
              ),
        ),
      ),
    );
  }
}
