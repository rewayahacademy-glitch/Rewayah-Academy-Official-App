// Captures de CAHIER-C3-LISTE (07/11/2026) : a partir de la coupure, la liste
// « Cahiers a remplir » montre une ligne PAR SEANCE ; deux seances de la meme
// Classe font deux lignes, et la carte de la seance dit que le cahier se
// remplit apres chaque seance. 390x844 @3 et 1440x900 @1, en francais et en
// arabe.
//
// Saute sans CAPTURE_DIR : la CI ne l'execute jamais et n'ecrit rien.
// Mode d'emploi : `test/capture/LISEZ-MOI.md`. Donnees : fixtures synthetiques.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';
import 'package:rewayah_academy/core/i18n/elision.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/matching/service_matching.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/priere/service_priere.dart';
import 'package:rewayah_academy/core/regles/service_regles.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/video/pre_vol.dart';
import 'package:rewayah_academy/features/journee/journee_page.dart';

import '../support/harnais.dart';
import 'outil_capture.dart';

const SessionState _session = SessionState(
  resolue: true,
  role: AppRole.teacher,
  profileId: 't1',
  accountStatus: AccountStatus.active,
  lectureProfil: LectureProfil.presente,
);

final DateTime _maintenant = DateTime(2026, 11, 12, 18, 40);

CahierEnRetard _retard(String id, DateTime debut) => CahierEnRetard(
  seanceId: id,
  debut: debut,
  fin: debut.add(const Duration(minutes: 45)),
  nbParticipants: 4,
  heuresDeRetard: _maintenant.difference(debut).inHours,
  groupeId: 'g-an-nour',
  groupeLibelle: 'An-Nour',
  parSeance: true,
);

List<Override> _surcharges() => <Override>[
  sourceSessionProvider.overrideWithValue(FausseSourceSession(_session)),
  serviceEnseignantProvider.overrideWithValue(
    FauxServiceEnseignant()
      ..seancesRendues = <SeanceEnseignant>[
        seanceDeTest(
          id: 'an-nour-12',
          debut: DateTime(2026, 11, 12, 17, 30),
          statut: StatutSeance.terminee,
          nbParticipants: 4,
          groupeId: 'g-an-nour',
          groupeLibelle: 'An-Nour',
        ),
      ]
      ..retardsRendus = <CahierEnRetard>[
        _retard('an-nour-10', DateTime(2026, 11, 10, 17, 30)),
        _retard('an-nour-12', DateTime(2026, 11, 12, 17, 30)),
      ],
  ),
  serviceMatchingProvider.overrideWithValue(FauxServiceMatching()),
  serviceReglesProvider.overrideWithValue(FauxServiceRegles()),
  servicePriereProvider.overrideWithValue(FauxServicePriere()),
  servicePreVolProvider.overrideWithValue(FauxServicePreVol()),
  servicePresenceProvider.overrideWithValue(FauxServicePresence()),
  serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
  maintenantJourneeProvider.overrideWithValue(() => _maintenant),
];

void main() {
  group('Capture : CAHIER-C3-LISTE', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

    final List<(String, Widget)> ecrans = <(String, Widget)>[
      ('journee', const JourneePage()),
      ('a_terminer', const ListeATerminerPage()),
    ];

    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final (String nom, Widget ecran) in ecrans) {
        for (final (Size taille, double densite) in <(Size, double)>[
          (const Size(390, 844), 3),
          (const Size(1440, 900), 1),
        ]) {
          final String format =
              '${taille.width.toInt()}x${taille.height.toInt()}@${densite.toInt()}';
          testWidgets('$format, $nom, ${langue.languageCode}', (
            WidgetTester tester,
          ) async {
            await tester.runAsync(() => LocaleSettings.setLocale(langue));
            fixerVueCapture(tester, taille, densite);
            await tester.pumpWidget(
              hoteCapture(ecran, surcharges: _surcharges()),
            );
            await stabiliser(tester);
            final String ligne = t.enseignant.journee.cahierLigne(
              classe: deDevant('An-Nour'),
            );
            if (nom == 'a_terminer') {
              // Deux seances de la meme Classe : deux lignes.
              expect(find.text(ligne), findsNWidgets(2));
            } else {
              final String rappel = t.enseignant.journee
                  .cahierObligatoireSeance(
                    classe: deDevant(
                      'An-Nour',
                      cle: 'enseignant.journee.cahierObligatoireSeance',
                    ),
                  );
              // En arabe, la carte isole le detail entier (U+2068).
              expect(find.textContaining(rappel), findsOneWidget);
              await tester.ensureVisible(find.textContaining(rappel));
              await stabiliser(tester);
            }
            expect(tester.takeException(), isNull);
            debugPrint(
              'PNG ${await capturer(tester, 'c3l_${nom}_${format}_${langue.languageCode}')}',
            );
          });
        }
      }
    }
  });
}
