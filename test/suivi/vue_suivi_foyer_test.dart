import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/features/suivi_foyer/vue_suivi_foyer.dart';

/// Le 13 septembre 2026 a 10h30, fige.
final DateTime _maintenant = DateTime(2026, 9, 13, 10, 30);

Seance _seance({
  required String id,
  required int ilYAMinutes,
  StatutSeance? statut = StatutSeance.terminee,
  String eleveId = 'enf-1',
  String elevePrenom = 'Sofia',
  String enseignantPrenom = 'Rachid',
}) {
  final DateTime debut = _maintenant.subtract(Duration(minutes: ilYAMinutes));
  return Seance(
    id: id,
    debut: debut,
    fin: debut.add(const Duration(minutes: 60)),
    statut: statut,
    eleveId: eleveId,
    elevePrenom: elevePrenom,
    eleveIdentifiant: 'STUD-000001',
    enseignantId: 'ens-1',
    enseignantPrenom: enseignantPrenom,
    enseignantIdentifiant: 'TEACH-000001',
  );
}

PresenceParticipant _presence({
  required String seanceId,
  required String profilId,
  EtatPresence etat = EtatPresence.absente,
  bool consolide = false,
}) => PresenceParticipant(
  seanceId: seanceId,
  profilId: profilId,
  role: 'student',
  prenom: 'Sofia',
  identifiantImmuable: 'STUD-000001',
  etat: etat,
  consolide: consolide,
);

void main() {
  group('TUT-06 : l\'ordre ne depend jamais de l\'etat', () {
    test('le plus recent d\'abord, meme quand le plus ancien est une absence', () {
      final VueSuiviFoyer vue = VueSuiviFoyer.depuis(
        seances: <Seance>[
          _seance(id: 'vieux', ilYAMinutes: 10080),
          _seance(id: 'recent', ilYAMinutes: 60),
        ],
        presences: <PresenceParticipant>[
          _presence(seanceId: 'vieux', profilId: 'enf-1'),
          _presence(
            seanceId: 'recent',
            profilId: 'enf-1',
            etat: EtatPresence.finalisee,
          ),
        ],
        maintenant: _maintenant,
      );

      // Un tri par urgence ferait remonter l'absence : la ligne changerait de
      // place entre deux visites, et se ferait toucher a la place d'une autre.
      expect(
        vue.lignes.map((LigneSuivi l) => l.seance.id),
        <String>['recent', 'vieux'],
      );
    });

    test('deux cours a la meme heure gardent un ordre stable', () {
      List<String> rendu(List<Seance> seances) => VueSuiviFoyer.depuis(
        seances: seances,
        presences: const <PresenceParticipant>[],
        maintenant: _maintenant,
      ).lignes.map((LigneSuivi l) => l.seance.id).toList();

      // Une fratrie a exactement autant de cours simultanes que d'enfants.
      final List<Seance> ordre = <Seance>[
        _seance(id: 'aaa', ilYAMinutes: 120),
        _seance(id: 'bbb', ilYAMinutes: 120, eleveId: 'enf-2'),
      ];
      expect(rendu(ordre), <String>['aaa', 'bbb']);
      expect(rendu(ordre.reversed.toList()), <String>['aaa', 'bbb']);
    });
  });

  group('TUT-06 : le sort du cours prime sur l\'etat de l\'enfant', () {
    test('un cours annule ne dit rien de l\'enfant, meme note absent', () {
      final VueSuiviFoyer vue = VueSuiviFoyer.depuis(
        seances: <Seance>[
          _seance(id: 'a', ilYAMinutes: 60, statut: StatutSeance.annulee),
        ],
        // La base dit « absente », et elle a raison : aucun evenement de salle
        // n'a eu lieu. La phrase, elle, serait fausse.
        presences: <PresenceParticipant>[
          _presence(seanceId: 'a', profilId: 'enf-1'),
        ],
        maintenant: _maintenant,
      );

      expect(vue.lignes.single.sort, SortDuCours.annule);
      expect(vue.lignes.single.montrePresence, isFalse);
      // L'etat reste porte par la ligne : la vue ne decide pas de l'affichage.
      expect(vue.lignes.single.presence.etat, EtatPresence.absente);
    });

    test('annulee tardivement compte comme annulee', () {
      expect(
        VueSuiviFoyer.sortDe(
          _seance(id: 'a', ilYAMinutes: 60, statut: StatutSeance.annuleeTard),
        ),
        SortDuCours.annule,
      );
    });

    test('enseignant absent et panne technique sont des cours non tenus', () {
      expect(
        VueSuiviFoyer.sortDe(
          _seance(
            id: 'a',
            ilYAMinutes: 60,
            statut: StatutSeance.enseignantAbsent,
          ),
        ),
        SortDuCours.nonTenu,
      );
      expect(
        VueSuiviFoyer.sortDe(
          _seance(
            id: 'b',
            ilYAMinutes: 60,
            statut: StatutSeance.incidentTechnique,
          ),
        ),
        SortDuCours.nonTenu,
      );
    });

    test('un eleve absent reste un cours tenu : c\'est SA presence', () {
      expect(
        VueSuiviFoyer.sortDe(
          _seance(id: 'a', ilYAMinutes: 60, statut: StatutSeance.eleveAbsent),
        ),
        SortDuCours.tenu,
      );
    });

    test('un statut illisible vaut tenu, jamais non tenu', () {
      // `depuisSql` rend `null` quand la base emet une valeur que cette version
      // ne connait pas : en deduire un incident inventerait un fait.
      expect(
        VueSuiviFoyer.sortDe(_seance(id: 'a', ilYAMinutes: 60, statut: null)),
        SortDuCours.tenu,
      );
    });
  });

  group('TUT-06 : invariant J3, inconnu n\'est pas absence', () {
    test('une presence indisponible laisse l\'historique lisible', () {
      final VueSuiviFoyer vue = VueSuiviFoyer.depuis(
        seances: <Seance>[
          _seance(id: 'a', ilYAMinutes: 60),
          _seance(id: 'b', ilYAMinutes: 10080),
        ],
        presences: null,
        maintenant: _maintenant,
      );

      expect(vue.lignes.length, 2);
      for (final LigneSuivi ligne in vue.lignes) {
        expect(ligne.presence.etat, EtatPresence.inconnu);
        expect(ligne.montrePresence, isTrue);
      }
    });

    test('un cours sans ligne de presence dit inconnu, pas absence', () {
      final VueSuiviFoyer vue = VueSuiviFoyer.depuis(
        seances: <Seance>[_seance(id: 'a', ilYAMinutes: 60)],
        presences: const <PresenceParticipant>[],
        maintenant: _maintenant,
      );

      expect(vue.lignes.single.presence.etat, EtatPresence.inconnu);
    });
  });

  group('TUT-06 : chaque etat retrouve son cours ET son enfant', () {
    test('deux enfants, deux cours, aucun croisement', () {
      final VueSuiviFoyer vue = VueSuiviFoyer.depuis(
        seances: <Seance>[
          _seance(id: 'cours-sofia', ilYAMinutes: 60),
          _seance(
            id: 'cours-ines',
            ilYAMinutes: 120,
            eleveId: 'enf-2',
            elevePrenom: 'Ines',
          ),
        ],
        presences: <PresenceParticipant>[
          _presence(
            seanceId: 'cours-sofia',
            profilId: 'enf-1',
            etat: EtatPresence.finalisee,
          ),
          _presence(
            seanceId: 'cours-ines',
            profilId: 'enf-2',
            etat: EtatPresence.absente,
          ),
          // Le meme enfant, un autre cours : sans la seance dans la cle, cette
          // ligne ecraserait la precedente.
          _presence(
            seanceId: 'cours-oublie',
            profilId: 'enf-1',
            etat: EtatPresence.absente,
          ),
        ],
        maintenant: _maintenant,
      );

      final Map<String, EtatPresence> parCours = <String, EtatPresence>{
        for (final LigneSuivi l in vue.lignes) l.seance.id: l.presence.etat,
      };
      expect(parCours['cours-sofia'], EtatPresence.finalisee);
      expect(parCours['cours-ines'], EtatPresence.absente);
    });

    test('la ligne d\'un autre profil sur le meme cours n\'est pas prise', () {
      final VueSuiviFoyer vue = VueSuiviFoyer.depuis(
        seances: <Seance>[_seance(id: 'a', ilYAMinutes: 60)],
        presences: <PresenceParticipant>[
          // Un tuteur qui assiste laisse sa propre ligne sur la seance : elle ne
          // doit jamais passer pour celle de l'enfant.
          _presence(
            seanceId: 'a',
            profilId: 'tuteur-1',
            etat: EtatPresence.presente,
          ),
        ],
        maintenant: _maintenant,
      );

      expect(vue.lignes.single.presence.etat, EtatPresence.inconnu);
    });
  });

  group('TUT-06 : les facettes et le filtre', () {
    test('un enfant par facette, comptees avant filtre et triees par prenom', () {
      final VueSuiviFoyer vue = VueSuiviFoyer.depuis(
        seances: <Seance>[
          _seance(id: 'a', ilYAMinutes: 60),
          _seance(id: 'b', ilYAMinutes: 120),
          _seance(
            id: 'c',
            ilYAMinutes: 180,
            eleveId: 'enf-2',
            elevePrenom: 'Ines',
          ),
        ],
        presences: const <PresenceParticipant>[],
        maintenant: _maintenant,
      );

      expect(vue.enfants.map((FacetteEnfant e) => e.prenom), <String>[
        'Ines',
        'Sofia',
      ]);
      expect(vue.enfants.first.nombre, 1);
      expect(vue.enfants.last.nombre, 2);
      expect(vue.total, 3);
    });

    test('retenir un enfant ne garde que ses cours', () {
      final VueSuiviFoyer vue = VueSuiviFoyer.depuis(
        seances: <Seance>[
          _seance(id: 'a', ilYAMinutes: 60),
          _seance(
            id: 'c',
            ilYAMinutes: 180,
            eleveId: 'enf-2',
            elevePrenom: 'Ines',
          ),
        ],
        presences: const <PresenceParticipant>[],
        maintenant: _maintenant,
        enfantId: 'enf-2',
      );

      expect(vue.lignes.single.seance.id, 'c');
      // Le total ne bouge pas : il compte ce que la lecture a rendu, et c'est
      // lui qui distingue une impasse de filtre d'un foyer sans cours.
      expect(vue.total, 2);
      expect(vue.impasseDeFiltre, isFalse);
    });

    test('un filtre sans resultat est une impasse, pas un foyer vide', () {
      final VueSuiviFoyer vue = VueSuiviFoyer.depuis(
        seances: <Seance>[_seance(id: 'a', ilYAMinutes: 60)],
        presences: const <PresenceParticipant>[],
        maintenant: _maintenant,
        enfantId: 'enf-inconnu',
      );

      expect(vue.lignes, isEmpty);
      expect(vue.impasseDeFiltre, isTrue);
    });

    test('un foyer sans cours n\'est pas une impasse', () {
      final VueSuiviFoyer vue = VueSuiviFoyer.depuis(
        seances: const <Seance>[],
        presences: const <PresenceParticipant>[],
        maintenant: _maintenant,
      );

      expect(vue.impasseDeFiltre, isFalse);
      expect(vue.tronquee, isFalse);
    });
  });

  group('TUT-06 : le pied de liste ne ment pas sur ce qu\'il montre', () {
    test('une lecture au plafond se declare tronquee', () {
      final List<Seance> pleine = <Seance>[
        for (int i = 0; i < 4; i++) _seance(id: 'c$i', ilYAMinutes: 60 * (i + 1)),
      ];

      expect(
        VueSuiviFoyer.depuis(
          seances: pleine,
          presences: const <PresenceParticipant>[],
          maintenant: _maintenant,
          plafond: 4,
        ).tronquee,
        isTrue,
      );
      expect(
        VueSuiviFoyer.depuis(
          seances: pleine,
          presences: const <PresenceParticipant>[],
          maintenant: _maintenant,
          plafond: 5,
        ).tronquee,
        isFalse,
      );
    });
  });
}
