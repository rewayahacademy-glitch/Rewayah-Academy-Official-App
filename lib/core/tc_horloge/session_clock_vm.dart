import 'package:flutter/foundation.dart';

import 'fenetre_seance.dart';

export 'fenetre_seance.dart' show FenetreSeance, PhaseSeance;

/// Une heure prete a lire, dans un fuseau donne.
///
/// **Tout est deja rendu.** `heureLocaleRendue` et `dateLocaleRendue` sont des
/// chaines calculees en amont, jamais recalculees par un widget : le depot n'a
/// ni `timezone`, ni `tz`, ni `intl` dans `pubspec.yaml`, et `pubspec.yaml` est
/// gele (decision `D-11`). Une conversion IANA cote client est aujourd'hui
/// **impossible**, et c'est tres bien ainsi : `public.instant_creneau()` sait
/// deja le faire, et la recoder rejouerait le bug des sept jours d'ecart entre
/// Paris et Conakry corrige par la migration `0006`.
///
/// `libelleVille` est lisible : « Riyad », « Conakry ». **Jamais « UTC+3 ».**
@immutable
class HorlogeAffichee {
  /// Cree une heure affichable.
  const HorlogeAffichee({
    required this.fuseauIana,
    required this.libelleVille,
    required this.heureLocaleRendue,
    required this.dateLocaleRendue,
  });

  /// L'identifiant IANA, par exemple `Asia/Riyadh`.
  final String fuseauIana;

  /// Le nom lisible de la ville ou de la zone, par exemple `Riyad`.
  final String libelleVille;

  /// L'heure, deja convertie et formatee, par exemple `18:00`.
  final String heureLocaleRendue;

  /// La date, deja convertie et formatee, par exemple `Lundi 21 septembre`.
  final String dateLocaleRendue;

  @override
  bool operator ==(Object other) =>
      other is HorlogeAffichee &&
      other.fuseauIana == fuseauIana &&
      other.libelleVille == libelleVille &&
      other.heureLocaleRendue == heureLocaleRendue &&
      other.dateLocaleRendue == dateLocaleRendue;

  @override
  int get hashCode => Object.hash(
    fuseauIana,
    libelleVille,
    heureLocaleRendue,
    dateLocaleRendue,
  );
}

/// A quelle distance se trouve une transition d'heure ete/hiver.
enum EcheanceDst {
  /// Trente jours : la premiere anticipation.
  j30,

  /// Sept jours.
  j7,

  /// La veille.
  j1,
}

/// L'avertissement de changement d'heure.
///
/// **Le widget ne calcule rien.** Il recoit deux heures deja rendues et une
/// echeance ; il ne connait ni les regles IANA, ni la date de transition d'un
/// fuseau. C'est la consigne explicite de la mission d'Agent A.
@immutable
class NoticeDst {
  /// Cree une notice.
  const NoticeDst({
    required this.transitionUtc,
    required this.fuseauConcerne,
    required this.heureAvantRendue,
    required this.heureApresRendue,
    required this.echeance,
  });

  /// L'instant UTC de la transition.
  final DateTime transitionUtc;

  /// Le fuseau IANA concerne.
  final String fuseauConcerne;

  /// L'heure du cours avant la transition, deja rendue.
  final String heureAvantRendue;

  /// L'heure du cours apres la transition, deja rendue.
  final String heureApresRendue;

  /// A quelle distance on se trouve de la transition.
  final EcheanceDst echeance;

  /// Vrai quand la transition deplace reellement l'heure lue par l'utilisateur.
  ///
  /// Une notice dont les deux heures coincident n'a rien a annoncer : la
  /// transition existe, mais elle ne change pas ce cours-la.
  bool get deplaceLHeure => heureAvantRendue != heureApresRendue;
}

/// Le temps d'une seance, tel que l'interface le lit.
///
/// **C'est la source unique du temps du Teaching Core.** Le depot porte deja
/// trois calculs de temps restant ; celui-ci les unifie derriere une donnee
/// unique plutot que d'en ajouter un quatrieme.
///
/// Cinq regles portees par ce type :
///
/// 1. **Aucun offset code en dur.** Les conversions arrivent rendues, dans
///    [horlogeUtilisateur] et [horlogeContrepartie].
/// 2. [restant] derive de [calculeeAUtc], **pas de l'horloge de l'appareil**.
///    C'est pour cela que `calculeeAUtc` est un champ : une vue qui lirait
///    `DateTime.now()` mentirait des que l'appareil est a l'heure approximative.
/// 3. `phase == prolongee` implique `restant == null` : **aucun compte a
///    rebours negatif**.
/// 4. `phase == attenteAvantT0` : **aucun temps academique consomme**.
/// 5. [horlogeContrepartie] vaut `null` quand les deux fuseaux coincident : on
///    n'affiche pas deux fois la meme heure.
@immutable
class SessionClockVM {
  /// Cree une horloge de seance.
  ///
  /// Le constructeur canonique ne derive rien : il transporte ce que le port a
  /// resolu. Pour deriver la phase et le restant d'une fenetre, voir
  /// [SessionClockVM.depuisFenetre].
  const SessionClockVM({
    required this.debutUtc,
    required this.finPrevueUtc,
    required this.joinOpensAtUtc,
    required this.fenetreAcces,
    required this.graceApresFin,
    required this.horlogeUtilisateur,
    required this.phase,
    required this.rejoindreOuvert,
    required this.calculeeAUtc,
    this.sessionId,
    this.horlogeContrepartie,
    this.restant,
    this.noticeDst,
  }) : assert(
         phase != PhaseSeance.prolongee || restant == null,
         'une prolongation n affiche jamais un compte a rebours',
       ),
       assert(
         phase != PhaseSeance.terminee || restant == null,
         'une seance terminee n a plus de temps restant',
       ),
       assert(
         restant == null || restant >= Duration.zero,
         'un temps restant negatif est un defaut, pas un affichage',
       );

  /// Derive l'horloge d'une fenetre a un instant serveur donne.
  ///
  /// **La seule fabrique autorisee a decider d'une phase.** Elle ne convertit
  /// aucun fuseau : elle recoit les horloges deja rendues et ne fait que de
  /// l'arithmetique sur des instants UTC.
  factory SessionClockVM.depuisFenetre({
    required FenetreSeance fenetre,
    required DateTime maintenantServeurUtc,
    required HorlogeAffichee horlogeUtilisateur,
    String? sessionId,
    HorlogeAffichee? horlogeContrepartie,
    bool connecte = false,
    bool? seanceOuverte,
    NoticeDst? noticeDst,
  }) {
    final PhaseSeance phase = fenetre.phaseA(
      maintenantServeurUtc,
      connecte: connecte,
      seanceOuverte: seanceOuverte,
    );
    final Duration? restant = fenetre.restantA(
      maintenantServeurUtc,
      seanceOuverte: seanceOuverte,
    );
    return SessionClockVM(
      sessionId: sessionId,
      debutUtc: fenetre.debutUtc,
      finPrevueUtc: fenetre.finPrevueUtc,
      joinOpensAtUtc: fenetre.joinOpensAtUtc,
      fenetreAcces: fenetre.fenetreAcces,
      graceApresFin: fenetre.graceApresFin,
      horlogeUtilisateur: horlogeUtilisateur,
      // Deux fuseaux identiques ne donnent qu'une horloge : afficher deux fois
      // la meme heure ferait croire a une difference qui n'existe pas.
      horlogeContrepartie:
          horlogeContrepartie == null ||
              horlogeContrepartie.fuseauIana == horlogeUtilisateur.fuseauIana
          ? null
          : horlogeContrepartie,
      phase: phase,
      restant: restant != null && restant.isNegative ? Duration.zero : restant,
      rejoindreOuvert: fenetre.rejoindreOuvertA(
        maintenantServeurUtc,
        seanceOuverte: seanceOuverte,
      ),
      noticeDst: noticeDst,
      calculeeAUtc: maintenantServeurUtc,
    );
  }

  /// Identifiant de la seance, `null` si l'occurrence n'est pas materialisee.
  final String? sessionId;

  /// Debut prevu, en UTC.
  final DateTime debutUtc;

  /// Fin prevue, en UTC.
  final DateTime finPrevueUtc;

  /// Ouverture de la salle, soit `debutUtc - fenetreAcces`.
  final DateTime joinOpensAtUtc;

  /// La fenetre d'acces. Defaut vise 20 minutes, **configurable**, jamais ecrite
  /// en dur cote client.
  final Duration fenetreAcces;

  /// De combien la seance reste joignable apres sa fin prevue.
  final Duration graceApresFin;

  /// L'heure de la personne qui regarde.
  final HorlogeAffichee horlogeUtilisateur;

  /// L'heure de l'enseignant vue par l'eleve, ou l'heure de reference du groupe
  /// vue par l'enseignant. `null` quand les deux fuseaux coincident.
  final HorlogeAffichee? horlogeContrepartie;

  /// Le moment de la seance.
  final PhaseSeance phase;

  /// Le temps restant avant le debut, ou avant la fin si le cours est en cours.
  /// `null` des la prolongation.
  final Duration? restant;

  /// Vrai quand il faut proposer « Rejoindre ».
  final bool rejoindreOuvert;

  /// L'avertissement de changement d'heure, quand il y en a un.
  final NoticeDst? noticeDst;

  /// L'instant serveur de reference. **Jamais `DateTime.now()` seul.**
  final DateTime calculeeAUtc;

  /// Vrai quand le cours se tient, prolongation comprise.
  bool get enDirect =>
      phase == PhaseSeance.enCours || phase == PhaseSeance.prolongee;

  /// La duree prevue de la seance.
  Duration get duree => finPrevueUtc.difference(debutUtc);

  /// La meme horloge, derivee a un autre instant serveur (Mes classes,
  /// 30/10/2026) : la phase, le restant et « Rejoindre » recalcules sur la
  /// meme fenetre, sans relire le serveur. L'instant vient de
  /// [calculeeAUtc] plus le temps ecoule depuis la lecture, jamais de
  /// l'horloge de l'appareil (`horloge_vivante.dart`). Pour une horloge lue
  /// par `horlogeDepuisLigne`, qui ne pose ni connexion ni ouverture forcee.
  SessionClockVM aLInstant(DateTime maintenantServeurUtc) =>
      SessionClockVM.depuisFenetre(
        fenetre: FenetreSeance(
          debutUtc: debutUtc,
          finPrevueUtc: finPrevueUtc,
          fenetreAcces: fenetreAcces,
          graceApresFin: graceApresFin,
        ),
        maintenantServeurUtc: maintenantServeurUtc,
        horlogeUtilisateur: horlogeUtilisateur,
        sessionId: sessionId,
        horlogeContrepartie: horlogeContrepartie,
        noticeDst: noticeDst,
      );
}
