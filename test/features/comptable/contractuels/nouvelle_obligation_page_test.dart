// CPT-CTR-1 : « Nouvelle obligation ». Prerempli, propose, saisi en dernier
// (K-57) ; creation seulement avec la capacite ; une seule ecriture, avec sa
// cle d'idempotence ; cinq etats.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_obligations_contractuels.dart';
import 'package:rewayah_academy/core/comptable/statuts_comptable.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/choice_card_group.dart';
import 'package:rewayah_academy/core/widgets/filter_pill.dart';
import 'package:rewayah_academy/features/demo/comptable/contractuels_demo.dart';

import 'support_contractuels.dart';

const String _nouvelle = Routes.comptableContractuelsNouvelle;

Finder _cle(String k) => find.byKey(ValueKey<String>(k));

class _Espion extends ObligationsContractuelsDemo {
  _Espion({this.echec = false});

  final bool echec;
  final List<BrouillonObligationContractuel> brouillons =
      <BrouillonObligationContractuel>[];
  final List<String> cles = <String>[];

  @override
  Future<ObligationContractuel> creer({
    required BrouillonObligationContractuel brouillon,
    required String cleIdempotence,
  }) {
    brouillons.add(brouillon);
    cles.add(cleIdempotence);
    if (echec) return Future<ObligationContractuel>.error(StateError('x'));
    return super.creer(brouillon: brouillon, cleIdempotence: cleIdempotence);
  }
}

Future<void> _saisir(WidgetTester tester, String cle, String texte) async {
  await tester.ensureVisible(_cle(cle));
  await tester.enterText(_cle(cle), texte);
  await tester.pump();
}

Future<void> _creer(WidgetTester tester) async {
  await tester.ensureVisible(_cle('creer-obligation'));
  await tester.tap(_cle('creer-obligation'));
  await tester.pumpAndSettle();
}

void main() {
  final c = t.comptable.contractuels;

  group('K-57 : preremplir, proposer, saisir en dernier', () {
    testWidgets('beneficiaire, echeance et centre de cout sont proposes', (
      WidgetTester tester,
    ) async {
      await monterContractuels(tester, depart: _nouvelle);
      final ChoiceCardGroup choix = tester.widget(_cle('choix-beneficiaire'));
      expect(choix.valeurInitiale!.valeurs, <String>{'ctr-01'});
      expect(
        tester.widget<FilterPill>(_cle('centre-Administration')).retenue,
        isTrue,
      );
      expect(find.text(c.deviseDe(devise: 'USD')), findsOneWidget);
      expect(find.text(c.changerEcheance), findsOneWidget);
    });

    testWidgets('seuls l objet et le montant se saisissent, en dernier', (
      WidgetTester tester,
    ) async {
      await monterContractuels(tester, depart: _nouvelle);
      // Un seul bouton plein, et aucun champ avant l'objet.
      expect(
        find.byType(ActionPrincipale).evaluate().where((Element e) {
          final ActionPrincipale a = e.widget as ActionPrincipale;
          return a.niveau == NiveauAction.principale;
        }),
        hasLength(1),
      );
      final double yObjet = tester.getTopLeft(_cle('champ-objet')).dy;
      final double yMontant = tester.getTopLeft(_cle('champ-montant')).dy;
      final double yCentre = tester
          .getTopLeft(_cle('centre-Administration'))
          .dy;
      expect(yCentre, lessThan(yObjet));
      expect(yObjet, lessThan(yMontant));
      expect(_cle('champ-nom-externe'), findsNothing);
    });

    testWidgets('un beneficiaire externe demande son nom', (
      WidgetTester tester,
    ) async {
      await monterContractuels(tester, depart: _nouvelle);
      await tester.ensureVisible(_cle('beneficiaire-externe'));
      await tester.tap(_cle('beneficiaire-externe'));
      await tester.pumpAndSettle();
      expect(_cle('champ-nom-externe'), findsOneWidget);
    });
  });

  group('Creation', () {
    testWidgets('cree une fois, avec le montant en unites mineures', (
      WidgetTester tester,
    ) async {
      final _Espion port = _Espion();
      final GoRouter routeur = await monterContractuels(
        tester,
        depart: _nouvelle,
        port: port,
      );
      await _saisir(tester, 'champ-objet', 'Facture #031');
      await _saisir(tester, 'champ-montant', '350,50');
      await _creer(tester);
      expect(port.brouillons, hasLength(1));
      final BrouillonObligationContractuel b = port.brouillons.single;
      expect(b.objet, 'Facture #031');
      expect(b.montant.mineur, 35050);
      expect(b.montant.devise, 'USD');
      expect(b.beneficiaireId, 'ctr-01');
      expect(b.centreCout, 'Administration');
      expect(b.nouveauBeneficiaire, isNull);
      expect(b.type, TypeObligationContractuel.ponctuelle);
      expect(port.cles.single, startsWith('ctr-'));
      // On arrive sur l'obligation creee, a approuver, montant defini.
      expect(
        routeur.routerDelegate.currentConfiguration.uri.path,
        startsWith(Routes.comptableContractuelsObligation),
      );
      expect(find.text('Facture #031'), findsWidgets);
      expect(find.text(c.montantDefini), findsOneWidget);
    });

    testWidgets('externe : le nom part avec le brouillon', (
      WidgetTester tester,
    ) async {
      final _Espion port = _Espion();
      await monterContractuels(tester, depart: _nouvelle, port: port);
      await tester.ensureVisible(_cle('beneficiaire-externe'));
      await tester.tap(_cle('beneficiaire-externe'));
      await tester.pumpAndSettle();
      await _saisir(tester, 'champ-nom-externe', 'Studio Baraka');
      await _saisir(tester, 'champ-objet', 'Maquettes');
      await _saisir(tester, 'champ-montant', '120');
      await _creer(tester);
      expect(port.brouillons.single.nouveauBeneficiaire, 'Studio Baraka');
      expect(port.brouillons.single.beneficiaireId, isEmpty);
    });

    testWidgets('champs manquants : trois erreurs, aucune ecriture', (
      WidgetTester tester,
    ) async {
      final _Espion port = _Espion();
      await monterContractuels(tester, depart: _nouvelle, port: port);
      await tester.ensureVisible(_cle('beneficiaire-externe'));
      await tester.tap(_cle('beneficiaire-externe'));
      await tester.pumpAndSettle();
      await _creer(tester);
      expect(port.brouillons, isEmpty);
      expect(find.text(c.erreurNomExterne), findsOneWidget);
      expect(find.text(c.erreurObjet), findsOneWidget);
      expect(find.text(c.erreurMontant), findsOneWidget);
    });

    testWidgets('un montant nul ou illisible est refuse', (
      WidgetTester tester,
    ) async {
      final _Espion port = _Espion();
      await monterContractuels(tester, depart: _nouvelle, port: port);
      await _saisir(tester, 'champ-objet', 'X');
      await _saisir(tester, 'champ-montant', '0');
      await _creer(tester);
      expect(port.brouillons, isEmpty);
      expect(find.text(c.erreurMontant), findsOneWidget);
    });

    testWidgets('echec : la phrase dit quoi faire, le bouton reste', (
      WidgetTester tester,
    ) async {
      final _Espion port = _Espion(echec: true);
      await monterContractuels(tester, depart: _nouvelle, port: port);
      await _saisir(tester, 'champ-objet', 'X');
      await _saisir(tester, 'champ-montant', '10');
      await _creer(tester);
      expect(find.text(c.erreurCreation), findsOneWidget);
      expect(_cle('creer-obligation'), findsOneWidget);
    });

    testWidgets('rejouer apres un echec garde la meme cle d idempotence', (
      WidgetTester tester,
    ) async {
      final _Espion port = _Espion(echec: true);
      await monterContractuels(tester, depart: _nouvelle, port: port);
      await _saisir(tester, 'champ-objet', 'X');
      await _saisir(tester, 'champ-montant', '10');
      await _creer(tester);
      await _creer(tester);
      expect(port.cles, hasLength(2));
      expect(port.cles[0], port.cles[1]);
    });
  });

  group('Capacite et etats', () {
    testWidgets('hors delegation : la raison, aucun formulaire', (
      WidgetTester tester,
    ) async {
      await monterContractuels(
        tester,
        depart: _nouvelle,
        port: ObligationsContractuelsDemo(peutCreer: false),
      );
      expect(find.byType(TextField), findsNothing);
      expect(find.text(c.creer), findsNothing);
      expect(
        find.text(t.comptable.statuts.raison.horsDelegation),
        findsOneWidget,
      );
      expect(find.text(c.creationIndisponible), findsOneWidget);
    });

    testWidgets('hors ligne : le bouton est retire, une phrase le dit', (
      WidgetTester tester,
    ) async {
      await monterContractuels(tester, depart: _nouvelle, horsLigne: true);
      expect(find.text(c.creer), findsNothing);
      expect(find.text(c.horsLigneCreation), findsOneWidget);
    });

    for (final (String nom, Size taille, double echelle) cas
        in <(String, Size, double)>[
          ('320 px texte x2', const Size(320, 640), 2),
          ('390 px', const Size(390, 844), 1),
          ('1440 px', const Size(1440, 900), 1),
        ]) {
      testWidgets('sans debordement : ${cas.$1}', (WidgetTester tester) async {
        await monterContractuels(
          tester,
          depart: _nouvelle,
          taille: cas.$2,
          echelleTexte: cas.$3,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });
}
