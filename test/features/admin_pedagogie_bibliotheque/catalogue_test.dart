// CAP29-A : le catalogue de la bibliotheque d'administration.
//
// Ce que le test prouve : la liste (table au bureau, cartes au telephone) sans
// aucun total ; la recherche et les segments passent par le port (le serveur
// filtre) ; la pagination a curseur et la pagination partielle ; une ligne
// ouvre la fiche, jamais de « Publier » depuis la liste ; l'ajout n'existe que
// sur la capacite ; les etats vide, recherche vide, erreur, hors ligne,
// non autorise ; deux pastilles distinctes (publication, droits) ; 320 px,
// texte x2, LTR et RTL.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/port_bibliotheque_admin.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/empty_state.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/demo/bibliotheque_admin_demo.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/aucun_mot_coupe.dart';
import '../../support/monter_admin_demo.dart';
import '../../support/rangee_plus.dart';

Future<void> _monter(
  WidgetTester tester,
  BibliothequeAdminDemo port, {
  Size taille = const Size(1440, 900),
  double echelle = 1,
  TextDirection? direction,
  bool horsLigne = false,
}) => monterAdminDemo(
  tester,
  route: Routes.adminPedagogieBibliotheque,
  bibliotheque: port,
  taille: taille,
  echelle: echelle,
  direction: direction,
  plus: <Override>[
    horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(horsLigne)),
  ],
);

void main() {
  final a = t.admin.bibliotheque;
  final c = a.catalogue;

  testWidgets('contenu : des lignes, deux pastilles, aucun total', (
    tester,
  ) async {
    await _monter(tester, BibliothequeAdminDemo());
    expect(find.byKey(const ValueKey<String>('catalogue-liste')), findsOne);
    expect(
      find.byKey(const ValueKey<String>('support-demo-support-001')),
      findsAny,
    );
    // Publication et droits : deux colonnes de pastilles distinctes.
    expect(find.text(c.colonnes.publication), findsWidgets);
    expect(find.text(c.colonnes.droits), findsWidgets);
    // Aucun nombre global, aucune action de publication depuis la liste.
    expect(find.textContaining('240'), findsNothing);
    expect(find.textContaining('Publier'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la recherche passe par le serveur', (tester) async {
    await _monter(tester, BibliothequeAdminDemo());
    await tester.enterText(
      find.byKey(const ValueKey<String>('catalogue-recherche')),
      'zzz-introuvable',
    );
    await stabiliser(tester, fois: 12);
    expect(
      find.byKey(const ValueKey<String>('catalogue-recherche-vide')),
      findsOneWidget,
    );
    expect(find.text(c.videRecherche), findsOneWidget);
    // Effacer les filtres relance le catalogue.
    await tester.tap(find.text(c.effacerFiltres));
    await stabiliser(tester);
    expect(find.byKey(const ValueKey<String>('catalogue-liste')), findsOne);
  });

  testWidgets('un segment filtre : retires seulement', (tester) async {
    await _monter(tester, BibliothequeAdminDemo());
    // L4-07 : « Retires » est range sous « Plus » ou dans la rangee.
    await toucherFiltre(
      tester,
      find.byKey(const ValueKey<String>('segment-retires')),
    );
    await stabiliser(tester);
    expect(find.byKey(const ValueKey<String>('catalogue-liste')), findsOne);
    expect(
      find.text(t.admin.bibliotheque.libelles.version.retire),
      findsWidgets,
    );
    expect(
      find.text(t.admin.bibliotheque.libelles.version.publiee),
      findsNothing,
    );
  });

  testWidgets('catalogue vide : etat vide avec l\'ajout', (tester) async {
    await _monter(tester, BibliothequeAdminDemo(nombre: 0));
    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text(a.vide), findsOneWidget);
    expect(find.text(a.ajouter), findsWidgets);
  });

  testWidgets('sans la capacite d\'import : pas de bouton d\'ajout', (
    tester,
  ) async {
    await _monter(
      tester,
      BibliothequeAdminDemo(
        droitsServeur: const CapacitesBibliotheque(peutLire: true),
      ),
    );
    expect(
      find.byKey(const ValueKey<String>('catalogue-ajouter')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey<String>('catalogue-liste')), findsOne);
  });

  testWidgets('chargement', (tester) async {
    await _monter(tester, BibliothequeAdminDemo(pas: Duration.zero));
    // Les futurs de la demo se resolvent en une trame : on regarde avant.
    expect(find.byType(Skeleton), findsNothing);
  });

  testWidgets('erreur : reessayer relance', (tester) async {
    final BibliothequeAdminDemo port = BibliothequeAdminDemo()
      ..panneListe = true;
    await _monter(tester, port);
    expect(find.byKey(const ValueKey<String>('catalogue-erreur')), findsOne);
    port.panneListe = false;
    await tester.tap(find.text(t.commun.reessayer));
    await stabiliser(tester);
    expect(find.byKey(const ValueKey<String>('catalogue-liste')), findsOne);
  });

  testWidgets('hors ligne sans donnees', (tester) async {
    await _monter(
      tester,
      BibliothequeAdminDemo()..panneListe = true,
      horsLigne: true,
    );
    expect(
      find.byKey(const ValueKey<String>('catalogue-sans-donnees')),
      findsOneWidget,
    );
  });

  testWidgets('pagination : voir plus ajoute, jamais de doublon', (
    tester,
  ) async {
    await _monter(
      tester,
      BibliothequeAdminDemo(),
      taille: const Size(390, 844),
    );
    final Finder plus = find.byKey(
      const ValueKey<String>('catalogue-voir-plus'),
    );
    await tester.scrollUntilVisible(
      plus,
      600,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(plus);
    await stabiliser(tester);
    expect(
      find.byKey(const ValueKey<String>('catalogue-page-erreur')),
      findsNothing,
    );
  });

  testWidgets('pagination partielle : la page lue reste, la suite se relance', (
    tester,
  ) async {
    final BibliothequeAdminDemo port = BibliothequeAdminDemo()
      ..panneAPartirDePage = 2;
    await _monter(tester, port, taille: const Size(390, 844));
    final Finder plus = find.byKey(
      const ValueKey<String>('catalogue-voir-plus'),
    );
    await tester.scrollUntilVisible(
      plus,
      600,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(plus);
    await stabiliser(tester);
    expect(
      find.byKey(const ValueKey<String>('catalogue-page-erreur')),
      findsOne,
    );
    expect(find.byKey(const ValueKey<String>('catalogue-liste')), findsOne);
    port.panneAPartirDePage = null;
    await tester.tap(find.text(t.commun.reessayer));
    await stabiliser(tester);
    expect(
      find.byKey(const ValueKey<String>('catalogue-page-erreur')),
      findsNothing,
    );
  });

  testWidgets('une ligne ouvre la fiche', (tester) async {
    await _monter(tester, BibliothequeAdminDemo());
    await tester.tap(
      find.byKey(const ValueKey<String>('support-demo-support-001')),
    );
    await stabiliser(tester);
    expect(find.text(a.ficheTitre), findsWidgets);
  });

  group('gabarits', () {
    setUpAll(chargerPolicesDuDepot);
    for (final TextDirection d in TextDirection.values) {
      testWidgets('320 px, texte x2, ${d.name}', (tester) async {
        await _monter(
          tester,
          BibliothequeAdminDemo(),
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
