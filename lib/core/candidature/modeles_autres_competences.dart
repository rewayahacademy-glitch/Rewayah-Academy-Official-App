// Les formes de donnees des autres competences d'un candidat (`CAND-07`,
// « Vos autres talents », `CAND-BR-19`,
// `docs/current/CANDIDATURES/CONTRAT_PORTS_CANDIDATURES.md`, sections 3 bis et
// 3 ter) : miroir Dart de ce que rendent `lire_autres_competences()`,
// `lire_catalogue_competences()` et, pour la direction, la cle
// `autresCompetences` de `lire_candidature()`.
//
// **Rien n'est calcule ici.** Les familles, les competences du catalogue, les
// niveaux, les disponibilites et la borne du texte viennent du serveur ; la
// reponse relue au serveur est la seule verite. Un code que cette version ne
// connait pas ne s'affiche jamais tel quel : l'ecran lui prend le libelle du
// catalogue, ou ne l'affiche pas (`libelles_talents.dart`).
//
// **Aucun montant.** « Chaque mission aura ses conditions » : rien ici ne porte
// une remuneration de mission.
library;

import 'package:flutter/foundation.dart';

/// Les six familles du catalogue : une liste fermee, parce qu'un nom de famille
/// se traduit dans l'application. Une septieme famille demande une migration
/// et un libelle ici.
enum FamilleCompetence {
  /// Communication et image.
  communication('communication'),

  /// Administration et organisation.
  administration('administration'),

  /// Finances et droit.
  financesDroit('finances_droit'),

  /// Pedagogie.
  pedagogie('pedagogie'),

  /// Technique.
  technique('technique'),

  /// Autre domaine : la famille du texte libre (et son seul code, `autre`).
  autre('autre');

  const FamilleCompetence(this.valeurSql);

  /// La valeur rendue par le serveur.
  final String valeurSql;

  /// La valeur lue, ou `null` pour une famille que cette version ne connait
  /// pas.
  static FamilleCompetence? depuisSql(Object? valeur) {
    for (final FamilleCompetence f in values) {
      if (f.valeurSql == valeur) {
        return f;
      }
    }
    return null;
  }
}

/// Le niveau declare pour une competence. Le niveau croit avec sa position :
/// `metier` contient `experience` pour un filtre par minimum.
enum NiveauCompetence {
  /// « Je debute ».
  debutant('debutant'),

  /// « J'ai de l'experience ».
  experience('experience'),

  /// « C'est mon metier ».
  metier('metier');

  const NiveauCompetence(this.valeurSql);

  /// La valeur rendue par le serveur.
  final String valeurSql;

  /// La valeur lue, ou `null`.
  static NiveauCompetence? depuisSql(Object? valeur) {
    for (final NiveauCompetence n in values) {
      if (n.valeurSql == valeur) {
        return n;
      }
    }
    return null;
  }
}

/// La disponibilite pour une mission. Elle ne se classe pas (« mi-temps » ne
/// contient pas « quelques heures ») : un filtre la compare par egalite.
enum DisponibiliteMission {
  /// Quelques heures par semaine.
  quelquesHeures('quelques_heures'),

  /// Un mi-temps.
  miTemps('mi_temps'),

  /// Plus qu'un mi-temps.
  plus('plus'),

  /// Pas pour l'instant.
  pasMaintenant('pas_maintenant');

  const DisponibiliteMission(this.valeurSql);

  /// La valeur rendue par le serveur.
  final String valeurSql;

  /// La valeur lue, ou `null`.
  static DisponibiliteMission? depuisSql(Object? valeur) {
    for (final DisponibiliteMission d in values) {
      if (d.valeurSql == valeur) {
        return d;
      }
    }
    return null;
  }
}

/// Pourquoi on ne peut pas enregistrer (lire et retirer restent permis).
enum RaisonFermeture {
  /// Aucun document de reponses envoye de la Salle d'examen.
  questionnaireNonEnvoye('questionnaire_non_envoye'),

  /// La candidature d'enseignant est refusee ou retiree.
  candidatureClose('candidature_close');

  const RaisonFermeture(this.valeurSql);

  /// La valeur rendue par le serveur.
  final String valeurSql;

  /// La valeur lue, ou `null`.
  static RaisonFermeture? depuisSql(Object? valeur) {
    for (final RaisonFermeture r in values) {
      if (r.valeurSql == valeur) {
        return r;
      }
    }
    return null;
  }
}

/// Une competence du catalogue, telle que l'ecran la lit.
@immutable
class EntreeCatalogue {
  /// Cree une entree.
  const EntreeCatalogue({
    required this.code,
    required this.familleCode,
    required this.ordre,
    required this.libelle,
    required this.actif,
    this.exemple,
    this.version,
  });

  /// Lit une entree, ou `null` sans code, sans famille ou sans libelle : on
  /// n'invente pas une competence.
  static EntreeCatalogue? depuisJson(Object? brut) {
    if (brut is! Map) {
      return null;
    }
    final Object? code = brut['code'];
    final Object? famille = brut['famille'];
    final Object? libelle = brut['libelle'];
    if (code is! String ||
        code.isEmpty ||
        famille is! String ||
        libelle is! String ||
        libelle.trim().isEmpty) {
      return null;
    }
    final Object? exemple = brut['exemple'];
    final Object? ordre = brut['ordre'];
    final Object? version = brut['version'];
    return EntreeCatalogue(
      code: code,
      familleCode: famille,
      ordre: ordre is int ? ordre : 999,
      libelle: libelle.trim(),
      exemple: exemple is String && exemple.trim().isNotEmpty
          ? exemple.trim()
          : null,
      actif: brut['actif'] != false,
      version: version is int ? version : null,
    );
  }

  /// Le code, stable pour toujours : une reponse ancienne le cite.
  final String code;

  /// La famille, telle que le serveur la rend (jamais affichee brute).
  final String familleCode;

  /// Le rang dans la famille.
  final int ordre;

  /// Le libelle de la direction, en francais.
  final String libelle;

  /// L'exemple de la direction, en francais.
  final String? exemple;

  /// Faux : n'est plus offerte, mais reste lisible dans une reponse ancienne.
  final bool actif;

  /// La version, pour la direction seule (ecriture par version attendue).
  final int? version;

  /// La famille connue de cette version, ou `null`.
  FamilleCompetence? get famille => FamilleCompetence.depuisSql(familleCode);

  /// Vrai pour la competence « Autre domaine », la seule qui porte un texte.
  bool get estAutre => code == codeAutre;

  /// Le code de la competence au texte libre.
  static const String codeAutre = 'autre';
}

/// Ce que l'ecran lit avec les reponses : le catalogue, les listes fermees et
/// la borne du texte libre.
@immutable
class ReferentielCompetences {
  /// Cree le referentiel.
  const ReferentielCompetences({
    required this.competences,
    this.familles = const <String>[],
    this.autreTexteMax = 200,
  });

  /// Lit le referentiel rendu par `lire_autres_competences()`.
  factory ReferentielCompetences.depuisJson(Object? brut) {
    if (brut is! Map || brut['competences'] is! List) {
      throw const FormatException('Referentiel des competences attendu.');
    }
    final Object? familles = brut['familles'];
    final Object? max = brut['autreTexteMax'];
    return ReferentielCompetences(
      familles: List<String>.unmodifiable(<String>[
        if (familles is List)
          for (final Object? f in familles)
            if (f is String) f,
      ]),
      competences: List<EntreeCatalogue>.unmodifiable(<EntreeCatalogue>[
        for (final Object? e in brut['competences'] as List)
          ?EntreeCatalogue.depuisJson(e),
      ]),
      autreTexteMax: max is int && max > 0 ? max : 200,
    );
  }

  /// Les familles dans l'ordre d'affichage.
  final List<String> familles;

  /// Les competences, dans l'ordre famille, rang, code : les actives et, avec
  /// `actif = false`, celles de la propre reponse de la personne.
  final List<EntreeCatalogue> competences;

  /// La longueur maximale du texte « Autre domaine ».
  final int autreTexteMax;

  /// Les competences d'une famille, dans l'ordre du serveur.
  List<EntreeCatalogue> deLaFamille(FamilleCompetence famille) =>
      List<EntreeCatalogue>.unmodifiable(<EntreeCatalogue>[
        for (final EntreeCatalogue e in competences)
          if (e.familleCode == famille.valeurSql) e,
      ]);

  /// L'entree d'un code, ou `null`.
  EntreeCatalogue? entree(String code) {
    for (final EntreeCatalogue e in competences) {
      if (e.code == code) {
        return e;
      }
    }
    return null;
  }
}

/// Les reponses enregistrees d'une personne.
@immutable
class ReponsesAutresCompetences {
  /// Cree les reponses.
  const ReponsesAutresCompetences({
    required this.domaines,
    required this.disponibilite,
    required this.accord,
    this.autreTexte,
    this.accordLe,
    this.majLe,
  });

  /// Lit les reponses, ou `null` quand le serveur n'en rend pas (aucune
  /// reponse enregistree).
  static ReponsesAutresCompetences? depuisJson(Object? brut) {
    if (brut is! Map || brut['domaines'] is! Map) {
      return null;
    }
    final DisponibiliteMission? dispo = DisponibiliteMission.depuisSql(
      brut['disponibilite'],
    );
    if (dispo == null) {
      return null;
    }
    final Map<String, NiveauCompetence> domaines =
        <String, NiveauCompetence>{};
    for (final MapEntry<Object?, Object?> e
        in (brut['domaines'] as Map<Object?, Object?>).entries) {
      final NiveauCompetence? niveau = NiveauCompetence.depuisSql(e.value);
      if (e.key is String && niveau != null) {
        domaines[e.key! as String] = niveau;
      }
    }
    final Object? texte = brut['autreTexte'];
    final Object? accordLe = brut['accordLe'];
    final Object? majLe = brut['majLe'];
    return ReponsesAutresCompetences(
      domaines: Map<String, NiveauCompetence>.unmodifiable(domaines),
      autreTexte: texte is String && texte.trim().isNotEmpty ? texte : null,
      disponibilite: dispo,
      accord: brut['accord'] == true,
      accordLe: accordLe is String ? DateTime.tryParse(accordLe) : null,
      majLe: majLe is String ? DateTime.tryParse(majLe) : null,
    );
  }

  /// Code du catalogue vers niveau.
  final Map<String, NiveauCompetence> domaines;

  /// Le texte court de « Autre domaine », present si et seulement si le
  /// domaine `autre` l'est.
  final String? autreTexte;

  /// La disponibilite pour une mission.
  final DisponibiliteMission disponibilite;

  /// L'accord d'etre contacte pour une mission.
  final bool accord;

  /// L'instant de l'ecriture qui a pose l'accord (UTC), nul sans accord.
  final DateTime? accordLe;

  /// La derniere mise a jour (UTC).
  final DateTime? majLe;
}

/// La lecture du candidat : si c'est ouvert, ses reponses, le referentiel.
@immutable
class AutresCompetences {
  /// Cree la lecture.
  const AutresCompetences({
    required this.ouvert,
    required this.version,
    required this.referentiel,
    this.raison,
    this.reponses,
  });

  /// Lit la reponse de `lire_autres_competences()`. Une reponse sans le
  /// booleen `ouvert` ou sans referentiel n'est pas une lecture :
  /// [FormatException], jamais une lecture inventee.
  factory AutresCompetences.depuisJson(Object? brut) {
    if (brut is! Map || brut['ouvert'] is! bool) {
      throw const FormatException('Autres competences attendues.');
    }
    final Object? version = brut['version'];
    return AutresCompetences(
      ouvert: brut['ouvert'] as bool,
      raison: RaisonFermeture.depuisSql(brut['raison']),
      version: version is int && version >= 0 ? version : 0,
      reponses: ReponsesAutresCompetences.depuisJson(brut['reponses']),
      referentiel: ReferentielCompetences.depuisJson(brut['referentiel']),
    );
  }

  /// Vrai : la personne peut enregistrer. Faux : elle ne peut que lire et
  /// retirer ([raison] dit pourquoi).
  final bool ouvert;

  /// Pourquoi ce n'est pas ouvert.
  final RaisonFermeture? raison;

  /// La version des reponses : 0 tant que rien n'est enregistre. C'est la
  /// `versionAttendue` de l'ecriture suivante.
  final int version;

  /// Les reponses enregistrees, ou `null`.
  final ReponsesAutresCompetences? reponses;

  /// Le catalogue et les listes fermees.
  final ReferentielCompetences referentiel;

  /// Vrai quand des reponses sont enregistrees.
  bool get aDesReponses => reponses != null;
}

/// Le resultat d'un enregistrement : jamais une reponse (l'ecran relit).
@immutable
class ResultatEnregistrement {
  /// Cree le resultat.
  const ResultatEnregistrement({
    required this.version,
    required this.inchange,
    required this.rejoue,
  });

  /// Lit le resultat de `enregistrer_autres_competences()`.
  factory ResultatEnregistrement.depuisJson(Object? brut) {
    if (brut is! Map || brut['version'] is! int) {
      throw const FormatException('Resultat d\'enregistrement attendu.');
    }
    return ResultatEnregistrement(
      version: brut['version'] as int,
      inchange: brut['inchange'] == true,
      rejoue: brut['rejoue'] == true,
    );
  }

  /// La version apres l'ecriture.
  final int version;

  /// Vrai : l'ecriture etait identique a l'etat courant, rien n'a change.
  final bool inchange;

  /// Vrai : la meme cle a rejoue un enregistrement deja fait.
  final bool rejoue;
}

/// Le resultat d'un retrait.
@immutable
class ResultatRetrait {
  /// Cree le resultat.
  const ResultatRetrait({
    required this.retire,
    required this.version,
    required this.rejoue,
  });

  /// Lit le resultat de `retirer_autres_competences()`.
  factory ResultatRetrait.depuisJson(Object? brut) {
    if (brut is! Map || brut['retire'] is! bool) {
      throw const FormatException('Resultat de retrait attendu.');
    }
    final Object? version = brut['version'];
    return ResultatRetrait(
      retire: brut['retire'] as bool,
      version: version is int ? version : 0,
      rejoue: brut['rejoue'] == true,
    );
  }

  /// Faux : rien n'etait enregistre.
  final bool retire;

  /// La version apres le retrait (0).
  final int version;

  /// Vrai : la meme cle a rejoue un retrait deja fait.
  final bool rejoue;
}

/// Le catalogue tel que `lire_catalogue_competences()` le rend.
@immutable
class CatalogueCompetences {
  /// Cree le catalogue.
  const CatalogueCompetences({
    required this.competences,
    this.familles = const <String>[],
    this.peutModifier = false,
  });

  /// Lit la reponse de `lire_catalogue_competences()`.
  factory CatalogueCompetences.depuisJson(Object? brut) {
    if (brut is! Map || brut['competences'] is! List) {
      throw const FormatException('Catalogue des competences attendu.');
    }
    final Object? familles = brut['familles'];
    return CatalogueCompetences(
      familles: List<String>.unmodifiable(<String>[
        if (familles is List)
          for (final Object? f in familles)
            if (f is String) f,
      ]),
      competences: List<EntreeCatalogue>.unmodifiable(<EntreeCatalogue>[
        for (final Object? e in brut['competences'] as List)
          ?EntreeCatalogue.depuisJson(e),
      ]),
      peutModifier: brut['peutModifier'] == true,
    );
  }

  /// Les familles dans l'ordre d'affichage.
  final List<String> familles;

  /// Les competences, dans l'ordre famille, rang, code.
  final List<EntreeCatalogue> competences;

  /// La capacite de modifier le catalogue (la direction active seule).
  final bool peutModifier;

  /// L'entree d'un code, ou `null`.
  EntreeCatalogue? entree(String code) {
    for (final EntreeCatalogue e in competences) {
      if (e.code == code) {
        return e;
      }
    }
    return null;
  }
}
