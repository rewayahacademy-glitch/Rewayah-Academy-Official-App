import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/tc_classe/roster_classe_vm.dart';
import 'package:rewayah_academy/core/tc_classe/roster_enseignant.dart';
import 'package:rewayah_academy/core/tc_classe/teacher_student_projection.dart';
import 'package:rewayah_academy/features/tc_classe_live/fiche_seance.dart';
import 'package:rewayah_academy/features/tc_classe_live/roster_classe.dart';

import 'faux/faux_classe.dart';
import 'support/hote_classe.dart';

/// **Le test de non-regression le plus important du lot.**
///
/// « Connaissance pedagogique forte, connaissance privee minimale » (spec
/// section 10). La protection ne tient pas par une barriere Flutter : elle tient
/// parce que la vue serveur ne delivre pas ces colonnes -- `teacher_roster_v` a
/// retire `last_name` en 0005 (ADR-008), et `profiles` n'accorde aucune policy
/// `select` a l'enseignant.
///
/// Ce test verifie les deux moities de cette phrase :
///
/// 1. **si une source livrait quand meme une colonne interdite, la projection ne
///    la reprendrait pas** -- les mappings lisent des cles nommees, jamais le
///    json entier ;
/// 2. **rien d'interdit n'atteint l'ecran**, ni en texte, ni en libelle parle.
///
/// Il n'est **pas** une autorisation a masquer cote client : si une donnee
/// interdite apparait dans une source, c'est un defaut a signaler, parce que la
/// spec exige qu'elle ne soit pas DELIVREE.
void main() {
  /// Les aiguilles interdites, telles qu'elles arriveraient d'une source fautive.
  const Map<String, String> interdits = <String, String>{
    'nom de famille': 'Benali',
    'initiale de nom': 'B.',
    'telephone': '0612345678',
    'email': 'famille@exemple.invalid',
    'adresse': '12 rue des Lilas',
    'identite du tuteur': 'Fatima Benali',
    'paiement': 'IBAN FR7630001007941234567890185',
    'geolocalisation': '48.8566,2.3522',
    'identifiant d appareil': 'device-9f3c1a77',
    'foyer': 'household-4412',
  };

  /// Une ligne de `teacher_roster_v` **polluee** par toutes les colonnes que la
  /// vue ne doit pas porter.
  Map<String, dynamic> ligneRosterPolluee() => <String, dynamic>{
    'session_id': 's1',
    'student_id': 'p1',
    'first_name': 'Amina',
    'immutable_id': 'RA-AB0012',
    'level': 'Decodage consolide',
    'riwaya': 'hafs',
    'last_name': interdits['nom de famille'],
    'phone': interdits['telephone'],
    'email': interdits['email'],
    'address': interdits['adresse'],
    'guardian_name': interdits['identite du tuteur'],
    'iban': interdits['paiement'],
    'geo': interdits['geolocalisation'],
    'device_id': interdits['identifiant d appareil'],
    'household_id': interdits['foyer'],
  };

  /// Tout ce qu'un arbre de widgets donne a lire ou a entendre.
  List<String> motsRendus(WidgetTester tester) => <String>[
    for (final Text t in tester.widgetList<Text>(find.byType(Text)))
      if (t.data case final String texte) texte,
    for (final Semantics s in tester.widgetList<Semantics>(
      find.byType(Semantics),
    ))
      ...<String>[
        if (s.properties.label case final String etiquette) etiquette,
        if (s.properties.value case final String valeur) valeur,
      ],
  ];

  void aucunInterdit(List<String> mots) {
    final String tout = mots.join(' | ');
    for (final MapEntry<String, String> aiguille in interdits.entries) {
      expect(
        tout.contains(aiguille.value),
        isFalse,
        reason:
            'PII rendue a l ecran : ${aiguille.key} (« ${aiguille.value} »)',
      );
    }
  }

  group('mapping : la projection ne reprend que ce que le contrat nomme', () {
    test('ficheDepuisRosterV ignore toute colonne interdite', () {
      final TeacherStudentProjection fiche = ficheDepuisRosterV(
        ligneRosterPolluee(),
      );

      expect(fiche.firstName, 'Amina');
      expect(fiche.academyId, 'RA-AB0012');
      expect(fiche.level, 'Decodage consolide');

      // Le prenom est seul : ni nom, ni initiale, ni rien d'autre.
      final String tout = <String?>[
        fiche.firstName,
        fiche.academyId,
        fiche.level,
        fiche.curriculumPath,
        fiche.currentUnit,
        ...fiche.activeGoals,
        ...fiche.authorizedPedagogicalNotes,
        fiche.lastLesson?.pointARevoir,
      ].whereType<String>().join(' | ');

      for (final MapEntry<String, String> aiguille in interdits.entries) {
        expect(
          tout.contains(aiguille.value),
          isFalse,
          reason: 'PII dans la projection : ${aiguille.key}',
        );
      }
    });

    test('riwaya est disponible et volontairement pas projetee', () {
      // Un agent n'ajoute pas un champ parce que la vue le lui offre : `riwaya`
      // ne figure pas au contrat section 12.
      final TeacherStudentProjection fiche = ficheDepuisRosterV(
        ligneRosterPolluee(),
      );
      expect(fiche.curriculumPath, isNull);
      expect(fiche.currentUnit, isNull);
    });

    test('PresenceParticipant ne livre que prenom et identifiant', () {
      final PresenceParticipant ligne = PresenceParticipant.depuisJson(
        <String, dynamic>{
          'session_id': 's1',
          'profile_id': 'p1',
          'role': 'student',
          'prenom': 'Amina',
          'identifiant_immuable': 'RA-AB0012',
          'etat': 'presente',
          'consolide': false,
          'last_name': interdits['nom de famille'],
          'phone': interdits['telephone'],
        },
      );
      expect(ligne.prenom, 'Amina');
      expect(ligne.identifiantImmuable, 'RA-AB0012');
      final List<TeacherStudentProjection> roster = composerRoster(
        presences: <PresenceParticipant>[ligne],
      );
      expect(roster.single.firstName, 'Amina');
      expect(roster.single.academyId, 'RA-AB0012');
    });
  });

  group('rendu : rien d interdit n atteint l ecran', () {
    testWidgets('le roster ne rend aucune PII', (WidgetTester tester) async {
      final TeacherStudentProjection fiche = ficheDepuisRosterV(
        ligneRosterPolluee(),
      );
      await tester.pumpWidget(
        hoteClasse(
          PanneauRoster(
            roster: RosterClasseVM(
              eleves: <TeacherStudentProjection>[fiche],
              disponible: true,
            ),
            entete: true,
            onOuvrirFiche: (String _) {},
          ),
        ),
      );
      await tester.pump();

      // Ce qui DOIT etre la : le prenom et l'identifiant d'academie, qui
      // remplace le nom de famille dans toute desambiguisation (ADR-008).
      expect(find.text('Amina'), findsOneWidget);
      expect(find.text('RA-AB0012'), findsOneWidget);
      aucunInterdit(motsRendus(tester));
    });

    testWidgets('la fiche pedagogique ne rend aucune PII', (
      WidgetTester tester,
    ) async {
      final TeacherStudentProjection fiche = ficheDepuisRosterV(
        ligneRosterPolluee(),
      );
      await tester.pumpWidget(
        hoteClasse(
          FicheSeance(eleve: fiche, sessionId: 's1'),
          surcharges: surchargesClasse(
            moteur: FauxMoteurClasse(),
            video: FauxServiceVideoClasse(),
            preVol: FauxPreVolClasse(),
            rappel: FauxRappelDiscret(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Amina'), findsOneWidget);
      expect(find.text('RA-AB0012'), findsOneWidget);
      expect(find.text('Decodage consolide'), findsOneWidget);
      aucunInterdit(motsRendus(tester));
    });

    testWidgets('aucune UI n ecrit « mode enfant »', (
      WidgetTester tester,
    ) async {
      // Decision D-07 : le nom visible est « Interface guidee ». La valeur SQL
      // reste `'child'`, et ce n'est pas un renommage de donnee.
      const TeacherStudentProjection fiche = TeacherStudentProjection(
        firstName: 'Ilyas',
        academyId: 'RA-CD0044',
        liveStatus: EtatPresenceProjete.present,
        interfaceGuidee: true,
        level: 'Debutant',
      );
      await tester.pumpWidget(
        hoteClasse(
          const FicheSeance(eleve: fiche, sessionId: 's1'),
          surcharges: surchargesClasse(
            moteur: FauxMoteurClasse(),
            video: FauxServiceVideoClasse(),
            preVol: FauxPreVolClasse(),
            rappel: FauxRappelDiscret(),
          ),
        ),
      );
      await tester.pump();

      final String tout = motsRendus(tester).join(' | ').toLowerCase();
      expect(tout.contains('mode enfant'), isFalse);
      expect(tout.contains('interface guidee'), isTrue);
    });
  });
}
