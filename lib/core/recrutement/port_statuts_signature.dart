/// RECRUT-ECRANS : ce que l'administration voit de la signature d'un dossier
/// (contrat C-17 de la feuille de liaison, 10/10/2026).
///
/// **Ecart a la feuille, a arbitrer par Codex.** Le contrat C-17 place
/// `statutContrat` et `statutAccuse` dans `DossierAValider` et
/// `EtatDossier`, qui sont dans des fichiers `service_*.dart` (zone de
/// Codex) ; la revue des dossiers lit d'ailleurs `PortRevueDossiers`, pas
/// `ServiceValidation`. Ce port separe, cle par l'identifiant de dossier de la
/// revue, evite de toucher un port existant sans ligne « accepte ». Quand
/// Codex aura ajoute les deux champs aux ports existants, ce port peut
/// disparaitre : l'ecran n'en lit que [StatutsSignature].
///
/// Les statuts sont calcules par le serveur : jamais compares cote client a
/// une constante de version.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Le statut d'une signature.
sealed class StatutSignature {
  const StatutSignature();
}

/// Signe a la version courante.
final class SigneVersionCourante extends StatutSignature {
  /// Cree le statut.
  const SigneVersionCourante();
}

/// Signe, mais a une ancienne version.
final class SigneAncienneVersion extends StatutSignature {
  /// Cree le statut.
  const SigneAncienneVersion(this.versionSignee);

  /// La version que la personne a signee.
  final String versionSignee;
}

/// Jamais signe.
final class NonSigne extends StatutSignature {
  /// Cree le statut.
  const NonSigne();
}

/// Les deux statuts d'un dossier.
@immutable
class StatutsSignature {
  /// Cree les statuts.
  const StatutsSignature({required this.contrat, required this.accuse});

  /// Le contrat enseignant.
  final StatutSignature contrat;

  /// L'accuse (enregistrement et visite de controle).
  final StatutSignature accuse;

  /// Vrai quand les deux sont a la version courante.
  bool get complets =>
      contrat is SigneVersionCourante && accuse is SigneVersionCourante;
}

/// Ce qui manque quand l'activation est refusee.
enum ManqueSignature { contrat, accuse }

/// Levee par la decision `valider` quand le contrat ou l'accuse n'est pas a la
/// version courante (course : les statuts lus avant la decision ont change).
/// Les adaptateurs de `PortRevueDossiers` la levent ; la revue la dit en
/// clair.
class ContratNonSigneVersionCourante implements Exception {
  /// Cree l'erreur.
  const ContratNonSigneVersionCourante(this.manque);

  /// Le ou les documents en defaut.
  final List<ManqueSignature> manque;
}

/// Le port.
abstract interface class PortStatutsSignature {
  /// Les statuts du dossier [dossierId] (celui de la revue), ou `null` quand
  /// le dossier n'a ni contrat ni accuse a signer (le serveur le sait ; l'ecran
  /// ne devine rien a partir d'un role).
  Future<StatutsSignature?> pour(String dossierId);
}

/// Le port : absent avant le branchement serveur. Absent, la revue n'affiche
/// pas la carte et ne bloque rien de plus : le serveur reste la barriere.
final Provider<PortStatutsSignature?> portStatutsSignatureProvider =
    Provider<PortStatutsSignature?>(
      (Ref _) => StatutsSignatureSupabase(Supabase.instance.client),
    );

/// Adaptateur du RPC qui calcule les signatures au regard des versions serveur.
final class StatutsSignatureSupabase implements PortStatutsSignature {
  /// Cree l'adaptateur.
  const StatutsSignatureSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<StatutsSignature?> pour(String dossierId) async {
    try {
      final Object? result = await _client.rpc<Object?>(
        'teacher_signature_statuses',
        params: <String, dynamic>{'p_profile_id': dossierId},
      );
      if (result is! Map<String, dynamic>) {
        throw const FormatException('teacher_signature_statuses invalide');
      }
      return StatutsSignature(
        contrat: _statut(result['contrat']),
        accuse: _statut(result['accuse']),
      );
    } on PostgrestException catch (error) {
      if (error.code == 'P0002') return null;
      rethrow;
    }
  }

  static StatutSignature _statut(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('statut de signature invalide');
    }
    return switch (value['status']) {
      'signe_version_courante' => const SigneVersionCourante(),
      'signe_ancienne_version' => SigneAncienneVersion(
        value['version_signee'] is String
            ? value['version_signee'] as String
            : '',
      ),
      _ => const NonSigne(),
    };
  }
}

/// Les statuts d'un dossier, `null` quand le port est absent.
final FutureProviderFamily<StatutsSignature?, String>
statutsSignatureDossierProvider =
    FutureProvider.family<StatutsSignature?, String>((
      Ref ref,
      String dossierId,
    ) {
      final PortStatutsSignature? port = ref.watch(
        portStatutsSignatureProvider,
      );
      return port == null
          ? Future<StatutsSignature?>.value()
          : port.pour(dossierId);
    }, retry: (int _, Object _) => null);
