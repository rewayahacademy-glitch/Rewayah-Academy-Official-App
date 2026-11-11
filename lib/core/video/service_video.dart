import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../observabilite/journal_dev.dart';
import 'video_session_provider.dart';

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
  const EchecSalle(this.motif, {this.detail});

  /// Ce qui a empeche l'entree.
  final MotifRefusSalle motif;

  /// FN-025 : le motif du serveur, seulement s'il l'a donne.
  final DetailRefusSalle? detail;

  @override
  String toString() => 'EchecSalle($motif, ${detail?.motif})';
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

/// L'implementation reelle.
class ServiceVideoSupabase implements ServiceVideo, RetablissementPublication {
  /// Cree le service.
  const ServiceVideoSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<AccesSalle> acces(String seanceId, {String? eleveId}) async {
    final FunctionResponse reponse;
    try {
      reponse = await _client.functions.invoke(
        'create-room-token',
        body: <String, dynamic>{'session_id': seanceId, 'eleve_id': ?eleveId},
      );
    } on FunctionException catch (e) {
      final MotifRefusSalle motif = _motifDe(e.status, e.details);
      throw EchecSalle(
        motif,
        detail: motif == MotifRefusSalle.acces
            ? DetailRefusSalle.depuis(e.details)
            : null,
      );
    } catch (_) {
      throw const EchecSalle(MotifRefusSalle.reseau);
    }

    final Object? corps = reponse.data;
    if (corps is! Map<String, dynamic>) {
      throw const EchecSalle(MotifRefusSalle.reseau);
    }
    return AccesSalle.depuisJson(corps)
        .pourLaDemande(seanceId: seanceId, eleveId: eleveId);
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

/// Le service video employe par l'application.
final Provider<ServiceVideo> serviceVideoProvider = Provider<ServiceVideo>(
  (Ref ref) => ServiceVideoSupabase(Supabase.instance.client),
);
