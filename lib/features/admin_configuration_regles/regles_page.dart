import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin/admin_domaine.dart';
import '../../core/admin/config_edition.dart';
import '../../core/admin/service_configuration.dart';
import '../../core/capacites/port_politique_revue_kyc.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/carte_lignes.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/sous_navigation_domaine.dart';

/// `ADM-15` : Configuration > Regles, premiere fonction du domaine (contrat
/// metier reçu le 19 septembre 2026,
/// `docs/archive/2026-09-pre-remise-a-plat/architecture/ADMIN_FINANCE_CONFIGURATION.md`).
///
/// **Le defaut de plateforme, jamais l'exception d'un profil.** Quatre de ces
/// dix cles (`session_duration_minutes`, `session_paid_minimum_minutes`,
/// `break_minutes_between_sessions`, `max_students_per_teacher`) ont deja une
/// surcharge par profil sous Operations > Regles individuelles (`ADM-06`,
/// `rule_overrides`, `core/regles/service_regles.dart`). Cet ecran n'y touche
/// pas : il edite la valeur qui s'applique quand aucune surcharge n'existe --
/// deux natures, deux routes canoniques, jamais le meme reglage aux deux
/// endroits.
class ReglesPage extends ConsumerWidget {
  /// Cree l'ecran des regles.
  const ReglesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AsyncValue<List<ValeurConfig>> valeurs = ref.watch(
      valeursReglesProvider,
    );

    return PageShell(
      titre: t.admin.regles.titre,
      entete: SousNavigationDomaine(
        onglets: ongletsConfiguration(
          politiqueRevueKyc: ref.watch(peutReglerPolitiqueKycProvider),
        ),
        indexActif: 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(t.admin.regles.intro, style: textes.bodyMedium),
          Ecart.vXl,
          switch (valeurs) {
            AsyncValue<List<ValeurConfig>>(hasValue: true) => _Corps(
              valeurs: valeurs.requireValue,
              onEcrit: () => ref.invalidate(valeursReglesProvider),
            ),
            AsyncValue<List<ValeurConfig>>(hasError: true) => EmptyState(
              message: t.admin.regles.erreur,
              icone: AppIcons.avertissement,
              libelleAction: t.commun.reessayer,
              onAction: () => ref.invalidate(valeursReglesProvider),
            ),
            _ => const Skeleton.liste(lignes: 5),
          },
        ],
      ),
    );
  }
}

typedef _ChampRegle = ({
  String titre,
  String description,
  String cle,
  String Function(int n) affichage,
});

List<_ChampRegle> _champs() => <_ChampRegle>[
  (
    titre: t.admin.regles.absenceSeuil,
    description: t.admin.regles.absenceSeuilDetail,
    cle: 'absence_threshold_minutes',
    affichage: (int n) => t.admin.regles.uniteMinutes(n: '$n'),
  ),
  (
    titre: t.admin.regles.dureeSeance,
    description: t.admin.regles.dureeSeanceDetail,
    cle: 'session_duration_minutes',
    affichage: (int n) => t.admin.regles.uniteMinutes(n: '$n'),
  ),
  (
    titre: t.admin.regles.dureeMinimalePayee,
    description: t.admin.regles.dureeMinimalePayeeDetail,
    cle: 'session_paid_minimum_minutes',
    affichage: (int n) => t.admin.regles.uniteMinutes(n: '$n'),
  ),
  (
    titre: t.admin.regles.pauseEntreSeances,
    description: t.admin.regles.pauseEntreSeancesDetail,
    cle: 'break_minutes_between_sessions',
    affichage: (int n) => t.admin.regles.uniteMinutes(n: '$n'),
  ),
  (
    titre: t.admin.regles.elevesParEnseignant,
    description: t.admin.regles.elevesParEnseignantDetail,
    cle: 'max_students_per_teacher',
    affichage: (int n) => t.admin.regles.uniteNombre(n: '$n'),
  ),
  (
    titre: t.admin.regles.horizonAffectation,
    description: t.admin.regles.horizonAffectationDetail,
    cle: 'matching_horizon_weeks',
    affichage: (int n) => t.admin.regles.uniteSemaines(n: '$n'),
  ),
  (
    titre: t.admin.regles.ageCameraAuto,
    description: t.admin.regles.ageCameraAutoDetail,
    cle: 'camera_auto_allow_min_age',
    affichage: (int n) => t.admin.regles.uniteNombre(n: '$n'),
  ),
  (
    titre: t.admin.regles.ageInterfaceEnfant,
    description: t.admin.regles.ageInterfaceEnfantDetail,
    cle: 'child_ui_mode_max_age',
    affichage: (int n) => t.admin.regles.uniteNombre(n: '$n'),
  ),
  (
    titre: t.admin.regles.appareilsParEleve,
    description: t.admin.regles.appareilsParEleveDetail,
    cle: 'max_devices_per_student',
    affichage: (int n) => t.admin.regles.uniteNombre(n: '$n'),
  ),
  (
    titre: t.admin.regles.seancesSimultanees,
    description: t.admin.regles.seancesSimultaneesDetail,
    cle: 'max_concurrent_sessions_per_profile',
    affichage: (int n) => t.admin.regles.uniteNombre(n: '$n'),
  ),
];

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
        t.admin.regles.erreurEcriture(message: message);

    return CarteLignes(
      lignes: <Widget>[
        for (final _ChampRegle champ in _champs())
          ConfigLigneEntiere(
            titre: champ.titre,
            description: champ.description,
            cle: champ.cle,
            valeur: v[champ.cle] ?? 0,
            affichage: champ.affichage,
            champValeur: t.admin.regles.champValeur,
            envoyer: t.admin.regles.envoyer,
            valeurInvalide: t.admin.regles.valeurInvalide,
            erreurEcriture: erreurEcriture,
            onEcrit: onEcrit,
          ),
      ],
    );
  }
}
