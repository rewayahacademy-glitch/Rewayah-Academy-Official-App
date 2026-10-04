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
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/bandeau_attention.dart';
import 'package:rewayah_academy/core/widgets/bouton_icone.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/filter_pill.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/admin_finance/politiques_commerciales.dart';
import 'package:rewayah_academy/features/demo/finance_demo.dart';

import '../../support/garde_interface.dart';
import '../../support/harnais.dart';

/// Un port de test : [versions] (la plus recente d'abord), ou [erreur] ; il
/// retient chaque brouillon qu'on lui demande de publier, et chaque apercu
/// demande. L'apercu est celui du double de demonstration, ou
/// [erreurApercu], ou [apercuSuspendu] (jamais rendu).
class _Port implements PortPolitiquesCommerciales {
  _Port({
    this.versionsRendues,
    this.erreur,
    this.erreurApercu,
    this.apercuSuspendu = false,
  });

  final List<PolitiqueCommerciale>? versionsRendues;
  final Object? erreur;
  final Object? erreurApercu;
  final bool apercuSuspendu;
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

  @override
  Future<List<PolitiqueCommerciale>> versions() async =>
      versionsRendues ?? <PolitiqueCommerciale>[];

  @override
  Future<void> publier(PolitiqueCommerciale brouillon) {
    publies.add(brouillon);
    return Future<void>.error(const CapaciteIndisponible('FI-BR-02'));
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
  'groupesObjectif',
  'groupesMax',
  'capaciteEnfant',
  'capaciteAdulte',
  'capaciteDebutant',
  'minimum',
  'conservation',
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
      // Enseignants : base 4 / plafond 7, par heure ; 3 et 4 groupes.
      expect(
        find.text(pol.parHeure(montant: formaterMontant(_usd(4)))),
        findsOneWidget,
      );
      expect(
        find.text(pol.parHeure(montant: formaterMontant(_usd(7)))),
        findsOneWidget,
      );
      expect(find.text(pol.groupes(n: 3)), findsOneWidget);
      expect(find.text(pol.groupes(n: 4)), findsOneWidget);
      expect(find.text(pol.internetNonFixee), findsOneWidget);
      // Groupes : 5 enfants, 6 adultes, 4 debutants, minimum 4.
      expect(find.text(pol.eleves(n: 5)), findsOneWidget);
      expect(find.text(pol.eleves(n: 6)), findsOneWidget);
      expect(find.text(pol.eleves(n: 4)), findsNWidgets(2));
      // Essai, place conservee.
      expect(find.text(pol.seances(n: 2)), findsOneWidget);
      expect(find.text(pol.jours(n: 7)), findsOneWidget);
      expect(pol.jours(n: 7), '7 jours');
      // Pilotage : des references, jamais un champ.
      expect(
        find.text(pol.margeValeur(objectif: '30', forte: '35', stretch: '40')),
        findsOneWidget,
      );
      // L'etat « sans brouillon » : la version active, publiee, datee.
      expect(find.text(pol.sansBrouillon), findsOneWidget);
      expect(_dansEntete(find.text(pol.statutPubliee)), findsOneWidget);
      expect(find.text(pol.statutBrouillon), findsNothing);
      expect(find.text(pol.enVigueur(date: '1 octobre 2026')), findsOneWidget);
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
        pol.groupesObjectifDetail,
        pol.groupesMaxDetail,
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
        _dansEntete(find.text(pol.dateEffet(date: '1 janvier 2027'))),
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
        'groupesObjectif': '3',
        'groupesMax': '4',
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
      for (final String regle in <String>[
        pol.invariantConfirmation,
        pol.invariantDoubleDebit,
        pol.invariantPeriode,
        pol.invariantSoldes,
      ]) {
        expect(
          find.descendant(of: carte, matching: find.text(regle)),
          findsOneWidget,
        );
      }
      expect(
        find.descendant(of: carte, matching: find.byType(TextField)),
        findsNothing,
      );
      // Le paiement web seul : une ligne lue, jamais un champ ; la marge de
      // reference non plus.
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
      expect(_champ('internet'), findsNothing);
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

      // Une classe sans siege n'a pas de taux : l'apercu le dit.
      await tester.enterText(_champ('capaciteEnfant'), '0');
      await tester.pumpAndSettle();
      expect(
        _dans(enseignant, find.text(pol.apercuCapaciteAttente)),
        findsOneWidget,
      );
      expect(find.byKey(taux), findsNothing);
      expect(_ligneDit(total, formaterMontant(_usd(160))), isTrue);
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
          matching: find.text(pol.dateEffet(date: '1 janvier 2027')),
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
          matching: find.text(pol.dateEffet(date: '1 octobre 2026')),
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
  });
}
