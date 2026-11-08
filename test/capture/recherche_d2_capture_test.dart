// RECHERCHE-LIVRAISON, D2 (08/11/2026) : le matricule exact, sur le VRAI
// routeur et le VRAI branchement (`moteursRechercheProduction`) avec des ports
// qui rendent des donnees de test : la direction trouve un eleve par son
// matricule complet (prenom et matricule lisibles, ouvre la liste des comptes
// filtree), le meme vide pour un matricule inconnu, l'indication « matricule
// exact » pour un nom, une panne ; le
// tuteur retrouve un profil de son foyer par son prenom. Francais et arabe, a
// 390 et a 1440 de large.
//
// Saute sans CAPTURE_DIR. Usage :
//   CAPTURE_DIR=docs/current/captures/E2E/recherche-d2 flutter test \
//     --no-pub test/capture/recherche_d2_capture_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_acces_foyer.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/recherche/port_recherche.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_classe/roster_enseignant.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart'
    show AccesFoyerDemo;
import 'package:rewayah_academy/features/recherche/domaines/familles_eleves/port_resolution_ra.dart';
import 'package:rewayah_academy/features/recherche/ecran/ecran_recherche.dart'
    show cleChampRecherche;
import 'package:rewayah_academy/features/recherche/moteurs_production.dart';

import '../router/support_routeur.dart' hide stabiliser;
import '../support/harnais.dart';
import '../teaching_core/h/faux/faux_ports_externes.dart' show FauxRoster;
import 'outil_capture.dart';

class _Ra implements PortResolutionRa {
  const _Ra({this.panne = false});

  final bool panne;

  @override
  Future<ElevePourRa?> resoudre(String identifiantExact) async {
    if (panne) throw StateError('serveur indisponible');
    return identifiantExact == 'RA-26-4817'
        ? const ElevePourRa(eleveId: 'e-1', prenom: 'Yanis')
        : null;
  }
}

List<Override> _production({bool panne = false}) => <Override>[
  moteursRechercheProvider.overrideWith(moteursRechercheProduction),
  portResolutionRaProvider.overrideWithValue(_Ra(panne: panne)),
  portAccesFoyerProvider.overrideWithValue(const AccesFoyerDemo()),
  portRosterEnseignantProvider.overrideWithValue(FauxRoster()),
];

Future<void> _chercher(WidgetTester tester, String texte) async {
  await tester.enterText(find.byKey(cleChampRecherche), texte);
  await tester.pump(const Duration(milliseconds: 300));
  await stabiliser(tester);
}

void main() {
  group('Capture RECHERCHE-LIVRAISON D2', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

    int rang = 0;
    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final Size taille in <Size>[
        const Size(390, 844),
        const Size(1440, 900),
      ]) {
        final String code = langue.languageCode;
        final int largeur = taille.width.toInt();
        final TextDirection direction = langue == AppLocale.ar
            ? TextDirection.rtl
            : TextDirection.ltr;

        Future<void> monter(
          WidgetTester tester,
          AppRole role, {
          bool panne = false,
        }) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          await monterRouteur(
            tester,
            Routes.recherche,
            source: FausseSourceSession(sessionActive(role)),
            taille: taille,
            direction: direction,
            surcharges: _production(panne: panne),
          );
          await stabiliser(tester);
        }

        Future<void> photo(WidgetTester tester, String nom) async {
          rang++;
          debugPrint(
            'PNG ${await capturerVue(tester, '${rang.toString().padLeft(2, '0')}_${code}_${largeur}_$nom')}',
          );
        }

        testWidgets('$code $largeur : la direction trouve un matricule', (
          WidgetTester tester,
        ) async {
          await monter(tester, AppRole.admin);
          await _chercher(tester, 'RA-26-4817');
          expect(find.text('Yanis'), findsWidgets);
          expect(find.text('RA-26-4817'), findsWidgets);
          await photo(tester, 'direction_matricule_trouve');
        });

        testWidgets('$code $largeur : un matricule inconnu, le meme vide', (
          WidgetTester tester,
        ) async {
          await monter(tester, AppRole.admin);
          await _chercher(tester, 'RA-26-0000');
          await photo(tester, 'direction_matricule_inconnu');
        });

        testWidgets('$code $largeur : un nom tape par la direction', (
          WidgetTester tester,
        ) async {
          await monter(tester, AppRole.admin);
          await _chercher(tester, 'Yanis');
          expect(find.text(t.recherche.formeAttendue), findsOneWidget);
          expect(find.text(t.recherche.etats.vide.titre), findsNothing);
          await photo(tester, 'direction_nom_indication');
        });

        testWidgets('$code $largeur : une panne', (WidgetTester tester) async {
          await monter(tester, AppRole.admin, panne: true);
          await _chercher(tester, 'RA-26-4817');
          await photo(tester, 'direction_panne');
        });

        testWidgets('$code $largeur : le tuteur trouve un profil du foyer', (
          WidgetTester tester,
        ) async {
          await monter(tester, AppRole.guardian);
          await _chercher(tester, 'Aïcha');
          await photo(tester, 'tuteur_par_prenom');
        });
      }
    }
  });
}
