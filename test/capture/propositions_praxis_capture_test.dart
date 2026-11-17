// Captures des propositions de Praxis dans le dossier d'une candidature (PX-2,
// R3) : 360 px de large, francais et arabe (de droite a gauche), clair.
//
// Etats : un complement (le texte et le motif de Praxis mot pour mot), un
// entretien a planifier (les participants a choisir), un dossier qui a change
// (plus de « Valider », une phrase). Les donnees sont fictives : aucune personne
// reelle. Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/agent/propositions_praxis.dart';
import 'package:rewayah_academy/core/candidature/modeles_entretien_direction.dart';
import 'package:rewayah_academy/core/candidature/port_entretiens_direction.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/admin_candidature/propositions_praxis_dossier.dart';

import 'outil_capture.dart';

enum _Etat { complement, entretien, change }

class _Service implements ServicePropositionsPraxis {
  _Service(this.liste);

  final List<PropositionPraxis> liste;

  @override
  Future<List<PropositionPraxis>> ouvertes() async => liste;

  @override
  Future<ResultatProposition> valider({
    required String id,
    required int version,
    required String cle,
    List<String>? participants,
  }) async => const ResultatProposition(fait: true);

  @override
  Future<ResultatProposition> ecarter({
    required String id,
    required String cle,
    String? motif,
  }) async => const ResultatProposition(fait: true);
}

PropositionPraxis _proposition(_Etat etat) {
  final DateTime expire = DateTime.utc(2026, 11, 20, 10);
  switch (etat) {
    case _Etat.complement:
      return PropositionPraxis(
        id: 'p1',
        geste: GestePrepare.demanderComplement,
        reference: 'CAND-00042',
        nom: 'Candidate Fictive',
        versionProposee: 3,
        versionActuelle: 3,
        parametres: const <String, dynamic>{
          'elements': <String>['langues'],
          'motif': 'Il manque les langues que vous enseignez.',
        },
        texte: "Le dossier est à compléter : la liste des langues d'enseignement est vide.",
        expireLe: expire,
      );
    case _Etat.entretien:
      return PropositionPraxis(
        id: 'p2',
        geste: GestePrepare.planifierEntretien,
        reference: 'CAND-00042',
        nom: 'Candidate Fictive',
        versionProposee: 3,
        versionActuelle: 3,
        parametres: const <String, dynamic>{
          'debut': '2026-11-19T09:00:00Z',
          'duree_minutes': 45,
        },
        texte: 'Les vérifications sont faites : je propose un entretien.',
        expireLe: expire,
      );
    case _Etat.change:
      return PropositionPraxis(
        id: 'p3',
        geste: GestePrepare.admettreVerifications,
        reference: 'CAND-00042',
        nom: 'Candidate Fictive',
        versionProposee: 3,
        versionActuelle: 5,
        parametres: const <String, dynamic>{},
        texte: 'Le dossier est complet : je propose de l’admettre.',
        expireLe: expire,
      );
  }
}

void main() {
  group('Capture : propositions de Praxis (PX-2)', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final _Etat etat in _Etat.values) {
        final String nom =
            'propositions_${etat.name}_${langue.languageCode}_360';
        testWidgets(nom, (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          fixerVueCapture(tester, const Size(360, 1100), 1);
          final List<Override> surcharges = <Override>[
            servicePropositionsPraxisProvider.overrideWithValue(
              _Service(<PropositionPraxis>[_proposition(etat)]),
            ),
            personnelEntretienProvider.overrideWith(
              (ref, String candidature) async => const <PersonnelEntretien>[
                PersonnelEntretien(
                  profilId: 'p1',
                  prenom: 'Amina',
                  nom: 'Fictive',
                  fondateur: true,
                ),
                PersonnelEntretien(
                  profilId: 'p2',
                  prenom: 'Bilal',
                  nom: 'Fictif',
                  fondateur: true,
                ),
              ],
            ),
          ];
          await tester.pumpWidget(
            hoteCapture(
              const Scaffold(
                body: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: PropositionsPraxisDossier(
                    reference: 'CAND-00042',
                    candidatureId: 'cand-42',
                  ),
                ),
              ),
              surcharges: surcharges,
            ),
          );
          await stabiliser(tester);
          expect(tester.takeException(), isNull);
          debugPrint('PNG ${await capturer(tester, nom)}');
          await tester.pumpWidget(const SizedBox());
          await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.fr));
        });
      }
    }
  });
}
