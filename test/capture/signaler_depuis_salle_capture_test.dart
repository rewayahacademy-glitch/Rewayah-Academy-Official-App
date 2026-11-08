// Captures de NON-BRANCHE-LIVRAISON 7 (08/11/2026) : dans la salle, la carte
// d'un eleve porte « Signaler un besoin » ; la feuille ouverte dit, sans
// reseau, que rien n'est parti. 390x844 @3 et 1440x900 @1, clair, francais
// et arabe. Donnees de test uniquement.
//
// Saute sans CAPTURE_DIR : la CI ne l'execute jamais et n'ecrit rien.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/tc_parcours/port_signalement.dart';
import 'package:rewayah_academy/features/fiche_groupe/fiche_eleve_enseignant.dart';
import 'package:rewayah_academy/features/salle_seance/actions_seance.dart';
import 'package:rewayah_academy/features/salle_seance/panneau_eleves.dart';
import 'package:rewayah_academy/features/salle_seance/signalement_seance.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../support/harnais.dart' show FauxServiceReseau;
import 'outil_capture.dart';

void main() {
  group(
    'Capture : NON-BRANCHE 7, signaler depuis la salle',
    skip: sautSansCapture,
    () {
      setUpAll(chargerPolicesDuDepot);

      for (final (Size taille, double densite) in <(Size, double)>[
        (const Size(390, 844), 3),
        (const Size(1440, 900), 1),
      ]) {
        final String format =
            '${taille.width.toInt()}x${taille.height.toInt()}@${densite.toInt()}';
        for (final AppLocale langue in <AppLocale>[
          AppLocale.fr,
          AppLocale.ar,
        ]) {
          final String l = langue.languageCode;
          testWidgets('$format, $l', (WidgetTester tester) async {
            await tester.runAsync(() => LocaleSettings.setLocale(langue));
            fixerVueCapture(tester, taille, densite);
            final String prenom = langue == AppLocale.ar ? 'ياسمين' : 'Yasmine';
            final VueSeance vue = VueSeance(
              role: RoleSeance.enseignant,
              nomClasse: 'An-Nour',
              nomEnseignant: langue == AppLocale.ar
                  ? 'السيدة أمينة'
                  : 'Sayyida Amina',
              initialesEnseignant: 'SA',
            );
            final bool ar = langue == AppLocale.ar;
            final EleveSeance eleve = EleveSeance(
              prenom: prenom,
              statut: StatutEleveSeance.connecte,
              id: 'RA-26-4817',
              fiche: FicheEleveSeance(
                niveau: ar ? 'الأساسيات' : 'Les bases',
                objectifActuel: ar ? 'يقرأ التنوين' : 'Lit le tanwin',
                derniereSeance: ar ? 'الصفحة 12' : 'Page 12',
                aReprendre: ar ? 'الصفحة 13' : 'Page 13',
                presenceRecente: ar ? '3 من 4' : '3 sur 4',
                travailActuel: ar ? 'لا شيء' : 'Aucun',
              ),
            );
            await tester.pumpWidget(
              hoteCapture(
                Builder(
                  builder: (BuildContext context) => Scaffold(
                    body: SafeArea(
                      child: Align(
                        alignment: AlignmentDirectional.topStart,
                        child: SizedBox(
                          width: taille.width < 600 ? taille.width : 400,
                          child: PanneauEleves(
                            eleves: <EleveSeance>[eleve],
                            large: taille.width >= 600,
                            actions: ActionsSeance(
                              onRappeler: (_) {},
                              onChoisirPourReciter: (_) {},
                              onSignaler: (EleveSeance e) => unawaited(
                                signalerDepuisSeance(
                                  context,
                                  e,
                                  vue,
                                  seanceId: 's1',
                                  groupeId: 'c1',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                surcharges: <Override>[
                  portSignalementProvider.overrideWithValue(
                    SignalementMemoire('enseignant-test'),
                  ),
                  serviceReseauProvider.overrideWithValue(
                    FauxServiceReseau(horsLigneRendu: true),
                  ),
                ],
              ),
            );
            await stabiliser(tester);
            // La carte du premier eleve connecte est depliee d'office.
            expect(tester.takeException(), isNull);
            debugPrint(
              'PNG ${await capturer(tester, 'sig_${format}_${l}_tuile')}',
            );

            await tester.tap(find.text(t.salle.seance.signalerBesoin).first);
            await stabiliser(tester);
            await tester.tap(find.text(CategorieBesoin.pedagogique.libelle));
            await tester.enterText(
              find.byKey(SignalerBesoin.detailsKey),
              langue == AppLocale.ar
                  ? 'تفقد التركيز بعد الصفحة الثانية'
                  : 'Perd le fil après la deuxième page',
            );
            await stabiliser(tester);
            final Finder envoyer = find.byKey(SignalerBesoin.envoyerKey);
            await tester.ensureVisible(envoyer);
            await tester.tap(envoyer);
            await stabiliser(tester);
            expect(find.byKey(SignalerBesoin.echecKey), findsOneWidget);
            await tester.ensureVisible(find.byKey(SignalerBesoin.echecKey));
            await stabiliser(tester);
            expect(tester.takeException(), isNull);
            debugPrint(
              'PNG ${await capturer(tester, 'sig_${format}_${l}_hors_ligne')}',
            );
            await tester.pumpWidget(const SizedBox());
            await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.fr));
          });
        }
      }
    },
  );
}
