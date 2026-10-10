import 'package:flutter/foundation.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/planning/service_planning.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';

/// Une heure pleine de la semaine : jour ISO (1 pour lundi) et heure locale.
typedef HeureSemaine = ({int jour, int heure});

/// Une plage de disponibilite : un jour, une heure de debut, une heure de fin.
///
/// DISPO-1 (directeur, 01/10) : l'enseignant ne coche plus des cases jour x
/// heure, il lit et saisit des plages « Lundi | de 17 h | a 23 h ».
///
/// **Rien ne change cote serveur** (K-19) : `weekly_availability` ne stocke
/// que des heures pleines ([Creneau.jour], [Creneau.heure]). Une plage n'est
/// donc qu'une lecture des heures posees : les heures consecutives d'un meme
/// jour forment une plage, et [a] est l'heure qui suit la derniere heure
/// posee (17, 18, ..., 22 donnent « de 17 h a 23 h »). Le pas est d'une heure.
@immutable
class Plage {
  /// Cree une plage. [a] est strictement apres [de], 24 au plus.
  const Plage({required this.jour, required this.de, required this.a})
    : assert(jour >= 1 && jour <= 7, 'jour ISO'),
      assert(de >= 0 && de < a && a <= 24, 'de < a <= 24');

  /// Jour ISO, 1 pour lundi.
  final int jour;

  /// Heure de debut, incluse (0 a 23).
  final int de;

  /// Heure de fin, exclue (1 a 24) : la plage s'arrete a cette heure.
  final int a;

  /// Les heures pleines que la plage pose.
  Set<HeureSemaine> get heures => <HeureSemaine>{
    for (int h = de; h < a; h++) (jour: jour, heure: h),
  };

  /// Vrai quand [heure] tombe dans la plage.
  bool contient(HeureSemaine heure) =>
      heure.jour == jour && heure.heure >= de && heure.heure < a;

  @override
  bool operator ==(Object other) =>
      other is Plage && other.jour == jour && other.de == de && other.a == a;

  @override
  int get hashCode => Object.hash(jour, de, a);

  @override
  String toString() => 'Plage($jour, $de-$a)';
}

/// Les heures posees, sans le fuseau (un enseignant n'en a qu'un).
Set<HeureSemaine> heuresDe(Iterable<Creneau> creneaux) => <HeureSemaine>{
  for (final Creneau c in creneaux) (jour: c.jour, heure: c.heure),
};

/// Les plages qu'on lit dans des heures pleines : par jour, les heures
/// consecutives regroupees, triees par jour puis par debut.
List<Plage> deduirePlages(Iterable<HeureSemaine> heures) {
  final List<HeureSemaine> triees = heures.toSet().toList()
    ..sort(
      (HeureSemaine x, HeureSemaine y) => x.jour != y.jour
          ? x.jour.compareTo(y.jour)
          : x.heure.compareTo(y.heure),
    );
  final List<Plage> plages = <Plage>[];
  int? jour;
  int? de;
  int? fin;
  for (final HeureSemaine h in triees) {
    if (jour == h.jour && fin == h.heure) {
      fin = h.heure + 1;
      continue;
    }
    if (jour != null) {
      plages.add(Plage(jour: jour, de: de!, a: fin!));
    }
    jour = h.jour;
    de = h.heure;
    fin = h.heure + 1;
  }
  if (jour != null) {
    plages.add(Plage(jour: jour, de: de!, a: fin!));
  }
  return plages;
}

/// Ce qu'une saisie de la feuille fera, calcule avant tout envoi.
@immutable
class PlanPlage {
  /// Cree un plan.
  const PlanPlage({
    required this.ajouts,
    required this.retraits,
    required this.fusions,
    this.dejaPosees = const <Plage>[],
  });

  /// Les heures a poser, triees.
  final List<HeureSemaine> ajouts;

  /// Les heures a retirer (seulement celles de la plage modifiee), triees.
  final List<HeureSemaine> retraits;

  /// Pour chaque jour choisi dont la plage chevauche ou touche une plage
  /// deja posee : la plage qui en resultera. La feuille le dit AVANT
  /// d'enregistrer.
  final List<Plage> fusions;

  /// Pour chaque jour choisi ou RIEN ne change : toutes les heures saisies
  /// sont deja posees (plage identique, ou entierement contenue dans une
  /// plage posee) et aucune heure de ce jour n'est retiree. La plage posee
  /// qui les contient ; la feuille le dit au lieu d'annoncer une fusion
  /// (DISPO-1b).
  final List<Plage> dejaPosees;

  /// Vrai quand rien ne change.
  bool get vide => ajouts.isEmpty && retraits.isEmpty;
}

int _ordre(HeureSemaine x, HeureSemaine y) =>
    x.jour != y.jour ? x.jour.compareTo(y.jour) : x.heure.compareTo(y.heure);

/// Le plan d'une saisie : [jours] de [de] a [a], a partir des heures deja
/// posees ([existantes]). [modifiee] est la plage touchee pour la modifier :
/// ses heures qui ne sont plus dans la saisie sont retirees.
///
/// Les heures deja posees ne sont jamais retirees hors de [modifiee] : une
/// plage qui chevauche ou touche une autre plage la rejoint (fusion), elle ne
/// l'ecrase pas.
PlanPlage planifier({
  required Set<HeureSemaine> existantes,
  required Set<int> jours,
  required int de,
  required int a,
  Plage? modifiee,
}) {
  final Set<HeureSemaine> cible = <HeureSemaine>{
    for (final int j in jours)
      for (int h = de; h < a; h++) (jour: j, heure: h),
  };
  // Seules les heures de la plage touchee ENCORE posees sont a retirer :
  // apres un echec partiel, les retraits deja confirmes ne repartent pas, et
  // ceux qui ne le sont pas repartent tous.
  final Set<HeureSemaine> origine = (modifiee?.heures ?? <HeureSemaine>{})
      .intersection(existantes);
  final List<HeureSemaine> retraits = origine.difference(cible).toList()
    ..sort(_ordre);
  final List<HeureSemaine> ajouts = cible.difference(existantes).toList()
    ..sort(_ordre);

  // Ce qui restera posee hors de la plage modifiee : c'est avec ces heures
  // que la saisie peut se reunir.
  final Set<HeureSemaine> autres = existantes.difference(origine);
  final Set<HeureSemaine> apres = <HeureSemaine>{...autres, ...cible};
  final List<Plage> fusions = <Plage>[];
  final List<Plage> dejaPosees = <Plage>[];
  for (final int j in (jours.toList()..sort())) {
    final Plage saisie = Plage(jour: j, de: de, a: a);
    final bool voisine = autres.any(
      (HeureSemaine h) => h.jour == j && h.heure >= de - 1 && h.heure <= a,
    );
    if (!voisine) {
      continue;
    }
    final Plage resultat = deduirePlages(
      apres.where((HeureSemaine h) => h.jour == j),
    ).firstWhere((Plage p) => p.contient((jour: j, heure: de)));
    // Une saisie identique a une plage posee, ou entierement contenue dans
    // elle, ne reunit rien : elle se dit deja posee, pas comme une fusion
    // (DISPO-1b). Seulement si RIEN ne change ce jour-la : une plage touchee
    // du meme jour deplacee dans une plage posee perd ses anciennes heures
    // (retraits), c'est alors bien une fusion, et elle se dit comme telle.
    final bool retraitCeJour = retraits.any((HeureSemaine h) => h.jour == j);
    if (!retraitCeJour && autres.containsAll(saisie.heures)) {
      dejaPosees.add(resultat);
    } else {
      fusions.add(resultat);
    }
  }
  return PlanPlage(
    ajouts: ajouts,
    retraits: retraits,
    fusions: fusions,
    dejaPosees: dejaPosees,
  );
}

/// Le jour ecrit en toutes lettres, avec sa majuscule (« Lundi », E15).
String jourCapitalise(int jour) {
  final String long = t.disponibilites.joursLongs[jour - 1];
  return long[0].toUpperCase() + long.substring(1);
}

/// « de 17 h », la colonne de debut d'une plage.
String libelleDe(int heure) =>
    LibellesGroupe.insecable(t.enseignant.creneaux.plageDe(heure: '$heure'));

/// « a 23 h », ou « a minuit » pour une plage qui finit a 24 h.
// DUREE-INSECABLE (porte par JONCTION-LIGNES-1) : « 23 h » ne se coupe pas.
String libelleA(int heure) => heure == 24
    ? t.enseignant.creneaux.plageAMinuit
    : LibellesGroupe.insecable(t.enseignant.creneaux.plageA(heure: '$heure'));

/// « lundi 17 h » : une heure nommee, pour les confirmations et les echecs.
String nommerHeure(HeureSemaine h) => LibellesGroupe.insecable(
  t.enseignant.creneaux.heureLibelle(
    jour: t.disponibilites.joursLongs[h.jour - 1],
    heure: '${h.heure}',
  ),
);
