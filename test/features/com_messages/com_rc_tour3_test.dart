// COM-RC tour 3 (derniers restes de la revue COM-R), cote fil de discussion.
//
// Chaque test verifie le PREMIER ECRAN, sans rien faire defiler, et dit sa
// contre-preuve : ce qui echouait a e0b9f890.
//
// - R-02, fin : a 320 x 640 et texte x2, dans la VRAIE coquille du role
//   (tuteur, enseignant, administration, Studio), « Envoyer » est entier au
//   premier ecran, au-dessus de la barre de navigation, et rien de la
//   coquille ne le couvre. Le defilement initial va jusqu'au bas de la
//   saisie, pas seulement jusqu'au dernier message ;
// - garde-fou de `TetePageConfiee` : deux fils sous un meme `PageShell` ne
//   se partagent jamais la tete de page (cle globale) ; un seul la pose ;
// - R-11 : a 320 et texte x2, le nom d'un fichier garde au moins six
//   caracteres de son debut (« …_3.pdf » avant) ; le nom complet est lu ;
// - RTL : un message ecrit en francais garde son sens de lecture dans
//   l'interface arabe (le point final n'est plus en tete de ligne).

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
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/carte_piece_jointe.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';
import 'package:rewayah_academy/features/com_studio/port_activite_studio.dart';
import 'package:rewayah_academy/features/com_studio/port_studio.dart';
import 'package:rewayah_academy/features/com_studio/studio_page.dart';
import 'package:rewayah_academy/features/demo/communications/com_messages_demo.dart';
import 'package:rewayah_academy/features/demo/communications/com_studio_demo.dart';
import 'package:rewayah_academy/features/demo/communications/com_vocal_demo.dart';
import 'package:rewayah_academy/features/demo/communications/demo_communications_page.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../router/support_routeur.dart' hide stabiliser;
import '../../support/envoi_fil.dart';
import '../../support/harnais.dart';

/// L'heure des donnees de demonstration (celle des captures).
final DateTime _maintenant = DateTime.utc(2026, 10, 4, 12);

const Size _petit = Size(320, 640);

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

/// Le vrai routeur, dans la vraie coquille du role, sur [chemin] ; 320 x 640
/// a la densite 2, texte x2 (comme la capture `*_320x2_clair`).
Future<void> _monterDansLaCoquille(
  WidgetTester tester,
  String chemin,
  List<Override> surcharges,
) async {
  tester.view.physicalSize = _petit * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = 2;
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

/// L'envoi (dans le champ, SUPERPOS-1) entier au premier ecran, sous aucun
/// element de la coquille,
/// au-dessus de la barre basse ; le champ et un message aussi.
void _envoyerEntier(WidgetTester tester) {
  expect(tester.takeException(), isNull);
  final Finder envoyer = envoiDuFil();
  expect(envoyer, findsOneWidget);
  final Rect r = tester.getRect(envoyer);
  final Rect ecran = Offset.zero & _petit;
  expect(
    r.top >= ecran.top && r.bottom <= ecran.bottom,
    isTrue,
    reason: '« Envoyer » ($r) est entier dans l ecran',
  );
  final Finder barre = find.byKey(NavShell.barreBasseKey);
  if (barre.evaluate().isNotEmpty) {
    expect(
      r.bottom,
      lessThanOrEqualTo(tester.getRect(barre).top),
      reason: '« Envoyer » est au-dessus de la barre de navigation',
    );
  }
  // Rien ne le couvre ni ne le coupe : chaque coin (a 2 points du bord) et
  // le centre atteignent l'envoi, pose DANS le champ (SUPERPOS-1, repris par
  // JONCTION-LIGNES-1) : le bouton, ou, champ vide, le champ qui porte sa
  // place reservee.
  final Finder cible = find.byKey(FilDiscussion.envoyerKey).evaluate().isEmpty
      ? find.byKey(FilDiscussion.champKey)
      : envoyer;
  for (final Offset p in <Offset>[
    r.center,
    r.topLeft + const Offset(2, 2),
    r.topRight + const Offset(-2, 2),
    r.bottomLeft + const Offset(2, -2),
    r.bottomRight + const Offset(-2, -2),
  ]) {
    expect(
      _atteint(tester, cible, p),
      isTrue,
      reason: 'le toucher en $p atteint « Envoyer »',
    );
  }
  // Le champ, qui le porte, est entier lui aussi.
  final Rect champ = tester.getRect(find.byKey(FilDiscussion.champKey));
  expect(champ.top, greaterThanOrEqualTo(0));
  expect(champ.top, lessThanOrEqualTo(r.top + 0.5));
  expect(champ.bottom, greaterThanOrEqualTo(r.bottom - 0.5));
  expect(
    _atteint(tester, find.byKey(FilDiscussion.champKey), champ.center),
    isTrue,
  );
  // Au moins un message se voit au-dessus du champ.
  final bool unMessage = find
      .descendant(
        of: find.byType(FilDiscussion),
        matching: find.byWidgetPredicate(
          (Widget w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith('message-'),
        ),
      )
      .evaluate()
      .any((Element e) {
        final RenderBox b = e.renderObject! as RenderBox;
        final Rect m = b.localToGlobal(Offset.zero) & b.size;
        return m.bottom > 24 && m.top < champ.top;
      });
  expect(unMessage, isTrue, reason: 'un message au premier ecran');
}

/// Un fil minimal, ecrit, avec son en-tete.
FilDiscussion _fil(String id) => FilDiscussion(
  key: ValueKey<String>(id),
  messages: <MessageFil>[
    MessageFil(
      id: '$id-1',
      auteur: 'Administration',
      texte: 'Bonjour, voici le planning.',
      horodatage: 'Lundi',
      deSoi: false,
    ),
  ],
  textes: textesFilTest,
  onEnvoyer: (String _) async {},
  // Un fil qui porte son en-tete prend la tete de la page (JONCTION-LIGNES-1 :
  // le fil sans en-tete du Controleur la laisse a la page, SUPERPOS-1).
  entete: Text('Contexte $id'),
);

/// Les textes d'un fil de test.
final TextesFilDiscussion textesFilTest = TextesFilDiscussion(
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

/// Un ecran nu : vrai theme, [echelle] de texte, [taille], [langue].
Future<void> _monterNu(
  WidgetTester tester,
  Widget enfant, {
  Size taille = _petit,
  double echelle = 2,
  AppLocale langue = AppLocale.fr,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = echelle;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.runAsync(() => LocaleSettings.setLocale(langue));
  addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
      ],
      child: TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          locale: langue.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: enfant,
        ),
      ),
    ),
  );
  await _attendre(tester);
}

void main() {
  setUpAll(() async {
    await chargerPolicesDuDepot();
    // La bibliotheque arabe est differee : chargee hors du `FakeAsync`.
    await LocaleSettings.setLocale(AppLocale.ar);
    await LocaleSettings.setLocale(AppLocale.fr);
  });

  group('R-02 : a 320 et texte x2, « Envoyer » entier au premier ecran, dans '
      'la coquille du role', () {
    // Contre-preuve : a e0b9f890, la saisie bornee a 40 % de la hauteur
    // coupait « Envoyer » au bas du premier ecran (Studio, administration),
    // ou sous la barre de navigation (tuteur) ; le defilement initial
    // s'arretait au dernier message.
    testWidgets('Messages du tuteur', (WidgetTester tester) async {
      await _monterDansLaCoquille(
        tester,
        Routes.tuteurFilPour('fil-adam'),
        <Override>[
          ..._role(AppRole.guardian),
          ..._messages(RoleDemoCommunications.tuteur),
        ],
      );
      _envoyerEntier(tester);
    });

    testWidgets('Messages de l enseignant', (WidgetTester tester) async {
      await _monterDansLaCoquille(
        tester,
        Routes.enseignantFilPour('fil-yasmine'),
        <Override>[
          ..._role(AppRole.teacher),
          ..._messages(RoleDemoCommunications.enseignant),
        ],
      );
      _envoyerEntier(tester);
    });

    testWidgets('Messages de l administration', (WidgetTester tester) async {
      await _monterDansLaCoquille(
        tester,
        Routes.adminFilPour('fil-mission'),
        <Override>[..._admin(), ..._messages(RoleDemoCommunications.admin)],
      );
      _envoyerEntier(tester);
    });

    testWidgets('canal du Studio', (WidgetTester tester) async {
      await _monterDansLaCoquille(
        tester,
        cheminCanalStudio(canalFocusDemo),
        <Override>[..._admin(), ..._studio()],
      );
      _envoyerEntier(tester);
    });
  });

  testWidgets('TetePageConfiee : deux fils sous une meme page, un seul pose '
      'la tete, sans conflit de cle', (WidgetTester tester) async {
    // Contre-preuve : a e0b9f890, chaque fil recevait la meme tete (et sa
    // `GlobalKey`) : « Multiple widgets used the same GlobalKey ».
    await _monterNu(
      tester,
      PageShell(
        titre: 'Titre de la page',
        defilante: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(child: _fil('premier')),
            Expanded(child: _fil('second')),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    // Chaque fil s'ouvre sur sa fin : on remonte les deux jusqu'en haut.
    for (final String id in <String>['premier', 'second']) {
      final ScrollableState liste = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byKey(ValueKey<String>(id)),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      liste.position.jumpTo(0);
    }
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Titre de la page'), findsOneWidget);
    // La tete est dans le premier fil, pas dans le second.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('premier')),
        matching: find.text('Titre de la page'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('second')),
        matching: find.text('Titre de la page'),
      ),
      findsNothing,
    );
  });

  testWidgets('R-11 : a 320 et texte x2, le nom du fichier garde son debut '
      '(six caracteres au moins), le nom complet est lu', (
    WidgetTester tester,
  ) async {
    // Contre-preuve : a e0b9f890, la carte ne montrait que « …_3.pdf ».
    const String nom = 'Devoir_semaine_3.pdf';
    final PieceJointe piece = PieceJointe(
      reference: ReferencePieceJointe('pj-devoir'),
      nom: nom,
      nature: NaturePieceJointe.document,
      typeLisible: 'PDF',
      tailleOctets: 2500000,
      etat: EtatPieceJointe.envoyee,
    );
    await _monterNu(
      tester,
      Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilDiscussion(
              messages: <MessageFil>[
                MessageFil(
                  id: 'pj',
                  auteur: 'Vous',
                  texte: '',
                  horodatage: 'Dimanche',
                  deSoi: true,
                  complement: CartePieceJointe(piece: piece),
                ),
              ],
              textes: textesFilTest,
              onEnvoyer: (String _) async {},
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final Finder affiche = find.descendant(
      of: find.byType(CartePieceJointe),
      matching: find.byWidgetPredicate(
        (Widget w) => w is Text && (w.data ?? '').endsWith('.pdf'),
      ),
    );
    expect(affiche, findsOneWidget);
    final String texte = tester.widget<Text>(affiche).data!;
    // Le debut avant l'ellipse ou le saut de ligne.
    final String debut = texte.split(RegExp('[\n…]')).first;
    expect(
      debut.length,
      greaterThanOrEqualTo(6),
      reason: 'le debut du nom reste lisible (« $texte »)',
    );
    expect(nom.startsWith(debut), isTrue);
    // Le nom affiche est entier dans sa carte, au premier ecran.
    final Rect r = tester.getRect(affiche);
    final Rect carte = tester.getRect(find.byType(CartePieceJointe));
    expect(r.left >= carte.left && r.right <= carte.right, isTrue);
    expect(r.top >= 0 && r.bottom <= _petit.height, isTrue);
    final RenderParagraph p = tester.renderObject<RenderParagraph>(
      find.descendant(of: affiche, matching: find.byType(RichText)),
    );
    expect(p.didExceedMaxLines, isFalse, reason: 'rien n est coupe');
    // Le lecteur d'ecran lit le nom complet.
    expect(
      find.descendant(
        of: find.byType(CartePieceJointe),
        matching: find.byWidgetPredicate(
          (Widget w) => w is Semantics && w.properties.label == nom,
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('RTL : un message ecrit en francais garde son sens de lecture '
      'dans l interface arabe', (WidgetTester tester) async {
    // Contre-preuve : a e0b9f890, le texte prenait le sens de l'interface
    // (droite a gauche) et le point final passait en tete de ligne.
    const String francais = 'Merci pour la seance de mardi.';
    const String arabe = 'شكرا على حصة الثلاثاء.';
    await _monterNu(
      tester,
      Scaffold(
        body: FilDiscussion(
          messages: const <MessageFil>[
            MessageFil(
              id: 'fr',
              auteur: 'Samira',
              texte: francais,
              horodatage: '1',
              deSoi: false,
            ),
            MessageFil(
              id: 'ar',
              auteur: 'Amina',
              texte: arabe,
              horodatage: '2',
              deSoi: false,
            ),
          ],
          textes: textesFilTest,
          onEnvoyer: (String _) async {},
        ),
      ),
      taille: const Size(390, 844),
      echelle: 1,
      langue: AppLocale.ar,
    );
    RenderParagraph paragraphe(String texte) =>
        tester.renderObject<RenderParagraph>(
          find.descendant(
            of: find.text(texte),
            matching: find.byType(RichText),
          ),
        );
    expect(paragraphe(francais).textDirection, TextDirection.ltr);
    expect(paragraphe(arabe).textDirection, TextDirection.rtl);
    // L'interface, elle, reste de droite a gauche.
    expect(
      Directionality.of(tester.element(find.text(francais))),
      TextDirection.rtl,
    );
  });
}
