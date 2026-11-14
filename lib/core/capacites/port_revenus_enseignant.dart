// Les revenus estimes de l'enseignant (FI-1c, guide Finance V4 §1.4, §5.5 ;
// FI-BR-11).
//
// **Une estimation, marquee comme telle** (FI20). Regle de paie en vigueur
// (DECISION-TARIFS-2026-10-18, 19/10, redite le 06/11) : par seance, par eleve
// present et par heure ; un absent n'est jamais paye ; aucun minimum. Aide
// Internet a part ; jamais un solde de famille ni un montant paye par une
// famille. Tout montant vient du serveur (`mes_revenus_enseignant`, lu dans
// la paie ecrite par seance) ou du double de demonstration, jamais d'un
// widget. REVENUS-VERITE (06/11/2026) : ni base garantie, ni plafond, ni
// sieges eligibles ; le detail par seance et par eleve, et le jour de paie.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../finance/montant.dart';
import 'capacite_indisponible.dart';
import 'port_autres_revenus.dart';

export 'port_autres_revenus.dart' show AutreRevenu, NatureAutreRevenu;

/// Le type d'une classe, qui fixe sa capacite de politique (guide §1.4 :
/// enfant 5, debutant 4, adulte 6). L'ecran le nomme, il n'en deduit rien.
enum TypeClasseRevenus {
  /// Classe d'enfants, capacite standard.
  enfants,

  /// Classe d'enfants debutants.
  debutants,

  /// Classe d'adultes.
  adultes,
}

/// Les revenus estimes d'une classe sur la periode.
@immutable
class RevenusClasse {
  /// Cree la ligne.
  const RevenusClasse({
    required this.classeId,
    required this.classe,
    required this.type,
    required this.minutesAssurees,
    required this.capacite,
    required this.tauxHoraireEffectif,
    required this.montantEstime,
    this.enRemplacement = false,
    this.montantARecevoir,
  });

  /// L'identifiant de la classe.
  final String classeId;

  /// Le nom propre de la classe (« An-Nour ») ; l'ecran ecrit « Classe »
  /// devant, jamais « groupe ».
  final String classe;

  /// Le type de la classe (FI-BR-11).
  final TypeClasseRevenus type;

  /// La duree assuree sur la periode, en minutes.
  final int minutesAssurees;

  /// La capacite effective de la classe.
  final int capacite;

  /// Le taux horaire effectif : le montant de la Classe rapporte aux heures
  /// assurees, calcule par la source.
  final Montant tauxHoraireEffectif;

  /// Le montant estime pour cette classe.
  final Montant montantEstime;

  /// Vrai quand l'enseignant n'est pas le titulaire de la classe et y a
  /// assure des seances en remplacement. Choix de contrat (revue FI-VAGUE-R,
  /// R5-01) : la seance est remuneree a celui qui l'assure, au taux de la
  /// classe ; la ligne ne porte que les minutes assurees par cet enseignant,
  /// et le titulaire ne les retrouve pas dans ses propres revenus.
  final bool enRemplacement;

  /// Ce que la Classe rapporte a recevoir : les montants ecrits de ses
  /// seances sans attente (cahier ou direction). Rendu par le serveur depuis REVENUS
  /// (07/11/2026) ; `null` avec un serveur plus ancien.
  final Montant? montantARecevoir;
}

/// La ligne de total du detail par classe, telle que la source la rend
/// (FI-BR-11) : l'ecran n'additionne ni ne divise rien.
@immutable
class TotalRevenus {
  /// Cree le total.
  const TotalRevenus({
    required this.minutesAssurees,
    required this.capacite,
    required this.tauxHoraireMoyen,
  });

  /// La duree assuree sur la periode, toutes classes, en minutes.
  final int minutesAssurees;

  /// La somme des capacites des classes.
  final int capacite;

  /// Le taux horaire moyen de la periode : le total estime rapporte aux
  /// heures assurees, calcule par la source.
  final Montant tauxHoraireMoyen;
}

/// Un mois du releve arrete par l'academie (guide §4, FI-BR-11). Aucun statut
/// « paye » : la paie reelle et son versement sont hors lot (ADR-007), le
/// releve dit seulement ce que l'academie a arrete.
@immutable
class LigneReleve {
  /// Cree la ligne.
  const LigneReleve({
    required this.mois,
    required this.minutesAssurees,
    required this.montant,
  });

  /// Le premier jour du mois arrete.
  final DateTime mois;

  /// La duree assuree sur ce mois, en minutes.
  final int minutesAssurees;

  /// Le montant arrete pour ce mois, hors aide Internet.
  final Montant montant;
}

/// Pourquoi le versement d'une seance attend.
enum AttenteVersement {
  /// Le cahier de la semaine manque : le montant est du, il sera verse une
  /// fois le cahier depose (DECISION-TARIFS, 18/10).
  cahier,

  /// La direction doit encore trancher la duree : aucun montant tant
  /// qu'elle ne l'a pas fait.
  direction,
}

/// La presence d'un eleve a une seance, telle que la paie la compte
/// (`private.presence_temps_reel`) : une presence partielle est payee comme
/// une presence (REVENUS, 07/11/2026).
enum PresenceRevenus {
  /// Present toute la seance.
  presente,

  /// Present une partie de la seance : paye comme present.
  partielle,

  /// Absent : jamais paye.
  absente;

  /// Lit la valeur du serveur ; `null` pour une valeur absente ou inconnue.
  static PresenceRevenus? depuisJson(Object? valeur) => switch (valeur) {
    'presente' => PresenceRevenus.presente,
    'partielle' => PresenceRevenus.partielle,
    'absente' => PresenceRevenus.absente,
    _ => null,
  };
}

/// Ce qu'un eleve inscrit a rapporte a une seance.
@immutable
class RevenusEleveSeance {
  /// Cree la ligne.
  const RevenusEleveSeance({
    required this.eleveId,
    required this.prenom,
    required this.present,
    required this.montant,
    this._presence,
  });

  /// L'identifiant de l'eleve.
  final String eleveId;

  /// Le prenom de l'eleve.
  final String prenom;

  /// Vrai quand l'eleve etait present (presence mesuree par la salle, ou
  /// corrigee par la direction) : seul un present est paye.
  final bool present;

  /// Sa part du montant de la seance, calculee par le serveur : 0 pour un
  /// absent ; `null` quand la direction doit encore trancher la seance.
  final Montant? montant;

  final PresenceRevenus? _presence;

  /// Present, present en partie ou absent. Rendu par le serveur ; un serveur
  /// plus ancien ne rend que [present] : un present est alors dit present.
  PresenceRevenus get presence =>
      _presence ??
      (present ? PresenceRevenus.presente : PresenceRevenus.absente);
}

/// Une seance tenue du mois : sa duree payee, son montant, ses eleves.
@immutable
class RevenusSeance {
  /// Cree la seance.
  const RevenusSeance({
    required this.seanceId,
    required this.debut,
    required this.classeId,
    required this.classe,
    required this.type,
    required this.minutes,
    required this.montant,
    required this.eleves,
    this.attente,
    this.enRemplacement = false,
    this.minutesPayees,
    this.minutesConnectees,
  });

  /// L'identifiant de la seance.
  final String seanceId;

  /// L'heure de debut prevue.
  final DateTime debut;

  /// L'identifiant de la Classe.
  final String classeId;

  /// Le nom propre de la Classe.
  final String classe;

  /// Le type de la Classe.
  final TypeClasseRevenus type;

  /// Les minutes ou l'enseignant etait connecte (mesure du releve), en
  /// minutes. Ce n'est PAS la duree payee : l'ecran dit [minutesPayees].
  final int minutes;

  /// La duree PAYEE par le serveur, en minutes (REVENUS-DUREE-PAYEE,
  /// `mes_durees_payees_enseignant`) ; `null` quand le serveur ne l'affirme
  /// pas (seance payee avant la fenetre payable, duree tranchee par la
  /// direction, lecture absente) : l'ecran renvoie alors au releve de
  /// l'academie, jamais a une duree inventee. Aucun calcul cote application.
  final int? minutesPayees;

  /// Les minutes de connexion DANS la fenetre payable, en minutes ; `null`
  /// quand la fenetre est inconnue ou la lecture absente.
  final int? minutesConnectees;

  /// Le montant ecrit par le serveur pour la seance (0 sans eleve present) ;
  /// `null` quand la direction doit encore trancher.
  final Montant? montant;

  /// Chaque eleve inscrit, presents d'abord.
  final List<RevenusEleveSeance> eleves;

  /// Pourquoi le versement attend, ou `null`.
  final AttenteVersement? attente;

  /// Vrai quand la seance a ete assuree en remplacement.
  final bool enRemplacement;

  /// Vrai quand le serveur a ecrit un montant non nul pour la seance. Sinon
  /// (montant nul, ou `null` en attente de la direction), l'ecran dit
  /// « aucun montant » : il ne redit aucune regle (revue du garde-cap,
  /// 08/11/2026, option i).
  bool get aUnMontant => (montant?.mineur ?? 0) > 0;
}

/// La fenetre du jour de paie du mois (reglage de la direction,
/// `paie.fenetre_versement`, par defaut du 1er au 10 du mois suivant).
@immutable
class FenetreVersement {
  /// Cree la fenetre.
  const FenetreVersement({required this.du, required this.au});

  /// Le premier jour de versement.
  final DateTime du;

  /// Le dernier jour de versement.
  final DateTime au;
}

/// Les revenus estimes de l'enseignant sur une periode.
@immutable
class RevenusEnseignant {
  /// Cree la vue.
  const RevenusEnseignant({
    required this.debut,
    required this.fin,
    required this.classes,
    required this.total,
    required this.totalEstime,
    this.seances = const <RevenusSeance>[],
    this.versement,
    this.autres = const <AutreRevenu>[],
    this.totalAutres,
    this.allocationInternet,
    this.totalARecevoir,
    this.totalAttenteCahier,
    this.seancesSansDureePayee,
  });

  /// Le debut de la periode.
  final DateTime debut;

  /// La fin de la periode.
  final DateTime fin;

  /// Le detail par classe, dans l'ordre rendu.
  final List<RevenusClasse> classes;

  /// La ligne de total du detail, rendue par la source.
  final TotalRevenus total;

  /// Le total estime de la remuneration pedagogique, hors aide Internet.
  final Montant totalEstime;

  /// Chaque seance tenue du mois, la plus recente d'abord.
  final List<RevenusSeance> seances;

  /// Le jour de paie de ce mois, ou `null` quand la source ne le rend pas.
  final FenetreVersement? versement;

  /// Les autres revenus du mois (aide Internet, primes, missions), attribues
  /// par la direction, payables avec la paie (REVENUS-VERITE point 5).
  final List<AutreRevenu> autres;

  /// Le total des autres revenus, rendu par la source ; nul si elle ne le rend
  /// pas.
  final Montant? totalAutres;

  /// L'aide Internet du mois, somme des aides attribuees ; `null` quand
  /// aucune ne l'est.
  final Montant? allocationInternet;

  /// Le total a recevoir du mois : les montants ecrits des seances sans
  /// attente (cahier de la semaine manquant, duree a trancher par la
  /// direction).
  /// Rendu par le serveur depuis REVENUS (07/11/2026) ; `null` avant.
  final Montant? totalARecevoir;

  /// Ce qui attend le cahier de la semaine, montre a part du total a
  /// recevoir ; `null` avec un serveur plus ancien.
  final Montant? totalAttenteCahier;

  /// Le nombre de seances du mois comptees au temps de connexion faute d'une
  /// duree payee affirmable par le serveur (REVENUS-DUREE-PAYEE) ; `null`
  /// avec un serveur plus ancien. Le serveur compte, l'ecran le dit.
  final int? seancesSansDureePayee;
}

/// Les revenus de l'enseignant connecte.
abstract interface class PortRevenusEnseignant {
  /// Les revenus estimes du mois en cours (FI-BR-11).
  Future<RevenusEnseignant> moisEnCours();

  /// Les revenus estimes du mois [mois] (premier jour), parmi
  /// [moisDisponibles] (FI-BR-11 ; choix du mois garde, FI-Q18 (a)).
  Future<RevenusEnseignant> duMois(DateTime mois);

  /// Les mois que la source sait rendre, le plus recent d'abord (premier
  /// jour de chaque mois) : le choix du mois ne propose qu'eux (FI-BR-11).
  Future<List<DateTime>> moisDisponibles();

  /// Le releve des mois arretes par l'academie, du plus recent au plus
  /// ancien (FI-BR-11). Une capacite absente se dit indisponible : l'ecran
  /// n'invente jamais un mois « paye ».
  Future<List<LigneReleve>> releve();
}

/// **Aucune source serveur a ce jour** (FI-BR-11).
class RevenusEnseignantIndisponibles implements PortRevenusEnseignant {
  /// Cree l'implementation.
  const RevenusEnseignantIndisponibles();

  @override
  Future<RevenusEnseignant> moisEnCours() =>
      Future<RevenusEnseignant>.error(const CapaciteIndisponible('FI-BR-11'));

  @override
  Future<RevenusEnseignant> duMois(DateTime mois) =>
      Future<RevenusEnseignant>.error(const CapaciteIndisponible('FI-BR-11'));

  @override
  Future<List<DateTime>> moisDisponibles() =>
      Future<List<DateTime>>.error(const CapaciteIndisponible('FI-BR-11'));

  @override
  Future<List<LigneReleve>> releve() =>
      Future<List<LigneReleve>>.error(const CapaciteIndisponible('FI-BR-11'));
}

/// Le port des revenus ; la demonstration le surcharge.
final Provider<PortRevenusEnseignant> portRevenusEnseignantProvider =
    Provider<PortRevenusEnseignant>(
      (Ref _) => const RevenusEnseignantIndisponibles(),
    );
