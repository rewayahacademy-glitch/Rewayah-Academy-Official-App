// B2.2 bis (c), plan de nuit du pilote (24/10/2026) : la direction ajoute un
// creneau hebdomadaire a une Classe. Le serveur repasse le predicat
// d'affectation (memes refus que le deplacement d'une Classe) puis cree aussitot
// les seances des quatre prochaines semaines
// (`ajouter_creneau_classe_admin`, migration 20261025020000).
//
// Classe a plusieurs creneaux et mixite (decisions D1 et D2 du 29/10/2026,
// migration 20261029170000) : la direction lit les creneaux d'une Classe, en
// modifie ou en retire un (ses seances a venir sont annulees avec le motif,
// jamais supprimees ; familles et enseignant prevenus), et regle son genre
// (hommes, femmes ou mixte).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../capacites/port_enseignants_classe.dart' show GenreClasse;
import 'creneaux_classe_supabase.dart';

/// Un creneau hebdomadaire d'une Classe, dans son fuseau.
typedef CreneauClasse = ({int jour, int heure});

/// Pourquoi le serveur refuse un geste sur un creneau.
enum MotifRefusCreneau {
  /// Le dernier creneau d'une Classe ne se retire pas.
  dernier,

  /// La Classe a deja ce creneau.
  existant,

  /// Le creneau n'existe plus (un autre ecran l'a change).
  introuvable,

  /// La Classe est fermee.
  classeFermee,
}

/// Un refus du serveur sur un creneau, en motif ferme.
class CreneauRefuse implements Exception {
  /// Cree le refus.
  const CreneauRefuse(this.motif);

  /// Le motif.
  final MotifRefusCreneau motif;

  @override
  String toString() => 'CreneauRefuse(${motif.name})';
}

/// Les creneaux d'une Classe.
abstract interface class ServiceCreneauxClasse {
  /// Ajoute le creneau ([jour] ISO 1 a 7, [heure] 0 a 23, dans le fuseau de
  /// la Classe) et rend le nombre de seances creees : 0 quand la Classe
  /// avait deja ce creneau. Un refus du predicat arrive en
  /// `AffectationRefusee`.
  Future<int> ajouter({
    required String groupeId,
    required int jour,
    required int heure,
  });

  /// Les creneaux de la Classe, par jour puis par heure.
  Future<List<CreneauClasse>> lister(String groupeId);

  /// Deplace un creneau et rend le nombre de seances creees. Les seances a
  /// venir de l'ancien creneau sont annulees avec [motif]. Un refus du
  /// predicat arrive en `AffectationRefusee`, un autre en [CreneauRefuse].
  Future<int> modifier({
    required String groupeId,
    required CreneauClasse ancien,
    required CreneauClasse nouveau,
    required String motif,
  });

  /// Retire un creneau et rend le nombre de seances annulees (avec
  /// [motif]). Le dernier creneau refuse ([MotifRefusCreneau.dernier]).
  Future<int> retirer({
    required String groupeId,
    required CreneauClasse creneau,
    required String motif,
  });

  /// Regle le genre de la Classe (hommes, femmes ou mixte, D1). Un
  /// enseignant attitre incompatible arrive en `AffectationRefusee`.
  Future<void> reglerGenre({
    required String groupeId,
    required GenreClasse genre,
    required String motif,
  });
}

/// Le service employe par l'application.
final Provider<ServiceCreneauxClasse> serviceCreneauxClasseProvider =
    Provider<ServiceCreneauxClasse>(
      (Ref ref) => CreneauxClasseSupabase(Supabase.instance.client),
    );

/// Les creneaux d'une Classe, relus apres chaque geste.
final FutureProviderFamily<List<CreneauClasse>, String> creneauxClasseProvider =
    FutureProvider.family<List<CreneauClasse>, String>(
      (Ref ref, String groupeId) =>
          ref.watch(serviceCreneauxClasseProvider).lister(groupeId),
    );
