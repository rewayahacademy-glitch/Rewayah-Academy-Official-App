import 'package:flutter/foundation.dart';

import 'shared_content_state.dart';

/// Ce qu'un reducteur a fait d'une revision candidate.
///
/// Les trois refus sont **distincts** parce qu'ils ne se diagnostiquent pas
/// pareil : un doublon est normal sur un reseau qui reemet, une revision
/// obsolete est normale sur un canal qui reordonne, et une seance etrangere est
/// un defaut de filtrage a corriger.
enum SuiteRevision {
  /// La revision est devenue l'etat courant.
  appliquee,

  /// Meme revision que l'etat courant : paquet duplique, rien a faire.
  dupliquee,

  /// Revision plus ancienne que l'etat courant : paquet hors ordre, ignore.
  obsolete,

  /// Le paquet ne concerne pas la seance suivie.
  seanceEtrangere,
}

/// Le verdict d'une revision candidate, avec l'etat retenu.
@immutable
class ResultatRevision {
  /// Cree un verdict.
  const ResultatRevision(this.suite, this.etat);

  /// Ce qui a ete decide.
  final SuiteRevision suite;

  /// L'etat retenu **apres** la decision. Inchange quand la revision est
  /// refusee : un appelant peut donc toujours rendre `etat` sans tester `suite`.
  final SharedContentState? etat;

  /// Vrai quand l'etat a change et qu'il faut le republier aux abonnes.
  bool get aChange => suite == SuiteRevision.appliquee;
}

/// L'ordonnanceur de l'etat partage d'une seance.
///
/// **C'est le coeur du lot F, et il est volontairement pur** : aucune entree
/// sortie, aucune horloge, aucun flux. Il se teste par comparaison de
/// revisions, sans transport ni SDK.
///
/// La regle tient en une phrase : **une revision inferieure ou egale a l'etat
/// courant n'ecrase jamais l'etat courant.** Elle couvre d'un coup le paquet
/// duplique, le paquet hors ordre et le rejeu d'une reconnexion, qui sont trois
/// noms pour la meme situation vue du recepteur.
///
/// **Il n'y a pas de traitement de lacune, et c'est un choix de conception.**
/// Chaque message fiable porte l'etat COMPLET a sa revision, jamais un delta :
/// recevoir 5 puis 9 sans 6, 7 ni 8 est donc parfaitement exploitable -- 9 est
/// un etat complet et plus recent. C'est ce qui permet a un arrivant tardif de
/// se mettre a jour avec **un seul message**, et c'est aussi pourquoi le lot F
/// n'a besoin d'aucun historique de messages (exigence de la spec ligne 1200).
class ReducteurEtatPartage {
  /// Cree un reducteur pour une seance, eventuellement deja positionne.
  ReducteurEtatPartage({required this.sessionId, SharedContentState? initial})
    : assert(
        initial == null || initial.sessionId == sessionId,
        'un etat initial appartient a la seance suivie',
      ),
      _etat = initial;

  /// La seance suivie. Tout paquet d'une autre seance est refuse.
  final String sessionId;

  SharedContentState? _etat;

  /// L'etat courant, ou `null` tant qu'aucune revision n'a ete retenue.
  SharedContentState? get etat => _etat;

  /// La revision courante, ou `-1` quand aucun etat n'est connu.
  ///
  /// `-1` et non `0` : la revision `0` est une revision legitime -- celle du
  /// premier support pose devant la classe -- et la confondre avec l'absence
  /// d'etat ferait refuser ce premier support.
  int get revisionCourante => _etat?.revision ?? -1;

  /// Confronte une revision candidate a l'etat courant.
  ///
  /// A revision egale, **le premier arrive gagne**. Deux emetteurs ne devraient
  /// jamais produire la meme revision : l'arbitrage reel est l'unicite
  /// `(session_id, revision)` demandee en base dans
  /// `TC_CONTRACT_REQUEST_F.md`. Cote client il faut malgre tout une regle
  /// deterministe, et « le premier arrive » est la seule qui ne depende pas
  /// d'une horloge partagee que personne n'a.
  ResultatRevision appliquer(SharedContentState candidat) {
    if (candidat.sessionId != sessionId) {
      return ResultatRevision(SuiteRevision.seanceEtrangere, _etat);
    }
    final SharedContentState? courant = _etat;
    if (courant != null) {
      if (candidat.revision == courant.revision) {
        return ResultatRevision(SuiteRevision.dupliquee, courant);
      }
      if (candidat.revision < courant.revision) {
        return ResultatRevision(SuiteRevision.obsolete, courant);
      }
    }
    _etat = candidat;
    return ResultatRevision(SuiteRevision.appliquee, candidat);
  }

  /// Installe l'etat lu au backend, apres une arrivee tardive ou une
  /// reconnexion.
  ///
  /// **La meme regle monotone s'applique qu'a un paquet realtime.** Le backend
  /// fait autorite sur le contenu, jamais sur le sens du temps : une lecture
  /// servie par une replique en retard ne doit pas faire reculer une classe qui
  /// a deja vu plus recent. C'est exactement l'invariant que le lot doit
  /// prouver -- « une revision ancienne n'ecrase jamais une revision recente »
  /// -- et il n'a pas d'exception pour le backend.
  ///
  /// Un `null` -- aucune presentation en cours cote backend -- **n'efface
  /// rien** : il n'apporte aucune revision, donc il ne peut pas etre plus
  /// recent que ce qu'on a.
  ResultatRevision restaurer(SharedContentState? depuisBackend) {
    if (depuisBackend == null) {
      return ResultatRevision(SuiteRevision.obsolete, _etat);
    }
    return appliquer(depuisBackend);
  }

  /// Oublie tout. Employe a la sortie volontaire d'une seance, jamais a une
  /// deconnexion : c'est la distinction que le socle tient deja entre
  /// `quitter()` et une coupure reseau.
  void vider() {
    _etat = null;
  }
}
