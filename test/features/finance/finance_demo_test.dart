// FI-1c : la seule source des donnees de demonstration de la Finance
// (`lib/features/demo/finance_demo.dart`) et les ports neutres.
//
// Ce que ces tests prouvent : chaque valeur de la politique de lancement
// (guide Finance V4 §1) se lit depuis la demonstration ; l'accent d'un profil
// ne depend pas de sa place dans la liste ; les six jeux du guide F2 existent
// et respectent FI1 a FI4 ; les ports de production sont neutres
// (`CapaciteIndisponible`) ; aucune valeur commerciale n'est ecrite ailleurs
// dans `lib/`.

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/port_acces_foyer.dart';
import 'package:rewayah_academy/core/capacites/port_finance_direction.dart';
import 'package:rewayah_academy/core/capacites/port_paiements_foyer.dart';
import 'package:rewayah_academy/core/capacites/port_politiques_commerciales.dart';
import 'package:rewayah_academy/core/capacites/port_recharge_foyer.dart';
import 'package:rewayah_academy/core/capacites/port_revenus_enseignant.dart';
import 'package:rewayah_academy/core/finance/finances_profil.dart';
import 'package:rewayah_academy/core/finance/montant.dart';
import 'package:rewayah_academy/core/finance/mouvements_profil.dart';
import 'package:rewayah_academy/core/finance/politique_commerciale.dart';
import 'package:rewayah_academy/core/finance/suivi_paiement.dart';
import 'package:rewayah_academy/features/demo/finance_demo.dart';

Montant _usd(int unites) => Montant(unites * 100, 'USD');

Matcher get _indisponible => throwsA(isA<CapaciteIndisponible>());

FinancesProfil _profil(JeuFoyerFinance jeu, String id) =>
    DonneesFinanceDemo.profils(jeu)
        .firstWhere((FinancesProfil p) => p.profilId == id);

void main() {
  group('politique de lancement (guide §1), lue depuis la demonstration', () {
    final PolitiqueCommerciale p = DonneesFinanceDemo.politiqueLancement;

    test('tarifs : 50 USD enfant, 60 USD adulte, en unites mineures', () {
      expect(p.tarifEnfant, _usd(50));
      expect(p.tarifAdulte, _usd(60));
      expect(p.tarifEnfant.mineur, 5000);
      expect(p.tarifEnfant.devise, 'USD');
    });

    test('essai : 2 seances au plus', () {
      expect(p.essaisMax, 2);
    });

    test('remises : rangs 1 et 2 aucune, rang 3 = -5, rang 4 et plus = -7', () {
      expect(p.remisePourRang(1), isNull);
      expect(p.remisePourRang(2), isNull);
      expect(p.remisePourRang(3), _usd(-5));
      expect(p.remisePourRang(4), _usd(-7));
      expect(p.remisePourRang(5), _usd(-7));
      expect(p.remisePourRang(9), _usd(-7));
    });

    test('exemples du guide §1.3 : 145 USD pour 3, 188 USD pour 4', () {
      int total(int membres) {
        int somme = 0;
        for (int rang = 1; rang <= membres; rang++) {
          for (final LigneMensualite l in DonneesFinanceDemo.lignesPourRang(
            rang,
          )) {
            somme += l.montant.mineur;
          }
        }
        return somme;
      }

      expect(total(3), 14500);
      expect(total(4), 18800);
    });

    test('enseignants : base 4/h, plafond 7/h', () {
      expect(p.baseHoraire, _usd(4));
      expect(p.plafondHoraire, _usd(7));
    });

    test('capacites 5 / 6 / 4, minimum d ouverture 4', () {
      expect(p.capaciteEnfant, 5);
      expect(p.capaciteAdulte, 6);
      expect(p.capaciteDebutant, 4);
      expect(p.minimumOuverture, 4);
    });

    test('classes par enseignant : objectif 3, maximum 4', () {
      expect(p.classesObjectif, 3);
      expect(p.classesMax, 4);
    });

    test('place conservee 7 jours', () {
      expect(p.joursConservationPlace, 7);
    });

    test('marge de reference 30 / 35 / 40 %', () {
      expect(p.margeReferencePourMille.objectif, 300);
      expect(p.margeReferencePourMille.forte, 350);
      expect(p.margeReferencePourMille.stretch, 400);
    });

    test('rail WEB_STRIPE seul actif (FI10)', () {
      expect(p.railsActifs, <RailPaiement>{RailPaiement.webStripe});
    });

    test('version publiee et datee, sans aucune annee 2024', () {
      expect(p.statut, StatutPolitique.publiee);
      expect(p.version, isNotEmpty);
      expect(p.dateEffet.year, isNot(2024));
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

    test('Mariam au rang 1 : aucune remise, jamais « -5 » (guide §5.2)', () {
      for (final JeuFoyerFinance jeu in JeuFoyerFinance.values) {
        final FinancesProfil m = _profil(jeu, DonneesFinanceDemo.mariamId);
        expect(
          m.lignesMensualite.map((LigneMensualite l) => l.nature),
          isNot(contains(NatureLigneMensualite.remiseRang)),
        );
        expect(m.mensualite, _usd(50));
      }
    });

    test('tous finances : rang 3 a sa remise ; un solde nul garde le mois', () {
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
      expect(f.profils[2].mensualite, _usd(45));
    });

    test('un a regulariser : le manque est dit, place conservee 7 jours', () {
      final FinancesProfil i = _profil(
        JeuFoyerFinance.unARegulariser,
        DonneesFinanceDemo.ibrahimId,
      );
      expect(i.etat, EtatFinancier.aRegulariser);
      expect(i.manque, _usd(8));
      // FIN4-09 : aucun débit partiel, le solde reste entier.
      expect(i.solde, _usd(42));
      expect(i.periode, isNull);
      expect(
        i.finConservation!.difference(DonneesFinanceDemo.debutMois).inDays,
        7,
      );
      expect(
        DonneesFinanceDemo.finances(JeuFoyerFinance.unARegulariser)
            .synthese
            .aPayerCeMois,
        _usd(8),
      );
    });

    test('un en essai : 1/2, sans mensualite ni debit, hors rangs payants', () {
      final List<FinancesProfil> l = DonneesFinanceDemo.profils(
        JeuFoyerFinance.unEnEssai,
      );
      final FinancesProfil aicha = l.last;
      expect(aicha.etat, EtatFinancier.essai);
      expect(aicha.essaisUtilises, 1);
      expect(aicha.solde.estNul, isTrue);
      expect(aicha.prochainDebit, isNull);
      expect(aicha.lignesMensualite, isEmpty);
      // FIN4-15 : l'essai ne fait pas passer un autre membre au rang 3.
      for (final FinancesProfil p in l.take(2)) {
        expect(
          p.lignesMensualite.map((LigneMensualite x) => x.nature),
          isNot(contains(NatureLigneMensualite.remiseRang)),
        );
      }
    });

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

    test('cinq profils : rang 4 et 5 a -7 chacun', () {
      final List<FinancesProfil> l = DonneesFinanceDemo.profils(
        JeuFoyerFinance.cinqProfils,
      );
      expect(l.map((FinancesProfil p) => p.mensualite.mineur).toList(), <int>[
        5000,
        5000,
        4500,
        4300,
        4300,
      ]);
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
      expect(essai.essaisMax, 2);
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
        expect(s.total, _usd(50));
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
      expect(ibrahim.montantSuggere, DonneesFinanceDemo.usd(8));
      expect(ibrahim.montantsProposes.first, DonneesFinanceDemo.usd(8));
      expect(liste.first.montantSuggere, isNull);
      // Entiers en unites mineures, jamais un double.
      for (final BeneficiaireRecharge b in liste) {
        for (final Montant m in b.montantsProposes) {
          expect(m.mineur, isA<int>());
          expect(m.devise, DonneesFinanceDemo.devise);
        }
      }
    });

    test('Mariam +10, Ibrahim +40 : total 50 arrete par la demonstration', () {
      final RecapitulatifRecharge r = DonneesFinanceDemo.recapitulatifMontants(
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
      expect(r.lignes.map((LigneRecapitulatif l) => l.beneficiaireId), <String>[
        DonneesFinanceDemo.mariamId,
        DonneesFinanceDemo.ibrahimId,
      ]);
      expect(r.total, '50\u00a0\$');
    });

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
    test('taux plafonne, jamais au-dessus du plafond', () {
      expect(
        DonneesFinanceDemo.tauxEffectif(siegesEligibles: 5, capacite: 5),
        _usd(7),
      );
      expect(
        DonneesFinanceDemo.tauxEffectif(siegesEligibles: 9, capacite: 5),
        _usd(7),
      );
      expect(
        DonneesFinanceDemo.tauxEffectif(siegesEligibles: 0, capacite: 5),
        _usd(4),
      );
      expect(
        DonneesFinanceDemo.tauxEffectif(siegesEligibles: 4, capacite: 5),
        const Montant(640, 'USD'),
      );
    });

    // Revue FI-1c-R M2 : la vue globale additionnait le revenu d'un foyer et
    // la paie de treize sieges (marge 12 pour mille). Revenu et paie portent
    // maintenant sur les memes sieges.
    test('vue globale : revenu et paie sur les memes sieges', () {
      final PolitiqueCommerciale p = DonneesFinanceDemo.politiqueLancement;
      final RevenusEnseignant r = DonneesFinanceDemo.revenus();
      final VueGlobaleFinance v = DonneesFinanceDemo.vueGlobale();
      final int sieges = r.classes.fold<int>(
        0,
        (int s, RevenusClasse c) => s + c.siegesEligibles,
      );
      expect(sieges, 13);
      // 9 enfants a 50 et 4 adultes (As-Salam, capacite adulte) a 60.
      expect(
        v.revenuAcademique,
        Montant(9 * p.tarifEnfant.mineur + 4 * p.tarifAdulte.mineur, 'USD'),
      );
      expect(v.revenuAcademique, _usd(690));
      expect(v.paieEnseignants, r.totalEstime);
      expect(v.paieEnseignants, const Montant(14320, 'USD'));
      expect(
        v.margeProjeteePourMille,
        (v.revenuAcademique.mineur - v.paieEnseignants.mineur) *
            1000 ~/
            v.revenuAcademique.mineur,
      );
      expect(v.margeProjeteePourMille, 792);
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
      expect(v.encaisse, _usd(690));
      // Les impayes sont les manques des sieges a regulariser des classes.
      expect(v.impayes, DonneesFinanceDemo.impayesDemo());
      expect(v.impayes, _usd(8));
      // Le meme siege que le foyer : Ibrahim, 42 sur 50 (FIN4-09).
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

    // Revue FI-1c-CORR-R m6 : As-Salam est une classe d'adultes (60 USD) ;
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
      expect(v.impayes, _usd(8));
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

    test('les quatre etats, dans l ordre, aux nombres des sieges', () {
      expect(
        etat.map((CompteEtatPaiements c) => c.etat).toList(),
        EtatPaiementsProfils.values,
      );
      expect(etat.map((CompteEtatPaiements c) => c.profils).toList(), <int>[
        13,
        1,
        0,
        0,
      ]);
    });

    test('parts en pour mille : 929 et 71, somme exacte de 1000', () {
      expect(
        etat.map((CompteEtatPaiements c) => c.partPourMille).toList(),
        <int?>[929, 71, 0, 0],
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
      // An-Nour 5 x 50, As-Salam 4 x 60, Al-Huda 4 x 50.
      expect(top.map((EncaissementClasse c) => c.classe).toList(), <String>[
        'An-Nour',
        'As-Salam',
        'Al-Huda',
      ]);
      expect(top.map((EncaissementClasse c) => c.encaisse).toList(), <Montant>[
        _usd(250),
        _usd(240),
        _usd(200),
      ]);
    });
  });
}

/// Un montant ecrit en dur : les montants de la politique en unites
/// mineures, les anciens montants a ne jamais recopier (guide §1.4, §2), et
/// toute ecriture d'un montant en unites (revue FI-3-R m5) : `usd(50)`,
/// `Montant(50 * 100, ...)`, « 50 USD », « 50 $ ».
final RegExp _montantEnDur = RegExp(
  r'\b(5000|6000|4500|4300|1450|1880|14500|18800)\b'
  r'|\busd\(\s*-?\d'
  r'|Montant\(\s*-?\d+\s*\*'
  r'|\b\d+(\s|\\u00A0)?(USD|EUR|GBP|XOF|GNF)\b'
  r'|\d(\s|\\u00A0)?\\?\$',
);
