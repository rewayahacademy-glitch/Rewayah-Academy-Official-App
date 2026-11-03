// N1 (02/11/2026, extension de zone du pilote) : la confirmation de
// « Signaler un besoin » dit ce qui est vrai.
//   * envoi reel accepte : « Signalement transmis à l'administration. »,
//     jamais « Démonstration : ... rien n'a été envoyé » ;
//   * envoi reel refuse : l'erreur et « Réessayer », aucune confirmation ;
//   * demonstration (aucun envoi) : le texte de demonstration, seul cas ou il
//     s'affiche.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/fiche_groupe/fiche_eleve_enseignant.dart';

import '../../support/harnais.dart';

const EleveFiche _eleve = EleveFiche(
  membre: MembreSeance(
    studentId: 'e1',
    identifiantImmuable: 'RA-26-4817',
    prenom: 'Yasmine',
  ),
  classe: 'An-Nour',
);

Future<void> _envoyer(
  WidgetTester tester,
  Future<void> Function(SignalementBesoin)? envoi,
) async {
  await tester.pumpWidget(
    hote(
      Scaffold(
        body: SingleChildScrollView(
          child: SignalerBesoin(eleve: _eleve, envoi: envoi),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(CategorieBesoin.securiteEnfant.libelle));
  await tester.enterText(
    find.byKey(SignalerBesoin.detailsKey),
    'Une inquietude pour Yasmine',
  );
  await tester.pumpAndSettle();
  final Finder envoyer = find.byKey(SignalerBesoin.envoyerKey);
  await tester.ensureVisible(envoyer);
  await tester.tap(envoyer);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('envoi reel accepte : transmis, jamais « Démonstration »', (
    WidgetTester tester,
  ) async {
    final List<SignalementBesoin> envoyes = <SignalementBesoin>[];
    await _envoyer(tester, (SignalementBesoin s) async => envoyes.add(s));

    expect(envoyes, hasLength(1));
    expect(envoyes.single.categorie, CategorieBesoin.securiteEnfant);
    expect(find.byKey(SignalerBesoin.confirmationKey), findsOneWidget);
    expect(find.text(t.tc.parcours.signalement.envoye), findsOneWidget);
    expect(find.text(t.enseignant.signalement.demoSucces), findsNothing);
    expect(find.text(t.enseignant.signalement.demoSuccesDetail), findsNothing);
  });

  testWidgets('envoi reel refuse : l erreur, aucune confirmation', (
    WidgetTester tester,
  ) async {
    await _envoyer(tester, (SignalementBesoin _) async {
      throw StateError('refus du serveur');
    });

    expect(find.byKey(SignalerBesoin.confirmationKey), findsNothing);
    expect(find.text(t.tc.parcours.signalement.echec), findsOneWidget);
    expect(find.text(t.tc.parcours.signalement.envoye), findsNothing);
    expect(find.text(t.enseignant.signalement.demoSucces), findsNothing);
  });

  testWidgets('demonstration, aucun envoi : le texte de demonstration', (
    WidgetTester tester,
  ) async {
    await _envoyer(tester, null);

    expect(find.byKey(SignalerBesoin.confirmationKey), findsOneWidget);
    expect(find.text(t.enseignant.signalement.demoSucces), findsOneWidget);
    expect(find.text(t.tc.parcours.signalement.envoye), findsNothing);
  });
}
