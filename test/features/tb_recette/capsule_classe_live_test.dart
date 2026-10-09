// TB-3 dans la vraie Classe Live (`ClasseLivePage`, faux moteur) : la
// capsule pendant le partage, le contexte enseignant qu'ouvre son avatar,
// et le detail du reseau (feuille `_voirReseau`, sortie de la barre a TB-2)
// atteignable depuis ce contexte (plan V2 §19.6). Aucun branchement serveur :
// le support presente arrive par le port neutre `supportPresente` du
// contexte, `null` en production tant que TB-BR ne le remplit pas.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_classe/session_live_vm.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/capsule_seance.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart';
import 'package:rewayah_academy/features/tc_classe_live/classe_live_page.dart';

import '../../teaching_core/e/faux/faux_classe.dart';
import '../../teaching_core/e/support/hote_classe.dart';

ContexteClasseLive _contexte({required bool partage}) => ContexteClasseLive(
  sessionId: 's1',
  groupeId: 'g1',
  libelleGroupe: 'Classe An-Nour',
  enseignant: const EnseignantDeClasse(nomAffichage: 'Amina'),
  descriptionSupport: DonneesSeanceDemo.support,
  supportPresente: partage ? DonneesSeanceDemo.supportPageFixe : null,
);

Future<void> _monter(
  WidgetTester tester, {
  required String role,
  required bool partage,
}) async {
  await monterClasse(
    tester,
    contexte: _contexte(partage: partage),
    surcharges: surchargesClasse(
      moteur: FauxMoteurClasse(),
      video: FauxServiceVideoClasse(acces0: accesDe(role)),
      preVol: FauxPreVolClasse(),
    ),
    ecran: LargeurEcran.mobile,
    mouvementReduit: true,
  );
  expect(find.byType(SalleSeance), findsOneWidget);
}

const Key _detailReseau = ValueKey<String>('contexte-detail-reseau');

void main() {
  testWidgets('enseignant : avatar de la capsule, contexte, detail du reseau', (
    WidgetTester tester,
  ) async {
    await _monter(tester, role: 'teacher', partage: true);
    final Finder avatar = find.byKey(CapsuleSeance.cleAvatar);
    expect(find.byKey(CapsuleSeance.cle), findsOneWidget);
    // L'avatar est tapable : onContexte est raccorde par la Classe Live.
    expect(
      find.descendant(of: avatar, matching: find.byType(GestureDetector)),
      findsWidgets,
    );
    await tester.tap(avatar);
    await tester.pumpAndSettle();
    expect(find.byKey(SectionContexte.cle), findsOneWidget);
    final Finder detail = find.byKey(_detailReseau);
    await tester.ensureVisible(detail);
    await tester.pumpAndSettle();
    await tester.tap(detail);
    await tester.pumpAndSettle();
    // La feuille du reseau de la Classe Live s'ouvre, titre « Reseau ».
    expect(find.text(t.salle.seance.reseau), findsWidgets);
    expect(tester.takeException(), isNull);

    // Fermee, « Reduire » revient a la capsule.
    Navigator.of(tester.element(find.text(t.salle.seance.reseau).last)).pop();
    await tester.pumpAndSettle();
    final Finder reduire = find.byKey(SectionContexte.cleReduire);
    await tester.ensureVisible(reduire);
    await tester.pumpAndSettle();
    await tester.tap(reduire);
    await tester.pumpAndSettle();
    expect(find.byKey(SectionContexte.cle), findsNothing);
    expect(find.byKey(CapsuleSeance.cle), findsOneWidget);
  });

  testWidgets('eleve : le contexte s\'ouvre, sans detail du reseau', (
    WidgetTester tester,
  ) async {
    await _monter(tester, role: 'student', partage: true);
    await tester.tap(find.byKey(CapsuleSeance.cleAvatar));
    await tester.pumpAndSettle();
    expect(find.byKey(SectionContexte.cle), findsOneWidget);
    expect(find.byKey(_detailReseau), findsNothing);
  });

  testWidgets('sans support presente (production avant TB-BR) : la vignette '
      'reste, aucune capsule', (WidgetTester tester) async {
    await _monter(tester, role: 'teacher', partage: false);
    expect(find.byKey(CapsuleSeance.cle), findsNothing);
  });
}
