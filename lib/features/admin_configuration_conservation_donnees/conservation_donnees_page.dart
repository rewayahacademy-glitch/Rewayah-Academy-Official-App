import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin/admin_domaine.dart';
import '../../core/admin/config_edition.dart';
import '../../core/admin/service_configuration.dart';
import '../../core/capacites/port_politique_revue_kyc.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/carte_lignes.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/sous_navigation_domaine.dart';

/// `ADM-17` : Configuration > Conservation des donnees, troisieme fonction du
/// domaine (contrat metier reçu le 19 septembre 2026,
/// `docs/archive/2026-09-pre-remise-a-plat/architecture/ADMIN_FINANCE_CONFIGURATION.md`).
///
/// Deux delais aujourd'hui : les enregistrements de seance
/// (`recording_retention_days`) et les documents d'identite deposes
/// (`kyc_retention_days`, `kyc_documents.purge_at` s'en deduit a chaque
/// depot, migration `0004`). Aucun autre delai de conservation n'existe
/// encore en base.
class ConservationDonneesPage extends ConsumerWidget {
  /// Cree l'ecran de conservation des donnees.
  const ConservationDonneesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AsyncValue<List<ValeurConfig>> valeurs = ref.watch(
      valeursConservationDonneesProvider,
    );

    return PageShell(
      titre: t.admin.conservationDonnees.titre,
      entete: SousNavigationDomaine(
        onglets: ongletsConfiguration(
          politiqueRevueKyc: ref.watch(peutReglerPolitiqueKycProvider),
        ),
        indexActif: 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(t.admin.conservationDonnees.intro, style: textes.bodyMedium),
          Ecart.vXl,
          switch (valeurs) {
            AsyncValue<List<ValeurConfig>>(hasValue: true) => _Corps(
              valeurs: valeurs.requireValue,
              onEcrit: () => ref.invalidate(valeursConservationDonneesProvider),
            ),
            AsyncValue<List<ValeurConfig>>(hasError: true) => EmptyState(
              message: t.admin.conservationDonnees.erreur,
              icone: AppIcons.avertissement,
              libelleAction: t.commun.reessayer,
              onAction: () =>
                  ref.invalidate(valeursConservationDonneesProvider),
            ),
            _ => const Skeleton.liste(lignes: 2),
          },
        ],
      ),
    );
  }
}

class _Corps extends StatelessWidget {
  const _Corps({required this.valeurs, required this.onEcrit});

  final List<ValeurConfig> valeurs;
  final VoidCallback onEcrit;

  @override
  Widget build(BuildContext context) {
    final Map<String, int> v = <String, int>{
      for (final ValeurConfig c in valeurs) c.cle: c.versEntier,
    };
    String erreurEcriture(String message) =>
        t.admin.conservationDonnees.erreurEcriture(message: message);

    return CarteLignes(
      lignes: <Widget>[
        ConfigLigneEntiere(
          titre: t.admin.conservationDonnees.enregistrements,
          description: t.admin.conservationDonnees.enregistrementsDetail,
          cle: 'recording_retention_days',
          valeur: v['recording_retention_days'] ?? 0,
          affichage: (int n) => LibellesGroupe.valeurSeule(
            t.admin.conservationDonnees.uniteJours(n: '$n'),
          ),
          champValeur: t.admin.conservationDonnees.champValeur,
          envoyer: t.admin.conservationDonnees.envoyer,
          valeurInvalide: t.admin.conservationDonnees.valeurInvalide,
          erreurEcriture: erreurEcriture,
          onEcrit: onEcrit,
        ),
        ConfigLigneEntiere(
          titre: t.admin.conservationDonnees.documentsIdentite,
          description: t.admin.conservationDonnees.documentsIdentiteDetail,
          cle: 'kyc_retention_days',
          valeur: v['kyc_retention_days'] ?? 0,
          affichage: (int n) => LibellesGroupe.valeurSeule(
            t.admin.conservationDonnees.uniteJours(n: '$n'),
          ),
          champValeur: t.admin.conservationDonnees.champValeur,
          envoyer: t.admin.conservationDonnees.envoyer,
          valeurInvalide: t.admin.conservationDonnees.valeurInvalide,
          erreurEcriture: erreurEcriture,
          onEcrit: onEcrit,
        ),
      ],
    );
  }
}
