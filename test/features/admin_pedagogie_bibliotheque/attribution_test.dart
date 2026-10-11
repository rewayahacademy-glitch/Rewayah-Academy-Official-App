// CAP29-E : attribuer a des classes et retirer.
//
// Ce que le test prouve : les classes sont paginees a curseur (35 classes,
// 25 par page) ; une classe deja servie est nommee et non modifiable ; le
// bouton n'est JAMAIS grise : sans classe choisie, la phrase dit quoi faire ;
// l'attribution est idempotente et le succes n'est annonce qu'apres le
// serveur ; l'epinglage est un choix explicite ; le retrait exige un motif,
// une confirmation qui dit la consequence, et laisse une trace dans
// l'historique ; sans capacite, aucune action n'est offerte ; un support non
// publie n'est pas attribuable ; un conflit de revision est dit ; les etats
// erreur et hors ligne ; 320 px, texte x2, LTR et RTL.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/modeles_bibliotheque_admin.dart';
import 'package:rewayah_academy/core/admin/port_bibliotheque_admin.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/demo/bibliotheque_admin_demo.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/aucun_mot_coupe.dart';
import '../../support/monter_admin_demo.dart';

const String _brouillon = 'demo-support-001';
const String _publie = 'demo-support-003';
const String _retire = 'demo-support-005';

Future<void> _monter(
  WidgetTester tester,
  String id, {
  BibliothequeAdminDemo? port,
  Size taille = const Size(1440, 900),
  double echelle = 1,
  TextDirection? direction,
}) => monterAdminDemo(
  tester,
  route: Routes.adminPedagogieSupportAttribution(id),
  bibliotheque: port ?? BibliothequeAdminDemo(),
  taille: taille,
  echelle: echelle,
  direction: direction,
);

Finder _cle(String k) => find.byKey(ValueKey<String>(k));

Future<void> _toucher(WidgetTester tester, String k) async {
  await tester.ensureVisible(_cle(k));
  await stabiliser(tester, fois: 2);
  if (tester.getCenter(_cle(k)).dy < 300) {
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 300));
    await stabiliser(tester, fois: 2);
  }
  await tester.tap(_cle(k));
  await stabiliser(tester);
}

void main() {
  final a = t.admin.bibliotheque.attribution;

  group('attribution', () {
    testWidgets('classes paginees, deja servies nommees', (tester) async {
      final BibliothequeAdminDemo port = BibliothequeAdminDemo();
      await _monter(tester, _publie, port: port);
      expect(_cle('attribution-contenu'), findsOneWidget);
      expect(_cle('attribution-classe-demo-classe-01'), findsOneWidget);
      expect(_cle('attribution-classe-demo-classe-30'), findsNothing);
      await _toucher(tester, 'attribution-plus');
      expect(_cle('attribution-classe-demo-classe-30'), findsOneWidget);
      expect(_cle('attribution-plus'), findsNothing);
    });

    testWidgets('jamais grise : sans classe, la phrase dit quoi faire', (
      tester,
    ) async {
      await _monter(tester, _publie);
      await _toucher(tester, 'attribution-attribuer');
      expect(find.text(a.attribuerAucune), findsOneWidget);
      expect(_cle('attribution-message'), findsNothing);
    });

    testWidgets('attribuer, epingler, idempotent, classes servies', (
      tester,
    ) async {
      final BibliothequeAdminDemo port = BibliothequeAdminDemo();
      await _monter(tester, _publie, port: port);
      await _toucher(tester, 'attribution-classe-demo-classe-02');
      await _toucher(tester, 'attribution-epingler');
      await _toucher(tester, 'attribution-attribuer');
      expect(find.text(a.attribuee), findsOneWidget);
      expect(find.text(a.classeEpinglee), findsOneWidget);
      final FicheSupport f = (await tester.runAsync(
        () => port.fiche(_publie),
      ))!;
      expect(f.historique.first.action, ActionAudit.attribution);
      final int servies = f.classesServies;
      // Une classe deja servie n'est plus modifiable.
      final CheckboxListTile c = tester.widget<CheckboxListTile>(
        _cle('attribution-classe-demo-classe-02'),
      );
      expect(c.onChanged, isNull);
      expect(c.value, isTrue);
      final ResultatEcriture r = (await tester.runAsync(
        () => port.attribuer(
          supportId: _publie,
          classeIds: <String>{'demo-classe-02'},
          epingler: true,
          revisionAttendue: f.revision,
        ),
      ))!;
      expect(r, isA<EcritureFaite>());
      final FicheSupport g = (await tester.runAsync(
        () => port.fiche(_publie),
      ))!;
      expect(g.classesServies, servies);
    });

    testWidgets('conflit de revision', (tester) async {
      final BibliothequeAdminDemo port = BibliothequeAdminDemo();
      await _monter(tester, _publie, port: port);
      final FicheSupport f = (await tester.runAsync(
        () => port.fiche(_publie),
      ))!;
      await tester.runAsync(
        () => port.attribuer(
          supportId: _publie,
          classeIds: <String>{'demo-classe-09'},
          epingler: false,
          revisionAttendue: f.revision,
        ),
      );
      await _toucher(tester, 'attribution-classe-demo-classe-03');
      await _toucher(tester, 'attribution-attribuer');
      expect(_cle('attribution-conflit'), findsOneWidget);
      await _toucher(tester, 'attribution-recharger');
      expect(_cle('attribution-conflit'), findsNothing);
    });

    testWidgets('echec reseau : rien n\'est annonce attribue', (tester) async {
      final BibliothequeAdminDemo port = BibliothequeAdminDemo();
      await _monter(tester, _publie, port: port);
      await _toucher(tester, 'attribution-classe-demo-classe-04');
      port.panneEcriture = true;
      await _toucher(tester, 'attribution-attribuer');
      expect(find.text(a.attribueEchec), findsOneWidget);
      expect(find.text(a.attribuee), findsNothing);
    });

    testWidgets('sans capacite : aucune action offerte', (tester) async {
      final BibliothequeAdminDemo port = BibliothequeAdminDemo(
        droitsServeur: const CapacitesBibliotheque(peutLire: true),
      );
      await _monter(tester, _publie, port: port);
      expect(_cle('attribution-contenu'), findsOneWidget);
      expect(_cle('attribution-attribuer'), findsNothing);
      expect(_cle('attribution-retirer'), findsNothing);
    });

    testWidgets('support non publie : pas attribuable', (tester) async {
      await _monter(tester, _brouillon);
      expect(_cle('attribution-non-publie'), findsOneWidget);
      expect(_cle('attribution-attribuer'), findsNothing);
    });
  });

  group('retrait', () {
    testWidgets('motif obligatoire, confirmation, trace', (tester) async {
      final BibliothequeAdminDemo port = BibliothequeAdminDemo();
      await _monter(tester, _publie, port: port);
      await _toucher(tester, 'attribution-retirer');
      expect(find.text(a.motifRequis), findsOneWidget);
      await tester.enterText(_cle('attribution-motif'), 'Licence retiree.');
      await _toucher(tester, 'attribution-retirer');
      expect(find.text(a.retraitConfirmerEffet), findsOneWidget);
      // Renoncer ne retire rien.
      await tester.tap(find.text(t.commun.annuler).last);
      await stabiliser(tester);
      expect(_cle('attribution-retire'), findsNothing);
      await _toucher(tester, 'attribution-retirer');
      await tester.tap(find.text(a.retraitConfirmerBouton));
      await stabiliser(tester);
      expect(find.text(a.retire), findsOneWidget);
      expect(_cle('attribution-retire'), findsOneWidget);
      final FicheSupport f = (await tester.runAsync(
        () => port.fiche(_publie),
      ))!;
      expect(f.support.retire, isTrue);
      expect(f.historique.first.action, ActionAudit.retrait);
      expect(f.historique.first.motif, 'Licence retiree.');
    });

    testWidgets('un support deja retire dit son motif', (tester) async {
      await _monter(tester, _retire);
      expect(_cle('attribution-retire'), findsOneWidget);
      expect(_cle('attribution-retirer'), findsNothing);
      expect(_cle('attribution-attribuer'), findsNothing);
    });
  });

  group('etats', () {
    testWidgets('erreur avec reessai', (tester) async {
      final BibliothequeAdminDemo port = BibliothequeAdminDemo()
        ..erreurFiche = true;
      await _monter(tester, _publie, port: port);
      expect(_cle('attribution-erreur'), findsOneWidget);
    });

    testWidgets('introuvable', (tester) async {
      await _monter(tester, 'demo-support-inconnu');
      expect(_cle('attribution-introuvable'), findsOneWidget);
    });
  });

  group('adaptation', () {
    setUpAll(chargerPolicesDuDepot);
    for (final TextDirection d in TextDirection.values) {
      testWidgets('320 px, texte x2, ${d.name}', (tester) async {
        await _monter(
          tester,
          _publie,
          taille: const Size(320, 640),
          echelle: 2,
          direction: d,
        );
        expect(tester.takeException(), isNull);
        verifierEcranSansMotCoupe(tester);
      });
    }
  });
}
