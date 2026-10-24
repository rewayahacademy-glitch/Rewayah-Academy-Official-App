import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_parcours/port_signalement.dart';
import 'package:rewayah_academy/core/tc_parcours/student_concern.dart';

const String _interne =
    'Confusion persistante entre sad et sin, et deux retards cette semaine.';
const String _famille =
    'Amina progresse bien, un point de prononciation a '
    'travailler a la maison.';

SignalementMemoire _depot() => SignalementMemoire(
  'ens-1',
  maintenant: () => DateTime.utc(2026, 9, 20, 18),
);

Future<StudentConcern> _signaler(SignalementMemoire depot, {String? famille}) =>
    depot.signaler(
      categorie: CategorieSignalement.pedagogique,
      groupeId: 'g1',
      sessionId: 's1',
      academyId: 'RA-AB0012',
      internalDetails: _interne,
      familySummary: famille,
    );

void main() {
  group('contexte prerempli', () {
    test('le professeur ne retape aucun identifiant', () async {
      final SignalementMemoire depot = _depot();
      final StudentConcern signalement = await _signaler(depot);

      expect(signalement.groupeId, 'g1');
      expect(signalement.sessionId, 's1');
      expect(signalement.academyId, 'RA-AB0012');
      // L'enseignant vient du jeton, jamais d'un champ de formulaire.
      expect(signalement.enseignantId, 'ens-1');
      expect(signalement.statut, StatutSignalement.ouvert);
      expect(signalement.creeLeUtc.isUtc, isTrue);
    });

    test('une note interne vide est refusee', () async {
      expect(
        () => _depot().signaler(
          categorie: CategorieSignalement.autre,
          groupeId: 'g1',
          academyId: 'RA-AB0012',
          internalDetails: '   ',
        ),
        throwsA(
          isA<EchecSignalement>().having(
            (EchecSignalement e) => e.motif,
            'motif',
            MotifEchecSignalement.interneVide,
          ),
        ),
      );
    });
  });

  group('separation interne / famille', () {
    test('un signalement sans family_summary est un cas normal', () async {
      final StudentConcern signalement = await _signaler(_depot());

      expect(signalement.familySummary, isNull);
      expect(signalement.peutEtreTransmis, isFalse);
      expect(signalement.pourLaFamille(), isNull);
    });

    test('un family_summary vide vaut absent', () async {
      final StudentConcern signalement = await _signaler(
        _depot(),
        famille: '   ',
      );

      expect(signalement.familySummary, isNull);
    });

    test('la note interne ne fuit pas vers la famille', () async {
      final StudentConcern signalement = await _signaler(
        _depot(),
        famille: _famille,
      );

      final ResumeFamilleSignalement resume = signalement.pourLaFamille()!;
      final Map<String, dynamic> charge = resume.versJson();

      // La charge utile exacte de ce qui partirait, mot pour mot.
      expect(resume.message, _famille);
      expect(charge.values.join(' '), isNot(contains('sad')));
      expect(charge.values.join(' '), isNot(contains(_interne)));
      expect(charge.containsKey('internal_details'), isFalse);
      expect(charge.keys, isNot(contains('note_interne')));
    });

    test('transmettre sans message famille echoue', () async {
      final SignalementMemoire depot = _depot();
      final StudentConcern signalement = await _signaler(depot);

      expect(
        () => depot.transmettre(
          concernId: signalement.id,
          cible: CibleTransmission.tuteurDuMineur,
        ),
        throwsA(
          isA<EchecSignalement>().having(
            (EchecSignalement e) => e.motif,
            'motif',
            MotifEchecSignalement.familleSansMessage,
          ),
        ),
      );
    });

    test('transmettre avec message famille marque le signalement', () async {
      final SignalementMemoire depot = _depot();
      final StudentConcern signalement = await _signaler(
        depot,
        famille: _famille,
      );

      await depot.transmettre(
        concernId: signalement.id,
        cible: CibleTransmission.eleveAdulte,
      );

      final StudentConcern relu = (await depot.mesSignalements()).single;
      expect(relu.statut, StatutSignalement.transmis);
      expect(relu.transmisA, CibleTransmission.eleveAdulte);
      expect(relu.transmisLeUtc, isNotNull);
      // La note interne reste attachee au signalement cote administration : ce
      // qui ne doit pas fuir, c'est ce qui PART, pas ce qui est conserve.
      expect(relu.internalDetails, _interne);
    });

    test(
      'un signalement transmis sans message est impossible a construire',
      () {
        expect(
          () => StudentConcern(
            id: 'c1',
            categorie: CategorieSignalement.autre,
            groupeId: 'g1',
            academyId: 'RA-AB0012',
            enseignantId: 'ens-1',
            internalDetails: _interne,
            statut: StatutSignalement.transmis,
            creeLeUtc: DateTime.utc(2026, 9, 20),
            transmisLeUtc: DateTime.utc(2026, 9, 20),
          ),
          throwsA(isA<AssertionError>()),
        );
      },
    );

    test('un signalement inconnu ne se transmet pas', () async {
      expect(
        () => _depot().transmettre(
          concernId: 'inexistant',
          cible: CibleTransmission.tuteurDuMineur,
        ),
        throwsA(
          isA<EchecSignalement>().having(
            (EchecSignalement e) => e.motif,
            'motif',
            MotifEchecSignalement.inconnu,
          ),
        ),
      );
    });
  });

  group('mes signalements', () {
    test('le filtre par groupe borne la liste', () async {
      final SignalementMemoire depot = _depot();
      await _signaler(depot);
      await depot.signaler(
        categorie: CategorieSignalement.technique,
        groupeId: 'g2',
        academyId: 'RA-CD0034',
        internalDetails: 'Micro coupe pendant toute la seance.',
      );

      expect(await depot.mesSignalements(), hasLength(2));
      expect(await depot.mesSignalements(groupeId: 'g2'), hasLength(1));
    });
  });
}
