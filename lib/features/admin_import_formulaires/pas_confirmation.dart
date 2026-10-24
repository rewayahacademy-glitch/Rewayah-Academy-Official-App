// Pas 7 de l'import des formulaires (`ADM-23`) : la confirmation.
//
// Une question : importer ces reponses maintenant ? L'ecran redit ce qui sera
// enregistre (les compteurs du serveur et les choix de la direction), ce que
// l'import **ne fait pas** (aucun compte, aucune invitation, aucune candidature,
// aucun message), et l'ecart avec le decompte attendu s'il y en a un. Le bouton
// plein est le seul de l'ecran. **Rien n'est dit importe avant la reponse du
// serveur** : pendant l'envoi le bouton tourne ; une reponse perdue laisse
// l'import « non confirme » et se rejoue avec la meme cle d'idempotence.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/candidature/modeles_import_candidatures.dart';
import '../../core/candidature/port_import_candidatures.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bandeau_attention.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/status_pill.dart';
import 'composants_import.dart';
import 'controleur_import.dart';
import 'pas_comptes.dart' show phraseEcarts;

/// Le pas « Confirmation ».
class PasConfirmation extends StatelessWidget {
  /// Cree le pas.
  const PasConfirmation({
    required this.controleur,
    required this.empile,
    required this.horsLigne,
    super.key,
  });

  /// Le controleur de l'import.
  final ControleurImportCandidatures controleur;

  /// Vrai sur telephone.
  final bool empile;

  /// Vrai quand l'appareil est hors ligne.
  final bool horsLigne;

  /// La cle du resume.
  static const Key resumeKey = ValueKey<String>('import-confirmation-resume');

  /// La cle de ce que l'import ne fait pas.
  static const Key garantiesKey = ValueKey<String>(
    'import-confirmation-garanties',
  );

  /// La cle de l'echec de la derniere confirmation.
  static const Key echecKey = ValueKey<String>('import-confirmation-echec');

  /// La cle du lien « Relancer l'analyse ».
  static const Key relancerKey = ValueKey<String>('import-relancer');

  @override
  Widget build(BuildContext context) {
    final a = t.admin.importFormulaires;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final CompteursImport? c = controleur.apercu?.compteurs;
    final bool envoi = controleur.phase == PhaseImport.envoi;
    final Object? echec = controleur.erreurConfirmation;
    final List<EcartCompte> ecarts = controleur.ecarts;
    final int groupes = controleur.apercu?.groupes.length ?? 0;

    final String? nonConfirme = switch (echec) {
      null => null,
      JetonPerime() => a.confirmation.jetonPerime,
      ChoixInvalide() => a.confirmation.choixInvalide,
      CleIdempotenceReutilisee() => a.confirmation.cleReutilisee,
      ImportInvalide() || ImportRefuseInconnu() => a.confirmation.refus,
      _ => a.confirmation.nonConfirme,
    };
    // Un refus nomme du serveur : rien n'a ete ecrit, l'analyse est a refaire.
    final bool aRefaire =
        echec is JetonPerime ||
        echec is ChoixInvalide ||
        echec is CleIdempotenceReutilisee;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        QuestionDuPas(
          question: a.confirmation.question,
          explication: a.confirmation.explication,
        ),
        Ecart.vXl,
        if (c != null)
          AppCard(
            key: resumeKey,
            entete: Semantics(
              header: true,
              child: TexteSansCoupure(
                a.confirmation.resume.titre,
                style: textes.titleMedium,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                LigneCleValeur(
                  cle: a.confirmation.resume.fichier,
                  valeur: controleur.fichier?.nom ?? '',
                  valeurEnFin: true,
                ),
                TexteSansCoupure(
                  a.depot.noms.ligne(
                    classeur: controleur.noms.classeur.trim(),
                    onglet: controleur.noms.onglet.trim(),
                  ),
                  style: palette.inkMuted.applyTo(
                    textes.bodyMedium ?? const TextStyle(),
                  ),
                ),
                Ecart.vMd,
                LigneCleValeur(
                  cle: a.comptes.nouvelles,
                  valeur: '${c.nouvelles}',
                  chiffres: true,
                  valeurEnFin: true,
                ),
                if (c.corrigees > 0)
                  LigneCleValeur(
                    cle: a.comptes.corrigees,
                    valeur: '${c.corrigees}',
                    chiffres: true,
                  ),
                LigneCleValeur(
                  cle: a.comptes.dejaConnues,
                  valeur: '${c.dejaConnues}',
                  chiffres: true,
                  valeurEnFin: true,
                ),
                LigneCleValeur(
                  cle: a.comptes.ignorees,
                  valeur: '${c.ignorees}',
                  chiffres: true,
                  valeurEnFin: true,
                ),
                LigneCleValeur(
                  cle: a.comptes.aCorriger,
                  valeur: '${c.aCorriger}',
                  chiffres: true,
                  valeurEnFin: true,
                ),
                Ecart.vMd,
                TexteSansCoupure(
                  groupes == 0
                      ? a.confirmation.resume.aucunDoublon
                      : a.confirmation.resume.doublons(
                          choisis: '${controleur.groupesTranches}',
                          total: '$groupes',
                        ),
                  key: const ValueKey<String>('import-confirmation-doublons'),
                  style: palette.inkMuted.applyTo(
                    textes.bodyMedium ?? const TextStyle(),
                  ),
                ),
              ],
            ),
          ),
        if (ecarts.isNotEmpty) ...<Widget>[
          Ecart.vLg,
          BandeauAttention(
            key: const ValueKey<String>('import-confirmation-ecart'),
            titre: a.comptes.ecartTitre,
            message: phraseEcarts(ecarts),
          ),
        ],
        Ecart.vLg,
        AppCard(
          key: garantiesKey,
          entete: Semantics(
            header: true,
            child: TexteSansCoupure(
              a.confirmation.garanties.titre,
              style: textes.titleMedium,
            ),
          ),
          child: TexteSansCoupure(
            a.confirmation.garanties.texte,
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        ),
        if (nonConfirme != null) ...<Widget>[
          Ecart.vLg,
          BandeauAttention(
            key: echecKey,
            titre: aRefaire
                ? a.confirmation.titreARefaire
                : a.confirmation.titreNonConfirme,
            message: nonConfirme,
            ton: aRefaire ? TonEtat.alerte : TonEtat.avertissement,
            action: aRefaire
                ? LienDebut(
                    key: relancerKey,
                    libelle: a.confirmation.relancer,
                    onPress: () => unawaited(controleur.relireLeFichier()),
                  )
                : null,
          ),
        ],
        Ecart.vLg,
        ActionsDuPas(
          empile: empile,
          libelleAction: horsLigne || aRefaire ? null : a.confirmation.importer,
          onAction: () => unawaited(controleur.confirmer()),
          enCours: envoi,
          onRetour: controleur.precedent,
          souscription: envoi
              ? IndicationPas(message: a.confirmation.envoi, discret: true)
              : horsLigne
              ? IndicationPas(message: a.confirmation.horsLigne, discret: true)
              : null,
        ),
      ],
    );
  }
}
