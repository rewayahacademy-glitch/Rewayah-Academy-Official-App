// COM-ANN-1 : la carte d'une annonce de Classe (`ClassAnnouncementCard`,
// spec section 13.3) et le port neutre des annonces (COM-BR-10). Le RENDU est
// verifie : niveau dit par un mot, actions rendues seulement quand elles
// aboutissent, texte coupe puis entier, 320 et 1440, texte x2, sombre, RTL.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/communications/modeles_communication.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/badge_non_lu.dart';
import 'package:rewayah_academy/core/widgets/carte_groupee.dart';
import 'package:rewayah_academy/features/com_annonces/carte_annonce_classe.dart';
import 'package:rewayah_academy/features/com_annonces/port_annonces.dart';

import '../../support/garde_interface.dart';
import 'faux_annonces.dart';

Future<void> _poser(
  WidgetTester tester,
  Widget carte, {
  Size taille = const Size(390, 844),
  double echelle = 1,
  Brightness luminosite = Brightness.light,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    TranslationProvider(
      child: Builder(
        builder: (BuildContext racine) => MaterialApp(
          theme: AppTheme.pour(InterfaceMode.standard, luminosite),
          locale: TranslationProvider.of(racine).flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Builder(
            builder: (BuildContext context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(echelle)),
              child: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: carte,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('CarteAnnonceClasse', () {
    testWidgets('non lue : le niveau « A lire » en toutes lettres, la '
        'Classe, le titre, l auteur ; une seule carte', (
      WidgetTester tester,
    ) async {
      await _poser(tester, CarteAnnonceClasse(annonce: annonceDeTest()));
      expect(find.byType(CarteGroupee), findsOneWidget);
      expect(
        // « An-Nour » insecable au trait d'union (lot L).
        find.text('${t.com.annonces.annonce} · Classe An-\u2060Nour'),
        findsOneWidget,
      );
      expect(find.text(t.com.socle.composants.badge.aLire), findsOneWidget);
      expect(find.byType(BadgeNonLu), findsOneWidget);
      expect(find.text('Récitation de fin de trimestre'), findsOneWidget);
      expect(
        find.textContaining('Enseignante de la Classe, le '),
        findsOneWidget,
      );
      // Aucune action sans rappel : rien n'est grise, rien n'est rendu.
      expect(find.byKey(CarteAnnonceClasse.cleLire), findsNothing);
      expect(find.byKey(CarteAnnonceClasse.cleOuvrirClasse), findsNothing);
      expect(find.byKey(CarteAnnonceClasse.cleMarquerLue), findsNothing);
    });

    testWidgets(
      'annonce generale rendue dans une Classe : la carte dit « Toute '
      'l academie », jamais le nom de la Classe de contexte',
      (WidgetTester tester) async {
        await _poser(
          tester,
          CarteAnnonceClasse(annonce: annonceDeTest(generale: true)),
        );
        expect(
          find.text(
            '${t.com.annonces.annonce} · ${t.com.annonces.toutesAcademie}',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('An-⁠Nour'), findsNothing);
        expect(
          find.bySemanticsLabel(
            RegExp(
              '^${RegExp.escape(t.com.annonces.carteSemantique(classe: t.com.annonces.toutesAcademie, titre: 'Récitation de fin de trimestre'))}',
            ),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('lue : plus de badge « A lire », ni « Marquer comme lue »', (
      WidgetTester tester,
    ) async {
      await _poser(
        tester,
        CarteAnnonceClasse(
          annonce: annonceDeTest(lue: true),
          onMarquerLue: () {},
        ),
      );
      expect(find.byType(BadgeNonLu), findsNothing);
      expect(find.text(t.com.socle.composants.badge.aLire), findsNothing);
      expect(find.byKey(CarteAnnonceClasse.cleMarquerLue), findsNothing);
    });

    testWidgets('urgente et lue : l urgence reste dite par un mot', (
      WidgetTester tester,
    ) async {
      await _poser(
        tester,
        CarteAnnonceClasse(
          annonce: annonceDeTest(lue: true, niveau: NiveauAttention.urgent),
        ),
      );
      expect(find.text(t.com.socle.composants.badge.urgent), findsOneWidget);
    });

    testWidgets('texte long : coupe sur la carte, « Lire l annonce en '
        'entier » ; texte court : ni coupe ni lien', (
      WidgetTester tester,
    ) async {
      int lectures = 0;
      await _poser(
        tester,
        CarteAnnonceClasse(annonce: annonceDeTest(), onLire: () => lectures++),
      );
      final Text texte = tester.widget<Text>(find.text(texteLong));
      expect(texte.maxLines, CarteAnnonceClasse.lignesCarte);
      await tester.tap(find.byKey(CarteAnnonceClasse.cleLire));
      expect(lectures, 1);

      await _poser(
        tester,
        CarteAnnonceClasse(
          annonce: annonceDeTest(texte: 'Révisez avant jeudi.'),
          onLire: () => lectures++,
        ),
      );
      expect(find.byKey(CarteAnnonceClasse.cleLire), findsNothing);
    });

    testWidgets('complete : le texte entier, sans lien de lecture', (
      WidgetTester tester,
    ) async {
      await _poser(
        tester,
        CarteAnnonceClasse(
          annonce: annonceDeTest(),
          complete: true,
          onLire: () {},
        ),
      );
      expect(tester.widget<Text>(find.text(texteLong)).maxLines, isNull);
      expect(find.byKey(CarteAnnonceClasse.cleLire), findsNothing);
    });

    testWidgets('« Ouvrir la Classe » : seulement avec un rappel ET une '
        'destination ; lu « Ouvrir Classe An-Nour »', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantique = tester.ensureSemantics();
      int ouvertures = 0;
      await _poser(
        tester,
        CarteAnnonceClasse(
          annonce: annonceDeTest(),
          onOuvrirClasse: () => ouvertures++,
        ),
      );
      expect(
        find.bySemanticsLabel(
          RegExp(
            RegExp.escape(
              t.com.annonces.ouvrirClasseSemantique(classe: 'Classe An-Nour'),
            ),
          ),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(CarteAnnonceClasse.cleOuvrirClasse));
      expect(ouvertures, 1);

      await _poser(
        tester,
        CarteAnnonceClasse(
          annonce: annonceDeTest(destination: null),
          onOuvrirClasse: () => ouvertures++,
        ),
      );
      expect(find.byKey(CarteAnnonceClasse.cleOuvrirClasse), findsNothing);
      semantique.dispose();
    });

    testWidgets('une destination vers la salle n est jamais suivie', (
      WidgetTester tester,
    ) async {
      final AnnonceClasse a = annonceDeTest(destination: '/tc/classe');
      expect(a.classe.destination, isNull);
      expect(annonceDeTest(destination: 'https://exemple.org'), isNotNull);
      expect(
        annonceDeTest(destination: 'https://exemple.org').classe.destination,
        isNull,
      );
    });

    for (final Size taille in <Size>[
      const Size(320, 700),
      const Size(1440, 900),
    ]) {
      for (final double echelle in <double>[1, 2]) {
        for (final Brightness b in Brightness.values) {
          testWidgets('${taille.width.toInt()}, texte x$echelle, ${b.name} : '
              'actions centrees, rien ne deborde', (WidgetTester tester) async {
            await _poser(
              tester,
              CarteAnnonceClasse(
                annonce: annonceDeTest(),
                onLire: () {},
                onOuvrirClasse: () {},
                onMarquerLue: () {},
              ),
              taille: taille,
              echelle: echelle,
              luminosite: b,
            );
            expect(tester.takeException(), isNull);
            expect(find.byKey(CarteAnnonceClasse.cleLire), findsOneWidget);
            expect(
              find.byKey(CarteAnnonceClasse.cleOuvrirClasse),
              findsOneWidget,
            );
            expect(
              find.byKey(CarteAnnonceClasse.cleMarquerLue),
              findsOneWidget,
            );
            verifierSansChevauchement(tester, <Finder>[
              find.byKey(CarteAnnonceClasse.cleMarquerLue),
              find.byKey(CarteAnnonceClasse.cleLire),
              find.byKey(CarteAnnonceClasse.cleOuvrirClasse),
            ]);
            verifierUnSeulBoutonPlein(tester);
          });
        }
      }
    }

    testWidgets('arabe : de droite a gauche, mots du niveau traduits', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
      await _poser(
        tester,
        CarteAnnonceClasse(annonce: annonceDeTest(), onMarquerLue: () {}),
      );
      expect(
        Directionality.of(tester.element(find.byType(CarteAnnonceClasse))),
        TextDirection.rtl,
      );
      expect(find.text('تحديد كمقروء'), findsOneWidget);
      // Le badge se range au debut de la ligne : a droite en arabe.
      final Rect carte = tester.getRect(find.byType(CarteGroupee));
      final Rect badge = tester.getRect(find.byType(BadgeNonLu));
      expect(badge.right, greaterThan(carte.center.dx));
      expect(tester.takeException(), isNull);
    });
  });

  group('PortAnnonces de production', () {
    test('neutre : chaque lecture et ecriture leve COM-BR-10', () async {
      final ProviderContainer c = ProviderContainer();
      addTearDown(c.dispose);
      final PortAnnonces port = c.read(portAnnoncesProvider);
      expect(port, isA<AnnoncesIndisponibles>());
      await expectLater(
        port.annoncesDeClasse('c1'),
        throwsA(
          isA<CapaciteIndisponible>().having(
            (CapaciteIndisponible e) => e.dependance,
            'dependance',
            'COM-BR-10',
          ),
        ),
      );
      await expectLater(
        port.annonce('a1'),
        throwsA(isA<CapaciteIndisponible>()),
      );
      await expectLater(
        port.marquerLue('a1'),
        throwsA(isA<CapaciteIndisponible>()),
      );
    });

    test('les capacites sont fermees par defaut', () {
      const AnnoncesDeLaClasse vue = AnnoncesDeLaClasse(
        annonces: <AnnonceClasse>[],
      );
      expect(vue.peut(CapaciteAnnonces.publier), isFalse);
      expect(
        const AnnoncesDeLaClasse(
          annonces: <AnnonceClasse>[],
          capacites: <CapaciteAnnonces>{CapaciteAnnonces.publier},
        ).peut(CapaciteAnnonces.publier),
        isTrue,
      );
    });
  });
}
