// DEPLACER-ENTRETIEN (BE-1j, pilote 17/11/2026) : l'entretien planifie d'un
// dossier et la feuille « Deplacer l'entretien ». 360 et 1440, francais et
// arabe. Donnees fictives. Saute sans CAPTURE_DIR.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';
import 'package:rewayah_academy/core/candidature/modeles_entretien_direction.dart';
import 'package:rewayah_academy/core/candidature/port_entretiens_direction.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';

import '../features/admin_candidature/hote_candidature.dart';
import '../fixtures/candidature/faux_candidatures_direction.dart';
import '../support/monter_recrutement.dart' show laisser;
import 'outil_capture.dart';

/// Un port d'entretiens qui ne sert que la lecture : un entretien a venir.
class _Entretiens implements PortEntretiensDirection {
  _Entretiens(this.debut);

  final DateTime debut;

  @override
  Future<List<EntretienCandidature>> entretiens(String candidatureId) async =>
      <EntretienCandidature>[
        EntretienCandidature(
          sessionId: 's1',
          candidatureId: candidatureId,
          debut: debut,
          fin: debut.add(const Duration(minutes: 45)),
          participants: 2,
          fondateurs: 2,
        ),
      ];

  @override
  Future<DetailEntretien> lire(String sessionId) async => const DetailEntretien(
    sessionId: 's1',
    participants: <ParticipantEntretien>[
      ParticipantEntretien(
        profilId: 'p-hafsa',
        prenom: 'Hafsa',
        nom: 'Kader',
        fondateur: true,
      ),
      ParticipantEntretien(
        profilId: 'p-salma',
        prenom: 'Salma',
        nom: 'Idrissi',
        fondateur: true,
      ),
    ],
    comptesRendus: <CompteRenduEntretien>[],
    presences: <PresenceEntretien>[],
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(chargerPolicesDuDepot);
  setUp(masquerRubanDebug);
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('DEPLACER-ENTRETIEN : captures', skip: sautSansCapture, () {
    for (final (int largeur, double hauteur) in <(int, double)>[
      (360, 800),
      (1440, 900),
    ]) {
      for (final (String nom, AppLocale langue) in <(String, AppLocale)>[
        ('fr', AppLocale.fr),
        ('ar', AppLocale.ar),
      ]) {
        final TextDirection? sens = langue == AppLocale.ar
            ? TextDirection.rtl
            : null;

        testWidgets('$largeur $nom entretien', (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          await monterCandidature(
            tester,
            port: FauxCandidaturesDirection(
              capacitesRendues: CapacitesCandidatures(
                peutLire: true,
                peutVoirContact: true,
                genreLecteurConnu: true,
                peutDecider: true,
                peutChoisirParticipants: true,
                peutMenerEntretien: true,
                fondateursExiges: 2,
                gestes: <String, bool>{
                  ...capacitesGestes.gestes,
                  'deplacerEntretien': true,
                  'planifierEntretien': true,
                  'consignerEntretien': true,
                },
                listes: capacitesGestes.listes,
              ),
              details: <DetailCandidature>[
                detailTest(
                  etape: EtapeCandidature.verifications,
                  etat: EtatCandidature.entretienPlanifie,
                  paiement: EtatVersement.compatible,
                ),
              ],
            ),
            largeur: largeur.toDouble(),
            hauteur: hauteur,
            direction: sens,
            surcharges: <Override>[
              portEntretiensDirectionProvider.overrideWithValue(
                _Entretiens(DateTime.now().add(const Duration(days: 3))),
              ),
            ],
          );
          await laisser(tester, fois: 6);
          final Finder bouton = find.byKey(
            const ValueKey<String>('entretien-deplacer'),
          );
          await tester.ensureVisible(bouton);
          await laisser(tester);
          await capturerVue(
            tester,
            'DEPLACER-ENTRETIEN/entretien_${nom}_$largeur',
          );
          await tester.tap(bouton);
          await laisser(tester, fois: 6);
          await capturerVue(
            tester,
            'DEPLACER-ENTRETIEN/feuille_${nom}_$largeur',
          );
        });
      }
    }
  });
}
