// CPT-CTR-1 : la vue d'une obligation. Le montant ne se modifie nulle part ;
// « Payer » ouvre W03 ; « Approuver » seulement si la source le permet, sinon
// sa raison ; lignes avec source, auteur et validation ; invitation du
// beneficiaire externe ; les cinq etats.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/port_obligations_contractuels.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/montant_sensible.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/demo/comptable/socle_comptable_demo.dart';

import 'support_contractuels.dart';

String _adresse(String id) => Routes.comptableContractuelObligationPour(id);

final Finder _action = find.byKey(const ValueKey<String>('action-obligation'));

void main() {
  final c = t.comptable.contractuels;
  final String masque = MontantSensible.masquePour('USD');

  group('Facture #024 (spec §22.4)', () {
    testWidgets('approuvee : montant fige, Payer, aucun champ de saisie', (
      WidgetTester tester,
    ) async {
      await monterContractuels(
        tester,
        depart: _adresse(SocleComptableDemo.obligationFacture024),
      );
      expect(find.text('Facture #024'), findsWidgets);
      expect(find.text('Karim Studio'), findsWidgets);
      expect(find.text(c.montantFige), findsOneWidget);
      expect(find.text(c.payer), findsOneWidget);
      expect(find.text(c.approuver), findsNothing);
      // Le montant ne se modifie pas : aucun champ de saisie sur la page.
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(EditableText), findsNothing);
    });

    testWidgets('masque par defaut', (WidgetTester tester) async {
      await monterContractuels(
        tester,
        depart: _adresse(SocleComptableDemo.obligationFacture024),
      );
      expect(find.text(masque), findsWidgets);
      expect(find.textContaining('350'), findsNothing);
    });

    testWidgets('350 USD une fois revele', (WidgetTester tester) async {
      await monterContractuels(
        tester,
        depart: _adresse(SocleComptableDemo.obligationFacture024),
        montantsAffiches: true,
      );
      expect(find.textContaining('350'), findsWidgets);
      expect(find.text(masque), findsNothing);
    });

    testWidgets('Payer ouvre le detail de paiement W03 de l obligation', (
      WidgetTester tester,
    ) async {
      await monterContractuels(
        tester,
        depart: _adresse(SocleComptableDemo.obligationFacture024),
      );
      await tester.tap(_action);
      await tester.pumpAndSettle();
      expect(find.text(texteW03('obl-pay-ctr-024')), findsOneWidget);
    });

    testWidgets('le journal et les informations sont lisibles', (
      WidgetTester tester,
    ) async {
      await monterContractuels(
        tester,
        depart: _adresse(SocleComptableDemo.obligationFacture024),
      );
      expect(find.text('facture-024.pdf'), findsOneWidget);
      expect(find.text('Communication'), findsOneWidget);
      expect(find.text(c.sectionHistorique), findsOneWidget);
      expect(find.text('Approbation'), findsOneWidget);
      expect(find.textContaining('la direction'), findsWidgets);
    });
  });

  group('Approbation', () {
    testWidgets('auteur = le Comptable : pas d Approuver, la raison rendue', (
      WidgetTester tester,
    ) async {
      await monterContractuels(tester, depart: _adresse('obl-ctr-025'));
      expect(_action, findsNothing);
      expect(find.byType(ActionPrincipale), findsNothing);
      expect(
        find.text(t.comptable.statuts.raison.autoPaiement),
        findsOneWidget,
      );
      expect(find.text(c.montantDefini), findsOneWidget);
    });

    testWidgets('permis : Approuver fige le montant, le paiement reste borne', (
      WidgetTester tester,
    ) async {
      await monterContractuels(tester, depart: _adresse('obl-ctr-027'));
      expect(find.text(c.approuver), findsOneWidget);
      expect(find.text(c.payer), findsNothing);
      await tester.tap(_action);
      await tester.pumpAndSettle();
      expect(find.text(c.approuver), findsNothing);
      expect(find.text(c.montantFige), findsOneWidget);
      // L'externe n'a pas encore saisi sa methode : pas de Payer, et la
      // raison rendue par la source est dite.
      expect(find.text(c.payer), findsNothing);
      expect(
        find.text(t.comptable.statuts.raison.infosManquantes),
        findsOneWidget,
      );
    });

    testWidgets('approuvee mais verification requise : pas de Payer, raison', (
      WidgetTester tester,
    ) async {
      await monterContractuels(tester, depart: _adresse('obl-ctr-026'));
      expect(_action, findsNothing);
      expect(
        find.text(t.comptable.statuts.raison.verificationRequise),
        findsOneWidget,
      );
    });
  });

  group('Lignes du montant (§23)', () {
    testWidgets('un ajustement est une ligne avec source, auteur, validation', (
      WidgetTester tester,
    ) async {
      await monterContractuels(tester, depart: _adresse('obl-ctr-026'));
      expect(find.text('Intervention supplémentaire'), findsOneWidget);
      expect(
        find.text(c.ligneSource(source: 'Demande de la direction')),
        findsOneWidget,
      );
      expect(find.text(c.ligneAuteur(auteur: 'la direction')), findsWidgets);
      expect(
        find.text(c.ligneValidation(validation: 'Validée le 2 octobre')),
        findsOneWidget,
      );
      expect(find.text('Forfait mensuel'), findsOneWidget);
    });
  });

  group('Beneficiaire externe (DR-16)', () {
    testWidgets('Invitation envoyee, Renvoyer l invitation', (
      WidgetTester tester,
    ) async {
      await monterContractuels(tester, depart: _adresse('obl-ctr-027'));
      expect(
        find.text(t.comptable.statuts.profil.invitationEnvoyee),
        findsOneWidget,
      );
      final Finder renvoyer = find.byKey(
        const ValueKey<String>('renvoyer-invitation'),
      );
      await tester.ensureVisible(renvoyer);
      await tester.tap(renvoyer);
      await tester.pumpAndSettle();
      expect(find.text(c.invitationRenvoyee), findsOneWidget);
    });

    testWidgets('un beneficiaire avec paiement verifie n a pas d invitation', (
      WidgetTester tester,
    ) async {
      await monterContractuels(tester, depart: _adresse('obl-ctr-025'));
      expect(find.text(c.renvoyerInvitation), findsNothing);
    });
  });

  group('Etats', () {
    testWidgets('refusee : le motif est dit, aucune action', (
      WidgetTester tester,
    ) async {
      await monterContractuels(tester, depart: _adresse('obl-ctr-021'));
      expect(
        find.textContaining("Doublon du devis d'octobre."),
        findsOneWidget,
      );
      expect(find.byType(ActionPrincipale), findsNothing);
    });

    testWidgets('introuvable : echec avec Reessayer', (
      WidgetTester tester,
    ) async {
      await monterContractuels(tester, depart: _adresse('inconnue'));
      expect(find.byType(EtatSysteme), findsOneWidget);
    });

    testWidgets('capacite absente : indisponible', (WidgetTester tester) async {
      await monterContractuels(tester, depart: _adresse('x'), port: _Absent());
      expect(find.text(t.commun.etats.indisponible.titre), findsOneWidget);
    });

    testWidgets('hors ligne', (WidgetTester tester) async {
      await monterContractuels(
        tester,
        depart: _adresse('x'),
        port: _EnEchec(),
        horsLigne: true,
      );
      expect(find.text(t.sansDonnees.obligation), findsOneWidget);
    });

    testWidgets('chargement : squelette', (WidgetTester tester) async {
      await monterContractuels(
        tester,
        depart: _adresse('x'),
        port: _Lent(),
        attendre: false,
      );
      expect(find.byType(Skeleton), findsWidgets);
      await tester.pumpWidget(const SizedBox());
    });

    for (final (String nom, Size taille, double echelle) cas
        in <(String, Size, double)>[
          ('320 px texte x2', const Size(320, 640), 2),
          ('390 px', const Size(390, 844), 1),
          ('1440 px', const Size(1440, 900), 1),
        ]) {
      testWidgets('sans debordement : ${cas.$1}', (WidgetTester tester) async {
        for (final String id in <String>[
          'obl-ctr-024',
          'obl-ctr-026',
          'obl-ctr-027',
        ]) {
          await monterContractuels(
            tester,
            depart: _adresse(
              id == 'obl-ctr-024'
                  ? SocleComptableDemo.obligationFacture024
                  : id,
            ),
            taille: cas.$2,
            echelleTexte: cas.$3,
          );
          expect(tester.takeException(), isNull, reason: id);
        }
      });
    }
  });
}

class _Absent extends PortVide {
  _Absent();

  @override
  Future<ObligationContractuel> detail(String obligationId) =>
      Future<ObligationContractuel>.error(
        const CapaciteIndisponible('CPT-BR-08'),
      );
}

class _EnEchec extends PortVide {
  _EnEchec();

  @override
  Future<ObligationContractuel> detail(String obligationId) =>
      Future<ObligationContractuel>.error(StateError('x'));
}

class _Lent extends PortVide {
  _Lent();

  @override
  Future<ObligationContractuel> detail(String obligationId) =>
      Completer<ObligationContractuel>().future;
}
