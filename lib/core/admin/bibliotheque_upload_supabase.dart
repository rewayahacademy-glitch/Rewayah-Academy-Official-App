import 'dart:async';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'modeles_bibliotheque_admin.dart';
import 'port_bibliotheque_admin.dart';

/// Adaptateur du flux R2 d'upload; le catalogue et ses mutations restent
/// portes par PortBibliothequeAdmin.
class BibliothequeUploadSupabase {
  BibliothequeUploadSupabase(this._supabase, {http.Client? transport})
    : _transport = transport ?? http.Client(),
      _possedeTransport = transport == null;

  final SupabaseClient _supabase;
  final http.Client _transport;
  final bool _possedeTransport;
  final Map<String, _DepotSigne> _depots = <String, _DepotSigne>{};

  /// Les depots de vignette en cours : leur confirmation et leur annulation
  /// prennent les actions `*_vignette` de la fonction Edge.
  final Set<String> _vignettes = <String>{};

  /// Demande une URL PUT pour un brouillon que l'Edge autorise.
  Future<IntentionUpload> demanderUpload({
    required String supportId,
    required FichierADeposer fichier,
    FinaliteUpload finalite = FinaliteUpload.support,
  }) async {
    if (fichier.sha256.length != 64 ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(fichier.sha256)) {
      throw const DepotImpossible(ErreurUpload.empreinte);
    }
    if (!typeAccepte(fichier, finalite)) {
      throw const DepotImpossible(ErreurUpload.type);
    }
    final bool vignette = finalite == FinaliteUpload.vignette;
    try {
      final FunctionResponse reponse = await _supabase.functions.invoke(
        'bibliotheque-upload',
        body: <String, Object?>{
          'action': vignette ? 'demander_vignette' : 'demander',
          'support_id': supportId,
          // La vignette n'a pas de finalite : l'action la designe, et le nom
          // du fichier du client n'entre jamais dans sa cle.
          if (!vignette) 'finalite': finalite.name,
          'fichier': <String, Object?>{
            // Jamais le nom choisi par la personne : il n'entre ni dans la
            // cle ni en base (un nom arabe faisait refuser le depot).
            if (!vignette) 'nom': nomNeutre(fichier.mime),
            'octets': fichier.octets,
            'mime': fichier.mime,
            'sha256': fichier.sha256,
          },
        },
      );
      final Map<String, dynamic> corps = _objet(reponse.data);
      final String id = _texte(corps, 'upload_id');
      final DateTime expiration = DateTime.parse(_texte(corps, 'expire_le_utc'))
          .toUtc();
      final Uri url = Uri.parse(_texte(corps, 'url'));
      final Object? entetes = corps['en_tetes_exiges'];
      if (url.scheme != 'https' || entetes is! Map) {
        throw const DepotImpossible(ErreurUpload.service);
      }
      final Map<String, String> headers = <String, String>{
        for (final MapEntry<Object?, Object?> entree in entetes.entries)
          if (entree.key is String && entree.value is String)
            entree.key! as String: entree.value! as String,
      };
      if (headers['content-type'] != fichier.mime ||
          headers['content-length'] != '${fichier.octets}') {
        throw const DepotImpossible(ErreurUpload.service);
      }
      _depots[id] = _DepotSigne(url: url, entetes: headers);
      if (vignette) _vignettes.add(id);
      return IntentionUpload(id: id, expireLeUtc: expiration);
    } on FunctionException catch (erreur) {
      // Statut 0 : la fonction n'a pas ete jointe (aucune reponse).
      if (erreur.status == 0) throw const BibliothequeHorsLigne();
      throw DepotImpossible(erreurPourStatut(erreur.status, erreur.details));
    } on ErreurBibliotheque {
      rethrow;
    } on TimeoutException {
      throw const DepotImpossible(ErreurUpload.delai);
    } on FormatException {
      // Une reponse que l'on ne sait pas lire : le service, pas la connexion.
      throw const DepotImpossible(ErreurUpload.service);
    } catch (_) {
      // Aucune reponse du tout : la seule cause qui soit la connexion.
      throw const BibliothequeHorsLigne();
    }
  }

  /// Envoie le contenu signé, puis demande à l'Edge de le vérifier et rattacher.
  Stream<ProgressionUpload> deposer({
    required String uploadId,
    Uint8List? octets,
  }) async* {
    final _DepotSigne? depot = _depots[uploadId];
    if (depot == null || octets == null || octets.isEmpty) {
      // Rien a envoyer (fichier vide) ou intention inconnue : ce n'est pas la
      // connexion.
      yield ProgressionUpload(
        phase: PhaseUpload.echec,
        erreur: depot == null ? ErreurUpload.service : ErreurUpload.type,
      );
      return;
    }
    yield const ProgressionUpload(phase: PhaseUpload.envoi, partie: 0);
    final http.StreamedResponse reponse;
    try {
      final Map<String, String> entetes = Map<String, String>.of(depot.entetes)
        ..remove('content-length');
      final http.Request demande = http.Request('PUT', depot.url)
        ..headers.addAll(entetes)
        ..bodyBytes = octets;
      reponse = await _transport.send(demande);
      await reponse.stream.drain<void>();
    } catch (_) {
      // Le serveur vient de repondre a la demande, et l'envoi n'a recu aucune
      // reponse : le stockage n'accepte pas l'envoi depuis cette adresse
      // (regle d'origine du seau), ou la connexion a coupe pendant l'envoi.
      _depots.remove(uploadId);
      yield const ProgressionUpload(
        phase: PhaseUpload.echec,
        erreur: ErreurUpload.envoi,
      );
      return;
    }
    if (reponse.statusCode < 200 || reponse.statusCode >= 300) {
      // Le stockage a repondu non (adresse signee expiree, signature refusee).
      _depots.remove(uploadId);
      yield const ProgressionUpload(
        phase: PhaseUpload.echec,
        erreur: ErreurUpload.stockage,
      );
      return;
    }
    yield const ProgressionUpload(
      phase: PhaseUpload.enAttenteConfirmation,
      partie: 1,
    );
    yield const ProgressionUpload(phase: PhaseUpload.verification);
    try {
      final FunctionResponse confirmation = await _supabase.functions.invoke(
        'bibliotheque-upload',
        body: <String, Object?>{
          'action': _vignettes.contains(uploadId)
              ? 'confirmer_vignette'
              : 'confirmer',
          'upload_id': uploadId,
        },
      );
      final Object? resultat = confirmation.data;
      if (resultat is! Map || resultat['phase'] != 'pret') {
        _depots.remove(uploadId);
        yield const ProgressionUpload(
          phase: PhaseUpload.echec,
          erreur: ErreurUpload.service,
        );
        return;
      }
      _depots.remove(uploadId);
      _vignettes.remove(uploadId);
      yield const ProgressionUpload(phase: PhaseUpload.pret, partie: 1);
    } on FunctionException catch (erreur) {
      _depots.remove(uploadId);
      yield ProgressionUpload(
        phase: PhaseUpload.echec,
        erreur: erreurPourStatut(erreur.status, erreur.details),
      );
    } on TimeoutException {
      _depots.remove(uploadId);
      yield const ProgressionUpload(
        phase: PhaseUpload.echec,
        erreur: ErreurUpload.delai,
      );
    } catch (_) {
      // Aucune reponse de la fonction : la connexion, et elle seule.
      _depots.remove(uploadId);
      yield const ProgressionUpload(
        phase: PhaseUpload.echec,
        erreur: ErreurUpload.reseau,
      );
    }
  }

  /// Annule l'intention; la clé temporaire demeure inaccessible sans URL valide.
  Future<void> annulerUpload(String uploadId) async {
    try {
      await _supabase.functions.invoke(
        'bibliotheque-upload',
        body: <String, Object?>{
          'action': _vignettes.contains(uploadId)
              ? 'annuler_vignette'
              : 'annuler',
          'upload_id': uploadId,
        },
      );
      _depots.remove(uploadId);
      _vignettes.remove(uploadId);
    } on FunctionException catch (erreur) {
      // Statut 0 : la fonction n'a pas ete jointe (aucune reponse).
      if (erreur.status == 0) throw const BibliothequeHorsLigne();
      throw DepotImpossible(erreurPourStatut(erreur.status, erreur.details));
    } catch (_) {
      throw const BibliothequeHorsLigne();
    }
  }

  /// Ferme le transport HTTP uniquement quand cet adaptateur l'a créé.
  void dispose() {
    if (_possedeTransport) _transport.close();
    _depots.clear();
    _vignettes.clear();
  }

  static Map<String, dynamic> _objet(Object? valeur) {
    if (valeur is Map<String, dynamic>) return valeur;
    throw const DepotImpossible(ErreurUpload.service);
  }

  static String _texte(Map<String, dynamic> objet, String cle) {
    final Object? valeur = objet[cle];
    if (valeur is String && valeur.isNotEmpty) return valeur;
    throw const DepotImpossible(ErreurUpload.service);
  }

  /// La cause d'un echec de depot, selon le statut et le motif rendus par la
  /// fonction Edge. Chaque cause a sa phrase ; « reseau » n'est rendu que pour
  /// le statut 0, quand aucune reponse n'est arrivee.
  static ErreurUpload erreurPourStatut(int statut, Object? details) {
    final String motif = details is Map && details['error'] is String
        ? details['error'] as String
        : '';
    return switch (statut) {
      // 0 : le client n'a recu aucune reponse (`FunctionsFetchException`).
      0 => ErreurUpload.reseau,
      401 => ErreurUpload.session,
      403 => ErreurUpload.refuse,
      422 => ErreurUpload.empreinte,
      400 || 413 => ErreurUpload.type,
      408 || 504 || 546 => ErreurUpload.delai,
      503 when motif.contains('mal reglee') => ErreurUpload.reglage,
      503 when motif.contains('confirmation') => ErreurUpload.nonActive,
      503 when motif.contains('stockage') => ErreurUpload.stockage,
      _ => ErreurUpload.service,
    };
  }

  /// Le nom neutre envoye a la place du nom du fichier : `document.<ext>`.
  static String nomNeutre(String mime) => switch (mime) {
    'application/pdf' => 'document.pdf',
    'image/png' => 'document.png',
    'image/jpeg' => 'document.jpg',
    'image/webp' => 'document.webp',
    'audio/mpeg' => 'document.mp3',
    'audio/mp4' => 'document.m4a',
    'audio/ogg' => 'document.ogg',
    _ => 'document',
  };

  /// Vrai quand le type annonce est de ceux que le depot accepte pour cette
  /// finalite : refuse ici, avec sa vraie phrase, plutot qu'au serveur.
  static bool typeAccepte(FichierADeposer f, FinaliteUpload finalite) {
    const Set<String> images = <String>{
      'image/png',
      'image/jpeg',
      'image/webp',
    };
    const Set<String> audios = <String>{'audio/mpeg', 'audio/mp4', 'audio/ogg'};
    return switch (finalite) {
      FinaliteUpload.vignette => images.contains(f.mime),
      FinaliteUpload.preuve =>
        images.contains(f.mime) || f.mime == 'application/pdf',
      FinaliteUpload.support =>
        images.contains(f.mime) ||
            audios.contains(f.mime) ||
            f.mime == 'application/pdf',
    };
  }
}

class _DepotSigne {
  const _DepotSigne({required this.url, required this.entetes});

  final Uri url;
  final Map<String, String> entetes;
}
