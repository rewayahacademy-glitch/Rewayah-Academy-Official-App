// FI-1c : la seule source des donnees de demonstration de la Finance
// (`lib/features/demo/finance_demo.dart`) et les ports neutres.
//
// Ce que ces tests prouvent : chaque valeur de la politique de lancement
// (guide Finance V4 §1) se lit depuis la demonstration ; l'accent d'un profil
// ne depend pas de sa place dans la liste ; les six jeux du guide F2 existent
// et respectent FI1 a FI4 ; les ports de production sont neutres
// (`CapaciteIndisponible`) ; aucune valeur commerciale n'est ecrite ailleurs
// dans `lib/`.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/port_acces_foyer.dart';
import 'package:rewayah_academy/core/capacites/port_finance_direction.dart';
import 'package:rewayah_academy/core/capacites/port_paiements_foyer.dart';
import 'package:rewayah_academy/core/capacites/port_politique_famille.dart';
import 'package:rewayah_academy/core/capacites/port_politiques_commerciales.dart';
import 'package:rewayah_academy/core/capacites/port_recharge_foyer.dart';
import 'package:rewayah_academy/core/capacites/port_revenus_enseignant.dart';
import 'package:rewayah_academy/core/finance/finances_profil.dart';
import 'package:rewayah_academy/core/finance/format_montant.dart';
import 'package:rewayah_academy/core/finance/montant.dart';
import 'package:rewayah_academy/core/finance/mouvements_profil.dart';
import 'package:rewayah_academy/core/finance/politique_commerciale.dart';
import 'package:rewayah_academy/core/finance/suivi_paiement.dart';
import 'package:rewayah_academy/features/demo/finance_demo.dart';

Matcher get _indisponible => throwsA(isA<CapaciteIndisponible>());

FinancesProfil _profil(JeuFoyerFinance jeu, String id) =>
    DonneesFinanceDemo.profils(jeu)
        .firstWhere((FinancesProfil p) => p.profilId == id);

void main() {
  group('politique de la demonstration (v2.0.0, tarifs du 18/10/2026)', () {
    final PolitiqueCommerciale p = DonneesFinanceDemo.politiqueLancement;

    // La source de verite des valeurs : le fichier des tarifs du directeur.
    // La demonstration doit lui etre egale, sans que le test recopie un seul
    // nombre.
    final Map<String, dynamic> tarifs = jsonDecode(
      File('docs/current/tarifs-2026-10-18.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    Montant mineur(Object? v) => Montant(v! as int, 'USD');
    final Map<String, dynamic> enfant =
        (tarifs['formules'] as Map<String, dynamic>)['enfant']
            as Map<String, dynamic>;
    final Map<String, dynamic> adulte =
        (tarifs['formules'] as Map<String, dynamic>)['adulte']
            as Map<String, dynamic>;
    final Map<String, dynamic> remises =
        tarifs['remises'] as Map<String, dynamic>;
    final Map<String, dynamic> prof =
        tarifs['enseignant'] as Map<String, dynamic>;
    final Map<String, dynamic> calendrier =
        tarifs['calendrier_paiement'] as Map<String, dynamic>;

    test('tarifs : ceux du fichier du 18/10/2026, en unites mineures', () {
      expect(p.tarifEnfant, mineur(enfant['prix_mensuel_mineur']));
      expect(p.tarifAdulte, mineur(adulte['prix_mensuel_mineur']));
      expect(p.tarifEnfant.devise, tarifs['devise']);
      expect(p.tarifEnfant.mineur, DonneesFinanceDemo.usd(55).mineur);
    });

    test('pas d essai gratuit', () {
      expect(tarifs['essai_gratuit'], isFalse);
      expect(p.essaiActif, isFalse);
      expect(p.essaisMax, 0);
    });

    test('remises du foyer : en pour mille, des le rang 2 et le rang 3', () {
      final List<dynamic> foyer = remises['foyer'] as List<dynamic>;
      expect(p.remisesParRang, hasLength(foyer.length));
      for (final (int i, dynamic r) in foyer.indexed) {
        final Map<String, dynamic> regle = r as Map<String, dynamic>;
        expect(p.remisesParRang[i].aPartirDuRang, regle['a_partir_du_rang']);
        expect(p.remisesParRang[i].pourMille, regle['pour_mille']);
        expect(p.remisesParRang[i].remise, isNull);
      }
      // Rang 1 : aucune remise ; au-dela du dernier palier, la meme.
      expect(p.remiseRangPour(1), isNull);
      expect(p.remiseRangPour(2)!.pourMille, p.remisesParRang.first.pourMille);
      expect(p.remiseRangPour(3)!.pourMille, p.remisesParRang.last.pourMille);
      expect(p.remiseRangPour(9)!.pourMille, p.remisesParRang.last.pourMille);
    });

    test('mensualites par rang : tarif moins la remise en pour mille', () {
      int attendu(int rang) {
        final int tarif = p.tarifEnfant.mineur;
        final int pm = p.remiseRangPour(rang)?.pourMille ?? 0;
        return tarif - (tarif * pm + 500) ~/ 1000;
      }

      for (int rang = 1; rang <= 5; rang++) {
        expect(
          DonneesFinanceDemo.mensualiteRang(rang).mineur,
          attendu(rang),
          reason: 'rang $rang',
        );
      }
      // Le total d'un foyer de 3 et de 4 enfants est la somme des rangs.
      int total(int membres) => <int>[
        for (int rang = 1; rang <= membres; rang++)
          for (final LigneMensualite l in DonneesFinanceDemo.lignesPourRang(
            rang,
          ))
            l.montant.mineur,
      ].fold<int>(0, (int s, int m) => s + m);
      expect(total(3), attendu(1) + attendu(2) + attendu(3));
      expect(total(4), total(3) + attendu(3));
      // Les adultes : meme regle sur leur tarif.
      final int tarifAdulte = p.tarifAdulte.mineur;
      final int pm2 = p.remiseRangPour(2)!.pourMille!;
      expect(
        DonneesFinanceDemo.mensualiteRang(2, adulte: true).mineur,
        tarifAdulte - (tarifAdulte * pm2 + 500) ~/ 1000,
      );
    });

    test('paie de l enseignant : par eleve present et par heure', () {
      final Map<String, dynamic> taux =
          prof['taux_par_eleve_present_heure_mineur'] as Map<String, dynamic>;
      final Map<String, dynamic> plafond =
          prof['plafond'] as Map<String, dynamic>;
      expect(p.tauxEleveHeureEnfant, mineur(taux['enfant']));
      expect(p.tauxEleveHeureAdulte, mineur(taux['adulte']));
      expect(p.plafondEleveHeureEnfant, mineur(plafond['enfant']));
      expect(p.plafondEleveHeureAdulte, mineur(plafond['adulte']));
      expect(p.dureeDueEnfantMinutes, enfant['duree_minimale_due_minutes']);
      expect(p.dureeDueAdulteMinutes, adulte['duree_minimale_due_minutes']);
      expect(
        p.tauxEleveHeureEnfant!.mineur,
        lessThanOrEqualTo(p.plafondEleveHeureEnfant!.mineur),
      );
    });

    test('prepaiement, bourse, parrainage, cumul et suspension', () {
      final Map<String, dynamic> pre =
          remises['prepaiement'] as Map<String, dynamic>;
      final Map<String, dynamic> bourse =
          remises['bourse'] as Map<String, dynamic>;
      expect(p.prepaiementTrimestrielPourMille, pre['trimestriel_pour_mille']);
      expect(p.prepaiementAnnuelPourMille, pre['annuel_pour_mille']);
      expect(p.parrainageCredit, mineur(remises['parrainage_credit_mineur']));
      expect(p.boursePourMille, bourse['pour_mille']);
      expect(
        p.boursePlacesPourMille,
        bourse['places_max_pour_mille_des_eleves'],
      );
      expect(p.bourseDureeMois, bourse['revue_mois']);
      expect(p.cumulMaxPourMille, remises['cumul_max_pour_mille']);
      expect(p.jourSuspension, calendrier['suspension_jour']);
      expect(p.joursRelance, calendrier['relances_jours_avant']);
    });

    test('groupes : le minimum d ouverture et les capacites du fichier', () {
      expect(p.minimumOuverture, enfant['groupe_min']);
      expect(p.capaciteEnfant, enfant['groupe_max']);
      expect(p.capaciteAdulte, adulte['groupe_max']);
    });

    test('place conservee : la duree du calendrier de paiement', () {
      expect(p.joursConservationPlace, calendrier['place_gardee_jours']);
    });

    test('marge de reference croissante, jamais une sanction', () {
      expect(
        p.margeReferencePourMille.objectif,
        lessThan(p.margeReferencePourMille.forte),
      );
      expect(
        p.margeReferencePourMille.forte,
        lessThan(p.margeReferencePourMille.stretch),
      );
    });

    test('rail WEB_STRIPE seul actif (FI10)', () {
      expect(p.railsActifs, <RailPaiement>{RailPaiement.webStripe});
    });

    test('version publiee et datee, sans aucune annee 2024', () {
      expect(p.statut, StatutPolitique.publiee);
      expect(p.version, isNotEmpty);
      expect(p.dateEffet.year, isNot(2024));
    });

    test('le brouillon reprend la politique, sans valeur de plus', () {
      final PolitiqueCommerciale b = DonneesFinanceDemo.politiqueBrouillon;
      expect(b.statut, StatutPolitique.brouillon);
      expect(b.tarifEnfant, p.tarifEnfant);
      expect(b.remisesParRang, p.remisesParRang);
      expect(b.tauxEleveHeureAdulte, p.tauxEleveHeureAdulte);
      expect(b.cumulMaxPourMille, p.cumulMaxPourMille);
    });
  });

  group('accent de profil (FI15)', () {
    test('ne change pas quand l ordre de la liste change', () {
      final List<FinancesProfil> liste = DonneesFinanceDemo.profils(
        JeuFoyerFinance.cinqProfils,
      );
      final Map<String, String> avant = <String, String>{
        for (final FinancesProfil p in liste) p.profilId: p.cleAccent,
      };
      final List<FinancesProfil> inverse = liste.reversed.toList();
      final List<FinancesProfil> melange = <FinancesProfil>[
        ...liste.skip(2),
        ...liste.take(2),
      ];
      for (final List<FinancesProfil> autre in <List<FinancesProfil>>[
        inverse,
        melange,
      ]) {
        for (final FinancesProfil p in autre) {
          expect(p.cleAccent, avant[p.profilId]);
        }
      }
    });

    test('ne vient jamais de la position : la meme cle dans tous les jeux', () {
      final Map<String, String> vues = <String, String>{};
      for (final JeuFoyerFinance jeu in JeuFoyerFinance.values) {
        for (final FinancesProfil p in DonneesFinanceDemo.profils(jeu)) {
          vues.putIfAbsent(p.profilId, () => p.cleAccent);
          expect(p.cleAccent, vues[p.profilId], reason: jeu.name);
          expect(p.cleAccent, isNot(contains(RegExp(r'^\d+$'))));
        }
      }
      // Deux profils ne partagent jamais une cle.
      expect(vues.values.toSet().length, vues.length);
    });
  });

  group('six jeux du foyer (guide §8 F2)', () {
    test('les six jeux existent, avec 3, 3, 3, 2, 1 et 5 profils', () {
      expect(JeuFoyerFinance.values, hasLength(6));
      expect(
        <int>[
          for (final JeuFoyerFinance j in JeuFoyerFinance.values)
            DonneesFinanceDemo.profils(j).length,
        ],
        <int>[3, 3, 3, 2, 1, 5],
      );
    });

    test('Mariam au rang 1 : aucune remise (guide §5.2)', () {
      for (final JeuFoyerFinance jeu in JeuFoyerFinance.values) {
        final FinancesProfil m = _profil(jeu, DonneesFinanceDemo.mariamId);
        expect(
          m.lignesMensualite.map((LigneMensualite l) => l.nature),
          isNot(contains(NatureLigneMensualite.remiseRang)),
        );
        expect(m.mensualite, DonneesFinanceDemo.politiqueLancement.tarifEnfant);
      }
    });

    test('tous finances : rangs 2 et 3 ont leur remise ; un solde nul garde '
        'le mois', () {
      final FinancesFoyer f = DonneesFinanceDemo.finances(
        JeuFoyerFinance.tousFinances,
      );
      expect(f.synthese.profilsFinances, 3);
      expect(f.synthese.aPayerCeMois.estNul, isTrue);
      final FinancesProfil ibrahim = f.profils[1];
      // FI2 : accès par la période, jamais par `solde > 0`.
      expect(ibrahim.solde.estNul, isTrue);
      expect(ibrahim.etat, EtatFinancier.finance);
      expect(ibrahim.periode, isNotNull);
      expect(f.profils[0].mensualite, DonneesFinanceDemo.mensualiteRang(1));
      expect(f.profils[1].mensualite, DonneesFinanceDemo.mensualiteRang(2));
      expect(f.profils[2].mensualite, DonneesFinanceDemo.mensualiteRang(3));
      expect(
        f.profils[2].mensualite.mineur,
        lessThan(f.profils[1].mensualite.mineur),
      );
    });

    test('un a regulariser : le manque est dit, place conservee selon la '
        'politique', () {
      final FinancesProfil i = _profil(
        JeuFoyerFinance.unARegulariser,
        DonneesFinanceDemo.ibrahimId,
      );
      expect(i.etat, EtatFinancier.aRegulariser);
      expect(i.manque, DonneesFinanceDemo.manqueDemo);
      // FIN4-09 : aucun débit partiel, le solde reste entier : la mensualite
      // moins ce qu'il manque.
      expect(
        i.solde.mineur + i.manque!.mineur,
        DonneesFinanceDemo.mensualiteRang(2).mineur,
      );
      expect(i.periode, isNull);
      expect(
        i.finConservation!.difference(DonneesFinanceDemo.debutMois).inDays,
        DonneesFinanceDemo.politiqueLancement.joursConservationPlace,
      );
      expect(
        DonneesFinanceDemo.finances(JeuFoyerFinance.unARegulariser)
            .synthese
            .aPayerCeMois,
        DonneesFinanceDemo.manqueDemo,
      );
    });

    test(
      'un en essai : 1 essai, sans mensualite ni debit, hors rangs payants',
      () {
        final List<FinancesProfil> l = DonneesFinanceDemo.profils(
          JeuFoyerFinance.unEnEssai,
        );
        final FinancesProfil aicha = l.last;
        expect(aicha.etat, EtatFinancier.essai);
        expect(aicha.essaisUtilises, 1);
        expect(aicha.solde.estNul, isTrue);
        expect(aicha.prochainDebit, isNull);
        expect(aicha.lignesMensualite, isEmpty);
        // FIN4-15 : l'essai ne compte pas parmi les rangs payants. Les deux
        // autres membres restent aux rangs 1 et 2 : pas de remise au
        // premier, la remise du rang 2 au second, jamais celle du rang 3.
        expect(l.first.mensualite, DonneesFinanceDemo.mensualiteRang(1));
        expect(l[1].mensualite, DonneesFinanceDemo.mensualiteRang(2));
        expect(
          l.first.lignesMensualite.map((LigneMensualite x) => x.nature),
          isNot(contains(NatureLigneMensualite.remiseRang)),
        );
        expect(
          l[1].mensualite.mineur,
          greaterThan(DonneesFinanceDemo.mensualiteRang(3).mineur),
        );
      },
    );

    test('aucun paiement : rien de finance, aucun paiement du mois', () {
      final FinancesFoyer f = DonneesFinanceDemo.finances(
        JeuFoyerFinance.aucunPaiement,
      );
      expect(f.synthese.profilsFinances, 0);
      expect(f.synthese.paiementsDuMois, 0);
      expect(f.synthese.totalSoldes.estNul, isTrue);
      for (final FinancesProfil p in f.profils) {
        expect(p.periode, isNull);
        expect(p.manque, p.mensualite);
      }
    });

    test('cinq profils : du rang 3 au rang 5, la meme remise', () {
      final List<FinancesProfil> l = DonneesFinanceDemo.profils(
        JeuFoyerFinance.cinqProfils,
      );
      expect(l.map((FinancesProfil p) => p.mensualite).toList(), <Montant>[
        for (int rang = 1; rang <= 5; rang++)
          DonneesFinanceDemo.mensualiteRang(rang),
      ]);
      expect(l[2].mensualite, l[3].mensualite);
      expect(l[3].mensualite, l[4].mensualite);
    });

    test('la synthese est une lecture : la somme des soldes individuels', () {
      for (final JeuFoyerFinance jeu in JeuFoyerFinance.values) {
        final FinancesFoyer f = DonneesFinanceDemo.finances(jeu);
        expect(
          f.synthese.totalSoldes.mineur,
          f.profils.fold<int>(
            0,
            (int s, FinancesProfil p) => s + p.solde.mineur,
          ),
        );
        expect(f.synthese.profils, f.profils.length);
        for (final FinancesProfil p in f.profils) {
          expect(p.solde.devise, 'USD');
          expect(p.mensualite.devise, 'USD');
        }
      }
    });

    test('acces : sans montant ni cause, seances fermees sans periode', () {
      final List<AccesBeneficiaire> a = DonneesFinanceDemo.acces(
        JeuFoyerFinance.unARegulariser,
      );
      expect(a[0].seancesPayantesOuvertes, isTrue);
      expect(a[1].seancesPayantesOuvertes, isFalse);
      expect(a[1].motif, isNull);
      expect(a[1].statutServeur, isNull);
      final AccesBeneficiaire essai = DonneesFinanceDemo.acces(
        JeuFoyerFinance.unEnEssai,
      ).last;
      expect(essai.essaisUtilises, 1);
      expect(essai.essaisMax, DonneesFinanceDemo.essaisMaxJeuEssai);
    });

    // Revue FI-1c-R M1 : `sansEcheance` est le cas ordinaire d'un compte
    // valide, et la page Acces affiche « Actif » pour tout etat qui n'est pas
    // `expire`. Un profil payant sans periode financee ne peut donc etre ni
    // `sansEcheance` ni `actif`.
    test('acces : un profil payant non finance se lit « expire », dans '
        'chaque jeu ; seul l essai reste sans echeance', () {
      for (final JeuFoyerFinance jeu in JeuFoyerFinance.values) {
        final List<FinancesProfil> finances = DonneesFinanceDemo.profils(jeu);
        final List<AccesBeneficiaire> acces = DonneesFinanceDemo.acces(jeu);
        expect(acces, hasLength(finances.length), reason: jeu.name);
        for (int i = 0; i < finances.length; i++) {
          final FinancesProfil f = finances[i];
          final AccesBeneficiaire a = acces[i];
          final String cas = '${jeu.name} ${f.prenom}';
          expect(a.eleveId, f.profilId, reason: cas);
          expect(a.seancesPayantesOuvertes, f.periode != null, reason: cas);
          final EtatAccesAffiche attendu = switch (f) {
            FinancesProfil(etat: EtatFinancier.essai) =>
              EtatAccesAffiche.sansEcheance,
            FinancesProfil(periode: null) => EtatAccesAffiche.expire,
            _ => EtatAccesAffiche.actif,
          };
          expect(a.etatAffiche, attendu, reason: cas);
          // L'etat rendu est celui que les ecrans recalculent (DB-FOY-05).
          expect(
            a.etatAffiche,
            etatAccesAffiche(
              finAcces: a.finAcces,
              maintenantUtc: DonneesFinanceDemo.aujourdhui.toUtc(),
            ),
            reason: cas,
          );
        }
      }
      final AccesBeneficiaire ibrahim = DonneesFinanceDemo.acces(
        JeuFoyerFinance.unARegulariser,
      )[1];
      expect(ibrahim.etatAffiche, EtatAccesAffiche.expire);
      expect(ibrahim.finAcces, DonneesFinanceDemo.finDernierAcces);
    });
  });

  group('paiement : les huit etats en demonstration (FI9)', () {
    test('chaque etat a sa commande ; les soldes seulement a « termine »', () {
      for (final EtatPaiement e in EtatPaiement.values) {
        final SuiviPaiement s = DonneesFinanceDemo.suivi(
          DonneesFinanceDemo.commandeDemo(e),
        );
        expect(s.etat, e);
        expect(
          s.total.mineur,
          s.allocations.fold<int>(
            0,
            (int t, AllocationProfil a) => t + a.montant.mineur,
          ),
        );
        expect(
          s.allocations.fold<int>(
            0,
            (int t, AllocationProfil a) => t + a.montant.mineur,
          ),
          s.total.mineur,
        );
        final bool soldes = s.allocations.every(
          (AllocationProfil a) => a.nouveauSolde != null,
        );
        expect(soldes, e == EtatPaiement.termine, reason: e.name);
      }
      expect(EtatPaiement.values, hasLength(8));
    });

    test('une commande inconnue n est jamais un succes', () {
      expect(() => DonneesFinanceDemo.suivi('inconnue'), _indisponible);
    });
  });

  group('recharge par montants en demonstration (FI-7, guide §5.3)', () {
    test('les profils du jeu, leurs montants proposes, le manque suggere', () {
      final List<BeneficiaireRecharge> liste =
          DonneesFinanceDemo.beneficiairesRecharge(
            JeuFoyerFinance.unARegulariser,
          );
      expect(liste.map((BeneficiaireRecharge b) => b.id), <String>[
        DonneesFinanceDemo.mariamId,
        DonneesFinanceDemo.ibrahimId,
        DonneesFinanceDemo.aichaId,
      ]);
      final BeneficiaireRecharge ibrahim = liste[1];
      expect(ibrahim.montantSuggere, DonneesFinanceDemo.manqueDemo);
      expect(ibrahim.montantsProposes.first, DonneesFinanceDemo.manqueDemo);
      expect(liste.first.montantSuggere, isNull);
      // Entiers en unites mineures, jamais un double.
      for (final BeneficiaireRecharge b in liste) {
        for (final Montant m in b.montantsProposes) {
          expect(m.mineur, isA<int>());
          expect(m.devise, DonneesFinanceDemo.devise);
        }
      }
    });

    test(
      'deux montants choisis : le total est arrete par la demonstration',
      () {
        final RecapitulatifRecharge r =
            DonneesFinanceDemo.recapitulatifMontants(
              JeuFoyerFinance.tousFinances,
              <MontantRecharge>[
                MontantRecharge(
                  beneficiaireId: DonneesFinanceDemo.ibrahimId,
                  montant: DonneesFinanceDemo.usd(40),
                ),
                MontantRecharge(
                  beneficiaireId: DonneesFinanceDemo.mariamId,
                  montant: DonneesFinanceDemo.usd(10),
                ),
              ],
            );
        // Dans l'ordre du foyer, une ligne par profil.
        expect(
          r.lignes.map((LigneRecapitulatif l) => l.beneficiaireId),
          <String>[DonneesFinanceDemo.mariamId, DonneesFinanceDemo.ibrahimId],
        );
        expect(r.total, formaterMontant(DonneesFinanceDemo.usd(40 + 10)));
      },
    );

    test('un montant non propose, nul ou un profil inconnu est refuse', () {
      for (final List<MontantRecharge> choix in <List<MontantRecharge>>[
        const <MontantRecharge>[],
        <MontantRecharge>[
          MontantRecharge(
            beneficiaireId: DonneesFinanceDemo.mariamId,
            montant: DonneesFinanceDemo.usd(7),
          ),
        ],
        <MontantRecharge>[
          MontantRecharge(
            beneficiaireId: 'inconnu',
            montant: DonneesFinanceDemo.usd(10),
          ),
        ],
      ]) {
        expect(
          () => DonneesFinanceDemo.recapitulatifMontants(
            JeuFoyerFinance.tousFinances,
            choix,
          ),
          throwsArgumentError,
        );
      }
    });
  });

  group('revenus de l enseignant (guide §1.4)', () {
    final PolitiqueCommerciale pol = DonneesFinanceDemo.politiqueLancement;

    test('ancien taux (sans type de classe) : borne par la base et le '
        'plafond', () {
      expect(
        DonneesFinanceDemo.tauxEffectif(siegesEligibles: 5, capacite: 5),
        pol.plafondHoraire,
      );
      expect(
        DonneesFinanceDemo.tauxEffectif(siegesEligibles: 9, capacite: 5),
        pol.plafondHoraire,
      );
      expect(
        DonneesFinanceDemo.tauxEffectif(siegesEligibles: 0, capacite: 5),
        pol.baseHoraire,
      );
      expect(
        DonneesFinanceDemo.tauxEffectif(siegesEligibles: 4, capacite: 5).mineur,
        pol.baseHoraire.mineur +
            (pol.plafondHoraire.mineur - pol.baseHoraire.mineur) * 4 ~/ 5,
      );
    });

    // Revue FI-1c-R M2 : la vue globale additionnait le revenu d'un foyer et
    // la paie de treize sieges (marge 12 pour mille). Revenu et paie portent
    // maintenant sur les memes sieges.
    test('vue globale : revenu et paie sur les memes sieges', () {
      final RevenusEnseignant r = DonneesFinanceDemo.revenus();
      final VueGlobaleFinance v = DonneesFinanceDemo.vueGlobale();
      final int sieges = r.classes.fold<int>(
        0,
        (int s, RevenusClasse c) => s + c.siegesEligibles,
      );
      // An-Nour pleine, Al-Huda moins la place a regulariser, As-Salam au
      // minimum d'ouverture.
      expect(
        sieges,
        pol.capaciteEnfant + (pol.capaciteEnfant - 1) + pol.minimumOuverture,
      );
      final int enfants = r.classes
          .where((RevenusClasse c) => c.type == TypeClasseRevenus.enfants)
          .fold<int>(0, (int s, RevenusClasse c) => s + c.siegesEligibles);
      final int adultes = sieges - enfants;
      expect(
        v.revenuAcademique,
        Montant(
          enfants * pol.tarifEnfant.mineur + adultes * pol.tarifAdulte.mineur,
          'USD',
        ),
      );
      expect(v.paieEnseignants, r.totalEstime);
      // La paie : minutes assurees x taux effectif de la classe / 60.
      expect(
        v.paieEnseignants.mineur,
        r.classes.fold<int>(
          0,
          (int s, RevenusClasse c) =>
              s + c.minutesAssurees * c.tauxHoraireEffectif.mineur ~/ 60,
        ),
      );
      expect(
        v.margeProjeteePourMille,
        (v.revenuAcademique.mineur - v.paieEnseignants.mineur) *
            1000 ~/
            v.revenuAcademique.mineur,
      );
      expect(v.paieEnseignants.mineur, lessThan(v.revenuAcademique.mineur));
    });

    // Revue FI-1c-CORR-R m5 : l'impaye venait du foyer de demonstration
    // (jeu `unARegulariser`) quand revenu et paie venaient des classes de
    // l'enseignant : deux populations. Encaisse et impayes se lisent
    // maintenant sur les memes sieges que revenu et paie.
    test('vue globale : encaisse et impayes sur les memes sieges que le '
        'revenu et la paie', () {
      final VueGlobaleFinance v = DonneesFinanceDemo.vueGlobale();
      final RevenusEnseignant r = DonneesFinanceDemo.revenus();
      // L'encaisse est le debit des sieges finances : le revenu de ces
      // memes sieges, au centime pres.
      expect(v.encaisse, DonneesFinanceDemo.revenuDemo());
      expect(v.encaisse, v.revenuAcademique);
      // Les impayes sont les manques des sieges a regulariser des classes.
      expect(v.impayes, DonneesFinanceDemo.impayesDemo());
      expect(v.impayes, DonneesFinanceDemo.manqueDemo);
      // Le meme siege que le foyer : Ibrahim, a regulariser (FIN4-09).
      final FinancesProfil ibrahim = _profil(
        JeuFoyerFinance.unARegulariser,
        DonneesFinanceDemo.ibrahimId,
      );
      expect(v.impayes, ibrahim.manque);
      // L'alerte vise une classe de ces sieges et dit le meme montant.
      final Set<String> classes = <String>{
        for (final RevenusClasse c in r.classes) c.classe,
      };
      final Iterable<AlerteFinance> alertes = v.alertes.where(
        (AlerteFinance a) => a.nature == NatureAlerteFinance.aRegulariser,
      );
      expect(alertes, isNotEmpty);
      for (final AlerteFinance a in alertes) {
        expect(classes, contains(a.classe));
      }
      expect(
        alertes.fold<int>(0, (int s, AlerteFinance a) => s + a.montant!.mineur),
        v.impayes.mineur,
      );
      // Un siege a regulariser n'est pas eligible (guide §1.4) : Al-Huda
      // garde 4 sieges eligibles sur 5, le cinquieme est celui d'Ibrahim.
      final RevenusClasse huda = r.classes.firstWhere(
        (RevenusClasse c) => c.classe == ibrahim.classe,
      );
      expect(huda.siegesEligibles, 4);
      expect(huda.siegesEligibles, lessThan(huda.capacite));
    });

    // Revue FI-1c-CORR-R m6 : As-Salam est une classe d'adultes ;
    // Youssef (12 ans) et Khadija (13 ans) y etaient inscrits. Aucun total
    // ne change : les classes de l'enseignant ne lisent pas les profils du
    // foyer, seule l'inscription des deux enfants est corrigee.
    test('aucun profil mineur dans une classe d adultes', () {
      final Set<String> adultes = DonneesFinanceDemo.classesAdultesDemo();
      expect(adultes, <String>{'As-Salam'});
      for (final JeuFoyerFinance jeu in JeuFoyerFinance.values) {
        for (final FinancesProfil p in DonneesFinanceDemo.profils(jeu)) {
          final String cas = '${jeu.name} ${p.prenom}';
          expect(p.age, isNotNull, reason: cas);
          if (p.age! < 18) {
            expect(adultes, isNot(contains(p.classe)), reason: cas);
            expect(p.estAdulte, isFalse, reason: cas);
          }
        }
      }
      expect(
        _profil(
          JeuFoyerFinance.cinqProfils,
          DonneesFinanceDemo.youssefId,
        ).classe,
        'Al-Huda',
      );
      expect(
        _profil(
          JeuFoyerFinance.cinqProfils,
          DonneesFinanceDemo.khadijaId,
        ).classe,
        'Al-Huda',
      );
    });

    test('total = somme des classes, aide Internet a part', () {
      final RevenusEnseignant r = DonneesFinanceDemo.revenus();
      expect(r.classes, hasLength(3));
      expect(
        r.totalEstime.mineur,
        r.classes.fold<int>(
          0,
          (int s, RevenusClasse c) => s + c.montantEstime.mineur,
        ),
      );
      for (final RevenusClasse c in r.classes) {
        expect(c.siegesEligibles, lessThanOrEqualTo(c.capacite));
        expect(
          c.tauxHoraireEffectif.mineur,
          lessThanOrEqualTo(
            DonneesFinanceDemo.politiqueLancement.plafondHoraire.mineur,
          ),
        );
      }
    });
  });

  group(
    'ports : neutres en production, demonstration sur surcharge (K-09)',
    () {
      test(
        'chaque port Finance de production rend CapaciteIndisponible',
        () async {
          final ProviderContainer c = ProviderContainer();
          addTearDown(c.dispose);
          await expectLater(
            c.read(portPaiementsFoyerProvider).finances(),
            _indisponible,
          );
          await expectLater(
            c.read(portRechargeFoyerProvider).suivre('x'),
            _indisponible,
          );
          await expectLater(
            c
                .read(portRechargeFoyerProvider)
                .verifierMontants(const <MontantRecharge>[]),
            _indisponible,
          );
          await expectLater(
            c.read(portPolitiquesCommercialesProvider).active(),
            _indisponible,
          );
          await expectLater(
            c.read(portPolitiquesCommercialesProvider).versions(),
            _indisponible,
          );
          await expectLater(
            c.read(portRevenusEnseignantProvider).moisEnCours(),
            _indisponible,
          );
          await expectLater(
            c.read(portFinanceDirectionProvider).vueGlobale(),
            _indisponible,
          );
          await expectLater(
            c.read(portAccesFoyerProvider).acces(),
            _indisponible,
          );
        },
      );

      test('la demonstration surcharge les ports et rend ses jeux', () async {
        final ProviderContainer c = ProviderContainer(
          overrides: [
            portPaiementsFoyerProvider.overrideWithValue(
              const PaiementsFoyerFinanceDemo(JeuFoyerFinance.unProfil),
            ),
            portPolitiquesCommercialesProvider.overrideWithValue(
              const PolitiquesCommercialesDemo(),
            ),
            portPolitiqueFamilleProvider.overrideWithValue(
              const PolitiqueFamilleDemo(),
            ),
            portFinanceDirectionProvider.overrideWithValue(
              const FinanceDirectionDemo(),
            ),
            portRevenusEnseignantProvider.overrideWithValue(
              const RevenusEnseignantDemo(),
            ),
          ],
        );
        addTearDown(c.dispose);
        final FinancesFoyer f = await c
            .read(portPaiementsFoyerProvider)
            .finances();
        expect(f.profils.single.prenom, 'Mariam');
        expect(
          await c.read(portPolitiquesCommercialesProvider).active(),
          same(DonneesFinanceDemo.politiqueLancement),
        );
        final VueGlobaleFinance v = await c
            .read(portFinanceDirectionProvider)
            .vueGlobale();
        // FI21 : encaissement, revenu, paie, marge et soldes separes.
        expect(v.encaisse.devise, 'USD');
        expect(v.paieEnseignants.mineur, lessThan(v.revenuAcademique.mineur));
        expect(v.margeProjeteePourMille, isNotNull);
        // Contre-revue FI-DIR-1 : la vue globale lit le foyer ou Ibrahim est
        // a regulariser ; aucun de ses profils n est en essai.
        expect(v.essaisEnCours, 0);
        expect(
          (await c.read(portRevenusEnseignantProvider).moisEnCours()).classes,
          isNotEmpty,
        );
      });
    },
  );

  test('le garde-fou voit un montant ecrit en unites ou calcule (revue '
      'FI-3-R m5)', () {
    // Contre-epreuve : chaque ecriture doit etre vue, sinon le garde-fou
    // ci-dessous passerait a cote d'un montant recopie.
    for (final String ligne in <String>[
      'tarif: usd(50),',
      'Montant(50 * 100, devise)',
      "Montant(5000, 'USD')",
      "Text('50 USD')",
      "Text('50 \$')",
      "Text('-5 \$')",
      'remise: DonneesFinanceDemo.usd(-5),',
    ]) {
      expect(_montantEnDur.hasMatch(ligne), isTrue, reason: ligne);
    }
    for (final String ligne in <String>[
      'formaterMontant(finance.solde)',
      'Montant(-l.montant.mineur, devise)',
      'const Duration(minutes: 50)',
    ]) {
      expect(_montantEnDur.hasMatch(ligne), isFalse, reason: ligne);
    }
  });

  test('aucune valeur commerciale de la politique hors finance_demo.dart', () {
    // Les montants de la politique en unites mineures, et les anciens
    // montants a ne jamais recopier (guide §1.4, §2).
    final RegExp interdit = _montantEnDur;
    final List<String> fautes = <String>[];
    for (final FileSystemEntity f in Directory(
      'lib',
    ).listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      if (f.path.endsWith('.g.dart')) continue;
      if (f.path.endsWith('finance_demo.dart')) continue;
      // Les donnees de demonstration du Comptable (CPT-FUS) : comme
      // `finance_demo.dart`, des montants de demonstration ecrits dans leur
      // seul fichier (K-09), jamais une valeur de la politique commerciale.
      if (f.path.contains('lib/features/demo/comptable/')) continue;
      final List<String> lignes = f.readAsLinesSync();
      for (int i = 0; i < lignes.length; i++) {
        if (lignes[i].trimLeft().startsWith('//')) continue;
        if (interdit.hasMatch(lignes[i])) fautes.add('${f.path}:${i + 1}');
      }
    }
    // Seules les finances : un nombre ailleurs (durees, tailles) n'est pas
    // forcement commercial, on ne cible que les fichiers Finance.
    expect(
      fautes.where(
        (String l) =>
            l.contains('finance') ||
            l.contains('paiement') ||
            l.contains('recharge') ||
            l.contains('solde') ||
            l.contains('argent') ||
            l.contains('revenus') ||
            l.contains('foyer'),
      ),
      isEmpty,
    );
  });

  group('vue globale de demonstration : une seule population (contre-revue '
      'FI-DIR-1)', () {
    final VueGlobaleFinance v = DonneesFinanceDemo.vueGlobale();
    final List<FinancesProfil> foyer = DonneesFinanceDemo.profils(
      DonneesFinanceDemo.jeuVueGlobale,
    );
    int compte(EtatPaiementsProfils e) => v.etatPaiements
        .firstWhere((CompteEtatPaiements c) => c.etat == e)
        .profils;

    test('aucune personne n est a la fois en essai et dans un paiement', () {
      final Set<String> enEssai = <String>{
        for (final FinancesProfil p in foyer)
          if (p.etat == EtatFinancier.essai) p.profilId,
      };
      final Set<String> payeurs = <String>{
        for (final MouvementFoyer m in v.dernieresOperations) m.profilId,
      };
      expect(v.dernieresOperations, isNotEmpty);
      expect(enEssai.intersection(payeurs), isEmpty);
      // Chaque personne d une operation est un profil de la population.
      expect(
        payeurs.difference(<String>{
          for (final FinancesProfil p in foyer) p.profilId,
        }),
        isEmpty,
      );
    });

    test('les essais de la tuile et de l etat des paiements sont les memes, '
        'et ceux de la population', () {
      final int essais = foyer
          .where((FinancesProfil p) => p.etat == EtatFinancier.essai)
          .length;
      expect(v.essaisEnCours, essais);
      expect(compte(EtatPaiementsProfils.enEssai), v.essaisEnCours);
    });

    test('l alerte nomme un profil a regulariser de la population, compte '
        'dans l etat des paiements', () {
      for (final AlerteFinance a in v.alertes) {
        final FinancesProfil p = foyer.firstWhere(
          (FinancesProfil f) => f.prenom == a.prenom,
        );
        expect(p.etat, EtatFinancier.aRegulariser);
        expect(a.montant, p.manque);
      }
      expect(
        compte(EtatPaiementsProfils.aRegulariser),
        v.alertes
            .where(
              (AlerteFinance a) => a.nature == NatureAlerteFinance.aRegulariser,
            )
            .length,
      );
      expect(v.impayes, DonneesFinanceDemo.manqueDemo);
    });

    test('la classe de chaque personne nommee est dans Top classes', () {
      final Set<String> classes = <String>{
        for (final EncaissementClasse c in v.topClasses) c.classe,
      };
      for (final MouvementFoyer m in v.dernieresOperations) {
        final FinancesProfil p = foyer.firstWhere(
          (FinancesProfil f) => f.profilId == m.profilId,
        );
        expect(classes, contains(p.classe), reason: p.prenom);
      }
    });

    test('les soldes crediteurs sont ceux de la population', () {
      expect(
        v.soldesCrediteurs.mineur,
        foyer.fold<int>(0, (int s, FinancesProfil p) => s + p.solde.mineur),
      );
    });
  });

  group('etatPaiementsDemo et topClassesDemo (contre-revue FI-DIR-1)', () {
    final List<CompteEtatPaiements> etat =
        DonneesFinanceDemo.etatPaiementsDemo();
    final List<EncaissementClasse> top = DonneesFinanceDemo.topClassesDemo();

    // Les sieges eligibles des classes, et le siege a regulariser (Ibrahim).
    final int finances = DonneesFinanceDemo.revenus().classes.fold<int>(
      0,
      (int s, RevenusClasse c) => s + c.siegesEligibles,
    );
    const int aRegulariser = 1;

    test('les quatre etats, dans l ordre, aux nombres des sieges', () {
      expect(
        etat.map((CompteEtatPaiements c) => c.etat).toList(),
        EtatPaiementsProfils.values,
      );
      expect(etat.map((CompteEtatPaiements c) => c.profils).toList(), <int>[
        finances,
        aRegulariser,
        0,
        0,
      ]);
    });

    test('parts en pour mille : plus fort reste, somme exacte de 1000', () {
      expect(
        etat.map((CompteEtatPaiements c) => c.partPourMille).toList(),
        <int?>[
          ...DonneesFinanceDemo.partsPourMille(<int>[
            finances,
            aRegulariser,
            0,
            0,
          ])!,
        ],
      );
      expect(
        etat.fold<int>(
          0,
          (int s, CompteEtatPaiements c) => s + (c.partPourMille ?? 0),
        ),
        1000,
      );
    });

    test('partsPourMille : plus fort reste, somme 1000, total nul sans '
        'part', () {
      expect(DonneesFinanceDemo.partsPourMille(<int>[13, 1, 1, 0]), <int>[
        867,
        67,
        66,
        0,
      ]);
      expect(DonneesFinanceDemo.partsPourMille(<int>[1, 1, 1]), <int>[
        334,
        333,
        333,
      ]);
      expect(DonneesFinanceDemo.partsPourMille(<int>[0, 0]), isNull);
      for (final List<int> n in <List<int>>[
        <int>[13, 1, 1, 0],
        <int>[7, 3, 2],
        <int>[1, 1, 1, 1, 1, 1, 1],
      ]) {
        expect(
          DonneesFinanceDemo.partsPourMille(n)!
              .fold<int>(0, (int s, int p) => s + p),
          1000,
          reason: '$n',
        );
      }
    });

    test('Top classes : somme = encaisse, de la plus forte a la plus '
        'faible', () {
      final VueGlobaleFinance v = DonneesFinanceDemo.vueGlobale();
      expect(
        top.fold<int>(
          0,
          (int s, EncaissementClasse c) => s + c.encaisse.mineur,
        ),
        v.encaisse.mineur,
      );
      expect(
        v.topClasses.map((EncaissementClasse c) => c.classe).toList(),
        top.map((EncaissementClasse c) => c.classe).toList(),
      );
      for (int i = 1; i < top.length; i++) {
        expect(
          top[i - 1].encaisse.mineur,
          greaterThanOrEqualTo(top[i].encaisse.mineur),
        );
      }
      // Le tarif du public de la classe x ses sieges eligibles, la plus forte
      // d'abord.
      final PolitiqueCommerciale pol = DonneesFinanceDemo.politiqueLancement;
      final List<RevenusClasse> classes = DonneesFinanceDemo.revenus().classes;
      final Map<String, int> attendu = <String, int>{
        for (final RevenusClasse c in classes)
          c.classe:
              (c.type == TypeClasseRevenus.adultes
                      ? pol.tarifAdulte
                      : pol.tarifEnfant)
                  .mineur *
              c.siegesEligibles,
      };
      expect(
        top.map((EncaissementClasse c) => c.encaisse.mineur).toList(),
        attendu.values.toList()..sort((int a, int b) => b.compareTo(a)),
      );
      for (final EncaissementClasse c in top) {
        expect(c.encaisse.mineur, attendu[c.classe], reason: c.classe);
      }
    });
  });
}

const List<int> _anciensMontants = <int>[
  5000,
  6000,
  4500,
  4300,
  1450,
  1880,
  14500,
  18800,
];

/// Les montants, en unites mineures, de la politique de la demonstration.
List<int> _montantsDeLaPolitique() {
  final PolitiqueCommerciale p = DonneesFinanceDemo.politiqueLancement;
  return <int>[
    p.tarifEnfant.mineur,
    p.tarifAdulte.mineur,
    for (int rang = 2; rang <= 4; rang++) ...<int>[
      DonneesFinanceDemo.mensualiteRang(rang).mineur,
      DonneesFinanceDemo.mensualiteRang(rang, adulte: true).mineur,
    ],
  ];
}

/// Un montant ecrit en dur : les montants de la politique en unites
/// mineures, les anciens montants a ne jamais recopier (guide §1.4, §2), et
/// toute ecriture d'un montant en unites (revue FI-3-R m5) : `usd(50)`,
/// `Montant(50 * 100, ...)`, « 50 USD », « 50 $ ».
final RegExp _montantEnDur = RegExp(
  // Les anciens montants (v1), puis les montants de la politique de la
  // demonstration, lus dans l'objet : tarifs, mensualites des quatre premiers
  // rangs.
  '\\b(${_anciensMontants.followedBy(_montantsDeLaPolitique()).toSet().join('|')})\\b'
  r'|\busd\(\s*-?\d'
  r'|Montant\(\s*-?\d+\s*\*'
  r'|\b\d+(\s|\\u00A0)?(USD|EUR|GBP|XOF|GNF)\b'
  r'|\d(\s|\\u00A0)?\\?\$',
);
