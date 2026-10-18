// FI-12 (suite de la critique, sections 1 et 3) : les actions Finance qui
// n'avaient ni test ni citation, et le tableau des donnees par role
// (UX_REVIEW_08_FINANCE.md:96-106, lecon 15), depuis la VRAIE coquille de
// chaque role.
//
// (a) Actions : Politiques (saisie, erreur de coherence, comparaison,
//     historique), Fiche > Acces, Compte > Paiements du second adulte,
//     Resultat annule, recharge de l'adulte ouverte directement.
// (d) Donnees par role : le second adulte rattache ne recoit ni solde, ni
//     mensualite, ni manque, ni recharge, et le port des finances n'est
//     jamais lu ; l'enfant ne recoit que l'etat d'acces, et ce port ne
//     porte ni montant ni cause.
//
// Deja tenu ailleurs, et non rejoue :
// - Rejoindre de l'enfant dans Mes groupes et a l'Accueil depuis la vraie
//   coquille : recette_fi_test.dart, refus 11 bis ;
// - le second adulte rattache dans Mon espace (aucun bandeau, aucune
//   finance lue) au niveau de la page : acces_finance_test.dart ;
// - Resultat annule et perime, « Recommencer la recharge » :
//   resultat_recharge_test.dart (la selection est gardee).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_acces_foyer.dart';
import 'package:rewayah_academy/core/capacites/port_mes_finances.dart';
import 'package:rewayah_academy/core/capacites/port_paiements_foyer.dart';
import 'package:rewayah_academy/core/capacites/port_recharge_foyer.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/finance/finances_profil.dart';
import 'package:rewayah_academy/core/finance/mouvements_profil.dart';
import 'package:rewayah_academy/core/finance/politique_commerciale.dart';
import 'package:rewayah_academy/core/finance/suivi_paiement.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart'
    show DisqueRetour;
import 'package:rewayah_academy/core/widgets/montant_argent.dart';
import 'package:rewayah_academy/core/widgets/resume_soldes.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';
import 'package:rewayah_academy/features/acces_finance/acces_finance.dart';
import 'package:rewayah_academy/features/admin_finance/politiques_commerciales.dart';
import 'package:rewayah_academy/features/admin_finance/vue_globale_finance.dart'
    show pourMilleEnTexte;
import 'package:rewayah_academy/features/compte/paiements_page.dart';
import 'package:rewayah_academy/features/compte/soldes_foyer.dart';
import 'package:rewayah_academy/features/demo/adulte_demo.dart';
import 'package:rewayah_academy/features/demo/demo_adulte_page.dart';
import 'package:rewayah_academy/features/demo/finance_demo.dart';
import 'package:rewayah_academy/features/foyer/fiche/acces_page.dart';
import 'package:rewayah_academy/features/foyer/fiche/finances_page.dart';
import 'package:rewayah_academy/features/foyer/fiche_eleve_page.dart';
import 'package:rewayah_academy/features/foyer/foyer_page.dart';
import 'package:rewayah_academy/features/foyer/invitation_conjoint.dart';
import 'package:rewayah_academy/features/mon_espace_adulte/mes_finances_page.dart';
import 'package:rewayah_academy/features/mon_espace_adulte/mon_espace_adulte_page.dart';

import '../../router/support_routeur.dart' show stabiliser;
import 'support_recette_fi.dart';

const String _ibrahim = DonneesFinanceDemo.ibrahimId;

/// Le port de mes finances, espion : il compte ses lectures et ne rend
/// rien (production).
class _MesFinancesEspion implements PortMesFinances {
  int lectures = 0;

  @override
  Future<FinancesProfil?> finances() async {
    lectures++;
    return null;
  }

  @override
  Future<List<MouvementProfil>> mouvements() async {
    lectures++;
    return const <MouvementProfil>[];
  }
}

/// Le champ de saisie de la politique [id].
Finder _saisie(String id) => find.descendant(
  of: find.byKey(PolitiquesCommercialesContenu.champKey(id)),
  matching: find.byType(TextField),
);

/// Le texte d'erreur rendu sous le champ [id], ou `null`.
String? _erreurDe(WidgetTester tester, String id) =>
    tester.widget<TextField>(_saisie(id)).decoration?.errorText;

/// Les textes rendus, y compris ceux des `RichText`.
List<String> _textes(WidgetTester tester) => <String>[
  for (final Text texte in tester.widgetList<Text>(find.byType(Text)))
    ?texte.data,
  for (final RichText r in tester.widgetList<RichText>(find.byType(RichText)))
    r.text.toPlainText(),
];

void main() {
  // -----------------------------------------------------------------------
  // (a) Actions sans test ni citation jusqu'ici
  // -----------------------------------------------------------------------
  group('(a) Politiques commerciales, vraie application', () {
    testWidgets('saisie : une remise au-dela de 100 % dit l erreur, '
        '« Publier » demande de corriger ; corrige, l erreur part et la '
        'comparaison avec la version active apparait', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monterAdminFi(tester);
      final pol = t.admin.finance.pol;
      final PolitiqueCommerciale active = DonneesFinanceDemo.politiqueLancement;
      // La remise du deuxieme rang, en pour mille du tarif (tarifs du
      // 18/10/2026) : le champ se lit et s'ecrit en pourcentage entier.
      final RemiseRang regle = active.remisesParRang.first;
      final String id = 'remise-${regle.aPartirDuRang}';
      final int pourcent = regle.pourMille! ~/ 10;
      // Avant toute saisie : aucune difference, aucune comparaison.
      expect(
        find.byKey(PolitiquesCommercialesContenu.comparaisonKey(id)),
        findsNothing,
      );
      expect(_erreurDe(tester, id), isNull);

      // Au-dela de 100 % : l'erreur de plafond.
      await tester.ensureVisible(_saisie(id));
      await tester.enterText(_saisie(id), '101');
      await stabiliser(tester);
      expect(_erreurDe(tester, id), pol.erreurPourcentMax);
      // « Publier » ne part pas : les champs a corriger, rien de publie.
      await toucherFi(tester, find.text(pol.publier));
      expect(find.text(pol.champsACorriger), findsOneWidget);
      expect(find.text(pol.publicationIndisponible), findsNothing);
      expect(cheminFi(routeur), Routes.adminFinancePolitiques);

      // Une forme invalide : l'erreur de champ.
      await tester.enterText(_saisie(id), '7,5');
      await stabiliser(tester);
      expect(_erreurDe(tester, id), pol.erreurChamp);

      // Corrige a une autre valeur : plus d'erreur, la comparaison dit la
      // valeur active.
      await tester.enterText(_saisie(id), '${pourcent + 1}');
      await stabiliser(tester);
      expect(_erreurDe(tester, id), isNull);
      final Finder comparaison = find.byKey(
        PolitiquesCommercialesContenu.comparaisonKey(id),
      );
      expect(comparaison, findsOneWidget);
      final String texte = tester.widget<Text>(comparaison).data!;
      expect(texte, startsWith(pol.versionActiveValeur(valeur: '')));
      expect(
        texte,
        contains(
          pol.pourcentValeur(valeur: pourMilleEnTexte(regle.pourMille!)),
        ),
      );
      expect(find.text(pol.champsACorriger), findsNothing);

      // Revenu a la valeur active : la comparaison s'efface.
      await tester.enterText(_saisie(id), '$pourcent');
      await stabiliser(tester);
      expect(comparaison, findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('historique : une ligne par version, la plus recente '
        'd abord, « Version active » sur la seule version publiee active', (
      WidgetTester tester,
    ) async {
      await monterAdminFi(tester);
      final pol = t.admin.finance.pol;
      final List<PolitiqueCommerciale> versions =
          await const PolitiquesCommercialesDemo().versions();
      final List<double> hauts = <double>[];
      for (final PolitiqueCommerciale v in versions) {
        final Finder ligne = find.byKey(
          PolitiquesCommercialesContenu.historiqueLigneKey(v.version),
        );
        await tester.ensureVisible(ligne);
        await stabiliser(tester);
        expect(ligne, findsOneWidget, reason: v.version);
        expect(
          find.descendant(
            of: ligne,
            matching: find.text(pol.historiqueVersion(version: v.version)),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: ligne,
            matching: find.text(
              v.statut == StatutPolitique.brouillon
                  ? pol.statutBrouillon
                  : pol.statutPubliee,
            ),
          ),
          findsOneWidget,
          reason: v.version,
        );
        final bool active =
            v.version == DonneesFinanceDemo.politiqueLancement.version;
        expect(
          find.descendant(
            of: ligne,
            matching: find.widgetWithText(StatusPill, pol.historiqueActive),
          ),
          active ? findsOneWidget : findsNothing,
          reason: v.version,
        );
        hauts.add(tester.getTopLeft(ligne).dy);
      }
      // L'ordre du port, sans retri : le brouillon puis la version active.
      expect(hauts, orderedEquals(<double>[...hauts]..sort()));
      expect(find.byKey(PolitiquesCommercialesContenu.historiqueKey), findsOne);
    });
  });

  group('(a) Fiche > Acces, vrai routeur', () {
    testWidgets('le retour ramene a la fiche ; la page ne porte aucune '
        'recharge : elle vit dans Finances, un seul endroit', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monterTuteurFi(
        tester,
        depart: Routes.ficheEleveSousPage(_ibrahim, 'acces'),
      );
      expect(find.byType(AccesElevePage), findsOneWidget);
      // Ibrahim a regulariser : la cause dite, sans bouton de recharge.
      expect(find.byKey(AccesElevePage.bandeauKey), findsOneWidget);
      expect(find.byType(ActionPrincipale), findsNothing);
      expect(find.byKey(FinancesElevePage.rechargerKey), findsNothing);
      expect(find.byType(RechargeFoyerPage), findsNothing);
      await toucherFi(tester, find.byType(DisqueRetour).first);
      expect(cheminFi(routeur), Routes.ficheElevePour(_ibrahim));
      expect(find.byType(FicheElevePage), findsOneWidget);
      // De la fiche, Finances porte la seule recharge du profil.
      routeur.go(Routes.ficheEleveSousPage(_ibrahim, 'finances'));
      await stabiliser(tester);
      await toucherFi(tester, find.byKey(FinancesElevePage.rechargerKey));
      expect(cheminFi(routeur), Routes.tuteurFoyerRecharge);
      expect(
        tester
            .widget<RechargeFoyerPage>(find.byType(RechargeFoyerPage))
            .preselection,
        <String>{_ibrahim},
      );
    });
  });

  group('(a) Resultat annule, vrai routeur', () {
    testWidgets('« Revenir aux paiements » ramene au Foyer ; « Recommencer » '
        'a l etape 1 ; aucun succes, aucun Payer', (WidgetTester tester) async {
      final String adresse = Routes.resultatRechargePour(
        DonneesFinanceDemo.commandeDemo(EtatPaiement.annule),
      );
      final GoRouter routeur = await monterTuteurFi(tester, depart: adresse);
      expect(
        find.byKey(ResultatRechargePage.etatKey(EtatPaiement.annule)),
        findsOneWidget,
      );
      expect(find.text(t.adulte.recharge.resultat.annuleTitre), findsOneWidget);
      // La repartition prevue reste lisible, sans aucun nouveau solde : rien
      // n'est credite.
      expect(find.byKey(ResultatRechargePage.repartitionKey), findsOneWidget);
      expect(
        find.textContaining(
          t.adulte.recharge.resultat.nouveauSolde(montant: '').trim(),
        ),
        findsNothing,
      );
      expect(find.byKey(RechargeFoyerPage.payerKey), findsNothing);
      await toucherFi(tester, find.byKey(ResultatRechargePage.revenirKey));
      expect(cheminFi(routeur), Routes.tuteurFoyer);
      expect(find.byType(FoyerPage), findsOneWidget);
      routeur.go(adresse);
      await stabiliser(tester);
      await toucherFi(tester, find.byKey(ResultatRechargePage.recommencerKey));
      expect(cheminFi(routeur), Routes.tuteurFoyerRecharge);
      expect(find.byKey(RechargeFoyerPage.payerKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('(a) Recharge de l eleve adulte autonome ouverte directement', () {
    for (final String? eleve in <String?>[null, DonneesAdulteDemo.aichaId]) {
      testWidgets('eleve=${eleve ?? 'absent'} : son seul profil, coche', (
        WidgetTester tester,
      ) async {
        await monterAdulteFi(
          tester,
          adresseDemoAdulte(
            EcranDemoAdulte.maRecharge,
            etat: EtatDemoAdulte.adulteSeul,
            eleve: eleve,
          ),
        );
        final RechargeFoyerPage page = tester.widget<RechargeFoyerPage>(
          find.byType(RechargeFoyerPage),
        );
        expect(page.preselection, <String>{DonneesAdulteDemo.mamadouId});
        expect(
          tester
              .widget<Checkbox>(
                find.byKey(
                  RechargeFoyerPage.caseDe(DonneesAdulteDemo.mamadouId),
                ),
              )
              .value,
          isTrue,
        );
        // Un seul beneficiaire, le sien : « Verifier » part tout de suite
        // des qu'un montant est choisi.
        expect(find.byType(Checkbox), findsOneWidget);
        await toucherFi(
          tester,
          find.byKey(RechargeFoyerPage.plusDe(DonneesAdulteDemo.mamadouId)),
        );
        expect(
          tester
              .widget<ActionPrincipale>(find.byKey(RechargeFoyerPage.payerKey))
              .onPress,
          isNotNull,
        );
      });
    }
  });

  // -----------------------------------------------------------------------
  // (d) Donnees par role (UX_REVIEW_08_FINANCE.md:96-106)
  // -----------------------------------------------------------------------
  group('(d) second adulte rattache', () {
    testWidgets('Compte > Paiements du foyer : l historique seul, retour vers '
        'Mon espace ; ni solde, ni recharge ; finances, soldes, mouvements '
        'et beneficiaires jamais lus, sur chaque ecran de sa coquille', (
      WidgetTester tester,
    ) async {
      final PaiementsEspionFi paiements = PaiementsEspionFi(
        JeuFoyerFinance.unARegulariser,
      );
      final RechargeEspionneFi recharge = RechargeEspionneFi(
        JeuFoyerFinance.unARegulariser,
      );
      final _MesFinancesEspion miennes = _MesFinancesEspion();
      final List<Override> espions = <Override>[
        portPaiementsFoyerProvider.overrideWithValue(paiements),
        portRechargeFoyerProvider.overrideWithValue(recharge),
        portMesFinancesProvider.overrideWithValue(miennes),
      ];
      String adresse(EcranDemoAdulte ecran) =>
          adresseDemoAdulte(ecran, vue: VueDemoAdulte.secondAdulte);

      // Sa page des paiements : l'historique du foyer, en lecture.
      final GoRouter routeur = await monterAdulteFi(
        tester,
        adresse(EcranDemoAdulte.paiementsFoyer),
        surcharges: espions,
      );
      expect(find.byType(PaiementsComptePage), findsOneWidget);
      expect(find.text(t.adulte.famille.paiementsFoyer), findsWidgets);
      expect(find.byKey(PaiementsComptePage.rechargerKey), findsNothing);
      expect(find.byKey(SoldesFoyerSection.cle), findsNothing);
      expect(paiements.lectures, contains('historique'));
      await toucherFi(tester, find.byType(DisqueRetour).first);
      expect(
        adresseFi(routeur).queryParameters['ecran'],
        EcranDemoAdulte.monEspace.name,
      );
      expect(find.byType(MonEspaceAdultePage), findsOneWidget);

      // Chaque ecran de sa coquille, et chaque adresse financiere tentee.
      for (final EcranDemoAdulte ecran in <EcranDemoAdulte>[
        EcranDemoAdulte.accueil,
        EcranDemoAdulte.monEspace,
        EcranDemoAdulte.forfaitFamille,
        EcranDemoAdulte.paiements,
        EcranDemoAdulte.recharge,
        EcranDemoAdulte.maRecharge,
        EcranDemoAdulte.mesMouvements,
      ]) {
        await monterAdulteFi(tester, adresse(ecran), surcharges: espions);
        expect(tester.takeException(), isNull, reason: ecran.name);
        expect(
          find.byType(RechargeFoyerPage),
          findsNothing,
          reason: ecran.name,
        );
        expect(find.byType(MesFinancesPage), findsNothing, reason: ecran.name);
        expect(
          find.byType(MesMouvementsPage),
          findsNothing,
          reason: ecran.name,
        );
        expect(find.byType(MontantArgent), findsNothing, reason: ecran.name);
        expect(find.byType(ResumeSoldes), findsNothing, reason: ecran.name);
        expect(find.byKey(SoldesFoyerSection.cle), findsNothing);
        expect(find.byKey(BandeauRegularisation.cle), findsNothing);
        for (final String texte in _textes(tester)) {
          expect(
            RegExp(
              r'solde|mensualit|manque|recharg',
              caseSensitive: false,
            ).hasMatch(texte),
            isFalse,
            reason: '${ecran.name} : $texte',
          );
        }
      }
      expect(paiements.lecturesFinancieres, isEmpty);
      expect(recharge.lecturesBeneficiaires, 0);
      expect(miennes.lectures, 0);
    });
  });

  group('(d) eleve enfant', () {
    test('le port de l acces ne porte ni montant ni cause : ses champs, et '
        'chaque acces rendu par la demonstration', () {
      // La classe `AccesBeneficiaire` : ses champs, lus dans la source.
      final String source = File('lib/core/capacites/port_acces_foyer.dart')
          .readAsStringSync();
      final int debut = source.indexOf('class AccesBeneficiaire');
      final int fin = source.indexOf('abstract interface class', debut);
      expect(debut, greaterThan(0));
      final Map<String, String> champs = <String, String>{
        for (final RegExpMatch m in RegExp(
          r'^\s*final\s+([\w?<>]+)\s+(\w+);',
          multiLine: true,
        ).allMatches(source.substring(debut, fin)))
          m.group(2)!: m.group(1)!,
      };
      expect(champs, <String, String>{
        'eleveId': 'String',
        'prenom': 'String',
        'finAcces': 'DateTime?',
        'etatAffiche': 'EtatAccesAffiche',
        'statutServeur': 'String?',
        'motif': 'String?',
        'seancesPayantesOuvertes': 'bool?',
        'essaisUtilises': 'int?',
        'essaisMax': 'int?',
        // FI-BR-08 (revue FI-VAGUE-R R4-04) : un etat de place et son jour,
        // jamais une cause ni un montant.
        'place': 'EtatPlace?',
        'datePlace': 'DateTime?',
        // Contre-revue FI-VAGUE-CORR : qui gere l'acces choisit la copie des
        // seances fermees (enfant ou adulte autonome), jamais une cause.
        'gereSonAcces': 'bool?',
      });
      // Aucun type d'argent, aucun nom de montant ou de cause financiere.
      for (final MapEntry<String, String> c in champs.entries) {
        expect(
          RegExp(r'Montant|Finances|Mouvement').hasMatch(c.value),
          isFalse,
          reason: c.key,
        );
        expect(
          RegExp(
            r'solde|montant|manque|mensualit|debit|tarif|paie',
            caseSensitive: false,
          ).hasMatch(c.key),
          isFalse,
          reason: c.key,
        );
      }
      // `motif` et `statutServeur` sont reserves : jamais rendus.
      for (final JeuFoyerFinance jeu in JeuFoyerFinance.values) {
        for (final AccesBeneficiaire a in DonneesFinanceDemo.acces(jeu)) {
          expect(a.motif, isNull, reason: '${jeu.name} ${a.prenom}');
          expect(a.statutServeur, isNull, reason: '${jeu.name} ${a.prenom}');
        }
      }
    });

    testWidgets('sur la vraie coquille de l eleve, ni les finances du foyer '
        'ni « mes finances » ne sont lues, sur aucun ecran, ouvert ou ferme', (
      WidgetTester tester,
    ) async {
      for (final JeuFoyerFinance jeu in <JeuFoyerFinance>[
        JeuFoyerFinance.tousFinances,
        JeuFoyerFinance.unARegulariser,
        JeuFoyerFinance.unEnEssai,
      ]) {
        final PaiementsEspionFi paiements = PaiementsEspionFi(jeu);
        final RechargeEspionneFi recharge = RechargeEspionneFi(jeu);
        final _MesFinancesEspion miennes = _MesFinancesEspion();
        final DateTime maintenant = DateTime.now();
        final GoRouter routeur = await monterEleveFi(
          tester,
          Routes.eleve,
          profilId: _ibrahim,
          seances: <Seance>[
            Seance(
              id: 'fi12-role',
              debut: maintenant.subtract(const Duration(minutes: 10)),
              fin: maintenant.add(const Duration(minutes: 50)),
              statut: StatutSeance.enCours,
              eleveId: _ibrahim,
              elevePrenom: 'Ibrahim',
              eleveIdentifiant: 'STUD-FI-$_ibrahim',
              enseignantId: 't1',
              enseignantPrenom: 'Aminata',
              enseignantIdentifiant: 'TEACH-FI-000001',
            ),
          ],
          surcharges: <Override>[
            // L'acces de l'enfant, borne a sa session (FI-BR-08, R4-02).
            portMonAccesProvider.overrideWithValue(
              MonAccesFinanceDemo(jeu, _ibrahim),
            ),
            portPaiementsFoyerProvider.overrideWithValue(paiements),
            portRechargeFoyerProvider.overrideWithValue(recharge),
            portMesFinancesProvider.overrideWithValue(miennes),
          ],
        );
        for (final String chemin in <String>[
          Routes.eleve,
          Routes.eleveSuivi,
          Routes.eleveCoran,
          Routes.tcGroupes,
        ]) {
          routeur.go(chemin);
          await stabiliser(tester);
          expect(find.byType(MontantArgent), findsNothing, reason: chemin);
          expect(tester.takeException(), isNull, reason: chemin);
        }
        expect(paiements.lectures, isEmpty, reason: jeu.name);
        expect(recharge.lecturesBeneficiaires, 0, reason: jeu.name);
        expect(miennes.lectures, 0, reason: jeu.name);
      }
    });
  });
}
