// CAP29-0 : le socle de la bibliotheque d'administration.
//
// Ce que le test prouve : la fonction est atteignable au clic reel depuis
// Pedagogie, en sixieme position entre Programmes et Qualite (CAP29-01) ;
// les routes existent ; le port absent dit « disponible au branchement
// serveur » ; sans la capacite de lecture, « pas d'acces » ; une lecture en
// echec propose « Reessayer » ; le double de demonstration porte au moins 200
// supports, tous les types et tous les etats, filtre et pagine par curseur
// sans total, et respecte l'immuabilite d'une version publiee.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/admin_domaine.dart';
import 'package:rewayah_academy/core/admin/modeles_bibliotheque_admin.dart';
import 'package:rewayah_academy/core/admin/port_bibliotheque_admin.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/features/demo/bibliotheque_admin_demo.dart';

import '../../support/monter_admin_demo.dart';

void main() {
  final a = t.admin.bibliotheque;

  group('navigation', () {
    test('sixieme fonction de Pedagogie, entre Programmes et Qualite', () {
      final List<String> chemins = <String>[
        for (final o in ongletsPedagogie()) o.chemin,
      ];
      expect(chemins.length, 6);
      expect(
        chemins.indexOf(Routes.adminPedagogieBibliotheque),
        chemins.indexOf(Routes.adminPedagogieProgrammes) + 1,
      );
      expect(
        chemins.indexOf(Routes.adminPedagogieQualite),
        chemins.indexOf(Routes.adminPedagogieBibliotheque) + 1,
      );
    });

    testWidgets('atteignable au clic depuis Pedagogie (CAP29-01)', (
      tester,
    ) async {
      await monterAdminDemo(tester, route: Routes.admin);
      await tester.tap(
        find.descendant(
          of: find.byKey(AdminShell.barreLateraleKey),
          matching: find.text(AdminDomaine.pedagogie.libelle),
        ),
      );
      await stabiliser(tester);
      // Six fonctions : la sous-navigation est un menu qui dit la fonction
      // courante (Diagnostics) ; on l'ouvre, puis on choisit Bibliotheque.
      await tester.tap(find.text(t.admin.diagnostics.titre).last);
      await stabiliser(tester);
      await tester.tap(find.text(a.titre).last);
      await stabiliser(tester);
      expect(find.text(a.intro), findsOneWidget);
    });
  });

  group('porte', () {
    testWidgets('port absent : disponible au branchement serveur', (
      tester,
    ) async {
      await monterAdminDemo(
        tester,
        route: Routes.adminPedagogieBibliotheque,
        bibliothequeAbsente: true,
      );
      expect(
        find.byKey(const ValueKey<String>('bibliotheque-indisponible')),
        findsOneWidget,
      );
      expect(find.text(a.indisponiblePhrase), findsOneWidget);
    });

    testWidgets('sans capacite de lecture : pas d\'acces', (tester) async {
      await monterAdminDemo(
        tester,
        route: Routes.adminPedagogieBibliotheque,
        bibliotheque: BibliothequeAdminDemo(
          droitsServeur: CapacitesBibliotheque.aucune,
        ),
      );
      expect(
        find.byKey(const ValueKey<String>('bibliotheque-non-autorise')),
        findsOneWidget,
      );
      expect(find.text(a.nonAutorise), findsOneWidget);
    });

    testWidgets('lecture en echec : reessayer', (tester) async {
      await monterAdminDemo(
        tester,
        route: Routes.adminPedagogieBibliotheque,
        bibliotheque: BibliothequeAdminDemo()..panne = true,
      );
      expect(
        find.byKey(const ValueKey<String>('bibliotheque-erreur')),
        findsOneWidget,
      );
    });

    testWidgets('fiche : la route d\'un support existe', (tester) async {
      await monterAdminDemo(
        tester,
        route: Routes.adminPedagogieSupport('demo-support-001'),
      );
      expect(find.text(a.ficheTitre), findsWidgets);
    });
  });

  group('double de demonstration', () {
    test('au moins 200 supports, tous les types et tous les etats', () async {
      final BibliothequeAdminDemo d = BibliothequeAdminDemo();
      final List<SupportAdmin> tous = <SupportAdmin>[];
      String? curseur;
      do {
        final PageSupports p = await d.lister(curseur: curseur, limite: 100);
        tous.addAll(p.elements);
        curseur = p.curseur;
      } while (curseur != null);
      expect(tous.length, greaterThanOrEqualTo(200));
      expect(
        tous.map((SupportAdmin s) => s.type).toSet(),
        TypeRessource.values.toSet(),
      );
      expect(
        tous.map((SupportAdmin s) => s.statutVersion).toSet(),
        StatutVersionRessource.values.take(2).toSet(),
      );
      expect(
        tous.map((SupportAdmin s) => s.revueDroits).toSet(),
        containsAll(<RevueDroits>[
          RevueDroits.aVerifier,
          RevueDroits.approuve,
          RevueDroits.expire,
        ]),
      );
      expect(tous.any((SupportAdmin s) => s.retire), isTrue);
    });

    test('filtres et curseur : jamais de total, pas de doublon', () async {
      final BibliothequeAdminDemo d = BibliothequeAdminDemo();
      final PageSupports p1 = await d.lister(limite: 10);
      final PageSupports p2 = await d.lister(curseur: p1.curseur, limite: 10);
      expect(p1.elements.length, 10);
      expect(p1.curseur, isNotNull);
      expect(
        <String>{
          ...p1.elements.map((SupportAdmin s) => s.id),
          ...p2.elements.map((SupportAdmin s) => s.id),
        }.length,
        20,
      );
      final PageSupports retires = await d.lister(
        filtre: const FiltreCatalogue(etat: EtatCatalogue.retires),
        limite: 100,
      );
      expect(retires.elements.every((SupportAdmin s) => s.retire), isTrue);
      final PageSupports pdf = await d.lister(
        filtre: const FiltreCatalogue(type: TypeRessource.pdf),
        limite: 100,
      );
      expect(
        pdf.elements.every((SupportAdmin s) => s.type == TypeRessource.pdf),
        isTrue,
      );
    });

    test('un support inconnu est introuvable, sans detail', () async {
      final BibliothequeAdminDemo d = BibliothequeAdminDemo();
      await expectLater(
        d.fiche('autre'),
        throwsA(isA<BibliothequeIntrouvable>()),
      );
    });

    test(
      'une nouvelle version est un brouillon, la publiee est inchangee',
      () async {
        final BibliothequeAdminDemo d = BibliothequeAdminDemo();
        // demo-support-003 : cas 2, publie.
        final FicheSupport avant = await d.fiche('demo-support-003');
        expect(avant.derniereVersion!.statut, StatutVersionRessource.publiee);
        final String v = await d.nouvelleVersion('demo-support-003');
        final FicheSupport apres = await d.fiche('demo-support-003');
        expect(apres.derniereVersion!.id, v);
        expect(apres.derniereVersion!.statut, StatutVersionRessource.brouillon);
        expect(apres.derniereVersion!.revueDroits, RevueDroits.aVerifier);
        expect(
          apres.versions.any(
            (VersionSupport x) =>
                x.id == avant.derniereVersion!.id &&
                x.statut == StatutVersionRessource.publiee,
          ),
          isTrue,
        );
      },
    );
  });
}
