// Donnees fictives de la salle de seance (vague Classe, plan de code section 3).
//
// Aucun appel serveur (consigne K-28) : une seule source pour le compteur,
// le panneau Eleves et le recapitulatif de fin (I-6). Les contenus (noms,
// support) sont des contenus de demonstration, pas des libelles d'interface.

import '../../core/tc_bibliotheque/catalogue_local.dart';
import '../../core/tc_bibliotheque/library_resource.dart';
import '../../core/tc_classe/roster_classe_vm.dart';
import '../../core/tc_groupe/group_summary_vm.dart' show TitreEnseignant;
import '../../core/tc_telechargement/port_etat_offline.dart';
import '../salle_seance/depuis_salle.dart';
import '../salle_seance/resultat_seance.dart';
import '../salle_seance/vue_seance.dart';
import 'enseignant_demo.dart';

/// Les etats montrables de la salle de demonstration.
enum EtatDemoSalle {
  /// Seance en cours, sans visite.
  repos,

  /// Le tuteur de Mariam observe.
  visite,

  /// L'enseignante n'a rien partage.
  rienPartage,

  /// Panneau Eleves ouvert (enseignant), avec la file de recitation.
  eleves,

  /// Appel discret recu (eleve) : « {titre et nom} vous appelle » (EN-9).
  appel,

  /// Panneau Supports ouvert (enseignant).
  supports,

  /// Seance terminee.
  fin,

  // --- Ecrans de secours (lot CL-7) ---

  /// Reseau faible, room connectee (P06).
  reseauFaible,

  /// Reconnexion en cours (P05).
  reconnexion,

  /// Connexion retablie (P05.6).
  retablie,

  /// Reconnexion impossible (P05.8).
  echec,

  /// Hors ligne confirme (P05.8).
  horsLigne,

  /// Micro bloque par le systeme (P09).
  microBloque,

  /// Camera interdite par le profil (P10).
  cameraInterdite,

  /// Heure de fin passee (P11).
  prolongee,

  /// Acces retire par le serveur (P12).
  accesRetire,
}

/// Les situations nommees du chantier Supports et tableau (TB-1b) : une par
/// vue de l'arborescence du plan V2 §17 (SAL-00 a END-01), plus les etats du
/// §12 qui n'y ont pas de vue propre. Le nom suit l'identifiant du plan.
///
/// `/demo/salle?role=…&tb=<situation>`. A TB-1b, chaque situation porte ses
/// DONNEES (affichage, support a page fixe, tableau libre, droits d'ecrire)
/// et s'ouvre dans la salle existante, sans disposition nouvelle : chaque
/// etape TB rendra la sienne.
enum SituationTb {
  /// SAL-00 : salle, connexion et personnes.
  sal00('SAL-00'),

  /// PED-01 et §12 « Aucun support » : le tableau libre.
  ped01('PED-01'),

  /// PED-02 : support seul.
  ped02('PED-02'),

  /// PED-03 : support avec notes.
  ped03('PED-03'),

  /// PED-04 et §12 « Tableau seul avec support retenu ».
  ped04('PED-04'),

  /// UI-01 : chrome compact pendant le partage.
  ui01('UI-01'),

  /// UI-02 : salle de bureau developpee.
  ui02('UI-02'),

  /// UI-03 : focus local (l'etat local `agrandi` existant).
  ui03('UI-03'),

  /// VIS-01 : barre de visio revelee.
  vis01('VIS-01'),

  /// CTX-01 : contexte enseignant et personnes.
  ctx01('CTX-01'),

  /// CTX-02 : informations de controle.
  ctx02('CTX-02'),

  /// CMD-01 : commandes pedagogiques.
  cmd01('CMD-01'),

  /// CMD-02 : options couleur et epaisseur.
  cmd02('CMD-02'),

  /// CMD-03 : ecriture active, palette courte.
  cmd03('CMD-03'),

  /// LIB-01 : catalogue et recherche.
  lib01('LIB-01'),

  /// LIB-02 : previsualisation personnelle.
  lib02('LIB-02'),

  /// LIB-03 et §12 « Chargement avant presentation ».
  lib03('LIB-03'),

  /// LIB-04 et §12 « Recherche catalogue vide ».
  lib04('LIB-04'),

  /// PER-01 : participants et autorisations.
  per01('PER-01'),

  /// DLG-01 et §12 « Effacement de page ».
  dlg01('DLG-01'),

  /// ERR-01 et §12 « Synchronisation interrompue ».
  err01('ERR-01'),

  /// ERR-02 et §12 « Recuperation d'etat ».
  err02('ERR-02'),

  /// ERR-03 et §12 « Sauvegarde en echec ».
  err03('ERR-03'),

  /// END-01 : quitter ou terminer la seance.
  end01('END-01'),

  // --- Etats du §12 sans vue propre au §17 ---

  /// §12 « Presentation en chargement cote eleve ».
  supportArrive('§12'),

  /// §12 « Ressource indisponible ».
  ressourceIndisponible('§12'),

  /// §12 « Autorisation de dessin ».
  autorisationEcrire('§12'),

  /// §12 « Droit retire ».
  droitRetire('§12'),

  /// §12 « Effacement du tableau libre ».
  effacementTableau('§12');

  const SituationTb(this.reference);

  /// L'identifiant du plan V2 (§17), ou « §12 ».
  final String reference;

  /// L'enseignant seulement : bibliotheque, participants et autorisations,
  /// effacements, ouverture du support, sauvegarde en echec (« pas d'alerte
  /// inutile » cote eleve, §12).
  static const Set<SituationTb> _enseignantSeul = <SituationTb>{
    lib01,
    lib02,
    lib03,
    lib04,
    per01,
    dlg01,
    err03,
    effacementTableau,
  };

  /// L'eleve seulement : le support qui arrive chez le destinataire.
  static const Set<SituationTb> _eleveSeul = <SituationTb>{supportArrive};

  /// La situation a-t-elle un sens pour [role] ? Une commande d'un autre
  /// role n'est jamais proposee (00_REPRISE §8).
  bool concerne(RoleSeance role) => role == RoleSeance.enseignant
      ? !_eleveSeul.contains(this)
      : !_enseignantSeul.contains(this);
}

/// Les situations Supports et tableau proposees pour [role], dans l'ordre.
List<SituationTb> situationsTb(RoleSeance role) => <SituationTb>[
  for (final SituationTb s in SituationTb.values)
    if (s.concerne(role)) s,
];

/// Les donnees exactes de la demonstration.
abstract final class DonneesSeanceDemo {
  static const String classe = 'Classe An-Nour';

  /// L'enseignant de la salle, le meme que sur Aujourd'hui et l'Espace
  /// Classe (E16) : « Sayyid Ibrahim » par defaut, pour tous les roles.
  static String enseignantPour(TitreEnseignant titre) =>
      DonneesEnseignantDemo.nomAffiche(titre);

  /// Le nom par defaut, « Sayyid Ibrahim ».
  static final String enseignante = enseignantPour(TitreEnseignant.sayyid);

  /// L'identifiant fictif de la Classe An-Nour (rail enseignant).
  static const String groupeDemo = 'demo-an-nour';
  static const String eleveCourant = 'Mariam';

  /// Les trois inscrits. « Eleves 1/3 » : seule Mariam est connectee.
  static const List<EleveSeance> eleves = <EleveSeance>[
    EleveSeance(
      prenom: 'Mariam',
      statut: StatutEleveSeance.connecte,
      fiche: FicheEleveSeance(
        // L'intitule « Niveau » est celui de la fiche : la valeur seule ici.
        niveau: '1',
        objectifActuel: 'Chapitre 1 (les bonnes manières)',
        derniereSeance: '21 sept. 2026',
        aReprendre: 'Pages 24 à 26',
        presenceRecente: '3 séances cette semaine',
        travailActuel: 'Écoute de la récitation',
      ),
    ),
    // Fiches fictives de Yusuf et Aïcha : leurs lignes (repliees sur les
    // images) se deplient donc vraiment en demonstration.
    EleveSeance(
      prenom: 'Yusuf',
      statut: StatutEleveSeance.pasEncoreConnecte,
      fiche: FicheEleveSeance(
        niveau: '1',
        objectifActuel: 'Chapitre 1 (les bonnes manières)',
        derniereSeance: '21 sept. 2026',
        aReprendre: 'Pages 20 à 23',
        presenceRecente: '2 séances cette semaine',
        travailActuel: 'Lecture du chapitre',
      ),
    ),
    EleveSeance(
      prenom: 'Aïcha',
      statut: StatutEleveSeance.connexionInterrompue,
      fiche: FicheEleveSeance(
        niveau: '1',
        objectifActuel: 'Chapitre 1 (les bonnes manières)',
        derniereSeance: '21 sept. 2026',
        aReprendre: 'Pages 24 à 26',
        presenceRecente: '3 séances cette semaine',
        travailActuel: 'Écoute de la récitation',
      ),
    ),
  ];

  static const SupportSeance support = SupportSeance(
    chapitre: 'Chapitre 1',
    titre: 'Les bonnes manières en classe',
    // Pas d'encadre : « le professeur » n'est jamais montre a l'eleve (E16).
    encadre: '',
    points: <String>[
      'Écouter avec calme.',
      'Poser des questions poliment.',
      'Respecter les camarades.',
    ],
    page: 1,
    pages: 12,
  );

  /// La version du Chapitre 1 : portee par son detail et par la page fixe.
  static const String _versionChapitre1 = 'v2.0';

  /// Le Chapitre 1, rubrique Reprendre : la seule source de son identifiant,
  /// de son titre, de sa version et de son nombre de pages (`support`).
  static const SupportDisponible chapitre1 = SupportDisponible(
    id: 'demo-chapitre-1',
    surTitre: 'Chapitre 1',
    titre: 'Les bonnes manières',
    detail: 'Support de cours · $_versionChapitre1',
    rubrique: RubriqueSupport.reprendre,
    type: TypeRessource.lecon,
    teinte: 9,
    monogramme: 'BM',
    contenu: support,
  );

  /// Le panneau Supports (CLV-08) : Reprendre, deux Recents, le fonds de la
  /// Classe. « Ouvrir » montre `contenu` dans la salle de demonstration.
  static const List<SupportDisponible> supports = <SupportDisponible>[
    chapitre1,
    SupportDisponible(
      id: 'demo-fiche-memorisation',
      titre: 'Fiche de mémorisation',
      detail: 'PDF · 12 pages · v1.1',
      rubrique: RubriqueSupport.recent,
      teinte: 25,
      monogramme: 'FM',
      contenu: SupportSeance(
        chapitre: 'Chapitre 1',
        titre: 'Fiche de mémorisation',
        encadre: 'Relire chaque règle à voix basse avant la séance.',
        points: <String>[
          'Écouter avant de parler.',
          'Lever la main pour demander la parole.',
          'Remercier le professeur.',
        ],
        page: 1,
        pages: 12,
      ),
    ),
    SupportDisponible(
      id: 'demo-exercices-chapitre-1',
      titre: 'Exercices – Chapitre 1',
      detail: 'PDF · 8 pages · v1.0',
      rubrique: RubriqueSupport.recent,
      teinte: 3,
      monogramme: 'EX',
      contenu: SupportSeance(
        chapitre: 'Chapitre 1',
        titre: 'Exercices – Chapitre 1',
        encadre: 'Associer chaque situation à la bonne manière.',
        points: <String>[
          'Un camarade parle : que fais-tu ?',
          'Tu as une question : que fais-tu ?',
          'Le professeur explique : que fais-tu ?',
        ],
        page: 1,
        pages: 8,
      ),
    ),
    SupportDisponible(
      id: 'demo-bibliotheque-an-nour',
      titre: 'Bibliothèque An-Nour',
      detail: '24 ressources',
      rubrique: RubriqueSupport.classe,
    ),
  ];

  // --- Supports et tableau (TB-1b) : la seule source de toutes les etapes ---

  /// La photo de demonstration d'un inscrit d'An-Nour, lue dans la Classe
  /// de l'Espace enseignant (meme cle, une seule source) ; a defaut, la cle
  /// au meme format. Aucun fichier n'est livre : le rendu retombe sur les
  /// initiales (E5).
  static String _photo(String prenom, String id) {
    for (final ClasseEnseignantDemo c in DonneesEnseignantDemo.classes) {
      if (c.id != 'demo-classe-an-nour') continue;
      for (final EleveEnseignantDemo e in c.eleves) {
        if (e.prenom == prenom && e.photo != null) return e.photo!;
      }
    }
    return 'demo/eleves/$id.png';
  }

  /// La quatrieme inscrite, autorisee a ecrire (planche 8 : « Peut ecrire »
  /// sur sa ligne).
  static const String eleveAutorisee = 'Zaynab';

  /// Les quatre inscrits du chantier, avec photo (K-44) : les trois de la
  /// salle (memes prenoms, statuts et fiches) et Zaynab, connectee, seule
  /// autorisee a ecrire (« Eleves 2/4 »).
  static final List<EleveSeance> elevesTb = <EleveSeance>[
    for (final EleveSeance e in eleves)
      EleveSeance(
        prenom: e.prenom,
        statut: e.statut,
        fiche: e.fiche,
        cleAvatar: _photo(
          e.prenom,
          'demo-eleve-${e.prenom.toLowerCase().replaceAll('ï', 'i')}',
        ),
      ),
    EleveSeance(
      prenom: eleveAutorisee,
      statut: StatutEleveSeance.connecte,
      cleAvatar: _photo(eleveAutorisee, 'demo-eleve-zaynab'),
      peutEcrire: true,
      fiche: const FicheEleveSeance(
        niveau: '1',
        objectifActuel: 'Chapitre 1 (les bonnes manières)',
        derniereSeance: '21 sept. 2026',
        aReprendre: 'Pages 24 à 26',
        presenceRecente: '3 séances cette semaine',
        travailActuel: 'Lecture du chapitre',
      ),
    ),
  ];

  /// Les dimensions canoniques de la page de demonstration : A4 portrait a
  /// 150 points par pouce (1240 x 1754). Fournies par les donnees, jamais
  /// deduites de l'ecran (TB4).
  static const int largeurPage = 1240;
  static const int hauteurPage = 1754;

  /// Le support a page fixe presente : le Chapitre 1 du panneau Supports,
  /// derive de [chapitre1] (meme identifiant, meme titre, meme version, meme
  /// nombre de pages). Une page neutre marquee « Support illustratif » :
  /// aucune page de Coran (TB27).
  static final SupportPageFixe supportPageFixe = SupportPageFixe(
    id: chapitre1.id,
    version: _versionChapitre1,
    titre: chapitre1.titre,
    page: 1,
    total: chapitre1.contenu!.pages,
    largeurCanonique: largeurPage,
    hauteurCanonique: hauteurPage,
    mention: 'Support illustratif',
  );

  // --- Bibliotheque en seance (TB-8) ---

  /// Le support de la demonstration dont l'ouverture echoue : montre LIB-03
  /// (« Ce support ne peut pas etre ouvert. »), jamais une page vide.
  static const String idSupportIndisponible = 'demo-cahier-ecriture';

  /// Les supports de la Bibliotheque unique en demonstration : ceux du
  /// panneau Supports qui ont un contenu (memes identifiants, memes titres)
  /// et un cahier dont le fichier manque. Aucun Coran (TB27).
  static List<LibraryResource> get ressourcesTb => <LibraryResource>[
    for (final SupportDisponible s in supports)
      if (s.contenu != null)
        LibraryResource(
          id: s.id,
          title: s.titre,
          shortTitle: s.titre,
          resourceType: s.type,
          language: 'fr',
          category: 'Bonnes manières',
          accessPolicy: PolitiqueAcces.inscrits,
          offlinePolicy: PolitiqueOffline.surDemande,
          currentVersionId: s.id == chapitre1.id ? _versionChapitre1 : 'v1.0',
          capabilities: const <CapaciteRessource>{
            CapaciteRessource.searchable,
            CapaciteRessource.pageable,
            CapaciteRessource.presentableInClass,
          },
        ),
    const LibraryResource(
      id: idSupportIndisponible,
      title: "Cahier d'écriture",
      shortTitle: "Cahier d'écriture",
      resourceType: TypeRessource.pdf,
      language: 'fr',
      category: 'Bonnes manières',
      accessPolicy: PolitiqueAcces.inscrits,
      offlinePolicy: PolitiqueOffline.surDemande,
      currentVersionId: 'v1.0',
      capabilities: <CapaciteRessource>{
        CapaciteRessource.searchable,
        CapaciteRessource.presentableInClass,
      },
    ),
  ];

  /// Le catalogue de la demonstration : toute la Bibliotheque assignee a la
  /// Classe, les deux Recents du panneau Supports.
  static CatalogueLocal get catalogueTb => CatalogueLocal(
    ressources: ressourcesTb,
    assignationsParGroupe: <String, List<String>>{
      groupeDemo: <String>[for (final LibraryResource r in ressourcesTb) r.id],
    },
    ordreRecents: <String>[
      for (final SupportDisponible s in supports)
        if (s.rubrique == RubriqueSupport.recent) s.id,
    ],
  );

  /// L'etat hors ligne des supports en demonstration : aucun stockage
  /// local (K-28), donc « hors ligne indisponible » pour tous.
  static const PortEtatOffline etatOfflineTb = _EtatOfflineDemo();

  /// Le support a page fixe presente apres « Presenter » : page 1, meme
  /// repere que la page de demonstration, nombre de pages de son contenu.
  static SupportPageFixe pagePresentee(LibraryResource r) {
    int total = 1;
    for (final SupportDisponible s in supports) {
      if (s.id == r.id) total = s.contenu?.pages ?? 1;
    }
    return SupportPageFixe(
      id: r.id,
      version: r.currentVersionId ?? 'v1.0',
      titre: r.title,
      page: 1,
      total: total,
      largeurCanonique: largeurPage,
      hauteurCanonique: hauteurPage,
      mention: 'Support illustratif',
    );
  }

  /// La diapositive d'un support presente, s'il en a une (la capsule de
  /// l'en-tete suit le support partage).
  static SupportSeance? diapositiveDe(String id) {
    for (final SupportDisponible s in supports) {
      if (s.id == id) return s.contenu;
    }
    return null;
  }

  /// Le tableau libre : choix provisoire, meme repere que la page de
  /// demonstration (UX_REVIEW_TB n. 15, une seule valeur, TB-BR-14).
  static const TableauLibre tableauLibre = TableauLibre(
    largeurCanonique: largeurPage,
    hauteurCanonique: hauteurPage,
  );

  /// La vue d'une situation Supports et tableau pour [role].
  ///
  /// Toutes les situations partent de l'etat `repos` (ou `rienPartage`,
  /// `fin`) de la meme demonstration : meme Classe, meme enseignant, memes
  /// inscrits. Seules les donnees du chantier changent.
  ///
  /// Surcharges de demonstration (TB-3, aucun serveur) : [etat] remplace
  /// l'etat de base (la visite du tuteur, pour la notice de l'enfant) ;
  /// [enregistrement] remplace l'enregistrement actif par defaut (inactif
  /// ou inconnu : aucun point rouge).
  static VueSeance vueTb(
    RoleSeance role,
    SituationTb situation, {
    TitreEnseignant titre = TitreEnseignant.sayyid,
    String prenomEleve = eleveCourant,
    EtatDemoSalle? etat,
    EtatEnregistrement enregistrement = EtatEnregistrement.actif,
  }) {
    final bool enseignant = role == RoleSeance.enseignant;
    final VueSeance base = vue(
      role,
      etat ?? etatBaseTb(situation),
      titre: titre,
      prenomEleve: prenomEleve,
    );
    // L'autorisation donnee a l'eleve courant (§12, CMD-02, CMD-03) :
    // une seule ligne « Peut ecrire », la sienne.
    final bool autoriseCourant = switch (situation) {
      SituationTb.autorisationEcrire ||
      SituationTb.cmd02 ||
      SituationTb.cmd03 => true,
      _ => false,
    };
    final List<EleveSeance> inscrits = <EleveSeance>[
      for (final EleveSeance e in elevesTb)
        EleveSeance(
          prenom: e.prenom,
          statut: e.statut,
          fiche: e.fiche,
          cleAvatar: e.cleAvatar,
          peutEcrire: autoriseCourant ? e.prenom == prenomEleve : e.peutEcrire,
        ),
    ];
    final bool sansSupport = switch (situation) {
      SituationTb.ped01 || SituationTb.effacementTableau => true,
      _ => false,
    };
    return base.copyWith(
      eleves: inscrits,
      enregistrement: enregistrement,
      // TB-3 (CTX-02) : la donnee du controle n'existe pas encore (TB-BR-24).
      // Demonstration seulement, dans la situation nommee : « Controle
      // possible », jamais « Controle actif » fabrique.
      controle: situation == SituationTb.ctx02 ? EtatControle.possible : null,
      // CTX-01, CTX-02 : le contexte s'ouvre deplie ; ailleurs, la capsule.
      contexte: switch (situation) {
        SituationTb.ctx01 => ContexteOuvert.enseignant,
        SituationTb.ctx02 => ContexteOuvert.controle,
        _ => ContexteOuvert.aucun,
      },
      tableauLibre: situation == SituationTb.effacementTableau
          ? const TableauLibre(
              largeurCanonique: largeurPage,
              hauteurCanonique: hauteurPage,
              aDesNotes: true,
            )
          : tableauLibre,
      supportPresente: sansSupport ? null : supportPageFixe,
      sansSupportPresente: sansSupport,
      affichage: switch (situation) {
        SituationTb.ped02 => AffichagePartage.support,
        SituationTb.ped04 => AffichagePartage.tableau,
        _ => AffichagePartage.avecNotes,
      },
      panneau: !enseignant
          ? PanneauOuvert.aucun
          : switch (situation) {
              // TB-8 : LIB-01 a LIB-04 partent du catalogue de la
              // Bibliotheque unique ; apercu, ouverture et echec se
              // rejoignent en touchant une carte puis « Presenter ».
              SituationTb.lib01 ||
              SituationTb.lib02 ||
              SituationTb.lib03 ||
              SituationTb.lib04 => PanneauOuvert.ressources,
              SituationTb.per01 ||
              SituationTb.autorisationEcrire ||
              SituationTb.droitRetire => PanneauOuvert.eleves,
              // TB-4 : CMD-01 s'ouvre sur les Commandes.
              SituationTb.cmd01 => PanneauOuvert.commandes,
              _ => PanneauOuvert.aucun,
            },
    );
  }

  /// L'etat existant d'ou part une situation : sans support pour le
  /// tableau libre, la fin existante pour END-01, le repos ailleurs.
  static EtatDemoSalle etatBaseTb(SituationTb situation) => switch (situation) {
    SituationTb.ped01 ||
    SituationTb.effacementTableau => EtatDemoSalle.rienPartage,
    SituationTb.end01 => EtatDemoSalle.fin,
    _ => EtatDemoSalle.repos,
  };

  /// La file de recitation de la demonstration (EN-9).
  static const FileRecitation recitation = FileRecitation(
    actif: 'Mariam',
    suivants: <String>['Yusuf', 'Aïcha'],
  );

  static const FinSeance fin = FinSeance(
    heureFin: '18:45',
    cahierACompleter: true,
  );

  /// La vue d'un role dans un etat.
  ///
  /// Horloge : « 32 min restantes » par defaut ; l'etat visite de
  /// l'enseignant montre « La seance se poursuit. » comme l'image CLV-06.
  /// La vue eleve de la meme visite garde l'horloge en cours, comme CLV-04
  /// (l'eleve n'affiche la suite que depassee, sans duree restante).
  static VueSeance vue(
    RoleSeance role,
    EtatDemoSalle etat, {
    TitreEnseignant titre = TitreEnseignant.sayyid,
    String prenomEleve = eleveCourant,
  }) {
    final bool enseignant = role == RoleSeance.enseignant;
    final String nom = enseignantPour(titre);
    return VueSeance(
      role: role,
      nomClasse: classe,
      nomEnseignant: nom,
      initialesEnseignant: DepuisSalle.initiales(nom),
      prenomEleve: enseignant ? null : prenomEleve,
      horloge:
          (etat == EtatDemoSalle.visite && enseignant) ||
              etat == EtatDemoSalle.prolongee
          ? const HorlogeDepassee()
          : const HorlogeRestante(32),
      connexion: connexion(etat),
      cameraAutorisee: etat != EtatDemoSalle.cameraInterdite,
      microBloque: etat == EtatDemoSalle.microBloque,
      visite: etat == EtatDemoSalle.visite
          ? VisiteSeance(prenomEnfant: prenomEleve, concerneMoi: true)
          : null,
      // La file de recitation (EN-9) : Mariam recite, Yusuf et Aïcha a
      // suivre. Des prenoms seulement (cles de demonstration).
      recitation: enseignant && etat == EtatDemoSalle.eleves
          ? recitation
          : FileRecitation.vide,
      appelRecu: !enseignant && etat == EtatDemoSalle.appel,
      support: etat == EtatDemoSalle.rienPartage ? null : support,
      cameraEnseignantActive: true,
      groupeId: groupeDemo,
      eleves: eleves,
      supports: supports,
      // Acces retire, cote enseignant : la fin CLV-10 avec le cahier (P12.4).
      fin:
          etat == EtatDemoSalle.fin ||
              (etat == EtatDemoSalle.accesRetire && enseignant)
          ? fin
          : null,
      panneau: !enseignant
          ? PanneauOuvert.aucun
          : switch (etat) {
              EtatDemoSalle.eleves => PanneauOuvert.eleves,
              EtatDemoSalle.supports => PanneauOuvert.supports,
              _ => PanneauOuvert.aucun,
            },
      // Le point non lu de la cloche des images CLV-04 et CLV-06 desktop.
      notificationsNonLues: 2,
    );
  }

  /// La connexion montree par un etat de secours (lot CL-7).
  static ConnexionSeance connexion(EtatDemoSalle etat) => switch (etat) {
    EtatDemoSalle.reseauFaible => ConnexionSeance.reseauFaible,
    EtatDemoSalle.reconnexion => ConnexionSeance.reconnexion,
    EtatDemoSalle.retablie => ConnexionSeance.retablie,
    EtatDemoSalle.echec => ConnexionSeance.echec,
    EtatDemoSalle.horsLigne => ConnexionSeance.horsLigne,
    _ => ConnexionSeance.enLigne,
  };

  /// L'issue de l'eleve impose par l'etat, ou `null` (salle ouverte). La
  /// guidee n'a qu'un ecran de fin : son rendu ignore l'issue.
  static IssueSeance? issueEleve(EtatDemoSalle etat) => switch (etat) {
    EtatDemoSalle.fin => IssueSeance.terminee,
    EtatDemoSalle.accesRetire => IssueSeance.accesRetire,
    _ => null,
  };
}

/// TB-8 : l'etat hors ligne de la demonstration, sans aucun stockage.
class _EtatOfflineDemo implements PortEtatOffline {
  const _EtatOfflineDemo();

  @override
  Future<EtatOffline> etatDe(String resourceId) async =>
      EtatOffline.indisponible;

  @override
  Stream<EtatOffline> suivre(String resourceId) =>
      Stream<EtatOffline>.value(EtatOffline.indisponible);

  @override
  Future<void> demanderTelechargement(String resourceId) async {}

  @override
  Future<void> libererCache(String resourceId) async {}
}
