// CAP29-B : la fiche d'un support.
//
// Ce que le test prouve : un brouillon s'edite, s'enregistre et mene a
// « Verifier et publier » ; une version publiee est figee et ne propose que
// « Creer une nouvelle version » (un nouveau brouillon) ; un support retire
// dit son motif ; une seule action principale ; les trois vocabulaires
// (version, droits, retrait) restent distincts ; un conflit d'edition est dit
// et la fiche se recharge ; sans capacite, aucune action n'est rendue ; les
// etats erreur, hors ligne, introuvable ; deux colonnes au bureau, sections
// repliables au telephone ; 320 px, texte x2, LTR et RTL.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/modeles_bibliotheque_admin.dart';
import 'package:rewayah_academy/core/admin/port_bibliotheque_admin.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/demo/bibliotheque_admin_demo.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/aucun_mot_coupe.dart';
import '../../support/monter_admin_demo.dart';

// Supports de la demonstration : 001 brouillon a verifier, 003 publie,
// 005 retire, 006 droits expires.
const String _brouillon = 'demo-support-001';
const String _publie = 'demo-support-003';
const String _retire = 'demo-support-005';
const String _expire = 'demo-support-006';

Future<void> _monter(
  WidgetTester tester,
  String id, {
  BibliothequeAdminDemo? port,
  Size taille = const Size(1440, 900),
  double echelle = 1,
  TextDirection? direction,
  bool horsLigne = false,
}) => monterAdminDemo(
  tester,
  route: Routes.adminPedagogieSupport(id),
  bibliotheque: port ?? BibliothequeAdminDemo(),
  taille: taille,
  echelle: echelle,
  direction: direction,
  plus: <Override>[
    horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(horsLigne)),
  ],
);

Finder _cle(String k) => find.byKey(ValueKey<String>(k));

/// Touche un element en le rendant d'abord visible (la fiche est longue).
Future<void> _toucher(WidgetTester tester, String k) async {
  await tester.ensureVisible(_cle(k));
  await stabiliser(tester, fois: 2);
  // ensureVisible peut laisser l'element sous l'en-tete fixe : on le descend
  // dans la zone libre avant de toucher.
  if (tester.getCenter(_cle(k)).dy < 300) {
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 300));
    await stabiliser(tester, fois: 2);
  }
  await tester.tap(_cle(k));
  await stabiliser(tester);
}

void main() {
  final a = t.admin.bibliotheque;
  final f = a.fiche;

  group('brouillon', () {
    testWidgets('s\'edite, s\'enregistre, mene a verifier et publier', (
      tester,
    ) async {
      final BibliothequeAdminDemo port = BibliothequeAdminDemo();
      await _monter(tester, _brouillon, port: port);
      expect(_cle('fiche-contenu'), findsOneWidget);
      expect(find.text(f.apercuAucunFichier), findsOneWidget);
      expect(_cle('fiche-champ-titre'), findsOneWidget);
      await tester.enterText(_cle('fiche-champ-titre'), 'Titre corrige');
      await _toucher(tester, 'fiche-enregistrer');
      expect(find.text(f.enregistre), findsOneWidget);
      expect((await port.fiche(_brouillon)).support.titre, 'Titre corrige');
      // L'action principale unique mene a la verification.
      expect(_cle('fiche-action-principale'), findsOneWidget);
      expect(
        find.descendant(
          of: _cle('fiche-action-principale'),
          matching: find.text(f.actions.verifier),
        ),
        findsOneWidget,
      );
      expect(find.text(f.actions.nouvelleVersion), findsNothing);
    });

    testWidgets('titre vide : l\'erreur est dite, rien n\'est envoye', (
      tester,
    ) async {
      final BibliothequeAdminDemo port = BibliothequeAdminDemo();
      await _monter(tester, _brouillon, port: port);
      final String avant = (await port.fiche(_brouillon)).support.titre;
      await tester.enterText(_cle('fiche-champ-titre'), '   ');
      await _toucher(tester, 'fiche-enregistrer');
      expect(find.text(f.titreVide), findsOneWidget);
      expect((await port.fiche(_brouillon)).support.titre, avant);
    });

    testWidgets('deux vocabulaires distincts : version et droits', (
      tester,
    ) async {
      await _monter(tester, _brouillon);
      expect(
        find.descendant(
          of: _cle('fiche-statut'),
          matching: find.text(a.libelles.version.brouillon),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _cle('fiche-revue'),
          matching: find.text(a.libelles.droits.aVerifier),
        ),
        findsOneWidget,
      );
    });

    testWidgets('conflit d\'edition : dit, puis la fiche se recharge', (
      tester,
    ) async {
      final BibliothequeAdminDemo port = BibliothequeAdminDemo();
      await _monter(tester, _brouillon, port: port);
      // Un autre administrateur ecrit entre-temps.
      final FicheSupport vue = await port.fiche(_brouillon);
      await port.mettreAJour(
        supportId: _brouillon,
        modification: const ModificationSupport(description: 'Autre admin'),
        revisionAttendue: vue.revision,
      );
      await _toucher(tester, 'fiche-enregistrer');
      expect(_cle('fiche-conflit'), findsOneWidget);
      expect(_cle('fiche-enregistrer'), findsNothing);
      await _toucher(tester, 'fiche-recharger');
      expect(_cle('fiche-conflit'), findsNothing);
      expect(_cle('fiche-enregistrer'), findsOneWidget);
    });
  });

  group('publie, retire, expire', () {
    testWidgets('publie : fige, seule une nouvelle version est offerte', (
      tester,
    ) async {
      final BibliothequeAdminDemo port = BibliothequeAdminDemo();
      await _monter(tester, _publie, port: port);
      expect(_cle('fiche-figee'), findsOneWidget);
      expect(find.text(f.figee), findsOneWidget);
      expect(_cle('fiche-champ-titre'), findsNothing);
      expect(_cle('fiche-enregistrer'), findsNothing);
      expect(find.text(f.actions.verifier), findsNothing);
      await _toucher(tester, 'fiche-action-principale');
      expect(find.text(f.nouvelleVersionOk), findsOneWidget);
      // La nouvelle version est un brouillon : l'edition revient.
      expect(_cle('fiche-champ-titre'), findsOneWidget);
      expect(
        (await port.fiche(_publie)).derniereVersion!.statut,
        StatutVersionRessource.brouillon,
      );
    });

    testWidgets('retire : motif en clair, rien a editer', (tester) async {
      await _monter(tester, _retire);
      expect(find.textContaining('Licence non renouvelée'), findsWidgets);
      expect(_cle('fiche-champ-titre'), findsNothing);
      expect(
        find.descendant(
          of: _cle('fiche-statut'),
          matching: find.text(a.libelles.version.retire),
        ),
        findsOneWidget,
      );
    });

    testWidgets('droits expires : la pastille le dit, pas la version', (
      tester,
    ) async {
      await _monter(tester, _expire);
      expect(
        find.descendant(
          of: _cle('fiche-revue'),
          matching: find.text(a.libelles.droits.expire),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _cle('fiche-statut'),
          matching: find.text(a.libelles.version.publiee),
        ),
        findsOneWidget,
      );
    });
  });

  group('capacites', () {
    testWidgets('sans capacite de modifier : ni champs ni boutons', (
      tester,
    ) async {
      await _monter(
        tester,
        _brouillon,
        port: BibliothequeAdminDemo(
          droitsServeur: const CapacitesBibliotheque(peutLire: true),
        ),
      );
      expect(_cle('fiche-contenu'), findsOneWidget);
      expect(_cle('fiche-champ-titre'), findsNothing);
      expect(_cle('fiche-enregistrer'), findsNothing);
      expect(_cle('fiche-action-principale'), findsNothing);
      expect(_cle('fiche-deposer'), findsNothing);
    });

    testWidgets('sans capacite d\'attribuer : pas d\'association', (
      tester,
    ) async {
      await _monter(
        tester,
        _publie,
        port: BibliothequeAdminDemo(
          droitsServeur: const CapacitesBibliotheque(
            peutLire: true,
            peutImporter: true,
          ),
        ),
      );
      expect(_cle('fiche-associer'), findsNothing);
      expect(_cle('fiche-retirer'), findsNothing);
    });

    testWidgets('publie avec capacites : associer et retirer existent', (
      tester,
    ) async {
      await _monter(tester, _publie);
      expect(_cle('fiche-associer'), findsOneWidget);
      expect(_cle('fiche-retirer'), findsOneWidget);
    });
  });

  group('etats', () {
    testWidgets('introuvable : meme message qu\'un support non visible', (
      tester,
    ) async {
      await _monter(tester, 'autre-foyer');
      expect(_cle('fiche-introuvable'), findsOneWidget);
    });

    testWidgets('erreur de lecture : reessayer', (tester) async {
      final BibliothequeAdminDemo port = BibliothequeAdminDemo()
        ..erreurFiche = true;
      await _monter(tester, _brouillon, port: port);
      expect(_cle('fiche-sans-donnees'), findsNothing);
      expect(_cle('fiche-erreur'), findsOneWidget);
      port.erreurFiche = false;
      await tester.tap(find.text(t.commun.reessayer));
      await stabiliser(tester);
      expect(_cle('fiche-contenu'), findsOneWidget);
    });

    testWidgets('hors ligne sans donnees', (tester) async {
      await _monter(
        tester,
        _brouillon,
        port: BibliothequeAdminDemo()..panneFiche = true,
        horsLigne: true,
      );
      expect(_cle('fiche-sans-donnees'), findsOneWidget);
    });
  });

  group('mise en page', () {
    testWidgets('bureau : deux colonnes', (tester) async {
      await _monter(tester, _brouillon);
      final double x1 = tester.getTopLeft(_cle('section-apercu')).dx;
      final double x2 = tester.getTopLeft(_cle('section-workflow')).dx;
      expect(x2, greaterThan(x1 + 300));
      expect(_cle('section-bascule-apercu'), findsNothing);
    });

    testWidgets('telephone : une colonne, sections repliables, action en bas', (
      tester,
    ) async {
      await _monter(tester, _brouillon, taille: const Size(390, 844));
      expect(_cle('section-bascule-apercu'), findsOneWidget);
      final double y1 = tester.getTopLeft(_cle('section-apercu')).dy;
      final double y2 = tester.getTopLeft(_cle('section-workflow')).dy;
      expect(y2, greaterThan(y1));
      expect(
        tester.getTopLeft(_cle('section-apercu')).dx,
        tester.getTopLeft(_cle('section-workflow')).dx,
      );
      // L'action principale est unique et vient apres les sections.
      expect(_cle('fiche-action-principale'), findsOneWidget);
      // Replier masque le contenu de la section.
      expect(find.text(f.apercuAucunFichier), findsOneWidget);
      await _toucher(tester, 'section-bascule-apercu');
      expect(find.text(f.apercuAucunFichier), findsNothing);
    });

    group('gabarits', () {
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
  });
}
