// Les formes de donnees du detail d'une candidature pour la direction
// (`ADM-21`, `PortCandidaturesDirection`,
// `docs/current/CANDIDATURES/CONTRAT_PORTS_CANDIDATURES.md`, section 1).
//
// Miroir Dart de ce que le serveur rend, jamais un calcul : `lire_candidature`
// (CAND-L1, redefinie par CAND-L2A2, D21), `lire_contact_candidature`,
// `historique_candidature` et le resultat des gestes de CAND-L2A2. L'ecran lit
// ces champs ; il ne recalcule ni l'etape, ni l'etat, ni un controle.
//
// **Ce que le serveur ne rend pas encore reste nul, et l'ecran le dit** : les
// controles nommes (`controles`), l'etat de la piece (`piece`) et l'entretien
// valent `null` aujourd'hui (lots L2B et L4). Un `null` n'est jamais un zero ni
// une liste vide : c'est « Disponible au branchement serveur ».
//
// **Aucun nom de personne dans l'historique** : le serveur rend l'auteur par sa
// categorie (systeme, candidat, direction), sans nom ni identifiant
// (`CAND-BR-07`, L1-6).
library;

import 'package:flutter/foundation.dart';

import 'modeles_candidature.dart';
import 'modeles_candidatures_direction.dart';

/// D'ou vient la candidature (colonne `source`).
enum ProvenanceCandidature {
  /// Les formulaires importes.
  importee('import'),

  /// Le lien public du site.
  lienPublic('lien_public'),

  /// Une invitation.
  invitation('invitation');

  const ProvenanceCandidature(this.valeurSql);

  /// La valeur ecrite en base.
  final String valeurSql;

  /// La valeur lue, ou `null` pour une valeur que cette version ne connait pas.
  static ProvenanceCandidature? depuisSql(Object? valeur) {
    for (final ProvenanceCandidature p in values) {
      if (p.valeurSql == valeur) {
        return p;
      }
    }
    return null;
  }
}

/// Un document de reponses a une version du questionnaire : celui que la
/// personne a envoye, ou celui d'un formulaire importe.
@immutable
class DocumentReponses {
  /// Cree un document.
  const DocumentReponses({
    required this.questionnaireVersion,
    required this.reponses,
    required this.importe,
    this.soumisLe,
  });

  /// Lit un document, ou `null` quand il n'a pas de reponses lisibles.
  static DocumentReponses? depuisJson(Object? brut) {
    if (brut is! Map || brut['reponses'] is! Map) {
      return null;
    }
    final Object? soumis = brut['soumisLe'];
    return DocumentReponses(
      questionnaireVersion: brut['questionnaireVersion'] is String
          ? brut['questionnaireVersion'] as String
          : '',
      reponses: Map<String, Object?>.unmodifiable(
        Map<String, Object?>.from(brut['reponses'] as Map),
      ),
      importe: brut['source'] == 'import',
      soumisLe: soumis is String ? DateTime.tryParse(soumis) : null,
    );
  }

  /// La version du questionnaire a laquelle ces reponses repondent.
  final String questionnaireVersion;

  /// Les reponses, par code de champ.
  final Map<String, Object?> reponses;

  /// Vrai pour les reponses d'un ancien formulaire importe : elles sont
  /// marquees comme telles (« Venu de l'ancien formulaire »).
  final bool importe;

  /// Le moment de l'envoi, en UTC.
  final DateTime? soumisLe;
}

/// Un controle nomme, vrai ou faux, avec sa cause quand il est faux.
@immutable
class ControleCandidature {
  /// Cree un controle.
  const ControleCandidature({
    required this.nom,
    required this.valeur,
    this.cause,
  });

  /// Lit un controle, ou `null` sans nom.
  static ControleCandidature? depuisJson(Object? brut) {
    if (brut is! Map || brut['nom'] is! String) {
      return null;
    }
    final Object? cause = brut['cause'];
    return ControleCandidature(
      nom: brut['nom'] as String,
      valeur: brut['valeur'] == true,
      cause: cause is String && cause.isNotEmpty ? cause : null,
    );
  }

  /// Le nom du controle (un code du serveur, jamais affiche tel quel).
  final String nom;

  /// Vrai quand le controle est satisfait.
  final bool valeur;

  /// La cause quand il ne l'est pas (un code du serveur).
  final String? cause;
}

/// L'etat de la piece d'identite : son etat seulement, jamais la piece.
enum EtatPiece {
  /// A deposer.
  aDeposer('a_deposer'),

  /// Deposee.
  deposee('deposee'),

  /// A corriger.
  aCorriger('a_corriger'),

  /// Validee.
  validee('validee');

  const EtatPiece(this.valeurSql);

  /// La valeur rendue par le serveur.
  final String valeurSql;

  /// La valeur lue, ou `null`.
  static EtatPiece? depuisSql(Object? valeur) {
    final Object? v = valeur is Map ? valeur['etat'] : valeur;
    for (final EtatPiece e in values) {
      if (e.valeurSql == v) {
        return e;
      }
    }
    return null;
  }
}

/// Le dossier d'une candidature, tel que `lire_candidature` le rend.
@immutable
class DetailCandidature {
  /// Cree le detail.
  const DetailCandidature({
    required this.ligne,
    required this.version,
    required this.documents,
    this.provenance,
    this.pauseModele,
    this.refusModele,
    this.restrictionCause,
    this.controles,
    this.piece,
    this.autreCote = false,
  });

  /// Lit la reponse de `lire_candidature`. Une reponse sans ligne lisible n'est
  /// pas un dossier : [FormatException], jamais un dossier invente.
  factory DetailCandidature.depuisJson(Object? brut) {
    final LigneCandidature? ligne = LigneCandidature.depuisJson(brut);
    if (ligne == null || brut is! Map) {
      throw const FormatException('Candidature attendue.');
    }
    final Object? version = brut['version'];
    if (version is! int || version < 1) {
      throw const FormatException('Version de candidature absente.');
    }
    String? texte(String cle) {
      final Object? v = brut[cle];
      return v is String && v.trim().isNotEmpty ? v : null;
    }

    final Object? reponses = brut['reponses'];
    final Object? controles = brut['controles'];
    return DetailCandidature(
      ligne: ligne,
      version: version,
      provenance: ProvenanceCandidature.depuisSql(brut['source']),
      pauseModele: texte('pauseModele'),
      refusModele: texte('refusModele'),
      restrictionCause: texte('restrictionCause'),
      documents: List<DocumentReponses>.unmodifiable(<DocumentReponses>[
        if (reponses is List)
          for (final Object? d in reponses) ?DocumentReponses.depuisJson(d),
      ]),
      controles: controles is List
          ? List<ControleCandidature>.unmodifiable(<ControleCandidature>[
              for (final Object? c in controles)
                ?ControleCandidature.depuisJson(c),
            ])
          : null,
      piece: EtatPiece.depuisSql(brut['piece']),
      autreCote: brut['autreCote'] == true,
    );
  }

  /// La ligne : reference, nom, etape, etat, issue, pause, restriction...
  final LigneCandidature ligne;

  /// La version de la candidature : le `versionAttendue` de chaque geste.
  final int version;

  /// D'ou elle vient, ou `null` pour une valeur inconnue de cette version.
  final ProvenanceCandidature? provenance;

  /// Le code du modele de message de la pause posee, ou `null`.
  final String? pauseModele;

  /// Le code du modele de message du refus, ou `null`.
  final String? refusModele;

  /// La cause de la restriction (`paiement`, `piece`, `manuelle`...), ou `null`.
  final String? restrictionCause;

  /// Les documents de reponses, du plus recent au plus ancien.
  final List<DocumentReponses> documents;

  /// Les controles nommes, ou `null` : le serveur ne les sert pas encore.
  final List<ControleCandidature>? controles;

  /// L'etat de la piece, ou `null` : le serveur ne le sert pas encore.
  final EtatPiece? piece;

  /// Vrai quand la candidature est de l'autre cote (femmes ou hommes) que le
  /// lecteur, lue par l'exception du super-admin. **Le serveur ne rend pas
  /// cette information aujourd'hui** (`lire_candidature` ne dit pas le cote) :
  /// elle vaut faux, et la phrase d'exception d'`ADM-21` ne se montre pas tant
  /// qu'il ne la rend pas.
  final bool autreCote;

  /// Les controles faux, nommes, avec leur cause.
  List<ControleCandidature> get blocages => <ControleCandidature>[
    for (final ControleCandidature c in controles ?? <ControleCandidature>[])
      if (!c.valeur) c,
  ];

  /// Le document de reponses le plus recent, ou `null`.
  DocumentReponses? get dernieresReponses =>
      documents.isEmpty ? null : documents.first;
}

/// Le contact d'une candidature, lu pour la direction nommee, chaque lecture
/// etant inscrite au journal. Valeurs validees et valeurs brutes a part.
@immutable
class ContactCandidat {
  /// Cree le contact.
  const ContactCandidat({
    this.courriel,
    this.telephone,
    this.courrielBrut,
    this.telephoneBrut,
  });

  /// Lit le contact rendu par `lire_contact_candidature`.
  factory ContactCandidat.depuisJson(Object? brut) {
    if (brut is! Map) {
      throw const FormatException('Contact attendu.');
    }
    String? texte(String cle) {
      final Object? v = brut[cle];
      return v is String && v.trim().isNotEmpty ? v.trim() : null;
    }

    return ContactCandidat(
      courriel: texte('courriel'),
      telephone: texte('telephone'),
      courrielBrut: texte('courrielBrut'),
      telephoneBrut: texte('telephoneBrut'),
    );
  }

  /// Le courriel valide.
  final String? courriel;

  /// Le telephone au format international.
  final String? telephone;

  /// Un courriel mal forme, garde tel quel.
  final String? courrielBrut;

  /// Un telephone sans indicatif connu, garde tel quel.
  final String? telephoneBrut;

  /// Le courriel a montrer : le valide, sinon le brut.
  String? get courrielAffiche => courriel ?? courrielBrut;

  /// Le telephone a montrer : le valide, sinon le brut.
  String? get telephoneAffiche => telephone ?? telephoneBrut;

  /// Aucune coordonnee n'est connue.
  bool get vide => courrielAffiche == null && telephoneAffiche == null;
}

/// Qui a fait un evenement : une categorie, jamais un nom.
enum AuteurEvenement {
  /// Le systeme (aucun auteur).
  systeme('systeme'),

  /// La personne dont c'est la candidature.
  candidat('candidat'),

  /// Un membre de la direction.
  direction('direction');

  const AuteurEvenement(this.valeurSql);

  /// La valeur rendue par le serveur.
  final String valeurSql;

  /// La valeur lue, `systeme` pour une valeur inconnue (la plus neutre).
  static AuteurEvenement depuisSql(Object? valeur) {
    for (final AuteurEvenement a in values) {
      if (a.valeurSql == valeur) {
        return a;
      }
    }
    return AuteurEvenement.systeme;
  }
}

/// Un evenement de l'historique : une ligne, du plus recent au plus ancien.
@immutable
class EvenementCandidature {
  /// Cree l'evenement.
  const EvenementCandidature({
    required this.id,
    required this.type,
    required this.auteur,
    this.quand,
    this.etapeAvant,
    this.etapeApres,
    this.etatAvant,
    this.etatApres,
    this.issueAvant,
    this.issueApres,
    this.motif,
  });

  /// Lit un evenement, ou `null` sans identifiant ni type.
  static EvenementCandidature? depuisJson(Object? brut) {
    if (brut is! Map || brut['id'] is! int || brut['type'] is! String) {
      return null;
    }
    String? texte(String cle) {
      final Object? v = brut[cle];
      return v is String && v.trim().isNotEmpty ? v : null;
    }

    return EvenementCandidature(
      id: brut['id'] as int,
      type: brut['type'] as String,
      auteur: AuteurEvenement.depuisSql(brut['auteur']),
      quand: DateTime.tryParse(texte('quand') ?? ''),
      etapeAvant: EtapeCandidature.depuisSql(brut['etapeAvant']),
      etapeApres: EtapeCandidature.depuisSql(brut['etapeApres']),
      etatAvant: EtatCandidature.depuisSql(brut['etatAvant']),
      etatApres: EtatCandidature.depuisSql(brut['etatApres']),
      issueAvant: brut['issueAvant'] == null
          ? null
          : IssueCandidature.depuisSql(brut['issueAvant']),
      issueApres: brut['issueApres'] == null
          ? null
          : IssueCandidature.depuisSql(brut['issueApres']),
      motif: texte('motif'),
    );
  }

  /// L'identifiant de l'evenement : le curseur de la page suivante.
  final int id;

  /// Le type (`transition`, `pause`, `reprise`, `restriction`...).
  final String type;

  /// Qui l'a fait, en categorie.
  final AuteurEvenement auteur;

  /// Quand, en UTC.
  final DateTime? quand;

  /// L'etape avant.
  final EtapeCandidature? etapeAvant;

  /// L'etape apres.
  final EtapeCandidature? etapeApres;

  /// L'etat avant.
  final EtatCandidature? etatAvant;

  /// L'etat apres.
  final EtatCandidature? etatApres;

  /// L'issue avant.
  final IssueCandidature? issueAvant;

  /// L'issue apres.
  final IssueCandidature? issueApres;

  /// Le motif interne, lu par la direction seule.
  final String? motif;
}

/// Une page de l'historique, du plus recent au plus ancien.
@immutable
class PageHistorique {
  /// Cree la page.
  const PageHistorique({required this.evenements, this.curseurSuivant});

  /// Lit la reponse de `historique_candidature`.
  factory PageHistorique.depuisJson(Object? brut) {
    if (brut is! Map || brut['evenements'] is! List) {
      throw const FormatException('Historique attendu.');
    }
    final Object? suivant = brut['curseurSuivant'];
    return PageHistorique(
      evenements: List<EvenementCandidature>.unmodifiable(
        <EvenementCandidature>[
          for (final Object? e in brut['evenements'] as List)
            ?EvenementCandidature.depuisJson(e),
        ],
      ),
      curseurSuivant: suivant is int ? suivant : null,
    );
  }

  /// Les evenements de la page.
  final List<EvenementCandidature> evenements;

  /// Le curseur de la page suivante, ou `null` a la fin.
  final int? curseurSuivant;
}

/// Un membre de la direction que la candidature peut avoir pour responsable.
@immutable
class ResponsablePossible {
  /// Cree le responsable.
  const ResponsablePossible({required this.id, required this.nom});

  /// L'identifiant du profil.
  final String id;

  /// Son nom.
  final String nom;
}

/// L'etat d'une candidature relu au serveur apres un geste (`D3`) : jamais une
/// reponse, un motif, un nom ni un contact. Le dossier complet se relit par
/// `lire_candidature`.
@immutable
class EtatApresGeste {
  /// Cree l'etat.
  const EtatApresGeste({
    required this.version,
    required this.issue,
    required this.enPause,
    this.etape,
    this.etat,
    this.paiement,
  });

  /// Lit le bloc `candidature` d'un resultat de geste.
  factory EtatApresGeste.depuisJson(Object? brut) {
    if (brut is! Map || brut['version'] is! int) {
      throw const FormatException('Candidature relue absente.');
    }
    return EtatApresGeste(
      version: brut['version'] as int,
      etape: EtapeCandidature.depuisSql(brut['etape']),
      etat: EtatCandidature.depuisSql(brut['etat']),
      issue: IssueCandidature.depuisSql(brut['issue']),
      enPause: brut['enPause'] == true,
      paiement: brut['paiement'] == null
          ? null
          : EtatVersement.depuisSql(brut['paiement']),
    );
  }

  /// La version apres le geste.
  final int version;

  /// L'etape apres le geste.
  final EtapeCandidature? etape;

  /// L'etat apres le geste.
  final EtatCandidature? etat;

  /// L'issue apres le geste.
  final IssueCandidature issue;

  /// La pause apres le geste.
  final bool enPause;

  /// Le versement apres le geste, quand le serveur le rend.
  final EtatVersement? paiement;
}

/// Le resultat d'un geste : la candidature relue au serveur. Jamais un succes
/// sans elle.
@immutable
class ResultatGeste {
  /// Cree le resultat.
  const ResultatGeste({
    required this.candidature,
    this.rejoue = false,
    this.elementsDemandes = const <String>[],
  });

  /// Lit la reponse d'un geste reussi.
  factory ResultatGeste.depuisJson(Map<String, dynamic> brut) {
    final Object? elements = brut['aCompleter'];
    return ResultatGeste(
      candidature: EtatApresGeste.depuisJson(brut['candidature']),
      rejoue: brut['rejoue'] == true,
      elementsDemandes: List<String>.unmodifiable(<String>[
        if (elements is List)
          for (final Object? e in elements)
            if (e is String) e,
      ]),
    );
  }

  /// La candidature relue au serveur.
  final EtatApresGeste candidature;

  /// Vrai quand la meme cle a rejoue un geste deja fait : rien n'a ete
  /// ecrit une seconde fois.
  final bool rejoue;

  /// Les elements du complement demande, quand le geste en demandait.
  final List<String> elementsDemandes;
}
