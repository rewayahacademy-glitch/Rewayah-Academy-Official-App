// PX-BD-0 : le bloc « Lots a confirmer » de la section Praxis.
//
// Ce que les cas prouvent (sur le vrai widget, la base est un double) :
//  - RIEN n'est lu a l'ouverture : le code ne s'affiche qu'a la demande de la
//    direction (« Afficher »), jamais avant ;
//  - le lot, son resume et son code se lisent ensemble, le code en deux
//    groupes de trois chiffres, de gauche a droite en arabe aussi ;
//  - les etats loading, content, empty, error et offline ;
//  - un refus faute de double verification se dit par la phrase vraie ;
//  - annuler attend le serveur, relit la liste, dit le resultat ;
//  - aucun bouton plein, aucune carte collee, aucun debordement, texte x2.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/agent/lots_praxis.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/features/admin_acces_agents/lots_praxis_section.dart';

import '../../support/faux_service_lots_praxis.dart';
import '../../support/garde_interface.dart';
import '../../support/harnais.dart';

Future<void> _monter(
  WidgetTester tester,
  FauxServiceLotsPraxis faux, {
  List<Override> en = const <Override>[],
  Size taille = const Size(1440, 2000),
  double echelle = 1,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hote(
      Builder(
        builder: (BuildContext c) => MediaQuery(
          data: MediaQuery.of(c)
              .copyWith(textScaler: TextScaler.linear(echelle)),
          child: const Scaffold(
            body: SingleChildScrollView(child: LotsPraxisSection()),
          ),
        ),
      ),
      surcharges: <Override>[
        serviceLotsPraxisProvider.overrideWithValue(faux),
        ...en,
      ],
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _presser(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

void main() {
  group('le code ne se montre qu a la demande', () {
    testWidgets('a l ouverture : rien n est lu, aucun code a l ecran', (
      tester,
    ) async {
      final FauxServiceLotsPraxis faux = FauxServiceLotsPraxis(
        lots: <LotPraxis>[lotFictif()],
      );
      await _monter(tester, faux);
      expect(faux.appels, isEmpty);
      expect(find.text(t.admin.praxis.lots.titre), findsOneWidget);
      expect(find.text(t.admin.praxis.lots.ferme), findsOneWidget);
      expect(find.byKey(ClesLotsPraxis.afficher), findsOneWidget);
      expect(find.textContaining('482'), findsNothing);
    });

    testWidgets('afficher : le lot, son resume, son code, son heure', (
      tester,
    ) async {
      final FauxServiceLotsPraxis faux = FauxServiceLotsPraxis(
        lots: <LotPraxis>[lotFictif()],
      );
      await _monter(tester, faux);
      await _presser(tester, find.byKey(ClesLotsPraxis.afficher));
      expect(faux.appels, <String>['enAttente']);
      expect(find.byKey(ClesLotsPraxis.code('l1')), findsOneWidget);
      expect(find.text('482 913'), findsOneWidget);
      expect(find.text('Note S : un'), findsOneWidget);
      expect(find.text('Note S : deux'), findsOneWidget);
      expect(find.text(t.admin.praxis.lots.lignes(n: 2)), findsOneWidget);
      expect(find.textContaining(t.admin.praxis.lots.dire), findsOneWidget);
      // Le nom technique de l'acte n'est jamais montre (mot interne).
      expect(find.textContaining('acte_fictif'), findsNothing);
      expect(find.byKey(ClesLotsPraxis.annuler('l1')), findsOneWidget);
    });

    testWidgets('plusieurs lots : un code par lot, chacun avec son resume', (
      tester,
    ) async {
      final FauxServiceLotsPraxis faux = FauxServiceLotsPraxis(
        lots: <LotPraxis>[
          lotFictif(),
          lotFictif(
            id: 'l2',
            code: '007154',
            nb: 1,
            resume: <String>['Autre ligne'],
          ),
        ],
      );
      await _monter(tester, faux);
      await _presser(tester, find.byKey(ClesLotsPraxis.afficher));
      expect(find.text('482 913'), findsOneWidget);
      expect(find.text('007 154'), findsOneWidget);
      expect(find.text('Autre ligne'), findsOneWidget);
    });

    testWidgets('un lot dont le code est douteux n est pas montre', (
      tester,
    ) async {
      expect(
        LotPraxis.depuisJson(<String, dynamic>{
          'id': 'x',
          'acte': 'a',
          'code': '12345',
          'expireLe': '2026-11-17T14:35:00Z',
        }),
        isNull,
      );
      expect(
        LotPraxis.depuisJson(<String, dynamic>{
          'id': 'x',
          'acte': 'a',
          'code': '1234ab',
          'expireLe': '2026-11-17T14:35:00Z',
        }),
        isNull,
      );
      expect(
        LotPraxis.depuisJson(<String, dynamic>{
          'id': 'x',
          'acte': 'a',
          'code': '123456',
          'expireLe': 'pas une date',
        }),
        isNull,
      );
    });
  });

  group('etats', () {
    testWidgets('chargement : un squelette, puis le contenu', (tester) async {
      final Completer<List<LotPraxis>> attente = Completer<List<LotPraxis>>();
      final _FauxLent faux = _FauxLent(attente.future);
      await _monter(tester, faux);
      await tester.tap(find.byKey(ClesLotsPraxis.afficher));
      await tester.pump();
      expect(find.byKey(ClesLotsPraxis.afficher), findsNothing);
      expect(find.text(t.admin.praxis.lots.ferme), findsNothing);
      attente.complete(<LotPraxis>[lotFictif()]);
      await tester.pumpAndSettle();
      expect(find.text('482 913'), findsOneWidget);
    });

    testWidgets('vide : la phrase le dit', (tester) async {
      await _monter(tester, FauxServiceLotsPraxis());
      await _presser(tester, find.byKey(ClesLotsPraxis.afficher));
      expect(find.text(t.admin.praxis.lots.vide), findsOneWidget);
      expect(find.text(t.admin.praxis.lots.videDetail), findsOneWidget);
    });

    testWidgets('erreur : jamais « aucun lot », et on peut reessayer', (
      tester,
    ) async {
      final FauxServiceLotsPraxis faux = FauxServiceLotsPraxis(
        erreurLecture: Exception('panne'),
      );
      await _monter(tester, faux);
      await _presser(tester, find.byKey(ClesLotsPraxis.afficher));
      expect(find.text(t.admin.praxis.lots.erreur), findsOneWidget);
      expect(find.text(t.admin.praxis.lots.vide), findsNothing);
      faux
        ..erreurLecture = null
        ..lots = <LotPraxis>[lotFictif()];
      await _presser(tester, find.text(t.commun.reessayer));
      expect(find.text('482 913'), findsOneWidget);
    });

    testWidgets('hors ligne : le bloc dit ce qui manque', (tester) async {
      await _monter(
        tester,
        FauxServiceLotsPraxis(erreurLecture: Exception('reseau')),
        en: <Override>[
          horsLigneProvider.overrideWith((ref) => Stream<bool>.value(true)),
        ],
      );
      await _presser(tester, find.byKey(ClesLotsPraxis.afficher));
      expect(find.text(t.admin.praxis.lots.horsLigne), findsOneWidget);
    });

    testWidgets('refus faute de double verification : la phrase vraie', (
      tester,
    ) async {
      await _monter(tester, FauxServiceLotsPraxis(refusDroit: true));
      await _presser(tester, find.byKey(ClesLotsPraxis.afficher));
      expect(find.text(t.admin.praxis.lots.doubleVerification), findsOneWidget);
      expect(find.text('482 913'), findsNothing);
    });
  });

  group('annuler', () {
    testWidgets('le lot disparait, la liste est relue, la phrase le dit', (
      tester,
    ) async {
      final FauxServiceLotsPraxis faux = FauxServiceLotsPraxis(
        lots: <LotPraxis>[
          lotFictif(),
          lotFictif(id: 'l2', code: '007154'),
        ],
      );
      await _monter(tester, faux);
      await _presser(tester, find.byKey(ClesLotsPraxis.afficher));
      await _presser(tester, find.byKey(ClesLotsPraxis.annuler('l1')));
      expect(faux.appels, <String>['enAttente', 'annuler:l1', 'enAttente']);
      expect(find.text('482 913'), findsNothing);
      expect(find.text('007 154'), findsOneWidget);
      expect(find.text(t.admin.praxis.lots.annule), findsOneWidget);
    });

    testWidgets('un lot qui n attendait plus : la phrase vraie', (
      tester,
    ) async {
      final FauxServiceLotsPraxis faux = FauxServiceLotsPraxis(
        lots: <LotPraxis>[lotFictif()],
        annulationRendue: false,
      );
      await _monter(tester, faux);
      await _presser(tester, find.byKey(ClesLotsPraxis.afficher));
      await _presser(tester, find.byKey(ClesLotsPraxis.annuler('l1')));
      expect(find.text(t.admin.praxis.lots.rien), findsOneWidget);
    });

    testWidgets('recharger relit la liste', (tester) async {
      final FauxServiceLotsPraxis faux = FauxServiceLotsPraxis(
        lots: <LotPraxis>[lotFictif()],
      );
      await _monter(tester, faux);
      await _presser(tester, find.byKey(ClesLotsPraxis.afficher));
      faux.lots = <LotPraxis>[lotFictif(id: 'l9', code: '999000')];
      await _presser(tester, find.byKey(ClesLotsPraxis.recharger));
      expect(find.text('999 000'), findsOneWidget);
      expect(find.text('482 913'), findsNothing);
    });
  });

  group('garde d interface', () {
    for (final Size taille in const <Size>[Size(320, 900), Size(1440, 900)]) {
      for (final double echelle in const <double>[1, 2]) {
        testWidgets('${taille.width.toInt()} x$echelle : aucun bouton plein, '
            'aucune carte collee, aucun debordement', (tester) async {
          final FauxServiceLotsPraxis faux = FauxServiceLotsPraxis(
            lots: <LotPraxis>[
              lotFictif(),
              lotFictif(id: 'l2', code: '007154'),
            ],
          );
          await _monter(tester, faux, taille: taille, echelle: echelle);
          await _presser(tester, find.byKey(ClesLotsPraxis.afficher));
          expect(tester.takeException(), isNull);
          verifierUnSeulBoutonPlein(tester, maximum: 0);
          final int vues = verifierAucuneCarteCollee(
            tester,
            estCarte: (Widget w) => w is AppCard,
          );
          expect(vues, greaterThanOrEqualTo(2));
        });
      }
    }
  });
}

class _FauxLent extends FauxServiceLotsPraxis {
  _FauxLent(this._attente);
  final Future<List<LotPraxis>> _attente;

  @override
  Future<List<LotPraxis>> enAttente() => _attente;
}
