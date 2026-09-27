// EN-7b : le cahier de seance (ENS-04) depuis la vraie coquille de
// demonstration : devoir precedent prerempli, suite par eleve (doc 04 §20.4),
// emplacements d'evaluation vides tant que l'echelle n'est pas fournie,
// actions de l'ecran enregistre, et un seul ton pour l'absence.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/enseignant/depot_cahiers.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';
import 'package:rewayah_academy/features/cahier/cahier_page.dart';
import 'package:rewayah_academy/features/demo/demo_enseignant_page.dart';
import 'package:rewayah_academy/features/demo/enseignant_demo.dart';

import '../../capture/outil_capture.dart';
import '../../support/harnais.dart';

Future<void> _monter(WidgetTester tester, Size taille) async {
  fixerVueCapture(tester, taille, 1);
  await tester.pumpWidget(
    hoteCapture(
      const CoquilleEnseignantDemo(
        ecran: EcranDemoEnseignant.cahier,
        etat: EtatDemoEnseignant.nominal,
      ),
      // Sans ce faux, le cahier ouvre une vraie base drift, qui appelle
      // path_provider (absent en test) : meme fable que captures_en_test.
      surcharges: <Override>[
        depotRapportsProvider.overrideWithValue(FauxDepotRapports()),
      ],
    ),
  );
  await stabiliser(tester);
}

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await stabiliser(tester);
  await tester.tap(cible);
  await stabiliser(tester);
  // La soumission de demonstration repond apres 600 ms.
  await tester.pump(const Duration(milliseconds: 700));
  await stabiliser(tester);
}

Finder _cle(String cle) => find.byKey(ValueKey<String>(cle));

void main() {
  testWidgets('la feuille d un eleve : devoir precedent prerempli, suite '
      'Renforcer tapee, puis relue sur la ligne', (WidgetTester tester) async {
    await _monter(tester, const Size(390, 1900));

    await _toucher(tester, find.text('Nour'));

    // Le devoir de la seance precedente est la, sans ressaisie.
    expect(_cle('cahier-devoir-precedent'), findsOneWidget);
    expect(
      find.text(
        t.enseignant.cahier.devoirPrecedent(
          devoir: t.enseignant.cahier.devoirPlage(
            sourate: '78',
            debut: '1',
            fin: '11',
          ),
        ),
      ),
      findsOneWidget,
    );

    // Les trois actions du doc 04 §20.4, mot pour mot.
    expect(find.text('Continuer'), findsOneWidget);
    expect(find.text('Renforcer'), findsOneWidget);
    expect(find.text('Suspendre le nouveau'), findsOneWidget);

    // Performance et faiblesses : emplacements prets, rien d'affiche.
    expect(_cle('cahier-emplacement-performance'), findsOneWidget);
    expect(_cle('cahier-emplacement-faiblesses'), findsOneWidget);
    expect(find.text(t.enseignant.cahier.performance), findsNothing);
    expect(find.text(t.enseignant.cahier.faiblesses), findsNothing);

    await _toucher(tester, _cle('cahier-suite-renforcer'));
    await _toucher(tester, find.text(t.enseignant.cahier.ajusterValider));

    // Ce qui est consigne se relit avant de valider.
    expect(find.text(t.enseignant.cahier.suiteRenforcer), findsOneWidget);
    expect(find.text(t.enseignant.cahier.ajusterValider), findsNothing);

    await _toucher(tester, _cle('cahier-valider'));
    expect(find.text(t.enseignant.cahier.depose), findsOneWidget);
  });

  testWidgets('Absents et Absence : un seul ton, jamais l alerte', (
    WidgetTester tester,
  ) async {
    await _monter(tester, const Size(390, 1900));

    final Iterable<StatusPill> pastilles = tester.widgetList<StatusPill>(
      find.byType(StatusPill),
    );
    final StatusPill absents = pastilles.firstWhere(
      (StatusPill p) =>
          p.libelle == t.enseignant.cahier.statutAbsents(nombre: '1'),
    );
    final StatusPill absence = pastilles.firstWhere(
      (StatusPill p) => p.libelle == t.presence.absente,
    );
    expect(absents.ton, absence.ton);
    expect(absents.ton, isNot(TonEtat.alerte));
    expect(tonCahier(TonEtat.alerte), TonEtat.avertissement);
  });

  testWidgets('cahier enregistre sur telephone : boutons pleine largeur', (
    WidgetTester tester,
  ) async {
    await _monter(tester, const Size(390, 1900));
    await _toucher(tester, _cle('cahier-valider'));

    final Rect corriger = tester.getRect(_cle('cahier-corriger'));
    final Rect retour = tester.getRect(_cle('cahier-retour-journee'));
    expect(corriger.width, retour.width);
    expect(retour.width, greaterThan(300));
    // Le dominant sous le tertiaire, au plus pres du pouce.
    expect(retour.top, greaterThan(corriger.bottom));
  });

  testWidgets('cahier enregistre sur bureau : le dominant au bord de fin', (
    WidgetTester tester,
  ) async {
    await _monter(tester, const Size(1440, 1000));
    await _toucher(tester, _cle('cahier-valider'));

    final Rect corriger = tester.getRect(_cle('cahier-corriger'));
    final Rect retour = tester.getRect(_cle('cahier-retour-journee'));
    expect(retour.width, lessThan(400));
    expect(retour.left, greaterThan(corriger.right));
  });
}
