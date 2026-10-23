// COM-RC tour 4, lot F (contre-verification COM-R-2, section 6.3), cote fil
// de discussion.
//
// Chaque test de rendu verifie le PREMIER ECRAN, sans rien faire defiler, et
// dit sa contre-preuve : ce qui echouait a 022cc31e.
//
// - N-1 : sous 480 points comme a texte agrandi, le fil s'ouvre avec son
//   contexte : une ligne compacte (interlocuteur, objet, et (i)) reste fixe
//   au-dessus de la liste, dans la VRAIE coquille du role ; « Envoyer »
//   reste entier (R-02) ;
// - N-3 : vider le champ a l'envoi n'efface pas le brouillon avant
//   l'accuse ;
// - N-6 : les seuils 1,5 et 480 ne sont definis qu'une fois ;
// - N-8 : `lecteursVocauxDuMessage`, code mort, a disparu ;
// - N-9 : une marge basse sous le panneau vocal borne.

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
import 'package:rewayah_academy/core/accessibilite/texte_agrandi.dart';
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
import 'package:rewayah_academy/core/widgets/espace_travail_adaptatif.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/com_messages/entete_fil_contexte.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';
import 'package:rewayah_academy/features/com_studio/canal_page.dart';
import 'package:rewayah_academy/features/com_studio/port_activite_studio.dart';
import 'package:rewayah_academy/features/com_studio/port_studio.dart';
import 'package:rewayah_academy/features/com_studio/studio_page.dart';
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

/// L'heure des donnees de demonstration (celle des captures).
final DateTime _maintenant = DateTime.utc(2026, 10, 4, 12);

const Size _telephone = Size(390, 844);
const Size _petit = Size(320, 640);

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

List<Override> _messages(RoleDemoCommunications role) => <Override>[
  portMessagesMetierProvider.overrideWithValue(
    MessagesMetierDemo(role: role, maintenant: _maintenant),
  ),
  portCapacitesCommunicationsProvider.overrideWithValue(
    const CapacitesCommunicationsFixes(<CapaciteCommunication>{
      CapaciteCommunication.ecrireDansFil,
      CapaciteCommunication.envoyerVocal,
    }),
  ),
  ...surchargesVocalDemo(),
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
Future<void> _monterDansLaCoquille(
  WidgetTester tester,
  String chemin,
  List<Override> surcharges, {
  required Size taille,
  required double echelle,
}) async {
  // Comme les captures : a 390, la barre d'etat et l'indicateur d'accueil.
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
/// son centre se touche (sauf [toucher] faux : une ligne de texte, dont les
/// textes sont verifies un a un).
void _entierALEcran(
  WidgetTester tester,
  Finder f,
  Size taille,
  String nom, {
  bool toucher = true,
}) {
  expect(f, findsOneWidget, reason: '$nom est rendu au premier ecran');
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
  if (toucher) {
    expect(_atteint(tester, f, r.center), isTrue, reason: '$nom se touche');
  }
}

/// Le contexte du fil au premier ecran : la ligne compacte, fixe au-dessus
/// de la liste, entiere ; [textes] (interlocuteur, objet) s'y lisent, sur
/// une ligne chacun, et (i) est dans sa rangee. « Envoyer » reste entier.
void _contexteVisible(
  WidgetTester tester,
  Size taille, {
  required List<String> textes,
}) {
  expect(tester.takeException(), isNull);
  final Finder compacte = find.byKey(FilDiscussion.cleEnteteCompacte);
  _entierALEcran(
    tester,
    compacte,
    taille,
    'la ligne de contexte',
    toucher: false,
  );
  final Rect ligne = tester.getRect(compacte);
  // Fixe : hors de la liste qui defile, au-dessus d'elle.
  expect(
    find.descendant(
      of: find.byKey(FilDiscussion.cleMessages),
      matching: compacte,
    ),
    findsNothing,
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
    expect(r.top >= ligne.top && r.bottom <= ligne.bottom, isTrue);
    // Rien ne couvre le texte.
    expect(_atteint(tester, f, r.center), isTrue, reason: '« $texte » se voit');
  }
  final Finder info = find.descendant(
    of: compacte,
    matching: find.byKey(EspaceTravailAdaptatif.cleOuvrirContexte),
  );
  _entierALEcran(tester, info, taille, '(i)');
  // R-02 tenu : l'envoi entier a l'ecran, dans le champ (SUPERPOS-1) ;
  // champ vide, sa place reservee, que le toucher du champ atteint.
  _entierALEcran(
    tester,
    envoiDuFil(),
    taille,
    '« Envoyer »',
    toucher: find.byKey(FilDiscussion.envoyerKey).evaluate().isNotEmpty,
  );
  final Rect envoyer = tester.getRect(envoiDuFil());
  for (final Offset p in <Offset>[
    envoyer.topLeft + const Offset(2, 2),
    envoyer.bottomRight - const Offset(2, 2),
  ]) {
    expect(_atteint(tester, cibleEnvoiDuFil(), p), isTrue);
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

/// Un ecran nu : vrai theme, texte x1, [taille].
Future<void> _monterNu(
  WidgetTester tester,
  Widget enfant, {
  Size taille = const Size(390, 844),
  List<Override> surcharges = const <Override>[],
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
        ...surcharges,
      ],
      child: TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Scaffold(body: enfant),
        ),
      ),
    ),
  );
  await _attendre(tester);
}

/// Un panneau vocal de test, haut, qui dit au fil qu'il occupe la saisie.
class _PanneauOuvert extends StatefulWidget {
  const _PanneauOuvert();

  static const Key cle = ValueKey<String>('panneau-vocal-test');

  @override
  State<_PanneauOuvert> createState() => _PanneauOuvertState();
}

class _PanneauOuvertState extends State<_PanneauOuvert> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) const PanneauVocalFil(ouvert: true).dispatch(context);
    });
  }

  @override
  Widget build(BuildContext context) =>
      const SizedBox(key: _PanneauOuvert.cle, height: 900, width: 200);
}

void main() {
  setUpAll(chargerPolicesDuDepot);

  group('N-1 : le fil s ouvre avec son contexte (interlocuteur, objet, (i)), '
      'fixe au-dessus de la liste, dans la coquille du role', () {
    // Contre-preuve : a 022cc31e, sous 480 points, l'en-tete passait dans la
    // liste et le defilement initial vers le bas le cachait : aucune ligne
    // de contexte au premier ecran (`cleEnteteCompacte` n'existait pas).
    testWidgets('Messages de l administration, 390, texte x1', (
      WidgetTester tester,
    ) async {
      await _monterDansLaCoquille(
        tester,
        Routes.adminFilPour('fil-mission'),
        <Override>[..._admin(), ..._messages(RoleDemoCommunications.admin)],
        taille: _telephone,
        echelle: 1,
      );
      _contexteVisible(
        tester,
        _telephone,
        textes: <String>['M. Rachid', 'Visite de contrôle'],
      );
    });

    testWidgets('Messages du tuteur, 320, texte x1', (
      WidgetTester tester,
    ) async {
      await _monterDansLaCoquille(
        tester,
        Routes.tuteurFilPour('fil-adam'),
        <Override>[
          ..._role(AppRole.guardian),
          ..._messages(RoleDemoCommunications.tuteur),
        ],
        taille: _petit,
        echelle: 1,
      );
      _contexteVisible(
        tester,
        _petit,
        textes: <String>['Sayyida Mariam', 'Adam'],
      );
    });

    testWidgets('Messages du tuteur, 320, texte x2', (
      WidgetTester tester,
    ) async {
      await _monterDansLaCoquille(
        tester,
        Routes.tuteurFilPour('fil-adam'),
        <Override>[
          ..._role(AppRole.guardian),
          ..._messages(RoleDemoCommunications.tuteur),
        ],
        taille: _petit,
        echelle: 2,
      );
      _contexteVisible(
        tester,
        _petit,
        textes: <String>['Sayyida Mariam', 'Adam'],
      );
      // La ligne ne prend pas le quart de l'ecran. Lot K, point 5 : ses
      // objets passent a la ligne (deux lignes au plus) au lieu de se
      // couper ; elle reste sous le sixieme de l'ecran.
      expect(
        tester.getRect(find.byKey(FilDiscussion.cleEnteteCompacte)).height,
        lessThanOrEqualTo(_petit.height / 6),
      );
    });

    testWidgets('canal du Studio, 320, texte x2', (WidgetTester tester) async {
      await _monterDansLaCoquille(
        tester,
        cheminCanalStudio(canalFocusDemo),
        <Override>[..._admin(), ..._studio()],
        taille: _petit,
        echelle: 2,
      );
      _contexteVisible(tester, _petit, textes: <String>['Organisation']);
      expect(
        find.descendant(
          of: find.byKey(FilDiscussion.cleEnteteCompacte),
          matching: find.byKey(EnteteCanal.cle),
        ),
        findsOneWidget,
      );
    });

    testWidgets('390, texte x1, vue haute : l en-tete complet reste fixe, '
        'sans ligne compacte', (WidgetTester tester) async {
      // Garde-fou : hors texte agrandi et hors vue basse, rien ne change.
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
      expect(tester.takeException(), isNull);
      expect(find.byKey(FilDiscussion.cleEnteteCompacte), findsNothing);
      _entierALEcran(
        tester,
        find.byKey(EnteteFilContexte.cle),
        _telephone,
        'l en-tete',
      );
    });
  });

  group('N-3 : le brouillon reste jusqu a l accuse', () {
    testWidgets('vider le champ a l envoi n efface pas le brouillon ; '
        'l accuse l efface', (WidgetTester tester) async {
      // Contre-preuve : a 022cc31e, `_champ.clear()` notait un texte vide,
      // qui effacait le brouillon avant l'accuse.
      final BrouillonsMemoire brouillons = BrouillonsMemoire();
      const CleBrouillon cle = CleBrouillon(
        type: TypeObjetLie.message,
        objetId: 'fil-n3',
      );
      final Completer<void> accuse = Completer<void>();
      await _monterNu(
        tester,
        FilDiscussion(
          messages: const <MessageFil>[],
          textes: _textes,
          cleBrouillon: cle,
          onEnvoyer: (String _) => accuse.future,
        ),
        surcharges: <Override>[
          portBrouillonsProvider.overrideWithValue(brouillons),
        ],
      );
      await tester.enterText(
        find.byKey(FilDiscussion.champKey),
        'Bonjour, a demain',
      );
      await tester.pump();
      expect((await brouillons.lire(cle))?.texte, 'Bonjour, a demain');
      await tester.tap(envoiDuFil());
      await tester.pump();
      // Le champ est vide, la bulle attend : le brouillon est garde.
      expect(
        tester
            .widget<TextField>(find.byKey(FilDiscussion.champKey))
            .controller!
            .text,
        isEmpty,
      );
      expect(find.text('En cours'), findsOneWidget);
      expect((await brouillons.lire(cle))?.texte, 'Bonjour, a demain');
      // L'accuse arrive : le brouillon s'efface.
      accuse.complete();
      await _attendre(tester);
      expect(find.text('Envoye'), findsOneWidget);
      expect(await brouillons.lire(cle), isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('un echec garde le brouillon', (WidgetTester tester) async {
      final BrouillonsMemoire brouillons = BrouillonsMemoire();
      const CleBrouillon cle = CleBrouillon(
        type: TypeObjetLie.message,
        objetId: 'fil-n3-echec',
      );
      await _monterNu(
        tester,
        FilDiscussion(
          messages: const <MessageFil>[],
          textes: _textes,
          cleBrouillon: cle,
          onEnvoyer: (String _) async => throw StateError('hors ligne'),
        ),
        surcharges: <Override>[
          portBrouillonsProvider.overrideWithValue(brouillons),
        ],
      );
      await tester.enterText(find.byKey(FilDiscussion.champKey), 'A garder');
      await tester.pump();
      await tester.tap(envoiDuFil());
      await _attendre(tester);
      expect(find.text('Non confirme'), findsOneWidget);
      expect((await brouillons.lire(cle))?.texte, 'A garder');
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('N-9 : une marge basse sous le panneau vocal borne', (
    WidgetTester tester,
  ) async {
    // Contre-preuve : a 022cc31e, la saisie bornee allait jusqu'au bas du
    // fil : le panneau touchait la barre de navigation ou le bord.
    const Size taille = Size(390, 844);
    await _monterNu(
      tester,
      FilDiscussion(
        messages: const <MessageFil>[
          MessageFil(
            id: 'm1',
            auteur: 'Sayyida Mariam',
            texte: 'Bonjour',
            horodatage: 'Lundi',
            deSoi: false,
          ),
        ],
        textes: _textes,
        onEnvoyer: (String _) async {},
        emplacementVocal: const _PanneauOuvert(),
      ),
      taille: taille,
    );
    expect(tester.takeException(), isNull);
    // Le panneau occupe la saisie : la rangee texte s'efface (R-04).
    expect(find.byKey(FilDiscussion.champKey), findsNothing);
    expect(find.byKey(FilDiscussion.cleMargeVocal), findsOneWidget);
    final Rect fil = tester.getRect(find.byType(FilDiscussion));
    final Rect saisie = tester.getRect(find.byKey(FilDiscussion.cleSaisie));
    expect(
      fil.bottom - saisie.bottom,
      greaterThanOrEqualTo(AppSpacing.lg),
      reason: 'la saisie bornee ($saisie) laisse une marge au bas du fil',
    );
  });

  group('N-6 et N-8 : une seule definition, aucun code mort', () {
    test('les seuils 1,5 et 480 ne sont definis qu une fois', () {
      // Contre-preuve : a 022cc31e, ils etaient recopies dans cinq
      // fichiers, parfois en litteral.
      expect(SeuilsTexteAgrandi.echelle, 1.5);
      expect(SeuilsTexteAgrandi.hauteurBasse, 480);
      final RegExp litteral = RegExp(r'scale\(1\)\s*>=\s*1\.5');
      final RegExp constante = RegExp(r'static const double \w+ = (1\.5|480);');
      for (final String chemin in <String>[
        'lib/core/widgets/fil_discussion.dart',
        'lib/features/com_communaute/flux_publications.dart',
        'lib/features/com_communaute/publication_detail.dart',
        'lib/features/com_communaute/communaute_page.dart',
        'lib/features/notifications/notifications_page.dart',
        'lib/features/com_studio/aujourdhui_page.dart',
        'lib/features/com_annonces/administration_communications_page.dart',
      ]) {
        final String source = File(chemin).readAsStringSync();
        expect(litteral.hasMatch(source), isFalse, reason: chemin);
        final Iterable<String> trouves = constante
            .allMatches(source)
            .map((RegExpMatch m) => m.group(0)!)
            // La largeur d'empilement d'« Envoyer » est une largeur.
            .where((String m) => !m.contains('_largeurEmpilee'));
        expect(trouves, isEmpty, reason: chemin);
      }
    });

    test('lecteursVocauxDuMessage a disparu', () {
      // Contre-preuve : a 022cc31e, la fonction n'etait plus appelee et
      // doublait `piecesDuMessage`.
      final String source = File('lib/features/com_vocal/lecteur_vocal.dart')
          .readAsStringSync();
      expect(source.contains('lecteursVocauxDuMessage'), isFalse);
      expect(source.contains('Widget? piecesDuMessage('), isTrue);
    });
  });
}
