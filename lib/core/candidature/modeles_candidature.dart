// Les formes de donnees du candidat dans `/attente` (CAND-01, TUT-00b etendu).
//
// Miroir Dart de ce que le serveur rend, jamais un calcul : l'etape, l'etat,
// la pause, la liste de ce qui reste a completer et les raisons d'un envoi
// bloque viennent de `etat_dossier()` (cle `candidature`,
// `20261022000000_cand_l2a1_moteur_salle_examen.sql`, C12). L'ecran lit ces
// champs ; il ne les recalcule pas.
//
// **Aucun montant.** Decision du directeur du 22/10/2026 : le candidat voit la
// part de l'enseignant en pourcentage, jamais un taux par eleve et par heure.
// `ConditionsRemuneration.depuisJson` ne lit donc ni `parElevePresentEtParHeure`
// ni `devise`, meme si une version du serveur les rendait encore.
library;

import 'package:flutter/foundation.dart';

/// L'etape de la candidature (colonne `etape`).
enum EtapeCandidature {
  /// Reçue, sans compte.
  recue('recue'),

  /// Invitee, sans compte.
  invitee('invitee'),

  /// Salle d'examen.
  prequalification('prequalification'),

  /// Salle de verification et d'entretien.
  verifications('verifications'),

  /// Salle des prets a enseigner.
  confirmee('confirmee');

  const EtapeCandidature(this.valeurSql);

  /// La valeur ecrite en base.
  final String valeurSql;

  /// La valeur lue, ou `null` pour une valeur que cette version ne connait pas.
  static EtapeCandidature? depuisSql(Object? valeur) {
    for (final EtapeCandidature e in values) {
      if (e.valeurSql == valeur) {
        return e;
      }
    }
    return null;
  }
}

/// L'etat dans l'etape (colonne `etat`, nul hors des deux etapes qui en ont).
enum EtatCandidature {
  /// A completer : le questionnaire et le cadre restent a faire.
  aCompleter('a_completer'),

  /// En examen : la direction lit les reponses.
  enExamen('en_examen'),

  /// Versement pas encore possible : aucun moyen de versement confirme dans
  /// le pays declare ; la candidature est gardee en Salle d'examen (transition
  /// 8 de L6, `private.paiement_recalculer`). Etat rendu par le serveur, que
  /// l'ecran ne deduit pas du versement.
  paiementNonDisponible('paiement_non_disponible'),

  /// Entretien a planifier.
  entretienAPlanifier('entretien_a_planifier'),

  /// Entretien planifie.
  entretienPlanifie('entretien_planifie'),

  /// Decision en attente.
  decisionEnAttente('decision_en_attente');

  const EtatCandidature(this.valeurSql);

  /// La valeur ecrite en base.
  final String valeurSql;

  /// La valeur lue, ou `null`.
  static EtatCandidature? depuisSql(Object? valeur) {
    for (final EtatCandidature e in values) {
      if (e.valeurSql == valeur) {
        return e;
      }
    }
    return null;
  }
}

/// L'issue de la candidature (colonne `issue`).
enum IssueCandidature {
  /// En cours.
  enCours('en_cours'),

  /// Refusee par l'academie.
  refusee('refusee'),

  /// Retiree par le candidat.
  retiree('retiree');

  const IssueCandidature(this.valeurSql);

  /// La valeur ecrite en base.
  final String valeurSql;

  /// La valeur lue, `enCours` par defaut (jamais une issue inventee).
  static IssueCandidature depuisSql(Object? valeur) {
    for (final IssueCandidature e in values) {
      if (e.valeurSql == valeur) {
        return e;
      }
    }
    return IssueCandidature.enCours;
  }
}

/// La dimension « versement » de la candidature, ses quatre codes seulement
/// (jamais une decision interne ni une note).
enum EtatVersement {
  /// Aucun moyen de versement declare.
  inconnu('inconnu'),

  /// A verifier par l'academie.
  aVerifier('a_verifier'),

  /// Confirme.
  compatible('compatible'),

  /// Aucun moyen possible pour l'instant.
  incompatible('incompatible');

  const EtatVersement(this.valeurSql);

  /// La valeur ecrite en base.
  final String valeurSql;

  /// La valeur lue, `inconnu` par defaut.
  static EtatVersement depuisSql(Object? valeur) {
    for (final EtatVersement e in values) {
      if (e.valeurSql == valeur) {
        return e;
      }
    }
    return EtatVersement.inconnu;
  }
}

/// Ce que le serveur dit du questionnaire pour ce candidat.
@immutable
class EtatQuestionnaire {
  /// Cree l'etat.
  const EtatQuestionnaire({
    this.versionCourante,
    this.versionReponses,
    this.perime = false,
    this.envoyeLe,
    this.manquants = const <String>[],
  });

  /// Lit le bloc `questionnaire` de `etat_dossier().candidature`.
  factory EtatQuestionnaire.depuisJson(Object? brut) {
    if (brut is! Map) {
      return const EtatQuestionnaire();
    }
    return EtatQuestionnaire(
      versionCourante: brut['versionCourante'] as String?,
      versionReponses: brut['versionReponses'] as String?,
      perime: brut['perime'] == true,
      envoyeLe: _instant(brut['envoyeLe']),
      manquants: _codes(brut['manquants']),
    );
  }

  /// La version courante du questionnaire.
  final String? versionCourante;

  /// La version a laquelle le candidat a repondu, s'il l'a fait.
  final String? versionReponses;

  /// Vrai quand les reponses viennent d'une version plus ancienne.
  final bool perime;

  /// Le moment de l'envoi, s'il a eu lieu.
  final DateTime? envoyeLe;

  /// Les codes des champs requis encore sans reponse valable.
  final List<String> manquants;

  @override
  bool operator ==(Object other) =>
      other is EtatQuestionnaire &&
      other.versionCourante == versionCourante &&
      other.versionReponses == versionReponses &&
      other.perime == perime &&
      other.envoyeLe == envoyeLe &&
      listEquals(other.manquants, manquants);

  @override
  int get hashCode => Object.hash(
    versionCourante,
    versionReponses,
    perime,
    envoyeLe,
    Object.hashAll(manquants),
  );
}

/// Le cadre religieux et pedagogique, vu du candidat.
@immutable
class EtatCadre {
  /// Cree l'etat.
  const EtatCadre({this.versionRequise, this.accepte = false});

  /// Lit le bloc `cadreReligieux`.
  factory EtatCadre.depuisJson(Object? brut) {
    if (brut is! Map) {
      return const EtatCadre();
    }
    return EtatCadre(
      versionRequise: brut['versionRequise'] as String?,
      accepte: brut['accepte'] == true,
    );
  }

  /// La version requise, nulle tant que le directeur ne l'a pas publiee.
  final String? versionRequise;

  /// Vrai quand le candidat a accepte la version requise.
  final bool accepte;

  /// Vrai quand une version est publiee.
  bool get publie => versionRequise != null;

  @override
  bool operator ==(Object other) =>
      other is EtatCadre &&
      other.versionRequise == versionRequise &&
      other.accepte == accepte;

  @override
  int get hashCode => Object.hash(versionRequise, accepte);
}

/// La candidature d'un compte, telle que `etat_dossier()` la rend.
@immutable
class CandidatureDossier {
  /// Cree une candidature.
  const CandidatureDossier({
    this.existe = false,
    this.etape,
    this.etat,
    this.issue = IssueCandidature.enCours,
    this.enPause = false,
    this.repriseLe,
    this.version = 0,
    this.pauseTexte,
    this.refusTexte,
    this.questionnaire = const EtatQuestionnaire(),
    this.cadre = const EtatCadre(),
    this.conditionsDisponibles = false,
    this.versionConditions,
    this.conditionsAcceptees = false,
    this.paiement = EtatVersement.inconnu,
    this.aCompleter = const <String>[],
    this.complementDemande = const <String>[],
    this.peutEnvoyer = false,
    this.envoiBloque = const <String>[],
  });

  /// Un compte sans candidature (`{"candidature": false}`), ou un serveur
  /// d'avant ce lot qui ne rend pas la cle.
  static const CandidatureDossier aucune = CandidatureDossier();

  /// Lit la cle `candidature` de `etat_dossier()`. Une cle absente, nulle ou
  /// mal formee vaut « aucune candidature » : l'ecran ne devine rien.
  factory CandidatureDossier.depuisJson(Object? brut) {
    if (brut is! Map || brut['candidature'] != true) {
      return CandidatureDossier.aucune;
    }
    final Object? conditions = brut['conditionsRemuneration'];
    return CandidatureDossier(
      existe: true,
      etape: EtapeCandidature.depuisSql(brut['etape']),
      etat: EtatCandidature.depuisSql(brut['etat']),
      issue: IssueCandidature.depuisSql(brut['issue']),
      enPause: brut['enPause'] == true,
      repriseLe: _jour(brut['repriseLe']),
      version: brut['version'] is int ? brut['version'] as int : 0,
      pauseTexte: _texteModele(brut['pauseTexte']),
      refusTexte: _texteModele(brut['refusTexte']),
      questionnaire: EtatQuestionnaire.depuisJson(brut['questionnaire']),
      cadre: EtatCadre.depuisJson(brut['cadreReligieux']),
      conditionsDisponibles:
          conditions is Map && conditions['disponible'] == true,
      versionConditions: conditions is Map
          ? conditions['version'] as String?
          : null,
      conditionsAcceptees: conditions is Map && conditions['acceptees'] == true,
      paiement: EtatVersement.depuisSql(brut['paiement']),
      aCompleter: _codes(brut['aCompleter']),
      complementDemande: _codes(brut['complementDemande']),
      peutEnvoyer: brut['peutEnvoyer'] == true,
      envoiBloque: _codes(brut['envoiBloque']),
    );
  }

  /// Vrai quand le compte porte une candidature.
  final bool existe;

  /// L'etape, nulle si elle est inconnue de cette version de l'application.
  final EtapeCandidature? etape;

  /// L'etat dans l'etape.
  final EtatCandidature? etat;

  /// L'issue.
  final IssueCandidature issue;

  /// Vrai pendant une pause decidee par l'academie.
  final bool enPause;

  /// La reprise prevue, si la direction l'a donnee.
  final DateTime? repriseLe;

  /// La version de la candidature, pour la concurrence optimiste des gestes
  /// du candidat (envoi, retrait).
  final int version;

  /// Le texte du modele de pause, rendu mot pour mot. **Absent aujourd'hui** :
  /// `etat_dossier()` (L2A1, C12) ne rend que la cle du modele
  /// (`pauseModele`), jamais son texte ; les textes arrivent avec le lot L5,
  /// sous un nom que ce lot fixera. Tant qu'il manque, le portail dit l'etat
  /// par son titre, sans texte. Jamais le motif interne.
  final String? pauseTexte;

  /// Le texte du modele de refus, rendu mot pour mot. **Absent aujourd'hui**,
  /// comme [pauseTexte] (le serveur rend `refusModele`, une cle). Jamais le
  /// motif interne.
  final String? refusTexte;

  /// L'etat du questionnaire.
  final EtatQuestionnaire questionnaire;

  /// L'etat du cadre religieux et pedagogique.
  final EtatCadre cadre;

  /// Vrai quand les conditions de remuneration sont lisibles.
  final bool conditionsDisponibles;

  /// La version des conditions de remuneration lues.
  final String? versionConditions;

  /// Vrai quand le candidat a accepte ces conditions.
  final bool conditionsAcceptees;

  /// L'etat du versement.
  final EtatVersement paiement;

  /// Ce qui reste a completer : `questionnaire`, `cadre_religieux`.
  final List<String> aCompleter;

  /// Les elements que la direction a demande de completer (liste choisie par
  /// elle, jamais un texte libre).
  final List<String> complementDemande;

  /// Vrai quand rien ne bloque l'envoi, selon le serveur.
  final bool peutEnvoyer;

  /// Les raisons d'un envoi bloque, en codes.
  final List<String> envoiBloque;

  /// Vrai en Salle d'examen, candidature en cours.
  bool get enSalleExamen =>
      existe &&
      etape == EtapeCandidature.prequalification &&
      issue == IssueCandidature.enCours;

  /// Vrai en Salle de verification et d'entretien, candidature en cours.
  bool get enSalleVerification =>
      existe &&
      etape == EtapeCandidature.verifications &&
      issue == IssueCandidature.enCours;

  /// Vrai quand le questionnaire s'ouvre en ecriture : Salle d'examen, a
  /// completer, hors pause.
  bool get questionnaireOuvert =>
      enSalleExamen && etat == EtatCandidature.aCompleter && !enPause;

  /// Vrai quand les reponses envoyees se relisent : Salle d'examen, questionnaire
  /// ferme (examen, pause, versement pas encore possible), un envoi a eu lieu.
  /// C'est l'entree de la lecture seule de `/attente/candidature`.
  bool get reponsesRelisibles =>
      enSalleExamen && !questionnaireOuvert && questionnaire.envoyeLe != null;

  /// Vrai quand le candidat peut retirer sa candidature : en cours, avant la
  /// Salle des prets a enseigner, pause comprise.
  bool get peutRetirer =>
      existe &&
      issue == IssueCandidature.enCours &&
      (etape == EtapeCandidature.prequalification ||
          etape == EtapeCandidature.verifications);

  @override
  bool operator ==(Object other) =>
      other is CandidatureDossier &&
      other.existe == existe &&
      other.etape == etape &&
      other.etat == etat &&
      other.issue == issue &&
      other.enPause == enPause &&
      other.repriseLe == repriseLe &&
      other.version == version &&
      other.pauseTexte == pauseTexte &&
      other.refusTexte == refusTexte &&
      other.questionnaire == questionnaire &&
      other.cadre == cadre &&
      other.conditionsDisponibles == conditionsDisponibles &&
      other.versionConditions == versionConditions &&
      other.conditionsAcceptees == conditionsAcceptees &&
      other.paiement == paiement &&
      listEquals(other.aCompleter, aCompleter) &&
      listEquals(other.complementDemande, complementDemande) &&
      other.peutEnvoyer == peutEnvoyer &&
      listEquals(other.envoiBloque, envoiBloque);

  @override
  int get hashCode => Object.hashAll(<Object?>[
    existe,
    etape,
    etat,
    issue,
    enPause,
    repriseLe,
    version,
    pauseTexte,
    refusTexte,
    questionnaire,
    cadre,
    conditionsDisponibles,
    versionConditions,
    conditionsAcceptees,
    paiement,
    Object.hashAll(aCompleter),
    Object.hashAll(complementDemande),
    peutEnvoyer,
    Object.hashAll(envoiBloque),
  ]);
}

/// La ligne d'un public dans les conditions de remuneration : la part de
/// l'enseignant, en pour mille du prix public.
@immutable
class PublicRemuneration {
  /// Cree la ligne.
  const PublicRemuneration({required this.code, required this.partPourMille});

  /// Le code du public : `enfant` ou `adulte`.
  final String code;

  /// La part de l'enseignant, en pour mille du prix public (470 vaut 47 %).
  final int partPourMille;

  @override
  bool operator ==(Object other) =>
      other is PublicRemuneration &&
      other.code == code &&
      other.partPourMille == partPourMille;

  @override
  int get hashCode => Object.hash(code, partPourMille);
}

/// Les conditions de remuneration, lues dans la politique de paie en base
/// (`conditions_remuneration_candidat()`, CAND-BR-12).
///
/// Rien n'est ecrit en dur : la part et les publics viennent du serveur. Aucun
/// montant n'est lu (decision du directeur du 22/10/2026).
@immutable
class ConditionsRemuneration {
  /// Cree les conditions.
  const ConditionsRemuneration({
    required this.version,
    required this.publics,
    this.dateEffet,
    this.enVigueur = false,
    this.accepteesLe,
  });

  /// Lit la reponse du serveur. Un `disponible` faux ne passe pas ici : c'est
  /// une capacite indisponible, levee par l'adaptateur.
  factory ConditionsRemuneration.depuisJson(Map<String, dynamic> json) {
    final Object? publics = json['publics'];
    return ConditionsRemuneration(
      version: json['version'] as String? ?? '',
      dateEffet: _jour(json['dateEffet']),
      enVigueur: json['enVigueur'] == true,
      accepteesLe: _instant(json['accepteesLe']),
      publics: <PublicRemuneration>[
        if (publics is List)
          for (final Object? p in publics)
            if (p is Map && p['public'] is String && p['partPourMille'] is int)
              PublicRemuneration(
                code: p['public'] as String,
                partPourMille: p['partPourMille'] as int,
              ),
      ],
    );
  }

  /// La version de la politique : celle que l'envoi doit porter.
  final String version;

  /// La date d'effet de la politique.
  final DateTime? dateEffet;

  /// Vrai quand la politique est deja en vigueur.
  final bool enVigueur;

  /// Le moment ou ce candidat a accepte ces conditions, s'il l'a fait.
  final DateTime? accepteesLe;

  /// Une ligne par public rendu par le serveur.
  final List<PublicRemuneration> publics;

  /// Vrai quand tous les publics ont la meme part : une seule phrase la dit.
  bool get partUnique =>
      publics.isNotEmpty &&
      publics.every(
        (PublicRemuneration p) =>
            p.partPourMille == publics.first.partPourMille,
      );

  @override
  bool operator ==(Object other) =>
      other is ConditionsRemuneration &&
      other.version == version &&
      other.dateEffet == dateEffet &&
      other.enVigueur == enVigueur &&
      other.accepteesLe == accepteesLe &&
      listEquals(other.publics, publics);

  @override
  int get hashCode => Object.hash(
    version,
    dateEffet,
    enVigueur,
    accepteesLe,
    Object.hashAll(publics),
  );
}

/// Le type d'un champ du questionnaire.
enum TypeChamp {
  /// Une reponse parmi une liste fermee.
  choix('choix'),

  /// Plusieurs reponses parmi une liste fermee.
  choixMultiple('choix_multiple'),

  /// Oui ou non.
  booleen('booleen'),

  /// Des creneaux hebdomadaires dans un fuseau.
  creneaux('creneaux');

  const TypeChamp(this.valeurSql);

  /// La valeur rendue par le serveur.
  final String valeurSql;

  /// La valeur lue, ou `null`.
  static TypeChamp? depuisSql(Object? valeur) {
    for (final TypeChamp e in values) {
      if (e.valeurSql == valeur) {
        return e;
      }
    }
    return null;
  }
}

/// Une option d'un champ de choix : le code que le serveur attend.
@immutable
class OptionQuestionnaire {
  /// Cree une option.
  const OptionQuestionnaire(
    this.code, {
    this.horsReferentiel = false,
    this.nom,
    this.methode,
  });

  /// Le code de la valeur.
  final String code;

  /// Vrai pour une langue que Rewayah ne propose pas encore comme langue de
  /// cours (hors du referentiel) : elle est marquee comme telle.
  final bool horsReferentiel;

  /// Le nom propre que le serveur donne a l'option quand elle n'a pas de
  /// traduction (le nom de marque d'un moyen de paiement, comme « Orange
  /// Money ») ; rendu tel quel. Nul pour toute autre option : son texte vient
  /// de `assets/i18n`, par son code.
  final String? nom;

  /// La methode de versement d'un moyen de paiement (`mobile_money` ou
  /// `virement_bancaire`), quand le serveur la donne.
  final String? methode;

  @override
  bool operator ==(Object other) =>
      other is OptionQuestionnaire &&
      other.code == code &&
      other.horsReferentiel == horsReferentiel &&
      other.nom == nom &&
      other.methode == methode;

  @override
  int get hashCode => Object.hash(code, horsReferentiel, nom, methode);
}

/// Un champ du questionnaire versionne.
@immutable
class ChampQuestionnaire {
  /// Cree un champ.
  const ChampQuestionnaire({
    required this.code,
    required this.carte,
    required this.type,
    required this.requis,
    this.min,
    this.max,
    this.dependDe,
    this.options = const <OptionQuestionnaire>[],
  });

  /// Lit un champ.
  static ChampQuestionnaire? depuisJson(Object? brut) {
    if (brut is! Map) {
      return null;
    }
    final TypeChamp? type = TypeChamp.depuisSql(brut['type']);
    final Object? code = brut['code'];
    final Object? carte = brut['carte'];
    if (type == null || code is! String || carte is! String) {
      return null;
    }
    final Object? options = brut['options'];
    return ChampQuestionnaire(
      code: code,
      carte: carte,
      type: type,
      requis: brut['requis'] == true,
      min: brut['min'] is int ? brut['min'] as int : null,
      max: brut['max'] is int ? brut['max'] as int : null,
      dependDe: brut['dependDe'] as String?,
      options: <OptionQuestionnaire>[
        if (options is List)
          for (final Object? o in options)
            if (o is String)
              OptionQuestionnaire(o)
            else if (o is Map && o['code'] is String)
              OptionQuestionnaire(
                o['code'] as String,
                horsReferentiel: o['referentiel'] == false,
                nom: o['nom'] is String && (o['nom'] as String).trim().isNotEmpty
                    ? (o['nom'] as String).trim()
                    : null,
                methode: o['methode'] is String ? o['methode'] as String : null,
              ),
      ],
    );
  }

  /// Le code du champ, cle de la reponse.
  final String code;

  /// La carte (le theme) qui porte le champ.
  final String carte;

  /// Le type.
  final TypeChamp type;

  /// Vrai quand une reponse est exigee.
  final bool requis;

  /// Le nombre minimal de reponses d'un choix multiple.
  final int? min;

  /// Le nombre maximal de reponses.
  final int? max;

  /// Le champ dont dependent les options (les operateurs dependent du pays de
  /// versement).
  final String? dependDe;

  /// Les options lues au serveur.
  final List<OptionQuestionnaire> options;

  @override
  bool operator ==(Object other) =>
      other is ChampQuestionnaire &&
      other.code == code &&
      other.carte == carte &&
      other.type == type &&
      other.requis == requis &&
      other.min == min &&
      other.max == max &&
      other.dependDe == dependDe &&
      listEquals(other.options, options);

  @override
  int get hashCode => Object.hash(
    code,
    carte,
    type,
    requis,
    min,
    max,
    dependDe,
    Object.hashAll(options),
  );
}

/// Le dernier document de reponses du candidat : un brouillon, ou un envoi.
@immutable
class DernieresReponses {
  /// Cree le document.
  const DernieresReponses({
    required this.questionnaireVersion,
    required this.reponses,
    required this.brouillon,
    required this.perime,
    this.soumisLe,
    this.envoyeLe,
  });

  /// Lit le document.
  static DernieresReponses? depuisJson(Object? brut) {
    if (brut is! Map || brut['reponses'] is! Map) {
      return null;
    }
    return DernieresReponses(
      questionnaireVersion: brut['questionnaireVersion'] as String? ?? '',
      reponses: Map<String, Object?>.unmodifiable(
        Map<String, Object?>.from(brut['reponses'] as Map),
      ),
      brouillon: brut['brouillon'] == true,
      perime: brut['perime'] == true,
      soumisLe: _instant(brut['soumisLe']),
      envoyeLe: _instant(brut['envoyeLe']),
    );
  }

  /// La version du questionnaire a laquelle le document repond.
  final String questionnaireVersion;

  /// Les reponses, par code de champ.
  final Map<String, Object?> reponses;

  /// Vrai pour un brouillon, faux pour un envoi.
  final bool brouillon;

  /// Vrai quand le questionnaire courant n'est plus cette version.
  final bool perime;

  /// Le moment de la derniere ecriture.
  final DateTime? soumisLe;

  /// Le moment de l'envoi, pour un document envoye.
  final DateTime? envoyeLe;
}

/// Le questionnaire de la Salle d'examen, tel que le serveur le rend.
///
/// Il rend des **codes**, jamais des libelles : l'application les affiche par
/// ses cles de traduction (fr et ar). Un code sans traduction se signale, il
/// ne s'affiche jamais tel quel.
@immutable
class Questionnaire {
  /// Cree le questionnaire.
  const Questionnaire({
    required this.version,
    required this.champs,
    required this.candidatureVersion,
    required this.versionBrouillon,
    this.dernieresReponses,
  });

  /// Lit la reponse de `questionnaire_salle_examen()`. Un `disponible` faux ne
  /// passe pas ici : c'est une capacite indisponible, levee par l'adaptateur.
  factory Questionnaire.depuisJson(Map<String, dynamic> json) {
    final Object? champs = json['champs'];
    return Questionnaire(
      version: json['version'] as String? ?? '',
      champs: <ChampQuestionnaire>[
        if (champs is List)
          for (final Object? c in champs) ?ChampQuestionnaire.depuisJson(c),
      ],
      candidatureVersion: json['candidatureVersion'] is int
          ? json['candidatureVersion'] as int
          : 0,
      versionBrouillon: json['versionBrouillon'] is int
          ? json['versionBrouillon'] as int
          : 0,
      dernieresReponses: DernieresReponses.depuisJson(
        json['dernieresReponses'],
      ),
    );
  }

  /// La version courante du questionnaire.
  final String version;

  /// Les champs, dans l'ordre du serveur.
  final List<ChampQuestionnaire> champs;

  /// La version de la candidature : le `versionAttendue` de l'envoi.
  final int candidatureVersion;

  /// La version du brouillon ouvert (0 sans brouillon) : le `versionAttendue`
  /// du brouillon.
  final int versionBrouillon;

  /// Le dernier document du candidat.
  final DernieresReponses? dernieresReponses;

  /// Le champ de ce code, s'il existe.
  ChampQuestionnaire? champ(String code) {
    for (final ChampQuestionnaire c in champs) {
      if (c.code == code) {
        return c;
      }
    }
    return null;
  }

  /// Les codes des cartes, dans l'ordre de leur premier champ.
  List<String> get cartes {
    final List<String> vues = <String>[];
    for (final ChampQuestionnaire c in champs) {
      if (!vues.contains(c.carte)) {
        vues.add(c.carte);
      }
    }
    return vues;
  }
}

/// Le resultat d'un enregistrement de brouillon.
@immutable
class ResultatBrouillon {
  /// Cree le resultat.
  const ResultatBrouillon({
    required this.versionBrouillon,
    required this.complet,
    this.manquants = const <String>[],
  });

  /// La version du brouillon, a reporter dans le prochain enregistrement.
  final int versionBrouillon;

  /// Vrai quand il ne manque plus aucun champ requis.
  final bool complet;

  /// Les champs requis encore sans reponse.
  final List<String> manquants;
}

/// Un moyen de versement par operateur que Rewayah a confirme pour un pays
/// (`options_paiement_confirmees`). Le nom est celui de l'operateur : un nom
/// propre, rendu tel que le serveur le donne.
@immutable
class OperateurPaiement {
  /// Cree l'operateur.
  const OperateurPaiement({required this.code, required this.nom});

  /// Le code attendu dans les reponses.
  final String code;

  /// Le nom de l'operateur.
  final String nom;

  @override
  bool operator ==(Object other) =>
      other is OperateurPaiement && other.code == code && other.nom == nom;

  @override
  int get hashCode => Object.hash(code, nom);
}

/// Les moyens de versement que Rewayah a confirmes pour un pays : ce que le
/// serveur dit, pas ce que l'ecran en conclut (`options_paiement_confirmees`,
/// seules les lignes `confirme`, sans note interne).
@immutable
class MoyensConfirmes {
  /// Cree les moyens.
  const MoyensConfirmes({
    this.virementBancaire = false,
    this.operateurs = const <OperateurPaiement>[],
  });

  /// Vrai quand le virement bancaire est confirme dans ce pays.
  final bool virementBancaire;

  /// Les operateurs de monnaie mobile confirmes dans ce pays.
  final List<OperateurPaiement> operateurs;

  /// Vrai quand aucun moyen n'est confirme dans ce pays.
  bool get aucun => !virementBancaire && operateurs.isEmpty;

  @override
  bool operator ==(Object other) =>
      other is MoyensConfirmes &&
      other.virementBancaire == virementBancaire &&
      listEquals(other.operateurs, operateurs);

  @override
  int get hashCode => Object.hash(virementBancaire, Object.hashAll(operateurs));
}

DateTime? _instant(Object? v) =>
    v is String ? DateTime.tryParse(v)?.toLocal() : null;

DateTime? _jour(Object? v) {
  if (v is! String) {
    return null;
  }
  final DateTime? date = DateTime.tryParse(v);
  return date == null ? null : DateTime(date.year, date.month, date.day);
}

List<String> _codes(Object? v) => List<String>.unmodifiable(<String>[
  if (v is List)
    for (final Object? c in v)
      if (c is String) c,
]);

/// Le texte d'un modele de message, tel que le serveur le rend (lot L5), mot
/// pour mot. Jamais un motif interne : le serveur ne rend que le texte du
/// modele.
String? _texteModele(Object? v) {
  if (v is String && v.trim().isNotEmpty) {
    return v;
  }
  return null;
}
