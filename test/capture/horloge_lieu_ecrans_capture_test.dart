// HORLOGE-ET-LIEU (R3, directeur, 01/11/2026) : trois autres familles d'ecrans
// que le lot change.
//
//   - la page des offres horaires de la famille, ecran entier, avec la ligne
//     d'apercu sous l'offre ;
//   - le centre de notifications : l'annonce d'un changement d'heure (famille)
//     et le refus de conversion d'une classe (direction), avec le texte reel
//     de `contenuNotificationPour` ;
//   - « Ma journee » de l'enseignant quand il n'a rien aujourd'hui : le jour et
//     l'heure de son prochain cours, au fuseau de son profil.
//
// 390 et 1440 de large, clair et sombre, francais et arabe. Sans CAPTURE_DIR
// ces tests sont sautes (test/capture/LISEZ-MOI.md).
//
//   CAPTURE_DIR=docs/current/captures/E2E/horloge-lieu \
//     flutter test test/capture/horloge_lieu_ecrans_capture_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_notifications.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/depot_cahiers.dart'
    show cahiersEnFileProvider;
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/offres/offre_horaire.dart';
import 'package:rewayah_academy/core/offres/service_offres.dart';
import 'package:rewayah_academy/core/priere/service_priere.dart'
    show pausePrevueProvider;
import 'package:rewayah_academy/core/regles/service_regles.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/tc_horloge/apercu_creneau.dart';
import 'package:rewayah_academy/core/tc_horloge/apercu_offre.dart';
import 'package:rewayah_academy/core/tc_horloge/mon_horloge.dart';
import 'package:rewayah_academy/features/journee/journee_page.dart';
import 'package:rewayah_academy/features/notifications/contenu_notification.dart';
import 'package:rewayah_academy/features/parcours_offres/parcours_offres_page.dart';

import '../parcours/faux_service_offres.dart';
import '../router/support_routeur.dart' hide stabiliser;
import '../support/harnais.dart';
import 'outil_capture.dart';

class _PortApercu implements PortApercuOffre {
  @override
  Future<ApercuCreneau?> lire({
    required String offreId,
    required String fuseau,
  }) async => ApercuCreneau.lire(<String, Object?>{
    'jour_maintenant': 1,
    'maintenant': '18:00',
    'meme': false,
    'date_changement': '2027-03-28',
    'jour_apres': 1,
    'heure_apres': '19:00',
  });
}

class _Notifications implements PortNotifications {
  _Notifications(this.rendues);

  final List<NotificationTuteur> rendues;

  @override
  Future<List<NotificationTuteur>> liste() async => rendues;

  @override
  Future<NotificationTuteur?> detail(String id) async =>
      rendues.where((NotificationTuteur n) => n.id == id).firstOrNull;
}

const Map<String, Object?> _riyad = <String, Object?>{
  'fuseau': 'Asia/Riyadh',
  'decalage_secondes': 10800,
  'prochain_changement': null,
};

MonHorloge _horloge(Map<String, Object?> moi) =>
    MonHorloge.lire(<String, Object?>{
      'maintenant': '2026-11-12T05:00:00Z',
      'moi': moi,
      'academie': _riyad,
    });

/// Les variantes communes : largeur, theme, langue.
final List<(double, bool, bool)> _variantes = <(double, bool, bool)>[
  for (final double l in <double>[390, 1440])
    for (final bool clair in <bool>[true, false])
      for (final bool arabe in <bool>[false, true]) (l, clair, arabe),
];

String _suffixe((double, bool, bool) v) =>
    '${v.$1.toInt()}_${v.$2 ? 'clair' : 'sombre'}_${v.$3 ? 'ar' : 'fr'}';

void main() {
  group('Capture : HORLOGE-ET-LIEU, autres ecrans', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
      await LocaleSettings.setLocale(AppLocale.ar);
      await LocaleSettings.setLocale(AppLocale.en);
      await LocaleSettings.setLocale(AppLocale.fr);
    });
    setUp(masquerRubanDebug);
    tearDown(() {
      poserMonHorlogePourTest(null);
      LocaleSettings.setLocaleSync(AppLocale.fr);
    });

    // ------------------------------------------------------------------
    // La page des offres horaires, ecran entier.
    // ------------------------------------------------------------------
    for (final (double, bool, bool) v in _variantes) {
      final String nom = 'horloge_lieu_page_offres_${_suffixe(v)}';
      testWidgets(nom, (WidgetTester tester) async {
        if (v.$3) LocaleSettings.setLocaleSync(AppLocale.ar);
        fixerVueCapture(tester, Size(v.$1, v.$1 > 600 ? 900 : 1400), 1);
        final FauxServiceOffres faux = FauxServiceOffres(
          parcoursRendu: <ParcoursApprenant>[
            apprenantDeTest(
              cohorte: 'enfant_8_10',
              langue: 'francais',
              onboardingFaitLe: DateTime(2026, 9, 20, 10),
              fuseauFoyer: 'Europe/Paris',
            ),
          ],
          offresRendues: <OffreHoraire>[
            offreDeTest(),
            offreDeTest(
              id: 'o2',
              creneaux: const <CreneauVu>[
                CreneauVu(jourIso: 2, heure: 17),
                CreneauVu(jourIso: 4, heure: 17),
              ],
              heureSource: 17,
            ),
          ],
        );
        await tester.pumpWidget(
          hoteCapture(
            const ParcoursOffresPage(eleveId: 'e1'),
            surcharges: <Override>[
              serviceOffresProvider.overrideWithValue(faux),
              portApercuOffreProvider.overrideWithValue(_PortApercu()),
            ],
            themeMode: v.$2 ? ThemeMode.light : ThemeMode.dark,
          ),
        );
        await stabiliser(tester);
        debugPrint('PNG ${await capturerVue(tester, nom)}');
      });
    }

    // ------------------------------------------------------------------
    // Le centre de notifications : annonce (famille) et refus (direction).
    // ------------------------------------------------------------------
    for (final (double, bool, bool) v in _variantes) {
      for (final (String quoi, AppRole role, String chemin)
          in <(String, AppRole, String)>[
            ('annonce', AppRole.guardian, Routes.tuteurNotifications),
            ('refus', AppRole.admin, Routes.adminNotifications),
          ]) {
        final String nom = 'horloge_lieu_notifications_${quoi}_${_suffixe(v)}';
        testWidgets(nom, (WidgetTester tester) async {
          if (v.$3) LocaleSettings.setLocaleSync(AppLocale.ar);
          final DateTime maintenant = DateTime.now();
          // Le texte est celui que l'application affiche : jamais un titre ecrit ici.
          final List<NotificationTuteur> rendues = quoi == 'annonce'
              ? <NotificationTuteur>[
                  NotificationTuteur(
                    id: 'n1',
                    titre: contenuNotificationPour(
                      'creneau_change',
                      <String, dynamic>{
                        'motif': 'changement_heure',
                        'portee': 'soi',
                        'sens': 'ete',
                        'academie': true,
                        'date_changement': '2027-03-28',
                        'changements': <Map<String, dynamic>>[
                          <String, dynamic>{
                            'jour_avant': 3,
                            'avant': '19:00',
                            'jour_apres': 3,
                            'apres': '20:00',
                          },
                        ],
                      },
                    ).titre,
                    date: maintenant.subtract(const Duration(hours: 3)),
                    lue: false,
                    evenement: 'creneau_change',
                  ),
                  NotificationTuteur(
                    id: 'n2',
                    titre: contenuNotificationPour(
                      'creneau_change',
                      <String, dynamic>{
                        'motif': 'changement_heure',
                        'portee': 'foyer',
                        'academie': true,
                        'date_changement': '2027-03-28',
                        'changements': <Map<String, dynamic>>[
                          <String, dynamic>{
                            'jour_avant': 7,
                            'avant': '23:00',
                            'jour_apres': 1,
                            'apres': '00:00',
                          },
                        ],
                      },
                    ).titre,
                    date: maintenant.subtract(const Duration(days: 2)),
                    evenement: 'creneau_change',
                  ),
                ]
              : <NotificationTuteur>[
                  NotificationTuteur(
                    id: 'n1',
                    titre: contenuNotificationPour(
                      'creneau_change',
                      <String, dynamic>{
                        'motif': 'conversion_refusee',
                        'classe': 'Classe des lionceaux',
                        'cause': 'proche',
                      },
                    ).titre,
                    date: maintenant.subtract(const Duration(hours: 5)),
                    lue: false,
                    evenement: 'creneau_change',
                  ),
                ];
          await monterRouteur(
            tester,
            chemin,
            source: FausseSourceSession(sessionActive(role)),
            taille: Size(v.$1, v.$1 > 600 ? 900 : 1100),
            themeMode: v.$2 ? ThemeMode.light : ThemeMode.dark,
            direction: v.$3 ? TextDirection.rtl : TextDirection.ltr,
            surcharges: <Override>[
              portNotificationsProvider.overrideWithValue(
                _Notifications(rendues),
              ),
            ],
          );
          await stabiliser(tester);
          debugPrint('PNG ${await capturerVue(tester, nom)}');
        });
      }
    }

    // ------------------------------------------------------------------
    // « Ma journee » de l'enseignant : rien aujourd'hui, prochain cours.
    // ------------------------------------------------------------------
    for (final (double, bool, bool) v in _variantes) {
      final String nom = 'horloge_lieu_journee_rien_${_suffixe(v)}';
      testWidgets(nom, (WidgetTester tester) async {
        if (v.$3) LocaleSettings.setLocaleSync(AppLocale.ar);
        fixerVueCapture(tester, Size(v.$1, v.$1 > 600 ? 900 : 1400), 1);
        // Jeudi 12/11/2026, 05:00 UTC. Le prochain cours : vendredi 13, 21:30 a
        // Riyad (UTC+3) = 18:30 UTC ; a Paris ce serait le meme jour, a Conakry
        // aussi ; le jour se lit au fuseau du profil.
        final MonHorloge horloge = _horloge(_riyad);
        poserMonHorlogePourTest(horloge);
        await tester.pumpWidget(
          hoteCapture(
            const JourneePage(),
            surcharges: <Override>[
              sourceSessionProvider.overrideWithValue(
                FausseSourceSession(sessionActive(AppRole.teacher)),
              ),
              monHorlogeProvider.overrideWith((Ref _) async => horloge),
              serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
              serviceEnseignantProvider.overrideWithValue(
                FauxServiceEnseignant(),
              ),
              cahiersEnFileProvider.overrideWith(
                (Ref _) async => const <String>{},
              ),
              maintenantJourneeProvider.overrideWithValue(
                () => DateTime.utc(2026, 11, 12, 5),
              ),
              seancesEnseignantProvider.overrideWith(
                (Ref _) async => <SeanceEnseignant>[
                  SeanceEnseignant(
                    id: 's1',
                    debut: DateTime.utc(2026, 11, 13, 18, 30),
                    fin: DateTime.utc(2026, 11, 13, 19, 45),
                    statut: StatutSeance.planifiee,
                    nbParticipants: 4,
                    cahierDepose: false,
                    groupeId: 'g1',
                    groupeLibelle: 'Coran du soir',
                  ),
                ],
              ),
              cahiersEnRetardProvider.overrideWith(
                (Ref _) async => const <CahierEnRetard>[],
              ),
              pausePrevueProvider.overrideWith((Ref _, String _) async => null),
              valeurRegleProvider((
                profilId: 'p-teacher',
                cle: CleRegle.pauseEntreCours,
              )).overrideWith((Ref _) async => 10),
            ],
            themeMode: v.$2 ? ThemeMode.light : ThemeMode.dark,
          ),
        );
        await stabiliser(tester);
        debugPrint('PNG ${await capturerVue(tester, nom)}');
      });
    }
  });
}
