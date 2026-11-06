// CAHIER-C2 (06/11/2026) : le contenu d'une etape du programme (objectifs,
// livre et pages, duree par tranche d'age, date limite deduite).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_programme.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/choix_nombre.dart';
import 'package:rewayah_academy/features/admin_pedagogie_programmes/feuille_contenu_niveau.dart';

import '../../support/harnais.dart';

const NiveauProgramme _etape = NiveauProgramme(
  id: 'n2',
  codeTechnique: 'BASES-2',
  nomHumain: 'Lire avec les voyelles',
  cycle: 'Les bases',
  ordre: 2,
  description: null,
  objectifs: <String>['Lit le tanwin', 'Lit la chadda'],
  plage: PlageSupport(support: SupportEtape.livreRewayah, ligneDebut: 3),
  durees: <String, DureeEtape>{
    'enfant_6_9': DureeEtape(prevue: 14, limite: 18),
  },
  complet: false,
);

class _Envoi {
  List<String>? objectifs;
  PlageSupport? plage;
  Map<String, DureeEtape>? durees;
  int nombre = 0;
}

Future<_Envoi> _ouvrir(
  WidgetTester tester, {
  bool modifiable = true,
  Size cadre = const Size(390, 844),
}) async {
  tester.view.physicalSize = cadre;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final _Envoi envoi = _Envoi();
  await tester.pumpWidget(
    hote(
      Scaffold(
        body: SingleChildScrollView(
          child: FeuilleContenuNiveau(
            niveau: _etape,
            modifiable: modifiable,
            onEnvoyer:
                ({
                  required List<String> objectifs,
                  required PlageSupport? plage,
                  required Map<String, DureeEtape> durees,
                }) async {
                  envoi
                    ..objectifs = objectifs
                    ..plage = plage
                    ..durees = durees
                    ..nombre += 1;
                },
            onSucces: () {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return envoi;
}

Future<void> _enregistrer(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  final Finder bouton = find.text(t.admin.programmes.contenu.enregistrer);
  await tester.ensureVisible(bouton);
  await tester.pumpAndSettle();
  await tester.tap(bouton);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  test('lecture du serveur : objectifs, plage, durees, etat', () {
    final NiveauProgramme n = NiveauProgramme.depuisJson(
      const <String, dynamic>{
        'niveau_id': 'n1',
        'code_technique': 'BASES-1',
        'nom_humain': 'Les lettres',
        'cycle': 'Les bases',
        'ordre': 1,
        'objectifs': <Object?>[' Reconnait chaque lettre ', null],
        'plage_support': <String, Object?>{
          'support': 'mushaf',
          'page_fin': 603,
        },
        'durees': <String, Object?>{
          'enfant_6_9': <String, Object?>{'prevue': 8, 'limite': 10},
          'ado_14_17': <String, Object?>{'prevue': 5},
        },
        'complet': true,
      },
    );
    expect(n.objectifs, <String>['Reconnait chaque lettre']);
    expect(n.plage!.support, SupportEtape.mushaf);
    expect(n.plage!.pageFin, 603);
    expect(n.durees.keys, <String>['enfant_6_9']);
    expect(n.complet, isTrue);
    // Lecture d'avant C2 : aucun contenu, etat inconnu.
    final NiveauProgramme ancien = NiveauProgramme.depuisJson(const <String, dynamic>{
      'niveau_id': 'x',
      'nom_humain': 'X',
    });
    expect(ancien.objectifs, isEmpty);
    expect(ancien.complet, isNull);
  });

  test('date limite deduite : x 1,3 arrondie (regle du 14/10)', () {
    expect(dateLimiteDeduite(37), 48);
    expect(dateLimiteDeduite(28), 36);
    expect(dateLimiteDeduite(24), 31);
    expect(dateLimiteDeduite(15), 20);
  });

  for (final Size cadre in <Size>[
    const Size(390, 844),
    const Size(1440, 900),
  ]) {
    testWidgets('enregistrer : objectifs nettoyes, durees de chaque tranche '
        'avec leur date limite, lignes gardees (${cadre.width.toInt()})', (
      WidgetTester tester,
    ) async {
      final _Envoi envoi = await _ouvrir(tester, cadre: cadre);
      expect(find.byType(ChoixNombre), findsNWidgets(4));
      expect(
        find.text(
          LibellesGroupe.insecable(
            t.admin.programmes.contenu.dateLimite(semaines: '18'),
          ),
        ),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('contenu-objectif-2')),
        '  Lit un mot sans epeler  ',
      );
      await _enregistrer(tester);
      expect(envoi.nombre, 1);
      expect(envoi.objectifs, <String>[
        'Lit le tanwin',
        'Lit la chadda',
        'Lit un mot sans epeler',
      ]);
      expect(envoi.plage!.support, SupportEtape.livreRewayah);
      expect(envoi.plage!.ligneDebut, 3);
      expect(envoi.durees!.keys, tranchesProgramme);
      expect(envoi.durees!['enfant_6_9']!.limite, 18);
      expect(envoi.durees!['adulte_18_plus']!.prevue, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('pages illisibles : rien n est envoye, la raison est dite', (
    WidgetTester tester,
  ) async {
    final _Envoi envoi = await _ouvrir(tester);
    await tester.enterText(
      find.byKey(const ValueKey<String>('contenu-page-debut')),
      '20',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('contenu-page-fin')),
      '10',
    );
    await _enregistrer(tester);
    expect(envoi.nombre, 0);
    expect(find.text(t.admin.programmes.contenu.manquePages), findsOneWidget);
  });

  testWidgets('version publiee : tout se lit, aucun bouton', (
    WidgetTester tester,
  ) async {
    await _ouvrir(tester, modifiable: false);
    expect(find.text(t.admin.programmes.contenu.lectureSeule), findsOneWidget);
    expect(find.text('Lit le tanwin'), findsOneWidget);
    expect(find.byType(ActionPrincipale), findsNothing);
    expect(find.byType(ChoixNombre), findsNothing);
    expect(
      find.text(
        LibellesGroupe.insecable(
          t.admin.programmes.contenu.dureeLecture(
            tranche: t.admin.programmes.contenu.tranche69,
            prevue: '14',
          ),
        ),
      ),
      findsOneWidget,
    );
  });
}
