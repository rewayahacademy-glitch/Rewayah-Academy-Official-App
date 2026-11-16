// Ce que le dossier en trois etages decide de montrer (BE-DOSSIER, directeur,
// 16/11/2026) : la phrase de situation, la pastille et le geste de chaque
// rubrique, la rubrique qui s'ouvre d'elle-meme, les fentes de la barre de
// decision.
//
// **Une presentation, pas une regle.** Tout vient de ce que le serveur a rendu
// (le dossier, ses controles, les gestes qu'il ouvre). Rien n'est recalcule :
// la table `gestes_proposes.dart` reste l'unique source de ce qui est propose,
// et le serveur refuse toujours ce qui est interdit. Ici, on ne fait que
// regrouper ce qui est deja rendu et dire en mots simples pourquoi un geste
// n'est pas disponible.
library;

import '../../core/candidature/gestes_candidature.dart';
import '../../core/candidature/modeles_candidature.dart';
import '../../core/candidature/modeles_candidature_detail.dart';
import '../../core/candidature/modeles_candidatures_direction.dart';
import '../../core/i18n/strings.g.dart';
import 'gestes_proposes.dart';
import 'libelles_candidature.dart';

/// Les rubriques du dossier, dans l'ordre ou elles s'affichent.
enum RubriqueDossierCode {
  /// La photo envoyee avec la candidature.
  photo,

  /// La piece d'identite.
  piece,

  /// Le versement : pays, moyens, confirmation.
  versement,

  /// Les accords signes.
  accords,

  /// Les reponses sur les langues.
  langues,

  /// Les reponses sur la recitation.
  recitation,

  /// Les reponses sur les disponibilites.
  disponibilites,

  /// Les reponses sur le public.
  publics,

  /// « Vos autres talents ».
  talents,

  /// L'entretien.
  entretien,

  /// Les messages.
  messages,

  /// Le responsable.
  responsable,

  /// Le contact.
  contact,

  /// L'historique.
  historique,
}

/// La pastille d'une rubrique.
enum PastilleRubrique {
  /// Rien a dire : c'est en ordre.
  bon,

  /// A regarder avant de decider.
  aVoir,

  /// Il manque quelque chose.
  manque,
}

/// Une fente de la barre de decision : un geste, son mot, et, quand le serveur
/// ne le propose pas, la raison en mots simples.
class FenteDecision {
  /// Cree la fente.
  const FenteDecision({
    required this.geste,
    required this.libelle,
    required this.actif,
    this.raison,
  });

  /// Le geste.
  final GesteCandidature geste;

  /// Son mot sur le bouton.
  final String libelle;

  /// Vrai quand le serveur propose ce geste pour ce dossier.
  final bool actif;

  /// Pourquoi il n'est pas disponible (seulement quand [actif] est faux).
  final String? raison;
}

/// Le plan d'un dossier : tout ce que l'ecran en trois etages en lit.
class PlanDossier {
  /// Cree le plan.
  PlanDossier({
    required this.detail,
    required this.capacites,
    required this.horsLigne,
  }) : gestes = gestesProposes(detail, capacites);

  /// Le dossier lu.
  final DetailCandidature detail;

  /// Les capacites que le serveur rend.
  final CapacitesCandidatures capacites;

  /// Vrai quand l'appareil n'a pas de reseau : aucun geste n'est rendu.
  final bool horsLigne;

  /// Les gestes proposes pour ce dossier.
  final GestesProposes gestes;

  /// Les gestes qui ont leur place a cote d'une rubrique : ils ne vont pas
  /// dans le menu de la barre.
  static const Set<GesteCandidature> gestesDeRubrique = <GesteCandidature>{
    GesteCandidature.confirmerMoyenPaiement,
    GesteCandidature.infirmerMoyenPaiement,
    GesteCandidature.definirResponsable,
  };

  /// Le serveur propose-t-il ce geste pour ce dossier ?
  bool propose(GesteCandidature geste) =>
      gestes.principal == geste || gestes.autres.contains(geste);

  /// Le geste est-il rendu (propose, et un reseau pour l'envoyer) ?
  bool offert(GesteCandidature geste) => !horsLigne && propose(geste);

  /// Les controles du serveur par nom, ou `null` quand il ne les rend pas.
  Map<String, bool>? get controles {
    final List<ControleCandidature>? tous = detail.controles;
    if (tous == null) return null;
    return <String, bool>{
      for (final ControleCandidature c in tous) c.nom: c.valeur,
    };
  }

  /// La rubrique que porte un controle, ou `null` : il n'a pas de rubrique et
  /// ne se dit que dans la phrase de situation.
  static RubriqueDossierCode? rubriqueDuControle(String nom) => switch (nom) {
    'paiement_compatible' => RubriqueDossierCode.versement,
    'cadre_religieux' || 'accords_signes' => RubriqueDossierCode.accords,
    'entretien_conclu' || 'evaluation_validee' => RubriqueDossierCode.entretien,
    'piece_validee' => RubriqueDossierCode.piece,
    _ => null,
  };

  /// La rubrique qui bloque, la premiere dans l'ordre d'affichage : elle
  /// s'ouvre d'elle-meme.
  RubriqueDossierCode? get rubriqueQuiBloque {
    final Set<RubriqueDossierCode> bloquantes = <RubriqueDossierCode>{
      for (final ControleCandidature c in detail.blocages)
        ?rubriqueDuControle(c.nom),
    };
    for (final RubriqueDossierCode code in RubriqueDossierCode.values) {
      if (bloquantes.contains(code)) return code;
    }
    return null;
  }

  /// La pastille d'une rubrique lue dans le dossier, ou `null` : la rubrique
  /// n'en porte pas (ou son etat n'est pas encore lu).
  PastilleRubrique? pastille(RubriqueDossierCode code) {
    final Map<String, bool>? c = controles;
    PastilleRubrique? deControles(List<String> noms) {
      if (c == null) return null;
      final List<bool> valeurs = <bool>[for (final String n in noms) ?c[n]];
      if (valeurs.isEmpty) return null;
      return valeurs.every((bool v) => v)
          ? PastilleRubrique.bon
          : PastilleRubrique.manque;
    }

    switch (code) {
      case RubriqueDossierCode.piece:
        return switch (detail.piece) {
          EtatPiece.validee => PastilleRubrique.bon,
          EtatPiece.deposee => PastilleRubrique.aVoir,
          EtatPiece.aDeposer || EtatPiece.aCorriger => PastilleRubrique.manque,
          null => deControles(<String>['piece_validee']),
        };
      case RubriqueDossierCode.versement:
        return switch (detail.ligne.paiement) {
          EtatVersement.compatible => PastilleRubrique.bon,
          EtatVersement.aVerifier => PastilleRubrique.aVoir,
          EtatVersement.incompatible ||
          EtatVersement.inconnu => PastilleRubrique.manque,
        };
      case RubriqueDossierCode.accords:
        return deControles(<String>['accords_signes', 'cadre_religieux']);
      case RubriqueDossierCode.entretien:
        return deControles(<String>['entretien_conclu']);
      case RubriqueDossierCode.responsable:
        return detail.ligne.responsableId == null
            ? PastilleRubrique.manque
            : PastilleRubrique.bon;
      case RubriqueDossierCode.photo ||
          RubriqueDossierCode.langues ||
          RubriqueDossierCode.recitation ||
          RubriqueDossierCode.disponibilites ||
          RubriqueDossierCode.publics ||
          RubriqueDossierCode.talents ||
          RubriqueDossierCode.messages ||
          RubriqueDossierCode.contact ||
          RubriqueDossierCode.historique:
        return null;
    }
  }

  /// Le noms des controles faux, dans la langue de la direction.
  List<String> get nomsBloquants => <String>[
    for (final ControleCandidature c in detail.blocages) libelleControle(c.nom),
  ];

  /// Les controles faux, tels que la phrase « Ce qui bloque » de l'etage 1 les
  /// dit. Un controle qui a sa rubrique n'est nomme que par son nom : sa cause
  /// se lit dans la rubrique, qui s'ouvre. Un controle sans rubrique garde sa
  /// cause dans la phrase, pour qu'aucune cause ne se perde avec le bloc
  /// « Controles ».
  List<String> get blocagesAvecCause => <String>[
    for (final ControleCandidature c in detail.blocages)
      c.cause == null || rubriqueDuControle(c.nom) != null
          ? libelleControle(c.nom)
          : controleEtCause(c.nom, c.cause),
  ];

  /// Qui doit agir, sur quoi, en une phrase.
  String quiAgit() {
    final LigneCandidature l = detail.ligne;
    final r = t.admin.candidatures.detail;
    if (l.issue != IssueCandidature.enCours) return r.fermee;
    if (l.enPause) return t.recrutement.dossier3.situation.pause;
    if (l.etat == EtatCandidature.aCompleter) return r.enAttentePersonne;
    final GesteCandidature? principal = gestes.principal;
    if (principal != null) {
      return t.recrutement.dossier3.situation.vous(
        geste: libelleGeste(principal),
      );
    }
    return t.recrutement.dossier3.situation.rien;
  }

  /// « Ce qui bloque : ... », ou `null` quand rien ne bloque (ou que le serveur
  /// ne rend pas encore les controles).
  String? phraseBloque() {
    final List<String> noms = blocagesAvecCause;
    if (noms.isEmpty) return null;
    return t.recrutement.dossier3.situation.bloque(
      liste: noms.join(t.admin.candidatures.detail.separateurControles),
    );
  }

  bool get _etapeVerifications =>
      detail.ligne.etape == EtapeCandidature.verifications;

  /// Les trois decisions de la barre, toutes visibles, dans l'ordre :
  /// accepter, demander une precision, refuser. Une decision que le serveur ne
  /// propose pas porte sa raison.
  List<FenteDecision> fentesDecision() {
    final d = t.admin.candidatures.decision;
    final GesteCandidature accepter = _etapeVerifications
        ? GesteCandidature.validerPiece
        : GesteCandidature.admettreVerifications;
    FenteDecision fente(GesteCandidature g, String libelle) {
      final bool actif = propose(g);
      return FenteDecision(
        geste: g,
        libelle: libelle,
        actif: actif,
        raison: actif ? null : _raison(g, accepter: g == accepter),
      );
    }

    return <FenteDecision>[
      fente(
        accepter,
        accepter == GesteCandidature.validerPiece
            ? libelleGeste(accepter)
            : d.accepter,
      ),
      fente(GesteCandidature.demanderComplement, d.preciser),
      fente(
        GesteCandidature.refuser,
        _etapeVerifications ? d.nePasAccueillir : d.refuser,
      ),
    ];
  }

  /// La prochaine action du serveur quand elle n'a ni fente ni rubrique (lever
  /// une pause) : elle reste visible dans la barre, jamais cachee dans le menu.
  GesteCandidature? get principalHorsFentes {
    final GesteCandidature? principal = gestes.principal;
    if (principal == null || gestesDeRubrique.contains(principal)) return null;
    return fentesDecision().any((FenteDecision f) => f.geste == principal)
        ? null
        : principal;
  }

  /// Les autres gestes, pour le menu « ⋯ » de la barre : tout ce que le
  /// serveur propose et qui n'a ni fente ni rubrique.
  List<GesteCandidature> gestesDuMenu() {
    final Set<GesteCandidature> fentes = <GesteCandidature>{
      for (final FenteDecision f in fentesDecision()) f.geste,
    };
    final GesteCandidature? visible = principalHorsFentes;
    return <GesteCandidature>[
      if (gestes.principal != null) gestes.principal!,
      ...gestes.autres,
    ].where((GesteCandidature g) {
      return g != visible &&
          !fentes.contains(g) &&
          !gestesDeRubrique.contains(g);
    }).toList();
  }

  String _raison(GesteCandidature g, {required bool accepter}) {
    final r = t.recrutement.dossier3.raison;
    final LigneCandidature l = detail.ligne;
    if (!capacites.peutDecider) return r.droit;
    if (l.issue != IssueCandidature.enCours) return r.fermee;
    if (l.enPause) return r.pause;
    if (accepter && nomsBloquants.isNotEmpty) {
      return r.manque(
        liste: nomsBloquants.join(
          t.admin.candidatures.detail.separateurControles,
        ),
      );
    }
    if (l.etat == EtatCandidature.aCompleter) return r.attente;
    return r.etape;
  }
}
