// PAIEMENT-FAMILLE-PRIX (directeur, 23/11/2026) : l'ecran de recharge explique
// chaque montant. Sur de vrais JSON du serveur (dette au prorata, offres de 0
// a 3 mois, remises accordees et non accordees) : la dette d'abord et a part,
// le « moins / plus » qui parcourt les offres, la phrase de l'offre choisie,
// le nombre de mois envoye au serveur, « premier inscrit » et « moins de trois
// mois » dits, un profil sans creneau a sa phrase. A 1280 et 1440, l'explication
// reste dans la colonne des profils (jamais une colonne de telephone etiree).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/capacites/port_paiements_foyer.dart';
import 'package:rewayah_academy/core/capacites/port_politique_famille.dart';
import 'package:rewayah_academy/core/capacites/port_politiques_commerciales.dart';
import 'package:rewayah_academy/core/capacites/port_recharge_foyer.dart';
import 'package:rewayah_academy/core/capacites/recharge_foyer_supabase.dart'
    show beneficiaireRechargeJson;
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/finance/finances_profil.dart';
import 'package:rewayah_academy/core/finance/format_montant.dart';
import 'package:rewayah_academy/core/finance/montant.dart';
import 'package:rewayah_academy/core/finance/suivi_paiement.dart';
import 'package:rewayah_academy/core/i18n/isolat_bidi.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/foyer/invitation_conjoint.dart';

import '../../router/support_routeur.dart';
import '../../support/demo/finance_demo.dart';
import '../../support/harnais.dart';

const String _mariam = DonneesFinanceDemo.mariamId;
const String _ibrahim = DonneesFinanceDemo.ibrahimId;
const String _aicha = DonneesFinanceDemo.aichaId;

FauxServiceAppairage _foyer() =>
    FauxServiceAppairage()
      ..elevesRendus = <EleveDuFoyer>[
        for (final FinancesProfil p in DonneesFinanceDemo.profils(
          JeuFoyerFinance.tousFinances,
        ))
          EleveDuFoyer(
            id: p.profilId,
            prenom: p.prenom,
            identifiantImmuable: 'STUD-FI-${p.profilId}',
            mode: InterfaceMode.standard,
            camera: CameraPolicy.allowed,
          ),
      ];

/// Monte l'application du tuteur sur le VRAI routeur, sur la recharge.
Future<void> _monter(
  WidgetTester tester, {
  required PortRechargeFoyer port,
  Size taille = const Size(390, 2400),
  double echelle = 1,
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesRouteur(
          FausseSourceSession(sessionActive(AppRole.guardian)),
          appairage: _foyer(),
        ),
        horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
        portPaiementsFoyerProvider.overrideWithValue(
          const PaiementsFoyerFinanceDemo(JeuFoyerFinance.tousFinances),
        ),
        portPolitiquesCommercialesProvider.overrideWithValue(
          const PolitiquesCommercialesDemo(),
        ),
        portPolitiqueFamilleProvider.overrideWithValue(
          const PolitiqueFamilleDemo(),
        ),
        portRechargeFoyerProvider.overrideWithValue(port),
      ],
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext _, WidgetRef ref, Widget? _) {
            routeur = ref.read(routeurProvider);
            return MediaQuery(
              data: MediaQueryData(
                size: taille,
                textScaler: TextScaler.linear(echelle),
              ),
              child: MaterialApp.router(
                theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
                routerConfig: routeur,
                builder: (BuildContext _, Widget? enfant) =>
                    Directionality(textDirection: direction, child: enfant!),
              ),
            );
          },
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(Routes.tuteurFoyerRecharge);
  await stabiliser(tester);
}

Map<String, Object?> _montant(int mineur) => <String, Object?>{
  'mineur': mineur,
  'devise': 'USD',
};

Map<String, Object?> _option({
  required int nb,
  required String formule,
  required int montant,
  required int dette,
  required int avance,
  Map<String, Object?>? couverts,
  List<Map<String, Object?>> lignes = const <Map<String, Object?>>[],
  List<Map<String, Object?>> non = const <Map<String, Object?>>[],
}) => <String, Object?>{
  'nbMois': nb,
  'formule': formule,
  'montant': _montant(montant),
  'dette': _montant(dette),
  'avance': _montant(avance),
  'moisCouverts': couverts,
  'lignes': lignes,
  'nonAppliquees': non,
};

Map<String, Object?> _couverts(String debut, String fin, int n) =>
    <String, Object?>{'debut': debut, 'fin': fin, 'nbMois': n};

Map<String, Object?> _prix(int mineur, int n) => <String, Object?>{
  'code': 'prix',
  'montant': _montant(mineur),
  'nbMois': n,
};

Map<String, Object?> _remiseFamille(int mineur) => <String, Object?>{
  'code': 'remise_famille',
  'montant': _montant(mineur),
  'rang': 2,
  'pourMille': 80,
};

Map<String, Object?> _enveloppe(
  String id,
  String prenom,
  String etat,
  int dette,
  List<Map<String, Object?>> options, {
  List<Object?> moisDus = const <Object?>[],
}) => <String, Object?>{
  'id': id,
  'prenom': prenom,
  'cleAvatar': null,
  'solde': _montant(0),
  'etat': etat,
  'rang': 1,
  'tarif': _montant(5500),
  'montantSuggere': dette > 0 ? _montant(dette) : null,
  'montantsProposes': <Object?>[
    for (final Map<String, Object?> o in options) o['montant'],
  ],
  'formules': <Object?>[
    for (final Map<String, Object?> o in options)
      <String, Object?>{'montant': o['montant'], 'formule': o['formule']},
  ],
  'dette': <String, Object?>{
    'total': _montant(dette),
    'solde': _montant(0),
    'mois': moisDus,
  },
  'options': options,
};

const Map<String, Object?> _moinsDeTrois = <String, Object?>{
  'type': 'remise_prepaiement',
  'code': 'moins_de_trois_mois',
};

const Map<String, Object?> _premierInscrit = <String, Object?>{
  'type': 'remise_famille',
  'code': 'premier_inscrit',
};

/// Mariam : entree en cours de mois, 25,30 USD de novembre au prorata, puis
/// 0 a 3 mois d'avance. Ibrahim : 1er inscrit, rien a regler. Aicha : sans
/// creneau.
List<BeneficiaireRecharge> _profils() => <BeneficiaireRecharge>[
  beneficiaireRechargeJson(
    _enveloppe(
      _mariam,
      'Mariam',
      'en_classe',
      2530,
      <Map<String, Object?>>[
        _option(nb: 0, formule: 'libre', montant: 2530, dette: 2530, avance: 0),
        _option(
          nb: 1,
          formule: 'avance',
          montant: 7590,
          dette: 2530,
          avance: 5060,
          couverts: _couverts('2026-12-01', '2026-12-01', 1),
          lignes: <Map<String, Object?>>[_prix(5500, 1), _remiseFamille(-440)],
          non: <Map<String, Object?>>[_moinsDeTrois],
        ),
        _option(
          nb: 2,
          formule: 'avance',
          montant: 12650,
          dette: 2530,
          avance: 10120,
          couverts: _couverts('2026-12-01', '2027-01-01', 2),
          lignes: <Map<String, Object?>>[_prix(11000, 2), _remiseFamille(-880)],
          non: <Map<String, Object?>>[_moinsDeTrois],
        ),
        _option(
          nb: 3,
          formule: 'trimestriel',
          montant: 16930,
          dette: 2530,
          avance: 14400,
          couverts: _couverts('2026-12-01', '2027-02-01', 3),
          lignes: <Map<String, Object?>>[
            _prix(16500, 3),
            _remiseFamille(-1320),
            <String, Object?>{
              'code': 'remise_prepaiement',
              'montant': _montant(-825),
              'pourMille': 50,
            },
            <String, Object?>{'code': 'arrondi', 'montant': _montant(45)},
          ],
        ),
      ],
      moisDus: <Object?>[
        <String, Object?>{
          'mois': '2026-11-01',
          'montant': _montant(2530),
          'apercu': false,
          'lignes': <Object?>[
            <String, Object?>{
              'nature': 'tarif',
              'montant': _montant(5500),
              'rang': null,
            },
            <String, Object?>{
              'nature': 'remise_rang',
              'montant': _montant(-440),
              'rang': 2,
            },
            <String, Object?>{
              'nature': 'prorata',
              'montant': _montant(-2530),
              'rang': null,
            },
          ],
          'prorata': <String, Object?>{
            'entreeLe': '2026-11-12',
            'seancesRestantes': 4,
            'seancesDuMois': 8,
          },
        },
      ],
    ),
  ),
  beneficiaireRechargeJson(
    _enveloppe(_ibrahim, 'Ibrahim', 'en_classe', 0, <Map<String, Object?>>[
      _option(
        nb: 1,
        formule: 'avance',
        montant: 5500,
        dette: 0,
        avance: 5500,
        couverts: _couverts('2026-12-01', '2026-12-01', 1),
        lignes: <Map<String, Object?>>[_prix(5500, 1)],
        non: <Map<String, Object?>>[_premierInscrit, _moinsDeTrois],
      ),
      _option(
        nb: 3,
        formule: 'trimestriel',
        montant: 15700,
        dette: 0,
        avance: 15700,
        couverts: _couverts('2026-12-01', '2027-02-01', 3),
        lignes: <Map<String, Object?>>[
          _prix(16500, 3),
          <String, Object?>{
            'code': 'remise_prepaiement',
            'montant': _montant(-825),
            'pourMille': 50,
          },
          <String, Object?>{'code': 'arrondi', 'montant': _montant(25)},
        ],
        non: <Map<String, Object?>>[_premierInscrit],
      ),
    ]),
  ),
  beneficiaireRechargeJson(
    _enveloppe(_aicha, 'Aicha', 'aucun_creneau', 0, <Map<String, Object?>>[]),
  ),
];

/// Un port qui rend ces profils et garde les choix envoyes.
class _PortExplique implements PortRechargeFoyer {
  final List<List<MontantRecharge>> envois = <List<MontantRecharge>>[];

  @override
  Future<List<BeneficiaireRecharge>> beneficiaires() async => _profils();

  @override
  Future<RecapitulatifRecharge> verifierMontants(
    List<MontantRecharge> choix,
  ) async {
    envois.add(choix);
    return DonneesFinanceDemo.recapitulatifDe(_profils(), choix);
  }

  @override
  Future<RecapitulatifRecharge> verifier(List<ChoixRecharge> choix) =>
      Future<RecapitulatifRecharge>.error(UnimplementedError());

  @override
  Future<String> payer({
    required String recapitulatifId,
    required String cle,
  }) => Future<String>.error(UnimplementedError());

  @override
  Future<SuiviPaiement> suivre(String commandeId) =>
      Future<SuiviPaiement>.error(UnimplementedError());
}

String _m(int mineur) => sansAncre(formaterMontant(Montant(mineur, 'USD')));

Future<void> _taper(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(f);
  await stabiliser(tester);
}

Finder _texte(String morceau) =>
    find.textContaining(morceau, findRichText: true);

void main() {
  testWidgets('un profil sans classe ni creneau : sa phrase dit quoi faire', (
    WidgetTester tester,
  ) async {
    await _monter(tester, port: _PortExplique());
    expect(_texte('Choisissez d\'abord un créneau'), findsOneWidget);
  });

  testWidgets(
    'la dette d abord ; moins / plus parcourt les offres, chacune expliquee',
    (WidgetTester tester) async {
      final _PortExplique port = _PortExplique();
      await _monter(tester, port: port);
      await _taper(tester, find.byKey(RechargeFoyerPage.caseDe(_mariam)));
      // La dette est retenue a la coche, et dite.
      expect(
        _texte('Vous payez ${_m(2530)} pour le mois dû (novembre).'),
        findsOneWidget,
      );
      expect(
        find.byKey(RechargeFoyerPage.explicationDe(_mariam)),
        findsOneWidget,
      );
      // Le calcul du mois du : prix, remise de famille, prorata et « 4 seances sur 8 ».
      expect(_texte('Au prorata des séances du mois'), findsOneWidget);
      expect(_texte('Début le 12 novembre'), findsOneWidget);
      expect(_texte('4 séances sur 8 ce mois-ci'), findsOneWidget);
      expect(port.envois.last.single.nbMois, 0);

      await _taper(tester, find.byKey(RechargeFoyerPage.plusDe(_mariam)));
      expect(
        _texte(
          'Vous payez d\'abord ${_m(2530)} (novembre), puis 1 mois d\'avance '
          '(décembre) : ${_m(7590)} en tout.',
        ),
        findsOneWidget,
      );
      expect(_texte('Remise de famille, 2ᵉ inscrit (8 %)'), findsOneWidget);
      expect(
        _texte('Pas de remise de paiement d\'avance en dessous de 3 mois.'),
        findsOneWidget,
      );
      expect(port.envois.last.single.nbMois, 1);

      await _taper(tester, find.byKey(RechargeFoyerPage.plusDe(_mariam)));
      expect(_texte('2 mois d\'avance (décembre et janvier)'), findsOneWidget);
      expect(port.envois.last.single.nbMois, 2);
      expect(port.envois.last.single.montant, const Montant(12650, 'USD'));

      await _taper(tester, find.byKey(RechargeFoyerPage.plusDe(_mariam)));
      expect(
        _texte('3 mois d\'avance (de décembre 2026 à février 2027)'),
        findsOneWidget,
      );
      expect(_texte('Remise de paiement d\'avance (5 %)'), findsOneWidget);
      expect(_texte('Arrondi au dollar'), findsOneWidget);
      // Plus d'offre au-dela de la derniere : « plus » disparait (jamais grise).
      expect(find.byKey(RechargeFoyerPage.plusDe(_mariam)), findsNothing);
      expect(find.text(_m(16930)), findsWidgets);

      // Et on revient : « moins » ramene a l'offre d'avant.
      await _taper(tester, find.byKey(RechargeFoyerPage.moinsDe(_mariam)));
      expect(_texte('2 mois d\'avance (décembre et janvier)'), findsOneWidget);
    },
  );

  testWidgets(
    'premier inscrit et moins de trois mois sont dits ; a trois mois, la remise de prepaiement',
    (WidgetTester tester) async {
      final _PortExplique port = _PortExplique();
      await _monter(tester, port: port);
      await _taper(tester, find.byKey(RechargeFoyerPage.caseDe(_ibrahim)));
      // Sans dette, rien n'est retenu a la coche : « plus » choisit la 1re offre.
      await _taper(tester, find.byKey(RechargeFoyerPage.plusDe(_ibrahim)));
      expect(
        _texte('Vous payez 1 mois d\'avance (décembre) : ${_m(5500)}.'),
        findsOneWidget,
      );
      expect(
        _texte('Pas de remise de famille : premier inscrit.'),
        findsOneWidget,
      );
      expect(
        _texte('Pas de remise de paiement d\'avance en dessous de 3 mois.'),
        findsOneWidget,
      );
      expect(port.envois.last.single.nbMois, 1);
      await _taper(tester, find.byKey(RechargeFoyerPage.plusDe(_ibrahim)));
      expect(_texte('Remise de paiement d\'avance (5 %)'), findsOneWidget);
      expect(
        _texte('Pas de remise de paiement d\'avance en dessous'),
        findsNothing,
      );
      expect(
        _texte('Pas de remise de famille : premier inscrit.'),
        findsOneWidget,
      );
    },
  );

  for (final double largeur in <double>[1280, 1440]) {
    testWidgets(
      '$largeur : l explication reste dans la colonne des profils, rien ne deborde',
      (WidgetTester tester) async {
        await _monter(
          tester,
          port: _PortExplique(),
          taille: Size(largeur, 1800),
        );
        await _taper(tester, find.byKey(RechargeFoyerPage.caseDe(_mariam)));
        await _taper(tester, find.byKey(RechargeFoyerPage.plusDe(_mariam)));
        await _taper(tester, find.byKey(RechargeFoyerPage.plusDe(_mariam)));
        final Size explication = tester.getSize(
          find.byKey(RechargeFoyerPage.explicationDe(_mariam)),
        );
        final Size profils = tester.getSize(
          find.byKey(RechargeFoyerPage.profilsKey),
        );
        expect(explication.width, lessThanOrEqualTo(profils.width));
        expect(explication.width, lessThan(largeur / 2));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('320 px, texte x2 : l explication se lit sans deborder', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      port: _PortExplique(),
      taille: const Size(320, 3600),
      echelle: 2,
    );
    await _taper(tester, find.byKey(RechargeFoyerPage.caseDe(_mariam)));
    await _taper(tester, find.byKey(RechargeFoyerPage.plusDe(_mariam)));
    expect(
      find.byKey(RechargeFoyerPage.explicationDe(_mariam)),
      findsOneWidget,
    );
    expect(_texte('Vous payez d\'abord'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
