// Le compte rendu du controleur (CTR-03, CT-4) : les faits automatiques de
// la visite, le choix du controleur et l'envoi.
//
// Decision du directeur du 27/09/2026 (C2) : a la sortie de la salle, la
// visite et ses faits partent AUTOMATIQUEMENT a l'administration
// (`transmettreVisite`, des l'arrivee sur le compte rendu, que le controleur
// reponde, choisisse « Plus tard » ou ferme l'app) ; l'envoi ne fait que
// joindre la reponse du controleur au meme rapport. Aucun interrupteur de
// partage. L'app fermee pendant l'envoi : le serveur doit aussi creer le
// rapport a la sortie annoncee (CT-BR).
//
// Les fournisseurs par defaut sont neutres : aucun fait, et un envoi qui
// echoue honnetement, faute de serveur (K-28). La source reelle (BR-1,
// `14_controleur/CT-BR.md`) se branche dans `main.dart` ; la demonstration
// les surcharge.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mission_controle.dart';
import 'observation_controle.dart';

/// Les faits d'une visite (doc 08 §1.1, C4) : releves par le systeme, jamais
/// saisis par le controleur.
@immutable
class FaitsVisite {
  /// Cree les faits.
  const FaitsVisite({
    required this.debutPrevu,
    required this.finPrevue,
    required this.debutReel,
    required this.participantsAttendus,
    required this.participantsPresents,
    required this.reconnexions,
    this.finReelle,
  });

  /// Debut prevu de la seance.
  final DateTime debutPrevu;

  /// Fin prevue de la seance.
  final DateTime finPrevue;

  /// Debut reel de la seance.
  final DateTime debutReel;

  /// Fin reelle, nulle tant que la seance continue.
  final DateTime? finReelle;

  /// Eleves attendus.
  final int participantsAttendus;

  /// Eleves presents.
  final int participantsPresents;

  /// Reconnexions relevees.
  final int reconnexions;

  /// Le retard au demarrage, en minutes entieres (zero si a l'heure).
  int get minutesDeRetard {
    final int m = debutReel.difference(debutPrevu).inMinutes;
    return m > 0 ? m : 0;
  }
}

/// Les faits de la visite qui vient de finir, ou nuls. **Neutre par
/// defaut** : aucun appel reseau.
final FutureProvider<FaitsVisite?> faitsVisiteProvider =
    FutureProvider<FaitsVisite?>((Ref _) async => null);

/// La reponse du controleur a « Avez-vous quelque chose a signaler ? ».
enum ChoixCompteRendu {
  /// Rien a signaler : envoi en une action.
  rienASignaler,

  /// Ajouter une observation : parcours CTR-03A.
  ajouterObservation,

  /// Signaler un point important : parcours CTR-03A.
  pointImportant,
}

/// L'adresse de CTR-03A a [chemin] pour [choix] : le choix est porte par
/// l'adresse (`?choix=`), pas par `extra` seul, pour qu'un rechargement de
/// la PWA ou un lien direct ne change pas en silence un « point important »
/// en observation ordinaire (revue CT-5).
/// La seance observee voyage aussi par l'adresse (`?seance=`, revue CT-R
/// B1) : l'observation part sur CETTE visite, jamais sur la mission courante.
String adresseObservation(
  String chemin,
  ChoixCompteRendu choix, {
  String? seanceId,
}) => Uri(
  path: chemin,
  queryParameters: <String, String>{'choix': choix.name, 'seance': ?seanceId},
).toString();

/// L'adresse du compte rendu (CTR-03) a [chemin] pour la visite [seanceId]
/// (revue CT-R B1) : la sortie de salle, la reprise depuis le Controle ou
/// l'Historique et un rechargement de la PWA rouvrent CETTE visite.
String adresseCompteRendu(
  String chemin,
  String? seanceId, {
  Map<String, String> autres = const <String, String>{},
}) {
  final Map<String, String> p = <String, String>{
    ...autres,
    'seance': ?seanceId,
  };
  return Uri(path: chemin, queryParameters: p.isEmpty ? null : p).toString();
}

/// Le choix de CTR-03A lu dans l'adresse, puis dans `extra` (appels
/// existants), sinon « Ajouter une observation ».
ChoixCompteRendu choixObservationDepuis(
  Map<String, String> parametres,
  Object? extra,
) {
  final String? nom = parametres['choix'];
  for (final ChoixCompteRendu c in ChoixCompteRendu.values) {
    if (c.name == nom) return c;
  }
  return extra is ChoixCompteRendu
      ? extra
      : ChoixCompteRendu.ajouterObservation;
}

/// Le port d'envoi du compte rendu. L'implementation reelle attend BR-1.
abstract interface class EnvoiCompteRendu {
  /// Transmet a l'administration la visite de [seanceId] et ses faits
  /// automatiques, des la sortie de la salle, sans geste du controleur (C2).
  /// Doit etre idempotent cote serveur. Leve une exception si le serveur n'a
  /// pas confirme.
  Future<void> transmettreVisite(String seanceId);

  /// Joint [choix] au rapport de la visite [seanceId] (jamais au rapport
  /// que le serveur jugerait courant, revue CT-R B1). Leve une exception si
  /// le serveur n'a pas confirme : aucun succes n'est affiche sans reponse.
  Future<void> envoyer(String seanceId, ChoixCompteRendu choix);

  /// Joint [observation] (CTR-03A) au rapport deja transmis de la visite
  /// [seanceId]. Leve une exception si le serveur n'a pas confirme.
  Future<void> envoyerObservation(
    String seanceId,
    ObservationControle observation,
  );
}

/// Sans serveur, rien ne part : l'envoi echoue, et l'ecran le dit.
class EnvoiCompteRenduIndisponible implements EnvoiCompteRendu {
  /// Cree le port neutre.
  const EnvoiCompteRenduIndisponible();

  @override
  Future<void> transmettreVisite(String seanceId) async =>
      throw StateError('Aucun serveur branche (BR-1).');

  @override
  Future<void> envoyer(String seanceId, ChoixCompteRendu choix) async =>
      throw StateError('Aucun serveur branche (BR-1).');

  @override
  Future<void> envoyerObservation(
    String seanceId,
    ObservationControle observation,
  ) async => throw StateError('Aucun serveur branche (BR-1).');
}

/// Ou en est la transmission automatique de la visite.
enum TransmissionVisite {
  /// Partie, sans reponse encore.
  enCours,

  /// Confirmee par le serveur.
  transmise,

  /// Le serveur n'a pas confirme : un nouvel essai est propose.
  echec,
}

/// Transmet la visite a terminer [seanceId], si elle n'est ni partie ni en
/// route.
///
/// Le port et le notifier sont lus AVANT l'attente : la page peut etre quittee
/// (« Plus tard ») pendant l'envoi, qui continue et met l'etat a jour dans le
/// conteneur racine.
Future<void> transmettreVisiteATerminer(WidgetRef ref, String seanceId) async {
  final CompteRenduATerminer suivi = ref.read(
    compteRenduATerminerProvider.notifier,
  );
  final CompteRenduEnSuspens? visite = ref.read(
    compteRenduATerminerProvider,
  )[seanceId];
  if (visite == null ||
      visite.transmission == TransmissionVisite.enCours ||
      visite.transmission == TransmissionVisite.transmise) {
    return;
  }
  final EnvoiCompteRendu port = ref.read(envoiCompteRenduProvider);
  suivi.marquer(seanceId, TransmissionVisite.enCours);
  try {
    await port.transmettreVisite(seanceId);
    suivi.marquer(seanceId, TransmissionVisite.transmise);
  } on Object {
    suivi.marquer(seanceId, TransmissionVisite.echec);
  }
}

/// Le port d'envoi ; neutre par defaut.
final Provider<EnvoiCompteRendu> envoiCompteRenduProvider =
    Provider<EnvoiCompteRendu>((Ref _) => const EnvoiCompteRenduIndisponible());

/// Les comptes rendus commences et non envoyes (« A terminer », doc 08
/// CTR-01), indexes par seance, dans l'ordre d'ouverture. Deux visites a
/// terminer coexistent : aucune n'en remplace une autre (revue CT-R B1).
/// **En memoire seulement** (C12), jamais persiste.
class CompteRenduATerminer extends Notifier<Map<String, CompteRenduEnSuspens>> {
  @override
  Map<String, CompteRenduEnSuspens> build() =>
      const <String, CompteRenduEnSuspens>{};

  /// Ajoute la visite aux comptes rendus a terminer. Une reprise de la meme
  /// visite garde l'etat de sa transmission.
  void ouvrir(CompteRenduEnSuspens visite) {
    if (state.containsKey(visite.seanceId)) return;
    state = <String, CompteRenduEnSuspens>{...state, visite.seanceId: visite};
  }

  /// Met a jour la transmission de la visite [seanceId], si elle reste a
  /// terminer.
  void marquer(String seanceId, TransmissionVisite transmission) {
    final CompteRenduEnSuspens? v = state[seanceId];
    if (v == null) return;
    state = <String, CompteRenduEnSuspens>{
      ...state,
      seanceId: v.avec(transmission),
    };
  }

  /// Le compte rendu de [seanceId] est envoye : il n'est plus a terminer.
  void terminer(String seanceId) => state = <String, CompteRenduEnSuspens>{
    for (final MapEntry<String, CompteRenduEnSuspens> e in state.entries)
      if (e.key != seanceId) e.key: e.value,
  };
}

/// Une visite observee, et l'etat de son compte rendu.
@immutable
class CompteRenduEnSuspens {
  /// Cree l'entree.
  const CompteRenduEnSuspens({
    required this.seanceId,
    required this.classe,
    required this.debut,
    this.missionId,
    this.transmission,
  });

  /// La visite d'une mission, copiee a l'entree en salle (revue CT-R B1).
  CompteRenduEnSuspens.deMission(MissionControle m)
    : this(
        seanceId: m.seanceId,
        classe: m.classe,
        debut: m.debut,
        missionId: m.id,
      );

  /// La seance observee.
  final String seanceId;

  /// La Classe observee.
  final String classe;

  /// Le debut prevu de la seance.
  final DateTime debut;

  /// La mission de la visite : son fil d'echanges (P-CTR-06), nulle si
  /// inconnue.
  final String? missionId;

  /// La transmission automatique de la visite, nulle avant le depart.
  final TransmissionVisite? transmission;

  /// La meme visite, sa transmission changee.
  CompteRenduEnSuspens avec(TransmissionVisite etat) => CompteRenduEnSuspens(
    seanceId: seanceId,
    classe: classe,
    debut: debut,
    missionId: missionId,
    transmission: etat,
  );
}

/// Les comptes rendus a terminer, par seance.
final NotifierProvider<CompteRenduATerminer, Map<String, CompteRenduEnSuspens>>
compteRenduATerminerProvider =
    NotifierProvider<CompteRenduATerminer, Map<String, CompteRenduEnSuspens>>(
      CompteRenduATerminer.new,
    );

/// Les visites ou le controleur est entre en salle, par seance : la mission
/// est copiee a l'entree, car apres la seance elle n'est plus disponible
/// (C1) et le serveur peut deja proposer la suivante (revue CT-R B1).
/// **En memoire seulement** (C12).
class VisitesObservees extends Notifier<Map<String, CompteRenduEnSuspens>> {
  /// Cree le suivi, eventuellement avec des visites deja connues (tests).
  VisitesObservees([this._initiales = const <String, CompteRenduEnSuspens>{}]);

  final Map<String, CompteRenduEnSuspens> _initiales;

  @override
  Map<String, CompteRenduEnSuspens> build() => <String, CompteRenduEnSuspens>{
    ..._initiales,
  };

  /// Note l'entree en salle pour [visite].
  void noter(CompteRenduEnSuspens visite) =>
      state = <String, CompteRenduEnSuspens>{...state, visite.seanceId: visite};
}

/// Les visites observees, par seance.
final NotifierProvider<VisitesObservees, Map<String, CompteRenduEnSuspens>>
visitesObserveesProvider =
    NotifierProvider<VisitesObservees, Map<String, CompteRenduEnSuspens>>(
      VisitesObservees.new,
    );

/// La visite [seanceId] : a terminer, sinon observee ; nulle si inconnue
/// (rechargement, lien direct). Jamais la mission courante.
CompteRenduEnSuspens? visiteDeSeance(WidgetRef ref, String? seanceId) {
  if (seanceId == null) return null;
  return ref.read(compteRenduATerminerProvider)[seanceId] ??
      ref.read(visitesObserveesProvider)[seanceId];
}
