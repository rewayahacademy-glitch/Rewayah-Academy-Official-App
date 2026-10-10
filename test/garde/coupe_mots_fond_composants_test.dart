// COUPE-MOTS-FOND-1 : les points de la fiche, mesures un par un sur le
// rendu (le balayage les couvre aussi, ecran par ecran).
//
// (1) `DataCollection` : a 1440 texte x1 le tableau reste un tableau ; a
//     1440 texte x2, aucun en-tete ni aucune cellule n'est tronque ou coupe
//     (« Entr... », « 23/09/20 / 26 », « 18:12: / 00 ») : le tableau se
//     replie en cartes quand le texte agrandi ne tient pas.
// (2) Comptes, cartes a 320 texte x2 : l'identifiant en titre garde la
//     taille des autres titres (hierarchie), sur deux lignes au besoin.
// (3) `RangeeFiltres` : puce retenue en derniere position, rangee en
//     butee : la puce precedente, a moitie visible, est sous un fondu.
//
// Contre-epreuve (ancien code, d986c1de) : (1) echoue (« Entrée :
// tronque », identifiants coupes), (2) echoue (titre reduit), (3) echoue
// (« puce coupee ... visible au-dela du fondu »).

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
          expect(cartes, findsNWidgets(5));
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
          // Le titre identifiant (« TEACHER-AS-000002 », sans nom) a la
          // taille des titres nommes : il passe sur deux lignes.
          for (final double taille in titres) {
            expect(taille, moreOrLessEquals(titres.first, epsilon: 0.01));
          }
          for (int k = 0; k < titres.length; k++) {
            expect(titres[k], greaterThan(secondaires[k]));
          }
          expect(defautsDeTexte(tester), isEmpty);
        });
      }
    }
  });

  group('(3) RangeeFiltres : puce retenue au bout, rangee en butee', () {
    for (final TextDirection sens in TextDirection.values) {
      testWidgets('${sens.name} 320 texte x2 : la puce precedente a moitie '
          'visible est sous un fondu', (WidgetTester tester) async {
        fixerVueCapture(tester, const Size(320, 600), 1);
        const List<String> libelles = <String>[
          'Tous',
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
        final FonduBordsRangee fondu = tester.widget(
          find.byType(FonduBordsRangee),
        );
        expect(fondu.avant, isTrue, reason: 'le debut cache des puces');
        expect(fondu.apres, isFalse, reason: 'rien apres la derniere');
        expect(rangeesSansFondu(tester), isEmpty);
        expect(defautsDeTexte(tester), isEmpty);
      });
    }
  });
}
