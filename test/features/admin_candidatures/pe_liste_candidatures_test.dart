// PE-LISTE-CANDIDATURES (PE-C4, 20/11/2026) : la liste traitee par groupes.
//
// Ce que le test prouve (sur le double du port, donnees fictives) :
// - « Selectionner la page », puis « Selectionner les N resultats » avec le
//   nombre exact rendu par le serveur ; la selection suit l'ordre de la liste ;
// - au-dela du plafond du serveur, les gestes restent offerts et le lot part
//   avec les 200 premieres ;
// - un filtre qui change retire la selection de tous les resultats ;
// - les gestes groupes neufs : l'apercu dit qui ne sera pas concerne et
//   pourquoi ; « Ecrire » exige son message ; le complement exige son element
//   et part avec lui ;
// - le tri par anciennete est envoye au serveur et inscrit dans l'adresse.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/gestes_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';
import 'package:rewayah_academy/core/candidature/modeles_lot_candidatures.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/admin_candidatures/adresse_candidatures.dart';
import 'package:rewayah_academy/features/admin_candidatures/candidatures_page.dart';
import 'package:rewayah_academy/features/admin_candidatures/feuille_filtres.dart';
import 'package:rewayah_academy/features/admin_candidatures/lot_candidatures.dart';

import '../../fixtures/candidature/faux_candidatures_direction.dart';
import '../../support/monter_recrutement.dart';
import 'hote_candidatures.dart';

final DateTime _base = DateTime.utc(2026, 11, 20, 8);

List<LigneCandidature> _lignes(int n) => <LigneCandidature>[
  for (int i = 0; i < n; i++)
    ligneTest(
      id: 'p$i',
      reference: 'CAND-${10000 + i}',
      nom: 'Fictif $i',
      derniereActivite: _base.subtract(Duration(hours: i)),
    ),
];

Future<FauxCandidaturesDirection> _monter(WidgetTester tester, int n) async {
  final FauxCandidaturesDirection port = FauxCandidaturesDirection(
    lignes: _lignes(n),
    capacitesRendues: capacitesGestes,
  );
  await monterCandidatures(tester, port: port, largeur: 1440, hauteur: 6000);
  return port;
}

Future<void> _toutRetenir(WidgetTester tester) async {
  await tester.tap(
    find.byKey(const ValueKey<String>('candidatures-selectionner')),
  );
  await laisser(tester);
  await tester.tap(
    find.byKey(const ValueKey<String>('candidatures-selection-page')),
  );
  await laisser(tester);
  await tester.tap(
    find.byKey(const ValueKey<String>('candidatures-selection-tous')),
  );
  await laisser(tester);
}

Future<void> _ouvrirLot(WidgetTester tester, GesteLot geste) async {
  final Finder op = find.byKey(CandidaturesPage.cleOperationLot(geste));
  await tester.ensureVisible(op);
  await tester.tap(op);
  await laisser(tester);
}

void main() {
  final s = t.admin.candidatures.selection;
  final l = t.admin.candidatures.lot;

  group('Selectionner les N resultats', () {
    testWidgets('la page, puis tous les resultats avec le nombre du serveur', (
      WidgetTester tester,
    ) async {
      final FauxCandidaturesDirection port = await _monter(tester, 120);
      await tester.tap(
        find.byKey(const ValueKey<String>('candidatures-selectionner')),
      );
      await laisser(tester);
      await tester.tap(
        find.byKey(const ValueKey<String>('candidatures-selection-page')),
      );
      await laisser(tester);
      expect(find.text(s.pageRetenue(n: 50)), findsOneWidget);
      expect(find.text(s.tous(n: 120)), findsOneWidget);
      expect(port.appelsSelection, isEmpty, reason: 'rien n est lu avant');
      await tester.tap(
        find.byKey(const ValueKey<String>('candidatures-selection-tous')),
      );
      await laisser(tester);
      expect(port.appelsSelection, hasLength(1));
      expect(find.text(s.tousRetenus(n: 120)), findsOneWidget);
      expect(find.text(l.selectionnees(n: 120)), findsNothing);
      expect(
        find.textContaining(l.dontPage(n: 50)),
        findsOneWidget,
        reason: 'la barre dit 120 retenues, dont 50 sur cette page',
      );
    });

    testWidgets('au-dela du plafond : les gestes restent, le lot porte sur '
        'les 200 premieres dans l ordre de la liste', (
      WidgetTester tester,
    ) async {
      final FauxCandidaturesDirection port = await _monter(tester, 260);
      await _toutRetenir(tester);
      expect(find.text(l.parTranche(n: 200, reste: 60)), findsOneWidget);
      await _ouvrirLot(tester, GesteLot.ecrire);
      expect(find.byType(FeuilleLot), findsOneWidget);
      final List<String> ids = port.appelsApercuLot.single.ids;
      expect(ids, hasLength(200));
      expect(ids.first, 'p0');
      expect(ids.last, 'p199');
    });

    testWidgets('un filtre qui change retire la selection de tous', (
      WidgetTester tester,
    ) async {
      await _monter(tester, 120);
      await _toutRetenir(tester);
      expect(find.text(s.tousRetenus(n: 120)), findsOneWidget);
      await tester.tap(find.byKey(CandidaturesPage.cleFiltres));
      await laisser(tester);
      await tester.tap(
        find.byKey(const ValueKey<String>('feuille-filtre-complet')),
      );
      await laisser(tester);
      await tester.tap(
        find.text(t.admin.candidatures.filtres.dossierComplet).last,
      );
      await laisser(tester);
      expect(find.text(s.tousRetenus(n: 120)), findsNothing);
    });
  });

  group('Gestes groupes neufs', () {
    testWidgets('ecrire : sans compte et en pause exclus, en le disant ; '
        'le message est exige', (WidgetTester tester) async {
      final FauxCandidaturesDirection port = await _monter(tester, 4)
        ..sansCompte.add('p1');
      await tester.tap(
        find.byKey(const ValueKey<String>('candidatures-selectionner')),
      );
      await laisser(tester);
      await tester.tap(
        find.byKey(const ValueKey<String>('candidatures-selection-page')),
      );
      await laisser(tester);
      await _ouvrirLot(tester, GesteLot.ecrire);
      expect(find.text(l.feuille.raisons.sansCompte), findsOneWidget);
      expect(find.text(l.feuille.message), findsOneWidget);
      await tester.enterText(find.byKey(FeuilleLot.cleNombre), '3');
      final Finder valider = find.byKey(FeuilleLot.cleValider);
      await tester.ensureVisible(valider);
      await tester.tap(valider);
      await laisser(tester);
      expect(find.text(l.feuille.messageManquant), findsOneWidget);
      expect(port.appelsLot, isEmpty, reason: 'rien ne part sans message');
    });

    testWidgets('admettre : un controle faux exclut, nomme', (
      WidgetTester tester,
    ) async {
      final FauxCandidaturesDirection port = await _monter(tester, 3)
        ..controlesAdmissionFaux['p2'] = 'cadre_religieux';
      await tester.tap(
        find.byKey(const ValueKey<String>('candidatures-selectionner')),
      );
      await laisser(tester);
      await tester.tap(
        find.byKey(const ValueKey<String>('candidatures-selection-page')),
      );
      await laisser(tester);
      await _ouvrirLot(tester, GesteLot.admettre);
      expect(
        find.textContaining(
          l.feuille.raisons.controle(controle: '').split('«').first,
        ),
        findsOneWidget,
      );
      expect(port.appelsApercuLot.single.geste, GesteLot.admettre);
    });

    testWidgets('demander un complement : l element est exige et part dans '
        'le modele', (WidgetTester tester) async {
      final FauxCandidaturesDirection port = await _monter(tester, 2);
      await tester.tap(
        find.byKey(const ValueKey<String>('candidatures-selectionner')),
      );
      await laisser(tester);
      await tester.tap(
        find.byKey(const ValueKey<String>('candidatures-selection-page')),
      );
      await laisser(tester);
      await _ouvrirLot(tester, GesteLot.demanderComplement);
      await tester.enterText(find.byKey(FeuilleLot.cleMotif), 'Merci.');
      await tester.enterText(find.byKey(FeuilleLot.cleNombre), '2');
      final Finder valider = find.byKey(FeuilleLot.cleValider);
      await tester.ensureVisible(valider);
      await tester.tap(valider);
      await laisser(tester);
      expect(find.text(l.feuille.elementManquant), findsOneWidget);
      expect(port.appelsLot, isEmpty);
      final Finder photo = find.byKey(const ValueKey<String>('element-photo'));
      await tester.ensureVisible(photo);
      await tester.tap(photo);
      await laisser(tester);
      await tester.ensureVisible(valider);
      await tester.tap(valider);
      await laisser(tester);
      expect(port.appelsLot.single.modele, 'photo');
      expect(port.appelsLot.single.motif, 'Merci.');
      expect(port.appelsLot.single.geste, GesteLot.demanderComplement);
    });
  });

  group('Apres un lot', () {
    testWidgets('au-dela de 200 : les reussies sortent, les suivantes puis '
        'les exclues restent retenues', (WidgetTester tester) async {
      final FauxCandidaturesDirection port = await _monter(tester, 260)
        ..sansCompte.add('p1');
      await _toutRetenir(tester);
      await _ouvrirLot(tester, GesteLot.ecrire);
      await tester.enterText(find.byKey(FeuilleLot.cleMotif), 'Bonjour.');
      await tester.enterText(find.byKey(FeuilleLot.cleNombre), '199');
      final Finder valider = find.byKey(FeuilleLot.cleValider);
      await tester.ensureVisible(valider);
      await tester.tap(valider);
      await laisser(tester);
      expect(port.appelsLot.single.ids, hasLength(200));
      final Finder terminer = find.byKey(FeuilleLot.cleTerminer);
      await tester.ensureVisible(terminer);
      await tester.tap(terminer);
      await laisser(tester);
      // 199 reussies sortent ; restent les 60 au-dela de 200, puis p1
      // (exclue), passee en fin d'ordre (seconde relecture, R2).
      expect(find.textContaining(l.selectionnees(n: 61)), findsOneWidget);
      await _ouvrirLot(tester, GesteLot.ecrire);
      final List<String> second = port.appelsApercuLot.last.ids;
      expect(second, hasLength(61));
      expect(second.first, 'p200');
      expect(second.last, 'p1');
      expect(second, contains('p200'));
      expect(second, isNot(contains('p0')));
    });

    testWidgets(
      'une panne incertaine garde la cle, meme si le message change',
      (WidgetTester tester) async {
        final FauxCandidaturesDirection port = await _monter(tester, 2)
          ..erreurLot = (DemandeLot d, int essai) =>
              essai == 1 ? const GesteNonConfirme() : null;
        await tester.tap(
          find.byKey(const ValueKey<String>('candidatures-selectionner')),
        );
        await laisser(tester);
        await tester.tap(
          find.byKey(const ValueKey<String>('candidatures-selection-page')),
        );
        await laisser(tester);
        await _ouvrirLot(tester, GesteLot.ecrire);
        await tester.enterText(find.byKey(FeuilleLot.cleMotif), 'Bonjour.');
        await tester.enterText(find.byKey(FeuilleLot.cleNombre), '2');
        final Finder valider = find.byKey(FeuilleLot.cleValider);
        await tester.ensureVisible(valider);
        await tester.tap(valider);
        await laisser(tester);
        await tester.enterText(find.byKey(FeuilleLot.cleMotif), 'Bonjour !');
        await tester.ensureVisible(valider);
        await tester.tap(valider);
        await laisser(tester);
        expect(port.appelsLot, hasLength(2));
        expect(
          port.appelsLot[1].cleIdempotence,
          port.appelsLot[0].cleIdempotence,
          reason: 'le lot a pu partir : jamais une seconde cle',
        );
      },
    );

    testWidgets(
      'R4 : la cle refusee apres une panne incertaine dit que le premier '
      'envoi est peut-etre parti, et invite a verifier les conversations',
      (WidgetTester tester) async {
        final FauxCandidaturesDirection port = await _monter(tester, 2)
          ..erreurLot = (DemandeLot d, int essai) =>
              essai == 1 ? const GesteNonConfirme() : const CleLotReutilisee();
        await tester.tap(
          find.byKey(const ValueKey<String>('candidatures-selectionner')),
        );
        await laisser(tester);
        await tester.tap(
          find.byKey(const ValueKey<String>('candidatures-selection-page')),
        );
        await laisser(tester);
        await _ouvrirLot(tester, GesteLot.ecrire);
        await tester.enterText(find.byKey(FeuilleLot.cleMotif), 'Bonjour.');
        await tester.enterText(find.byKey(FeuilleLot.cleNombre), '2');
        final Finder valider = find.byKey(FeuilleLot.cleValider);
        await tester.ensureVisible(valider);
        await tester.tap(valider);
        await laisser(tester);
        await tester.enterText(find.byKey(FeuilleLot.cleMotif), 'Bonjour !');
        await tester.ensureVisible(valider);
        await tester.tap(valider);
        await laisser(tester);
        expect(port.appelsLot, hasLength(2));
        expect(find.text(l.erreurs.cleReutiliseeEcrire), findsOneWidget);
        expect(find.text(l.erreurs.cleReutilisee), findsNothing);
      },
    );

    testWidgets(
      'R4 : sans panne incertaine, la cle refusee garde sa phrase d avant',
      (WidgetTester tester) async {
        await _monter(tester, 2).then(
          (FauxCandidaturesDirection p) =>
              p.erreurLot = (DemandeLot d, int essai) =>
                  const CleLotReutilisee(),
        );
        await tester.tap(
          find.byKey(const ValueKey<String>('candidatures-selectionner')),
        );
        await laisser(tester);
        await tester.tap(
          find.byKey(const ValueKey<String>('candidatures-selection-page')),
        );
        await laisser(tester);
        await _ouvrirLot(tester, GesteLot.ecrire);
        await tester.enterText(find.byKey(FeuilleLot.cleMotif), 'Bonjour.');
        await tester.enterText(find.byKey(FeuilleLot.cleNombre), '2');
        final Finder valider = find.byKey(FeuilleLot.cleValider);
        await tester.ensureVisible(valider);
        await tester.tap(valider);
        await laisser(tester);
        expect(find.text(l.erreurs.cleReutilisee), findsOneWidget);
        expect(find.text(l.erreurs.cleReutiliseeEcrire), findsNothing);
      },
    );

    testWidgets(
      'R2 : 450 retenues dont les 200 premieres ne peuvent pas recevoir le '
      'geste : elles passent en fin, le second apercu porte sur les suivantes',
      (WidgetTester tester) async {
        final FauxCandidaturesDirection port = await _monter(tester, 450);
        for (int i = 0; i < 200; i++) {
          port.sansCompte.add('p$i');
        }
        await _toutRetenir(tester);
        await _ouvrirLot(tester, GesteLot.ecrire);
        final List<String> premier = port.appelsApercuLot.last.ids;
        expect(premier.first, 'p0');
        expect(premier.last, 'p199');
        expect(find.text(l.feuille.reporteesEnFin), findsOneWidget);
        final Finder annuler = find.byKey(FeuilleLot.cleAnnuler);
        await tester.ensureVisible(annuler);
        await tester.tap(annuler);
        await laisser(tester);
        expect(find.textContaining(l.selectionnees(n: 450)), findsOneWidget);
        await _ouvrirLot(tester, GesteLot.ecrire);
        final List<String> second = port.appelsApercuLot.last.ids;
        expect(second, hasLength(200));
        expect(second.first, 'p200');
        expect(second.toSet().intersection(premier.toSet()), isEmpty);
      },
    );

    testWidgets(
      'R2 : apres un rapport, les exclues passent en fin ; le lot suivant '
      'porte sur des dossiers non encore tentes',
      (WidgetTester tester) async {
        final FauxCandidaturesDirection port = await _monter(tester, 450);
        // Une seule eligible parmi les 200 premieres : p0.
        for (int i = 1; i < 200; i++) {
          port.sansCompte.add('p$i');
        }
        await _toutRetenir(tester);
        await _ouvrirLot(tester, GesteLot.ecrire);
        await tester.enterText(find.byKey(FeuilleLot.cleMotif), 'Bonjour.');
        await tester.enterText(find.byKey(FeuilleLot.cleNombre), '1');
        final Finder valider = find.byKey(FeuilleLot.cleValider);
        await tester.ensureVisible(valider);
        await tester.tap(valider);
        await laisser(tester);
        final List<String> premier = port.appelsLot.single.ids;
        final Finder terminer = find.byKey(FeuilleLot.cleTerminer);
        await tester.ensureVisible(terminer);
        await tester.tap(terminer);
        await laisser(tester);
        // p0 sort ; les 199 exclues restent, apres les 250 non tentees.
        expect(find.textContaining(l.selectionnees(n: 449)), findsOneWidget);
        await _ouvrirLot(tester, GesteLot.ecrire);
        final List<String> second = port.appelsApercuLot.last.ids;
        expect(second, hasLength(200));
        expect(second.first, 'p200');
        expect(second.toSet().intersection(premier.toSet()), isEmpty);
      },
    );

    testWidgets('complement : seuls les elements acceptes par toutes les '
        'candidatures retenues sont proposes', (WidgetTester tester) async {
      final FauxCandidaturesDirection port = FauxCandidaturesDirection(
        lignes: <LigneCandidature>[
          ligneTest(id: 'x1', nom: 'Examen Fictif'),
          ligneTest(
            id: 'x2',
            nom: 'Verification Fictive',
            etape: EtapeCandidature.verifications,
            etat: EtatCandidature.entretienAPlanifier,
          ),
        ],
        capacitesRendues: capacitesGestes,
      );
      await monterCandidatures(
        tester,
        port: port,
        largeur: 1440,
        hauteur: 6000,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('candidatures-selectionner')),
      );
      await laisser(tester);
      await tester.tap(
        find.byKey(const ValueKey<String>('candidatures-selection-page')),
      );
      await laisser(tester);
      await _ouvrirLot(tester, GesteLot.demanderComplement);
      expect(
        find.byKey(const ValueKey<String>('element-contrat')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('element-langues')),
        findsNothing,
      );
    });
  });

  group('Tri par anciennete', () {
    test('l adresse porte le tri et les trois filtres neufs', () {
      const RequeteCandidatures r = RequeteCandidatures(
        filtre: FiltreCandidatures(
          dossierComplet: true,
          pilePraxis: 'pret_a_decider',
          etiquettePraxis: 'pepite',
        ),
        tri: TriCandidatures.ancienne,
      );
      final Map<String, String> a = requeteEnAdresse(r);
      expect(a, <String, String>{
        'complet': 'oui',
        'pile': 'pret_a_decider',
        'etiquette': 'pepite',
        'tri': 'ancienne',
      });
      expect(requeteDepuisAdresse(a), r);
      // Une valeur inconnue est ignoree.
      expect(
        requeteDepuisAdresse(<String, String>{'pile': 'pepite'})
            .filtre
            .pilePraxis,
        isNull,
      );
    });

    testWidgets('« Attente la plus longue » part au serveur', (
      WidgetTester tester,
    ) async {
      final FauxCandidaturesDirection port = await _monter(tester, 3);
      await tester.tap(find.byKey(CandidaturesPage.cleTri));
      await laisser(tester);
      await tester.tap(find.byKey(FeuilleTri.cle(TriCandidatures.ancienne)));
      await laisser(tester);
      expect(port.appels.last.tri, TriCandidatures.ancienne);
    });
  });
}
