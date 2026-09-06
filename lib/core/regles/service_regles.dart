import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/enums.dart';

/// Ce que vaut une regle pour un profil, et ce qu'elle vaudrait sans surcharge.
///
/// Les deux valeurs voyagent ensemble : `ADM-06` les affiche cote a cote pour
/// que l'ecart se voie sans calcul mental.
@immutable
class RegleProfil {
  /// Cree une regle lue.
  const RegleProfil({
    required this.cle,
    required this.valeurEffective,
    required this.valeurPlateforme,
    this.surchargeId,
    this.motif,
    this.poseeLe,
  });

  /// Lit une ligne de `regles_profil_v`.
  factory RegleProfil.depuisJson(Map<String, dynamic> json) => RegleProfil(
    cle: CleRegle.depuisSql(json['key'] as String?),
    valeurEffective: (json['valeur_effective'] as num?)?.toInt() ?? 0,
    valeurPlateforme: (json['valeur_plateforme'] as num?)?.toInt() ?? 0,
    surchargeId: json['override_id'] as String?,
    motif: json['motif'] as String?,
    poseeLe: DateTime.tryParse(json['pose_le'] as String? ?? '')?.toLocal(),
  );

  /// La regle concernee. `null` quand la base en expose une que ce code ne
  /// connait pas encore : l'ecran l'ignore plutot que d'inventer un libelle.
  final CleRegle? cle;

  /// Ce qui s'applique a ce profil.
  final int valeurEffective;

  /// Ce qui s'appliquerait sans surcharge.
  final int valeurPlateforme;

  /// L'identifiant de la surcharge active, quand il y en a une.
  final String? surchargeId;

  /// Le motif de la surcharge. C'est lui qui rend la decision lisible six mois
  /// plus tard.
  final String? motif;

  /// Depuis quand elle s'applique.
  final DateTime? poseeLe;

  /// Vrai quand ce profil ne suit pas la regle de la plateforme.
  bool get surchargee => surchargeId != null;
}

/// Les regles qui peuvent differer d'un profil a l'autre (ADR-017 section 2.4).
///
/// **Seul chemin de lecture d'une regle.** Un ecran qui lirait une constante ou
/// la valeur de plateforme afficherait la mauvaise regle a l'eleve qui n'en
/// releve pas, et l'ecart ne se verrait qu'au moment de la facture.
abstract interface class ServiceRegles {
  /// La valeur qui s'applique a ce profil pour cette regle.
  Future<int> valeur(String profilId, CleRegle cle);

  /// Toutes les regles d'un profil, avec le defaut de plateforme en regard.
  Future<List<RegleProfil>> regles(String profilId);

  /// Pose une regle sur un profil. Reserve a l'administration, et le motif est
  /// obligatoire : une regle sans motif ne se relit pas.
  Future<void> poser({
    required String profilId,
    required CleRegle cle,
    required int valeur,
    required String motif,
  });

  /// Clot une surcharge. Elle ne se supprime pas : une regle qui a compte pour
  /// une seance passee doit rester verifiable.
  Future<void> clore({required String surchargeId, required String motif});
}

/// L'implementation reelle.
class ServiceReglesSupabase implements ServiceRegles {
  /// Cree le service.
  const ServiceReglesSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<int> valeur(String profilId, CleRegle cle) async {
    final Object? reponse = await _client.rpc<Object?>(
      'regle_effective',
      params: <String, dynamic>{
        'p_profile_id': profilId,
        'p_key': cle.valeurSql,
      },
    );
    if (reponse is num) {
      return reponse.toInt();
    }
    throw StateError('regle illisible : ${cle.valeurSql}');
  }

  @override
  Future<List<RegleProfil>> regles(String profilId) async {
    final List<Map<String, dynamic>> lignes = await _client
        .from('regles_profil_v')
        .select()
        .eq('profile_id', profilId);
    return lignes.map(RegleProfil.depuisJson).toList();
  }

  @override
  Future<void> poser({
    required String profilId,
    required CleRegle cle,
    required int valeur,
    required String motif,
  }) => _client.rpc<void>(
    'poser_regle',
    params: <String, dynamic>{
      'p_profile_id': profilId,
      'p_key': cle.valeurSql,
      'p_value': valeur,
      'p_motif': motif,
    },
  );

  @override
  Future<void> clore({required String surchargeId, required String motif}) =>
      _client.rpc<void>(
        'clore_regle',
        params: <String, dynamic>{
          'p_override_id': surchargeId,
          'p_motif': motif,
        },
      );
}

/// Le service de regles employe par l'application.
final Provider<ServiceRegles> serviceReglesProvider = Provider<ServiceRegles>(
  (Ref ref) => ServiceReglesSupabase(Supabase.instance.client),
);

/// Les regles d'un profil, defaut de plateforme en regard.
final FutureProviderFamily<List<RegleProfil>, String> reglesProfilProvider =
    FutureProvider.family<List<RegleProfil>, String>(
      (Ref ref, String profilId) =>
          ref.watch(serviceReglesProvider).regles(profilId),
    );

/// Ce qu'une lecture de regle demande : un profil et une regle.
typedef DemandeRegle = ({String profilId, CleRegle cle});

/// La valeur qui s'applique a un profil pour **une** regle.
///
/// **Passe par `regle_effective()`, jamais par `regles_profil_v`.** La vue ne
/// joint a un profil que les cles qui ont un sens pour son role : a un
/// enseignant, elle ne rend que son plafond d'eleves. La pause entre deux cours
/// n'y figure donc pas, et un ecran qui l'y chercherait, comme `ENS-06` cherche
/// le plafond, lirait zero sans qu'aucune erreur ne se produise. Zero se lit
/// « aucun trou n'est une pause » : la colonne de `ENS-02` n'en afficherait
/// jamais une seule, et rien ne le signalerait.
///
/// La fonction, elle, ne borne rien par role : elle borne par perimetre de
/// lecture, et rend la surcharge du profil ou le defaut de plateforme.
final FutureProviderFamily<int, DemandeRegle> valeurRegleProvider =
    FutureProvider.family<int, DemandeRegle>(
      (Ref ref, DemandeRegle demande) => ref
          .watch(serviceReglesProvider)
          .valeur(demande.profilId, demande.cle),
    );
