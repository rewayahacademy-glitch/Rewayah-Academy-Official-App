import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `FutureProviderFamily` n'est pas exporte par l'entree principale de
// Riverpod 3 : il vit dans `misc.dart`, comme `Override`.
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/enums.dart';
import '../planning/service_planning.dart';

/// Un eleve sans enseignant, tel que `eleves_sans_enseignant()` l'expose a
/// l'administration.
///
/// **Une ligne par eleve**, contrairement au feed de `ENS-06` qui en rend une
/// par creneau : la colonne de gauche de `ADM-05` est une file de personnes, pas
/// un tableau d'heures. Les creneaux proposes voyagent avec, parce que c'est
/// parmi eux que l'attribution choisira.
@immutable
class FoyerEnAttente {
  /// Cree une ligne de la file.
  const FoyerEnAttente({
    required this.eleveId,
    required this.prenom,
    required this.identifiantImmuable,
    required this.foyerId,
    required this.mode,
    required this.creneaux,
    this.niveau,
    this.depuis,
  });

  /// Lit une ligne rendue par `eleves_sans_enseignant()`.
  factory FoyerEnAttente.depuisJson(Map<String, dynamic> json) {
    final Object? cases = json['creneaux'];
    return FoyerEnAttente(
      eleveId: json['student_id'] as String,
      prenom: json['first_name'] as String? ?? '',
      identifiantImmuable: json['immutable_id'] as String? ?? '',
      foyerId: json['household_id'] as String? ?? '',
      mode: InterfaceMode.depuisSql(json['interface_mode'] as String?),
      niveau: json['level'] as String?,
      depuis: DateTime.tryParse(json['depuis'] as String? ?? '')?.toLocal(),
      creneaux: cases is List<dynamic>
          ? cases
                .whereType<Map<String, dynamic>>()
                .map(Creneau.depuisJson)
                .toList()
          : const <Creneau>[],
    );
  }

  /// Identifiant du profil eleve.
  final String eleveId;

  /// Prenom. Jamais le nom de famille (ADR-008).
  final String prenom;

  /// Identifiant immuable, seule autre donnee d'identite affichee.
  final String identifiantImmuable;

  /// Comment nommer cet eleve a l'ecran.
  ///
  /// **Se replie sur l'identifiant immuable quand le prenom est masque.** En
  /// mode observation, `eleves_sans_enseignant()` rend `first_name` nul depuis
  /// la migration `0016` : sans ce repli, `ADM-05` afficherait une carte au
  /// titre vide.
  String get libelle => prenom.isEmpty ? identifiantImmuable : prenom;

  /// Vrai quand le prenom est lisible.
  bool get prenomConnu => prenom.isNotEmpty;

  /// Le foyer auquel il appartient. Deux enfants d'un meme foyer se lisent
  /// ainsi comme deux lignes d'une meme famille.
  final String foyerId;

  /// Mode d'interface de l'eleve.
  final InterfaceMode mode;

  /// Niveau declare, quand il existe.
  final String? niveau;

  /// Depuis quand ce foyer attend. `null` quand il n'a pose aucun creneau : il
  /// n'attend alors pas au sens du matching, il n'a simplement rien propose.
  final DateTime? depuis;

  /// Les heures que la famille propose. **C'est la seule source d'heures d'une
  /// attribution** : ni l'enseignant ni l'administration n'en ajoutent.
  final List<Creneau> creneaux;

  /// Vrai quand cet eleve peut recevoir un enseignant.
  ///
  /// Un foyer qui n'a pose aucun creneau reste dans la file, parce que le
  /// masquer donnerait un compteur `ADM-01` sans ligne en face. Mais l'ecran
  /// doit dire pourquoi il ne se traite pas ici.
  bool get attribuable => creneaux.isNotEmpty;

  /// Le nombre de jours d'attente a un instant donne.
  int? joursDAttente(DateTime maintenant) {
    final DateTime? debut = depuis;
    return debut == null ? null : maintenant.difference(debut).inDays;
  }
}

/// Un enseignant, vu depuis `ADM-05` pour un eleve donne.
///
/// **Tous les enseignants au compte valide sont rendus**, pas seulement ceux
/// dont un creneau croise : le jour ou aucun croisement n'existe est exactement
/// celui ou l'on ouvre cet ecran.
@immutable
class EnseignantCandidat {
  /// Cree un candidat.
  const EnseignantCandidat({
    required this.id,
    required this.prenom,
    required this.nom,
    required this.identifiantImmuable,
    required this.elevesActifs,
    required this.plafond,
    required this.creneauxCommuns,
    this.pays,
  });

  /// Lit une ligne rendue par `enseignants_pour()`.
  factory EnseignantCandidat.depuisJson(Map<String, dynamic> json) {
    final Object? cases = json['creneaux_communs'];
    return EnseignantCandidat(
      id: json['teacher_id'] as String,
      prenom: json['first_name'] as String? ?? '',
      nom: json['last_name'] as String? ?? '',
      identifiantImmuable: json['immutable_id'] as String? ?? '',
      pays: json['country'] as String?,
      elevesActifs: (json['eleves_actifs'] as num?)?.toInt() ?? 0,
      plafond: (json['plafond'] as num?)?.toInt() ?? 0,
      creneauxCommuns: cases is List<dynamic>
          ? cases
                .whereType<Map<String, dynamic>>()
                .map(Creneau.depuisJson)
                .toList()
          : const <Creneau>[],
    );
  }

  /// Identifiant du profil enseignant.
  final String id;

  /// Prenom.
  final String prenom;

  /// Nom. L'administration voit l'identite complete d'un membre du personnel :
  /// c'est l'eleve que l'ADR-008 protege, pas l'enseignant vu de l'admin.
  final String nom;

  /// Identifiant immuable.
  final String identifiantImmuable;

  /// Comment nommer cet enseignant a l'ecran.
  ///
  /// Se replie sur l'identifiant immuable quand l'identite est masquee
  /// (migration `0016`).
  String get libelle {
    final String complet = '$prenom $nom'.trim();
    return complet.isEmpty ? identifiantImmuable : complet;
  }

  /// Vrai quand l'identite est lisible.
  bool get identiteConnue => prenom.isNotEmpty || nom.isNotEmpty;

  /// Comment le nommer **dans une phrase** : le prenom seul, et l'identifiant
  /// faute de prenom. Le nom complet reste sur sa carte.
  String get libelleCourt =>
      prenom.isEmpty ? identifiantImmuable : prenom;

  /// Pays declare, quand il existe.
  final String? pays;

  /// Le nombre d'eleves qu'il suit aujourd'hui.
  final int elevesActifs;

  /// Le plafond qui s'applique reellement a **lui**, surcharge comprise.
  final int plafond;

  /// Les heures qu'il partage avec ce foyer, croisees par instant.
  final List<Creneau> creneauxCommuns;

  /// Vrai quand une attribution ne demandera aucun motif.
  bool get croise => creneauxCommuns.isNotEmpty;

  /// Vrai quand il a atteint son plafond. La base refusera de toute facon :
  /// l'ecran le dit avant le geste plutot qu'apres.
  bool get complet => elevesActifs >= plafond;
}

/// L'attribution manuelle, cote administration (`ADM-05`).
///
/// Jumelle de [ServiceMatching] et non son extension : le matching inverse est
/// le geste de l'enseignant, celui-ci est le geste de secours de
/// l'administration. Les deux ecrivent dans la meme table, par deux portes
/// distinctes et deux fonctions nommees.
abstract interface class ServiceAttribution {
  /// Les eleves sans enseignant actif, anciennete d'abord.
  Future<List<FoyerEnAttente>> foyersEnAttente();

  /// Les enseignants, ordonnes pour cet eleve : ceux qui croisent d'abord, puis
  /// les moins charges.
  Future<List<EnseignantCandidat>> enseignantsPour(String eleveId);

  /// Attribue un enseignant a un eleve sur une heure proposee par la famille.
  ///
  /// [motif] est **obligatoire** quand le creneau ne figure pas dans les
  /// disponibilites de l'enseignant (ADR-021). La base l'exige aussi : ce qui ne
  /// se verifie qu'au clavier finit par ne plus se verifier du tout.
  Future<void> attribuer({
    required String eleveId,
    required String enseignantId,
    required Creneau creneau,
    String? motif,
  });
}

/// L'implementation reelle.
class ServiceAttributionSupabase implements ServiceAttribution {
  /// Cree le service.
  const ServiceAttributionSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<List<FoyerEnAttente>> foyersEnAttente() async {
    final List<dynamic> reponse = await _client.rpc<List<dynamic>>(
      'eleves_sans_enseignant',
    );
    return reponse
        .map(
          (dynamic ligne) =>
              FoyerEnAttente.depuisJson(ligne as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<List<EnseignantCandidat>> enseignantsPour(String eleveId) async {
    final List<dynamic> reponse = await _client.rpc<List<dynamic>>(
      'enseignants_pour',
      params: <String, dynamic>{'p_student_profile_id': eleveId},
    );
    return reponse
        .map(
          (dynamic ligne) =>
              EnseignantCandidat.depuisJson(ligne as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<void> attribuer({
    required String eleveId,
    required String enseignantId,
    required Creneau creneau,
    String? motif,
  }) => _client.rpc<void>(
    'attribuer_eleve',
    params: <String, dynamic>{
      'p_student_profile_id': eleveId,
      'p_teacher_profile_id': enseignantId,
      'p_weekday': creneau.jour,
      'p_hour': creneau.heure,
      'p_motif': motif,
    },
  );
}

/// Le service d'attribution employe par l'application.
final Provider<ServiceAttribution> serviceAttributionProvider =
    Provider<ServiceAttribution>(
      (Ref ref) => ServiceAttributionSupabase(Supabase.instance.client),
    );

/// La colonne de gauche de `ADM-05`.
final FutureProvider<List<FoyerEnAttente>> foyersEnAttenteProvider =
    FutureProvider<List<FoyerEnAttente>>(
      (Ref ref) => ref.watch(serviceAttributionProvider).foyersEnAttente(),
    );

/// La colonne de droite de `ADM-05`, pour l'eleve selectionne.
final FutureProviderFamily<List<EnseignantCandidat>, String>
enseignantsPourProvider =
    FutureProvider.family<List<EnseignantCandidat>, String>(
      (Ref ref, String eleveId) =>
          ref.watch(serviceAttributionProvider).enseignantsPour(eleveId),
    );
