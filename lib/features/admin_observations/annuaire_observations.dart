import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Les noms que la consultation admin des observations affiche (lot E,
// sous-paquet 3). `guardian_session_visit` ne porte que des identifiants : les
// noms des tuteurs et des eleves viennent de `profiles`, ceux des classes de
// `groupes`, tous deux lisibles par l'administration seule
// (`profiles_admin_all`, `0001_fondations.sql` ; `groupes`, `0017`).
//
// **Lu seulement quand l'historique l'est** : l'ecran n'interroge l'annuaire
// qu'apres une page de visites rendue, jamais tant que le port dit
// « indisponible ». Aucune ecriture.

/// Une personne trouvee par la recherche.
@immutable
class PersonneAnnuaire {
  /// Cree une personne.
  const PersonneAnnuaire({
    required this.id,
    required this.nom,
    required this.estTuteur,
  });

  /// Le profil.
  final String id;

  /// Prenom et nom.
  final String nom;

  /// Vrai pour un tuteur, faux pour un eleve.
  final bool estTuteur;
}

/// Une classe, pour le filtre « Classe ».
typedef ClasseAnnuaire = ({String id, String libelle});

/// Les noms de la consultation admin.
abstract interface class AnnuaireObservations {
  /// Prenom et nom de chaque profil de [ids] que la base connait.
  Future<Map<String, String>> noms(Set<String> ids);

  /// Le libelle de chaque classe de [ids] que la base connait.
  Future<Map<String, String>> classes(Set<String> ids);

  /// Les classes en cours, par libelle croissant.
  Future<List<ClasseAnnuaire>> classesEnCours();

  /// Les tuteurs et eleves dont le prenom ou le nom contient [texte].
  Future<List<PersonneAnnuaire>> chercher(String texte);
}

/// L'annuaire lu dans Supabase, sous RLS admin.
class AnnuaireObservationsSupabase implements AnnuaireObservations {
  /// Cree l'annuaire. Le client est lu a la demande.
  const AnnuaireObservationsSupabase(this._client);

  final SupabaseClient Function() _client;

  /// Le nombre de personnes proposees par la recherche.
  static const int propositions = 8;

  @override
  Future<Map<String, String>> noms(Set<String> ids) async {
    if (ids.isEmpty) {
      return const <String, String>{};
    }
    final List<Map<String, dynamic>> lignes = await _client()
        .from('profiles')
        .select('id, first_name, last_name')
        .inFilter('id', ids.toList());
    return <String, String>{
      for (final Map<String, dynamic> l in lignes)
        if (l['id'] case final String id) id: nomComplet(l),
    };
  }

  @override
  Future<Map<String, String>> classes(Set<String> ids) async {
    if (ids.isEmpty) {
      return const <String, String>{};
    }
    final List<Map<String, dynamic>> lignes = await _client()
        .from('groupes')
        .select('id, libelle')
        .inFilter('id', ids.toList());
    return <String, String>{
      for (final Map<String, dynamic> l in lignes)
        if ((l['id'], l['libelle']) case (
          final String id,
          final String libelle,
        ))
          id: libelle,
    };
  }

  @override
  Future<List<ClasseAnnuaire>> classesEnCours() async {
    final List<Map<String, dynamic>> lignes = await _client()
        .from('groupes')
        .select('id, libelle')
        .isFilter('ended_at', null)
        .order('libelle', ascending: true);
    return <ClasseAnnuaire>[
      for (final Map<String, dynamic> l in lignes)
        if ((l['id'], l['libelle']) case (
          final String id,
          final String libelle,
        ))
          (id: id, libelle: libelle),
    ];
  }

  @override
  Future<List<PersonneAnnuaire>> chercher(String texte) async {
    final String motif = motifRecherche(texte);
    if (motif.length < 2) {
      return const <PersonneAnnuaire>[];
    }
    final List<Map<String, dynamic>> lignes = await _client()
        .from('profiles')
        .select('id, first_name, last_name, role')
        .inFilter('role', <String>['guardian', 'student'])
        .isFilter('deleted_at', null)
        .or('first_name.ilike.*$motif*,last_name.ilike.*$motif*')
        .order('last_name', ascending: true)
        .order('first_name', ascending: true)
        .limit(propositions);
    return <PersonneAnnuaire>[
      for (final Map<String, dynamic> l in lignes)
        if (l['id'] case final String id)
          PersonneAnnuaire(
            id: id,
            nom: nomComplet(l),
            estTuteur: l['role'] == 'guardian',
          ),
    ];
  }
}

/// « Prenom Nom », sans espace en trop quand une partie manque.
String nomComplet(Map<String, dynamic> ligne) => <Object?>[
  ligne['first_name'],
  ligne['last_name'],
].whereType<String>().where((String s) => s.trim().isNotEmpty).join(' ');

/// Le texte de recherche, reduit aux lettres, chiffres, espaces, tirets et
/// apostrophes : rien de ce qui a un sens dans un filtre PostgREST
/// (virgule, parenthese, point, etoile, guillemet) ne passe.
String motifRecherche(String texte) =>
    texte.replaceAll(RegExp(r"[^\p{L}\p{N} '\-]", unicode: true), '').trim();

/// L'annuaire employe par l'ecran.
final Provider<AnnuaireObservations> annuaireObservationsProvider =
    Provider<AnnuaireObservations>(
      (Ref ref) => AnnuaireObservationsSupabase(() => Supabase.instance.client),
    );
