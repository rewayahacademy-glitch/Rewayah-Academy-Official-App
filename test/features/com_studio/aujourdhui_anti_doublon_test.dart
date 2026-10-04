// COM-STU-2 : la regle anti-doublon d'Aujourd'hui (spec section 7, R-COM-11).
// Chaque ligne ouvre son module canonique (dossier, Classe, Administration
// des communications, canal) ; une ligne Finance ou Planning, sans page,
// est nommee sans chevron ni geste ; le Studio n'execute aucune action
// metier (aucun bouton plein, rien que « ouvrir » et « marquer lu »).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/admin_domaine.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/pressable.dart';
import 'package:rewayah_academy/features/com_studio/aujourdhui_page.dart';
import 'package:rewayah_academy/features/com_studio/canal_page.dart';
import 'package:rewayah_academy/features/com_studio/port_activite_studio.dart';
import 'package:rewayah_academy/features/demo/communications/com_studio_demo.dart';

import 'support_studio.dart';

Future<(GoRouter, ActiviteStudioDemo)> _monter(
  WidgetTester tester, {
  Size taille = const Size(1440, 900),
}) async {
  final ActiviteStudioDemo activite = ActiviteStudioDemo(
    maintenant: maintenantTest,
  );
  final GoRouter routeur = await monterStudio(
    tester,
    port: portDemo(),
    depart: Routes.adminStudio,
    activite: activite,
    taille: taille,
  );
  return (routeur, activite);
}

/// Vrai si le texte [libelle] est dans une ligne qui se presse.
bool _pressable(String libelle) => find
    .ancestor(of: find.text(libelle), matching: find.byType(Pressable))
    .evaluate()
    .isNotEmpty;

Future<void> _toucher(WidgetTester tester, String libelle) async {
  final Finder f = find.text(libelle);
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  const String paiement =
      'Paiement de septembre non confirmé pour la famille Haddad';
  const String dossier = 'Dossier de la famille Karim prêt pour une décision';

  testWidgets('R-COM-11 : une ligne Finance ne s execute pas dans Le Studio '
      'et ne mene nulle part tant que Finance n a pas de page', (
    WidgetTester tester,
  ) async {
    final (GoRouter routeur, ActiviteStudioDemo activite) = await _monter(
      tester,
    );
    // Finance n'a pas de page (`admin_domaine.dart:99`).
    expect(AdminDomaine.finance.chemin, isNull);
    expect(find.text(paiement), findsOneWidget);
    expect(_pressable(paiement), isFalse);
    expect(_pressable('Clôture du mois de septembre'), isFalse);
    expect(
      _pressable('Choisir le remplaçant de mardi pour la Classe An-Nour'),
      isFalse,
    );
    final a = t.com.studio.aujourdhui;
    expect(
      find.textContaining(a.seTraiteDans(module: a.modules.finance)),
      findsNWidgets(2),
    );
    expect(
      find.textContaining(a.seTraiteDans(module: a.modules.planning)),
      findsOneWidget,
    );
    // Aucun bouton d'action metier : ni « Payer », ni « Valider », rien de
    // plein.
    expect(find.byType(ActionPrincipale), findsNothing);
    await tester.tap(find.text(paiement));
    await tester.pumpAndSettle();
    expect(cheminCourant(routeur), Routes.adminStudio);
    expect(activite.marqueesLues, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('une ligne dossier ouvre SON dossier (identifiant en argument, '
      'jamais dans l adresse) et se marque lue', (WidgetTester tester) async {
    final (GoRouter routeur, ActiviteStudioDemo activite) = await _monter(
      tester,
    );
    expect(_pressable(dossier), isTrue);
    await _toucher(tester, dossier);
    expect(cheminCourant(routeur), Routes.adminPersonnesDossiers);
    expect(adresseCourante(routeur), Routes.adminPersonnesDossiers);
    expect(
      find.text(temoinModule(Routes.adminPersonnesDossiers, 'profil-karim')),
      findsOneWidget,
    );
    expect(activite.marqueesLues, <String>['act-dossier-karim']);
  });

  testWidgets('une decision de Classe ouvre les Classes', (
    WidgetTester tester,
  ) async {
    final (GoRouter routeur, _) = await _monter(tester);
    await _toucher(tester, "Valider l'ouverture d'une Classe le samedi matin");
    expect(cheminCourant(routeur), Routes.adminOperationsGroupes);
    expect(
      find.text(temoinModule(Routes.adminOperationsGroupes, null)),
      findsOneWidget,
    );
  });

  testWidgets('une annonce ouvre l Administration des communications', (
    WidgetTester tester,
  ) async {
    final (GoRouter routeur, _) = await _monter(tester);
    await _toucher(
      tester,
      "Annonce publiée : l'académie ferme le 1er novembre",
    );
    expect(cheminCourant(routeur), Routes.adminCommunicationsAnnonces);
  });

  testWidgets('390 : une mention ouvre son canal, dans Le Studio', (
    WidgetTester tester,
  ) async {
    final (GoRouter routeur, _) = await _monter(
      tester,
      taille: const Size(390, 844),
    );
    await _toucher(tester, 'Samira vous a mentionnée');
    expect(cheminCourant(routeur), Routes.canalStudioPour('admissions'));
    expect(find.byType(CanalStudio), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('les acces rapides ouvrent des modules livres, jamais Finance '
      'ni Planning', (WidgetTester tester) async {
    final (GoRouter routeur, _) = await _monter(tester);
    final List<AccesRapideStudio> acces = accesRapidesStudio();
    expect(
      acces.map((AccesRapideStudio a) => a.destination.module),
      isNot(contains(ModuleCanonique.finance)),
    );
    expect(
      acces.map((AccesRapideStudio a) => a.destination.module),
      isNot(contains(ModuleCanonique.planning)),
    );
    for (final AccesRapideStudio a in acces) {
      expect(modulesTemoins, contains(a.destination.chemin));
      // Le module annonce est celui de la page ouverte (R-COM-11) : le
      // chemin est sous la racine de son module.
      expect(
        destinationModule(a.destination.module, a.destination.chemin),
        a.destination.chemin,
        reason: '${a.libelle} annonce ${a.destination.module.name}',
      );
    }
    final Finder dossiers = find.descendant(
      of: find.byKey(TableauAujourdhui.cleAcces),
      matching: find.text(t.com.studio.aujourdhui.acces.dossiers),
    );
    await tester.ensureVisible(dossiers);
    await tester.pumpAndSettle();
    await tester.tap(dossiers);
    await tester.pumpAndSettle();
    expect(cheminCourant(routeur), Routes.adminPersonnesDossiers);
  });

  group('La destination suit le module de la ligne', () {
    test('un chemin hors de son module n est pas suivi', () {
      expect(
        destinationModule(
          ModuleCanonique.finance,
          Routes.canalStudioPour('organisation'),
        ),
        isNull,
      );
      expect(
        destinationModule(ModuleCanonique.classes, Routes.adminStudio),
        isNull,
      );
      expect(
        destinationModule(ModuleCanonique.studio, '/admin/studio-x'),
        isNull,
      );
      expect(
        destinationModule(ModuleCanonique.planning, Routes.adminOperations),
        isNull,
      );
      expect(
        destinationModule(
          ModuleCanonique.studio,
          Routes.canalStudioPour('organisation'),
        ),
        Routes.canalStudioPour('organisation'),
      );
      expect(
        destinationModule(
          ModuleCanonique.dossiers,
          Routes.adminPersonnesDossiers,
        ),
        Routes.adminPersonnesDossiers,
      );
    });

    test('une adresse externe ou de la salle n est jamais une destination', () {
      ActiviteStudio vers(String chemin) => ActiviteStudio(
        id: 'x',
        type: TypeActivite.changementModule,
        module: ModuleCanonique.classes,
        libelle: 'x',
        survenueLe: maintenantTest,
        objet: ObjetLie(
          type: TypeObjetLie.classe,
          id: 'x',
          libelle: 'x',
          destination: chemin,
        ),
      );
      expect(vers('https://exemple.org/admin').destination, isNull);
      expect(vers('//exemple.org').destination, isNull);
      expect(vers(Routes.salle).destination, isNull);
      expect(
        vers(Routes.adminOperationsGroupes).destination,
        const DestinationStudio(
          chemin: Routes.adminOperationsGroupes,
          module: ModuleCanonique.classes,
        ),
      );
    });

    test('un dossier porte son identifiant en argument', () {
      final ActiviteStudio a = fixturesActiviteStudioDemo(maintenantTest)
          .firstWhere((ActiviteStudio a) => a.id == 'act-dossier-karim');
      expect(a.destination?.argument, 'profil-karim');
      expect(a.destination?.chemin, Routes.adminPersonnesDossiers);
    });
  });
}
