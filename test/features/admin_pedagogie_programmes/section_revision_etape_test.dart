// MA-PROGRESSION-ECRAN (12/11/2026) : la direction regle les heures de revision
// par semaine et les repetitions estimees d'une etape, au pas a pas ; « Non
// regle » vide la valeur ; l'echec du serveur est dit.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_programme.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart'
    show LibellesGroupe;
import 'package:rewayah_academy/features/admin_pedagogie_programmes/feuille_contenu_niveau.dart';
import 'package:rewayah_academy/features/admin_pedagogie_programmes/section_revision_etape.dart';

import '../../support/harnais.dart';

class _Appels {
  final List<({double? heures, int? repetitions})> faits =
      <({double? heures, int? repetitions})>[];
  Exception? echec;
}

Future<_Appels> _monter(
  WidgetTester tester, {
  double? heures,
  int? repetitions,
}) async {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final _Appels appels = _Appels();
  await tester.pumpWidget(
    hote(
      Scaffold(
        body: SingleChildScrollView(
          child: SectionRevisionEtape(
            heuresInitiales: heures,
            repetitionsInitiales: repetitions,
            onRegler: ({double? heures, int? repetitions}) async {
              if (appels.echec case final Exception e) throw e;
              appels.faits.add((heures: heures, repetitions: repetitions));
            },
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return appels;
}

Future<void> _plus(WidgetTester tester, String libelle, int fois) async {
  for (int i = 0; i < fois; i++) {
    await tester.tap(find.bySemanticsLabel(libelle));
    await tester.pump();
  }
}

Future<void> _enregistrer(WidgetTester tester) async {
  final Finder bouton = find.byKey(SectionRevisionEtape.enregistrerKey);
  await tester.ensureVisible(bouton);
  await tester.pumpAndSettle();
  await tester.tap(bouton);
  await tester.pumpAndSettle();
}

void main() {
  final c = t.admin.programmes.contenu;

  testWidgets('vide par defaut : « Non regle » aux deux, rien d inventé', (
    WidgetTester tester,
  ) async {
    final _Appels appels = await _monter(tester);
    expect(find.text(c.revisionNonRegle), findsNWidgets(2));
    await _enregistrer(tester);
    expect(appels.faits.single, (heures: null, repetitions: null));
  });

  testWidgets('les valeurs deja reglees sont reprises', (
    WidgetTester tester,
  ) async {
    await _monter(tester, heures: 2.5, repetitions: 40);
    expect(
      find.text(
        LibellesGroupe.insecable(c.revisionHeuresValeur(heures: '2,5')),
      ),
      findsOneWidget,
    );
    expect(find.text('40'), findsOneWidget);
  });

  testWidgets('au pas a pas : 5 demi-heures et 3 repetitions', (
    WidgetTester tester,
  ) async {
    final _Appels appels = await _monter(tester);
    await _plus(tester, c.revisionHeuresPlus, 5);
    await _plus(tester, c.revisionRepetitionsPlus, 3);
    expect(
      find.text(
        LibellesGroupe.insecable(c.revisionHeuresValeur(heures: '2,5')),
      ),
      findsOneWidget,
    );
    await _enregistrer(tester);
    expect(appels.faits.single, (heures: 2.5, repetitions: 3));
    expect(find.text(c.revisionEnregistree), findsOneWidget);
  });

  testWidgets('revenir a « Non regle » vide la valeur', (
    WidgetTester tester,
  ) async {
    final _Appels appels = await _monter(tester, heures: 1, repetitions: 2);
    await _plus(tester, c.revisionHeuresMoins, 2);
    await _plus(tester, c.revisionRepetitionsMoins, 2);
    await _enregistrer(tester);
    expect(appels.faits.single, (heures: null, repetitions: null));
  });

  testWidgets('un echec du serveur est dit, rien n est pretendu', (
    WidgetTester tester,
  ) async {
    final _Appels appels = await _monter(tester)
      ..echec = Exception('reglage reserve a l administration');
    await _enregistrer(tester);
    expect(appels.faits, isEmpty);
    expect(find.textContaining(c.revisionEnregistree), findsNothing);
    expect(find.textContaining('reserve a l administration'), findsOneWidget);
  });

  testWidgets('dans la feuille du contenu : posee a la fin, absente sans '
      'elle', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Future<void> monter({Widget? section}) async {
      await tester.pumpWidget(
        hote(
          Scaffold(
            body: SingleChildScrollView(
              child: FeuilleContenuNiveau(
                niveau: const NiveauProgramme(
                  id: 'n2',
                  codeTechnique: 'BASES-2',
                  nomHumain: 'Lire avec les voyelles',
                  cycle: 'Les bases',
                  ordre: 2,
                  description: null,
                  objectifs: <String>[],
                  plage: null,
                  durees: <String, DureeEtape>{},
                  complet: false,
                ),
                modifiable: true,
                onEnvoyer: ({
                  required List<String> objectifs,
                  required PlageSupport? plage,
                  required Map<String, DureeEtape> durees,
                }) async {},
                onSucces: () {},
                sectionRevision: section,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await monter();
    expect(find.text(c.revisionTitre), findsNothing);
    await monter(
      section: SectionRevisionEtape(
        heuresInitiales: null,
        repetitionsInitiales: null,
        onRegler: ({double? heures, int? repetitions}) async {},
      ),
    );
    expect(find.text(c.revisionTitre), findsOneWidget);
    expect(
      tester.getTopLeft(find.text(c.revisionTitre)).dy,
      greaterThan(
        tester.getTopLeft(find.byKey(FeuilleContenuNiveau.enregistrerKey)).dy,
      ),
    );
  });
}
