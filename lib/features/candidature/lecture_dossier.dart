// PE-B5 (directeur, 19/11/2026 : « le candidat sait toujours ou il en est, ce
// qui lui manque et ce qui se passe ensuite ») : ce que l'onglet Dossier dit
// d'une candidature, calcule une fois, sans widget.
//
// **Aucun etat n'est invente ici.** L'etape, l'etat, l'issue, la pause, ce
// qui reste a completer, les accords, la piece et la photo viennent de
// `etat_dossier()` ; ce fichier ne fait que les ranger : UN titre, UNE action
// « a faire maintenant » (ou aucune), les lignes du dossier, la suite. Les
// regles sont celles du portail d'avant (`portail_candidature.dart`,
// `attente_page.dart`), reprises une a une.
library;

import 'package:flutter/foundation.dart';

import '../../core/candidature/modeles_candidature.dart';
import '../../core/dossier/etat_dossier.dart';
import '../../core/i18n/isolat_bidi.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/routes.dart';
import 'portail_candidature.dart';

/// Une phrase de l'etat, avec sa cle de test et son poids.
typedef PhraseDossier = ({String texte, String? cle, bool forte, bool muette});

/// La seule action « a faire maintenant ».
@immutable
class ActionDossier {
  /// Cree l'action.
  const ActionDossier({
    required this.phrase,
    required this.libelle,
    required this.chemin,
  });

  /// Ce qu'il y a a faire, en une phrase.
  final String phrase;

  /// Le libelle du bouton.
  final String libelle;

  /// La route ouverte.
  final String chemin;
}

/// L'etat d'une ligne du dossier.
enum EtatLigne {
  /// Fait : rien a faire.
  fait,

  /// A faire par le candidat.
  aFaire,
}

/// Une ligne du dossier : un element, son etat, ce qu'il est.
@immutable
class LigneDossier {
  /// Cree la ligne.
  const LigneDossier({
    required this.code,
    required this.icone,
    required this.libelle,
    required this.valeur,
    required this.etat,
    required this.detail,
    this.legende,
  });

  /// Le code stable de l'element (cle de test, jamais affiche).
  final String code;

  /// L'icone de l'element.
  final AppIcon icone;

  /// Le nom de l'element.
  final String libelle;

  /// Le mot de l'etat (« Fait », « A deposer »...).
  final String valeur;

  /// L'etat, pour le dessin (jamais la couleur seule : [valeur] le dit).
  final EtatLigne etat;

  /// Ce que le serveur dit de plus (piece recue, photo demandee...).
  final String? legende;

  /// Ce qu'est l'element, deplie au toucher.
  final String detail;
}

/// Tout ce que l'onglet Dossier montre.
@immutable
class LectureDossier {
  /// Cree la lecture.
  const LectureDossier({
    required this.titre,
    required this.phrases,
    required this.lignes,
    this.titreLignes,
    this.action,
    this.attendMajorite = false,
    this.ensuite,
    this.actualisable = false,
    this.relisible = false,
    this.fermee = false,
    this.retiree = false,
  });

  /// Le titre de l'etat ; `null` quand la ligne d'etapes le dit deja
  /// (« Bienvenue dans l'equipe »).
  final String? titre;

  /// Le titre des lignes, quand il differe du titre ordinaire (« Ce qu'il
  /// faut pour envoyer », tant que la candidature est a completer).
  final String? titreLignes;

  /// Les phrases de l'etat.
  final List<PhraseDossier> phrases;

  /// Les lignes du dossier.
  final List<LigneDossier> lignes;

  /// L'action a faire maintenant, ou `null`.
  final ActionDossier? action;

  /// Vrai quand la seule chose a faire est de declarer son age, dans la carte
  /// posee en tete (aucun bouton ici).
  final bool attendMajorite;

  /// Ce qui se passe ensuite, en une phrase ; `null` quand rien ne suit
  /// (pause, refus, retrait).
  final String? ensuite;

  /// Vrai quand « Actualiser » a un sens (la direction a la main).
  final bool actualisable;

  /// Vrai quand les reponses envoyees se relisent.
  final bool relisible;

  /// Vrai quand la candidature n'est plus en cours (refus, retrait).
  final bool fermee;

  /// Vrai quand la candidature est retiree.
  final bool retiree;

  /// La part faite des lignes, de 0 a 1 ; 1 sans ligne.
  double get partFaite => lignes.isEmpty
      ? 1
      : lignes.where((LigneDossier l) => l.etat == EtatLigne.fait).length /
            lignes.length;
}

PhraseDossier _phrase(
  String texte, {
  String? cle,
  bool forte = false,
  bool muette = false,
}) => (texte: texte, cle: cle, forte: forte, muette: muette);

String _jour(DateTime d) => isolerSens(
  '${d.day.toString().padLeft(2, '0')}/'
  '${d.month.toString().padLeft(2, '0')}/${d.year}',
);

/// Le libelle d'un element que la direction demande de completer, ou `null`
/// pour un code que cette version ne connait pas (il ne s'affiche jamais).
String? libelleElementDemande(String code) => switch (code) {
  'langues' => t.recrutement.questionnaire.langues,
  'recitation' => t.recrutement.questionnaire.recitation,
  'disponibilites' => t.recrutement.questionnaire.disponibilites,
  'publics' => t.recrutement.questionnaire.publics,
  'versement' => t.recrutement.questionnaire.versement,
  'cadre_religieux' => t.recrutement.portail.elementCadre,
  'piece_identite' => t.recrutement.portail.elementPiece,
  'contrat' => t.recrutement.portail.elementContrat,
  'avis' => t.attente.carteAccuse,
  'code_conduite' => t.recrutement.portail.elementCodeConduite,
  'photo' => t.recrutement.portail.elementPhoto,
  'accord_publication' => t.recrutement.portail.elementAccordPublication,
  'pays_versement' => t.recrutement.portail.elementPaysVersement,
  _ => null,
};

/// La phrase « a faire maintenant » de la route [chemin].
String _phraseAction(String chemin) {
  final a = t.recrutement.accueil.aFaire;
  if (chemin == Routes.attenteCadre) return a.cadre;
  if (chemin == Routes.attenteAccords) return a.accords;
  if (chemin == Routes.attentePiece) return a.piece;
  if (chemin == Routes.attenteEntretien) return a.entretien;
  return a.reponses;
}

ActionDossier _action(({String libelle, String chemin}) p) => ActionDossier(
  phrase: _phraseAction(p.chemin),
  libelle: p.libelle,
  chemin: p.chemin,
);

/// Les lignes du dossier : le cadre, les accords, la piece, la photo et les
/// reponses, chacune avec son etat lu au serveur.
List<LigneDossier> lignesDuDossier(EtatDossier d) {
  final CandidatureDossier c = d.candidature;
  final r = t.recrutement.portail;
  final l = t.recrutement.accueil.lignes;
  final bool ouvert = c.questionnaireOuvert;
  final bool cadreAFaire = c.cadre.publie && !c.cadre.accepte;
  final bool accords = accordsFaits(d);
  final bool piece = !pieceADeposer(d);
  final int restantes = c.questionnaire.manquants.length;
  final bool reponsesPretes = !c.questionnaire.perime && restantes == 0;
  final bool reponsesEnvoyees = !ouvert && c.questionnaire.envoyeLe != null;
  return <LigneDossier>[
    if (c.cadre.publie)
      LigneDossier(
        code: 'cadre',
        icone: AppIcons.cahier,
        libelle: r.elementCadre,
        valeur: cadreAFaire ? t.attente.etatAAccepter : r.etatFait,
        etat: cadreAFaire ? EtatLigne.aFaire : EtatLigne.fait,
        detail: l.cadreDetail,
      ),
    LigneDossier(
      code: 'accords',
      icone: AppIcons.contractuel,
      libelle: r.elementAccords,
      valeur: accords ? r.etatFait : t.attente.etatAAccepter,
      etat: accords ? EtatLigne.fait : EtatLigne.aFaire,
      detail: l.accordsDetail,
    ),
    if (!c.depotPieceSuspendu)
      LigneDossier(
        code: 'piece',
        icone: AppIcons.profil,
        libelle: r.elementPiece,
        valeur: piece ? r.etatFait : r.etatADeposer,
        etat: piece ? EtatLigne.fait : EtatLigne.aFaire,
        // INCIDENT-CANDIDATS (14/11/2026) : la piece recue se dit en mots.
        // AUDIT-PORTAIL-CANDIDAT : une piece refusee se dit a reprendre.
        legende: pieceRefusee(d)
            ? t.attente.refuseDetail(element: r.elementPiece)
            : pieceRedemandee(d)
            ? r.pieceDemandee
            : d.pieceDeposee
            ? r.pieceRecue
            : null,
        detail: l.pieceDetail,
      ),
    // HARMONISATION-E : la photo, lue dans etat_dossier() ; un serveur qui ne
    // la rend pas : pas de ligne.
    if (d.photoPosee != null)
      LigneDossier(
        code: 'photo',
        icone: AppIcons.image,
        libelle: r.elementPhoto,
        // COMPLEMENT-ET-FORMATS : redemandee, elle part avec les reponses.
        valeur: c.demande('photo')
            ? r.etatAEnvoyer
            : d.photoPosee!
            ? r.etatFait
            : r.etatAAjouter,
        etat: !c.demande('photo') && d.photoPosee!
            ? EtatLigne.fait
            : EtatLigne.aFaire,
        legende: c.demande('photo')
            ? r.photoDemandee
            : !d.photoPosee!
            ? null
            : (d.accordPublicationSigne ?? false)
            ? r.photoRecue
            : r.accordAEnvoyer,
        detail: l.photoDetail,
      ),
    LigneDossier(
      code: 'reponses',
      icone: AppIcons.dossiers,
      libelle: r.elementReponses,
      valeur: reponsesEnvoyees ? r.etatFait : r.etatAEnvoyer,
      etat: reponsesEnvoyees ? EtatLigne.fait : EtatLigne.aFaire,
      legende: !ouvert
          ? null
          : reponsesPretes
          ? r.reponsesPretes
          : r.reponsesRestantes(n: restantes),
      detail: l.reponsesDetail,
    ),
  ];
}

/// Ce que l'onglet Dossier dit de [d]. [d] porte une candidature.
LectureDossier lireDossier(EtatDossier d) {
  final CandidatureDossier c = d.candidature;
  final r = t.recrutement.portail;
  final a = t.recrutement.accueil;
  final List<LigneDossier> lignes = lignesDuDossier(d);

  if (c.issue == IssueCandidature.refusee) {
    return LectureDossier(
      titre: r.refuseeTitre,
      phrases: <PhraseDossier>[
        // Le texte du modele de la direction, mot pour mot ; jamais le motif.
        if (c.refusTexte != null)
          _phrase(c.refusTexte!, cle: 'portail-refus-texte', forte: true),
      ],
      lignes: const <LigneDossier>[],
      fermee: true,
    );
  }
  if (c.issue == IssueCandidature.retiree) {
    return LectureDossier(
      titre: r.retireeTitre,
      phrases: const <PhraseDossier>[],
      lignes: const <LigneDossier>[],
      fermee: true,
      retiree: true,
    );
  }
  if (c.enPause) {
    return LectureDossier(
      titre: r.enPauseTitre,
      phrases: <PhraseDossier>[
        if (c.pauseTexte != null)
          _phrase(c.pauseTexte!, cle: 'portail-pause-texte', forte: true),
        if (c.repriseLe != null)
          _phrase(r.repriseLe(date: _jour(c.repriseLe!)), muette: true),
        _phrase(r.libreDePartir, muette: true),
      ],
      lignes: lignes,
    );
  }
  // MAJEUR (directeur, 16/11/2026) : tant que « 18 ans ou plus » n'est pas
  // declare, aucune autre action n'est proposee.
  final bool majorite = c.majorite.aAttester;

  // « Faisons connaissance » : les accords, la piece, l'entretien.
  if (c.etape == EtapeCandidature.verifications) {
    return _salleDeux(d, lignes, majorite: majorite);
  }
  if (c.etape == EtapeCandidature.confirmee) {
    // « Bienvenue dans l'equipe » : la ligne d'etapes et la phrase de passage
    // le disent ; la session relue ouvre l'espace d'enseignant.
    return LectureDossier(
      titre: null,
      phrases: const <PhraseDossier>[],
      lignes: lignes,
      ensuite: a.etapes.ensuiteEquipe,
    );
  }

  final ({String libelle, String chemin})? prochaine = prochaineCandidature(
    c,
    dossier: d,
  );
  if (c.questionnaireOuvert) {
    final List<String> demandes = <String>[
      for (final String code in c.complementDemande)
        if (libelleElementDemande(code) case final String libelle) libelle,
    ];
    return LectureDossier(
      titre: r.aCompleterTitre,
      phrases: <PhraseDossier>[
        if (demandes.isNotEmpty) ...<PhraseDossier>[
          _phrase(r.complementDemande),
          // La liste que la direction a choisie, jamais un texte libre.
          _phrase(
            r.complementListe(elements: demandes.join(', ')),
            cle: 'portail-complement',
          ),
        ],
      ],
      lignes: lignes,
      titreLignes: r.listeTitre,
      action: prochaine == null ? null : _action(prochaine),
      attendMajorite: majorite,
      ensuite: a.etapes.ensuiteACompleter,
    );
  }
  if (c.etat == EtatCandidature.paiementNonDisponible) {
    // Versement pas encore possible : l'etat vient du serveur (transition 8
    // de L6), l'ecran ne le deduit pas du versement.
    return LectureDossier(
      titre: r.versementImpossibleTitre,
      phrases: <PhraseDossier>[
        _phrase(r.versementImpossible, cle: 'portail-versement'),
        _phrase(r.libreDePartir, muette: true),
      ],
      lignes: lignes,
      action: prochaine == null ? null : _action(prochaine),
      attendMajorite: majorite,
      actualisable: true,
      relisible: c.reponsesRelisibles,
    );
  }
  // En examen : la direction lit les reponses.
  return LectureDossier(
    titre: r.enExamenTitre,
    phrases: <PhraseDossier>[
      // AUDIT-PORTAIL-CANDIDAT : la piece refusee se dit, avec son chemin.
      if (pieceRefusee(d))
        _phrase(
          t.attente.refuseDetail(element: r.elementPiece),
          cle: 'portail-piece-refusee',
        ),
    ],
    lignes: lignes,
    action: prochaine == null ? null : _action(prochaine),
    attendMajorite: majorite,
    ensuite: a.etapes.ensuiteEnExamen,
    actualisable: true,
    relisible: c.reponsesRelisibles,
  );
}

/// La Salle de verification et d'entretien, telle que le candidat la lit.
/// Memes regles que le portail d'avant : un cadre neuf d'abord, puis les
/// accords, puis la piece ; ensuite l'entretien.
LectureDossier _salleDeux(
  EtatDossier d,
  List<LigneDossier> lignes, {
  required bool majorite,
}) {
  final CandidatureDossier c = d.candidature;
  final a = t.recrutement.accueil;
  final bool accordsAFaire = !accordsFaits(d);
  final bool pieceManque =
      d.manquants.contains(PieceManquante.pieceIdentite) || pieceADeposer(d);
  final bool refusee = d.etape == EtapeDossier.refuse;
  final String? entretien = libelleEntretienPortail(c);

  ActionDossier? action;
  if (!majorite) {
    if (cadreAAccepterEnSalle2(c)) {
      action = ActionDossier(
        phrase: a.aFaire.cadre,
        libelle: t.attente.lireEtAccepter,
        chemin: Routes.attenteCadre,
      );
    } else if (accordsAFaire) {
      action = ActionDossier(
        phrase: a.aFaire.accords,
        libelle: refusee ? t.attente.corriger : t.attente.lireEtAccepter,
        chemin: Routes.attenteAccords,
      );
    } else if (pieceManque && d.correctionAutorisee != false) {
      action = ActionDossier(
        phrase: refusee ? a.aFaire.corriger : a.aFaire.piece,
        libelle: refusee ? t.attente.corriger : t.attente.deposerLaPiece,
        chemin: Routes.attentePiece,
      );
    } else if (c.etat == EtatCandidature.entretienAPlanifier &&
        entretien != null) {
      action = ActionDossier(
        phrase: a.aFaire.entretien,
        libelle: entretien,
        chemin: Routes.attenteEntretien,
      );
    }
  }

  final String titre;
  final List<PhraseDossier> phrases;
  if (refusee) {
    titre = t.attente.refuse;
    phrases = <PhraseDossier>[
      // La base refuse un verdict negatif sans motif : cette phrase existe
      // toujours quand on arrive ici.
      if ((d.motifRefus ?? '').isNotEmpty) _phrase(d.motifRefus!, forte: true),
      _phrase(
        d.correctionAutorisee == false
            ? t.attente.correctionImpossible
            : t.attente.refuseDetail(element: t.attente.pieceIdentite),
      ),
    ];
  } else if (accordsAFaire || pieceManque) {
    titre = t.attente.dossierIncomplet;
    // Ce qui reste se lit dans « A faire maintenant » et dans les lignes.
    phrases = const <PhraseDossier>[];
  } else {
    titre = t.attente.titre;
    phrases = <PhraseDossier>[
      _phrase(
        <String>[
          if (d.deposeLe != null) t.attente.deposeLe(date: _jour(d.deposeLe!)),
          t.attente.delai,
        ].join('\n'),
        muette: true,
      ),
    ];
  }
  return LectureDossier(
    titre: titre,
    phrases: phrases,
    lignes: <LigneDossier>[
      for (final LigneDossier l in lignes)
        // En salle 2, les reponses sont envoyees : la ligne ne s'ouvre plus.
        if (l.code != 'reponses' && l.code != 'photo') l,
    ],
    action: action,
    attendMajorite: majorite,
    ensuite: a.etapes.ensuiteConnaissance,
    actualisable: action == null,
  );
}
