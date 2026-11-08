// Captures des dettes UI (agent F, 07/11/2026) : pave numerique non miroir,
// message du champ de confirmation vide, carte de fin de seance de
// l'enseignant avec son nom de Classe. 390 et 1440, francais et arabe.
//
// Saute sans CAPTURE_DIR (voir LISEZ-MOI.md du meme dossier).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/confirm_destructive.dart';
import 'package:rewayah_academy/core/widgets/pin_pad.dart';
import 'package:rewayah_academy/features/salle_seance/actions_seance.dart';
import 'package:rewayah_academy/features/salle_seance/resultat_seance.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../support/demo/seance_demo.dart';
import 'outil_capture.dart';

void _rien() {}
void _aller(String _) {}

const ActionsSeance _actions = ActionsSeance(
  onRetour: _rien,
  onNotifications: _rien,
  onReglages: _rien,
  onCompte: _rien,
  onNaviguer: _aller,
);

/// Demonte l'ecran et laisse passer les minuteries (un minuteur en attente
/// fait echouer le test).
Future<void> demonter(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  group('Capture : dettes UI', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final Size taille in const <Size>[Size(390, 844), Size(1440, 900)]) {
        final String suffixe = '${taille.width.toInt()}_${langue.languageCode}';

        Future<void> monter(WidgetTester tester, Widget ecran) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          addTearDown(() => unawaited(LocaleSettings.setLocale(AppLocale.fr)));
          fixerVueCapture(tester, taille, 2);
          await tester.pumpWidget(hoteCapture(ecran));
          await stabiliser(tester);
        }

        testWidgets('pave numerique $suffixe', (WidgetTester tester) async {
          await monter(
            tester,
            Scaffold(
              body: Center(
                child: SingleChildScrollView(
                  child: PinPad(onCodeComplet: (String _) {}),
                ),
              ),
            ),
          );
          await capturer(tester, 'pave_numerique_$suffixe');
          await demonter(tester);
        });

        testWidgets('champ vide $suffixe', (WidgetTester tester) async {
          final EtatSaisieConfirmation etat = EtatSaisieConfirmation()
            ..signaler();
          await monter(
            tester,
            Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(24),
                child: ConfirmDestructive(
                  question: 'Supprimer le profil de Yasmine ?',
                  consequence: 'Le profil ne peut plus se connecter.',
                  libelleConfirmer: 'Oui, supprimer Yasmine',
                  onConfirmer: _rien,
                  onAnnuler: _rien,
                  etatSaisie: etat,
                  saisie: const SaisieConfirmation(
                    attendu: 'Yasmine',
                    libelle: 'Prénom',
                    erreur: 'Ce n\'est pas le prénom Yasmine.',
                  ),
                ),
              ),
            ),
          );
          await capturer(tester, 'champ_vide_$suffixe');
          await demonter(tester);
        });

        testWidgets('fin de seance $suffixe', (WidgetTester tester) async {
          await monter(
            tester,
            FinSeanceEnseignant(
              vue: DonneesSeanceDemo.vue(
                RoleSeance.enseignant,
                EtatDemoSalle.fin,
              ),
              actions: _actions,
              onOuvrirCahier: _rien,
              onRevenirJournee: _rien,
            ),
          );
          await capturer(tester, 'fin_seance_$suffixe');
          await demonter(tester);
        });
      }
    }
  });
}
