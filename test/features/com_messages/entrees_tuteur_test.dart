// COM-MSG-2 (K-07) : les entrees reelles des Messages metier du tuteur (et de
// l'eleve adulte, qui a en production le role `guardian` et la meme
// coquille, UX_REV-09), TAPEES depuis la vraie coquille et le vrai routeur :
// l'Espace Classe (`ClasseTuteurPage`, atteint par « Voir la classe » de
// l'Accueil) et la cloche (une notification qui ouvre le fil). Aucune
// cinquieme destination : le shell tuteur garde ses quatre destinations et
// l'Accueil reste allume (spec section 21).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_notifications.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/badge_non_lu.dart';
import 'package:rewayah_academy/core/widgets/carte_piece_jointe.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/pile_cartes.dart';
import 'package:rewayah_academy/features/accueil_famille/accueil_famille_page.dart';
import 'package:rewayah_academy/features/classe_tuteur/classe_tuteur_page.dart';
import 'package:rewayah_academy/features/com_messages/entree_messages_contexte.dart';
import 'package:rewayah_academy/features/com_messages/messages_page.dart';
import 'package:rewayah_academy/features/com_messages/panneau_contexte_fil.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';
import 'package:rewayah_academy/features/notifications/notifications_page.dart';

import '../../fixtures/tuteur/faux_capacites.dart' show FauxNotifications;
import '../../router/support_routeur.dart' show stabiliser;
import '../classe_tuteur/support_classe.dart';
import 'support_messages.dart';

const Participant _mariam = Participant(
  id: 'p-mariam',
  nomAffiche: 'Mme Mariam',
  fonction: 'Enseignante de la Classe',
);
const Participant _direction = Participant(
  id: 'p-direction',
  nomAffiche: 'Administration',
  fonction: 'Direction de Rewayah',
);

ObjetLie _classe() =>
    ObjetLie(type: TypeObjetLie.classe, id: classeA, libelle: 'Classe A');

FauxMessagesMetier _port() => FauxMessagesMetier(
  fils: <FilMetier>[
    filAvec(
      id: 'fil-mariam',
      autre: _mariam,
      objets: <ObjetLie>[
        _classe(),
        ObjetLie(type: TypeObjetLie.eleve, id: eleveA1, libelle: 'Eleve A1'),
      ],
      attention: const IndicateurAttention(nonLus: 1),
      // §25 « piece jointe indisponible » : nommee, jamais ouverte.
      pieces: <PieceJointe>[
        PieceJointe(
          reference: ReferencePieceJointe('pj-ancienne'),
          nom: 'Fiche_ancienne.pdf',
          nature: NaturePieceJointe.document,
          typeLisible: 'PDF',
          etat: EtatPieceJointe.indisponible,
        ),
      ],
    ),
    filAvec(
      id: 'fil-direction',
      autre: _direction,
      objets: <ObjetLie>[_classe()],
      texte: 'Bonjour, que pouvons-nous faire pour vous ?',
    ),
  ],
  conversations: <String, List<ConversationPossible>>{
    cleObjet(TypeObjetLie.classe, classeA): <ConversationPossible>[
      ConversationPossible(
        interlocuteur: _mariam,
        objet: ObjetLie(
          type: TypeObjetLie.eleve,
          id: eleveA1,
          libelle: 'Eleve A1',
        ),
        filId: 'fil-mariam',
        attention: const IndicateurAttention(nonLus: 1),
      ),
      ConversationPossible(
        interlocuteur: _direction,
        nature: NatureInterlocuteur.administration,
        objet: _classe(),
      ),
    ],
  },
  filsParObjet: <String, String>{
    cleObjet(TypeObjetLie.classe, classeA): 'fil-direction',
  },
);

Future<GoRouter> _monter(
  WidgetTester tester, {
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
      overrides: <Override>[
        ...surchargesClasse(),
        portMessagesMetierProvider.overrideWithValue(port ?? _port()),
        capaciteEcrireOuverteTest,
        if (notif != null) portNotificationsProvider.overrideWithValue(notif),
      ],
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
  await stabiliser(tester);
  routeur.go(Routes.tuteurAccueil);
  await stabiliser(tester);
  return routeur;
}

String _chemin(GoRouter routeur) =>
    routeur.routerDelegate.currentConfiguration.uri.path;

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await stabiliser(tester);
  await tester.tap(cible);
  await stabiliser(tester);
}

/// De l'Accueil a l'Espace Classe, par « Voir la classe ».
Future<void> _ouvrirLaClasse(WidgetTester tester) async {
  expect(find.byType(AccueilFamillePage), findsOneWidget);
  await _toucher(tester, find.text(t.tuteur.accueil.voirLaClasse));
  expect(find.byType(ClasseTuteurPage), findsOneWidget);
}

Finder _dansEntree(Finder cible) => find.descendant(
  of: find.byKey(EntreeMessagesContexte.cleObjet),
  matching: cible,
);

void main() {
  group('Espace Classe du tuteur', () {
    for (final Size taille in const <Size>[
      Size(390, 844),
      Size(768, 1024),
      Size(1440, 900),
    ]) {
      testWidgets('${taille.width.toInt()} : « Ecrire a Mme Mariam » ouvre '
          'le fil, l Accueil reste allume, quatre destinations', (
        WidgetTester tester,
      ) async {
        final GoRouter routeur = await _monter(tester, taille: taille);
        await _ouvrirLaClasse(tester);
        expect(
          _dansEntree(find.text(t.com.messages.entree.titreClasse)),
          findsOneWidget,
        );
        expect(_dansEntree(find.byType(BadgeNonLu)), findsOneWidget);

        await _toucher(
          tester,
          _dansEntree(
            find.text(t.com.messages.entree.ecrireA(nom: 'Mme Mariam')),
          ),
        );
        expect(_chemin(routeur), Routes.tuteurFilPour('fil-mariam'));
        expect(find.byType(MessagesPage), findsOneWidget);
        expect(find.byType(FilDiscussion), findsOneWidget);
        final NavShell coquille = tester.widget<NavShell>(
          find.byType(NavShell),
        );
        expect(coquille.indexActif, 0);
        expect(coquille.destinations, hasLength(4));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('« Ecrire a l Administration » : le fil de la Classe est '
        'ouvert a la demande', (WidgetTester tester) async {
      final FauxMessagesMetier port = _port();
      final GoRouter routeur = await _monter(tester, port: port);
      await _ouvrirLaClasse(tester);
      expect(port.objetsDemandes, isEmpty);
      await _toucher(
        tester,
        _dansEntree(find.text(t.com.messages.entree.ecrireAdministration)),
      );
      expect(port.objetsDemandes, <String>[
        cleObjet(TypeObjetLie.classe, classeA),
      ]);
      expect(_chemin(routeur), Routes.tuteurFilPour('fil-direction'));
      expect(
        find.text('Bonjour, que pouvons-nous faire pour vous ?'),
        findsWidgets,
      );
    });

    testWidgets('§25 piece jointe indisponible : nommee dans le panneau, '
        'marquee indisponible', (WidgetTester tester) async {
      await _monter(tester, taille: const Size(1440, 900));
      await _ouvrirLaClasse(tester);
      await _toucher(
        tester,
        _dansEntree(
          find.text(t.com.messages.entree.ecrireA(nom: 'Mme Mariam')),
        ),
      );
      expect(find.byType(PanneauContexteFil), findsOneWidget);
      final Finder carte = find.descendant(
        of: find.byKey(PanneauContexteFil.cleFichiers),
        matching: find.byType(CartePieceJointe),
      );
      expect(carte, findsOneWidget);
      expect(
        tester.widget<CartePieceJointe>(carte).piece.etat,
        EtatPieceJointe.indisponible,
      );
      expect(
        find.descendant(
          of: find.byType(PileCartes),
          matching: find.text('Fiche_ancienne.pdf'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('production (port neutre) : aucune entree, la Classe '
        'inchangee', (WidgetTester tester) async {
      await _monter(tester, port: const MessagesMetierIndisponibles());
      await _ouvrirLaClasse(tester);
      expect(find.byKey(EntreeMessagesContexte.cleObjet), findsNothing);
      expect(find.text(t.com.messages.entree.titreClasse), findsNothing);
      expect(find.text(t.classe.planning), findsOneWidget);
    });
  });

  group('Cloche du tuteur', () {
    testWidgets('390 : la cloche, puis la notification, ouvrent le fil', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(
        tester,
        notif: FauxNotifications(
          notifications: <NotificationTuteur>[
            NotificationTuteur(
              id: 'n1',
              titre: 'Nouveau message de Mme Mariam',
              date: maintenantTest,
              destination: Routes.tuteurFilPour('fil-mariam'),
            ),
          ],
        ),
      );
      await tester.tap(
        find.bySemanticsLabel(t.commun.entete.notifications).first,
      );
      await stabiliser(tester);
      expect(find.byType(NotificationsPage), findsOneWidget);
      await _toucher(tester, find.text('Nouveau message de Mme Mariam'));
      expect(_chemin(routeur), Routes.tuteurFilPour('fil-mariam'));
      expect(find.byType(FilDiscussion), findsOneWidget);
      expect(tester.widget<NavShell>(find.byType(NavShell)).indexActif, 0);
      expect(tester.takeException(), isNull);
    });
  });
}
