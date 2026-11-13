/// SUIVI-ATTENTE (directeur, 12/11/2026 ; arbitrages S1 a S9) : le suivi de
/// l'attente de la classe choisie, « comme une livraison ».
///
/// Cinq etapes, toujours les memes, dans cet ordre :
/// 1. Demande recue ; 2. Classe en formation ; 3. Classe confirmee ;
/// 4. Enseignant affecte ; 5. Tout est pret.
///
/// **Une etape est franchie seulement quand le serveur le dit** (S1) : ce
/// modele ne calcule ni etape, ni pourcentage, ni delai. Il range ce que la
/// lecture `suivi_attente_foyer()` rend et refuse ce qui serait faux :
/// - **aucun enseignant avant l'etape 4** (S4) : le constructeur efface la
///   carte de l'enseignant si l'etape 4 n'est pas franchie ;
/// - **aucune promesse sans date** (S2) : le delai n'existe que si le serveur
///   l'a rendu, c'est-a-dire si la valeur est dans les reglages ;
/// - **heures murales du foyer** : un instant UTC est refuse (aucune heure
///   plutot qu'une heure fausse, comme `port_frise_demande.dart`).
///
/// Aucun branchement serveur ici : en production le port est absent tant que
/// `lib/main.dart` ne le pose pas ; sans port, aucune carte n'est inventee.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../offres/port_suivi_demandes.dart' show CreneauDemande, MotifCloture;

export '../offres/port_suivi_demandes.dart'
    show CreneauDemande, MotifCloture, OccurrenceCreneau;

/// Le nombre d'etapes du suivi.
const int nombreEtapesAttente = 5;

/// Les jours pendant lesquels le suivi reste en tete de l'accueil apres le
/// premier cours (S6). Le serveur decide : il rend `visible_accueil`.
const int joursApresPremierCours = 7;

/// L'etat d'une etape (rendu par le serveur).
enum EtatEtapeAttente {
  /// Franchie.
  fait,

  /// En cours.
  enCours,

  /// A venir.
  aVenir,
}

/// A qui l'ecran parle (arbitrage du 13/11/2026). Ce n'est pas l'age de l'eleve
/// seul qui decide : un tuteur lit toujours le suivi d'un enfant avec les mots
/// des adultes, l'enfant le lit dans son propre espace.
enum AudienceAttente {
  /// Un adulte ou un tuteur : vouvoiement, dates et delais.
  adulte,

  /// Un mineur de 10 a 17 ans dans son espace : tutoiement, dates et delais,
  /// rien sur l'argent ni sur les gestes reserves au tuteur.
  mineur,

  /// Un enfant de 6 a 9 ans dans son espace : tutoiement, **ni date ni duree**.
  petit,
}

/// Ou en est la demande, hors du chemin droit ou sur lui (S3).
enum CasAttente {
  /// Le chemin droit : aucun accroc.
  chemin,

  /// La classe est confirmee et attend son enseignant.
  enAttenteEnseignant,

  /// Toutes les classes de ce creneau sont pleines : la demande attend.
  listeAttente,

  /// La direction n'a pas retenu la demande.
  refusee,

  /// La demande est retiree (par la famille, ou avec l'offre).
  retiree,

  /// Close, motif autre ou inconnu : ni refus ni retrait suppose.
  close,
}

/// Une etape et son instant.
@immutable
class EtapeAttente {
  /// Cree l'etape. [quand] : heure murale du foyer, jamais UTC.
  EtapeAttente({required this.numero, required this.etat, DateTime? quand})
    : assert(numero >= 1 && numero <= nombreEtapesAttente),
      assert(
        quand == null || !quand.isUtc,
        'quand est une heure murale du foyer, jamais UTC',
      ),
      quand = quand == null || quand.isUtc ? null : quand;

  /// Son rang, de 1 a 5.
  final int numero;

  /// Son etat.
  final EtatEtapeAttente etat;

  /// Quand elle a ete franchie (heure murale du foyer), si le serveur le sait.
  final DateTime? quand;
}

/// Le delai honnete de formation d'une classe (S2), tire des reglages.
@immutable
class DelaiFormation {
  /// Cree le delai.
  const DelaiFormation({
    required this.jours,
    required this.limite,
    this.point,
    this.pointPasse = false,
    this.depasse = false,
  });

  /// Le delai maximum, en jours.
  final int jours;

  /// La date limite (heure murale du foyer).
  final DateTime limite;

  /// La date du point d'etape, si le reglage existe.
  final DateTime? point;

  /// Vrai quand le point d'etape est passe.
  final bool pointPasse;

  /// Vrai quand la date limite est passee.
  final bool depasse;
}

/// Ce que la famille voit de l'enseignant a l'etape 4 (S4) : rien d'autre.
/// Ni ville, ni telephone, ni courriel, ni date de naissance, ni piece.
@immutable
class CarteEnseignantAttente {
  /// Cree la carte. Quand [montre] est faux, photo, pays et mot sont nuls.
  const CarteEnseignantAttente({
    required this.prenom,
    required this.nom,
    required this.montre,
    this.titre,
    this.langueCours,
    this.enseignantId,
    this.paysOrigine,
    this.paysResidence,
    this.mot,
  });

  /// Son prenom.
  final String prenom;

  /// Son nom.
  final String nom;

  /// `sayyid`, `sayyida`, ou nul.
  final String? titre;

  /// La langue du cours, lisible.
  final String? langueCours;

  /// Vrai quand l'enseignant montre sa photo, ses pays et son mot aux
  /// familles de ses classes.
  final bool montre;

  /// Son identifiant, pour la photo : nul s'il ne montre pas.
  final String? enseignantId;

  /// Pays d'origine (code ISO), nul si non declare ou non montre.
  final String? paysOrigine;

  /// Pays de residence (code ISO), nul si non declare ou non montre.
  final String? paysResidence;

  /// Son mot de presentation, tel qu'il l'a ecrit.
  final String? mot;
}

/// Le suivi d'une demande de classe pour un eleve.
@immutable
class SuiviAttente {
  /// Cree le suivi. L'enseignant n'est gardé que si l'etape 4 est franchie.
  SuiviAttente({
    required this.demandeId,
    required this.eleveId,
    required this.prenom,
    required this.fuseauIana,
    required this.cas,
    required Iterable<EtapeAttente> etapes,
    this.typePublic = 'enfant',
    this.versionSimple = false,
    this.motif,
    this.creneau,
    this.delai,
    this.classe,
    this.premierCours,
    this.premierCoursPasse = false,
    this.creneauChangeLe,
    CarteEnseignantAttente? enseignant,
    this.peutChoisirAutreCreneau = false,
    this.visibleAccueil = true,
    AudienceAttente? audience,
  }) : audience =
           audience ??
           (versionSimple ? AudienceAttente.petit : AudienceAttente.adulte),
       etapes = List<EtapeAttente>.unmodifiable(_rangees(etapes)),
       enseignant =
           _rangees(etapes).any(
             (EtapeAttente e) =>
                 e.numero == 4 && e.etat == EtatEtapeAttente.fait,
           )
           ? enseignant
           : null,
       assert(
         _rangees(etapes).length == nombreEtapesAttente,
         'cinq etapes, toujours les memes',
       );

  /// L'identifiant de la demande.
  final String demandeId;

  /// L'eleve concerne.
  final String eleveId;

  /// Son prenom.
  final String prenom;

  /// Le fuseau IANA du foyer : toutes les heures y sont rendues.
  final String fuseauIana;

  /// Le cas : chemin droit ou accroc.
  final CasAttente cas;

  /// `enfant` ou `adulte`.
  final String typePublic;

  /// Vrai pour un enfant de moins de 10 ans : version simple, sans delai
  /// chiffre (S6).
  final bool versionSimple;

  /// Le motif de cloture, nul tant que la demande vit.
  final MotifCloture? motif;

  /// Les jours et heures choisis (heure du foyer), nuls si le serveur n'en
  /// rend aucun.
  final CreneauDemande? creneau;

  /// Les cinq etapes, dans l'ordre.
  final List<EtapeAttente> etapes;

  /// Le delai de formation, nul quand il ne s'applique pas ou n'est pas dans
  /// les reglages.
  final DelaiFormation? delai;

  /// Le nom de la classe, des l'etape 3.
  final String? classe;

  /// Le premier cours (heure murale du foyer), si le serveur le connait.
  final DateTime? premierCours;

  /// Vrai quand le premier cours est passe.
  final bool premierCoursPasse;

  /// Le dernier changement de creneau de la classe (14 jours), si recent.
  final DateTime? creneauChangeLe;

  /// L'enseignant, a l'etape 4 seulement.
  final CarteEnseignantAttente? enseignant;

  /// Capacite rendue par le serveur : choisir un autre creneau (demande close).
  final bool peutChoisirAutreCreneau;

  /// Vrai quand le suivi est encore en tete de l'accueil (S6).
  final bool visibleAccueil;

  /// A qui l'ecran parle. Fixee par l'espace de celui qui regarde
  /// ([pourEspace]) ; par defaut, un enfant de 6 a 9 ans est « petit », tout
  /// le reste est « adulte ».
  final AudienceAttente audience;

  /// Le meme suivi, lu depuis l'espace de celui qui regarde : le tuteur et
  /// l'adulte lisent avec les mots des adultes ; l'enfant, dans son espace, avec
  /// les siens (6 a 9 ans : sans date ni duree ; 10 a 17 ans : tutoiement, avec
  /// dates et delais).
  SuiviAttente pourEspace({required bool espaceEnfant}) {
    final AudienceAttente voulue = !espaceEnfant
        ? AudienceAttente.adulte
        : versionSimple
        ? AudienceAttente.petit
        : typePublic == 'enfant'
        ? AudienceAttente.mineur
        : AudienceAttente.adulte;
    if (voulue == audience) return this;
    return SuiviAttente(
      demandeId: demandeId,
      eleveId: eleveId,
      prenom: prenom,
      fuseauIana: fuseauIana,
      cas: cas,
      etapes: etapes,
      typePublic: typePublic,
      versionSimple: versionSimple,
      motif: motif,
      creneau: creneau,
      delai: delai,
      classe: classe,
      premierCours: premierCours,
      premierCoursPasse: premierCoursPasse,
      creneauChangeLe: creneauChangeLe,
      enseignant: enseignant,
      peutChoisirAutreCreneau: peutChoisirAutreCreneau,
      visibleAccueil: visibleAccueil,
      audience: voulue,
    );
  }

  /// L'etape en cours, nulle quand tout est fait ou que la demande est close.
  EtapeAttente? get courante {
    for (final EtapeAttente e in etapes) {
      if (e.etat == EtatEtapeAttente.enCours) return e;
    }
    return null;
  }

  /// Vrai quand la demande est close (refusee, retiree, autre).
  bool get close =>
      cas == CasAttente.refusee ||
      cas == CasAttente.retiree ||
      cas == CasAttente.close;

  /// Vrai quand les cinq etapes sont franchies.
  bool get toutEstPret =>
      etapes.every((EtapeAttente e) => e.etat == EtatEtapeAttente.fait);

  /// L'etape [numero].
  EtapeAttente etape(int numero) => etapes[numero - 1];

  static List<EtapeAttente> _rangees(Iterable<EtapeAttente> etapes) {
    final List<EtapeAttente> triees = etapes.toList()
      ..sort((EtapeAttente a, EtapeAttente b) => a.numero.compareTo(b.numero));
    return triees;
  }
}

/// Le port du suivi : une entree par demande du foyer connecte.
abstract interface class PortSuiviAttente {
  /// Les suivis, remis a jour a chaque passage d'etape.
  Stream<List<SuiviAttente>> suivre();
}

/// Le port : absent avant le branchement serveur.
final Provider<PortSuiviAttente?> portSuiviAttenteProvider =
    Provider<PortSuiviAttente?>((Ref _) => null);

/// Les suivis du foyer. Sans port, aucun.
final StreamProvider<List<SuiviAttente>> suivisAttenteProvider =
    StreamProvider<List<SuiviAttente>>((Ref ref) {
      final PortSuiviAttente? port = ref.watch(portSuiviAttenteProvider);
      if (port == null) return Stream<List<SuiviAttente>>.value(const []);
      return port.suivre();
    });

/// Ce qu'un enseignant a regle pour les familles de ses classes (S4).
@immutable
class PresentationAuxFamilles {
  /// Cree le reglage.
  const PresentationAuxFamilles({
    required this.montre,
    required this.confirme,
    this.paysOrigine,
    this.paysResidence,
    this.mot,
  });

  /// Montre sa photo, ses pays et son mot aux familles de ses classes.
  final bool montre;

  /// Vrai quand l'enseignant a lui-meme confirme son choix.
  final bool confirme;

  /// Pays d'origine (code ISO), nul si non declare.
  final String? paysOrigine;

  /// Pays de residence (code ISO), nul si non declare.
  final String? paysResidence;

  /// Son mot de presentation (500 caracteres au plus).
  final String? mot;
}

/// Longueur maximale du mot de presentation (miroir de la contrainte serveur).
const int longueurMaxMotPresentation = 500;

/// Le port du reglage de l'enseignant.
abstract interface class PortPresentationEnseignant {
  /// Lit le reglage de l'enseignant connecte.
  Future<PresentationAuxFamilles> lire();

  /// Enregistre le reglage de l'enseignant connecte.
  Future<void> regler({
    required bool montre,
    String? paysOrigine,
    String? paysResidence,
    String? mot,
  });
}

/// Le port du reglage : absent avant le branchement serveur.
final Provider<PortPresentationEnseignant?> portPresentationEnseignantProvider =
    Provider<PortPresentationEnseignant?>((Ref _) => null);

/// Le reglage de l'enseignant connecte. Sans port, une erreur.
final FutureProvider<PresentationAuxFamilles> presentationEnseignantProvider =
    FutureProvider<PresentationAuxFamilles>((Ref ref) {
      final PortPresentationEnseignant? port = ref.watch(
        portPresentationEnseignantProvider,
      );
      if (port == null) {
        return Future<PresentationAuxFamilles>.error(
          StateError('port de presentation absent'),
        );
      }
      return port.lire();
    });
