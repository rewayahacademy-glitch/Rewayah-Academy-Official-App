// Pas 8 de l'import des formulaires (`ADM-23`) : le rapport final.
//
// Il n'existe qu'apres la reponse du serveur. Il montre les compteurs de ce que
// l'import a fait (choix de doublons compris), puis le rapport **ligne par
// ligne, sans nom** : le numero de la ligne, sa reference source (classeur,
// onglet, horodatage ecrit dans le fichier) et ce qu'elle est devenue. Aucun
// bouton plein : deux liens, « Revenir aux candidatures » et « Importer un autre
// fichier ». Un rapport rejoue (la meme demande deja enregistree) le dit.
library;

import 'package:flutter/material.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/candidature/modeles_import_candidatures.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/status_pill.dart';
import 'composants_import.dart';
import 'controleur_import.dart';
import 'libelles_import.dart';

/// Le pas « Rapport ».
class PasRapport extends StatelessWidget {
  /// Cree le pas.
  const PasRapport({
    required this.controleur,
    required this.onRevenir,
    super.key,
  });

  /// Le controleur de l'import.
  final ControleurImportCandidatures controleur;

  /// Revient a la file des candidatures.
  final VoidCallback onRevenir;

  /// La cle du lien « Revenir aux candidatures ».
  static const Key revenirKey = ValueKey<String>('import-revenir');

  /// La cle du lien « Importer un autre fichier ».
  static const Key autreFichierKey = ValueKey<String>('import-autre-fichier');

  /// La cle du titre du rapport.
  static const Key titreKey = ValueKey<String>('import-rapport-titre');

  @override
  Widget build(BuildContext context) {
    final a = t.admin.importFormulaires;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final RapportImport? r = controleur.rapport;
    if (r == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          liveRegion: true,
          child: QuestionDuPas(
            key: titreKey,
            question: a.rapport.titre,
            explication: a.rapport.question,
          ),
        ),
        Ecart.vXl,
        if (r.rejoue) ...<Widget>[
          InfoPas(
            key: const ValueKey<String>('import-rapport-rejoue'),
            message: a.rapport.rejoue,
          ),
          Ecart.vLg,
        ],
        CompteursCarte(compteurs: r.compteurs, termine: true),
        if (r.compteurs.historique > 0) ...<Widget>[
          Ecart.vSm,
          TexteSansCoupure(
            a.rapport.historique(n: r.compteurs.historique),
            key: const ValueKey<String>('import-rapport-historique'),
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        ],
        Ecart.vLg,
        AppCard(
          key: const ValueKey<String>('import-rapport-garantie'),
          child: TexteSansCoupure(
            a.rapport.sansCandidature,
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        ),
        Ecart.vLg,
        ListeLignesCarte(
          cle: 'rapport',
          titre: a.rapport.lignes.titre,
          aide: a.rapport.lignes.aide,
          compteur: r.lignes.length,
          entrees: <EntreeLigne>[
            for (final LigneRapport l in r.lignes)
              EntreeLigne(
                ligne: l.ligne,
                texte: a.apercu.ligne(ligne: l.ligne),
                complement: l.reference == null
                    ? a.rapport.lignes.sansReference
                    : a.rapport.lignes.reference(
                        reference: horodatageDeReference(l.reference!),
                      ),
                pastille: _pastille(l),
                ton: l.etatFinal == EtatFinalLigne.historique
                    ? TonEtat.neutre
                    : tonIssue(l.issue),
              ),
          ],
          pasDeLignes: (int n) => a.rapport.plus(n: n),
        ),
        Ecart.vXl,
        LienDebut(
          key: revenirKey,
          libelle: a.retourCandidatures,
          fleche: true,
          onPress: onRevenir,
        ),
        Ecart.vSm,
        LienDebut(
          key: autreFichierKey,
          libelle: a.rapport.autreFichier,
          onPress: controleur.recommencer,
        ),
      ],
    );
  }

  String _pastille(LigneRapport l) => l.etatFinal == EtatFinalLigne.historique
      ? t.admin.importFormulaires.issue.historique
      : libelleIssue(l.issue);
}
