import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_revue_dossiers.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/features/admin_dossiers/dossiers_page.dart';
import 'package:rewayah_academy/features/demo/dossiers_demo.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';

import '../support/dossiers_production.dart';
import '../support/harnais.dart';

/// Fait defiler jusqu'a un libelle puis tape dessus, comme l'administrateur.
Future<void> _taper(WidgetTester tester, String libelle) async {
  final Finder cible = find.text(libelle);
  await tester.scrollUntilVisible(
    cible,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

/// Rend visible puis tape (la revue ouverte directement n'a pas de liste).
Future<void> _toucher(WidgetTester tester, String libelle) async {
  await tester.ensureVisible(find.text(libelle).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text(libelle).first);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('ADM-02 sous la demonstration admin, sans serveur', (
    WidgetTester tester,
  ) async {
    final EtatRevueDemo etat = EtatRevueDemo.initial();
    await tester.pumpWidget(
      hote(
        const DossiersPage(),
        surcharges: surchargesDemoAdmin(environnement: 'staging', etat: etat),
      ),
    );
    await tester.pumpAndSettle();
    // AD-5 : la page montre la file ; taper la premiere ligne ouvre la revue.
    await ouvrirPremierDossier(tester);

    // Le plus ancien dossier synthetique d'abord, piece jamais montree.
    // AD-6 : titre de la revue, piece jamais montree, raison dite.
    expect(find.text("Dossier d'Omar Haddad"), findsOneWidget);
    // AD-7 : la piece s'ouvre par « Voir la piece », jamais en ligne.
    expect(find.text(t.dossiers.revue.pieceIndisponible), findsNothing);
    expect(find.text(t.dossiers.revue.voirPiece), findsOneWidget);
    expect(find.byType(Image), findsNothing);

    for (final String point in <String>[
      t.dossiers.pointLisible,
      t.dossiers.pointNom,
      t.dossiers.pointValidite,
    ]) {
      await _taper(tester, point);
    }
    await _taper(tester, t.dossiers.approuver);
    // AD-8 : 02E s'ouvre ; rien n'est decide avant la confirmation.
    expect(find.text(t.dossiers.validation.titre), findsOneWidget);
    expect(etat.nombreDecisions, 0);
    await tester.tap(find.text(t.dossiers.approuver).last);
    await tester.pumpAndSettle();
    expect(find.text(t.dossiers.validation.succes), findsOneWidget);
    expect(etat.nombreDecisions, 1);

    expect(
      etat.dossiers[DonneesDossiersDemo.enseignantNominal]!.statut,
      StatutRevue.valide,
    );
    expect(find.text('Omar Haddad'), findsNothing);
    expect(find.text('Amina Benali'), findsOneWidget);
  });

  testWidgets('AD-8 : refus a reponse perdue (07), une seule decision', (
    WidgetTester tester,
  ) async {
    final EtatRevueDemo etat = EtatRevueDemo.initial();
    await tester.pumpWidget(
      hote(
        const DossiersPage(),
        surcharges: surchargesDemoAdmin(environnement: 'staging', etat: etat),
      ),
    );
    await tester.pumpAndSettle();
    final Finder ligne = find.bySemanticsLabel(
      RegExp('Ouvrir le dossier d.In'),
    );
    await tester.ensureVisible(ligne.first);
    await tester.pumpAndSettle();
    await tester.tap(ligne.first);
    await tester.pumpAndSettle();

    await _toucher(tester, t.dossiers.refuser);
    await tester.enterText(find.byType(TextField), 'Motif fictif.');
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.dossiers.refuser).last);
    await tester.pumpAndSettle();

    // Reponse perdue : jamais un echec certain, aucune relance seule.
    expect(find.text(t.dossiers.refus.inconnu), findsOneWidget);
    expect(etat.nombreDecisions, 1);
    await tester.pump(const Duration(seconds: 30));
    expect(etat.nombreDecisions, 1);

    // Surface fermee : le statut reste sous les actions, les deux
    // decisions fermees (P-ADM-10.6).
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text(t.dossiers.refus.corps), findsNothing);
    expect(find.text(t.dossiers.refus.inconnu), findsOneWidget);
    for (final String l in <String>[t.dossiers.refuser, t.dossiers.approuver]) {
      final ActionPrincipale a = tester.widget<ActionPrincipale>(
        find
            .ancestor(of: find.text(l), matching: find.byType(ActionPrincipale))
            .first,
      );
      expect(a.onPress, isNull, reason: l);
    }

    // Premiere relecture : encore en attente ; seconde : reussie, une fois.
    await _toucher(tester, t.dossiers.decision.verifierResultat);
    expect(find.text(t.dossiers.refus.inconnu), findsOneWidget);
    await _toucher(tester, t.dossiers.decision.verifierResultat);
    expect(find.text(t.dossiers.refus.succes), findsOneWidget);
    expect(etat.nombreDecisions, 1);
  });
}
