// Apercu du profil (directeur, 14/11/2026) : captures R3. Le fil d'une
// candidature lu par l'equipe, le profil du candidat dans le contexte (1440)
// et, au telephone, apres le toucher du nom (390). fr et ar. Donnees de test
// seulement. Jamais sans `CAPTURE_DIR`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart';
import 'package:rewayah_academy/core/candidature/modeles_entretien_direction.dart';
import 'package:rewayah_academy/core/candidature/port_candidatures_direction.dart';
import 'package:rewayah_academy/core/candidature/port_entretiens_direction.dart';
import 'package:rewayah_academy/core/communications/libelles_communication_slang.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/com_messages/entete_fil_contexte.dart';
import 'package:rewayah_academy/features/com_messages/messages_metier_supabase.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';

import '../features/com_messages/support_messages.dart';
import '../fixtures/candidature/faux_candidatures_direction.dart';
import 'outil_capture.dart';

const String _fil = '7c900000-0000-4000-8000-0000000000f1';
const String _cand = 'c-apercu';

FilMetier _fil0(bool arabe) => filMetierJson(<String, dynamic>{
  'id': _fil,
  'objet': <String, dynamic>{'type': 'candidature', 'id': _cand},
  'accessible': true,
  'parties': <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'p-cand',
      'nature': 'profil',
      'fonction': 'enseignant',
      'prenom': 'Salma',
      'nom': 'Benali',
    },
    <String, dynamic>{'id': 'equipe', 'nature': 'equipe', 'est_soi': true},
  ],
  'messages': <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'm-1',
      'auteur': <String, dynamic>{
        'id': 'p-cand',
        'nature': 'profil',
        'fonction': 'enseignant',
        'prenom': 'Salma',
        'nom': 'Benali',
      },
      'texte': arabe
          ? 'السلام عليكم، متى المقابلة؟'
          : 'Bonjour, quand a lieu l\'entretien ?',
      'envoye_le': '2026-11-14T09:00:00Z',
    },
  ],
  'non_lus': 0,
  'peut_ecrire': true,
}, const LibellesCommunicationSlang());

final List<Override> _serveur = <Override>[
  portCandidaturesDirectionProvider.overrideWithValue(
    FauxCandidaturesDirection(
      details: <DetailCandidature>[
        detailTest(
          id: _cand,
          nom: 'Salma Benali',
          genre: 'female',
          paysResidence: 'MA',
          piece: EtatPiece.validee,
        ),
      ],
      historiques: <String, List<EvenementCandidature>>{
        _cand: <EvenementCandidature>[
          EvenementCandidature(
            id: 3,
            type: 'transition',
            auteur: AuteurEvenement.systeme,
            quand: DateTime.utc(2026, 11, 12, 10),
          ),
          EvenementCandidature(
            id: 2,
            type: 'transition',
            auteur: AuteurEvenement.candidat,
            quand: DateTime.utc(2026, 11, 8, 9),
          ),
        ],
      },
    ),
  ),
  entretiensCandidatureProvider.overrideWith(
    (Ref _, String _) async => <EntretienCandidature>[
      EntretienCandidature(
        sessionId: 's1',
        candidatureId: _cand,
        debut: DateTime.utc(2026, 11, 20, 14),
        fin: DateTime.utc(2026, 11, 20, 15),
        participants: 2,
        fondateurs: 1,
      ),
    ],
  ),
];

void main() {
  group('Capture : apercu du profil', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);

    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      testWidgets('1440, ${langue.name}', (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        await monterMessages(
          tester,
          port: FauxMessagesMetier(
            fils: <FilMetier>[_fil0(langue == AppLocale.ar)],
          ),
          depart: cheminFilTest(_fil),
          langue: langue,
          surcharges: _serveur,
        );
        debugPrint(
          'PNG ${await capturerVue(tester, 'apercu-profil/${langue.name}_1440x900')}',
        );
      });

      testWidgets('390, ${langue.name}', (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        await monterMessages(
          tester,
          port: FauxMessagesMetier(
            fils: <FilMetier>[_fil0(langue == AppLocale.ar)],
          ),
          depart: cheminFilTest(_fil),
          taille: const Size(390, 844),
          langue: langue,
          surcharges: _serveur,
        );
        await tester.tap(find.byKey(EnteteFilContexte.cleRaccourci));
        await stabiliser(tester);
        debugPrint(
          'PNG ${await capturerVue(tester, 'apercu-profil/${langue.name}_390x844_feuille')}',
        );
      });
    }
  });
}
