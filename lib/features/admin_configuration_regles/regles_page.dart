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
import '../priere_serveur/regles_priere.dart';

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
    titre: t.admin.regles.depassementSeance,
    description: t.admin.regles.depassementSeanceDetail,
    cle: cleDepassementSeance,
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
    final TextTheme textes = Theme.of(context).textTheme;
    // V2-a : la regle des fondateurs d'un entretien (V1-a). Un serveur d'avant
    // V1-a ne rend pas ces cles ; la section n'est alors pas montree.
    final ValeurConfig? regleFondateurs = _valeur(
      valeurs,
      cleEntretiensRegleFondateurs,
    );
    final List<Widget> entretiens =
        absentes.contains(cleEntretiensRegleFondateurs) ||
            absentes.contains(cleEntretiensFondateursMinimum)
        ? const <Widget>[]
        : <Widget>[
            Ecart.vXl,
            Text(
              t.admin.regles.entretiensSection,
              key: const ValueKey<String>('regles-entretiens'),
              style: textes.titleMedium,
            ),
            Ecart.vSm,
            Text(t.admin.regles.entretiensIntro, style: textes.bodyMedium),
            Ecart.vMd,
            CarteLignes(
              lignes: <Widget>[
                ConfigLigneBooleenne(
                  titre: t.admin.regles.regleFondateurs,
                  description: t.admin.regles.regleFondateursDetail,
                  cle: cleEntretiensRegleFondateurs,
                  valeur: regleFondateurs?.versBooleen ?? false,
                  erreurEcriture: erreurEcriture,
                  onEcrit: onEcrit,
                ),
                ConfigLigneEntiere(
                  titre: t.admin.regles.fondateursMinimum,
                  description: t.admin.regles.fondateursMinimumDetail,
                  cle: cleEntretiensFondateursMinimum,
                  valeur: v[cleEntretiensFondateursMinimum]!,
                  min: 1,
                  max: 99,
                  aideBornes: t.admin.regles.fondateursBornes,
                  affichage: (int n) => t.admin.regles.uniteNombre(n: '$n'),
                  champValeur: t.admin.regles.champValeur,
                  envoyer: t.admin.regles.envoyer,
                  valeurInvalide: t.admin.regles.valeurInvalide,
                  erreurEcriture: erreurEcriture,
                  onEcrit: onEcrit,
                ),
              ],
            ),
          ];
    // REVENUS-VERITE (06/11/2026) : le jour de paie, reglage de la direction.
    // Un serveur d'avant le lot ne rend pas la cle : la section n'est pas
    // montree.
    final ({int debut, int fin})? fenetre = fenetreVersementDe(
      _valeur(valeurs, clePaieFenetreVersement)?.valeur,
    );
    final List<Widget> paie = fenetre == null
        ? const <Widget>[]
        : _sectionPaie(textes, fenetre, erreurEcriture, onEcrit);
    // PRIERE-1 : les reglages de la priere de l'ecole ; absents d'un serveur
    // d'avant le lot, la section n'est pas montree.
    final List<Widget> priere = sectionReglesPriere(
      valeurs: valeurs,
      textes: textes,
      onEcrit: onEcrit,
      erreurEcriture: erreurEcriture,
    );
    // A3 : un serveur d'avant la regle ne rend pas ces cles ; alors la section
    // n'est pas montree, plutot qu'un « 0 min » que rien n'ecrirait.
    if (clesRemplacement.any(absentes.contains)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[generales, ...entretiens, ...paie, ...priere],
      );
    }
    final int avertissement = v[cleRemplacementAvertissement]!;
    final int perte = v[cleRemplacementPerteAcces]!;
    final int objectif = v[cleRemplacementObjectif]!;
    // SNT : absente d'un serveur d'avant le lot ; la ligne n'est pas montree.
    final int? nonTenue = absentes.contains(cleRemplacementSeanceNonTenue)
        ? null
        : v[cleRemplacementSeanceNonTenue];
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
      // Le refus d'ordre du serveur (20261104200000) se dit en mots simples :
      // un autre reglage a change pendant que la feuille etait ouverte.
      erreurEcriture: (String message) =>
          message.contains('delais de remplacement')
          ? t.admin.regles.remplacementOrdreRefuse
          : erreurEcriture(message),
      onEcrit: onEcrit,
    );
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
              // A3-bis : l'enseignant ne perd la seance que si un remplacant
              // est pret ; « risque de perdre ».
              description: t.a3bis.regles.avertissementDetail,
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
              // A3-bis : l'enseignant n'est ecarte que si un remplacant est
              // pret ; l'ancien texte disait l'inverse.
              description: t.a3bis.regles.perteDetail,
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
              max: nonTenue == null ? _delaiRemplacementMax : nonTenue - 1,
              aide: nonTenue == null
                  ? t.admin.regles.remplacementBornesObjectif(min: m(perte + 1))
                  : t.snt.regles.bornesObjectif(
                      min: m(perte + 1),
                      max: m(nonTenue - 1),
                    ),
            ),
            // SNT (03/11/2026) : la seance non tenue, apres l'objectif.
            if (nonTenue != null)
              ligne(
                titre: t.snt.regles.nonTenue,
                description: t.snt.regles.nonTenueDetail,
                cle: cleRemplacementSeanceNonTenue,
                valeur: nonTenue,
                min: objectif + 1,
                max: _delaiRemplacementMax,
                aide: t.snt.regles.bornesNonTenue(
                  min: m(objectif + 1),
                  max: m(_delaiRemplacementMax),
                ),
              ),
            // A3-bis : un serveur d'avant ce lot ne rend pas ces deux cles ;
            // les lignes ne sont alors pas montrees.
            if (!absentes.contains(cleRemplacementAlerteDirection))
              ligne(
                titre: t.a3bis.regles.alerteDirection,
                description: t.a3bis.regles.alerteDirectionDetail,
                cle: cleRemplacementAlerteDirection,
                valeur: v[cleRemplacementAlerteDirection]!,
                min: 0,
                max: _delaiRemplacementMax,
                aide: t.a3bis.regles.bornesAlerte(
                  min: m(0),
                  max: m(_delaiRemplacementMax),
                ),
              ),
            if (!absentes.contains(cleRemplacementSeanceTardive))
              ligne(
                titre: t.a3bis.regles.seanceTardive,
                description: t.a3bis.regles.seanceTardiveDetail,
                cle: cleRemplacementSeanceTardive,
                valeur: v[cleRemplacementSeanceTardive]!,
                min: 0,
                max: _delaiRemplacementMax,
                aide: t.a3bis.regles.bornesTardive(
                  min: m(0),
                  max: m(_delaiRemplacementMax),
                ),
              ),
          ],
        ),
        ...entretiens,
        ...paie,
        ...priere,
      ],
    );
  }
}

/// « le 1er », « le 10 » : un jour du mois suivant.
String jourDePaie(int n) => LibellesGroupe.valeurSeule(
  n == 1 ? t.admin.regles.paie.premier : t.admin.regles.paie.jour(n: '$n'),
);

/// La section « Paie des enseignants » (REVENUS-VERITE, exige 4 : un reglage
/// de la direction, A5). Deux lignes, chacune ecrit l'objet entier
/// `{"jourDebut", "jourFin"}` ; les bornes se tiennent l'une l'autre, et le
/// refus du declencheur serveur se dit en mots simples.
List<Widget> _sectionPaie(
  TextTheme textes,
  ({int debut, int fin}) fenetre,
  String Function(String message) erreurEcriture,
  VoidCallback onEcrit,
) {
  final p = t.admin.regles.paie;
  String refus(String message) =>
      message.contains('jour de paie') ? p.refus : erreurEcriture(message);
  Future<void> ecrire(ServiceConfiguration s, int debut, int fin) => s.ecrire(
    clePaieFenetreVersement,
    <String, int>{'jourDebut': debut, 'jourFin': fin},
  );
  String j(int n) => sansAncre(jourDePaie(n));
  return <Widget>[
    Ecart.vXl,
    Text(
      p.section,
      key: const ValueKey<String>('regles-paie'),
      style: textes.titleMedium,
    ),
    Ecart.vSm,
    Text(p.intro, style: textes.bodyMedium),
    Ecart.vMd,
    CarteLignes(
      lignes: <Widget>[
        ConfigLigneEntiere(
          key: const ValueKey<String>('regles-paie-debut'),
          titre: p.debut,
          description: p.debutDetail,
          cle: clePaieFenetreVersement,
          valeur: fenetre.debut,
          min: 1,
          max: fenetre.fin,
          aideBornes: p.bornesDebut(max: j(fenetre.fin)),
          affichage: jourDePaie,
          champValeur: t.admin.regles.champValeur,
          envoyer: t.admin.regles.envoyer,
          valeurInvalide: t.admin.regles.valeurInvalide,
          erreurEcriture: refus,
          onEcrit: onEcrit,
          ecrireValeur: (ServiceConfiguration s, int v) =>
              ecrire(s, v, fenetre.fin),
        ),
        ConfigLigneEntiere(
          key: const ValueKey<String>('regles-paie-fin'),
          titre: p.fin,
          description: p.finDetail,
          cle: clePaieFenetreVersement,
          valeur: fenetre.fin,
          min: fenetre.debut,
          max: 28,
          aideBornes: p.bornesFin(min: j(fenetre.debut)),
          affichage: jourDePaie,
          champValeur: t.admin.regles.champValeur,
          envoyer: t.admin.regles.envoyer,
          valeurInvalide: t.admin.regles.valeurInvalide,
          erreurEcriture: refus,
          onEcrit: onEcrit,
          ecrireValeur: (ServiceConfiguration s, int v) =>
              ecrire(s, fenetre.debut, v),
        ),
      ],
    ),
  ];
}

ValeurConfig? _valeur(List<ValeurConfig> valeurs, String cle) {
  for (final ValeurConfig c in valeurs) {
    if (c.cle == cle) return c;
  }
  return null;
}
