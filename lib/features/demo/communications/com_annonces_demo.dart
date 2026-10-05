// La demonstration de la voie COM-ANN (centre de notifications partage et
// annonces de Classe) : `/demo/communications?voie=annonces&role=...`.
//
// **Jamais en production** : la route n'existe que si
// `environnementAutoriseDemo` l'autorise (`routesDemoCommunications`), et les
// doubles de ce fichier ne sont poses que dans la portee de la page de
// demonstration (K-28) ; les fournisseurs de l'application gardent leurs
// ports neutres.
//
// Sans role : le choix du role. Avec un role : la VRAIE `NotificationsPage`,
// remplie du catalogue de la spec section 13.2 pour ce role (fixtures de la
// section 26 : une notification urgente, une annonce). Avec `classe=...` en
// plus : l'Espace Classe de demonstration, ou se pose le VRAI emplacement
// `AnnoncesDeClasse` ; c'est la que mene « Ouvrir la Classe » (R-COM-12).
//
// COM-ANN-2 : avec `role=admin&ecran=administration&onglet=...`, la VRAIE
// Administration des communications dans la VRAIE coquille Admin, sur des
// fixtures marquees « Démonstration » (annonces, regles de portee de la spec
// section 13.4 seulement, file de moderation) ; avec
// `role=enseignant&ecran=publier`, le VRAI publieur limite a la Classe.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';

import '../../../core/admin/admin_domaine.dart';
import '../../../core/capacites/capacite_indisponible.dart';
import '../../../core/capacites/port_notifications.dart';
import '../../../core/communications/capacites_communication.dart';
import '../../../core/communications/modeles_communication.dart';
import '../../../core/communications/moderation.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/admin_shell.dart';
import '../../../core/widgets/lien_fleche.dart';
import '../../../core/widgets/page_shell.dart';
import '../../com_annonces/administration_communications_page.dart';
import '../../com_annonces/annonces_de_classe.dart';
import '../../com_annonces/file_moderation.dart';
import '../../com_annonces/port_annonces.dart';
import '../../com_annonces/port_regles_audience.dart';
import '../../com_annonces/publier_annonce_classe_page.dart';
import '../../notifications/notifications_page.dart';
import 'com_messages_demo.dart';
import 'demo_communications_page.dart';

/// La demonstration de la voie COM-ANN.
class ComAnnoncesDemo extends StatefulWidget {
  /// Cree la demonstration de la voie.
  const ComAnnoncesDemo({super.key, this.role, this.maintenant});

  /// Le role mis en scene (`?role=`), nul si l'adresse n'en donne pas.
  final RoleDemoCommunications? role;

  /// L'instant de reference des dates ; par defaut, maintenant.
  final DateTime? maintenant;

  @override
  State<ComAnnoncesDemo> createState() => _ComAnnoncesDemoState();
}

/// L'adresse de l'Espace Classe de demonstration de [classeId], pour [role].
String adresseClasseDemo(RoleDemoCommunications role, String classeId) => Uri(
  path: Routes.demoCommunications,
  queryParameters: <String, String>{
    'voie': VoieDemoCommunications.annonces.name,
    'role': role.name,
    'classe': classeId,
  },
).toString();

/// Le libelle d'un role de la demonstration.
String libelleRoleDemo(RoleDemoCommunications role) {
  final r = t.com.annonces.demo.roles;
  return switch (role) {
    RoleDemoCommunications.tuteur => r.tuteur,
    RoleDemoCommunications.enseignant => r.enseignant,
    RoleDemoCommunications.adulte => r.adulte,
    RoleDemoCommunications.admin => r.admin,
    RoleDemoCommunications.controleur => r.controleur,
  };
}

/// Les identifiants des Classes de demonstration.
abstract final class ClassesDemoAnnonces {
  /// La Classe An-Nour (famille).
  static const String nour = 'demo-classe-nour';

  /// La Classe Al-Fajr (eleve adulte).
  static const String fajr = 'demo-classe-fajr';

  /// Le libelle d'une Classe de demonstration, ou `null`.
  static String? libelle(String id) => switch (id) {
    nour => t.com.annonces.demo.classeNour,
    fajr => t.com.annonces.demo.classeFajr,
    _ => null,
  };
}

/// Les annonces de demonstration de [role], par Classe.
Map<String, List<AnnonceClasse>> annoncesDemo(
  RoleDemoCommunications role,
  DateTime maintenant,
) {
  final f = t.com.annonces.demo.f;
  final Participant enseignante = Participant(
    id: 'demo-enseignante',
    nomAffiche: t.com.annonces.demo.enseignante,
    fonction: t.com.annonces.demo.enseignante,
  );
  AnnonceClasse annonce({
    required String id,
    required String classeId,
    required String titre,
    required String texte,
    required Duration il,
  }) => AnnonceClasse(
    id: id,
    titre: titre,
    texte: texte,
    publieeLe: maintenant.subtract(il),
    auteur: enseignante,
    classe: ObjetLie(
      type: TypeObjetLie.classe,
      id: classeId,
      libelle: ClassesDemoAnnonces.libelle(classeId)!,
      destination: adresseClasseDemo(role, classeId),
    ),
  );
  return switch (role) {
    RoleDemoCommunications.tuteur => <String, List<AnnonceClasse>>{
      ClassesDemoAnnonces.nour: <AnnonceClasse>[
        annonce(
          id: 'demo-annonce-nour',
          classeId: ClassesDemoAnnonces.nour,
          titre: f.annonceNourTitre,
          texte: f.annonceNourTexte,
          il: const Duration(hours: 3),
        ),
      ],
    },
    RoleDemoCommunications.adulte => <String, List<AnnonceClasse>>{
      ClassesDemoAnnonces.fajr: <AnnonceClasse>[
        annonce(
          id: 'demo-annonce-fajr',
          classeId: ClassesDemoAnnonces.fajr,
          titre: f.annonceFajrTitre,
          texte: f.annonceFajrTexte,
          il: const Duration(hours: 5),
        ),
      ],
    },
    RoleDemoCommunications.enseignant ||
    RoleDemoCommunications.admin ||
    RoleDemoCommunications.controleur => const <String, List<AnnonceClasse>>{},
  };
}

/// Le catalogue de demonstration de [role] (spec section 13.2), la plus
/// recente d'abord. Aucune destination vers une page a session : une
/// destination de demonstration reste dans les adresses de demonstration
/// (le fil des Messages, la Journee de demonstration de l'enseignant...),
/// une notification sans destination ouvre son detail, une annonce ouvre
/// l'Espace Classe de demonstration. Une « Action requise » a toujours une
/// destination (revue COM-R, R-06).
List<NotificationTuteur> notificationsDemo(
  RoleDemoCommunications role,
  DateTime maintenant,
) {
  final f = t.com.annonces.demo.f;
  NotificationTuteur n(
    String id,
    String titre,
    Duration il,
    TypeNotification type,
    NiveauAttention niveau, {
    bool lue = false,
    bool mention = false,
    String? texte,
    String? annonceId,
    String? destination,
  }) => NotificationTuteur(
    id: id,
    titre: titre,
    date: maintenant.subtract(il),
    type: type,
    niveau: niveau,
    lue: lue,
    mention: mention,
    texte: texte,
    annonceId: annonceId,
    destination: destination,
  );
  const Duration h1 = Duration(hours: 1);
  const Duration h3 = Duration(hours: 3);
  const Duration h2 = Duration(hours: 2);
  const Duration h4 = Duration(hours: 4);
  const Duration h5 = Duration(hours: 5);
  const Duration h6 = Duration(hours: 6);
  const Duration j1 = Duration(days: 1);
  const Duration j2 = Duration(days: 2);
  const Duration j3 = Duration(days: 3);
  const Duration j5 = Duration(days: 5);
  return switch (role) {
    RoleDemoCommunications.tuteur => <NotificationTuteur>[
      n(
        'demo-t-urgent',
        f.tuteurUrgent,
        h1,
        TypeNotification.changementSeance,
        NiveauAttention.urgent,
        texte: f.tuteurUrgentTexte,
      ),
      n(
        'demo-t-annonce',
        f.annonceNourTitre,
        h3,
        TypeNotification.annonceClasse,
        NiveauAttention.aLire,
        annonceId: 'demo-annonce-nour',
      ),
      n(
        'demo-t-reponse',
        f.tuteurReponse,
        j1,
        TypeNotification.reponseAttendue,
        NiveauAttention.actionRequise,
        texte: f.tuteurReponseTexte,
        destination: adresseDemoCommunications(
          VoieDemoCommunications.messages,
          role: RoleDemoCommunications.tuteur,
        ),
      ),
      n(
        'demo-t-message',
        f.tuteurMessage,
        j2,
        TypeNotification.messageMetier,
        NiveauAttention.aLire,
        mention: true,
        destination: adresseDemoCommunications(
          VoieDemoCommunications.messages,
          role: RoleDemoCommunications.tuteur,
        ),
      ),
      n(
        'demo-t-dossier',
        f.tuteurDossier,
        j5,
        TypeNotification.decisionDossier,
        NiveauAttention.information,
        lue: true,
      ),
    ],
    RoleDemoCommunications.adulte => <NotificationTuteur>[
      n(
        'demo-a-annonce',
        f.annonceFajrTitre,
        h5,
        TypeNotification.annonceClasse,
        NiveauAttention.aLire,
        annonceId: 'demo-annonce-fajr',
      ),
      n(
        'demo-a-seance',
        f.adulteSeance,
        j1,
        TypeNotification.changementSeance,
        NiveauAttention.actionRequise,
        destination: Routes.demoAdulte,
      ),
      n(
        'demo-a-message',
        f.adulteMessage,
        j2,
        TypeNotification.messageMetier,
        NiveauAttention.aLire,
        lue: true,
      ),
    ],
    RoleDemoCommunications.enseignant => <NotificationTuteur>[
      n(
        'demo-e-famille',
        f.enseignantFamille,
        h1,
        TypeNotification.messageMetier,
        NiveauAttention.aLire,
        destination: adresseDemoCommunications(
          VoieDemoCommunications.messages,
          role: RoleDemoCommunications.enseignant,
        ),
      ),
      n(
        'demo-e-direction',
        f.enseignantDirection,
        h3,
        TypeNotification.annonceDirection,
        NiveauAttention.aLire,
        texte: f.enseignantDirectionTexte,
      ),
      n(
        'demo-e-planning',
        f.enseignantPlanning,
        h5,
        TypeNotification.changementPlanning,
        NiveauAttention.actionRequise,
        destination: Routes.demoEnseignant,
      ),
      n(
        'demo-e-mention',
        f.enseignantMention,
        j1,
        TypeNotification.mentionCommunaute,
        NiveauAttention.aLire,
        mention: true,
        destination: adresseDemoCommunications(
          VoieDemoCommunications.communaute,
          role: RoleDemoCommunications.enseignant,
        ),
      ),
      n(
        'demo-e-reponse',
        f.enseignantReponse,
        j2,
        TypeNotification.reponseCommunaute,
        NiveauAttention.information,
        lue: true,
      ),
      n(
        'demo-e-administration',
        f.enseignantAdministration,
        j5,
        TypeNotification.messageAdministration,
        NiveauAttention.aLire,
        lue: true,
      ),
    ],
    RoleDemoCommunications.admin => <NotificationTuteur>[
      n(
        'demo-d-signalement',
        f.adminSignalement,
        h1,
        TypeNotification.signalementCommunaute,
        NiveauAttention.urgent,
        destination: adresseDemoCommunications(
          VoieDemoCommunications.annonces,
          role: RoleDemoCommunications.admin,
        ),
      ),
      n(
        'demo-d-dossiers',
        f.adminDossiers,
        h3,
        TypeNotification.dossierATraiter,
        // Les dossiers n'ont pas de demonstration ou se traiter : la
        // notification se lit, elle ne promet pas d'action (R-06).
        NiveauAttention.aLire,
      ),
      n(
        'demo-d-planifiee',
        f.adminPlanifiee,
        h5,
        TypeNotification.annoncePlanifiee,
        NiveauAttention.actionRequise,
        destination: adresseDemoCommunications(
          VoieDemoCommunications.annonces,
          role: RoleDemoCommunications.admin,
        ),
      ),
      n(
        'demo-d-reponse',
        f.adminReponse,
        j1,
        TypeNotification.reponseFil,
        NiveauAttention.aLire,
        mention: true,
      ),
      n(
        'demo-d-operationnel',
        f.adminOperationnel,
        j2,
        TypeNotification.evenementOperationnel,
        NiveauAttention.information,
        lue: true,
      ),
      // Le catalogue « Equipe Studio » (section 13.2) : le Studio est reserve
      // a l'Administration (reponse du directeur), ses notifications
      // arrivent donc dans ce meme centre.
      n(
        'demo-d-studio-decision',
        f.adminStudioDecision,
        h2,
        TypeNotification.decisionDemandee,
        NiveauAttention.actionRequise,
        destination: adresseDemoCommunications(
          VoieDemoCommunications.studio,
          role: RoleDemoCommunications.admin,
        ),
      ),
      n(
        'demo-d-studio-mention',
        f.adminStudioMention,
        h4,
        TypeNotification.mentionStudio,
        NiveauAttention.aLire,
        mention: true,
      ),
      n(
        'demo-d-studio-assigne',
        f.adminStudioAssigne,
        h6,
        TypeNotification.elementAssigne,
        NiveauAttention.actionRequise,
        destination: adresseDemoCommunications(
          VoieDemoCommunications.studio,
          role: RoleDemoCommunications.admin,
        ),
      ),
      n(
        'demo-d-studio-reponse',
        f.adminStudioReponse,
        j1 + h2,
        TypeNotification.reponseStudio,
        NiveauAttention.aLire,
      ),
      n(
        'demo-d-studio-interne',
        f.adminStudioInterne,
        j3,
        TypeNotification.annonceInterne,
        NiveauAttention.information,
      ),
      n(
        'demo-d-studio-contexte',
        f.adminStudioContexte,
        j5,
        TypeNotification.evenementContextuel,
        NiveauAttention.information,
        lue: true,
      ),
    ],
    RoleDemoCommunications.controleur => <NotificationTuteur>[
      n(
        'demo-c-mission',
        f.controleurMission,
        h3,
        TypeNotification.mission,
        NiveauAttention.aLire,
      ),
      n(
        'demo-c-changement',
        f.controleurChangement,
        j1,
        TypeNotification.changementMission,
        NiveauAttention.actionRequise,
        destination: Routes.demoControleur,
      ),
      n(
        'demo-c-reponse',
        f.controleurReponse,
        j2,
        TypeNotification.reponseAdministration,
        NiveauAttention.aLire,
        lue: true,
      ),
    ],
  };
}

/// Les notifications de demonstration, en memoire : la lecture s'y
/// enregistre tant que la page de demonstration est ouverte.
class NotificationsDemonstration
    implements PortNotifications, PortLectureNotifications {
  /// Cree le double avec [initiales].
  NotificationsDemonstration(List<NotificationTuteur> initiales)
    : _liste = List<NotificationTuteur>.of(initiales);

  final List<NotificationTuteur> _liste;

  @override
  Future<List<NotificationTuteur>> liste() async =>
      List<NotificationTuteur>.unmodifiable(_liste);

  @override
  Future<NotificationTuteur?> detail(String id) async =>
      _liste.where((NotificationTuteur n) => n.id == id).firstOrNull;

  @override
  Future<void> marquerLue(String id) async {
    final int i = _liste.indexWhere((NotificationTuteur n) => n.id == id);
    if (i >= 0) _liste[i] = _liste[i].marqueeLue();
  }
}

/// Les annonces de demonstration, en memoire.
///
/// COM-ANN-2 : elles portent aussi les audiences ouvertes ([cibles]), les
/// annonces de l'Administration ([publiees], [planifiees]) et la
/// publication. La publication est idempotente par sa cle (un « Reessayer »
/// ne publie pas deux fois) ; [echecPublication] simule un accuse qui ne
/// revient pas. Toute la lecture de l'Administration porte
/// `demonstration: true`, dite a l'ecran.
class AnnoncesDemonstration implements PortAnnonces {
  /// Cree le double avec les annonces [parClasse].
  AnnoncesDemonstration(
    this.parClasse, {
    this.cibles = const <CibleAnnonce>[],
    List<AnnonceAdministration> publiees = const <AnnonceAdministration>[],
    List<AnnonceAdministration> planifiees = const <AnnonceAdministration>[],
    this.maintenant,
    this.echecPublication = false,
  }) : publiees = List<AnnonceAdministration>.of(publiees),
       planifiees = List<AnnonceAdministration>.of(planifiees);

  /// Les annonces, par Classe.
  final Map<String, List<AnnonceClasse>> parClasse;

  /// Les audiences ouvertes.
  final List<CibleAnnonce> cibles;

  /// Les annonces publiees, la plus recente d'abord.
  final List<AnnonceAdministration> publiees;

  /// Les annonces planifiees, la plus proche d'abord.
  final List<AnnonceAdministration> planifiees;

  /// L'instant de reference ; par defaut, maintenant.
  final DateTime Function()? maintenant;

  /// Vrai : l'accuse de publication ne revient pas.
  bool echecPublication;

  /// Les publications par cle d'idempotence (tests).
  final Map<String, AnnonceConfirmee> parCle = <String, AnnonceConfirmee>{};

  final Set<String> _lues = <String>{};

  AnnonceClasse _vue(AnnonceClasse a) => _lues.contains(a.id)
      ? AnnonceClasse(
          id: a.id,
          titre: a.titre,
          texte: a.texte,
          publieeLe: a.publieeLe,
          classe: a.classe,
          auteur: a.auteur,
          niveau: a.niveau,
          lue: true,
        )
      : a;

  /// La capacite de publier pour une Classe suit l'audience ouverte par le
  /// serveur : une Classe dont l'audience est dans [cibles] peut recevoir
  /// une annonce (revue COM-R, R-20 : le publieur lit cette capacite).
  @override
  Future<AnnoncesDeLaClasse> annoncesDeClasse(String classeId) async =>
      AnnoncesDeLaClasse(
        annonces: <AnnonceClasse>[
          for (final AnnonceClasse a
              in parClasse[classeId] ?? const <AnnonceClasse>[])
            _vue(a),
        ],
        capacites: <CapaciteAnnonces>{
          if (cibles.any(
            (CibleAnnonce c) =>
                c.nature == NatureCible.classe && c.classeId == classeId,
          ))
            CapaciteAnnonces.publier,
        },
      );

  @override
  Future<AnnonceClasse?> annonce(String id) async {
    for (final List<AnnonceClasse> annonces in parClasse.values) {
      for (final AnnonceClasse a in annonces) {
        if (a.id == id) return _vue(a);
      }
    }
    return null;
  }

  @override
  Future<void> marquerLue(String annonceId) async => _lues.add(annonceId);

  @override
  Future<List<CibleAnnonce>> ciblesPublication({String? classeId}) async =>
      classeId == null
      ? List<CibleAnnonce>.unmodifiable(cibles)
      : <CibleAnnonce>[
          for (final CibleAnnonce c in cibles)
            if (c.nature == NatureCible.classe && c.classeId == classeId) c,
        ];

  @override
  Future<AnnonceConfirmee> publier({
    required BrouillonAnnonce brouillon,
    required String cleIdempotence,
  }) async {
    final AnnonceConfirmee? deja = parCle[cleIdempotence];
    if (deja != null) return deja;
    if (echecPublication) throw StateError('accuse de publication non recu');
    if (!cibles.contains(brouillon.cible)) {
      // Comme le serveur : une audience non ouverte est refusee.
      throw StateError('audience refusee');
    }
    final DateTime maintenant = (this.maintenant ?? DateTime.now)().toUtc();
    final DateTime? prevue = brouillon.programmeeLe;
    final AnnonceConfirmee confirmee = AnnonceConfirmee(
      id: 'demo-annonce-${parCle.length + 1}',
      etat: prevue == null ? EtatAnnonce.publiee : EtatAnnonce.planifiee,
      le: prevue ?? maintenant,
    );
    parCle[cleIdempotence] = confirmee;
    final AnnonceAdministration vue = AnnonceAdministration(
      id: confirmee.id,
      titre: brouillon.titre,
      texte: brouillon.texte,
      cible: brouillon.cible,
      etat: confirmee.etat,
      le: confirmee.le,
    );
    if (prevue == null) {
      publiees.insert(0, vue);
    } else {
      planifiees
        ..add(vue)
        ..sort(
          (AnnonceAdministration a, AnnonceAdministration b) =>
              a.le.compareTo(b.le),
        );
    }
    return confirmee;
  }

  @override
  Future<AnnoncesAdministration> annoncesAdministration() async =>
      AnnoncesAdministration(
        publiees: List<AnnonceAdministration>.unmodifiable(publiees),
        planifiees: List<AnnonceAdministration>.unmodifiable(planifiees),
        demonstration: true,
      );
}

/// Les audiences de demonstration : toute l'ecole, deux publics, deux
/// Classes (spec section 13.4).
List<CibleAnnonce> ciblesDemo() {
  final d = t.com.annonces.demoPublication;
  return <CibleAnnonce>[
    CibleAnnonce(
      id: 'demo-toutes',
      libelle: d.toutes,
      nature: NatureCible.toutes,
    ),
    CibleAnnonce(
      id: 'demo-familles',
      libelle: d.familles,
      nature: NatureCible.public,
    ),
    CibleAnnonce(
      id: 'demo-enseignants',
      libelle: d.enseignants,
      nature: NatureCible.public,
    ),
    CibleAnnonce(
      id: 'demo-audience-${ClassesDemoAnnonces.nour}',
      libelle: t.com.annonces.demo.classeNour,
      nature: NatureCible.classe,
      classeId: ClassesDemoAnnonces.nour,
    ),
    CibleAnnonce(
      id: 'demo-audience-${ClassesDemoAnnonces.fajr}',
      libelle: t.com.annonces.demo.classeFajr,
      nature: NatureCible.classe,
      classeId: ClassesDemoAnnonces.fajr,
    ),
  ];
}

/// Les annonces de l'Administration en demonstration : trois publiees, une
/// planifiee.
({List<AnnonceAdministration> publiees, List<AnnonceAdministration> planifiees})
annoncesAdministrationDemo(DateTime maintenant) {
  final d = t.com.annonces.demoPublication;
  final List<CibleAnnonce> c = ciblesDemo();
  AnnonceAdministration a(
    String id,
    String titre,
    String texte,
    CibleAnnonce cible,
    EtatAnnonce etat,
    Duration decalage,
  ) => AnnonceAdministration(
    id: id,
    titre: titre,
    texte: texte,
    cible: cible,
    etat: etat,
    le: maintenant.add(decalage).toUtc(),
  );
  return (
    publiees: <AnnonceAdministration>[
      a(
        'demo-adm-vacances',
        d.vacancesTitre,
        d.vacancesTexte,
        c[0],
        EtatAnnonce.publiee,
        const Duration(hours: -2),
      ),
      a(
        'demo-adm-reunion',
        d.reunionTitre,
        d.reunionTexte,
        c[2],
        EtatAnnonce.publiee,
        const Duration(days: -1),
      ),
      a(
        'demo-adm-recitation',
        d.recitationTitre,
        d.recitationTexte,
        c[3],
        EtatAnnonce.publiee,
        const Duration(days: -3),
      ),
    ],
    planifiees: <AnnonceAdministration>[
      a(
        'demo-adm-rentree',
        d.rentreeTitre,
        d.rentreeTexte,
        c[1],
        EtatAnnonce.planifiee,
        const Duration(days: 4),
      ),
    ],
  );
}

/// Les regles de portee de demonstration : la spec section 13.4, rien de
/// plus (Direction : toute audience ; enseignant : sa Classe ; famille,
/// eleve, controleur : aucune publication). Aucune validation n'est
/// inventee : la spec n'en prevoit pas, la colonne n'est donc pas montree.
class ReglesAudienceDemo implements PortReglesAudience {
  /// Cree la matrice.
  const ReglesAudienceDemo();

  @override
  Future<ReglesAudience> regles() async {
    final d = t.com.annonces.demoPublication;
    return ReglesAudience(
      demonstration: true,
      regles: <RegleAudience>[
        RegleAudience(
          id: 'direction',
          auteurs: d.direction,
          peutPublier: true,
          audiences: d.audiencesDirection,
        ),
        RegleAudience(
          id: 'enseignants',
          auteurs: d.enseignants,
          peutPublier: true,
          audiences: d.audiencesEnseignant,
        ),
        RegleAudience(
          id: 'familles',
          auteurs: d.familles,
          peutPublier: false,
          audiences: '',
        ),
        RegleAudience(
          id: 'eleves',
          auteurs: d.eleves,
          peutPublier: false,
          audiences: '',
        ),
        RegleAudience(
          id: 'controleurs',
          auteurs: d.controleurs,
          peutPublier: false,
          audiences: '',
        ),
      ],
    );
  }
}

/// L'adresse de la Communaute enseignants en demonstration, ouverte par
/// « Ouvrir le contexte » : l'aiguillage du socle (`?voie=`, `?role=`), sans
/// importer la voie COM-COMU (fiche COM-ANN-2). `etat=nominal` est la
/// situation nominale de la demonstration Communaute ; une voie qui ne lit
/// pas ce parametre l'ignore.
final String adresseDemoCommunauteModeration = Uri(
  path: Routes.demoCommunications,
  queryParameters: <String, String>{
    'voie': VoieDemoCommunications.communaute.name,
    'role': RoleDemoCommunications.enseignant.name,
    'etat': 'nominal',
  },
).toString();

/// La moderation de l'Administration en demonstration : trois signalements
/// de la Communaute (un lien affilie, une vente, un hors sujet), toutes les
/// actions permises. Une decision est accusee en memoire ; [indisponible]
/// et [nonConfirme] simulent les deux echecs.
class ModerationAdministrationDemo implements PortModeration {
  /// Cree la moderation.
  ModerationAdministrationDemo({
    required this.maintenant,
    this.actions = const <ActionModeration>{
      ActionModeration.masquer,
      ActionModeration.restaurer,
      ActionModeration.rejeter,
      ActionModeration.approuver,
    },
    this.vide = false,
    this.indisponible = false,
    this.nonConfirme = false,
  });

  /// L'instant de reference des dates.
  final DateTime maintenant;

  /// Les actions permises.
  final Set<ActionModeration> actions;

  /// Vrai : la file est vide.
  final bool vide;

  /// Vrai : chaque decision echoue comme un port sans contrat.
  final bool indisponible;

  /// Vrai : l'accuse d'une decision ne revient pas.
  bool nonConfirme;

  /// Les decisions accusees (tests).
  final List<(String, ActionModeration)> decisions =
      <(String, ActionModeration)>[];

  @override
  Future<CapacitesModeration> capacites() async =>
      CapacitesModeration(peutSignaler: true, actions: actions);

  @override
  Future<ResultatSignalement> signaler({
    required ObjetLie objet,
    required MotifSignalement motif,
    required String cleIdempotence,
    String? precision,
  }) async => ResultatSignalement.enregistre;

  @override
  Future<Set<ObjetLie>> mesSignalements() async => <ObjetLie>{};

  @override
  Future<List<ElementModeration>> file() async {
    if (vide) return const <ElementModeration>[];
    final d = t.com.annonces.demoPublication;
    final String communaute = adresseDemoCommunauteModeration;
    return <ElementModeration>[
      ElementModeration(
        id: 'demo-sig-affilie',
        objet: ObjetLie(
          type: TypeObjetLie.publication,
          id: 'demo-pub-affilie',
          libelle: d.signalementAffilie,
          destination: communaute,
        ),
        motif: MotifSignalement.lienAffilie,
        signaleLe: maintenant.subtract(const Duration(hours: 5)).toUtc(),
        extrait: d.extraitAffilie,
      ),
      ElementModeration(
        id: 'demo-sig-vente',
        objet: ObjetLie(
          type: TypeObjetLie.publication,
          id: 'demo-pub-vente',
          libelle: d.signalementVente,
          destination: communaute,
        ),
        motif: MotifSignalement.venteNonAutorisee,
        signaleLe: maintenant.subtract(const Duration(hours: 3)).toUtc(),
        extrait: d.extraitVente,
      ),
      ElementModeration(
        id: 'demo-sig-hors-sujet',
        objet: ObjetLie(
          type: TypeObjetLie.publication,
          id: 'demo-rep-hors-sujet',
          libelle: d.signalementHorsSujet,
        ),
        motif: MotifSignalement.horsSujet,
        signaleLe: maintenant.subtract(const Duration(hours: 1)).toUtc(),
      ),
    ];
  }

  @override
  Future<void> appliquer({
    required String signalementId,
    required ActionModeration action,
  }) async {
    if (indisponible) throw const CapaciteIndisponible('COM-BR-06');
    if (nonConfirme) throw StateError('accuse de decision non recu');
    decisions.add((signalementId, action));
  }
}

/// Les capacites Communications ouvertes en demonstration : publier,
/// programmer (moderer est lu dans `CapacitesModeration`, R-21).
const Set<CapaciteCommunication> capacitesDemoAdministration =
    <CapaciteCommunication>{
      CapaciteCommunication.publierAnnonce,
      CapaciteCommunication.programmer,
    };

/// Les surcharges de l'Administration des communications et du publieur en
/// demonstration : seuls des doubles en memoire, marques « Démonstration ».
/// Les lectures derivees sont surchargees elles-memes : sous un
/// `ProviderScope` imbrique, elles liraient sinon la racine, ou les ports
/// restent neutres.
List<Override> surchargesAdministrationDemo({
  required AnnoncesDemonstration annonces,
  required PortModeration moderation,
  PortReglesAudience regles = const ReglesAudienceDemo(),
  Set<CapaciteCommunication> capacites = capacitesDemoAdministration,
}) => <Override>[
  portAnnoncesProvider.overrideWithValue(annonces),
  annoncesAdministrationProvider.overrideWith(
    (Ref _) => annonces.annoncesAdministration(),
  ),
  ciblesPublicationProvider.overrideWith(
    (Ref _, String? classeId) => annonces.ciblesPublication(classeId: classeId),
  ),
  annoncesDeClasseProvider.overrideWith(
    (Ref _, String id) => annonces.annoncesDeClasse(id),
  ),
  portReglesAudienceProvider.overrideWithValue(regles),
  reglesAudienceProvider.overrideWith((Ref _) => regles.regles()),
  portModerationProvider.overrideWithValue(moderation),
  capacitesModerationFileProvider.overrideWith(
    (Ref _) => moderation.capacites(),
  ),
  fileModerationProvider.overrideWith((Ref _) => moderation.file()),
  moderationDemonstrationProvider.overrideWithValue(true),
  portCapacitesCommunicationsProvider.overrideWithValue(
    CapacitesCommunicationsFixes(capacites),
  ),
  capacitesCommunicationProvider.overrideWith(
    (Ref _) async => CapacitesCommunication(capacites),
  ),
];

/// L'ecran de l'Administration des communications en demonstration
/// (`?ecran=administration`, role Administration).
const String ecranAdministrationDemo = 'administration';

/// L'ecran du publieur de l'enseignant en demonstration (`?ecran=publier`,
/// role Enseignant).
const String ecranPublierDemo = 'publier';

/// L'adresse de l'Administration des communications de demonstration, sur
/// l'onglet [onglet].
String adresseAdministrationDemo(OngletCommunications onglet) => Uri(
  path: Routes.demoCommunications,
  queryParameters: <String, String>{
    'voie': VoieDemoCommunications.annonces.name,
    'role': RoleDemoCommunications.admin.name,
    'ecran': ecranAdministrationDemo,
    'onglet': onglet.name,
  },
).toString();

/// L'adresse du publieur de l'enseignant en demonstration.
String adressePublierDemo() => Uri(
  path: Routes.demoCommunications,
  queryParameters: <String, String>{
    'voie': VoieDemoCommunications.annonces.name,
    'role': RoleDemoCommunications.enseignant.name,
    'ecran': ecranPublierDemo,
  },
).toString();

/// Les onglets de l'Administration de demonstration : les libelles du
/// socle, des adresses qui restent dans la demonstration. L'onglet Messages
/// est une autre page (COM-MSG-2, COM-FUS) : il mene a la demonstration des
/// Messages de l'administration.
List<({String libelle, String chemin})> ongletsAdministrationDemo() =>
    <({String libelle, String chemin})>[
      for (final (int i, ({String libelle, String chemin}) o)
          in ongletsCommunications().indexed)
        (
          libelle: o.libelle,
          chemin: i < OngletCommunications.values.length
              ? adresseAdministrationDemo(OngletCommunications.values[i])
              : adresseDemoMessages(RoleDemoCommunications.admin),
        ),
    ];

class _ComAnnoncesDemoState extends State<ComAnnoncesDemo> {
  NotificationsDemonstration? _notifications;
  AnnoncesDemonstration? _annonces;
  ModerationAdministrationDemo? _moderation;
  RoleDemoCommunications? _rolePorts;

  /// Les doubles du role, gardes d'une reconstruction a l'autre : une lecture
  /// enregistree le reste tant que la demonstration est ouverte.
  ({
    NotificationsDemonstration notifications,
    AnnoncesDemonstration annonces,
    ModerationAdministrationDemo moderation,
  })
  _ports(RoleDemoCommunications role) {
    final NotificationsDemonstration? n = _notifications;
    final AnnoncesDemonstration? a = _annonces;
    final ModerationAdministrationDemo? m = _moderation;
    if (_rolePorts == role && n != null && a != null && m != null) {
      return (notifications: n, annonces: a, moderation: m);
    }
    final DateTime maintenant = widget.maintenant ?? DateTime.now();
    final NotificationsDemonstration nouvelles = NotificationsDemonstration(
      notificationsDemo(role, maintenant),
    );
    final List<CibleAnnonce> cibles = ciblesDemo();
    final administration = annoncesAdministrationDemo(maintenant);
    final AnnoncesDemonstration annonces = AnnoncesDemonstration(
      annoncesDemo(role, maintenant),
      // L'Administration vise toutes les audiences ; l'enseignant, sa
      // Classe seulement (spec section 13.4) ; les autres, aucune.
      cibles: switch (role) {
        RoleDemoCommunications.admin => cibles,
        RoleDemoCommunications.enseignant => <CibleAnnonce>[
          for (final CibleAnnonce c in cibles)
            if (c.classeId == ClassesDemoAnnonces.nour) c,
        ],
        RoleDemoCommunications.tuteur ||
        RoleDemoCommunications.adulte ||
        RoleDemoCommunications.controleur => const <CibleAnnonce>[],
      },
      publiees: role == RoleDemoCommunications.admin
          ? administration.publiees
          : const <AnnonceAdministration>[],
      planifiees: role == RoleDemoCommunications.admin
          ? administration.planifiees
          : const <AnnonceAdministration>[],
      maintenant: widget.maintenant == null ? null : () => maintenant,
    );
    final ModerationAdministrationDemo moderation =
        ModerationAdministrationDemo(maintenant: maintenant);
    _rolePorts = role;
    _notifications = nouvelles;
    _annonces = annonces;
    _moderation = moderation;
    return (
      notifications: nouvelles,
      annonces: annonces,
      moderation: moderation,
    );
  }

  @override
  Widget build(BuildContext context) {
    final RoleDemoCommunications? role = widget.role;
    if (role == null) return const _ChoixRole();
    final ports = _ports(role);
    final Map<String, String> parametres =
        GoRouter.maybeOf(context)?.state.uri.queryParameters ??
        const <String, String>{};
    final String? classeId = parametres['classe'];
    final String? ecran = parametres['ecran'];
    final String? libelleClasse = classeId == null
        ? null
        : ClassesDemoAnnonces.libelle(classeId);
    return ProviderScope(
      // Les doubles ne vivent que sous cette portee : les fournisseurs de
      // l'application gardent leurs ports neutres.
      overrides: <Override>[
        portNotificationsProvider.overrideWithValue(ports.notifications),
        notificationsTuteurProvider.overrideWith(
          (Ref _) => ports.notifications.liste(),
        ),
        annonceProvider.overrideWith(
          (Ref _, String id) => ports.annonces.annonce(id),
        ),
        ...surchargesAdministrationDemo(
          annonces: ports.annonces,
          moderation: ports.moderation,
          capacites: switch (role) {
            RoleDemoCommunications.admin => capacitesDemoAdministration,
            RoleDemoCommunications.enseignant => const <CapaciteCommunication>{
              CapaciteCommunication.publierAnnonce,
            },
            RoleDemoCommunications.tuteur ||
            RoleDemoCommunications.adulte ||
            RoleDemoCommunications.controleur =>
              const <CapaciteCommunication>{},
          },
        ),
      ],
      child:
          role == RoleDemoCommunications.admin &&
              ecran == ecranAdministrationDemo
          ? _AdministrationDemo(
              onglet:
                  OngletCommunications.values
                      .where(
                        (OngletCommunications o) =>
                            o.name == parametres['onglet'],
                      )
                      .firstOrNull ??
                  OngletCommunications.annonces,
              horloge: widget.maintenant == null
                  ? null
                  : () => widget.maintenant!,
            )
          : role == RoleDemoCommunications.enseignant &&
                ecran == ecranPublierDemo
          ? PublierAnnonceClassePage(
              groupeId: ClassesDemoAnnonces.nour,
              horloge: widget.maintenant == null
                  ? null
                  : () => widget.maintenant!,
              onRetour: () => GoRouter.of(
                context,
              ).go(adresseDemoCommunications(VoieDemoCommunications.annonces)),
            )
          : classeId != null && libelleClasse != null
          ? PageShell(
              key: const ValueKey<String>('demo-espace-classe'),
              titre: libelleClasse,
              sousTitre: t.com.annonces.demo.detail,
              onRetour: () => GoRouter.of(context).go(
                adresseDemoCommunications(
                  VoieDemoCommunications.annonces,
                  role: role,
                ),
              ),
              child: AnnoncesDeClasse(classeId: classeId),
            )
          : NotificationsPage(
              onRetour: () => GoRouter.of(
                context,
              ).go(adresseDemoCommunications(VoieDemoCommunications.annonces)),
            ),
    );
  }
}

/// L'Administration des communications de demonstration, dans la VRAIE
/// coquille Admin (domaine Operations allume) ; les domaines et le compte ne
/// menent nulle part hors de la demonstration.
class _AdministrationDemo extends StatelessWidget {
  const _AdministrationDemo({required this.onglet, this.horloge});

  final OngletCommunications onglet;
  final DateTime Function()? horloge;

  @override
  Widget build(BuildContext context) {
    void index() =>
        GoRouter.of(context)
            .go(adresseDemoCommunications(VoieDemoCommunications.annonces));
    return AdminShell(
      domaines: domainesAdmin(voitDirection: false),
      domaineActif: AdminDomaine.operations,
      onAller: (String _) => index(),
      onCompte: index,
      onRetour: index,
      child: AdministrationCommunicationsPage(
        key: ValueKey<String>('demo-administration-${onglet.name}'),
        onglet: onglet,
        onglets: ongletsAdministrationDemo(),
        horloge: horloge,
      ),
    );
  }
}

/// Le choix du role mis en scene.
class _ChoixRole extends StatelessWidget {
  const _ChoixRole();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final d = t.com.annonces.demo;
    return PageShell(
      titre: libelleVoieDemoCommunications(VoieDemoCommunications.annonces),
      sousTitre: d.detail,
      onRetour: () => GoRouter.of(context).go(Routes.demoCommunications),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            d.choisirRole,
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
          Ecart.vMd,
          for (final RoleDemoCommunications r in RoleDemoCommunications.values)
            LienFleche(
              key: ValueKey<String>('lien-role-${r.name}'),
              libelle: libelleRoleDemo(r),
              onPress: () => GoRouter.of(context).go(
                adresseDemoCommunications(
                  VoieDemoCommunications.annonces,
                  role: r,
                ),
              ),
            ),
          // COM-ANN-2 : l'Administration des communications et le publieur
          // de l'enseignant.
          LienFleche(
            key: const ValueKey<String>('lien-administration'),
            libelle: t.com.annonces.demoPublication.lienAdministration,
            onPress: () => GoRouter.of(context)
                .go(adresseAdministrationDemo(OngletCommunications.annonces)),
          ),
          LienFleche(
            key: const ValueKey<String>('lien-publier'),
            libelle: t.com.annonces.demoPublication.lienPublier,
            onPress: () => GoRouter.of(context).go(adressePublierDemo()),
          ),
        ],
      ),
    );
  }
}
