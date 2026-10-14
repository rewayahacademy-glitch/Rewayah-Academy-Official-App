// Captures de recette de LIB-LOT3-2 : vraies polices, vrai theme.
//
// - la feuille « Ajuster » du cahier de transmission pour un prenom a voyelle
//   (« Objectif d'Aya », « Ce qu'Aya doit atteindre », « Devoir d'Aya ») ;
// - la journee quand seuls les cahiers en retard n'ont pas pu etre lus (le
//   texte nomme les cahiers, pas les horaires de priere).
//
// 390, 1440, puis 320 a texte x2 ; clair et sombre. Aucun mot coupe.
//
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`). Sortie versionnee
// dans `docs/current/captures/LIB-LOT3-2/`. Donnees : fixtures synthetiques.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/depot_cahiers.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';
import 'package:rewayah_academy/core/matching/service_matching.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/priere/service_priere.dart';
import 'package:rewayah_academy/core/regles/service_regles.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/video/pre_vol.dart';
import 'package:rewayah_academy/features/cahier/cahier_page.dart';
import 'package:rewayah_academy/features/cahier/vue_cahier.dart';
import 'package:rewayah_academy/features/demo/demo_enseignant_page.dart';
import 'package:rewayah_academy/features/demo/enseignant_demo.dart';
import 'package:rewayah_academy/features/journee/journee_page.dart';

import '../support/aucun_mot_coupe.dart';
import '../support/harnais.dart';
import 'outil_capture.dart';

const String _monId = 't1';

const SessionState _session = SessionState(
  resolue: true,
  role: AppRole.teacher,
  profileId: _monId,
  accountStatus: AccountStatus.active,
  lectureProfil: LectureProfil.presente,
);

class _RetardsEnEchec extends FauxServiceEnseignant {
  @override
  Future<List<CahierEnRetard>> cahiersEnRetard() async =>
      throw StateError('cahiers en retard indisponibles');
}

BrouillonCahier _brouillonAvecAya() {
  final BrouillonCahier b = DonneesEnseignantDemo.brouillonCahier();
  return BrouillonCahier(
    seanceId: b.seanceId,
    debut: b.debut,
    fin: b.fin,
    statut: b.statut,
    dureeMinutes: b.dureeMinutes,
    minutesInterruption: b.minutesInterruption,
    dejaDepose: false,
    groupeId: b.groupeId,
    participants: <ParticipantBrouillon>[
      const ParticipantBrouillon(
        membre: MembreSeance(
          studentId: 'e-aya',
          identifiantImmuable: 'RA-AYA',
          prenom: 'Aya',
        ),
        presence: EtatPresence.presente,
      ),
      b.participants.first,
    ],
    evenements: b.evenements,
  );
}

typedef _Vue = ({String nom, Size taille, double echelle});

const List<_Vue> _vues = <_Vue>[
  (nom: '390', taille: Size(390, 844), echelle: 1),
  (nom: '1440', taille: Size(1440, 900), echelle: 1),
  (nom: '320_x2', taille: Size(320, 900), echelle: 2),
];

void main() {
  group('Capture : LIB-LOT3-2', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final _Vue vue in _vues) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String suffixe = '${vue.nom}_${mode.name}';

        testWidgets('cahier, feuille Ajuster d\'Aya, $suffixe', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, vue.taille, 1);
          await tester.pumpWidget(
            hoteCapture(
              const CahierPage(
                seanceId: DonneesEnseignantDemo.cahierDemoSeanceId,
              ),
              surcharges: <Override>[
                ...surchargesCoquilleEnseignantDemo(EtatDemoEnseignant.nominal),
                soumissionCahierProvider.overrideWithValue(
                  const SoumissionCahierDemo(),
                ),
                horlogeCahierProvider.overrideWithValue(
                  () => DonneesEnseignantDemo.maintenant,
                ),
                brouillonCahierProvider(
                  DonneesEnseignantDemo.cahierDemoSeanceId,
                ).overrideWith((Ref _) async => _brouillonAvecAya()),
                depotRapportsProvider.overrideWithValue(FauxDepotRapports()),
              ],
              themeMode: mode,
              echelleTexte: vue.echelle,
            ),
          );
          await stabiliser(tester);
          await tester.ensureVisible(find.text('Aya'));
          await stabiliser(tester);
          await tester.tap(find.text('Aya'));
          await stabiliser(tester);
          await tester.pump(const Duration(milliseconds: 700));
          await stabiliser(tester);
          expect(find.text("Objectif d'Aya"), findsOneWidget);
          expect(find.text("Devoir d'Aya"), findsOneWidget);
          final List<String> fautes = motsCoupes(
            tester,
            find.byType(FeuilleAjusterCahier),
            traitDUnionPermis: true,
          );
          // La feuille seule (la page derriere porte un texte tronque a 320 x2, hors
          // de cette etape). Les paires arabes isolees des makharij (U+2067) se coupent en deux
          // lignes par conception (test cahier_en7c) : hors de cette etape.
          fautes.removeWhere((String m) => m.contains('\u2067'));
          if (fautes.isNotEmpty) {
            debugPrint('FAUTES ${fautes.toSet().join(' | ')}');
          }
          expect(fautes, isEmpty, reason: 'Un mot coupe ou tronque');
          // La feuille defile : une capture sur « Objectif », une sur « Devoir ».
          await tester.ensureVisible(
            find.byKey(const ValueKey<String>('cahier-objectif')),
          );
          await stabiliser(tester);
          debugPrint('PNG ${await capturer(tester, 'cahier_aya_$suffixe')}');
          await tester.ensureVisible(
            find.byKey(const ValueKey<String>('cahier-devoir')),
          );
          await stabiliser(tester);
          debugPrint(
            'PNG ${await capturer(tester, 'cahier_aya_devoir_$suffixe')}',
          );
        });

        testWidgets('journee, echec des seuls cahiers, $suffixe', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, vue.taille, 1);
          await tester.pumpWidget(
            hoteCapture(
              const JourneePage(),
              surcharges: <Override>[
                sourceSessionProvider.overrideWithValue(
                  FausseSourceSession(_session),
                ),
                serviceEnseignantProvider.overrideWithValue(_RetardsEnEchec()),
                serviceMatchingProvider.overrideWithValue(
                  FauxServiceMatching(),
                ),
                serviceReglesProvider.overrideWithValue(FauxServiceRegles()),
                servicePriereProvider.overrideWithValue(FauxServicePriere()),
                servicePreVolProvider.overrideWithValue(FauxServicePreVol()),
                servicePresenceProvider.overrideWithValue(
                  FauxServicePresence(),
                ),
                serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
                maintenantJourneeProvider.overrideWithValue(
                  () => DateTime(2026, 9, 28, 16),
                ),
              ],
              themeMode: mode,
              echelleTexte: vue.echelle,
            ),
          );
          await stabiliser(tester);
          expect(
            find.byKey(const ValueKey<String>('journee-erreur-partielle')),
            findsOneWidget,
          );
          // Le message d'echec se lit dans la capture, meme a 320 x2.
          await tester.ensureVisible(
            find.byKey(const ValueKey<String>('journee-erreur-partielle')),
          );
          await stabiliser(tester);
          final List<String> fautes = motsCoupes(
            tester,
            find.byKey(cadreCapture),
            traitDUnionPermis: true,
          );
          if (fautes.isNotEmpty) {
            debugPrint('FAUTES ${fautes.toSet().join(' | ')}');
          }
          expect(fautes, isEmpty, reason: 'Un mot coupe ou tronque');
          debugPrint(
            'PNG ${await capturer(tester, 'journee_erreur_cahiers_$suffixe')}',
          );
        });
      }
    }
  });
}
