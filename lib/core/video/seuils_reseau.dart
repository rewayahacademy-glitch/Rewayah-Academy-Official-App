// Lot RESEAU-ELEVES (directeur, 11/11/2026 ; cahier de la salle §5 et §6) :
// la qualite du lien de chaque participant, telle que le serveur de visio la
// mesure, filtree pour ne jamais faire clignoter un signe. Dart pur, sans
// SDK ni widget : la salle y lit ce qu'elle montre.
//
// **Ce que cette qualite est, et ce qu'elle n'est pas.** LiveKit calcule pour
// chaque participant une note de lien (excellente, bonne, mediocre, perdue)
// a partir des pertes, de la gigue et du debit qu'il voit passer. C'est un
// INDICE que la voix peut arriver abimee, pas une preuve : la mesure de ce
// que l'auditeur entend vraiment (le « son reconstruit » du navigateur,
// `docs/current/salle/MESURES-VOIX.md`) n'est pas encore lue en direct. Les
// phrases de la salle disent donc « peut-etre » : elles ne promettent pas plus
// que ce qu'on mesure.
//
// **Le seuil vient de la mesure.** `MESURES-VOIX.md` (banc du 11/11/2026) :
// sous des pertes isolees ou un lien de type 3G, la voix arrive intacte (zero
// mot perdu) ; c'est quand le lien devient mauvais (pertes en rafales de 10 %
// et plus) que des mots tombent, et c'est exactement la que LiveKit passe la
// note a « mediocre » et la salle coupe l'image (« La regle : ce que
// l'application fait sous chaque seuil », ligne « Lien mediocre »). Le signe
// « Reseau faible » et la phrase « on vous entend peut-etre mal » partent donc
// du meme seuil que le repli audio : `mediocre` ou `perdue`. Un lien « bon »
// (deux barres) ne declenche rien : le banc ne montre aucune perte de mot a
// ce niveau.

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'video_session_provider.dart';

/// Le temps qu'une nouvelle qualite doit tenir avant d'etre montree.
///
/// Justification : le serveur de visio publie un changement de note des
/// qu'il le voit, et une rafale de pertes d'une seconde suffit a faire passer
/// la note de bonne a mediocre puis de nouveau a bonne. Montrer chaque
/// changement ferait clignoter les barres (cahier §6 : un indicateur qui
/// trompe n'aide pas). Trois secondes ecartent un passage d'une ou deux
/// secondes, et restent courtes devant une phrase de recitation : le signe
/// suit le reseau reel sans le retarder au point de mentir.
const Duration tenueAvantChangement = Duration(seconds: 3);

/// Le temps de mauvais lien avant la phrase (« On entend peut-etre mal
/// Yasmine », « Votre connexion est faible »).
///
/// Justification : la demande du directeur est « depuis plusieurs
/// secondes », jamais une alerte qui derange le cours. Huit secondes, c'est
/// plus de deux fois [tenueAvantChangement] : la phrase ne vient qu'apres un
/// signe deja stable, quand le mauvais lien a dure le temps d'un verset
/// court. Un mauvais lien plus bref se lit dans les barres, sans phrase.
const Duration tenueAvantAlerte = Duration(seconds: 8);

/// Vrai pour les deux notes ou la voix risque d'arriver abimee.
bool lienMauvais(QualiteLien qualite) =>
    qualite == QualiteLien.mediocre || qualite == QualiteLien.perdue;

/// Le reseau d'un participant, tel que la salle peut le montrer.
@immutable
class EtatReseau {
  /// Cree un etat.
  const EtatReseau({required this.qualite, this.alerte = false});

  /// La qualite stable (filtree par [tenueAvantChangement]).
  final QualiteLien qualite;

  /// Le lien est mauvais depuis au moins [tenueAvantAlerte] : la salle le
  /// dit en une phrase.
  final bool alerte;

  /// Les barres (0 a 3), ou `null` tant qu'aucune mesure n'est stable :
  /// jamais un signal invente.
  int? get barres => switch (qualite) {
    QualiteLien.excellente => 3,
    QualiteLien.bonne => 2,
    QualiteLien.mediocre => 1,
    QualiteLien.perdue => 0,
    QualiteLien.inconnue => null,
  };

  /// Le lien est faible (une barre ou aucune).
  bool get faible => lienMauvais(qualite);

  @override
  bool operator ==(Object other) =>
      other is EtatReseau && other.qualite == qualite && other.alerte == alerte;

  @override
  int get hashCode => Object.hash(qualite, alerte);

  @override
  String toString() => 'EtatReseau(${qualite.name}, alerte: $alerte)';
}

/// Le filtre d'un participant : une qualite n'est montree qu'apres avoir
/// tenu [tenueAvantChangement] ; l'alerte ne vient qu'apres
/// [tenueAvantAlerte] de mauvais lien, et ne s'eteint que quand la qualite
/// montree redevient bonne (un bon passage d'une seconde ne l'eteint pas).
class FiltreQualite {
  QualiteLien _montree = QualiteLien.inconnue;
  QualiteLien _brute = QualiteLien.inconnue;
  DateTime? _bruteDepuis;
  DateTime? _mauvaisDepuis;

  /// Prend une mesure brute (la note que LiveKit vient de publier).
  void mesurer(QualiteLien brute, DateTime maintenant) {
    if (brute != _brute) {
      _brute = brute;
      _bruteDepuis = maintenant;
    }
    if (lienMauvais(brute)) _mauvaisDepuis ??= maintenant;
    _evaluer(maintenant);
  }

  void _evaluer(DateTime maintenant) {
    final DateTime? depuis = _bruteDepuis;
    if (_brute != _montree &&
        depuis != null &&
        maintenant.difference(depuis) >= tenueAvantChangement) {
      _montree = _brute;
    }
    // Le mauvais lien n'est oublie que quand ni la mesure brute ni la
    // qualite montree ne sont mauvaises.
    if (!lienMauvais(_brute) && !lienMauvais(_montree)) _mauvaisDepuis = null;
  }

  /// L'etat a montrer a [maintenant].
  EtatReseau etat(DateTime maintenant) {
    _evaluer(maintenant);
    final DateTime? mauvais = _mauvaisDepuis;
    return EtatReseau(
      qualite: _montree,
      alerte:
          lienMauvais(_montree) &&
          mauvais != null &&
          maintenant.difference(mauvais) >= tenueAvantAlerte,
    );
  }

  /// Le prochain instant ou [etat] peut changer sans nouvelle mesure, ou
  /// `null` : rien n'est en attente.
  DateTime? prochaineEcheance(DateTime maintenant) {
    _evaluer(maintenant);
    final List<DateTime> echeances = <DateTime>[
      if (_brute != _montree && _bruteDepuis != null)
        _bruteDepuis!.add(tenueAvantChangement),
      if (_mauvaisDepuis != null &&
          maintenant.difference(_mauvaisDepuis!) < tenueAvantAlerte)
        _mauvaisDepuis!.add(tenueAvantAlerte),
    ];
    if (echeances.isEmpty) return null;
    echeances.sort();
    return echeances.first;
  }
}

/// Le reseau de toute la salle : un [FiltreQualite] par participant (par son
/// identite, l'identifiant de profil que le serveur a mis dans le jeton).
///
/// **Ce suivi n'envoie rien.** Il vit en memoire, le temps de la seance :
/// aucune ecriture en base, aucun envoi. Le releve conserve comme preuve
/// (lot RESEAU-PREUVE, 11/11/2026) est `releve_qualite.dart` : il lit
/// [etats] et n'envoie au serveur que la ligne du participant local
/// (`docs/current/salle/DROIT-RELEVE-QUALITE.md`).
///
/// Il tient sa propre minuterie : quand une qualite doit devenir stable ou
/// une alerte s'allumer sans nouvelle mesure (LiveKit ne publie que les
/// changements), [quandChange] est appele au bon moment.
class SuiviReseau {
  /// Cree le suivi.
  SuiviReseau({required this.quandChange, DateTime Function()? horloge})
    : _horloge = horloge ?? DateTime.now;

  /// Appele quand un etat change sans nouvelle mesure.
  final VoidCallback quandChange;
  final DateTime Function() _horloge;
  final Map<String, FiltreQualite> _filtres = <String, FiltreQualite>{};
  Timer? _minuterie;

  /// Prend les qualites de la liste des participants (locale comprise).
  void mesurer(Iterable<ParticipantSalle> participants) {
    final DateTime maintenant = _horloge();
    final Set<String> presents = <String>{};
    for (final ParticipantSalle p in participants) {
      if (p.identite.isEmpty) continue;
      presents.add(p.identite);
      _filtres
          .putIfAbsent(p.identite, FiltreQualite.new)
          .mesurer(p.qualite, maintenant);
    }
    _filtres.removeWhere(
      (String id, FiltreQualite _) => !presents.contains(id),
    );
    _armer(maintenant);
  }

  /// L'etat de chacun, par identite. Un participant sans mesure stable
  /// n'y figure pas.
  Map<String, EtatReseau> etats() {
    final DateTime maintenant = _horloge();
    return <String, EtatReseau>{
      for (final MapEntry<String, FiltreQualite> e in _filtres.entries)
        if (e.value.etat(maintenant) case final EtatReseau etat
            when etat.qualite != QualiteLien.inconnue)
          e.key: etat,
    };
  }

  void _armer(DateTime maintenant) {
    _minuterie?.cancel();
    _minuterie = null;
    DateTime? prochaine;
    for (final FiltreQualite f in _filtres.values) {
      final DateTime? e = f.prochaineEcheance(maintenant);
      if (e != null && (prochaine == null || e.isBefore(prochaine))) {
        prochaine = e;
      }
    }
    if (prochaine == null) return;
    final Duration attente = prochaine.difference(maintenant);
    _minuterie = Timer(attente.isNegative ? Duration.zero : attente, () {
      _minuterie = null;
      quandChange();
      _armer(_horloge());
    });
  }

  /// Oublie tout (nouvelle entree en salle).
  void remettre() {
    _minuterie?.cancel();
    _minuterie = null;
    _filtres.clear();
  }

  /// Arrete la minuterie.
  void fermer() => remettre();
}
