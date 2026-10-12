// CAP29-D : verifier et publier.
//
// Ce que le test prouve : chaque critere est rendu par le serveur, avec trois
// signaux (icone, mot, encre) ; la liste des blocages dit comment les lever ;
// « Publier la version » n'est JAMAIS grise : bloque, il reste actif et la
// phrase du blocage est visible ; la confirmation recapitulative dit la portee
// et l'effet ; le succes n'est annonce qu'apres le serveur ; la publication est
// atomique (un echec ne publie rien) ; un conflit d'edition est dit ; sans la
// capacite de publier, le controle reste consultable ; une version deja
// publiee ne se republie pas ; les etats erreur, hors ligne, introuvable ;
// 320 px, texte x2, LTR et RTL.
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

// 001 : brouillon sans fichier, niveau absent, droits a verifier.
// 002 : brouillon avec fichier et niveau, droits a verifier.
// 003 : deja publie.
const String _bloque = 'demo-support-001';
const String _pret = 'demo-support-002';
const String _publie = 'demo-support-003';

Future<void> _monter(
  WidgetTester tester,
  String id, {
  BibliothequeAdminDemo? port,
  Size taille = const Size(1440, 900),
  double echelle = 1,
  TextDirection? direction,
}) => monterAdminDemo(
  tester,
  route: Routes.adminPedagogieSupportPublication(id),
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

/// Depose la preuve d'autorisation d'un support, comme l'import le fait.
Future<void> _deposerPreuve(BibliothequeAdminDemo port, String id) async {
  final IntentionUpload i = await port.demanderUpload(
    supportId: id,
    fichier: const FichierADeposer(
      nom: 'preuve.pdf',
      octets: 10,
      mime: 'application/pdf',
      sha256: '0000000000000000000000000000000000000000000000000000000000000000',
    ),
    finalite: FinaliteUpload.preuve,
  );
  await port.deposer(uploadId: i.id).last;
}

/// Remplit la revue des droits d'un brouillon et l'enregistre.
Future<void> _completerDroits(WidgetTester tester) async {
  await tester.enterText(_cle('droits-source'), 'Editions de demonstration');
  await tester.enterText(_cle('droits-titulaire'), 'Titulaire connu');
  for (final String u in <String>['application', 'classe']) {
    await _toucher(tester, 'droits-usage-$u');
  }
  await _toucher(tester, 'droits-approuver');
  await _toucher(tester, 'publication-enregistrer');
}

void main() {
  final a = t.admin.bibliotheque.publication;

  group('controle', () {
    testWidgets('chaque critere est rendu, blocages expliques', (tester) async {
      await _monter(tester, _bloque);
      expect(_cle('publication-contenu'), findsOneWidget);
      for (final CleCritere c in CleCritere.values) {
        expect(_cle('critere-${c.name}'), findsOneWidget);
      }
      // Trois signaux : le mot de l'etat est lu, pas seulement la couleur.
      expect(find.text(a.etats.bloque), findsWidgets);
      expect(find.text(a.etats.valide), findsWidgets);
      expect(_cle('publication-blocages-titre'), findsOneWidget);
      expect(_cle('blocage-source'), findsOneWidget);
      expect(_cle('blocage-fichierSain'), findsOneWidget);
    });

    testWidgets('publier n\'est jamais grise : actif, la phrase est a cote', (
      tester,
    ) async {
      final BibliothequeAdminDemo port = BibliothequeAdminDemo();
      await _monter(tester, _bloque, port: port);
      expect(_cle('publication-publier'), findsOneWidget);
      expect(_cle('publication-bloque'), findsOneWidget);
      expect(find.text(a.bloque), findsOneWidget);
      await _toucher(tester, 'publication-publier');
      // Bloque : pas de confirmation, rien n'est publie.
      expect(find.text(a.confirmerEffet), findsNothing);
      expect(
        (await port.fiche(_bloque)).derniereVersion!.statut,
        StatutVersionRessource.brouillon,
      );
      expect(_cle('publication-bloque'), findsOneWidget);
    });

    testWidgets('la revue des droits leve des blocages, pas tous', (
      tester,
    ) async {
      await _monter(tester, _bloque);
      await _completerDroits(tester);
      expect(find.text(a.droitsEnregistres), findsOneWidget);
      expect(_cle('blocage-source'), findsNothing);
      expect(_cle('blocage-titulaire'), findsNothing);
      // Il manque encore le fichier : la publication reste bloquee.
      expect(_cle('blocage-fichierSain'), findsOneWidget);
      expect(_cle('publication-bloque'), findsOneWidget);
    });
  });

  group('publication', () {
    testWidgets('confirmation recapitulative, puis succes apres le serveur', (
      tester,
    ) async {
      final BibliothequeAdminDemo port = BibliothequeAdminDemo(
        pas: Duration.zero,
      );
      await tester.runAsync(() => _deposerPreuve(port, _pret));
      await _monter(tester, _pret, port: port);
      await _completerDroits(tester);
      expect(_cle('aucun-blocage'), findsOneWidget);
      expect(_cle('publication-bloque'), findsNothing);
      await _toucher(tester, 'publication-publier');
      // La confirmation dit la portee et l'effet.
      expect(find.text(a.confirmerEffet), findsOneWidget);
      expect(find.text(a.confirmerTitre(numero: '1')), findsOneWidget);
      expect(
        (await port.fiche(_pret)).derniereVersion!.statut,
        StatutVersionRessource.brouillon,
      );
      await tester.tap(find.text(a.confirmerBouton).last);
      await stabiliser(tester);
      expect(find.text(a.publiee), findsOneWidget);
      expect(_cle('deja-publiee'), findsOneWidget);
      expect(_cle('publication-publier'), findsNothing);
      final FicheSupport f = await port.fiche(_pret);
      expect(f.derniereVersion!.statut, StatutVersionRessource.publiee);
      expect(f.support.publie, isTrue);
    });

    testWidgets('renoncer a la confirmation : rien n\'est publie', (
      tester,
    ) async {
      final BibliothequeAdminDemo port = BibliothequeAdminDemo(
        pas: Duration.zero,
      );
      await tester.runAsync(() => _deposerPreuve(port, _pret));
      await _monter(tester, _pret, port: port);
      await _completerDroits(tester);
      await _toucher(tester, 'publication-publier');
      await tester.tap(find.text(t.commun.annuler).last);
      await stabiliser(tester);
      expect(
        (await port.fiche(_pret)).derniereVersion!.statut,
        StatutVersionRessource.brouillon,
      );
      expect(_cle('publication-publier'), findsOneWidget);
    });

    testWidgets('reseau coupe : rien n\'est publie, la phrase le dit', (
      tester,
    ) async {
      final BibliothequeAdminDemo port = BibliothequeAdminDemo(
        pas: Duration.zero,
      );
      await tester.runAsync(() => _deposerPreuve(port, _pret));
      await _monter(tester, _pret, port: port);
      await _completerDroits(tester);
      port.panneEcriture = true;
      await _toucher(tester, 'publication-publier');
      await tester.tap(find.text(a.confirmerBouton).last);
      await stabiliser(tester);
      expect(_cle('publication-echec'), findsOneWidget);
      expect(find.text(a.echec), findsOneWidget);
      expect(
        (await port.fiche(_pret)).derniereVersion!.statut,
        StatutVersionRessource.brouillon,
      );
      // Le serveur revient : la meme page republie.
      port.panneEcriture = false;
      await _toucher(tester, 'publication-publier');
      await tester.tap(find.text(a.confirmerBouton).last);
      await stabiliser(tester);
      expect(find.text(a.publiee), findsOneWidget);
    });

    testWidgets('conflit : un autre administrateur a ecrit entre-temps', (
      tester,
    ) async {
      final BibliothequeAdminDemo port = BibliothequeAdminDemo(
        pas: Duration.zero,
      );
      await tester.runAsync(() => _deposerPreuve(port, _pret));
      await _monter(tester, _pret, port: port);
      await _completerDroits(tester);
      final FicheSupport vue = await port.fiche(_pret);
      await port.mettreAJour(
        supportId: _pret,
        modification: const ModificationSupport(description: 'Autre admin'),
        revisionAttendue: vue.revision,
      );
      await _toucher(tester, 'publication-publier');
      await tester.tap(find.text(a.confirmerBouton).last);
      await stabiliser(tester);
      expect(_cle('publication-conflit'), findsOneWidget);
      expect(
        (await port.fiche(_pret)).derniereVersion!.statut,
        StatutVersionRessource.brouillon,
      );
      await _toucher(tester, 'publication-recharger');
      expect(_cle('publication-conflit'), findsNothing);
    });
  });

  group('capacites et etats', () {
    testWidgets('sans la capacite de publier : controle seul', (tester) async {
      await _monter(
        tester,
        _bloque,
        port: BibliothequeAdminDemo(
          droitsServeur: const CapacitesBibliotheque(
            peutLire: true,
            peutImporter: true,
          ),
        ),
      );
      expect(_cle('publication-checklist'), findsOneWidget);
      expect(_cle('publication-publier'), findsNothing);
      expect(_cle('publication-sans-capacite'), findsOneWidget);
    });

    testWidgets('version deja publiee : pas de republication', (tester) async {
      await _monter(tester, _publie);
      expect(_cle('deja-publiee'), findsOneWidget);
      expect(_cle('publication-publier'), findsNothing);
      expect(_cle('droits-figes'), findsOneWidget);
      expect(_cle('publication-vers-fiche'), findsOneWidget);
    });

    testWidgets('introuvable', (tester) async {
      await _monter(tester, 'autre-foyer');
      expect(_cle('publication-introuvable'), findsOneWidget);
    });

    testWidgets('hors ligne sans donnees', (tester) async {
      await _monter(
        tester,
        _bloque,
        port: BibliothequeAdminDemo()..panneFiche = true,
      );
      expect(_cle('publication-sans-donnees'), findsOneWidget);
    });

    testWidgets('erreur de lecture : reessayer', (tester) async {
      final BibliothequeAdminDemo port = BibliothequeAdminDemo()
        ..erreurFiche = true;
      await _monter(tester, _bloque, port: port);
      expect(_cle('publication-erreur'), findsOneWidget);
      port.erreurFiche = false;
      await tester.tap(find.text(t.commun.reessayer));
      await stabiliser(tester);
      expect(_cle('publication-contenu'), findsOneWidget);
    });
  });

  group('gabarits', () {
    setUpAll(chargerPolicesDuDepot);
    for (final TextDirection d in TextDirection.values) {
      testWidgets('320 px, texte x2, ${d.name}', (tester) async {
        await _monter(
          tester,
          _bloque,
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
