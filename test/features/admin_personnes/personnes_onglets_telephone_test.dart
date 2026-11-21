// PERSONNES-UNE-PAGE (pilote, 21/11/2026) : au telephone, chaque onglet de la
// page « Personnes » montre son icone ET un mot court, avec les VRAIES polices
// (la police de test dessine des carres plus larges que les lettres) ; le nom
// de l'onglet ouvert est ecrit en toutes lettres sous les onglets. Le
// directeur (20/11/2026) craignait qu'on agisse sur la mauvaise liste.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/enseignants/modeles_enseignants.dart';
import 'package:rewayah_academy/core/enseignants/port_enseignants.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/admin_personnes/personnes_page.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/harnais.dart';

class _Comptes implements ServiceComptes {
  const _Comptes();

  @override
  Future<List<CompteAdmin>> comptes() async => const <CompteAdmin>[];
}

class _Enseignants implements PortEnseignants {
  const _Enseignants();

  @override
  Future<PageEnseignants> lister({
    required FiltreEnseignants filtre,
    required TriEnseignants tri,
    required int page,
  }) async => const PageEnseignants(
    lignes: <LigneEnseignant>[],
    total: 0,
    page: 1,
    taillePage: 50,
  );
}

void main() {
  setUpAll(() async {
    await chargerPolicesDuDepot();
    await LocaleSettings.setLocale(AppLocale.ar);
    await LocaleSettings.setLocale(AppLocale.en);
    await LocaleSettings.setLocale(AppLocale.fr);
  });
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  const Map<AppLocale, List<String>> mots = <AppLocale, List<String>>{
    AppLocale.fr: <String>['Élèves', 'Familles', 'Enseignants', 'Équipe'],
    AppLocale.en: <String>['Students', 'Families', 'Teachers', 'Team'],
    AppLocale.ar: <String>['الطلاب', 'العائلات', 'المعلمون', 'الفريق'],
  };

  for (final MapEntry<AppLocale, List<String>> cas in mots.entries) {
    for (final double largeur in <double>[390, 360]) {
      testWidgets('${cas.key.languageCode}, $largeur points : quatre icones '
          'differentes, un mot court entier sous chacune, le nom de l\'onglet '
          'en toutes lettres', (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(cas.key));
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(largeur, 844);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          hoteRoutant(
            depart: '/admin/personnes?onglet=familles',
            routes: <RouteBase>[
              GoRoute(
                path: Routes.adminPersonnes,
                builder: (BuildContext _, GoRouterState e) =>
                    PersonnesPage(requete: e.uri.queryParameters),
              ),
            ],
            surcharges: <Override>[
              serviceComptesProvider.overrideWithValue(const _Comptes()),
              serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
              portEnseignantsProvider.overrideWithValue(const _Enseignants()),
            ],
          ),
        );
        await tester.pumpAndSettle();

        final Finder onglets = find.byKey(PersonnesPage.cleOnglets);
        final List<Icon> icones = tester
            .widgetList<Icon>(
              find.descendant(of: onglets, matching: find.byType(Icon)),
            )
            .toList();
        expect(icones, hasLength(4));
        expect(
          icones.map((Icon i) => i.icon!.codePoint).toSet(),
          hasLength(4),
          reason: 'quatre dessins differents',
        );
        for (final String mot in cas.value) {
          final Finder texte = find.descendant(
            of: onglets,
            matching: find.text(mot),
          );
          expect(texte, findsOneWidget, reason: mot);
          final RenderParagraph rendu = tester.renderObject(texte);
          // Une seule ligne, rien de coupe, a peine reduit au besoin.
          expect(
            rendu
                .getBoxesForSelection(
                  TextSelection(baseOffset: 0, extentOffset: mot.length),
                )
                .map((TextBox b) => b.top.round())
                .toSet(),
            hasLength(1),
            reason: '$mot sur une ligne',
          );
          expect(rendu.didExceedMaxLines, isFalse, reason: mot);
          // Reduit d'un dixieme au plus : il reste lisible.
          expect(
            tester.getSize(texte).width,
            greaterThanOrEqualTo(rendu.size.width * 0.9 - 0.5),
            reason: '$mot reste lisible',
          );
        }
        expect(find.byKey(PersonnesPage.cleNomOnglet), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
