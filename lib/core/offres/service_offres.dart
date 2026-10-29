import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `FutureProviderFamily` n'est pas exporte par l'entree principale de
// `flutter_riverpod` (meme convention que `service_groupes.dart`).
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'offre_horaire.dart';

/// La cle d'une recherche d'offres : un apprenant et le fuseau d'affichage.
@immutable
class CleOffres {
  /// Cree une cle.
  const CleOffres({required this.membreId, required this.fuseau});

  /// L'apprenant concerne.
  final String membreId;

  /// Le fuseau dans lequel les horaires doivent etre exprimes.
  final String fuseau;

  @override
  bool operator ==(Object other) =>
      other is CleOffres &&
      other.membreId == membreId &&
      other.fuseau == fuseau;

  @override
  int get hashCode => Object.hash(membreId, fuseau);
}

/// Les offres horaires vitrines, le profil d'apprentissage, et l'intention.
///
/// **Le filtrage de compatibilite est serveur.** La fonction serveur ne rend
/// que ce qui convient a l'apprenant nomme ; le client ne recoit jamais le
/// catalogue entier pour le filtrer lui-meme. Deux raisons : un filtre client
/// se contourne, et un catalogue entier dirait a une famille quels autres
/// creneaux existent pour d'autres publics.
abstract interface class ServiceOffres {
  /// Les regles de l'academie : capacites, minimum de lancement, durees,
  /// pause. Jamais de constante ecrite dans un widget.
  Future<ReglesAcademie> regles();

  /// Les langues d'enseignement actives, dans l'ordre publie.
  Future<List<LangueCours>> langues();

  /// Tout le referentiel des langues, retirees comprises, dans l'ordre publie.
  ///
  /// Sert a NOMMER une langue deja enregistree (le profil enseignant porte des
  /// codes, CAND-Q15 lot langue) : une langue retiree de l'onboarding reste
  /// lisible sur les profils qui la portent. Seules les actives se proposent.
  Future<List<LangueCours>> referentielLangues();

  /// Les tranches d'age actives, dans l'ordre publie.
  Future<List<CohorteAge>> cohortes();

  /// Ou en est chaque apprenant du foyer.
  Future<List<ParcoursApprenant>> parcours();

  /// Enregistre les reponses de personnalisation d'un apprenant.
  ///
  /// [fuseau] est confirme par la famille, jamais preleve d'une position :
  /// l'appareil propose, la personne valide.
  Future<void> enregistrerProfil({
    required String membreId,
    required String langueCode,
    required String cohorteCode,
    required NiveauDeclare niveau,
    required ObjectifApprentissage objectif,
    required String fuseau,
  });

  /// Les offres compatibles avec cet apprenant, exprimees dans [fuseau].
  Future<List<OffreHoraire>> offresCompatibles(CleOffres cle);

  /// Enregistre le choix d'une offre.
  ///
  /// **N'affecte aucun groupe, n'appelle aucun enseignant, ne reserve aucune
  /// place.** Le libelle affiche apres cet appel doit le dire.
  Future<String> choisirOffre(CleOffres cle, String offreId);

  /// Renonce a la preference enregistree.
  Future<void> renoncer({required String membreId, required String motif});

  /// Signale qu'aucun horaire propose ne convient.
  ///
  /// Cree **un signal de demande non satisfaite**, rien de plus : ni groupe, ni
  /// recherche d'enseignant, ni promesse d'horaire futur.
  Future<void> signalerHoraireInsatisfait({
    required String membreId,
    required String fuseau,
    String? langueCode,
    String? cohorteCode,
  });
}

/// L'implementation reelle.
class ServiceOffresSupabase implements ServiceOffres {
  /// Cree le service.
  const ServiceOffresSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<ReglesAcademie> regles() async {
    final Map<String, dynamic>? json = await _client.rpc<Map<String, dynamic>?>(
      'regles_academie',
    );
    // `regles_academie()` rend `null` a un compte hors parcours. Les defauts de
    // `ReglesAcademie.depuisJson` prennent alors le relais : un ecran sans
    // regles vaut mieux qu'un ecran en erreur, et aucune de ces valeurs n'ouvre
    // quoi que ce soit -- elles ne servent qu'a ecrire une phrase.
    return ReglesAcademie.depuisJson(json ?? const <String, dynamic>{});
  }

  @override
  Future<List<LangueCours>> langues() async {
    // Admission, lot B (29/10/2026) : lisible sans compte, pour l'inscription
    // avant le compte ; code et libelle des langues actives, dans l'ordre
    // publie (`langues_cours_publiques`, 20261029180000).
    final List<dynamic> lignes = await _client.rpc<List<dynamic>>(
      'langues_cours_publiques',
    );
    return <LangueCours>[
      for (final Object? l in lignes)
        if (l is Map<String, dynamic>) LangueCours.depuisJson(l),
    ];
  }

  @override
  Future<List<LangueCours>> referentielLangues() async {
    // Sans filtre `actif` : la policy `langues_cours_lecture` (0043) laisse
    // lire toutes les lignes a tout compte connecte. Meme ordre que le
    // declencheur serveur qui ramene un nom a son code (ordre, puis code).
    final List<Map<String, dynamic>> lignes = await _client
        .from('langues_cours')
        .select('code, nom_humain, actif')
        .order('ordre', ascending: true)
        .order('code', ascending: true);
    return lignes.map(LangueCours.depuisJson).toList(growable: false);
  }

  @override
  Future<List<CohorteAge>> cohortes() async {
    final List<Map<String, dynamic>> lignes = await _client
        .from('cohortes_age')
        .select('code, nom_humain, type_public')
        .eq('actif', true)
        .order('ordre', ascending: true);
    return lignes.map(CohorteAge.depuisJson).toList(growable: false);
  }

  @override
  Future<List<ParcoursApprenant>> parcours() async {
    final List<Map<String, dynamic>> lignes = await _client
        .from('v_parcours_onboarding')
        .select();
    return lignes.map(ParcoursApprenant.depuisJson).toList(growable: false);
  }

  @override
  Future<void> enregistrerProfil({
    required String membreId,
    required String langueCode,
    required String cohorteCode,
    required NiveauDeclare niveau,
    required ObjectifApprentissage objectif,
    required String fuseau,
  }) => _client.rpc<void>(
    'enregistrer_profil_apprentissage',
    params: <String, dynamic>{
      'p_membre_id': membreId,
      'p_langue_code': langueCode,
      'p_cohorte': cohorteCode,
      'p_niveau_declare': niveau.valeurSql,
      'p_objectif': objectif.valeurSql,
      'p_fuseau_iana': fuseau,
    },
  );

  @override
  Future<List<OffreHoraire>> offresCompatibles(CleOffres cle) async {
    final List<dynamic> reponse = await _client.rpc<List<dynamic>>(
      'offres_compatibles',
      params: <String, dynamic>{
        'p_membre_id': cle.membreId,
        'p_fuseau_vue': cle.fuseau,
      },
    );
    return reponse
        .map(
          (dynamic ligne) =>
              OffreHoraire.depuisJson(ligne as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  @override
  Future<String> choisirOffre(CleOffres cle, String offreId) =>
      _client.rpc<String>(
        'choisir_offre_horaire',
        params: <String, dynamic>{
          'p_membre_id': cle.membreId,
          'p_offre_id': offreId,
          'p_fuseau_vue': cle.fuseau,
        },
      );

  @override
  Future<void> renoncer({required String membreId, required String motif}) =>
      _client.rpc<void>(
        'renoncer_intention_horaire',
        params: <String, dynamic>{'p_membre_id': membreId, 'p_motif': motif},
      );

  @override
  Future<void> signalerHoraireInsatisfait({
    required String membreId,
    required String fuseau,
    String? langueCode,
    String? cohorteCode,
  }) => _client.rpc<void>(
    'signaler_horaire_insatisfait',
    params: <String, dynamic>{
      'p_membre_id': membreId,
      // Le detail sert a l'academie pour lire la demande non satisfaite. Il ne
      // porte AUCUN horaire souhaite : ce parcours ne demande jamais « quel
      // horaire voulez-vous », et enregistrer un voeu ici creerait exactement
      // l'attente que la mission interdit.
      'p_detail': <String, dynamic>{
        'fuseau': fuseau,
        'langue': ?langueCode,
        'cohorte': ?cohorteCode,
      },
    },
  );
}

/// Le service des offres employe par l'application.
final Provider<ServiceOffres> serviceOffresProvider = Provider<ServiceOffres>(
  (Ref ref) => ServiceOffresSupabase(Supabase.instance.client),
);

/// Les regles de l'academie.
final FutureProvider<ReglesAcademie> reglesAcademieProvider =
    FutureProvider<ReglesAcademie>(
      (Ref ref) => ref.watch(serviceOffresProvider).regles(),
    );

/// Les langues d'enseignement publiees.
final FutureProvider<List<LangueCours>> languesCoursProvider =
    FutureProvider<List<LangueCours>>(
      (Ref ref) => ref.watch(serviceOffresProvider).langues(),
    );

/// Tout le referentiel des langues, retirees comprises : ce que le profil
/// enseignant lit pour nommer les codes qu'il porte et proposer les langues
/// actives (FORM-L8, CAND-Q15 lot langue).
final FutureProvider<List<LangueCours>> referentielLanguesProvider =
    FutureProvider<List<LangueCours>>(
      (Ref ref) => ref.watch(serviceOffresProvider).referentielLangues(),
    );

/// Les tranches d'age publiees.
final FutureProvider<List<CohorteAge>> cohortesAgeProvider =
    FutureProvider<List<CohorteAge>>(
      (Ref ref) => ref.watch(serviceOffresProvider).cohortes(),
    );

/// Ou en est chaque apprenant du foyer.
final FutureProvider<List<ParcoursApprenant>> parcoursFoyerProvider =
    FutureProvider<List<ParcoursApprenant>>(
      (Ref ref) => ref.watch(serviceOffresProvider).parcours(),
    );

/// Les offres compatibles avec un apprenant, dans un fuseau donne.
final FutureProviderFamily<List<OffreHoraire>, CleOffres>
offresCompatiblesProvider =
    FutureProvider.family<List<OffreHoraire>, CleOffres>(
      (Ref ref, CleOffres cle) =>
          ref.watch(serviceOffresProvider).offresCompatibles(cle),
    );

/// Pourquoi une lecture du parcours a echoue, dit en termes d'ecran.
enum PanneParcours {
  /// Le serveur n'a pas encore les tables ou fonctions du parcours : la
  /// migration `0043` n'est pas appliquee. Etat indisponible honnete, jamais
  /// une erreur a reessayer.
  indisponible,

  /// Le reseau ne repond pas : on garde les reponses et on propose de
  /// reessayer.
  horsLigne,

  /// Toute autre erreur.
  erreur,
}

/// Classe une erreur de lecture du parcours.
///
/// `42P01` (table inconnue), `42883` (fonction inconnue), `PGRST202` et
/// `PGRST205` (fonction ou relation absente du cache de schema) disent que le
/// backend du parcours n'existe pas encore sur ce serveur.
PanneParcours classerPanneParcours(Object erreur) {
  if (erreur is PostgrestException) {
    return switch (erreur.code) {
      '42P01' ||
      '42883' ||
      'PGRST202' ||
      'PGRST205' => PanneParcours.indisponible,
      _ => PanneParcours.erreur,
    };
  }
  final String texte = erreur.toString();
  if (texte.contains('SocketException') ||
      texte.contains('ClientException') ||
      texte.contains('Failed host lookup') ||
      texte.contains('Connection refused')) {
    return PanneParcours.horsLigne;
  }
  return PanneParcours.erreur;
}

/// Les reponses en cours d'un apprenant, gardees hors de la page.
///
/// Quitter le questionnaire (Retour, autre onglet) puis y revenir retrouve la
/// page et les reponses deja touchees : retour sans perte, reprise. Rien n'est
/// ecrit au serveur avant la fin des questions.
class BrouillonParcours {
  /// Page courante, nulle tant que l'on ne sait pas d'ou partir.
  int? page;

  /// Tranche d'age touchee.
  String? cohorte;

  /// Langue du cours touchee.
  String? langue;

  /// Fuseau touche.
  String? fuseau;

  /// Niveau declare touche.
  NiveauDeclare? niveau;

  /// Objectif touche.
  ObjectifApprentissage? objectif;

  /// Moments de la journee retenus (noms d'enum).
  final Set<String> moments = <String>{};
}

/// Les brouillons du questionnaire, par apprenant, pour la duree de la
/// session de l'application.
final Provider<Map<String, BrouillonParcours>> brouillonsParcoursProvider =
    Provider<Map<String, BrouillonParcours>>(
      (Ref ref) => <String, BrouillonParcours>{},
    );
