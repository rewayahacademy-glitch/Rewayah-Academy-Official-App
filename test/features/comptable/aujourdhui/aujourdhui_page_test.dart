// CPT-JOUR : Aujourd'hui du Comptable (FIN-CPT-W01, M01 ecran 1 ; spec §29,
// §12, §28, §11). Ce que ces tests tiennent :
// - les neuf zones de §29 sur bureau, la Tresorerie libre au centre, la
//   Reserve en lecture, aucun « Disponible » ni « Reservee » (DR-07) ;
// - aucun bouton Payer (DR-11), aucun graphique (DR-09) ;
// - montants masques a l'entree (R-FIN-01) ;
// - « A traiter » et « Alertes » disjointes : chaque element de la file
//   apparait une seule fois (DR-10) ;
// - chaque ligne ouvre l'ecran canonique par sa route (spec §5.1) ;
// - telephone : une tache dominante, trois lignes et « Voir tout » ;
// - la file complete (`?vue=attention`) ;
// - les etats : chargement, contenu, vide, erreur, indisponible, hors
//   ligne ; 320 px texte x2 sans debordement ni mot coupe.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/port_aujourdhui_comptable.dart';
import 'package:rewayah_academy/core/comptable/modeles_comptable.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/finance/format_montant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/comptable/carte_reserve_strategique.dart';
import 'package:rewayah_academy/core/widgets/comptable/resume_tresorerie.dart';
import 'package:rewayah_academy/core/widgets/montant_argent.dart';
import 'package:rewayah_academy/core/widgets/montant_sensible.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/comptable/aujourdhui/aujourdhui_page.dart';
import 'package:rewayah_academy/features/demo/comptable/aujourdhui_demo.dart';
import 'package:rewayah_academy/features/demo/comptable/socle_comptable_demo.dart';

import '../../../router/support_routeur.dart';
import '../../../support/harnais.dart';
import '../../../support/mots_coupes.dart';

/// Un port d'essai : rend [valeur], ou jette [erreur], ou attend [attente].
class _Port implements PortAujourdhuiComptable {
  _Port({this.valeur, this.erreur, this.attente});

  final AujourdhuiComptable? valeur;
  final Object? erreur;
  final Completer<AujourdhuiComptable>? attente;

  @override
  Future<AujourdhuiComptable> aujourdhui() {
    final Completer<AujourdhuiComptable>? c = attente;
    if (c != null) return c.future;
    final Object? e = erreur;
    if (e != null) return Future<AujourdhuiComptable>.error(e);
    return Future<AujourdhuiComptable>.value(valeur);
  }

  @override
  Future<List<EntreeJournal>> journal(String objetId) async =>
      const <EntreeJournal>[];
}

const Size _bureau = Size(1440, 900);
const Size _telephone = Size(390, 844);
const Size _etroit = Size(320, 640);

void _taille(WidgetTester tester, Size taille, {double texte = 1}) {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = texte;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

/// Monte la page sur `/comptable` (ou [depart]) ; toute autre route rend
/// son adresse, pour verifier ou mene une ligne.
Future<void> _monter(
  WidgetTester tester, {
  PortAujourdhuiComptable port = const AujourdhuiComptableDemo(),
  String depart = Routes.comptable,
  bool horsLigne = false,
  bool stabiliserTout = true,
}) async {
  final List<Override> surcharges = <Override>[
    ...surchargesRouteur(
      FausseSourceSession(sessionActive(AppRole.accountant)),
    ),
    portAujourdhuiComptableProvider.overrideWithValue(port),
    horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(horsLigne)),
  ];
  await tester.pumpWidget(
    hoteRoutant(
      depart: depart,
      surcharges: surcharges,
      routes: <RouteBase>[
        GoRoute(
          path: Routes.comptable,
          builder: (BuildContext _, GoRouterState etat) =>
              AujourdhuiComptablePage(
                vue: etat.uri.queryParameters[Routes.parametreVueComptable],
              ),
        ),
        GoRoute(
          path: '/comptable/:reste(.*)',
          builder: (BuildContext _, GoRouterState etat) =>
              Scaffold(body: Text('ROUTE ${etat.uri}')),
        ),
      ],
    ),
  );
  if (stabiliserTout) await tester.pumpAndSettle();
}

/// Un element de la file de demonstration, par identifiant.
ElementAttention _element(String id) =>
    DonneesAujourdhuiDemo.file.firstWhere((ElementAttention e) => e.id == id);

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

void main() {
  final a = t.comptable.aujourdhui;

  group('bureau 1440', () {
    testWidgets('les neuf zones de §29, la Tresorerie libre au centre, la '
        'Reserve en lecture', (WidgetTester tester) async {
      _taille(tester, _bureau);
      await _monter(tester);
      expect(find.byType(ResumeTresorerie), findsOneWidget);
      expect(find.byType(CarteReserveStrategique), findsOneWidget);
      for (final String titre in <String>[
        a.aTraiter,
        a.echeances,
        a.encaissementsRecents,
        a.paiementsAEffectuer,
        a.alertes,
        a.activiteRecente,
        a.accesRapides,
        a.prestataires,
      ]) {
        expect(find.text(titre), findsOneWidget, reason: titre);
      }
      expect(find.text(t.comptable.commun.tresorerieLibre), findsOneWidget);
      expect(find.text(t.comptable.commun.reserveStrategique), findsOneWidget);
      // DR-07 : un seul vocabulaire, jamais « Disponible » ni « Reservee ».
      expect(find.textContaining('Disponible'), findsNothing);
      expect(find.textContaining('Réservée'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('DR-11 : aucun bouton Payer ; DR-09 : aucun graphique', (
      WidgetTester tester,
    ) async {
      _taille(tester, _bureau);
      await _monter(tester);
      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
      expect(
        find.byType(CustomPaint).evaluate().where((Element e) {
          final CustomPaint p = e.widget as CustomPaint;
          // Seule la jauge de la Reserve (theme) peint : aucun graphique.
          return p.painter != null &&
              !p.painter.runtimeType.toString().contains('Progress') &&
              !p.painter.runtimeType.toString().contains('Ink') &&
              p.painter.runtimeType.toString().contains('Chart');
        }),
        isEmpty,
      );
      for (final Element e in find.byType(Text).evaluate()) {
        final String? texte = (e.widget as Text).data;
        if (texte == null) continue;
        expect(
          RegExp(r'^Payer\b').hasMatch(texte),
          isFalse,
          reason: 'bouton « $texte »',
        );
      }
    });

    testWidgets('R-FIN-01 : les montants sont masques a l entree', (
      WidgetTester tester,
    ) async {
      _taille(tester, _bureau);
      await _monter(tester);
      expect(
        find.text(formaterMontant(DonneesAujourdhuiDemo.tresorerie.libre)),
        findsNothing,
      );
      expect(find.byType(MontantArgent), findsNothing);
      expect(find.text(MontantSensible.masquePour('USD')), findsWidgets);
    });

    testWidgets('DR-10 : chaque element de la file apparait une seule fois, '
        'les paiements dans leur zone, les alertes dans la leur', (
      WidgetTester tester,
    ) async {
      _taille(tester, _bureau);
      await _monter(tester);
      for (final ElementAttention e in DonneesAujourdhuiDemo.file) {
        final int n =
            find
                .byKey(ValueKey<String>('attention-${e.id}'))
                .evaluate()
                .length +
            find.byKey(ValueKey<String>('paiement-${e.id}')).evaluate().length;
        expect(n, 1, reason: e.id);
      }
      expect(
        find.byKey(const ValueKey<String>('paiement-att-enseignants')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('attention-att-enseignants')),
        findsNothing,
      );
    });

    for (final (String nom, Finder Function() cible, String attendu) cas
        in <(String, Finder Function(), String)>[
          (
            'infos manquantes',
            () => find.byKey(const ValueKey<String>('attention-att-infos')),
            _element('att-infos').route,
          ),
          (
            'enseignants a payer',
            () =>
                find.byKey(const ValueKey<String>('paiement-att-enseignants')),
            Routes.comptablePaiementsFiltres(
              filtre: 'prets',
              type: 'enseignant',
            ),
          ),
          (
            'alerte doublon',
            () => find.byKey(const ValueKey<String>('attention-att-doublon')),
            Routes.comptableRapprochement,
          ),
          (
            'echeance Facture #024',
            () =>
                find.byKey(const ValueKey<String>('echeance-ech-facture-024')),
            Routes.comptableContractuelObligationPour(
              SocleComptableDemo.obligationFacture024,
            ),
          ),
          (
            'encaissement',
            () => find.byKey(const ValueKey<String>('encaissement-enc-01')),
            Routes.comptableEncaissementPour('enc-01'),
          ),
          (
            'acces Alimenter',
            () => find.byKey(const ValueKey<String>('acces-alimenter')),
            Routes.comptableTresorerieAlimenter,
          ),
          (
            'carte Reserve',
            () => find.byType(CarteReserveStrategique),
            Routes.comptableTresorerie,
          ),
        ]) {
      testWidgets('§5.1 : « ${cas.$1} » ouvre l ecran canonique', (
        WidgetTester tester,
      ) async {
        _taille(tester, _bureau);
        await _monter(tester);
        await _toucher(tester, cas.$2());
        expect(find.text('ROUTE ${cas.$3}'), findsOneWidget);
      });
    }

    testWidgets('« Voir tout » d A traiter ouvre la file complete', (
      WidgetTester tester,
    ) async {
      _taille(tester, _bureau);
      await _monter(tester);
      await _toucher(tester, find.text(a.voirTout).first);
      expect(find.text(a.attention), findsOneWidget);
    });
  });

  group('telephone 390 (M01 ecran 1)', () {
    testWidgets('une tache dominante : trois lignes, le resume des alertes, '
        'trois echeances, pas de bureau compresse', (
      WidgetTester tester,
    ) async {
      _taille(tester, _telephone);
      await _monter(tester);
      expect(find.byType(ResumeTresorerie), findsOneWidget);
      expect(find.byType(CarteReserveStrategique), findsNothing);
      expect(find.text(a.activiteRecente), findsNothing);
      final int lignes = DonneesAujourdhuiDemo.file
          .where(
            (ElementAttention e) => find
                .byKey(ValueKey<String>('attention-${e.id}'))
                .evaluate()
                .isNotEmpty,
          )
          .length;
      expect(lignes, 3);
      expect(
        find.byKey(const ValueKey<String>('resume-alertes')),
        findsOneWidget,
      );
      expect(find.text(a.alertesResume(n: 3)), findsOneWidget);
      final int echeances = DonneesAujourdhuiDemo.echeances
          .where(
            (EcheanceComptable e) => find
                .byKey(ValueKey<String>('echeance-${e.id}'))
                .evaluate()
                .isNotEmpty,
          )
          .length;
      expect(echeances, 3);
      expect(tester.takeException(), isNull);
    });

    testWidgets('le resume des alertes mene a la file complete', (
      WidgetTester tester,
    ) async {
      _taille(tester, _telephone);
      await _monter(tester);
      await _toucher(
        tester,
        find.byKey(const ValueKey<String>('resume-alertes')),
      );
      expect(find.text(a.attention), findsOneWidget);
    });
  });

  group('file complete (?vue=attention)', () {
    testWidgets('toutes les lignes A traiter puis Alertes, avec un retour', (
      WidgetTester tester,
    ) async {
      _taille(tester, _telephone);
      await _monter(tester, depart: Routes.comptableAttention);
      expect(find.text(a.attention), findsOneWidget);
      for (final ElementAttention e in DonneesAujourdhuiDemo.file) {
        await tester.scrollUntilVisible(
          find.byKey(ValueKey<String>('attention-${e.id}')),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(
          find.byKey(ValueKey<String>('attention-${e.id}')),
          findsOneWidget,
          reason: e.id,
        );
      }
      expect(find.byType(ResumeTresorerie), findsNothing);
    });
  });

  group('etats', () {
    testWidgets('chargement : un squelette, aucun chiffre', (
      WidgetTester tester,
    ) async {
      _taille(tester, _bureau);
      final Completer<AujourdhuiComptable> attente =
          Completer<AujourdhuiComptable>();
      await _monter(
        tester,
        port: _Port(attente: attente),
        stabiliserTout: false,
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(Skeleton), findsWidgets);
      expect(find.byType(ResumeTresorerie), findsNothing);
      attente.complete(await const AujourdhuiComptableDemo().aujourdhui());
      await tester.pumpAndSettle();
      expect(find.byType(ResumeTresorerie), findsOneWidget);
    });

    testWidgets('vide : un jour calme garde les chiffres et dit « Rien a '
        'traiter »', (WidgetTester tester) async {
      _taille(tester, _bureau);
      await _monter(
        tester,
        port: _Port(
          valeur: AujourdhuiComptable(
            tresorerie: DonneesAujourdhuiDemo.tresorerie,
            reserve: DonneesAujourdhuiDemo.reserve,
          ),
        ),
      );
      expect(find.byType(ResumeTresorerie), findsOneWidget);
      expect(find.text(a.aTraiterVide), findsOneWidget);
      expect(find.text(a.alertesVide), findsOneWidget);
      expect(find.text(a.paiementsVide), findsOneWidget);
      expect(find.text(a.echeancesVide), findsOneWidget);
      expect(find.text(a.encaissementsVide), findsOneWidget);
      expect(find.text(a.activiteVide), findsOneWidget);
      expect(find.text(a.prestatairesVide), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('erreur : « Reessayer » relit la source', (
      WidgetTester tester,
    ) async {
      _taille(tester, _bureau);
      await _monter(tester, port: _Port(erreur: StateError('panne')));
      final Finder reessayer = find.text(t.commun.etats.actions.reessayer);
      expect(reessayer, findsOneWidget);
      expect(find.byType(ResumeTresorerie), findsNothing);
    });

    testWidgets('indisponible (port neutre de production) : sans '
        '« Reessayer »', (WidgetTester tester) async {
      _taille(tester, _bureau);
      await _monter(tester, port: const AujourdhuiComptableIndisponible());
      expect(find.text(t.commun.etats.indisponible.titre), findsOneWidget);
      expect(find.text(t.commun.etats.actions.reessayer), findsNothing);
      expect(find.byType(ResumeTresorerie), findsNothing);
      Object? erreur;
      try {
        await const AujourdhuiComptableIndisponible().aujourdhui();
      } on Object catch (e) {
        erreur = e;
      }
      expect(erreur, isA<CapaciteIndisponible>());
    });

    testWidgets('hors ligne : l echec se dit hors ligne', (
      WidgetTester tester,
    ) async {
      _taille(tester, _bureau);
      await _monter(
        tester,
        port: _Port(erreur: StateError('reseau')),
        horsLigne: true,
      );
      expect(find.text(t.commun.etats.horsLigne.titre), findsOneWidget);
      expect(find.byType(ResumeTresorerie), findsNothing);
    });
  });

  group('320 px, texte x2', () {
    for (final String depart in <String>[
      Routes.comptable,
      Routes.comptableAttention,
    ]) {
      testWidgets('$depart : aucun debordement, aucun mot coupe', (
        WidgetTester tester,
      ) async {
        _taille(tester, _etroit, texte: 2);
        await _monter(tester, depart: depart);
        expect(tester.takeException(), isNull);
        expect(
          motsCoupes(tester, find.byType(AujourdhuiComptablePage)),
          isEmpty,
        );
      });
    }

    testWidgets('bureau, texte x2 : aucun debordement', (
      WidgetTester tester,
    ) async {
      _taille(tester, _bureau, texte: 2);
      await _monter(tester);
      expect(tester.takeException(), isNull);
    });
  });
}
