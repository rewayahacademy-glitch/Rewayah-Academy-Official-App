// CARTES-PERSO-1 : les cartes de la classe (fiche CLS-CARTES,
// `docs/current/DASH_STRATEGIE.md` §3.9 et annexe A).
//
// Tri, validation, port de production indisponible, en-tete, capacite (un
// widget lit `peutModifier`, jamais un role), cinq etats, feuille de
// l'enseignant, Interface guidee, aucun mot coupe a 320 px texte x2 en LTR
// et en RTL, clair et sombre.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/isolat_bidi.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/tc_groupe/cartes_classe.dart';
import 'package:rewayah_academy/core/tc_horloge/emplacement_entree.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/lien_fleche.dart';
import 'package:rewayah_academy/core/widgets/section_header.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/demo/cartes_classe_demo.dart';
import 'package:rewayah_academy/features/demo/classe_demo.dart';
import 'package:rewayah_academy/features/demo/demo_classe_page.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/bloc_cartes_classe.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/feuille_carte_classe.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/aucun_mot_coupe.dart';
import '../../support/garde_interface.dart';
import '../../support/harnais.dart' show FauxServiceReseau;

const String _id = 'classe-test';

final DateTime _lundi = DateTime(2026, 10, 12);

List<CarteClasse> _troisCartes() => <CarteClasse>[
  // Volontairement hors d'ordre, et des identifiants a rebours des
  // positions : la lecture trie par position d'abord.
  const CarteClasse(
    id: 'a1',
    position: 2,
    type: TypeCarteClasse.rappel,
    titre: 'Pas de séance pendant les vacances',
  ),
  CarteClasse(
    id: 'c3',
    position: 0,
    type: TypeCarteClasse.devoir,
    titre: 'Réviser la sourate Al-Fil',
    texte: 'Lire la sourate trois fois à voix haute, en suivant le doigt.',
    echeance: _lundi,
  ),
  const CarteClasse(
    id: 'b2',
    position: 1,
    type: TypeCarteClasse.lien,
    titre: 'Récitation modèle',
    texte: "L'enregistrement de la séance de lundi.",
    lien: 'https://rewayah.academy/demo/recitation',
  ),
];

/// Un port de test : lectures comptees, ecritures gardees.
class _PortTest implements PortCartesClasse {
  _PortTest(this.lecture);

  Future<CartesClasseVM> Function() lecture;
  int lectures = 0;

  @override
  Future<CartesClasseVM> lire(String groupeId) {
    lectures++;
    return lecture();
  }

  @override
  Future<CarteClasse> enregistrer(
    String groupeId,
    BrouillonCarte brouillon, {
    String? carteId,
  }) => throw StateError('perdue');

  @override
  Future<void> retirer(String groupeId, String carteId) =>
      throw StateError('perdue');
}

Widget _hote(
  Widget enfant, {
  List<Override> surcharges = const <Override>[],
  InterfaceMode mode = InterfaceMode.standard,
  Brightness luminosite = Brightness.light,
  double echelle = 1,
  TextDirection sens = TextDirection.ltr,
  bool horsLigne = false,
}) => ProviderScope(
  overrides: <Override>[
    serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
    horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(horsLigne)),
    ...surcharges,
  ],
  child: TranslationProvider(
    child: MaterialApp(
      theme: AppTheme.pour(mode, luminosite),
      locale: AppLocale.fr.flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (BuildContext c, Widget? app) => MediaQuery(
        data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(echelle)),
        child: Directionality(textDirection: sens, child: app!),
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: enfant,
        ),
      ),
    ),
  ),
);

List<Override> _avec(PortCartesClasse port) => <Override>[
  portCartesClasseProvider.overrideWithValue(port),
];

List<Override> _demo({required bool peutModifier, List<CarteClasse>? cartes}) =>
    <Override>[
      portCartesClasseProvider.overrideWith(
        (Ref _) => PortCartesClasseDemo(
          peutModifier: peutModifier,
          cartes: cartes ?? _troisCartes(),
        ),
      ),
    ];

void _taille(WidgetTester tester, Size s) {
  tester.view.physicalSize = s;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Finder get _cartes => find.byType(VueCarteClasse);

void main() {
  group('modele', () {
    test('trierCartes : la position, puis l identifiant', () {
      final List<CarteClasse> tries = trierCartes(<CarteClasse>[
        ..._troisCartes(),
        const CarteClasse(
          id: 'a2',
          position: 1,
          type: TypeCarteClasse.annonce,
          titre: 'x',
        ),
      ]);
      expect(tries.map((CarteClasse c) => c.id), <String>[
        'c3',
        'a2',
        'b2',
        'a1',
      ]);
    });

    test('defautsCarte : chaque borne, et un brouillon complet passe', () {
      const BrouillonCarte ok = BrouillonCarte(
        type: TypeCarteClasse.annonce,
        titre: 'Bienvenue',
      );
      expect(defautsCarte(ok), isEmpty);
      expect(defautsCarte(ok.copie(titre: '   ')), <DefautCarte>{
        DefautCarte.titreVide,
      });
      expect(
        defautsCarte(ok.copie(titre: 'a' * (BornesCarteClasse.titreMax + 1))),
        <DefautCarte>{DefautCarte.titreLong},
      );
      expect(
        defautsCarte(ok.copie(titre: 'a' * BornesCarteClasse.titreMax)),
        isEmpty,
      );
      expect(
        defautsCarte(ok.copie(texte: 'a' * (BornesCarteClasse.texteMax + 1))),
        <DefautCarte>{DefautCarte.texteLong},
      );
      for (final String faux in <String>[
        'http://rewayah.academy',
        'rewayah.academy',
        'https://localhost',
        'https://rewayah .academy',
        'https://${'a' * BornesCarteClasse.lienMax}.fr',
      ]) {
        expect(defautsCarte(ok.copie(lien: faux)), <DefautCarte>{
          DefautCarte.lienInvalide,
        }, reason: faux);
      }
      expect(
        defautsCarte(ok.copie(lien: 'https://rewayah.academy/a')),
        isEmpty,
      );
      expect(
        defautsCarte(ok.copie(type: TypeCarteClasse.devoir)),
        <DefautCarte>{DefautCarte.echeanceManquante},
      );
    });

    test('modele K-57 : un devoir et un rappel prennent la prochaine '
        'seance pour echeance, une annonce et un lien n en ont pas', () {
      final DateTime seance = DateTime(2026, 10, 12, 18, 30);
      for (final TypeCarteClasse type in TypeCarteClasse.values) {
        final BrouillonCarte b = BrouillonCarte.modele(
          type,
          titre: 'T',
          prochaineSeance: seance,
        );
        expect(b.titre, 'T');
        expect(
          b.echeance,
          type == TypeCarteClasse.devoir || type == TypeCarteClasse.rappel
              ? DateTime(2026, 10, 12)
              : isNull,
          reason: type.name,
        );
      }
    });

    test(
      'production : le port rend CapaciteIndisponible, jamais une carte',
      () async {
        final ProviderContainer c = ProviderContainer();
        addTearDown(c.dispose);
        expect(
          c.read(portCartesClasseProvider),
          isA<PortCartesClasseIndisponible>(),
        );
        await expectLater(
          c.read(portCartesClasseProvider).lire(_id),
          throwsA(isA<CapaciteIndisponible>()),
        );
        await expectLater(
          c
              .read(portCartesClasseProvider)
              .enregistrer(
                _id,
                const BrouillonCarte(type: TypeCarteClasse.annonce, titre: 'x'),
              ),
          throwsA(isA<CapaciteIndisponible>()),
        );
      },
    );

    test('demonstration : la capacite fausse refuse l ecriture ; vraie, une '
        'nouvelle carte se pose en dernier', () async {
      final PortCartesClasseDemo lecteur = PortCartesClasseDemo(
        peutModifier: false,
        cartes: _troisCartes(),
      );
      await expectLater(
        lecteur.enregistrer(
          _id,
          const BrouillonCarte(type: TypeCarteClasse.annonce, titre: 'x'),
        ),
        throwsA(isA<StateError>()),
      );
      final PortCartesClasseDemo ens = PortCartesClasseDemo(
        peutModifier: true,
        cartes: _troisCartes(),
      );
      await ens.enregistrer(
        _id,
        const BrouillonCarte(type: TypeCarteClasse.annonce, titre: 'Neuve'),
      );
      final CartesClasseVM vue = await ens.lire(_id);
      expect(vue.cartes.map((CarteClasse c) => c.titre).last, 'Neuve');
      expect(vue.cartes.last.position, 3);
    });
  });

  group('emplacement', () {
    setUpAll(chargerPolicesDuDepot);

    testWidgets('en-tete et production : « pas encore ouvertes », sans '
        'Reessayer ni carte', (WidgetTester tester) async {
      await tester.pumpWidget(_hote(const BlocCartesClasse(groupeId: _id)));
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(SectionHeader, t.classe.cartes.titre),
        findsOneWidget,
      );
      final EtatSysteme etat = tester.widget<EtatSysteme>(
        find.byType(EtatSysteme),
      );
      expect(etat.nature, NatureEtat.indisponible);
      expect(etat.dependance, PortCartesClasseIndisponible.dependance);
      expect(find.text(t.classe.cartes.indisponibleTitre), findsOneWidget);
      expect(find.text(t.commun.etats.actions.reessayer), findsNothing);
      expect(_cartes, findsNothing);
      expect(find.text(PortCartesClasseIndisponible.dependance), findsNothing);
    });

    testWidgets('chargement : un squelette sous l en-tete', (
      WidgetTester tester,
    ) async {
      final Completer<CartesClasseVM> attente = Completer<CartesClasseVM>();
      await tester.pumpWidget(
        _hote(
          const BlocCartesClasse(groupeId: _id),
          surcharges: _avec(_PortTest(() => attente.future)),
        ),
      );
      await tester.pump();
      expect(find.text(t.classe.cartes.titre), findsOneWidget);
      expect(find.byType(Skeleton), findsWidgets);
      expect(_cartes, findsNothing);
      attente.complete(const CartesClasseVM(cartes: <CarteClasse>[]));
      await tester.pumpAndSettle();
    });

    testWidgets('erreur : la phrase dit quoi faire, Reessayer relit', (
      WidgetTester tester,
    ) async {
      final _PortTest port = _PortTest(
        () => Future<CartesClasseVM>.error(StateError('reseau')),
      );
      await tester.pumpWidget(
        _hote(const BlocCartesClasse(groupeId: _id), surcharges: _avec(port)),
      );
      await tester.pumpAndSettle();
      expect(find.text(t.classe.cartes.erreurLecture), findsOneWidget);
      final int avant = port.lectures;
      port.lecture = () async => CartesClasseVM(cartes: _troisCartes());
      await tester.tap(find.text(t.commun.etats.actions.reessayer));
      await tester.pumpAndSettle();
      expect(port.lectures, greaterThan(avant));
      expect(_cartes, findsNWidgets(3));
    });

    testWidgets('vide, sans capacite : un etat subi, rien a ajouter', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _hote(
          const BlocCartesClasse(groupeId: _id),
          surcharges: _demo(peutModifier: false, cartes: <CarteClasse>[]),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(t.classe.cartes.aucune), findsOneWidget);
      expect(find.byKey(BlocCartesClasse.ajouterKey), findsNothing);
    });

    testWidgets('vide, avec capacite : une phrase et « Ajouter une carte »', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _hote(
          const BlocCartesClasse(groupeId: _id),
          surcharges: _demo(peutModifier: true, cartes: <CarteClasse>[]),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(isolerSens(t.classe.cartes.aucuneEnseignant)),
        findsOneWidget,
      );
      expect(find.byKey(BlocCartesClasse.ajouterKey), findsOneWidget);
    });

    testWidgets('contenu : les cartes dans l ordre de la Classe', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _hote(
          const BlocCartesClasse(groupeId: _id),
          surcharges: _demo(peutModifier: false),
        ),
      );
      await tester.pumpAndSettle();
      final List<double> hauts = <double>[
        for (final String titre in <String>[
          'Réviser la sourate Al-Fil',
          'Récitation modèle',
          'Pas de séance pendant les vacances',
        ])
          tester.getTopLeft(find.text(texteAffiche(titre))).dy,
      ];
      expect(hauts, List<double>.of(hauts)..sort());
      expect(
        find.text(t.classe.cartes.echeance(date: echeanceRendue(_lundi))),
        findsOneWidget,
      );
      // K-55 : des cartes detachees, separees de 16 au moins.
      expect(
        verifierAucuneCarteCollee(tester, estCarte: (Widget w) => w is AppCard),
        3,
      );
    });

    testWidgets('capacite fausse (tuteur, eleve, adulte) : les cartes se '
        'lisent, ne se pressent pas, le lien se copie', (
      WidgetTester tester,
    ) async {
      String? copie;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall appel) async {
          if (appel.method == 'Clipboard.setData') {
            copie =
                (appel.arguments as Map<Object?, Object?>)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(
        _hote(
          const BlocCartesClasse(groupeId: _id),
          surcharges: _demo(peutModifier: false),
        ),
      );
      await tester.pumpAndSettle();
      for (final AppCard carte in tester.widgetList<AppCard>(
        find.byType(AppCard),
      )) {
        expect(carte.onPress, isNull);
      }
      expect(
        find.text(isolerSens(t.classe.cartes.contexteEnseignant)),
        findsNothing,
      );
      expect(find.byKey(BlocCartesClasse.ajouterKey), findsNothing);
      final Finder copier = find.widgetWithText(
        LienFleche,
        isolerSens(
          t.classe.cartes.copierLien(titre: isolerSens('Récitation modèle')),
        ),
      );
      expect(copier, findsOneWidget);
      await tester.tap(copier);
      await tester.pumpAndSettle();
      expect(copie, 'https://rewayah.academy/demo/recitation');
      expect(find.text(t.classe.cartes.lienCopie), findsOneWidget);
      verifierUnSeulBoutonPlein(tester, maximum: 0);
    });

    testWidgets('capacite vraie (enseignant) : toute la carte ouvre sa '
        'modification, le lien se lit sans bouton dans la carte', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantique = tester.ensureSemantics();
      await tester.pumpWidget(
        _hote(
          const BlocCartesClasse(groupeId: _id),
          surcharges: _demo(peutModifier: true),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(isolerSens(t.classe.cartes.contexteEnseignant)),
        findsOneWidget,
      );
      for (final AppCard carte in tester.widgetList<AppCard>(
        find.byType(AppCard),
      )) {
        expect(carte.onPress, isNotNull);
      }
      expect(
        find.descendant(of: _cartes, matching: find.byType(LienFleche)),
        findsNothing,
      );
      expect(
        find.descendant(of: _cartes, matching: find.byType(ActionPrincipale)),
        findsNothing,
      );
      expect(
        find.text(isolerSens('https://rewayah.academy/demo/recitation')),
        findsOneWidget,
      );
      expect(find.byKey(BlocCartesClasse.ajouterKey), findsOneWidget);
      // Le lecteur d'ecran annonce d'abord le geste, puis le contenu.
      expect(
        find.bySemanticsLabel(
          RegExp(
            '^${RegExp.escape(t.classe.cartes.modifierLecteur(titre: 'Récitation modèle'))}',
          ),
        ),
        findsOneWidget,
      );
      semantique.dispose();
    });

    testWidgets('six cartes : plus d ajout, une phrase dit la limite', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _hote(
          const BlocCartesClasse(groupeId: _id),
          surcharges: _demo(
            peutModifier: true,
            cartes: <CarteClasse>[
              for (int i = 0; i < BornesCarteClasse.cartesMax; i++)
                CarteClasse(
                  id: 'c$i',
                  position: i,
                  type: TypeCarteClasse.annonce,
                  titre: 'Carte $i',
                ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(BlocCartesClasse.ajouterKey), findsNothing);
      expect(
        find.text(
          isolerSens(t.classe.cartes.limite(max: BornesCarteClasse.cartesMax)),
        ),
        findsOneWidget,
      );
    });

    testWidgets('hors ligne sans donnees : le bloc dit ce qui manque, sans '
        'redire le reseau', (WidgetTester tester) async {
      await tester.pumpWidget(
        _hote(
          const BlocCartesClasse(groupeId: _id),
          horsLigne: true,
          surcharges: _avec(
            _PortTest(() => Future<CartesClasseVM>.error(StateError('x'))),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(BlocCartesClasse.sansDonneesKey), findsOneWidget);
      expect(find.text(t.classe.cartes.sansDonnees), findsOneWidget);
      expect(find.text(t.commun.etats.horsLigne.titre), findsNothing);
      expect(find.text(t.classe.cartes.erreurLecture), findsNothing);
    });

    testWidgets('hors ligne, enseignant : cartes lues gardees, ni pression ni '
        'ajout (jamais grises), une phrase dit quand', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _hote(
          const BlocCartesClasse(groupeId: _id),
          horsLigne: true,
          surcharges: _demo(peutModifier: true),
        ),
      );
      await tester.pumpAndSettle();
      expect(_cartes, findsNWidgets(3));
      for (final AppCard carte in tester.widgetList<AppCard>(
        find.byType(AppCard),
      )) {
        expect(carte.onPress, isNull);
      }
      expect(find.byKey(BlocCartesClasse.ajouterKey), findsNothing);
      expect(
        find.text(isolerSens(t.classe.cartes.modificationPlusTard)),
        findsOneWidget,
      );
    });

    testWidgets('hors ligne, port qui echoue apres une premiere lecture : '
        'les cartes deja lues restent, sans erreur ni bloc « rien » '
        '(lectureHorsLigne, revue CARTES-PERSO-1)', (
      WidgetTester tester,
    ) async {
      final _PortTest port = _PortTest(
        () async => CartesClasseVM(cartes: _troisCartes()),
      );
      await tester.pumpWidget(
        _hote(
          const BlocCartesClasse(groupeId: _id),
          horsLigne: true,
          surcharges: _avec(port),
        ),
      );
      await tester.pumpAndSettle();
      expect(_cartes, findsNWidgets(3));
      expect(port.lectures, 1);
      // Le reseau tombe : toute relecture echoue desormais.
      port.lecture = () => Future<CartesClasseVM>.error(StateError('reseau'));
      ProviderScope.containerOf(tester.element(find.byType(BlocCartesClasse)))
          .invalidate(cartesClasseProvider(_id));
      await tester.pumpAndSettle();
      expect(port.lectures, 2);
      // Les cartes deja lues restent consultables, dans leur ordre.
      expect(_cartes, findsNWidgets(3));
      expect(
        <String>[
          for (final VueCarteClasse v in tester.widgetList<VueCarteClasse>(
            _cartes,
          ))
            v.carte.titre,
        ],
        <String>[
          'Réviser la sourate Al-Fil',
          'Récitation modèle',
          'Pas de séance pendant les vacances',
        ],
      );
      expect(find.text(t.classe.cartes.erreurLecture), findsNothing);
      expect(find.byKey(BlocCartesClasse.sansDonneesKey), findsNothing);
      expect(find.text(t.commun.etats.actions.reessayer), findsNothing);
    });

    test('chaque modele a son pictogramme : devoir et lien utile ne '
        'partagent plus le meme livre (revue CARTES-PERSO-1)', () {
      final Set<int> points = <int>{
        for (final TypeCarteClasse type in TypeCarteClasse.values)
          iconeTypeCarte(type).repos.codePoint,
      };
      expect(points, hasLength(TypeCarteClasse.values.length));
    });

    testWidgets('Interface guidee : titre et texte, sans le modele ; le lien '
        'est un bouton pleine largeur de sa carte, non plein', (
      WidgetTester tester,
    ) async {
      _taille(tester, const Size(390, 1400));
      await tester.pumpWidget(
        _hote(
          const BlocCartesClasse(groupeId: _id),
          mode: InterfaceMode.enfant,
          surcharges: _demo(peutModifier: false),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(t.classe.cartes.types.devoir), findsNothing);
      expect(
        find.text(texteAffiche('Réviser la sourate Al-Fil')),
        findsOneWidget,
      );
      final String libelle = t.classe.cartes.copierLien(
        titre: 'Récitation modèle',
      );
      final Finder bouton = find.widgetWithText(
        ActionPrincipale,
        t.classe.cartes.copierLienCourt,
      );
      expect(bouton, findsOneWidget);
      // Le lecteur d'ecran lit le libelle entier, qui dit quel lien.
      final SemanticsHandle semantique = tester.ensureSemantics();
      expect(find.bySemanticsLabel(libelle), findsOneWidget);
      semantique.dispose();
      expect(find.widgetWithText(LienFleche, libelle), findsNothing);
      expect(
        tester.widget<ActionPrincipale>(bouton).niveau,
        NiveauAction.secondaire,
      );
      final Finder carte = find.ancestor(
        of: bouton,
        matching: find.byType(VueCarteClasse),
      );
      // Pleine largeur de la carte, a sa marge interieure pres.
      expect(
        tester.getSize(bouton).width,
        greaterThan(tester.getSize(carte).width * 0.8),
      );
      verifierUnSeulBoutonPlein(tester, maximum: 0);
    });
  });

  group('feuille de l enseignant', () {
    setUpAll(chargerPolicesDuDepot);

    Future<void> ouvrir(WidgetTester tester, {String? titre}) async {
      _taille(tester, const Size(390, 2400));
      await tester.pumpWidget(
        _hote(
          const BlocCartesClasse(groupeId: _id),
          surcharges: _demo(peutModifier: true),
        ),
      );
      await tester.pumpAndSettle();
      if (titre == null) {
        await tester.tap(find.byKey(BlocCartesClasse.ajouterKey));
      } else {
        await tester.tap(find.text(texteAffiche(titre)));
      }
      await tester.pumpAndSettle();
    }

    testWidgets('toucher une carte ouvre sa modification ; le titre change '
        'et la classe le voit', (WidgetTester tester) async {
      await ouvrir(tester, titre: 'Récitation modèle');
      expect(find.byType(FeuilleCarteClasse), findsOneWidget);
      expect(
        find.text(isolerSens(t.classe.cartes.feuille.contexte)),
        findsOneWidget,
      );
      verifierUnSeulBoutonPlein(tester);
      await tester.enterText(
        find.byKey(FeuilleCarteClasse.titreKey),
        'Récitation de la sourate',
      );
      await tester.ensureVisible(find.byKey(FeuilleCarteClasse.enregistrerKey));
      await tester.tap(find.byKey(FeuilleCarteClasse.enregistrerKey));
      await tester.pumpAndSettle();
      expect(find.byType(FeuilleCarteClasse), findsNothing);
      expect(
        find.text(texteAffiche('Récitation de la sourate')),
        findsOneWidget,
      );
      expect(find.text(texteAffiche('Récitation modèle')), findsNothing);
      expect(find.text(t.classe.cartes.enregistree), findsOneWidget);
    });

    testWidgets('nouvelle carte : le modele preremplit le titre ; un titre '
        'vide se dit au lieu de griser le bouton', (WidgetTester tester) async {
      await ouvrir(tester);
      expect(
        tester
            .widget<TextField>(find.byKey(FeuilleCarteClasse.titreKey))
            .controller!
            .text,
        t.classe.cartes.modeles.annonce,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('classe.cartes.modele.lien')),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(FeuilleCarteClasse.titreKey))
            .controller!
            .text,
        t.classe.cartes.modeles.lien,
      );
      await tester.enterText(find.byKey(FeuilleCarteClasse.titreKey), '');
      await tester.pump();
      final ActionPrincipale bouton = tester.widget<ActionPrincipale>(
        find.byKey(FeuilleCarteClasse.enregistrerKey),
      );
      expect(bouton.onPress, isNotNull, reason: 'jamais grise');
      await tester.ensureVisible(find.byKey(FeuilleCarteClasse.enregistrerKey));
      await tester.tap(find.byKey(FeuilleCarteClasse.enregistrerKey));
      await tester.pumpAndSettle();
      expect(find.byType(FeuilleCarteClasse), findsOneWidget);
      expect(
        find.text(isolerSens(t.classe.cartes.feuille.defauts.titreVide)),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(FeuilleCarteClasse.lienKey),
        'rewayah.academy',
      );
      await tester.pumpAndSettle();
      expect(
        find.text(isolerSens(t.classe.cartes.feuille.defauts.lienInvalide)),
        findsOneWidget,
      );
    });

    testWidgets('un devoir sans echeance dit quoi faire', (
      WidgetTester tester,
    ) async {
      await ouvrir(tester);
      await tester.tap(
        find.byKey(const ValueKey<String>('classe.cartes.modele.devoir')),
      );
      await tester.pumpAndSettle();
      // Sans prochaine seance connue, aucune echeance n'est deduite.
      expect(find.text(t.classe.cartes.feuille.echeanceAucune), findsOneWidget);
      await tester.ensureVisible(find.byKey(FeuilleCarteClasse.enregistrerKey));
      await tester.tap(find.byKey(FeuilleCarteClasse.enregistrerKey));
      await tester.pumpAndSettle();
      expect(
        find.text(
          isolerSens(t.classe.cartes.feuille.defauts.echeanceManquante),
        ),
        findsOneWidget,
      );
    });

    testWidgets('prochaine seance connue : le devoir la prend pour echeance', (
      WidgetTester tester,
    ) async {
      _taille(tester, const Size(390, 2400));
      await tester.pumpWidget(
        _hote(
          FeuilleCarteClasse(
            groupeId: _id,
            prochaineSeance: DateTime(2026, 10, 12, 18),
          ),
          surcharges: _demo(peutModifier: true),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('classe.cartes.modele.devoir')),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(t.classe.cartes.echeance(date: echeanceRendue(_lundi))),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextField>(find.byKey(FeuilleCarteClasse.titreKey))
            .controller!
            .text,
        t.classe.cartes.modeles.devoir,
      );
    });

    testWidgets('retirer une carte passe par une confirmation', (
      WidgetTester tester,
    ) async {
      await ouvrir(tester, titre: 'Pas de séance pendant les vacances');
      await tester.ensureVisible(find.byKey(FeuilleCarteClasse.retirerKey));
      await tester.tap(find.byKey(FeuilleCarteClasse.retirerKey));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(t.classe.cartes.feuille.retirerConfirmer).last,
      );
      await tester.pumpAndSettle();
      expect(
        find.text(texteAffiche('Pas de séance pendant les vacances')),
        findsNothing,
      );
      expect(find.text(t.classe.cartes.retiree), findsOneWidget);
      expect(_cartes, findsNWidgets(2));
    });

    testWidgets('envoi perdu : « non confirme », jamais « non enregistre »', (
      WidgetTester tester,
    ) async {
      _taille(tester, const Size(390, 2400));
      await tester.pumpWidget(
        _hote(
          const FeuilleCarteClasse(groupeId: _id),
          surcharges: _avec(
            _PortTest(
              () async => const CartesClasseVM(cartes: <CarteClasse>[]),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(FeuilleCarteClasse.enregistrerKey));
      await tester.tap(find.byKey(FeuilleCarteClasse.enregistrerKey));
      await tester.pumpAndSettle();
      expect(
        find.text(isolerSens(t.classe.cartes.feuille.envoiNonConfirme)),
        findsOneWidget,
      );
    });
  });

  group('aucun mot coupe, 320 px, texte x2', () {
    setUpAll(chargerPolicesDuDepot);

    for (final TextDirection sens in TextDirection.values) {
      for (final Brightness luminosite in Brightness.values) {
        for (final (String nom, bool peutModifier, InterfaceMode mode)
            in <(String, bool, InterfaceMode)>[
              ('famille', false, InterfaceMode.standard),
              ('enseignant', true, InterfaceMode.standard),
              ('guidee', false, InterfaceMode.enfant),
            ]) {
          testWidgets('$nom, ${sens.name}, ${luminosite.name}', (
            WidgetTester tester,
          ) async {
            _taille(tester, const Size(320, 4000));
            await tester.pumpWidget(
              _hote(
                const BlocCartesClasse(groupeId: _id),
                surcharges: _demo(peutModifier: peutModifier),
                mode: mode,
                echelle: 2,
                sens: sens,
                luminosite: luminosite,
              ),
            );
            await tester.pumpAndSettle();
            expect(_cartes, findsNWidgets(3));
            verifierAucunMotCoupe(
              tester,
              find.byType(BlocCartesClasse),
              // Une adresse est un seul « mot » sans espace : plus large que
              // la colonne a 320 px et texte x2, elle passe forcement a la
              // ligne. Elle se lit en entier ; seul l'enseignant la voit.
              exceptions: <String>{
                isolerSens('https://rewayah.academy/demo/recitation'),
              },
            );
            expect(tester.takeException(), isNull);
          });
        }
      }
    }

    for (final TextDirection sens in TextDirection.values) {
      testWidgets('feuille de l enseignant, ${sens.name}', (
        WidgetTester tester,
      ) async {
        _taille(tester, const Size(320, 4000));
        await tester.pumpWidget(
          _hote(
            const FeuilleCarteClasse(groupeId: _id),
            surcharges: _demo(peutModifier: true),
            echelle: 2,
            sens: sens,
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(FeuilleCarteClasse.enregistrerKey));
        await tester.enterText(find.byKey(FeuilleCarteClasse.titreKey), '');
        await tester.tap(find.byKey(FeuilleCarteClasse.enregistrerKey));
        await tester.pumpAndSettle();
        verifierAucunMotCoupe(tester, find.byType(FeuilleCarteClasse));
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('sens de lecture des phrases de l interface', () {
    setUpAll(chargerPolicesDuDepot);

    // Revue CARTES-PERSO-1 : en RTL, « familles la voient .aussitôt ». Les
    // phrases de l'interface encore en francais sont isolees comme les mots
    // de l'enseignant ; isolees, elles gardent leur point a la fin.
    for (final (
          String nom,
          List<CarteClasse> cartes,
          bool horsLigne,
          String Function() phrase,
        )
        in <(String, List<CarteClasse>, bool, String Function())>[
          (
            'contexte',
            _troisCartes(),
            false,
            () => t.classe.cartes.contexteEnseignant,
          ),
          (
            'aucune carte',
            <CarteClasse>[],
            false,
            () => t.classe.cartes.aucuneEnseignant,
          ),
          (
            'hors ligne',
            _troisCartes(),
            true,
            () => t.classe.cartes.modificationPlusTard,
          ),
        ]) {
      testWidgets('enseignant, rtl : $nom isole', (WidgetTester tester) async {
        _taille(tester, const Size(390, 2400));
        await tester.pumpWidget(
          _hote(
            const BlocCartesClasse(groupeId: _id),
            surcharges: _demo(peutModifier: true, cartes: cartes),
            sens: TextDirection.rtl,
            horsLigne: horsLigne,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(isolerSens(phrase())), findsOneWidget);
        expect(find.text(phrase()), findsNothing);
      });
    }

    testWidgets('lecture (tuteur, adulte), rtl : « Copier le lien de » '
        'isole en entier', (WidgetTester tester) async {
      _taille(tester, const Size(390, 2400));
      await tester.pumpWidget(
        _hote(
          const BlocCartesClasse(groupeId: _id),
          surcharges: _demo(peutModifier: false),
          sens: TextDirection.rtl,
        ),
      );
      await tester.pumpAndSettle();
      final String nu = t.classe.cartes.copierLien(
        titre: isolerSens('Récitation modèle'),
      );
      expect(find.widgetWithText(LienFleche, isolerSens(nu)), findsOneWidget);
      expect(find.widgetWithText(LienFleche, nu), findsNothing);
    });

    testWidgets('feuille, rtl : la phrase de contexte isolee', (
      WidgetTester tester,
    ) async {
      _taille(tester, const Size(390, 2400));
      await tester.pumpWidget(
        _hote(
          const FeuilleCarteClasse(groupeId: _id),
          surcharges: _demo(peutModifier: true),
          sens: TextDirection.rtl,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(isolerSens(t.classe.cartes.feuille.contexte)),
        findsOneWidget,
      );
      expect(find.text(t.classe.cartes.feuille.contexte), findsNothing);
    });

    // Revue CARTES-PERSO-1, deuxieme passe : en RTL, les aides des champs
    // (« caracteres au plus 60 »), les erreurs (« par .//:https ») et les
    // descriptions des modeles (« .classe ») se lisaient a rebours.
    testWidgets('feuille, rtl : aides, erreurs et descriptions des modeles '
        'isolees', (WidgetTester tester) async {
      _taille(tester, const Size(390, 3200));
      await tester.pumpWidget(
        _hote(
          const FeuilleCarteClasse(groupeId: _id),
          surcharges: _demo(peutModifier: true),
          sens: TextDirection.rtl,
        ),
      );
      await tester.pumpAndSettle();
      final f = t.classe.cartes.feuille;
      final List<String> aides = <String>[
        f.aideLongueur(max: BornesCarteClasse.titreMax),
        f.aideLongueur(max: BornesCarteClasse.texteMax),
        f.aideLien,
      ];
      final List<String> descriptions = <String>[
        t.classe.cartes.typesDetail.annonce,
        t.classe.cartes.typesDetail.devoir,
        t.classe.cartes.typesDetail.lien,
        t.classe.cartes.typesDetail.rappel,
      ];
      for (final String phrase in <String>[...aides, ...descriptions]) {
        expect(find.text(isolerSens(phrase)), findsOneWidget, reason: phrase);
        expect(find.text(phrase), findsNothing, reason: phrase);
      }
      // Les erreurs : titre vide, lien invalide.
      await tester.enterText(find.byKey(FeuilleCarteClasse.titreKey), '');
      await tester.enterText(find.byKey(FeuilleCarteClasse.lienKey), 'www');
      await tester.ensureVisible(find.byKey(FeuilleCarteClasse.enregistrerKey));
      await tester.tap(find.byKey(FeuilleCarteClasse.enregistrerKey));
      await tester.pumpAndSettle();
      for (final String erreur in <String>[
        f.defauts.titreVide,
        f.defauts.lienInvalide,
      ]) {
        expect(find.text(isolerSens(erreur)), findsOneWidget, reason: erreur);
        expect(find.text(erreur), findsNothing, reason: erreur);
      }
    });

    test('sensDeLaSaisie : la premiere lettre decide, sans lettre rien', () {
      expect(sensDeLaSaisie('Lire la sourate.'), TextDirection.ltr);
      expect(sensDeLaSaisie('« 3 » Réviser'), TextDirection.ltr);
      expect(sensDeLaSaisie('اقرأ السورة.'), TextDirection.rtl);
      expect(sensDeLaSaisie('12 — اقرأ'), TextDirection.rtl);
      expect(sensDeLaSaisie(''), isNull);
      expect(sensDeLaSaisie('12 : ...'), isNull);
    });

    // Revue CARTES-PERSO-1, deuxieme passe (capture arabe de la vraie
    // feuille) : le titre de la feuille se lisait « Modifier la carte « «
    // Récitation modèle », le texte saisi « .L'enregistrement ... lundi ».
    testWidgets('modification, rtl : titre de la feuille isole, champs dans '
        'le sens de leur texte, lien de gauche a droite', (
      WidgetTester tester,
    ) async {
      _taille(tester, const Size(390, 3200));
      await tester.pumpWidget(
        _hote(
          const BlocCartesClasse(groupeId: _id),
          surcharges: _demo(peutModifier: true),
          sens: TextDirection.rtl,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(texteAffiche('Récitation modèle')));
      await tester.pumpAndSettle();
      expect(find.byType(FeuilleCarteClasse), findsOneWidget);
      final String titre = isolerSens(
        t.classe.cartes.feuille.titreModifier(
          titre: isolerSens('Récitation modèle'),
        ),
      );
      expect(find.text(titre), findsOneWidget);
      TextDirection? sensDe(Key cle) =>
          tester.widget<TextField>(find.byKey(cle)).textDirection;
      expect(sensDe(FeuilleCarteClasse.titreKey), TextDirection.ltr);
      expect(sensDe(FeuilleCarteClasse.texteKey), TextDirection.ltr);
      expect(sensDe(FeuilleCarteClasse.lienKey), TextDirection.ltr);
      // Un texte arabe saisi passe le champ de droite a gauche ; vide, il
      // suit l'interface.
      await tester.enterText(find.byKey(FeuilleCarteClasse.texteKey), 'اقرأ');
      await tester.pump();
      expect(sensDe(FeuilleCarteClasse.texteKey), TextDirection.rtl);
      await tester.enterText(find.byKey(FeuilleCarteClasse.texteKey), '');
      await tester.pump();
      expect(sensDe(FeuilleCarteClasse.texteKey), isNull);
    });
  });

  group('demonstration', () {
    setUpAll(chargerPolicesDuDepot);

    Future<void> monter(
      WidgetTester tester,
      String adresse, {
      Size taille = const Size(390, 5200),
    }) async {
      _taille(tester, taille);
      final GoRouter routeur = GoRouter(
        initialLocation: adresse,
        routes: routesDemoClasse('dev'),
      );
      addTearDown(routeur.dispose);
      await tester.pumpWidget(
        ProviderScope(
          child: TranslationProvider(
            child: MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              locale: AppLocale.fr.flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              routerConfig: routeur,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('Espace Classe eleve : les cartes se lisent, sans '
        'modification', (WidgetTester tester) async {
      await monter(
        tester,
        adresseDemoClasse(RoleEntree.eleve, EtatDemoClasse.aVenir),
      );
      expect(find.byType(BlocCartesClasse), findsOneWidget);
      expect(_cartes, findsNWidgets(3));
      expect(find.byKey(BlocCartesClasse.ajouterKey), findsNothing);
    });

    testWidgets('Espace Classe enseignant : les cartes se modifient', (
      WidgetTester tester,
    ) async {
      await monter(
        tester,
        adresseDemoClasse(RoleEntree.enseignant, EtatDemoClasse.aVenir),
      );
      expect(find.byType(BlocCartesClasse), findsOneWidget);
      expect(find.byKey(BlocCartesClasse.ajouterKey), findsOneWidget);
      expect(
        find.text(isolerSens(t.classe.cartes.contexteEnseignant)),
        findsOneWidget,
      );
    });

    // Revue CARTES-PERSO-1 : la feuille vit sur le Navigator du routeur,
    // au-dessus du `ProviderScope` imbrique de la demonstration. Sur la
    // VRAIE page, l'enregistrement et le retrait doivent aboutir.
    for (final Size taille in const <Size>[Size(390, 5200), Size(1440, 5200)]) {
      final String l = '${taille.width.toInt()}';
      testWidgets('Espace Classe enseignant, $l : une carte touchee '
          's enregistre', (WidgetTester tester) async {
        await monter(
          tester,
          adresseDemoClasse(RoleEntree.enseignant, EtatDemoClasse.aVenir),
          taille: taille,
        );
        await tester.ensureVisible(_cartes.first);
        await tester.pumpAndSettle();
        await tester.tap(_cartes.first);
        await tester.pumpAndSettle();
        expect(find.byType(FeuilleCarteClasse), findsOneWidget);
        await tester.enterText(
          find.byKey(FeuilleCarteClasse.titreKey),
          'Réviser la sourate Quraysh',
        );
        await tester.ensureVisible(
          find.byKey(FeuilleCarteClasse.enregistrerKey),
        );
        await tester.tap(find.byKey(FeuilleCarteClasse.enregistrerKey));
        await tester.pumpAndSettle();
        expect(
          find.text(isolerSens(t.classe.cartes.feuille.envoiNonConfirme)),
          findsNothing,
        );
        expect(find.byType(FeuilleCarteClasse), findsNothing);
        expect(
          find.text(texteAffiche('Réviser la sourate Quraysh')),
          findsOneWidget,
        );
        expect(find.text(t.classe.cartes.enregistree), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('Espace Classe enseignant, $l : une carte se retire', (
        WidgetTester tester,
      ) async {
        await monter(
          tester,
          adresseDemoClasse(RoleEntree.enseignant, EtatDemoClasse.aVenir),
          taille: taille,
        );
        final String titre = texteAffiche('Pas de séance pendant les vacances');
        await tester.ensureVisible(find.text(titre));
        await tester.pumpAndSettle();
        await tester.tap(find.text(titre));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(FeuilleCarteClasse.retirerKey));
        await tester.tap(find.byKey(FeuilleCarteClasse.retirerKey));
        await tester.pumpAndSettle();
        await tester.tap(
          find.text(t.classe.cartes.feuille.retirerConfirmer).last,
        );
        await tester.pumpAndSettle();
        expect(
          find.text(isolerSens(t.classe.cartes.feuille.retraitNonConfirme)),
          findsNothing,
        );
        expect(find.byType(FeuilleCarteClasse), findsNothing);
        expect(find.text(titre), findsNothing);
        expect(_cartes, findsNWidgets(2));
        expect(find.text(t.classe.cartes.retiree), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
