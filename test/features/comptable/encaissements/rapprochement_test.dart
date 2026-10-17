// CPT-ENC-2 : `ReconciliationWorkspace`, doublon potentiel, remboursements
// et avoirs (spec §25, §26, §47, §48 ; CPT-BR-14, 15, 17).
//
// - six etats §25 en filtres, compteurs de lignes ;
// - correspondances proposees, « Rapprocher » selon la permission rendue,
//   raison de blocage rendue sinon (DR-19) ; l'etat affiche apres ecriture
//   est celui de la source (§5.3) ;
// - doublon potentiel jamais silencieux (§47) ;
// - cle d'idempotence rejouee apres un echec ;
// - remboursements : vus, executes selon la politique, jamais reecrite ;
// - journal par operation (§48) ;
// - etats, montants masques, 320 texte x2, sombre, RTL.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_encaissements.dart';
import 'package:rewayah_academy/core/capacites/port_rapprochement.dart';
import 'package:rewayah_academy/core/comptable/statuts_comptable.dart';
import 'package:rewayah_academy/core/finance/format_montant.dart';
import 'package:rewayah_academy/core/finance/montant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/bandeau_attention.dart';
import 'package:rewayah_academy/core/widgets/empty_state.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/montant_sensible.dart';
import 'package:rewayah_academy/core/widgets/pastilles_comptable.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/comptable/encaissements/rapprochement/espace_rapprochement.dart';
import 'package:rewayah_academy/features/comptable/encaissements/rapprochement/feuille_remboursement.dart';
import 'package:rewayah_academy/features/comptable/encaissements/rapprochement/panneau_rapprochement.dart';
import 'package:rewayah_academy/features/comptable/encaissements/rapprochement/remboursements_avoirs.dart';
import 'package:rewayah_academy/features/demo/comptable/encaissements_demo.dart';

import '../../../support/rangee_plus.dart';
import 'support_encaissements.dart';

/// Un port de rapprochement qui retient les cles et peut echouer une fois.
class _Espion extends RapprochementDemo {
  _Espion({this.echecs = 0, this.liste, this.erreurListe, this.attente});

  int echecs;
  final List<ElementRapprochement>? liste;
  final Object? erreurListe;
  final Completer<List<ElementRapprochement>>? attente;
  final List<String> cles = <String>[];
  int lectures = 0;

  @override
  Future<List<ElementRapprochement>> aRapprocher(FiltreRapprochement filtre) {
    lectures++;
    final Completer<List<ElementRapprochement>>? a = attente;
    if (a != null) return a.future;
    final Object? e = erreurListe;
    if (e != null) return Future<List<ElementRapprochement>>.error(e);
    final List<ElementRapprochement>? l = liste;
    if (l != null) return Future<List<ElementRapprochement>>.value(l);
    return super.aRapprocher(filtre);
  }

  @override
  Future<ElementRapprochement> rapprocher({
    required String transactionId,
    required String cibleId,
    required String cleIdempotence,
  }) {
    cles.add(cleIdempotence);
    if (echecs > 0) {
      echecs--;
      return Future<ElementRapprochement>.error(StateError('coupure'));
    }
    return super.rapprocher(
      transactionId: transactionId,
      cibleId: cibleId,
      cleIdempotence: cleIdempotence,
    );
  }
}

/// Un port d'encaissements qui compte les executions.
class _EncEspion extends EncaissementsDemo {
  final List<String> cles = <String>[];

  @override
  Future<Remboursement> executerRemboursement({
    required String remboursementId,
    required String cleIdempotence,
  }) {
    cles.add(cleIdempotence);
    return super.executerRemboursement(
      remboursementId: remboursementId,
      cleIdempotence: cleIdempotence,
    );
  }
}

List<Override> _demo({PortRapprochement? rap, PortEncaissements? enc}) =>
    <Override>[
      portRapprochementProvider.overrideWithValue(rap ?? RapprochementDemo()),
      portEncaissementsProvider.overrideWithValue(enc ?? EncaissementsDemo()),
    ];

int _compteur(WidgetTester tester, Key cle) => tester
    .widgetList<Text>(
      find.descendant(of: find.byKey(cle), matching: find.byType(Text)),
    )
    .map((Text x) => int.tryParse(x.data ?? ''))
    .whereType<int>()
    .single;

Future<void> _choisir(WidgetTester tester, String id) async {
  final Finder ligne = find.byKey(ReconciliationWorkspace.ligneKey(id));
  await tester.ensureVisible(ligne);
  await tester.tap(ligne);
  await tester.pumpAndSettle();
}

Future<void> _appuyer(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

const Size _bureau = Size(1440, 2000);

void main() {
  final r = t.comptable.encaissements.rap;

  group('a rapprocher : filtres §25 et panneau a 1440', () {
    testWidgets('six etats en filtres, compteurs de lignes, montants masques', (
      WidgetTester tester,
    ) async {
      await monterEncaissements(
        tester,
        Routes.comptableRapprochement,
        surcharges: _demo(),
        taille: _bureau,
      );
      expect(_compteur(tester, ReconciliationWorkspace.filtreKey(null)), 6);
      for (final EtatRapprochement e in EtatRapprochement.values) {
        expect(
          _compteur(tester, ReconciliationWorkspace.filtreKey(e)),
          1,
          reason: e.name,
        );
      }
      // « A rapprocher » : ce qui attend encore le Comptable.
      expect(
        _compteur(
          tester,
          ReconciliationWorkspace.vueKey(VueRapprochement.transactions),
        ),
        4,
      );
      expect(find.text(r.choisirTitre), findsOneWidget);
      expect(
        find.text(formaterMontant(const Montant(6000, 'USD'))),
        findsNothing,
      );
      expect(find.byType(MontantSensible), findsNWidgets(6));
      // Doublon jamais silencieux (§47) : sa pastille dans la liste.
      expect(
        find.descendant(
          of: find.byKey(
            ReconciliationWorkspace.ligneKey(
              DonneesEncaissementsDemo.trxDoublon,
            ),
          ),
          matching: find.text(
            t.comptable.statuts.rapprochement.doublonPotentiel,
          ),
        ),
        findsOneWidget,
      );
      // L4-07 : « Conflit » est rangee sous « Plus ».
      await toucherFiltre(
        tester,
        find.byKey(
          ReconciliationWorkspace.filtreKey(EtatRapprochement.conflit),
        ),
      );
      expect(find.text('Famille Touré · carte bancaire'), findsOneWidget);
      expect(find.text('Famille Bah · carte bancaire'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a verifier : la correspondance proposee, « Rapprocher », '
        'puis l etat rendu par la source', (WidgetTester tester) async {
      await monterEncaissements(
        tester,
        Routes.comptableRapprochement,
        surcharges: _demo(),
        taille: _bureau,
      );
      await _choisir(tester, DonneesEncaissementsDemo.trxAVerifier);
      final Finder panneau = find.byKey(ReconciliationWorkspace.panneauKey);
      expect(panneau, findsOneWidget);
      expect(
        find.descendant(of: panneau, matching: find.text(r.candidats)),
        findsOneWidget,
      );
      expect(find.text('Mensualité d’octobre · Youssef'), findsOneWidget);
      await _appuyer(
        tester,
        find.byKey(PanneauRapprochement.rapprocherKey('att-diallo-10')),
      );
      expect(
        find.text(
          r.resultat(etat: t.comptable.statuts.rapprochement.rapproche),
        ),
        findsOneWidget,
      );
      // La liste relue : deux rapproches, plus de « Rapprocher ».
      expect(
        _compteur(
          tester,
          ReconciliationWorkspace.filtreKey(EtatRapprochement.rapproche),
        ),
        2,
      );
      expect(
        find.byKey(PanneauRapprochement.rapprocherKey('att-diallo-10')),
        findsNothing,
      );
      expect(
        find.text(r.relieA(libelle: 'Mensualité d’octobre · Youssef')),
        findsOneWidget,
      );
    });

    testWidgets('doublon potentiel : bandeau, « Marquer comme doublon », '
        'jamais efface', (WidgetTester tester) async {
      await monterEncaissements(
        tester,
        Routes.comptableRapprochement,
        surcharges: _demo(),
        taille: _bureau,
      );
      await _choisir(tester, DonneesEncaissementsDemo.trxDoublon);
      expect(
        find.descendant(
          of: find.byType(BandeauAttention),
          matching: find.text(r.doublonTitre),
        ),
        findsOneWidget,
      );
      expect(find.text(r.doublonPhrase), findsOneWidget);
      expect(find.byType(BandeauAttention), findsOneWidget);
      // Le journal de la source (§48).
      expect(
        find.text('Transaction reçue deux minutes après DEMO-7A1F'),
        findsOneWidget,
      );
      await _appuyer(tester, find.byKey(PanneauRapprochement.doublonKey));
      expect(
        find.text(
          r.resultat(etat: t.comptable.statuts.rapprochement.doublonPotentiel),
        ),
        findsOneWidget,
      );
      // Toujours la, marque, sans action.
      expect(
        find.byKey(
          ReconciliationWorkspace.ligneKey(DonneesEncaissementsDemo.trxDoublon),
        ),
        findsOneWidget,
      );
      expect(find.byKey(PanneauRapprochement.doublonKey), findsNothing);
    });

    testWidgets('hors delegation : aucun bouton, la raison rendue (DR-19)', (
      WidgetTester tester,
    ) async {
      await monterEncaissements(
        tester,
        Routes.comptableRapprochement,
        surcharges: _demo(),
        taille: _bureau,
      );
      await _choisir(tester, DonneesEncaissementsDemo.trxHorsDelegation);
      expect(
        find.text(libelleRaisonBlocage(RaisonBlocage.horsDelegation)),
        findsOneWidget,
      );
      expect(find.text(r.rapprocher), findsNothing);
      expect(find.text(r.candidatsAucun), findsOneWidget);
    });

    testWidgets('apres un echec, le nouvel appui rejoue la meme cle', (
      WidgetTester tester,
    ) async {
      final _Espion port = _Espion(echecs: 1);
      await monterEncaissements(
        tester,
        Routes.comptableRapprochement,
        surcharges: _demo(rap: port),
        taille: _bureau,
      );
      await _choisir(tester, DonneesEncaissementsDemo.trxAVerifier);
      final Finder bouton = find.byKey(
        PanneauRapprochement.rapprocherKey('att-diallo-10'),
      );
      await _appuyer(tester, bouton);
      expect(find.text(r.erreurEnvoi), findsOneWidget);
      // Aucun succes suppose.
      expect(
        find.text(
          r.resultat(etat: t.comptable.statuts.rapprochement.rapproche),
        ),
        findsNothing,
      );
      await _appuyer(tester, bouton);
      expect(port.cles, hasLength(2));
      expect(port.cles.first, port.cles.last);
      expect(
        find.text(
          r.resultat(etat: t.comptable.statuts.rapprochement.rapproche),
        ),
        findsOneWidget,
      );
    });
  });

  group('remboursements et avoirs (§26)', () {
    testWidgets('vus selon la politique ; executer passe par la confirmation '
        'et rend l etat de la source', (WidgetTester tester) async {
      final _EncEspion enc = _EncEspion();
      await monterEncaissements(
        tester,
        Routes.comptableRapprochement,
        surcharges: _demo(enc: enc),
        taille: _bureau,
      );
      await tester.tap(
        find.byKey(
          ReconciliationWorkspace.vueKey(VueRapprochement.remboursements),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(r.politiqueNote), findsOneWidget);
      expect(find.text('Famille Keita'), findsOneWidget);
      expect(find.text(r.approbationNon), findsOneWidget);
      expect(find.text(r.approbationRequise), findsOneWidget);
      // Le second attend une approbation : la raison, aucun bouton.
      expect(
        find.text(libelleRaisonBlocage(RaisonBlocage.validationRequise)),
        findsOneWidget,
      );
      expect(
        find.byKey(
          RemboursementsAvoirs.executerKey(
            DonneesEncaissementsDemo.rembAApprouver,
          ),
        ),
        findsNothing,
      );
      // Annuler : rien ne part.
      final Finder executer = find.byKey(
        RemboursementsAvoirs.executerKey(DonneesEncaissementsDemo.rembApprouve),
      );
      await _appuyer(tester, executer);
      expect(find.text(r.executerTitre), findsOneWidget);
      expect(find.text(r.executerPhrase), findsOneWidget);
      await tester.tap(find.text(t.commun.annuler));
      await tester.pumpAndSettle();
      expect(enc.cles, isEmpty);
      // Confirmer : l'etat rendu, « Approuve », jamais « Execute » suppose.
      await _appuyer(tester, executer);
      await tester.tap(find.byKey(confirmerRemboursementKey));
      await tester.pumpAndSettle();
      expect(enc.cles, hasLength(1));
      expect(
        find.text(r.resultat(etat: t.comptable.statuts.remboursement.approuve)),
        findsOneWidget,
      );
      expect(
        find.text(t.comptable.statuts.remboursement.execute),
        findsNothing,
      );
      expect(executer, findsNothing);
      // Le journal du remboursement (§48).
      expect(
        find.text('Remboursement accordé selon la politique'),
        findsOneWidget,
      );
      expect(find.text(r.journalRemboursementVide), findsOneWidget);
    });
  });

  group('sous 1200 : la feuille', () {
    testWidgets('390 : la ligne ouvre la feuille du detail', (
      WidgetTester tester,
    ) async {
      await monterEncaissements(
        tester,
        Routes.comptableRapprochement,
        surcharges: _demo(),
        taille: const Size(390, 844),
      );
      expect(find.text(r.choisirTitre), findsNothing);
      await _choisir(tester, DonneesEncaissementsDemo.trxDoublon);
      expect(find.text(r.doublonPhrase), findsOneWidget);
      expect(find.byKey(PanneauRapprochement.doublonKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('etats', () {
    testWidgets('production sans source : « en preparation »', (
      WidgetTester tester,
    ) async {
      await monterEncaissements(tester, Routes.comptableRapprochement);
      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text(t.comptable.commun.enPreparationTitre), findsOneWidget);
    });

    testWidgets('chargement : le squelette', (WidgetTester tester) async {
      await monterEncaissements(
        tester,
        Routes.comptableRapprochement,
        surcharges: _demo(
          rap: _Espion(attente: Completer<List<ElementRapprochement>>()),
        ),
        attendre: false,
      );
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(Skeleton), findsWidgets);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('vide : rien a rapprocher', (WidgetTester tester) async {
      await monterEncaissements(
        tester,
        Routes.comptableRapprochement,
        surcharges: _demo(rap: _Espion(liste: const <ElementRapprochement>[])),
      );
      expect(find.text(r.videTitre), findsOneWidget);
    });

    testWidgets('erreur : Reessayer relit', (WidgetTester tester) async {
      final _Espion port = _Espion(erreurListe: StateError('panne'));
      await monterEncaissements(
        tester,
        Routes.comptableRapprochement,
        surcharges: _demo(rap: port),
      );
      await tester.tap(
        find.text(EtatSysteme.libelleActionPar(NatureEtat.echecServeur)),
      );
      await tester.pumpAndSettle();
      expect(port.lectures, 2);
    });

    testWidgets('hors ligne : l echec se dit hors ligne', (
      WidgetTester tester,
    ) async {
      await monterEncaissements(
        tester,
        Routes.comptableRapprochement,
        surcharges: _demo(rap: _Espion(erreurListe: StateError('reseau'))),
        horsLigne: true,
      );
      expect(
        find.byWidgetPredicate(
          (Widget w) => w is EtatSysteme && w.nature == NatureEtat.horsLigne,
        ),
        findsOneWidget,
      );
    });
  });

  group('320 texte x2, sombre, RTL', () {
    for (final (
          String nom,
          Size taille,
          double echelle,
          Brightness l,
          TextDirection s,
        )
        cas
        in <(String, Size, double, Brightness, TextDirection)>[
          (
            '320 x2',
            const Size(320, 900),
            2,
            Brightness.light,
            TextDirection.ltr,
          ),
          (
            '390 sombre RTL',
            const Size(390, 844),
            1,
            Brightness.dark,
            TextDirection.rtl,
          ),
          (
            '1440 x2',
            const Size(1440, 900),
            2,
            Brightness.light,
            TextDirection.ltr,
          ),
          (
            '1440 sombre RTL',
            const Size(1440, 1600),
            1,
            Brightness.dark,
            TextDirection.rtl,
          ),
        ]) {
      testWidgets('les deux vues sans debordement : ${cas.$1}', (
        WidgetTester tester,
      ) async {
        await monterEncaissements(
          tester,
          Routes.comptableRapprochement,
          surcharges: _demo(),
          taille: cas.$2,
          echelle: cas.$3,
          luminosite: cas.$4,
          sens: cas.$5,
          montantsAffiches: true,
        );
        expect(tester.takeException(), isNull);
        if (cas.$2.width >= 1200 && cas.$3 == 1) {
          await _choisir(tester, DonneesEncaissementsDemo.trxDoublon);
          expect(tester.takeException(), isNull);
        }
        await _appuyer(
          tester,
          find.byKey(
            ReconciliationWorkspace.vueKey(VueRapprochement.remboursements),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(PastilleRemboursement), findsNWidgets(2));
      });
    }
  });
}
