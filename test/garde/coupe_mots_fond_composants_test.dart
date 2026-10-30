// COUPE-MOTS-FOND-1 : les points de la fiche, mesures un par un sur le
// rendu (le balayage les couvre aussi, ecran par ecran).
//
// (1) `DataCollection` : a 1440 texte x1 le tableau reste un tableau ; a
//     1440 texte x2, aucun en-tete ni aucune cellule n'est tronque ou coupe
//     (« Entr... », « 23/09/20 / 26 », « 18:12: / 00 ») : le tableau se
//     replie en cartes quand le texte agrandi ne tient pas.
// (2) Comptes, cartes a 320 texte x2 : chaque carte a un titre a la taille
//     des autres titres (hierarchie) ; un identifiant trop long pour le
//     titre passe en sous-titre, ENTIER : ses traits restent insecables
//     (U+2011), aucune espace sans chasse, jamais coupe.
// (3) `RangeeFiltres` : puce retenue en derniere position, rangee en
//     butee : la puce precedente, a moitie visible, est sous un fondu.
//
// Contre-epreuve (ancien code, d986c1de) : (1) echoue (« Entrée :
// tronque », identifiants coupes), (2) echoue (titre reduit), (3) echoue
// (« puce coupee ... visible au-dela du fondu »). Sur d643e317, (2) echoue
// aussi : l'identifiant ouvert par U+200B est coupe a ses traits.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_observation/port_historique_observations.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/data_collection.dart';
import 'package:rewayah_academy/core/widgets/filter_pill.dart';
import 'package:rewayah_academy/core/widgets/rangee_filtres.dart';
import 'package:rewayah_academy/features/admin_comptes/comptes_page.dart';
import 'package:rewayah_academy/features/admin_observations/annuaire_observations.dart';
import 'package:rewayah_academy/features/admin_observations/observations_admin_page.dart';

import '../capture/outil_capture.dart';
import '../features/admin_observations/support_admin_observations.dart'
    show FauxAnnuaire, FauxHistoriqueObservationsAdmin;
import '../support/balayage_ecrans.dart';
import '../support/doubles_balayage.dart';
import '../support/garde_coupe_mots_rendu.dart';
import '../support/sens_et_echelle.dart';

EcranBalayage _comptes() => (
  nom: 'Comptes',
  page: () => const ComptesPage(),
  routeur: null,
  depart: null,
  surcharges: () => <Override>[
    reseauBalayage(),
    serviceComptesProvider.overrideWithValue(ComptesBalayage()),
  ],
);

EcranBalayage _observations() => (
  nom: 'Observations',
  page: () => ObservationsAdminPage(horloge: () => DateTime(2026, 10, 5, 12)),
  routeur: null,
  depart: null,
  surcharges: () => <Override>[
    reseauBalayage(),
    portHistoriqueObservationsAdminProvider.overrideWithValue(
      FauxHistoriqueObservationsAdmin(),
    ),
    annuaireObservationsProvider.overrideWithValue(FauxAnnuaire()),
  ],
);

ConfigBalayage _config(
  Size taille,
  double echelle, {
  AppLocale langue = AppLocale.fr,
  InterfaceMode interface = InterfaceMode.standard,
}) => (
  gabarit: (nom: 'x', taille: taille, echelle: echelle),
  langue: langue,
  interface: interface,
);

/// La taille rendue (taille de police x echelle appliquee) d'un paragraphe.
double _tailleRendue(RenderParagraph p) =>
    p.textScaler.scale(p.text.style?.fontSize ?? 14);

void main() {
  setUpAll(() async {
    await chargerPolicesDuDepot();
    await LocaleSettings.setLocale(AppLocale.ar);
    await LocaleSettings.setLocale(AppLocale.fr);
  });

  group('(1) DataCollection', () {
    testWidgets('1440 texte x1 : le tableau reste un tableau, en-tetes '
        'entiers', (WidgetTester tester) async {
      await monterEcranBalayage(
        tester,
        _comptes(),
        _config(const Size(1440, 900), 1),
      );
      expect(find.text(t.admin.comptes.colonnePiece), findsOneWidget);
      expect(defautsDeTexte(tester), isEmpty);
    });

    for (final (String nom, EcranBalayage Function() ecran)
        in <(String, EcranBalayage Function())>[
          ('Comptes', _comptes),
          ('Observations', _observations),
        ]) {
      for (final InterfaceMode i in InterfaceMode.values) {
        testWidgets('$nom 1440 texte x2 ${i.name} : ni en-tete tronque, '
            'ni date, heure ou identifiant coupe', (WidgetTester tester) async {
          await monterEcranBalayage(
            tester,
            ecran(),
            _config(const Size(1440, 900), 2, interface: i),
          );
          // La mesure porte sur des dates et des identifiants rendus.
          expect(
            find.textContaining(RegExp(r'\d{2}/\d{2}/\d{4}|[A-Z]+.[A-Z]{2}.')),
            findsWidgets,
          );
          expect(await defautsEcranDefile(tester), isEmpty);
        });
      }
    }

    testWidgets('tientEnTableau : un mot plus large que sa colonne replie '
        'le tableau a texte agrandi, jamais a la taille du theme', (
      WidgetTester tester,
    ) async {
      final List<ColonneDonnees<String>> colonnes = <ColonneDonnees<String>>[
        ColonneDonnees<String>(titre: 'Quand', texte: (String l) => l),
        ColonneDonnees<String>(titre: 'Qui', texte: (String _) => 'Aicha'),
      ];
      late bool x1Etroit;
      late bool x2Etroit;
      late bool x2Large;
      Widget hote(double echelle, void Function(BuildContext) lire) =>
          MaterialApp(
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            builder: sensEtEchelle(echelle: echelle),
            home: Builder(
              builder: (BuildContext c) {
                lire(c);
                return const SizedBox.shrink();
              },
            ),
          );
      await tester.pumpWidget(
        hote(1, (BuildContext c) {
          x1Etroit = DataCollection.tientEnTableau<String>(
            c,
            colonnes: colonnes,
            lignes: <String>['23/09/2026'],
            largeur: 160,
          );
        }),
      );
      await tester.pumpWidget(
        hote(2, (BuildContext c) {
          x2Etroit = DataCollection.tientEnTableau<String>(
            c,
            colonnes: colonnes,
            lignes: <String>['23/09/2026'],
            largeur: 160,
          );
          x2Large = DataCollection.tientEnTableau<String>(
            c,
            colonnes: colonnes,
            lignes: <String>['23/09/2026'],
            largeur: 1200,
          );
        }),
      );
      expect(x1Etroit, isTrue, reason: 'a la taille du theme : tableau');
      expect(x2Etroit, isFalse, reason: 'texte x2, colonne etroite : cartes');
      expect(x2Large, isTrue, reason: 'texte x2, colonne large : tableau');
    });
  });

  group('(2) Comptes : hierarchie des titres de carte a 320 texte x2', () {
    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final InterfaceMode i in InterfaceMode.values) {
        testWidgets('${langue.name} ${i.name} : tous les titres a la meme '
            'taille, au-dessus de la ligne secondaire', (
          WidgetTester tester,
        ) async {
          await monterEcranBalayage(
            tester,
            _comptes(),
            _config(const Size(320, 4000), 2, langue: langue, interface: i),
          );
          final Finder cartes = find.descendant(
            of: find.byType(DataCollection<CompteAdmin>),
            matching: find.byType(AppCard),
          );
          // Comptes par role (30/10/2026) : la vue Enseignants s'ouvre (deux
          // enseignants attendent) et montre les trois enseignants du jeu.
          expect(cartes, findsNWidgets(3));
          final List<double> titres = <double>[];
          final List<double> secondaires = <double>[];
          for (final Element carte in cartes.evaluate()) {
            final List<RenderParagraph> p = find
                .descendant(
                  of: find.byWidget(carte.widget),
                  matching: find.byType(RichText),
                )
                .evaluate()
                .map((Element e) => e.renderObject! as RenderParagraph)
                .toList();
            titres.add(_tailleRendue(p.first));
            secondaires.add(_tailleRendue(p[1]));
          }
          // La carte dont le titre est l'identifiant (« TEACHER-AS-000002 »,
          // sans nom) garde un titre a la taille des titres nommes : l'en-tete
          // de la colonne ; l'identifiant passe en sous-titre, entier.
          for (final double taille in titres) {
            expect(taille, moreOrLessEquals(titres.first, epsilon: 0.01));
          }
          for (int k = 0; k < titres.length; k++) {
            expect(titres[k], greaterThan(secondaires[k]));
          }
          // L'identifiant n'est jamais ouvert a la coupure : traits
          // insecables, aucune espace sans chasse, sur une seule ligne.
          final Iterable<String> rendus = find
              .descendant(
                of: find.byType(DataCollection<CompteAdmin>),
                matching: find.byType(RichText),
              )
              .evaluate()
              .map(
                (Element e) =>
                    (e.renderObject! as RenderParagraph).text.toPlainText(),
              );
          expect(rendus.where((String t) => t.contains('\u200B')), isEmpty);
          expect(
            rendus.where((String t) => t.contains('TEACHER\u2011AS\u2011')),
            isNotEmpty,
          );
          // Relecture : l'identifiant passe en sous-titre n'est pas repete
          // en tete de la ligne de resume. Une seule fois dans sa carte.
          final Finder carteId = find.ancestor(
            of: find.text('TEACHER\u2011AS\u2011000002'),
            matching: find.byType(AppCard),
          );
          expect(carteId, findsOneWidget);
          final List<String> textesCarteId = find
              .descendant(of: carteId, matching: find.byType(RichText))
              .evaluate()
              .map(
                (Element e) =>
                    (e.renderObject! as RenderParagraph).text.toPlainText(),
              )
              .toList();
          expect(
            textesCarteId.where(
              (String t) => t.contains('TEACHER\u2011AS\u2011000002'),
            ),
            hasLength(1),
            reason: textesCarteId.join(' | '),
          );
          expect(identifiantsCoupes(tester, textesVisibles()), isEmpty);
          // Comptes n'est pas traduit en arabe : la ligne visuelle RTL n'est
          // pas lue (repli francais, `ecransTraduitsEnArabe`).
          expect(
            defautsDeTexte(tester, ligneVisuelleRtl: langue != AppLocale.ar),
            isEmpty,
          );
        });
      }
    }
  });

  group('(3) RangeeFiltres : puce retenue au bout, rangee en butee', () {
    for (final TextDirection sens in TextDirection.values) {
      testWidgets('${sens.name} 320 texte x2 : la puce precedente a moitie '
          'visible est sous un fondu', (WidgetTester tester) async {
        fixerVueCapture(tester, const Size(320, 600), 1);
        // L4-07 : la rangee ne montre qu'une puce et « Plus » quand un mot
        // long les empeche de tenir ; la puce retenue est rangee sous « Plus »,
        // qui la dit (« Plus, 1 ») et se voit au bout de la rangee qui defile.
        const List<String> libelles = <String>[
          'Anticonstitutionnellement',
          'En attente',
          'Actif',
          'Provisoire',
          'Suspendu',
        ];
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            builder: sensEtEchelle(direction: sens, echelle: 2),
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    RangeeFiltres(
                      filtres: <Widget>[
                        for (final String l in libelles)
                          FilterPill(
                            libelle: l,
                            compteur: 3,
                            retenue: l == libelles.last,
                            onPress: () {},
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final ScrollableState rangee = tester.state<ScrollableState>(
          find.descendant(
            of: find.byType(RangeeFiltres),
            matching: find.byType(Scrollable),
          ),
        );
        // En butee : la puce retenue est la derniere.
        expect(
          rangee.position.pixels,
          moreOrLessEquals(rangee.position.maxScrollExtent, epsilon: 0.5),
        );
        final RenduFonduBordsRangee fondu = tester.renderObject(
          find.byType(FonduBordsRangee),
        );
        expect(
          fondu.etatPeint.avant,
          isTrue,
          reason: 'le debut cache des puces',
        );
        expect(
          fondu.etatPeint.apres,
          isFalse,
          reason: 'rien apres la derniere',
        );
        // Le masque compose est actif, lu sur le calque.
        final Layer? calque = fondu.debugLayer;
        expect(calque, isA<ShaderMaskLayer>());
        expect((calque! as ShaderMaskLayer).blendMode, BlendMode.dstIn);
        expect(rangeesSansFondu(tester), isEmpty);
        expect(defautsDeTexte(tester), isEmpty);

        // Un pas de defilement qui ne change ni le debordement ni les bords
        // caches ne reconstruit pas la rangee : seul le masque se
        // redessine (il ecoute le controleur), et il suit la puce coupee.
        final StatefulElement element =
            tester.element(find.byType(RangeeFiltres)) as StatefulElement;
        // Hors butee d'abord (les deux bords cachent des puces), puis un
        // petit pas.
        rangee.position.jumpTo(rangee.position.pixels - 20);
        await tester.pump();
        expect(fondu.etatPeint.avant, isTrue);
        expect(fondu.etatPeint.apres, isTrue);
        rangee.position.jumpTo(rangee.position.pixels - 6);
        expect(element.dirty, isFalse, reason: 'aucune reconstruction');
        expect(fondu.debugNeedsPaint, isTrue, reason: 'le masque se redessine');
        await tester.pump();
        expect(fondu.etatPeint.avant, isTrue);
        expect(fondu.etatPeint.apres, isTrue);
        expect(rangeesSansFondu(tester), isEmpty);
      });
    }
  });
}
