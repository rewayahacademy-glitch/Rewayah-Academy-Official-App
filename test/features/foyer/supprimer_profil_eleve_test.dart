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
  await tester.tap(find.text('Supprimer le profil').last);
  await tester.pumpAndSettle();
}

void main() {
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
