import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/features/classes/domaine/conformite.dart';
import 'package:rewayah_academy/features/classes/porte_salle.dart';

import '../../support/harnais.dart';

Future<void> _poser(
  WidgetTester tester,
  PreconditionSalle? precondition, {
  VoidCallback? onAjouterPhoto,
  VoidCallback? onRejoindre,
}) async {
  await tester.pumpWidget(
    hote(
      Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: PorteSalle(
            precondition: precondition,
            onRejoindre: onRejoindre ?? () {},
            onAjouterPhoto: onAjouterPhoto,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('photo requise et absente : la condition, pas le bouton', (
    WidgetTester tester,
  ) async {
    bool ajout = false;
    await _poser(
      tester,
      const PreconditionSalle(
        prenom: 'Amina',
        photoRequise: true,
        photoPresente: false,
      ),
      onAjouterPhoto: () => ajout = true,
    );

    // Le rappel, calme : pourquoi, ce que cela permet, et l'action.
    expect(find.byKey(PorteSalle.cleRappelPhoto), findsOneWidget);
    expect(
      find.text(t.classes.porte.photoTitre(prenom: 'Amina')),
      findsOneWidget,
    );
    expect(find.text(t.classes.porte.photoRaison), findsOneWidget);
    // Le bouton d'entree n'est pas rendu : il n'aboutirait pas.
    expect(
      find.widgetWithText(ActionPrincipale, t.classes.porte.rejoindre),
      findsNothing,
    );
    // Aucun vocabulaire menacant.
    for (final String interdit in <String>['interdit', 'refus', 'bloqu']) {
      expect(find.textContaining(interdit), findsNothing, reason: interdit);
    }

    await tester.tap(find.text(t.classes.porte.ajouterPhoto));
    await tester.pumpAndSettle();
    expect(ajout, isTrue);
  });

  testWidgets('quand cet ecran ne peut pas ajouter la photo, il dit ou', (
    WidgetTester tester,
  ) async {
    await _poser(
      tester,
      const PreconditionSalle(
        prenom: 'Amina',
        photoRequise: true,
        photoPresente: false,
      ),
    );

    expect(find.text(t.classes.porte.ajouterPhoto), findsNothing);
    expect(find.text(t.classes.porte.photoParTuteur), findsOneWidget);
  });

  testWidgets('photo presente : le bouton, et rien d autre', (
    WidgetTester tester,
  ) async {
    bool rejoint = false;
    await _poser(
      tester,
      const PreconditionSalle(
        prenom: 'Amina',
        photoRequise: true,
        photoPresente: true,
      ),
      onRejoindre: () => rejoint = true,
    );

    expect(find.byKey(PorteSalle.cleRappelPhoto), findsNothing);
    await tester.tap(find.text(t.classes.porte.rejoindre));
    await tester.pumpAndSettle();
    expect(rejoint, isTrue);
  });

  testWidgets('precondition inconnue : le bouton reste, le serveur tranche', (
    WidgetTester tester,
  ) async {
    // Bloquer sur un doute inventerait une regle pour un eleve adulte.
    await _poser(tester, null);
    expect(
      find.widgetWithText(ActionPrincipale, t.classes.porte.rejoindre),
      findsOneWidget,
    );

    await _poser(tester, const PreconditionSalle.inconnue());
    expect(
      find.widgetWithText(ActionPrincipale, t.classes.porte.rejoindre),
      findsOneWidget,
    );
  });

  testWidgets('photo non requise : rien ne se lit, meme sans photo', (
    WidgetTester tester,
  ) async {
    await _poser(
      tester,
      const PreconditionSalle(
        prenom: 'Karim',
        photoRequise: false,
        photoPresente: false,
      ),
    );
    expect(find.byKey(PorteSalle.cleRappelPhoto), findsNothing);
    expect(
      find.widgetWithText(ActionPrincipale, t.classes.porte.rejoindre),
      findsOneWidget,
    );
  });

  test('bloqueParPhoto ne s allume que sur une exigence positive', () {
    expect(
      const PreconditionSalle(
        prenom: 'a',
        photoRequise: true,
        photoPresente: false,
      ).bloqueParPhoto,
      isTrue,
    );
    expect(
      const PreconditionSalle(prenom: 'a', photoRequise: true).bloqueParPhoto,
      isTrue,
    );
    expect(const PreconditionSalle.inconnue().bloqueParPhoto, isFalse);
    expect(
      const PreconditionSalle(prenom: 'a', photoRequise: false).bloqueParPhoto,
      isFalse,
    );
  });
}
