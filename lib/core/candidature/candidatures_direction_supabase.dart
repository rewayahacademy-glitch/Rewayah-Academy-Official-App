// L'adaptateur Supabase de la direction pour les candidatures
// (`PortCandidaturesDirection`), sur les RPC de CAND-L1
// (`20261021200000_cand_l1_socle_candidatures.sql`), redefinies par CAND-L2A2
// (`20261022000100_cand_l2a2_gestes_direction.sql`) :
// - la file (`ADM-20`) : `capacites_candidatures`, `lister_candidatures` ;
// - la candidature (`ADM-21`) : `lire_candidature`, `lire_contact_candidature`,
//   `historique_candidature`, `options_paiement_confirmees` (L6), et une RPC par
//   geste : `demander_complement_candidat`, `admettre_salle_verification`,
//   `refuser_candidat`, `mettre_en_pause_candidat`, `lever_pause_candidat`,
//   `consigner_retrait_candidat`, `rouvrir_candidat`,
//   `definir_responsable_candidat`, `confirmer_moyen_paiement_candidat`,
//   `infirmer_moyen_paiement_candidat`.
//
// Le serveur decide : portee de genre dans le WHERE, refus du genre inconnu,
// pagination de 50, tri, compteurs, controles, transitions permises, journal de
// chaque lecture. L'adaptateur ne filtre rien, ne trie rien et ne recalcule
// rien ; il traduit.
//
// - `42501` dit « non autorise ». Le message distingue les deux refus du
//   serveur : « genre du lecteur inconnu » devient [GenreLecteurInconnu], tout
//   autre devient [PermissionInsuffisante].
// - `PGRST202` / `42883` : la fonction n'est pas encore versee ; la lecture est
//   alors une capacite indisponible (`CAND-BR-nn`), pas une panne a reessayer.
// - Les refus metier d'un geste, d'une lecture de dossier arrivent **dans la
//   reponse** (`{"erreur": "..."}`), jamais en exception de base : le serveur les
//   rend pour ne laisser aucune ecriture. Ils deviennent des exceptions typees
//   ([RefusGeste], [CandidatureHorsPortee], [CandidatureIntrouvable]).
// - Un geste sans reponse (reseau coupe, serveur muet) devient [GesteNonConfirme] :
//   il est possible qu'il ne soit pas parvenu, et rejouer la meme cle
//   d'idempotence ne le fait pas deux fois.
// - Toute autre erreur d'une lecture remonte telle quelle : l'ecran dit « n'a pas
//   pu etre lue » avec « Reessayer », sans affirmer une cause.
//
// Les filtres envoyes sont exactement les cles que le serveur connait
// (`type`, `etape`, `etat`, `issue`, `enPause`, `paiement`, `paysResidence`,
// `recherche`) : une cle inconnue serait refusee (`22023`). Une cle sans valeur
// n'est pas envoyee.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../capacites/capacite_indisponible.dart';
import '../capacites/permission_insuffisante.dart';
import 'gestes_candidature.dart';
import 'modeles_candidature.dart';
import 'modeles_candidature_detail.dart';
import 'modeles_candidatures_direction.dart';
import 'port_candidatures_direction.dart';

/// La direction servie par Supabase.
class CandidaturesDirectionSupabase implements PortCandidaturesDirection {
  /// Cree l'adaptateur sur le client de l'application.
  const CandidaturesDirectionSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<CapacitesCandidatures> capacites() async {
    final Object? brut = await _appel('capacites_candidatures');
    if (brut is! Map) {
      throw const FormatException('Capacites attendues.');
    }
    return CapacitesCandidatures.depuisJson(Map<String, dynamic>.from(brut));
  }

  @override
  Future<PageCandidatures> lister({
    required FiltreCandidatures filtre,
    required TriCandidatures tri,
    required int page,
  }) async {
    final Object? brut = await _appel('lister_candidatures', <String, dynamic>{
      'p_filtre': filtreEnJson(filtre),
      'p_tri': tri.valeurSql,
      'p_page': page,
    });
    return PageCandidatures.depuisJson(brut);
  }

  @override
  Future<DetailCandidature> lire(String candidatureId) async {
    final Map<String, dynamic> brut = _objet(
      await _appel('lire_candidature', <String, dynamic>{
        'p_id': candidatureId,
      }, dependanceDetailCandidature),
    );
    _refusDeLecture(brut);
    return DetailCandidature.depuisJson(brut);
  }

  @override
  Future<ContactCandidat> lireContact(String candidatureId) async {
    final Map<String, dynamic> brut = _objet(
      await _appel('lire_contact_candidature', <String, dynamic>{
        'p_id': candidatureId,
      }, dependanceDetailCandidature),
    );
    _refusDeLecture(brut);
    return ContactCandidat.depuisJson(brut);
  }

  @override
  Future<PageHistorique> historique(
    String candidatureId, {
    int? curseur,
  }) async {
    final Map<String, dynamic> brut = _objet(
      await _appel('historique_candidature', <String, dynamic>{
        'p_id': candidatureId,
        'p_curseur': ?curseur,
      }, dependanceHistoriqueCandidature),
    );
    _refusDeLecture(brut);
    return PageHistorique.depuisJson(brut);
  }

  @override
  Future<List<ResponsablePossible>> responsablesPossibles(
    String candidatureId,
  ) =>
      // Aucune RPC ne sert encore cette liste (`PORTS` : `responsablesPossibles`,
      // L2, a ajouter) : la capacite est indisponible, jamais une liste inventee.
      Future<List<ResponsablePossible>>.error(
        const CapaciteIndisponible(dependanceGestesCandidature),
      );

  @override
  Future<MoyensConfirmes> moyensConfirmes(String paysVersement) async {
    final Map<String, dynamic> brut = _objet(
      await _appel('options_paiement_confirmees', <String, dynamic>{
        'p_pays': paysVersement,
      }, dependanceGestesCandidature),
    );
    final Object? lignes = brut['lignes'];
    bool virement = false;
    final Map<String, OperateurPaiement> parCode =
        <String, OperateurPaiement>{};
    if (lignes is List) {
      for (final Object? ligne in lignes) {
        if (ligne is! Map) {
          continue;
        }
        if (ligne['methode'] == 'virement_bancaire') {
          virement = true;
        } else if (ligne['methode'] == 'mobile_money' &&
            ligne['operateur'] is String) {
          final String code = ligne['operateur'] as String;
          final Object? nom = ligne['operateurNom'];
          parCode.putIfAbsent(
            code,
            () => OperateurPaiement(
              code: code,
              nom: nom is String && nom.trim().isNotEmpty ? nom.trim() : code,
            ),
          );
        }
      }
    }
    return MoyensConfirmes(
      virementBancaire: virement,
      operateurs: List<OperateurPaiement>.unmodifiable(parCode.values),
    );
  }

  @override
  Future<ResultatGeste> geste(DemandeGeste demande) async {
    final (String fonction, Map<String, dynamic> params) = parametresDuGeste(
      demande,
    );
    final Object? brut;
    try {
      brut = await _appel(fonction, params, dependanceGestesCandidature);
    } on PermissionInsuffisante {
      rethrow;
    } on GenreLecteurInconnu {
      rethrow;
    } on CapaciteIndisponible {
      rethrow;
    } on PostgrestException {
      rethrow;
    } on FormatException {
      rethrow;
    } on Exception {
      // Pas de reponse : le geste est non confirme (D5).
      throw const GesteNonConfirme();
    }
    final Map<String, dynamic> corps = _objet(brut);
    _refusDeGeste(corps);
    return ResultatGeste.depuisJson(corps);
  }

  Future<Object?> _appel(
    String fonction, [
    Map<String, dynamic>? params,
    String dependance = dependanceFileCandidatures,
  ]) async {
    try {
      return await _client.rpc<Object?>(fonction, params: params);
    } on PostgrestException catch (e) {
      if (e.code == '42501') {
        if (e.message.contains('genre du lecteur inconnu')) {
          throw const GenreLecteurInconnu();
        }
        throw PermissionInsuffisante(fonction);
      }
      // PGRST202 : fonction absente du cache de schema ; 42883 : fonction
      // inconnue de la base. Le lot serveur n'est pas encore verse.
      if (e.code == 'PGRST202' || e.code == '42883') {
        throw CapaciteIndisponible(dependance);
      }
      rethrow;
    }
  }
}

/// La RPC d'un geste et ses parametres, tels que CAND-L2A2 les lit. Public pour
/// que le test prouve la forme envoyee : la version attendue et la cle
/// d'idempotence partent avec chaque geste.
(String, Map<String, dynamic>) parametresDuGeste(DemandeGeste d) {
  String jour(DateTime j) =>
      '${j.year.toString().padLeft(4, '0')}-'
      '${j.month.toString().padLeft(2, '0')}-'
      '${j.day.toString().padLeft(2, '0')}';
  final Map<String, dynamic> commun = <String, dynamic>{
    'p_id': d.candidatureId,
    'p_version_attendue': d.versionAttendue,
    'p_cle_idempotence': d.cleIdempotence,
  };
  switch (d.geste) {
    case GesteCandidature.demanderComplement:
    case GesteCandidature.cloreComplement:
      return (
        'demander_complement_candidat',
        <String, dynamic>{
          ...commun,
          'p_elements': d.elements,
          'p_motif': d.motif,
        },
      );
    case GesteCandidature.admettreVerifications:
      return ('admettre_salle_verification', commun);
    case GesteCandidature.refuser:
      return (
        'refuser_candidat',
        <String, dynamic>{...commun, 'p_motif': d.motif, 'p_modele': d.modele},
      );
    case GesteCandidature.mettreEnPause:
      return (
        'mettre_en_pause_candidat',
        <String, dynamic>{
          ...commun,
          'p_motif': d.motif,
          'p_modele': d.modele,
          'p_reprise_le': d.repriseLe == null ? null : jour(d.repriseLe!),
        },
      );
    case GesteCandidature.leverPause:
      return (
        'lever_pause_candidat',
        <String, dynamic>{...commun, 'p_motif': d.motif},
      );
    case GesteCandidature.consignerRetrait:
      return (
        'consigner_retrait_candidat',
        <String, dynamic>{
          ...commun,
          'p_canal': d.canal?.valeurSql,
          'p_demande_recue_le': d.demandeRecueLe == null
              ? null
              : jour(d.demandeRecueLe!),
          'p_motif': d.motif,
        },
      );
    case GesteCandidature.rouvrir:
      return (
        'rouvrir_candidat',
        <String, dynamic>{...commun, 'p_motif': d.motif},
      );
    case GesteCandidature.definirResponsable:
      return (
        'definir_responsable_candidat',
        <String, dynamic>{...commun, 'p_responsable_id': d.responsableId},
      );
    case GesteCandidature.confirmerMoyenPaiement:
      return (
        'confirmer_moyen_paiement_candidat',
        <String, dynamic>{
          ...commun,
          'p_methode': d.moyen?.methode,
          'p_operateur': d.moyen?.operateur,
        },
      );
    case GesteCandidature.infirmerMoyenPaiement:
      return (
        'infirmer_moyen_paiement_candidat',
        <String, dynamic>{
          ...commun,
          'p_methode': d.moyen?.methode,
          'p_operateur': d.moyen?.operateur,
          'p_motif': d.motif,
        },
      );
  }
}

/// Le filtre tel que `lister_candidatures` le lit : seules les cles posees,
/// avec les valeurs ecrites en base. Public pour que le test prouve la forme
/// envoyee.
Map<String, Object> filtreEnJson(FiltreCandidatures filtre) => <String, Object>{
  if (filtre.rechercheEnvoyee.isNotEmpty) 'recherche': filtre.rechercheEnvoyee,
  if (filtre.etape != null) 'etape': filtre.etape!.valeurSql,
  if (filtre.etat != null) 'etat': filtre.etat!.valeurSql,
  if (filtre.issue != null) 'issue': filtre.issue!.valeurSql,
  if (filtre.enPause != null) 'enPause': filtre.enPause!,
  if (filtre.paiement != null) 'paiement': filtre.paiement!.valeurSql,
  if (filtre.paysResidence != null) 'paysResidence': filtre.paysResidence!,
};

/// Les deux refus d'une lecture de dossier, rendus dans la reponse.
void _refusDeLecture(Map<String, dynamic> brut) {
  switch (brut['erreur']) {
    case null:
      return;
    case 'absente':
      throw const CandidatureIntrouvable();
    case 'hors_portee':
      throw const CandidatureHorsPortee();
    default:
      throw FormatException('Refus inconnu : ${brut['erreur']}');
  }
}

/// Traduit un refus rendu par le serveur pour un geste en exception typee.
void _refusDeGeste(Map<String, dynamic> brut) {
  final Object? erreur = brut['erreur'];
  if (erreur == null) {
    return;
  }
  switch (erreur) {
    case 'absente':
      throw const CandidatureIntrouvable();
    case 'hors_portee':
      throw const CandidatureHorsPortee();
    case 'conflit_candidature':
      throw ConflitGeste(
        brut['versionCourante'] is int ? brut['versionCourante'] as int : null,
      );
    case 'transition_interdite':
      throw GesteInterdit(
        etape: EtapeCandidature.depuisSql(brut['etape']),
        etat: EtatCandidature.depuisSql(brut['etat']),
        issue: IssueCandidature.depuisSql(brut['issue']),
        enPause: brut['enPause'] == true,
        parLaPause: brut['raison'] == 'pause',
      );
    case 'controles_non_satisfaits':
      throw ControlesNonSatisfaits(<({String nom, String? cause})>[
        if (brut['controles'] is List)
          for (final Object? c in brut['controles'] as List)
            if (c is Map && c['nom'] is String)
              (
                nom: c['nom'] as String,
                cause: c['cause'] is String ? c['cause'] as String : null,
              ),
      ]);
    case 'motif_requis':
      throw const MotifRequis();
    case 'modele_requis':
      throw const ModeleRequis();
    case 'modele_inconnu':
      throw const ModeleInconnu();
    case 'elements_requis':
      throw const ElementsRequis();
    case 'elements_invalides':
      throw const ElementsInvalides();
    case 'aucun_complement':
      throw const AucunComplement();
    case 'date_reprise_invalide':
      throw const RepriseInvalide();
    case 'date_demande_invalide':
      throw const DateDemandeInvalide();
    case 'moyen_non_confirmable':
      throw MoyenNonConfirmable(
        nonDeclare: brut['cause'] == 'non_declare',
        etatLigne: brut['etatLigne'] is String
            ? brut['etatLigne'] as String
            : null,
      );
    case 'moyen_non_declare':
      throw const MoyenNonDeclare();
    case 'responsable_invalide':
      throw const ResponsableInvalide();
    case 'cle_idempotence_reutilisee':
      throw const CleReutilisee();
    default:
      throw FormatException('Refus inconnu : $erreur');
  }
}

Map<String, dynamic> _objet(Object? v) {
  if (v is! Map) {
    throw const FormatException('Objet attendu.');
  }
  return Map<String, dynamic>.from(v);
}
