// L'accord de publication de l'enseignant (CAND-PHOTO, 06/11/2026, demande du
// directeur) : « Votre nom, votre photo et votre pays peuvent apparaitre sur
// le site public de Rewayah Academy ». Separe de la candidature, facultatif,
// donne puis retirable. Le serveur
// (`20261110330000_cand_photo.sql`) enregistre l'accord avec la version du
// texte, la date et le nom du compte comme signature : l'application n'envoie
// ni le nom ni la date.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../capacites/capacite_indisponible.dart';
import '../capacites/permission_insuffisante.dart';

/// La dependance serveur, pour la trace et les tests : jamais affichee.
const String dependanceAccordPublication = 'CAND-PHOTO';

/// L'etat de l'accord de la personne connectee.
class AccordPublication {
  /// Cree l'etat.
  const AccordPublication({
    required this.versionCourante,
    required this.enCours,
    this.nomCompte,
    this.version,
    this.nomSigne,
    this.accepteLe,
  });

  /// Lit la reponse du serveur. Une forme inattendue est une
  /// [FormatException].
  factory AccordPublication.depuisJson(Map<String, dynamic> j) {
    final Object? courante = j['versionCourante'];
    final Object? enCours = j['enCours'];
    if (enCours is! bool || (courante != null && courante is! String)) {
      throw const FormatException('accord attendu : versionCourante, enCours');
    }
    final Object? le = j['accepteLe'];
    return AccordPublication(
      versionCourante: courante as String?,
      enCours: enCours,
      nomCompte: j['nomCompte'] as String?,
      version: j['version'] as String?,
      nomSigne: j['nomSigne'] as String?,
      accepteLe: le is String ? DateTime.tryParse(le)?.toLocal() : null,
    );
  }

  /// La version du texte publiee ; `null` si aucun texte n'est publie.
  final String? versionCourante;

  /// Vrai quand un accord est en cours.
  final bool enCours;

  /// Le nom du compte, qui vaut signature (lecture seule).
  final String? nomCompte;

  /// La version acceptee.
  final String? version;

  /// Le nom signe (celui du compte, relu au serveur).
  final String? nomSigne;

  /// La date de l'accord.
  final DateTime? accepteLe;
}

/// Un refus du serveur, sans ecriture.
final class AccordPublicationRefuse implements Exception {
  /// Cree le refus.
  const AccordPublicationRefuse(this.code);

  /// `version_perimee`, `texte_indisponible`, `nom_absent` (trace, jamais
  /// affiche tel quel).
  final String code;
}

/// Le port de l'accord de publication.
abstract interface class PortAccordPublication {
  /// L'etat de l'accord.
  Future<AccordPublication> lire();

  /// Donne l'accord a la [version] affichee.
  Future<AccordPublication> accepter(String version);

  /// Retire l'accord en cours.
  Future<AccordPublication> retirer();
}

/// L'adaptateur Supabase.
class AccordPublicationSupabase implements PortAccordPublication {
  /// Cree l'adaptateur sur le client de l'application.
  AccordPublicationSupabase(SupabaseClient client)
    : _appel = ((String nom, [Map<String, dynamic>? params]) =>
          client.rpc<Object?>(nom, params: params));

  /// Cree l'adaptateur sur un appel injecte (tests).
  AccordPublicationSupabase.avecAppel(this._appel);

  final Future<Object?> Function(String nom, [Map<String, dynamic>? params])
  _appel;

  @override
  Future<AccordPublication> lire() => _executer('mon_accord_publication');

  @override
  Future<AccordPublication> accepter(String version) => _executer(
    'accepter_accord_publication',
    <String, dynamic>{'p_version': version},
  );

  @override
  Future<AccordPublication> retirer() =>
      _executer('retirer_accord_publication');

  Future<AccordPublication> _executer(
    String nom, [
    Map<String, dynamic>? params,
  ]) async {
    final Object? brut;
    try {
      brut = await _appel(nom, params);
    } on PostgrestException catch (e) {
      if (e.code == '42501') throw PermissionInsuffisante(nom);
      if (e.code == 'PGRST202' || e.code == '42883') {
        throw const CapaciteIndisponible(dependanceAccordPublication);
      }
      rethrow;
    }
    if (brut is! Map) throw const FormatException('objet attendu');
    final Map<String, dynamic> j = Map<String, dynamic>.from(brut);
    final Object? erreur = j['erreur'];
    if (erreur is String) throw AccordPublicationRefuse(erreur);
    return AccordPublication.depuisJson(j);
  }
}

/// Le port : absent avant le branchement serveur.
final Provider<PortAccordPublication?> portAccordPublicationProvider =
    Provider<PortAccordPublication?>((Ref _) => null);

/// L'etat de l'accord. Sans port : [CapaciteIndisponible].
final FutureProvider<AccordPublication> accordPublicationProvider =
    FutureProvider.autoDispose<AccordPublication>((Ref ref) {
      final PortAccordPublication? port = ref.watch(
        portAccordPublicationProvider,
      );
      if (port == null) {
        return Future<AccordPublication>.error(
          const CapaciteIndisponible(dependanceAccordPublication),
        );
      }
      return port.lire();
    }, retry: (int _, Object _) => null);
