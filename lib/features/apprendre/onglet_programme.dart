/// ESPACE-APPRENDRE (lot 5) : l'onglet « Programme » de l'espace Apprendre.
///
/// **Un hub, des raccourcis, jamais de doublon** (architecte, 13/11/2026) :
/// l'ecran « Ma progression » de `main` ([CarteSuiviPedagogique] : niveau,
/// etape, sourates, objectifs, matieres, dates, rythme, chemin des etapes) est
/// **reutilise tel quel** dans cet onglet, qui est son lieu d'origine pour
/// l'eleve ; le chemin n'est dessine qu'a un endroit, par ce composant. Aucune
/// carte d'etape n'est redessinee ici.
///
/// Ce que l'onglet ajoute, et que l'ecran de `main` ne dit pas :
///
/// - l'etat « pas encore de classe » quand il n'y a rien a montrer (l'ecran de
///   `main` se tait alors) ;
/// - la section « Dates de l'academie » (evaluations, fermetures, rencontres de
///   recitation) derriere un port ([portDatesEcoleProvider]) qui rend
///   aujourd'hui « rien de publie » : le calendrier est le lot 2. Elle n'existe
///   que si le serveur dit `eleve_voit_dates` : un enfant de 6 a 9 ans ne voit
///   aucune date.
///
/// Chargement, echec (hors ligne compris) et attente de l'entretien de lecture
/// sont ceux de l'ecran de `main`, qui les rend tels que le serveur les dit.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/apprendre/dates_ecole.dart';
import '../../core/apprendre/programme_publie.dart';
import '../../core/capacites/port_progression_famille.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/session/session_controleur.dart';
import '../../core/suivi/ma_progression.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../suivi_foyer/carte_suivi_pedagogique.dart';

/// Les cles des tests.
abstract final class ClesProgramme {
  /// L'etat « pas encore de classe ».
  static const Key vide = ValueKey<String>('programme-vide');

  /// Le programme de l'academie, montre sans etape propre.
  static const Key programmePublie = ValueKey<String>('programme-publie');

  /// La phrase « votre place sera indiquee par votre enseignant ».
  static const Key votrePlace = ValueKey<String>('programme-votre-place');

  /// Aucune etape publiee : la carte n'a que des sourates, ou un niveau.
  static const Key sansEtape = ValueKey<String>('programme-sans-etape');

  /// La section des dates de l'academie.
  static const Key datesEcole = ValueKey<String>('programme-dates-ecole');

  /// L'etat vide des dates de l'academie.
  static const Key datesEcoleVide = ValueKey<String>(
    'programme-dates-ecole-vide',
  );
}

/// L'onglet.
class OngletProgramme extends ConsumerWidget {
  /// Cree l'onglet pour la personne connectee (elle lit pour elle-meme).
  const OngletProgramme({super.key, this.tutoiement = false});

  /// Vrai en Interface guidee : « Ton etape », jamais « Votre etape ».
  final bool tutoiement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? eleveId = ref.watch(sessionProvider).profileId;
    if (eleveId == null || ref.watch(portMaProgressionProvider) == null) {
      return const _Vide();
    }
    final AsyncValue<MaProgression?> lecture = ref.watch(
      maProgressionProvider(eleveId),
    );
    // L'etat « pas encore de classe » ne se dit que si l'ecran de `main` n'a
    // vraiment RIEN a montrer : ni etape, ni sourate, ni jalon, ni niveau
    // declare (ce que la famille avait saisi, que l'ecran lit aussi). Pendant
    // la lecture ou en echec, l'ecran dit lui-meme ce qui se passe.
    final AsyncValue<ProgressionEleve?> famille = ref.watch(
      progressionFamilleLueProvider(eleveId),
    );
    final bool jalon = famille.value?.jalons.isNotEmpty ?? false;
    final bool niveauDeclare =
        famille.value?.niveauHumain?.trim().isNotEmpty ?? false;
    final bool rien =
        lecture.hasValue &&
        lecture.value == null &&
        !famille.isLoading &&
        !jalon &&
        !niveauDeclare;
    final bool dates = lecture.value?.suivi?.eleveVoitDates ?? false;
    // Constat du directeur (14/11/2026) : la carte ne montrait
    // que « sourates de fondation », sans etape ni parcours, et rien ne disait
    // pourquoi. Une lecture sans etape ni cycle le dit, sans ecran vide.
    final MaProgression? lue = lecture.value;
    final bool sansEtape =
        !rien && lue != null && lue.suivi == null && lue.cycle.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (rien) const _Vide(),
        const CarteSuiviPedagogique(),
        if (sansEtape) _ProgrammeSansEtape(eleveId: eleveId),
        // Un enfant de 6 a 9 ans ne voit aucune date : pas de section.
        if (dates) _DatesEcole(eleveId: eleveId),
      ],
    );
  }
}

/// Pas encore de classe : l'etape apparaitra a l'entree en classe.
class _Vide extends StatelessWidget {
  const _Vide();

  @override
  Widget build(BuildContext context) => EmptyState(
    key: ClesProgramme.vide,
    message: t.apprendre.programme.vide,
    icone: AppIcons.chemin,
    registre: RegistreVide.subi,
  );
}

String _jour(DateTime d) => LibellesGroupe.insecable(
  t.suiviPedagogique.dateJour(
    numero: '${d.day}',
    mois: t.commun.dates.mois[d.month - 1],
    annee: '${d.year}',
  ),
);

/// « Dates de l'academie » : les evaluations, fermetures et rencontres de
/// recitation que le calendrier publiera (lot 2). Aujourd'hui, rien n'est
/// publie : l'etat vide le dit, sans date inventee.
class _DatesEcole extends ConsumerWidget {
  const _DatesEcole({required this.eleveId});

  final String eleveId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<DateEcole>> lecture = ref.watch(
      datesEcoleProvider(eleveId),
    );
    final Widget corps;
    if (lecture.hasError && !lecture.hasValue) {
      // Une absence n'est pas un echec : seule une lecture en echec le dit.
      corps = EmptyState(
        message: t.suiviPedagogique.erreur,
        icone: AppIcons.avertissement,
        libelleAction: t.commun.reessayer,
        onAction: () => ref.invalidate(datesEcoleProvider(eleveId)),
      );
    } else if (!lecture.hasValue) {
      corps = const Skeleton.liste(lignes: 2);
    } else if (lecture.requireValue.isEmpty) {
      corps = EmptyState(
        key: ClesProgramme.datesEcoleVide,
        message: t.apprendre.programme.datesEcoleVide,
        icone: AppIcons.calendrier,
        registre: RegistreVide.subi,
      );
    } else {
      final g = t.apprendre.programme.genre;
      corps = GroupeReglages(
        lignes: <LigneRubrique>[
          for (final DateEcole d in lecture.requireValue)
            LigneRubrique(
              icone: AppIcons.calendrier,
              libelle:
                  d.libelle ??
                  switch (d.genre) {
                    GenreDateEcole.evaluation => g.evaluation,
                    GenreDateEcole.fermeture => g.fermeture,
                    GenreDateEcole.rencontre => g.rencontre,
                  },
              legende: _jour(d.jour),
            ),
        ],
      );
    }
    return Column(
      key: ClesProgramme.datesEcole,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SectionHeader(titre: t.apprendre.programme.datesEcole),
        Ecart.vMd,
        corps,
      ],
    );
  }
}

/// Sans etape propre : le programme de l'academie, tel que le serveur le
/// publie, et la phrase qui dit que l'enseignant indiquera la place de la
/// personne. Si le serveur n'en publie aucun (ou s'il n'y a pas de port), la
/// phrase sans etape reste, sans ecran vide.
class _ProgrammeSansEtape extends ConsumerWidget {
  const _ProgrammeSansEtape({required this.eleveId});

  final String eleveId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ProgrammePublie?> lecture = ref.watch(
      programmePublieProvider(eleveId),
    );
    final ProgrammePublie? programme = lecture.value;
    if (lecture.hasError && !lecture.hasValue) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        child: EmptyState(
          message: t.suiviPedagogique.erreur,
          icone: AppIcons.avertissement,
          libelleAction: t.commun.reessayer,
          onAction: () => ref.invalidate(programmePublieProvider(eleveId)),
        ),
      );
    }
    if (!lecture.hasValue && ref.watch(portProgrammePublieProvider) != null) {
      return const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.xl),
        child: Skeleton.liste(lignes: 3),
      );
    }
    if (programme == null || programme.vide) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        child: EmptyState(
          key: ClesProgramme.sansEtape,
          message: t.apprendre.programme.sansEtape,
          icone: AppIcons.chemin,
          registre: RegistreVide.subi,
        ),
      );
    }
    final TextTheme textes = Theme.of(context).textTheme;
    final s = t.suiviPedagogique;
    return Padding(
      key: ClesProgramme.programmePublie,
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SectionHeader(titre: t.apprendre.programme.titreProgramme),
          Ecart.vSm,
          Text(
            t.apprendre.programme.votrePlace,
            key: ClesProgramme.votrePlace,
            style: textes.bodyMedium,
          ),
          for (final CycleProgramme cycle in programme.cycles)
            if (cycle.etapes.isNotEmpty) ...<Widget>[
              Ecart.vXl,
              SectionHeader(titre: cycle.nom),
              Ecart.vMd,
              GroupeReglages(
                lignes: <LigneRubrique>[
                  for (final EtapeProgramme e in cycle.etapes)
                    LigneRubrique(
                      cle: ValueKey<String>('programme-etape-${e.code}'),
                      icone: AppIcons.coran,
                      libelle: e.nom,
                      legende: <String>[
                        ...e.objectifs,
                        if (e.matierePrincipale case final String m)
                          LibellesGroupe.insecable(
                            '${s.matierePrincipale}\u00a0: $m',
                          ),
                        if (e.matiereSecondaire case final String m)
                          LibellesGroupe.insecable(
                            '${s.matiereSecondaire}\u00a0: $m',
                          ),
                        if (e.dureePrevueSemaines != null &&
                            e.dateLimiteSemaines != null)
                          LibellesGroupe.insecable(
                            s.dureesEtape(
                              prevue: '${e.dureePrevueSemaines}',
                              limite: '${e.dateLimiteSemaines}',
                            ),
                          ),
                      ].join('\n'),
                    ),
                ],
              ),
            ],
        ],
      ),
    );
  }
}
