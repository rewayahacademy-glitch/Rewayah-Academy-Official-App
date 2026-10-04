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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';

import '../../../core/capacites/port_notifications.dart';
import '../../../core/communications/modeles_communication.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/lien_fleche.dart';
import '../../../core/widgets/page_shell.dart';
import '../../com_annonces/annonces_de_classe.dart';
import '../../com_annonces/port_annonces.dart';
import '../../notifications/notifications_page.dart';
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
/// notification de demonstration ouvre son detail, une annonce ouvre
/// l'Espace Classe de demonstration.
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
  );
  const Duration h1 = Duration(hours: 1);
  const Duration h3 = Duration(hours: 3);
  const Duration h5 = Duration(hours: 5);
  const Duration j1 = Duration(days: 1);
  const Duration j2 = Duration(days: 2);
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
      ),
      n(
        'demo-t-message',
        f.tuteurMessage,
        j2,
        TypeNotification.messageMetier,
        NiveauAttention.aLire,
        mention: true,
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
      ),
      n(
        'demo-e-mention',
        f.enseignantMention,
        j1,
        TypeNotification.mentionCommunaute,
        NiveauAttention.aLire,
        mention: true,
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
      ),
      n(
        'demo-d-dossiers',
        f.adminDossiers,
        h3,
        TypeNotification.dossierATraiter,
        NiveauAttention.actionRequise,
      ),
      n(
        'demo-d-planifiee',
        f.adminPlanifiee,
        h5,
        TypeNotification.annoncePlanifiee,
        NiveauAttention.actionRequise,
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
class AnnoncesDemonstration implements PortAnnonces {
  /// Cree le double avec les annonces [parClasse].
  AnnoncesDemonstration(this.parClasse);

  /// Les annonces, par Classe.
  final Map<String, List<AnnonceClasse>> parClasse;

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

  @override
  Future<AnnoncesDeLaClasse> annoncesDeClasse(String classeId) async =>
      AnnoncesDeLaClasse(
        annonces: <AnnonceClasse>[
          for (final AnnonceClasse a
              in parClasse[classeId] ?? const <AnnonceClasse>[])
            _vue(a),
        ],
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
}

class _ComAnnoncesDemoState extends State<ComAnnoncesDemo> {
  NotificationsDemonstration? _notifications;
  AnnoncesDemonstration? _annonces;
  RoleDemoCommunications? _rolePorts;

  /// Les doubles du role, gardes d'une reconstruction a l'autre : une lecture
  /// enregistree le reste tant que la demonstration est ouverte.
  ({NotificationsDemonstration notifications, AnnoncesDemonstration annonces})
  _ports(RoleDemoCommunications role) {
    final NotificationsDemonstration? n = _notifications;
    final AnnoncesDemonstration? a = _annonces;
    if (_rolePorts == role && n != null && a != null) {
      return (notifications: n, annonces: a);
    }
    final DateTime maintenant = widget.maintenant ?? DateTime.now();
    final NotificationsDemonstration nouvelles = NotificationsDemonstration(
      notificationsDemo(role, maintenant),
    );
    final AnnoncesDemonstration annonces = AnnoncesDemonstration(
      annoncesDemo(role, maintenant),
    );
    _rolePorts = role;
    _notifications = nouvelles;
    _annonces = annonces;
    return (notifications: nouvelles, annonces: annonces);
  }

  @override
  Widget build(BuildContext context) {
    final RoleDemoCommunications? role = widget.role;
    if (role == null) return const _ChoixRole();
    final ports = _ports(role);
    final String? classeId = GoRouter.maybeOf(context)
        ?.state
        .uri
        .queryParameters['classe'];
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
        portAnnoncesProvider.overrideWithValue(ports.annonces),
        annoncesDeClasseProvider.overrideWith(
          (Ref _, String id) => ports.annonces.annoncesDeClasse(id),
        ),
        annonceProvider.overrideWith(
          (Ref _, String id) => ports.annonces.annonce(id),
        ),
      ],
      child: classeId != null && libelleClasse != null
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
        ],
      ),
    );
  }
}
