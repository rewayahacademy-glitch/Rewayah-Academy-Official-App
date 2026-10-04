import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Comme `Override` a l'etape 3 : le type d'une famille de providers n'est pas
// exporte par l'entree principale de Riverpod 3, il vit dans `misc.dart`.
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/enums.dart';

/// Une case de la grille hebdomadaire.
///
/// Un motif, pas un instant : une recurrence porte un fuseau IANA et non une
/// heure absolue, sinon tous les cours se decalent au changement d'heure
/// (audit O3). Le jour suit la convention ISO, 1 pour lundi et 7 pour dimanche,
/// comme `extract(isodow)`.
@immutable
class Creneau {
  /// Cree une case.
  const Creneau({
    required this.jour,
    required this.heure,
    required this.fuseau,
    this.poseLe,
  });

  /// Lit une ligne de `weekly_availability`.
  factory Creneau.depuisJson(Map<String, dynamic> json) => Creneau(
    jour: (json['weekday'] as num).toInt(),
    heure: (json['hour_local'] as num).toInt(),
    fuseau: json['timezone_iana'] as String? ?? 'Europe/Paris',
    poseLe: DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal(),
  );

  /// Jour ISO, 1 pour lundi.
  final int jour;

  /// Heure locale pleine, de 0 a 23.
  final int heure;

  /// Le fuseau IANA dans lequel cette heure se lit.
  final String fuseau;

  /// Quand cette case a ete proposee. `null` quand la source ne le dit pas.
  ///
  /// C'est ce qui donne a `TUT-01` la date de la demande de son enfant : le
  /// foyer attend depuis le jour ou il a propose sa premiere heure, et c'est
  /// exactement l'anciennete sur laquelle `ENS-06` trie son feed. **Une seule
  /// source pour un meme fait** : deux calculs de « depuis quand ce foyer
  /// attend » finiraient par afficher deux dates.
  final DateTime? poseLe;

  /// Deux cases sont la meme case quand elles designent la meme heure.
  ///
  /// [poseLe] n'entre pas dans la comparaison, volontairement : la grille
  /// compare des cases, et une case reposee apres avoir ete retiree reste la
  /// meme case de la semaine.
  @override
  bool operator ==(Object other) =>
      other is Creneau &&
      other.jour == jour &&
      other.heure == heure &&
      other.fuseau == fuseau;

  @override
  int get hashCode => Object.hash(jour, heure, fuseau);
}

/// Une seance, telle que `mes_seances_v` l'expose aux trois roles.
///
/// La meme ligne sert a `TUT-01`, `ELV-02` et `ENS-02` : deux vues jumelles
/// finiraient par afficher deux etats differents de la meme seance. Prenom et
/// identifiant immuable des deux cotes, jamais de nom de famille (ADR-008).
@immutable
class Seance {
  /// Cree une seance.
  const Seance({
    required this.id,
    required this.debut,
    required this.fin,
    required this.statut,
    required this.eleveId,
    required this.elevePrenom,
    required this.eleveIdentifiant,
    required this.enseignantId,
    required this.enseignantPrenom,
    required this.enseignantIdentifiant,
    this.minutesInterruption = 0,
    this.enseignantPays,
  });

  /// Lit une ligne de la vue.
  ///
  /// **Parsing strict des bornes** : un `started_at` ou un `ended_at` absent ou
  /// illisible leve une `FormatException`, il ne devient jamais
  /// `DateTime.now()`. L'ancien repli fabriquait une seance « en cours » a
  /// l'instant de la lecture. Pour ecarter une ligne illisible d'une liste
  /// plutot que de faire echouer toute la lecture, voir [Seance.lire].
  factory Seance.depuisJson(Map<String, dynamic> json) => Seance(
    id: json['session_id'] as String,
    debut: _instant(json, 'started_at'),
    fin: _instant(json, 'ended_at'),
    statut: StatutSeance.depuisSql(json['status'] as String?),
    eleveId: json['student_id'] as String? ?? '',
    elevePrenom: json['student_first_name'] as String? ?? '',
    eleveIdentifiant: json['student_immutable_id'] as String? ?? '',
    enseignantId: json['teacher_id'] as String? ?? '',
    enseignantPrenom: json['teacher_first_name'] as String? ?? '',
    enseignantIdentifiant: json['teacher_immutable_id'] as String? ?? '',
    minutesInterruption: (json['prayer_pause_minutes'] as num?)?.toInt() ?? 0,
    // ENS-PAYS-1 : lu des que `mes_seances_v` l'expose (BR-1), nul avant.
    enseignantPays: json['teacher_country'] as String?,
  );

  /// Lit une ligne de la vue, ou rend `null` si elle est illisible.
  ///
  /// Une ligne sans identifiant ou sans bornes lisibles est **ecartee**, jamais
  /// completee : une seance dont on ne sait pas quand elle a lieu ne peut ni
  /// s'afficher, ni decider d'un etat.
  static Seance? lire(Map<String, dynamic> json) {
    if (json['session_id'] is! String) {
      return null;
    }
    try {
      return Seance.depuisJson(json);
    } on FormatException {
      return null;
    }
  }

  static DateTime _instant(Map<String, dynamic> json, String cle) {
    final Object? valeur = json[cle];
    final DateTime? lu = valeur is String ? DateTime.tryParse(valeur) : null;
    if (lu == null) {
      throw FormatException('borne de seance illisible : $cle');
    }
    return lu.toLocal();
  }

  /// Identifiant de la seance.
  final String id;

  /// Debut, dans le fuseau de l'appareil.
  final DateTime debut;

  /// Fin prevue.
  final DateTime fin;

  /// L'etat tel que la base l'a decide. `null` quand il est illisible.
  final StatutSeance? statut;

  /// Identifiant du profil eleve.
  final String eleveId;

  /// Prenom de l'eleve.
  final String elevePrenom;

  /// Identifiant immuable de l'eleve, celui que l'enseignant voit.
  final String eleveIdentifiant;

  /// Identifiant du profil enseignant.
  final String enseignantId;

  /// Prenom de l'enseignant.
  final String enseignantPrenom;

  /// Identifiant immuable de l'enseignant.
  final String enseignantIdentifiant;

  /// Minutes d'interruption consignees, prieres comprises (ADR-017).
  final int minutesInterruption;

  /// Le pays declare par l'enseignant (ENS-PAYS-1). `null` quand il n'est
  /// pas declare ou tant que la vue ne l'expose pas : rien ne s'affiche.
  final String? enseignantPays;

  /// La duree prevue.
  Duration get duree => fin.difference(debut);

  /// Vrai quand la seance est en cours a l'instant donne.
  bool enCoursA(DateTime maintenant) =>
      statut == StatutSeance.enCours ||
      (!maintenant.isBefore(debut) && maintenant.isBefore(fin));

  /// Le temps restant avant le debut. Zero quand il est passe.
  Duration avantDebut(DateTime maintenant) {
    final Duration reste = debut.difference(maintenant);
    return reste.isNegative ? Duration.zero : reste;
  }
}

/// Qui suit qui, tel que `mes_affectations_v` l'expose.
///
/// Elle existe avant la premiere seance : c'est ce qui permet a `TUT-01`
/// d'afficher « en recherche d'un enseignant » plutot qu'un ecran vide.
@immutable
class Affectation {
  /// Cree une affectation.
  const Affectation({
    required this.id,
    required this.enseignantId,
    required this.enseignantPrenom,
    required this.enseignantIdentifiant,
    required this.eleveId,
    required this.elevePrenom,
    required this.creneau,
    required this.depuis,
    this.closeLe,
  });

  /// Lit une ligne de la vue.
  factory Affectation.depuisJson(Map<String, dynamic> json) => Affectation(
    id: json['id'] as String,
    enseignantId: json['teacher_id'] as String? ?? '',
    enseignantPrenom: json['teacher_first_name'] as String? ?? '',
    enseignantIdentifiant: json['teacher_immutable_id'] as String? ?? '',
    eleveId: json['student_id'] as String? ?? '',
    elevePrenom: json['student_first_name'] as String? ?? '',
    creneau: Creneau.depuisJson(json),
    depuis:
        DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal() ??
        DateTime.now(),
    closeLe: DateTime.tryParse(json['ended_at'] as String? ?? '')?.toLocal(),
  );

  /// Identifiant de l'affectation.
  final String id;

  /// Identifiant du profil enseignant.
  final String enseignantId;

  /// Prenom de l'enseignant.
  final String enseignantPrenom;

  /// Identifiant immuable de l'enseignant.
  final String enseignantIdentifiant;

  /// Identifiant du profil eleve.
  final String eleveId;

  /// Prenom de l'eleve.
  final String elevePrenom;

  /// Le rendez-vous hebdomadaire qui en decoule.
  final Creneau creneau;

  /// Depuis quand elle dure.
  final DateTime depuis;

  /// Quand elle a ete close, s'il y a lieu.
  final DateTime? closeLe;

  /// Vrai tant qu'elle lie l'eleve et l'enseignant.
  bool get active => closeLe == null;
}

/// Les disponibilites, les seances et les affectations.
///
/// **Aucune duree n'est calculee ici.** La duree d'une seance vient de la base,
/// qui applique la regle de cet eleve : voir `ServiceRegles`.
abstract interface class ServicePlanning {
  /// Le fuseau dans lequel l'appelant pose et lit ses creneaux.
  ///
  /// Jamais celui de l'appareil : celui-la suit le voyageur, alors que le cours
  /// ne bouge pas.
  Future<String> monFuseau();

  /// Les creneaux poses pour un profil.
  Future<List<Creneau>> disponibilites(String profilId);

  /// Ajoute une case a la grille.
  Future<void> poser({required String profilId, required Creneau creneau});

  /// Retire une case. Une case se pose ou se retire, elle ne se deplace pas.
  Future<void> retirer({required String profilId, required Creneau creneau});

  /// Les seances de l'appelant, quel que soit son role.
  Future<List<Seance>> seances();

  /// Les affectations qui concernent l'appelant.
  Future<List<Affectation>> affectations();
}

/// L'implementation reelle.
class ServicePlanningSupabase implements ServicePlanning {
  /// Cree le service.
  const ServicePlanningSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<String> monFuseau() async {
    final Object? reponse = await _client.rpc<Object?>('mon_fuseau');
    return reponse is String && reponse.isNotEmpty ? reponse : 'Europe/Paris';
  }

  @override
  Future<List<Creneau>> disponibilites(String profilId) async {
    final List<Map<String, dynamic>> lignes = await _client
        .from('weekly_availability')
        .select()
        .eq('profile_id', profilId)
        .order('weekday')
        .order('hour_local');
    return lignes.map(Creneau.depuisJson).toList();
  }

  @override
  Future<void> poser({
    required String profilId,
    required Creneau creneau,
  }) async {
    await _client.from('weekly_availability').insert(<String, dynamic>{
      'profile_id': profilId,
      'weekday': creneau.jour,
      'hour_local': creneau.heure,
      'timezone_iana': creneau.fuseau,
    });
  }

  @override
  Future<void> retirer({
    required String profilId,
    required Creneau creneau,
  }) async {
    await _client
        .from('weekly_availability')
        .delete()
        .eq('profile_id', profilId)
        .eq('weekday', creneau.jour)
        .eq('hour_local', creneau.heure);
  }

  @override
  Future<List<Seance>> seances() async {
    final List<Map<String, dynamic>> lignes = await _client
        .from('mes_seances_v')
        .select()
        .order('started_at');
    return lignes.map(Seance.lire).nonNulls.toList();
  }

  @override
  Future<List<Affectation>> affectations() async {
    final List<Map<String, dynamic>> lignes = await _client
        .from('mes_affectations_v')
        .select()
        .order('created_at');
    return lignes.map(Affectation.depuisJson).toList();
  }
}

/// Le service de planning employe par l'application.
final Provider<ServicePlanning> servicePlanningProvider =
    Provider<ServicePlanning>(
      (Ref ref) => ServicePlanningSupabase(Supabase.instance.client),
    );

/// Le fuseau de l'appelant.
final FutureProvider<String> monFuseauProvider = FutureProvider<String>(
  (Ref ref) => ref.watch(servicePlanningProvider).monFuseau(),
);

/// Les creneaux poses pour un profil donne.
final FutureProviderFamily<List<Creneau>, String> disponibilitesProvider =
    FutureProvider.family<List<Creneau>, String>(
      (Ref ref, String profilId) =>
          ref.watch(servicePlanningProvider).disponibilites(profilId),
    );

/// Les seances de l'appelant.
final FutureProvider<List<Seance>> seancesProvider =
    FutureProvider<List<Seance>>(
      (Ref ref) => ref.watch(servicePlanningProvider).seances(),
    );

/// Les affectations qui concernent l'appelant.
final FutureProvider<List<Affectation>> affectationsProvider =
    FutureProvider<List<Affectation>>(
      (Ref ref) => ref.watch(servicePlanningProvider).affectations(),
    );
