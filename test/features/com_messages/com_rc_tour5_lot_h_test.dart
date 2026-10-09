// COM-RC tour 5, lot H (contre-verification COM-R-3, section 7.3, et deux
// decisions du directeur), cote fil de discussion.
//
// Chaque test dit sa contre-preuve : ce qui echouait a 27689f94.
//
// - constat 1 : un accuse efface le brouillon de SON texte, meme apres un
//   echec ou la fermeture du fil ; un texte envoye ne revient jamais, meme
//   dans un fil rouvert avant l'accuse (contre-verification) ;
// - constat 2 : en lecture seule, l'en-tete complet reste a 1440 ;
// - constat 3 (N-9) : le panneau de pre-ecoute se lit en entier ;
// - constat 6 : l'entree dans le Focus ne se compte plus pendant `build` ;
// - constat 7 : N-1 pour l'enseignant et pour le Focus en vue basse ;
// - constat 8 : le nom se lit a 320 x2, un retour reste visible ;
// - decision « Focus a 320 » : la saisie se reduit a une ligne, une bulle
//   reste visible ;
// - decision R-28 : un micro a cote d'« Envoyer ».

import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/profils_locaux.dart';
import 'package:rewayah_academy/core/cache/db/app_database.dart';
import 'package:rewayah_academy/core/communications/capacites_communication.dart';
import 'package:rewayah_academy/core/communications/port_brouillons.dart';
import 'package:rewayah_academy/core/communications/port_elements_enregistres.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/espace_travail_adaptatif.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/com_messages/entete_fil_contexte.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';
import 'package:rewayah_academy/features/com_studio/canal_page.dart';
import 'package:rewayah_academy/features/com_studio/focus/bascule_focus.dart';
import 'package:rewayah_academy/features/com_studio/port_activite_studio.dart';
import 'package:rewayah_academy/features/com_studio/port_studio.dart';
import 'package:rewayah_academy/features/com_studio/studio_page.dart';
import 'package:rewayah_academy/features/com_vocal/composer_vocal.dart';
import 'package:rewayah_academy/features/demo/communications/com_messages_demo.dart';
import 'package:rewayah_academy/features/demo/communications/com_studio_demo.dart';
import 'package:rewayah_academy/features/demo/communications/com_vocal_demo.dart';
import 'package:rewayah_academy/features/demo/communications/demo_communications_page.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';

import '../../capture/outil_capture.dart'
    show chargerPolicesDuDepot, fixerVueCapture;
import '../../router/support_routeur.dart' hide stabiliser;
import '../../support/envoi_fil.dart';
import '../../support/harnais.dart';
import '../com_vocal/support_vocal.dart';

/// L'heure des donnees de demonstration (celle des captures).
final DateTime _maintenant = DateTime.utc(2026, 10, 4, 12);

const Size _telephone = Size(390, 844);
const Size _petit = Size(320, 640);
const Size _bureau = Size(1440, 900);

/// Une vue basse (telephone a l'horizontale) : sous 480 points.
const Size _basse = Size(844, 390);

/// La zone sure d'un telephone de 390 (celle des captures).
const EdgeInsets _zone390 = EdgeInsets.only(top: 47, bottom: 34);

Override _baseMemoire() => baseLocaleProvider.overrideWith((Ref ref) {
  final AppDatabase base = AppDatabase.surExecuteur(NativeDatabase.memory());
  ref.onDispose(base.close);
  return base;
});

List<Override> _role(AppRole role) => <Override>[
  ...surchargesRouteur(FausseSourceSession(sessionActive(role))),
  _baseMemoire(),
];

List<Override> _admin() => <Override>[
  ...surchargesDemoAdmin(environnement: 'staging'),
  _baseMemoire(),
];

List<Override> _messages(
  RoleDemoCommunications role, {
  HorlogeManuelle? horloge,
}) => <Override>[
  portMessagesMetierProvider.overrideWithValue(
    MessagesMetierDemo(role: role, maintenant: _maintenant),
  ),
  portCapacitesCommunicationsProvider.overrideWithValue(
    const CapacitesCommunicationsFixes(<CapaciteCommunication>{
      CapaciteCommunication.ecrireDansFil,
      CapaciteCommunication.envoyerVocal,
    }),
  ),
  if (horloge == null)
    ...surchargesVocalDemo()
  else
    ...surchargesVocalDemo(horloge: horloge.horloge),
];

List<Override> _studio() => <Override>[
  portStudioProvider.overrideWithValue(StudioDemo(maintenant: _maintenant)),
  portActiviteStudioProvider.overrideWithValue(
    ActiviteStudioDemo(maintenant: _maintenant),
  ),
  portBrouillonsProvider.overrideWithValue(
    brouillonsStudioDemo(
      SituationDemoStudio.normale,
      maintenant: () => _maintenant,
    ),
  ),
  portElementsEnregistresProvider.overrideWithValue(
    ElementsEnregistresMemoire(),
  ),
  portCapacitesCommunicationsProvider.overrideWithValue(
    const CapacitesCommunicationsFixes(<CapaciteCommunication>{
      CapaciteCommunication.envoyerVocal,
    }),
  ),
  ...surchargesVocalDemo(),
];

Future<void> _attendre(WidgetTester tester) async {
  for (int i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Le vrai routeur, dans la vraie coquille du role, sur [chemin], a
/// [taille] (densite 2) et texte x[echelle].
Future<GoRouter> _monterDansLaCoquille(
  WidgetTester tester,
  String chemin,
  List<Override> surcharges, {
  required Size taille,
  required double echelle,
}) async {
  fixerVueCapture(
    tester,
    taille,
    2,
    zoneSure: taille.width == _telephone.width ? _zone390 : EdgeInsets.zero,
  );
  tester.platformDispatcher.textScaleFactorTestValue = echelle;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: surcharges,
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext context, WidgetRef ref, Widget? _) {
            routeur = ref.read(routeurProvider);
            return MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              locale: TranslationProvider.of(context).flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              routerConfig: routeur,
            );
          },
        ),
      ),
    ),
  );
  await _attendre(tester);
  routeur.go(chemin);
  await _attendre(tester);
  return routeur;
}

/// Vrai quand le toucher en [point] atteint [cible] (rien ne la couvre).
bool _atteint(WidgetTester tester, Finder cible, Offset point) {
  final RenderObject boite = tester.renderObject(cible);
  final HitTestResult resultat = HitTestResult();
  tester.binding.hitTestInView(resultat, point, tester.view.viewId);
  return resultat.path.any((HitTestEntry e) {
    final Object c = e.target;
    if (c is! RenderObject) return false;
    RenderObject? o = c;
    while (o != null) {
      if (identical(o, boite)) return true;
      o = o.parent;
    }
    return false;
  });
}

/// [f] est entier dans l'ecran [taille], au-dessus de la barre basse, et
/// son centre se touche.
void _entierALEcran(WidgetTester tester, Finder f, Size taille, String nom) {
  expect(f, findsOneWidget, reason: '$nom est rendu');
  final Rect r = tester.getRect(f);
  expect(
    r.top >= 0 &&
        r.left >= 0 &&
        r.bottom <= taille.height &&
        r.right <= taille.width,
    isTrue,
    reason: '$nom ($r) est entier dans l ecran',
  );
  final Finder barre = find.byKey(NavShell.barreBasseKey);
  if (barre.evaluate().isNotEmpty) {
    expect(
      r.bottom,
      lessThanOrEqualTo(tester.getRect(barre).top),
      reason: '$nom est au-dessus de la barre de navigation',
    );
  }
  expect(_atteint(tester, f, r.center), isTrue, reason: '$nom se touche');
}

/// La ligne compacte est fixe au-dessus de la liste, entiere, et [textes]
/// s'y lisent.
void _ligneCompacteFixe(
  WidgetTester tester,
  Size taille, {
  required List<String> textes,
}) {
  final Finder compacte = find.byKey(FilDiscussion.cleEnteteCompacte);
  expect(compacte, findsOneWidget, reason: 'la ligne de contexte est rendue');
  final Rect ligne = tester.getRect(compacte);
  expect(ligne.top >= 0 && ligne.bottom <= taille.height, isTrue);
  expect(
    find.descendant(
      of: find.byKey(FilDiscussion.cleMessages),
      matching: compacte,
    ),
    findsNothing,
    reason: 'la ligne est hors de la liste qui defile',
  );
  expect(
    ligne.bottom,
    lessThanOrEqualTo(
      tester.getRect(find.byKey(FilDiscussion.cleMessages)).top,
    ),
  );
  for (final String texte in textes) {
    final Finder f = find.descendant(
      of: compacte,
      matching: find.textContaining(texte),
    );
    expect(f, findsOneWidget, reason: '« $texte » est dans la ligne');
    final Rect r = tester.getRect(f);
    expect(_atteint(tester, f, r.center), isTrue, reason: '« $texte » se voit');
  }
}

/// Les textes d'un fil de test.
final TextesFilDiscussion _textes = TextesFilDiscussion(
  aideChamp: 'Message',
  libelleChamp: 'Message',
  envoyer: 'Envoyer',
  champVide: 'Ecrivez un message.',
  enCours: 'En cours',
  envoye: 'Envoye',
  echec: 'Non confirme',
  reessayer: 'Reessayer',
  auteurSoi: 'Vous',
  annonce: (String a, String texte) => '$a : $texte',
);

/// Un ecran nu : vrai theme, [taille], texte x[echelle].
Future<void> _monterNu(
  WidgetTester tester,
  Widget enfant, {
  Size taille = _telephone,
  double echelle = 1,
  List<Override> surcharges = const <Override>[],
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = echelle;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
        ...surcharges,
      ],
      child: TranslationProvider(
        child: Builder(
          builder: (BuildContext context) => MaterialApp(
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            locale: TranslationProvider.of(context).flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: Scaffold(body: enfant),
          ),
        ),
      ),
    ),
  );
  await _attendre(tester);
}

const CleBrouillon _cle = CleBrouillon(
  type: TypeObjetLie.message,
  objetId: 'fil-lot-h',
);

TextEditingController _champ(WidgetTester tester) =>
    tester.widget<TextField>(find.byKey(FilDiscussion.champKey)).controller!;

/// Un message recu, pour qu'un fil ait une bulle.
const MessageFil _recu = MessageFil(
  id: 'm1',
  auteur: 'Sayyida Mariam',
  texte: 'Bonjour',
  horodatage: 'Lundi',
  deSoi: false,
);

/// Entre dans le Focus du Studio par « Mode focus » (l'en-tete du canal
/// defile avec le fil a texte agrandi ou en vue basse).
Future<void> _entrerFocus(WidgetTester tester) async {
  final Finder entrer = find.byKey(BasculeFocus.cleEntrer);
  if (entrer.evaluate().isEmpty) {
    tester
        .state<ScrollableState>(
          find
              .descendant(
                of: find.byKey(FilDiscussion.cleMessages),
                matching: find.byType(Scrollable),
              )
              .first,
        )
        .position
        .jumpTo(0);
    await tester.pump();
  }
  await tester.ensureVisible(entrer);
  await _attendre(tester);
  await tester.tap(entrer);
  await _attendre(tester);
}

void main() {
  setUpAll(chargerPolicesDuDepot);

  group('constat 1 : un accuse efface le brouillon de son texte', () {
    testWidgets('A echoue, puis B est confirme : le brouillon de B '
        's efface, B ne revient pas', (WidgetTester tester) async {
      // Contre-preuve : a 27689f94, la bulle A en echec bloquait tout
      // effacement : le brouillon gardait « Second » apres son accuse.
      final BrouillonsMemoire brouillons = BrouillonsMemoire();
      int essais = 0;
      await _monterNu(
        tester,
        FilDiscussion(
          messages: const <MessageFil>[],
          textes: _textes,
          cleBrouillon: _cle,
          onEnvoyer: (String _) async {
            essais++;
            if (essais == 1) throw StateError('hors ligne');
          },
        ),
        surcharges: <Override>[
          portBrouillonsProvider.overrideWithValue(brouillons),
        ],
      );
      await tester.enterText(find.byKey(FilDiscussion.champKey), 'Premier');
      await tester.pump();
      await tester.tap(envoiDuFil());
      await _attendre(tester);
      expect(find.text('Non confirme'), findsOneWidget);
      // L'echec garde son texte en brouillon (N-3).
      expect((await brouillons.lire(_cle))?.texte, 'Premier');
      await tester.enterText(find.byKey(FilDiscussion.champKey), 'Second');
      await tester.pump();
      expect((await brouillons.lire(_cle))?.texte, 'Second');
      await tester.tap(envoiDuFil());
      await _attendre(tester);
      expect(find.text('Envoye'), findsOneWidget);
      expect(await brouillons.lire(_cle), isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('un accuse arrive apres la fermeture du fil efface le '
        'brouillon : le texte envoye ne revient pas a la reouverture', (
      WidgetTester tester,
    ) async {
      // Contre-preuve : a 27689f94, `if (!mounted) return` sautait
      // l'effacement : le texte envoye revenait dans le champ.
      final BrouillonsMemoire brouillons = BrouillonsMemoire();
      final Completer<void> accuse = Completer<void>();
      Widget fil() => FilDiscussion(
        messages: const <MessageFil>[],
        textes: _textes,
        cleBrouillon: _cle,
        onEnvoyer: (String _) => accuse.future,
      );
      final List<Override> surcharges = <Override>[
        portBrouillonsProvider.overrideWithValue(brouillons),
      ];
      await _monterNu(tester, fil(), surcharges: surcharges);
      await tester.enterText(find.byKey(FilDiscussion.champKey), 'Parti');
      await tester.pump();
      await tester.tap(envoiDuFil());
      await tester.pump();
      expect((await brouillons.lire(_cle))?.texte, 'Parti');
      // La personne quitte le fil avant l'accuse.
      await _monterNu(tester, const SizedBox(), surcharges: surcharges);
      accuse.complete();
      await _attendre(tester);
      expect(await brouillons.lire(_cle), isNull);
      // A la reouverture, le champ est vide.
      await _monterNu(tester, fil(), surcharges: surcharges);
      expect(_champ(tester).text, isEmpty);
      expect(find.byKey(FilDiscussion.cleBrouillonRestaure), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('un texte saisi depuis l envoi reste garde a l accuse', (
      WidgetTester tester,
    ) async {
      // Garde-fou : l'accuse de A n'efface pas le brouillon de C.
      final BrouillonsMemoire brouillons = BrouillonsMemoire();
      final Completer<void> accuse = Completer<void>();
      await _monterNu(
        tester,
        FilDiscussion(
          messages: const <MessageFil>[],
          textes: _textes,
          cleBrouillon: _cle,
          onEnvoyer: (String _) => accuse.future,
        ),
        surcharges: <Override>[
          portBrouillonsProvider.overrideWithValue(brouillons),
        ],
      );
      await tester.enterText(find.byKey(FilDiscussion.champKey), 'A');
      await tester.pump();
      await tester.tap(envoiDuFil());
      await tester.pump();
      await tester.enterText(find.byKey(FilDiscussion.champKey), 'C en cours');
      await tester.pump();
      accuse.complete();
      await _attendre(tester);
      expect((await brouillons.lire(_cle))?.texte, 'C en cours');
      expect(_champ(tester).text, 'C en cours');
    });

    testWidgets('un fil rouvert AVANT l accuse ne remet pas le texte parti : '
        'rien ne peut repartir en double', (WidgetTester tester) async {
      // Contre-preuve : a 71e3e555, le fil remonte restaurait « Parti »
      // (« Brouillon restaure ») ; a l'accuse, l'ancien etat effacait le
      // brouillon, mais le champ du nouveau gardait « Parti ».
      final BrouillonsMemoire brouillons = BrouillonsMemoire();
      final Completer<void> accuse = Completer<void>();
      int envois = 0;
      Widget fil() => FilDiscussion(
        messages: const <MessageFil>[],
        textes: _textes,
        cleBrouillon: _cle,
        onEnvoyer: (String _) {
          envois++;
          return accuse.future;
        },
      );
      final List<Override> surcharges = <Override>[
        portBrouillonsProvider.overrideWithValue(brouillons),
      ];
      await _monterNu(tester, fil(), surcharges: surcharges);
      await tester.enterText(find.byKey(FilDiscussion.champKey), 'Parti');
      await tester.pump();
      await tester.tap(envoiDuFil());
      await tester.pump();
      // Le fil est quitte, puis rouvert avant l'accuse.
      await _monterNu(tester, const SizedBox(), surcharges: surcharges);
      await _monterNu(tester, fil(), surcharges: surcharges);
      expect(_champ(tester).text, isEmpty);
      expect(find.byKey(FilDiscussion.cleBrouillonRestaure), findsNothing);
      accuse.complete();
      await _attendre(tester);
      expect(await brouillons.lire(_cle), isNull);
      expect(_champ(tester).text, isEmpty);
      expect(envois, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('COM-RC tour 6 (8.3-1) : A envoye, fil ferme puis rouvert, '
        'B saisi ; l accuse de A garde B (champ et brouillon)', (
      WidgetTester tester,
    ) async {
      // Contre-preuve : a a1a33222, l'ancien etat (ferme) effacait le
      // brouillon sans condition a l'accuse de A : B disparaissait du port.
      final BrouillonsMemoire brouillons = BrouillonsMemoire();
      final Completer<void> accuse = Completer<void>();
      Widget fil() => FilDiscussion(
        messages: const <MessageFil>[],
        textes: _textes,
        cleBrouillon: _cle,
        onEnvoyer: (String _) => accuse.future,
      );
      final List<Override> surcharges = <Override>[
        portBrouillonsProvider.overrideWithValue(brouillons),
      ];
      await _monterNu(tester, fil(), surcharges: surcharges);
      await tester.enterText(find.byKey(FilDiscussion.champKey), 'A');
      await tester.pump();
      await tester.tap(envoiDuFil());
      await tester.pump();
      await _monterNu(tester, const SizedBox(), surcharges: surcharges);
      await _monterNu(tester, fil(), surcharges: surcharges);
      expect(_champ(tester).text, isEmpty);
      await tester.enterText(find.byKey(FilDiscussion.champKey), 'B');
      await tester.pump();
      expect((await brouillons.lire(_cle))?.texte, 'B');
      accuse.complete();
      await _attendre(tester);
      expect(_champ(tester).text, 'B');
      expect((await brouillons.lire(_cle))?.texte, 'B');
      expect(tester.takeException(), isNull);
    });

    testWidgets('a l accuse, un autre fil qui montre encore ce texte remis, '
        'sans modification, vide son champ', (WidgetTester tester) async {
      // Contre-preuve : a 71e3e555, le second fil gardait « Parti » apres
      // l'accuse, pret a partir en double.
      final BrouillonsMemoire brouillons = BrouillonsMemoire();
      await brouillons.enregistrer(_cle, 'Parti');
      final Completer<void> accuse = Completer<void>();
      Widget fil(Key cle) => Expanded(
        child: FilDiscussion(
          key: cle,
          messages: const <MessageFil>[],
          textes: _textes,
          cleBrouillon: _cle,
          onEnvoyer: (String _) => accuse.future,
        ),
      );
      await _monterNu(
        tester,
        Column(
          children: <Widget>[
            fil(const ValueKey<String>('a')),
            fil(const ValueKey<String>('b')),
          ],
        ),
        taille: const Size(390, 1600),
        surcharges: <Override>[
          portBrouillonsProvider.overrideWithValue(brouillons),
        ],
      );
      final Finder champs = find.byKey(FilDiscussion.champKey);
      TextEditingController champ(int i) =>
          tester.widget<TextField>(champs.at(i)).controller!;
      expect(champ(0).text, 'Parti');
      expect(champ(1).text, 'Parti');
      await tester.tap(envoiDuFil().first);
      await tester.pump();
      expect(champ(0).text, isEmpty);
      expect(champ(1).text, 'Parti');
      accuse.complete();
      await _attendre(tester);
      expect(champ(1).text, isEmpty);
      expect(await brouillons.lire(_cle), isNull);
      expect(tester.takeException(), isNull);
    });
  });

  group('constat 2 : la lecture seule garde l en-tete complet a 1440', () {
    Widget filLecture() => FilDiscussion(
      messages: const <MessageFil>[_recu],
      textes: _textes,
      entete: const Text(
        'En-tete complet',
        key: ValueKey<String>('entete-complet'),
      ),
      enteteCompacte: const Text('Ligne compacte'),
      lectureSeule: 'Vous pouvez lire ce canal.',
    );

    testWidgets('1440, texte x1 : l en-tete complet, fixe, sans ligne '
        'compacte', (WidgetTester tester) async {
      // Contre-preuve : a 27689f94, `limite != null` rendait la ligne
      // compacte a toutes les tailles : l'en-tete complet disparaissait.
      await _monterNu(tester, filLecture(), taille: _bureau);
      expect(find.byKey(FilDiscussion.cleEnteteCompacte), findsNothing);
      final Finder entete = find.byKey(
        const ValueKey<String>('entete-complet'),
      );
      expect(entete, findsOneWidget);
      // Fixe : au-dessus de la liste, hors d'elle.
      expect(
        find.descendant(
          of: find.byKey(FilDiscussion.cleMessages),
          matching: entete,
        ),
        findsNothing,
      );
      expect(find.byKey(FilDiscussion.cleLectureSeule), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('320, texte x2 : la ligne compacte, fixe', (
      WidgetTester tester,
    ) async {
      await _monterNu(tester, filLecture(), taille: _petit, echelle: 2);
      expect(find.byKey(FilDiscussion.cleEnteteCompacte), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('entete-complet')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('constat 3 (N-9) : le panneau de pre-ecoute se lit en entier', () {
    Future<void> preEcoute(WidgetTester tester, HorlogeManuelle h) async {
      await tester.ensureVisible(find.byKey(FilDiscussion.cleMicro));
      await tester.tap(find.byKey(FilDiscussion.cleMicro));
      await tester.pump();
      await tester.pump();
      await avancer(tester, h, const Duration(seconds: 5));
      await tester.ensureVisible(find.byKey(ComposerVocal.cleArreter));
      await tester.tap(find.byKey(ComposerVocal.cleArreter));
      await _attendre(tester);
    }

    for (final Size taille in <Size>[_telephone, _bureau]) {
      testWidgets('Messages du tuteur, ${taille.width.toInt()}, texte x1 : la '
          'carte entiere, ses actions se touchent, sans defiler', (
        WidgetTester tester,
      ) async {
        // Contre-preuve : a 27689f94, la saisie bornee a 40 % defilait depuis
        // son haut : le bas du panneau (« Supprimer », « Envoyer ») etait
        // coupe.
        final HorlogeManuelle h = HorlogeManuelle();
        await _monterDansLaCoquille(
          tester,
          Routes.tuteurFilPour('fil-adam'),
          <Override>[
            ..._role(AppRole.guardian),
            ..._messages(RoleDemoCommunications.tuteur, horloge: h),
          ],
          taille: taille,
          echelle: 1,
        );
        await preEcoute(tester, h);
        expect(tester.takeException(), isNull);
        final Finder carte = find
            .ancestor(
              of: find.byKey(ComposerVocal.cleEnvoyer),
              matching: find.byType(AppCard),
            )
            .first;
        final Rect r = tester.getRect(carte);
        final Rect saisie = tester.getRect(find.byKey(FilDiscussion.cleSaisie));
        expect(
          r.top >= saisie.top - 0.5 && r.bottom <= saisie.bottom + 0.5,
          isTrue,
          reason:
              'la carte du panneau ($r) est entiere dans la saisie ($saisie)',
        );
        for (final Key cle in <Key>[
          ComposerVocal.cleEnvoyer,
          ComposerVocal.cleSupprimer,
        ]) {
          _entierALEcran(tester, find.byKey(cle), taille, '$cle');
        }
      });
    }

    testWidgets('Messages du tuteur, 320, texte x2 : le fil va au bas du '
        'panneau', (WidgetTester tester) async {
      final HorlogeManuelle h = HorlogeManuelle();
      await _monterDansLaCoquille(
        tester,
        Routes.tuteurFilPour('fil-adam'),
        <Override>[
          ..._role(AppRole.guardian),
          ..._messages(RoleDemoCommunications.tuteur, horloge: h),
        ],
        taille: _petit,
        echelle: 2,
      );
      await preEcoute(tester, h);
      expect(tester.takeException(), isNull);
      final Finder carte = find
          .ancestor(
            of: find.byKey(ComposerVocal.cleEnvoyer),
            matching: find.byType(AppCard),
          )
          .first;
      final Rect r = tester.getRect(carte);
      final Rect liste = tester.getRect(find.byKey(FilDiscussion.cleMessages));
      expect(
        r.bottom <= liste.bottom + 0.5,
        isTrue,
        reason: 'le bas de la carte ($r) est dans la liste ($liste)',
      );
      // Le panneau defile lui-meme : son « Envoyer » se rejoint et se
      // touche.
      await tester.ensureVisible(find.byKey(ComposerVocal.cleEnvoyer));
      await tester.pump();
      _entierALEcran(
        tester,
        find.byKey(ComposerVocal.cleEnvoyer),
        _petit,
        '« Envoyer » du vocal',
      );
    });
  });

  test('constat 6 : l entree dans le Focus ne se compte pas dans build', () {
    // Contre-preuve : a 27689f94, `_entreesFocus++` etait dans `build`.
    final String source = File('lib/features/com_studio/canal_page.dart')
        .readAsStringSync();
    final int etat = source.indexOf('class _CanalStudioState');
    expect(etat, isNonNegative);
    final int debut = source.indexOf(
      '  Widget build(BuildContext context)',
      etat,
    );
    expect(debut, isNonNegative);
    final String build = source.substring(debut);
    expect(build.contains('_entreesFocus++'), isFalse);
    expect(source.contains('void _surFocus()'), isTrue);
  });

  testWidgets('constat 6 : chaque entree dans le Focus ramene la saisie, '
      'une fois', (WidgetTester tester) async {
    await _monterDansLaCoquille(
      tester,
      cheminCanalStudio(canalFocusDemo),
      <Override>[..._admin(), ..._studio()],
      taille: _bureau,
      echelle: 1,
    );
    int jeton() => tester
        .widget<FilDiscussion>(find.byType(FilDiscussion))
        .demandeSaisieVisible;
    final int avant = jeton();
    await _entrerFocus(tester);
    expect(jeton(), avant + 1);
    // Un rendu de plus, sans changement du Focus, ne compte rien.
    await tester.pump();
    expect(jeton(), avant + 1);
    await tester.tap(find.byKey(BasculeFocus.cleQuitter));
    await _attendre(tester);
    expect(jeton(), avant + 1);
    await _entrerFocus(tester);
    expect(jeton(), avant + 2);
    expect(tester.takeException(), isNull);
  });

  group('constat 7 : N-1 pour l enseignant et pour le Focus en vue basse', () {
    for (final (Size taille, double echelle) cas in <(Size, double)>[
      (_petit, 2),
      (_basse, 1),
    ]) {
      testWidgets('Messages de l enseignant, ${cas.$1.width.toInt()}x'
          '${cas.$1.height.toInt()}, texte x${cas.$2.toInt()}', (
        WidgetTester tester,
      ) async {
        await _monterDansLaCoquille(
          tester,
          Routes.enseignantFilPour('fil-adam'),
          <Override>[
            ..._role(AppRole.teacher),
            ..._messages(RoleDemoCommunications.enseignant),
          ],
          taille: cas.$1,
          echelle: cas.$2,
        );
        expect(tester.takeException(), isNull);
        _ligneCompacteFixe(tester, cas.$1, textes: <String>['Ahmed', 'Adam']);
        _entierALEcran(
          tester,
          find.descendant(
            of: find.byKey(FilDiscussion.cleEnteteCompacte),
            matching: find.byKey(EspaceTravailAdaptatif.cleOuvrirContexte),
          ),
          cas.$1,
          '(i)',
        );
      });
    }

    testWidgets('Focus du Studio, vue basse (844 x 390) : le nom du canal '
        'reste fixe, « Quitter le focus » aussi', (WidgetTester tester) async {
      await _monterDansLaCoquille(
        tester,
        cheminCanalStudio(canalFocusDemo),
        <Override>[..._admin(), ..._studio()],
        taille: _basse,
        echelle: 1,
      );
      await _entrerFocus(tester);
      expect(tester.takeException(), isNull);
      _ligneCompacteFixe(tester, _basse, textes: <String>['Organisation']);
      expect(
        find.descendant(
          of: find.byKey(FilDiscussion.cleEnteteCompacte),
          matching: find.byKey(EnteteCanal.cle),
        ),
        findsOneWidget,
      );
      // Le fil defile : la ligne reste.
      await tester.drag(
        find.byKey(FilDiscussion.cleMessages),
        const Offset(0, 300),
      );
      await _attendre(tester);
      _ligneCompacteFixe(tester, _basse, textes: <String>['Organisation']);
      _entierALEcran(
        tester,
        find.byKey(BasculeFocus.cleQuitter),
        _basse,
        '« Quitter le focus »',
      );
    });
  });

  group('constat 8 : a 320 x2, le nom se lit et un retour reste', () {
    testWidgets('Messages du tuteur : nom entier, retour dans la ligne', (
      WidgetTester tester,
    ) async {
      // Contre-preuve : a 27689f94, « Sayyida Mariam, Enseignante de la
      // Classe » tenait sur une ligne coupee, et le disque retour de la
      // page defilait avec elle hors de l'ecran.
      final GoRouter routeur = await _monterDansLaCoquille(
        tester,
        Routes.tuteurFilPour('fil-adam'),
        <Override>[
          ..._role(AppRole.guardian),
          ..._messages(RoleDemoCommunications.tuteur),
        ],
        taille: _petit,
        echelle: 2,
      );
      expect(tester.takeException(), isNull);
      final Finder compacte = find.byKey(FilDiscussion.cleEnteteCompacte);
      final Finder nom = find.descendant(
        of: compacte,
        matching: find.textContaining('Sayyida Mariam'),
      );
      expect(nom, findsOneWidget);
      expect(
        tester.renderObject<RenderParagraph>(nom).didExceedMaxLines,
        isFalse,
        reason: 'le nom n est pas coupe',
      );
      // Le lecteur d'ecran entend le contexte entier, fonction comprise.
      final SemanticsHandle semantique = tester.ensureSemantics();
      expect(
        tester
            .getSemantics(
              find.descendant(
                of: compacte,
                matching: find.byKey(EnteteFilContexte.cle),
              ),
            )
            .label,
        contains('Sayyida Mariam, Enseignante'),
      );
      semantique.dispose();
      final Finder retour = find.descendant(
        of: compacte,
        matching: find.byKey(FilDiscussion.cleRetourCompacte),
      );
      _entierALEcran(tester, retour, _petit, 'le retour');
      expect(tester.getSize(retour).height, greaterThanOrEqualTo(48));
      await tester.tap(retour);
      await _attendre(tester);
      expect(
        routeur.routerDelegate.currentConfiguration.uri.path,
        Routes.tuteurMessages,
      );
    });

    testWidgets('390, texte x1 : la tete de la page est fixe, pas de second '
        'retour', (WidgetTester tester) async {
      await _monterDansLaCoquille(
        tester,
        Routes.tuteurFilPour('fil-adam'),
        <Override>[
          ..._role(AppRole.guardian),
          ..._messages(RoleDemoCommunications.tuteur),
        ],
        taille: _telephone,
        echelle: 1,
      );
      expect(find.byKey(FilDiscussion.cleRetourCompacte), findsNothing);
    });
  });

  group('decision « Focus a 320 » : la saisie reduite a une ligne', () {
    testWidgets('320, texte x2 : une bulle au moins se voit ; le champ '
        'reprend sa forme au focus', (WidgetTester tester) async {
      // Contre-preuve : a 27689f94 (capture com_studio_focus_320x2), la
      // saisie entiere (aide, « Envoyer » empile) prenait l'ecran : aucune
      // bulle n'etait visible.
      await _monterDansLaCoquille(
        tester,
        cheminCanalStudio(canalFocusDemo),
        <Override>[..._admin(), ..._studio()],
        taille: _petit,
        echelle: 2,
      );
      await _entrerFocus(tester);
      expect(tester.takeException(), isNull);
      final Rect liste = tester.getRect(find.byKey(FilDiscussion.cleMessages));
      // Les bulles du fil, dans la liste.
      final Iterable<Element> bulles = find
          .descendant(
            of: find.byKey(FilDiscussion.cleMessages),
            matching: find.byWidgetPredicate(
              (Widget w) =>
                  w.key is ValueKey<String> &&
                  (w.key! as ValueKey<String>).value.startsWith('message-'),
            ),
          )
          .evaluate();
      // Une bulle ENTIERE (auteur, texte, date) : a 27689f94, seul le bas
      // de la derniere (80 points) depassait au-dessus de la saisie.
      final List<Rect> entieres = <Rect>[
        for (final Element e in bulles)
          if (e.renderObject case final RenderBox b)
            if (b.localToGlobal(Offset.zero) & b.size case final Rect r)
              if (r.top >= liste.top - 0.5 && r.bottom <= liste.bottom + 0.5) r,
      ];
      expect(
        entieres,
        isNotEmpty,
        reason: 'une bulle entiere se voit au-dessus de la saisie',
      );
      final Rect champVu = tester.getRect(find.byKey(FilDiscussion.champKey));
      expect(
        entieres.any((Rect r) => r.bottom <= champVu.top),
        isTrue,
        reason: 'la bulle est au-dessus du champ',
      );
      // Le champ, sur une ligne, se voit et se touche ; « Envoyer », inerte
      // tant que le champ est vide, n'est pas rendu.
      final Finder champ = find.byKey(FilDiscussion.champKey);
      _entierALEcran(tester, champ, _petit, 'le champ');
      expect(tester.widget<TextField>(champ).maxLines, 1);
      expect(envoiDuFil(), findsNothing);
      // Le micro reste a cote du champ (R-28).
      _entierALEcran(
        tester,
        find.byKey(FilDiscussion.cleMicro),
        _petit,
        'le micro',
      );
      // Le focus rend la saisie entiere.
      await tester.showKeyboard(champ);
      await _attendre(tester);
      // Entiere : plusieurs lignes, bornees par ZoneSaisie aux deux
      // cinquiemes de la vue (SUPERPOS-1).
      expect(tester.widget<TextField>(champ).maxLines, greaterThan(1));
      expect(envoiDuFil(), findsOneWidget);
      expect(
        tester.widget<TextField>(champ).focusNode!.hasFocus,
        isTrue,
        reason: 'le champ garde le focus en reprenant sa forme',
      );
      await tester.enterText(champ, 'Bonjour');
      await tester.pump();
      FocusManager.instance.primaryFocus?.unfocus();
      await _attendre(tester);
      // Du texte : la saisie reste entiere, « Envoyer » actif.
      expect(envoiDuFil(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('390, texte x2, et hors Focus a 320 : la saisie entiere', (
      WidgetTester tester,
    ) async {
      await _monterDansLaCoquille(
        tester,
        cheminCanalStudio(canalFocusDemo),
        <Override>[..._admin(), ..._studio()],
        taille: _petit,
        echelle: 2,
      );
      // Hors Focus.
      expect(envoiDuFil(), findsOneWidget);
      await _monterDansLaCoquille(
        tester,
        cheminCanalStudio(canalFocusDemo),
        <Override>[..._admin(), ..._studio()],
        taille: _telephone,
        echelle: 2,
      );
      await _entrerFocus(tester);
      expect(envoiDuFil(), findsOneWidget);
    });
  });

  group('decision R-28 : le micro a cote d « Envoyer »', () {
    Widget filVocal() => FilDiscussion(
      messages: const <MessageFil>[_recu],
      textes: _textes,
      onEnvoyer: (String _) async {},
      emplacementVocal: ComposerVocal(onEnvoyer: (_) async {}),
    );

    testWidgets('390 : une icone nommee de 48, a cote du champ (et de l envoi), qui '
        'ouvre l enregistrement ; plus de lien sous le champ', (
      WidgetTester tester,
    ) async {
      // Contre-preuve : a 27689f94, l'entree etait le lien « Enregistrer un
      // message vocal » sous le champ, et aucun micro n'existait.
      final HorlogeManuelle h = HorlogeManuelle();
      await _monterNu(
        tester,
        filVocal(),
        surcharges: surchargesVocalDemo(horloge: h.horloge),
      );
      final Finder micro = find.byKey(FilDiscussion.cleMicro);
      expect(micro, findsOneWidget);
      expect(find.byKey(ComposerVocal.cleEnregistrer), findsNothing);
      final Size taille = tester.getSize(micro);
      expect(taille.width, greaterThanOrEqualTo(48));
      expect(taille.height, greaterThanOrEqualTo(48));
      // SUPERPOS-1 (repris par JONCTION-LIGNES-1) : l'envoi est dans le
      // champ, a son bord de fin ; le micro suit le champ, sur sa ligne,
      // apres un palier.
      final Rect m = tester.getRect(micro);
      final Rect champ = tester.getRect(find.byKey(FilDiscussion.champKey));
      final Rect envoyer = tester.getRect(envoiDuFil());
      expect(m.top, champ.top, reason: 'sur la ligne du champ');
      expect(envoyer.right, lessThanOrEqualTo(champ.right + 0.5));
      expect(m.left - champ.right, AppSpacing.sm);
      final SemanticsHandle semantique = tester.ensureSemantics();
      expect(
        find.bySemanticsLabel(t.com.socle.composants.composer.enregistrerVocal),
        findsOneWidget,
      );
      expect(
        t.com.socle.composants.composer.enregistrerVocal,
        'Enregistrer un message vocal',
      );
      semantique.dispose();
      await tester.tap(micro);
      await tester.pump();
      await tester.pump();
      // L'enregistrement s'ouvre, sa rangee remplace la rangee texte.
      expect(find.byKey(ComposerVocal.cleArreter), findsOneWidget);
      expect(micro, findsNothing);
      expect(envoiDuFil(), findsNothing);
      await avancer(tester, h, const Duration(seconds: 3));
      await tester.tap(find.byKey(ComposerVocal.cleArreter));
      await _attendre(tester);
      await tester.tap(find.byKey(ComposerVocal.cleSupprimer));
      await tester.pump();
      await tester.tap(find.byKey(ComposerVocal.cleConfirmerSuppression));
      await _attendre(tester);
      // Le panneau ferme : le micro revient.
      expect(micro, findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('arabe : le libelle du micro est arabe', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
      await _monterNu(tester, filVocal(), surcharges: surchargesVocalDemo());
      final String ar = t.com.socle.composants.composer.enregistrerVocal;
      expect(ar, 'تسجيل رسالة صوتية');
      final SemanticsHandle semantique = tester.ensureSemantics();
      expect(find.bySemanticsLabel(ar), findsOneWidget);
      semantique.dispose();
      // En arabe, le micro suit le champ (et l'envoi, a son bord de fin)
      // vers la gauche.
      final Rect m = tester.getRect(find.byKey(FilDiscussion.cleMicro));
      final Rect champ = tester.getRect(find.byKey(FilDiscussion.champKey));
      final Rect envoyer = tester.getRect(envoiDuFil());
      expect(m.right, lessThanOrEqualTo(champ.left));
      expect(envoyer.left, greaterThanOrEqualTo(champ.left - 0.5));
      expect(tester.takeException(), isNull);
    });

    testWidgets('capacite fermee (aucun composer) ou enregistreur absent : '
        'aucun micro', (WidgetTester tester) async {
      await _monterNu(
        tester,
        FilDiscussion(
          messages: const <MessageFil>[_recu],
          textes: _textes,
          onEnvoyer: (String _) async {},
        ),
      );
      expect(find.byKey(FilDiscussion.cleMicro), findsNothing);
      // Le port neutre de production : le composer le dit, sans micro.
      await _monterNu(
        tester,
        FilDiscussion(
          messages: const <MessageFil>[_recu],
          textes: _textes,
          onEnvoyer: (String _) async {},
          emplacementVocal: ComposerVocal(onEnvoyer: (_) async {}),
        ),
      );
      expect(find.byKey(ComposerVocal.cleIndisponible), findsOneWidget);
      expect(find.byKey(FilDiscussion.cleMicro), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
