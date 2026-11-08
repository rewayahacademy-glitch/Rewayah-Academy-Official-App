// Les formes de donnees du traitement groupe des candidatures (LISTES-1, lot 2,
// ex `ADM-22`) : l'apercu, la demande, le rapport, et les refus propres au lot.
//
// Miroir Dart des deux RPC que CAND-L2A2 a livrees
// (`apercu_lot_candidats`, `executer_lot_candidats`,
// `20261022000100_cand_l2a2_gestes_direction.sql`, section 4). **Rien n'est
// calcule ici** : les eligibles, les exclus et leur raison, le jeton, le
// nombre, le rapport ligne par ligne viennent du serveur. Le jeton est un
// HMAC que le client ne peut ni fabriquer ni verifier.
//
// Le serveur ne sait grouper que trois gestes (mettre en pause, lever la
// pause, refuser) et plafonne a 200 candidatures : un autre geste est refuse
// (`geste_non_groupable`), et ce fichier n'en offre pas la valeur.
library;

import 'package:flutter/foundation.dart';

import 'gestes_candidature.dart';
import 'modeles_candidature.dart';

/// Le plafond de candidatures d'un lot, fixe par le serveur.
const int plafondLotCandidatures = 200;

/// Les trois gestes que le serveur sait faire en lot.
enum GesteLot {
  /// Mettre en pause.
  mettreEnPause('mettreEnPause', GesteCandidature.mettreEnPause),

  /// Lever la pause.
  leverPause('leverPause', GesteCandidature.leverPause),

  /// Refuser la candidature.
  refuser('refuser', GesteCandidature.refuser);

  const GesteLot(this.valeurSql, this.geste);

  /// La valeur envoyee au serveur (`p_geste`).
  final String valeurSql;

  /// Le geste individuel du meme nom : ses mots, ses modeles, sa capacite.
  final GesteCandidature geste;

  /// Le geste de lot d'un geste individuel, ou `null` : il ne se groupe pas.
  static GesteLot? depuisGeste(GesteCandidature g) {
    for (final GesteLot l in values) {
      if (l.geste == g) {
        return l;
      }
    }
    return null;
  }

  /// La valeur lue (`mettre_en_pause` ou `mettreEnPause`), ou `null`.
  static GesteLot? depuisSql(Object? valeur) {
    for (final GesteLot l in values) {
      if (l.valeurSql == valeur) {
        return l;
      }
    }
    return switch (valeur) {
      'mettre_en_pause' => mettreEnPause,
      'lever_pause' => leverPause,
      _ => null,
    };
  }
}

/// Une candidature que le lot fera, avec la version que le serveur a lue.
@immutable
class EligibleLot {
  /// Cree l'eligible.
  const EligibleLot({
    required this.id,
    required this.reference,
    required this.nomComplet,
    this.etape,
    this.etat,
    this.issue = IssueCandidature.enCours,
    this.enPause = false,
    this.version,
  });

  /// Lit un eligible, ou `null` sans identifiant lisible.
  static EligibleLot? depuisJson(Object? brut) {
    if (brut is! Map) {
      return null;
    }
    final Object? id = brut['id'];
    if (id is! String || id.isEmpty) {
      return null;
    }
    return EligibleLot(
      id: id,
      reference: brut['reference'] is String ? brut['reference'] as String : '',
      nomComplet: brut['nomComplet'] is String
          ? brut['nomComplet'] as String
          : '',
      etape: EtapeCandidature.depuisSql(brut['etape']),
      etat: EtatCandidature.depuisSql(brut['etat']),
      issue: IssueCandidature.depuisSql(brut['issue']),
      enPause: brut['enPause'] == true,
      version: brut['version'] is int ? brut['version'] as int : null,
    );
  }

  /// L'identifiant de la candidature.
  final String id;

  /// La reference `CAND-...`.
  final String reference;

  /// Le nom.
  final String nomComplet;

  /// L'etape.
  final EtapeCandidature? etape;

  /// L'etat dans l'etape.
  final EtatCandidature? etat;

  /// L'issue.
  final IssueCandidature issue;

  /// En pause.
  final bool enPause;

  /// La version lue par le serveur (le jeton la couvre).
  final int? version;
}

/// Pourquoi le serveur exclut une candidature du lot.
enum RaisonExclusion {
  /// Elle n'existe plus.
  absente,

  /// Elle est de l'autre cote : le serveur ne rend aucune donnee.
  horsPortee,

  /// Son etat ne permet pas ce geste.
  transitionInterdite,

  /// Une raison que cette version ne connait pas.
  inconnue;

  /// La raison lue.
  static RaisonExclusion depuisSql(Object? valeur) => switch (valeur) {
    'absente' => absente,
    'hors_portee' => horsPortee,
    'transition_interdite' => transitionInterdite,
    _ => inconnue,
  };
}

/// Une candidature que le lot ne fera pas, et pourquoi.
@immutable
class ExclusLot {
  /// Cree l'exclu.
  const ExclusLot({
    required this.id,
    required this.raison,
    this.reference = '',
    this.nomComplet = '',
    this.etape,
    this.etat,
    this.issue = IssueCandidature.enCours,
    this.enPause = false,
    this.parLaPause = false,
  });

  /// Lit un exclu, ou `null` sans identifiant lisible.
  static ExclusLot? depuisJson(Object? brut) {
    if (brut is! Map) {
      return null;
    }
    final Object? id = brut['id'];
    if (id is! String || id.isEmpty) {
      return null;
    }
    return ExclusLot(
      id: id,
      raison: RaisonExclusion.depuisSql(brut['raison']),
      reference: brut['reference'] is String ? brut['reference'] as String : '',
      nomComplet: brut['nomComplet'] is String
          ? brut['nomComplet'] as String
          : '',
      etape: EtapeCandidature.depuisSql(brut['etape']),
      etat: EtatCandidature.depuisSql(brut['etat']),
      issue: IssueCandidature.depuisSql(brut['issue']),
      enPause: brut['enPause'] == true,
      parLaPause: brut['detail'] == 'pause',
    );
  }

  /// L'identifiant.
  final String id;

  /// La raison de l'exclusion.
  final RaisonExclusion raison;

  /// La reference, vide quand le serveur ne la rend pas (absente, hors portee).
  final String reference;

  /// Le nom, vide quand le serveur ne le rend pas.
  final String nomComplet;

  /// L'etape courante.
  final EtapeCandidature? etape;

  /// L'etat courant.
  final EtatCandidature? etat;

  /// L'issue courante.
  final IssueCandidature issue;

  /// En pause.
  final bool enPause;

  /// C'est la pause seule qui interdit le geste (`detail: pause`).
  final bool parLaPause;
}

/// Ce que le serveur dit du lot avant de l'executer : rien n'est ecrit.
@immutable
class ApercuLot {
  /// Cree l'apercu.
  const ApercuLot({
    required this.geste,
    required this.eligibles,
    required this.exclus,
    required this.nombre,
    required this.jeton,
    this.motifRequis = false,
    this.modeleRequis = false,
  });

  /// Lit la reponse de `apercu_lot_candidats`. Une reponse sans jeton ni
  /// nombre n'est pas un apercu : [FormatException].
  factory ApercuLot.depuisJson(Object? brut) {
    if (brut is! Map) {
      throw const FormatException('Apercu de lot attendu.');
    }
    final GesteLot? geste = GesteLot.depuisSql(brut['geste']);
    final Object? jeton = brut['jeton'];
    final Object? nombre = brut['nombre'];
    if (geste == null || jeton is! String || nombre is! int) {
      throw const FormatException('Geste, jeton ou nombre absents.');
    }
    return ApercuLot(
      geste: geste,
      motifRequis: brut['motifRequis'] == true,
      modeleRequis: brut['modeleRequis'] == true,
      eligibles: List<EligibleLot>.unmodifiable(<EligibleLot>[
        if (brut['eligibles'] is List)
          for (final Object? e in brut['eligibles'] as List)
            if (EligibleLot.depuisJson(e) case final EligibleLot x) x,
      ]),
      exclus: List<ExclusLot>.unmodifiable(<ExclusLot>[
        if (brut['exclus'] is List)
          for (final Object? e in brut['exclus'] as List)
            if (ExclusLot.depuisJson(e) case final ExclusLot x) x,
      ]),
      nombre: nombre,
      jeton: jeton,
    );
  }

  /// Le geste.
  final GesteLot geste;

  /// Le geste exige un motif interne, une fois pour tout le lot.
  final bool motifRequis;

  /// Le geste exige un modele de message, une fois pour tout le lot.
  final bool modeleRequis;

  /// Les candidatures que le lot fera.
  final List<EligibleLot> eligibles;

  /// Les candidatures que le lot ne fera pas.
  final List<ExclusLot> exclus;

  /// Le nombre de candidatures que le lot fera : **celui que la direction
  /// saisit pour confirmer**.
  final int nombre;

  /// Le jeton de l'apercu : il lie le lot tel qu'il etait a ce moment.
  final String jeton;
}

/// Ce que la direction demande au serveur d'executer.
@immutable
class DemandeLot {
  /// Cree la demande.
  const DemandeLot({
    required this.geste,
    required this.ids,
    required this.jeton,
    required this.nombreConfirme,
    required this.cleIdempotence,
    this.motif,
    this.modele,
    this.repriseLe,
  });

  /// Le geste.
  final GesteLot geste;

  /// Les identifiants du lot, ceux de l'apercu (1 a 200).
  final List<String> ids;

  /// Le jeton de l'apercu.
  final String jeton;

  /// Le nombre saisi par la direction.
  final int nombreConfirme;

  /// La cle d'idempotence du lot : rejouee telle quelle apres un « non
  /// confirme », jamais pour d'autres identifiants.
  final String cleIdempotence;

  /// Le motif interne commun.
  final String? motif;

  /// Le modele de message commun.
  final String? modele;

  /// La reprise commune d'une pause, en jour.
  final DateTime? repriseLe;
}

/// Ce qui est arrive a une candidature du lot.
enum IssueLigneLot {
  /// Le geste est fait.
  reussie,

  /// Exclue par le serveur : rien n'a ete tente.
  exclue,

  /// Le serveur a refuse le geste pour cette candidature.
  refusee;

  /// L'issue lue, ou `null`.
  static IssueLigneLot? depuisSql(Object? valeur) => switch (valeur) {
    'reussie' => reussie,
    'exclue' => exclue,
    'refusee' => refusee,
    _ => null,
  };
}

/// Une ligne du rapport.
@immutable
class LigneRapportLot {
  /// Cree la ligne.
  const LigneRapportLot({
    required this.id,
    required this.issue,
    this.reference = '',
    this.raison,
    this.parLaPause = false,
  });

  static LigneRapportLot? _depuisJson(Object? l) {
    if (l is! Map || l['id'] is! String) {
      return null;
    }
    final IssueLigneLot? issue = IssueLigneLot.depuisSql(l['issue']);
    if (issue == null) {
      return null;
    }
    return LigneRapportLot(
      id: l['id'] as String,
      reference: l['reference'] is String ? l['reference'] as String : '',
      issue: issue,
      raison: l['raison'] is String ? l['raison'] as String : null,
      parLaPause: l['detail'] == 'pause',
    );
  }

  /// L'identifiant.
  final String id;

  /// La reference, vide quand le serveur ne la rend pas.
  final String reference;

  /// Ce qui est arrive.
  final IssueLigneLot issue;

  /// Le code de la raison d'une exclusion ou d'un refus (`transition_interdite`,
  /// `conflit_candidature`, `erreur_serveur`...), que l'ecran dit en mots.
  final String? raison;

  /// Une exclusion due a la pause seule.
  final bool parLaPause;
}

/// Le rapport ligne par ligne d'un lot execute.
@immutable
class RapportLot {
  /// Cree le rapport.
  const RapportLot({
    required this.geste,
    required this.nombre,
    required this.reussies,
    required this.exclues,
    required this.refusees,
    required this.lignes,
    this.rejoue = false,
  });

  /// Lit la reponse de `executer_lot_candidats`. Un rapport sans compte n'est
  /// pas un rapport : [FormatException], jamais un succes suppose.
  factory RapportLot.depuisJson(Object? brut) {
    if (brut is! Map) {
      throw const FormatException('Rapport de lot attendu.');
    }
    final GesteLot? geste = GesteLot.depuisSql(brut['geste']);
    final Object? reussies = brut['reussies'];
    final Object? exclues = brut['exclues'];
    final Object? refusees = brut['refusees'];
    if (geste == null ||
        reussies is! int ||
        exclues is! int ||
        refusees is! int) {
      throw const FormatException('Comptes du rapport absents.');
    }
    return RapportLot(
      geste: geste,
      nombre: brut['nombre'] is int ? brut['nombre'] as int : reussies,
      reussies: reussies,
      exclues: exclues,
      refusees: refusees,
      rejoue: brut['rejoue'] == true,
      lignes: List<LigneRapportLot>.unmodifiable(<LigneRapportLot>[
        if (brut['lignes'] is List)
          for (final Object? l in brut['lignes'] as List)
            if (LigneRapportLot._depuisJson(l) case final LigneRapportLot x) x,
      ]),
    );
  }

  /// Le geste.
  final GesteLot geste;

  /// Le nombre de candidatures que le lot visait.
  final int nombre;

  /// Les candidatures dont le geste est fait.
  final int reussies;

  /// Les candidatures exclues.
  final int exclues;

  /// Les candidatures dont le serveur a refuse le geste.
  final int refusees;

  /// Une ligne par candidature.
  final List<LigneRapportLot> lignes;

  /// Vrai quand le serveur a rejoue un lot deja execute : rien n'a ete ecrit
  /// une seconde fois.
  final bool rejoue;
}

/// Un refus que le serveur rend pour un lot, sans rien ecrire. Les refus qui
/// sont ceux d'un geste (motif, modele, reprise) sont les [RefusGeste]
/// existants.
sealed class RefusLot implements Exception {
  const RefusLot();
}

/// Le lot a change depuis l'apercu : il faut un nouvel apercu.
final class JetonPerime extends RefusLot {
  /// Cree le refus.
  const JetonPerime();
}

/// Aucune candidature du lot n'est eligible.
final class AucunEligible extends RefusLot {
  /// Cree le refus.
  const AucunEligible();
}

/// Le nombre saisi n'est pas celui du lot : [nombre] est le vrai.
final class NombreDiscordant extends RefusLot {
  /// Cree le refus.
  const NombreDiscordant(this.nombre);

  /// Le nombre que le serveur a compte.
  final int? nombre;
}

/// Le geste ne se fait pas en lot.
final class GesteNonGroupable extends RefusLot {
  /// Cree le refus.
  const GesteNonGroupable();
}

/// La cle du lot a deja servi a un autre lot.
final class CleLotReutilisee extends RefusLot {
  /// Cree le refus.
  const CleLotReutilisee();
}
