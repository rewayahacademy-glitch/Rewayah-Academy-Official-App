// COM-MSG-2 : les etats de l'entree des Messages (spec section 25), sur un
// routeur minimal qui reprend les adresses reelles (`/enseignant/groupe/:id`,
// `/admin/...`, `/demo/...`) : chargement, contenu, vide, erreur, hors
// ligne, indisponible, ecriture fermee, plus de cinq conversations, fil
// inaccessible et ouverture en echec ; puis le RENDU a 390, 768 et 1440, en
// clair et en sombre, en arabe (RTL) et a 200 % de texte.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/badge_non_lu.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/groupe_reglages.dart';
import 'package:rewayah_academy/core/widgets/vue_etat_communication.dart';
import 'package:rewayah_academy/features/com_messages/entree_messages_contexte.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';
import 'package:rewayah_academy/features/demo/communications/com_messages_demo.dart';
import 'package:rewayah_academy/features/demo/communications/demo_communications_page.dart';

import '../../support/harnais.dart';
import 'support_messages.dart';

const String _classe = 'c1';

Participant _famille(int i) => Participant(
  id: 'p-$i',
  nomAffiche: 'Parent $i',
  fonction: 'Parent de Eleve $i',
);

ConversationPossible _conversation(
  int i, {
  String? filId,
  NatureInterlocuteur nature = NatureInterlocuteur.famille,
  IndicateurAttention attention = IndicateurAttention.aucun,
}) => ConversationPossible(
  interlocuteur: _famille(i),
  nature: nature,
  objet: ObjetLie(type: TypeObjetLie.eleve, id: 'e$i', libelle: 'Eleve $i'),
  filId: filId,
  attention: attention,
);

/// Deux conversations : une avec fil (non lu), une a ouvrir.
FauxMessagesMetier _port({
  List<ConversationPossible>? conversations,
  Map<String, String> filsParObjet = const <String, String>{},
}) => FauxMessagesMetier(
  fils: <FilMetier>[
    filAvec(
      id: 'fil-1',
      autre: _famille(1),
      objets: <ObjetLie>[
        ObjetLie(type: TypeObjetLie.eleve, id: 'e1', libelle: 'Eleve 1'),
      ],
      attention: const IndicateurAttention(nonLus: 3),
    ),
  ],
  conversations: <String, List<ConversationPossible>>{
    cleObjet(TypeObjetLie.classe, _classe):
        conversations ??
        <ConversationPossible>[
          _conversation(
            1,
            filId: 'fil-1',
            attention: const IndicateurAttention(nonLus: 3),
          ),
          _conversation(2),
        ],
  },
  filsParObjet: filsParObjet,
);

/// Un hote minimal par adresse : la page de la Classe (entree sur l'objet),
/// Mes classes (entree generale), le dossier admin (entree sur le dossier),
/// une demonstration (aucune coquille), et les cibles des Messages.
GoRouter _routeur(String depart) => GoRouter(
  initialLocation: depart,
  routes: <RouteBase>[
    GoRoute(
      path: '${Routes.enseignantGroupe}/:id',
      builder: (BuildContext _, GoRouterState etat) => Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text('hote-classe'),
              EntreeMessagesContexte(
                type: TypeObjetLie.classe,
                objetId: etat.pathParameters['id'],
                ecartAvant: Ecart.vSection,
              ),
            ],
          ),
        ),
      ),
    ),
    GoRoute(
      path: Routes.enseignantClasses,
      builder: (BuildContext _, GoRouterState _) => const Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('hote-classes'),
            EntreeMessagesContexte(ecartAvant: Ecart.vSection),
          ],
        ),
      ),
    ),
    GoRoute(
      path: '/admin/personnes/dossiers/:id',
      builder: (BuildContext _, GoRouterState etat) => Scaffold(
        body: EntreeMessagesContexte(
          type: TypeObjetLie.dossier,
          objetId: etat.pathParameters['id'],
        ),
      ),
    ),
    GoRoute(
      path: '/demo/communications',
      builder: (BuildContext _, GoRouterState _) => const Scaffold(
        body: EntreeMessagesContexte(
          type: TypeObjetLie.classe,
          objetId: _classe,
        ),
      ),
    ),
    GoRoute(
      path: Routes.enseignantMessages,
      builder: (BuildContext _, GoRouterState _) =>
          const Scaffold(body: Text('liste-enseignant')),
      routes: <RouteBase>[
        GoRoute(
          path: ':filId',
          builder: (BuildContext _, GoRouterState etat) =>
              Scaffold(body: Text('fil-${etat.pathParameters['filId']}')),
        ),
      ],
    ),
    GoRoute(
      path: Routes.adminCommunicationsMessages,
      builder: (BuildContext _, GoRouterState _) =>
          const Scaffold(body: Text('liste-admin')),
      routes: <RouteBase>[
        GoRoute(
          path: ':filId',
          builder: (BuildContext _, GoRouterState etat) =>
              Scaffold(body: Text('fil-admin-${etat.pathParameters['filId']}')),
        ),
      ],
    ),
  ],
);

Future<GoRouter> _monter(
  WidgetTester tester, {
  required PortMessagesMetier port,
  String depart = '${Routes.enseignantGroupe}/$_classe',
  Size taille = const Size(390, 844),
  AppLocale langue = AppLocale.fr,
  double echelleTexte = 1,
  Brightness luminosite = Brightness.light,
  bool horsLigne = false,
  bool ecritureOuverte = true,
  bool stabiliser = true,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.runAsync(() => LocaleSettings.setLocale(langue));
  addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
  final GoRouter routeur = _routeur(depart);
  addTearDown(routeur.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        serviceReseauProvider.overrideWithValue(
          FauxServiceReseau(horsLigneRendu: horsLigne),
        ),
        portMessagesMetierProvider.overrideWithValue(port),
        if (ecritureOuverte) capaciteEcrireOuverteTest,
      ],
      child: TranslationProvider(
        child: MaterialApp.router(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
          themeMode: luminosite == Brightness.dark
              ? ThemeMode.dark
              : ThemeMode.light,
          locale: langue.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (BuildContext context, Widget? app) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(echelleTexte)),
            child: app!,
          ),
          routerConfig: routeur,
        ),
      ),
    ),
  );
  if (stabiliser) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  return routeur;
}

final Finder _groupe = find.byKey(EntreeMessagesContexte.cleObjet);

Finder _dansGroupe(Finder cible) =>
    find.descendant(of: _groupe, matching: cible);

void main() {
  group('Etats de l entree sur un objet', () {
    testWidgets('chargement : le squelette des communications, puis le '
        'contenu', (WidgetTester tester) async {
      final FauxMessagesMetier port = _port()
        ..attenteConversations = Completer<void>();
      await _monter(tester, port: port, stabiliser: false);
      expect(find.byKey(VueEtatCommunication.cleChargement), findsOneWidget);
      expect(_groupe, findsNothing);
      port.attenteConversations!.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(VueEtatCommunication.cleChargement), findsNothing);
      expect(_groupe, findsOneWidget);
    });

    testWidgets('contenu : titre de l objet, une ligne par interlocuteur, '
        'le badge des non-lus, l ecart de la page hote', (
      WidgetTester tester,
    ) async {
      await _monter(tester, port: _port());
      expect(
        _dansGroupe(find.text(t.com.messages.entree.titreClasse)),
        findsOneWidget,
      );
      expect(
        _dansGroupe(find.text(t.com.messages.entree.ecrireFamille)),
        findsNWidgets(2),
      );
      expect(_dansGroupe(find.text('Parent 1, Parent de Eleve 1')), findsOne);
      expect(_dansGroupe(find.byType(BadgeNonLu)), findsOneWidget);
      // L'ecart de la page hote est rendu avec le contenu.
      expect(
        find.descendant(
          of: find.byType(EntreeMessagesContexte),
          matching: find.byWidget(Ecart.vSection),
        ),
        findsOneWidget,
      );
    });

    testWidgets('vide : rien n est rendu, ni groupe ni ecart', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        port: _port(conversations: const <ConversationPossible>[]),
      );
      expect(_groupe, findsNothing);
      expect(
        find.descendant(
          of: find.byType(EntreeMessagesContexte),
          matching: find.byType(SizedBox),
        ),
        findsOneWidget,
      );
      expect(tester.getSize(find.byType(EntreeMessagesContexte)).height, 0);
    });

    testWidgets('erreur : « Reessayer » relit et rend le contenu', (
      WidgetTester tester,
    ) async {
      final FauxMessagesMetier port = _port()
        ..erreurConversations = Exception('reseau');
      await _monter(tester, port: port);
      expect(find.text(t.com.socle.composants.etats.erreurTitre), findsOne);
      port.erreurConversations = null;
      await tester.tap(find.text(t.com.socle.composants.etats.reessayer));
      await tester.pumpAndSettle();
      expect(port.lecturesConversations, 2);
      expect(_groupe, findsOneWidget);
    });

    testWidgets('hors ligne : l etat hors ligne et « Reessayer »', (
      WidgetTester tester,
    ) async {
      final FauxMessagesMetier port = _port()
        ..erreurConversations = Exception('hors ligne');
      await _monter(tester, port: port, horsLigne: true);
      expect(find.text(t.com.socle.composants.etats.horsLigne), findsOneWidget);
      expect(find.text(t.com.socle.composants.etats.reessayer), findsOne);
      expect(_groupe, findsNothing);
    });

    testWidgets('indisponible (production) : rien n est rendu, la page '
        'hote reste celle d avant', (WidgetTester tester) async {
      await _monter(tester, port: const MessagesMetierIndisponibles());
      expect(_groupe, findsNothing);
      expect(find.byType(EtatSysteme), findsNothing);
      expect(find.text('hote-classe'), findsOneWidget);
      expect(tester.getSize(find.byType(EntreeMessagesContexte)).height, 0);
    });

    testWidgets('ecriture fermee (COM-BR-16) : seul le fil existant reste, '
        'nomme sans « Ecrire »', (WidgetTester tester) async {
      await _monter(tester, port: _port(), ecritureOuverte: false);
      expect(
        _dansGroupe(
          find.text(t.com.messages.entree.conversationAvec(nom: 'Parent 1')),
        ),
        findsOneWidget,
      );
      expect(
        _dansGroupe(find.text(t.com.messages.entree.ecrireFamille)),
        findsNothing,
      );
      expect(_dansGroupe(find.textContaining('Parent 2')), findsNothing);
    });

    testWidgets('plus de cinq conversations : cinq lignes, puis « Voir '
        'toutes les conversations » ouvre la liste', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(
        tester,
        port: _port(
          conversations: <ConversationPossible>[
            for (int i = 1; i <= 7; i++) _conversation(i, filId: 'fil-$i'),
          ],
        ),
      );
      expect(
        _dansGroupe(find.text(t.com.messages.entree.ecrireFamille)),
        findsNWidgets(limiteConversationsEntree),
      );
      await tester.tap(find.text(t.com.messages.entree.voirTout));
      await tester.pumpAndSettle();
      expect(cheminCourant(routeur), Routes.enseignantMessages);
      expect(find.text('liste-enseignant'), findsOneWidget);
    });

    testWidgets('fil existant : ouvert sans redemander l objet', (
      WidgetTester tester,
    ) async {
      final FauxMessagesMetier port = _port();
      final GoRouter routeur = await _monter(tester, port: port);
      await tester.tap(find.text('Parent 1, Parent de Eleve 1'));
      await tester.pumpAndSettle();
      expect(cheminCourant(routeur), Routes.enseignantFilPour('fil-1'));
      expect(port.objetsDemandes, isEmpty);
    });

    testWidgets('§25 fil inaccessible : la paire est refusee, l etat le '
        'dit sous le groupe, l adresse ne change pas', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(tester, port: _port());
      await tester.tap(find.text('Parent 2, Parent de Eleve 2'));
      await tester.pumpAndSettle();
      expect(cheminCourant(routeur), '${Routes.enseignantGroupe}/$_classe');
      final Finder echec = find.byKey(EntreeMessagesContexte.cleEchec);
      expect(echec, findsOneWidget);
      expect(
        find.descendant(
          of: echec,
          matching: find.text(t.com.messages.entree.inaccessibleTitre),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: echec,
          matching: find.text(t.com.messages.entree.inaccessible),
        ),
        findsOneWidget,
      );
      // L'etat ne colle pas au groupe (K-55) : 16 au moins entre les deux.
      final double basGroupe = tester.getBottomLeft(_groupe).dy;
      final double hautEchec = tester.getTopLeft(echec).dy;
      expect(hautEchec - basGroupe, greaterThanOrEqualTo(AppSpacing.lg));
    });

    testWidgets('ouverture en echec : la cause et quoi faire, puis un nouvel '
        'essai aboutit', (WidgetTester tester) async {
      final FauxMessagesMetier port = _port(
        filsParObjet: <String, String>{
          cleObjet(TypeObjetLie.eleve, 'e2'): 'fil-1',
        },
      )..erreurFilPourObjet = Exception('reseau');
      final GoRouter routeur = await _monter(tester, port: port);
      await tester.tap(find.text('Parent 2, Parent de Eleve 2'));
      await tester.pumpAndSettle();
      expect(
        find.text(t.com.messages.entree.erreurOuvertureTitre),
        findsOneWidget,
      );
      expect(find.text(t.com.messages.entree.ouvertureEchouee), findsOne);
      port.erreurFilPourObjet = null;
      await tester.tap(find.text('Parent 2, Parent de Eleve 2'));
      await tester.pumpAndSettle();
      expect(cheminCourant(routeur), Routes.enseignantFilPour('fil-1'));
    });

    testWidgets('administration : l adresse /admin mene a l onglet Messages, '
        'libelle selon l interlocuteur (« Ecrire a la famille »)', (
      WidgetTester tester,
    ) async {
      final FauxMessagesMetier port = FauxMessagesMetier(
        conversations: <String, List<ConversationPossible>>{
          cleObjet(TypeObjetLie.dossier, 'd1'): <ConversationPossible>[
            ConversationPossible(
              interlocuteur: _famille(1),
              nature: NatureInterlocuteur.famille,
              objet: ObjetLie(
                type: TypeObjetLie.dossier,
                id: 'd1',
                libelle: 'Dossier',
              ),
              filId: 'fil-d1',
            ),
          ],
        },
      );
      final GoRouter routeur = await _monter(
        tester,
        port: port,
        depart: '/admin/personnes/dossiers/d1',
      );
      expect(
        _dansGroupe(find.text(t.com.messages.entree.titreDossier)),
        findsOneWidget,
      );
      expect(
        _dansGroupe(find.text(t.com.messages.entree.ecrireFamille)),
        findsOneWidget,
      );
      await tester.tap(find.text(t.com.messages.entree.ecrireFamille));
      await tester.pumpAndSettle();
      expect(cheminCourant(routeur), Routes.adminFilPour('fil-d1'));
    });

    testWidgets('hors coquille (demonstration) : rien n est rendu', (
      WidgetTester tester,
    ) async {
      final FauxMessagesMetier port = _port();
      await _monter(tester, port: port, depart: '/demo/communications');
      expect(_groupe, findsNothing);
      expect(tester.getSize(find.byType(EntreeMessagesContexte)).height, 0);
    });
  });

  group('Entree generale (Mes classes)', () {
    testWidgets('le badge additionne les non-lus ; la ligne ouvre la liste', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(
        tester,
        port: _port(),
        depart: Routes.enseignantClasses,
      );
      final Finder entree = find.byKey(EntreeMessagesContexte.cleGenerale);
      expect(entree, findsOneWidget);
      expect(
        find.descendant(
          of: entree,
          matching: find.text(t.com.messages.entree.aLire(nombre: 3)),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text(t.com.messages.titre));
      await tester.pumpAndSettle();
      expect(cheminCourant(routeur), Routes.enseignantMessages);
    });

    testWidgets('aucun non-lu : « Toutes vos conversations », sans badge', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        port: FauxMessagesMetier(fils: <FilMetier>[filSimple()]),
        depart: Routes.enseignantClasses,
      );
      expect(find.text(t.com.messages.entree.toutes), findsOneWidget);
      expect(find.byType(BadgeNonLu), findsNothing);
    });

    testWidgets('lecture en echec : la ligne reste, sans badge', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        port: FauxMessagesMetier()..erreurListe = Exception('reseau'),
        depart: Routes.enseignantClasses,
      );
      expect(find.byKey(EntreeMessagesContexte.cleGenerale), findsOneWidget);
      expect(find.byType(BadgeNonLu), findsNothing);
    });

    testWidgets('indisponible (production) : aucune ligne', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        port: const MessagesMetierIndisponibles(),
        depart: Routes.enseignantClasses,
      );
      expect(find.byKey(EntreeMessagesContexte.cleGenerale), findsNothing);
    });
  });

  group('Rendu', () {
    for (final (Size, Brightness) cas in const <(Size, Brightness)>[
      (Size(390, 844), Brightness.light),
      (Size(768, 1024), Brightness.dark),
      (Size(1440, 900), Brightness.light),
    ]) {
      testWidgets('${cas.$1.width.toInt()}, ${cas.$2.name} : le groupe '
          'occupe la largeur, aucune ligne ne deborde', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          port: _port(),
          taille: cas.$1,
          luminosite: cas.$2,
        );
        expect(tester.takeException(), isNull);
        expect(_groupe, findsOneWidget);
        expect(tester.getSize(_groupe).width, cas.$1.width - 2 * AppSpacing.lg);
        // Chaque ligne tient au moins sa cible tactile.
        for (final Element e
            in find
                .descendant(of: _groupe, matching: find.byType(GroupeReglages))
                .evaluate()) {
          expect(e.size!.height, greaterThanOrEqualTo(48));
        }
      });
    }

    testWidgets('arabe (RTL), 390 : le groupe se lit de droite a gauche', (
      WidgetTester tester,
    ) async {
      await _monter(tester, port: _port(), langue: AppLocale.ar);
      expect(tester.takeException(), isNull);
      expect(Directionality.of(tester.element(_groupe)), TextDirection.rtl);
      expect(_dansGroupe(find.text('التواصل بشأن هذا الفصل')), findsOneWidget);
      expect(_dansGroupe(find.text('مراسلة الأسرة')), findsNWidgets(2));
      // Le titre commence au bord droit (debut de ligne en RTL).
      final Rect titre = tester.getRect(
        _dansGroupe(find.text('التواصل بشأن هذا الفصل')),
      );
      final Rect boite = tester.getRect(_groupe);
      expect(boite.right - titre.right, lessThan(boite.width / 2));
    });

    testWidgets('200 % de texte, 390 : rien ne deborde, les libelles '
        'restent entiers', (WidgetTester tester) async {
      await _monter(tester, port: _port(), echelleTexte: 2);
      expect(tester.takeException(), isNull);
      expect(
        _dansGroupe(find.text(t.com.messages.entree.ecrireFamille)),
        findsNWidgets(2),
      );
    });
  });

  group('Demonstration (hors production)', () {
    test('enseignante : les familles de la Classe An-Nour, fils existants '
        'puis famille a ouvrir', () async {
      final MessagesMetierDemo port = portDemo(
        RoleDemoCommunications.enseignant,
      );
      final List<ConversationPossible> liste = await port
          .conversationsPourObjet(TypeObjetLie.classe, 'classe-an-nour');
      expect(
        liste.map((ConversationPossible c) => c.interlocuteur.id).toList(),
        <String>['p-ahmed', 'p-fatima', 'p-direction', 'p-karim'],
      );
      expect(liste.first.nature, NatureInterlocuteur.famille);
      expect(liste.first.filId, 'fil-adam');
      expect(liste.last.filId, isNull);

      // Ouvrir la famille de Yusuf cree son fil, vide, une seule fois.
      final FilMetier? cree = await port.filPourObjet(
        TypeObjetLie.eleve,
        'eleve-yusuf',
      );
      expect(cree?.id, 'fil-eleve-yusuf');
      expect(cree?.messages, isEmpty);
      expect(cree?.peut(CapaciteFil.ecrire), isTrue);
      expect(
        (await port.filPourObjet(TypeObjetLie.eleve, 'eleve-yusuf'))?.id,
        'fil-eleve-yusuf',
      );
      final List<ConversationPossible> apres = await port
          .conversationsPourObjet(TypeObjetLie.classe, 'classe-an-nour');
      expect(apres, hasLength(4), reason: 'jamais en double');
    });

    test('famille : l enseignante et l Administration ; un autre objet, '
        'rien', () async {
      final MessagesMetierDemo port = portDemo(RoleDemoCommunications.tuteur);
      final List<ConversationPossible> liste = await port
          .conversationsPourObjet(TypeObjetLie.classe, 'classe-an-nour');
      expect(
        liste.map((ConversationPossible c) => c.nature).toList(),
        <NatureInterlocuteur>[
          NatureInterlocuteur.personne,
          NatureInterlocuteur.administration,
        ],
      );
      expect(
        await port.conversationsPourObjet(TypeObjetLie.classe, 'autre'),
        isEmpty,
      );
      expect(
        await port.filPourObjet(TypeObjetLie.eleve, 'eleve-yusuf'),
        isNull,
        reason: 'une famille n ouvre pas le fil d une autre famille',
      );
    });
  });
}
