// LISTES-1 : le traitement groupe des candidatures, de la selection au rapport.
//
// Ce que le test prouve :
// - l'apercu vient du serveur : les candidatures que le geste fera, celles qu'il
//   exclut avec leur raison en mots, le nombre a confirmer ; rien n'est ecrit ;
// - le lot ne part pas sans ce que le geste exige (motif, message) ni sans le
//   bon nombre, saisi par la direction ; il part avec le jeton de l'apercu et une
//   cle d'idempotence ;
// - « non confirme » garde la cle : « Reessayer » rejoue le MEME lot, rien n'est
//   ecrit deux fois ; un refus nomme (jeton perime...) remet une cle neuve et
//   demande un nouvel apercu ;
// - le rapport dit chaque ligne : reussie, exclue, refusee ; rien n'est dit
//   reussi avant la reponse du serveur ; la liste se relit et la selection se vide.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/gestes_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';
import 'package:rewayah_academy/core/candidature/modeles_lot_candidatures.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/features/admin_candidatures/candidatures_page.dart';
import 'package:rewayah_academy/features/admin_candidatures/ligne_candidature.dart';
import 'package:rewayah_academy/features/admin_candidatures/lot_candidatures.dart';

import '../../fixtures/candidature/faux_candidatures_direction.dart';
import '../../support/garde_interface.dart';
import '../../support/monter_recrutement.dart';
import 'hote_candidatures.dart';

final lot = t.admin.candidatures.lot;
final feuille = t.admin.candidatures.lot.feuille;

List<LigneCandidature> _lignes() => <LigneCandidature>[
  ligneTest(id: 'a1', nom: 'Amina Diallo'),
  ligneTest(id: 'b2', nom: 'Bilal Haddad'),
  // Deja en pause : exclue de « Mettre en pause », eligible a « Lever la pause ».
  ligneTest(id: 'e5', nom: 'Emna Gharbi', enPause: true),
  ligneTest(id: 'f6', nom: 'Farah Nasser', issue: IssueCandidature.refusee),
];

Future<FauxCandidaturesDirection> _monter(
  WidgetTester tester, {
  Map<String, String> refusParLigne = const <String, String>{},
  double largeur = 390,
}) async {
  final FauxCandidaturesDirection port = FauxCandidaturesDirection(
    lignes: _lignes(),
    capacitesRendues: capacitesGestes,
    refusParLigne: refusParLigne,
  );
  await monterCandidatures(tester, port: port, largeur: largeur, hauteur: 3000);
  return port;
}

Future<void> _cocher(WidgetTester tester, List<String> ids) async {
  for (final String id in ids) {
    final Finder f = find.byKey(cleCase(id));
    await tester.ensureVisible(f);
    await tester.pump();
    await tester.tap(f);
    await laisser(tester);
  }
}

Future<void> _ouvrirFeuille(WidgetTester tester, GesteLot geste) async {
  final Finder operation = find.byKey(CandidaturesPage.cleOperationLot(geste));
  await tester.ensureVisible(operation);
  await tester.pump();
  await tester.tap(operation);
  await laisser(tester, fois: 12);
}

Future<void> _remplir(
  WidgetTester tester, {
  String nombre = '2',
  bool modele = true,
  bool motif = true,
}) async {
  if (modele) {
    final Finder m = find.byKey(const ValueKey<String>('modele-pause_general'));
    await tester.ensureVisible(m);
    await tester.pump();
    await tester.tap(m);
    await laisser(tester);
  }
  if (motif) {
    await tester.enterText(
      find.byKey(FeuilleLot.cleMotif),
      'Attente des pieces.',
    );
  }
  await tester.enterText(find.byKey(FeuilleLot.cleNombre), nombre);
  await tester.pump();
}

Future<void> _valider(WidgetTester tester) async {
  final Finder b = find.byKey(FeuilleLot.cleValider);
  await tester.ensureVisible(b);
  await tester.pump();
  await tester.tap(b);
  await laisser(tester, fois: 12);
}

void main() {
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('l\'apercu', () {
    testWidgets(
      'les eligibles, les exclus avec leur raison en mots, rien d\'ecrit',
      (tester) async {
        final FauxCandidaturesDirection port = await _monter(tester);
        await _cocher(tester, <String>['a1', 'b2', 'e5']);
        await _ouvrirFeuille(tester, GesteLot.mettreEnPause);
        expect(find.byKey(FeuilleLot.cle), findsOneWidget);
        // L'apercu est demande au serveur, avec les identifiants retenus.
        expect(port.appelsApercuLot, hasLength(1));
        expect(port.appelsApercuLot.single.geste, GesteLot.mettreEnPause);
        expect(port.appelsApercuLot.single.ids.toSet(), <String>{
          'a1',
          'b2',
          'e5',
        });
        expect(find.text(feuille.seront(n: 2)), findsOneWidget);
        expect(find.text(feuille.neSeront(n: 1)), findsOneWidget);
        // L'exclue, avec sa raison.
        expect(
          find.descendant(
            of: find.byKey(FeuilleLot.cleExclus),
            matching: find.textContaining('Emna Gharbi'),
          ),
          findsOneWidget,
        );
        expect(find.text(feuille.raisons.dejaEnPause), findsOneWidget);
        // Rien n'est ecrit : aucun lot, aucun geste.
        expect(port.appelsLot, isEmpty);
        expect(port.appelsGeste, isEmpty);
      },
    );

    testWidgets('une exclusion pour l\'etat nomme l\'etat, jamais un code', (
      tester,
    ) async {
      await _monter(tester);
      await _cocher(tester, <String>['a1', 'f6']);
      await _ouvrirFeuille(tester, GesteLot.mettreEnPause);
      expect(
        find.text(
          feuille.raisons.etat(etat: t.admin.candidatures.etats.refusee),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('transition_interdite'), findsNothing);
    });

    testWidgets(
      'aucune candidature eligible : pas de bouton qui ne peut pas aboutir',
      (tester) async {
        await _monter(tester);
        await _cocher(tester, <String>['f6']);
        await _ouvrirFeuille(tester, GesteLot.mettreEnPause);
        expect(find.text(feuille.seront(n: 0)), findsOneWidget);
        expect(find.byKey(FeuilleLot.cleValider), findsNothing);
        expect(find.byKey(FeuilleLot.cleNombre), findsNothing);
        expect(find.byKey(FeuilleLot.cleAnnuler), findsOneWidget);
      },
    );

    testWidgets('un seul bouton plein dans la feuille', (tester) async {
      await _monter(tester);
      await _cocher(tester, <String>['a1', 'b2']);
      await _ouvrirFeuille(tester, GesteLot.mettreEnPause);
      verifierUnSeulBoutonPlein(tester);
    });
  });

  group('ce que le geste exige', () {
    testWidgets('sans motif, sans message, sans le bon nombre : rien ne part', (
      tester,
    ) async {
      final FauxCandidaturesDirection port = await _monter(tester);
      await _cocher(tester, <String>['a1', 'b2']);
      await _ouvrirFeuille(tester, GesteLot.mettreEnPause);
      await _valider(tester);
      expect(port.appelsLot, isEmpty);
      expect(
        find.text(t.admin.candidatures.feuille.motifManquant),
        findsWidgets,
      );
      // Le motif et le message, mais le mauvais nombre.
      await _remplir(tester, nombre: '5');
      await _valider(tester);
      expect(port.appelsLot, isEmpty);
      expect(find.text(feuille.nombreFaux(n: 2)), findsOneWidget);
    });

    testWidgets(
      'le nombre est une saisie : jamais ecrit a la place de la direction',
      (tester) async {
        await _monter(tester);
        await _cocher(tester, <String>['a1', 'b2']);
        await _ouvrirFeuille(tester, GesteLot.mettreEnPause);
        final TextField champ = tester.widget<TextField>(
          find.descendant(
            of: find.byKey(FeuilleLot.cleNombre),
            matching: find.byType(TextField),
          ),
        );
        expect(champ.controller!.text, isEmpty);
        expect(find.text(feuille.nombreAide(n: 2)), findsOneWidget);
      },
    );

    testWidgets('lever la pause n\'exige ni motif ni message', (tester) async {
      final FauxCandidaturesDirection port = await _monter(tester);
      await _cocher(tester, <String>['e5']);
      await _ouvrirFeuille(tester, GesteLot.leverPause);
      expect(find.byKey(FeuilleLot.cleMotif), findsNothing);
      await tester.enterText(find.byKey(FeuilleLot.cleNombre), '1');
      await tester.pump();
      await _valider(tester);
      expect(port.appelsLot.single.geste, GesteLot.leverPause);
      expect(port.appelsLot.single.motif, isNull);
      expect(port.appelsLot.single.modele, isNull);
    });
  });

  group('l\'execution et le rapport', () {
    testWidgets(
      'part avec le jeton de l\'apercu, le nombre saisi et une cle ; le rapport dit tout',
      (tester) async {
        final FauxCandidaturesDirection port = await _monter(
          tester,
          refusParLigne: <String, String>{'b2': 'conflit_candidature'},
        );
        await _cocher(tester, <String>['a1', 'b2', 'e5']);
        final int lectures = port.appels.length;
        await _ouvrirFeuille(tester, GesteLot.mettreEnPause);
        await _remplir(tester, nombre: '2');
        await _valider(tester);
        // Ce qui est parti.
        expect(port.appelsLot, hasLength(1));
        final DemandeLot d = port.appelsLot.single;
        expect(d.geste, GesteLot.mettreEnPause);
        expect(d.ids.toSet(), <String>{'a1', 'b2', 'e5'});
        expect(d.nombreConfirme, 2);
        expect(d.motif, 'Attente des pieces.');
        expect(d.modele, 'pause_general');
        expect(d.cleIdempotence, startsWith('cand-'));
        expect(d.jeton, hasLength(32));
        // Le rapport, ligne par ligne : une reussie, une exclue, une refusee.
        final p = feuille.rapport;
        Finder dansRapport(String texte) => find.descendant(
          of: find.byKey(FeuilleLot.cleRapport),
          matching: find.text(texte),
        );
        expect(find.byKey(FeuilleLot.cleRapport), findsOneWidget);
        expect(dansRapport(p.reussies(n: 1)), findsOneWidget);
        expect(dansRapport(p.exclues(n: 1)), findsOneWidget);
        expect(dansRapport(p.refusees(n: 1)), findsOneWidget);
        expect(
          find.text(
            p.ligneEtRaison(
              statut: p.ligneRefusee,
              raison: feuille.raisons.conflit,
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            p.ligneEtRaison(
              statut: p.ligneExclue,
              raison: feuille.raisons.dejaEnPause,
            ),
          ),
          findsOneWidget,
        );
        expect(find.text(p.ligneReussie), findsOneWidget);
        // La liste se relit, la selection est videe.
        expect(port.appels.length, greaterThan(lectures));
        await tester.tap(find.byKey(FeuilleLot.cleTerminer));
        await laisser(tester, fois: 12);
        expect(find.byKey(FeuilleLot.cle), findsNothing);
        expect(find.byKey(CandidaturesPage.cleBarreLot), findsNothing);
        expect(find.text(p.reussies(n: 1)), findsOneWidget);
      },
    );

    testWidgets('la liste relue montre l\'etat apres le lot', (tester) async {
      await _monter(tester);
      await _cocher(tester, <String>['a1']);
      await _ouvrirFeuille(tester, GesteLot.mettreEnPause);
      await _remplir(tester, nombre: '1');
      await _valider(tester);
      await tester.tap(find.byKey(FeuilleLot.cleTerminer));
      await laisser(tester, fois: 12);
      // « En pause » : celle d'Emna et celle d'Amina.
      expect(find.text(t.admin.candidatures.etats.enPause), findsNWidgets(2));
    });

    testWidgets('refuser : bouton d\'alerte, jamais un fond plein rouge', (
      tester,
    ) async {
      final FauxCandidaturesDirection port = await _monter(tester);
      await _cocher(tester, <String>['a1']);
      await _ouvrirFeuille(tester, GesteLot.refuser);
      final ActionPrincipale bouton = tester.widget<ActionPrincipale>(
        find.byKey(FeuilleLot.cleValider),
      );
      expect(bouton.niveau, NiveauAction.destructive);
      expect(bouton.libelle, lot.refuser);
      expect(port.appelsLot, isEmpty);
    });

    testWidgets(
      '« non confirme » garde la cle : « Reessayer » rejoue le meme lot, rien d\'ecrit deux fois',
      (tester) async {
        final FauxCandidaturesDirection port = FauxCandidaturesDirection(
          lignes: _lignes(),
          capacitesRendues: capacitesGestes,
          // Le lot arrive au serveur et s'ecrit ; seule la reponse est perdue.
          perteApresEcriture: true,
          erreurLot: (DemandeLot _, int essai) =>
              essai == 1 ? const GesteNonConfirme() : null,
        );
        await monterCandidatures(tester, port: port, hauteur: 3000);
        await _cocher(tester, <String>['a1', 'b2']);
        await _ouvrirFeuille(tester, GesteLot.mettreEnPause);
        await _remplir(tester, nombre: '2');
        await _valider(tester);
        // Rien n'est dit reussi : le serveur n'a pas repondu.
        expect(find.byKey(FeuilleLot.cleRapport), findsNothing);
        expect(
          find.text(t.admin.candidatures.erreurs.nonConfirme),
          findsOneWidget,
        );
        final Finder reessayer = find.byKey(FeuilleLot.cleValider);
        expect(
          find.descendant(
            of: reessayer,
            matching: find.text(t.commun.reessayer),
          ),
          findsOneWidget,
        );
        await _valider(tester);
        // La meme cle, les memes identifiants : le serveur rend le premier rapport.
        expect(port.appelsLot, hasLength(2));
        expect(
          port.appelsLot[1].cleIdempotence,
          port.appelsLot[0].cleIdempotence,
        );
        expect(port.appelsLot[1].ids, port.appelsLot[0].ids);
        expect(find.byKey(FeuilleLot.cleRapport), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(FeuilleLot.cleRapport),
            matching: find.text(feuille.rapport.rejoue),
          ),
          findsOneWidget,
        );
        // Deux candidatures en pause en plus d'Emna : ecrites une seule fois.
        expect(
          port.lignes.where((LigneCandidature l) => l.enPause),
          hasLength(3),
        );
      },
    );

    testWidgets(
      'changer un champ apres un « non confirme » prend une cle neuve',
      (tester) async {
        final FauxCandidaturesDirection port = FauxCandidaturesDirection(
          lignes: _lignes(),
          capacitesRendues: capacitesGestes,
          erreurLot: (DemandeLot _, int essai) =>
              essai == 1 ? const GesteNonConfirme() : null,
        );
        await monterCandidatures(tester, port: port, hauteur: 3000);
        await _cocher(tester, <String>['a1', 'b2']);
        await _ouvrirFeuille(tester, GesteLot.mettreEnPause);
        await _remplir(tester, nombre: '2');
        await _valider(tester);
        await tester.enterText(
          find.byKey(FeuilleLot.cleMotif),
          'Un autre motif.',
        );
        await tester.pump();
        await _valider(tester);
        expect(port.appelsLot, hasLength(2));
        expect(
          port.appelsLot[1].cleIdempotence,
          isNot(port.appelsLot[0].cleIdempotence),
        );
      },
    );

    testWidgets(
      'jeton perime : rien d\'ecrit, un nouvel apercu, une cle neuve',
      (tester) async {
        final FauxCandidaturesDirection port = await _monter(tester);
        await _cocher(tester, <String>['a1', 'b2']);
        await _ouvrirFeuille(tester, GesteLot.mettreEnPause);
        await _remplir(tester, nombre: '2');
        // Entre l'apercu et l'execution, une candidature du lot change.
        final int i = port.lignes.indexWhere(
          (LigneCandidature l) => l.id == 'b2',
        );
        port.lignes[i] = ligneTest(
          id: 'b2',
          nom: 'Bilal Haddad',
          enPause: true,
        );
        await _valider(tester);
        expect(
          find.text(t.admin.candidatures.lot.erreurs.jetonPerime),
          findsOneWidget,
        );
        expect(find.byKey(FeuilleLot.cleRapport), findsNothing);
        expect(
          port.lignes
              .where((LigneCandidature l) => l.enPause)
              .map((LigneCandidature l) => l.id),
          <String>['b2', 'e5'],
          reason: 'rien n\'a ete ecrit',
        );
        // Un nouvel apercu : un seul eligible, une autre vue.
        await tester.tap(find.byKey(FeuilleLot.cleActualiser));
        await laisser(tester, fois: 12);
        expect(port.appelsApercuLot, hasLength(2));
        expect(find.text(feuille.seront(n: 1)), findsOneWidget);
      },
    );

    testWidgets('l\'apercu illisible : un message, aucun bouton', (
      tester,
    ) async {
      final FauxCandidaturesDirection port = FauxCandidaturesDirection(
        lignes: _lignes(),
        capacitesRendues: capacitesGestes,
      );
      await monterCandidatures(tester, port: port, hauteur: 3000);
      await _cocher(tester, <String>['a1']);
      // Un id que le serveur ne connait plus : exclu comme « absente ».
      port.lignes.removeWhere((LigneCandidature l) => l.id == 'a1');
      await _ouvrirFeuille(tester, GesteLot.mettreEnPause);
      expect(find.text(feuille.raisons.absente), findsOneWidget);
      expect(find.byKey(FeuilleLot.cleValider), findsNothing);
    });
  });
}
