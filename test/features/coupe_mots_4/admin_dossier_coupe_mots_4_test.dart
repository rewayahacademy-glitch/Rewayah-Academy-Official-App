// COUPE-MOTS-4, appelants Administration et Dossier de `ChoiceCardGroup` :
// depot de la piece d'identite (type de piece) et feuille d'une regle d'un
// eleve (« Pourquoi ce changement ? », valeur proposee). 320 px, texte x2,
// francais (LTR) et arabe (RTL), Interface standard et guidee : aucun mot
// coupe sur l'ecran entier (cartes, valeurs « Plateforme : 60 min », textes
// de la piece), aucune ponctuation haute seule a la ligne.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/selecteur_fichier.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/regles/service_regles.dart';
import 'package:rewayah_academy/features/admin_demandes/demandes_page.dart';
import 'package:rewayah_academy/features/dossier/depot_piece_page.dart';

import '../../support/aucun_mot_coupe.dart';
import '../../support/harnais.dart';
import 'support_coupe_mots_4.dart';

FauxServiceRegles _regles() =>
    FauxServiceRegles()
      ..parProfil['e1'] = const <RegleProfil>[
        RegleProfil(
          cle: CleRegle.dureeSeance,
          valeurEffective: 45,
          valeurPlateforme: 60,
        ),
        RegleProfil(
          cle: CleRegle.minimumPayable,
          valeurEffective: 45,
          valeurPlateforme: 45,
        ),
        RegleProfil(
          cle: CleRegle.pauseEntreCours,
          valeurEffective: 30,
          valeurPlateforme: 30,
        ),
      ];

void main() {
  preparerCoupeMots4();

  for (final AppLocale langue in languesCoupeMots4) {
    for (final InterfaceMode interface in interfacesCoupeMots4) {
      final String cas = '${langue.name} ${nomInterface(interface)} 320 x2';

      testWidgets('$cas : depot de la piece', (WidgetTester tester) async {
        await monterCoupeMots4(
          tester,
          () => const DepotPiecePage(),
          langue: langue,
          interface: interface,
          surcharges: <Override>[
            serviceDossierProvider.overrideWithValue(FauxServiceDossier()),
            selecteurFichierProvider.overrideWithValue(
              FauxSelecteurFichier(null),
            ),
          ],
        );
        await tester.pumpAndSettle();
        verifierCartesDeChoixEntieres(tester);
      });

      testWidgets('$cas : feuille d une regle', (WidgetTester tester) async {
        await monterCoupeMots4(
          tester,
          () => const Scaffold(
            body: FeuilleRegles(profilId: 'e1', prenom: 'Aissatou'),
          ),
          langue: langue,
          interface: interface,
          surcharges: <Override>[
            serviceReglesProvider.overrideWithValue(_regles()),
          ],
        );
        await tester.pumpAndSettle();
        // La feuille des regles elle-meme, avant toute feuille ouverte :
        // « Plateforme : 60 min » ne laisse ni « Plateforme » coupe ni le
        // « : » seul a la ligne (relecture adverse du lot 4).
        expect(find.textContaining('60'), findsWidgets);
        verifierEcranEntierCoupeMots4(tester);
        final Finder changer = find.text(t.admin.demandes.changer).first;
        await tester.ensureVisible(changer);
        await tester.pumpAndSettle();
        await tester.tap(changer);
        await tester.pumpAndSettle();
        verifierCartesDeChoixEntieres(tester);
        expect(find.text(t.admin.demandes.poserMotif), findsWidgets);
        // L'ecran entier et la feuille ouverte (verifierCartesDeChoixEntieres).
        // Ligne visuelle RTL non lue : la feuille n'est pas traduite en
        // arabe (repli francais, `ecransTraduitsEnArabe`).
        expect(
          ponctuationsIsolees(
            tester,
            find.byType(BottomSheet),
            ligneVisuelleRtl: false,
          ),
          isEmpty,
        );
      });
    }
  }
}
