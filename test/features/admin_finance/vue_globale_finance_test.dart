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
import 'package:rewayah_academy/core/capacites/port_finance_direction.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/finance/format_montant.dart';
import 'package:rewayah_academy/core/finance/montant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/bandeau_attention.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/admin_finance/vue_globale_finance.dart';
import 'package:rewayah_academy/features/demo/finance_demo.dart';

import '../../support/garde_interface.dart';
import '../../support/harnais.dart';

/// Un port de test qui rend [vue], ou echoue avec [erreur].
class _Port implements PortFinanceDirection {
  const _Port({this.vue, this.erreur});
  final VueGlobaleFinance? vue;
  final Object? erreur;

  @override
  Future<VueGlobaleFinance> vueGlobale() => erreur == null
      ? Future<VueGlobaleFinance>.value(vue)
      : Future<VueGlobaleFinance>.error(erreur!);
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
        prenom: i.isEven ? 'Abderrahmane-Mohamed $i' : null,
        classe: i % 3 == 0 ? null : 'Al-Ikhlass du soir $i',
        montant: i % 4 == 0 ? null : _usd(10 + i),
      ),
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
      // 690 USD encaisses ET 690 USD de revenu : deux cartes, jamais une.
      expect(formaterMontant(DonneesFinanceDemo.usd(690)), '690\u00a0\$');
      expect(
        find.text(formaterMontant(DonneesFinanceDemo.usd(690))),
        findsNWidgets(2),
      );
      expect(formaterMontant(demo.paieEnseignants), '143,20\u00a0\$');
      expect(find.text(formaterMontant(demo.paieEnseignants)), findsOneWidget);
      // La marge du port, 792 pour mille, jamais recalculee.
      expect(demo.margeProjeteePourMille, 792);
      expect(find.text(vue.margeValeur(valeur: '79,2')), findsOneWidget);
      expect(find.text(vue.margeDetail), findsOneWidget);
      expect(find.text(formaterMontant(demo.impayes)), findsOneWidget);
      expect(formaterMontant(demo.impayes), '8\u00a0\$');
      expect(find.text('${demo.essaisEnCours}'), findsOneWidget);
      expect(find.text(formaterMontant(demo.soldesCrediteurs)), findsOneWidget);
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
            mois: vue.moisAnnee(mois: 'octobre', annee: '2026'),
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
        8,
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
      // Les references de la politique ne sont jamais rendues.
      expect(find.textContaining('30'), findsNothing);
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
      expect(find.text(vue.aucuneAlerte), findsOneWidget);
      expect(find.byType(BandeauAttention), findsNothing);
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

    test('colonnes : 4 au bureau, 2 en tablette, 1 au telephone, moins '
        'quand le texte est agrandi', () {
      const TextScaler x1 = TextScaler.noScaling;
      const TextScaler x2 = TextScaler.linear(2);
      expect(VueGlobaleFinanceContenu.colonnesPour(1100, x1), 4);
      expect(VueGlobaleFinanceContenu.colonnesPour(1100, x2), 2);
      expect(VueGlobaleFinanceContenu.colonnesPour(700, x1), 2);
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
}
