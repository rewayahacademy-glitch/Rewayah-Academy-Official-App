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

  /// Demande une URL PUT pour un brouillon que l'Edge autorise.
  Future<IntentionUpload> demanderUpload({
    required String supportId,
    required FichierADeposer fichier,
    FinaliteUpload finalite = FinaliteUpload.support,
  }) async {
    if (fichier.sha256.length != 64 ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(fichier.sha256)) {
      throw const BibliothequeHorsLigne();
    }
    try {
      final FunctionResponse reponse = await _supabase.functions.invoke(
        'bibliotheque-upload',
        body: <String, Object?>{
          'action': 'demander',
          'support_id': supportId,
          'finalite': finalite.name,
          'fichier': <String, Object?>{
            'nom': fichier.nom,
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
        throw const BibliothequeHorsLigne();
      }
      final Map<String, String> headers = <String, String>{
        for (final MapEntry<Object?, Object?> entree in entetes.entries)
          if (entree.key is String && entree.value is String)
            entree.key! as String: entree.value! as String,
      };
      if (headers['content-type'] != fichier.mime ||
          headers['content-length'] != '${fichier.octets}') {
        throw const BibliothequeHorsLigne();
      }
      _depots[id] = _DepotSigne(url: url, entetes: headers);
      return IntentionUpload(id: id, expireLeUtc: expiration);
    } on FunctionException catch (erreur) {
      throw _traduire(erreur.status, erreur.details);
    } on ErreurBibliotheque {
      rethrow;
    } catch (_) {
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
      yield const ProgressionUpload(
        phase: PhaseUpload.echec,
        erreur: ErreurUpload.reseau,
      );
      return;
    }
    yield const ProgressionUpload(phase: PhaseUpload.envoi, partie: 0);
    try {
      final Map<String, String> entetes = Map<String, String>.of(depot.entetes)
        ..remove('content-length');
      final http.Request demande = http.Request('PUT', depot.url)
        ..headers.addAll(entetes)
        ..bodyBytes = octets;
      final http.StreamedResponse reponse = await _transport.send(demande);
      await reponse.stream.drain<void>();
      if (reponse.statusCode < 200 || reponse.statusCode >= 300) {
        yield const ProgressionUpload(
          phase: PhaseUpload.echec,
          erreur: ErreurUpload.reseau,
        );
        return;
      }
      yield const ProgressionUpload(
        phase: PhaseUpload.enAttenteConfirmation,
        partie: 1,
      );
      yield const ProgressionUpload(phase: PhaseUpload.verification);
      final FunctionResponse confirmation = await _supabase.functions.invoke(
        'bibliotheque-upload',
        body: <String, Object?>{'action': 'confirmer', 'upload_id': uploadId},
      );
      final Map<String, dynamic> resultat = _objet(confirmation.data);
      if (resultat['phase'] != 'pret') {
        throw const BibliothequeHorsLigne();
      }
      _depots.remove(uploadId);
      yield const ProgressionUpload(phase: PhaseUpload.pret, partie: 1);
    } on FunctionException catch (erreur) {
      _depots.remove(uploadId);
      yield ProgressionUpload(
        phase: PhaseUpload.echec,
        erreur: _erreurUpload(erreur.status, erreur.details),
      );
    } catch (_) {
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
        body: <String, Object?>{'action': 'annuler', 'upload_id': uploadId},
      );
      _depots.remove(uploadId);
    } on FunctionException catch (erreur) {
      throw _traduire(erreur.status, erreur.details);
    } catch (_) {
      throw const BibliothequeHorsLigne();
    }
  }

  /// Ferme le transport HTTP uniquement quand cet adaptateur l'a créé.
  void dispose() {
    if (_possedeTransport) _transport.close();
    _depots.clear();
  }

  static Map<String, dynamic> _objet(Object? valeur) {
    if (valeur is Map<String, dynamic>) return valeur;
    throw const BibliothequeHorsLigne();
  }

  static String _texte(Map<String, dynamic> objet, String cle) {
    final Object? valeur = objet[cle];
    if (valeur is String && valeur.isNotEmpty) return valeur;
    throw const BibliothequeHorsLigne();
  }

  static ErreurBibliotheque _traduire(int statut, Object? details) {
    if (statut == 401 || statut == 403) return const BibliothequeNonAutorisee();
    return const BibliothequeHorsLigne();
  }

  static ErreurUpload _erreurUpload(int statut, Object? details) {
    if (statut == 401 || statut == 403) return ErreurUpload.refuse;
    if (statut == 422) return ErreurUpload.empreinte;
    if (statut == 400) return ErreurUpload.type;
    return ErreurUpload.reseau;
  }
}

class _DepotSigne {
  const _DepotSigne({required this.url, required this.entetes});

  final Uri url;
  final Map<String, String> entetes;
}
