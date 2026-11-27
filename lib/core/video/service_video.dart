import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../observabilite/journal_dev.dart';
import 'appareil_salle.dart';
import 'diagnostic_transport.dart';
import 'libelle_appareil.dart';
import 'second_appareil.dart';
import 'video_session_provider.dart';

/// ENTREE-ROBUSTE (directeur, 12/11/2026, retours sur la salle, point 11 :
/// « l'eleve suivant a du mal a rejoindre ») : le temps au-dela duquel la
/// demande du jeton (`create-room-token`) est tenue pour perdue. Sans lui, une
/// reponse qui n'arrive jamais laissait la salle sur « connexion » sans fin.
/// 15 secondes : bien plus qu'un demarrage a froid de la fonction, bien moins
/// que la patience d'un eleve devant un ecran qui attend. Un delai depasse
/// n'est pas un refus : la salle propose « Reessayer » ([EchecSalle.delaiDepasse]).
const Duration delaiJetonSalle = Duration(seconds: 15);

/// Pourquoi une salle refuse d'ouvrir.
///
/// Le backend ne distingue pas pour qui n'a pas droit a la salle : il repond
/// « acces a la salle refuse » sans dire si la seance existe, si elle a
/// commence, ou si l'appelant est simplement en avance -- un appelant qui
/// tente une salle qui n'est pas la sienne n'a pas a l'apprendre. A qui y a
/// droit, il ajoute un motif (FN-025, [DetailRefusSalle]). Cette enumeration ne sert donc qu'a separer ce
/// que le client PEUT distinguer sans rien reveler : un refus, une panne de
/// configuration, et une coupure reseau.
enum MotifRefusSalle {
  /// La video n'est pas encore branchee sur ce deploiement.
  videoNonConfiguree,

  /// Le fournisseur retenu n'a pas de trousseau utilisable.
  fournisseurIndisponible,

  /// L'acces est refuse : pas inscrit, hors fenetre, ou seance close.
  acces,

  /// Le reseau ou le backend n'a pas repondu.
  reseau,

  /// SALLE-SECOND-APPAREIL (23/11/2026) : le meme compte est deja dans la
  /// classe sur un autre appareil, et celui-ci a refuse l'entree.
  passageRefuse,

  /// SALLE-SECOND-APPAREIL : l'autre appareil, vivant, n'a pas repondu a
  /// temps. Se reessaye.
  passageSansReponse,

  /// SALLE-SECOND-APPAREIL : la personne a renonce a entrer depuis cet
  /// appareil.
  passageAnnule,
}

/// FN-025 : pourquoi la salle est fermee, quand le serveur le dit.
///
/// Le serveur ne le dit qu'a qui pouvait entrer (participant, enseignant
/// effectif, tuteur d'un eleve inscrit : `motif_refus_salle`) ; a tout autre
/// appelant, le refus reste generique et aucun detail n'arrive ici.
enum MotifServeurSalle {
  /// Avant l'ouverture de la salle.
  pasEncoreOuverte,

  /// La seance est close, ou la salle a ferme apres la fin.
  terminee,

  /// La seance est annulee.
  annulee,

  /// Le titulaire n'est pas entre a temps : la seance de ce jour lui est
  /// retiree (absence automatique, A3). Il reste l'enseignant de la classe.
  accesPerdu,

  /// A3-bis (03/11/2026) : apres une prise de remplacement, l'enseignant de
  /// la classe est entre le premier ; le remplacant ne peut plus entrer.
  titulaireEntre,

  /// A3-bis (03/11/2026) : le remplacant qui a pris la classe est entre le
  /// premier ; le titulaire ne peut plus entrer.
  remplacantEntre,

  /// SNT (03/11/2026) : aucun enseignant n'a rejoint la salle a temps, la
  /// seance est reportee ; la salle ne s'ouvre plus pour personne.
  seanceReportee,

  /// SITUATIONS-GRAVES (11/11/2026) : cette seance n'est pas celle de
  /// l'appelant (la meme reponse qu'elle existe ou non).
  nonInscrit,

  /// SITUATIONS-GRAVES : l'acces de l'eleve a cette classe est suspendu.
  /// Aucun detail d'argent n'arrive ici.
  accesSuspendu,

  /// SITUATIONS-GRAVES : l'enseignant a fait sortir cet eleve de la seance.
  sorti,

  /// SITUATIONS-GRAVES : le temps d'observation du tuteur est epuise.
  observationTerminee,

  /// SITUATIONS-GRAVES : le compte n'est plus valide.
  compteInvalide,
}

/// FN-025 : le motif d'un refus et les heures du serveur qui l'accompagnent.
@immutable
class DetailRefusSalle {
  /// Cree le detail.
  const DetailRefusSalle({
    required this.motif,
    this.finUtc,
    this.ouvertureUtc,
    this.graceMinutes,
  });

  /// Lit le corps du 403 de `create-room-token`, ou `null` sans motif connu
  /// (refus generique, ou forme inattendue) : rien n'est invente.
  static DetailRefusSalle? depuis(Object? details) {
    if (details is! Map) return null;
    final MotifServeurSalle? motif = switch (details['motif']) {
      'pas_encore_ouverte' => MotifServeurSalle.pasEncoreOuverte,
      'terminee' => MotifServeurSalle.terminee,
      'annulee' => MotifServeurSalle.annulee,
      'acces_perdu' => MotifServeurSalle.accesPerdu,
      'titulaire_entre' => MotifServeurSalle.titulaireEntre,
      'remplacant_entre' => MotifServeurSalle.remplacantEntre,
      'seance_reportee' => MotifServeurSalle.seanceReportee,
      'non_inscrit' => MotifServeurSalle.nonInscrit,
      'acces_suspendu' => MotifServeurSalle.accesSuspendu,
      'sorti' => MotifServeurSalle.sorti,
      'observation_terminee' => MotifServeurSalle.observationTerminee,
      'compte_invalide' => MotifServeurSalle.compteInvalide,
      _ => null,
    };
    if (motif == null) return null;
    DateTime? instant(Object? v) =>
        v is String ? DateTime.tryParse(v)?.toUtc() : null;
    final Object? grace = details['grace_minutes'];
    return DetailRefusSalle(
      motif: motif,
      finUtc: instant(details['fin_utc']),
      ouvertureUtc: instant(details['ouverture_utc']),
      graceMinutes: grace is int && grace >= 0 ? grace : null,
    );
  }

  /// Le motif.
  final MotifServeurSalle motif;

  /// La fin prevue de la seance, du serveur.
  final DateTime? finUtc;

  /// L'ouverture de la salle, du serveur.
  final DateTime? ouvertureUtc;

  /// La grace apres la fin (`grace_after_end_minutes`), du serveur.
  final int? graceMinutes;

  @override
  bool operator ==(Object other) =>
      other is DetailRefusSalle &&
      other.motif == motif &&
      other.finUtc == finUtc &&
      other.ouvertureUtc == ouvertureUtc &&
      other.graceMinutes == graceMinutes;

  @override
  int get hashCode => Object.hash(motif, finUtc, ouvertureUtc, graceMinutes);
}

/// L'echec d'une entree en salle.
class EchecSalle implements Exception {
  /// Cree un echec.
  const EchecSalle(this.motif, {this.detail, this.delaiDepasse = false});

  /// Ce qui a empeche l'entree.
  final MotifRefusSalle motif;

  /// FN-025 : le motif du serveur, seulement s'il l'a donne.
  final DetailRefusSalle? detail;

  /// ENTREE-ROBUSTE : vrai quand le serveur n'a pas repondu dans
  /// [delaiJetonSalle] (motif `reseau`). Distingue, pour la supervision, un
  /// delai depasse d'une panne qui repond et d'un refus.
  final bool delaiDepasse;

  @override
  String toString() =>
      'EchecSalle($motif, ${detail?.motif}${delaiDepasse ? ', delai' : ''})';
}

/// L'acces a la salle, l'inscription des temoins, et la sortie volontaire.
///
/// **Les deux portes de temoin ne remplacent pas `acces`, elles la precedent.**
/// `autoriser_jeton_video()` lit l'appartenance dans `session_participants` et
/// n'accepte jamais de la recevoir en parametre (0010) : un temoin qui n'y est
/// pas inscrit obtient « non inscrit a cette seance », quel que soit son role.
/// C'est precisement ce qui arrivait au controleur et au tuteur jusqu'a la
/// migration 0012 -- personne ne les inscrivait.
abstract interface class ServiceVideo {
  /// Demande au backend le droit d'entrer dans une seance.
  ///
  /// Avec [eleveId], un tuteur demande le jeton de son enfant, qui rejoint la
  /// salle depuis l'appareil du tuteur (D6) : la base verifie le foyer et
  /// l'inscription a la seance, et ne rend que le role eleve.
  Future<AccesSalle> acces(String seanceId, {String? eleveId});

  /// Inscrit l'appelant comme **observateur invisible** d'une seance en cours.
  ///
  /// Reservee au controle qualite, et journalisee nommement : identite, seance,
  /// horodatage (ADR-011). La base refuse une seance close, une seance pas
  /// encore commencee, et une seance dont l'appelant est deja partie prenante.
  Future<void> observerEnControle(String seanceId);

  /// Annonce un depart **volontaire**, avant de se deconnecter.
  ///
  /// C'est la seule ecriture de presence confiee au client, et c'est elle qui
  /// empeche `sortie` de se confondre avec `deconnectee` : les deux produisent
  /// le meme evenement `left` cote LiveKit, seule la source les distingue.
  Future<void> annoncerSortie(String seanceId);
}

/// MICRO-AVANT-ENSEIGNANT (directeur, 11/11/2026) : le filet. Un eleve dont
/// le droit de publier attend l'enseignant, et qui voit son enseignant dans
/// la salle, demande au serveur de lui rendre ce droit.
///
/// **Le client ne decide rien** : le serveur reverifie que l'appelant a droit
/// a cette seance et que l'enseignant est bien dans la salle LiveKit, puis
/// change lui-meme les droits du participant. Le resultat arrive par LiveKit
/// (changement de permissions), pas par la reponse de cet appel.
///
/// Interface a part, comme `MotifEchecSalle` : seul le service qui parle au
/// serveur reel l'implemente.
abstract interface class RetablissementPublication {
  /// Demande au serveur de rendre le droit de publier de [acces]. Sans effet
  /// si l'acces ne dit pas pour quelle seance il a ete emis.
  Future<void> retablirPublication(AccesSalle acces);
}

/// FERMETURE-SALLE (directeur, 11/11/2026, journal D-018) : un participant
/// demande au serveur de relire la regle dans sa salle (enseignant parti
/// depuis le delai de grace, seance finie).
///
/// **Le client ne decide rien** : le serveur relit lui-meme qui est dans la
/// salle chez LiveKit et la seance en base, puis ferme les micros des eleves
/// ou la salle. Le resultat arrive par LiveKit (changement de permissions,
/// deconnexion), pas par la reponse de cet appel.
///
/// Interface a part, comme [RetablissementPublication].
abstract interface class VerificationSalle {
  /// Demande la verification pour la seance de [acces]. Rend le temps qui
  /// reste avant l'echeance, en secondes, quand un delai court ; `null`
  /// sinon (rien en cours, porte fermee, acces sans seance).
  Future<int?> verifierSalle(AccesSalle acces);
}

/// L'appel de la fonction `create-room-token` (injecte pour les tests).
typedef AppelJeton = Future<FunctionResponse> Function(
  Map<String, dynamic> corps,
);

/// SALLE-SECOND-APPAREIL : combien de temps le second appareil attend avant de
/// relire l'etat de sa demande.
const Duration pasAttentePassage = Duration(seconds: 2);

/// SALLE-SECOND-APPAREIL : au bout de ce temps sans lecture possible, la
/// connexion est tenue pour perdue (la demande reste posee cote serveur).
const Duration patienceHorsLignePassage = Duration(seconds: 20);

/// SALLE-SECOND-APPAREIL : garde-fou du client. Le serveur tranche a 45 s ;
/// au-dela, une attente qui ne finit pas est dite « sans reponse ».
const Duration attenteMaxPassage = Duration(seconds: 60);

/// L'implementation reelle.
class ServiceVideoSupabase
    implements ServiceVideo, RetablissementPublication, VerificationSalle {
  /// Cree le service.
  ServiceVideoSupabase(
    this._client, {
    this._port,
    this._pilote,
    this._appel,
    String Function()? appareil,
    String Function()? libelle,
    this.pas = pasAttentePassage,
  }) : _appareil = appareil ?? identifiantAppareilSalle,
       _libelle = libelle ?? libelleAppareilCourant;

  final SupabaseClient _client;
  final PortSecondAppareil? _port;
  final PilotePassage? _pilote;
  final AppelJeton? _appel;
  final String Function() _appareil;
  final String Function() _libelle;

  /// Le pas de la relecture de la demande (reglable pour les tests).
  final Duration pas;

  Future<FunctionResponse> _demanderJeton(Map<String, dynamic> corps) =>
      (_appel ?? _appelReel)(corps);

  Future<FunctionResponse> _appelReel(Map<String, dynamic> corps) =>
      _client.functions.invoke('create-room-token', body: corps);

  @override
  Future<AccesSalle> acces(String seanceId, {String? eleveId}) async {
    String? demandeId;
    try {
      while (true) {
        final Object attendu = await _essai(seanceId, eleveId, demandeId);
        if (attendu is AccesSalle) {
          return attendu;
        }
        // Un autre appareil du meme profil est dans la salle.
        final _PassageDemande p = attendu as _PassageDemande;
        demandeId = p.demandeId;
        if (p.decision == 'refuse') {
          throw const EchecSalle(MotifRefusSalle.passageRefuse);
        }
        if (p.decision == 'sans_reponse') {
          throw const EchecSalle(MotifRefusSalle.passageSansReponse);
        }
        final EtatPassage etat = await _attendre(demandeId, p.libelleAutre);
        switch (etat) {
          case EtatPassage.refuse:
            throw const EchecSalle(MotifRefusSalle.passageRefuse);
          case EtatPassage.sansReponse:
            throw const EchecSalle(MotifRefusSalle.passageSansReponse);
          case EtatPassage.annule:
            throw const EchecSalle(MotifRefusSalle.passageAnnule);
          case EtatPassage.accepte || EtatPassage.libre:
            // Le jeton se redemande avec la meme demande : le serveur la
            // reverifie (demandeur, appareil, profil, seance).
            continue;
          case EtatPassage.enAttente || EtatPassage.inconnu:
            throw const EchecSalle(MotifRefusSalle.passageSansReponse);
        }
      }
    } finally {
      final PilotePassage? pilote = _pilote;
      if (pilote != null && pilote.phase != PhasePassage.ancienSilencieux) {
        pilote.effacer();
      }
    }
  }

  /// Un essai de jeton : l'acces, ou une demande a attendre.
  Future<Object> _essai(
    String seanceId,
    String? eleveId,
    String? demandeId,
  ) async {
    final FunctionResponse reponse;
    try {
      reponse = await _demanderJeton(<String, dynamic>{
        'session_id': seanceId,
        'eleve_id': ?eleveId,
        'appareil_id': _appareil(),
        'appareil_libelle': _libelle(),
        'demande_id': ?demandeId,
      }).timeout(delaiJetonSalle);
    } on FunctionException catch (e) {
      // SALLE-SECOND-APPAREIL : 409, un autre appareil tient la place.
      final Object? details = e.details;
      if (e.status == 409 && details is Map && details['passage'] is String) {
        return _PassageDemande(
          decision: details['passage'] as String,
          demandeId: details['demande_id'] is String
              ? details['demande_id'] as String
              : demandeId,
          libelleAutre: details['appareil_libelle'] is String
              ? details['appareil_libelle'] as String
              : '',
        );
      }
      final MotifRefusSalle motif = _motifDe(e.status, e.details);
      // ENTREE-ROBUSTE : un refus est une reponse normale du serveur, rien a
      // superviser ; une panne qui repond (5xx), si.
      if (motif != MotifRefusSalle.acces) {
        signalerJetonImpossible(nature: 'statut', statut: e.status);
      }
      throw EchecSalle(
        motif,
        detail: motif == MotifRefusSalle.acces
            ? DetailRefusSalle.depuis(e.details)
            : null,
      );
    } on TimeoutException {
      signalerJetonImpossible(nature: 'delai');
      throw const EchecSalle(MotifRefusSalle.reseau, delaiDepasse: true);
    } catch (e) {
      signalerJetonImpossible(nature: e.runtimeType.toString());
      throw const EchecSalle(MotifRefusSalle.reseau);
    }

    final Object? corps = reponse.data;
    if (corps is! Map<String, dynamic>) {
      throw const EchecSalle(MotifRefusSalle.reseau);
    }
    if (corps['note_passage'] == 'ancien_silencieux') {
      // L'autre appareil ne repondait plus : le dire apres l'entree.
      _pilote?.publier(
        const PassageSalle(phase: PhasePassage.ancienSilencieux),
      );
    }
    return AccesSalle.depuisJson(corps)
        .pourLaDemande(seanceId: seanceId, eleveId: eleveId);
  }

  /// Attend la decision du premier appareil, en le disant a l'ecran. Une
  /// coupure de connexion ne fait pas perdre la demande : elle se dit, puis
  /// l'attente reprend ; trop longue, elle devient un echec de reseau.
  Future<EtatPassage> _attendre(String? demandeId, String libelleAutre) async {
    final PortSecondAppareil? port = _port;
    if (demandeId == null || port == null) {
      return EtatPassage.sansReponse;
    }
    _pilote?.commencer();
    PassageSalle dit(PhasePassage phase) =>
        PassageSalle(phase: phase, libelleAutre: libelleAutre);
    _pilote?.publier(dit(PhasePassage.attente));
    final Stopwatch depuis = Stopwatch()..start();
    DateTime? coupeDepuis;
    while (true) {
      if (_pilote?.annulationDemandee ?? false) {
        try {
          await port.annuler(demandeId);
        } on Object catch (e) {
          journalDev('annulation du passage impossible : $e');
        }
        return EtatPassage.annule;
      }
      try {
        final EtatPassage etat = await port.etat(demandeId);
        coupeDepuis = null;
        _pilote?.publier(dit(PhasePassage.attente));
        if (etat != EtatPassage.enAttente && etat != EtatPassage.inconnu) {
          return etat;
        }
      } on PostgrestException catch (e) {
        // Une demande refusee par la base n'est pas une coupure.
        if (e.code == '42501') {
          throw const EchecSalle(MotifRefusSalle.acces);
        }
        coupeDepuis ??= DateTime.now();
        _pilote?.publier(dit(PhasePassage.horsLigne));
      } on Object {
        coupeDepuis ??= DateTime.now();
        _pilote?.publier(dit(PhasePassage.horsLigne));
      }
      if (coupeDepuis != null &&
          DateTime.now().difference(coupeDepuis) > patienceHorsLignePassage) {
        throw const EchecSalle(MotifRefusSalle.reseau);
      }
      if (depuis.elapsed > attenteMaxPassage) {
        return EtatPassage.sansReponse;
      }
      await Future<void>.delayed(pas);
    }
  }

  @override
  Future<void> retablirPublication(AccesSalle acces) async {
    final String? seanceId = acces.seanceId;
    if (seanceId == null) {
      return;
    }
    await _client.functions.invoke(
      'create-room-token',
      body: <String, dynamic>{
        'session_id': seanceId,
        'eleve_id': ?acces.eleveId,
        'action': 'retablir_publication',
      },
    );
  }

  @override
  Future<int?> verifierSalle(AccesSalle acces) async {
    final String? seanceId = acces.seanceId;
    if (seanceId == null) {
      return null;
    }
    try {
      final FunctionResponse reponse = await _client.functions.invoke(
        'create-room-token',
        body: <String, dynamic>{
          'session_id': seanceId,
          'eleve_id': ?acces.eleveId,
          'action': 'verifier_salle',
        },
      );
      return resteAvantEcheance(reponse.data);
    } on FunctionException catch (e) {
      // 403 : la porte de la seance est fermee (seance finie). Le serveur a
      // relu la salle ; s'il l'a fermee, LiveKit le dira. Ce n'est pas une
      // panne.
      if (e.status == 403) {
        return null;
      }
      rethrow;
    }
  }

  /// Traduit le refus du backend, sans jamais inventer une raison qu'il n'a
  /// pas donnee.
  MotifRefusSalle _motifDe(int statut, Object? details) {
    if (statut == 503) {
      final String message = details is Map<String, dynamic>
          ? (details['error'] as String? ?? '')
          : details?.toString() ?? '';
      return message.contains('non configuree')
          ? MotifRefusSalle.videoNonConfiguree
          : MotifRefusSalle.fournisseurIndisponible;
    }
    if (statut == 401 || statut == 403) {
      return MotifRefusSalle.acces;
    }
    return MotifRefusSalle.reseau;
  }

  // Les deux inscriptions ne rattrapent aucune erreur, contrairement a la
  // sortie : un echec ici doit remonter a l'ecran, qui dira que la visite n'a
  // pas eu lieu. Continuer vers la salle apres un refus n'y ferait entrer
  // personne et remplacerait un message clair par l'impasse d'acces.
  @override
  Future<void> observerEnControle(String seanceId) => _client.rpc<void>(
    'rejoindre_observation',
    params: <String, dynamic>{'p_session_id': seanceId},
  );

  @override
  Future<void> annoncerSortie(String seanceId) async {
    // Un echec ici ne doit jamais empecher de quitter la salle : au pire la
    // sortie sera lue comme une deconnexion, ce qui est desagreable mais pas
    // faux. Retenir l'usager dans une salle parce qu'une ecriture a echoue le
    // serait, lui.
    try {
      await _client.rpc<void>(
        'quitter_salle',
        params: <String, dynamic>{'p_session_id': seanceId},
      );
    } catch (e) {
      journalDev('annonce de sortie impossible : $e');
    }
  }
}

/// FERMETURE-SALLE : lit `reste_s` dans la reponse de `verifier_salle`, ou
/// `null` (absent, forme inattendue, valeur negative) : rien n'est invente.
int? resteAvantEcheance(Object? corps) {
  if (corps is! Map) return null;
  final Object? reste = corps['reste_s'];
  return reste is int && reste >= 0 ? reste : null;
}

/// Ce que le serveur repond quand un autre appareil du meme profil tient la
/// place : attendre sa decision (ou la lire, deja prise).
class _PassageDemande {
  const _PassageDemande({
    required this.decision,
    required this.demandeId,
    required this.libelleAutre,
  });

  final String decision;
  final String? demandeId;
  final String libelleAutre;
}

/// Le service video employe par l'application.
final Provider<ServiceVideo> serviceVideoProvider = Provider<ServiceVideo>(
  (Ref ref) => ServiceVideoSupabase(
    Supabase.instance.client,
    port: ref.read(portSecondAppareilProvider),
    pilote: ref.read(passageSalleProvider.notifier),
  ),
);
