// Pas 2 de l'import des formulaires (`ADM-23`) : l'apercu.
//
// Une question : est-ce le bon fichier ? La reponse se lit en un coup d'oeil :
// combien de lignes, combien de colonnes reconnues, et les premieres lignes avec
// ce que le serveur en a fait. **Aucun nom, courriel ni telephone n'est montre**
// (5.5) : le serveur n'en rend pas, et l'ecran n'en lit aucun dans le fichier.
// Seules deux marques voyagent, « courriel a obtenir » et « indicatif a
// confirmer ».
library;

import 'package:flutter/material.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/candidature/modeles_import_candidatures.dart';
import '../../core/candidature/port_import_candidatures.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bandeau_attention.dart';
import '../../core/widgets/status_pill.dart';
import 'composants_import.dart';
import 'controleur_import.dart';
import 'libelles_import.dart';

/// Combien de lignes l'apercu montre.
const int lignesDApercu = 5;

/// Le pas « Aperçu ».
class PasApercu extends StatelessWidget {
  /// Cree le pas.
  const PasApercu({required this.controleur, required this.empile, super.key});

  /// Le controleur de l'import.
  final ControleurImportCandidatures controleur;

  /// Vrai sur telephone.
  final bool empile;

  /// La cle de la carte des lignes lues.
  static const Key resumeKey = ValueKey<String>('import-apercu-resume');

  /// La cle de la carte des premieres lignes.
  static const Key premieresKey = ValueKey<String>('import-apercu-premieres');

  @override
  Widget build(BuildContext context) {
    final a = t.admin.importFormulaires;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final ApercuImport? apercu = controleur.apercu;
    final Object? erreur = controleur.erreurAnalyse;
    final int lues =
        apercu?.compteurs.lignesLues ?? controleur.fichier?.nombreLignes ?? 0;
    final int colonnes = controleur.fichier?.nombreColonnes ?? 0;
    final int reconnues = apercu != null
        ? apercu.colonnesReconnues
        : controleur.colonnes.where((c) => c.champ != null).length;
    final List<LigneApercu> premieres = apercu == null
        ? const <LigneApercu>[]
        : apercu.lignes.take(lignesDApercu).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        QuestionDuPas(
          question: a.apercu.question,
          explication: a.apercu.explication,
        ),
        Ecart.vLg,
        InfoPas(
          key: const ValueKey<String>('import-contacts-masques'),
          message: a.apercu.contactsMasques,
          icone: AppIcons.masquer,
        ),
        Ecart.vLg,
        if (erreur is MappageIncomplet) ...<Widget>[
          BandeauAttention(
            key: const ValueKey<String>('import-apercu-manquants'),
            titre: a.apercu.colonnesATitre,
            message: a.apercu.mappageIncomplet(
              champs: listeDe(<String>[
                for (final ChampManquant c in erreur.champs) libelleManquant(c),
              ]),
            ),
          ),
          Ecart.vLg,
        ] else if (erreur is EntetesAmbigus) ...<Widget>[
          BandeauAttention(
            key: const ValueKey<String>('import-apercu-ambigu'),
            titre: a.apercu.ambiguTitre,
            message: a.apercu.ambigu(
              champs: listeDe(<String>[
                for (final ChampFormulaire c in erreur.champs) libelleChamp(c),
              ]),
            ),
          ),
          Ecart.vLg,
        ],
        AppCard(
          key: resumeKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TexteSansCoupure(
                a.apercu.lignes(n: lues),
                key: const ValueKey<String>('import-apercu-lignes'),
                style: textes.titleMedium,
              ),
              Ecart.vSm,
              TexteSansCoupure(
                a.apercu.colonnesReconnues(
                  reconnues: '$reconnues',
                  total: '$colonnes',
                ),
                key: const ValueKey<String>('import-apercu-colonnes'),
                style: textes.bodyLarge,
              ),
            ],
          ),
        ),
        if (apercu == null) ...<Widget>[
          Ecart.vLg,
          TexteSansCoupure(
            a.apercu.sansLignes,
            key: const ValueKey<String>('import-apercu-sans-lignes'),
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        ] else if (premieres.isNotEmpty) ...<Widget>[
          Ecart.vLg,
          AppCard(
            key: premieresKey,
            entete: Semantics(
              header: true,
              child: TexteSansCoupure(
                a.apercu.premieres,
                style: textes.titleMedium,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (final LigneApercu l in premieres) ...<Widget>[
                  _LigneDApercu(ligne: l),
                  Ecart.vMd,
                ],
                if (premieres.any(
                  (LigneApercu l) =>
                      l.courrielAObtenir ||
                      l.indicatifAConfirmer ||
                      l.issue == IssueLigne.ignoree,
                )) ...<Widget>[
                  TexteSansCoupure(
                    a.apercu.aideMarques,
                    key: const ValueKey<String>('import-apercu-aide-marques'),
                    style: palette.inkMuted.applyTo(
                      textes.bodyMedium ?? const TextStyle(),
                    ),
                  ),
                  Ecart.vMd,
                ],
                if (apercu.lignes.length > premieres.length)
                  TexteSansCoupure(
                    a.apercu.autres(n: apercu.lignes.length - premieres.length),
                    style: palette.inkMuted.applyTo(
                      textes.bodyMedium ?? const TextStyle(),
                    ),
                  ),
              ],
            ),
          ),
        ],
        Ecart.vLg,
        ActionsDuPas(
          empile: empile,
          libelleAction: t.commun.continuer,
          onAction: controleur.suivant,
          onRetour: controleur.precedent,
        ),
      ],
    );
  }
}

/// Une ligne de l'apercu : son numero, ce que le serveur en fait, ses marques.
///
/// Les mots d'etat se rangent les uns a cote des autres, a la suite du numero,
/// et passent a la ligne quand la place manque. Texte tres agrandi : ils
/// passent sous le numero.
class _LigneDApercu extends StatelessWidget {
  const _LigneDApercu({required this.ligne});

  final LigneApercu ligne;

  @override
  Widget build(BuildContext context) {
    final a = t.admin.importFormulaires;
    final TextTheme textes = Theme.of(context).textTheme;
    final bool empile =
        MediaQuery.textScalerOf(context).scale(1) > seuilTexteEmpile;
    final Widget numero = TexteSansCoupure(
      a.apercu.ligne(ligne: ligne.ligne),
      style: textes.bodyLarge,
    );
    final Widget mots = Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: <Widget>[
        StatusPill(
          libelle: libelleIssue(ligne.issue),
          ton: tonIssue(ligne.issue),
        ),
        if (ligne.courrielAObtenir)
          StatusPill(
            libelle: a.apercu.marque.courrielAObtenir,
            ton: TonEtat.avertissement,
          ),
        if (ligne.indicatifAConfirmer)
          StatusPill(
            libelle: a.apercu.marque.indicatifAConfirmer,
            ton: TonEtat.avertissement,
          ),
      ],
    );
    final Key cle = ValueKey<String>('import-apercu-ligne-${ligne.ligne}');
    if (empile) {
      return Column(
        key: cle,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[numero, Ecart.vXs, mots],
      );
    }
    return Row(
      key: cle,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(flex: 2, child: numero),
        Ecart.hSm,
        Expanded(flex: 5, child: mots),
      ],
    );
  }
}
