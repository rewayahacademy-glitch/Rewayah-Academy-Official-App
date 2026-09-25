import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/presence/service_presence.dart';
import '../../core/router/routes.dart';
import '../../core/seance_famille/seance_famille.dart';
import '../../core/tc_observation/activation_observation.dart';
import '../../core/tc_observation/disponibilite_observation.dart';
import '../../core/tc_observation/echec_observation.dart';
import '../../core/tc_observation/guardian_observation_policy.dart';
import '../../core/tc_observation/port_politique_observation.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/skeleton.dart';

/// « 2 visites disponibles », « 1 visite disponible ».
String visitesDisponibles(int nombre) => nombre == 1
    ? t.classe.observation.uneVisite
    : t.classe.observation.visites(nombre: nombre);

/// « 1/2 visite restante » dit en toutes lettres, accorde, et « Aucune visite
/// restante pour cette seance » a zero (decision du directeur, 1 bis-5).
String visitesRestantes(int nombre) => switch (nombre) {
  <= 0 => t.classe.observation.restanteAucune,
  1 => t.classe.observation.restanteUne,
  _ => t.classe.observation.restantes(nombre: nombre),
};

/// La duree d'une visite, « 2 min », « 1 min 20 s », « 40 s ». Rendue telle
/// que le serveur la donne : jamais arrondie a la hausse.
String dureeVisite(Duration duree) {
  final int total = duree.inSeconds < 0 ? 0 : duree.inSeconds;
  final int minutes = total ~/ Duration.secondsPerMinute;
  final int secondes = total % Duration.secondsPerMinute;
  if (minutes == 0) {
    return t.classe.observation.secondes(secondes: secondes);
  }
  if (secondes == 0) {
    return t.classe.observation.minutes(minutes: minutes);
  }
  return t.classe.observation.minutesSecondes(
    minutes: minutes,
    secondes: secondes,
  );
}

/// Ce que la famille lit quand l'observation n'est pas proposee.
String texteMotif(MotifIndisponibilite motif, {required String prenom}) {
  final m = t.classe.observation.motif;
  return switch (motif) {
    MotifIndisponibilite.visitesEpuisees => m.visitesEpuisees,
    MotifIndisponibilite.tempsEpuise => m.tempsEpuise,
    MotifIndisponibilite.seanceNonCommencee => m.seanceNonCommencee,
    MotifIndisponibilite.seanceTerminee => m.seanceTerminee,
    MotifIndisponibilite.seanceNonTenue => m.seanceNonTenue,
    MotifIndisponibilite.horsFenetre => m.horsFenetre,
    MotifIndisponibilite.observationDesactivee => m.observationDesactivee,
    MotifIndisponibilite.lienAbsent => m.lienAbsent,
    MotifIndisponibilite.enfantAbsent => m.enfantAbsent(prenom: prenom),
    MotifIndisponibilite.presenceEnVerification => m.presenceEnVerification(
      prenom: prenom,
    ),
    MotifIndisponibilite.visiteDejaOuverte => m.visiteDejaOuverte,
    MotifIndisponibilite.garantieServeurAbsente => m.garantieServeurAbsente,
    MotifIndisponibilite.reseau => m.reseau,
    MotifIndisponibilite.capaciteAbsente => m.capaciteAbsente,
  };
}

/// Les etats de seance pour lesquels le budget d'observation merite d'etre
/// lu : la salle est (peut-etre) ouverte. Avant, apres, ou quand la seance
/// n'a pas lieu, le motif se dit sans appeler le serveur.
bool budgetUtile(EtatSeanceFamille etat) => switch (etat) {
  EtatSeanceFamille.salleOuverte ||
  EtatSeanceFamille.enDirect ||
  EtatSeanceFamille.prolongee ||
  EtatSeanceFamille.horaireIncertain => true,
  EtatSeanceFamille.aVenir ||
  EtatSeanceFamille.terminee ||
  EtatSeanceFamille.annulee ||
  EtatSeanceFamille.annuleeTardive ||
  EtatSeanceFamille.nonTenue ||
  EtatSeanceFamille.reportee => false,
};

/// Le bloc « Observer la seance » de la carte de classe (maquette M1).
///
/// **Construit depuis `DisponibiliteObservation` (contrat K4), et rien
/// d'autre** : le CTA n'existe que si une visite peut commencer, sinon une
/// phrase dit pourquoi (un bouton qui ne peut pas aboutir n'est pas rendu).
///
/// - Interrupteur `OBSERVATION_TUTEUR_REELLE` ferme (production, point P3) :
///   **aucune porte serveur n'est appelee**, ni budget, ni politique ; la
///   phrase dit que l'observation n'est pas encore ouverte.
/// - Ouvert : budget (`budget_observation`, lecture sans effet) seulement
///   quand la salle est ou peut etre ouverte, politique de la classe si elle
///   se lit, presence de l'eleve **indicative**.
///
/// « Observer la seance » et « Comment ca marche ? » ouvrent l'ecran du lot O
/// (`/tc/observation/:seanceId`), avec `?classe=` et `?eleve=` pour le retour
/// a la classe, et `?aide=1` pour l'explication seule. Aucun compteur ne
/// demarre ici.
class BlocObservationClasse extends ConsumerWidget {
  /// Cree le bloc.
  const BlocObservationClasse({
    required this.classeId,
    required this.eleveId,
    required this.prenom,
    required this.seance,
    required this.etat,
    required this.presence,
    super.key,
  });

  /// La classe.
  final String classeId;

  /// L'eleve concerne.
  final String eleveId;

  /// Son prenom.
  final String prenom;

  /// La seance a observer.
  final SeanceFamille seance;

  /// Son etat affiche (K2).
  final EtatSeanceFamille etat;

  /// La presence lue de l'eleve, **indicative** ; `null` : non lue.
  final EtatPresence? presence;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool activation = ref.watch(observationTuteurReelleProvider);
    if (!activation) {
      return _Motif(
        texte: texteMotif(
          MotifIndisponibilite.garantieServeurAbsente,
          prenom: prenom,
        ),
      );
    }

    final String seanceId = seance.seanceId;
    final AsyncValue<BudgetObservation>? budget = budgetUtile(etat)
        ? ref.watch(budgetObservationProvider(seanceId))
        : null;
    if (budget != null && budget.isLoading && !budget.hasValue) {
      return const Skeleton.texte(lignes: 2);
    }
    final GuardianObservationPolicy? politique = ref
        .watch(politiqueObservationProvider(classeId))
        .value;

    final Object? erreur = budget?.error;
    final DisponibiliteObservation disponibilite = erreur is EchecObservation
        ? ObservationIndisponible(motifDepuisEchec(erreur))
        : disponibiliteObservation(
            budget: budget?.value,
            politique: politique,
            presenceEnfant: presence,
            activationReelle: true,
            etatSeance: etat,
          );

    switch (disponibilite) {
      case ObservationPossible():
        return _Possible(
          disponibilite: disponibilite,
          onObserver: () => _ouvrir(context, aide: false),
          onCommentCaMarche: () => _ouvrir(context, aide: true),
        );
      case ObservationIndisponible(
        :final MotifIndisponibilite motif,
        visitesRestantes: final int? restantes,
      ):
        return _Motif(
          texte: texteMotif(motif, prenom: prenom),
          visites: restantes == null ? null : visitesRestantes(restantes),
          onReessayer: motif == MotifIndisponibilite.reseau
              ? () => ref.invalidate(budgetObservationProvider(seanceId))
              : null,
        );
    }
  }

  /// Ouvre l'entree d'observation (lot O) par son adresse : le navigateur la
  /// garde (retour, rechargement), et l'ecran d'entree revient a la classe
  /// par `?classe=` et `?eleve=`, filtres par lui (identifiants seulement).
  void _ouvrir(BuildContext context, {required bool aide}) {
    GoRouter.of(context).go(
      Uri(
        path: Routes.tcObservation(seance.seanceId),
        queryParameters: <String, String>{
          'classe': classeId,
          'eleve': eleveId,
          if (aide) 'aide': '1',
        },
      ).toString(),
    );
  }
}

/// Une visite peut commencer : le CTA dominant, les visites et leur duree,
/// puis « Comment ca marche ? » (M1).
class _Possible extends StatelessWidget {
  const _Possible({
    required this.disponibilite,
    required this.onObserver,
    required this.onCommentCaMarche,
  });

  final ObservationPossible disponibilite;
  final VoidCallback onObserver;
  final VoidCallback onCommentCaMarche;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ActionPrincipale(
          libelle: t.classe.observer,
          fleche: true,
          onPress: onObserver,
        ),
        Ecart.vMd,
        Text(
          t.classe.observation.resume(
            visites: visitesDisponibles(disponibilite.visitesRestantes),
            duree: dureeVisite(disponibilite.dureeProchaineVisite),
          ),
          textAlign: TextAlign.center,
          style: palette.inkMuted.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
        Center(
          child: LienFleche(
            libelle: t.classe.observation.commentCaMarche,
            fleche: false,
            icone: AppIcons.info,
            onPress: onCommentCaMarche,
          ),
        ),
      ],
    );
  }
}

/// Aucune visite ne peut commencer : une phrase, les visites restantes quand
/// elles sont connues, et « Reessayer » pour le seul motif reseau.
class _Motif extends StatelessWidget {
  const _Motif({required this.texte, this.visites, this.onReessayer});

  final String texte;
  final String? visites;
  final VoidCallback? onReessayer;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle discret = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    return Semantics(
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(texte, textAlign: TextAlign.center, style: discret),
          if (visites != null) ...<Widget>[
            Ecart.vXs,
            Text(visites!, textAlign: TextAlign.center, style: discret),
          ],
          if (onReessayer != null)
            Center(
              child: ActionPrincipale(
                libelle: t.commun.reessayer,
                onPress: onReessayer,
                niveau: NiveauAction.tertiaire,
                pleineLargeur: false,
              ),
            ),
        ],
      ),
    );
  }
}
