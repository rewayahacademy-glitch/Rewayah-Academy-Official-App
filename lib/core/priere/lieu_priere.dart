import 'package:flutter/foundation.dart';

import '../domain/enums.dart';

/// Le lieu de priere d'un enseignant et ses reglages, tels que
/// `priere_reglages_lire` les rend (PRIERE-1).
///
/// Lu par l'enseignant lui-meme et par la direction seulement : la position est
/// une donnee personnelle, jamais rendue a un eleve ni a un tuteur.
@immutable
class LieuPriere {
  /// Cree un lieu.
  const LieuPriere({
    required this.enseignantId,
    required this.lieu,
    required this.latitude,
    required this.longitude,
    required this.fuseau,
    required this.methode,
    required this.ecoleAsr,
    required this.methodeSurchargee,
    required this.ecoleSurchargee,
    required this.ajustements,
    required this.assisteVendredi,
    required this.vendrediDebut,
    required this.vendrediFin,
  });

  /// Lit la reponse de `priere_reglages_lire`.
  factory LieuPriere.depuisJson(Map<String, dynamic> json) {
    final Map<Priere, int> ajustements = <Priere, int>{};
    final Object? brut = json['ajustements'];
    if (brut is Map<String, dynamic>) {
      for (final MapEntry<String, dynamic> e in brut.entries) {
        final Priere? p = Priere.depuisSql(e.key);
        final Object? v = e.value;
        if (p != null && v is num) {
          ajustements[p] = v.round();
        }
      }
    }
    return LieuPriere(
      enseignantId: json['enseignant_id'] as String? ?? '',
      lieu: json['lieu'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      fuseau: json['fuseau'] as String? ?? '',
      methode: MethodeCalcul.depuisSql(json['methode'] as String?),
      ecoleAsr: Madhab.depuisSql(json['ecole_asr'] as String?),
      methodeSurchargee: json['methode_surcharge'] != null,
      ecoleSurchargee: json['ecole_asr_surcharge'] != null,
      ajustements: ajustements,
      assisteVendredi: json['assiste_vendredi'] == true,
      vendrediDebut: json['vendredi_debut'] as String? ?? '12:30',
      vendrediFin: json['vendredi_fin'] as String? ?? '14:30',
    );
  }

  /// L'enseignant.
  final String enseignantId;

  /// Le nom du lieu, tel que la direction l'a ecrit.
  final String lieu;

  /// Latitude, en degres.
  final double latitude;

  /// Longitude, en degres.
  final double longitude;

  /// Le fuseau IANA de l'enseignant.
  final String fuseau;

  /// La methode en vigueur pour lui (la sienne, ou celle de l'ecole).
  final MethodeCalcul? methode;

  /// L'ecole d'Asr en vigueur pour lui.
  final Madhab? ecoleAsr;

  /// Vrai quand la methode est propre a cet enseignant.
  final bool methodeSurchargee;

  /// Vrai quand l'ecole d'Asr est propre a cet enseignant.
  final bool ecoleSurchargee;

  /// L'ajustement de chaque priere, en minutes (de -30 a +30).
  final Map<Priere, int> ajustements;

  /// Vrai quand il assiste a la priere du vendredi.
  final bool assisteVendredi;

  /// Debut de sa plage du vendredi, `HH:MM`, heure de l'enseignant.
  final String vendrediDebut;

  /// Fin de sa plage du vendredi, `HH:MM`.
  final String vendrediFin;

  /// L'ajustement d'une priere, zero par defaut.
  int ajustement(Priere priere) => ajustements[priere] ?? 0;
}

/// Une heure d'entree de priere, telle que le serveur la rend.
@immutable
class HeurePriere {
  /// Cree une heure.
  const HeurePriere({
    required this.priere,
    required this.instant,
    required this.approximee,
    required this.fuseau,
  });

  /// Lit une ligne de `priere_horaires_jour`. Une priere inconnue est ecartee
  /// par l'appelant (`null`).
  static HeurePriere? depuisJson(Map<String, dynamic> json) {
    final Priere? priere = Priere.depuisSql(json['priere'] as String?);
    final Object? instant = json['instant_utc'];
    if (priere == null || instant is! String) {
      return null;
    }
    return HeurePriere(
      priere: priere,
      instant: DateTime.parse(instant).toLocal(),
      approximee: json['approximee'] == true,
      fuseau: json['fuseau'] as String? ?? '',
    );
  }

  /// La priere.
  final Priere priere;

  /// L'instant, dans le fuseau de l'appareil.
  final DateTime instant;

  /// Vrai quand l'angle ne se definit pas (haute latitude, ete) : le repli de la
  /// nuit partagee en deux a servi.
  final bool approximee;

  /// Le fuseau de l'enseignant.
  final String fuseau;
}

/// Ce que la direction pose pour un enseignant (`priere_lieu_definir`).
@immutable
class DefinitionLieu {
  /// Cree une definition.
  const DefinitionLieu({
    required this.enseignantId,
    required this.lieu,
    required this.latitude,
    required this.longitude,
    required this.fuseau,
    this.methode,
    this.ecoleAsr,
    this.assisteVendredi = false,
    this.vendrediDebut = '12:30',
    this.vendrediFin = '14:30',
  });

  /// L'enseignant.
  final String enseignantId;

  /// Le nom du lieu.
  final String lieu;

  /// Latitude.
  final double latitude;

  /// Longitude.
  final double longitude;

  /// Fuseau IANA.
  final String fuseau;

  /// Methode propre a l'enseignant ; `null` : celle de l'ecole.
  final MethodeCalcul? methode;

  /// Ecole d'Asr propre a l'enseignant ; `null` : celle de l'ecole.
  final Madhab? ecoleAsr;

  /// Assiste a la priere du vendredi.
  final bool assisteVendredi;

  /// Debut de la plage du vendredi.
  final String vendrediDebut;

  /// Fin de la plage du vendredi.
  final String vendrediFin;
}

/// Une ligne de la liste « Lieux de priere » de la direction.
@immutable
class EnseignantPriere {
  /// Cree une ligne.
  const EnseignantPriere({
    required this.enseignantId,
    required this.prenom,
    required this.lieu,
    required this.fuseau,
    required this.assisteVendredi,
    required this.aUnLieu,
  });

  /// Lit une ligne de `priere_enseignants_liste`.
  factory EnseignantPriere.depuisJson(Map<String, dynamic> json) =>
      EnseignantPriere(
        enseignantId: json['enseignant_id'] as String,
        prenom: json['prenom'] as String? ?? '',
        lieu: json['lieu'] as String?,
        fuseau: json['fuseau'] as String?,
        assisteVendredi: json['assiste_vendredi'] == true,
        aUnLieu: json['a_un_lieu'] == true,
      );

  /// L'enseignant.
  final String enseignantId;

  /// Son prenom.
  final String prenom;

  /// Son lieu de priere, nul s'il n'en a pas.
  final String? lieu;

  /// Le fuseau de ce lieu.
  final String? fuseau;

  /// Assiste a la priere du vendredi.
  final bool assisteVendredi;

  /// Vrai quand un lieu est pose.
  final bool aUnLieu;
}

/// Un croisement du creneau d'une classe avec une priere, sur une periode.
@immutable
class CroisementPriere {
  /// Cree un croisement.
  const CroisementPriere({
    required this.priere,
    required this.du,
    required this.au,
    required this.nbSeances,
    required this.nbPause,
    required this.nbApresCours,
  });

  /// Lit un element de `croisements`.
  static CroisementPriere? depuisJson(Map<String, dynamic> json) {
    final Priere? priere = Priere.depuisSql(json['priere'] as String?);
    final DateTime? du = DateTime.tryParse(json['du'] as String? ?? '');
    final DateTime? au = DateTime.tryParse(json['au'] as String? ?? '');
    if (priere == null || du == null || au == null) {
      return null;
    }
    return CroisementPriere(
      priere: priere,
      du: du,
      au: au,
      nbSeances: (json['nb_seances'] as num?)?.toInt() ?? 0,
      nbPause: (json['nb_pause'] as num?)?.toInt() ?? 0,
      nbApresCours: (json['nb_apres_cours'] as num?)?.toInt() ?? 0,
    );
  }

  /// La priere.
  final Priere priere;

  /// Premiere seance de la periode.
  final DateTime du;

  /// Derniere seance de la periode.
  final DateTime au;

  /// Seances de la periode qui croisent cette priere.
  final int nbSeances;

  /// Dont la pause de priere sera placee.
  final int nbPause;

  /// Dont la priere tombe dans les dernieres minutes : l'enseignant prie apres
  /// le cours.
  final int nbApresCours;
}

/// Ce que la direction lit sur un creneau d'une classe (P8, P9).
@immutable
class LectureCreneauPriere {
  /// Cree une lecture.
  const LectureCreneauPriere({
    required this.jour,
    required this.heure,
    required this.fuseau,
    required this.dureeMinutes,
    required this.sansLieu,
    required this.indefini,
    required this.seances,
    required this.croisements,
    required this.vendrediAssiste,
    required this.vendrediSeances,
    required this.vendrediDebut,
    required this.vendrediFin,
    required this.heuresSansPriere,
  });

  /// Lit un element de `creneaux` de `priere_lecture_classe`.
  factory LectureCreneauPriere.depuisJson(Map<String, dynamic> json) {
    final Map<String, dynamic> lecture =
        (json['lecture'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    final Map<String, dynamic> vendredi =
        (lecture['vendredi'] as Map<String, dynamic>?) ??
        const <String, dynamic>{};
    final Object? libres = lecture['heures_sans_priere'];
    return LectureCreneauPriere(
      jour: (json['weekday'] as num?)?.toInt() ?? 1,
      heure: (json['hour_local'] as num?)?.toInt() ?? 0,
      fuseau: json['timezone'] as String? ?? '',
      dureeMinutes: (json['duree_minutes'] as num?)?.toInt() ?? 0,
      sansLieu: lecture['sans_lieu'] != false,
      indefini: lecture['indefini'] == true,
      seances: (lecture['seances'] as num?)?.toInt() ?? 0,
      croisements: <CroisementPriere>[
        for (final Object? c
            in (lecture['croisements'] as List<dynamic>?) ?? const <dynamic>[])
          if (c is Map<String, dynamic>) ?CroisementPriere.depuisJson(c),
      ],
      vendrediAssiste: vendredi['assiste'] == true,
      vendrediSeances: (vendredi['nb_seances'] as num?)?.toInt() ?? 0,
      vendrediDebut: vendredi['debut'] as String? ?? '12:30',
      vendrediFin: vendredi['fin'] as String? ?? '14:30',
      heuresSansPriere: libres is List<dynamic>
          ? <int>[
              for (final Object? h in libres)
                if (h is num) h.toInt(),
            ]
          : null,
    );
  }

  /// Jour de la semaine, 1 = lundi.
  final int jour;

  /// Heure de debut dans le fuseau de la classe.
  final int heure;

  /// Fuseau de la classe.
  final String fuseau;

  /// Duree des seances.
  final int dureeMinutes;

  /// Vrai quand l'enseignant n'a pas de lieu de priere.
  final bool sansLieu;

  /// Vrai quand le calcul n'existe pas pour une partie de l'annee.
  final bool indefini;

  /// Seances du creneau sur les 12 mois.
  final int seances;

  /// Les croisements, periode par periode.
  final List<CroisementPriere> croisements;

  /// Vrai quand l'enseignant assiste a la priere du vendredi.
  final bool vendrediAssiste;

  /// Seances de l'annee qui chevauchent sa plage du vendredi.
  final int vendrediSeances;

  /// Debut de la plage du vendredi.
  final String vendrediDebut;

  /// Fin de la plage du vendredi.
  final String vendrediFin;

  /// Les heures de debut sans priere ce jour-la ; `null` quand le serveur ne
  /// peut pas le dire.
  final List<int>? heuresSansPriere;
}

/// Un enseignant dont le compte et le lieu de priere ne concordent pas.
@immutable
class IncoherencePriere {
  /// Cree une incoherence.
  const IncoherencePriere({
    required this.enseignantId,
    required this.prenom,
    required this.motif,
    required this.detail,
  });

  /// Lit une ligne de `priere_incoherences_enseignants`.
  factory IncoherencePriere.depuisJson(Map<String, dynamic> json) =>
      IncoherencePriere(
        enseignantId: json['enseignant_id'] as String,
        prenom: json['prenom'] as String? ?? '',
        motif: json['motif'] as String? ?? '',
        detail: json['detail'] as String? ?? '',
      );

  /// L'enseignant.
  final String enseignantId;

  /// Son prenom.
  final String prenom;

  /// `fuseau_compte_different`, `fuseau_lieu_incoherent` ou
  /// `pays_lieu_incoherent`.
  final String motif;

  /// Les deux valeurs qui ne concordent pas.
  final String detail;
}
