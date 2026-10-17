// CPT-CTR-1 : W06, la liste. Quatre zones, montants masques par defaut,
// « Payer » seulement quand la source le permet et vers W03, « Nouvelle
// obligation » seulement avec la capacite, les cinq etats.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/empty_state.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/filter_pill.dart';
import 'package:rewayah_academy/core/widgets/montant_sensible.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/demo/comptable/contractuels_demo.dart';

import '../../../support/rangee_plus.dart';
import 'support_contractuels.dart';

final String _masque = MontantSensible.masquePour('USD');

Finder _pilule(String parametre) =>
    find.byKey(ValueKey<String>('onglet-$parametre'));

/// Touche l'onglet [parametre] : dans la rangee des zones, ou sous « Plus »
/// quand elle n'en montre que trois (RangeeFiltres, L4-07).
Future<void> _toucherOnglet(WidgetTester tester, String parametre) =>
    toucherFiltre(tester, _pilule(parametre));

int _compteur(WidgetTester tester, String parametre) =>
    tester.widget<FilterPill>(_pilule(parametre)).compteur!;

void main() {
  final c = t.comptable.contractuels;

  group('W06 liste : contenu', () {
    testWidgets('quatre zones avec leur compteur, Obligations ouverte', (
      WidgetTester tester,
    ) async {
      await monterContractuels(tester);
      // Les quatre zones ; « Plus » en porte une (Historique), L4-07.
      expect(
        find.byWidgetPredicate(
          (Widget w) =>
              w is FilterPill &&
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith('onglet-'),
        ),
        findsNWidgets(4),
      );
      // Demo : 5 en cours (025, 026, 027, 028 et 024), 2 a approuver,
      // 2 a payer, 3 dans l'historique.
      expect(_compteur(tester, 'obligations'), 5);
      expect(_compteur(tester, 'a-approuver'), 2);
      expect(_compteur(tester, 'a-payer'), 2);
      expect(_compteur(tester, 'historique'), 3);
      expect(tester.widget<FilterPill>(_pilule('obligations')).retenue, isTrue);
      expect(find.text('Karim Studio'), findsOneWidget);
      expect(find.text('Atelier Noor'), findsOneWidget);
    });

    testWidgets('l adresse ?onglet= ouvre la zone demandee', (
      WidgetTester tester,
    ) async {
      await monterContractuels(
        tester,
        depart: '${Routes.comptableContractuels}?onglet=historique',
      );
      expect(tester.widget<FilterPill>(_pilule('historique')).retenue, isTrue);
      expect(find.text('Imprimerie Al-Qalam'), findsOneWidget);
      expect(find.text('Karim Studio'), findsNothing);
    });

    testWidgets('changer de zone filtre la liste', (WidgetTester tester) async {
      await monterContractuels(tester);
      await _toucherOnglet(tester, 'a-approuver');
      await tester.pumpAndSettle();
      expect(find.text('Atelier Noor'), findsOneWidget);
      expect(find.text('Traduction Hikma'), findsOneWidget);
      expect(find.text('Karim Studio'), findsNothing);
    });

    testWidgets('les montants sont masques par defaut, jamais en texte', (
      WidgetTester tester,
    ) async {
      await monterContractuels(tester);
      expect(find.text(_masque), findsWidgets);
      expect(find.textContaining('350'), findsNothing);
      expect(find.textContaining('USD'), findsNothing);
    });

    testWidgets('revele, le montant est exact', (WidgetTester tester) async {
      await monterContractuels(tester, montantsAffiches: true);
      expect(find.text(_masque), findsNothing);
      expect(find.textContaining('350'), findsOneWidget);
    });
  });

  group('W06 liste : Payer (DR-12)', () {
    testWidgets('seulement quand la source le permet, vers W03', (
      WidgetTester tester,
    ) async {
      await monterContractuels(
        tester,
        depart: '${Routes.comptableContractuels}?onglet=a-payer',
      );
      // 024 : payer permis. 026 : verification requise, aucun bouton.
      final Finder payer024 = find.byKey(
        const ValueKey<String>('payer-obl-ctr-024'),
      );
      expect(payer024, findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('payer-obl-ctr-026')),
        findsNothing,
      );
      expect(_actionsDeZone, findsOneWidget);
      await tester.tap(payer024);
      await tester.pumpAndSettle();
      expect(find.text(texteW03('obl-pay-ctr-024')), findsOneWidget);
    });

    testWidgets('ni Payer ni Approuver sur une obligation a approuver', (
      WidgetTester tester,
    ) async {
      await monterContractuels(
        tester,
        depart: '${Routes.comptableContractuels}?onglet=a-approuver',
      );
      expect(find.text(c.payer), findsNothing);
    });

    testWidgets('toucher une ligne ouvre le detail', (
      WidgetTester tester,
    ) async {
      await monterContractuels(tester);
      await tester.tap(find.text('Karim Studio'));
      await tester.pumpAndSettle();
      expect(find.text(c.detailTitre), findsOneWidget);
      expect(find.text(c.montantFige), findsOneWidget);
    });
  });

  group('W06 liste : Nouvelle obligation (§34)', () {
    testWidgets('presente quand la capacite est rendue, vers le formulaire', (
      WidgetTester tester,
    ) async {
      await monterContractuels(tester);
      final Finder bouton = find.text(c.nouvelle);
      expect(bouton, findsOneWidget);
      await tester.tap(bouton);
      await tester.pumpAndSettle();
      expect(find.text(c.creer), findsOneWidget);
    });

    testWidgets('absente hors delegation, la raison rendue est dite', (
      WidgetTester tester,
    ) async {
      await monterContractuels(
        tester,
        port: ObligationsContractuelsDemo(peutCreer: false),
      );
      expect(find.text(c.nouvelle), findsNothing);
      expect(
        find.text(
          c.creationBloquee(raison: t.comptable.statuts.raison.horsDelegation),
        ),
        findsOneWidget,
      );
    });
  });

  group('W06 liste : les cinq etats', () {
    testWidgets('chargement : un squelette', (WidgetTester tester) async {
      await monterContractuels(tester, port: PortSansFin(), attendre: false);
      expect(find.byType(Skeleton), findsWidgets);
      // Libere les minuteries de l'attente avant la fin du test.
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('vide : une phrase par zone, aucune action', (
      WidgetTester tester,
    ) async {
      await monterContractuels(tester, port: PortVide());
      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text(c.videObligations), findsOneWidget);
      await _toucherOnglet(tester, 'a-payer');
      await tester.pumpAndSettle();
      expect(find.text(c.videAPayer), findsOneWidget);
      await _toucherOnglet(tester, 'historique');
      await tester.pumpAndSettle();
      expect(find.text(c.videHistorique), findsOneWidget);
      expect(_actionsDeZone, findsNothing);
    });

    testWidgets('erreur : Reessayer, puis la liste revient', (
      WidgetTester tester,
    ) async {
      await monterContractuels(tester, port: PortEnEchec(StateError('x')));
      expect(find.byType(EtatSysteme), findsOneWidget);
      expect(find.text(t.commun.etats.actions.reessayer), findsOneWidget);
    });

    testWidgets('capacite absente : indisponible, sans relance', (
      WidgetTester tester,
    ) async {
      await monterContractuels(
        tester,
        port: PortEnEchec(const CapaciteIndisponible('CPT-BR-08')),
      );
      expect(find.text(t.commun.etats.indisponible.titre), findsOneWidget);
    });

    testWidgets('hors ligne : le mot hors ligne, pas une erreur serveur', (
      WidgetTester tester,
    ) async {
      await monterContractuels(
        tester,
        port: PortEnEchec(StateError('x')),
        horsLigne: true,
      );
      expect(find.text(t.commun.etats.horsLigne.titre), findsOneWidget);
    });
  });

  group('W06 liste : lisibilite', () {
    testWidgets('320 px, texte x2 : aucun debordement', (
      WidgetTester tester,
    ) async {
      await monterContractuels(
        tester,
        taille: const Size(320, 640),
        echelleTexte: 2,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Karim Studio'), findsOneWidget);
    });

    testWidgets('1440 : le tableau, sans debordement', (
      WidgetTester tester,
    ) async {
      await monterContractuels(tester, taille: const Size(1440, 900));
      expect(tester.takeException(), isNull);
      expect(find.text(c.colonneBeneficiaire), findsOneWidget);
      expect(find.text(c.colonneMontant), findsOneWidget);
    });
  });
}

/// Les actions portees par les obligations, hors « Nouvelle obligation » qui
/// appartient a l'en-tete (sous les onglets sur telephone).
final Finder _actionsDeZone = find.byWidgetPredicate(
  (Widget w) =>
      w is ActionPrincipale &&
      w.key != const ValueKey<String>('nouvelle-obligation'),
);
