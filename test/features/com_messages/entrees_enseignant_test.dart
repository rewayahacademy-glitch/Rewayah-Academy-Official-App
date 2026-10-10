// COM-MSG-2 (K-07) : les entrees reelles des Messages metier de
// l'enseignant, chacune TAPEE depuis la vraie coquille et le vrai routeur
// (`app_router.dart`) : Mes classes (la ligne « Messages metier »), l'Espace
// Classe (`FicheGroupePage`, « Ecrire a la famille », jamais un bloc
// « Messages » general, 02_DEC-11) et la cloche (une notification qui
// ouvre le fil, avec le double de `PortNotifications` et son champ
// `destination`). Aucune destination ajoutee : Classes reste allumee.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_notifications.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/matching/service_matching.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/priere/service_priere.dart';
import 'package:rewayah_academy/core/profil/service_profil_enseignant.dart';
import 'package:rewayah_academy/core/regles/service_regles.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/badge_non_lu.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/com_messages/entete_fil_contexte.dart';
import 'package:rewayah_academy/features/com_messages/entree_messages_contexte.dart';
import 'package:rewayah_academy/features/com_messages/liste_fils.dart';
import 'package:rewayah_academy/features/com_messages/messages_page.dart';
import 'package:rewayah_academy/features/com_messages/panneau_contexte_fil.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';
import 'package:rewayah_academy/features/demo/enseignant_demo.dart';
import 'package:rewayah_academy/features/fiche_groupe/fiche_groupe_page.dart';
import 'package:rewayah_academy/features/notifications/notifications_page.dart';

import '../../fixtures/tuteur/faux_capacites.dart' show FauxNotifications;
import '../../support/harnais.dart';
import 'support_messages.dart';

/// La Classe An-Nour de la demonstration enseignant (memes identifiants que
/// `navigation_reelle_test.dart`).
const String _groupeId = 'demo-classe-an-nour';

const Participant _ahmed = Participant(
  id: 'p-ahmed',
  nomAffiche: 'Ahmed',
  fonction: "Parent d'Adam",
);
const Participant _karim = Participant(
  id: 'p-karim',
  nomAffiche: 'Karim',
  fonction: 'Parent de Yusuf',
);
const Participant _fatima = Participant(
  id: 'p-fatima',
  nomAffiche: 'Fatima',
  fonction: 'Parent de Yasmine',
);

ObjetLie _classe() => ObjetLie(
  type: TypeObjetLie.classe,
  id: _groupeId,
  libelle: 'Classe An-Nour',
);
ObjetLie _eleve(String id, String prenom) =>
    ObjetLie(type: TypeObjetLie.eleve, id: id, libelle: prenom);

/// Le port des tests : deux fils (Adam, Yasmine sortie de la Classe) et une
/// famille sans fil encore ouvert (Yusuf). [yusufOuvrable] faux : le serveur
/// refuse d'ouvrir le fil de Yusuf (paire non autorisee).
FauxMessagesMetier _port({bool yusufOuvrable = true}) => FauxMessagesMetier(
  fils: <FilMetier>[
    filAvec(
      id: 'fil-adam',
      autre: _ahmed,
      objets: <ObjetLie>[_classe(), _eleve('eleve-adam', 'Adam')],
      attention: const IndicateurAttention(nonLus: 2),
    ),
    filAvec(
      id: 'fil-yasmine',
      autre: _fatima,
      objets: <ObjetLie>[_classe(), _eleve('eleve-yasmine', 'Yasmine')],
      // §25 « objet lie inaccessible » : Yasmine a quitte la Classe.
      objetsInaccessibles: const <String>{'eleve-yasmine'},
    ),
    filAvec(
      id: 'fil-yusuf',
      autre: _karim,
      objets: <ObjetLie>[_eleve('eleve-yusuf', 'Yusuf')],
      texte: 'Bonjour Karim.',
    ),
  ],
  conversations: <String, List<ConversationPossible>>{
    cleObjet(TypeObjetLie.classe, _groupeId): <ConversationPossible>[
      ConversationPossible(
        interlocuteur: _ahmed,
        nature: NatureInterlocuteur.famille,
        objet: _eleve('eleve-adam', 'Adam'),
        filId: 'fil-adam',
        attention: const IndicateurAttention(nonLus: 2),
      ),
      ConversationPossible(
        interlocuteur: _fatima,
        nature: NatureInterlocuteur.famille,
        objet: _eleve('eleve-yasmine', 'Yasmine'),
        filId: 'fil-yasmine',
      ),
      ConversationPossible(
        interlocuteur: _karim,
        nature: NatureInterlocuteur.famille,
        objet: _eleve('eleve-yusuf', 'Yusuf'),
      ),
    ],
  },
  filsParObjet: yusufOuvrable
      ? <String, String>{
          cleObjet(TypeObjetLie.eleve, 'eleve-yusuf'): 'fil-yusuf',
        }
      : const <String, String>{},
);

List<Override> _surcharges(
  PortMessagesMetier port, {
  PortNotifications? notif,
}) {
  final FauxServiceEnseignant serviceEnseignant = FauxServiceEnseignant()
    ..groupesRendus = DonneesEnseignantDemo.groupes()
    ..seancesRendues = DonneesEnseignantDemo.seances(EtatDemoEnseignant.nominal)
    ..retardsRendus = DonneesEnseignantDemo.cahiersEnRetard(
      EtatDemoEnseignant.nominal,
    )
    ..membresRendus = <String, List<MembreSeance>>{
      _groupeId: <MembreSeance>[
        membreDeTest(studentId: 'eleve-adam', prenom: 'Adam'),
        membreDeTest(
          studentId: 'eleve-yusuf',
          identifiant: 'RA-0002',
          prenom: 'Yusuf',
        ),
      ],
    };
  return <Override>[
    sourceSessionProvider.overrideWithValue(
      FausseSourceSession(
        const SessionState(
          resolue: true,
          role: AppRole.teacher,
          profileId: 'ens-1',
          householdId: 'h1',
          accountStatus: AccountStatus.active,
          lectureProfil: LectureProfil.presente,
        ),
      ),
    ),
    serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
    serviceEnseignantProvider.overrideWithValue(serviceEnseignant),
    servicePlanningProvider.overrideWithValue(FauxServicePlanning()),
    serviceMatchingProvider.overrideWithValue(FauxServiceMatching()),
    serviceReglesProvider.overrideWithValue(FauxServiceRegles()),
    servicePriereProvider.overrideWithValue(FauxServicePriere()),
    profilEnseignantProvider.overrideWith(
      (Ref _) async => DonneesEnseignantDemo.profil,
    ),
    portMessagesMetierProvider.overrideWithValue(port),
    capaciteEcrireOuverteTest,
    if (notif != null) portNotificationsProvider.overrideWithValue(notif),
  ];
}

Future<GoRouter> _monter(
  WidgetTester tester,
  String depart, {
  PortMessagesMetier? port,
  PortNotifications? notif,
  Size taille = const Size(390, 844),
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: _surcharges(port ?? _port(), notif: notif),
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext _, WidgetRef ref, Widget? _) {
            routeur = ref.read(routeurProvider);
            return MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              routerConfig: routeur,
            );
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  routeur.go(depart);
  await tester.pumpAndSettle();
  return routeur;
}

String _chemin(GoRouter routeur) =>
    routeur.routerDelegate.currentConfiguration.uri.path;

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

/// De Mes classes a l'Espace Classe An-Nour, par la ligne de la Classe.
Future<void> _ouvrirClasse(WidgetTester tester) async {
  await _toucher(tester, find.text('An-Nour'));
  expect(find.byType(FicheGroupePage), findsOneWidget);
}

Finder _dansEntree(Finder cible) => find.descendant(
  of: find.byKey(EntreeMessagesContexte.cleObjet),
  matching: cible,
);

void main() {
  group('Mes classes : la ligne « Messages metier »', () {
    for (final Size taille in const <Size>[Size(390, 844), Size(1440, 900)]) {
      testWidgets('${taille.width.toInt()} : le badge dit les non-lus, la '
          'ligne ouvre la liste dans Classes', (WidgetTester tester) async {
        final GoRouter routeur = await _monter(
          tester,
          Routes.enseignantClasses,
          taille: taille,
        );
        final Finder entree = find.byKey(EntreeMessagesContexte.cleGenerale);
        await tester.ensureVisible(entree);
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: entree,
            matching: find.text(t.com.messages.titre),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: entree,
            matching: find.text(t.com.messages.entree.aLire(nombre: 2)),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: entree, matching: find.byType(BadgeNonLu)),
          findsOneWidget,
        );

        await _toucher(
          tester,
          find.descendant(
            of: entree,
            matching: find.text(t.com.messages.titre),
          ),
        );
        expect(_chemin(routeur), Routes.enseignantMessages);
        expect(find.byType(ListeFils), findsOneWidget);
        // Aucune destination ajoutee : la pose garde Classes allumee.
        final NavShell coquille = tester.widget<NavShell>(
          find.byType(NavShell),
        );
        expect(coquille.indexActif, 1);
        expect(coquille.destinations, hasLength(4));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('production (port neutre) : aucune ligne, Mes classes '
        'inchange', (WidgetTester tester) async {
      await _monter(
        tester,
        Routes.enseignantClasses,
        port: const MessagesMetierIndisponibles(),
      );
      expect(find.byKey(EntreeMessagesContexte.cleGenerale), findsNothing);
      expect(find.text('An-Nour'), findsOneWidget);
    });
  });

  group('Espace Classe : « Ecrire a la famille »', () {
    for (final Size taille in const <Size>[Size(390, 844), Size(1440, 900)]) {
      testWidgets('${taille.width.toInt()} : depuis Mes classes, la famille '
          'd Adam ouvre son fil existant', (WidgetTester tester) async {
        final GoRouter routeur = await _monter(
          tester,
          Routes.enseignantClasses,
          taille: taille,
        );
        await _ouvrirClasse(tester);
        final Finder groupe = find.byKey(EntreeMessagesContexte.cleObjet);
        await tester.ensureVisible(groupe);
        await tester.pumpAndSettle();
        // Le titre dit l'objet : jamais un bloc « Messages » general.
        expect(
          _dansEntree(find.text(t.com.messages.entree.titreClasse)),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(FicheGroupePage),
            matching: find.text(t.com.messages.titre),
          ),
          findsNothing,
        );
        expect(
          _dansEntree(find.text(t.com.messages.entree.ecrireFamille)),
          findsNWidgets(3),
        );
        expect(_dansEntree(find.byType(BadgeNonLu)), findsOneWidget);

        await _toucher(tester, _dansEntree(find.text("Ahmed, Parent d'Adam")));
        expect(_chemin(routeur), Routes.enseignantFilPour('fil-adam'));
        expect(find.byType(FilDiscussion), findsOneWidget);
        expect(find.byType(EnteteFilContexte), findsOneWidget);
        expect(tester.widget<NavShell>(find.byType(NavShell)).indexActif, 1);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('famille sans fil : le fil est ouvert a la demande, puis '
        'rendu', (WidgetTester tester) async {
      final FauxMessagesMetier port = _port();
      final GoRouter routeur = await _monter(
        tester,
        Routes.groupePour(_groupeId),
        port: port,
      );
      expect(port.objetsDemandes, isEmpty, reason: 'jamais au rendu');
      await _toucher(tester, _dansEntree(find.text('Karim, Parent de Yusuf')));
      expect(port.objetsDemandes, <String>[
        cleObjet(TypeObjetLie.eleve, 'eleve-yusuf'),
      ]);
      expect(_chemin(routeur), Routes.enseignantFilPour('fil-yusuf'));
      expect(find.text('Bonjour Karim.'), findsWidgets);
    });

    testWidgets('§25 fil inaccessible : le serveur refuse, l Espace Classe '
        'reste et le dit, rien du fil n est montre', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(
        tester,
        Routes.groupePour(_groupeId),
        port: _port(yusufOuvrable: false),
      );
      await _toucher(tester, _dansEntree(find.text('Karim, Parent de Yusuf')));
      expect(_chemin(routeur), Routes.groupePour(_groupeId));
      final Finder echec = find.byKey(EntreeMessagesContexte.cleEchec);
      expect(echec, findsOneWidget);
      expect(
        tester
            .widget<EtatSysteme>(
              find.descendant(of: echec, matching: find.byType(EtatSysteme)),
            )
            .nature,
        NatureEtat.accesRefuse,
      );
      expect(
        find.text(t.com.messages.entree.inaccessibleTitre),
        findsOneWidget,
      );
      expect(find.text('Bonjour Karim.'), findsNothing);
      expect(find.byType(FilDiscussion), findsNothing);
    });

    testWidgets('§25 objet lie inaccessible : le fil de Yasmine s ouvre, '
        'l eleve est nomme sans lien', (WidgetTester tester) async {
      await _monter(
        tester,
        Routes.groupePour(_groupeId),
        taille: const Size(1440, 900),
      );
      await _toucher(
        tester,
        _dansEntree(find.text('Fatima, Parent de Yasmine')),
      );
      expect(find.byType(PanneauContexteFil), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(PanneauContexteFil.cleObjets),
          matching: find.text(t.com.messages.panneau.inaccessible),
        ),
        findsOneWidget,
      );
    });
  });

  group('Cloche : une notification ouvre le fil', () {
    testWidgets('390 : la cloche de la coquille, puis la notification, '
        'menent au fil d Adam', (WidgetTester tester) async {
      final GoRouter routeur = await _monter(
        tester,
        Routes.enseignantClasses,
        notif: FauxNotifications(
          notifications: <NotificationTuteur>[
            NotificationTuteur(
              id: 'n1',
              titre: "Nouveau message d'Ahmed",
              date: maintenantTest,
              destination: Routes.enseignantFilPour('fil-adam'),
            ),
          ],
        ),
      );
      await tester.tap(
        find.bySemanticsLabel(t.commun.entete.notifications).first,
      );
      await tester.pumpAndSettle();
      expect(_chemin(routeur), Routes.enseignantNotifications);
      expect(find.byType(NotificationsPage), findsOneWidget);

      await _toucher(tester, find.text("Nouveau message d'Ahmed"));
      expect(_chemin(routeur), Routes.enseignantFilPour('fil-adam'));
      expect(find.byType(MessagesPage), findsOneWidget);
      expect(find.byType(FilDiscussion), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
