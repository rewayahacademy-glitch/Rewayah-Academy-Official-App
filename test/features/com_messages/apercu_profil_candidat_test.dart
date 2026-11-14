// Apercu du profil (directeur, 14/11/2026) : dans un fil de candidature lu par
// l'equipe, le contexte montre le profil du candidat (nom, type, genre, pays,
// situation, piece, entretien, dernieres decisions) et « Voir tout le
// dossier » ; toucher le nom ouvre ce contexte au telephone ; le candidat
// lui-meme ne voit jamais cet apercu ; un refus du serveur ne montre rien.

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
import 'package:rewayah_academy/features/com_messages/apercu_profil_candidat.dart';
import 'package:rewayah_academy/features/com_messages/entete_fil_contexte.dart';
import 'package:rewayah_academy/features/com_messages/messages_metier_supabase.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';

import '../../fixtures/candidature/faux_candidatures_direction.dart';
import '../../support/garde_interface.dart';
import 'support_messages.dart';

const String _fil = '7c900000-0000-4000-8000-0000000000f1';
const String _cand = 'c-apercu';

FilMetier _filPour({required bool equipeLit}) =>
    filMetierJson(<String, dynamic>{
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
          'est_soi': !equipeLit,
        },
        <String, dynamic>{
          'id': 'equipe',
          'nature': 'equipe',
          'est_soi': equipeLit,
        },
      ],
      'messages': <Map<String, dynamic>>[],
      'non_lus': 0,
      'peut_ecrire': true,
    }, const LibellesCommunicationSlang());

List<Override> _serveur({bool refuse = false}) => <Override>[
  portCandidaturesDirectionProvider.overrideWithValue(
    FauxCandidaturesDirection(
      details: <DetailCandidature>[
        detailTest(
          id: _cand,
          nom: 'Salma Benali',
          genre: 'female',
          piece: EtatPiece.validee,
        ),
      ],
      historiques: <String, List<EvenementCandidature>>{
        _cand: <EvenementCandidature>[
          EvenementCandidature(
            id: 2,
            type: 'transition',
            auteur: AuteurEvenement.systeme,
            quand: DateTime.utc(2026, 11, 10, 9),
          ),
        ],
      },
      erreurLire: refuse ? (int _) => Exception('refus') : null,
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
  testWidgets('1440 : l\'equipe voit le profil du candidat dans le contexte', (
    WidgetTester tester,
  ) async {
    await monterMessages(
      tester,
      port: FauxMessagesMetier(fils: <FilMetier>[_filPour(equipeLit: true)]),
      depart: cheminFilTest(_fil),
      surcharges: _serveur(),
    );
    final m = t.com.messages.apercu;
    expect(find.byKey(ApercuProfilCandidat.cle), findsOneWidget);
    expect(find.text(m.typeEnseignant), findsOneWidget);
    expect(
      find.text(t.admin.candidatures.detail.etatsPiece.validee),
      findsOneWidget,
    );
    expect(
      find.textContaining(m.entretienPrevu(quand: '').trim().split(' ').first),
      findsWidgets,
    );
    expect(find.byKey(ApercuProfilCandidat.cleDossier), findsOneWidget);
    verifierUnSeulBoutonPlein(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('le candidat ne voit jamais l\'apercu', (
    WidgetTester tester,
  ) async {
    await monterMessages(
      tester,
      port: FauxMessagesMetier(fils: <FilMetier>[_filPour(equipeLit: false)]),
      depart: cheminFilTest(_fil),
      surcharges: _serveur(),
    );
    expect(find.byKey(ApercuProfilCandidat.cle), findsNothing);
  });

  testWidgets('un refus du serveur ne montre rien du candidat', (
    WidgetTester tester,
  ) async {
    await monterMessages(
      tester,
      port: FauxMessagesMetier(fils: <FilMetier>[_filPour(equipeLit: true)]),
      depart: cheminFilTest(_fil),
      surcharges: _serveur(refuse: true),
    );
    expect(find.byKey(ApercuProfilCandidat.cle), findsNothing);
    expect(find.text(t.com.messages.apercu.typeEnseignant), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('390 : toucher le nom ouvre le contexte, avec le profil', (
    WidgetTester tester,
  ) async {
    await monterMessages(
      tester,
      port: FauxMessagesMetier(fils: <FilMetier>[_filPour(equipeLit: true)]),
      depart: cheminFilTest(_fil),
      taille: const Size(390, 844),
      surcharges: _serveur(),
    );
    expect(find.byKey(ApercuProfilCandidat.cle), findsNothing);
    await tester.tap(find.byKey(EnteteFilContexte.cleRaccourci));
    await tester.pumpAndSettle();
    expect(find.byKey(ApercuProfilCandidat.cle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
