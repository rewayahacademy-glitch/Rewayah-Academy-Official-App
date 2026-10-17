// L2-05 : l'administration des offres vitrine (liste, creation, publication,
// retrait).
//
// Ce que le test prouve :
// - les cinq etats : chargement (squelette), contenu (trois offres, une par
//   etat), vide, erreur et sa relecture, hors ligne ;
// - un seul bouton plein, « Nouvelle offre » ; jamais « Modifier » ; aucun
//   enseignant ;
// - publier un brouillon, puis la liste se relit ;
// - retirer sans motif est refuse, avec un motif l'offre est retiree ;
// - creer : aucun jour choisi donne « Choisissez au moins un jour », un
//   mauvais nombre de jours est dit, un refus du serveur est dit, une
//   creation valide envoie les parametres attendus (jours ISO, heure pleine) ;
// - 390 et 1440, clair, arabe (miroir), 320 px texte x2 : aucun debordement,
//   aucun mot coupe.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/offres/offres_admin_demo.dart';
import 'package:rewayah_academy/core/offres/port_offres_admin.dart';
import 'package:rewayah_academy/core/reseau/etat_sans_donnees.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/admin_offres/admin_offres_page.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/aucun_mot_coupe.dart';
import '../../support/garde_interface.dart';

/// Un port en memoire dont on voit les appels et dont on pilote les pannes.
class _Faux extends OffresAdminDemo {
  _Faux({super.offres, this.refus});

  bool lectureEnEchec = false;
  OffreAdminRefusee? refus;
  Completer<void>? porte;
  int lectures = 0;
  final List<Map<String, Object?>> creations = <Map<String, Object?>>[];
  final List<String> retraits = <String>[];

  @override
  Future<List<OffreAdmin>> lister() async {
    lectures++;
    if (porte != null) await porte!.future;
    if (lectureEnEchec) throw StateError('lecture');
    return super.lister();
  }

  @override
  Future<String> creer({
    required String typePublic,
    required String langueCode,
    required String fuseauIana,
    required List<int> jours,
    required int heureLocale,
    int? dureeMinutes,
  }) async {
    if (refus != null) throw refus!;
    creations.add(<String, Object?>{
      'public': typePublic,
      'langue': langueCode,
      'fuseau': fuseauIana,
      'jours': jours,
      'heure': heureLocale,
      'duree': dureeMinutes,
    });
    return super.creer(
      typePublic: typePublic,
      langueCode: langueCode,
      fuseauIana: fuseauIana,
      jours: jours,
      heureLocale: heureLocale,
      dureeMinutes: dureeMinutes,
    );
  }

  @override
  Future<void> retirer(String offreId, {required String motif}) {
    retraits.add('$offreId|$motif');
    return super.retirer(offreId, motif: motif);
  }
}

Future<void> _monter(
  WidgetTester tester, {
  required PortOffresAdmin port,
  bool horsLigne = false,
  double largeur = 390,
  double hauteur = 3000,
  double echelle = 1,
  bool arabe = false,
  Brightness luminosite = Brightness.light,
}) async {
  if (arabe) {
    // La locale arabe est une bibliotheque differee : elle se charge hors de
    // l'horloge simulee du test.
    await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
  } else {
    LocaleSettings.setLocaleSync(AppLocale.fr);
  }
  addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
  tester.view.physicalSize = Size(largeur, hauteur);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        portOffresAdminProvider.overrideWithValue(port),
        horsLigneProvider.overrideWith(
          (Ref _) => Stream<bool>.value(horsLigne),
        ),
      ],
      child: TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.pour(InterfaceMode.standard, luminosite),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (BuildContext contexte, Widget? app) => Directionality(
            textDirection: arabe ? TextDirection.rtl : TextDirection.ltr,
            child: MediaQuery(
              data: MediaQuery.of(contexte)
                  .copyWith(textScaler: TextScaler.linear(echelle)),
              child: app!,
            ),
          ),
          home: const AdminOffresPage(),
        ),
      ),
    ),
  );
  await _laisser(tester);
}

Future<void> _laisser(WidgetTester tester, {int fois = 8}) async {
  for (int i = 0; i < fois; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Finder _cle(String cle) => find.byKey(ValueKey<String>(cle));

Future<void> _toucher(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.tap(f);
  await _laisser(tester);
}

Future<void> _ouvrirCreation(WidgetTester tester) async {
  await _toucher(tester, _cle('offres-nouvelle'));
  expect(_cle('nouvelle-offre-bloc'), findsOneWidget);
}

Finder _boutonCreer() =>
    find.widgetWithText(ActionPrincipale, t.admin.offres.formulaire.creer);

void main() {
  setUpAll(chargerPolicesDuDepot);

  group('Les cinq etats', () {
    testWidgets('chargement : un squelette, puis le contenu', (
      WidgetTester tester,
    ) async {
      final _Faux port = _Faux()..porte = Completer<void>();
      await _monter(tester, port: port);
      expect(find.byType(Skeleton), findsWidgets);
      expect(_cle('offres-contenu'), findsNothing);
      port.porte!.complete();
      await _laisser(tester);
      expect(_cle('offres-contenu'), findsOneWidget);
    });

    testWidgets('contenu : trois offres, une par etat, et leurs actions', (
      WidgetTester tester,
    ) async {
      await _monter(tester, port: _Faux());
      for (final String id in <String>[
        'offre-demo-1',
        'offre-demo-2',
        'offre-demo-3',
      ]) {
        expect(_cle('offre-$id'), findsOneWidget);
      }
      expect(find.text('Publiée'), findsOneWidget);
      expect(find.text('Brouillon'), findsOneWidget);
      expect(find.text('Retirée'), findsOneWidget);
      // Brouillon : Publier et Retirer ; publiee : Retirer ; retiree : rien.
      expect(_cle('offre-publier-offre-demo-2'), findsOneWidget);
      expect(_cle('offre-retirer-offre-demo-2'), findsOneWidget);
      expect(_cle('offre-publier-offre-demo-1'), findsNothing);
      expect(_cle('offre-retirer-offre-demo-1'), findsOneWidget);
      expect(_cle('offre-publier-offre-demo-3'), findsNothing);
      expect(_cle('offre-retirer-offre-demo-3'), findsNothing);
      // Le motif d'une offre retiree se lit ; jamais « Modifier ».
      expect(_cle('offre-motif-offre-demo-3'), findsOneWidget);
      expect(find.textContaining('Modifier'), findsNothing);
      expect(find.textContaining('nseignant'), findsOneWidget);
      verifierUnSeulBoutonPlein(tester);
    });

    testWidgets('vide : la phrase de la fiche, et le bouton plein reste', (
      WidgetTester tester,
    ) async {
      await _monter(tester, port: _Faux(offres: <OffreAdmin>[]));
      expect(_cle('offres-vide'), findsOneWidget);
      expect(
        find.text(
          "Aucune offre pour l'instant. Créez la première pour ouvrir la "
          'vitrine aux familles.',
        ),
        findsOneWidget,
      );
      expect(_cle('offres-nouvelle'), findsOneWidget);
      verifierUnSeulBoutonPlein(tester);
    });

    testWidgets('erreur : « Reessayer » relit', (WidgetTester tester) async {
      final _Faux port = _Faux()..lectureEnEchec = true;
      await _monter(tester, port: port);
      expect(_cle('offres-erreur'), findsOneWidget);
      expect(find.byType(EtatSysteme), findsOneWidget);
      final int avant = port.lectures;
      port.lectureEnEchec = false;
      await _toucher(
        tester,
        find.widgetWithText(ActionPrincipale, t.commun.reessayer),
      );
      expect(port.lectures, greaterThan(avant));
      expect(_cle('offres-contenu'), findsOneWidget);
    });

    testWidgets('hors ligne : sans donnees dit ce qui manque', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        port: _Faux()..lectureEnEchec = true,
        horsLigne: true,
      );
      expect(_cle('offres-sans-donnees'), findsOneWidget);
      expect(find.byType(EtatSansDonnees), findsOneWidget);
    });

    testWidgets(
      'hors ligne avec donnees : aucune action de carte, une phrase',
      (WidgetTester tester) async {
        await _monter(tester, port: _Faux(), horsLigne: true);
        expect(_cle('offres-contenu'), findsOneWidget);
        expect(_cle('offres-hors-ligne'), findsOneWidget);
        expect(_cle('offre-publier-offre-demo-2'), findsNothing);
        expect(_cle('offre-retirer-offre-demo-1'), findsNothing);
      },
    );
  });

  group('Publier et retirer', () {
    testWidgets('publier un brouillon le rend publie', (
      WidgetTester tester,
    ) async {
      await _monter(tester, port: _Faux());
      await _toucher(tester, _cle('offre-publier-offre-demo-2'));
      expect(find.text(t.admin.offres.publiee), findsOneWidget);
      expect(_cle('offre-publier-offre-demo-2'), findsNothing);
      expect(find.text('Publiée'), findsNWidgets(2));
    });

    testWidgets('retirer sans motif est refuse, rien ne part', (
      WidgetTester tester,
    ) async {
      final _Faux port = _Faux();
      await _monter(tester, port: port);
      await _toucher(tester, _cle('offre-retirer-offre-demo-1'));
      expect(_cle('retrait-motif'), findsOneWidget);
      await _toucher(
        tester,
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.widgetWithText(
            ActionPrincipale,
            t.admin.offres.retirer,
          ),
        ),
      );
      expect(find.text(t.admin.offres.motifManque), findsOneWidget);
      expect(port.retraits, isEmpty);
    });

    testWidgets('retirer avec un motif retire l offre', (
      WidgetTester tester,
    ) async {
      final _Faux port = _Faux();
      await _monter(tester, port: port);
      await _toucher(tester, _cle('offre-retirer-offre-demo-1'));
      await tester.enterText(_cle('retrait-motif'), 'Horaire remplacé');
      await _toucher(
        tester,
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.widgetWithText(
            ActionPrincipale,
            t.admin.offres.retirer,
          ),
        ),
      );
      expect(port.retraits, <String>['offre-demo-1|Horaire remplacé']);
      expect(find.text(t.admin.offres.retiree), findsOneWidget);
      expect(_cle('offre-retirer-offre-demo-1'), findsNothing);
      expect(_cle('offre-motif-offre-demo-1'), findsOneWidget);
    });
  });

  group('Creation', () {
    testWidgets('aucun jour : le bouton reste actif et dit ce qui manque', (
      WidgetTester tester,
    ) async {
      final _Faux port = _Faux();
      await _monter(tester, port: port);
      await _ouvrirCreation(tester);
      await _toucher(tester, _boutonCreer());
      expect(find.text('Choisissez au moins un jour'), findsOneWidget);
      expect(port.creations, isEmpty);
    });

    testWidgets('un autre nombre de jours que celui de l academie est dit', (
      WidgetTester tester,
    ) async {
      final _Faux port = _Faux();
      await _monter(tester, port: port);
      await _ouvrirCreation(tester);
      await _toucher(tester, _cle('offre-jour-1'));
      await _toucher(tester, _boutonCreer());
      // Le nombre et son unite sont insecables (U+00A0, DUREE-INSECABLE-3).
      expect(find.text('Choisissez exactement 3\u00a0jours'), findsOneWidget);
      expect(port.creations, isEmpty);
    });

    testWidgets('une creation valide envoie jours ISO, heure pleine, duree', (
      WidgetTester tester,
    ) async {
      final _Faux port = _Faux();
      await _monter(tester, port: port);
      await _ouvrirCreation(tester);
      for (final int j in <int>[1, 3, 5]) {
        await _toucher(tester, _cle('offre-jour-$j'));
      }
      await _toucher(tester, _cle('offre-public-adulte'));
      await _toucher(tester, _boutonCreer());
      expect(port.creations, hasLength(1));
      final Map<String, Object?> c = port.creations.single;
      expect(c['public'], 'adulte');
      expect(c['jours'], <int>[1, 3, 5]);
      expect(c['heure'], 18);
      expect(c['fuseau'], 'Europe/Paris');
      expect(c['duree'], 90);
      // Retour a la liste : l'offre est la, en brouillon, et la phrase le dit.
      expect(_cle('offres-contenu'), findsOneWidget);
      expect(find.text(t.admin.offres.creee), findsOneWidget);
      expect(find.text('Brouillon'), findsNWidgets(2));
    });

    testWidgets(
      'apres une creation confirmee : formulaire ferme, liste relue',
      (WidgetTester tester) async {
        final _Faux port = _Faux();
        await _monter(tester, port: port);
        final int lecturesAvant = port.lectures;
        await _ouvrirCreation(tester);
        for (final int j in <int>[1, 3, 6]) {
          await _toucher(tester, _cle('offre-jour-$j'));
        }
        await _toucher(tester, _boutonCreer());
        // L2-05-reprise (D-3) : le formulaire ne reste jamais ouvert apres une
        // creation que le serveur a confirmee, et la liste est relue.
        expect(_cle('nouvelle-offre-bloc'), findsNothing);
        expect(find.text(t.admin.offres.creee), findsOneWidget);
        expect(port.lectures, greaterThan(lecturesAvant));
        expect(find.textContaining('Refusé par le serveur'), findsNothing);
      },
    );

    testWidgets('un refus du serveur est dit, la saisie reste', (
      WidgetTester tester,
    ) async {
      final _Faux port = _Faux(
        refus: const OffreAdminRefusee('Une offre identique existe déjà.'),
      );
      await _monter(tester, port: port);
      await _ouvrirCreation(tester);
      for (final int j in <int>[2, 4, 6]) {
        await _toucher(tester, _cle('offre-jour-$j'));
      }
      await _toucher(tester, _boutonCreer());
      expect(
        find.textContaining('Une offre identique existe déjà.'),
        findsOneWidget,
      );
      expect(_cle('nouvelle-offre-bloc'), findsOneWidget);
    });

    testWidgets('hors ligne : rien ne part, une phrase le dit', (
      WidgetTester tester,
    ) async {
      final _Faux port = _Faux();
      await _monter(tester, port: port, horsLigne: true);
      await _ouvrirCreation(tester);
      for (final int j in <int>[1, 3, 5]) {
        await _toucher(tester, _cle('offre-jour-$j'));
      }
      await _toucher(tester, _boutonCreer());
      expect(find.text(t.admin.offres.formulaire.horsLigne), findsOneWidget);
      expect(port.creations, isEmpty);
    });
  });

  group('Gabarits', () {
    for (final (String nom, double largeur, double echelle, bool arabe)
        in <(String, double, double, bool)>[
          ('390 clair', 390, 1, false),
          ('1440 clair', 1440, 1, false),
          ('390 arabe (miroir)', 390, 1, true),
          ('320 texte x2', 320, 2, false),
          ('320 texte x2 arabe', 320, 2, true),
        ]) {
      testWidgets('la liste, $nom : aucun debordement, aucun mot coupe', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          port: _Faux(),
          largeur: largeur,
          echelle: echelle,
          arabe: arabe,
        );
        expect(tester.takeException(), isNull);
        expect(_cle('offres-contenu'), findsOneWidget);
        verifierUnSeulBoutonPlein(tester);
        verifierEcranSansMotCoupe(tester);
      });

      testWidgets('le formulaire, $nom : aucun debordement, aucun mot coupe', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          port: _Faux(),
          largeur: largeur,
          echelle: echelle,
          arabe: arabe,
        );
        await _toucher(tester, _cle('offres-nouvelle'));
        expect(tester.takeException(), isNull);
        expect(_cle('nouvelle-offre-bloc'), findsOneWidget);
        verifierUnSeulBoutonPlein(tester);
        verifierEcranSansMotCoupe(tester);
      });
    }

    testWidgets('l arabe lit les libelles de la fiche', (
      WidgetTester tester,
    ) async {
      await _monter(tester, port: _Faux(offres: <OffreAdmin>[]), arabe: true);
      expect(find.text('عرض جديد'), findsOneWidget);
      expect(
        find.text(
          'لا توجد عروض حتى الآن. أنشئ العرض الأول لفتح الواجهة للعائلات.',
        ),
        findsOneWidget,
      );
    });
  });
}
