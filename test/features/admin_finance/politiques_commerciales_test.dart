// FI-11b : les Politiques commerciales de la direction, guide Finance V4 §1,
// §5.7, §8 LOT F8 ; K-57, K-58.
//
// - les valeurs de lancement lues sur le port : rang 3 -5 USD, rang 4 et
//   suivants -7 USD, base 4 / plafond 7, capacites 5 / 6 / 4, minimum 4,
//   place conservee 7 jours ;
// - brouillon : les champs preremplis, la comparaison avec la version
//   active, l'erreur de champ ; aucun invariant n'est un champ ;
// - « Publier » appelle le port et rend l'etat honnete, sans ecriture ;
// - les etats : chargement, production indisponible, erreur, hors ligne ;
// - 320 px texte x2 et 1440 px, clair et sombre, LTR et RTL.
//
// FI-11c : l'historique des versions (lecture seule, version active
// marquee) et l'apercu du brouillon (foyer de 1 a 5 enfants : 145 USD pour
// 3, 231 USD pour 5 ; classe de 5 : 7 $/h pour 5 eligibles, 6,40 $/h pour
// 4), arrete par le port et relu a chaque saisie valide ; ses etats
// (attente d'une saisie valide, calcul, indisponible, erreur, hors ligne) ;
// garde de source : aucune formule de prix, remise ou taux dans
// lib/features/admin_finance.
//
// REVUE2 : aide Internet saisissable quand elle n'est pas fixee ; six
// invariants ; erreurs de coherence (plafond, maximum, minimum, capacite,
// tarif, remise) ; franc guineen a 7 chiffres ; marge et rails comptes ;
// « Prix normal » pour un rang sans remise ; publication non confirmee ;
// recalcul signale perime ; etats de l'apercu a 320 px texte x2, LTR/RTL.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/port_politiques_commerciales.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/finance/format_montant.dart';
import 'package:rewayah_academy/core/finance/montant.dart';
import 'package:rewayah_academy/core/finance/politique_commerciale.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/bandeau_attention.dart';
import 'package:rewayah_academy/core/widgets/bouton_icone.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/filter_pill.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/admin_finance/politiques_commerciales.dart';
import 'package:rewayah_academy/features/demo/finance_demo.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../support/garde_interface.dart';
import '../../support/harnais.dart';

/// Un port de test : [versions] (la plus recente d'abord), ou [erreur] ; il
/// retient chaque brouillon qu'on lui demande de publier, et chaque apercu
/// demande. L'apercu est celui du double de demonstration, ou
/// [erreurApercu], ou [apercuSuspendu] (jamais rendu ; modifiable en cours
/// de test pour suspendre un calcul apres un premier resultat). La
/// publication rend `CapaciteIndisponible`, sauf [publication] : `null`
/// pour une reponse sans erreur, ou l'erreur a lever.
class _Port implements PortPolitiquesCommerciales {
  _Port({
    this.versionsRendues,
    this.erreur,
    this.erreurApercu,
    this.apercuSuspendu = false,
    this.publication = const CapaciteIndisponible('FI-BR-02'),
  });

  final List<PolitiqueCommerciale>? versionsRendues;
  final Object? erreur;
  final Object? erreurApercu;
  bool apercuSuspendu;
  final Object? publication;
  final List<PolitiqueCommerciale> publies = <PolitiqueCommerciale>[];
  final List<(PolitiqueCommerciale, int)> apercusFamille =
      <(PolitiqueCommerciale, int)>[];
  final List<(int, int)> apercusEnseignant = <(int, int)>[];

  static const PolitiquesCommercialesDemo _demo = PolitiquesCommercialesDemo();

  Future<T> _apercu<T>(Future<T> Function() calcul) {
    if (apercuSuspendu) return Completer<T>().future;
    if (erreurApercu != null) return Future<T>.error(erreurApercu!);
    return calcul();
  }

  @override
  Future<ApercuFamille> apercuFamille(
    PolitiqueCommerciale brouillon,
    int enfants,
  ) {
    apercusFamille.add((brouillon, enfants));
    return _apercu(() => _demo.apercuFamille(brouillon, enfants));
  }

  @override
  Future<ApercuEnseignant> apercuEnseignant(
    PolitiqueCommerciale brouillon, {
    required int capacite,
    required int eligibles,
  }) {
    apercusEnseignant.add((capacite, eligibles));
    return _apercu(
      () => _demo.apercuEnseignant(
        brouillon,
        capacite: capacite,
        eligibles: eligibles,
      ),
    );
  }

  @override
  Future<PolitiqueCommerciale> active() => erreur == null
      ? Future<PolitiqueCommerciale>.value(
          DonneesFinanceDemo.politiqueLancement,
        )
      : Future<PolitiqueCommerciale>.error(erreur!);

  /// Le nombre de lectures des versions (relecture apres publication).
  int lectures = 0;

  @override
  Future<List<PolitiqueCommerciale>> versions() async {
    lectures++;
    return versionsRendues ?? <PolitiqueCommerciale>[];
  }

  @override
  Future<void> publier(PolitiqueCommerciale brouillon) {
    publies.add(brouillon);
    final Object? rendu = publication;
    return rendu == null ? Future<void>.value() : Future<void>.error(rendu);
  }
}

/// La seule version active, sans brouillon.
_Port _sansBrouillon() => _Port(
  versionsRendues: <PolitiqueCommerciale>[
    DonneesFinanceDemo.politiqueLancement,
  ],
);

/// Le brouillon de la demonstration et la version active.
_Port _avecBrouillon() => _Port(
  versionsRendues: <PolitiqueCommerciale>[
    DonneesFinanceDemo.politiqueBrouillon,
    DonneesFinanceDemo.politiqueLancement,
  ],
);

Widget _hote({
  required List<Override> surcharges,
  double echelle = 1,
  Brightness luminosite = Brightness.light,
  TextDirection sens = TextDirection.ltr,
  bool horsLigne = false,
}) => ProviderScope(
  overrides: <Override>[
    serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
    horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(horsLigne)),
    sansPersonneConnectee(),
    ...surcharges,
  ],
  child: TranslationProvider(
    child: MaterialApp(
      theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
      darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
      themeMode: luminosite == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      builder: (BuildContext context, Widget? app) => Directionality(
        textDirection: sens,
        child: MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(echelle)),
          child: app!,
        ),
      ),
      home: const Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: PolitiquesCommercialesBloc(),
          ),
        ),
      ),
    ),
  ),
);

/// Le brouillon de la demonstration, avec quelques valeurs changees.
PolitiqueCommerciale _brouillon({
  Montant? tarifEnfant,
  List<RemiseRang>? remisesParRang,
  ({int objectif, int forte, int stretch})? marge,
  Set<RailPaiement>? rails,
  bool? essaiActif,
  List<int>? joursRelance,
  List<BudgetPilotage>? budgets,
}) {
  final PolitiqueCommerciale b = DonneesFinanceDemo.politiqueBrouillon;
  return PolitiqueCommerciale(
    version: b.version,
    statut: b.statut,
    dateEffet: b.dateEffet,
    tarifEnfant: tarifEnfant ?? b.tarifEnfant,
    tarifAdulte: b.tarifAdulte,
    essaisMax: b.essaisMax,
    essaiActif: essaiActif ?? b.essaiActif,
    remisesParRang: remisesParRang ?? b.remisesParRang,
    baseHoraire: b.baseHoraire,
    plafondHoraire: b.plafondHoraire,
    capaciteEnfant: b.capaciteEnfant,
    capaciteAdulte: b.capaciteAdulte,
    capaciteDebutant: b.capaciteDebutant,
    minimumOuverture: b.minimumOuverture,
    classesObjectif: b.classesObjectif,
    classesMax: b.classesMax,
    joursConservationPlace: b.joursConservationPlace,
    margeReferencePourMille: marge ?? b.margeReferencePourMille,
    railsActifs: rails ?? b.railsActifs,
    allocationInternet: b.allocationInternet,
    joursRelance: joursRelance ?? b.joursRelance,
    budgets: budgets ?? b.budgets,
  );
}

/// [brouillon] et la version active.
_Port _avecCeBrouillon(PolitiqueCommerciale brouillon) => _Port(
  versionsRendues: <PolitiqueCommerciale>[
    brouillon,
    DonneesFinanceDemo.politiqueLancement,
  ],
);

List<Override> _avec(PortPolitiquesCommerciales port) => <Override>[
  portPolitiquesCommercialesProvider.overrideWithValue(port),
];

void _taille(WidgetTester tester, Size taille) {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Montant _usd(int unites) => DonneesFinanceDemo.usd(unites);

bool _estEtat(NatureEtat n) =>
    find
        .byWidgetPredicate((Widget w) => w is EtatSysteme && w.nature == n)
        .evaluate()
        .length ==
    1;

Finder _champ(String id) => find.descendant(
  of: find.byKey(PolitiquesCommercialesContenu.champKey(id)),
  matching: find.byType(TextField),
);

String _saisie(WidgetTester tester, String id) =>
    tester.widget<TextField>(_champ(id)).controller!.text;

Finder _comparaison(String id) =>
    find.byKey(PolitiquesCommercialesContenu.comparaisonKey(id));

Finder _dansEntete(Finder f) => find.descendant(
  of: find.byKey(PolitiquesCommercialesContenu.enteteKey),
  matching: f,
);

Finder _dans(Key carte, Finder f) =>
    find.descendant(of: find.byKey(carte), matching: f);

/// Le texte de la valeur d'une ligne d'apercu ([cle]), quelle qu'en soit
/// la mise en page.
bool _ligneDit(Key cle, String texte) =>
    find
        .descendant(of: find.byKey(cle), matching: find.text(texte))
        .evaluate()
        .length ==
    1;

Finder _bouton(String libelle) => find.byWidgetPredicate(
  (Widget w) => w is BoutonIcone && w.libelle == libelle,
);

Future<void> _toucher(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> _publier(WidgetTester tester) async {
  final Finder bouton = find.text(t.admin.finance.pol.publier);
  // Le champ encore saisi ramene sa ligne a l'ecran quand l'apercu se
  // recalcule : le bouton est ramene une seconde fois une fois l'ecran
  // stable.
  await tester.ensureVisible(bouton);
  await tester.pumpAndSettle();
  await tester.ensureVisible(bouton);
  await tester.pumpAndSettle();
  await tester.tap(bouton);
  await tester.pumpAndSettle();
}

/// Les champs reglables d'un brouillon : rien d'autre (FI22).
const Set<String> _reglables = <String>{
  'tarifEnfant',
  'tarifAdulte',
  'essais',
  'remise-3',
  'remise-4',
  'baseHoraire',
  'plafondHoraire',
  'classesObjectif',
  'classesMax',
  'internet',
  'capaciteEnfant',
  'capaciteAdulte',
  'capaciteDebutant',
  'minimum',
  'conservation',
  // FI-Q21.1 : les trois reperes de la marge de reference.
  'margeObjectif',
  'margeForte',
  'margeStretch',
};

void main() {
  final pol = t.admin.finance.pol;

  group('version active seule (lecture)', () {
    testWidgets('les valeurs de lancement, exactes, sans champ ni bouton', (
      WidgetTester tester,
    ) async {
      _taille(tester, const Size(1440, 2400));
      await tester.pumpWidget(_hote(surcharges: _avec(_sansBrouillon())));
      await tester.pumpAndSettle();

      // Remises : rangs 1 et 2 au prix normal, rang 3 -5 USD, rang 4 et
      // suivants -7 USD.
      expect(find.text(pol.remiseAucune(rang: '2')), findsOneWidget);
      expect(find.text(pol.remiseAucuneValeur), findsOneWidget);
      expect(find.text(pol.remiseRang(rang: '3')), findsOneWidget);
      expect(find.text(pol.remiseRangSuivants(rang: '4')), findsOneWidget);
      expect(formaterMontant(_usd(-5)), '${signeMoins}5 \$');
      expect(find.text(formaterMontant(_usd(-5))), findsOneWidget);
      expect(find.text(formaterMontant(_usd(-7))), findsOneWidget);
      // Tarifs.
      expect(find.text(formaterMontant(_usd(50))), findsOneWidget);
      expect(find.text(formaterMontant(_usd(60))), findsOneWidget);
      // Enseignants : base 4 / plafond 7, par heure ; 3 et 4 classes.
      expect(
        find.text(pol.parHeure(montant: formaterMontant(_usd(4)))),
        findsOneWidget,
      );
      expect(
        find.text(pol.parHeure(montant: formaterMontant(_usd(7)))),
        findsOneWidget,
      );
      expect(find.text(pol.classes(n: 3)), findsOneWidget);
      expect(find.text(pol.classes(n: 4)), findsOneWidget);
      expect(find.text(pol.internetNonFixee), findsOneWidget);
      // Classes : 5 enfants, 6 adultes, 4 debutants, minimum 4.
      expect(find.text(pol.eleves(n: 5)), findsOneWidget);
      expect(find.text(pol.eleves(n: 6)), findsOneWidget);
      expect(find.text(pol.eleves(n: 4)), findsNWidgets(2));
      // Essai, place conservee.
      expect(find.text(pol.seances(n: 2)), findsOneWidget);
      // Insecable a l'ecran (DUREE-INSECABLE-3, JONCTION-LIGNES-1).
      expect(
        find.text(LibellesGroupe.insecable(pol.jours(n: 7))),
        findsOneWidget,
      );
      expect(pol.jours(n: 7), '7 jours');
      // Pilotage : trois reperes lus, jamais un champ hors brouillon.
      for (final (String id, String valeur) in <(String, String)>[
        ('margeObjectif', '30'),
        ('margeForte', '35'),
        ('margeStretch', '40'),
      ]) {
        expect(
          find.descendant(
            of: find.byKey(PolitiquesCommercialesContenu.champKey(id)),
            matching: find.text(pol.pourcentValeur(valeur: valeur)),
          ),
          findsOneWidget,
          reason: id,
        );
      }
      // L'etat « sans brouillon » : la version active, publiee, datee.
      expect(find.text(pol.sansBrouillon), findsOneWidget);
      expect(_dansEntete(find.text(pol.statutPubliee)), findsOneWidget);
      expect(find.text(pol.statutBrouillon), findsNothing);
      expect(
        find.text(pol.enVigueur(date: '1er octobre 2026')),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsNothing);
      verifierUnSeulBoutonPlein(tester, maximum: 0);
      expect(find.text(pol.publier), findsNothing);
      // Huit cartes (sept sections et les regles fixes), l'en-tete et
      // l'historique ; aucun apercu sans brouillon.
      expect(
        verifierAucuneCarteCollee(
          tester,
          estCarte: (Widget w) => w is AppCard || w is BandeauAttention,
        ),
        10,
      );
      expect(
        find.byKey(PolitiquesCommercialesContenu.apercuFamilleKey),
        findsNothing,
      );
      expect(find.text(pol.apercu), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('K-58 : chaque valeur dit sa consequence en une phrase', (
      WidgetTester tester,
    ) async {
      _taille(tester, const Size(1440, 2400));
      await tester.pumpWidget(_hote(surcharges: _avec(_sansBrouillon())));
      await tester.pumpAndSettle();
      for (final String phrase in <String>[
        pol.tarifEnfantDetail,
        pol.tarifAdulteDetail,
        pol.essaisDetail,
        pol.remiseAucuneDetail,
        pol.remiseRangDetail,
        pol.remiseRangSuivantsDetail,
        pol.baseHoraireDetail,
        pol.plafondHoraireDetail,
        pol.occupationDetail,
        pol.classesObjectifDetail,
        pol.classesMaxDetail,
        pol.internetDetail,
        pol.capaciteEnfantDetail,
        pol.capaciteAdulteDetail,
        pol.capaciteDebutantDetail,
        pol.minimumDetail,
        pol.railWebDetail,
        pol.conservationDetail,
        pol.margeDetail,
      ]) {
        expect(find.text(phrase), findsOneWidget, reason: phrase);
      }
    });
  });

  group('brouillon', () {
    testWidgets('statut, date d effet, champs preremplis, un seul bouton '
        'plein', (WidgetTester tester) async {
      _taille(tester, const Size(1440, 2600));
      await tester.pumpWidget(_hote(surcharges: _avec(_avecBrouillon())));
      await tester.pumpAndSettle();

      expect(_dansEntete(find.text(pol.statutBrouillon)), findsOneWidget);
      expect(_dansEntete(find.text(pol.statutPubliee)), findsOneWidget);
      expect(
        find.text(
          pol.versionBrouillon(
            version: DonneesFinanceDemo.politiqueBrouillon.version,
          ),
        ),
        findsOneWidget,
      );
      expect(
        _dansEntete(find.text(pol.dateEffet(date: '1er janvier 2027'))),
        findsOneWidget,
      );
      expect(find.text(pol.aucuneDifference), findsOneWidget);
      expect(find.text(pol.nonEnregistre), findsOneWidget);

      // Saisie en unites entieres : 50 $, -5 $ (« 5 $ de remise »), 4 et 7
      // par heure, capacites 5 / 6 / 4, minimum 4, 7 jours.
      final Map<String, String> attendu = <String, String>{
        'tarifEnfant': '50',
        'tarifAdulte': '60',
        'essais': '2',
        'remise-3': '5',
        'remise-4': '7',
        'baseHoraire': '4',
        'plafondHoraire': '7',
        'classesObjectif': '3',
        'classesMax': '4',
        // L'aide Internet n'est pas encore fixee : un champ vide, qui le dit.
        'internet': '',
        'capaciteEnfant': '5',
        'capaciteAdulte': '6',
        'capaciteDebutant': '4',
        'minimum': '4',
        'conservation': '7',
      };
      for (final MapEntry<String, String> e in attendu.entries) {
        expect(_saisie(tester, e.key), e.value, reason: e.key);
      }
      expect(
        tester.widget<TextField>(_champ('remise-3')).decoration!.suffixText,
        pol.suffixeRemise(symbole: r'$'),
      );
      expect(
        tester.widget<TextField>(_champ('baseHoraire')).decoration!.suffixText,
        pol.suffixeParHeure(symbole: r'$'),
      );
      final InputDecoration internet = tester
          .widget<TextField>(_champ('internet'))
          .decoration!;
      expect(internet.hintText, pol.internetNonFixee);
      expect(internet.suffixText, r'$');
      expect(internet.errorText, isNull);
      // Aucune comparaison tant que rien ne differe.
      for (final String id in _reglables) {
        expect(_comparaison(id), findsNothing, reason: id);
      }
      verifierUnSeulBoutonPlein(tester);
      expect(find.text(pol.publier), findsOneWidget);
      expect(find.text(pol.publierConsequence), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('aucun invariant n est un champ', (WidgetTester tester) async {
      _taille(tester, const Size(1440, 2600));
      await tester.pumpWidget(_hote(surcharges: _avec(_avecBrouillon())));
      await tester.pumpAndSettle();

      // Les champs sont exactement les reglables, un par parametre.
      expect(find.byType(TextField), findsNWidgets(_reglables.length));
      for (final String id in _reglables) {
        expect(_champ(id), findsOneWidget, reason: id);
      }
      // Les regles fixes : du texte, aucun champ dans leur carte.
      final Finder carte = find.byKey(
        PolitiquesCommercialesContenu.invariantsKey,
      );
      // Les six invariants du guide §5.7.
      for (final String regle in <String>[
        pol.invariantIdempotence,
        pol.invariantSoldes,
        pol.invariantHistorique,
        pol.invariantConfirmation,
        pol.invariantDoubleDebit,
        pol.invariantPeriode,
      ]) {
        expect(
          find.descendant(of: carte, matching: find.text(regle)),
          findsOneWidget,
          reason: regle,
        );
      }
      expect(
        find.descendant(of: carte, matching: find.byType(TextField)),
        findsNothing,
      );
      // Le paiement web : un interrupteur, jamais un champ de saisie
      // (FI-Q21.1) ; la marge : trois champs, deja comptes dans les
      // reglables.
      expect(find.text(pol.railWeb), findsOneWidget);
      expect(find.text(pol.railActif), findsOneWidget);
      expect(
        find.descendant(
          of: find.ancestor(
            of: find.text(pol.railWeb),
            matching: find.byType(AppCard),
          ),
          matching: find.byType(TextField),
        ),
        findsOneWidget, // la seule conservation de place
      );
      expect(_champ('marge'), findsNothing);
      expect(_champ('rails'), findsNothing);
    });

    testWidgets('aide Internet pas encore fixee : un champ facultatif, saisi '
        'en USD, compare et transmis ; vide, elle reste non fixee', (
      WidgetTester tester,
    ) async {
      _taille(tester, const Size(1440, 2600));
      final _Port port = _avecBrouillon();
      await tester.pumpWidget(_hote(surcharges: _avec(port)));
      await tester.pumpAndSettle();

      await tester.enterText(_champ('internet'), '30');
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(_comparaison('internet')).data,
        pol.versionActiveValeur(valeur: pol.internetNonFixee),
      );
      expect(find.text(pol.differences(n: 1)), findsOneWidget);
      await _publier(tester);
      expect(
        port.publies.single.allocationInternet,
        const Montant(3000, 'USD'),
      );

      await tester.enterText(_champ('internet'), '');
      await tester.pumpAndSettle();
      expect(_comparaison('internet'), findsNothing);
      expect(find.text(pol.erreurChamp), findsNothing);
      await _publier(tester);
      expect(port.publies.last.allocationInternet, isNull);
    });

    testWidgets('comparaison : la valeur active apparait sous un champ qui '
        'differe, et disparait quand il revient', (WidgetTester tester) async {
      _taille(tester, const Size(1440, 2600));
      await tester.pumpWidget(_hote(surcharges: _avec(_avecBrouillon())));
      await tester.pumpAndSettle();

      await tester.enterText(_champ('capaciteEnfant'), '6');
      await tester.pump();
      expect(_comparaison('capaciteEnfant'), findsOneWidget);
      expect(
        tester.widget<Text>(_comparaison('capaciteEnfant')).data,
        pol.versionActiveValeur(valeur: pol.eleves(n: 5)),
      );
      expect(find.text(pol.differences(n: 1)), findsOneWidget);

      await tester.enterText(_champ('remise-3'), '6');
      await tester.pump();
      expect(
        find.text(pol.versionActiveValeur(valeur: formaterMontant(_usd(-5)))),
        findsOneWidget,
      );
      expect(find.text(pol.differences(n: 2)), findsOneWidget);

      await tester.enterText(_champ('capaciteEnfant'), '5');
      await tester.enterText(_champ('remise-3'), '5');
      await tester.pump();
      expect(_comparaison('capaciteEnfant'), findsNothing);
      expect(_comparaison('remise-3'), findsNothing);
      expect(find.text(pol.aucuneDifference), findsOneWidget);
    });

    testWidgets('erreur de champ : la phrase sous le champ, et Publier '
        'demande de corriger sans appeler le port', (
      WidgetTester tester,
    ) async {
      _taille(tester, const Size(1440, 2600));
      final _Port port = _avecBrouillon();
      await tester.pumpWidget(_hote(surcharges: _avec(port)));
      await tester.pumpAndSettle();

      await tester.enterText(_champ('tarifEnfant'), '');
      await tester.pump();
      expect(find.text(pol.erreurChamp), findsOneWidget);
      await tester.enterText(_champ('plafondHoraire'), '7,5');
      await tester.pump();
      expect(find.text(pol.erreurChamp), findsNWidgets(2));

      await _publier(tester);
      expect(find.text(pol.champsACorriger), findsOneWidget);
      expect(port.publies, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('coherence : plafond sous la base, maximum sous l objectif, '
        'minimum au-dessus de la plus petite classe, capacite ou tarif nul, '
        'remise au-dessus du tarif ; chacun sa phrase, Publier refuse', (
      WidgetTester tester,
    ) async {
      _taille(tester, const Size(1440, 3200));
      final _Port port = _avecBrouillon();
      await tester.pumpWidget(_hote(surcharges: _avec(port)));
      await tester.pumpAndSettle();
      String? erreur(String id) =>
          tester.widget<TextField>(_champ(id)).decoration!.errorText;

      await tester.enterText(_champ('plafondHoraire'), '3');
      await tester.pumpAndSettle();
      expect(
        erreur('plafondHoraire'),
        pol.erreurPlafond(
          base: pol.parHeure(montant: formaterMontant(_usd(4))),
        ),
      );
      // L'apercu attend : aucune part d'occupation negative.
      expect(find.text(pol.apercuAttente), findsNWidgets(2));
      await _publier(tester);
      expect(find.text(pol.champsACorriger), findsOneWidget);
      expect(port.publies, isEmpty);
      await tester.enterText(_champ('plafondHoraire'), '7');

      await tester.enterText(_champ('classesMax'), '2');
      await tester.pump();
      expect(
        erreur('classesMax'),
        pol.erreurClassesMax(objectif: pol.classes(n: 3)),
      );
      await tester.enterText(_champ('classesMax'), '4');

      await tester.enterText(_champ('minimum'), '5');
      await tester.pump();
      expect(erreur('minimum'), pol.erreurMinimum(capacite: pol.eleves(n: 4)));
      await tester.enterText(_champ('minimum'), '4');

      await tester.enterText(_champ('capaciteAdulte'), '0');
      await tester.pump();
      expect(erreur('capaciteAdulte'), pol.erreurCapacite);
      // La capacite nulle porte seule l'erreur, pas le minimum.
      expect(erreur('minimum'), isNull);
      await tester.enterText(_champ('capaciteAdulte'), '6');

      await tester.enterText(_champ('tarifAdulte'), '0');
      await tester.pump();
      expect(erreur('tarifAdulte'), pol.erreurTarif);
      await tester.enterText(_champ('tarifAdulte'), '60');

      await tester.enterText(_champ('remise-3'), '51');
      await tester.pump();
      expect(
        erreur('remise-3'),
        pol.erreurRemise(tarif: formaterMontant(_usd(50))),
      );
      await tester.enterText(_champ('remise-3'), '50');
      await tester.pump();
      expect(erreur('remise-3'), isNull);
      await tester.enterText(_champ('remise-3'), '5');
      await tester.pumpAndSettle();

      for (final String id in _reglables) {
        expect(erreur(id), isNull, reason: id);
      }
      await _publier(tester);
      expect(port.publies, hasLength(1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('franc guineen : un tarif de 1 500 000 GNF se preremplit sans '
        'erreur et se publie tel quel', (WidgetTester tester) async {
      _taille(tester, const Size(1440, 2600));
      final _Port port = _avecCeBrouillon(
        _brouillon(tarifEnfant: const Montant(1500000, 'GNF')),
      );
      await tester.pumpWidget(_hote(surcharges: _avec(port)));
      await tester.pumpAndSettle();
      expect(_saisie(tester, 'tarifEnfant'), '1500000');
      expect(
        tester.widget<TextField>(_champ('tarifEnfant')).decoration!.errorText,
        isNull,
      );
      expect(find.text(pol.erreurChamp), findsNothing);
      await _publier(tester);
      expect(find.text(pol.champsACorriger), findsNothing);
      expect(port.publies.single.tarifEnfant, const Montant(1500000, 'GNF'));
    });

    testWidgets('marge et rails qui different : comptes dans l en-tete et '
        'rappeles sous leur ligne', (WidgetTester tester) async {
      _taille(tester, const Size(1440, 2600));
      await tester.pumpWidget(
        _hote(
          surcharges: _avec(
            _avecCeBrouillon(
              _brouillon(
                marge: (objectif: 320, forte: 350, stretch: 400),
                rails: const <RailPaiement>{},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(pol.aucuneDifference), findsNothing);
      expect(find.text(pol.differences(n: 2)), findsOneWidget);
      // FI-Q21.1 : la marge se regle repere par repere ; seul l'objectif
      // differe, il est rappele sous son champ.
      expect(_saisie(tester, 'margeObjectif'), '32');
      expect(
        tester.widget<Text>(_comparaison('margeObjectif')).data,
        pol.versionActiveValeur(valeur: pol.pourcentValeur(valeur: '30')),
      );
      expect(_comparaison('margeForte'), findsNothing);
      expect(
        tester.widget<Text>(_comparaison('rails')).data,
        pol.versionActiveValeur(valeur: pol.railActif),
      );
      expect(find.text(pol.railInactif), findsOneWidget);
    });

    testWidgets('un rang remise dans le brouillon, sans remise dans la '
        'version active : « Prix normal », jamais « Pas encore fixee »', (
      WidgetTester tester,
    ) async {
      _taille(tester, const Size(1440, 2600));
      await tester.pumpWidget(
        _hote(
          surcharges: _avec(
            _avecCeBrouillon(
              _brouillon(
                remisesParRang: <RemiseRang>[
                  RemiseRang(aPartirDuRang: 2, remise: _usd(-3)),
                  RemiseRang(aPartirDuRang: 3, remise: _usd(-5)),
                  RemiseRang(aPartirDuRang: 4, remise: _usd(-7)),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(_comparaison('remise-2')).data,
        pol.versionActiveValeur(valeur: pol.remiseAucuneValeur),
      );
      expect(
        find.text(pol.versionActiveValeur(valeur: pol.internetNonFixee)),
        findsNothing,
      );
    });
  });

  group('Publier', () {
    testWidgets('l etat honnete : rien n est publie, le brouillon a l ecran '
        'est transmis tel quel, en unites mineures', (
      WidgetTester tester,
    ) async {
      _taille(tester, const Size(1440, 2600));
      final _Port port = _avecBrouillon();
      await tester.pumpWidget(_hote(surcharges: _avec(port)));
      await tester.pumpAndSettle();

      await tester.enterText(_champ('tarifAdulte'), '65');
      await tester.enterText(_champ('remise-4'), '8');
      await tester.pump();
      await _publier(tester);

      expect(
        find.descendant(
          of: find.byKey(PolitiquesCommercialesContenu.publicationKey),
          matching: find.text(pol.publicationIndisponible),
        ),
        findsOneWidget,
      );
      expect(find.text(pol.publicationIndisponibleDetail), findsOneWidget);
      final PolitiqueCommerciale envoye = port.publies.single;
      expect(envoye.statut, StatutPolitique.brouillon);
      expect(envoye.tarifAdulte, const Montant(6500, 'USD'));
      expect(envoye.remisePourRang(4), const Montant(-800, 'USD'));
      expect(envoye.remisePourRang(3), const Montant(-500, 'USD'));
      expect(envoye.capaciteEnfant, 5);
      // La version active n'a pas change : l'en-tete la dit toujours.
      expect(
        find.text(
          pol.versionActive(
            version: DonneesFinanceDemo.politiqueLancement.version,
          ),
        ),
        findsOneWidget,
      );
      verifierUnSeulBoutonPlein(tester);
      expect(tester.takeException(), isNull);
    });

    for (final (String nom, Object? rendu) in <(String, Object?)>[
      ('une erreur reseau', const SocketException('coupure')),
      (
        'une erreur serveur inattendue',
        const PostgrestException(message: 'x', code: '57014'),
      ),
    ]) {
      testWidgets('$nom : « Publication non confirmee », jamais un succes ni '
          'le brouillon dit publie', (WidgetTester tester) async {
        _taille(tester, const Size(1440, 2600));
        final _Port port = _Port(
          versionsRendues: _avecBrouillon().versionsRendues,
          publication: rendu,
        );
        await tester.pumpWidget(_hote(surcharges: _avec(port)));
        await tester.pumpAndSettle();
        await _publier(tester);

        expect(port.publies, hasLength(1));
        expect(
          find.descendant(
            of: find.byKey(PolitiquesCommercialesContenu.publicationKey),
            matching: find.text(pol.publicationNonConfirmee),
          ),
          findsOneWidget,
        );
        expect(find.text(pol.publicationNonConfirmeeDetail), findsOneWidget);
        expect(find.text(pol.publicationIndisponible), findsNothing);
        // Le brouillon reste un brouillon ; « Publiee » ne marque que la
        // version active, dans l'en-tete comme dans l'historique.
        expect(_dansEntete(find.text(pol.statutBrouillon)), findsOneWidget);
        expect(_dansEntete(find.text(pol.statutPubliee)), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(
              PolitiquesCommercialesContenu.historiqueLigneKey(
                DonneesFinanceDemo.politiqueBrouillon.version,
              ),
            ),
            matching: find.text(pol.statutPubliee),
          ),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('reponse du serveur : « Version publiee », versions relues, '
        'le message survit a la relecture', (WidgetTester tester) async {
      _taille(tester, const Size(1440, 2600));
      final _Port port = _Port(
        versionsRendues: _avecBrouillon().versionsRendues,
        publication: null,
      );
      await tester.pumpWidget(_hote(surcharges: _avec(port)));
      await tester.pumpAndSettle();
      final int lecturesAvant = port.lectures;
      await _publier(tester);

      expect(port.publies, hasLength(1));
      expect(port.lectures, greaterThan(lecturesAvant));
      expect(
        find.descendant(
          of: find.byKey(PolitiquesCommercialesContenu.publicationKey),
          matching: find.text(pol.publicationFaite),
        ),
        findsOneWidget,
      );
      expect(find.text(pol.publicationFaiteDetail), findsOneWidget);
      expect(find.text(pol.publicationNonConfirmee), findsNothing);
      verifierUnSeulBoutonPlein(tester);
      expect(tester.takeException(), isNull);
    });

    for (final (String code, String titre, String detail)
        in <(String, String, String)>[
          ('42501', pol.publicationRefusee, pol.publicationRefuseeDetail),
          ('22023', pol.publicationInvalide, pol.publicationInvalideDetail),
        ]) {
      testWidgets(
        'refus $code du serveur : « $titre », rien n est dit publie',
        (WidgetTester tester) async {
          _taille(tester, const Size(1440, 2600));
          final _Port port = _Port(
            versionsRendues: _avecBrouillon().versionsRendues,
            publication: PostgrestException(message: 'refus', code: code),
          );
          await tester.pumpWidget(_hote(surcharges: _avec(port)));
          await tester.pumpAndSettle();
          await _publier(tester);

          expect(
            find.descendant(
              of: find.byKey(PolitiquesCommercialesContenu.publicationKey),
              matching: find.text(titre),
            ),
            findsOneWidget,
          );
          expect(find.text(detail), findsOneWidget);
          expect(find.text(pol.publicationFaite), findsNothing);
          expect(_dansEntete(find.text(pol.statutBrouillon)), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('demonstration : la publication reste indisponible', (
      WidgetTester tester,
    ) async {
      _taille(tester, const Size(1440, 2600));
      await tester.pumpWidget(
        _hote(surcharges: _avec(const PolitiquesCommercialesDemo())),
      );
      await tester.pumpAndSettle();
      expect(_dansEntete(find.text(pol.statutBrouillon)), findsOneWidget);
      await _publier(tester);
      expect(find.text(pol.publicationIndisponible), findsOneWidget);
      await expectLater(
        const PolitiquesCommercialesDemo().publier(
          DonneesFinanceDemo.politiqueBrouillon,
        ),
        throwsA(isA<CapaciteIndisponible>()),
      );
      await expectLater(
        const PolitiquesCommercialesIndisponibles().publier(
          DonneesFinanceDemo.politiqueBrouillon,
        ),
        throwsA(isA<CapaciteIndisponible>()),
      );
    });
  });

  group('etats', () {
    testWidgets('chargement : le squelette, aucune valeur', (
      WidgetTester tester,
    ) async {
      final Completer<PolitiquesLues> jamais = Completer<PolitiquesLues>();
      await tester.pumpWidget(
        _hote(
          surcharges: <Override>[
            politiquesCommercialesProvider.overrideWith(
              (Ref _) => jamais.future,
            ),
          ],
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(Skeleton), findsWidgets);
      expect(find.text(pol.tarifs), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('production : « Pas encore disponible », sans Reessayer, '
        'champ ni chiffre', (WidgetTester tester) async {
      await tester.pumpWidget(_hote(surcharges: const <Override>[]));
      await tester.pumpAndSettle();
      expect(_estEtat(NatureEtat.indisponible), isTrue);
      expect(find.text(pol.tarifs), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.textContaining(r'$'), findsNothing);
      expect(find.text(pol.publier), findsNothing);
    });

    testWidgets('production hors ligne : reste indisponible', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _hote(surcharges: const <Override>[], horsLigne: true),
      );
      await tester.pumpAndSettle();
      expect(_estEtat(NatureEtat.indisponible), isTrue);
      expect(_estEtat(NatureEtat.horsLigne), isFalse);
    });

    testWidgets('erreur : l echec du bloc, avec Reessayer qui relit', (
      WidgetTester tester,
    ) async {
      int lectures = 0;
      await tester.pumpWidget(
        _hote(
          surcharges: <Override>[
            politiquesCommercialesProvider.overrideWith((Ref _) {
              lectures++;
              return Future<PolitiquesLues>.error(StateError('panne'));
            }),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(_estEtat(NatureEtat.echecServeur), isTrue);
      expect(find.text(pol.tarifs), findsNothing);
      await tester.tap(
        find.text(EtatSysteme.libelleActionPar(NatureEtat.echecServeur)),
      );
      await tester.pumpAndSettle();
      expect(lectures, 2);
    });

    testWidgets('hors ligne : l echec se dit « hors ligne »', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _hote(
          surcharges: _avec(_Port(erreur: StateError('reseau'))),
          horsLigne: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(_estEtat(NatureEtat.horsLigne), isTrue);
      expect(_estEtat(NatureEtat.echecServeur), isFalse);
    });
  });

  group('apercu : calcul du double de demonstration (lancement)', () {
    const PolitiquesCommercialesDemo demo = PolitiquesCommercialesDemo();
    final PolitiqueCommerciale lancement =
        DonneesFinanceDemo.politiqueLancement;

    test('foyer : 3 profils = 145 USD, 5 profils = 231 USD', () async {
      final ApercuFamille trois = await demo.apercuFamille(lancement, 3);
      expect(trois.enfants.map((MensualiteApercu m) => m.mensualite), <Montant>[
        _usd(50),
        _usd(50),
        _usd(45),
      ]);
      expect(trois.total, const Montant(14500, 'USD'));
      expect(trois.enfants[0].remise, isNull);
      expect(trois.enfants[2].remise, _usd(-5));
      final ApercuFamille cinq = await demo.apercuFamille(lancement, 5);
      expect(cinq.enfants.map((MensualiteApercu m) => m.mensualite), <Montant>[
        _usd(50),
        _usd(50),
        _usd(45),
        _usd(43),
        _usd(43),
      ]);
      expect(cinq.total, const Montant(23100, 'USD'));
      final ApercuFamille un = await demo.apercuFamille(lancement, 1);
      expect(un.total, _usd(50));
    });

    test('enseignant : base 4, plafond 7, capacite 5 : 5 eligibles = 7 \$/h, '
        '4 eligibles = 6,40 \$/h', () async {
      final ApercuEnseignant plein = await demo.apercuEnseignant(
        lancement,
        capacite: 5,
        eligibles: 5,
      );
      expect(plein.tauxHoraire, const Montant(700, 'USD'));
      expect(plein.occupation, const Montant(300, 'USD'));
      final ApercuEnseignant quatre = await demo.apercuEnseignant(
        lancement,
        capacite: 5,
        eligibles: 4,
      );
      expect(quatre.tauxHoraire, const Montant(640, 'USD'));
      expect(quatre.baseHoraire, const Montant(400, 'USD'));
      expect(quatre.occupation, const Montant(240, 'USD'));
      expect(formaterMontant(quatre.tauxHoraire), '6,40 \$');
      // Le meme taux que les revenus de l'enseignant (une seule formule).
      expect(
        quatre.tauxHoraire,
        DonneesFinanceDemo.tauxEffectif(siegesEligibles: 4, capacite: 5),
      );
      await expectLater(
        demo.apercuEnseignant(lancement, capacite: 0, eligibles: 0),
        throwsArgumentError,
      );
    });

    test('incoherences refusees par le double : plafond sous la base, '
        'remise au-dessus du tarif (aucun montant negatif)', () {
      final PolitiqueCommerciale l = lancement;
      final PolitiqueCommerciale incoherente = PolitiqueCommerciale(
        version: l.version,
        statut: l.statut,
        dateEffet: l.dateEffet,
        tarifEnfant: l.tarifEnfant,
        tarifAdulte: l.tarifAdulte,
        essaisMax: l.essaisMax,
        essaiActif: l.essaiActif,
        remisesParRang: <RemiseRang>[
          RemiseRang(aPartirDuRang: 3, remise: _usd(-60)),
        ],
        baseHoraire: _usd(4),
        plafondHoraire: _usd(3),
        capaciteEnfant: l.capaciteEnfant,
        capaciteAdulte: l.capaciteAdulte,
        capaciteDebutant: l.capaciteDebutant,
        minimumOuverture: l.minimumOuverture,
        classesObjectif: l.classesObjectif,
        classesMax: l.classesMax,
        joursConservationPlace: l.joursConservationPlace,
        margeReferencePourMille: l.margeReferencePourMille,
        railsActifs: l.railsActifs,
      );
      expect(
        () => DonneesFinanceDemo.apercuEnseignant(
          incoherente,
          capacite: 5,
          eligibles: 5,
        ),
        throwsArgumentError,
      );
      expect(
        () => DonneesFinanceDemo.apercuFamille(incoherente, 3),
        throwsArgumentError,
      );
      // Deux rangs au prix normal restent calcules.
      expect(DonneesFinanceDemo.apercuFamille(incoherente, 2).total, _usd(100));
    });

    test('production : l apercu est indisponible', () async {
      await expectLater(
        const PolitiquesCommercialesIndisponibles().apercuFamille(lancement, 3),
        throwsA(isA<CapaciteIndisponible>()),
      );
      await expectLater(
        const PolitiquesCommercialesIndisponibles().apercuEnseignant(
          lancement,
          capacite: 5,
          eligibles: 5,
        ),
        throwsA(isA<CapaciteIndisponible>()),
      );
    });
  });

  group('apercu a l ecran', () {
    const Key famille = PolitiquesCommercialesContenu.apercuFamilleKey;
    const Key enseignant = PolitiquesCommercialesContenu.apercuEnseignantKey;
    const Key total = PolitiquesCommercialesContenu.apercuTotalKey;
    const Key taux = PolitiquesCommercialesContenu.apercuTauxKey;
    String parHeure(int mineur) =>
        pol.parHeure(montant: formaterMontant(Montant(mineur, 'USD')));

    testWidgets('brouillon = lancement : 3 enfants 145 USD, 5 enfants '
        '231 USD ; classe de 5 : 7 \$/h puis 6,40 \$/h', (
      WidgetTester tester,
    ) async {
      _taille(tester, const Size(1440, 3200));
      final _Port port = _avecBrouillon();
      await tester.pumpWidget(_hote(surcharges: _avec(port)));
      await tester.pumpAndSettle();

      expect(find.text(pol.apercu), findsOneWidget);
      // Le foyer de la maquette : trois enfants payants.
      expect(_ligneDit(total, formaterMontant(_usd(145))), isTrue);
      expect(
        _ligneDit(
          PolitiquesCommercialesContenu.apercuEnfantKey(3),
          pol.apercuRemise(montant: formaterMontant(_usd(-5))),
        ),
        isTrue,
      );
      expect(
        _ligneDit(
          PolitiquesCommercialesContenu.apercuEnfantKey(1),
          pol.apercuPrixNormal,
        ),
        isTrue,
      );
      expect(port.apercusFamille.last.$2, 3);

      await _toucher(tester, find.text(pol.apercuEnfants(n: 5)));
      expect(_ligneDit(total, formaterMontant(_usd(231))), isTrue);
      expect(
        _ligneDit(
          PolitiquesCommercialesContenu.apercuEnfantKey(5),
          formaterMontant(_usd(43)),
        ),
        isTrue,
      );
      expect(port.apercusFamille.last.$2, 5);

      await _toucher(tester, find.text(pol.apercuEnfants(n: 1)));
      expect(_ligneDit(total, formaterMontant(_usd(50))), isTrue);
      expect(
        find.byKey(PolitiquesCommercialesContenu.apercuEnfantKey(2)),
        findsNothing,
      );

      // Enseignant : classe d'enfants de 5, pleine par defaut.
      expect(
        _dans(
          enseignant,
          find.text(pol.apercuEligibles(eligibles: '5', capacite: '5')),
        ),
        findsOneWidget,
      );
      expect(_ligneDit(taux, parHeure(700)), isTrue);
      expect(port.apercusEnseignant.last, (5, 5));
      // A la capacite, « plus » disparait (sa place reste), jamais grise.
      expect(
        tester
            .widget<Visibility>(
              find
                  .ancestor(
                    of: _bouton(pol.apercuEligiblesPlus),
                    matching: find.byType(Visibility),
                  )
                  .first,
            )
            .visible,
        isFalse,
      );
      await _toucher(tester, _bouton(pol.apercuEligiblesMoins));
      expect(_ligneDit(taux, parHeure(640)), isTrue);
      expect(
        _dans(
          enseignant,
          find.text(pol.apercuOccupationDetail(eligibles: '4', capacite: '5')),
        ),
        findsOneWidget,
      );
      expect(port.apercusEnseignant.last, (5, 4));
      // Classe d'adultes : 6 sieges, pleine.
      await _toucher(tester, find.text(pol.apercuClasseAdultes));
      expect(port.apercusEnseignant.last, (6, 6));
      expect(_ligneDit(taux, parHeure(700)), isTrue);
      verifierUnSeulBoutonPlein(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('remise de rang 3 de 5 a 6 dans le brouillon : 3 enfants = '
        '144 USD, relu sur le port', (WidgetTester tester) async {
      _taille(tester, const Size(1440, 3200));
      final _Port port = _avecBrouillon();
      await tester.pumpWidget(_hote(surcharges: _avec(port)));
      await tester.pumpAndSettle();
      expect(_ligneDit(total, formaterMontant(_usd(145))), isTrue);
      final int appels = port.apercusFamille.length;

      await tester.enterText(_champ('remise-3'), '6');
      await tester.pumpAndSettle();
      expect(_ligneDit(total, formaterMontant(_usd(144))), isTrue);
      expect(port.apercusFamille.length, greaterThan(appels));
      expect(
        port.apercusFamille.last.$1.remisePourRang(3),
        const Montant(-600, 'USD'),
      );
      // Le plafond du brouillon change le taux de la classe pleine.
      await tester.enterText(_champ('plafondHoraire'), '8');
      await tester.pumpAndSettle();
      expect(_ligneDit(taux, parHeure(800)), isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('saisie invalide : l apercu attend, puis se recalcule', (
      WidgetTester tester,
    ) async {
      _taille(tester, const Size(1440, 3200));
      final _Port port = _avecBrouillon();
      await tester.pumpWidget(_hote(surcharges: _avec(port)));
      await tester.pumpAndSettle();
      final int appels = port.apercusFamille.length;

      await tester.enterText(_champ('tarifEnfant'), '');
      await tester.pumpAndSettle();
      expect(find.text(pol.apercuAttente), findsNWidgets(2));
      expect(find.text(pol.apercuAttenteDetail), findsNWidgets(2));
      expect(find.byKey(total), findsNothing);
      expect(find.byKey(taux), findsNothing);
      expect(port.apercusFamille.length, appels);

      await tester.enterText(_champ('tarifEnfant'), '55');
      await tester.pumpAndSettle();
      expect(find.text(pol.apercuAttente), findsNothing);
      // 55 + 55 + 50 : la remise de rang 3 s'applique au nouveau tarif.
      expect(_ligneDit(total, formaterMontant(_usd(160))), isTrue);

      // Une classe sans siege est refusee sous son champ : l'apercu attend,
      // sans taux.
      await tester.enterText(_champ('capaciteEnfant'), '0');
      await tester.pumpAndSettle();
      expect(find.text(pol.erreurCapacite), findsOneWidget);
      expect(_dans(enseignant, find.text(pol.apercuAttente)), findsOneWidget);
      expect(find.byKey(taux), findsNothing);
      expect(find.byKey(total), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('recalcul lent apres un premier resultat : l ancien total est '
        'signale perime, puis remplace', (WidgetTester tester) async {
      _taille(tester, const Size(1440, 3200));
      final _Port port = _avecBrouillon();
      await tester.pumpWidget(_hote(surcharges: _avec(port)));
      await tester.pumpAndSettle();
      expect(_ligneDit(total, formaterMontant(_usd(145))), isTrue);
      expect(find.text(pol.apercuRecalcul), findsNothing);

      port.apercuSuspendu = true;
      await _toucher(tester, find.text(pol.apercuEnfants(n: 5)));
      // La pilule « 5 enfants » est retenue ; le total de 3 reste a l'ecran
      // mais il est dit perime, en region annoncee.
      expect(_dans(famille, find.text(pol.apercuRecalcul)), findsOneWidget);
      expect(
        _dans(famille, find.text(pol.apercuRecalculDetail)),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Semantics>(
              find
                  .ancestor(
                    of: find.text(pol.apercuRecalcul),
                    matching: find.byType(Semantics),
                  )
                  .first,
            )
            .properties
            .liveRegion,
        isTrue,
      );
      expect(_dans(enseignant, find.text(pol.apercuRecalcul)), findsNothing);

      // Le meme signe pour le taux d'une classe.
      await _toucher(tester, _bouton(pol.apercuEligiblesMoins));
      expect(_dans(enseignant, find.text(pol.apercuRecalcul)), findsOneWidget);

      // Une reponse arrive : le signe disparait avec l'ancien resultat.
      port.apercuSuspendu = false;
      await _toucher(tester, find.text(pol.apercuEnfants(n: 4)));
      expect(_dans(famille, find.text(pol.apercuRecalcul)), findsNothing);
      expect(_ligneDit(total, formaterMontant(_usd(188))), isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('calcul en cours : le squelette dans chaque carte', (
      WidgetTester tester,
    ) async {
      _taille(tester, const Size(1440, 3200));
      await tester.pumpWidget(
        _hote(
          surcharges: _avec(
            _Port(
              versionsRendues: _avecBrouillon().versionsRendues,
              apercuSuspendu: true,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(_dans(famille, find.byType(Skeleton)), findsOneWidget);
      expect(_dans(enseignant, find.byType(Skeleton)), findsOneWidget);
      expect(find.byKey(total), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('apercu indisponible : dit honnetement, sans relance ni '
        'montant', (WidgetTester tester) async {
      _taille(tester, const Size(1440, 3200));
      await tester.pumpWidget(
        _hote(
          surcharges: _avec(
            _Port(
              versionsRendues: _avecBrouillon().versionsRendues,
              erreurApercu: const CapaciteIndisponible('FI-BR-01'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(pol.apercuIndisponible), findsNWidgets(2));
      expect(find.text(pol.apercuRecalculer), findsNothing);
      expect(find.byKey(total), findsNothing);
      // Le reste de l'ecran reste en place.
      expect(find.text(pol.publier), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('apercu en echec : relancer rappelle le port ; hors ligne, '
        'il le dit', (WidgetTester tester) async {
      _taille(tester, const Size(1440, 3200));
      final _Port port = _Port(
        versionsRendues: _avecBrouillon().versionsRendues,
        erreurApercu: StateError('panne'),
      );
      await tester.pumpWidget(_hote(surcharges: _avec(port)));
      await tester.pumpAndSettle();
      expect(find.text(pol.apercuErreur), findsNWidgets(2));
      expect(find.text(pol.apercuErreurDetail), findsNWidgets(2));
      final int appels = port.apercusFamille.length;
      await _toucher(tester, _dans(famille, find.text(pol.apercuRecalculer)));
      expect(port.apercusFamille.length, appels + 1);
      expect(find.text(pol.apercuErreur), findsNWidgets(2));
      verifierUnSeulBoutonPlein(tester);

      // Une nouvelle lecture, appareil hors ligne.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(_hote(surcharges: _avec(port), horsLigne: true));
      await tester.pumpAndSettle();
      expect(find.text(pol.apercuHorsLigne), findsNWidgets(2));
      expect(find.text(pol.apercuErreur), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('historique des versions', () {
    const Key carte = PolitiquesCommercialesContenu.historiqueKey;

    testWidgets('brouillon puis version active, statut et date d effet, la '
        'version active marquee, rien d editable', (WidgetTester tester) async {
      _taille(tester, const Size(1440, 3200));
      await tester.pumpWidget(_hote(surcharges: _avec(_avecBrouillon())));
      await tester.pumpAndSettle();

      final PolitiqueCommerciale b = DonneesFinanceDemo.politiqueBrouillon;
      final PolitiqueCommerciale a = DonneesFinanceDemo.politiqueLancement;
      final Finder ligneB = find.byKey(
        PolitiquesCommercialesContenu.historiqueLigneKey(b.version),
      );
      final Finder ligneA = find.byKey(
        PolitiquesCommercialesContenu.historiqueLigneKey(a.version),
      );
      expect(_dans(carte, find.text(pol.historique)), findsOneWidget);
      // La plus recente d'abord.
      expect(
        tester.getTopLeft(ligneB).dy,
        lessThan(tester.getTopLeft(ligneA).dy),
      );
      expect(
        find.descendant(of: ligneB, matching: find.text(pol.statutBrouillon)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: ligneB,
          matching: find.text(pol.dateEffet(date: '1er janvier 2027')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: ligneA, matching: find.text(pol.statutPubliee)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: ligneA,
          matching: find.text(pol.dateEffet(date: '1er octobre 2026')),
        ),
        findsOneWidget,
      );
      // Une seule version active, marquee sur sa ligne.
      expect(find.text(pol.historiqueActive), findsOneWidget);
      expect(
        find.descendant(of: ligneA, matching: find.text(pol.historiqueActive)),
        findsOneWidget,
      );
      expect(_dans(carte, find.byType(TextField)), findsNothing);
      expect(_dans(carte, find.byType(FilterPill)), findsNothing);
      expect(find.text(pol.historiqueVide), findsNothing);
    });

    testWidgets('version active seule : une ligne, marquee, et la phrase', (
      WidgetTester tester,
    ) async {
      _taille(tester, const Size(1440, 2600));
      await tester.pumpWidget(_hote(surcharges: _avec(_sansBrouillon())));
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          PolitiquesCommercialesContenu.historiqueLigneKey(
            DonneesFinanceDemo.politiqueLancement.version,
          ),
        ),
        findsOneWidget,
      );
      expect(find.text(pol.historiqueActive), findsOneWidget);
      expect(find.text(pol.historiqueVide), findsOneWidget);
    });
  });

  test('garde de source : aucune formule de prix, remise ou taux dans '
      'lib/features/admin_finance (FI6)', () {
    final List<File> fichiers = Directory('lib/features/admin_finance')
        .listSync()
        .whereType<File>()
        .where((File f) => f.path.endsWith('.dart'))
        .toList();
    expect(fichiers, isNotEmpty);
    final List<(String, RegExp)> interdits = <(String, RegExp)>[
      ('division par 100', RegExp(r'~/\s*100')),
      ('multiplication par 7', RegExp(r'\*\s*7\b')),
      ('arithmetique sur unites mineures', RegExp(r'\.mineur\s*[-+*/~]')),
      ('arithmetique sur unites mineures', RegExp(r'[-+*/]\s*\w+\.mineur')),
      ('somme d une liste', RegExp(r'fold\s*<')),
      ('formule de taux', RegExp(r'tauxEffectif|eligibles\s*/|/\s*capacite\b')),
      ('mensualites par rang', RegExp(r'lignesPourRang|DonneesFinanceDemo')),
      ('remise appliquee', RegExp(r'(tarif\w*|remise\w*)\s*[-+]\s*\w')),
    ];
    for (final File f in fichiers) {
      // Le code seul : les commentaires peuvent citer une formule.
      final String source = f
          .readAsLinesSync()
          .where((String l) => !l.trimLeft().startsWith('//'))
          .join('\n');
      for (final (String nom, RegExp motif) in interdits) {
        expect(motif.hasMatch(source), isFalse, reason: '${f.path} : $nom');
      }
    }
    // L'apercu passe bien par le port.
    final String ecran = File(
      'lib/features/admin_finance/politiques_commerciales.dart',
    ).readAsStringSync();
    expect(ecran, contains('.apercuFamille('));
    expect(ecran, contains('.apercuEnseignant('));
  });

  group('contre-revue FI-VAGUE-R', () {
    testWidgets('R6-05 : « Classes » partout, jamais « groupe »', (
      WidgetTester tester,
    ) async {
      _taille(tester, const Size(1440, 2600));
      await tester.pumpWidget(_hote(surcharges: _avec(_avecBrouillon())));
      await tester.pumpAndSettle();
      expect(find.text(pol.sectionClasses), findsOneWidget);
      expect(pol.sectionClasses, 'Classes');
      expect(pol.classes(n: 3), '3 classes');
      expect(pol.classes(n: 1), '1 classe');
      expect(pol.classesObjectif, 'Objectif de classes par enseignant');
      expect(pol.classesMax, 'Maximum normal de classes');
      // L'unite du champ, dans le brouillon.
      expect(
        find.descendant(
          of: find.byKey(PolitiquesCommercialesContenu.champKey('classesMax')),
          matching: find.text(pol.uniteClasses),
        ),
        findsOneWidget,
      );
      await tester.enterText(_champ('classesMax'), '2');
      await tester.pump();
      final RegExp groupe = RegExp('groupe', caseSensitive: false);
      for (final Element e in find.byType(RichText).evaluate()) {
        final String texte = (e.widget as RichText).text.toPlainText();
        expect(groupe.hasMatch(texte), isFalse, reason: texte);
      }
      expect(find.text(pol.erreurClassesMax(objectif: '3 classes')), findsOne);
    });

    testWidgets('R6-06 : activation de l essai, relances et budgets lus, '
        'budgets non contraignants', (WidgetTester tester) async {
      _taille(tester, const Size(1440, 2600));
      await tester.pumpWidget(_hote(surcharges: _avec(_sansBrouillon())));
      await tester.pumpAndSettle();
      Finder ligne(String id, String texte) => find.descendant(
        of: find.byKey(PolitiquesCommercialesContenu.champKey(id)),
        matching: find.text(texte),
      );
      expect(ligne('essaiActif', pol.essaiActivation), findsOneWidget);
      expect(ligne('essaiActif', pol.essaiActive), findsOneWidget);
      expect(ligne('essaiActif', pol.essaiActivationDetail), findsOneWidget);
      // Le guide ne fixe ni relance ni budget : rien d'invente.
      expect(ligne('relances', pol.relancesNonFixees), findsOneWidget);
      expect(ligne('relances', pol.relancesDetail), findsOneWidget);
      expect(ligne('budgets', pol.budgetsNonFixes), findsOneWidget);
      expect(ligne('budgets', pol.budgetsDetail), findsOneWidget);
      expect(pol.budgetsDetail, startsWith('Non contraignants'));
      expect(find.byType(Switch), findsNothing);
    });

    testWidgets('R6-06 : relances et budgets fixes dans le brouillon, une '
        'ligne chacun, comptes et compares', (WidgetTester tester) async {
      _taille(tester, const Size(1440, 2600));
      await tester.pumpWidget(
        _hote(
          surcharges: _avec(
            _avecCeBrouillon(
              _brouillon(
                joursRelance: const <int>[1, 3, 6],
                budgets: const <BudgetPilotage>[
                  BudgetPilotage(nature: NatureBudget.marketing, pourMille: 80),
                  BudgetPilotage(
                    nature: NatureBudget.operationnel,
                    pourMille: 150,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(pol.relanceRang(rang: '3')), findsOneWidget);
      expect(
        find.text(
          pol.relanceApres(jours: LibellesGroupe.insecable(pol.jours(n: 6))),
        ),
        findsOneWidget,
      );
      expect(find.text(pol.budgetMarketing), findsOneWidget);
      expect(find.text(pol.budgetValeur(valeur: '8')), findsOneWidget);
      expect(find.text(pol.budgetOperationnel), findsOneWidget);
      expect(find.text(pol.budgetValeur(valeur: '15')), findsOneWidget);
      expect(pol.budgetValeur(valeur: '8'), '8\u00A0%, non contraignant');
      expect(find.text(pol.differences(n: 2)), findsOneWidget);
      expect(
        tester.widget<Text>(_comparaison('relances')).data,
        pol.versionActiveValeur(valeur: pol.relancesNonFixees),
      );
      expect(
        tester.widget<Text>(_comparaison('budgets')).data,
        pol.versionActiveValeur(valeur: pol.budgetsNonFixes),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('R6-06 : l interrupteur d activation de l essai, compte, '
        'compare et transmis a la publication', (WidgetTester tester) async {
      _taille(tester, const Size(1440, 2600));
      final _Port port = _avecBrouillon();
      await tester.pumpWidget(_hote(surcharges: _avec(port)));
      await tester.pumpAndSettle();
      final Finder interrupteur = find.descendant(
        of: find.byKey(PolitiquesCommercialesContenu.champKey('essaiActif')),
        matching: find.byType(Switch),
      );
      expect(interrupteur, findsOneWidget);
      expect(find.text(pol.aucuneDifference), findsOneWidget);
      await _toucher(tester, interrupteur);
      expect(find.text(pol.essaiDesactive), findsOneWidget);
      expect(find.text(pol.differences(n: 1)), findsOneWidget);
      expect(
        tester.widget<Text>(_comparaison('essaiActif')).data,
        pol.versionActiveValeur(valeur: pol.essaiActive),
      );
      await _publier(tester);
      expect(port.publies.single.essaiActif, isFalse);
      verifierUnSeulBoutonPlein(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('R6-10 : « Publier la version », versions de demonstration '
        'numerotees', (WidgetTester tester) async {
      _taille(tester, const Size(1440, 2600));
      await tester.pumpWidget(_hote(surcharges: _avec(_avecBrouillon())));
      await tester.pumpAndSettle();
      expect(pol.publier, 'Publier la version');
      expect(find.text('Publier la version'), findsOneWidget);
      expect(
        _dansEntete(find.text(pol.versionBrouillon(version: 'v1.1.0'))),
        findsOneWidget,
      );
      expect(
        _dansEntete(find.text(pol.versionActive(version: 'v1.0.0'))),
        findsOneWidget,
      );
      expect(find.textContaining('brouillon-'), findsNothing);
    });
  });

  group('FI-DIR-1 : FI-Q21 et R6-08', () {
    testWidgets('Q21.1 : les trois reperes forment le groupe « Marge de '
        'reference », visible et annonce comme titre', (
      WidgetTester tester,
    ) async {
      _taille(tester, const Size(390, 4000));
      final SemanticsHandle semantique = tester.ensureSemantics();
      await tester.pumpWidget(_hote(surcharges: _avec(_avecBrouillon())));
      await tester.pumpAndSettle();
      final Finder groupe = find.byKey(PolitiquesCommercialesContenu.margeKey);
      expect(groupe, findsOneWidget);
      final Finder titre = find.descendant(
        of: groupe,
        matching: find.text(pol.marge),
      );
      expect(titre, findsOneWidget);
      await tester.ensureVisible(titre);
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(titre),
        matchesSemantics(label: pol.marge, isHeader: true),
      );
      for (final String id in <String>[
        'margeObjectif',
        'margeForte',
        'margeStretch',
      ]) {
        expect(
          find.descendant(
            of: groupe,
            matching: find.byKey(PolitiquesCommercialesContenu.champKey(id)),
          ),
          findsOneWidget,
          reason: id,
        );
      }
      // Le titre precede les trois champs.
      expect(
        tester.getTopLeft(titre).dy,
        lessThan(tester.getTopLeft(_champ('margeObjectif')).dy),
      );
      semantique.dispose();
    });

    testWidgets('Q21.1 : la marge de reference se regle en brouillon, '
        'repere par repere, et part au port en pour mille', (
      WidgetTester tester,
    ) async {
      _taille(tester, const Size(1440, 2600));
      final _Port port = _avecBrouillon();
      await tester.pumpWidget(_hote(surcharges: _avec(port)));
      await tester.pumpAndSettle();
      expect(_saisie(tester, 'margeObjectif'), '30');
      expect(_saisie(tester, 'margeForte'), '35');
      expect(_saisie(tester, 'margeStretch'), '40');
      expect(
        tester
            .widget<TextField>(_champ('margeObjectif'))
            .decoration!
            .suffixText,
        pol.unitePourcent,
      );
      await tester.enterText(_champ('margeObjectif'), '33');
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(_comparaison('margeObjectif')).data,
        pol.versionActiveValeur(valeur: pol.pourcentValeur(valeur: '30')),
      );
      expect(find.text(pol.differences(n: 1)), findsOneWidget);
      await _publier(tester);
      expect(port.publies.single.margeReferencePourMille, (
        objectif: 330,
        forte: 350,
        stretch: 400,
      ));
    });

    testWidgets('Q21.1 : la coherence des reperes, une phrase sous le champ', (
      WidgetTester tester,
    ) async {
      _taille(tester, const Size(1440, 2600));
      final _Port port = _avecBrouillon();
      await tester.pumpWidget(_hote(surcharges: _avec(port)));
      await tester.pumpAndSettle();
      String? erreur(String id) =>
          tester.widget<TextField>(_champ(id)).decoration!.errorText;
      await tester.enterText(_champ('margeForte'), '25');
      await tester.pump();
      expect(
        erreur('margeForte'),
        pol.erreurMargeForte(objectif: pol.pourcentValeur(valeur: '30')),
      );
      await tester.enterText(_champ('margeForte'), '35');
      await tester.enterText(_champ('margeStretch'), '34');
      await tester.pump();
      expect(
        erreur('margeStretch'),
        pol.erreurMargeStretch(forte: pol.pourcentValeur(valeur: '35')),
      );
      await tester.enterText(_champ('margeStretch'), '101');
      await tester.pump();
      expect(erreur('margeStretch'), pol.erreurMargeMax);
      await _publier(tester);
      expect(port.publies, isEmpty);
      expect(find.text(pol.champsACorriger), findsOneWidget);
    });

    testWidgets('Q21.1 et Q21.2 : le paiement web en interrupteur, iOS et '
        'Android « Préparé (inactif) », jamais un reglage', (
      WidgetTester tester,
    ) async {
      _taille(tester, const Size(1440, 2600));
      final _Port port = _avecBrouillon();
      await tester.pumpWidget(_hote(surcharges: _avec(port)));
      await tester.pumpAndSettle();
      for (final String id in <String>['railIos', 'railAndroid']) {
        final Finder ligne = find.byKey(
          PolitiquesCommercialesContenu.champKey(id),
        );
        expect(
          find.descendant(of: ligne, matching: find.text(pol.railPrepare)),
          findsOneWidget,
          reason: id,
        );
        expect(
          find.descendant(of: ligne, matching: find.byType(Switch)),
          findsNothing,
        );
      }
      final Finder web = find.descendant(
        of: find.byKey(PolitiquesCommercialesContenu.champKey('rails')),
        matching: find.byType(Switch),
      );
      expect(web, findsOneWidget);
      await _toucher(tester, web);
      expect(
        tester.widget<Text>(_comparaison('rails')).data,
        pol.versionActiveValeur(valeur: pol.railActif),
      );
      await _publier(tester);
      expect(port.publies.single.railsActifs, isEmpty);
    });

    testWidgets('Q21.2 : en lecture aussi, iOS et Android « Préparé '
        '(inactif) »', (WidgetTester tester) async {
      _taille(tester, const Size(1440, 2600));
      await tester.pumpWidget(_hote(surcharges: _avec(_sansBrouillon())));
      await tester.pumpAndSettle();
      expect(find.text(pol.railPrepare), findsNWidgets(2));
      expect(find.byType(Switch), findsNothing);
    });

    testWidgets('Q21.3 : edition directe, aucun bouton « Modifier » par '
        'carte', (WidgetTester tester) async {
      _taille(tester, const Size(1440, 2600));
      await tester.pumpWidget(_hote(surcharges: _avec(_avecBrouillon())));
      await tester.pumpAndSettle();
      expect(find.textContaining('Modifier'), findsNothing);
      expect(_champ('tarifEnfant'), findsOneWidget);
    });

    testWidgets('Q21.4 : la date d effet se regle dans le brouillon et part '
        'avec lui', (WidgetTester tester) async {
      _taille(tester, const Size(1440, 2600));
      final _Port port = _avecBrouillon();
      await tester.pumpWidget(_hote(surcharges: _avec(port)));
      await tester.pumpAndSettle();
      expect(find.text(pol.dateEffetReglable), findsOneWidget);
      // Le calendrier s'ouvre sur la date du brouillon, ou sur le lendemain
      // quand elle est passee : la cible se calcule depuis l'horloge, jamais
      // en dur (contre-revue FI-DIR-1).
      final DateTime maintenant = DateTime.now();
      final DateTime demain = DateTime(
        maintenant.year,
        maintenant.month,
        maintenant.day + 1,
      );
      final DateTime duBrouillon =
          DonneesFinanceDemo.politiqueBrouillon.dateEffet;
      final DateTime ouverture = duBrouillon.isBefore(demain)
          ? demain
          : duBrouillon;
      final DateTime cible = DateTime(
        ouverture.year,
        ouverture.month,
        ouverture.day + 1,
      );
      await _toucher(tester, find.text(pol.changerDate));
      expect(find.byType(DatePickerDialog), findsOneWidget);
      if (cible.month != ouverture.month) {
        await tester.tap(find.byTooltip('Next month'));
        await tester.pumpAndSettle();
      }
      await tester.tap(
        find.descendant(
          of: find.byType(DatePickerDialog),
          matching: find.text('${cible.day}'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      final String attendue = pol.dateEffet(date: dateEffetEnTexte(cible));
      expect(_dansEntete(find.text(attendue)), findsOneWidget);
      await _publier(tester);
      expect(port.publies.single.dateEffet, cible);
    });

    testWidgets('Q21.4 : une date d effet changee compte dans les '
        'differences', (WidgetTester tester) async {
      _taille(tester, const Size(1440, 2600));
      await tester.pumpWidget(_hote(surcharges: _avec(_avecBrouillon())));
      await tester.pumpAndSettle();
      expect(find.text(pol.aucuneDifference), findsOneWidget);
      await _toucher(tester, find.text(pol.changerDate));
      // Le calendrier s'ouvre sur un jour permis ; le jour suivant l'est
      // aussi (meme mois ou mois suivant).
      final DatePickerDialog dialogue = tester.widget<DatePickerDialog>(
        find.byType(DatePickerDialog),
      );
      final DateTime ouverture = dialogue.initialDate!;
      final DateTime cible = DateTime(
        ouverture.year,
        ouverture.month,
        ouverture.day + 1,
      );
      if (cible.month != ouverture.month) {
        await tester.tap(find.byTooltip('Next month'));
        await tester.pumpAndSettle();
      }
      await tester.tap(
        find.descendant(
          of: find.byType(DatePickerDialog),
          matching: find.text('${cible.day}'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text(pol.aucuneDifference), findsNothing);
      expect(find.text(pol.differences(n: 1)), findsOneWidget);
    });

    testWidgets('Q21.4 : une date d effet au-dela de la borne technique '
        'ouvre le calendrier sans assertion', (WidgetTester tester) async {
      _taille(tester, const Size(1440, 2600));
      final PolitiqueCommerciale b = DonneesFinanceDemo.politiqueBrouillon;
      final DateTime lointaine = DateTime(DateTime.now().year + 9, 6, 15);
      final PolitiqueCommerciale loin = PolitiqueCommerciale(
        version: b.version,
        statut: b.statut,
        dateEffet: lointaine,
        tarifEnfant: b.tarifEnfant,
        tarifAdulte: b.tarifAdulte,
        essaisMax: b.essaisMax,
        essaiActif: b.essaiActif,
        remisesParRang: b.remisesParRang,
        baseHoraire: b.baseHoraire,
        plafondHoraire: b.plafondHoraire,
        capaciteEnfant: b.capaciteEnfant,
        capaciteAdulte: b.capaciteAdulte,
        capaciteDebutant: b.capaciteDebutant,
        minimumOuverture: b.minimumOuverture,
        classesObjectif: b.classesObjectif,
        classesMax: b.classesMax,
        joursConservationPlace: b.joursConservationPlace,
        margeReferencePourMille: b.margeReferencePourMille,
        railsActifs: b.railsActifs,
        allocationInternet: b.allocationInternet,
        joursRelance: b.joursRelance,
        budgets: b.budgets,
      );
      await tester.pumpWidget(
        _hote(
          surcharges: _avec(
            _Port(
              versionsRendues: <PolitiqueCommerciale>[
                loin,
                DonneesFinanceDemo.politiqueLancement,
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _toucher(tester, find.text(pol.changerDate));
      expect(tester.takeException(), isNull);
      final DatePickerDialog dialogue = tester.widget<DatePickerDialog>(
        find.byType(DatePickerDialog),
      );
      expect(dialogue.initialDate, lointaine);
      expect(dialogue.lastDate.isBefore(lointaine), isFalse);
    });

    testWidgets('Q21.4 : sans brouillon, aucune date a regler', (
      WidgetTester tester,
    ) async {
      _taille(tester, const Size(1440, 2600));
      await tester.pumpWidget(_hote(surcharges: _avec(_sansBrouillon())));
      await tester.pumpAndSettle();
      expect(find.text(pol.changerDate), findsNothing);
    });

    testWidgets('R6-08 : 1440, les sections se lisent rangee par rangee, '
        'l en-tete tient sur une rangee, l historique en fin de page', (
      WidgetTester tester,
    ) async {
      _taille(tester, const Size(1440, 900));
      await tester.pumpWidget(_hote(surcharges: _avec(_avecBrouillon())));
      await tester.pumpAndSettle();
      Offset haut(String titre) => tester.getTopLeft(
        find
            .ancestor(of: find.text(titre), matching: find.byType(AppCard))
            .first,
      );
      final List<String> ordre = <String>[
        pol.tarifs,
        pol.essai,
        pol.remises,
        pol.enseignants,
        pol.sectionClasses,
        pol.paiement,
        pol.pilotage,
        pol.invariants,
      ];
      for (int i = 0; i < ordre.length; i += 2) {
        final Offset gauche = haut(ordre[i]);
        final Offset droite = haut(ordre[i + 1]);
        // Meme rangee : meme haut, la gauche avant la droite.
        expect(droite.dy, gauche.dy, reason: ordre[i + 1]);
        expect(droite.dx, greaterThan(gauche.dx), reason: ordre[i + 1]);
        if (i > 0) {
          expect(
            gauche.dy,
            greaterThan(haut(ordre[i - 1]).dy),
            reason: ordre[i],
          );
        }
      }
      // Le premier ecran (900 de haut) montre deja les premieres sections.
      expect(haut(pol.tarifs).dy, lessThan(900));
      // L'historique apres la publication.
      expect(
        tester
            .getTopLeft(find.byKey(PolitiquesCommercialesContenu.historiqueKey))
            .dy,
        greaterThan(tester.getTopLeft(find.text(pol.publier)).dy),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('gabarits', () {
    for (final (String nom, Size taille, double echelle)
        in <(String, Size, double)>[
          ('320 texte x2', const Size(320, 900), 2),
          ('1440', const Size(1440, 900), 1),
        ]) {
      for (final TextDirection sens in TextDirection.values) {
        for (final Brightness luminosite in Brightness.values) {
          testWidgets('$nom, ${sens.name}, ${luminosite.name} : aucun '
              'debordement, cartes separees', (WidgetTester tester) async {
            _taille(tester, taille);
            await tester.pumpWidget(
              _hote(
                surcharges: _avec(_avecBrouillon()),
                echelle: echelle,
                sens: sens,
                luminosite: luminosite,
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            // Une difference et l'etat de publication, pour tout rendre.
            await tester.enterText(_champ('capaciteEnfant'), '6');
            await tester.pump();
            await _publier(tester);
            expect(tester.takeException(), isNull);
            expect(
              find.text(pol.publicationIndisponible, skipOffstage: false),
              findsOneWidget,
            );
            expect(_comparaison('capaciteEnfant'), findsOneWidget);
            verifierAucuneCarteCollee(
              tester,
              estCarte: (Widget w) => w is AppCard || w is BandeauAttention,
            );
          });
        }
      }
    }

    // Les etats de l'apercu a 320 px, texte a 200 %, dans les deux sens.
    for (final TextDirection sens in TextDirection.values) {
      for (final (String nom, Object? erreurApercu, bool horsLigne)
          in <(String, Object?, bool)>[
            ('echec', StateError('panne'), false),
            ('hors ligne', StateError('reseau'), true),
            ('indisponible', const CapaciteIndisponible('FI-BR-01'), false),
            ('attente', null, false),
          ]) {
        testWidgets('apercu $nom, 320 texte x2, ${sens.name} : aucun '
            'debordement', (WidgetTester tester) async {
          _taille(tester, const Size(320, 900));
          await tester.pumpWidget(
            _hote(
              surcharges: _avec(
                _Port(
                  versionsRendues: _avecBrouillon().versionsRendues,
                  erreurApercu: erreurApercu,
                ),
              ),
              echelle: 2,
              sens: sens,
              horsLigne: horsLigne,
            ),
          );
          await tester.pumpAndSettle();
          if (erreurApercu == null) {
            await tester.enterText(_champ('tarifEnfant'), '');
            await tester.pumpAndSettle();
          }
          expect(tester.takeException(), isNull);
          final String titre = switch (nom) {
            'echec' => pol.apercuErreur,
            'hors ligne' => pol.apercuHorsLigne,
            'indisponible' => pol.apercuIndisponible,
            _ => pol.apercuAttente,
          };
          expect(find.text(titre, skipOffstage: false), findsNWidgets(2));
          final Finder relancer = find.text(
            pol.apercuRecalculer,
            skipOffstage: false,
          );
          if (erreurApercu is StateError) {
            expect(relancer, findsNWidgets(2));
            await _toucher(tester, relancer.first);
            expect(tester.takeException(), isNull);
          } else {
            expect(relancer, findsNothing);
          }
          verifierAucuneCarteCollee(
            tester,
            estCarte: (Widget w) => w is AppCard || w is BandeauAttention,
          );
        });
      }
    }
  });
}
