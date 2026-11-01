import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin/admin_domaine.dart';
import '../../core/admin/config_edition.dart';
import '../../core/admin/service_configuration.dart';
import '../../core/capacites/port_politique_revue_kyc.dart';
import '../../core/i18n/isolat_bidi.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
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

/// Une valeur de regle en minutes, affichee seule : « 45 min », insecable et
/// ancree en interface de droite a gauche (DUREE-INSECABLE-3).
String uniteMinutesRegle(int n) =>
    LibellesGroupe.valeurSeule(t.admin.regles.uniteMinutes(n: '$n'));

List<_ChampRegle> _champs() => <_ChampRegle>[
  (
    titre: t.admin.regles.absenceSeuil,
    description: t.admin.regles.absenceSeuilDetail,
    cle: 'absence_threshold_minutes',
    affichage: uniteMinutesRegle,
  ),
  (
    titre: t.admin.regles.dureeSeance,
    description: t.admin.regles.dureeSeanceDetail,
    cle: 'session_duration_minutes',
    affichage: uniteMinutesRegle,
  ),
  (
    titre: t.admin.regles.dureeMinimalePayee,
    description: t.admin.regles.dureeMinimalePayeeDetail,
    cle: 'session_paid_minimum_minutes',
    affichage: uniteMinutesRegle,
  ),
  (
    titre: t.admin.regles.pauseEntreSeances,
    description: t.admin.regles.pauseEntreSeancesDetail,
    cle: 'break_minutes_between_sessions',
    affichage: uniteMinutesRegle,
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
    affichage: (int n) =>
        LibellesGroupe.valeurSeule(t.admin.regles.uniteSemaines(n: n)),
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
  (
    titre: t.admin.regles.classesParEnseignant,
    description: t.admin.regles.classesParEnseignantDetail,
    cle: cleClassesParEnseignant,
    affichage: (int n) => t.admin.regles.uniteNombre(n: '$n'),
  ),
];

/// Les reglages que seul un serveur a jour porte : sans eux dans la reponse
/// (valeur nulle), la ligne n'est pas montree, plutot qu'un « 0 » que rien
/// n'ecrirait. Aujourd'hui, le nombre maximal de Classes par enseignant (lot
/// CLASSES-PLAFOND, `20261022000200_classes_plafond_par_enseignant.sql`).
const Set<String> _reglagesDuServeurAJour = <String>{cleClassesParEnseignant};

/// Le plafond des delais A3 : `private.remplacement_reglage` ne lit qu'un
/// entier de 1 a 3 chiffres (`20261102500000_remplacement_auto.sql`).
const int _delaiRemplacementMax = 999;

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

    // Les cles que le serveur ne rend pas (valeur nulle).
    final Set<String> absentes = <String>{
      for (final ValeurConfig c in valeurs)
        if (c.valeur == null) c.cle,
    };
    final Widget generales = CarteLignes(
      lignes: <Widget>[
        for (final _ChampRegle champ in _champs())
          if (!(_reglagesDuServeurAJour.contains(champ.cle) &&
              absentes.contains(champ.cle)))
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
    // A3 : un serveur d'avant la regle ne rend pas ces cles ; alors la section
    // n'est pas montree, plutot qu'un « 0 min » que rien n'ecrirait.
    if (clesRemplacement.any(absentes.contains)) return generales;
    final int avertissement = v[cleRemplacementAvertissement]!;
    final int perte = v[cleRemplacementPerteAcces]!;
    final int objectif = v[cleRemplacementObjectif]!;
    String m(int n) => sansAncre(uniteMinutesRegle(n));
    ConfigLigneEntiere ligne({
      required String titre,
      required String description,
      required String cle,
      required int valeur,
      required int min,
      required int max,
      required String aide,
    }) => ConfigLigneEntiere(
      titre: titre,
      description: description,
      cle: cle,
      valeur: valeur,
      min: min,
      max: max,
      aideBornes: aide,
      affichage: uniteMinutesRegle,
      champValeur: t.admin.regles.champValeur,
      envoyer: t.admin.regles.envoyer,
      valeurInvalide: t.admin.regles.valeurInvalide,
      erreurEcriture: erreurEcriture,
      onEcrit: onEcrit,
    );
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        generales,
        Ecart.vXl,
        Text(t.admin.regles.remplacementSection, style: textes.titleMedium),
        Ecart.vSm,
        Text(t.admin.regles.remplacementIntro, style: textes.bodyMedium),
        Ecart.vMd,
        CarteLignes(
          lignes: <Widget>[
            ligne(
              titre: t.admin.regles.remplacementAvertissement,
              description: t.admin.regles.remplacementAvertissementDetail,
              cle: cleRemplacementAvertissement,
              valeur: avertissement,
              min: 0,
              max: perte - 1,
              aide: t.admin.regles.remplacementBornesAvertissement(
                min: m(0),
                max: m(perte - 1),
              ),
            ),
            ligne(
              titre: t.admin.regles.remplacementPerte,
              description: t.admin.regles.remplacementPerteDetail,
              cle: cleRemplacementPerteAcces,
              valeur: perte,
              min: avertissement + 1,
              max: objectif - 1,
              aide: t.admin.regles.remplacementBornesPerte(
                min: m(avertissement + 1),
                max: m(objectif - 1),
              ),
            ),
            ligne(
              titre: t.admin.regles.remplacementObjectif,
              description: t.admin.regles.remplacementObjectifDetail,
              cle: cleRemplacementObjectif,
              valeur: objectif,
              min: perte + 1,
              max: _delaiRemplacementMax,
              aide: t.admin.regles.remplacementBornesObjectif(
                min: m(perte + 1),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
