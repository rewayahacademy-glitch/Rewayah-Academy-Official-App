// DYNAMIQUE-CHRONO-1 (directeur, 12/11/2026, retours sur la salle, points 2,
// 3 et 5 ; `docs/current/salle/PLAN-RETOURS-2026-11-12.md`, decision 1) : ce
// que porte la Dynamique chrono en plus du temps.
//
// - Une **marque** : un etat qui dure (« En retard », « Yasmine recite »,
//   « Pause dans 21 min »). Repliee, la barre la montre en point de couleur,
//   avec son libelle lu ; depliee, en clair (point ET mot : jamais la couleur
//   seule).
// - Une **alerte** : un evenement passager (titre, une ou deux actions comme
//   Oui / Non), qui deplie la barre un instant, part seul et laisse sa trace
//   en marque. DYNAMIQUE-CHRONO-2 (directeur, 12/11/2026) : les alertes de la
//   salle (arrivees, appel, recitation, pause proposee) sont emises par
//   `PiloteDynamique` (`pilote_dynamique.dart`), qui tient la file, le
//   repli et les marques laissees.
//
// Types fermes : on ajoute un genre ici, jamais une marque construite a la
// main dans un ecran.

import 'package:flutter/foundation.dart';

import '../../core/widgets/status_pill.dart' show TonEtat;

/// Le genre d'une marque : la liste fermee de ce que la barre sait dire.
enum GenreMarqueChrono {
  /// Sa propre presence quand elle s'ecarte de « En salle » (« En retard »,
  /// « Pas encore la ») : l'eleve seul, la sienne seulement (section 6.6).
  presence,

  /// L'eleve qui recite, dit a la classe.
  recitation,

  /// La pause programmee (« Pause dans 21 min », « Pause prevue »).
  pauseProgrammee,

  /// La pause en cours (« Pause, reprise a 20:45 »).
  pauseEnCours,

  /// La pause deja prise.
  pausePrise,

  /// DYNAMIQUE-CHRONO-2 : un evenement passe qui laisse une trace courte
  /// (« Yasmine dans la salle », « Appel envoye a Yasmine »).
  evenement,

  /// DYNAMIQUE-CHRONO-2 : l'appel recu, jusqu'a ce que l'eleve touche la
  /// barre.
  appel,
}

/// Un etat qui dure, porte par la Dynamique chrono.
@immutable
class MarqueChrono {
  const MarqueChrono._({
    required this.genre,
    required this.libelle,
    required this.annonce,
    required this.ton,
  });

  /// Sa propre presence ([GenreMarqueChrono.presence]).
  const MarqueChrono.presence({required String libelle, required TonEtat ton})
    : this._(
        genre: GenreMarqueChrono.presence,
        libelle: libelle,
        annonce: libelle,
        ton: ton,
      );

  /// L'eleve qui recite ([GenreMarqueChrono.recitation]).
  const MarqueChrono.recitation({required String libelle})
    : this._(
        genre: GenreMarqueChrono.recitation,
        libelle: libelle,
        annonce: libelle,
        ton: TonEtat.accent,
      );

  /// DYNAMIQUE-CHRONO-2 : la trace d'un evenement ([GenreMarqueChrono.evenement]
  /// ou [GenreMarqueChrono.appel]).
  const MarqueChrono.evenement({
    required String libelle,
    GenreMarqueChrono genre = GenreMarqueChrono.evenement,
    TonEtat ton = TonEtat.neutre,
  }) : this._(genre: genre, libelle: libelle, annonce: libelle, ton: ton);

  /// La pause, selon son statut : le texte visible et sa version lue.
  const MarqueChrono.pause({
    required GenreMarqueChrono genre,
    required String libelle,
    required String annonce,
  }) : this._(
         genre: genre,
         libelle: libelle,
         annonce: annonce,
         ton: genre == GenreMarqueChrono.pauseEnCours
             ? TonEtat.accent
             : TonEtat.neutre,
       );

  /// Ce que la marque dit, en clair (barre depliee).
  final String libelle;

  /// Ce que lit le lecteur d'ecran (barre repliee comme depliee).
  final String annonce;

  /// La famille de son point.
  final TonEtat ton;

  /// Le genre de la marque.
  final GenreMarqueChrono genre;

  /// Vrai pour une marque de pause.
  bool get estPause =>
      genre == GenreMarqueChrono.pauseProgrammee ||
      genre == GenreMarqueChrono.pauseEnCours ||
      genre == GenreMarqueChrono.pausePrise;

  @override
  bool operator ==(Object other) =>
      other is MarqueChrono &&
      other.genre == genre &&
      other.libelle == libelle &&
      other.annonce == annonce &&
      other.ton == ton;

  @override
  int get hashCode => Object.hash(genre, libelle, annonce, ton);
}

/// Une action d'une alerte passagere (« Oui », « Non »).
@immutable
class ActionAlerteChrono {
  /// Cree l'action.
  const ActionAlerteChrono({
    required this.libelle,
    required this.onPress,
    this.principale = false,
  });

  /// Le verbe, court.
  final String libelle;

  /// DYNAMIQUE-CHRONO-2 : l'action de l'alerte (« Oui »), en bouton plein
  /// compact ; l'autre reste un lien (K-56 : un seul bouton plein).
  final bool principale;

  /// Ce que fait l'action ; la barre se replie ensuite.
  final VoidCallback onPress;
}

/// Un evenement passager de la Dynamique chrono (lot DYNAMIQUE-CHRONO-2) :
/// la barre se deplie et le montre, puis il part seul apres [duree] (ou des
/// qu'une action est choisie) et laisse [trace] dans les marques.
@immutable
class AlerteChrono {
  /// Cree l'alerte. Une ou deux actions au plus, aucune obligatoire.
  const AlerteChrono({
    required this.id,
    required this.titre,
    this.detail,
    this.compte,
    this.actions = const <ActionAlerteChrono>[],
    this.duree,
    this.trace,
    this.cleTrace,
    this.dureeTrace,
    this.rouvrable = false,
    this.groupe,
  }) : assert(actions.length <= 2, 'Une ou deux actions au plus.');

  /// DYNAMIQUE-CHRONO-2 : une phrase sous le titre (« Votre micro est
  /// ferme... »), ou `null`.
  final String? detail;

  /// DYNAMIQUE-CHRONO-2 : le nombre qui roule devant le titre (« +2 »), ou
  /// `null`.
  final int? compte;

  /// DYNAMIQUE-CHRONO-2 : la cle de la trace dans les marques (une trace de
  /// meme cle remplace la precedente) ; `null` : [id].
  final String? cleTrace;

  /// DYNAMIQUE-CHRONO-2 : combien de temps la trace reste ; `null` : tant
  /// que l'emetteur ne la retire pas.
  final Duration? dureeTrace;

  /// DYNAMIQUE-CHRONO-2 : un toucher de la barre rouvre l'alerte tant que sa
  /// trace est la (la pause proposee).
  final bool rouvrable;

  /// DYNAMIQUE-CHRONO-2 : la famille de l'alerte (« arrivees ») : une
  /// alerte de la meme famille remplace celle qui est montree.
  final String? groupe;

  /// Identifie l'alerte : la meme alerte reconstruite ne se rejoue pas.
  final String id;

  /// Ce qui arrive, en une phrase.
  final String titre;

  /// Une ou deux actions (Oui / Non), ou aucune.
  final List<ActionAlerteChrono> actions;

  /// Combien de temps elle reste ; `null` : [AppMouvement.alerteChrono].
  final Duration? duree;

  /// La marque laissee quand l'alerte est partie ; `null` : aucune.
  final MarqueChrono? trace;
}
