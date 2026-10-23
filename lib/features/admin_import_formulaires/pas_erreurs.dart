// Pas 5 de l'import des formulaires (`ADM-23`) : les erreurs et les avertissements,
// ligne par ligne.
//
// Une question : y a-t-il des lignes a corriger ? Trois listes, dans cet ordre :
// ce qui n'est pas importe (« A corriger »), ce qui l'est avec un point a verifier
// (« A regarder »), ce qui est ignore. Chaque ligne se nomme par son numero dans
// le fichier et dit sa cause en mots ; **aucun nom, courriel ni telephone**. Une
// ligne a corriger se corrige dans le classeur, puis le fichier se rejoue : les
// lignes deja importees ne sont pas ajoutees deux fois.
library;

import 'package:flutter/material.dart';

import '../../core/candidature/modeles_import_candidatures.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/status_pill.dart';
import 'composants_import.dart';
import 'controleur_import.dart';
import 'libelles_import.dart';

/// Le pas « Erreurs ».
class PasErreurs extends StatelessWidget {
  /// Cree le pas.
  const PasErreurs({required this.controleur, required this.empile, super.key});

  /// Le controleur de l'import.
  final ControleurImportCandidatures controleur;

  /// Vrai sur telephone.
  final bool empile;

  /// Les phrases d'une ligne : ses motifs et avertissements, puis ses marques.
  static String phraseDeLigne(LigneApercu l) {
    final a = t.admin.importFormulaires.apercu.marque;
    final String remarques = remarquesDeLigne(l.motifs, l.avertissements);
    final List<String> marques = <String>[
      if (l.courrielAObtenir) a.courrielAObtenir,
      if (l.indicatifAConfirmer) a.indicatifAConfirmer,
    ];
    return <String>[
      if (remarques.isNotEmpty) remarques,
      ...marques,
    ].join(' ; ');
  }

  @override
  Widget build(BuildContext context) {
    final a = t.admin.importFormulaires;
    final ApercuImport? apercu = controleur.apercu;
    final List<LigneApercu> lignes = apercu?.lignes ?? const <LigneApercu>[];
    final List<LigneApercu> aCorriger = <LigneApercu>[
      for (final LigneApercu l in lignes)
        if (l.issue == IssueLigne.aCorriger) l,
    ];
    final List<LigneApercu> ignorees = <LigneApercu>[
      for (final LigneApercu l in lignes)
        if (l.issue == IssueLigne.ignoree) l,
    ];
    final List<LigneApercu> aRegarder = <LigneApercu>[
      for (final LigneApercu l in lignes)
        if (l.issue != IssueLigne.aCorriger &&
            l.issue != IssueLigne.ignoree &&
            phraseDeLigne(l).isNotEmpty)
          l,
    ];
    EntreeLigne entree(LigneApercu l) => EntreeLigne(
      ligne: l.ligne,
      texte: a.controle.ligne(
        ligne: l.ligne,
        motif: phraseDeLigne(l).isEmpty ? texteRemarque('') : phraseDeLigne(l),
      ),
    );
    final bool rien =
        aCorriger.isEmpty && ignorees.isEmpty && aRegarder.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        QuestionDuPas(
          question: a.controle.question,
          explication: a.controle.explication,
        ),
        Ecart.vXl,
        if (rien)
          EmptyState(
            key: const ValueKey<String>('import-erreurs-aucune'),
            message: a.controle.aucune,
            invitation: a.controle.aucuneAide,
            icone: AppIcons.succes,
            registre: RegistreVide.bonneNouvelle,
          )
        else ...<Widget>[
          if (aCorriger.isNotEmpty) ...<Widget>[
            ListeLignesCarte(
              cle: 'a-corriger',
              titre: a.controle.aCorriger.titre,
              aide: a.controle.aCorriger.aide,
              ton: TonEtat.avertissement,
              entrees: <EntreeLigne>[
                for (final LigneApercu l in aCorriger) entree(l),
              ],
              pasDeLignes: (int n) => a.controle.plus(n: n),
            ),
            Ecart.vLg,
          ],
          if (aRegarder.isNotEmpty) ...<Widget>[
            ListeLignesCarte(
              cle: 'a-regarder',
              titre: a.controle.avertissements.titre,
              aide: a.controle.avertissements.aide,
              entrees: <EntreeLigne>[
                for (final LigneApercu l in aRegarder) entree(l),
              ],
              pasDeLignes: (int n) => a.controle.plus(n: n),
            ),
            Ecart.vLg,
          ],
          if (ignorees.isNotEmpty) ...<Widget>[
            ListeLignesCarte(
              cle: 'ignorees',
              titre: a.controle.ignorees.titre,
              aide: a.controle.ignorees.aide,
              entrees: <EntreeLigne>[
                for (final LigneApercu l in ignorees) entree(l),
              ],
              pasDeLignes: (int n) => a.controle.plus(n: n),
            ),
            Ecart.vLg,
          ],
        ],
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
