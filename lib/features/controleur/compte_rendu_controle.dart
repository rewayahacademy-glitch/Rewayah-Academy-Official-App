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

/// Le port d'envoi du compte rendu. L'implementation reelle attend BR-1.
abstract interface class EnvoiCompteRendu {
  /// Transmet a l'administration la visite de [seanceId] et ses faits
  /// automatiques, des la sortie de la salle, sans geste du controleur (C2).
  /// Doit etre idempotent cote serveur. Leve une exception si le serveur n'a
  /// pas confirme.
  Future<void> transmettreVisite(String seanceId);

  /// Joint [choix] au rapport de la visite. Leve une exception si le serveur
  /// n'a pas confirme : aucun succes n'est affiche sans reponse.
  Future<void> envoyer(ChoixCompteRendu choix);

  /// Joint [observation] (CTR-03A) au rapport de la visite deja transmis.
  /// Leve une exception si le serveur n'a pas confirme.
  Future<void> envoyerObservation(ObservationControle observation);
}

/// Sans serveur, rien ne part : l'envoi echoue, et l'ecran le dit.
class EnvoiCompteRenduIndisponible implements EnvoiCompteRendu {
  /// Cree le port neutre.
  const EnvoiCompteRenduIndisponible();

  @override
  Future<void> transmettreVisite(String seanceId) async =>
      throw StateError('Aucun serveur branche (BR-1).');

  @override
  Future<void> envoyer(ChoixCompteRendu choix) async =>
      throw StateError('Aucun serveur branche (BR-1).');

  @override
  Future<void> envoyerObservation(ObservationControle observation) async =>
      throw StateError('Aucun serveur branche (BR-1).');
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

/// Transmet la visite a terminer, si elle n'est ni partie ni en route.
///
/// Le port et le notifier sont lus AVANT l'attente : la page peut etre quittee
/// (« Plus tard ») pendant l'envoi, qui continue et met l'etat a jour dans le
/// conteneur racine.
Future<void> transmettreVisiteATerminer(WidgetRef ref) async {
  final CompteRenduATerminer suivi = ref.read(
    compteRenduATerminerProvider.notifier,
  );
  final CompteRenduEnSuspens? visite = ref.read(compteRenduATerminerProvider);
  if (visite == null ||
      visite.transmission == TransmissionVisite.enCours ||
      visite.transmission == TransmissionVisite.transmise) {
    return;
  }
  final EnvoiCompteRendu port = ref.read(envoiCompteRenduProvider);
  suivi.marquer(visite.seanceId, TransmissionVisite.enCours);
  try {
    await port.transmettreVisite(visite.seanceId);
    suivi.marquer(visite.seanceId, TransmissionVisite.transmise);
  } on Object {
    suivi.marquer(visite.seanceId, TransmissionVisite.echec);
  }
}

/// Le port d'envoi ; neutre par defaut.
final Provider<EnvoiCompteRendu> envoiCompteRenduProvider =
    Provider<EnvoiCompteRendu>((Ref _) => const EnvoiCompteRenduIndisponible());

/// Le compte rendu commence et non envoye (« A terminer », doc 08 CTR-01) :
/// la Classe et l'heure de la visite, ou nul. **En memoire seulement** (C12),
/// jamais persiste.
class CompteRenduATerminer extends Notifier<CompteRenduEnSuspens?> {
  @override
  CompteRenduEnSuspens? build() => null;

  /// Marque le compte rendu de la visite comme a terminer. Une reprise de la
  /// meme visite garde l'etat de sa transmission.
  void ouvrir(CompteRenduEnSuspens visite) {
    if (state?.seanceId == visite.seanceId) return;
    state = visite;
  }

  /// Met a jour la transmission de la visite [seanceId], si c'est toujours
  /// elle qui reste a terminer.
  void marquer(String seanceId, TransmissionVisite transmission) {
    final CompteRenduEnSuspens? v = state;
    if (v == null || v.seanceId != seanceId) return;
    state = v.avec(transmission);
  }

  /// Le compte rendu est envoye : plus rien a terminer.
  void terminer() => state = null;
}

/// Une visite dont le compte rendu reste a terminer.
@immutable
class CompteRenduEnSuspens {
  /// Cree l'entree.
  const CompteRenduEnSuspens({
    required this.seanceId,
    required this.classe,
    required this.debut,
    this.transmission,
  });

  /// La seance observee.
  final String seanceId;

  /// La Classe observee.
  final String classe;

  /// Le debut prevu de la seance.
  final DateTime debut;

  /// La transmission automatique de la visite, nulle avant le depart.
  final TransmissionVisite? transmission;

  /// La meme visite, sa transmission changee.
  CompteRenduEnSuspens avec(TransmissionVisite etat) => CompteRenduEnSuspens(
    seanceId: seanceId,
    classe: classe,
    debut: debut,
    transmission: etat,
  );
}

/// Le compte rendu a terminer, ou nul.
final NotifierProvider<CompteRenduATerminer, CompteRenduEnSuspens?>
compteRenduATerminerProvider =
    NotifierProvider<CompteRenduATerminer, CompteRenduEnSuspens?>(
      CompteRenduATerminer.new,
    );
