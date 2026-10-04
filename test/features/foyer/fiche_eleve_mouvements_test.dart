// FI-6b (guide Finance V4 §4, §5.2, §5.4 ; maquettes 05 et 06) : les
// mouvements d'un profil et le recu. Atteints depuis le Foyer, la fiche puis
// Finances, sur le vrai routeur ; montants toujours signes (formaterMontant) ;
// filtre par personne ; recu (date, reference, moyen, montant, repartition) ;
// historique en ajout seul (aucune suppression ni edition) ; donnees de
// demonstration coherentes avec les soldes et les mensualites ; etats
// chargement, contenu, vide, erreur, hors ligne et production ; liste a 390,
// tableau a 1440 ; 320 px texte x2, clair et sombre, LTR et RTL.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/port_paiements_foyer.dart';
import 'package:rewayah_academy/core/capacites/port_politiques_commerciales.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/finance/finances_profil.dart';
import 'package:rewayah_academy/core/finance/format_montant.dart';
import 'package:rewayah_academy/core/finance/montant.dart';
import 'package:rewayah_academy/core/finance/mouvements_profil.dart';
import 'package:rewayah_academy/core/finance/suivi_paiement.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/ligne_allocation.dart';
import 'package:rewayah_academy/core/widgets/ligne_transaction.dart';
import 'package:rewayah_academy/core/widgets/menu_actions.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/demo/finance_demo.dart';
import 'package:rewayah_academy/features/foyer/fiche/finances_page.dart';
import 'package:rewayah_academy/features/foyer/fiche/mouvements_page.dart';
import 'package:rewayah_academy/features/foyer/foyer_page.dart';
import 'package:rewayah_academy/features/foyer/ligne_membre.dart';

import '../../router/support_routeur.dart';
import '../../support/garde_interface.dart';
import '../../support/harnais.dart';

/// Le 4 octobre 2026 a midi, dans le mois de reference de la demonstration.
final DateTime _maintenant = DateTime(2026, 10, 4, 12);

const String _mariam = DonneesFinanceDemo.mariamId;
const String _ibrahim = DonneesFinanceDemo.ibrahimId;

/// Un foyer dont les eleves ont les identifiants des finances [profils].
FauxServiceAppairage _foyer(List<FinancesProfil> profils) =>
    FauxServiceAppairage()
      ..elevesRendus = <EleveDuFoyer>[
        for (final FinancesProfil p in profils)
          EleveDuFoyer(
            id: p.profilId,
            prenom: p.prenom,
            identifiantImmuable: 'STUD-FI-${p.profilId}',
            mode: InterfaceMode.standard,
            camera: CameraPolicy.allowed,
          ),
      ];

/// Un port dont les mouvements sont [lecture] : des donnees injectees, un
/// echec ou une attente sans fin. Les finances restent celles du jeu.
class _PortMouvements implements PortPaiementsFoyer {
  _PortMouvements(this.lecture);

  final Future<List<MouvementProfil>> Function(String profilId) lecture;

  @override
  Future<List<MouvementProfil>> mouvements(String profilId) =>
      lecture(profilId);

  @override
  Future<FinancesFoyer> finances() async =>
      DonneesFinanceDemo.finances(JeuFoyerFinance.unARegulariser);

  @override
  Future<List<PaiementFoyer>> historique() async => <PaiementFoyer>[];

  @override
  Future<PaiementFoyer?> detail(String id) async => null;

  @override
  Future<SoldesFoyer> soldes() async =>
      const SoldesFoyer(beneficiaires: <SoldeBeneficiaire>[]);
}

Future<GoRouter> _monter(
  WidgetTester tester, {
  JeuFoyerFinance jeu = JeuFoyerFinance.unARegulariser,
  PortPaiementsFoyer? port,
  bool avecFinances = true,
  bool horsLigne = false,
  String? depart,
  Size taille = const Size(390, 2400),
  double echelle = 1,
  Brightness luminosite = Brightness.light,
  TextDirection sens = TextDirection.ltr,
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
          appairage: _foyer(DonneesFinanceDemo.profils(jeu)),
        ),
        horlogeFoyerProvider.overrideWithValue(() => _maintenant),
        if (horsLigne)
          horsLigneProvider.overrideWith((Ref ref) => Stream<bool>.value(true)),
        if (avecFinances) ...<Override>[
          portPaiementsFoyerProvider.overrideWithValue(
            port ?? PaiementsFoyerFinanceDemo(jeu),
          ),
          portPolitiquesCommercialesProvider.overrideWithValue(
            const PolitiquesCommercialesDemo(),
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
                    Directionality(textDirection: sens, child: enfant!),
              ),
            );
          },
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(depart ?? Routes.tuteurFoyer);
  await stabiliser(tester);
  return routeur;
}

String _chemin(String id) => Routes.ficheEleveSousPage(id, 'mouvements');

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await stabiliser(tester);
  await tester.tap(cible);
  await stabiliser(tester);
}

Finder _etat(NatureEtat nature) => find.byWidgetPredicate(
  (Widget w) => w is EtatSysteme && w.nature == nature,
);

/// Les montants affiches par les lignes de mouvement, dans l'ordre.
List<String> _montantsAffiches(WidgetTester tester) => <String>[
  for (final LigneTransaction l in tester.widgetList<LigneTransaction>(
    find.byType(LigneTransaction),
  ))
    formaterMontant(l.montant, signe: true),
];

/// Aucune action qui efface ou modifie l'historique (guide §5.7).
void _verifierAjoutSeul(WidgetTester tester) {
  expect(find.byType(ActionPrincipale), findsNothing);
  expect(find.byType(MenuActions), findsNothing);
  for (final String mot in <String>[
    'Supprimer',
    'supprimer',
    'Modifier',
    'modifier',
    'Effacer',
    'Annuler le mouvement',
  ]) {
    expect(find.textContaining(mot), findsNothing, reason: mot);
  }
}

void main() {
  group('Donnees de demonstration (FI-BR-05)', () {
    test('pour chaque jeu et chaque profil, la somme des mouvements est le '
        'solde ; le recu repartit exactement son total', () {
      for (final JeuFoyerFinance jeu in JeuFoyerFinance.values) {
        final RecuPaiement? recu = DonneesFinanceDemo.recu(jeu);
        if (recu != null) {
          expect(
            recu.allocations.fold<int>(
              0,
              (int s, AllocationProfil a) => s + a.montant.mineur,
            ),
            recu.total.mineur,
            reason: '$jeu',
          );
        }
        for (final FinancesProfil p in DonneesFinanceDemo.profils(jeu)) {
          final List<MouvementProfil> m = DonneesFinanceDemo.mouvements(
            jeu,
            p.profilId,
          );
          expect(
            m.fold<int>(0, (int s, MouvementProfil x) => s + x.montant.mineur),
            p.solde.mineur,
            reason: '$jeu ${p.prenom}',
          );
          // Le debit de la periode est la mensualite rendue, signe inverse.
          final int periode = m
              .where(
                (MouvementProfil x) => x.nature != NatureMouvement.recharge,
              )
              .fold<int>(0, (int s, MouvementProfil x) => s + x.montant.mineur);
          expect(
            periode,
            p.periode == null ? 0 : -p.mensualite.mineur,
            reason: '$jeu ${p.prenom}',
          );
          for (final MouvementProfil r in m.where(
            (MouvementProfil x) => x.nature == NatureMouvement.recharge,
          )) {
            expect(
              recu!.allocations
                  .singleWhere((AllocationProfil a) => a.profilId == p.profilId)
                  .montant,
              r.montant,
            );
          }
        }
      }
      // Un essai et un foyer sans paiement n'ont aucun mouvement.
      expect(
        DonneesFinanceDemo.mouvements(
          JeuFoyerFinance.unEnEssai,
          DonneesFinanceDemo.aichaId,
        ),
        isEmpty,
      );
      expect(DonneesFinanceDemo.recu(JeuFoyerFinance.aucunPaiement), isNull);
    });

    test('production : CapaciteIndisponible FI-BR-05', () async {
      await expectLater(
        const PaiementsFoyerIndisponible().mouvements(_mariam),
        throwsA(
          isA<CapaciteIndisponible>().having(
            (CapaciteIndisponible e) => e.dependance,
            'dependance',
            'FI-BR-05',
          ),
        ),
      );
    });
  });

  group('Atteinte, liste, filtre et recu', () {
    testWidgets('Foyer -> fiche -> Finances -> Mouvements, onglet Foyer '
        'actif, retour a Finances', (WidgetTester tester) async {
      final GoRouter routeur = await _monter(tester);
      await _toucher(tester, find.text('Mariam').first);
      expect(lieu(routeur), Routes.ficheElevePour(_mariam));
      await _toucher(tester, find.text(t.ficheEleve.lignes.finances));
      expect(lieu(routeur), Routes.ficheEleveSousPage(_mariam, 'finances'));
      await _toucher(tester, find.byKey(FinancesElevePage.mouvementsKey));
      expect(lieu(routeur), _chemin(_mariam));
      expect(find.byType(MouvementsElevePage), findsOneWidget);
      expect(tester.widget<NavShell>(find.byType(NavShell)).indexActif, 1);
      verifierUnSeulBoutonPlein(tester);

      await _toucher(tester, find.byType(DisqueRetour));
      expect(lieu(routeur), Routes.ficheEleveSousPage(_mariam, 'finances'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('390 : une liste, montants signes de la source, ajout seul', (
      WidgetTester tester,
    ) async {
      await _monter(tester, depart: _chemin(_mariam));
      expect(find.byKey(MouvementsElevePage.listeKey), findsOneWidget);
      expect(find.byKey(MouvementsElevePage.tableauKey), findsNothing);
      final List<MouvementProfil> attendus = DonneesFinanceDemo.mouvements(
        JeuFoyerFinance.unARegulariser,
        _mariam,
      );
      expect(_montantsAffiches(tester), <String>[
        for (final MouvementProfil m in attendus)
          formaterMontant(m.montant, signe: true),
      ]);
      // Chaque montant est ecrit signe a l'ecran : « −50 $ », « +62 $ ».
      for (final MouvementProfil m in attendus) {
        final String texte = formaterMontant(m.montant, signe: true);
        expect(texte, anyOf(startsWith('+'), startsWith(signeMoins)));
        expect(find.text(texte), findsOneWidget);
      }
      expect(
        find.text(
          t.ficheEleve.mouvements.nature.mensualiteDe(
            mois: t.commun.dates.mois[9],
            annee: '2026',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.text(t.ficheEleve.mouvements.nature.recharge),
        findsOneWidget,
      );
      _verifierAjoutSeul(tester);
    });

    testWidgets('3e membre : la remise apparait en credit signe', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        jeu: JeuFoyerFinance.tousFinances,
        depart: _chemin(DonneesFinanceDemo.aichaId),
      );
      expect(find.text(t.ficheEleve.mouvements.nature.remise), findsOneWidget);
      expect(
        find.text(formaterMontant(DonneesFinanceDemo.usd(5), signe: true)),
        findsOneWidget,
      );
    });

    testWidgets('filtre par personne : choisir Ibrahim ouvre ses mouvements', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(tester, depart: _chemin(_mariam));
      await _toucher(tester, find.byKey(MouvementsElevePage.filtreKey));
      await _toucher(tester, find.text('Ibrahim').last);
      expect(lieu(routeur), _chemin(_ibrahim));
      // Ibrahim a regulariser : une recharge partielle, aucun debit.
      expect(_montantsAffiches(tester), <String>[
        for (final MouvementProfil m in DonneesFinanceDemo.mouvements(
          JeuFoyerFinance.unARegulariser,
          _ibrahim,
        ))
          formaterMontant(m.montant, signe: true),
      ]);
      expect(
        find.text(t.ficheEleve.mouvements.nature.mensualite),
        findsNothing,
      );
    });

    testWidgets('un seul profil : aucun filtre par personne', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        jeu: JeuFoyerFinance.unProfil,
        depart: _chemin(_mariam),
      );
      expect(find.byKey(MouvementsElevePage.filtreKey), findsNothing);
      expect(find.byType(LigneTransaction), findsWidgets);
    });

    testWidgets('recu : date, reference, moyen, montant, repartition rendus', (
      WidgetTester tester,
    ) async {
      await _monter(tester, depart: _chemin(_mariam));
      final MouvementProfil recharge =
          DonneesFinanceDemo.mouvements(
            JeuFoyerFinance.unARegulariser,
            _mariam,
          ).singleWhere(
            (MouvementProfil m) => m.nature == NatureMouvement.recharge,
          );
      final RecuPaiement recu = recharge.recu!;
      // Seule la recharge a un recu.
      expect(find.text(t.ficheEleve.mouvements.voirRecu), findsOneWidget);
      await _toucher(
        tester,
        find.byKey(MouvementsElevePage.voirRecuKey(recharge.id)),
      );
      final Finder feuille = find.byKey(MouvementsElevePage.recuKey);
      expect(feuille, findsOneWidget);
      Finder dans(String texte) =>
          find.descendant(of: feuille, matching: find.text(texte));
      expect(dans(dateEcheance(recu.date)), findsOneWidget);
      expect(dans(recu.reference), findsOneWidget);
      expect(dans(t.argent.moyen.webStripe), findsOneWidget);
      expect(dans(formaterMontant(recu.total)), findsOneWidget);
      expect(dans(t.ficheEleve.mouvements.recu.repartition), findsOneWidget);
      final List<LigneAllocation> parts = tester
          .widgetList<LigneAllocation>(
            find.descendant(
              of: feuille,
              matching: find.byType(LigneAllocation),
            ),
          )
          .toList();
      expect(
        <(String, Montant)>[
          for (final LigneAllocation l in parts) (l.prenom, l.montant),
        ],
        <(String, Montant)>[
          for (final AllocationProfil a in recu.allocations)
            (a.prenom, a.montant),
        ],
      );
      _verifierAjoutSeul(tester);
      // Plein ecran sur telephone : le disque retour de la surface de
      // lecture, au-dessus de celui de la page.
      final DisqueRetour fermer = tester.widget<DisqueRetour>(
        find.byType(DisqueRetour).last,
      );
      expect(fermer.libelleSemantique, t.ficheEleve.mouvements.recu.fermer);
      await _toucher(tester, find.byType(DisqueRetour).last);
      expect(find.byKey(MouvementsElevePage.recuKey), findsNothing);
    });

    testWidgets('recu sans repartition rendue : aucune section inventee', (
      WidgetTester tester,
    ) async {
      final MouvementProfil seul = MouvementProfil(
        id: 'm1',
        date: DonneesFinanceDemo.dateRecharge,
        nature: NatureMouvement.recharge,
        montant: DonneesFinanceDemo.usd(20),
        recu: RecuPaiement(
          reference: 'REF-1',
          date: DonneesFinanceDemo.dateRecharge,
          rail: DonneesFinanceDemo.politiqueLancement.railsActifs.single,
          total: DonneesFinanceDemo.usd(20),
        ),
      );
      await _monter(
        tester,
        port: _PortMouvements((_) async => <MouvementProfil>[seul]),
        depart: _chemin(_mariam),
      );
      await _toucher(tester, find.byKey(MouvementsElevePage.voirRecuKey('m1')));
      expect(find.text('REF-1'), findsWidgets);
      expect(find.text(t.ficheEleve.mouvements.recu.repartition), findsNothing);
      expect(find.byType(LigneAllocation), findsNothing);
    });

    testWidgets('en confirmation : la pastille le dit en mots', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        port: _PortMouvements(
          (_) async => <MouvementProfil>[
            MouvementProfil(
              id: 'm2',
              date: DonneesFinanceDemo.aujourdhui,
              nature: NatureMouvement.recharge,
              montant: DonneesFinanceDemo.usd(10),
              statut: StatutMouvement.enConfirmation,
            ),
          ],
        ),
        depart: _chemin(_mariam),
      );
      expect(
        find.text(t.ficheEleve.mouvements.statut.enConfirmation),
        findsOneWidget,
      );
      expect(find.text(t.ficheEleve.mouvements.voirRecu), findsNothing);
    });
  });

  group('Etats', () {
    testWidgets('vide : « Aucun mouvement » (essai)', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        jeu: JeuFoyerFinance.unEnEssai,
        depart: _chemin(DonneesFinanceDemo.aichaId),
      );
      expect(_etat(NatureEtat.aucunResultat), findsOneWidget);
      expect(find.text(t.ficheEleve.mouvements.videTitre), findsOneWidget);
      expect(find.byType(LigneTransaction), findsNothing);
    });

    testWidgets('chargement : squelette, puis contenu', (
      WidgetTester tester,
    ) async {
      final Completer<List<MouvementProfil>> attente =
          Completer<List<MouvementProfil>>();
      await _monter(
        tester,
        port: _PortMouvements((_) => attente.future),
        depart: _chemin(_mariam),
      );
      expect(find.byKey(MouvementsElevePage.listeKey), findsNothing);
      attente.complete(
        DonneesFinanceDemo.mouvements(JeuFoyerFinance.unARegulariser, _mariam),
      );
      await stabiliser(tester);
      expect(find.byKey(MouvementsElevePage.listeKey), findsOneWidget);
    });

    testWidgets('erreur : titre, « Reessayer » relit la source', (
      WidgetTester tester,
    ) async {
      bool echoue = true;
      await _monter(
        tester,
        port: _PortMouvements((String id) async {
          if (echoue) throw Exception('lecture refusee');
          return DonneesFinanceDemo.mouvements(
            JeuFoyerFinance.unARegulariser,
            id,
          );
        }),
        depart: _chemin(_mariam),
      );
      expect(_etat(NatureEtat.echecServeur), findsOneWidget);
      expect(
        find.text(t.ficheEleve.mouvements.erreurTitre(prenom: 'Mariam')),
        findsOneWidget,
      );
      await tester.tap(find.text(t.commun.etats.actions.reessayer));
      echoue = false;
      await stabiliser(tester);
      expect(find.byKey(MouvementsElevePage.listeKey), findsOneWidget);
    });

    testWidgets('hors ligne : dit hors ligne, pas echec du serveur', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        port: _PortMouvements((_) async => throw Exception('reseau')),
        horsLigne: true,
        depart: _chemin(_mariam),
      );
      expect(_etat(NatureEtat.horsLigne), findsOneWidget);
      expect(_etat(NatureEtat.echecServeur), findsNothing);
    });

    testWidgets('production : « pas encore disponible », aucun montant', (
      WidgetTester tester,
    ) async {
      await _monter(tester, avecFinances: false, depart: _chemin(_mariam));
      expect(_etat(NatureEtat.indisponible), findsOneWidget);
      expect(
        find.text(t.ficheEleve.mouvements.indisponibleTitre),
        findsOneWidget,
      );
      expect(find.byType(LigneTransaction), findsNothing);
    });
  });

  group('Gabarits', () {
    testWidgets('1440 : un tableau date / libelle / montant / statut, '
        'montants signes', (WidgetTester tester) async {
      await _monter(
        tester,
        depart: _chemin(_mariam),
        taille: const Size(1440, 1200),
      );
      final Finder tableau = find.byKey(MouvementsElevePage.tableauKey);
      expect(tableau, findsOneWidget);
      expect(find.byKey(MouvementsElevePage.listeKey), findsNothing);
      for (final String colonne in <String>[
        t.ficheEleve.mouvements.colonne.date,
        t.ficheEleve.mouvements.colonne.libelle,
        t.ficheEleve.mouvements.colonne.montant,
        t.ficheEleve.mouvements.colonne.statut,
      ]) {
        expect(
          find.descendant(of: tableau, matching: find.text(colonne)),
          findsOneWidget,
          reason: colonne,
        );
      }
      for (final MouvementProfil m in DonneesFinanceDemo.mouvements(
        JeuFoyerFinance.unARegulariser,
        _mariam,
      )) {
        expect(
          find.descendant(
            of: tableau,
            matching: find.text(formaterMontant(m.montant, signe: true)),
          ),
          findsOneWidget,
        );
      }
      _verifierAjoutSeul(tester);
    });

    for (final (double, double) cas in const <(double, double)>[
      (320, 2),
      (1440, 1),
    ]) {
      for (final Brightness luminosite in Brightness.values) {
        for (final TextDirection sens in TextDirection.values) {
          testWidgets('${cas.$1.toInt()} px, texte x${cas.$2.toInt()}, '
              '${luminosite.name}, ${sens.name} : aucun debordement, recu '
              'compris', (WidgetTester tester) async {
            await _monter(
              tester,
              depart: _chemin(_mariam),
              taille: Size(cas.$1, 3000),
              echelle: cas.$2,
              luminosite: luminosite,
              sens: sens,
            );
            expect(tester.takeException(), isNull);
            expect(
              find.byKey(
                cas.$1 >= 1440
                    ? MouvementsElevePage.tableauKey
                    : MouvementsElevePage.listeKey,
              ),
              findsOneWidget,
            );
            verifierUnSeulBoutonPlein(tester);
            await _toucher(
              tester,
              find.byKey(
                MouvementsElevePage.voirRecuKey(
                  'demo-fi-mvt-$_mariam-recharge',
                ),
              ),
            );
            expect(find.byKey(MouvementsElevePage.recuKey), findsOneWidget);
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  });
}
