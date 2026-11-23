// PAIEMENT-UNIFIE P5 (directeur, 23/11/2026) : la section « Paiement » de la
// fiche d'un eleve. L'etat vient du serveur (jamais calcule ici), quatre
// gestes (Prix special, Exonerer, Reporter, Demander maintenant), « Retirer la
// remise » seulement quand une remise est en cours ; « Demander maintenant »
// est l'unique appel nouveau et son echec se dit « non confirmee ».

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/fiche_eleve_direction.dart';
import 'package:rewayah_academy/core/i18n/elision.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/admin_personnes/fiche_eleve_direction_page.dart';
import 'package:rewayah_academy/features/admin_personnes/section_paiement_fiche.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/harnais.dart';

Map<String, dynamic> _json(Map<String, dynamic>? paiement) => <String, dynamic>{
  'identite': <String, dynamic>{
    'id': 'e1',
    'matricule': 'RA-26-4817',
    'prenom': 'Yasmine',
    'nom': 'Benali',
    'tranche': 'enfant',
    'etat_compte': 'active',
  },
  'classes': <Object>[],
  'presences': <String, dynamic>{'total': 0, 'dernieres': <Object>[]},
  'paiement': ?paiement,
};

class _Port implements PortFicheEleveDirection {
  _Port(this._json, {this.resultat, this.echec = false});

  final Map<String, dynamic> _json;
  final ResultatDemandePaiement? resultat;
  final bool echec;
  final List<String> demandes = <String>[];

  @override
  Future<FicheEleveDirection?> lire(String eleveId) async =>
      FicheEleveDirection.depuisJson(_json);

  @override
  Future<ResultatDemandePaiement> demanderPaiement(String eleveId) async {
    demandes.add(eleveId);
    if (echec) throw StateError('reseau');
    return resultat ?? ResultatDemandePaiement.demandee;
  }
}

Future<void> _monter(
  WidgetTester tester,
  _Port port, {
  Size taille = const Size(1440, 900),
  bool horsLigne = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = taille;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hoteRoutant(
      depart: Routes.adminPersonnesElevePour('e1'),
      routes: <RouteBase>[
        GoRoute(
          path: Routes.adminPersonnesEleve,
          builder: (BuildContext _, GoRouterState e) => FicheEleveDirectionPage(
            eleveId: e.pathParameters['eleveId'] ?? '',
          ),
        ),
      ],
      surcharges: <Override>[
        portFicheEleveDirectionProvider.overrideWithValue(port),
        serviceReseauProvider.overrideWithValue(
          FauxServiceReseau(horsLigneRendu: horsLigne),
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

const Map<String, dynamic> _aPayer = <String, dynamic>{
  'etat': 'a_payer',
  'deja_paye': false,
  'facture': <String, dynamic>{
    'mois': '2026-11-01',
    'total_mineur': 5500,
    'devise': 'USD',
    'statut': 'a_financer',
    'emise_le': '2026-11-20T10:00:00Z',
  },
};

void main() {
  setUpAll(chargerPolicesDuDepot);
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  group('lecture du bloc paiement', () {
    test('les quatre etats viennent du serveur, un mot inconnu vaut a payer', () {
      expect(EtatPaiementEleve.depuis('paye'), EtatPaiementEleve.paye);
      expect(EtatPaiementEleve.depuis('en_retard'), EtatPaiementEleve.enRetard);
      expect(EtatPaiementEleve.depuis('exonere'), EtatPaiementEleve.exonere);
      expect(EtatPaiementEleve.depuis('a_payer'), EtatPaiementEleve.aPayer);
      expect(EtatPaiementEleve.depuis('inconnu'), EtatPaiementEleve.aPayer);
      expect(EtatPaiementEleve.depuis(null), EtatPaiementEleve.aPayer);
    });

    test('facture et remise lues ; absentes, nulles', () {
      final PaiementFiche p = PaiementFiche.depuisJson(<String, dynamic>{
        ..._aPayer,
        'remise': <String, dynamic>{
          'nature': 'prix_special',
          'pour_mille': null,
          'montant_mineur': 4000,
          'devise': 'USD',
          'mois_fin': '2027-01-01',
        },
      })!;
      expect(p.facture?.attendPaiement, isTrue);
      expect(p.facture?.totalMineur, 5500);
      expect(p.remise?.nature, 'prix_special');
      expect(p.remise?.montantMineur, 4000);
      expect(PaiementFiche.depuisJson(null), isNull);
      final PaiementFiche vide = PaiementFiche.depuisJson(<String, dynamic>{
        'etat': 'paye',
        'deja_paye': true,
        'facture': null,
        'remise': null,
      })!;
      expect(vide.facture, isNull);
      expect(vide.remise, isNull);
      expect(vide.dejaPaye, isTrue);
    });

    test('un serveur d\'avant le lot : pas de section, pas d\'etat invente', () {
      expect(FicheEleveDirection.depuisJson(_json(null))!.paiement, isNull);
    });
  });

  group('la section', () {
    testWidgets('a payer : l\'etat, la facture et les quatre gestes', (
      WidgetTester tester,
    ) async {
      await _monter(tester, _Port(_json(_aPayer)));
      expect(find.byKey(SectionPaiementFiche.cle), findsOneWidget);
      expect(find.text(t.admin.ficheEleve.paiement.aPayer), findsOneWidget);
      expect(find.text(t.admin.ficheEleve.paiement.premierPasEncore), findsOne);
      for (final String g in <String>[
        'prix',
        'exonerer',
        'reporter',
        'demander',
      ]) {
        expect(
          find.byKey(SectionPaiementFiche.cleGeste(g), skipOffstage: false),
          findsOneWidget,
          reason: g,
        );
      }
      // Aucune remise : pas de geste « Retirer ».
      expect(
        find.byKey(SectionPaiementFiche.cleGeste('retirer')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('une remise en cours : « Retirer la remise » apparait', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        _Port(
          _json(<String, dynamic>{
            'etat': 'exonere',
            'deja_paye': false,
            'remise': <String, dynamic>{
              'nature': 'acces_offert',
              'pour_mille': 1000,
              'mois_fin': '2027-01-01',
            },
          }),
        ),
      );
      expect(find.text(t.admin.ficheEleve.paiement.exonere), findsOneWidget);
      expect(
        find.byKey(
          SectionPaiementFiche.cleGeste('retirer'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
    });

    testWidgets('les quatre etats se disent en mots', (
      WidgetTester tester,
    ) async {
      final p = t.admin.ficheEleve.paiement;
      for (final (String, String) e in <(String, String)>[
        ('a_payer', p.aPayer),
        ('paye', p.paye),
        ('en_retard', p.enRetard),
        ('exonere', p.exonere),
      ]) {
        await _monter(
          tester,
          _Port(
            _json(<String, dynamic>{'etat': e.$1, 'deja_paye': e.$1 == 'paye'}),
          ),
        );
        expect(find.text(e.$2), findsOneWidget, reason: e.$1);
      }
    });

    testWidgets('« Demander maintenant » : un appel, la famille prevenue', (
      WidgetTester tester,
    ) async {
      final _Port port = _Port(_json(_aPayer));
      await _monter(tester, port);
      await tester.ensureVisible(
        find.byKey(SectionPaiementFiche.cleGeste('demander')),
      );
      await tester.tap(find.byKey(SectionPaiementFiche.cleGeste('demander')));
      await tester.pumpAndSettle();
      expect(port.demandes, <String>['e1']);
      expect(
        find.text(t.admin.ficheEleve.paiement.demandeTitre),
        findsOneWidget,
      );
    });

    testWidgets('rien a payer : le dit, sans prevenir personne', (
      WidgetTester tester,
    ) async {
      final _Port port = _Port(
        _json(_aPayer),
        resultat: ResultatDemandePaiement.rienAPayer,
      );
      await _monter(tester, port);
      await tester.ensureVisible(
        find.byKey(SectionPaiementFiche.cleGeste('demander')),
      );
      await tester.tap(find.byKey(SectionPaiementFiche.cleGeste('demander')));
      await tester.pumpAndSettle();
      expect(find.text(t.admin.ficheEleve.paiement.rienTitre), findsOneWidget);
    });

    testWidgets('echec : « non confirmee », jamais « non envoyee »', (
      WidgetTester tester,
    ) async {
      final _Port port = _Port(_json(_aPayer), echec: true);
      await _monter(tester, port);
      await tester.ensureVisible(
        find.byKey(SectionPaiementFiche.cleGeste('demander')),
      );
      await tester.tap(find.byKey(SectionPaiementFiche.cleGeste('demander')));
      await tester.pumpAndSettle();
      expect(
        find.text(t.admin.ficheEleve.paiement.echecTitre),
        findsOneWidget,
      );
      expect(find.textContaining('non envoy'), findsNothing);
    });

    testWidgets('hors ligne : aucun appel ne part, la phrase le dit', (
      WidgetTester tester,
    ) async {
      final _Port port = _Port(_json(_aPayer));
      await _monter(tester, port, horsLigne: true);
      await tester.ensureVisible(
        find.byKey(
          SectionPaiementFiche.cleGeste('demander'),
          skipOffstage: false,
        ),
      );
      await tester.tap(find.byKey(SectionPaiementFiche.cleGeste('demander')));
      await tester.pumpAndSettle();
      expect(port.demandes, isEmpty);
    });

    testWidgets('« Reporter » ouvre la feuille de report', (
      WidgetTester tester,
    ) async {
      await _monter(tester, _Port(_json(_aPayer)));
      await tester.ensureVisible(
        find.byKey(SectionPaiementFiche.cleGeste('reporter')),
      );
      await tester.tap(find.byKey(SectionPaiementFiche.cleGeste('reporter')));
      await tester.pumpAndSettle();
      expect(
        find.text(t.admin.finance.tarifs.reporterTitre(dePrenom: deDevant('Yasmine'))),
        findsWidgets,
      );
      expect(find.text(t.admin.finance.tarifs.reporterMois), findsOneWidget);
    });

    for (final Size taille in const <Size>[
      Size(390, 844),
      Size(1280, 800),
      Size(1440, 900),
    ]) {
      testWidgets('rien ne deborde a ${taille.width.toInt()}', (
        WidgetTester tester,
      ) async {
        await _monter(tester, _Port(_json(_aPayer)), taille: taille);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('en arabe', () {
    setUp(() async {
      await LocaleSettings.setLocale(AppLocale.ar);
    });
    tearDown(() async {
      await LocaleSettings.setLocale(AppLocale.fr);
    });

    testWidgets('sans debordement, les gestes sont la', (
      WidgetTester tester,
    ) async {
      await _monter(tester, _Port(_json(_aPayer)));
      expect(find.byKey(SectionPaiementFiche.cle), findsOneWidget);
      expect(
        find.byKey(
          SectionPaiementFiche.cleGeste('demander'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
