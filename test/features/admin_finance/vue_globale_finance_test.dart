// FI-11a : la Vue globale de la Finance (direction), guide Finance V4 §1.5,
// §5.6, §8 LOT F7.
//
// - les chiffres exacts de la demonstration, lus via `formaterMontant` ;
// - les cinq etats et l'etat « Pas encore disponible » de la production ;
// - les jeux F7 que le port permet (chiffres vides, mois sans activite,
//   impayes, soldes crediteurs, longue liste d'alertes) ;
// - aucune phrase de sanction, la marge jamais rapprochee des 30 % nets ;
// - 320 px texte x2, 1440 px, clair et sombre, LTR et RTL.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/port_finance_direction.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/finance/format_montant.dart';
import 'package:rewayah_academy/core/finance/montant.dart';
import 'package:rewayah_academy/core/finance/mouvements_profil.dart';
import 'package:rewayah_academy/core/i18n/elision.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/bandeau_attention.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/lien_fleche.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';
import 'package:rewayah_academy/features/admin_finance/vue_globale_finance.dart';
import 'package:rewayah_academy/features/demo/finance_demo.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/garde_interface.dart';
import '../../support/harnais.dart';

/// Un port de test qui rend [vue], ou echoue avec [erreur].
class _Port implements PortFinanceDirection {
  const _Port({this.vue, this.erreur, this.mois, this.parMois});
  final VueGlobaleFinance? vue;
  final Object? erreur;

  /// Les mois rendus ; nul : aucun choix (capacite absente).
  final List<DateTime>? mois;

  /// La vue d'un mois choisi (cle : son mois).
  final Map<int, VueGlobaleFinance>? parMois;

  @override
  Future<VueGlobaleFinance> vueGlobale({DateTime? mois}) {
    if (erreur != null) return Future<VueGlobaleFinance>.error(erreur!);
    final VueGlobaleFinance? choisie = mois == null
        ? null
        : parMois?[mois.month];
    return Future<VueGlobaleFinance>.value(choisie ?? vue);
  }

  @override
  Future<List<DateTime>> moisDisponibles() => mois == null
      ? Future<List<DateTime>>.error(const CapaciteIndisponible('FI-BR-12'))
      : Future<List<DateTime>>.value(mois);
}

Montant _usd(int unites) => Montant(unites * 100, 'USD');

/// Mois sans activite : tout a zero, marge nulle, aucune alerte.
final VueGlobaleFinance _sansActivite = VueGlobaleFinance(
  mois: DateTime(2026, 7),
  encaisse: _usd(0),
  revenuAcademique: _usd(0),
  paieEnseignants: _usd(0),
  margeProjeteePourMille: null,
  impayes: _usd(0),
  essaisEnCours: 0,
  soldesCrediteurs: _usd(0),
);

/// Revenu reconnu nul, mais des soldes, des impayes et des essais : la marge
/// manque, le mois n'est pas vide (revue FI-11a).
final VueGlobaleFinance _sansRevenu = VueGlobaleFinance(
  mois: DateTime(2026, 8),
  encaisse: _usd(0),
  revenuAcademique: _usd(0),
  paieEnseignants: _usd(0),
  margeProjeteePourMille: null,
  impayes: const Montant(4500, 'USD'),
  essaisEnCours: 3,
  soldesCrediteurs: const Montant(12000, 'USD'),
);

/// Impayes et soldes crediteurs eleves, longue liste d'alertes de toutes
/// natures, avec et sans donnees facultatives.
final VueGlobaleFinance _chargee = VueGlobaleFinance(
  mois: DateTime(2026, 11),
  encaisse: const Montant(1234567, 'USD'),
  revenuAcademique: const Montant(1100000, 'USD'),
  paieEnseignants: const Montant(330000, 'USD'),
  margeProjeteePourMille: 700,
  impayes: const Montant(45050, 'USD'),
  essaisEnCours: 12,
  soldesCrediteurs: const Montant(248000, 'USD'),
  alertes: <AlerteFinance>[
    for (int i = 0; i < 12; i++)
      AlerteFinance(
        id: 'a$i',
        nature: NatureAlerteFinance.values[i % 3],
        cible: i % 3 == 2
            ? CibleAlerteFinance.classes
            : CibleAlerteFinance.comptes,
        prenom: i.isEven ? 'Abderrahmane-Mohamed $i' : null,
        classe: i % 3 == 0 ? null : 'Al-Ikhlass du soir $i',
        montant: i % 4 == 0 ? null : _usd(10 + i),
      ),
  ],
  encaisseParMois: <MontantMensuel>[
    for (int m = 6; m <= 11; m++)
      MontantMensuel(mois: DateTime(2026, m), montant: _usd(1000 * m + 7)),
  ],
  paieParMois: <MontantMensuel>[
    for (int m = 6; m <= 11; m++)
      MontantMensuel(mois: DateTime(2026, m), montant: _usd(400 * m + 1)),
  ],
  margeParMois: <MargeMensuelle>[
    for (int m = 6; m <= 10; m++)
      MargeMensuelle(mois: DateTime(2026, m), pourMille: 600 + 13 * m),
    MargeMensuelle(mois: DateTime(2026, 11), pourMille: null),
  ],
  revenuParType: <PartRevenu>[
    PartRevenu(type: TypeEleveRevenu.enfant, montant: _usd(8000)),
    PartRevenu(type: TypeEleveRevenu.adulte, montant: _usd(3000)),
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
            child: VueGlobaleFinanceBloc(),
          ),
        ),
      ),
    ),
  ),
);

List<Override> _avec(PortFinanceDirection port) => <Override>[
  portFinanceDirectionProvider.overrideWithValue(port),
];

void _taille(WidgetTester tester, Size taille) {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Tous les textes rendus, ceux des `Text` et des `RichText`.
List<String> _textes(WidgetTester tester) => <String>[
  for (final Element e in find.byType(RichText).evaluate())
    (e.widget as RichText).text.toPlainText(),
];

bool _estEtat(NatureEtat n) =>
    find
        .byWidgetPredicate((Widget w) => w is EtatSysteme && w.nature == n)
        .evaluate()
        .length ==
    1;

void main() {
  group('demonstration : chiffres exacts', () {
    final VueGlobaleFinance demo = DonneesFinanceDemo.vueGlobale();

    testWidgets('les sept indicateurs, separes, avec leur nombre exact', (
      WidgetTester tester,
    ) async {
      _taille(tester, const Size(1440, 1400));
      await tester.pumpWidget(
        _hote(surcharges: _avec(const FinanceDirectionDemo())),
      );
      await tester.pumpAndSettle();

      final vue = t.admin.finance.vue;
      for (final String libelle in <String>[
        vue.encaisse,
        vue.revenu,
        vue.paie,
        vue.marge,
        vue.impayes,
        vue.essais,
        vue.soldes,
      ]) {
        expect(find.text(libelle), findsOneWidget, reason: libelle);
      }
      // Les indicateurs seuls : les graphiques repetent les nombres du mois.
      Finder carte(Finder f) => find.descendant(
        of: find.byKey(VueGlobaleFinanceContenu.indicateursKey),
        matching: f,
      );
      // 690 USD encaisses ET 690 USD de revenu : deux cartes, jamais une.
      expect(formaterMontant(DonneesFinanceDemo.usd(690)), '690\u00a0\$');
      expect(
        carte(find.text(formaterMontant(DonneesFinanceDemo.usd(690)))),
        findsNWidgets(2),
      );
      expect(formaterMontant(demo.paieEnseignants), '143,20\u00a0\$');
      expect(
        carte(find.text(formaterMontant(demo.paieEnseignants))),
        findsOneWidget,
      );
      // La marge du port, 792 pour mille, jamais recalculee.
      expect(demo.margeProjeteePourMille, 792);
      expect(carte(find.text(vue.margeValeur(valeur: '79,2'))), findsOneWidget);
      expect(find.text(vue.margeDetail), findsOneWidget);
      expect(carte(find.text(formaterMontant(demo.impayes))), findsOneWidget);
      expect(formaterMontant(demo.impayes), '8\u00a0\$');
      // L'etat des paiements repete des nombres (« 1 » en essai) : la
      // carte des essais seule.
      expect(carte(find.text('${demo.essaisEnCours}')), findsOneWidget);
      expect(
        carte(find.text(formaterMontant(demo.soldesCrediteurs))),
        findsOneWidget,
      );
      // Les graphiques de la demonstration : le seul mois depuis le
      // lancement (octobre 2026), avec ses nombres exacts.
      Finder graphique(Key cle, Finder f) =>
          find.descendant(of: find.byKey(cle), matching: f);
      expect(
        graphique(
          VueGlobaleFinanceContenu.graphiqueEncaisseKey,
          find.text(formaterMontant(DonneesFinanceDemo.usd(690))),
        ),
        findsOneWidget,
      );
      expect(
        graphique(
          VueGlobaleFinanceContenu.graphiquePaieKey,
          find.text(formaterMontant(demo.paieEnseignants)),
        ),
        findsOneWidget,
      );
      expect(
        graphique(
          VueGlobaleFinanceContenu.graphiqueMargeKey,
          find.text(vue.margeValeur(valeur: '79,2')),
        ),
        findsOneWidget,
      );
      // La repartition : enfants et adultes, dont la somme est le revenu.
      expect(demo.revenuParType, hasLength(2));
      expect(
        demo.revenuParType.fold<int>(
          0,
          (int s, PartRevenu p) => s + p.montant.mineur,
        ),
        demo.revenuAcademique.mineur,
      );
      for (final PartRevenu p in demo.revenuParType) {
        expect(
          graphique(
            VueGlobaleFinanceContenu.graphiqueRepartitionKey,
            find.text(formaterMontant(p.montant)),
          ),
          findsOneWidget,
        );
      }
      // L'alerte de la demonstration : Ibrahim, le meme manque de 8 USD.
      final AlerteFinance alerte = demo.alertes.single;
      expect(find.byType(BandeauAttention), findsOneWidget);
      expect(find.text(vue.alerte.aRegulariser), findsOneWidget);
      expect(
        find.text(
          vue.alerte.aRegulariserMontant(
            qui: vue.alerte.quiPrenomClasse(
              prenom: alerte.prenom!,
              classe: alerte.classe!,
            ),
            montant: formaterMontant(demo.impayes),
          ),
        ),
        findsOneWidget,
      );
      // Le mois : octobre 2026.
      expect(
        find.text(
          vue.contexte(
            deMois: deDevant(vue.moisAnnee(mois: 'octobre', annee: '2026')),
          ),
        ),
        findsOneWidget,
      );
      // Aucun bouton plein : une page de lecture.
      verifierUnSeulBoutonPlein(tester, maximum: 0);
      expect(
        verifierAucuneCarteCollee(
          tester,
          estCarte: (Widget w) => w is AppCard || w is BandeauAttention,
        ),
        // Sept indicateurs, quatre graphiques, une alerte, puis l'etat des
        // paiements, le top classes et les dernieres operations (FI-DIR-1).
        15,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('aucune phrase de sanction, la marge jamais comparee aux '
        'references nettes', (WidgetTester tester) async {
      _taille(tester, const Size(1440, 1400));
      await tester.pumpWidget(
        _hote(surcharges: _avec(const FinanceDirectionDemo())),
      );
      await tester.pumpAndSettle();
      final RegExp sanction = RegExp(
        r'sanction|objectif|cible|insuffisant|p[ée]nalit|bloqu|mauvais|'
        r'faible|en dessous|sous la r[ée]f[ée]rence|30\s?%|35\s?%|40\s?%|net\b',
        caseSensitive: false,
      );
      final List<String> textes = _textes(tester);
      expect(textes, isNotEmpty);
      for (final String texte in textes) {
        expect(sanction.hasMatch(texte), isFalse, reason: texte);
      }
      // Les references de la politique ne sont jamais rendues (l'heure
      // « 10:30 » d'une operation n'en est pas une).
      expect(find.textContaining(RegExp(r'(?<!:)\b30\b')), findsNothing);
    });
  });

  group('etats', () {
    testWidgets('chargement : le squelette, aucun chiffre', (
      WidgetTester tester,
    ) async {
      final Completer<VueGlobaleFinance> jamais =
          Completer<VueGlobaleFinance>();
      await tester.pumpWidget(
        _hote(
          surcharges: <Override>[
            vueGlobaleFinanceProvider.overrideWith((Ref _) => jamais.future),
          ],
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(Skeleton), findsWidgets);
      expect(find.text(t.admin.finance.vue.encaisse), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('production : « Pas encore disponible », sans Reessayer ni '
        'chiffre', (WidgetTester tester) async {
      await tester.pumpWidget(_hote(surcharges: const <Override>[]));
      await tester.pumpAndSettle();
      expect(_estEtat(NatureEtat.indisponible), isTrue);
      expect(
        find.text(EtatSysteme.textesPar(NatureEtat.indisponible).titre),
        findsOneWidget,
      );
      expect(find.text(t.admin.finance.vue.encaisse), findsNothing);
      expect(find.textContaining('\$'), findsNothing);
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
            vueGlobaleFinanceProvider.overrideWith((Ref _) {
              lectures++;
              return Future<VueGlobaleFinance>.error(StateError('panne'));
            }),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(_estEtat(NatureEtat.echecServeur), isTrue);
      expect(find.text(t.admin.finance.vue.encaisse), findsNothing);
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

  group('jeux F7', () {
    testWidgets('chiffres vides et mois sans activite : les zeros restent, '
        'la phrase le dit', (WidgetTester tester) async {
      _taille(tester, const Size(1440, 1400));
      await tester.pumpWidget(
        _hote(surcharges: _avec(_Port(vue: _sansActivite))),
      );
      await tester.pumpAndSettle();
      final vue = t.admin.finance.vue;
      expect(
        find.text(
          vue.sansActivite(
            mois: vue.moisAnnee(mois: 'juillet', annee: '2026'),
          ),
        ),
        findsOneWidget,
      );
      // Encaisse, revenu, paie, impayes, soldes : cinq zeros affiches.
      expect(find.text(formaterMontant(_usd(0))), findsNWidgets(5));
      expect(find.text('0'), findsOneWidget);
      expect(find.text(vue.margeSansActivite), findsOneWidget);
      expect(find.text(vue.margeNonCalculable), findsNothing);
      expect(find.textContaining(vue.sansRevenu(mois: '')), findsNothing);
      expect(find.text(vue.aucuneAlerte), findsOneWidget);
      expect(find.byType(BandeauAttention), findsNothing);
    });

    testWidgets('revenu nul avec soldes et impayes : pas de « a zero », les '
        'montants rendus, la phrase de la marge', (WidgetTester tester) async {
      _taille(tester, const Size(1440, 1400));
      await tester.pumpWidget(
        _hote(surcharges: _avec(_Port(vue: _sansRevenu))),
      );
      await tester.pumpAndSettle();
      final vue = t.admin.finance.vue;
      final String mois = vue.moisAnnee(mois: 'août', annee: '2026');
      expect(find.text(vue.sansActivite(mois: mois)), findsNothing);
      expect(find.text(vue.margeSansActivite), findsNothing);
      expect(find.text(vue.sansRevenu(mois: mois)), findsOneWidget);
      expect(find.text(vue.margeNonCalculable), findsOneWidget);
      expect(find.text(formaterMontant(_sansRevenu.impayes)), findsOneWidget);
      expect(
        find.text(formaterMontant(_sansRevenu.soldesCrediteurs)),
        findsOneWidget,
      );
      expect(find.text('3'), findsOneWidget);
      // Encaisse, revenu, paie : trois zeros, vrais, restent affiches.
      expect(find.text(formaterMontant(_usd(0))), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });

    testWidgets('impayes, soldes crediteurs, longue liste d alertes : tout '
        'est rendu, aucune carte collee', (WidgetTester tester) async {
      _taille(tester, const Size(1440, 900));
      await tester.pumpWidget(_hote(surcharges: _avec(_Port(vue: _chargee))));
      await tester.pumpAndSettle();
      expect(find.text(formaterMontant(_chargee.impayes)), findsOneWidget);
      expect(find.text('450,50\u00a0\$'), findsOneWidget);
      expect(
        find.text(formaterMontant(_chargee.soldesCrediteurs)),
        findsOneWidget,
      );
      expect(find.text(formaterMontant(_chargee.encaisse)), findsOneWidget);
      expect(
        find.text(t.admin.finance.vue.margeValeur(valeur: '70')),
        findsOneWidget,
      );
      // Les douze alertes, chacune une fois, dans l'ordre du port.
      expect(
        find.byType(BandeauAttention, skipOffstage: false),
        findsNWidgets(12),
      );
      for (final AlerteFinance a in _chargee.alertes) {
        expect(
          find.byKey(ValueKey<String>(a.id), skipOffstage: false),
          findsOneWidget,
        );
      }
      final vueA = t.admin.finance.vue.alerte;
      // Sans prenom ni classe, ou sans montant : la phrase reste entiere.
      expect(
        find.text(
          vueA.aRegulariserMontant(
            qui: vueA.quiInconnu,
            montant: formaterMontant(_usd(13)),
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.text(vueA.aRegulariserSansMontant(qui: 'Abderrahmane-Mohamed 0')),
        findsOneWidget,
      );
      expect(
        find.text(
          vueA.confirmationMontant(
            qui: vueA.quiClasse(classe: 'Al-Ikhlass du soir 1'),
            montant: formaterMontant(_usd(11)),
          ),
        ),
        findsOneWidget,
      );
      verifierAucuneCarteCollee(
        tester,
        estCarte: (Widget w) => w is AppCard || w is BandeauAttention,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('contre-revue FI-VAGUE-R', () {
    Finder dans(Key cle, Finder f) =>
        find.descendant(of: find.byKey(cle), matching: f);

    testWidgets('R6-01 : un graphique par notion, chaque barre avec son '
        'nombre exact, aucune notion melee', (WidgetTester tester) async {
      _taille(tester, const Size(1440, 2400));
      await tester.pumpWidget(_hote(surcharges: _avec(_Port(vue: _chargee))));
      await tester.pumpAndSettle();
      final vue = t.admin.finance.vue;
      for (final String titre in <String>[
        vue.graphiqueEncaisse,
        vue.graphiquePaie,
        vue.graphiqueMarge,
        vue.graphiqueRepartition,
      ]) {
        expect(find.text(titre), findsOneWidget, reason: titre);
      }
      for (final MontantMensuel p in _chargee.encaisseParMois) {
        final String n = formaterMontant(p.montant);
        expect(
          dans(VueGlobaleFinanceContenu.graphiqueEncaisseKey, find.text(n)),
          findsOneWidget,
          reason: n,
        );
        // Jamais dans le graphique de la charge.
        expect(
          dans(VueGlobaleFinanceContenu.graphiquePaieKey, find.text(n)),
          findsNothing,
        );
      }
      for (final MontantMensuel p in _chargee.paieParMois) {
        expect(
          dans(
            VueGlobaleFinanceContenu.graphiquePaieKey,
            find.text(formaterMontant(p.montant)),
          ),
          findsOneWidget,
        );
      }
      // Les mois, en mots, dans l'ordre du port.
      expect(
        dans(
          VueGlobaleFinanceContenu.graphiqueEncaisseKey,
          find.text(vue.moisAnnee(mois: 'juin', annee: '2026')),
        ),
        findsOneWidget,
      );
      // La marge : 67,8 % en juin ; novembre sans revenu, non calculable.
      expect(
        dans(
          VueGlobaleFinanceContenu.graphiqueMargeKey,
          find.text(vue.margeValeur(valeur: '67,8')),
        ),
        findsOneWidget,
      );
      expect(
        dans(
          VueGlobaleFinanceContenu.graphiqueMargeKey,
          find.text(vue.margeNonCalculable),
        ),
        findsOneWidget,
      );
      // La repartition par type d'eleve, seules categories du modele.
      expect(
        dans(
          VueGlobaleFinanceContenu.graphiqueRepartitionKey,
          find.text(vue.repartitionEnfants),
        ),
        findsOneWidget,
      );
      expect(
        dans(
          VueGlobaleFinanceContenu.graphiqueRepartitionKey,
          find.text(formaterMontant(_usd(3000))),
        ),
        findsOneWidget,
      );
      expect(find.text(vue.sansHistorique), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('R6-01 : sans serie rendue, chaque graphique le dit', (
      WidgetTester tester,
    ) async {
      _taille(tester, const Size(1440, 2400));
      await tester.pumpWidget(
        _hote(surcharges: _avec(_Port(vue: _sansActivite))),
      );
      await tester.pumpAndSettle();
      expect(find.text(t.admin.finance.vue.sansHistorique), findsNWidgets(4));
      expect(tester.takeException(), isNull);
    });

    test('R6-01 : longueurs de barres, une geometrie bornee a 0..1', () {
      expect(longueursDeBarres(<int>[50, 100, 0]), <double>[0.5, 1, 0]);
      expect(longueursDeBarres(<int>[0, 0]), <double>[0, 0]);
      expect(longueursDeBarres(<int>[-10, 20]), <double>[0, 1]);
      expect(longueursDeBarres(<int>[]), isEmpty);
    });

    for (final (CibleAlerteFinance cible, String route, int index)
        in <(CibleAlerteFinance, String, int)>[
          (CibleAlerteFinance.comptes, Routes.adminPersonnesComptes, 0),
          (CibleAlerteFinance.classes, Routes.adminOperationsGroupes, 2),
        ]) {
      testWidgets('R6-04 : chaque alerte a un seul lien, qui ouvre sa cible '
          '(${cible.name})', (WidgetTester tester) async {
        _taille(tester, const Size(1440, 2400));
        final GoRouter routeur = GoRouter(
          routes: <RouteBase>[
            GoRoute(
              path: '/',
              builder: (BuildContext _, GoRouterState _) => const Scaffold(
                body: SingleChildScrollView(child: VueGlobaleFinanceBloc()),
              ),
            ),
            for (final String r in <String>[
              Routes.adminPersonnesComptes,
              Routes.adminOperationsGroupes,
            ])
              GoRoute(
                path: r,
                builder: (BuildContext _, GoRouterState _) =>
                    Scaffold(body: Text('page $r')),
              ),
          ],
        );
        addTearDown(routeur.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
              horsLigneProvider.overrideWith(
                (Ref _) => Stream<bool>.value(false),
              ),
              sansPersonneConnectee(),
              ..._avec(_Port(vue: _chargee)),
            ],
            child: TranslationProvider(
              child: MaterialApp.router(
                theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
                routerConfig: routeur,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        // Une action secondaire par alerte, jamais deux.
        for (final AlerteFinance a in _chargee.alertes) {
          expect(
            find.descendant(
              of: find.byKey(ValueKey<String>(a.id), skipOffstage: false),
              matching: find.byType(LienFleche, skipOffstage: false),
            ),
            findsOneWidget,
            reason: a.id,
          );
        }
        final AlerteFinance alerte = _chargee.alertes[index];
        expect(alerte.cible, cible);
        final Finder lien = find.byKey(ValueKey<String>('${alerte.id}-cible'));
        await tester.ensureVisible(lien);
        await tester.pumpAndSettle();
        await tester.tap(lien);
        await tester.pumpAndSettle();
        expect(find.text('page $route'), findsOneWidget);
      });
    }
  });

  group('FI-DIR-1 : FI-R6 (a) et FI-Q18 (a)', () {
    Finder dans(Key cle, Finder f) =>
        find.descendant(of: find.byKey(cle), matching: f);

    final VueGlobaleFinance complete = VueGlobaleFinance(
      mois: DateTime(2026, 11),
      encaisse: _usd(690),
      revenuAcademique: _usd(690),
      paieEnseignants: _usd(143),
      margeProjeteePourMille: 792,
      impayes: _usd(8),
      essaisEnCours: 1,
      soldesCrediteurs: _usd(57),
      etatPaiements: const <CompteEtatPaiements>[
        CompteEtatPaiements(
          etat: EtatPaiementsProfils.finances,
          profils: 13,
          partPourMille: 866,
        ),
        CompteEtatPaiements(
          etat: EtatPaiementsProfils.aRegulariser,
          profils: 1,
          partPourMille: 66,
        ),
        CompteEtatPaiements(etat: EtatPaiementsProfils.enEssai, profils: 1),
        CompteEtatPaiements(
          etat: EtatPaiementsProfils.enConfirmation,
          profils: 0,
          partPourMille: 0,
        ),
      ],
      // Un ordre qui n'est PAS celui des montants : l'ecran garde l'ordre
      // rendu, il ne trie rien.
      topClasses: <EncaissementClasse>[
        EncaissementClasse(classe: 'Al-Huda', encaisse: _usd(200)),
        EncaissementClasse(classe: 'An-Nour', encaisse: _usd(250)),
      ],
      dernieresOperations: <MouvementFoyer>[
        MouvementFoyer(
          profilId: 'p1',
          prenom: 'Ibrahim',
          mouvement: MouvementProfil(
            id: 'op1',
            date: DateTime(2026, 11, 3, 14, 32),
            nature: NatureMouvement.recharge,
            montant: _usd(40),
            statut: StatutMouvement.enConfirmation,
          ),
        ),
        MouvementFoyer(
          profilId: 'p2',
          prenom: 'Mariam',
          mouvement: MouvementProfil(
            id: 'op2',
            date: DateTime(2026, 11, 1, 8, 5),
            nature: NatureMouvement.debitPeriode,
            montant: const Montant(-5000, 'USD'),
            periode: DateTime(2026, 11),
          ),
        ),
      ],
    );

    testWidgets('R6-02 : État des paiements, Top classes et Dernières '
        'opérations, chaque nombre tel que rendu', (WidgetTester tester) async {
      _taille(tester, const Size(1440, 3200));
      await tester.pumpWidget(_hote(surcharges: _avec(_Port(vue: complete))));
      await tester.pumpAndSettle();
      final vue = t.admin.finance.vue;
      expect(find.text(vue.etatPaiements), findsOneWidget);
      expect(find.text(vue.topClasses), findsOneWidget);
      expect(find.text(vue.dernieresOperations), findsOneWidget);
      // Les quatre etats nommes, leur nombre et leur part rendue.
      for (final (String libelle, String nombre) in <(String, String)>[
        (vue.etatFinances, '13'),
        (vue.etatARegulariser, '1'),
        (vue.etatEnEssai, '1'),
        (vue.etatEnConfirmation, '0'),
      ]) {
        expect(
          dans(VueGlobaleFinanceContenu.etatPaiementsKey, find.text(libelle)),
          findsOneWidget,
          reason: libelle,
        );
        expect(
          dans(VueGlobaleFinanceContenu.etatPaiementsKey, find.text(nombre)),
          findsWidgets,
          reason: nombre,
        );
      }
      expect(
        dans(
          VueGlobaleFinanceContenu.etatPaiementsKey,
          find.text(vue.etatPart(valeur: '86,6')),
        ),
        findsOneWidget,
      );
      // Sans part rendue, aucune part inventee : trois parts seulement.
      expect(
        dans(
          VueGlobaleFinanceContenu.etatPaiementsKey,
          find.textContaining('% des profils'),
        ),
        findsNWidgets(3),
      );
      // Le classement dans l'ordre rendu : Al-Huda premier.
      final Finder huda = dans(
        VueGlobaleFinanceContenu.topClassesKey,
        find.text(vue.topClasse(rang: '1', classe: nomSansCoupure('Al-Huda'))),
      );
      final Finder nour = dans(
        VueGlobaleFinanceContenu.topClassesKey,
        find.text(vue.topClasse(rang: '2', classe: nomSansCoupure('An-Nour'))),
      );
      expect(huda, findsOneWidget);
      expect(nour, findsOneWidget);
      expect(tester.getTopLeft(huda).dy, lessThan(tester.getTopLeft(nour).dy));
      // « As-Salam » ne se coupe jamais au trait d union (320, texte x2).
      expect(nomSansCoupure('As-Salam'), isNot(contains('-')));
      expect(
        dans(
          VueGlobaleFinanceContenu.topClassesKey,
          find.text(formaterMontant(_usd(250))),
        ),
        findsOneWidget,
      );
      // Les operations : prenom, heure, montant signe, etat en mots.
      expect(
        dans(
          VueGlobaleFinanceContenu.operationsKey,
          find.textContaining('Ibrahim'),
        ),
        findsOneWidget,
      );
      expect(
        dans(
          VueGlobaleFinanceContenu.operationsKey,
          find.textContaining('14:32'),
        ),
        findsOneWidget,
      );
      expect(
        dans(
          VueGlobaleFinanceContenu.operationsKey,
          find.text(formaterMontant(_usd(40), signe: true)),
        ),
        findsOneWidget,
      );
      expect(
        dans(VueGlobaleFinanceContenu.operationsKey, find.byType(StatusPill)),
        findsOneWidget,
      );
      // Sur bureau, etat des paiements et classement cote a cote.
      expect(
        tester
            .getTopLeft(find.byKey(VueGlobaleFinanceContenu.etatPaiementsKey))
            .dy,
        tester
            .getTopLeft(find.byKey(VueGlobaleFinanceContenu.topClassesKey))
            .dy,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('R6-02 : rien de rendu, chaque carte le dit, aucun chiffre '
        'invente', (WidgetTester tester) async {
      _taille(tester, const Size(390, 3200));
      await tester.pumpWidget(
        _hote(surcharges: _avec(_Port(vue: _sansActivite))),
      );
      await tester.pumpAndSettle();
      final vue = t.admin.finance.vue;
      expect(find.text(vue.etatVide), findsOneWidget);
      expect(find.text(vue.topClassesVide), findsOneWidget);
      expect(find.text(vue.dernieresOperationsVide), findsOneWidget);
      expect(find.textContaining('% des profils'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('R6-03 et FI-Q18 : le choix du mois propose les seuls mois '
        'rendus et relit la vue du mois choisi', (WidgetTester tester) async {
      _taille(tester, const Size(1440, 3200));
      await tester.pumpWidget(
        _hote(
          surcharges: _avec(
            _Port(
              vue: complete,
              mois: <DateTime>[DateTime(2026, 11), DateTime(2026, 8)],
              parMois: <int, VueGlobaleFinance>{8: _sansRevenu},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final Finder selecteur = find.byKey(
        VueGlobaleFinanceContenu.selecteurMoisKey,
      );
      expect(selecteur, findsOneWidget);
      expect(
        find.descendant(of: selecteur, matching: find.text('novembre 2026')),
        findsOneWidget,
      );
      await tester.tap(selecteur);
      await tester.pumpAndSettle();
      // Deux mois, ceux du port, et aucun autre.
      expect(find.text('août 2026'), findsOneWidget);
      expect(find.text('octobre 2026'), findsNothing);
      await tester.tap(find.text('août 2026'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: selecteur, matching: find.text('août 2026')),
        findsOneWidget,
      );
      // La vue d'aout : revenu nul, la phrase de la marge absente le dit.
      expect(
        find.text(t.admin.finance.vue.sansRevenu(mois: 'août 2026')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('R6-03 : sans mois rendus (production), aucun choix pose', (
      WidgetTester tester,
    ) async {
      _taille(tester, const Size(1440, 2400));
      await tester.pumpWidget(_hote(surcharges: _avec(_Port(vue: complete))));
      await tester.pumpAndSettle();
      expect(
        find.byKey(VueGlobaleFinanceContenu.selecteurMoisKey),
        findsNothing,
      );
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
                surcharges: _avec(_Port(vue: _chargee)),
                echelle: echelle,
                sens: sens,
                luminosite: luminosite,
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(
              find.text(formaterMontant(_chargee.impayes)),
              findsOneWidget,
            );
            verifierAucuneCarteCollee(
              tester,
              estCarte: (Widget w) => w is AppCard || w is BandeauAttention,
            );
          });
        }
      }
    }

    test('colonnes : par largeur minimale de carte, proportionnelle au '
        'texte, bornee a 4', () {
      const TextScaler x1 = TextScaler.noScaling;
      const TextScaler x2 = TextScaler.linear(2);
      expect(VueGlobaleFinanceContenu.colonnesPour(1100, x1), 4);
      expect(VueGlobaleFinanceContenu.colonnesPour(1100, x2), 2);
      expect(VueGlobaleFinanceContenu.colonnesPour(700, x1), 3);
      expect(VueGlobaleFinanceContenu.colonnesPour(560, x1), 2);
      expect(VueGlobaleFinanceContenu.colonnesPour(840, x1), 4);
      expect(VueGlobaleFinanceContenu.colonnesPour(1408, x1), 4);
      expect(
        VueGlobaleFinanceContenu.colonnesPour(
          860,
          const TextScaler.linear(1.4),
        ),
        2,
      );
      expect(VueGlobaleFinanceContenu.colonnesPour(700, x2), 1);
      expect(VueGlobaleFinanceContenu.colonnesPour(288, x1), 1);
    });

    test('pour mille en texte : une mise en forme, jamais un calcul', () {
      expect(pourMilleEnTexte(792), '79,2');
      expect(pourMilleEnTexte(300), '30');
      expect(pourMilleEnTexte(0), '0');
      expect(pourMilleEnTexte(-45), '${signeMoins}4,5');
    });
  });

  // Dernier groupe : les vraies polices, une fois chargees, le restent pour
  // tout le fichier. La police de test (carres de 1 em) exagere les largeurs.
  group('polices du depot', () {
    setUpAll(chargerPolicesDuDepot);

    testWidgets('860 px de contenu, texte 1,4, montant a 7 chiffres : le '
        'montant reste dans sa carte, sur une ligne', (
      WidgetTester tester,
    ) async {
      // 860 de contenu : la page de 892 moins 2 x 16 de marge.
      _taille(tester, const Size(892, 1600));
      final VueGlobaleFinance large = VueGlobaleFinance(
        mois: DateTime(2026, 11),
        encaisse: const Montant(123456789, 'USD'),
        revenuAcademique: const Montant(123456789, 'USD'),
        paieEnseignants: const Montant(123456789, 'USD'),
        margeProjeteePourMille: 700,
        impayes: const Montant(123456789, 'USD'),
        essaisEnCours: 12,
        soldesCrediteurs: const Montant(123456789, 'USD'),
      );
      await tester.pumpWidget(
        _hote(surcharges: _avec(_Port(vue: large)), echelle: 1.4),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final String texte = formaterMontant(large.encaisse);
      final Finder montants = find.text(texte);
      expect(montants, findsNWidgets(5));
      for (final Element e in montants.evaluate()) {
        final Finder carte = find.ancestor(
          of: find.byWidget(e.widget),
          matching: find.byType(AppCard),
        );
        final Rect zoneCarte = tester.getRect(carte.first);
        final Rect zone = tester.getRect(find.byWidget(e.widget).first);
        expect(zoneCarte.contains(zone.topLeft), isTrue);
        expect(
          zoneCarte.contains(zone.bottomRight - const Offset(1, 1)),
          isTrue,
        );
        // Une seule ligne : la hauteur rendue est celle du texte non borne.
        final Text t0 = e.widget as Text;
        final TextPainter seul = TextPainter(
          text: TextSpan(
            text: texte,
            style: DefaultTextStyle.of(e).style.merge(t0.style),
          ),
          textDirection: TextDirection.ltr,
          textScaler: const TextScaler.linear(1.4),
        )..layout();
        expect(zone.height, closeTo(seul.height, 0.5), reason: texte);
        seul.dispose();
      }
    });
  });
}
