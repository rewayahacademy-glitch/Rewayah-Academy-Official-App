// CAP29-C : ajouter un support.
//
// Ce que le test prouve : trois sections sur une page ; rien ne part tant que
// la ressource n'est pas decrite ; le depot passe par le port (intention,
// envoi avec progression mesuree, attente de confirmation, verification,
// pret) ; annulation ; pas de remplacement pendant l'envoi ; erreurs de
// taille, de type et de reseau, chacune avec sa phrase ; « Poursuivre » n'est
// rendu que fichier verifie et mene a la verification, jamais a « publie » ;
// reprise d'un brouillon sans ressaisie ; sans capacite d'import, rien ;
// 320 px, texte x2, LTR et RTL.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/modeles_bibliotheque_admin.dart';
import 'package:rewayah_academy/core/admin/port_bibliotheque_admin.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/admin_pedagogie_bibliotheque/import/selecteur_support.dart';
import 'package:rewayah_academy/features/demo/bibliotheque_admin_demo.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/aucun_mot_coupe.dart';
import '../../support/monter_admin_demo.dart';

class _Selecteur implements SelecteurFichierSupport {
  _Selecteur(this.fichier);

  FichierChoisi? fichier;
  final List<TypeRessource> demandes = <TypeRessource>[];

  @override
  Future<FichierChoisi?> choisir(TypeRessource type) async {
    demandes.add(type);
    return fichier;
  }
}

FichierChoisi _pdf({int octets = 1024, String mime = 'application/pdf'}) =>
    FichierChoisi(
      nom: 'cours-tajwid.pdf',
      octets: Uint8List(octets),
      mime: mime,
    );

Future<void> _monter(
  WidgetTester tester, {
  BibliothequeAdminDemo? port,
  _Selecteur? selecteur,
  String route = Routes.adminPedagogieBibliothequeNouveau,
  Size taille = const Size(1440, 900),
  double echelle = 1,
  TextDirection? direction,
}) => monterAdminDemo(
  tester,
  route: route,
  bibliotheque: port ?? BibliothequeAdminDemo(),
  taille: taille,
  echelle: echelle,
  direction: direction,
  plus: <Override>[
    selecteurFichierSupportProvider.overrideWithValue(
      selecteur ?? _Selecteur(_pdf()),
    ),
  ],
);

Finder _cle(String k) => find.byKey(ValueKey<String>(k));

Future<void> _toucher(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await stabiliser(tester, fois: 2);
  if (tester.getCenter(f).dy < 300) {
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 300));
    await stabiliser(tester, fois: 2);
  }
  await tester.tap(f);
  await stabiliser(tester, fois: 2);
}

Future<void> _choisirDansMenu(
  WidgetTester tester,
  String menu,
  String entree,
) async {
  await _toucher(tester, find.text(menu).first);
  await stabiliser(tester, fois: 3);
  await tester.tap(find.text(entree).last);
  await stabiliser(tester, fois: 3);
}

Future<void> _remplir(WidgetTester tester, {String type = 'PDF'}) async {
  final c = t.admin.bibliotheque.import.champs;
  await tester.enterText(_cle('import-titre'), 'Cours de tajwid');
  await tester.enterText(_cle('import-categorie'), 'Tajwid');
  await _choisirDansMenu(tester, c.type, type);
  await _choisirDansMenu(tester, c.langue, 'Français');
}

void main() {
  final i = t.admin.bibliotheque.import;

  testWidgets('trois sections, aucun bouton de suite sans fichier', (
    tester,
  ) async {
    await _monter(tester);
    expect(_cle('import-ressource'), findsOneWidget);
    expect(_cle('import-fichier'), findsOneWidget);
    expect(_cle('import-droits'), findsOneWidget);
    expect(_cle('import-poursuivre'), findsNothing);
    expect(_cle('import-aide'), findsOneWidget);
    // Seuls les types reellement pris en charge sont proposes.
    expect(find.text(t.admin.bibliotheque.libelles.type.quran), findsNothing);
  });

  testWidgets('ressource incomplete : rien ne part, la phrase le dit', (
    tester,
  ) async {
    final BibliothequeAdminDemo port = BibliothequeAdminDemo(nombre: 0);
    final _Selecteur sel = _Selecteur(_pdf());
    await _monter(tester, port: port, selecteur: sel);
    await _toucher(tester, _cle('import-choisir-support'));
    expect(_cle('import-incomplet'), findsOneWidget);
    expect(sel.demandes, isEmpty);
    expect((await port.lister()).elements, isEmpty);
  });

  testWidgets('depot : progression, verification, pret, puis la suite', (
    tester,
  ) async {
    final BibliothequeAdminDemo port = BibliothequeAdminDemo(nombre: 0);
    await _monter(tester, port: port);
    await _remplir(tester);
    await _toucher(tester, _cle('import-choisir-support'));
    // Pendant l'envoi : la progression est mesuree, le remplacement n'existe pas.
    await tester.pump(const Duration(milliseconds: 200));
    expect(_cle('import-progression-support'), findsOneWidget);
    expect(find.textContaining('%'), findsWidgets);
    expect(_cle('import-choisir-support'), findsNothing);
    expect(_cle('import-annuler-support'), findsOneWidget);
    expect(_cle('import-poursuivre'), findsNothing);
    // Fin du depot.
    await stabiliser(tester, fois: 40);
    expect(find.text(i.etats.pret), findsOneWidget);
    expect(_cle('import-poursuivre'), findsOneWidget);
    expect(_cle('import-choisir-support'), findsOneWidget);
    expect(find.text(i.choisirAutre), findsOneWidget);
    // Un brouillon existe, jamais un support publie.
    final PageSupports p = await port.lister();
    expect(p.elements.single.statutVersion, StatutVersionRessource.brouillon);
    // Poursuivre mene a la verification.
    await _toucher(tester, _cle('import-poursuivre'));
    await stabiliser(tester, fois: 6);
    expect(
      find.byKey(const ValueKey<String>('catalogue-recherche')),
      findsNothing,
    );
  });

  testWidgets('annuler pendant l\'envoi', (tester) async {
    // Un depot lent : le temps d'annuler pendant l'envoi.
    await _monter(
      tester,
      port: BibliothequeAdminDemo(
        nombre: 0,
        pas: const Duration(milliseconds: 1500),
      ),
    );
    await _remplir(tester);
    await _toucher(tester, _cle('import-choisir-support'));
    await tester.pump(const Duration(milliseconds: 200));
    await _toucher(tester, _cle('import-annuler-support'));
    await stabiliser(tester, fois: 40);
    expect(find.text(i.etats.annule), findsOneWidget);
    expect(_cle('import-poursuivre'), findsNothing);
    expect(_cle('import-choisir-support'), findsOneWidget);
  });

  group('erreurs', () {
    testWidgets('type mensonger', (tester) async {
      await _monter(
        tester,
        port: BibliothequeAdminDemo(nombre: 0),
        selecteur: _Selecteur(_pdf(mime: 'text/html')),
      );
      await _remplir(tester);
      await _toucher(tester, _cle('import-choisir-support'));
      await stabiliser(tester, fois: 10);
      expect(find.text(i.erreurs.type), findsOneWidget);
      expect(_cle('import-poursuivre'), findsNothing);
    });

    testWidgets('fichier trop gros', (tester) async {
      await _monter(
        tester,
        port: BibliothequeAdminDemo(nombre: 0),
        selecteur: _Selecteur(
          _pdf(octets: BibliothequeAdminDemo.tailleMaximale + 1),
        ),
      );
      await _remplir(tester);
      await _toucher(tester, _cle('import-choisir-support'));
      await stabiliser(tester, fois: 10);
      expect(find.text(i.erreurs.taille), findsOneWidget);
    });

    testWidgets('connexion perdue : non confirme, on peut reessayer', (
      tester,
    ) async {
      final BibliothequeAdminDemo port = BibliothequeAdminDemo(nombre: 0)
        ..echecDepot = ErreurUpload.reseau;
      await _monter(tester, port: port);
      await _remplir(tester);
      await _toucher(tester, _cle('import-choisir-support'));
      await stabiliser(tester, fois: 40);
      expect(find.text(i.erreurs.reseau), findsOneWidget);
      // L'echec n'a pas rendu le depot « pret » ; le choix revient.
      await _toucher(tester, _cle('import-choisir-support'));
      await stabiliser(tester, fois: 40);
      expect(find.text(i.etats.pret), findsOneWidget);
    });
  });

  testWidgets('preuve d\'autorisation : un depot distinct', (tester) async {
    final BibliothequeAdminDemo port = BibliothequeAdminDemo(nombre: 0);
    await _monter(tester, port: port);
    await _remplir(tester);
    await _toucher(tester, _cle('import-choisir-preuve'));
    await stabiliser(tester, fois: 40);
    expect(_cle('import-etat-preuve'), findsOneWidget);
    expect(find.text(i.etats.pret), findsOneWidget);
    // Le support lui-meme n'est pas depose pour autant.
    expect(_cle('import-poursuivre'), findsNothing);
    final String id = (await port.lister()).elements.single.id;
    expect((await port.fiche(id)).droits.preuveFournie, isTrue);
  });

  testWidgets('reprise d\'un brouillon : ressource visible, pas ressaisie', (
    tester,
  ) async {
    await _monter(
      tester,
      route: Routes.adminPedagogieSupportFichier('demo-support-001'),
    );
    expect(_cle('import-titre'), findsNothing);
    expect(find.text('Introduction au Tajwid 1'), findsOneWidget);
    expect(_cle('import-choisir-support'), findsOneWidget);
  });

  testWidgets('sans capacite d\'import : rien', (tester) async {
    await _monter(
      tester,
      port: BibliothequeAdminDemo(
        droitsServeur: const CapacitesBibliotheque(peutLire: true),
      ),
    );
    expect(_cle('import-non-autorise'), findsOneWidget);
    expect(_cle('import-contenu'), findsNothing);
  });

  group('gabarits', () {
    setUpAll(chargerPolicesDuDepot);
    for (final TextDirection d in TextDirection.values) {
      testWidgets('320 px, texte x2, ${d.name}', (tester) async {
        await _monter(
          tester,
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
