// Les formes de donnees de la direction pour la file des candidatures
// (`ADM-20`, `PortCandidaturesDirection`,
// `docs/current/CANDIDATURES/CONTRAT_PORTS_CANDIDATURES.md`, section 1).
//
// Miroir Dart de ce que le serveur rend, jamais un calcul : les compteurs
// d'etapes et d'alertes, le total du filtre, la page et l'etat de chaque ligne
// viennent de `lister_candidatures` et de `capacites_candidatures`
// (`20261021200000_cand_l1_socle_candidatures.sql`, redefinies par
// `20261022000100_cand_l2a2_gestes_direction.sql`). L'ecran lit ces champs ; il
// ne les recalcule pas.
//
// **Aucune donnee personnelle de contact.** Une ligne ne porte ni courriel, ni
// telephone, ni genre, ni piece, ni motif interne, ni reponse libre
// (`CONS` 8.3) : le serveur ne les rend pas, et ce fichier n'a aucun champ pour
// les recevoir. Du contact, seules deux marques voyagent.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'modeles_autres_competences.dart';
import 'modeles_candidature.dart';

/// Ce que la direction peut faire de la file, lu au serveur
/// (`capacites_candidatures`). Un widget lit cette capacite, jamais un role.
@immutable
class CapacitesCandidatures {
  /// Cree les capacites.
  const CapacitesCandidatures({
    this.peutLire = false,
    this.peutVoirContact = false,
    this.peutLireHorsGenre = false,
    this.genreLecteurConnu = false,
    this.peutDecider = false,
    this.peutImporter = false,
    this.peutMenerEntretien = false,
    this.peutEcrireReferentiel = false,
    this.gestes = const <String, bool>{},
    this.listes = const ListesGestes(),
  });

  /// Aucune capacite : un lecteur sans droit.
  static const CapacitesCandidatures aucune = CapacitesCandidatures();

  /// Lit les capacites rendues par le serveur. Une cle absente vaut faux : une
  /// capacite ne se suppose jamais.
  factory CapacitesCandidatures.depuisJson(Map<String, dynamic> json) {
    bool vrai(String cle) => json[cle] == true;
    final Object? brutGestes = json['gestes'];
    return CapacitesCandidatures(
      peutLire: vrai('peutLire'),
      peutVoirContact: vrai('peutVoirContact'),
      peutLireHorsGenre: vrai('peutLireHorsGenre'),
      genreLecteurConnu: vrai('genreLecteurConnu'),
      peutDecider: vrai('peutDecider'),
      peutImporter: vrai('peutImporter'),
      peutMenerEntretien: vrai('peutMenerEntretien'),
      peutEcrireReferentiel: vrai('peutEcrireReferentiel'),
      gestes: <String, bool>{
        if (brutGestes is Map)
          for (final MapEntry<Object?, Object?> e in brutGestes.entries)
            if (e.key is String) e.key! as String: e.value == true,
      },
      listes: ListesGestes.depuisJson(json['listes']),
    );
  }

  /// `candidatures.lire` : la file est lisible.
  final bool peutLire;

  /// `candidatures.contact` : le contact se lit dans le detail, journalise.
  final bool peutVoirContact;

  /// L'exception de lecture du super-admin, qui lit les deux cotes. Active, elle
  /// se dit en tete de la file (`CONS` 8.2).
  final bool peutLireHorsGenre;

  /// Le genre du lecteur est connu en base. Faux : le serveur refuse toute
  /// lecture (hors exception), et l'ecran le dit.
  final bool genreLecteurConnu;

  /// `candidatures.decider` : les gestes sur une candidature.
  final bool peutDecider;

  /// `candidatures.importer` : l'import des formulaires.
  final bool peutImporter;

  /// `entretiens.mener`.
  final bool peutMenerEntretien;

  /// `paiement.referentiel.ecrire`.
  final bool peutEcrireReferentiel;

  /// Une capacite par geste, vraie pour ceux que le serveur sait faire. Les
  /// noms sont ceux du serveur ; une cle absente vaut faux.
  final Map<String, bool> gestes;

  /// Les listes fermees des gestes (modeles de message, elements d'un
  /// complement, canaux d'un retrait), lues au serveur.
  final ListesGestes listes;

  /// Le serveur sait-il faire ce geste, pour ce lecteur ?
  bool geste(String nom) => gestes[nom] == true;

  /// Le geste « agir en lot » : la selection multiple n'a de sens que pour qui
  /// peut decider ET que le serveur ouvre en lot.
  bool get peutAgirEnLot => peutDecider && geste('agirEnLot');

  /// Le geste « garder pour suivi » (ligne `recue`) : tant que le directeur ne
  /// l'a pas confirme (`CONS` 0.3), le serveur le rend faux et l'ecran ne rend
  /// ni la puce ni le mot.
  bool get peutGarderPourSuivi => geste('garderPourSuivi');
}

/// Les listes fermees que le serveur donne aux gestes
/// (`capacites_candidatures().listes`). Une liste absente est vide : l'ecran
/// ne propose alors aucun choix, il ne l'invente pas.
@immutable
class ListesGestes {
  /// Cree les listes.
  const ListesGestes({
    this.modelesRefus = const <String>[],
    this.modelesPause = const <String>[],
    this.complementSalleExamen = const <String>[],
    this.complementSalleVerification = const <String>[],
    this.canauxRetrait = const <String>[],
    this.codesClotureComplement = const <String>[],
  });

  /// Lit les listes rendues par le serveur.
  factory ListesGestes.depuisJson(Object? brut) {
    if (brut is! Map) {
      return const ListesGestes();
    }
    List<String> codes(String cle) => List<String>.unmodifiable(<String>[
      if (brut[cle] is List)
        for (final Object? c in brut[cle] as List)
          if (c is String && c.isNotEmpty) c,
    ]);
    return ListesGestes(
      modelesRefus: codes('modelesRefus'),
      modelesPause: codes('modelesPause'),
      complementSalleExamen: codes('complementSalleExamen'),
      complementSalleVerification: codes('complementSalleVerification'),
      canauxRetrait: codes('canauxRetrait'),
      codesClotureComplement: codes('codesClotureComplement'),
    );
  }

  /// Les codes des modeles de message d'un refus, dans l'ordre du serveur.
  final List<String> modelesRefus;

  /// Les codes des modeles de message d'une pause.
  final List<String> modelesPause;

  /// Les elements qu'un complement peut nommer en Salle d'examen.
  final List<String> complementSalleExamen;

  /// Les elements qu'un complement peut nommer en Salle de verification et
  /// d'entretien.
  final List<String> complementSalleVerification;

  /// Les canaux par lesquels un retrait peut etre demande.
  final List<String> canauxRetrait;

  /// Les codes qui cloturent un complement en cours.
  final List<String> codesClotureComplement;
}

/// Les trois clefs de tri que le serveur sait servir.
enum TriCandidatures {
  /// La derniere activite d'abord (defaut du serveur).
  activite('activite'),

  /// La date de reception, la plus recente d'abord.
  recente('recente'),

  /// Le nom, par ordre alphabetique.
  nom('nom');

  const TriCandidatures(this.valeurSql);

  /// La valeur envoyee au serveur.
  final String valeurSql;
}

/// Le filtre de la file. Chaque axe nul veut dire « tous ». Seuls les axes que
/// `lister_candidatures` sait filtrer sont ici : un axe que le serveur refuse
/// (`22023`) n'a pas de champ.
@immutable
class FiltreCandidatures {
  /// Cree un filtre.
  const FiltreCandidatures({
    this.recherche = '',
    this.etape,
    this.etat,
    this.issue,
    this.enPause,
    this.paiement,
    this.paysResidence,
    this.competenceDomaine,
    this.competenceNiveauMin,
    this.competenceDisponibilite,
    this.competenceAccord,
  });

  /// Le texte cherche : nom partiel, reference `CAND-` exacte, courriel exact.
  /// Normalise au serveur (arabe et latin).
  final String recherche;

  /// L'etape (la salle).
  final EtapeCandidature? etape;

  /// L'etat dans l'etape.
  final EtatCandidature? etat;

  /// L'issue (refusee, retiree, en cours).
  final IssueCandidature? issue;

  /// Vrai : seulement les candidatures en pause. Faux : seulement celles qui
  /// ne le sont pas. Nul : toutes.
  final bool? enPause;

  /// Le versement.
  final EtatVersement? paiement;

  /// Le pays de residence declare (code ISO a deux lettres majuscules).
  final String? paysResidence;

  /// Autres competences (CAND-07) : un **code du catalogue** ou une **famille**
  /// (tous les codes de cette famille, desactives compris). Chaque cle de
  /// competence exige qu'une reponse existe : la liste ne rend alors que les
  /// personnes qui ont repondu a « Vos autres talents ».
  final String? competenceDomaine;

  /// Autres competences : ce niveau ou plus. Sans domaine, « au moins un domaine a
  /// ce niveau ».
  final NiveauCompetence? competenceNiveauMin;

  /// Autres competences : la disponibilite exacte (elle ne se classe pas).
  final DisponibiliteMission? competenceDisponibilite;

  /// Autres competences : vrai, seulement les personnes qui acceptent d'etre
  /// contactees ; faux, celles qui ont repondu sans accord. La recherche d'une
  /// personne pour une mission envoie toujours vrai.
  final bool? competenceAccord;

  /// Le texte cherche, sans les blancs de bord.
  String get rechercheNette => recherche.trim();

  /// La longueur que `lister_candidatures` accepte pour la recherche : au-dela,
  /// le serveur refuse tout le filtre (`22023`).
  static const int longueurRechercheMax = 200;

  /// Le texte cherche tel que le serveur le compare : les traits d'union que
  /// l'ecran affiche insecables dans une reference (U+2011) et
  /// les autres tirets reviennent au trait d'union ordinaire de la donnee, sans
  /// quoi une reference copiee a l'ecran ne retrouverait rien ; la longueur est
  /// bornee a ce que le serveur accepte.
  String get rechercheEnvoyee {
    final String nette = rechercheNette.replaceAll(
      RegExp('[\u2010\u2011\u2012\u2013\u2014\u2212]'),
      '-',
    );
    final Runes caracteres = nette.runes;
    return caracteres.length <= longueurRechercheMax
        ? nette
        : String.fromCharCodes(caracteres.take(longueurRechercheMax)).trim();
  }

  /// Vrai quand aucun axe n'est pose.
  bool get estVide =>
      rechercheNette.isEmpty &&
      etape == null &&
      etat == null &&
      issue == null &&
      enPause == null &&
      paiement == null &&
      paysResidence == null &&
      competenceDomaine == null &&
      competenceNiveauMin == null &&
      competenceDisponibilite == null &&
      competenceAccord == null;

  /// Le nombre d'axes poses (la recherche compte pour un).
  int get nombreAxes =>
      (rechercheNette.isEmpty ? 0 : 1) +
      (etape == null ? 0 : 1) +
      (etat == null ? 0 : 1) +
      (issue == null ? 0 : 1) +
      (enPause == null ? 0 : 1) +
      (paiement == null ? 0 : 1) +
      (paysResidence == null ? 0 : 1) +
      (competenceDomaine == null ? 0 : 1) +
      (competenceNiveauMin == null ? 0 : 1) +
      (competenceDisponibilite == null ? 0 : 1) +
      (competenceAccord == null ? 0 : 1);

  /// Le meme filtre, un axe change. Une fonction par axe rend `null` possible
  /// (« tous »).
  FiltreCandidatures avec({
    String? recherche,
    EtapeCandidature? Function()? etape,
    EtatCandidature? Function()? etat,
    IssueCandidature? Function()? issue,
    bool? Function()? enPause,
    EtatVersement? Function()? paiement,
    String? Function()? paysResidence,
    String? Function()? competenceDomaine,
    NiveauCompetence? Function()? competenceNiveauMin,
    DisponibiliteMission? Function()? competenceDisponibilite,
    bool? Function()? competenceAccord,
  }) => FiltreCandidatures(
    recherche: recherche ?? this.recherche,
    etape: etape == null ? this.etape : etape(),
    etat: etat == null ? this.etat : etat(),
    issue: issue == null ? this.issue : issue(),
    enPause: enPause == null ? this.enPause : enPause(),
    paiement: paiement == null ? this.paiement : paiement(),
    paysResidence: paysResidence == null ? this.paysResidence : paysResidence(),
    competenceDomaine: competenceDomaine == null
        ? this.competenceDomaine
        : competenceDomaine(),
    competenceNiveauMin: competenceNiveauMin == null
        ? this.competenceNiveauMin
        : competenceNiveauMin(),
    competenceDisponibilite: competenceDisponibilite == null
        ? this.competenceDisponibilite
        : competenceDisponibilite(),
    competenceAccord: competenceAccord == null
        ? this.competenceAccord
        : competenceAccord(),
  );

  /// Le meme filtre sans aucun axe : « Effacer les filtres ».
  FiltreCandidatures get efface => const FiltreCandidatures();

  @override
  bool operator ==(Object other) =>
      other is FiltreCandidatures &&
      other.rechercheNette == rechercheNette &&
      other.etape == etape &&
      other.etat == etat &&
      other.issue == issue &&
      other.enPause == enPause &&
      other.paiement == paiement &&
      other.paysResidence == paysResidence &&
      other.competenceDomaine == competenceDomaine &&
      other.competenceNiveauMin == competenceNiveauMin &&
      other.competenceDisponibilite == competenceDisponibilite &&
      other.competenceAccord == competenceAccord;

  @override
  int get hashCode => Object.hash(
    rechercheNette,
    etape,
    etat,
    issue,
    enPause,
    paiement,
    paysResidence,
    competenceDomaine,
    competenceNiveauMin,
    competenceDisponibilite,
    competenceAccord,
  );
}

/// La requete d'une page de la file : le filtre, le tri et la page (a partir de
/// 1). La cle du fournisseur : deux requetes egales partagent leur lecture.
@immutable
class RequeteCandidatures {
  /// Cree la requete.
  const RequeteCandidatures({
    this.filtre = const FiltreCandidatures(),
    this.tri = TriCandidatures.activite,
    this.page = 1,
  });

  /// Le filtre.
  final FiltreCandidatures filtre;

  /// Le tri, fait au serveur.
  final TriCandidatures tri;

  /// La page, a partir de 1.
  final int page;

  @override
  bool operator ==(Object other) =>
      other is RequeteCandidatures &&
      other.filtre == filtre &&
      other.tri == tri &&
      other.page == page;

  @override
  int get hashCode => Object.hash(filtre, tri, page);
}

/// Une ligne de la file : une candidature, sans aucun contact.
@immutable
class LigneCandidature {
  /// Cree une ligne.
  const LigneCandidature({
    required this.id,
    required this.reference,
    required this.nomComplet,
    required this.type,
    required this.etape,
    required this.etat,
    required this.issue,
    required this.enPause,
    required this.restreinte,
    required this.indisponible,
    required this.paiement,
    required this.courrielAObtenir,
    required this.indicatifAConfirmer,
    required this.derniereActivite,
    this.repriseLe,
    this.indisponibleJusquAu,
    this.paysResidence,
    this.responsableId,
    this.recueLe,
  });

  /// Lit une ligne rendue par le serveur, ou `null` quand elle n'a pas
  /// d'identifiant lisible : on n'invente pas une ligne.
  static LigneCandidature? depuisJson(Object? brut) {
    if (brut is! Map) {
      return null;
    }
    final Map<String, dynamic> json = Map<String, dynamic>.from(brut);
    final Object? id = json['id'];
    final Object? reference = json['reference'];
    if (id is! String || id.isEmpty || reference is! String) {
      return null;
    }
    String? texte(String cle) {
      final Object? v = json[cle];
      return v is String && v.trim().isNotEmpty ? v : null;
    }

    return LigneCandidature(
      id: id,
      reference: reference,
      nomComplet: texte('nomComplet') ?? '',
      type: texte('type') ?? '',
      etape: EtapeCandidature.depuisSql(json['etape']),
      etat: EtatCandidature.depuisSql(json['etat']),
      issue: IssueCandidature.depuisSql(json['issue']),
      enPause: json['enPause'] == true,
      repriseLe: DateTime.tryParse(texte('repriseLe') ?? ''),
      restreinte: json['restreinte'] == true,
      indisponible: json['indisponible'] == true,
      indisponibleJusquAu: DateTime.tryParse(
        texte('indisponibleJusquAu') ?? '',
      ),
      paiement: EtatVersement.depuisSql(json['paiement']),
      paysResidence: texte('paysResidence'),
      responsableId: texte('responsableId'),
      courrielAObtenir: json['courrielAObtenir'] == true,
      indicatifAConfirmer: json['indicatifAConfirmer'] == true,
      derniereActivite:
          DateTime.tryParse(texte('derniereActivite') ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      recueLe: DateTime.tryParse(texte('recueLe') ?? ''),
    );
  }

  /// L'identifiant de la candidature.
  final String id;

  /// La reference `CAND-…`, jamais reattribuee, distincte du matricule.
  final String reference;

  /// Le nom affiche.
  final String nomComplet;

  /// Le type de candidature (`enseignant`).
  final String type;

  /// L'etape, ou `null` pour une valeur que cette version ne connait pas.
  final EtapeCandidature? etape;

  /// L'etat dans l'etape (nul hors des deux salles qui en ont).
  final EtatCandidature? etat;

  /// L'issue.
  final IssueCandidature issue;

  /// La candidature est en pause.
  final bool enPause;

  /// La reprise prevue d'une pause, si elle est connue.
  final DateTime? repriseLe;

  /// Confirmee puis restreinte (piece, versement ou decision). La cause n'est
  /// lue que dans le detail.
  final bool restreinte;

  /// Confirmee mais indisponible aujourd'hui.
  final bool indisponible;

  /// La date jusqu'a laquelle elle l'est, si le serveur la connait.
  final DateTime? indisponibleJusquAu;

  /// Le versement.
  final EtatVersement paiement;

  /// Le pays de residence declare (code ISO), ou `null`.
  final String? paysResidence;

  /// L'identifiant du responsable, ou `null`. Le serveur ne rend pas son nom
  /// dans la liste.
  final String? responsableId;

  /// Aucun courriel valide n'est connu : « Courriel a obtenir ».
  final bool courrielAObtenir;

  /// Un telephone brut attend la confirmation de son indicatif.
  final bool indicatifAConfirmer;

  /// La derniere activite, en UTC.
  final DateTime derniereActivite;

  /// La date de reception, en UTC.
  final DateTime? recueLe;
}

/// Les compteurs des quatre alertes, jamais confondues. Un compteur que le
/// serveur ne sert pas encore est `null` : l'ecran le dit seul, il n'affiche
/// jamais un zero qui ne serait pas lu.
@immutable
class CompteursAlertes {
  /// Cree les compteurs.
  const CompteursAlertes({
    this.bloquees,
    this.entretiensEnRetard,
    this.informationsManquantes,
    this.confirmeesIndisponibles,
  });

  /// Lit les compteurs rendus par le serveur ; un compteur absent ou nul reste
  /// nul.
  factory CompteursAlertes.depuisJson(Object? brut) {
    if (brut is! Map) {
      return const CompteursAlertes();
    }
    int? entier(String cle) {
      final Object? v = brut[cle];
      return v is int && v >= 0 ? v : null;
    }

    return CompteursAlertes(
      bloquees: entier('bloquees'),
      entretiensEnRetard: entier('entretiensEnRetard'),
      informationsManquantes: entier('informationsManquantes'),
      confirmeesIndisponibles: entier('confirmeesIndisponibles'),
    );
  }

  /// Un controle faux nomme, ou une restriction.
  final int? bloquees;

  /// Un entretien dont la date est passee sans compte rendu.
  final int? entretiensEnRetard;

  /// A completer, complement demande, courriel a obtenir, indicatif a
  /// confirmer.
  final int? informationsManquantes;

  /// Confirmees mais indisponibles.
  final int? confirmeesIndisponibles;

  /// Les quatre compteurs sont servis.
  bool get tousServis =>
      bloquees != null &&
      entretiensEnRetard != null &&
      informationsManquantes != null &&
      confirmeesIndisponibles != null;

  /// Les quatre sont servis et valent zero : « Rien a traiter ».
  bool get rienATraiter =>
      tousServis &&
      bloquees == 0 &&
      entretiensEnRetard == 0 &&
      informationsManquantes == 0 &&
      confirmeesIndisponibles == 0;
}

/// Une page de la file, telle que le serveur la rend.
@immutable
class PageCandidatures {
  /// Cree une page.
  const PageCandidatures({
    required this.lignes,
    required this.total,
    required this.page,
    required this.taillePage,
    required this.compteursEtapes,
    required this.compteursAlertes,
  });

  /// Lit la reponse de `lister_candidatures`. Une reponse sans total ni page
  /// n'est pas une page : [FormatException], jamais une liste inventee.
  factory PageCandidatures.depuisJson(Object? brut) {
    if (brut is! Map) {
      throw const FormatException('Page de candidatures attendue.');
    }
    final Object? total = brut['total'];
    final Object? page = brut['page'];
    final Object? taille = brut['taillePage'];
    if (total is! int || page is! int || taille is! int || taille < 1) {
      throw const FormatException('Total, page ou taille de page absents.');
    }
    final Object? brutLignes = brut['lignes'];
    final Object? brutEtapes = brut['compteursEtapes'];
    return PageCandidatures(
      lignes: List<LigneCandidature>.unmodifiable(<LigneCandidature>[
        if (brutLignes is List)
          for (final Object? b in brutLignes)
            if (LigneCandidature.depuisJson(b) case final LigneCandidature l) l,
      ]),
      total: total,
      page: page,
      taillePage: taille,
      compteursEtapes: Map<EtapeCandidature, int>.unmodifiable(
        <EtapeCandidature, int>{
          if (brutEtapes is Map)
            for (final EtapeCandidature e in EtapeCandidature.values)
              if (brutEtapes[e.valeurSql] case final int n when n >= 0) e: n,
        },
      ),
      compteursAlertes: CompteursAlertes.depuisJson(brut['compteursAlertes']),
    );
  }

  /// Les lignes de la page, dans l'ordre du tri serveur.
  final List<LigneCandidature> lignes;

  /// Le total reel du filtre, pas celui de la page.
  final int total;

  /// La page, a partir de 1.
  final int page;

  /// Le nombre de lignes par page, fixe par le serveur.
  final int taillePage;

  /// Les candidatures en cours par etape, sur toute la portee du lecteur, sans
  /// les autres filtres. Une etape absente n'est pas servie.
  final Map<EtapeCandidature, int> compteursEtapes;

  /// Les compteurs des quatre alertes.
  final CompteursAlertes compteursAlertes;

  /// Le nombre de pages du filtre, une au moins.
  int get pages => math.max(1, (total + taillePage - 1) ~/ taillePage);

  /// Le rang de la premiere ligne de la page dans le filtre (0 sans ligne).
  int get debut => lignes.isEmpty ? 0 : (page - 1) * taillePage + 1;

  /// Le rang de la derniere ligne de la page dans le filtre (0 sans ligne).
  int get fin => lignes.isEmpty ? 0 : debut + lignes.length - 1;
}
