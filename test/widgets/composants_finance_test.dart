// Composants partages des ecrans finance (LT-3) : resume de solde, ligne de
// beneficiaire, selection de profils, resultat par profil.
//
// Pour chacun : semantique, cible de 48, texte a 200 % sans debordement a
// 390, theme clair et sombre. Un solde inconnu ne s'affiche jamais « 0 ».

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_finance_foyer.dart';
import 'package:rewayah_academy/core/finance/format_montant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/widgets/ligne_beneficiaire.dart';
import 'package:rewayah_academy/core/widgets/resultat_par_profil.dart';
import 'package:rewayah_academy/core/widgets/resume_solde.dart';
import 'package:rewayah_academy/core/widgets/selecteur_profils.dart';
import 'package:rewayah_academy/core/widgets/selection_profils.dart';

import '../support/hote_theme.dart';

Future<void> verifierCibles(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
}

const SoldeProfil _connu = SoldeProfil(
  profilId: 'e1',
  montantMineur: 2400,
  devise: 'XTS',
);

const SoldeProfil _inconnu = SoldeProfil(
  profilId: 'e2',
  montantMineur: null,
  devise: null,
);

const List<ProfilSelectionnable> _profils = <ProfilSelectionnable>[
  ProfilSelectionnable(id: 'e1', prenom: 'Mariam', etat: 'Solde : 24'),
  ProfilSelectionnable(id: 'e2', prenom: 'Salam', etat: 'Solde : 12'),
  ProfilSelectionnable(id: 'e3', prenom: 'Fatimah', etat: 'Solde : 6'),
];

/// Aucun texte visible ne contient un chiffre seul qui dirait « zero ».
void _jamaisZero() {
  expect(find.textContaining(RegExp(r'(^|\D)0([^0-9,]|$)')), findsNothing);
}

/// Tous les composants, pour les axes communs.
final List<(String, Widget)> _tous = <(String, Widget)>[
  (
    'ResumeSolde foyer',
    const ResumeSolde.foyer(
      totaux: <TotalSoldes>[
        TotalSoldes(montantMineur: 123456789, devise: 'XTS'),
        TotalSoldes(montantMineur: 4200, devise: 'EUR'),
      ],
      complet: false,
      legende: 'Réparties entre trois profils',
    ),
  ),
  (
    'ResumeSolde profil inconnu',
    const ResumeSolde.profil(prenom: 'Mariam', solde: _inconnu),
  ),
  (
    'LigneBeneficiaire',
    LigneBeneficiaire(
      prenom: 'Mariam',
      solde: _connu,
      acces: 'Accès actif',
      onPress: () {},
    ),
  ),
  (
    'SelectionProfils',
    SelectionProfils(
      profils: _profils,
      selection: const <String>{'e1'},
      onChange: (Set<String> _) {},
      titre: 'Profils concernés',
    ),
  ),
  (
    'ResultatParProfil',
    const ResultatParProfil(
      issues: <IssueProfil>[
        IssueProfil(profilId: 'e1', issue: IssueServeur.confirmee),
        IssueProfil(profilId: 'e2', issue: IssueServeur.enAttente),
        IssueProfil(profilId: 'x', issue: IssueServeur.echouee),
      ],
      prenoms: <String, String>{'e1': 'Mariam', 'e2': 'Salam'},
    ),
  ),
];

void main() {
  group('formaterMontant : mise en forme seule', () {
    test('virgule, milliers, exposant, signe', () {
      expect(formaterMontant(2400, 'XTS'), '24,00 XTS');
      expect(formaterMontant(5, 'EUR'), '0,05 EUR');
      expect(formaterMontant(123456789, 'EUR'), '1 234 567,89 EUR');
      expect(formaterMontant(1500, 'XOF'), '1 500 XOF');
      expect(formaterMontant(-1250, 'TND'), '−1,250 TND');
    });
  });

  group('ResumeSolde', () {
    testWidgets('montant inconnu : une phrase, jamais « 0 »', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantique = tester.ensureSemantics();
      fixerVue(tester, vueMobile);
      await tester.pumpWidget(
        hoteTheme(const ResumeSolde.profil(prenom: 'Mariam', solde: _inconnu)),
      );
      await tester.pumpAndSettle();
      expect(find.text(t.finance.soldeInconnu), findsOneWidget);
      expect(find.text(t.finance.soldeDe(prenom: 'Mariam')), findsOneWidget);
      _jamaisZero();
      expect(
        find.bySemanticsLabel(RegExp(t.finance.soldeInconnu)),
        findsOneWidget,
      );

      // Un foyer sans total rendu ne dit pas « 0 » non plus.
      await tester.pumpWidget(
        hoteTheme(
          const ResumeSolde.foyer(totaux: <TotalSoldes>[], complet: false),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(t.finance.aucunTotal), findsOneWidget);
      expect(find.text(t.finance.totalIncomplet), findsOneWidget);
      _jamaisZero();
      semantique.dispose();
    });

    testWidgets('un sous-total par devise, lu avec le titre', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantique = tester.ensureSemantics();
      fixerVue(tester, vueMobile);
      await tester.pumpWidget(hoteTheme(_tous.first.$2));
      await tester.pumpAndSettle();
      expect(find.text('1 234 567,89 XTS'), findsOneWidget);
      expect(find.text('42,00 EUR'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          RegExp('${t.finance.totalFoyer}.*42,00', dotAll: true),
        ),
        findsOneWidget,
      );
      semantique.dispose();
    });
  });

  group('LigneBeneficiaire', () {
    testWidgets('prenom, solde, acces lus ; solde inconnu en mots', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantique = tester.ensureSemantics();
      fixerVue(tester, vueMobile);
      int ouvertures = 0;
      await tester.pumpWidget(
        hoteTheme(
          LigneBeneficiaire(
            prenom: 'Mariam',
            solde: _connu,
            acces: 'Accès actif',
            onPress: () => ouvertures++,
          ),
        ),
      );
      final Finder ligne = find.bySemanticsLabel(
        RegExp('Mariam.*24,00 XTS.*Accès actif', dotAll: true),
      );
      expect(ligne, findsOneWidget);
      expect(
        tester.getSemantics(ligne),
        isSemantics(isButton: true, hasTapAction: true),
      );
      await tester.tap(find.text('Mariam'));
      expect(ouvertures, 1);
      await verifierCibles(tester);

      await tester.pumpWidget(
        hoteTheme(const LigneBeneficiaire(prenom: 'Salam', solde: _inconnu)),
      );
      expect(find.textContaining(t.finance.soldeInconnu), findsOneWidget);
      _jamaisZero();
      semantique.dispose();
    });
  });

  group('SelectionProfils', () {
    testWidgets('taper un profil puis « tous » change la selection', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantique = tester.ensureSemantics();
      fixerVue(tester, vueMobile);
      Set<String> selection = <String>{};
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (BuildContext _, StateSetter majEtat) => hoteTheme(
            SelectionProfils(
              profils: _profils,
              selection: selection,
              onChange: (Set<String> s) => majEtat(() => selection = s),
            ),
          ),
        ),
      );
      Finder caseDe(String libelle) => find.descendant(
        of: find.ancestor(
          of: find.text(libelle),
          matching: find.byType(MergeSemantics),
        ),
        matching: find.byType(Checkbox),
      );

      expect(
        tester.getSemantics(
          find.bySemanticsLabel(RegExp('Mariam.*Solde : 24', dotAll: true)),
        ),
        isSemantics(hasCheckedState: true, isChecked: false),
      );
      expect(
        find.text(t.finance.profilsSelectionnes(nombre: 0)),
        findsOneWidget,
      );

      await tester.tap(caseDe('Salam'));
      await tester.pump();
      expect(selection, <String>{'e2'});
      expect(
        find.text(t.finance.profilsSelectionnes(nombre: 1)),
        findsOneWidget,
      );
      expect(
        tester.getSemantics(
          find.bySemanticsLabel(RegExp('Salam.*Solde : 12', dotAll: true)),
        ),
        isSemantics(hasCheckedState: true, isChecked: true),
      );
      // Partiel : « Tout selectionner » est mixte.
      expect(
        tester.widget<Checkbox>(caseDe(t.finance.toutSelectionner)).value,
        isNull,
      );

      await tester.tap(caseDe(t.finance.toutSelectionner));
      await tester.pump();
      expect(selection, <String>{'e1', 'e2', 'e3'});

      await tester.tap(caseDe(t.finance.toutSelectionner));
      await tester.pump();
      expect(selection, isEmpty);

      await verifierCibles(tester);
      semantique.dispose();
    });
  });

  group('ResultatParProfil', () {
    testWidgets('une issue par profil, en mots, motif jamais brut', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantique = tester.ensureSemantics();
      fixerVue(tester, vueMobile);
      await tester.pumpWidget(
        hoteTheme(
          const ResultatParProfil(
            issues: <IssueProfil>[
              IssueProfil(profilId: 'e1', issue: IssueServeur.confirmee),
              IssueProfil(profilId: 'e2', issue: IssueServeur.enAttente),
              IssueProfil(
                profilId: 'x',
                issue: IssueServeur.echouee,
                motifServeur: 'wallet_insufficient',
              ),
            ],
            prenoms: <String, String>{'e1': 'Mariam', 'e2': 'Salam'},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel(
          RegExp('Mariam.*${t.finance.issues.confirmee}', dotAll: true),
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          RegExp('Salam.*${t.finance.issues.enAttente}', dotAll: true),
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          RegExp(
            '${t.finance.profilSansPrenom}.*${t.finance.issues.echouee}',
            dotAll: true,
          ),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('wallet'), findsNothing);
      semantique.dispose();
    });
  });

  for (final Brightness luminosite in Brightness.values) {
    for (final (String nom, Widget composant) in _tous) {
      testWidgets('$nom : texte a 200 % sur 390, $luminosite', (
        WidgetTester tester,
      ) async {
        fixerVue(tester, vueMobile);
        await tester.pumpWidget(
          hoteTheme(composant, luminosite: luminosite, echelleTexte: 2),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          AppPalette.of(tester.element(find.byWidget(composant))),
          luminosite == Brightness.dark
              ? AppPalette.sombre()
              : AppPalette.claire(),
        );
      });
    }
  }
}
