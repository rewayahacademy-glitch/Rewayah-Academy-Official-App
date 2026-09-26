import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin/admin_domaine.dart';
import '../../core/admin/config_edition.dart';
import '../../core/admin/service_configuration.dart';
import '../../core/capacites/port_politique_revue_kyc.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/sous_navigation_domaine.dart';

/// `ADM-16` : Configuration > Fonctionnalites, deuxieme fonction du domaine
/// (contrat metier reçu le 19 septembre 2026,
/// `docs/archive/2026-09-pre-remise-a-plat/architecture/ADMIN_FINANCE_CONFIGURATION.md`).
///
/// Exemple donne par le contrat lui-meme : « Activer les cours
/// multi-participants -> Configuration > Fonctionnalites ». Le plafond de
/// participants voyage avec l'interrupteur qui le rend applicable, pas
/// separement.
class FonctionnalitesPage extends ConsumerWidget {
  /// Cree l'ecran des fonctionnalites.
  const FonctionnalitesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AsyncValue<List<ValeurConfig>> valeurs = ref.watch(
      valeursFonctionnalitesProvider,
    );

    return PageShell(
      titre: t.admin.fonctionnalites.titre,
      entete: SousNavigationDomaine(
        onglets: ongletsConfiguration(
          politiqueRevueKyc: ref.watch(peutReglerPolitiqueKycProvider),
        ),
        indexActif: 1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(t.admin.fonctionnalites.intro, style: textes.bodyMedium),
          Ecart.vXl,
          switch (valeurs) {
            AsyncValue<List<ValeurConfig>>(hasValue: true) => _Corps(
              valeurs: valeurs.requireValue,
              onEcrit: () => ref.invalidate(valeursFonctionnalitesProvider),
            ),
            AsyncValue<List<ValeurConfig>>(hasError: true) => EmptyState(
              message: t.admin.fonctionnalites.erreur,
              icone: AppIcons.avertissement,
              libelleAction: t.commun.reessayer,
              onAction: () => ref.invalidate(valeursFonctionnalitesProvider),
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
    final Map<String, ValeurConfig> v = <String, ValeurConfig>{
      for (final ValeurConfig c in valeurs) c.cle: c,
    };
    String erreurEcriture(String message) =>
        t.admin.fonctionnalites.erreurEcriture(message: message);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ConfigLigneBooleenne(
          titre: t.admin.fonctionnalites.multiParticipants,
          description: t.admin.fonctionnalites.multiParticipantsDetail,
          cle: 'allow_multi_participant_sessions',
          valeur: v['allow_multi_participant_sessions']?.versBooleen ?? false,
          erreurEcriture: erreurEcriture,
          onEcrit: onEcrit,
        ),
        ConfigLigneEntiere(
          titre: t.admin.fonctionnalites.participantsMax,
          description: t.admin.fonctionnalites.participantsMaxDetail,
          cle: 'max_participants_per_session',
          valeur: v['max_participants_per_session']?.versEntier ?? 0,
          affichage: (int n) => t.admin.fonctionnalites.uniteNombre(n: '$n'),
          champValeur: t.admin.fonctionnalites.champValeur,
          envoyer: t.admin.fonctionnalites.envoyer,
          valeurInvalide: t.admin.fonctionnalites.valeurInvalide,
          erreurEcriture: erreurEcriture,
          onEcrit: onEcrit,
        ),
      ],
    );
  }
}
