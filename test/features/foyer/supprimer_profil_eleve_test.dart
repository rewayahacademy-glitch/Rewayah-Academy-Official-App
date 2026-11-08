// SUPPRIMER : la ligne « Supprimer le profil de … » de la fiche d'un enfant.
// Confirmation qui dit la consequence ; succes : le foyer est relu et la page
// y revient ; refus traduits ; hors ligne, rien ne part.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/permission_insuffisante.dart';
import 'package:rewayah_academy/core/capacites/port_retraits_comptes.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/foyer/selection_eleve.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/confirm_destructive.dart';
import 'package:rewayah_academy/features/foyer/supprimer_profil_eleve.dart';

import '../../support/harnais.dart';

class _Port implements PortRetraitsComptes {
  _Port(this.reponse);
  final Future<ResultatSuppressionEnfant> Function() reponse;
  final List<String> envois = <String>[];

  @override
  Future<ResultatSuppressionEnfant> supprimerProfilEnfant(String eleveId) {
    envois.add(eleveId);
    return reponse();
  }

  @override
  Future<PageRetraits> lister({
    EtatRetraits etat = EtatRetraits.enCours,
    CurseurRetraits? apres,
  }) => throw UnimplementedError();

  @override
  Future<List<ResultatRestauration>> restaurer(List<String> ids) =>
      throw UnimplementedError();

  @override
  Future<List<ResultatRetrait>> retirer(
    List<String> ids, {
    String? motif,
    bool anonymiserMaintenant = false,
  }) => throw UnimplementedError();
}

const ProfilEleveFoyer _yasmine = ProfilEleveFoyer(
  eleveId: 'e1',
  prenom: 'Yasmine',
  nature: NatureProfilEleve.membreDuFoyer,
  mode: InterfaceMode.standard,
  camera: CameraPolicy.allowed,
);

Future<(_Port, List<String>)> _monter(
  WidgetTester tester,
  Future<ResultatSuppressionEnfant> Function() reponse, {
  bool horsLigne = false,
}) async {
  final _Port port = _Port(reponse);
  final List<String> chemins = <String>[];
  await tester.pumpWidget(
    hote(
      Scaffold(
        body: SupprimerProfilEleve(profil: _yasmine, onAller: chemins.add),
      ),
      surcharges: <Override>[
        portRetraitsComptesProvider.overrideWithValue(port),
        serviceReseauProvider.overrideWithValue(
          FauxServiceReseau(horsLigneRendu: horsLigne),
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
  return (port, chemins);
}

Future<void> _confirmer(WidgetTester tester) async {
  await tester.tap(find.text('Supprimer le profil de Yasmine'));
  await tester.pumpAndSettle();
  expect(find.text('Supprimer le profil de Yasmine ?'), findsWidgets);
  expect(find.textContaining('quitte ses classes'), findsWidgets);
  await tester.enterText(
    find.byKey(ConfirmDestructive.champSaisieKey),
    'Yasmine',
  );
  await tester.pump();
  await tester.tap(find.text('Oui, supprimer Yasmine'));
  await tester.pumpAndSettle();
}

void main() {
  // SUPPRIMER-PRENOM (07/11/2026) : deux appuis rapides ne suppriment plus.
  testWidgets('prenom faux : rien ne part, le champ le dit et garde le focus', (
    tester,
  ) async {
    final (_Port port, List<String> chemins) = await _monter(
      tester,
      () async => ResultatSuppressionEnfant.retire,
    );
    await tester.tap(find.text('Supprimer le profil de Yasmine'));
    await tester.pumpAndSettle();
    // Le bouton de la feuille ne porte pas le libelle de la ligne.
    expect(find.text('Oui, supprimer Yasmine'), findsOneWidget);
    // « Supprimer le profil » ne reste que le titre du groupe, derriere.
    expect(find.text('Supprimer le profil'), findsOneWidget);

    // Deuxieme appui rapide, sans rien ecrire : refus.
    await tester.tap(find.text('Oui, supprimer Yasmine'));
    await tester.pumpAndSettle();
    expect(port.envois, isEmpty);
    expect(chemins, isEmpty);
    const String erreur =
        "Ce n'est pas le prénom Yasmine. Écrivez-le pour confirmer la suppression.";
    // Dette (b) : champ vide, la phrase dit quoi ecrire, avec le vrai prenom.
    const String vide = 'Écrivez le prénom Yasmine pour confirmer';
    expect(find.text(vide), findsOneWidget);
    expect(find.text(erreur), findsNothing);
    final EditableText champ = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(ConfirmDestructive.champSaisieKey),
        matching: find.byType(EditableText),
      ),
    );
    expect(champ.focusNode.hasFocus, isTrue);

    // Un autre prenom : toujours refuse.
    await tester.enterText(
      find.byKey(ConfirmDestructive.champSaisieKey),
      'Hakim',
    );
    await tester.pump();
    expect(find.text(vide), findsNothing, reason: 'la frappe efface l erreur');
    await tester.tap(find.text('Oui, supprimer Yasmine'));
    await tester.pumpAndSettle();
    expect(port.envois, isEmpty);
    expect(find.text(erreur), findsOneWidget);
  });

  testWidgets('prenom juste (casse et espaces libres) : la suppression part', (
    tester,
  ) async {
    final (_Port port, List<String> chemins) = await _monter(
      tester,
      () async => ResultatSuppressionEnfant.retire,
    );
    await tester.tap(find.text('Supprimer le profil de Yasmine'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(ConfirmDestructive.champSaisieKey),
      '  yasmine ',
    );
    await tester.pump();
    await tester.tap(find.text('Oui, supprimer Yasmine'));
    await tester.pumpAndSettle();
    expect(port.envois.single, 'e1');
    expect(chemins.single, Routes.tuteurFoyer);
  });

  testWidgets('succes : le foyer est relu, la page y revient', (tester) async {
    final (_Port port, List<String> chemins) = await _monter(
      tester,
      () async => ResultatSuppressionEnfant.retire,
    );
    await _confirmer(tester);
    expect(port.envois.single, 'e1');
    expect(chemins.single, Routes.tuteurFoyer);
  });

  testWidgets('renoncer : rien ne part', (tester) async {
    final (_Port port, _) = await _monter(
      tester,
      () async => ResultatSuppressionEnfant.retire,
    );
    await tester.tap(find.text('Supprimer le profil de Yasmine'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ne rien changer'));
    await tester.pumpAndSettle();
    expect(port.envois, isEmpty);
  });

  testWidgets('hors foyer : la phrase dit quoi faire', (tester) async {
    final (_, List<String> chemins) = await _monter(
      tester,
      () async => ResultatSuppressionEnfant.horsFoyer,
    );
    await _confirmer(tester);
    expect(chemins, isEmpty);
    expect(
      tester.widget<Text>(find.byKey(SupprimerProfilEleve.messageKey)).data,
      contains('Écrivez à la direction'),
    );
  });

  testWidgets('refus de droit', (tester) async {
    await _monter(
      tester,
      () async => throw const PermissionInsuffisante('SUPPRIMER'),
    );
    await _confirmer(tester);
    expect(
      find.text(
        'Votre compte ne peut pas supprimer ce profil. Écrivez à la direction.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('hors ligne : rien ne part', (tester) async {
    final (_Port port, _) = await _monter(
      tester,
      () async => ResultatSuppressionEnfant.retire,
      horsLigne: true,
    );
    await _confirmer(tester);
    expect(port.envois, isEmpty);
    expect(find.textContaining('le réseau est absent'), findsOneWidget);
  });
}
