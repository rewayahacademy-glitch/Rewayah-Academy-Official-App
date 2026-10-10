import 'package:flutter/foundation.dart';

import 'modeles_recherche.dart';

/// Ou en est la recherche : une phase, un texte (spec RECH-03 §5).
///
/// L'ecran rend **une phase, un texte** : jamais un « aucun resultat » pour
/// autre chose qu'un vide confirme (`ok` et aucun element, dans chaque domaine
/// interroge).
enum PhaseRecherche {
  /// Champ vide : rien n'est interroge (§5 « Initial »).
  inactif,

  /// Du texte, mais trop court : « Saisissez au moins 3 caracteres. ».
  saisie,

  /// Le delai apres la derniere frappe court : la recherche partira.
  attente,

  /// La recherche est partie, rien n'est encore revenu.
  chargement,

  /// Au moins un domaine a des resultats et tous ont repondu.
  resultats,

  /// Des resultats, mais un domaine en panne ou encore attendu.
  partiels,

  /// Vide confirme : chaque domaine a repondu `ok` sans element.
  vide,

  /// Aucun domaine n'a pu repondre.
  erreur,

  /// Aucun domaine n'a repondu a temps.
  delai,

  /// L'appareil est hors ligne : aucune requete n'est partie.
  horsLigne,

  /// Aucun domaine n'est servi, ou le droit a ete retire : rien a chercher.
  nonAutorise,

  /// La session a expire.
  sessionExpiree,
}

/// L'avancement d'un domaine.
enum AvancementDomaine {
  /// Pas encore demande (file des demandes simultanees).
  enAttente,

  /// Demande partie.
  enCours,

  /// A repondu `ok`.
  termine,

  /// N'a pas pu repondre.
  enEchec,
}

/// L'etat d'un domaine dans la page de resultats.
@immutable
class EtatDomaine {
  /// Cree un etat de domaine.
  const EtatDomaine({
    required this.domaine,
    this.avancement = AvancementDomaine.enAttente,
    this.elements = const <ResultatRecherche>[],
    this.curseur,
    this.aPlus = false,
    this.echec,
    this.pageEnCours = false,
    this.pageEnEchec = false,
  });

  /// Le domaine.
  final DomaineRecherche domaine;

  /// Son avancement.
  final AvancementDomaine avancement;

  /// Les resultats recus (premiere page puis pages suivantes).
  final List<ResultatRecherche> elements;

  /// Le curseur opaque de la page suivante.
  final String? curseur;

  /// Vrai quand d'autres resultats existent (« Voir davantage »).
  final bool aPlus;

  /// Pourquoi il n'a pas repondu, si [avancement] est `enEchec`.
  final StatutRecherche? echec;

  /// Vrai pendant le chargement de la page suivante.
  final bool pageEnCours;

  /// Vrai quand la page suivante a echoue : les lignes deja recues restent.
  final bool pageEnEchec;

  /// Vrai quand le domaine a repondu `ok` sans element : le seul vide confirme.
  bool get videConfirme =>
      avancement == AvancementDomaine.termine && elements.isEmpty;

  /// Vrai quand le domaine a fini, bien ou mal.
  bool get fini =>
      avancement == AvancementDomaine.termine ||
      avancement == AvancementDomaine.enEchec;

  /// Une copie modifiee.
  EtatDomaine copier({
    AvancementDomaine? avancement,
    List<ResultatRecherche>? elements,
    String? curseur,
    bool? aPlus,
    StatutRecherche? echec,
    bool? pageEnCours,
    bool? pageEnEchec,
    bool effacerCurseur = false,
    bool effacerEchec = false,
  }) => EtatDomaine(
    domaine: domaine,
    avancement: avancement ?? this.avancement,
    elements: elements ?? this.elements,
    curseur: effacerCurseur ? null : curseur ?? this.curseur,
    aPlus: aPlus ?? this.aPlus,
    echec: effacerEchec ? null : echec ?? this.echec,
    pageEnCours: pageEnCours ?? this.pageEnCours,
    pageEnEchec: pageEnEchec ?? this.pageEnEchec,
  );
}

/// L'etat complet de la surface de recherche.
@immutable
class EtatRecherche {
  /// Cree un etat.
  const EtatRecherche({
    this.texte = '',
    this.phase = PhaseRecherche.inactif,
    this.domaines = const <EtatDomaine>[],
    this.lent = false,
  });

  /// Le texte nettoye de la recherche en cours (« Resultats pour « ... » »).
  final String texte;

  /// La phase.
  final PhaseRecherche phase;

  /// Les domaines interroges, dans l'ordre d'affichage.
  final List<EtatDomaine> domaines;

  /// Vrai a 2 s : la recherche dure plus que prevu, sans rien retirer.
  final bool lent;

  /// Les domaines qui ont des elements a montrer.
  Iterable<EtatDomaine> get avecElements =>
      domaines.where((EtatDomaine d) => d.elements.isNotEmpty);

  /// Les domaines en echec, a dire un par un (§5 « Domaine indisponible »).
  Iterable<EtatDomaine> get enEchec => domaines.where(
    (EtatDomaine d) => d.avancement == AvancementDomaine.enEchec,
  );

  /// Une copie modifiee.
  EtatRecherche copier({
    String? texte,
    PhaseRecherche? phase,
    List<EtatDomaine>? domaines,
    bool? lent,
  }) => EtatRecherche(
    texte: texte ?? this.texte,
    phase: phase ?? this.phase,
    domaines: domaines ?? this.domaines,
    lent: lent ?? this.lent,
  );
}

/// La phase que racontent les domaines, une fois la recherche partie.
///
/// Pure, pour se tester sans widget. Regles :
///
/// - tant que rien n'est revenu : [PhaseRecherche.chargement] ;
/// - des elements et tout est fini sans echec : [PhaseRecherche.resultats] ;
/// - des elements et (un echec ou une attente) : [PhaseRecherche.partiels] ;
/// - tout fini sans element, sans echec : [PhaseRecherche.vide] (le seul vide
///   confirme) ;
/// - tout fini en echec : selon le motif, session expiree, delai, droit
///   retire ou erreur ; jamais un vide ;
/// - fini sans element mais avec un echec parmi des `ok` vides : partiel, car
///   le domaine en panne peut avoir des resultats (pas de faux « Aucun »).
PhaseRecherche phaseDesDomaines(List<EtatDomaine> domaines) {
  if (domaines.isEmpty) return PhaseRecherche.nonAutorise;
  final bool toutFini = domaines.every((EtatDomaine d) => d.fini);
  final bool desElements = domaines.any(
    (EtatDomaine d) => d.elements.isNotEmpty,
  );
  final Iterable<EtatDomaine> echecs = domaines.where(
    (EtatDomaine d) => d.avancement == AvancementDomaine.enEchec,
  );
  if (desElements) {
    return toutFini && echecs.isEmpty
        ? PhaseRecherche.resultats
        : PhaseRecherche.partiels;
  }
  if (!toutFini) return PhaseRecherche.chargement;
  if (echecs.isEmpty) return PhaseRecherche.vide;
  if (echecs.length < domaines.length) return PhaseRecherche.partiels;
  final Set<StatutRecherche?> motifs = echecs
      .map((EtatDomaine d) => d.echec)
      .toSet();
  if (motifs.contains(StatutRecherche.sessionExpiree)) {
    return PhaseRecherche.sessionExpiree;
  }
  if (motifs.contains(StatutRecherche.contexteRevoque)) {
    return PhaseRecherche.nonAutorise;
  }
  if (motifs.every((StatutRecherche? m) => m == StatutRecherche.delai)) {
    return PhaseRecherche.delai;
  }
  return PhaseRecherche.erreur;
}
