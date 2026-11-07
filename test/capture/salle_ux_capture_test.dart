// SALLE-UX (rang 15) : les ecrans de fin de la salle, rendus par les vrais
// composants, FR et AR, 390 et 1440. Prefixe des PNG : `salle_ux_`. Saute
// sans CAPTURE_DIR.
//
// - UX-039 : l'eleve en Interface guidee (ou le tuteur qui l'accompagne)
//   apres « Quitter » : « Vous avez quitte la seance. » et « Retourner dans
//   la salle », jamais « La seance est terminee. ».
// - UX-040 : l'enseignant apres « Quitter » : ni « Seance terminee » ni la
//   pastille « Terminee ».
// - UX-043 : l'enseignant, seance close par le serveur : aucun « Retourner
//   dans la salle », le cahier est l'action pleine.
//
// Ce ne sont pas les captures du robot de la pile locale (R3).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/salle_seance/actions_seance.dart';
import 'package:rewayah_academy/features/salle_seance/resultat_seance.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../support/demo/seance_demo.dart';
import 'outil_capture.dart';

void _rien() {}

VueSeance _vueFin({required bool close}) {
  final VueSeance base = DonneesSeanceDemo.vue(
    RoleSeance.enseignant,
    EtatDemoSalle.fin,
  );
  return base.copyWith(
    fin: FinSeance(
      heureFin: base.fin!.heureFin,
      cahierACompleter: true,
      close: close,
    ),
  );
}

void main() {
  group('Capture : SALLE-UX', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
      await LocaleSettings.setLocale(AppLocale.ar);
      await LocaleSettings.setLocale(AppLocale.fr);
    });

    final Map<String, (Widget, InterfaceMode)> ecrans =
        <String, (Widget, InterfaceMode)>{
          'ux039_guidee_apres_quitter': (
            const ResultatSeance(
              issue: IssueSeance.quittee,
              onRetour: _rien,
              onRevenir: _rien,
              onAccueil: _rien,
            ),
            InterfaceMode.enfant,
          ),
          'ux040_enseignant_apres_quitter': (
            FinSeanceEnseignant(
              vue: _vueFin(close: false),
              actions: const ActionsSeance(onRetour: _rien),
              onOuvrirCahier: _rien,
              onRevenirJournee: _rien,
              onRetournerSalle: _rien,
            ),
            InterfaceMode.standard,
          ),
          'ux043_enseignant_seance_close': (
            FinSeanceEnseignant(
              vue: _vueFin(close: true),
              actions: const ActionsSeance(onRetour: _rien),
              onOuvrirCahier: _rien,
              onRevenirJournee: _rien,
            ),
            InterfaceMode.standard,
          ),
        };

    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final Size taille in <Size>[
        const Size(390, 844),
        const Size(1440, 900),
      ]) {
        ecrans.forEach((String nom, (Widget, InterfaceMode) ecran) {
          final String fichier =
              'salle_ux_${nom}_${taille.width.toInt()}_${langue.languageCode}';
          testWidgets(fichier, (WidgetTester tester) async {
            LocaleSettings.setLocaleSync(langue);
            addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
            fixerVueCapture(tester, taille, 1);
            await tester.pumpWidget(
              hoteCapture(ecran.$1, interfaceMode: ecran.$2),
            );
            await stabiliser(tester);
            debugPrint('PNG ${await capturer(tester, fichier)}');
          });
        });
      }
    }
  });
}
