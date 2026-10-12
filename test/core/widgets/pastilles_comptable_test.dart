// CPT-F : les habits de `StatusPill` du Comptable (spec §15, §24.1, §25,
// §38, §42, §49). Chaque etat porte un mot distinct, lisible sans couleur ;
// chaque enumeration est couverte en entier ; `LigneDestinationMasquee` lit
// la destination au lecteur d'ecran sans suite de points.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/comptable/modeles_comptable.dart';
import 'package:rewayah_academy/core/comptable/statuts_comptable.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/ligne_destination_masquee.dart';
import 'package:rewayah_academy/core/widgets/pastilles_comptable.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';

import '../../support/harnais.dart';

void _motsDistincts<T>(List<T> valeurs, String Function(T) libelle) {
  final Set<String> mots = <String>{};
  for (final T v in valeurs) {
    final String mot = libelle(v);
    expect(mot.trim(), isNotEmpty, reason: '$v');
    expect(mots.add(mot), isTrue, reason: '$v : mot deja pris « $mot »');
  }
}

void main() {
  setUpAll(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  test('15 etats de paiement sortant, un mot chacun (§15)', () {
    expect(EtatPaiementSortant.values, hasLength(15));
    _motsDistincts(EtatPaiementSortant.values, libellePaiementSortant);
    expect(
      libellePaiementSortant(EtatPaiementSortant.validationRequise),
      'Validation supplémentaire requise',
    );
  });

  test('9 etats d encaissement (§24.1), 6 de rapprochement (§25)', () {
    expect(EtatEncaissement.values, hasLength(9));
    _motsDistincts(EtatEncaissement.values, libelleEncaissement);
    expect(EtatRapprochement.values, hasLength(6));
    _motsDistincts(EtatRapprochement.values, libelleRapprochement);
  });

  test('6 + 1 etats de profil (§38, §18), 5 capacites (§42), '
      '6 etats de Reserve (§49)', () {
    expect(EtatProfilPaiement.values, hasLength(7));
    _motsDistincts(EtatProfilPaiement.values, libelleProfilPaiement);
    expect(
      libelleProfilPaiement(EtatProfilPaiement.invitationEnvoyee),
      'Invitation envoyée',
    );
    expect(CapacitePayout.values, hasLength(5));
    _motsDistincts(CapacitePayout.values, libelleCapacitePayout);
    expect(EtatReserve.values, hasLength(6));
    _motsDistincts(EtatReserve.values, libelleEtatReserve);
  });

  test('12 alertes (§28) avec leur liste (DR-10), 12 actions, '
      '16 raisons de blocage (CPT-BR §1, dont les 6 de DELEG-FIN-1), 7 coffres (§8.1)', () {
    expect(TypeAlerteComptable.values, hasLength(12));
    _motsDistincts(TypeAlerteComptable.values, libelleAlerteComptable);
    expect(
      TypeAlerteComptable.values
          .where(
            (TypeAlerteComptable a) =>
                a.listeParDefaut == ListeAttention.alerte,
          )
          .length,
      4,
    );
    expect(ActionFinance.values, hasLength(12));
    expect(RaisonBlocage.values, hasLength(16));
    _motsDistincts(RaisonBlocage.values, libelleRaisonBlocage);
    expect(
      libelleRaisonBlocage(RaisonBlocage.autoPaiement),
      'Traitement par un autre responsable requis',
    );
    expect(Coffre.values, hasLength(7));
    _motsDistincts(Coffre.values, libelleCoffre);
    expect(Coffre.values.where((Coffre c) => c.protege).length, 5);
    expect(libelleCoffre(Coffre.reserveStrategique), 'Réserve stratégique');
  });

  testWidgets('une pastille = un point et un mot, jamais la couleur seule', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hote(
        const Material(
          child: Column(
            children: <Widget>[
              PastillePaiementSortant(EtatPaiementSortant.pretAPayer),
              PastilleEncaissement(EtatEncaissement.confirme),
              PastilleRapprochement(EtatRapprochement.doublonPotentiel),
              PastilleProfilPaiement(EtatProfilPaiement.verifie),
              PastilleCapacitePayout(
                CapacitePayout.soldePrestataireInsuffisant,
              ),
              PastilleEtatReserve(EtatReserve.sousObjectif),
              PastilleObligationContractuel(
                EtatObligationContractuel.approuvee,
              ),
              PastilleRemboursement(EtatRemboursement.approbationRequise),
              PastilleDemandeValidation(EtatDemandeValidation.enAttente),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(StatusPill), findsNWidgets(9));
    expect(find.text('Prêt à payer'), findsOneWidget);
    expect(find.text('Doublon potentiel'), findsOneWidget);
    expect(find.text('Sous objectif'), findsOneWidget);
    expect(find.text('Validation demandée'), findsOneWidget);
    final StatusPill echoue =
        (find.byType(StatusPill).evaluate().first.widget) as StatusPill;
    expect(echoue.ton, TonEtat.accent);
    expect(tonPaiementSortant(EtatPaiementSortant.echoue), TonEtat.alerte);
  });

  testWidgets('LigneDestinationMasquee : suffixe rendu par la source, lu en '
      'mots, aucune coordonnee complete', (WidgetTester tester) async {
    const DestinationMasquee d = DestinationMasquee(
      type: 'Mobile money',
      operateur: 'Operateur A',
      suffixe: '4423',
      pays: 'GN',
      devise: 'GNF',
      verification: EtatProfilPaiement.verifie,
    );
    await tester.pumpWidget(
      hote(
        const Material(
          child: Column(
            children: <Widget>[
              LigneDestinationMasquee(destination: d),
              LigneDestinationMasquee(),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('•••• 4423'), findsOneWidget);
    expect(find.text(t.comptable.commun.destinationAucune), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('se termine par 4423')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(RegExp('••••')), findsNothing);
  });
}
