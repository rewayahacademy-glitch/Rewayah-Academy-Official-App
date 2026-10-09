// COM-RC, lot A (revue COM-R) : fil de discussion et vocal.
//
// Chaque test ne s'appuie que sur l'API publique d'avant COM-RC (cles du
// champ, de l'envoi, du composer vocal, types des composants) : rejoues sur
// `de2bdb64`, ils echouent ; ils passent apres la correction.
//
// - R-02 : a texte x2 sur 320, le fil Messages (tuteur, admin) et le canal
//   du Studio montrent un message ET le champ, sans debordement ; (i) est
//   dans la rangee de l'en-tete du fil ;
// - R-04 : pendant la pre-ecoute, la rangee texte s'efface (un seul
//   « Envoyer ») et revient ensuite, son texte garde ; le vocal recu de la
//   demonstration se lit (Messages et Studio) ;
// - R-11 : la piece non vocale est une carte dans la bulle ;
// - R-22 : le fil Messages garde son brouillon d'un fil a l'autre ;
// - R-24 : un fil en ecriture sans message le dit ;
// - R-25 : Ctrl+Entree envoie, Entree seule n'envoie pas (fil, publication
//   de la Communaute, publieur d'annonce).

import 'package:flutter/gestures.dart' show HitTestEntry;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/communications/capacites_communication.dart';
import 'package:rewayah_academy/core/communications/port_brouillons.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/carte_piece_jointe.dart';
import 'package:rewayah_academy/core/widgets/empty_state.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/espace_travail_adaptatif.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/features/com_messages/entete_fil_contexte.dart';
import 'package:rewayah_academy/features/com_messages/messages_admin.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';
import 'package:rewayah_academy/features/com_studio/canal_page.dart';
import 'package:rewayah_academy/features/com_studio/port_studio.dart'
    show Canal;
import 'package:rewayah_academy/features/com_vocal/composer_vocal.dart';
import 'package:rewayah_academy/features/com_vocal/envoi_vocal.dart';
import 'package:rewayah_academy/features/com_vocal/lecteur_vocal.dart';
import 'package:rewayah_academy/features/com_vocal/port_enregistreur_vocal.dart';
import 'package:rewayah_academy/features/demo/communications/com_vocal_demo.dart';
import 'package:rewayah_academy/features/demo/communications/demo_communications_page.dart';

import '../../support/harnais.dart' show FauxServiceReseau;
import '../com_studio/support_studio.dart' as studio;
import '../com_vocal/support_vocal.dart';
import 'support_messages.dart';

const Size _petit = Size(320, 568);
const Size _telephone = Size(390, 844);

Finder _dansFil(Finder f) =>
    find.descendant(of: find.byType(FilDiscussion), matching: f);

/// La liste des messages du fil (premier defilant du fil).
Finder get _listeFil => _dansFil(find.byType(CustomScrollView)).first;

/// Les bulles rendues du fil.
Finder get _bulles => _dansFil(
  find.byWidgetPredicate(
    (Widget w) =>
        w.key is ValueKey<String> &&
        (w.key! as ValueKey<String>).value.startsWith('message-'),
  ),
);

/// Vrai quand [o] est [ancetre] ou l'un de ses descendants.
bool _sous(RenderObject o, RenderObject ancetre) {
  RenderObject? courant = o;
  while (courant != null) {
    if (identical(courant, ancetre)) return true;
    courant = courant.parent;
  }
  return false;
}

/// Le fil montre au moins une bulle et le champ AU PREMIER ECRAN, sans rien
/// faire defiler, et sans debordement (R-02, COM-RC tour 2) : la tete de la
/// page ne repousse plus le champ sous le pli. Elle reste atteignable en
/// remontant le fil.
Future<void> _filLisible(
  WidgetTester tester,
  Size taille, {
  required Finder titrePage,
}) async {
  expect(tester.takeException(), isNull);
  expect(find.byKey(FilDiscussion.champKey), findsOneWidget);
  final Rect liste = tester.getRect(_listeFil);
  expect(liste.height, greaterThan(100), reason: 'la liste a de la place');
  final Rect champ = tester.getRect(find.byKey(FilDiscussion.champKey));
  expect(champ.top, greaterThanOrEqualTo(0));
  // La saisie est bornee a 40 % de la hauteur et defile elle-meme : la
  // ligne d'ecriture du champ (une cible de 48) est a l'ecran.
  expect(
    champ.top + AppTouchTarget.standard,
    lessThanOrEqualTo(taille.height),
    reason: 'le champ est a l ecran au premier ecran',
  );
  // COM-RC tour 3 : « Envoyer » est entier au premier ecran, et rien ne le
  // couvre ni ne le coupe (le defilement initial va jusqu'au bas de la
  // saisie, pas seulement jusqu'au dernier message).
  final Finder envoyer = find.byKey(FilDiscussion.envoyerKey);
  final Rect bouton = tester.getRect(envoyer);
  expect(
    bouton.top >= 0 && bouton.bottom <= taille.height,
    isTrue,
    reason: '« Envoyer » ($bouton) est entier au premier ecran',
  );
  expect(bouton.top, greaterThanOrEqualTo(champ.bottom));
  for (final Offset coin in <Offset>[
    bouton.topLeft + const Offset(2, 2),
    bouton.bottomRight - const Offset(2, 2),
  ]) {
    expect(
      tester
          .hitTestOnBinding(coin)
          .path
          .any(
            (HitTestEntry e) =>
                e.target is RenderObject &&
                _sous(e.target as RenderObject, tester.renderObject(envoyer)),
          ),
      isTrue,
      reason: 'le toucher en $coin atteint « Envoyer »',
    );
  }
  expect(_bulles, findsWidgets);
  final bool uneVisible = _bulles.evaluate().any((Element e) {
    final Rect r = tester.getRect(
      find.byElementPredicate((Element x) => x == e),
    );
    return r.bottom > liste.top &&
        r.top < liste.bottom &&
        r.top < taille.height &&
        r.bottom > 0;
  });
  expect(uneVisible, isTrue, reason: 'au moins un message au premier ecran');
  expect(tester.takeException(), isNull);
  // La tete de la page n'a pas disparu : elle defile avec le fil.
  await tester.scrollUntilVisible(
    titrePage,
    -200,
    scrollable: find
        .descendant(of: _listeFil, matching: find.byType(Scrollable))
        .first,
  );
  expect(titrePage, findsOneWidget);
  expect(tester.takeException(), isNull);
}

/// Ctrl+Entree, depuis le champ qui a le focus.
Future<void> _ctrlEntree(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pumpAndSettle();
}

/// Les doubles du vocal, capacite ouverte (Messages : ecrire aussi).
List<Override> _vocal(HorlogeManuelle horloge) => <Override>[
  portEnregistreurVocalProvider.overrideWithValue(
    EnregistreurVocalDemonstration(horloge: horloge.horloge),
  ),
  portLectureVocaleProvider.overrideWithValue(
    LecturesVocalesDemonstration(horloge: horloge.horloge),
  ),
  horlogeVocaleProvider.overrideWithValue(horloge.horloge),
  portEnvoiVocalProvider.overrideWithValue(EnvoiVocalDemonstration()),
  portCapacitesCommunicationsProvider.overrideWithValue(
    const CapacitesCommunicationsFixes(<CapaciteCommunication>{
      CapaciteCommunication.ecrireDansFil,
      CapaciteCommunication.envoyerVocal,
    }),
  ),
];

Future<void> _toucher(WidgetTester tester, Key cle) async {
  await tester.ensureVisible(find.byKey(cle));
  await tester.tap(find.byKey(cle));
  await tester.pump();
  await tester.pump();
}

/// Monte l'onglet Messages de l'administration sur le fil [filId].
Future<void> _monterAdmin(
  WidgetTester tester, {
  required PortMessagesMetier port,
  required String filId,
  required Size taille,
  double echelleTexte = 1,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final GoRouter routeur = GoRouter(
    initialLocation: Routes.adminFilPour(filId),
    routes: <RouteBase>[
      GoRoute(
        path: Routes.adminCommunicationsMessages,
        builder: (BuildContext _, GoRouterState _) => const MessagesAdminPage(),
        routes: <RouteBase>[
          GoRoute(
            path: ':filId',
            builder: (BuildContext _, GoRouterState etat) =>
                MessagesAdminPage(filId: etat.pathParameters['filId']),
          ),
        ],
      ),
    ],
  );
  addTearDown(routeur.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
        portMessagesMetierProvider.overrideWithValue(port),
        capaciteEcrireOuverteTest,
      ],
      child: TranslationProvider(
        child: MaterialApp.router(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          locale: AppLocale.fr.flutterLocale,
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
  await tester.pumpAndSettle();
}

void main() {
  group('R-02 : texte x2 a 320, le fil se lit et s ecrit', () {
    testWidgets('Messages du tuteur', (WidgetTester tester) async {
      await monterMessages(
        tester,
        port: portDemo(RoleDemoCommunications.tuteur),
        depart: cheminFilTest('fil-adam'),
        taille: _petit,
        echelleTexte: 2,
      );
      await _filLisible(
        tester,
        _petit,
        titrePage: find.text(t.com.messages.titre),
      );
    });

    testWidgets('Messages de l enseignant', (WidgetTester tester) async {
      await monterMessages(
        tester,
        port: portDemo(RoleDemoCommunications.enseignant),
        depart: cheminFilTest('fil-yasmine'),
        taille: _petit,
        echelleTexte: 2,
      );
      await _filLisible(
        tester,
        _petit,
        titrePage: find.text(t.com.messages.titre),
      );
    });

    testWidgets('Messages de l administration', (WidgetTester tester) async {
      await _monterAdmin(
        tester,
        port: FauxMessagesMetier(fils: <FilMetier>[filSimple()]),
        filId: 'fil-1',
        taille: _petit,
        echelleTexte: 2,
      );
      await _filLisible(
        tester,
        _petit,
        // Le titre de la spec, ou son repli sur l'onglet (R-09) : l'en-tete
        // de la page, avec son retour.
        titrePage: find.byType(EntetePage),
      );
    });

    testWidgets('canal du Studio', (WidgetTester tester) async {
      await studio.monterStudio(
        tester,
        port: studio.portDemo(),
        depart: Routes.canalStudioPour('organisation'),
        taille: _petit,
        echelleTexte: 2,
      );
      await _filLisible(
        tester,
        _petit,
        titrePage: find.text(t.com.studio.titre),
      );
    });

    testWidgets('390 : (i) est dans la rangee de l en-tete du fil, pas dans '
        'une rangee a part', (WidgetTester tester) async {
      await monterMessages(
        tester,
        port: portDemo(RoleDemoCommunications.tuteur),
        depart: cheminFilTest('fil-adam'),
        taille: _telephone,
      );
      final Finder info = find.byKey(EspaceTravailAdaptatif.cleOuvrirContexte);
      expect(info, findsOneWidget);
      expect(_dansFil(info), findsOneWidget);
      final Rect entete = tester.getRect(find.byType(EnteteFilContexte));
      final Rect bouton = tester.getRect(info);
      expect(bouton.top, greaterThanOrEqualTo(entete.top));
      expect(bouton.top, lessThan(entete.bottom));
      expect(tester.takeException(), isNull);
    });
  });

  group('R-04 : un seul « Envoyer » pendant le vocal', () {
    testWidgets('390 : la pre-ecoute remplace la rangee texte, qui revient '
        'avec son texte', (WidgetTester tester) async {
      final HorlogeManuelle horloge = HorlogeManuelle();
      await monterMessages(
        tester,
        port: FauxMessagesMetier(fils: <FilMetier>[filSimple()]),
        depart: cheminFilTest('fil-1'),
        taille: _telephone,
        ecritureOuverte: false,
        surcharges: _vocal(horloge),
      );
      await tester.enterText(find.byKey(FilDiscussion.champKey), 'Je reviens');
      await tester.pump();
      await _toucher(tester, FilDiscussion.cleMicro);
      // Enregistrement : le panneau seul.
      expect(find.byKey(FilDiscussion.champKey), findsNothing);
      expect(find.byKey(FilDiscussion.envoyerKey), findsNothing);
      await avancer(tester, horloge, const Duration(seconds: 5));
      await _toucher(tester, ComposerVocal.cleArreter);
      // Pre-ecoute : un seul « Envoyer », celui du vocal.
      expect(find.byKey(ComposerVocal.cleEnvoyer), findsOneWidget);
      expect(find.byKey(FilDiscussion.envoyerKey), findsNothing);
      expect(find.byKey(FilDiscussion.champKey), findsNothing);
      // Le vocal supprime, la rangee texte revient, son texte garde.
      await _toucher(tester, ComposerVocal.cleSupprimer);
      await _toucher(tester, ComposerVocal.cleConfirmerSuppression);
      await tester.pumpAndSettle();
      expect(find.byKey(FilDiscussion.champKey), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(FilDiscussion.champKey))
            .controller!
            .text,
        'Je reviens',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Messages, demonstration : le vocal recu se lit', (
      WidgetTester tester,
    ) async {
      await monterMessages(
        tester,
        port: portDemo(RoleDemoCommunications.tuteur),
        depart: cheminFilTest('fil-adam'),
        taille: _telephone,
      );
      await tester.scrollUntilVisible(
        _dansFil(find.byType(LecteurVocalRecu)),
        -200,
        scrollable: _dansFil(find.byType(Scrollable)).first,
      );
      expect(
        find.descendant(
          of: find.byType(LecteurVocalRecu),
          matching: find.byKey(LecteurVocal.cleAction),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Studio, demonstration : le vocal recu se lit', (
      WidgetTester tester,
    ) async {
      await studio.monterStudio(
        tester,
        port: studio.portDemo(),
        depart: Routes.canalStudioPour('organisation'),
      );
      expect(
        find.descendant(
          of: _dansFil(find.byType(LecteurVocalRecu)),
          matching: find.byKey(LecteurVocal.cleAction),
        ),
        findsOneWidget,
      );
    });
  });

  testWidgets('R-11 : la piece non vocale est une carte dans la bulle', (
    WidgetTester tester,
  ) async {
    await monterMessages(
      tester,
      port: portDemo(RoleDemoCommunications.tuteur),
      depart: cheminFilTest('fil-adam'),
      taille: _telephone,
    );
    final Finder carte = _dansFil(find.byType(CartePieceJointe));
    expect(carte, findsOneWidget);
    expect(
      // Le nom complet est lu ; a l'ecran, il peut etre raccourci par le
      // milieu (COM-RC tour 2, R-11).
      find.descendant(
        of: carte,
        matching: find.byWidgetPredicate(
          (Widget w) =>
              w is Semantics && w.properties.label == 'Devoir_semaine_3.pdf',
        ),
      ),
      findsOneWidget,
    );
    expect(
      _dansFil(
        find.text(
          t.com.socle.composants.lecture.pieceJointe(
            nom: 'Devoir_semaine_3.pdf',
          ),
        ),
      ),
      findsNothing,
    );
  });

  testWidgets('R-22 : le fil Messages garde son brouillon d un fil a l autre', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = await monterMessages(
      tester,
      port: FauxMessagesMetier(
        fils: <FilMetier>[
          filSimple(),
          filSimple(id: 'fil-2'),
        ],
      ),
      depart: cheminFilTest('fil-1'),
      surcharges: <Override>[
        portBrouillonsProvider.overrideWithValue(BrouillonsMemoire()),
      ],
    );
    await tester.enterText(find.byKey(FilDiscussion.champKey), 'A reprendre');
    await tester.pump();
    routeur.go(cheminFilTest('fil-2'));
    await tester.pumpAndSettle();
    String champ() => tester
        .widget<TextField>(find.byKey(FilDiscussion.champKey))
        .controller!
        .text;
    expect(champ(), isEmpty, reason: 'jamais le texte d un autre fil');
    routeur.go(cheminFilTest('fil-1'));
    await tester.pumpAndSettle();
    expect(champ(), 'A reprendre');
    expect(tester.takeException(), isNull);
  });

  testWidgets('R-24 : un fil en ecriture sans message le dit', (
    WidgetTester tester,
  ) async {
    await monterMessages(
      tester,
      port: FauxMessagesMetier(
        fils: <FilMetier>[
          FilMetier(
            id: 'fil-1',
            contexte: filSimple().contexte,
            participants: filSimple().participants,
            messages: const <MessageCommunication>[],
            capacites: const <CapaciteFil>{CapaciteFil.ecrire},
          ),
        ],
      ),
      depart: cheminFilTest('fil-1'),
      taille: _telephone,
    );
    expect(_dansFil(find.byType(EmptyState)), findsOneWidget);
    expect(find.byKey(FilDiscussion.champKey), findsOneWidget);
  });

  group('R-25 : Ctrl+Entree envoie, Entree garde le saut de ligne', () {
    testWidgets('fil de discussion', (WidgetTester tester) async {
      final List<String> envoyes = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          home: Scaffold(
            body: FilDiscussion(
              messages: const <MessageFil>[],
              textes: TextesFilDiscussion(
                aideChamp: 'aide',
                libelleChamp: 'champ',
                envoyer: 'Envoyer',
                champVide: 'vide',
                enCours: 'en cours',
                envoye: 'envoye',
                echec: 'echec',
                reessayer: 'reessayer',
                auteurSoi: 'Vous',
                annonce: (String a, String b) => '$a $b',
              ),
              onEnvoyer: (String texte) async => envoyes.add(texte),
            ),
          ),
        ),
      );
      await tester.enterText(find.byKey(FilDiscussion.champKey), 'Bonjour');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(envoyes, isEmpty, reason: 'Entree seule n envoie pas');
      await _ctrlEntree(tester);
      expect(envoyes, <String>['Bonjour']);
      // Cmd+Entree aussi (Mac).
      await tester.enterText(find.byKey(FilDiscussion.champKey), 'Encore');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await tester.pumpAndSettle();
      expect(envoyes, <String>['Bonjour', 'Encore']);
    });

    testWidgets('canal du Studio', (WidgetTester tester) async {
      final studio.FauxStudio port = studio.FauxStudio(
        canaux: <Canal>[studio.canalSimple(id: 'c1', nom: 'Coordination')],
      );
      await studio.monterStudio(
        tester,
        port: port,
        depart: Routes.canalStudioPour('c1'),
      );
      await tester.enterText(find.byKey(FilDiscussion.champKey), 'Vu, merci');
      await _ctrlEntree(tester);
      expect(port.envois.single.$2, 'Vu, merci');
      expect(find.byType(CanalStudio), findsOneWidget);
    });
  });
}
