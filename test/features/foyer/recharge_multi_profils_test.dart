// FI-7 (guide Finance V4 §1.6, §4, §5.3, §8 LOT F4 ; maquettes 04 et 07) :
// la recharge multi-profils du tuteur, UN seul moteur (`RechargeFoyerPage`)
// sur `/tuteur/foyer/recharge`. Un, plusieurs ou tous les profils ; un
// montant par profil, desactive tant que le profil n'est pas coche ; le
// total RENDU par le port, jamais additionne a l'ecran ; le seul paiement
// web (ni App Store ni Play) ; « Recharger Ibrahim » (Foyer) et « Recharger »
// (Compte > Paiements) ouvrent la meme route ; hors ligne, erreur,
// production indisponible ; 320 px a 200 % et 1440 px, LTR et RTL, clair et
// sombre.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/capacites/port_paiements_foyer.dart';
import 'package:rewayah_academy/core/capacites/port_politiques_commerciales.dart';
import 'package:rewayah_academy/core/capacites/port_recharge_foyer.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/finance/finances_profil.dart';
import 'package:rewayah_academy/core/finance/format_montant.dart';
import 'package:rewayah_academy/core/finance/montant.dart';
import 'package:rewayah_academy/core/finance/politique_commerciale.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/bouton_icone.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/ligne_moyen_paiement.dart';
import 'package:rewayah_academy/features/compte/paiements_page.dart';
import 'package:rewayah_academy/features/demo/finance_demo.dart';
import 'package:rewayah_academy/features/foyer/foyer_page.dart';
import 'package:rewayah_academy/features/foyer/invitation_conjoint.dart';

import '../../router/support_routeur.dart';
import '../../support/garde_interface.dart';
import '../../support/harnais.dart';

const String _mariam = DonneesFinanceDemo.mariamId;
const String _ibrahim = DonneesFinanceDemo.ibrahimId;
const String _aicha = DonneesFinanceDemo.aichaId;

/// Le foyer du jeu [jeu] : les memes identifiants que ses finances.
FauxServiceAppairage _foyer(JeuFoyerFinance jeu) =>
    FauxServiceAppairage()
      ..elevesRendus = <EleveDuFoyer>[
        for (final FinancesProfil p in DonneesFinanceDemo.profils(jeu))
          EleveDuFoyer(
            id: p.profilId,
            prenom: p.prenom,
            identifiantImmuable: 'STUD-FI-${p.profilId}',
            mode: InterfaceMode.standard,
            camera: CameraPolicy.allowed,
          ),
      ];

/// Monte l'application du tuteur sur le VRAI routeur, puis va a [depart].
Future<GoRouter> _monter(
  WidgetTester tester, {
  JeuFoyerFinance jeu = JeuFoyerFinance.tousFinances,
  String depart = Routes.tuteurFoyerRecharge,
  bool avecFinances = true,
  PortRechargeFoyer? port,
  PortPolitiquesCommerciales? politiques,
  bool horsLigne = false,
  Size taille = const Size(390, 2400),
  double echelle = 1,
  TextDirection direction = TextDirection.ltr,
  Brightness luminosite = Brightness.light,
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
          appairage: _foyer(jeu),
        ),
        horsLigneProvider.overrideWith(
          (Ref _) => Stream<bool>.value(horsLigne),
        ),
        if (avecFinances) ...<Override>[
          portPaiementsFoyerProvider.overrideWithValue(
            PaiementsFoyerFinanceDemo(jeu),
          ),
          portPolitiquesCommercialesProvider.overrideWithValue(
            politiques ?? const PolitiquesCommercialesDemo(),
          ),
          portRechargeFoyerProvider.overrideWithValue(
            port ?? RechargeFoyerFinanceDemo(jeu),
          ),
        ],
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
                theme: AppTheme.pour(InterfaceMode.standard, luminosite),
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
  routeur.go(depart);
  await stabiliser(tester);
  return routeur;
}

Future<void> _taper(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await stabiliser(tester);
}

Future<void> _cocher(WidgetTester tester, String id) =>
    _taper(tester, find.byKey(RechargeFoyerPage.caseDe(id)));

/// [pas] appuis sur « plus » : le [pas]-ieme montant propose.
Future<void> _plus(WidgetTester tester, String id, int pas) async {
  for (int i = 0; i < pas; i++) {
    await _taper(tester, find.byKey(RechargeFoyerPage.plusDe(id)));
  }
}

bool _coche(WidgetTester tester, String id) =>
    tester.widget<Checkbox>(find.byKey(RechargeFoyerPage.caseDe(id))).value ??
    false;

bool _actif(WidgetTester tester, Key cle) =>
    find.byKey(cle).evaluate().isNotEmpty &&
    tester.widget<BoutonIcone>(find.byKey(cle)).onPress != null;

VoidCallback? _verifier(WidgetTester tester) => tester
    .widget<ActionPrincipale>(find.byKey(RechargeFoyerPage.verifierKey))
    .onPress;

Finder _dans(Key parent, Finder f) =>
    find.descendant(of: find.byKey(parent), matching: f);

/// Le montant affiche pour [id] a l'etape 1.
String _montantAffiche(WidgetTester tester, String id) => tester
    .widget<Text>(_dans(RechargeFoyerPage.montantDe(id), find.byType(Text)))
    .data!;

/// Un port qui garde les montants envoyes et rend un total qui n'est la
/// somme de rien : l'ecran doit l'afficher tel quel.
class _PortEspion extends RechargeFoyerFinanceDemo {
  _PortEspion({this.echec = false}) : super(JeuFoyerFinance.tousFinances);

  final bool echec;
  final List<List<MontantRecharge>> envois = <List<MontantRecharge>>[];

  @override
  Future<RecapitulatifRecharge> verifierMontants(
    List<MontantRecharge> choix,
  ) async {
    envois.add(choix);
    if (echec) throw StateError('coupure');
    final RecapitulatifRecharge r = await super.verifierMontants(choix);
    return RecapitulatifRecharge(
      id: r.id,
      lignes: r.lignes,
      total: 'TOTAL-ARRETE-PAR-LE-PORT',
    );
  }
}

/// Une politique qui liste aussi les rails de magasin : l'ecran ne les rend
/// jamais (guide §1.6).
class _PolitiqueTousRails implements PortPolitiquesCommerciales {
  const _PolitiqueTousRails();

  static PolitiqueCommerciale get _p {
    final PolitiqueCommerciale l = DonneesFinanceDemo.politiqueLancement;
    return PolitiqueCommerciale(
      version: l.version,
      statut: l.statut,
      dateEffet: l.dateEffet,
      tarifEnfant: l.tarifEnfant,
      tarifAdulte: l.tarifAdulte,
      essaisMax: l.essaisMax,
      remisesParRang: l.remisesParRang,
      baseHoraire: l.baseHoraire,
      plafondHoraire: l.plafondHoraire,
      capaciteEnfant: l.capaciteEnfant,
      capaciteAdulte: l.capaciteAdulte,
      capaciteDebutant: l.capaciteDebutant,
      minimumOuverture: l.minimumOuverture,
      groupesObjectif: l.groupesObjectif,
      groupesMax: l.groupesMax,
      joursConservationPlace: l.joursConservationPlace,
      margeReferencePourMille: l.margeReferencePourMille,
      railsActifs: RailPaiement.values.toSet(),
    );
  }

  @override
  Future<PolitiqueCommerciale> active() async => _p;

  @override
  Future<List<PolitiqueCommerciale>> versions() async => <PolitiqueCommerciale>[
    _p,
  ];
}

void main() {
  testWidgets('un profil : montant choisi, recapitulatif et total rendus, '
      'paiement web seul, etat honnete', (WidgetTester tester) async {
    await _monter(tester, jeu: JeuFoyerFinance.unProfil);
    expect(find.byType(RechargeFoyerPage), findsOneWidget);
    expect(find.text(t.adulte.recharge.titre), findsOneWidget);
    expect(find.text(t.adulte.recharge.profils), findsOneWidget);
    expect(find.byKey(RechargeFoyerPage.repartitionKey), findsOneWidget);
    // Non coche : montant desactive, « 0 $ », la raison du bouton inactif.
    expect(_coche(tester, _mariam), isFalse);
    expect(_actif(tester, RechargeFoyerPage.plusDe(_mariam)), isFalse);
    expect(
      _montantAffiche(tester, _mariam),
      formaterMontant(const Montant(0, 'USD')),
    );
    expect(find.text(t.adulte.recharge.raisonAucun), findsOneWidget);
    expect(_verifier(tester), isNull);

    await _cocher(tester, _mariam);
    expect(find.text(t.adulte.recharge.raisonMontant), findsOneWidget);
    await _plus(tester, _mariam, 1);
    expect(
      _montantAffiche(tester, _mariam),
      formaterMontant(DonneesFinanceDemo.usd(10)),
    );
    expect(find.byKey(RechargeFoyerPage.raisonKey), findsNothing);
    await _taper(tester, find.byKey(RechargeFoyerPage.verifierKey));

    expect(find.text(t.adulte.recharge.verifierTitre), findsOneWidget);
    expect(find.byKey(RechargeFoyerPage.ligneDe(_mariam)), findsOneWidget);
    final String total = formaterMontant(DonneesFinanceDemo.usd(10));
    expect(_dans(RechargeFoyerPage.totalKey, find.text(total)), findsOneWidget);
    expect(
      _dans(
        RechargeFoyerPage.totalKey,
        find.text(t.adulte.recharge.repartition),
      ),
      findsOneWidget,
    );
    expect(find.byType(LigneMoyenPaiement), findsOneWidget);
    expect(find.text(t.adulte.recharge.payer(montant: total)), findsOneWidget);
    verifierUnSeulBoutonPlein(tester);

    await _taper(tester, find.byKey(RechargeFoyerPage.payerKey));
    expect(
      find.text(t.adulte.recharge.paiementIndisponibleTitre),
      findsOneWidget,
    );
    expect(find.textContaining(RegExp(r'réussi|confirmé$')), findsNothing);
    expect(find.byKey(RechargeFoyerPage.payerKey), findsNothing);
  });

  testWidgets('plusieurs profils : Mariam +10, Ibrahim +40 ; le port recoit '
      'chaque montant et arrete le total, que l ecran affiche tel quel', (
    WidgetTester tester,
  ) async {
    final _PortEspion port = _PortEspion();
    await _monter(tester, port: port);
    await _cocher(tester, _mariam);
    await _plus(tester, _mariam, 1);
    await _cocher(tester, _ibrahim);
    await _plus(tester, _ibrahim, 4);
    // Aicha n'est pas cochee : son montant reste desactive.
    expect(_actif(tester, RechargeFoyerPage.plusDe(_aicha)), isFalse);
    await _taper(tester, find.byKey(RechargeFoyerPage.verifierKey));

    expect(port.envois, hasLength(1));
    expect(
      <String, Montant>{
        for (final MontantRecharge m in port.envois.single)
          m.beneficiaireId: m.montant,
      },
      <String, Montant>{
        _mariam: DonneesFinanceDemo.usd(10),
        _ibrahim: DonneesFinanceDemo.usd(40),
      },
    );
    // A qui va chaque montant (guide §5.3) : une ligne par profil.
    expect(
      _dans(
        RechargeFoyerPage.ligneDe(_mariam),
        find.text(formaterMontant(DonneesFinanceDemo.usd(10))),
      ),
      findsOneWidget,
    );
    expect(
      _dans(
        RechargeFoyerPage.ligneDe(_ibrahim),
        find.text(formaterMontant(DonneesFinanceDemo.usd(40))),
      ),
      findsOneWidget,
    );
    expect(find.byKey(RechargeFoyerPage.ligneDe(_aicha)), findsNothing);
    // Le total est celui du port, jamais une addition de l'ecran.
    expect(
      _dans(RechargeFoyerPage.totalKey, find.text('TOTAL-ARRETE-PAR-LE-PORT')),
      findsOneWidget,
    );
    expect(
      find.text(formaterMontant(DonneesFinanceDemo.usd(50))),
      findsNothing,
    );

    // « Modifier » : retour sans perte, le montant d'Ibrahim garde.
    await _taper(tester, find.byKey(RechargeFoyerPage.modifierDe(_ibrahim)));
    expect(_coche(tester, _mariam), isTrue);
    expect(_coche(tester, _ibrahim), isTrue);
    expect(
      _montantAffiche(tester, _ibrahim),
      formaterMontant(DonneesFinanceDemo.usd(40)),
    );
  });

  testWidgets('tous les profils : « Tout selectionner », un montant pour '
      'chacun, cinq lignes au recapitulatif', (WidgetTester tester) async {
    await _monter(tester, jeu: JeuFoyerFinance.cinqProfils);
    final List<String> ids = <String>[
      for (final FinancesProfil p in DonneesFinanceDemo.profils(
        JeuFoyerFinance.cinqProfils,
      ))
        p.profilId,
    ];
    await _taper(tester, find.byKey(RechargeFoyerPage.toutSelectionnerKey));
    for (final String id in ids) {
      expect(_coche(tester, id), isTrue);
      expect(_actif(tester, RechargeFoyerPage.plusDe(id)), isTrue);
    }
    expect(find.text(t.adulte.recharge.toutDeselectionner), findsOneWidget);
    expect(_verifier(tester), isNull);
    expect(find.text(t.adulte.recharge.raisonMontant), findsOneWidget);
    for (final String id in ids) {
      await _plus(tester, id, 1);
    }
    expect(_verifier(tester), isNotNull);
    await _taper(tester, find.byKey(RechargeFoyerPage.verifierKey));
    for (final String id in ids) {
      expect(find.byKey(RechargeFoyerPage.ligneDe(id)), findsOneWidget);
    }
    expect(
      _dans(
        RechargeFoyerPage.totalKey,
        find.text(formaterMontant(DonneesFinanceDemo.usd(50))),
      ),
      findsOneWidget,
    );
  });

  testWidgets('deselection et montant 0 : le montant se desactive, rien ne '
      'part sans montant', (WidgetTester tester) async {
    await _monter(tester);
    await _cocher(tester, _mariam);
    await _plus(tester, _mariam, 2);
    expect(_verifier(tester), isNotNull);
    // Decochee : montant desactive (« 0 »), plus rien a verifier.
    await _cocher(tester, _mariam);
    expect(_actif(tester, RechargeFoyerPage.plusDe(_mariam)), isFalse);
    expect(_actif(tester, RechargeFoyerPage.moinsDe(_mariam)), isFalse);
    expect(
      _montantAffiche(tester, _mariam),
      formaterMontant(const Montant(0, 'USD')),
    );
    expect(_verifier(tester), isNull);
    // Recochee : son montant revient (W-337).
    await _cocher(tester, _mariam);
    expect(
      _montantAffiche(tester, _mariam),
      formaterMontant(DonneesFinanceDemo.usd(20)),
    );
    // Ramene a 0 : la raison est dite, « moins » s'arrete.
    await _taper(tester, find.byKey(RechargeFoyerPage.moinsDe(_mariam)));
    await _taper(tester, find.byKey(RechargeFoyerPage.moinsDe(_mariam)));
    expect(_actif(tester, RechargeFoyerPage.moinsDe(_mariam)), isFalse);
    expect(find.text(t.adulte.recharge.raisonMontant), findsOneWidget);
    expect(_verifier(tester), isNull);
  });

  testWidgets('« Recharger Ibrahim » depuis le Foyer : la meme route, Ibrahim '
      'coche, le manque suggere et retenu', (WidgetTester tester) async {
    final GoRouter routeur = await _monter(
      tester,
      jeu: JeuFoyerFinance.unARegulariser,
      depart: Routes.tuteurFoyer,
    );
    await _taper(tester, find.byKey(FoyerPage.rechargerPourKey(_ibrahim)));
    expect(routeur.state.uri.path, Routes.tuteurFoyerRecharge);
    expect(_coche(tester, _ibrahim), isTrue);
    expect(_coche(tester, _mariam), isFalse);
    final String manque = formaterMontant(DonneesFinanceDemo.usd(8));
    expect(_montantAffiche(tester, _ibrahim), manque);
    expect(
      find.text(t.adulte.recharge.montantSuggere(montant: manque)),
      findsOneWidget,
    );
    expect(_verifier(tester), isNotNull);
  });

  testWidgets('?profils=inconnu : rien n est coche, rien n est bloque, la '
      'raison reste juste', (WidgetTester tester) async {
    await _monter(tester, depart: Routes.rechargePour(<String>['inconnu']));
    for (final String id in <String>[_mariam, _ibrahim, _aicha]) {
      expect(_coche(tester, id), isFalse);
    }
    expect(find.text(t.adulte.recharge.raisonAucun), findsOneWidget);
    expect(find.text(t.adulte.recharge.raisonMontant), findsNothing);
    await _cocher(tester, _mariam);
    await _plus(tester, _mariam, 1);
    expect(find.byKey(RechargeFoyerPage.raisonKey), findsNothing);
    expect(_verifier(tester), isNotNull);
    await _taper(tester, find.byKey(RechargeFoyerPage.verifierKey));
    expect(find.byKey(RechargeFoyerPage.ligneDe(_mariam)), findsOneWidget);
  });

  testWidgets('?profils=inconnu,Mariam : Mariam cochee, l inconnu ignore', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      depart: Routes.rechargePour(<String>['inconnu', _mariam]),
    );
    expect(_coche(tester, _mariam), isTrue);
    expect(find.text(t.adulte.recharge.raisonMontant), findsOneWidget);
    expect(find.text(t.adulte.recharge.raisonAucun), findsNothing);
    await _plus(tester, _mariam, 1);
    expect(find.byKey(RechargeFoyerPage.raisonKey), findsNothing);
    expect(_verifier(tester), isNotNull);
    // « Tout selectionner » ne compte que les profils rendus.
    expect(find.text(t.adulte.recharge.toutSelectionner), findsOneWidget);
  });

  testWidgets('Compte > Paiements : « Recharger » ouvre LA meme route ; sans '
      'finances, aucun raccourci', (WidgetTester tester) async {
    final GoRouter routeur = await _monter(
      tester,
      depart: Routes.compteTuteurSousPage('paiements'),
    );
    expect(find.byType(PaiementsComptePage), findsOneWidget);
    await _taper(tester, find.byKey(PaiementsComptePage.rechargerKey));
    expect(routeur.state.uri.path, Routes.tuteurFoyerRecharge);
    expect(find.byType(RechargeFoyerPage), findsOneWidget);
    expect(find.byType(PaiementsComptePage), findsNothing);
  });

  testWidgets('Compte > Paiements sans source (production) : aucun raccourci', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      avecFinances: false,
      depart: Routes.compteTuteurSousPage('paiements'),
    );
    expect(find.byType(PaiementsComptePage), findsOneWidget);
    expect(find.byKey(PaiementsComptePage.rechargerKey), findsNothing);
  });

  testWidgets('StoreKit et Play jamais montres, meme ouverts par la '
      'politique', (WidgetTester tester) async {
    await _monter(tester, politiques: const _PolitiqueTousRails());
    await _cocher(tester, _mariam);
    await _plus(tester, _mariam, 1);
    await _taper(tester, find.byKey(RechargeFoyerPage.verifierKey));
    final Iterable<LigneMoyenPaiement> lignes = tester
        .widgetList<LigneMoyenPaiement>(find.byType(LigneMoyenPaiement));
    expect(lignes.map((LigneMoyenPaiement l) => l.rail), <RailPaiement>[
      RailPaiement.webStripe,
    ]);
    expect(lignes.single.retenu, isTrue);
    expect(find.textContaining(RegExp('App Store|Play')), findsNothing);
  });

  testWidgets('hors ligne : rien ne part, la raison dite', (
    WidgetTester tester,
  ) async {
    await _monter(tester, horsLigne: true);
    await _cocher(tester, _mariam);
    await _plus(tester, _mariam, 1);
    expect(_verifier(tester), isNull);
    expect(find.text(t.adulte.recharge.horsLigneVerifier), findsOneWidget);
  });

  testWidgets('erreur de verification : dite, les choix gardes', (
    WidgetTester tester,
  ) async {
    await _monter(tester, port: _PortEspion(echec: true));
    await _cocher(tester, _mariam);
    await _plus(tester, _mariam, 1);
    await _taper(tester, find.byKey(RechargeFoyerPage.verifierKey));
    expect(find.text(t.adulte.recharge.verificationEchecTitre), findsOneWidget);
    expect(_coche(tester, _mariam), isTrue);
    expect(_verifier(tester), isNotNull);
  });

  testWidgets('production : la recharge se dit indisponible, sans bouton', (
    WidgetTester tester,
  ) async {
    await _monter(tester, avecFinances: false);
    final EtatSysteme e = tester.widget<EtatSysteme>(find.byType(EtatSysteme));
    expect(e.nature, NatureEtat.indisponible);
    expect(e.dependance, 'EA-BR-24');
    expect(find.byKey(RechargeFoyerPage.verifierKey), findsNothing);
    expect(find.byType(LigneMoyenPaiement), findsNothing);
  });

  group('responsive : 320 a 200 % et 1440, LTR et RTL, clair et sombre', () {
    for (final (Size taille, double echelle) in <(Size, double)>[
      (const Size(320, 4000), 2),
      (const Size(1440, 1600), 1),
    ]) {
      for (final TextDirection direction in TextDirection.values) {
        for (final Brightness luminosite in Brightness.values) {
          testWidgets(
            '${taille.width.toInt()} px x$echelle, ${direction.name}, '
            '${luminosite.name}',
            (WidgetTester tester) async {
              await _monter(
                tester,
                taille: taille,
                echelle: echelle,
                direction: direction,
                luminosite: luminosite,
              );
              expect(tester.takeException(), isNull);
              await _cocher(tester, _mariam);
              await _plus(tester, _mariam, 1);
              await _cocher(tester, _ibrahim);
              await _plus(tester, _ibrahim, 4);
              expect(tester.takeException(), isNull);
              verifierUnSeulBoutonPlein(tester);
              // Le montant reste dans la ligne de son profil.
              final Rect ligne = tester.getRect(
                find.byKey(RechargeFoyerPage.profilDe(_mariam)),
              );
              final Rect montant = tester.getRect(
                find.byKey(RechargeFoyerPage.plusDe(_mariam)),
              );
              expect(ligne.contains(montant.center), isTrue);
              await _taper(tester, find.byKey(RechargeFoyerPage.verifierKey));
              expect(tester.takeException(), isNull);
              verifierUnSeulBoutonPlein(tester);
              // « Payer » au bord de fin du moyen de paiement.
              final Rect payer = tester.getRect(
                find.byKey(RechargeFoyerPage.payerKey),
              );
              final Rect moyen = tester.getRect(
                find.byKey(RechargeFoyerPage.moyenKey),
              );
              if (direction == TextDirection.ltr) {
                expect(
                  payer.right,
                  moreOrLessEquals(moyen.right, epsilon: 0.5),
                );
              } else {
                expect(payer.left, moreOrLessEquals(moyen.left, epsilon: 0.5));
              }
            },
          );
        }
      }
    }
  });
}
