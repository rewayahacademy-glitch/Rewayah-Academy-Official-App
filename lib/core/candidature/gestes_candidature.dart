// Les gestes de la direction sur une candidature (`ADM-21`,
// `PortCandidaturesDirection.geste`), ceux que CAND-L2A2 ouvre
// (`20261022000100_cand_l2a2_gestes_direction.sql`), et les refus nommes que le
// serveur rend.
//
// Chaque geste porte sa **version attendue** (concurrence optimiste) et sa
// **cle d'idempotence** (une par geste : la rejouer ne l'ecrit pas deux fois).
// Les refus metier arrivent dans la reponse du serveur (`{"erreur": ...}`),
// jamais en exception de base : ils sont rendus pour ne laisser aucune
// ecriture. L'adaptateur les traduit en [RefusGeste], que l'ecran dit en mots
// (K-59), jamais par leur code.
//
// Les gestes que le serveur ne sait pas encore faire (inviter, consigner le
// lien envoye, garder pour suivi, rattacher, planifier un entretien, consigner
// un entretien, piece a corriger, valider la piece, restreindre, lever la
// restriction, noter ou lever une indisponibilite) n'ont pas de valeur ici : un
// geste que le serveur n'ouvre pas n'est pas rendu (`capacites_candidatures`,
// `gestes`, une cle absente vaut faux).
library;

import 'package:flutter/foundation.dart';

import 'modeles_candidature.dart';

/// Un geste de la direction, avec le nom que lui donne `capacites_candidatures`
/// (`gestes.<nom>`).
enum GesteCandidature {
  /// Demander un complement (transitions 7 et 23).
  demanderComplement('demanderComplement'),

  /// Clore le complement en cours en Salle de verification et d'entretien
  /// (transition 23, code `complement_clos`).
  cloreComplement('cloreComplement'),

  /// Admettre en Salle de verification et d'entretien (transition 10).
  admettreVerifications('admettreVerifications'),

  /// Confirmer un moyen de versement declare (transition 24).
  confirmerMoyenPaiement('confirmerMoyenPaiement'),

  /// Ecarter un moyen de versement declare (transition 25).
  infirmerMoyenPaiement('infirmerMoyenPaiement'),

  /// Mettre en pause (transition 18).
  mettreEnPause('mettreEnPause'),

  /// Lever la pause (transition 18).
  leverPause('leverPause'),

  /// Refuser la candidature (transition 16).
  refuser('refuser'),

  /// Enregistrer un retrait demande hors de l'application (transition 17).
  consignerRetrait('consignerRetrait'),

  /// Rouvrir une candidature refusee ou retiree (transition 19).
  rouvrir('rouvrir'),

  /// Choisir le responsable (transition 28).
  definirResponsable('definirResponsable');

  const GesteCandidature(this.capacite);

  /// La cle de `capacites_candidatures().gestes`.
  final String capacite;

  /// Le geste exige un motif interne, saisi par la direction.
  bool get exigeMotif => switch (this) {
    demanderComplement ||
    cloreComplement ||
    infirmerMoyenPaiement ||
    mettreEnPause ||
    refuser ||
    consignerRetrait ||
    rouvrir => true,
    admettreVerifications ||
    confirmerMoyenPaiement ||
    leverPause ||
    definirResponsable => false,
  };

  /// Le geste exige un modele de message pour la personne.
  bool get exigeModele => this == refuser || this == mettreEnPause;

  /// Le geste est destructif : il ferme la candidature, ou la met de cote.
  bool get destructif =>
      this == refuser ||
      this == consignerRetrait ||
      this == infirmerMoyenPaiement;
}

/// Le canal par lequel un retrait a ete demande hors de l'application.
enum CanalRetrait {
  /// La conversation de la candidature.
  conversation('conversation'),

  /// Un courriel.
  courriel('courriel');

  const CanalRetrait(this.valeurSql);

  /// La valeur envoyee au serveur.
  final String valeurSql;

  /// La valeur lue, ou `null`.
  static CanalRetrait? depuisSql(Object? valeur) {
    for (final CanalRetrait c in values) {
      if (c.valeurSql == valeur) {
        return c;
      }
    }
    return null;
  }
}

/// Un moyen de versement declare : le virement bancaire, ou un operateur de
/// monnaie mobile.
@immutable
class MoyenVersement {
  /// Le virement bancaire.
  const MoyenVersement.virement() : operateur = null;

  /// Un operateur de monnaie mobile, par son code.
  const MoyenVersement.mobile(String this.operateur);

  /// Le code de l'operateur, ou `null` pour le virement bancaire.
  final String? operateur;

  /// La methode envoyee au serveur.
  String get methode =>
      operateur == null ? 'virement_bancaire' : 'mobile_money';

  @override
  bool operator ==(Object other) =>
      other is MoyenVersement && other.operateur == operateur;

  @override
  int get hashCode => operateur.hashCode;
}

/// Ce que la direction demande au serveur de faire : un geste, sa candidature,
/// la version qu'elle a lue, sa cle d'idempotence et ses arguments.
///
/// Un constructeur par geste, qui ne prend que les arguments du geste : on ne
/// peut pas oublier un motif exige ni en poser un qui ne sert pas.
@immutable
class DemandeGeste {
  const DemandeGeste._({
    required this.geste,
    required this.candidatureId,
    required this.versionAttendue,
    required this.cleIdempotence,
    this.motif,
    this.modele,
    this.repriseLe,
    this.elements = const <String>[],
    this.canal,
    this.demandeRecueLe,
    this.moyen,
    this.responsableId,
  });

  /// Demander un complement : les [elements] choisis dans la liste fermee, et
  /// un [motif] interne.
  factory DemandeGeste.demanderComplement({
    required String candidatureId,
    required int versionAttendue,
    required String cleIdempotence,
    required List<String> elements,
    required String motif,
  }) => DemandeGeste._(
    geste: GesteCandidature.demanderComplement,
    candidatureId: candidatureId,
    versionAttendue: versionAttendue,
    cleIdempotence: cleIdempotence,
    elements: List<String>.unmodifiable(elements),
    motif: motif,
  );

  /// Clore le complement en cours (Salle de verification et d'entretien) : le
  /// seul code [codeCloture], avec un [motif].
  factory DemandeGeste.cloreComplement({
    required String candidatureId,
    required int versionAttendue,
    required String cleIdempotence,
    required String motif,
    String codeCloture = 'complement_clos',
  }) => DemandeGeste._(
    geste: GesteCandidature.cloreComplement,
    candidatureId: candidatureId,
    versionAttendue: versionAttendue,
    cleIdempotence: cleIdempotence,
    elements: List<String>.unmodifiable(<String>[codeCloture]),
    motif: motif,
  );

  /// Admettre en Salle de verification et d'entretien.
  factory DemandeGeste.admettreVerifications({
    required String candidatureId,
    required int versionAttendue,
    required String cleIdempotence,
  }) => DemandeGeste._(
    geste: GesteCandidature.admettreVerifications,
    candidatureId: candidatureId,
    versionAttendue: versionAttendue,
    cleIdempotence: cleIdempotence,
  );

  /// Confirmer le [moyen] de versement declare.
  factory DemandeGeste.confirmerMoyenPaiement({
    required String candidatureId,
    required int versionAttendue,
    required String cleIdempotence,
    required MoyenVersement moyen,
  }) => DemandeGeste._(
    geste: GesteCandidature.confirmerMoyenPaiement,
    candidatureId: candidatureId,
    versionAttendue: versionAttendue,
    cleIdempotence: cleIdempotence,
    moyen: moyen,
  );

  /// Ecarter le [moyen] de versement declare, avec un [motif].
  factory DemandeGeste.infirmerMoyenPaiement({
    required String candidatureId,
    required int versionAttendue,
    required String cleIdempotence,
    required MoyenVersement moyen,
    required String motif,
  }) => DemandeGeste._(
    geste: GesteCandidature.infirmerMoyenPaiement,
    candidatureId: candidatureId,
    versionAttendue: versionAttendue,
    cleIdempotence: cleIdempotence,
    moyen: moyen,
    motif: motif,
  );

  /// Mettre en pause : un [motif] interne, un [modele] de message pour la
  /// personne, et une reprise facultative ([repriseLe], un jour posterieur a
  /// aujourd'hui en UTC).
  factory DemandeGeste.mettreEnPause({
    required String candidatureId,
    required int versionAttendue,
    required String cleIdempotence,
    required String motif,
    required String modele,
    DateTime? repriseLe,
  }) => DemandeGeste._(
    geste: GesteCandidature.mettreEnPause,
    candidatureId: candidatureId,
    versionAttendue: versionAttendue,
    cleIdempotence: cleIdempotence,
    motif: motif,
    modele: modele,
    repriseLe: repriseLe,
  );

  /// Lever la pause. Le motif est facultatif.
  factory DemandeGeste.leverPause({
    required String candidatureId,
    required int versionAttendue,
    required String cleIdempotence,
    String? motif,
  }) => DemandeGeste._(
    geste: GesteCandidature.leverPause,
    candidatureId: candidatureId,
    versionAttendue: versionAttendue,
    cleIdempotence: cleIdempotence,
    motif: motif,
  );

  /// Refuser la candidature : un [motif] interne et un [modele] de message
  /// pour la personne.
  factory DemandeGeste.refuser({
    required String candidatureId,
    required int versionAttendue,
    required String cleIdempotence,
    required String motif,
    required String modele,
  }) => DemandeGeste._(
    geste: GesteCandidature.refuser,
    candidatureId: candidatureId,
    versionAttendue: versionAttendue,
    cleIdempotence: cleIdempotence,
    motif: motif,
    modele: modele,
  );

  /// Enregistrer un retrait demande par la personne hors de l'application :
  /// son [canal], le jour de la demande ([demandeRecueLe]) et un [motif].
  factory DemandeGeste.consignerRetrait({
    required String candidatureId,
    required int versionAttendue,
    required String cleIdempotence,
    required CanalRetrait canal,
    required DateTime demandeRecueLe,
    required String motif,
  }) => DemandeGeste._(
    geste: GesteCandidature.consignerRetrait,
    candidatureId: candidatureId,
    versionAttendue: versionAttendue,
    cleIdempotence: cleIdempotence,
    canal: canal,
    demandeRecueLe: demandeRecueLe,
    motif: motif,
  );

  /// Rouvrir une candidature refusee ou retiree, avec un [motif].
  factory DemandeGeste.rouvrir({
    required String candidatureId,
    required int versionAttendue,
    required String cleIdempotence,
    required String motif,
  }) => DemandeGeste._(
    geste: GesteCandidature.rouvrir,
    candidatureId: candidatureId,
    versionAttendue: versionAttendue,
    cleIdempotence: cleIdempotence,
    motif: motif,
  );

  /// Choisir le responsable, ou personne ([responsableId] nul).
  factory DemandeGeste.definirResponsable({
    required String candidatureId,
    required int versionAttendue,
    required String cleIdempotence,
    String? responsableId,
  }) => DemandeGeste._(
    geste: GesteCandidature.definirResponsable,
    candidatureId: candidatureId,
    versionAttendue: versionAttendue,
    cleIdempotence: cleIdempotence,
    responsableId: responsableId,
  );

  /// Le geste.
  final GesteCandidature geste;

  /// L'identifiant de la candidature.
  final String candidatureId;

  /// La version lue : le serveur refuse le geste si la candidature a change.
  final int versionAttendue;

  /// La cle d'idempotence : une par geste, rejouee telle quelle pour un essai
  /// non confirme.
  final String cleIdempotence;

  /// Le motif interne, que la personne ne lit jamais.
  final String? motif;

  /// Le code du modele de message que la personne lira.
  final String? modele;

  /// La reprise d'une pause, en jour.
  final DateTime? repriseLe;

  /// Les elements d'un complement (ou le code de cloture).
  final List<String> elements;

  /// Le canal d'un retrait.
  final CanalRetrait? canal;

  /// Le jour d'une demande de retrait.
  final DateTime? demandeRecueLe;

  /// Le moyen de versement confirme ou ecarte.
  final MoyenVersement? moyen;

  /// Le responsable choisi.
  final String? responsableId;
}

/// Un refus que le serveur rend pour un geste, sans rien ecrire. Chaque refus
/// se dit en mots (K-59) : ce qui n'a pas ete fait, pourquoi, quoi faire.
sealed class RefusGeste implements Exception {
  const RefusGeste();
}

/// La candidature a change depuis son ouverture : [versionCourante] est la
/// version a relire. Rien n'a ete fait.
final class ConflitGeste extends RefusGeste {
  /// Cree le refus.
  const ConflitGeste(this.versionCourante);

  /// La version courante de la candidature.
  final int? versionCourante;
}

/// Le geste n'est pas permis depuis l'etat courant : le serveur nomme cet
/// etat, que l'ecran dit par son libelle.
final class GesteInterdit extends RefusGeste {
  /// Cree le refus.
  const GesteInterdit({
    this.etape,
    this.etat,
    this.issue = IssueCandidature.enCours,
    this.enPause = false,
    this.parLaPause = false,
  });

  /// L'etape courante.
  final EtapeCandidature? etape;

  /// L'etat courant.
  final EtatCandidature? etat;

  /// L'issue courante.
  final IssueCandidature issue;

  /// La candidature est en pause.
  final bool enPause;

  /// C'est la pause seule qui interdit le geste (`raison: pause`).
  final bool parLaPause;
}

/// Des controles ne sont pas satisfaits : le serveur les nomme avec leur cause.
final class ControlesNonSatisfaits extends RefusGeste {
  /// Cree le refus.
  const ControlesNonSatisfaits(this.controles);

  /// Les controles faux.
  final List<({String nom, String? cause})> controles;
}

/// Un motif interne est exige.
final class MotifRequis extends RefusGeste {
  /// Cree le refus.
  const MotifRequis();
}

/// Un modele de message est exige.
final class ModeleRequis extends RefusGeste {
  /// Cree le refus.
  const ModeleRequis();
}

/// Le modele choisi n'est pas dans la liste du serveur.
final class ModeleInconnu extends RefusGeste {
  /// Cree le refus.
  const ModeleInconnu();
}

/// Aucun element n'a ete choisi pour le complement.
final class ElementsRequis extends RefusGeste {
  /// Cree le refus.
  const ElementsRequis();
}

/// Des elements choisis ne sont pas dans la liste de la salle.
final class ElementsInvalides extends RefusGeste {
  /// Cree le refus.
  const ElementsInvalides();
}

/// Aucun complement n'est en cours : rien a clore.
final class AucunComplement extends RefusGeste {
  /// Cree le refus.
  const AucunComplement();
}

/// La date de reprise doit etre posterieure a aujourd'hui.
final class RepriseInvalide extends RefusGeste {
  /// Cree le refus.
  const RepriseInvalide();
}

/// La date de la demande de retrait est future ou anterieure a la reception.
final class DateDemandeInvalide extends RefusGeste {
  /// Cree le refus.
  const DateDemandeInvalide();
}

/// Le moyen de versement ne peut pas etre confirme : il n'est pas declare, ou
/// la ligne du referentiel n'est pas confirmee dans le pays de versement.
final class MoyenNonConfirmable extends RefusGeste {
  /// Cree le refus.
  const MoyenNonConfirmable({this.nonDeclare = false, this.etatLigne});

  /// Le moyen n'a pas ete declare par la personne.
  final bool nonDeclare;

  /// L'etat de la ligne du referentiel (`en_verification`, `indisponible`...),
  /// quand le serveur le dit.
  final String? etatLigne;
}

/// Le moyen de versement a ecarter n'a pas ete declare par la personne.
final class MoyenNonDeclare extends RefusGeste {
  /// Cree le refus.
  const MoyenNonDeclare();
}

/// Le responsable choisi n'est pas un membre actif de la direction de ce cote.
final class ResponsableInvalide extends RefusGeste {
  /// Cree le refus.
  const ResponsableInvalide();
}

/// La cle d'idempotence a deja servi a un autre geste.
final class CleReutilisee extends RefusGeste {
  /// Cree le refus.
  const CleReutilisee();
}

/// Aucune reponse : l'appareil est hors ligne, ou le serveur n'a pas repondu.
/// Le geste est **non confirme** (D5) : il est possible qu'il ne soit pas
/// parvenu. Rejouer avec la meme cle d'idempotence est sans risque.
final class GesteNonConfirme extends RefusGeste {
  /// Cree le refus.
  const GesteNonConfirme();
}

/// La candidature n'existe pas, ou plus.
class CandidatureIntrouvable implements Exception {
  /// Cree l'erreur.
  const CandidatureIntrouvable();

  @override
  String toString() => 'CandidatureIntrouvable';
}

/// La candidature est de l'autre cote (femmes ou hommes) : le serveur ne rend
/// aucune donnee et trace la tentative.
class CandidatureHorsPortee implements Exception {
  /// Cree l'erreur.
  const CandidatureHorsPortee();

  @override
  String toString() => 'CandidatureHorsPortee';
}
