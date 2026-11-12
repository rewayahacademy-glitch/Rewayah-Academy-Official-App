/// SUIVI-ELEVE (07/11/2026) : ou en est l'eleve sur le programme, pour lui ou
/// pour sa famille.
///
/// Le serveur decide de tout (`suivi_pedagogique_eleve`, migration
/// 20261115000000) : qui lit (l'eleve lui-meme, le titulaire de son profil,
/// le tuteur de son foyer), l'etape en cours, la date limite et la vitesse.
/// **La vitesse n'est jamais calculee ici** : le client lit [Rythme] tel que
/// la base le rend.
library;

import 'package:flutter/foundation.dart';

/// La vitesse de l'eleve sur son etape, calculee par le serveur.
///
/// Seuils du garde-cap (07/11/2026), sur les regles deja decidees : il n'y a
/// pas d'etat « en avance », rien dans le programme ne le mesure.
enum Rythme {
  /// Le temps ecoule tient dans la duree prevue.
  dansLesTemps('dans_les_temps'),

  /// Au-dela de la duree prevue, avant la date limite.
  auDelaDuPrevu('au_dela_du_prevu'),

  /// La date limite est passee.
  dateLimiteDepassee('date_limite_depassee'),

  /// Pas de date de debut ou pas de duree : la ligne se cache.
  inconnu('inconnu');

  const Rythme(this.valeurSql);

  /// La valeur rendue par la base.
  final String valeurSql;

  /// Lit une valeur de la base ; une valeur inconnue rend [inconnu], jamais
  /// un rythme suppose.
  static Rythme depuisSql(Object? valeur) {
    for (final Rythme r in Rythme.values) {
      if (r.valeurSql == valeur) return r;
    }
    return Rythme.inconnu;
  }
}

/// Le suivi pedagogique d'un eleve, tel que la base le rend.
@immutable
class SuiviPedagogique {
  /// Cree un suivi.
  const SuiviPedagogique({
    required this.etapeNom,
    required this.etapeOrdre,
    this.objectifs = const <String>[],
    this.dureePrevueSemaines,
    this.dateLimite,
    this.semainesEcoulees,
    this.rythme = Rythme.inconnu,
    this.pageReprise,
  });

  /// Lit une ligne de `suivi_pedagogique_eleve`. Pure, pour les tests ; nulle
  /// quand la ligne est illisible (aucune etape).
  static SuiviPedagogique? depuisJson(Object? brut) {
    final Object? ligne = brut is List
        ? (brut.isEmpty ? null : brut.first)
        : brut;
    if (ligne is! Map) return null;
    final String nom = '${ligne['etape_nom'] ?? ''}'.trim();
    if (nom.isEmpty) return null;
    final Object? page = ligne['page_reprise'];
    final int? pageLue = page is num ? page.toInt() : null;
    final Object? objectifs = ligne['objectifs'];
    return SuiviPedagogique(
      etapeNom: nom,
      etapeOrdre: _entier(ligne['etape_ordre']),
      objectifs: <String>[
        for (final Object? o
            in objectifs is List ? objectifs : const <Object?>[])
          if ('${o ?? ''}'.trim().isNotEmpty) '$o'.trim(),
      ],
      dureePrevueSemaines: _entier(ligne['duree_prevue_semaines']),
      dateLimite: DateTime.tryParse('${ligne['date_limite']}'),
      semainesEcoulees: _entier(ligne['semaines_ecoulees']),
      rythme: Rythme.depuisSql(ligne['rythme']),
      pageReprise: pageLue != null && pageLue >= 1 && pageLue <= 604
          ? pageLue
          : null,
    );
  }

  static int? _entier(Object? v) => v is num ? v.toInt() : null;

  /// Le nom de l'etape en cours.
  final String etapeNom;

  /// Son rang dans le programme.
  final int? etapeOrdre;

  /// Ses objectifs, dans l'ordre.
  final List<String> objectifs;

  /// La duree prevue pour la tranche d'age de l'eleve, en semaines.
  final int? dureePrevueSemaines;

  /// La date limite (la prochaine echeance), nulle sans date de debut.
  final DateTime? dateLimite;

  /// Les semaines ecoulees depuis le debut de l'etape.
  final int? semainesEcoulees;

  /// La vitesse, calculee par le serveur.
  final Rythme rythme;

  /// La derniere page du Mushaf presentee en classe (CAHIER-C1), nulle quand
  /// rien n'a ete presente : la ligne se cache.
  final int? pageReprise;
}

/// Les sourates des bases validees d'un eleve, telles que le serveur les
/// compte (`sourates_eleve`, par `ma_progression`) : jamais calculees sur l'appareil.
@immutable
class SouratesValidees {
  /// Cree le compte.
  const SouratesValidees({required this.validees, required this.total})
    : assert(total > 0 && validees >= 0 && validees <= total);

  /// Lit le compte ; nul si l'une des deux valeurs manque ou est incoherente.
  static SouratesValidees? depuis(Object? validees, Object? total) {
    if (validees is! num || total is! num) return null;
    final int v = validees.toInt();
    final int t = total.toInt();
    if (t <= 0 || v < 0 || v > t) return null;
    return SouratesValidees(validees: v, total: t);
  }

  /// Le nombre de sourates validees.
  final int validees;

  /// Le nombre de sourates des bases (17).
  final int total;

  /// Toutes les sourates des bases sont validees.
  bool get toutes => validees == total;
}
