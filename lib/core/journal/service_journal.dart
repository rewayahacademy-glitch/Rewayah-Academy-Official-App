import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Une entree du journal d'audit, telle que `journal_audit()` l'expose.
///
/// **Rien ici n'est modifiable, et c'est le sujet** : `audit_logs` refuse
/// `update` et `delete` par declencheur depuis l'etape 1. Le modele est donc
/// en lecture seule de bout en bout, sans methode de copie ni champ mutable.
@immutable
class EntreeJournal {
  /// Cree une entree.
  const EntreeJournal({
    required this.id,
    required this.survenuLe,
    required this.typeEvenement,
    required this.tableVisee,
    required this.details,
    this.acteur,
    this.roleActeur,
    this.nomActeur,
    this.ligneVisee,
  });

  /// Lit une ligne rendue par `journal_audit()`.
  factory EntreeJournal.depuisJson(Map<String, dynamic> json) {
    final Object? details = json['details'];
    return EntreeJournal(
      id: (json['entree_id'] as num).toInt(),
      survenuLe:
          DateTime.tryParse(json['survenu_le'] as String? ?? '')?.toLocal() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      acteur: json['acteur'] as String?,
      roleActeur: json['role_acteur'] as String?,
      nomActeur: json['nom_acteur'] as String?,
      typeEvenement: json['type_evenement'] as String? ?? '',
      tableVisee: json['table_visee'] as String? ?? '',
      ligneVisee: json['ligne_visee'] as String?,
      details: details is Map<String, dynamic>
          ? details
          : const <String, dynamic>{},
    );
  }

  /// Identifiant de l'entree. Il ordonne la chaine autant qu'il la nomme.
  final int id;

  /// Quand l'evenement est survenu, dans le fuseau de qui lit.
  final DateTime survenuLe;

  /// Le compte a l'origine du geste. `null` pour une ecriture du systeme,
  /// faite hors de toute session : ce n'est pas une anomalie, et l'ecran ne
  /// doit pas la rendre comme telle.
  final String? acteur;

  /// Le role que l'acteur portait **au moment du geste**, pas aujourd'hui.
  final String? roleActeur;

  /// Le nom de l'acteur, quand son profil est encore lisible. Il survit a la
  /// cloture du compte : une ligne de journal anonyme ne sert a rien.
  final String? nomActeur;

  /// Ce qui a ete fait : `kyc_read`, `affectation_attribuee`, et les douze
  /// autres. Le vocabulaire vient de la base, jamais d'une liste ecrite ici.
  final String typeEvenement;

  /// La table touchee.
  final String tableVisee;

  /// La ligne touchee, quand l'evenement en vise une.
  final String? ligneVisee;

  /// Le contenu libre de l'evenement. Il fait partie du condensat : le lire
  /// n'est pas un detail decoratif, c'est ce que la chaine protege.
  final Map<String, dynamic> details;

  /// Vrai quand l'evenement n'a pas d'auteur humain.
  bool get parLeSysteme => acteur == null;
}

/// Une valeur proposee par un filtre, avec le nombre d'entrees derriere elle.
///
/// Le compteur n'est pas decoratif : il dit a l'avance si un filtre mene
/// quelque part. Un filtre qui ouvre sur un ecran vide est une impasse que
/// l'administration decouvre apres coup.
@immutable
class ValeurFiltre {
  /// Cree une valeur de filtre.
  const ValeurFiltre({
    required this.valeur,
    required this.libelle,
    required this.nombre,
    this.role,
  });

  /// La valeur transmise a la lecture : un type d'evenement, ou un identifiant
  /// d'acteur.
  final String valeur;

  /// Ce qui s'affiche.
  final String libelle;

  /// Le nombre d'entrees derriere cette valeur.
  final int nombre;

  /// Le role de l'acteur, pour les filtres d'acteur seulement.
  final String? role;
}

/// Ce que les filtres de `ADM-04` proposent, en une seule lecture.
@immutable
class FiltresJournal {
  /// Cree un jeu de filtres.
  const FiltresJournal({
    required this.actions,
    required this.acteurs,
    required this.total,
    this.premiere,
  });

  /// Lit l'objet rendu par `journal_audit_filtres()`.
  factory FiltresJournal.depuisJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> lignes(String cle) =>
        (json[cle] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .toList();

    return FiltresJournal(
      total: (json['total'] as num?)?.toInt() ?? 0,
      premiere: DateTime.tryParse(json['premiere'] as String? ?? '')?.toLocal(),
      actions: lignes('actions')
          .map(
            (Map<String, dynamic> l) => ValeurFiltre(
              valeur: l['action'] as String? ?? '',
              libelle: l['action'] as String? ?? '',
              nombre: (l['n'] as num?)?.toInt() ?? 0,
            ),
          )
          .toList(),
      acteurs: lignes('acteurs')
          .map(
            (Map<String, dynamic> l) => ValeurFiltre(
              valeur: l['id'] as String? ?? '',
              libelle: l['nom'] as String? ?? '',
              nombre: (l['n'] as num?)?.toInt() ?? 0,
              role: l['role'] as String?,
            ),
          )
          .toList(),
    );
  }

  /// Les types d'evenements presents, les plus frequents d'abord.
  final List<ValeurFiltre> actions;

  /// Les acteurs presents, les plus actifs d'abord.
  final List<ValeurFiltre> acteurs;

  /// Le nombre total d'entrees du journal.
  final int total;

  /// La date de la toute premiere entree. C'est la profondeur reelle du
  /// journal, et elle borne ce qu'une periode peut promettre.
  final DateTime? premiere;
}

/// Le verdict de la chaine de hachage.
///
/// C'est ce qui separe un journal d'une liste : `audit_logs` porte `prev_hash`
/// et `hash` depuis l'etape 1, et `log_sensitive_access` paie un verrou de
/// table a chaque ecriture pour les tenir. Sans cette lecture, le prix serait
/// paye sans que la garantie soit jamais constatee.
@immutable
class EtatChaine {
  /// Cree un verdict.
  const EtatChaine({
    required this.verifiees,
    required this.rompues,
    this.premiereRompue,
    this.rompueLe,
  });

  /// Lit la ligne rendue par `verifier_chaine_audit()`.
  factory EtatChaine.depuisJson(Map<String, dynamic> json) => EtatChaine(
    verifiees: (json['verifiees'] as num?)?.toInt() ?? 0,
    rompues: (json['rompues'] as num?)?.toInt() ?? 0,
    premiereRompue: (json['premiere_rompue'] as num?)?.toInt(),
    rompueLe: DateTime.tryParse(json['rompue_le'] as String? ?? '')?.toLocal(),
  );

  /// Le nombre d'entrees passees au controle.
  final int verifiees;

  /// Le nombre d'entrees dont le condensat ou le maillon ne tombe pas juste.
  final int rompues;

  /// La plus ancienne entree en defaut.
  final int? premiereRompue;

  /// Sa date.
  final DateTime? rompueLe;

  /// Vrai quand rien n'a bouge depuis l'ecriture.
  bool get intacte => rompues == 0;
}

/// Le curseur de pagination : les deux bornes de la derniere entree lue.
///
/// **Les deux voyagent ensemble ou pas du tout.** La base compare le couple
/// `(created_at, id)`, et une comparaison de lignes dont un membre est nul vaut
/// nul, c'est-a-dire « aucune ligne » : un curseur a moitie renseigne rendrait
/// une page vide, et un journal qui s'arrete au bout d'une page ressemble a un
/// journal qui finit.
@immutable
class CurseurJournal {
  /// Cree un curseur.
  const CurseurJournal({required this.avantDate, required this.avantId});

  /// Le curseur pose sur une entree.
  factory CurseurJournal.apres(EntreeJournal entree) =>
      CurseurJournal(avantDate: entree.survenuLe, avantId: entree.id);

  /// L'horodatage de la derniere entree lue.
  final DateTime avantDate;

  /// Son identifiant.
  final int avantId;
}

/// Le journal d'audit, en lecture seule (`ADM-04`).
///
/// **Aucune methode d'ecriture, et ce n'est pas un oubli** : la seule chose
/// qu'on puisse faire d'un journal immuable, c'est le lire. Ajouter ici un
/// geste de purge ou de correction reviendrait a defaire ce que les
/// declencheurs de 0001 protegent.
abstract interface class ServiceJournal {
  /// Une page du journal, la plus recente d'abord.
  Future<List<EntreeJournal>> entrees({
    String? acteur,
    String? typeEvenement,
    DateTime? depuis,
    int limite = 50,
    CurseurJournal? curseur,
  });

  /// Ce que les filtres proposent, tel que le journal le contient.
  Future<FiltresJournal> filtres();

  /// Le verdict de la chaine sur les dernieres entrees.
  Future<EtatChaine> verifierChaine({int limite = 200});
}

/// L'implementation reelle.
class ServiceJournalSupabase implements ServiceJournal {
  /// Cree le service.
  const ServiceJournalSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<List<EntreeJournal>> entrees({
    String? acteur,
    String? typeEvenement,
    DateTime? depuis,
    int limite = 50,
    CurseurJournal? curseur,
  }) async {
    final List<dynamic> reponse = await _client.rpc<List<dynamic>>(
      'journal_audit',
      params: <String, dynamic>{
        'p_acteur': acteur,
        'p_action': typeEvenement,
        // En UTC, toujours : la base compare des `timestamptz`, et envoyer une
        // heure locale sans fuseau decalerait la periode de qui ne vit pas a
        // Paris. Le produit tourne sur trois continents.
        'p_depuis': depuis?.toUtc().toIso8601String(),
        'p_limite': limite,
        'p_avant_date': curseur?.avantDate.toUtc().toIso8601String(),
        'p_avant_id': curseur?.avantId,
      },
    );
    return reponse
        .map(
          (dynamic ligne) =>
              EntreeJournal.depuisJson(ligne as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<FiltresJournal> filtres() async {
    final Map<String, dynamic> reponse = await _client
        .rpc<Map<String, dynamic>>('journal_audit_filtres');
    return FiltresJournal.depuisJson(reponse);
  }

  @override
  Future<EtatChaine> verifierChaine({int limite = 200}) async {
    final List<dynamic> reponse = await _client.rpc<List<dynamic>>(
      'verifier_chaine_audit',
      params: <String, dynamic>{'p_limite': limite},
    );
    if (reponse.isEmpty) {
      throw StateError('aucun verdict de chaine rendu');
    }
    return EtatChaine.depuisJson(reponse.first as Map<String, dynamic>);
  }
}

/// Le service de journal employe par l'application.
final Provider<ServiceJournal> serviceJournalProvider =
    Provider<ServiceJournal>(
      (Ref ref) => ServiceJournalSupabase(Supabase.instance.client),
    );

/// Les filtres de `ADM-04`.
final FutureProvider<FiltresJournal> filtresJournalProvider =
    FutureProvider<FiltresJournal>(
      (Ref ref) => ref.watch(serviceJournalProvider).filtres(),
    );

/// Le verdict de la chaine.
///
/// **Separe de la liste, et non une colonne de plus** : un `lag()` pose sur une
/// liste filtree comparerait chaque entree a la precedente du filtre et non a
/// celle de la chaine, ce qui declarerait le journal rompu des le premier
/// filtre pose.
final FutureProvider<EtatChaine> chaineJournalProvider =
    FutureProvider<EtatChaine>(
      (Ref ref) => ref.watch(serviceJournalProvider).verifierChaine(),
    );
