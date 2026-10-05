import 'dart:async';

import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Comme partout ailleurs : le type d'une famille de providers n'est pas exporte
// par l'entree principale de Riverpod 3, il vit dans `misc.dart`.
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../capacites/capacite_indisponible.dart';
import '../domain/enums.dart';
import '../planning/service_planning.dart';
import '../tc_horloge/session_clock_vm.dart';
import 'seance_famille.dart';

/// Les seances du foyer, vues par la famille (contrat K2).
///
/// Un seul point d'entree pour l'Accueil, la Classe, l'Historique et
/// l'observation : quatre lectures separees finiraient par afficher quatre
/// etats differents de la meme seance.
abstract interface class PortSeancesFamille {
  /// La prochaine seance d'un eleve : celle qui se tient, sinon la premiere
  /// dont la fin prevue n'est pas passee. **Une seance annulee a venir reste
  /// la prochaine** : la famille doit apprendre qu'elle n'aura pas lieu.
  Future<SeanceFamille?> prochaine(String eleveId);

  /// La derniere seance passee d'un eleve, annulee ou non tenue comprise.
  Future<SeanceFamille?> derniere(String eleveId);

  /// Les seances du foyer, la plus recente d'abord, filtrees par eleve et par
  /// periode (debut compris dans la periode).
  Future<List<SeanceFamille>> historique({
    String? eleveId,
    DateTimeRange? periode,
  });

  /// Une seance precise. [eleveId] departage deux enfants du foyer inscrits a
  /// la meme seance ; sans lui, la premiere ligne lue est rendue.
  Future<SeanceFamille?> seance(String seanceId, {String? eleveId});

  /// Le planning date d'une classe.
  ///
  /// Leve `CapaciteIndisponible('DB-CRS-03')` tant que le serveur ne rend pas
  /// d'occurrences datees avec heures rendues : le client n'a aucune
  /// bibliotheque de fuseaux et n'invente aucune occurrence.
  Future<List<SeanceFamille>> planning({
    required String groupeId,
    required String eleveId,
    required DateTimeRange periode,
  });

  /// L'instant serveur (`maintenant_serveur()`).
  ///
  /// Leve `CapaciteIndisponible` quand aucune horloge serveur n'est branchee :
  /// **jamais `DateTime.now()` a sa place.**
  Future<DateTime> maintenantServeurUtc();

  /// La seance, relue a la cadence de l'implementation.
  ///
  /// **Un seul flux par seance, aucun minuteur dans un widget.** Une seance
  /// introuvable emet `SeanceIntrouvable` ; une lecture en echec emet son
  /// erreur, et la lecture suivante a lieu comme prevu.
  Stream<SeanceFamille> suivre(String seanceId, {String? eleveId});
}

/// La seance demandee n'est pas (ou plus) visible par l'appelant.
///
/// Ne dit pas pourquoi : une seance d'un autre foyer et une seance supprimee
/// se ressemblent volontairement (aucune fuite).
class SeanceIntrouvable implements Exception {
  /// Cree l'exception.
  const SeanceIntrouvable(this.seanceId);

  /// La seance demandee.
  final String seanceId;

  @override
  String toString() => 'SeanceIntrouvable($seanceId)';
}

/// La cadence de relecture d'une seance suivie.
///
/// Trente secondes, comme l'adaptateur d'horloge : un statut qui change
/// (annulation, ouverture) se voit en moins d'une demi-minute, et une seance
/// suivie coute deux lectures par minute.
const Duration cadenceSeanceFamille = Duration(seconds: 30);

/// Les statuts qui disent qu'une seance est derriere nous, quelle que soit
/// l'heure. Les annulations n'y sont pas : une annulation a venir est encore
/// « la prochaine », pour que la famille l'apprenne.
const Set<StatutSeance> _statutsClos = <StatutSeance>{
  StatutSeance.terminee,
  StatutSeance.enseignantAbsent,
  StatutSeance.eleveAbsent,
  StatutSeance.incidentTechnique,
};

/// La seance famille d'une ligne de `mes_seances_v`, sans horloge serveur.
///
/// `mes_seances_v` ne porte ni `groupe_id` (DB-CRS-13), ni titre ni photo
/// d'enseignant : ces champs restent nuls, jamais devines.
SeanceFamille seanceFamilleDepuis(Seance seance) => SeanceFamille(
  seanceId: seance.id,
  eleveId: seance.eleveId,
  debutUtc: seance.debut.toUtc(),
  finPrevueUtc: seance.fin.toUtc(),
  statutServeur: seance.statut,
  enseignant: EnseignantSeance(
    prenom: seance.enseignantPrenom,
    pays: seance.enseignantPays,
  ),
  minutesInterruption: seance.minutesInterruption,
);

/// La meme seance, avec la fenetre et les heures rendues par l'horloge
/// serveur (`horloge_seance()`).
///
/// La fenetre se deduit de `joinOpensAtUtc` rendu par le serveur, jamais d'une
/// constante client (`pre_vol.dart`, `billet_salle.dart`). Une horloge absente
/// ou incoherente (ouverture apres le debut) laisse la seance inchangee :
/// mieux vaut un horaire incertain qu'une salle annoncee ouverte a tort.
SeanceFamille avecHorlogeServeur(
  SeanceFamille seance,
  SessionClockVM? horloge,
) {
  if (horloge == null) {
    return seance;
  }
  final Duration ouverture = horloge.debutUtc.difference(
    horloge.joinOpensAtUtc,
  );
  if (ouverture.isNegative || horloge.graceApresFin.isNegative) {
    return seance;
  }
  return SeanceFamille(
    seanceId: seance.seanceId,
    eleveId: seance.eleveId,
    groupeId: seance.groupeId,
    debutUtc: seance.debutUtc,
    finPrevueUtc: seance.finPrevueUtc,
    statutServeur: seance.statutServeur,
    fenetre: FenetreSeance(
      debutUtc: horloge.debutUtc,
      finPrevueUtc: horloge.finPrevueUtc,
      fenetreAcces: ouverture,
      graceApresFin: horloge.graceApresFin,
    ),
    heureFoyer: horloge.horlogeUtilisateur,
    // `SessionClockVM` rend deja `null` quand les deux fuseaux coincident.
    heureGroupe: horloge.horlogeContrepartie,
    enseignant: seance.enseignant,
    minutesInterruption: seance.minutesInterruption,
  );
}

/// La prochaine seance de [eleveId] parmi [seances], a l'instant [referenceUtc].
///
/// Pure. Une seance que le serveur declare en cours l'emporte sur l'heure ;
/// sinon la premiere, par debut, dont la fin prevue n'est pas passee et dont
/// le statut n'est pas clos.
SeanceFamille? prochaineParmi(
  Iterable<SeanceFamille> seances, {
  required String eleveId,
  required DateTime referenceUtc,
}) {
  final List<SeanceFamille> retenues =
      seances
          .where(
            (SeanceFamille s) =>
                s.eleveId == eleveId && !_statutsClos.contains(s.statutServeur),
          )
          .toList()
        ..sort(
          (SeanceFamille a, SeanceFamille b) =>
              a.debutUtc.compareTo(b.debutUtc),
        );
  for (final SeanceFamille s in retenues) {
    if (s.statutServeur == StatutSeance.enCours) {
      return s;
    }
  }
  final DateTime reference = referenceUtc.toUtc();
  for (final SeanceFamille s in retenues) {
    if (reference.isBefore(s.finPrevueUtc)) {
      return s;
    }
  }
  return null;
}

/// La derniere seance passee de [eleveId] parmi [seances].
///
/// Pure. Passee : statut clos, ou fin prevue atteinte sans que le serveur la
/// declare encore en cours. Les annulations passees comptent : la famille voit
/// que la derniere seance n'a pas eu lieu.
SeanceFamille? derniereParmi(
  Iterable<SeanceFamille> seances, {
  required String eleveId,
  required DateTime referenceUtc,
}) {
  final DateTime reference = referenceUtc.toUtc();
  SeanceFamille? retenue;
  for (final SeanceFamille s in seances) {
    if (s.eleveId != eleveId) {
      continue;
    }
    final bool passee =
        _statutsClos.contains(s.statutServeur) ||
        (s.statutServeur != StatutSeance.enCours &&
            !reference.isBefore(s.finPrevueUtc));
    if (passee && (retenue == null || s.debutUtc.isAfter(retenue.debutUtc))) {
      retenue = s;
    }
  }
  return retenue;
}

/// L'adaptateur reel, sur les sources existantes.
///
/// - Les seances : `mes_seances_v` par `ServicePlanning.seances()`, relue a
///   chaque appel (une ligne illisible est ecartee par `Seance.lire`).
/// - L'horloge serveur (`horloge_seance()`, `maintenant_serveur()`) :
///   **optionnelle**. Sans elle, [maintenantServeurUtc] leve
///   `CapaciteIndisponible('DB-TRV-07')` et chaque seance est rendue sans
///   fenetre ni heure rendue, donc en `horaireIncertain`. Jamais le double de
///   demonstration a la place.
/// - [horlogeAppareilUtc] ne sert qu'a **choisir** la prochaine et la derniere
///   seance quand l'horloge serveur manque ; il ne decide d'aucun etat
///   affiche.
///
/// La presence ne passe pas par ici : un bloc qui l'affiche lit
/// `presenceSeanceProvider(seanceId)` et la table d'affichage unique de
/// `LignePresence`.
class SeancesFamilleDepuisPlanning implements PortSeancesFamille {
  /// Cree l'adaptateur.
  SeancesFamilleDepuisPlanning({
    required this._lireSeances,
    required this._horlogeAppareilUtc,
    this._lireMaintenantServeur,
    this._lireHorloge,
    this.cadence = cadenceSeanceFamille,
  });

  final Future<List<Seance>> Function() _lireSeances;
  final DateTime Function() _horlogeAppareilUtc;
  final Future<DateTime> Function()? _lireMaintenantServeur;
  final Future<SessionClockVM?> Function(String seanceId)? _lireHorloge;

  /// La cadence de [suivre]. Decidee ici, jamais par un widget.
  final Duration cadence;

  Future<List<SeanceFamille>> _toutes() async => <SeanceFamille>[
    for (final Seance s in await _lireSeances()) seanceFamilleDepuis(s),
  ];

  Future<SeanceFamille> _avecHorloge(SeanceFamille seance) async {
    final Future<SessionClockVM?> Function(String)? lire = _lireHorloge;
    if (lire == null) {
      return seance;
    }
    return avecHorlogeServeur(seance, await lire(seance.seanceId));
  }

  /// La reference de choix : l'horloge serveur si elle repond, sinon celle de
  /// l'appareil. Elle ne sert qu'a choisir une ligne, jamais a dire un etat.
  Future<DateTime> _reference() async {
    if (_lireMaintenantServeur != null) {
      try {
        return (await maintenantServeurUtc()).toUtc();
      } on Object {
        // Le choix de la prochaine seance ne doit pas tomber avec l'horloge :
        // l'etat affiche, lui, restera `horaireIncertain`.
      }
    }
    return _horlogeAppareilUtc().toUtc();
  }

  @override
  Future<SeanceFamille?> prochaine(String eleveId) async {
    final SeanceFamille? retenue = prochaineParmi(
      await _toutes(),
      eleveId: eleveId,
      referenceUtc: await _reference(),
    );
    return retenue == null ? null : _avecHorloge(retenue);
  }

  @override
  Future<SeanceFamille?> derniere(String eleveId) async {
    final SeanceFamille? retenue = derniereParmi(
      await _toutes(),
      eleveId: eleveId,
      referenceUtc: await _reference(),
    );
    return retenue == null ? null : _avecHorloge(retenue);
  }

  @override
  Future<List<SeanceFamille>> historique({
    String? eleveId,
    DateTimeRange? periode,
  }) async {
    final DateTime? debut = periode?.start.toUtc();
    final DateTime? fin = periode?.end.toUtc();
    // ponytail: aucune horloge par ligne d'historique (une requete par seance
    // ferait N appels) ; une seance passee se lit par son statut. Plafond :
    // une ligne sans statut clos reste `horaireIncertain` ; relever alors
    // l'horloge de la seule seance ouverte en detail, via [seance].
    return (await _toutes())
        .where(
          (SeanceFamille s) =>
              (eleveId == null || s.eleveId == eleveId) &&
              (debut == null || !s.debutUtc.isBefore(debut)) &&
              (fin == null || !s.debutUtc.isAfter(fin)),
        )
        .toList()
      ..sort(
        (SeanceFamille a, SeanceFamille b) => b.debutUtc.compareTo(a.debutUtc),
      );
  }

  @override
  Future<SeanceFamille?> seance(String seanceId, {String? eleveId}) async {
    for (final SeanceFamille s in await _toutes()) {
      if (s.seanceId == seanceId && (eleveId == null || s.eleveId == eleveId)) {
        return _avecHorloge(s);
      }
    }
    return null;
  }

  @override
  Future<List<SeanceFamille>> planning({
    required String groupeId,
    required String eleveId,
    required DateTimeRange periode,
  }) => Future<List<SeanceFamille>>.error(
    const CapaciteIndisponible('DB-CRS-03'),
  );

  @override
  Future<DateTime> maintenantServeurUtc() {
    final Future<DateTime> Function()? lire = _lireMaintenantServeur;
    if (lire == null) {
      return Future<DateTime>.error(const CapaciteIndisponible('DB-TRV-07'));
    }
    return lire();
  }

  @override
  Stream<SeanceFamille> suivre(String seanceId, {String? eleveId}) {
    // Une minuterie annulable, et non une boucle `async*` qui attend : le
    // defaut a deja ete mesure sur la presence (`service_presence.dart`), ou un
    // `Future.delayed` continuait de courir apres la sortie d'ecran.
    final StreamController<SeanceFamille> sortie =
        StreamController<SeanceFamille>();
    Timer? minuterie;

    Future<void> lire() async {
      try {
        final SeanceFamille? lue = await seance(seanceId, eleveId: eleveId);
        if (sortie.isClosed) {
          return;
        }
        if (lue == null) {
          sortie.addError(SeanceIntrouvable(seanceId));
        } else {
          sortie.add(lue);
        }
      } on Object catch (erreur, pile) {
        if (!sortie.isClosed) {
          sortie.addError(erreur, pile);
        }
      }
    }

    sortie
      ..onListen = () {
        minuterie = Timer.periodic(cadence, (Timer _) => unawaited(lire()));
        unawaited(lire());
      }
      ..onCancel = () {
        minuterie?.cancel();
        return sortie.close();
      };
    return sortie.stream;
  }
}

/// Le port des seances employe par l'application.
///
/// **Horloge serveur non branchee sur cette base** (dependance DB-TRV-07) :
/// l'adaptateur `HorlogeSeanceSupabase` n'existe que dans le commit `33503fe`,
/// dont la reprise (point P8, phase 0a) n'etait pas commitee quand ce contrat
/// a ete pose. Le coordinateur branche ici `lireMaintenantServeur` et
/// `lireHorloge` sur l'adaptateur reel une fois la reprise integree, et
/// **jamais** sur `HorlogeSeanceDemonstration`. D'ici la, toute seance dont le
/// statut ne tranche pas est en `horaireIncertain`.
final Provider<PortSeancesFamille> portSeancesFamilleProvider =
    Provider<PortSeancesFamille>((Ref ref) {
      final ServicePlanning planning = ref.watch(servicePlanningProvider);
      return SeancesFamilleDepuisPlanning(
        lireSeances: planning.seances,
        horlogeAppareilUtc: () => DateTime.now().toUtc(),
      );
    });

/// La prochaine seance d'un eleve, par `eleveId`.
final FutureProviderFamily<SeanceFamille?, String> prochaineSeanceProvider =
    FutureProvider.family<SeanceFamille?, String>(
      (Ref ref, String eleveId) =>
          ref.watch(portSeancesFamilleProvider).prochaine(eleveId),
    );

/// La derniere seance passee d'un eleve, par `eleveId`.
final FutureProviderFamily<SeanceFamille?, String> derniereSeanceProvider =
    FutureProvider.family<SeanceFamille?, String>(
      (Ref ref, String eleveId) =>
          ref.watch(portSeancesFamilleProvider).derniere(eleveId),
    );
