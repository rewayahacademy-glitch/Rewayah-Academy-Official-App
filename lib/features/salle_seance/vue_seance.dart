// La salle de seance unique : ce que chaque role voit.
//
// Toutes les regles de `10_classe/V/01_MATRICE_ROLES.md` (pilotage) vivent
// ICI, en getters purs : les widgets ne decident rien, ils lisent. Ni LiveKit
// ni Supabase : une `VueSeance` se construit depuis `/salle`, depuis
// `/tc/classe` ou depuis la demonstration (`lib/features/demo/seance_demo.dart`).

import 'package:flutter/foundation.dart';

import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_gabarit.dart';
import '../salle/vue_salle.dart';

/// Le role effectif devant l'ecran : colonnes ES, IG et EN de la matrice.
enum RoleSeance {
  /// Eleve en interface standard (CLV-04).
  eleve,

  /// Eleve en Interface guidee (CLV-05), mode `InterfaceMode.enfant`.
  guidee,

  /// Enseignant (CLV-06 a 08, 10).
  enseignant;

  /// Le role du JETON et le mode d'interface lu dans le theme donnent le role
  /// effectif. Tout autre role du jeton (tuteur observateur, controleur,
  /// administration, inconnu) rend `null` : la salle garde son ancien rendu.
  static RoleSeance? resoudre(RoleSalle role, InterfaceMode mode) =>
      switch (role) {
        RoleSalle.enseignant => RoleSeance.enseignant,
        RoleSalle.eleve =>
          mode == InterfaceMode.enfant ? RoleSeance.guidee : RoleSeance.eleve,
        _ => null,
      };

  /// Vrai pour les deux vues d'eleve.
  bool get estEleve => this != RoleSeance.enseignant;
}

/// L'horloge de la seance, vue de l'enseignant seulement.
@immutable
sealed class HorlogeSeance {
  const HorlogeSeance();
}

/// Il reste [minutes] minutes avant l'heure de fin prevue.
final class HorlogeRestante extends HorlogeSeance {
  const HorlogeRestante(this.minutes);
  final int minutes;
}

/// L'heure de fin est passee : « La seance se poursuit. », texte simple.
final class HorlogeDepassee extends HorlogeSeance {
  const HorlogeDepassee();
}

/// L'etat de la connexion de celui qui regarde.
enum ConnexionSeance { enLigne, reconnexion }

/// Statut d'un inscrit pendant la seance. Jamais « present » ni « absent »
/// avant la consolidation par le serveur (I-6).
enum StatutEleveSeance { connecte, pasEncoreConnecte, connexionInterrompue }

/// La fiche d'un eleve, panneau Eleves (CLV-07), enseignant seulement.
@immutable
class FicheEleveSeance {
  const FicheEleveSeance({
    required this.niveau,
    required this.objectifActuel,
    required this.derniereSeance,
    required this.aReprendre,
    required this.presenceRecente,
    required this.travailActuel,
  });

  final String niveau;
  final String objectifActuel;
  final String derniereSeance;
  final String aReprendre;
  final String presenceRecente;
  final String travailActuel;
}

/// Un inscrit de la Classe.
@immutable
class EleveSeance {
  const EleveSeance({required this.prenom, required this.statut, this.fiche});

  final String prenom;
  final StatutEleveSeance statut;
  final FicheEleveSeance? fiche;

  /// Connecte au moins une fois pendant la seance (recapitulatif de fin).
  bool get aEteConnecte => statut != StatutEleveSeance.pasEncoreConnecte;
}

/// Une visite d'observation en cours.
@immutable
class VisiteSeance {
  const VisiteSeance({required this.prenomEnfant, required this.concerneMoi});

  /// Le prenom de l'enfant dont le tuteur observe.
  final String prenomEnfant;

  /// Vrai si l'eleve devant l'ecran est cet enfant. Sans objet pour
  /// l'enseignant, qui voit toujours la notice.
  final bool concerneMoi;
}

/// Le support partage, tel que l'enseignant le montre.
@immutable
class SupportSeance {
  const SupportSeance({
    required this.chapitre,
    required this.titre,
    required this.encadre,
    required this.points,
    required this.page,
    required this.pages,
  });

  final String chapitre;
  final String titre;
  final String encadre;
  final List<String> points;
  final int page;
  final int pages;
}

/// Un support proposable (panneau Supports, CLV-08).
@immutable
class SupportDisponible {
  const SupportDisponible({required this.titre, required this.detail});

  final String titre;
  final String detail;
}

/// Le recapitulatif de fin (CLV-10), enseignant seulement.
@immutable
class FinSeance {
  const FinSeance({required this.heureFin, required this.cahierACompleter});

  final String heureFin;
  final bool cahierACompleter;
}

/// Le panneau ouvert a cote du support (enseignant seulement).
enum PanneauOuvert { aucun, eleves, supports }

/// Une commande du dock, par role (I-4).
enum CommandeDock { micro, camera, agrandir, reseau, quitter }

/// Un compte affiche en haut a droite : celui de la personne devant l'ecran.
@immutable
class CompteSeance {
  const CompteSeance({required this.nom, required this.initiales});

  final String nom;
  final String initiales;
}

/// Tout ce qu'une salle affiche, pour UN role. Immuable et pure.
@immutable
class VueSeance {
  const VueSeance({
    required this.role,
    required this.nomClasse,
    required this.nomEnseignant,
    required this.initialesEnseignant,
    this.prenomEleve,
    this.horloge,
    this.connexion = ConnexionSeance.enLigne,
    this.enregistrementConfirme = true,
    this.visite,
    this.support,
    this.cameraEnseignantActive = true,
    this.cameraAutorisee = true,
    this.signalEnseignant = 3,
    this.eleves = const <EleveSeance>[],
    this.supports = const <SupportDisponible>[],
    this.fin,
    this.panneau = PanneauOuvert.aucun,
    this.notificationsNonLues = 0,
  });

  // --- Reponses retenues aux questions Q1 a Q8 (plan de code section 4) ---
  //
  // Sans reponse du directeur, l'option deja retenue dans les images. Un
  // « non » se change ici, en une ligne.

  /// Q1 : guidee, disques pleins vert (Parler) et violet (Camera).
  static const bool optionQ1 = true;

  /// Q2 : enseignant desktop, carte « Outils d'enseignement » en colonne
  /// droite (CLV-07, 08) ; rangee au-dessus du support sur CLV-06.
  static const bool optionQ2 = true;

  /// Q3 : compte retire du coin haut droit (non : il reste en haut a droite).
  static const bool optionQ3 = false;

  /// Q4 : « Le tuteur de {prenom} observe la seance. » (non : texte de la
  /// spec, « Tuteur de {prenom} observe. »).
  static const bool optionQ4 = false;

  /// Q5 : guidee, texte court « Le cours est enregistre. » (non : texte
  /// complet).
  static const bool optionQ5 = false;

  /// Q6 : zoom local de l'eleve standard, qui ne publie rien.
  static const bool optionQ6 = true;

  /// Q7 : l'eleve standard ne voit jamais la video des autres eleves.
  static const bool optionQ7 = true;

  /// Q8 : guidee desktop, video a cote du support, jamais par-dessus.
  static const bool optionQ8 = true;

  final RoleSeance role;
  final String nomClasse;
  final String nomEnseignant;
  final String initialesEnseignant;

  /// L'eleve devant l'ecran (vues eleve et guidee). `null` pour l'enseignant.
  final String? prenomEleve;

  final HorlogeSeance? horloge;
  final ConnexionSeance connexion;

  /// Le serveur a confirme l'enregistrement (I-1). Sans confirmation, aucune
  /// mention.
  final bool enregistrementConfirme;

  final VisiteSeance? visite;

  /// `null` : rien n'est partage.
  final SupportSeance? support;
  final bool cameraEnseignantActive;

  /// La politique du profil autorise la camera de l'eleve (ADR-009).
  final bool cameraAutorisee;

  /// Barres de signal de la video de l'enseignant (0 a 3), lues seulement
  /// par l'enseignant.
  final int signalEnseignant;

  /// Les inscrits : source unique du compteur, du panneau et du
  /// recapitulatif (I-6).
  final List<EleveSeance> eleves;
  final List<SupportDisponible> supports;

  /// Non nul : la seance est finie.
  final FinSeance? fin;
  final PanneauOuvert panneau;

  /// Notifications non lues de la personne devant l'ecran : le point de la
  /// cloche (CLV-04, CLV-06 desktop). La guidee n'a pas de cloche.
  final int notificationsNonLues;

  bool get _enseignant => role == RoleSeance.enseignant;
  bool get _guidee => role == RoleSeance.guidee;
  bool get estFinie => fin != null;

  // --- En-tete (matrice section 1, I-9) ---

  /// « Seance en direct » ou « Ma seance ».
  String get titre =>
      _guidee ? t.salle.seance.titreGuidee : t.salle.seance.titre;

  /// La ligne d'etat sous le titre, ou `null` (guidee : aucun sous-titre).
  ///
  /// Eleve : « Classe · Enseignant », et « La seance se poursuit. » en texte
  /// simple apres l'heure de fin. Enseignant : « Classe · 32 min restantes »
  /// ou « Classe · La seance se poursuit. », jamais son propre nom.
  String? get ligneEtat {
    switch (role) {
      case RoleSeance.guidee:
        return null;
      case RoleSeance.eleve:
        final String base = t.salle.seance.ligne(
          debut: nomClasse,
          fin: nomEnseignant,
        );
        return horloge is HorlogeDepassee
            ? t.salle.seance.ligne(debut: base, fin: t.salle.seance.sePoursuit)
            : base;
      case RoleSeance.enseignant:
        final String? suite = switch (horloge) {
          HorlogeRestante(:final int minutes) =>
            t.salle.seance.minutesRestantes(minutes: minutes),
          HorlogeDepassee() => t.salle.seance.sePoursuit,
          null => null,
        };
        return suite == null
            ? nomClasse
            : t.salle.seance.ligne(debut: nomClasse, fin: suite);
    }
  }

  /// La duree restante n'est lue que par l'enseignant.
  bool get voitDureeRestante => _enseignant;

  /// Le libelle de la pastille de connexion.
  String get texteConnexion => switch (connexion) {
    ConnexionSeance.enLigne => t.salle.seance.enLigne,
    ConnexionSeance.reconnexion => t.salle.seance.reconnexion,
  };

  /// Le compte en haut a droite : TOUJOURS celui de la personne devant
  /// l'ecran (I-9). L'enseignant ne voit jamais le compte d'un eleve.
  CompteSeance get compte => _enseignant || prenomEleve == null
      ? CompteSeance(nom: nomEnseignant, initiales: initialesEnseignant)
      : CompteSeance(
          nom: prenomEleve!,
          initiales: prenomEleve!.substring(0, 1).toUpperCase(),
        );

  /// Guidee : ni theme, ni cloche, ni reglages, ni menu de compte.
  bool get voitReglagesEnTete => !_guidee;

  // --- Mention et notice (I-1, I-2) ---

  /// Le texte de la mention d'enregistrement, ou `null` (non confirme, fin).
  String? get texteMention {
    if (!enregistrementConfirme || estFinie) return null;
    return _guidee && optionQ5
        ? t.salle.seance.coursEnregistreCourt
        : t.salle.bandeauPermanent;
  }

  /// La visite est-elle annoncee a ce role ? Toujours a l'enseignant ;
  /// a un eleve seulement si c'est son parent qui observe.
  bool get visiteVisible =>
      visite != null &&
      texteMention != null &&
      (_enseignant || visite!.concerneMoi);

  /// La notice de visite, qui remplace le texte de la mention, ou `null`.
  String? get texteNotice {
    if (!visiteVisible) return null;
    return switch (role) {
      RoleSeance.eleve => t.salle.seance.votreParentObserve,
      RoleSeance.guidee => t.salle.seance.tonParentObserve,
      RoleSeance.enseignant =>
        optionQ4
            ? t.salle.seance.leTuteurDeObserve(prenom: visite!.prenomEnfant)
            : t.salle.seance.tuteurDeObserve(prenom: visite!.prenomEnfant),
    };
  }

  /// Le point clignote pendant une visite visible, jamais en guidee (S l.781).
  bool get pointClignote => visiteVisible && !_guidee;

  /// L'icone oeil accompagne la notice en guidee seulement.
  bool get voitOeilNotice => visiteVisible && _guidee;

  // --- Commandes reservees a l'enseignant (I-4, I-6, I-10) ---

  bool get voitCompteurEleves => _enseignant;
  bool get voitBoutonsPanneaux => _enseignant;
  bool get voitOutils => _enseignant && support != null;
  bool get voitSignalVideo => _enseignant;

  /// Connectes maintenant, derive de la liste (I-6).
  int get connectes => eleves
      .where((EleveSeance e) => e.statut == StatutEleveSeance.connecte)
      .length;

  /// Inscrits de la Classe.
  int get inscrits => eleves.length;

  /// « Eleves 1/3 », ou `null` hors enseignant.
  String? get compteurEleves => _enseignant
      ? t.salle.seance.compteurEleves(connectes: connectes, inscrits: inscrits)
      : null;

  /// Connectes au moins une fois (recapitulatif de fin, meme source).
  int get connectesAuMoinsUneFois =>
      eleves.where((EleveSeance e) => e.aEteConnecte).length;

  // --- Barre du support (I-5, I-7) ---

  /// Fleches ‹ 1/12 › qui changent la page de tous : enseignant, desktop.
  bool voitPaginationActive(Gabarit gabarit) =>
      _enseignant && support != null && gabarit == Gabarit.desktop;

  /// « 1 / 12 » en lecture seule : eleve standard, desktop.
  bool voitIndicateurPage(Gabarit gabarit) =>
      role == RoleSeance.eleve && support != null && gabarit == Gabarit.desktop;

  /// Zoom local : enseignant, et eleve standard si Q6 ; jamais en guidee.
  bool voitZoomLocal(Gabarit gabarit) =>
      support != null &&
      gabarit == Gabarit.desktop &&
      (_enseignant || (role == RoleSeance.eleve && optionQ6));

  /// Le dock, dans l'ordre (I-4).
  List<CommandeDock> get commandesDock => switch (role) {
    RoleSeance.enseignant => const <CommandeDock>[
      CommandeDock.micro,
      CommandeDock.camera,
      CommandeDock.reseau,
      CommandeDock.quitter,
    ],
    RoleSeance.eleve || RoleSeance.guidee => <CommandeDock>[
      CommandeDock.micro,
      if (cameraAutorisee) CommandeDock.camera,
      CommandeDock.agrandir,
      CommandeDock.quitter,
    ],
  };

  /// Copie modifiee.
  VueSeance copyWith({
    RoleSeance? role,
    HorlogeSeance? horloge,
    bool sansHorloge = false,
    VisiteSeance? visite,
    bool sansVisite = false,
    SupportSeance? support,
    bool sansSupport = false,
    bool? enregistrementConfirme,
    bool? cameraAutorisee,
    List<EleveSeance>? eleves,
    FinSeance? fin,
    PanneauOuvert? panneau,
  }) => VueSeance(
    role: role ?? this.role,
    nomClasse: nomClasse,
    nomEnseignant: nomEnseignant,
    initialesEnseignant: initialesEnseignant,
    prenomEleve: prenomEleve,
    horloge: sansHorloge ? null : horloge ?? this.horloge,
    connexion: connexion,
    enregistrementConfirme:
        enregistrementConfirme ?? this.enregistrementConfirme,
    visite: sansVisite ? null : visite ?? this.visite,
    support: sansSupport ? null : support ?? this.support,
    cameraEnseignantActive: cameraEnseignantActive,
    cameraAutorisee: cameraAutorisee ?? this.cameraAutorisee,
    signalEnseignant: signalEnseignant,
    eleves: eleves ?? this.eleves,
    supports: supports,
    fin: fin ?? this.fin,
    panneau: panneau ?? this.panneau,
    notificationsNonLues: notificationsNonLues,
  );
}
