import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Le responsable de la protection des enfants, tel que l'administration l'a
/// saisi (PE, 18/10/2026).
///
/// **Rien n'est en dur** : le nom affiche et le courriel de contact sont deux
/// reglages de `app_config` (`protection_enfants.responsable_nom` et
/// `protection_enfants.responsable_courriel`), vides tant que l'administration
/// n'a rien saisi. Vide, l'ecran dit que la direction recoit le signalement.
@immutable
class ResponsableProtection {
  /// Cree le responsable.
  const ResponsableProtection({this.nom = '', this.courriel = ''});

  /// Lit la reponse de `responsable_protection_enfants()`.
  factory ResponsableProtection.depuisJson(Map<String, dynamic> json) {
    final Object? nom = json['nom'];
    final Object? courriel = json['courriel'];
    return ResponsableProtection(
      nom: nom is String ? nom.trim() : '',
      courriel: courriel is String ? courriel.trim() : '',
    );
  }

  /// Personne : la direction recoit le signalement.
  static const ResponsableProtection aucun = ResponsableProtection();

  /// Le nom affiche. Vide tant que rien n'est saisi.
  final String nom;

  /// Le courriel de contact. Vide tant que rien n'est saisi.
  final String courriel;

  /// Vrai quand l'administration a nomme quelqu'un.
  bool get estNomme => nom.isNotEmpty;

  /// Vrai quand un courriel de contact existe.
  bool get aUnCourriel => courriel.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      other is ResponsableProtection &&
      other.nom == nom &&
      other.courriel == courriel;

  @override
  int get hashCode => Object.hash(nom, courriel);
}

/// La lecture du responsable de la protection des enfants.
abstract interface class PortResponsableProtection {
  /// Le responsable actuel. Leve si la lecture n'a pas abouti : l'ecran ne
  /// doit jamais dire « la direction » sur un echec de lecture comme s'il
  /// s'agissait d'un reglage vide.
  Future<ResponsableProtection> lire();
}

/// L'adaptateur reel : la fonction `responsable_protection_enfants()`.
class ResponsableProtectionSupabase implements PortResponsableProtection {
  /// Cree l'adaptateur.
  const ResponsableProtectionSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<ResponsableProtection> lire() async {
    final Map<String, dynamic> ligne = await _client.rpc<Map<String, dynamic>>(
      'responsable_protection_enfants',
    );
    return ResponsableProtection.depuisJson(ligne);
  }
}

/// Le port employe par l'application.
final Provider<PortResponsableProtection> portResponsableProtectionProvider =
    Provider<PortResponsableProtection>(
      (Ref ref) => ResponsableProtectionSupabase(Supabase.instance.client),
    );

/// Le responsable, relu a chaque invalidation.
final FutureProvider<ResponsableProtection> responsableProtectionProvider =
    FutureProvider<ResponsableProtection>(
      (Ref ref) => ref.watch(portResponsableProtectionProvider).lire(),
    );

/// Les cles `app_config` du responsable.
abstract final class ClesProtectionEnfants {
  /// Le nom affiche.
  static const String nom = 'protection_enfants.responsable_nom';

  /// Le courriel de contact.
  static const String courriel = 'protection_enfants.responsable_courriel';

  /// Les deux cles, dans l'ordre d'affichage.
  static const List<String> toutes = <String>[nom, courriel];
}
