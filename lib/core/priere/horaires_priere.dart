import 'package:adhan/adhan.dart' as adhan;
import 'package:flutter/foundation.dart';

import '../domain/enums.dart';
import 'reglages_priere.dart';

/// Les cinq horaires d'une journee, calcules a partir de [ReglagesPriere].
///
/// **Le calcul ne depend de rien d'autre que des reglages et de la date.** Ni
/// de l'appareil, ni du role de celui qui regarde, ni de l'heure qu'il est :
/// c'est ce qui permet a l'eleve, au tuteur et a l'enseignant d'obtenir la meme
/// minute (I8). Le paquet `adhan` est appele par sa porte UTC, `PrayerTimes.utc`,
/// qui prend une date civile en UTC et rend des instants absolus. Sa porte
/// ordinaire rendrait des heures du fuseau de l'appareil, et Paris et Conakry
/// n'annonceraient pas la meme chose.
@immutable
class HorairesPriere {
  const HorairesPriere._(this.instants);

  /// Calcule les cinq horaires du jour civil de [jour].
  ///
  /// Rend des horaires vides quand les reglages sont illisibles : mieux vaut
  /// n'annoncer aucune interruption qu'une fausse.
  factory HorairesPriere.duJour({
    required ReglagesPriere reglages,
    required DateTime jour,
  }) {
    final MethodeCalcul? methode = reglages.methode;
    final Madhab? madhab = reglages.madhab;
    if (methode == null || madhab == null) {
      return const HorairesPriere._(<Priere, DateTime>{});
    }

    final DateTime civil = jour.toUtc();
    final adhan.CalculationParameters parametres = _parametres(methode)
      ..madhab = madhab == Madhab.hanafi
          ? adhan.Madhab.hanafi
          : adhan.Madhab.shafi
      // L'ajustement a la minute pres exige par l'operateur : une heure
      // calculee ne correspond pas toujours a celle de la mosquee de reference.
      ..adjustments = adhan.PrayerAdjustments(
        fajr: reglages.ajustement(Priere.fajr),
        dhuhr: reglages.ajustement(Priere.dhuhr),
        asr: reglages.ajustement(Priere.asr),
        maghrib: reglages.ajustement(Priere.maghrib),
        isha: reglages.ajustement(Priere.isha),
      );

    final adhan.PrayerTimes calcul = adhan.PrayerTimes.utc(
      adhan.Coordinates(reglages.latitude, reglages.longitude),
      adhan.DateComponents(civil.year, civil.month, civil.day),
      parametres,
    );

    return HorairesPriere._(<Priere, DateTime>{
      Priere.fajr: calcul.fajr.toLocal(),
      Priere.dhuhr: calcul.dhuhr.toLocal(),
      Priere.asr: calcul.asr.toLocal(),
      Priere.maghrib: calcul.maghrib.toLocal(),
      Priere.isha: calcul.isha.toLocal(),
    });
  }

  /// L'instant de chaque priere.
  ///
  /// Dans le fuseau de l'appareil, comme une seance lue : c'est un instant
  /// absolu, deux appareils de deux continents y lisent le meme moment sous
  /// deux heures locales differentes.
  final Map<Priere, DateTime> instants;

  /// L'instant d'une priere, `null` quand les reglages ne permettent pas de le
  /// calculer.
  DateTime? operator [](Priere priere) => instants[priere];

  /// Vrai quand aucun horaire n'a pu etre calcule.
  bool get vides => instants.isEmpty;
}

/// Une interruption de cours prevue, avec ce qu'elle vaut en temps.
///
/// Elle est annoncee **avant** le cours, jamais decouverte pendant (ADR-017
/// section 2.3). Sa duree ne sort pas d'ici : elle vient de `pause_minutes`,
/// que l'enseignant pose et que ses eleves lisent.
@immutable
class InterruptionPriere {
  /// Cree une interruption.
  const InterruptionPriere({
    required this.priere,
    required this.debut,
    required this.duree,
    required this.preavis,
  });

  /// La priere qui l'occasionne.
  final Priere priere;

  /// Quand elle commence.
  final DateTime debut;

  /// Combien de temps elle dure.
  final Duration duree;

  /// Combien de temps a l'avance elle est annoncee.
  final Duration preavis;

  /// Quand elle se termine.
  DateTime get fin => debut.add(duree);

  /// A partir de quand l'alerte est rendue.
  DateTime get alerteA => debut.subtract(preavis);

  /// Vrai quand l'alerte doit etre visible a cet instant : entre le preavis et
  /// la fin de l'interruption.
  bool alerteVisibleA(DateTime maintenant) =>
      !maintenant.isBefore(alerteA) && maintenant.isBefore(fin);

  /// Vrai quand elle croise l'intervalle donne.
  ///
  /// Bornes semi-ouvertes, comme les seances en base : une interruption qui
  /// s'acheve a l'instant ou le cours commence ne l'interrompt pas. Meme
  /// convention que `guard_session_overlap` depuis le defaut 3.9.
  bool croise(DateTime debutFenetre, DateTime finFenetre) =>
      debut.isBefore(finFenetre) && fin.isAfter(debutFenetre);
}

/// Les interruptions prevues entre deux instants.
///
/// Les horaires des trois jours civils qui entourent la fenetre sont calcules,
/// puis filtres par instant. **Aucun croisement ne passe par une heure
/// locale** : entre Paris et Conakry, la meme priere ne tombe pas le meme jour
/// civil, et un croisement par heure locale se tromperait de journee deux fois
/// par an, au changement d'heure.
List<InterruptionPriere> interruptionsEntre({
  required ReglagesPriere reglages,
  required DateTime debut,
  required DateTime fin,
}) {
  if (!reglages.calculables || !fin.isAfter(debut)) {
    return const <InterruptionPriere>[];
  }

  final List<InterruptionPriere> trouvees = <InterruptionPriere>[];
  final DateTime pivot = debut.toUtc();
  for (int decalage = -1; decalage <= 1; decalage++) {
    final HorairesPriere horaires = HorairesPriere.duJour(
      reglages: reglages,
      jour: pivot.add(Duration(days: decalage)),
    );
    for (final MapEntry<Priere, DateTime> entree in horaires.instants.entries) {
      final InterruptionPriere interruption = InterruptionPriere(
        priere: entree.key,
        debut: entree.value,
        duree: reglages.pause,
        preavis: reglages.preavis,
      );
      if (interruption.croise(debut, fin)) {
        trouvees.add(interruption);
      }
    }
  }

  trouvees.sort(
    (InterruptionPriere a, InterruptionPriere b) => a.debut.compareTo(b.debut),
  );
  return trouvees;
}

/// La correspondance avec le paquet de calcul, nom pour nom.
adhan.CalculationParameters _parametres(MethodeCalcul methode) =>
    switch (methode) {
      MethodeCalcul.ligueMondiale =>
        adhan.CalculationMethod.muslim_world_league,
      MethodeCalcul.egypte => adhan.CalculationMethod.egyptian,
      MethodeCalcul.karachi => adhan.CalculationMethod.karachi,
      MethodeCalcul.ummAlQura => adhan.CalculationMethod.umm_al_qura,
      MethodeCalcul.dubai => adhan.CalculationMethod.dubai,
      MethodeCalcul.moonSighting =>
        adhan.CalculationMethod.moon_sighting_committee,
      MethodeCalcul.ameriqueDuNord => adhan.CalculationMethod.north_america,
      MethodeCalcul.koweit => adhan.CalculationMethod.kuwait,
      MethodeCalcul.qatar => adhan.CalculationMethod.qatar,
      MethodeCalcul.singapour => adhan.CalculationMethod.singapore,
      MethodeCalcul.teheran => adhan.CalculationMethod.tehran,
      MethodeCalcul.turquie => adhan.CalculationMethod.turkey,
    }.getParameters();
