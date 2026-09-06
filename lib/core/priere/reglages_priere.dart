import 'package:flutter/foundation.dart';

import '../domain/enums.dart';

/// Les entrees du calcul des horaires de priere, telles que `prayer_settings`
/// les porte.
///
/// **Ce qui est en base, ce sont les entrees, jamais le resultat.** Si
/// l'enseignant calculait chez lui et annoncait l'heure obtenue, il n'y aurait
/// pas de transparence, seulement une parole contre une autre (ADR-017 section
/// 2.3). Ici l'eleve et son tuteur recalculent la meme minute a partir des
/// memes reglages : c'est l'invariant I8.
@immutable
class ReglagesPriere {
  /// Cree des reglages.
  const ReglagesPriere({
    required this.enseignantId,
    required this.latitude,
    required this.longitude,
    required this.methode,
    required this.madhab,
    this.ajustements = const <Priere, int>{},
    this.fuseau = 'Europe/Paris',
    this.minutesPause = 15,
    this.minutesPreavis = 10,
    this.lieu,
  });

  /// Lit une ligne de `prayer_settings`.
  factory ReglagesPriere.depuisJson(Map<String, dynamic> json) {
    final Map<Priere, int> ajustements = <Priere, int>{};
    final Object? brut = json['adjustments'];
    if (brut is Map<String, dynamic>) {
      for (final MapEntry<String, dynamic> entree in brut.entries) {
        final Priere? priere = Priere.depuisSql(entree.key);
        final int? minutes = _entier(entree.value);
        if (priere != null && minutes != null) {
          ajustements[priere] = minutes;
        }
      }
    }

    return ReglagesPriere(
      enseignantId: json['teacher_id'] as String? ?? '',
      latitude: _reel(json['latitude']) ?? 0,
      longitude: _reel(json['longitude']) ?? 0,
      methode: MethodeCalcul.depuisSql(json['method'] as String?),
      madhab: Madhab.depuisSql(json['madhab'] as String?),
      ajustements: ajustements,
      fuseau: json['timezone_iana'] as String? ?? 'Europe/Paris',
      minutesPause: _entier(json['pause_minutes']) ?? 15,
      minutesPreavis: _entier(json['alert_lead_minutes']) ?? 10,
      lieu: json['place_label'] as String?,
    );
  }

  /// L'enseignant dont ces reglages sont ceux du cours.
  final String enseignantId;

  /// Latitude du lieu de reference.
  final double latitude;

  /// Longitude du lieu de reference.
  final double longitude;

  /// La methode de calcul. `null` quand la base en porte une que ce code ne
  /// connait pas : aucune interruption n'est alors annoncee.
  final MethodeCalcul? methode;

  /// L'ecole qui decide de l'heure du asr. `null` pour la meme raison.
  final Madhab? madhab;

  /// L'ajustement de chaque priere, en minutes, borne a une demi-heure par la
  /// base. Une priere absente de la table ne bouge pas.
  final Map<Priere, int> ajustements;

  /// Le fuseau IANA dans lequel l'enseignant lit ces heures.
  ///
  /// Il ne sert pas au calcul, qui travaille en instants absolus : il sert a
  /// dire dans quelle heure locale l'enseignant a pose ses ajustements.
  final String fuseau;

  /// Combien de temps une priere interrompt le cours.
  final int minutesPause;

  /// Combien de temps a l'avance l'alerte est rendue.
  ///
  /// Il vient des reglages et non du code : si chaque role portait le sien,
  /// l'enseignant serait prevenu dix minutes avant et l'eleve cinq.
  final int minutesPreavis;

  /// Le nom du lieu de reference, tel que l'enseignant l'a ecrit.
  final String? lieu;

  /// L'ajustement d'une priere, zero par defaut.
  int ajustement(Priere priere) => ajustements[priere] ?? 0;

  /// La duree d'une interruption.
  Duration get pause => Duration(minutes: minutesPause);

  /// Le preavis de l'alerte.
  Duration get preavis => Duration(minutes: minutesPreavis);

  /// Vrai quand ces reglages permettent un calcul.
  ///
  /// Faux des qu'une entree est illisible : mieux vaut n'annoncer aucune
  /// interruption que d'en annoncer une fausse.
  bool get calculables => methode != null && madhab != null;

  /// Les memes reglages avec un ajustement change, pour l'ecran de reglage.
  ReglagesPriere avecAjustement(Priere priere, int minutes) => ReglagesPriere(
    enseignantId: enseignantId,
    latitude: latitude,
    longitude: longitude,
    methode: methode,
    madhab: madhab,
    ajustements: <Priere, int>{...ajustements, priere: minutes},
    fuseau: fuseau,
    minutesPause: minutesPause,
    minutesPreavis: minutesPreavis,
    lieu: lieu,
  );

  /// Ce que la base attend en ecriture.
  Map<String, dynamic> versJson() => <String, dynamic>{
    'teacher_id': enseignantId,
    'latitude': latitude,
    'longitude': longitude,
    if (methode != null) 'method': methode!.valeurSql,
    if (madhab != null) 'madhab': madhab!.valeurSql,
    // Les cinq cles, toujours : le declencheur refuse un objet incomplet.
    'adjustments': <String, int>{
      for (final Priere priere in Priere.values)
        priere.valeurSql: ajustement(priere),
    },
    'timezone_iana': fuseau,
    'pause_minutes': minutesPause,
    'alert_lead_minutes': minutesPreavis,
    'place_label': lieu,
  };
}

/// Lit un entier venu de PostgREST, qui rend parfois un nombre et parfois une
/// chaine selon le type SQL d'origine.
int? _entier(Object? valeur) => switch (valeur) {
  final num nombre => nombre.round(),
  final String texte => int.tryParse(texte),
  _ => null,
};

/// Lit un reel. `numeric` traverse le JSON sous les deux formes.
double? _reel(Object? valeur) => switch (valeur) {
  final num nombre => nombre.toDouble(),
  final String texte => double.tryParse(texte),
  _ => null,
};
