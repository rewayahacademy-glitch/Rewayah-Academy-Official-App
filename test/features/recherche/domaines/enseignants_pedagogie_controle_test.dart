// RECH-D3 : enseignants, remplacements, pedagogie, controle sur les ports que
// l'application lit deja : mission expiree refusee, champs prives non
// recherchables, aucune fuite de liste d'eleves ni de rapport, capacite jamais
// role (spec RECH-03 §2, §3, §7 ; SEC-R01, R02, R06, R15 ; REC-02, 03, 04).

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/absence_remplacement.dart';
import 'package:rewayah_academy/core/enseignant/port_remplacements.dart';
import 'package:rewayah_academy/core/recherche/modeles_recherche.dart';
import 'package:rewayah_academy/core/recherche/port_recherche.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_classe/port_roster_enseignant.dart';
import 'package:rewayah_academy/core/tc_classe/teacher_student_projection.dart';
import 'package:rewayah_academy/core/tc_groupe/demonstration_groupes.dart';
import 'package:rewayah_academy/core/tc_horloge/demonstration_horloge.dart';
import 'package:rewayah_academy/core/widgets/section_header.dart';
import 'package:rewayah_academy/core/widgets/setting_row.dart';
import 'package:rewayah_academy/features/controleur/mission_controle.dart';
import 'package:rewayah_academy/features/recherche/domaines/enseignants_pedagogie_controle/moteur_controle_mission.dart';
import 'package:rewayah_academy/features/recherche/domaines/enseignants_pedagogie_controle/moteurs_enseignants.dart';
import 'package:rewayah_academy/features/recherche/ecran/ecran_recherche.dart'
    show cleChampRecherche;

import '../../../router/support_routeur.dart';
import '../../../support/harnais.dart';

const ContexteRecherche _enseignant = ContexteRecherche(
  espace: EspaceRecherche.enseignant,
);
const ContexteRecherche _famille = ContexteRecherche(
  espace: EspaceRecherche.famille,
);
const ContexteRecherche _controleur = ContexteRecherche(
  espace: EspaceRecherche.controleur,
);

final DateTime _maintenant = DateTime(2026, 10, 11, 18);

TeacherStudentProjection _eleve(
  String prenom,
  String ra, {
  String? niveau,
  List<String> objectifs = const <String>[],
  List<String> notes = const <String>[],
}) => TeacherStudentProjection(
  firstName: prenom,
  academyId: ra,
  liveStatus: EtatPresenceProjete.attendu,
  interfaceGuidee: false,
  level: niveau,
  activeGoals: objectifs,
  authorizedPedagogicalNotes: notes,
);

class _RosterEspion extends PortRosterEnseignant {
  _RosterEspion(this.parGroupe);

  final Map<String, List<TeacherStudentProjection>> parGroupe;
  final List<String> lus = <String>[];

  @override
  Future<List<TeacherStudentProjection>> rosterDeGroupe(String groupeId) async {
    lus.add(groupeId);
    return parGroupe[groupeId] ?? const <TeacherStudentProjection>[];
  }

  @override
  Future<List<TeacherStudentProjection>> rosterDeSeance(
    String sessionId,
  ) async => const <TeacherStudentProjection>[];

  @override
  Future<TeacherStudentProjection?> fiche({
    required String academyId,
    String? sessionId,
  }) async => null;

  @override
  Stream<List<TeacherStudentProjection>> suivreRoster(String sessionId) =>
      const Stream<List<TeacherStudentProjection>>.empty();
}

class _Remplacements implements PortRemplacements {
  _Remplacements(this.offres);

  final List<OffreCommune> offres;

  @override
  Stream<List<OffreCommune>> suivre() =>
      Stream<List<OffreCommune>>.value(offres);

  @override
  Future<ResultatPriseRemplacement> prendre(String seanceId) async =>
      ResultatPriseRemplacement.acceptee;
}

OffreCommune _offre(String id, String classe, EtatOffreCommune etat) =>
    OffreCommune(
      offre: OffreRemplacement(
        seanceId: id,
        classe: classe,
        debut: _maintenant,
        fin: _maintenant.add(const Duration(hours: 1)),
        nbEleves: 4,
      ),
      etat: etat,
    );

MissionControle _mission({
  EtatMissionControle etat = EtatMissionControle.enDirect,
  DateTime? fin,
}) => MissionControle(
  id: 'm1',
  seanceId: 's1',
  classe: 'Classe Al-Fatiha',
  enseignant: 'Sayyid Youssouf',
  nombreEleves: 12,
  debut: _maintenant.subtract(const Duration(minutes: 20)),
  finPrevue: fin ?? _maintenant.add(const Duration(minutes: 30)),
  etat: etat,
);

String _titres(ReponseDomaine r) =>
    (r as ReponseOk).elements.map((ResultatRecherche e) => e.titre).join('|');

void main() {
  group('enseignants de mes classes', () {
    final MoteurEnseignantsDesClasses moteur = MoteurEnseignantsDesClasses(
      GroupesDemonstrationLocale(),
    );

    test(
      'un enseignant que je connais se retrouve par son nom, une fois',
      () async {
        final ReponseOk r = await moteur.rechercher(
          requete: 'youssouf',
          contexte: _famille,
        ) as ReponseOk;
        expect(r.elements.length, 1);
        expect(r.elements.single.type, TypeResultat.enseignant);
        expect(r.elements.single.contexte, contains('Classe Al-Fatiha'));
      },
    );

    test(
      'aucun annuaire : un nom inconnu de mes classes est un vide confirme',
      () async {
        final ReponseDomaine r = await moteur.rechercher(
          requete: 'inconnue',
          contexte: _famille,
        );
        expect(r, isA<ReponseOk>());
        expect((r as ReponseOk).elements, isEmpty);
      },
    );

    test(
      'ni l\'enseignant, ni l\'administration, ni le controleur : absent',
      () async {
        for (final EspaceRecherche e in <EspaceRecherche>[
          EspaceRecherche.enseignant,
          EspaceRecherche.administration,
          EspaceRecherche.controleur,
          EspaceRecherche.comptable,
        ]) {
          expect(
            await moteur.disponiblePour(ContexteRecherche(espace: e)),
            isFalse,
          );
        }
        expect(await moteur.disponiblePour(_famille), isTrue);
      },
    );

    test('un pays, un identifiant ne font pas matcher', () async {
      for (final String q in <String>['guinee', 'demo-ens', 'france']) {
        final ReponseOk r = await moteur.rechercher(
          requete: q,
          contexte: _famille,
        ) as ReponseOk;
        expect(r.elements, isEmpty, reason: q);
      }
    });
  });

  group('remplacements', () {
    final MoteurRemplacements moteur = MoteurRemplacements(
      _Remplacements(<OffreCommune>[
        _offre('s1', 'Classe Al-Fatiha', EtatOffreCommune.ouverte),
        _offre('s2', 'Classe Al-Baqara', EtatOffreCommune.priseParMoi),
        _offre('s3', 'Classe Al-Hikma', EtatOffreCommune.priseParUnCollegue),
      ]),
    );

    test('mes offres se trouvent, celle d\'un collegue jamais', () async {
      expect(
        _titres(
          await moteur.rechercher(requete: 'classe', contexte: _enseignant),
        ),
        'Classe Al-Fatiha|Classe Al-Baqara',
      );
      expect(
        _titres(
          await moteur.rechercher(requete: 'hikma', contexte: _enseignant),
        ),
        '',
      );
    });

    test('l\'etat se dit, sans motif ni nom de l\'absent', () async {
      final ReponseOk r = await moteur.rechercher(
        requete: 'baqara',
        contexte: _enseignant,
      ) as ReponseOk;
      expect(r.elements.single.contexte, 'Votre remplacement');
      expect(r.elements.single.cible.kind, KindCible.remplacement);
    });

    test('capacite : seul l\'espace enseignant a ce domaine', () async {
      expect(await moteur.disponiblePour(_enseignant), isTrue);
      expect(await moteur.disponiblePour(_famille), isFalse);
      expect(
        await moteur.rechercher(requete: 'classe', contexte: _famille),
        isA<ReponseEchec>(),
      );
    });
  });

  group('pedagogie : les eleves de mes classes', () {
    late _RosterEspion roster;
    late MoteurPedagogieEleves moteur;

    setUp(() {
      roster = _RosterEspion(<String, List<TeacherStudentProjection>>{
        GroupesDemonstration.alFatiha: <TeacherStudentProjection>[
          _eleve(
            'Mariam',
            'RA-AB0012',
            niveau: 'Niveau 2',
            objectifs: <String>['sourate Al-Ikhlas'],
            notes: <String>['allergie arachide, mot secret diabete'],
          ),
          _eleve('Yusuf', 'RA-AB0013'),
        ],
        // Une classe qui n'est PAS la mienne : ne doit jamais etre lue.
        'classe-etrangere': <TeacherStudentProjection>[
          _eleve('Intrus', 'RA-ZZ9999'),
        ],
      });
      moteur = MoteurPedagogieEleves(GroupesDemonstrationLocale(), roster);
    });

    test('un eleve se trouve par son prenom, avec sa classe', () async {
      final ReponseOk r = await moteur.rechercher(
        requete: 'mariam',
        contexte: _enseignant,
      ) as ReponseOk;
      expect(r.elements.length, 1);
      expect(r.elements.single.titre, 'Mariam');
      expect(r.elements.single.contexte, 'Élève de la classe Classe Al-Fatiha');
    });

    test('un mot present SEULEMENT dans une note privee ou un objectif ne fait '
        'jamais remonter l\'eleve (SEC-R02, REC-03)', () async {
      for (final String q in <String>['diabete', 'arachide', 'ikhlas']) {
        final ReponseOk r = await moteur.rechercher(
          requete: q,
          contexte: _enseignant,
        ) as ReponseOk;
        expect(r.elements, isEmpty, reason: q);
      }
    });

    test(
      'le niveau est un champ cherchable, l\'identifiant d\'academie non',
      () async {
        expect(
          _titres(
            await moteur.rechercher(requete: 'niveau 2', contexte: _enseignant),
          ),
          'Mariam',
        );
        for (final String q in <String>['ra-ab0012', 'ab0012']) {
          expect(
            _titres(await moteur.rechercher(requete: q, contexte: _enseignant)),
            '',
            reason: q,
          );
        }
      },
    );

    test(
      'aucun identifiant d\'academie ni note dans ce qui est rendu',
      () async {
        final ReponseOk r = await moteur.rechercher(
          requete: 'yusuf',
          contexte: _enseignant,
        ) as ReponseOk;
        for (final ResultatRecherche e in r.elements) {
          expect(
            '${e.titre} ${e.contexte} ${e.extrait}',
            isNot(contains('RA-')),
          );
          expect(e.extrait, isNull);
        }
      },
    );

    test('seules MES classes sont lues, jamais une classe etrangere', () async {
      await moteur.rechercher(requete: 'intrus', contexte: _enseignant);
      expect(roster.lus, isNot(contains('classe-etrangere')));
      expect(
        _titres(
          await moteur.rechercher(requete: 'intrus', contexte: _enseignant),
        ),
        '',
      );
    });

    test(
      'ni la famille ni le controleur n\'ont ce domaine, roster jamais lu',
      () async {
        for (final ContexteRecherche c in <ContexteRecherche>[
          _famille,
          _controleur,
        ]) {
          expect(await moteur.disponiblePour(c), isFalse);
          expect(
            await moteur.rechercher(requete: 'mariam', contexte: c),
            isA<ReponseEchec>(),
          );
        }
        expect(roster.lus, isEmpty);
      },
    );
  });

  group('controle : la mission, zero ou une', () {
    MoteurControleMission moteur(
      MissionControle? mission, {
      DateTime? maintenant,
    }) => MoteurControleMission(
      lire: () async => mission,
      maintenant: () => maintenant ?? _maintenant,
    );

    test(
      'la mission en cours se trouve par sa classe et son enseignant',
      () async {
        final MoteurControleMission m = moteur(_mission());
        expect(
          _titres(await m.rechercher(requete: 'fatiha', contexte: _controleur)),
          'Classe Al-Fatiha',
        );
        expect(
          _titres(
            await m.rechercher(requete: 'youssouf', contexte: _controleur),
          ),
          'Classe Al-Fatiha',
        );
      },
    );

    test('le nombre d\'eleves ni aucun nom d\'eleve, rapport ou fil ne font '
        'matcher', () async {
      final MoteurControleMission m = moteur(_mission());
      for (final String q in <String>['12', 'mariam', 'rapport', 'fil']) {
        expect(
          _titres(await m.rechercher(requete: q, contexte: _controleur)),
          '',
          reason: q,
        );
      }
    });

    test(
      'une mission EXPIREE refuse : jamais un resultat, jamais un vide',
      () async {
        final MoteurControleMission m = moteur(
          _mission(fin: _maintenant.subtract(const Duration(hours: 2))),
        );
        final ReponseDomaine r = await m.rechercher(
          requete: 'fatiha',
          contexte: _controleur,
        );
        expect(r, isA<ReponseEchec>());
        expect((r as ReponseEchec).statut, StatutRecherche.contexteRevoque);
      },
    );

    test('une mission indisponible refuse', () async {
      final ReponseDomaine r = await moteur(
        _mission(etat: EtatMissionControle.indisponible),
      ).rechercher(requete: 'fatiha', contexte: _controleur);
      expect((r as ReponseEchec).statut, StatutRecherche.contexteRevoque);
    });

    test(
      'la marge de fin : encore ouverte juste apres la fin, fermee ensuite',
      () async {
        final MissionControle mission = _mission(fin: _maintenant);
        expect(
          await moteur(
            mission,
            maintenant: _maintenant.add(const Duration(minutes: 10)),
          ).rechercher(requete: 'fatiha', contexte: _controleur),
          isA<ReponseOk>(),
        );
        expect(
          await moteur(
            mission,
            maintenant: _maintenant.add(const Duration(minutes: 40)),
          ).rechercher(requete: 'fatiha', contexte: _controleur),
          isA<ReponseEchec>(),
        );
      },
    );

    test('sans mission : vide confirme, sans aucun indice', () async {
      final ReponseDomaine r = await moteur(null)
          .rechercher(requete: 'fatiha', contexte: _controleur);
      expect(r, isA<ReponseOk>());
      expect((r as ReponseOk).elements, isEmpty);
    });

    test('capacite : seul l\'espace du controleur a ce domaine', () async {
      final MoteurControleMission m = moteur(_mission());
      expect(await m.disponiblePour(_controleur), isTrue);
      for (final ContexteRecherche c in <ContexteRecherche>[
        _famille,
        _enseignant,
        const ContexteRecherche(espace: EspaceRecherche.administration),
        const ContexteRecherche(espace: EspaceRecherche.comptable),
      ]) {
        expect(await m.disponiblePour(c), isFalse);
      }
    });
  });

  group('sur la surface /recherche', () {
    Future<void> chercher(WidgetTester tester, String texte) async {
      await tester.enterText(find.byKey(cleChampRecherche), texte);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
    }

    Future<void> monter(
      WidgetTester tester,
      AppRole role,
      List<MoteurRechercheDomaine> moteurs,
    ) => monterRouteur(
      tester,
      Routes.recherche,
      source: FausseSourceSession(sessionActive(role)),
      surcharges: <Override>[
        moteursRechercheProvider.overrideWithValue(moteurs),
      ],
    );

    testWidgets('l\'enseignant trouve un eleve ; un mot de note privee ne '
        'donne que « aucun resultat »', (WidgetTester tester) async {
      final List<MoteurRechercheDomaine> moteurs = <MoteurRechercheDomaine>[
        MoteurPedagogieEleves(
          GroupesDemonstrationLocale(),
          _RosterEspion(<String, List<TeacherStudentProjection>>{
            GroupesDemonstration.alFatiha: <TeacherStudentProjection>[
              _eleve('Mariam', 'RA-AB0012', notes: <String>['mot secret']),
            ],
          }),
        ),
      ];
      await monter(tester, AppRole.teacher, moteurs);
      await chercher(tester, 'mariam');
      expect(find.widgetWithText(SectionHeader, 'Élèves'), findsOneWidget);
      expect(find.byType(SettingRow), findsOneWidget);
      await chercher(tester, 'secret');
      expect(find.text('Aucun résultat pour cette recherche.'), findsOneWidget);
    });

    testWidgets('le controleur dont la mission a expire : « Recherche '
        'indisponible », aucune classe montree', (WidgetTester tester) async {
      await monter(tester, AppRole.controller, <MoteurRechercheDomaine>[
        MoteurControleMission(
          lire: () async =>
              _mission(fin: DateTime.now().subtract(const Duration(days: 1))),
        ),
      ]);
      await chercher(tester, 'fatiha');
      expect(
        find.text('Recherche indisponible pour le moment.'),
        findsOneWidget,
      );
      expect(find.text('Classe Al-Fatiha'), findsNothing);
    });

    testWidgets('le controleur voit sa mission sous « Controle », jamais un '
        'domaine d\'un autre espace', (WidgetTester tester) async {
      await monter(tester, AppRole.controller, <MoteurRechercheDomaine>[
        MoteurControleMission(
          lire: () async =>
              _mission(fin: DateTime.now().add(const Duration(hours: 1))),
        ),
        MoteurPedagogieEleves(
          GroupesDemonstrationLocale(),
          _RosterEspion(const <String, List<TeacherStudentProjection>>{}),
        ),
      ]);
      await chercher(tester, 'fatiha');
      expect(find.widgetWithText(SectionHeader, 'Contrôle'), findsOneWidget);
      expect(find.widgetWithText(SectionHeader, 'Élèves'), findsNothing);
    });
  });
}
