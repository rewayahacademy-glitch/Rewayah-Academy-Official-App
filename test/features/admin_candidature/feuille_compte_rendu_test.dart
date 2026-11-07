// SALLE-2-ENTRETIEN (07/11/2026) : « Ecrire mon compte rendu ». Texte et
// avis exiges, constat facultatif ; le serveur decide (trop tot, consigne).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/compte_rendu_entretien.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/admin_candidature/feuille_compte_rendu.dart';

import '../../support/hote_theme.dart';

class _FauxPort implements PortCompteRenduEntretien {
  RefusCompteRendu? refus;
  final List<(String, CompteRenduAEcrire)> ecrits =
      <(String, CompteRenduAEcrire)>[];

  @override
  Future<RefusCompteRendu?> ecrire(
    String sessionId,
    CompteRenduAEcrire cr,
  ) async {
    ecrits.add((sessionId, cr));
    return refus;
  }
}

Future<List<String>> _monter(WidgetTester tester, _FauxPort port) async {
  final List<String> finis = <String>[];
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hoteTheme(
      FeuilleCompteRendu(
        sessionId: 'seance-1',
        onFini: finis.add,
        onAnnuler: () {},
      ),
      surcharges: <Override>[
        portCompteRenduEntretienProvider.overrideWithValue(port),
      ],
    ),
  );
  await tester.pumpAndSettle();
  return finis;
}

Future<void> _enregistrer(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(FeuilleCompteRendu.enregistrerKey));
  await tester.tap(find.byKey(FeuilleCompteRendu.enregistrerKey));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));
  final c = t.admin.candidatures.entretien.compteRendu;

  testWidgets('texte et avis exiges : rien ne part sans eux', (
    WidgetTester tester,
  ) async {
    final _FauxPort port = _FauxPort();
    await _monter(tester, port);
    await _enregistrer(tester);
    expect(port.ecrits, isEmpty);
    expect(find.text(c.texteManquant), findsOneWidget);
    expect(find.text(c.avisManquant), findsOneWidget);
  });

  testWidgets('texte, avis et constat partent ; la feuille se ferme sur '
      '« enregistre »', (WidgetTester tester) async {
    final _FauxPort port = _FauxPort();
    final List<String> finis = await _monter(tester, port);
    await tester.enterText(
      find.byKey(FeuilleCompteRendu.texteKey),
      '  Lecture sure, tajwid applique.  ',
    );
    await tester.tap(find.byKey(const ValueKey<String>('avis-favorable')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(
        const ValueKey<String>('constat-niveauLectureTajwid-tajwid_applique'),
      ),
    );
    await tester.tap(
      find.byKey(
        const ValueKey<String>('constat-niveauLectureTajwid-tajwid_applique'),
      ),
    );
    await tester.pumpAndSettle();
    await _enregistrer(tester);
    final (String seance, CompteRenduAEcrire cr) = port.ecrits.single;
    expect(seance, 'seance-1');
    expect(cr.texte, 'Lecture sure, tajwid applique.');
    expect(cr.avis, AvisEntretien.favorable);
    expect(cr.tajwid, 'tajwid_applique');
    expect(cr.memorisation, isNull);
    expect(finis, <String>[c.enregistre]);
  });

  testWidgets('refus du serveur : trop tot, dit tel quel', (
    WidgetTester tester,
  ) async {
    final _FauxPort port = _FauxPort()..refus = RefusCompteRendu.pasCommence;
    final List<String> finis = await _monter(tester, port);
    await tester.enterText(find.byKey(FeuilleCompteRendu.texteKey), 'Texte');
    await tester.tap(find.byKey(const ValueKey<String>('avis-reserve')));
    await tester.pumpAndSettle();
    await _enregistrer(tester);
    expect(find.text(c.pasCommence), findsOneWidget);
    expect(finis, isEmpty);
  });

  testWidgets('constat complet (memorisation, riwayat, ijaza) : tout part, '
      'les riwayat dans l\'ordre du questionnaire', (
    WidgetTester tester,
  ) async {
    final _FauxPort port = _FauxPort();
    await _monter(tester, port);
    await tester.enterText(find.byKey(FeuilleCompteRendu.texteKey), 'Complet');
    await tester.tap(find.byKey(const ValueKey<String>('avis-favorable')));
    await tester.pumpAndSettle();
    for (final String cle in <String>[
      'constat-niveauMemorisationDeclare-coran_entier',
      'constat-riwayat-warsh',
      'constat-riwayat-hafs',
      'constat-ijazaPresentable-oui',
    ]) {
      await tester.ensureVisible(find.byKey(ValueKey<String>(cle)));
      await tester.tap(find.byKey(ValueKey<String>(cle)));
      await tester.pumpAndSettle();
    }
    await _enregistrer(tester);
    final CompteRenduAEcrire cr = port.ecrits.single.$2;
    expect(cr.memorisation, 'coran_entier');
    expect(cr.riwayat, <String>['hafs', 'warsh']);
    expect(cr.ijaza, 'oui');
  });
}
