/// RECRUT-ECRANS : la signature probante du contrat (contrats C-15 et C-16 de
/// la feuille de liaison, 10/10/2026).
///
/// La version, l'empreinte et le texte viennent du serveur
/// ([ContratCourant]) : l'application ne porte plus de constante de version
/// pour cet ecran. L'empreinte [ContratCourant.sha256] ne sert qu'a un
/// controle d'affichage (le texte montre doit hasher a l'empreinte annoncee,
/// sinon la signature n'est pas proposee) ; aucune empreinte de reference
/// n'est calculee cote Flutter. L'horodatage d'une [Signature] est celui du
/// serveur, jamais celui de l'appareil.
///
/// Aucun branchement serveur ici : le port vaut `null` en production.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../capacites/capacite_indisponible.dart';
import '../domain/enums.dart';

/// Le contrat en vigueur pour une sorte.
@immutable
class ContratCourant {
  /// Cree le contrat courant.
  const ContratCourant({
    required this.kind,
    required this.version,
    required this.texte,
    required this.sha256,
  });

  /// La sorte de contrat.
  final SorteContrat kind;

  /// La version courante.
  final String version;

  /// Le texte valide, servi tel quel.
  final String texte;

  /// L'empreinte annoncee du texte.
  final String sha256;
}

/// Une signature enregistree.
@immutable
class Signature {
  /// Cree une signature.
  const Signature({
    required this.kind,
    required this.version,
    required this.sha256,
    required this.nomSaisi,
    required this.signeLe,
  });

  /// La sorte signee.
  final SorteContrat kind;

  /// La version signee.
  final String version;

  /// L'empreinte du texte signe.
  final String sha256;

  /// Le nom tape par le signataire.
  final String nomSaisi;

  /// Horodatage serveur.
  final DateTime signeLe;
}

/// Les refus de la signature.
sealed class ErreurSignature implements Exception {
  const ErreurSignature();
}

/// Le texte a change pendant la lecture : recharger [versionCourante].
final class VersionPerimee extends ErreurSignature {
  /// Cree l'erreur.
  const VersionPerimee(this.versionCourante);

  /// La version a relire.
  final String versionCourante;
}

/// Le nom est vide (apres trim).
final class NomVide extends ErreurSignature {
  /// Cree l'erreur.
  const NomVide();
}

/// Le nom depasse la longueur admise.
final class NomTropLong extends ErreurSignature {
  /// Cree l'erreur.
  const NomTropLong();
}

/// Aucune session.
final class NonConnecte extends ErreurSignature {
  /// Cree l'erreur.
  const NonConnecte();
}

/// Aucune reponse : hors ligne.
final class HorsLigneSignature extends ErreurSignature {
  /// Cree l'erreur.
  const HorsLigneSignature();
}

/// Le serveur n'a aucun contrat courant pour cette sorte.
final class ContratIntrouvable extends ErreurSignature {
  /// Cree l'erreur.
  const ContratIntrouvable();
}

/// Le serveur ne conserve pas encore de copie documentaire a telecharger.
final class CopieSigneeIndisponible extends ErreurSignature {
  /// Cree l'erreur.
  const CopieSigneeIndisponible();
}

/// Le port.
abstract interface class PortSignatureContrat {
  /// Le contrat courant.
  Future<ContratCourant> contratCourant(SorteContrat kind);

  /// Signe. Idempotent : une signature existante pour (profil, kind, version)
  /// est renvoyee sans erreur.
  Future<Signature> signerContrat(
    SorteContrat kind,
    String version,
    String nomSaisi,
  );

  /// La derniere signature, `null` si jamais signe.
  Future<Signature?> maSignature(SorteContrat kind);

  /// URL signee de courte duree vers la copie signee.
  Future<String> copieSigneeUrl(SorteContrat kind);
}

/// L'identifiant de la dependance serveur, pour la trace et les tests.
const String dependanceSignatureContrat = 'RECRUT-SIGNATURE';

/// Le port : absent avant le branchement serveur.
final Provider<PortSignatureContrat?> portSignatureContratProvider =
    Provider<PortSignatureContrat?>(
      (Ref _) => SignatureContratSupabase(Supabase.instance.client),
    );

/// Adaptateur Supabase du contrat enseignant versionne.
///
/// La migration F70 ne stocke que le texte, son empreinte et la ligne de
/// signature; aucun fichier PDF signe ni bucket prive n'y est defini.
final class SignatureContratSupabase implements PortSignatureContrat {
  /// Cree l'adaptateur.
  const SignatureContratSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<ContratCourant> contratCourant(SorteContrat kind) async {
    _exigerContratEnseignant(kind);
    try {
      final Map<String, dynamic>? row = await _client
          .from('contract_texts')
          .select('contract_kind, version, body, sha256')
          .eq('contract_kind', kind.valeurSql)
          .eq('locale', 'fr')
          .eq('is_current', true)
          .maybeSingle();
      if (row == null) throw const ContratIntrouvable();
      return ContratCourant(
        kind: kind,
        version: _string(row, 'version'),
        texte: _string(row, 'body'),
        sha256: _string(row, 'sha256'),
      );
    } on PostgrestException catch (error) {
      _traduireErreur(error);
    } on ContratIntrouvable {
      rethrow;
    } on Object catch (error) {
      if (_estHorsLigne(error)) throw const HorsLigneSignature();
      rethrow;
    }
  }

  @override
  Future<Signature> signerContrat(
    SorteContrat kind,
    String version,
    String nomSaisi,
  ) async {
    _exigerContratEnseignant(kind);
    if (_client.auth.currentSession == null) throw const NonConnecte();
    try {
      final Object? result = await _client.rpc<Object?>(
        'signer_contrat',
        params: <String, dynamic>{
          'p_version': version,
          'p_nom_saisi': nomSaisi,
        },
      );
      if (result is! Map<String, dynamic>) {
        throw const FormatException('reponse signer_contrat invalide');
      }
      return _signatureDepuisJson(result, kind);
    } on PostgrestException catch (error) {
      _traduireErreur(error);
    } on Object catch (error) {
      if (_estHorsLigne(error)) throw const HorsLigneSignature();
      rethrow;
    }
  }

  @override
  Future<Signature?> maSignature(SorteContrat kind) async {
    _exigerContratEnseignant(kind);
    if (_client.auth.currentSession == null) throw const NonConnecte();
    try {
      final Map<String, dynamic>? row = await _client
          .from('contract_acceptances')
          .select(
            'contract_kind, version, accepted_at, signed_sha256, signer_name',
          )
          .eq('contract_kind', kind.valeurSql)
          .order('accepted_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return row == null ? null : _signatureDepuisJson(row, kind);
    } on PostgrestException catch (error) {
      _traduireErreur(error);
    } on Object catch (error) {
      if (_estHorsLigne(error)) throw const HorsLigneSignature();
      rethrow;
    }
  }

  @override
  Future<String> copieSigneeUrl(SorteContrat kind) async {
    _exigerContratEnseignant(kind);
    throw const CopieSigneeIndisponible();
  }

  static Signature _signatureDepuisJson(
    Map<String, dynamic> json,
    SorteContrat kind,
  ) {
    final Object? acceptedAt = json['accepted_at'];
    final DateTime? signedAt = acceptedAt is String
        ? DateTime.tryParse(acceptedAt)?.toLocal()
        : null;
    final String? digest = json['signed_sha256'] as String?;
    final String? signerName = json['signer_name'] as String?;
    final String? version = json['version'] as String?;
    if (signedAt == null ||
        digest == null ||
        signerName == null ||
        version == null) {
      throw const FormatException('signature enseignant incomplete');
    }
    return Signature(
      kind: kind,
      version: version,
      sha256: digest,
      nomSaisi: signerName,
      signeLe: signedAt,
    );
  }

  static String _string(Map<String, dynamic> row, String field) {
    final Object? value = row[field];
    if (value is String && value.isNotEmpty) return value;
    throw FormatException('champ $field invalide');
  }

  static void _exigerContratEnseignant(SorteContrat kind) {
    if (kind != SorteContrat.contratEnseignant) {
      throw ArgumentError.value(kind, 'kind', 'contrat enseignant uniquement');
    }
  }

  static bool _estHorsLigne(Object error) =>
      error.runtimeType.toString().contains('SocketException') ||
      error.runtimeType.toString().contains('ClientException') ||
      error.toString().contains('Failed host lookup');

  Never _traduireErreur(PostgrestException error) {
    final String message = error.message;
    if (error.code == 'P0002' || message.contains('contrat_introuvable')) {
      throw const ContratIntrouvable();
    }
    if (message == 'nom_vide') throw const NomVide();
    if (message == 'nom_trop_long') throw const NomTropLong();
    if (message.startsWith('version_perimee:')) {
      throw VersionPerimee(message.substring('version_perimee:'.length));
    }
    if (_estHorsLigne(error)) throw const HorsLigneSignature();
    Error.throwWithStackTrace(error, StackTrace.current);
  }
}

PortSignatureContrat _port(Ref ref) {
  final PortSignatureContrat? port = ref.watch(portSignatureContratProvider);
  if (port == null) {
    throw const CapaciteIndisponible(dependanceSignatureContrat);
  }
  return port;
}

/// Le contrat courant de l'enseignant.
final FutureProvider<ContratCourant> contratEnseignantCourantProvider =
    FutureProvider<ContratCourant>(
      (Ref ref) => _port(ref).contratCourant(SorteContrat.contratEnseignant),
      retry: (int _, Object _) => null,
    );

/// La signature de l'enseignant, `null` si jamais signe.
final FutureProvider<Signature?> maSignatureEnseignantProvider =
    FutureProvider<Signature?>(
      (Ref ref) => _port(ref).maSignature(SorteContrat.contratEnseignant),
      retry: (int _, Object _) => null,
    );
