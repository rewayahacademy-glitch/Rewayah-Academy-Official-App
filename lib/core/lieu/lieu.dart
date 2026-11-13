// HORLOGE-ET-LIEU, partie B (12/11/2026, H5) : la ville de chacun.
//
// Chaque foyer (par son adulte) et chaque enseignant indique sa ville : le nom,
// le pays, le fuseau et le CENTRE de la ville, jamais une adresse ni la position
// de l'appareil. La liste est cote serveur (`public.villes_ref`, GeoNames,
// CC BY 4.0) ; le client n'envoie jamais qu'un identifiant de ville, et le
// serveur recopie tout le reste.
//
// Un enfant ne saisit rien : il herite de la ville de son foyer.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';
import '../domain/enums.dart';
import '../session/session_controleur.dart';
import '../session/session_state.dart';
import 'lieu_supabase.dart';

/// Une ville de la liste.
@immutable
class Ville {
  /// Cree une ville.
  const Ville({
    required this.id,
    required this.nom,
    required this.paysCode,
    required this.fuseau,
    this.nomAr,
    this.region,
    this.milliers = 0,
  });

  /// Lit une ligne rendue par `rechercher_villes` ou `villes_proposees`, ou
  /// `null` quand elle ne se lit pas.
  static Ville? lire(Object? brut) {
    if (brut is! Map) return null;
    final Object? id = brut['id'];
    final Object? nom = brut['nom'];
    final Object? pays = brut['pays_code'];
    final Object? fuseau = brut['fuseau_iana'];
    if (id is! int || nom is! String || pays is! String || fuseau is! String) {
      return null;
    }
    final Object? nomAr = brut['nom_ar'];
    final Object? region = brut['region'];
    final Object? milliers = brut['milliers'];
    return Ville(
      id: id,
      nom: nom,
      nomAr: nomAr is String && nomAr.isNotEmpty ? nomAr : null,
      paysCode: pays,
      region: region is String && region.isNotEmpty ? region : null,
      fuseau: fuseau,
      milliers: milliers is int ? milliers : 0,
    );
  }

  /// L'identifiant de la liste (GeoNames).
  final int id;

  /// Le nom latin.
  final String nom;

  /// Le nom arabe, quand la liste en donne un (pays arabes).
  final String? nomAr;

  /// Le code ISO du pays.
  final String paysCode;

  /// La region, qui distingue deux villes de meme nom.
  final String? region;

  /// Le fuseau IANA.
  final String fuseau;

  /// La population, en milliers.
  final int milliers;

  @override
  bool operator ==(Object other) => other is Ville && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Ce que le serveur dit de l'etape de la ville pour la personne connectee.
@immutable
class EtatLieu {
  /// Cree l'etat.
  const EtatLieu({
    required this.requis,
    required this.reportsRestants,
    required this.reportsMax,
  });

  /// Lit la reponse de `mon_lieu_a_fournir`, ou `null`.
  static EtatLieu? lire(Object? brut) {
    if (brut is! Map) return null;
    final Object? requis = brut['requis'];
    final Object? restants = brut['reports_restants'];
    final Object? max = brut['reports_max'];
    if (requis is! bool || restants is! int || max is! int) return null;
    return EtatLieu(requis: requis, reportsRestants: restants, reportsMax: max);
  }

  /// Vrai quand la personne doit encore choisir sa ville.
  final bool requis;

  /// Combien de fois elle peut encore reporter l'etape.
  final int reportsRestants;

  /// Le nombre de reports permis (reglage de la direction).
  final int reportsMax;

  /// Vrai quand « Plus tard » peut encore se montrer.
  bool get peutReporter => requis && reportsRestants > 0;
}

/// Le lieu enregistre de la personne (sans les coordonnees : le client n'en a
/// pas besoin, le serveur les garde pour les heures de priere).
@immutable
class LieuChoisi {
  /// Cree le lieu.
  const LieuChoisi({
    required this.ville,
    required this.paysCode,
    required this.fuseau,
    required this.verifie,
  });

  /// Lit la reponse de `mon_lieu`, ou `null` quand aucune ville n'est choisie.
  static LieuChoisi? lire(Object? brut) {
    if (brut is! Map) return null;
    final Object? ville = brut['ville'];
    final Object? pays = brut['pays_code'];
    final Object? fuseau = brut['fuseau_iana'];
    if (ville is! String || pays is! String || fuseau is! String) return null;
    return LieuChoisi(
      ville: ville,
      paysCode: pays,
      fuseau: fuseau,
      verifie: brut['verifie'] == true,
    );
  }

  /// Le nom de la ville.
  final String ville;

  /// Le code ISO du pays.
  final String paysCode;

  /// Le fuseau IANA de la ville.
  final String fuseau;

  /// Vrai quand la direction a verifie la ville (enseignant).
  final bool verifie;
}

/// Ce que rend le choix d'une ville.
@immutable
class ResultatVille {
  /// Cree le resultat.
  const ResultatVille({required this.disponibilitesARelire});

  /// Vrai quand un enseignant a change de fuseau : ses disponibilites gardent
  /// leurs instants, et il doit les relire.
  final bool disponibilitesARelire;
}

/// L'acces aux fonctions du lieu.
abstract interface class PortLieu {
  /// Les villes dont le nom commence par [texte].
  Future<List<Ville>> rechercher(String texte);

  /// Les plus grandes villes dont le fuseau a, aujourd'hui, ce decalage.
  Future<List<Ville>> proposees(int decalageMinutes);

  /// Choisit la ville [villeId].
  Future<ResultatVille> enregistrer(int villeId);

  /// L'etape est-elle a fournir, et combien de reports restent.
  Future<EtatLieu> aFournir();

  /// Reporte l'etape ; echoue quand il ne reste aucun report.
  Future<EtatLieu> reporter();

  /// La ville enregistree, ou `null`.
  Future<LieuChoisi?> monLieu();
}

/// Sans serveur (PLAYGROUND, test sans Supabase) : aucune ville, aucune etape.
class LieuAbsent implements PortLieu {
  /// Cree le port vide.
  const LieuAbsent();

  @override
  Future<List<Ville>> rechercher(String texte) async => const <Ville>[];

  @override
  Future<List<Ville>> proposees(int decalageMinutes) async => const <Ville>[];

  @override
  Future<ResultatVille> enregistrer(int villeId) async =>
      const ResultatVille(disponibilitesARelire: false);

  @override
  Future<EtatLieu> aFournir() async =>
      const EtatLieu(requis: false, reportsRestants: 0, reportsMax: 0);

  @override
  Future<EtatLieu> reporter() => aFournir();

  @override
  Future<LieuChoisi?> monLieu() async => null;
}

/// Le port employe par l'application.
final Provider<PortLieu> portLieuProvider = Provider<PortLieu>((Ref ref) {
  if (Env.playgroundActif) return const LieuAbsent();
  try {
    return LieuSupabase(Supabase.instance.client);
  } on Object {
    return const LieuAbsent();
  }
});

/// L'etat de l'etape de la ville de la personne connectee : lu une fois par
/// compte (le role et l'identifiant le renouvellent), `null` pour qui n'a pas
/// de ville a donner (eleve, direction, comptable, controleur).
final FutureProvider<EtatLieu?> etatLieuProvider = FutureProvider<EtatLieu?>((
  Ref ref,
) async {
  final AppRole? role = ref.watch(
    sessionProvider.select((SessionState s) => s.role),
  );
  ref.watch(sessionProvider.select((SessionState s) => s.profileId));
  if (role != AppRole.guardian && role != AppRole.teacher) return null;
  return ref.watch(portLieuProvider).aFournir();
}, retry: (int _, Object _) => null);

/// Vrai quand la personne connectee doit choisir sa ville MAINTENANT : le
/// routeur la mene alors a `/ville`. Faux pendant la lecture, en cas d'echec
/// et hors ligne : jamais bloque hors ligne, la question se repose a la lecture
/// suivante.
final Provider<bool> villeAFournirProvider = Provider<bool>((Ref ref) {
  final EtatLieu? etat = ref.watch(etatLieuProvider).value;
  return etat != null && etat.requis && !ref.watch(villeReporteeProvider);
});

/// Vrai quand la personne a reporte l'etape pendant cette ouverture : le
/// routeur ne la ramene pas a `/ville` avant la prochaine ouverture.
final NotifierProvider<VilleReportee, bool> villeReporteeProvider =
    NotifierProvider<VilleReportee, bool>(VilleReportee.new);

/// Le report de l'etape pendant cette ouverture de l'application.
class VilleReportee extends Notifier<bool> {
  @override
  bool build() => false;

  /// Note que la personne a reporte l'etape.
  void reporter() => state = true;
}
