// La file des candidatures sur le VRAI routeur (demonstration d'administration),
// avec la coque (barre laterale, en-tete) : ce que le directeur voit a 1440 x 900
// (LISTES-1, lot 2).
//
//   * la densite : la position de la premiere ligne, la hauteur des lignes, le
//     nombre de lignes entierement visibles sans defiler ;
//   * le retour de fiche : recherche, filtres, tri, page et defilement sont
//     gardes quand on revient de la candidature.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';
import 'package:rewayah_academy/core/candidature/port_candidatures_direction.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/case_a_cocher.dart';
import 'package:rewayah_academy/core/widgets/data_collection.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart'
    show DisqueRetour;
import 'package:rewayah_academy/core/widgets/pied_de_liste.dart';
import 'package:rewayah_academy/features/admin_candidature/candidature_page.dart';
import 'package:rewayah_academy/features/admin_candidatures/candidatures_page.dart';
import 'package:rewayah_academy/features/admin_candidatures/ligne_candidature.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../fixtures/candidature/faux_candidatures_direction.dart';
import '../../support/monter_recrutement.dart';

Future<GoRouter> _monter(
  WidgetTester tester,
  FauxCandidaturesDirection port, {
  Size taille = const Size(1440, 900),
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...surchargesDemoAdmin(environnement: 'staging'),
        portCandidaturesDirectionProvider.overrideWithValue(port),
      ],
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
  await laisser(tester);
  routeur.go(Routes.adminPersonnesCandidatures);
  await laisser(tester, fois: 12);
  return routeur;
}

/// Le bas de la zone visible du tableau : le haut de son pied.
double _basDuTableau(WidgetTester tester) =>
    tester.getTopLeft(find.byKey(CandidaturesPage.clePied)).dy;

void main() {
  // Les vraies polices : avec celles du test (des carres), chaque texte est plus
  // large qu'a l'ecran et le tableau compte moins de lignes que le directeur n'en
  // voit.
  setUpAll(chargerPolicesDuDepot);
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('densite a 1440 x 900 avec la coque', () {
    testWidgets('dix lignes entieres au moins, sans defiler', (
      WidgetTester tester,
    ) async {
      final List<LigneCandidature> donnees = lignesEnMasse(40);
      await _monter(
        tester,
        FauxCandidaturesDirection(
          lignes: donnees,
          capacitesRendues: capacitesGestes,
        ),
      );
      final double bas = _basDuTableau(tester);
      int entieres = 0;
      for (final LigneCandidature l in donnees) {
        final Finder f = find.byKey(cleCandidature(l.id));
        if (f.evaluate().isEmpty) break;
        final Rect r = tester.getRect(f);
        if (r.bottom <= bas + 0.5) entieres++;
      }
      final double premiere = tester
          .getTopLeft(find.byKey(cleCandidature('m0')))
          .dy;
      debugPrint(
        'MESURE premiere ligne y=$premiere, bas du tableau y=$bas, '
        'lignes entieres=$entieres',
      );
      // Avant : la premiere ligne a y = 684 et deux lignes tenaient.
      expect(premiere, lessThan(340));
      expect(entieres, greaterThanOrEqualTo(10));
    });

    testWidgets(
      'cocher une ligne ne deplace pas le tableau : la barre flotte (R-1)',
      (WidgetTester tester) async {
        final List<LigneCandidature> donnees = lignesEnMasse(40);
        await _monter(
          tester,
          FauxCandidaturesDirection(
            lignes: donnees,
            capacitesRendues: capacitesGestes,
          ),
        );
        final double avant = tester
            .getTopLeft(find.byKey(cleCandidature('m0')))
            .dy;
        final double basAvant = _basDuTableau(tester);
        // La premiere case du tableau est celle de l'en-tete : la suivante est
        // celle de la premiere ligne.
        await tester.tap(find.byType(CaseACocher).at(1));
        await laisser(tester);
        expect(find.byKey(CandidaturesPage.cleBarreLot), findsOneWidget);
        expect(
          tester.getTopLeft(find.byKey(cleCandidature('m0'))).dy,
          avant,
          reason: 'la premiere ligne ne bouge pas',
        );
        expect(_basDuTableau(tester), basAvant, reason: 'le pied ne bouge pas');
        // La barre est au-dessus du pied, jamais dessous.
        expect(
          tester.getRect(find.byKey(CandidaturesPage.cleBarreLot)).bottom,
          lessThanOrEqualTo(basAvant),
        );
      },
    );

    testWidgets('une ligne sans alerte mesure 56 au plus', (
      WidgetTester tester,
    ) async {
      final List<LigneCandidature> donnees = lignesEnMasse(12);
      await _monter(
        tester,
        FauxCandidaturesDirection(
          lignes: donnees,
          capacitesRendues: capacitesGestes,
        ),
      );
      for (final LigneCandidature l in donnees.take(6)) {
        expect(
          tester.getSize(find.byKey(cleCandidature(l.id))).height,
          lessThanOrEqualTo(56),
          reason: l.nomComplet,
        );
      }
    });

    testWidgets(
      'une ligne avec un repere d\'alerte reste a 56 : jamais deux pastilles empilees',
      (WidgetTester tester) async {
        final List<LigneCandidature> donnees = <LigneCandidature>[
          ligneTest(
            id: 'a1',
            nom: 'Amina Diallo',
            courrielAObtenir: true,
            indicatifAConfirmer: true,
          ),
          ligneTest(id: 'b2', nom: 'Bilal Haddad'),
        ];
        await _monter(
          tester,
          FauxCandidaturesDirection(
            lignes: donnees,
            capacitesRendues: capacitesGestes,
          ),
        );
        expect(
          tester.getSize(find.byKey(cleCandidature('a1'))).height,
          lessThanOrEqualTo(56),
        );
        expect(
          find.bySemanticsLabel(
            RegExp('Courriel à obtenir, Indicatif à confirmer'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('l\'en-tete de colonnes est colle : la table defile seule', (
      WidgetTester tester,
    ) async {
      final List<LigneCandidature> donnees = lignesEnMasse(40);
      await _monter(
        tester,
        FauxCandidaturesDirection(
          lignes: donnees,
          capacitesRendues: capacitesGestes,
        ),
      );
      final Finder entete = find.text(t.admin.candidatures.colonnes.nom);
      final double avant = tester.getTopLeft(entete).dy;
      final double premiere = tester
          .getTopLeft(find.byKey(cleCandidature('m0')))
          .dy;
      await tester.drag(
        find.byKey(cleCandidature('m3')),
        const Offset(0, -300),
      );
      await laisser(tester);
      expect(tester.getTopLeft(entete).dy, avant);
      // La liste a bouge, pas la page : la premiere ligne a quitte la vue.
      expect(
        find.byKey(cleCandidature('m0')).evaluate().isEmpty ||
            tester.getTopLeft(find.byKey(cleCandidature('m0'))).dy < premiere,
        isTrue,
      );
      // Et le pied reste en bas.
      expect(find.byType(PiedDeListe), findsOneWidget);
    });
  });

  group('retour de fiche', () {
    testWidgets('recherche, filtres, tri, page et defilement sont gardes', (
      WidgetTester tester,
    ) async {
      // 120 lignes : trois pages de 50, un tri, un filtre, une recherche.
      final List<LigneCandidature> donnees = <LigneCandidature>[
        for (int i = 0; i < 120; i++)
          ligneTest(
            id: 'p$i',
            nom: 'Personne ${i.toString().padLeft(3, '0')}',
            etat: EtatCandidature.enExamen,
            derniereActivite: DateTime.utc(
              2026,
              10,
              20,
            ).subtract(Duration(minutes: i)),
            recueLe: DateTime.utc(2026, 10, 1).add(Duration(minutes: i)),
          ),
      ];
      final FauxCandidaturesDirection port = FauxCandidaturesDirection(
        lignes: donnees,
        capacitesRendues: capacitesGestes,
        details: <DetailCandidature>[
          detailTest(id: 'p60', nom: 'Personne 060'),
        ],
      );
      await _monter(tester, port);

      // Le filtre : l'etat « En examen ».
      await tester.tap(
        find.byKey(const ValueKey<String>('candidatures-filtre-etat')),
      );
      await laisser(tester);
      await tester.tap(find.text(t.admin.candidatures.etats.enExamen).last);
      await laisser(tester, fois: 12);
      // La recherche.
      await tester.enterText(
        find.byKey(const ValueKey<String>('candidatures-recherche')),
        'Personne',
      );
      await laisser(tester, fois: 12);
      // Le tri : la date de reception (un toucher sur l'en-tete de date).
      await tester.tap(find.text(t.admin.candidatures.tri.activite));
      await laisser(tester, fois: 12);
      // La page 2.
      await tester.tap(find.byKey(const ValueKey<String>('nav-suivant')));
      await laisser(tester, fois: 12);

      final FiltreCandidatures filtre = port.appels.last.filtre;
      expect(filtre.etat, EtatCandidature.enExamen);
      expect(filtre.recherche, 'Personne');
      expect(port.appels.last.tri, TriCandidatures.recente);
      expect(port.appels.last.page, 2);

      // Le defilement de la table, puis l'ouverture d'une candidature de la
      // page 2 (par sa ligne).
      final Finder table = find.byType(Scrollable).last;
      await tester.drag(table, const Offset(0, -240));
      await laisser(tester);
      final double decalage = tester
          .state<ScrollableState>(
            find
                .descendant(
                  of: find.byType(DataCollection<LigneCandidature>),
                  matching: find.byType(Scrollable),
                )
                .first,
          )
          .position
          .pixels;
      expect(decalage, greaterThan(0));
      final int lectures = port.appels.length;

      await tester.tap(find.byKey(cleCandidature('p60')).hitTestable().first);
      await laisser(tester, fois: 12);
      expect(find.byType(CandidatureDirectionPage), findsOneWidget);

      await tester.tap(find.byType(DisqueRetour).first);
      await laisser(tester, fois: 12);
      expect(find.byType(CandidaturesPage), findsOneWidget);

      // Tout est la : le champ, le filtre en cours, le tri, la page, la position.
      final TextField champ = tester.widget<TextField>(
        find.byKey(const ValueKey<String>('candidatures-recherche')),
      );
      expect(champ.controller!.text, 'Personne');
      // Le filtre d'etat se lit sur son bouton (plus de puce qui le redise).
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('candidatures-filtre-etat')),
          matching: find.text(t.admin.candidatures.etats.enExamen),
        ),
        findsOneWidget,
      );
      expect(
        find.text(t.commun.listes.tranche(debut: 51, fin: 100, total: 120)),
        findsOneWidget,
      );
      final double decalageApres = tester
          .state<ScrollableState>(
            find
                .descendant(
                  of: find.byType(DataCollection<LigneCandidature>),
                  matching: find.byType(Scrollable),
                )
                .first,
          )
          .position
          .pixels;
      expect(decalageApres, decalage);
      // Aucune relecture inutile : la liste n'a pas ete relue au retour (chaque
      // lecture est journalisee au serveur).
      expect(port.appels.length, lectures);
    });
  });
}
