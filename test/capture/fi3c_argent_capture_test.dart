// Captures FI-3c (revue FI-3-R, K-07, K-61) : les composants d'argent dans
// une carte, montants au bord de fin (M1), pastille « Essai : 1/2 » au ton
// neutre (M2, M3), grand montant d'un seul tenant (m1), moyen de paiement
// hors ligne (m3). 320 px texte x2, 390 px et 1440 px, clair et sombre, et
// 390 px en RTL.
//
// Saute sans CAPTURE_DIR : la CI ne l'execute jamais et n'ecrit rien. Mode
// d'emploi : `test/capture/LISEZ-MOI.md`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/finance/finances_profil.dart';
import 'package:rewayah_academy/core/finance/montant.dart';
import 'package:rewayah_academy/core/finance/politique_commerciale.dart';
import 'package:rewayah_academy/core/theme/accent_profil.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/avatar_tile.dart';
import 'package:rewayah_academy/core/widgets/badge_periode_financee.dart';
import 'package:rewayah_academy/core/widgets/identite_profil.dart';
import 'package:rewayah_academy/core/widgets/ligne_allocation.dart';
import 'package:rewayah_academy/core/widgets/ligne_finance.dart';
import 'package:rewayah_academy/core/widgets/ligne_moyen_paiement.dart';
import 'package:rewayah_academy/core/widgets/ligne_transaction.dart';
import 'package:rewayah_academy/core/widgets/montant_argent.dart';
import 'package:rewayah_academy/core/widgets/pastille_financiere.dart';
import 'package:rewayah_academy/core/widgets/resume_soldes.dart';

import 'outil_capture.dart';

Widget _planche(TextDirection sens) => Directionality(
  textDirection: sens,
  child: Scaffold(
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const AppCard(
              child: ResumeSoldes(
                synthese: SyntheseFoyer(
                  totalSoldes: Montant(-123456, 'USD'),
                  aPayerCeMois: Montant(800, 'USD'),
                  profilsFinances: 2,
                  profils: 3,
                  paiementsDuMois: 2,
                ),
              ),
            ),
            Ecart.vLg,
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                const PastilleFinanciere(
                  etat: EtatFinancier.essai,
                  essaisUtilises: 1,
                  essaisMax: 2,
                ),
                const PastilleFinanciere(etat: EtatFinancier.finance),
                const PastilleFinanciere(etat: EtatFinancier.aRegulariser),
                BadgePeriodeFinancee(
                  periode: PeriodeFinancee(
                    debut: DateTime(2026, 10),
                    fin: DateTime(2026, 10, 31, 12),
                  ),
                ),
              ],
            ),
            Ecart.vLg,
            const AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  LigneFinance(
                    libelle: 'Tarif enfant',
                    montant: Montant(5000, 'USD'),
                  ),
                  LigneFinance(
                    libelle: 'Remise familiale',
                    detail: '3e membre',
                    montant: Montant(-500, 'USD'),
                  ),
                  LigneFinance(
                    libelle: 'Taxe applicable',
                    montant: Montant(14320, 'USD'),
                    signe: true,
                  ),
                  LigneFinance(
                    libelle: 'Total à financer',
                    montant: Montant(14500, 'USD'),
                    total: true,
                  ),
                  LigneTransaction(
                    libelle: 'Recharge',
                    date: '4 octobre',
                    montant: Montant(9500, 'USD'),
                    statut: PastilleFinanciere(
                      etat: EtatFinancier.enConfirmation,
                    ),
                  ),
                  LigneTransaction(
                    libelle: "Période d'octobre",
                    date: '1er octobre',
                    montant: Montant(-5000, 'USD'),
                  ),
                  LigneAllocation(
                    prenom: 'Mariam',
                    detail: 'Octobre',
                    montant: Montant(5000, 'USD'),
                    avatar: BandeauProfil(
                      avatar: AvatarTile(
                        prenom: 'Mariam',
                        diametre: AppAvatar.moyen,
                      ),
                      diametre: AppAvatar.moyen,
                      accent: AccentProfil.lavande,
                    ),
                  ),
                ],
              ),
            ),
            Ecart.vLg,
            const Align(
              alignment: AlignmentDirectional.centerStart,
              child: MontantArgent(
                Montant(-123456, 'USD'),
                taille: TailleMontant.grand,
              ),
            ),
            Ecart.vLg,
            const LigneMoyenPaiement(rail: RailPaiement.webStripe),
          ],
        ),
      ),
    ),
  ),
);

void main() {
  group('Capture : composants d argent FI-3c', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
    });

    for (final ({String nom, Size taille, double echelle, TextDirection sens})
        vue
        in <({String nom, Size taille, double echelle, TextDirection sens})>[
          (
            nom: '320x2',
            taille: const Size(320, 2400),
            echelle: 2,
            sens: TextDirection.ltr,
          ),
          (
            nom: '390',
            taille: const Size(390, 1500),
            echelle: 1,
            sens: TextDirection.ltr,
          ),
          (
            nom: '1440',
            taille: const Size(1440, 1100),
            echelle: 1,
            sens: TextDirection.ltr,
          ),
          (
            nom: '390-rtl',
            taille: const Size(390, 1500),
            echelle: 1,
            sens: TextDirection.rtl,
          ),
        ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        testWidgets('${vue.nom}, ${mode.name}', (WidgetTester tester) async {
          fixerVueCapture(tester, vue.taille, vue.taille.width > 1000 ? 1 : 2);
          await tester.pumpWidget(
            hoteCapture(
              _planche(vue.sens),
              themeMode: mode,
              echelleTexte: vue.echelle,
            ),
          );
          await stabiliser(tester);
          expect(tester.takeException(), isNull);
          await capturer(tester, 'fi3c-argent_${vue.nom}_${mode.name}');
        });
      }
    }
  });
}
