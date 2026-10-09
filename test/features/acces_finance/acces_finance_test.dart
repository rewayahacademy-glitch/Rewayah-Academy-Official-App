// FI-9a : acces, essai et impaye, pour l'enfant, le tuteur et l'eleve adulte
// autonome (guide Finance V4 §1.2, §1.7, §8 F5 ; revue FI-1a:77).
//
// Ce que ces tests tiennent :
// - l'enfant ne lit jamais une cause financiere : ni « payé », ni « manque »,
//   ni « USD », ni un montant, et son ecran ne lit jamais la finance ;
// - le tuteur et l'adulte autonome lisent le manque exact, mis en mots par
//   `formaterMontant`, et le mois du debit attendu, rendus par la source ;
// - « Essai\u00A0: n/2 » vient des compteurs rendus ;
// - Rejoindre depend de la periode financee, jamais du solde ;
// - production (ports neutres), echec, hors ligne : rien n'est invente ;
// - 320 px, texte 200 %, clair et sombre, LTR et RTL, sans debordement.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/capacites/port_acces_foyer.dart';
import 'package:rewayah_academy/core/capacites/port_identite_titulaire.dart';
import 'package:rewayah_academy/core/capacites/port_mes_finances.dart';
import 'package:rewayah_academy/core/capacites/port_paiements_foyer.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/finance/finances_profil.dart';
import 'package:rewayah_academy/core/finance/format_montant.dart';
import 'package:rewayah_academy/core/finance/mouvements_profil.dart';
import 'package:rewayah_academy/core/i18n/elision.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/priere/service_priere.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/tc_horloge/demonstration_horloge.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/bandeau_attention.dart';
import 'package:rewayah_academy/core/widgets/pastille_financiere.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';
import 'package:rewayah_academy/features/acces_finance/acces_finance.dart';
import 'package:rewayah_academy/features/accueil_eleve/accueil_accessibilite.dart';
import 'package:rewayah_academy/features/accueil_eleve/accueil_eleve_page.dart';
import 'package:rewayah_academy/features/compte/acces_page.dart';
import 'package:rewayah_academy/features/compte/donnees_compte.dart';
import 'package:rewayah_academy/features/demo/accessibilite_demo.dart';
import 'package:rewayah_academy/features/demo/demo_accessibilite_page.dart';
import 'package:rewayah_academy/features/demo/finance_demo.dart';
import 'package:rewayah_academy/features/foyer/fiche/acces_page.dart';
import 'package:rewayah_academy/features/foyer/foyer_page.dart';
import 'package:rewayah_academy/features/mon_espace_adulte/mon_espace_adulte_page.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/carte_session.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/espace_groupe_page.dart';
import 'package:rewayah_academy/features/tc_mes_groupes/carte_groupe.dart';
import 'package:rewayah_academy/features/tc_mes_groupes/mes_groupes_page.dart';

import '../../router/support_routeur.dart';
import '../../support/harnais.dart';
import '../../teaching_core/a/support/hote_tc_a.dart';

/// L'instant de reference : le 4 octobre 2026, jour de la demonstration.
final DateTime _maintenant = DateTime(2026, 10, 4, 17);

/// Les acces du foyer rendus tels quels.
class _AccesFixes implements PortAccesFoyer {
  const _AccesFixes(this.rendus);

  final List<AccesBeneficiaire> rendus;

  @override
  Future<List<AccesBeneficiaire>> acces() async => rendus;
}

/// L'acces de l'eleve connecte, borne a sa session (FI-BR-08, revue
/// FI-VAGUE-R R4-02) : sa seule ligne, aucune, ou un echec.
class _MonAccesFixe implements PortMonAcces {
  const _MonAccesFixe(this.rendu, {this.echec = false});

  final AccesBeneficiaire? rendu;
  final bool echec;

  @override
  Future<AccesBeneficiaire?> monAcces() async {
    if (echec) throw Exception('lecture de l acces refusee');
    return rendu;
  }
}

/// L'acces de l'eleve connecte, rendu a la demande du test.
class _MonAccesEnAttente implements PortMonAcces {
  final Completer<AccesBeneficiaire?> reponse = Completer<AccesBeneficiaire?>();

  @override
  Future<AccesBeneficiaire?> monAcces() => reponse.future;
}

/// L'acces de la personne connectee, qui compte ses lectures et rend une
/// ligne distincte a chacune : une ligne lue pour une autre personne ne doit
/// jamais survivre a un changement de session.
class _MonAccesCompte implements PortMonAcces {
  int lectures = 0;

  @override
  Future<AccesBeneficiaire?> monAcces() async {
    lectures++;
    return AccesBeneficiaire(
      eleveId: 'lecture-$lectures',
      prenom: 'Aïcha',
      etatAffiche: EtatAccesAffiche.sansEcheance,
      seancesPayantesOuvertes: true,
    );
  }
}

/// Un port de l'acces du FOYER qui compte ses lectures : un ecran d'eleve ne
/// doit jamais en faire une (revue FI-VAGUE-R R4-02). Il rend les seances
/// d'Ibrahim fermees : si l'ecran le lisait, il le montrerait.
class _AccesFoyerEspion implements PortAccesFoyer {
  int lectures = 0;

  @override
  Future<List<AccesBeneficiaire>> acces() async {
    lectures++;
    return DonneesFinanceDemo.acces(JeuFoyerFinance.unARegulariser);
  }
}

/// Un port des paiements qui compte ses lectures de finance : l'ecran de
/// l'enfant ne doit jamais en faire une (lecon 15).
class _PaiementsEspion implements PortPaiementsFoyer {
  _PaiementsEspion(this.foyer);

  final FinancesFoyer foyer;
  int lecturesFinances = 0;

  @override
  Future<FinancesFoyer> finances() async {
    lecturesFinances++;
    return foyer;
  }

  @override
  Future<List<PaiementFoyer>> historique() async => const <PaiementFoyer>[];

  @override
  Future<PaiementFoyer?> detail(String id) async => null;

  @override
  Future<SoldesFoyer> soldes() => throw UnimplementedError();

  @override
  Future<List<MouvementProfil>> mouvements(String profilId) async =>
      const <MouvementProfil>[];

  @override
  Future<List<MouvementFoyer>> derniersMouvements({int limite = 3}) async =>
      const <MouvementFoyer>[];
}

/// L'acces d'Aicha apres ses deux essais, sans periode financee (FIN4-13).
const AccesBeneficiaire _essaisEpuises = AccesBeneficiaire(
  eleveId: DonneesFinanceDemo.aichaId,
  prenom: 'Aïcha',
  etatAffiche: EtatAccesAffiche.sansEcheance,
  seancesPayantesOuvertes: false,
  essaisUtilises: 2,
  essaisMax: 2,
);

AccesBeneficiaire _acces(JeuFoyerFinance jeu, String id) =>
    DonneesFinanceDemo.acces(jeu).firstWhere((AccesBeneficiaire a) {
      return a.eleveId == id;
    });

FinancesProfil _finance(JeuFoyerFinance jeu, String id) =>
    DonneesFinanceDemo.profils(jeu).firstWhere((FinancesProfil p) {
      return p.profilId == id;
    });

/// L'eleve adulte autonome a regulariser : 52 $ sur 60, janvier a financer
/// (l'exemple du guide §1.7).
final FinancesProfil _adulteARegulariser = FinancesProfil(
  profilId: 'adulte-autonome',
  prenom: 'Youssouf',
  cleAccent: 'accent-adulte',
  estAdulte: true,
  etat: EtatFinancier.aRegulariser,
  solde: DonneesFinanceDemo.usd(52),
  mensualite: DonneesFinanceDemo.usd(60),
  prochainDebit: ProchainDebit(
    date: DateTime(2027),
    montant: DonneesFinanceDemo.usd(60),
  ),
  manque: DonneesFinanceDemo.usd(8),
  finConservation: DateTime(2027, 1, 8),
);

FinancesFoyer _foyerDe(FinancesProfil p) => FinancesFoyer(
  synthese: SyntheseFoyer(
    totalSoldes: p.solde,
    aPayerCeMois: p.manque ?? DonneesFinanceDemo.usd(0),
    profilsFinances: 0,
    profils: 1,
    paiementsDuMois: 0,
  ),
  profils: <FinancesProfil>[p],
);

/// L'hote d'un ecran : largeur, texte agrandi, sens et theme au choix.
Widget _hote(
  Widget ecran, {
  List<Override> surcharges = const <Override>[],
  double echelle = 1,
  TextDirection sens = TextDirection.ltr,
  Brightness luminosite = Brightness.light,
}) => ProviderScope(
  overrides: <Override>[
    // R7-04 : les lectures d'argent suivent la session ; sans source de
    // session fournie par le test, aucune personne connectee.
    if (!surcharges.any((Override o) => o.origin == sourceSessionProvider))
      sansPersonneConnectee(),
    ...surcharges,
  ],
  child: TranslationProvider(
    child: MaterialApp(
      theme: AppTheme.pour(InterfaceMode.standard, luminosite),
      locale: AppLocale.fr.flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Builder(
        builder: (BuildContext context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(echelle),
            disableAnimations: true,
          ),
          child: Directionality(textDirection: sens, child: ecran),
        ),
      ),
    ),
  ),
);

void _taille(WidgetTester tester, Size taille) {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Les textes rendus, y compris ceux des `RichText`.
List<String> _textes(WidgetTester tester) => <String>[
  for (final Text texte in tester.widgetList<Text>(find.byType(Text)))
    ?texte.data,
  for (final RichText r in tester.widgetList<RichText>(find.byType(RichText)))
    r.text.toPlainText(),
];

// ---------------------------------------------------------------------------
// Enfant : accueil eleve.

/// Le cours en direct de l'eleve [eleveId].
Seance _coursEnDirect(String eleveId) => Seance(
  id: 's1',
  debut: _maintenant.subtract(const Duration(minutes: 10)),
  fin: _maintenant.add(const Duration(minutes: 50)),
  statut: StatutSeance.enCours,
  eleveId: eleveId,
  elevePrenom: 'Ibrahim',
  eleveIdentifiant: 'STUD-FI-000002',
  enseignantId: 't1',
  enseignantPrenom: 'Aminata',
  enseignantIdentifiant: 'TEACH-AD-000001',
);

List<Override> _surchargesEnfant({
  required String eleveId,
  PortMonAcces? acces,
  PortAccesFoyer? foyer,
  PortPaiementsFoyer? paiements,
  bool horsLigne = false,
}) => <Override>[
  servicePlanningProvider.overrideWithValue(
    FauxServicePlanning()..seancesRendues = <Seance>[_coursEnDirect(eleveId)],
  ),
  servicePriereProvider.overrideWithValue(FauxServicePriere()),
  serviceReseauProvider.overrideWithValue(
    FauxServiceReseau(horsLigneRendu: horsLigne),
  ),
  // L'acces est relu par personne connectee : la session la nomme.
  sourceSessionProvider.overrideWithValue(
    FausseSourceSession(sessionActive(AppRole.student)),
  ),
  if (acces != null) portMonAccesProvider.overrideWithValue(acces),
  if (foyer != null) portAccesFoyerProvider.overrideWithValue(foyer),
  if (paiements != null)
    portPaiementsFoyerProvider.overrideWithValue(paiements),
];

/// L'acces d'Ibrahim, connecte, dans le jeu [jeu].
MonAccesFinanceDemo _ibrahim(JeuFoyerFinance jeu, {EtatPlace? place}) =>
    MonAccesFinanceDemo(jeu, DonneesFinanceDemo.ibrahimId, place: place);

Widget _accueil() => AccueilElevePage(horloge: () => _maintenant);

/// Le bouton Rejoindre, s'il est rendu.
Finder get _rejoindre => find.byWidgetPredicate(
  (Widget w) => w is ActionPrincipale && w.libelle == t.eleve.accueil.rejoindre,
);

/// Aucune cause financiere, aucun montant, aucune devise (guide §1.7).
void _verifierSansCauseFinanciere(WidgetTester tester) {
  final RegExp interdit = RegExp(
    r'pay|manque|usd|\$|€|solde|régularis|financ|\d',
    caseSensitive: false,
  );
  for (final String texte in _textes(tester)) {
    // Les chiffres de l'horloge et du compte a rebours ne sont pas sur
    // l'ecran d'un cours en direct : tout chiffre serait un montant.
    expect(interdit.hasMatch(texte), isFalse, reason: texte);
  }
}

/// La fiche eleve > Acces sur le vrai routeur, session tuteur (FI-9a).
Future<void> _monterFicheAcces(
  WidgetTester tester, {
  required JeuFoyerFinance jeu,
  required String eleveId,
  bool finance = true,
  Size taille = const Size(390, 844),
  PortAccesFoyer? acces,
  PortPaiementsFoyer? paiements,
  Map<String, EtatPlace> places = const <String, EtatPlace>{},
  double echelle = 1,
  TextDirection sens = TextDirection.ltr,
}) async {
  _taille(tester, taille);
  final FinancesProfil profil = _finance(jeu, eleveId);
  final FauxServiceAppairage appairage = FauxServiceAppairage()
    ..elevesRendus = <EleveDuFoyer>[
      EleveDuFoyer(
        id: eleveId,
        prenom: profil.prenom,
        identifiantImmuable: 'STUD-FI-000002',
        mode: InterfaceMode.standard,
        camera: CameraPolicy.forbidden,
        finAcces: _acces(jeu, eleveId).finAcces,
      ),
    ];
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesRouteur(
          FausseSourceSession(sessionActive(AppRole.guardian)),
          appairage: appairage,
        ),
        horlogeFoyerProvider.overrideWithValue(() => _maintenant),
        portAccesFoyerProvider.overrideWithValue(
          acces ?? AccesFoyerFinanceDemo(jeu, places: places),
        ),
        if (finance)
          portPaiementsFoyerProvider.overrideWithValue(
            paiements ?? PaiementsFoyerFinanceDemo(jeu),
          ),
      ],
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext _, WidgetRef ref, Widget? _) {
            routeur = ref.read(routeurProvider);
            return MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              routerConfig: routeur,
              builder: (BuildContext context, Widget? enfant) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(echelle)),
                child: Directionality(
                  textDirection: sens,
                  child: enfant ?? const SizedBox.shrink(),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(Routes.ficheEleveSousPage(eleveId, 'acces'));
  await stabiliser(tester);
}

/// L'eleve adulte autonome dans Mon espace (FI-9b).
List<Override> _surchargesAdulte({
  PortPaiementsFoyer? paiements,
  PortMonAcces? acces,
  PortAccesFoyer? foyer,
  LigneFamilleAdulte? ligne = LigneFamilleAdulte.ajouterMaFamille,
}) => <Override>[
  horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
  identiteTitulaireProvider.overrideWith(
    (Ref _) async => const IdentiteTitulaire(
      prenom: 'Youssouf',
      nom: 'Diallo',
      methodeConnexion: MethodeConnexion.lienCourriel,
    ),
  ),
  monEspaceAdulteProvider.overrideWith(
    (Ref _) async => MonEspaceAdulteVM(ligneFamille: ligne),
  ),
  if (paiements != null) ...<Override>[
    portPaiementsFoyerProvider.overrideWithValue(paiements),
    // FI-9b : l'adulte seul lit ses finances par son propre port.
    portMesFinancesProvider.overrideWithValue(_MesFinancesDe(paiements)),
  ],
  // L'acces est relu par personne connectee : la session la nomme.
  sourceSessionProvider.overrideWithValue(
    FausseSourceSession(sessionActive(AppRole.student)),
  ),
  if (acces != null) portMonAccesProvider.overrideWithValue(acces),
  if (foyer != null) portAccesFoyerProvider.overrideWithValue(foyer),
];

void main() {
  group('regles pures', () {
    test('Rejoindre suit la periode financee, jamais le solde', () {
      // Ibrahim a 0 $ et son mois est finance : ouvert (FIN4-08).
      expect(
        _finance(
          JeuFoyerFinance.tousFinances,
          DonneesFinanceDemo.ibrahimId,
        ).solde.estNul,
        isTrue,
      );
      expect(
        ouvertureSeances(
          _acces(JeuFoyerFinance.tousFinances, DonneesFinanceDemo.ibrahimId),
        ),
        OuvertureSeances.ouvertes,
      );
      // Ibrahim a 42 $ et sa nouvelle periode n'est pas financee : ferme.
      expect(
        _finance(
          JeuFoyerFinance.unARegulariser,
          DonneesFinanceDemo.ibrahimId,
        ).solde.mineur,
        greaterThan(0),
      );
      expect(
        ouvertureSeances(
          _acces(JeuFoyerFinance.unARegulariser, DonneesFinanceDemo.ibrahimId),
        ),
        OuvertureSeances.fermees,
      );
    });

    test('essai : 1/2 ouvert, 2/2 ferme, rien de suppose sans compteur', () {
      final AccesBeneficiaire essai = _acces(
        JeuFoyerFinance.unEnEssai,
        DonneesFinanceDemo.aichaId,
      );
      expect(ouvertureSeances(essai), OuvertureSeances.essai);
      expect(libelleEssai(essai), 'Essai\u00A0: 1/2');
      expect(ouvertureSeances(_essaisEpuises), OuvertureSeances.fermees);
      expect(libelleEssai(_essaisEpuises), 'Essai\u00A0: 2/2');
      expect(ouvertureSeances(null), OuvertureSeances.inconnue);
      expect(
        ouvertureSeances(
          const AccesBeneficiaire(
            eleveId: 'x',
            prenom: 'X',
            etatAffiche: EtatAccesAffiche.sansEcheance,
          ),
        ),
        OuvertureSeances.inconnue,
      );
    });

    test('tuteur : le manque exact et le mois du debit attendu', () {
      final FinancesProfil ibrahim = _finance(
        JeuFoyerFinance.unARegulariser,
        DonneesFinanceDemo.ibrahimId,
      );
      expect(aRegulariser(ibrahim), isTrue);
      expect(
        messageRegularisation(ibrahim),
        t.argent.acces.regulariserManque(
          montant: formaterMontant(DonneesFinanceDemo.usd(8)),
          mois: 'octobre',
        ),
      );
      expect(
        messageRegularisation(_adulteARegulariser),
        'Il manque 8 \$ pour financer janvier.',
      );
      expect(
        phraseConservation(ibrahim),
        t.argent.acces.placeConservee(date: '8 octobre 2026'),
      );
      // R8-05 : le premier du mois s'ecrit « 1er ».
      expect(
        phraseConservation(
          FinancesProfil(
            profilId: ibrahim.profilId,
            prenom: ibrahim.prenom,
            cleAccent: ibrahim.cleAccent,
            estAdulte: ibrahim.estAdulte,
            etat: ibrahim.etat,
            solde: ibrahim.solde,
            mensualite: ibrahim.mensualite,
            finConservation: DateTime(2026, 11, 1, 12),
          ),
        ),
        t.argent.acces.placeConservee(date: '1er novembre 2026'),
      );
    });

    test('copies du guide, mot pour mot', () {
      expect(
        t.argent.acces.enfantTitre,
        'Accès à cette classe temporairement indisponible',
      );
      expect(t.argent.acces.enfantMessage, "Votre tuteur peut gérer l'accès.");
      expect(t.argent.acces.regulariserTitre, 'Accès à régulariser');
    });
  });

  group('enfant : accueil eleve', () {
    testWidgets('periode non financee : copie neutre, Rejoindre absent, '
        'aucune cause, aucune finance lue', (WidgetTester tester) async {
      final _PaiementsEspion espion = _PaiementsEspion(
        DonneesFinanceDemo.finances(JeuFoyerFinance.unARegulariser),
      );
      final _AccesFoyerEspion foyer = _AccesFoyerEspion();
      await tester.pumpWidget(
        _hote(
          _accueil(),
          surcharges: _surchargesEnfant(
            eleveId: DonneesFinanceDemo.ibrahimId,
            acces: _ibrahim(JeuFoyerFinance.unARegulariser),
            foyer: foyer,
            paiements: espion,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(BandeauAccesEnfant.cle), findsOneWidget);
      expect(find.text(t.argent.acces.enfantTitre), findsOneWidget);
      expect(find.text(t.argent.acces.enfantMessage), findsOneWidget);
      expect(_rejoindre, findsNothing);
      // Le compte reste navigable : le bloc du Coran reste la.
      expect(find.text(t.eleve.accueil.coran), findsOneWidget);
      _verifierSansCauseFinanciere(tester);
      expect(espion.lecturesFinances, 0);
      // R4-02 : l'acces du foyer entier n'est jamais charge sur l'appareil
      // de l'enfant ; sa seule ligne vient du port borne a sa session.
      expect(foyer.lectures, 0);
    });

    testWidgets('essais epuises (2/2) : la meme copie neutre', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _hote(
          _accueil(),
          surcharges: _surchargesEnfant(
            eleveId: DonneesFinanceDemo.aichaId,
            acces: const _MonAccesFixe(_essaisEpuises),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(BandeauAccesEnfant.cle), findsOneWidget);
      expect(_rejoindre, findsNothing);
      _verifierSansCauseFinanciere(tester);
    });

    final Map<String, (String, PortMonAcces?)> ouverts =
        <String, (String, PortMonAcces?)>{
          'mois finance a solde nul': (
            DonneesFinanceDemo.ibrahimId,
            _ibrahim(JeuFoyerFinance.tousFinances),
          ),
          'essai 1/2': (
            DonneesFinanceDemo.aichaId,
            const MonAccesFinanceDemo(
              JeuFoyerFinance.unEnEssai,
              DonneesFinanceDemo.aichaId,
            ),
          ),
          'acces reactive': (
            DonneesFinanceDemo.ibrahimId,
            _ibrahim(
              JeuFoyerFinance.unARegulariser,
              place: EtatPlace.reactivee,
            ),
          ),
          'production (port neutre)': (DonneesFinanceDemo.ibrahimId, null),
          'lecture en echec': (
            DonneesFinanceDemo.ibrahimId,
            const _MonAccesFixe(null, echec: true),
          ),
          'aucune ligne pour l appelant': (
            DonneesFinanceDemo.ibrahimId,
            const _MonAccesFixe(null),
          ),
        };
    for (final MapEntry<String, (String, PortMonAcces?)> cas
        in ouverts.entries) {
      testWidgets('${cas.key} : Rejoindre rendu et actif, aucun bandeau', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          _hote(
            _accueil(),
            surcharges: _surchargesEnfant(
              eleveId: cas.value.$1,
              acces: cas.value.$2,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(BandeauAccesEnfant.cle), findsNothing);
        expect(_rejoindre, findsOneWidget);
        expect(tester.widget<ActionPrincipale>(_rejoindre).onPress, isNotNull);
      });
    }

    testWidgets('acces en lecture : Rejoindre present et inerte, puis actif '
        'une fois l acces ouvert rendu', (WidgetTester tester) async {
      final _MonAccesEnAttente port = _MonAccesEnAttente();
      await tester.pumpWidget(
        _hote(
          _accueil(),
          surcharges: _surchargesEnfant(
            eleveId: DonneesFinanceDemo.ibrahimId,
            acces: port,
          ),
        ),
      );
      // Les seances sont rendues, l'acces ne l'est pas encore.
      await tester.pump();
      await tester.pump();
      expect(find.byKey(BandeauAccesEnfant.cle), findsNothing);
      expect(_rejoindre, findsOneWidget);
      expect(tester.widget<ActionPrincipale>(_rejoindre).onPress, isNull);
      // Inerte sans message hors ligne : ce n'est pas une panne de reseau.
      expect(find.text(t.eleve.accueil.horsLigne), findsNothing);

      port.reponse.complete(
        _acces(JeuFoyerFinance.tousFinances, DonneesFinanceDemo.ibrahimId),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<ActionPrincipale>(_rejoindre).onPress, isNotNull);
    });

    testWidgets('acces en lecture puis ferme : Rejoindre inerte puis retire, '
        'jamais actif entre les deux', (WidgetTester tester) async {
      final _MonAccesEnAttente port = _MonAccesEnAttente();
      await tester.pumpWidget(
        _hote(
          _accueil(),
          surcharges: _surchargesEnfant(
            eleveId: DonneesFinanceDemo.aichaId,
            acces: port,
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(tester.widget<ActionPrincipale>(_rejoindre).onPress, isNull);

      port.reponse.complete(_essaisEpuises);
      await tester.pumpAndSettle();
      expect(_rejoindre, findsNothing);
      expect(find.byKey(BandeauAccesEnfant.cle), findsOneWidget);
    });

    testWidgets('hors ligne et periode financee : Rejoindre present, inerte '
        '(panne, pas une limite de droit)', (WidgetTester tester) async {
      await tester.pumpWidget(
        _hote(
          _accueil(),
          surcharges: _surchargesEnfant(
            eleveId: DonneesFinanceDemo.ibrahimId,
            acces: _ibrahim(JeuFoyerFinance.tousFinances),
            horsLigne: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(BandeauAccesEnfant.cle), findsNothing);
      expect(tester.widget<ActionPrincipale>(_rejoindre).onPress, isNull);
    });

    testWidgets('hors ligne et periode non financee : la copie neutre, sans '
        'Rejoindre', (WidgetTester tester) async {
      await tester.pumpWidget(
        _hote(
          _accueil(),
          surcharges: _surchargesEnfant(
            eleveId: DonneesFinanceDemo.ibrahimId,
            acces: _ibrahim(JeuFoyerFinance.unARegulariser),
            horsLigne: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(BandeauAccesEnfant.cle), findsOneWidget);
      expect(_rejoindre, findsNothing);
    });

    testWidgets('R4-02 : l acces du foyer dit « ferme », le sien « ouvert » : '
        'seul le sien compte, le foyer n est jamais lu', (
      WidgetTester tester,
    ) async {
      final _AccesFoyerEspion foyer = _AccesFoyerEspion();
      await tester.pumpWidget(
        _hote(
          _accueil(),
          surcharges: _surchargesEnfant(
            eleveId: DonneesFinanceDemo.ibrahimId,
            acces: _ibrahim(JeuFoyerFinance.tousFinances),
            foyer: foyer,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(BandeauAccesEnfant.cle), findsNothing);
      expect(tester.widget<ActionPrincipale>(_rejoindre).onPress, isNotNull);
      expect(foyer.lectures, 0);
    });

    testWidgets('R4-04 : place liberee (acces suspendu) : la meme copie '
        'neutre, jamais « libérée » ni une date', (WidgetTester tester) async {
      await tester.pumpWidget(
        _hote(
          _accueil(),
          surcharges: _surchargesEnfant(
            eleveId: DonneesFinanceDemo.ibrahimId,
            acces: _ibrahim(
              JeuFoyerFinance.unARegulariser,
              place: EtatPlace.liberee,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(BandeauAccesEnfant.cle), findsOneWidget);
      expect(find.byKey(BandeauPlace.suspenduKey), findsNothing);
      expect(_rejoindre, findsNothing);
      expect(find.textContaining('libérée'), findsNothing);
      expect(find.textContaining('suspendu'), findsNothing);
      _verifierSansCauseFinanciere(tester);
    });

    for (final TextDirection sens in TextDirection.values) {
      for (final Brightness luminosite in Brightness.values) {
        testWidgets('320 px, texte 200 %, ${sens.name}, ${luminosite.name} : '
            'aucun debordement', (WidgetTester tester) async {
          _taille(tester, const Size(320, 900));
          await tester.pumpWidget(
            _hote(
              _accueil(),
              echelle: 2,
              sens: sens,
              luminosite: luminosite,
              surcharges: _surchargesEnfant(
                eleveId: DonneesFinanceDemo.ibrahimId,
                acces: _ibrahim(JeuFoyerFinance.unARegulariser),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byKey(BandeauAccesEnfant.cle), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('enfant : Mes groupes', () {
    /// L'eleve connecte : son identifiant de session est celui de sa ligne
    /// d'acces.
    final String moi = sessionActive(AppRole.student).profileId!;

    AccesBeneficiaire accesDeMoi({required bool ouvert}) => AccesBeneficiaire(
      eleveId: moi,
      prenom: 'Aïcha',
      etatAffiche: EtatAccesAffiche.sansEcheance,
      seancesPayantesOuvertes: ouvert,
      essaisUtilises: ouvert ? null : 2,
      essaisMax: ouvert ? null : 2,
    );

    Finder rejoindreGroupe() =>
        find.widgetWithText(ActionPrincipale, LibellesGroupe.rejoindre);

    Future<void> poser(
      WidgetTester tester,
      PortMonAcces acces, {
      PortAccesFoyer? foyer,
    }) async {
      await tester.pumpWidget(
        hoteTcA(
          MesGroupesPage(onRejoindre: (_) {}),
          surcharges: <Override>[
            ...surchargesDemonstration(),
            portMonAccesProvider.overrideWithValue(acces),
            if (foyer != null) portAccesFoyerProvider.overrideWithValue(foyer),
            sourceSessionProvider.overrideWithValue(
              FausseSourceSession(sessionActive(AppRole.student)),
            ),
          ],
        ),
      );
      // Les groupes, la session puis les acces se rendent chacun a leur tour.
      for (int i = 0; i < 4; i++) {
        await tester.pump();
      }
    }

    testWidgets('seances fermees : aucun Rejoindre, la copie neutre, aucun '
        'mot financier', (WidgetTester tester) async {
      await avecLargeur(tester, largeurMobile, () async {
        await poser(tester, _MonAccesFixe(accesDeMoi(ouvert: false)));
        expect(find.byType(CarteGroupe), findsWidgets);
        expect(rejoindreGroupe(), findsNothing);
        expect(find.byKey(BandeauAccesEnfant.cle), findsOneWidget);
        expect(find.text(t.argent.acces.enfantTitre), findsOneWidget);
        expect(find.text(t.argent.acces.enfantMessage), findsOneWidget);
        // Les heures et capacites des cartes sont des chiffres : seuls les
        // mots d'argent sont interdits ici.
        final RegExp interdit = RegExp(
          r'pay|manque|usd|\$|€|solde|régularis|financ',
          caseSensitive: false,
        );
        for (final String texte in _textes(tester)) {
          expect(interdit.hasMatch(texte), isFalse, reason: texte);
        }
      });
    });

    testWidgets('seances ouvertes : Rejoindre rendu et actif, aucun bandeau', (
      WidgetTester tester,
    ) async {
      await avecLargeur(tester, largeurMobile, () async {
        await poser(tester, _MonAccesFixe(accesDeMoi(ouvert: true)));
        expect(find.byKey(BandeauAccesEnfant.cle), findsNothing);
        expect(rejoindreGroupe(), findsWidgets);
        for (final ActionPrincipale b in tester.widgetList<ActionPrincipale>(
          rejoindreGroupe(),
        )) {
          expect(b.onPress, isNotNull);
        }
      });
    });

    testWidgets('acces en lecture : Rejoindre present et inerte', (
      WidgetTester tester,
    ) async {
      await avecLargeur(tester, largeurMobile, () async {
        final _MonAccesEnAttente port = _MonAccesEnAttente();
        await poser(tester, port);
        expect(find.byKey(BandeauAccesEnfant.cle), findsNothing);
        expect(rejoindreGroupe(), findsWidgets);
        for (final ActionPrincipale b in tester.widgetList<ActionPrincipale>(
          rejoindreGroupe(),
        )) {
          expect(b.onPress, isNull);
        }
        port.reponse.complete(accesDeMoi(ouvert: false));
        await tester.pump();
        await tester.pump();
        expect(rejoindreGroupe(), findsNothing);
        expect(find.byKey(BandeauAccesEnfant.cle), findsOneWidget);
      });
    });

    for (final (String nom, PortMonAcces port) in <(String, PortMonAcces)>[
      ('aucune ligne pour l appelant', const _MonAccesFixe(null)),
      ('lecture en echec', const _MonAccesFixe(null, echec: true)),
    ]) {
      testWidgets('$nom : rien ne change', (WidgetTester tester) async {
        await avecLargeur(tester, largeurMobile, () async {
          await poser(tester, port);
          expect(find.byKey(BandeauAccesEnfant.cle), findsNothing);
          expect(rejoindreGroupe(), findsWidgets);
        });
      });
    }

    testWidgets('R4-02 : le foyer n est jamais lu, meme quand il dirait '
        '« ferme »', (WidgetTester tester) async {
      await avecLargeur(tester, largeurMobile, () async {
        final _AccesFoyerEspion foyer = _AccesFoyerEspion();
        await poser(
          tester,
          _MonAccesFixe(accesDeMoi(ouvert: true)),
          foyer: foyer,
        );
        expect(find.byKey(BandeauAccesEnfant.cle), findsNothing);
        expect(rejoindreGroupe(), findsWidgets);
        expect(foyer.lectures, 0);
      });
    });
  });

  group('tuteur : Compte > Acces', () {
    List<Override> surcharges(JeuFoyerFinance jeu, {bool finance = true}) =>
        <Override>[
          portAccesFoyerProvider.overrideWithValue(AccesFoyerFinanceDemo(jeu)),
          if (finance)
            portPaiementsFoyerProvider.overrideWithValue(
              PaiementsFoyerFinanceDemo(jeu),
            ),
        ];

    testWidgets('a regulariser : pastille et manque exact en legende', (
      WidgetTester tester,
    ) async {
      _taille(tester, const Size(390, 844));
      await tester.pumpWidget(
        _hote(
          const AccesComptePage(),
          surcharges: surcharges(JeuFoyerFinance.unARegulariser),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PastilleFinanciere), findsOneWidget);
      expect(find.text(t.argent.etat.aRegulariser), findsOneWidget);
      expect(
        find.text(
          t.argent.acces.regulariserManque(
            montant: formaterMontant(DonneesFinanceDemo.usd(8)),
            mois: 'octobre',
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('essai : « Essai\u00A0: 1/2 »', (WidgetTester tester) async {
      _taille(tester, const Size(390, 844));
      await tester.pumpWidget(
        _hote(
          const AccesComptePage(),
          surcharges: surcharges(JeuFoyerFinance.unEnEssai),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Essai\u00A0: 1/2'), findsOneWidget);
    });

    testWidgets('finance indisponible (production) : la ligne de l echeance, '
        'aucune cause inventee', (WidgetTester tester) async {
      _taille(tester, const Size(390, 844));
      await tester.pumpWidget(
        _hote(
          const AccesComptePage(),
          surcharges: surcharges(
            JeuFoyerFinance.unARegulariser,
            finance: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PastilleFinanciere), findsNothing);
      expect(
        find.text(t.compte.tuteur.pageAcces.pastilleExpire),
        findsOneWidget,
      );
      expect(find.textContaining('manque'), findsNothing);
    });

    for (final TextDirection sens in TextDirection.values) {
      testWidgets('320 px, texte 200 %, ${sens.name}, sombre : aucun '
          'debordement', (WidgetTester tester) async {
        _taille(tester, const Size(320, 1200));
        await tester.pumpWidget(
          _hote(
            const AccesComptePage(),
            echelle: 2,
            sens: sens,
            luminosite: Brightness.dark,
            surcharges: surcharges(JeuFoyerFinance.unARegulariser),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('tuteur : fiche eleve > Acces', () {
    Future<void> monter(
      WidgetTester tester, {
      required JeuFoyerFinance jeu,
      required String eleveId,
      bool finance = true,
      Size taille = const Size(390, 844),
      PortAccesFoyer? acces,
      PortPaiementsFoyer? paiements,
    }) => _monterFicheAcces(
      tester,
      jeu: jeu,
      eleveId: eleveId,
      finance: finance,
      taille: taille,
      acces: acces,
      paiements: paiements,
    );

    testWidgets('a regulariser : « Accès à régulariser », le manque exact, la '
        'place conservee ; jamais « ne peut plus entrer »', (
      WidgetTester tester,
    ) async {
      await monter(
        tester,
        jeu: JeuFoyerFinance.unARegulariser,
        eleveId: DonneesFinanceDemo.ibrahimId,
      );
      expect(find.byType(AccesElevePage), findsOneWidget);
      expect(find.byKey(AccesElevePage.bandeauKey), findsOneWidget);
      final BandeauAttention bandeau = tester.widget<BandeauAttention>(
        find.byKey(AccesElevePage.bandeauKey),
      );
      expect(bandeau.titre, 'Accès à régulariser');
      expect(
        bandeau.message,
        'Il manque ${formaterMontant(DonneesFinanceDemo.usd(8))} pour '
        'financer octobre.',
      );
      expect(
        find.text(t.argent.acces.placeConservee(date: '8 octobre 2026')),
        findsOneWidget,
      );
      expect(find.byType(PastilleFinanciere), findsOneWidget);
      expect(
        find.text(t.ficheEleve.acces.expirePhrase(prenom: 'Ibrahim')),
        findsNothing,
      );
    });

    testWidgets('essai : la pastille « Essai\u00A0: 1/2 »', (
      WidgetTester tester,
    ) async {
      await monter(
        tester,
        jeu: JeuFoyerFinance.unEnEssai,
        eleveId: DonneesFinanceDemo.aichaId,
      );
      expect(
        tester.widget<StatusPill>(find.byType(StatusPill)).libelle,
        'Essai\u00A0: 1/2',
      );
      expect(find.byKey(AccesElevePage.bandeauKey), findsNothing);
    });

    /// Aicha apres ses deux essais, sans periode financee : la finance dit
    /// « essai », pas « a regulariser », avec ou sans manque rendu.
    FinancesProfil aichaEssaisEpuises({required bool avecManque}) =>
        FinancesProfil(
          profilId: DonneesFinanceDemo.aichaId,
          prenom: 'Aïcha',
          cleAccent: 'accent-aicha',
          estAdulte: false,
          etat: EtatFinancier.essai,
          solde: DonneesFinanceDemo.usd(0),
          mensualite: DonneesFinanceDemo.usd(50),
          essaisUtilises: 2,
          prochainDebit: avecManque
              ? ProchainDebit(
                  date: DateTime(2026, 11),
                  montant: DonneesFinanceDemo.usd(50),
                )
              : null,
          manque: avecManque ? DonneesFinanceDemo.usd(50) : null,
        );

    testWidgets('essais epuises (2/2) avec manque rendu : la cause utile, '
        'meme hors « a regulariser »', (WidgetTester tester) async {
      await monter(
        tester,
        jeu: JeuFoyerFinance.unEnEssai,
        eleveId: DonneesFinanceDemo.aichaId,
        acces: const _AccesFixes(<AccesBeneficiaire>[_essaisEpuises]),
        paiements: _PaiementsEspion(
          _foyerDe(aichaEssaisEpuises(avecManque: true)),
        ),
      );
      final BandeauAttention bandeau = tester.widget<BandeauAttention>(
        find.byKey(AccesElevePage.bandeauKey),
      );
      expect(bandeau.titre, t.argent.acces.regulariserTitre);
      expect(
        bandeau.message,
        t.argent.acces.regulariserManque(
          montant: formaterMontant(DonneesFinanceDemo.usd(50)),
          mois: 'novembre',
        ),
      );
      expect(find.byKey(AccesElevePage.bandeauFermeKey), findsNothing);
      expect(
        tester.widget<StatusPill>(find.byType(StatusPill)).libelle,
        'Essai\u00A0: 2/2',
      );
    });

    testWidgets('essais epuises (2/2) sans manque rendu : la phrase neutre', (
      WidgetTester tester,
    ) async {
      await monter(
        tester,
        jeu: JeuFoyerFinance.unEnEssai,
        eleveId: DonneesFinanceDemo.aichaId,
        acces: const _AccesFixes(<AccesBeneficiaire>[_essaisEpuises]),
        paiements: _PaiementsEspion(
          _foyerDe(aichaEssaisEpuises(avecManque: false)),
        ),
      );
      expect(find.byKey(AccesElevePage.bandeauKey), findsNothing);
      final BandeauAttention bandeau = tester.widget<BandeauAttention>(
        find.byKey(AccesElevePage.bandeauFermeKey),
      );
      expect(bandeau.titre, t.argent.acces.seancesFermeesTitre);
      expect(
        bandeau.message,
        t.argent.acces.seancesFermees(
          prenom: _finance(
            JeuFoyerFinance.unEnEssai,
            DonneesFinanceDemo.aichaId,
          ).prenom,
        ),
      );
      expect(find.textContaining('manque'), findsNothing);
    });

    testWidgets('essais epuises, finance indisponible : la phrase neutre, '
        'aucune cause inventee', (WidgetTester tester) async {
      await monter(
        tester,
        jeu: JeuFoyerFinance.unEnEssai,
        eleveId: DonneesFinanceDemo.aichaId,
        acces: const _AccesFixes(<AccesBeneficiaire>[_essaisEpuises]),
        finance: false,
      );
      expect(find.byKey(AccesElevePage.bandeauFermeKey), findsOneWidget);
      expect(find.byKey(AccesElevePage.bandeauKey), findsNothing);
      expect(find.textContaining('manque'), findsNothing);
    });

    testWidgets('finance indisponible : la carte de l echeance seule', (
      WidgetTester tester,
    ) async {
      await monter(
        tester,
        jeu: JeuFoyerFinance.unARegulariser,
        eleveId: DonneesFinanceDemo.ibrahimId,
        finance: false,
      );
      expect(find.byKey(AccesElevePage.bandeauKey), findsNothing);
      expect(
        tester.widget<StatusPill>(find.byType(StatusPill)).libelle,
        t.ficheEleve.acces.pastilleExpire,
      );
    });

    testWidgets('320 px : aucun debordement', (WidgetTester tester) async {
      await monter(
        tester,
        jeu: JeuFoyerFinance.unARegulariser,
        eleveId: DonneesFinanceDemo.ibrahimId,
        taille: const Size(320, 900),
      );
      expect(find.byKey(AccesElevePage.bandeauKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('adulte autonome : Mon espace', () {
    List<Override> surcharges({
      PortPaiementsFoyer? paiements,
      PortMonAcces? acces,
      PortAccesFoyer? foyer,
      LigneFamilleAdulte? ligne = LigneFamilleAdulte.ajouterMaFamille,
    }) => _surchargesAdulte(
      paiements: paiements,
      acces: acces,
      foyer: foyer,
      ligne: ligne,
    );

    testWidgets('a regulariser : « Accès à régulariser » et « Il manque 8 \$ '
        'pour financer janvier. »', (WidgetTester tester) async {
      _taille(tester, const Size(390, 1400));
      await tester.pumpWidget(
        _hote(
          const MonEspaceAdultePage(),
          surcharges: surcharges(
            paiements: _PaiementsEspion(_foyerDe(_adulteARegulariser)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(BandeauRegularisation.cle), findsOneWidget);
      expect(find.text('Accès à régulariser'), findsOneWidget);
      expect(
        find.text('Il manque 8 \$ pour financer janvier.'),
        findsOneWidget,
      );
      expect(
        find.text(t.argent.acces.placeConservee(date: '8 janvier 2027')),
        findsOneWidget,
      );
      // Aucun compte ferme : les rubriques restent la.
      expect(find.text(t.adulte.monEspace.monCompte), findsOneWidget);
    });

    testWidgets('essai : « Essai\u00A0: 1/2 »', (WidgetTester tester) async {
      _taille(tester, const Size(390, 1400));
      await tester.pumpWidget(
        _hote(
          const MonEspaceAdultePage(),
          surcharges: surcharges(
            acces: _MonAccesFixe(
              _acces(JeuFoyerFinance.unEnEssai, DonneesFinanceDemo.aichaId),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(AccesAdulte.essaiKey), findsOneWidget);
      expect(find.text('Essai\u00A0: 1/2'), findsOneWidget);
    });

    testWidgets('second adulte rattache : aucune finance lue, aucun bandeau', (
      WidgetTester tester,
    ) async {
      _taille(tester, const Size(390, 1400));
      final _PaiementsEspion espion = _PaiementsEspion(
        _foyerDe(_adulteARegulariser),
      );
      await tester.pumpWidget(
        _hote(
          const MonEspaceAdultePage(),
          surcharges: surcharges(
            paiements: espion,
            ligne: LigneFamilleAdulte.forfaitFamille,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(BandeauRegularisation.cle), findsNothing);
      expect(espion.lecturesFinances, 0);
    });

    testWidgets('production (ports neutres) : rien d invente', (
      WidgetTester tester,
    ) async {
      _taille(tester, const Size(390, 1400));
      await tester.pumpWidget(
        _hote(const MonEspaceAdultePage(), surcharges: surcharges()),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(BandeauRegularisation.cle), findsNothing);
      expect(find.byKey(AccesAdulte.essaiKey), findsNothing);
      expect(find.text(t.adulte.monEspace.monCompte), findsOneWidget);
    });

    for (final TextDirection sens in TextDirection.values) {
      testWidgets('320 px, texte 200 %, ${sens.name} : aucun debordement', (
        WidgetTester tester,
      ) async {
        _taille(tester, const Size(320, 2400));
        await tester.pumpWidget(
          _hote(
            const MonEspaceAdultePage(),
            echelle: 2,
            sens: sens,
            surcharges: surcharges(
              paiements: _PaiementsEspion(_foyerDe(_adulteARegulariser)),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(BandeauRegularisation.cle), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('R4-04 : place liberee (acces suspendu) et reactivation', () {
    final AccesBeneficiaire libere = _acces(
      JeuFoyerFinance.unARegulariser,
      DonneesFinanceDemo.ibrahimId,
    );

    AccesBeneficiaire avec(EtatPlace place, {DateTime? jour}) =>
        AccesBeneficiaire(
          eleveId: libere.eleveId,
          prenom: libere.prenom,
          etatAffiche: libere.etatAffiche,
          seancesPayantesOuvertes: place == EtatPlace.reactivee,
          place: place,
          datePlace: jour,
        );

    test('les phrases du tuteur et de l adulte, avec et sans date rendue', () {
      final DateTime jour = DateTime(2026, 10, 9);
      expect(
        phrasePlace(avec(EtatPlace.liberee, jour: jour), prenom: 'Ibrahim'),
        'La place réservée à Ibrahim a été libérée le 9 octobre 2026. '
        'Son compte et ses contenus restent accessibles.',
      );
      expect(
        phrasePlace(avec(EtatPlace.liberee), prenom: 'Ibrahim'),
        t.argent.acces.suspenduTuteurSansDate(prenom: 'Ibrahim'),
      );
      expect(
        phrasePlace(avec(EtatPlace.liberee, jour: jour)),
        'Votre place a été libérée le 9 octobre 2026. Votre compte et vos '
        'contenus restent accessibles.',
      );
      expect(
        phrasePlace(avec(EtatPlace.reactivee, jour: jour), prenom: 'Ibrahim'),
        'Ibrahim peut de nouveau rejoindre ses séances depuis le 9 octobre '
        '2026.',
      );
      expect(
        phrasePlace(avec(EtatPlace.reactivee)),
        t.argent.acces.reactiveAdulteSansDate,
      );
      // R8-05 : le premier du mois s'ecrit « 1er ».
      expect(
        phrasePlace(avec(EtatPlace.liberee, jour: DateTime(2026, 11, 1, 12))),
        'Votre place a été libérée le 1er novembre 2026. Votre compte et vos '
        'contenus restent accessibles.',
      );
      // Sans etat de place rendu, rien n'est dit.
      expect(phrasePlace(libere, prenom: 'Ibrahim'), isNull);
      expect(phrasePlace(null), isNull);
    });

    test('le contrat de demonstration : liberee ferme, reactivee rouvre, '
        'jamais de compte ferme', () {
      final AccesBeneficiaire l = DonneesFinanceDemo.acces(
        JeuFoyerFinance.unARegulariser,
        places: <String, EtatPlace>{
          DonneesFinanceDemo.ibrahimId: EtatPlace.liberee,
        },
      ).firstWhere((AccesBeneficiaire a) => a.eleveId == libere.eleveId);
      expect(l.place, EtatPlace.liberee);
      expect(l.datePlace, DonneesFinanceDemo.jourPlaceLiberee);
      expect(ouvertureSeances(l), OuvertureSeances.fermees);
      final AccesBeneficiaire r = DonneesFinanceDemo.acces(
        JeuFoyerFinance.unARegulariser,
        places: <String, EtatPlace>{
          DonneesFinanceDemo.ibrahimId: EtatPlace.reactivee,
        },
      ).firstWhere((AccesBeneficiaire a) => a.eleveId == libere.eleveId);
      expect(r.place, EtatPlace.reactivee);
      expect(ouvertureSeances(r), OuvertureSeances.ouvertes);
      // Sans etat demande, le jeu reste celui d'avant.
      expect(
        DonneesFinanceDemo.acces(JeuFoyerFinance.unARegulariser)
            .every((AccesBeneficiaire a) => a.place == null),
        isTrue,
      );
    });

    testWidgets('tuteur, Compte > Acces : la place liberee se lit dans la '
        'ligne, pastille « Suspendu »', (WidgetTester tester) async {
      _taille(tester, const Size(390, 844));
      await tester.pumpWidget(
        _hote(
          const AccesComptePage(),
          surcharges: <Override>[
            portAccesFoyerProvider.overrideWithValue(
              const AccesFoyerFinanceDemo(
                JeuFoyerFinance.unARegulariser,
                places: <String, EtatPlace>{
                  DonneesFinanceDemo.ibrahimId: EtatPlace.liberee,
                  DonneesFinanceDemo.mariamId: EtatPlace.reactivee,
                },
              ),
            ),
            portPaiementsFoyerProvider.overrideWithValue(
              const PaiementsFoyerFinanceDemo(JeuFoyerFinance.unARegulariser),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(
          t.argent.acces.suspenduTuteur(
            prenom: 'Ibrahim',
            date: '9 octobre 2026',
          ),
        ),
        findsOneWidget,
      );
      expect(find.text(t.argent.acces.pastilleSuspendu), findsOneWidget);
      expect(
        find.text(
          t.argent.acces.reactiveTuteur(
            prenom: 'Mariam',
            date: '3 octobre 2026',
          ),
        ),
        findsOneWidget,
      );
      expect(find.text(t.argent.acces.pastilleReactive), findsOneWidget);
    });

    testWidgets('tuteur, fiche > Acces : « Accès suspendu » avant le manque', (
      WidgetTester tester,
    ) async {
      await _monterFicheAcces(
        tester,
        jeu: JeuFoyerFinance.unARegulariser,
        eleveId: DonneesFinanceDemo.ibrahimId,
        places: <String, EtatPlace>{
          DonneesFinanceDemo.ibrahimId: EtatPlace.liberee,
        },
      );
      final BandeauAttention bandeau = tester.widget<BandeauAttention>(
        find.byKey(BandeauPlace.suspenduKey),
      );
      expect(bandeau.titre, 'Accès suspendu');
      expect(
        bandeau.message,
        t.argent.acces.suspenduTuteur(
          prenom: 'Ibrahim',
          date: '9 octobre 2026',
        ),
      );
      expect(find.byKey(AccesElevePage.pastilleSuspenduKey), findsOneWidget);
      expect(find.byKey(AccesElevePage.bandeauKey), findsNothing);
    });

    testWidgets('tuteur, fiche > Acces : « Accès réactivé »', (
      WidgetTester tester,
    ) async {
      await _monterFicheAcces(
        tester,
        jeu: JeuFoyerFinance.tousFinances,
        eleveId: DonneesFinanceDemo.ibrahimId,
        places: <String, EtatPlace>{
          DonneesFinanceDemo.ibrahimId: EtatPlace.reactivee,
        },
      );
      final BandeauAttention bandeau = tester.widget<BandeauAttention>(
        find.byKey(BandeauPlace.reactiveKey),
      );
      expect(bandeau.titre, 'Accès réactivé');
      expect(bandeau.ton, TonEtat.succes);
      expect(find.byKey(BandeauPlace.suspenduKey), findsNothing);
    });

    testWidgets('adulte autonome, Mon espace : « Votre place a été libérée », '
        'puis « Accès réactivé »', (WidgetTester tester) async {
      for (final (EtatPlace place, Key cle, String phrase)
          in <(EtatPlace, Key, String)>[
            (
              EtatPlace.liberee,
              BandeauPlace.suspenduKey,
              t.argent.acces.suspenduAdulte(date: '9 octobre 2026'),
            ),
            (
              EtatPlace.reactivee,
              BandeauPlace.reactiveKey,
              t.argent.acces.reactiveAdulte(date: '9 octobre 2026'),
            ),
          ]) {
        _taille(tester, const Size(390, 1400));
        await tester.pumpWidget(
          _hote(
            const MonEspaceAdultePage(),
            // La finance rendue dit encore « a regulariser » : la place
            // liberee passe avant, et la reactivation n'a plus de manque.
            surcharges: _surchargesAdulte(
              paiements: place == EtatPlace.liberee
                  ? _PaiementsEspion(_foyerDe(_adulteARegulariser))
                  : null,
              acces: _MonAccesFixe(avec(place, jour: DateTime(2026, 10, 9))),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(cle), findsOneWidget, reason: place.name);
        expect(find.text(phrase), findsOneWidget, reason: place.name);
        expect(
          find.byKey(BandeauRegularisation.cle),
          findsNothing,
          reason: place.name,
        );
        expect(find.text(t.adulte.monEspace.monCompte), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    for (final TextDirection sens in TextDirection.values) {
      testWidgets('320 px, texte 200 %, ${sens.name} : aucun debordement', (
        WidgetTester tester,
      ) async {
        await _monterFicheAcces(
          tester,
          jeu: JeuFoyerFinance.unARegulariser,
          eleveId: DonneesFinanceDemo.ibrahimId,
          places: <String, EtatPlace>{
            DonneesFinanceDemo.ibrahimId: EtatPlace.liberee,
          },
          taille: const Size(320, 1200),
          echelle: 2,
          sens: sens,
        );
        expect(find.byKey(BandeauPlace.suspenduKey), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('R4-01 : Rejoindre selon l acces, partout ou une carte le propose', () {
    final String moi = sessionActive(AppRole.student).profileId!;
    AccesBeneficiaire accesDeMoi({required bool ouvert}) => AccesBeneficiaire(
      eleveId: moi,
      prenom: 'Aïcha',
      etatAffiche: EtatAccesAffiche.sansEcheance,
      seancesPayantesOuvertes: ouvert,
      essaisUtilises: ouvert ? null : 2,
      essaisMax: ouvert ? null : 2,
    );

    Finder rejoindre() =>
        find.widgetWithText(ActionPrincipale, LibellesGroupe.rejoindre);

    Future<void> espaceGroupe(WidgetTester tester, PortMonAcces acces) async {
      await tester.pumpWidget(
        hoteTcA(
          EspaceGroupePage(
            groupeId: GroupesDemonstration.anNour,
            onRejoindre: (_) {},
          ),
          surcharges: <Override>[
            ...surchargesDemonstration(),
            sourceSessionProvider.overrideWithValue(
              FausseSourceSession(sessionActive(AppRole.student)),
            ),
            portMonAccesProvider.overrideWithValue(acces),
          ],
        ),
      );
      for (int i = 0; i < 4; i++) {
        await tester.pump();
      }
    }

    testWidgets('Espace groupe ouvert avec l acces ferme : Rejoindre retire, '
        'la copie neutre, aucun mot financier', (WidgetTester tester) async {
      await avecLargeur(tester, largeurMobile, () async {
        await espaceGroupe(tester, _MonAccesFixe(accesDeMoi(ouvert: false)));
        expect(find.byType(CarteSession), findsOneWidget);
        expect(rejoindre(), findsNothing);
        expect(find.byKey(BandeauAccesEnfant.cle), findsOneWidget);
        final RegExp interdit = RegExp(
          r'pay|manque|usd|\$|€|solde|régularis|financ',
          caseSensitive: false,
        );
        for (final String texte in _textes(tester)) {
          expect(interdit.hasMatch(texte), isFalse, reason: texte);
        }
      });
    });

    testWidgets('Espace groupe, adulte autonome, acces ferme : sa copie, '
        'jamais celle du tuteur (contre-revue FI-VAGUE-CORR)', (
      WidgetTester tester,
    ) async {
      await avecLargeur(tester, largeurMobile, () async {
        await espaceGroupe(
          tester,
          _MonAccesFixe(
            AccesBeneficiaire(
              eleveId: moi,
              prenom: 'Youssef',
              etatAffiche: EtatAccesAffiche.sansEcheance,
              seancesPayantesOuvertes: false,
              gereSonAcces: true,
            ),
          ),
        );
        expect(rejoindre(), findsNothing);
        expect(find.byKey(BandeauAccesAdulte.cle), findsOneWidget);
        expect(find.byKey(BandeauAccesEnfant.cle), findsNothing);
        expect(find.text(t.argent.acces.enfantMessage), findsNothing);
        for (final String texte in _textes(tester)) {
          expect(
            texte.toLowerCase().contains('tuteur'),
            isFalse,
            reason: texte,
          );
        }
      });
    });

    testWidgets('Mes groupes, adulte autonome, acces ferme : jamais la copie '
        'du tuteur (contre-revue FI-VAGUE-CORR)', (WidgetTester tester) async {
      await avecLargeur(tester, largeurMobile, () async {
        await tester.pumpWidget(
          hoteTcA(
            const MesGroupesPage(),
            surcharges: <Override>[
              ...surchargesDemonstration(),
              sourceSessionProvider.overrideWithValue(
                FausseSourceSession(sessionActive(AppRole.student)),
              ),
              portMonAccesProvider.overrideWithValue(
                _MonAccesFixe(
                  AccesBeneficiaire(
                    eleveId: moi,
                    prenom: 'Youssef',
                    etatAffiche: EtatAccesAffiche.sansEcheance,
                    seancesPayantesOuvertes: false,
                    gereSonAcces: true,
                  ),
                ),
              ),
            ],
          ),
        );
        for (int i = 0; i < 4; i++) {
          await tester.pump();
        }
        expect(find.byKey(BandeauAccesAdulte.cle), findsOneWidget);
        expect(find.text(t.argent.acces.enfantMessage), findsNothing);
      });
    });

    testWidgets('Espace groupe, ligne sans la capacite (enfant) : la copie '
        'de l enfant reste', (WidgetTester tester) async {
      await avecLargeur(tester, largeurMobile, () async {
        await espaceGroupe(tester, _MonAccesFixe(accesDeMoi(ouvert: false)));
        expect(find.byKey(BandeauAccesEnfant.cle), findsOneWidget);
        expect(find.byKey(BandeauAccesAdulte.cle), findsNothing);
      });
    });

    testWidgets('Espace groupe, acces ouvert : Rejoindre rendu et actif', (
      WidgetTester tester,
    ) async {
      await avecLargeur(tester, largeurMobile, () async {
        await espaceGroupe(tester, _MonAccesFixe(accesDeMoi(ouvert: true)));
        expect(find.byKey(BandeauAccesEnfant.cle), findsNothing);
        expect(rejoindre(), findsOneWidget);
        expect(tester.widget<ActionPrincipale>(rejoindre()).onPress, isNotNull);
      });
    });

    testWidgets('Espace groupe, acces en lecture : Rejoindre present et '
        'inerte, puis retire', (WidgetTester tester) async {
      await avecLargeur(tester, largeurMobile, () async {
        final _MonAccesEnAttente port = _MonAccesEnAttente();
        await espaceGroupe(tester, port);
        expect(rejoindre(), findsOneWidget);
        expect(tester.widget<ActionPrincipale>(rejoindre()).onPress, isNull);
        port.reponse.complete(accesDeMoi(ouvert: false));
        await tester.pump();
        await tester.pump();
        expect(rejoindre(), findsNothing);
        expect(find.byKey(BandeauAccesEnfant.cle), findsOneWidget);
      });
    });

    testWidgets('Espace groupe en production (port neutre) : rien ne change', (
      WidgetTester tester,
    ) async {
      await avecLargeur(tester, largeurMobile, () async {
        await espaceGroupe(tester, const MonAccesIndisponible());
        expect(find.byKey(BandeauAccesEnfant.cle), findsNothing);
        expect(rejoindre(), findsOneWidget);
        expect(tester.widget<ActionPrincipale>(rejoindre()).onPress, isNotNull);
      });
    });

    testWidgets('Accueil du Mode Accessibilite : acces ferme, Rejoindre '
        'retire, « Voir ma classe » reste', (WidgetTester tester) async {
      _taille(tester, const Size(390, 1600));
      await tester.pumpWidget(
        _hote(
          AccueilAccessibilite(
            prenom: 'Mariam',
            espace: DonneesAccessibiliteDemo.espaceAccueil(
              MomentDemoAccessibilite.pendant,
            ),
            onVoirClasse: () {},
            onRejoindre: () {},
            onCoran: () {},
            onAide: () {},
            tutoiement: true,
            accesFerme: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(BandeauAccesEnfant.cle), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(CarteSession),
          matching: find.byType(EmplacementEntreeVue),
        ),
        findsNothing,
      );
      expect(find.byKey(AccueilAccessibilite.cleVoirClasse), findsOneWidget);
    });

    testWidgets('Accueil du Mode Accessibilite, eleve adulte (vouvoye) : '
        'acces ferme, la copie de l adulte, jamais celle de l enfant', (
      WidgetTester tester,
    ) async {
      _taille(tester, const Size(390, 1600));
      await tester.pumpWidget(
        _hote(
          AccueilAccessibilite(
            prenom: 'Idriss',
            espace: DonneesAccessibiliteDemo.espaceAccueil(
              MomentDemoAccessibilite.pendant,
            ),
            onVoirClasse: () {},
            onRejoindre: () {},
            onCoran: () {},
            onAide: () {},
            tutoiement: false,
            accesFerme: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(BandeauAccesAdulte.cle), findsOneWidget);
      expect(find.byKey(BandeauAccesEnfant.cle), findsNothing);
      expect(find.text(t.argent.acces.enfantMessage), findsNothing);
      expect(find.byKey(AccueilAccessibilite.cleVoirClasse), findsOneWidget);
    });

    testWidgets('demonstration du Mode Accessibilite : l hote lit l acces de '
        'l eleve et le passe a l Accueil', (WidgetTester tester) async {
      _taille(tester, const Size(390, 844));
      final GoRouter routeur = GoRouter(
        initialLocation: adresseDemoAccessibilite(
          EleveDemoAccessibilite.mariam,
        ),
        routes: routesDemoAccessibilite('local'),
      );
      addTearDown(routeur.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            sourceSessionProvider.overrideWithValue(
              FausseSourceSession(sessionActive(AppRole.student)),
            ),
            portMonAccesProvider.overrideWithValue(
              _MonAccesFixe(accesDeMoi(ouvert: false)),
            ),
          ],
          child: TranslationProvider(
            child: MaterialApp.router(
              routerConfig: routeur,
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              locale: AppLocale.fr.flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
            ),
          ),
        ),
      );
      await stabiliser(tester);
      await tester.tap(find.text(t.nav.eleve.accueil).last);
      await stabiliser(tester);
      expect(
        tester
            .widget<AccueilAccessibilite>(find.byType(AccueilAccessibilite))
            .accesFerme,
        isTrue,
      );
      expect(find.byKey(BandeauAccesEnfant.cle), findsOneWidget);
    });
  });

  test('contre-revue : l acces de la personne connectee est relu quand la '
      'personne change, jamais garde de la precedente', () async {
    final _MonAccesCompte port = _MonAccesCompte();
    final ProviderContainer conteneur = ProviderContainer(
      overrides: <Override>[
        demoAuthActiveProvider.overrideWithValue(true),
        sourceSessionProvider.overrideWithValue(FausseSourceSession()),
        portMonAccesProvider.overrideWithValue(port),
      ],
    );
    addTearDown(conteneur.dispose);
    final ProviderSubscription<AsyncValue<AccesBeneficiaire?>> abonnement =
        conteneur.listen(monAccesProvider, (_, _) {});
    addTearDown(abonnement.close);
    final SessionControleur session = conteneur.read(sessionProvider.notifier)
      ..ouvrirDemo((role: AppRole.guardian, mode: InterfaceMode.standard));
    final String? avant = (await conteneur.read(monAccesProvider.future))
        ?.eleveId;
    final int lecturesAvant = port.lectures;
    // Meme personne : aucune relecture.
    await conteneur.read(monAccesProvider.future);
    expect(port.lectures, lecturesAvant);
    session
      ..fermerDemo()
      ..ouvrirDemo((role: AppRole.student, mode: InterfaceMode.enfant));
    final String? apres = (await conteneur.read(monAccesProvider.future))
        ?.eleveId;
    expect(port.lectures, greaterThan(lecturesAvant));
    expect(apres, isNot(avant));
  });

  group('R4-05, R4-07, R4-08 : adulte autonome et elision', () {
    test('R4-05 : mes finances et mes mouvements sont relus a chaque '
        'ouverture (autoDispose)', () async {
      final _MesFinancesComptees port = _MesFinancesComptees();
      final ProviderContainer conteneur = ProviderContainer(
        overrides: <Override>[
          sansPersonneConnectee(),
          portMesFinancesProvider.overrideWithValue(port),
        ],
      );
      addTearDown(conteneur.dispose);
      for (int ouverture = 1; ouverture <= 2; ouverture++) {
        final ProviderSubscription<AsyncValue<FinancesProfil?>> f = conteneur
            .listen(mesFinancesProvider, (_, _) {});
        final ProviderSubscription<AsyncValue<List<MouvementProfil>>> m =
            conteneur.listen(mesMouvementsProvider, (_, _) {});
        await conteneur.read(mesFinancesProvider.future);
        await conteneur.read(mesMouvementsProvider.future);
        expect(port.lecturesFinances, ouverture);
        expect(port.lecturesMouvements, ouverture);
        // L'ecran se ferme : plus personne ne regarde, la lecture part.
        f.close();
        m.close();
        await Future<void>.delayed(Duration.zero);
      }
    });

    testWidgets('R4-07 : la legende de « Paiements » de l adulte autonome dit '
        'ce que la page ouvre', (WidgetTester tester) async {
      _taille(tester, const Size(390, 1400));
      await tester.pumpWidget(
        _hote(
          const MonEspaceAdultePage(),
          surcharges: _surchargesAdulte(
            paiements: _PaiementsEspion(_foyerDe(_adulteARegulariser)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(t.adulte.monEspace.paiementsLegendeAutonome),
        findsOneWidget,
      );
      expect(find.text(t.adulte.monEspace.paiementsLegende), findsNothing);
    });

    testWidgets('R4-07 : ailleurs (« Ma famille »), la legende des paiements '
        'du foyer reste', (WidgetTester tester) async {
      _taille(tester, const Size(390, 1400));
      await tester.pumpWidget(
        _hote(
          const MonEspaceAdultePage(),
          surcharges: _surchargesAdulte(
            paiements: _PaiementsEspion(_foyerDe(_adulteARegulariser)),
            ligne: LigneFamilleAdulte.maFamille,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(t.adulte.monEspace.paiementsLegende), findsOneWidget);
      expect(
        find.text(t.adulte.monEspace.paiementsLegendeAutonome),
        findsNothing,
      );
    });

    test('R4-08 : « d\' » devant voyelle ou h muet, « de » ailleurs', () {
      expect(
        t.ficheEleve.acces.ligne(dePrenom: deDevant('Aïcha')),
        "Accès d'Aïcha",
      );
      expect(
        t.ficheEleve.acces.ligne(dePrenom: deDevant('Ibrahim')),
        "Accès d'Ibrahim",
      );
      expect(
        t.ficheEleve.acces.ligne(dePrenom: deDevant('Mariam')),
        'Accès de Mariam',
      );
      expect(
        t.ficheEleve.finances.moisNonFinance(deMois: deDevant('octobre')),
        "La période d'octobre n'est pas encore financée.",
      );
      expect(
        t.ficheEleve.mouvements.erreurTitre(dePrenom: deDevant('Ousmane')),
        "Les mouvements d'Ousmane ne peuvent pas être lus",
      );
    });

    test('R4-08 : « y » suivi d une voyelle est une consonne, « de » '
        '(contre-revue FI-VAGUE-CORR)', () {
      expect(deDevant('Youssef'), 'de Youssef');
      expect(deDevant('Yasmine'), 'de Yasmine');
      expect(deDevant('Yahya'), 'de Yahya');
      expect(deDevant('Yusuf'), 'de Yusuf');
      expect(deDevant('Yanis'), 'de Yanis');
      expect(deDevant('Yacine'), 'de Yacine');
      expect(
        t.ficheEleve.acces.ligne(dePrenom: deDevant('Youssef')),
        'Accès de Youssef',
      );
      // Suivi d'une consonne, « y » se prononce « i » : il elide.
      expect(deDevant('Yvette'), "d'Yvette");
    });

    testWidgets('R4-08 : la fiche > Acces d Aicha dit « Accès d\'Aïcha »', (
      WidgetTester tester,
    ) async {
      await _monterFicheAcces(
        tester,
        jeu: JeuFoyerFinance.unEnEssai,
        eleveId: DonneesFinanceDemo.aichaId,
      );
      expect(find.text("Accès d'Aïcha"), findsOneWidget);
      expect(find.text('Accès de Aïcha'), findsNothing);
    });
  });
}

/// Les finances du seul profil d'un foyer d'un profil (adulte autonome),
/// rendues par le port borne a la session (FI-9b).
class _MesFinancesDe implements PortMesFinances {
  _MesFinancesDe(this.foyer);

  final PortPaiementsFoyer foyer;

  @override
  Future<FinancesProfil?> finances() async {
    final List<FinancesProfil> p = (await foyer.finances()).profils;
    return p.length == 1 ? p.single : null;
  }

  @override
  Future<List<MouvementProfil>> mouvements() async => const <MouvementProfil>[];
}

/// Un port des finances de l'adulte qui compte ses lectures (R4-05).
class _MesFinancesComptees implements PortMesFinances {
  int lecturesFinances = 0;
  int lecturesMouvements = 0;

  @override
  Future<FinancesProfil?> finances() async {
    lecturesFinances++;
    return null;
  }

  @override
  Future<List<MouvementProfil>> mouvements() async {
    lecturesMouvements++;
    return const <MouvementProfil>[];
  }
}
