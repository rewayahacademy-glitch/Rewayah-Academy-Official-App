import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/presence/vue_presence.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';

/// L'instant de reference de tous les calculs de ce fichier.
///
/// Fige, jamais `DateTime.now()` : une duree qui se compare a l'horloge de la
/// machine donne un test qui passe le matin et echoue a la seconde pres.
final DateTime _maintenant = DateTime(2026, 9, 13, 10, 30);

PresenceParticipant _ligne(
  EtatPresence etat, {
  String profilId = 'p1',
  String role = 'student',
  String prenom = 'Maryam',
  bool consolide = false,
  DateTime? entreLe,
  DateTime? derniereTraceLe,
  DateTime? debutSeance,
}) => PresenceParticipant(
  profilId: profilId,
  role: role,
  prenom: prenom,
  identifiantImmuable: 'STUD-000001',
  etat: etat,
  consolide: consolide,
  entreLe: entreLe,
  derniereTraceLe: derniereTraceLe,
  debutSeance: debutSeance ?? _maintenant.subtract(const Duration(minutes: 20)),
);

VuePresence _vue(PresenceParticipant? ligne) =>
    VuePresence.depuis(ligne: ligne, maintenant: _maintenant);

void main() {
  group('J3 : un etat indisponible se dit inconnu, jamais absent', () {
    test('une presence illisible rend inconnu', () {
      final VuePresence vue = _vue(null);

      expect(vue.etat, EtatPresence.inconnu);
      expect(vue.etat, isNot(EtatPresence.absente));
      // Ni bon ni mauvais : ne pas savoir n'est pas une absence, et ne doit
      // donc ni alarmer ni rassurer.
      expect(vue.ton, TonEtat.neutre);
      expect(vue.repere, RepereTemps.aucun);
      expect(vue.ecoule, isNull);
    });

    test('un etat que cette version ne connait pas retombe sur inconnu', () {
      // Le jour ou la base gagnerait un quinzieme etat, une application non
      // mise a jour doit dire « je ne sais pas », jamais affirmer une absence
      // qu'elle n'a pas lue.
      expect(EtatPresence.depuisSql('teleporte'), EtatPresence.inconnu);
      expect(EtatPresence.depuisSql(null), EtatPresence.inconnu);
      expect(EtatPresence.depuisSql(''), EtatPresence.inconnu);
    });

    test('les quatorze etats de la base se lisent tous', () {
      // L'invariant J4 : aucun etat n'est ni ajoute ni retire. Quatorze plus
      // l'inconnu, qui n'est pas un etat de la base.
      expect(EtatPresence.values.length, 15);
      for (final EtatPresence etat in EtatPresence.values) {
        if (etat == EtatPresence.inconnu) {
          continue;
        }
        expect(
          EtatPresence.depuisSql(etat.valeurSql),
          etat,
          reason: '${etat.valeurSql} doit se relire',
        );
      }
    });
  });

  group('J7 : un etat critique porte toujours plus qu\'une couleur', () {
    test('les cinq etats qui appellent une reaction sont dits critiques', () {
      expect(EtatPresence.deconnectee.critique, isTrue);
      expect(EtatPresence.enReconnexion.critique, isTrue);
      expect(EtatPresence.absente.critique, isTrue);
      expect(EtatPresence.enRetard.critique, isTrue);
      expect(EtatPresence.inconnu.critique, isTrue);

      expect(EtatPresence.presente.critique, isFalse);
      expect(EtatPresence.finalisee.critique, isFalse);
    });

    test('tout etat critique porte une duree ou un mot, jamais rien', () {
      // La verification est indirecte mais c'est la bonne : un etat critique
      // qui n'aurait ni repere ni contexte se reduirait a sa pastille, donc a
      // sa couleur -- et `StatusPill` lui donne au moins son libelle.
      for (final EtatPresence etat in EtatPresence.values) {
        if (!etat.critique) {
          continue;
        }
        expect(
          VuePresence.depuis(
            ligne: _ligne(
              etat,
              entreLe: _maintenant.subtract(const Duration(minutes: 12)),
              derniereTraceLe: _maintenant.subtract(
                const Duration(minutes: 4),
              ),
            ),
            maintenant: _maintenant,
          ).etat,
          etat,
        );
      }
    });
  });

  group('La duree dit ce qu\'elle mesure', () {
    test('present : depuis l\'entree', () {
      final VuePresence vue = _vue(
        _ligne(
          EtatPresence.presente,
          entreLe: _maintenant.subtract(const Duration(minutes: 12)),
        ),
      );

      expect(vue.repere, RepereTemps.entree);
      expect(vue.ecoule, const Duration(minutes: 12));
      expect(vue.ton, TonEtat.succes);
    });

    test('en retard : contre l\'heure prevue, pas contre maintenant', () {
      // Le cours a commence il y a vingt minutes, l'eleve est entre il y a
      // huit : son retard est de douze minutes, et surtout pas de huit.
      final VuePresence vue = _vue(
        _ligne(
          EtatPresence.enRetard,
          entreLe: _maintenant.subtract(const Duration(minutes: 8)),
        ),
      );

      expect(vue.repere, RepereTemps.retard);
      expect(vue.ecoule, const Duration(minutes: 12));
      expect(vue.ton, TonEtat.avertissement);
    });

    test('deconnecte : depuis la derniere trace', () {
      final VuePresence vue = _vue(
        _ligne(
          EtatPresence.deconnectee,
          entreLe: _maintenant.subtract(const Duration(minutes: 18)),
          derniereTraceLe: _maintenant.subtract(const Duration(minutes: 5)),
        ),
      );

      expect(vue.repere, RepereTemps.silence);
      expect(vue.ecoule, const Duration(minutes: 5));
      expect(vue.ton, TonEtat.alerte);
    });

    test('pas encore la : depuis le debut du cours', () {
      final VuePresence vue = _vue(_ligne(EtatPresence.enAttente));

      expect(vue.repere, RepereTemps.attente);
      expect(vue.ecoule, const Duration(minutes: 20));
    });

    test('une duree negative ne s\'affiche pas a l\'envers', () {
      // Une seance qui commence dans dix minutes, et une horloge d'appareil
      // qui aurait pris de l'avance : mieux vaut taire une duree que dire
      // « le cours a commence il y a -10 min ».
      final VuePresence vue = _vue(
        _ligne(
          EtatPresence.enAttente,
          debutSeance: _maintenant.add(const Duration(minutes: 10)),
        ),
      );

      expect(vue.repere, RepereTemps.aucun);
      expect(vue.ecoule, isNull);
    });

    test('un etat sans trace ne date rien', () {
      final VuePresence vue = _vue(_ligne(EtatPresence.presente));

      expect(vue.repere, RepereTemps.aucun);
      expect(vue.ecoule, isNull);
    });
  });

  group('Provisoire contre consolide', () {
    test('un etat calcule n\'est pas consolide', () {
      expect(_vue(_ligne(EtatPresence.presente)).consolide, isFalse);
    });

    test('une decision humaine consolide', () {
      expect(
        _vue(_ligne(EtatPresence.excusee, consolide: true)).consolide,
        isTrue,
      );
    });
  });

  group('Le tableau de presence', () {
    test('les eleves d\'abord, par prenom, l\'enseignant ensuite', () {
      final List<PresenceParticipant> trie = tableauDePresence(
        <PresenceParticipant>[
          _ligne(
            EtatPresence.presente,
            profilId: 'e1',
            role: 'teacher',
            prenom: 'Yacine',
          ),
          _ligne(EtatPresence.presente, profilId: 'p2', prenom: 'Zineb'),
          _ligne(EtatPresence.absente, profilId: 'p3', prenom: 'Adam'),
        ],
      );

      expect(
        trie.map((PresenceParticipant p) => p.prenom).toList(),
        <String>['Adam', 'Zineb', 'Yacine'],
      );
    });

    test('l\'ordre ne depend jamais de l\'etat', () {
      // La liste se relit toutes les vingt secondes : une ligne qui
      // remonterait d'elle-meme entre deux regards se ferait toucher a la
      // place d'une autre.
      final List<PresenceParticipant> avant = tableauDePresence(
        <PresenceParticipant>[
          _ligne(EtatPresence.presente, profilId: 'p1', prenom: 'Adam'),
          _ligne(EtatPresence.presente, profilId: 'p2', prenom: 'Zineb'),
        ],
      );
      final List<PresenceParticipant> apres = tableauDePresence(
        <PresenceParticipant>[
          _ligne(EtatPresence.deconnectee, profilId: 'p1', prenom: 'Adam'),
          _ligne(EtatPresence.presente, profilId: 'p2', prenom: 'Zineb'),
        ],
      );

      expect(
        avant.map((PresenceParticipant p) => p.profilId).toList(),
        apres.map((PresenceParticipant p) => p.profilId).toList(),
      );
    });

    test('une presence indisponible rend une liste vide, pas une exception', () {
      expect(tableauDePresence(null), isEmpty);
    });
  });

  group('Ma propre ligne', () {
    test('se retrouve par le profil', () {
      final PresenceParticipant? mienne = maPresence(<PresenceParticipant>[
        _ligne(EtatPresence.presente, profilId: 'p1'),
        _ligne(EtatPresence.absente, profilId: 'p2'),
      ], 'p2');

      expect(mienne?.etat, EtatPresence.absente);
    });

    test('vaut null quand elle n\'y est pas, et ce n\'est pas une anomalie', () {
      // Un controleur n'a aucune ligne lisible, pas meme la sienne : la vue le
      // lui refuse en base (ADR-011). L'ecran affichera l'inconnu.
      expect(
        maPresence(<PresenceParticipant>[
          _ligne(EtatPresence.presente, profilId: 'p1'),
        ], 'ctrl'),
        isNull,
      );
      expect(maPresence(null, 'p1'), isNull);
      expect(
        maPresence(<PresenceParticipant>[_ligne(EtatPresence.presente)], null),
        isNull,
      );
    });
  });

  group('La lecture d\'une ligne de la base', () {
    test('une ligne complete se lit', () {
      final PresenceParticipant ligne = PresenceParticipant.depuisJson(
        const <String, dynamic>{
          'profile_id': 'p1',
          'role': 'student',
          'prenom': 'Maryam',
          'identifiant_immuable': 'STUD-000001',
          'etat': 'en_retard',
          'consolide': false,
          'entre_le': '2026-09-13T08:38:00Z',
          'derniere_trace_le': '2026-09-13T08:40:00Z',
          'started_at': '2026-09-13T08:30:00Z',
        },
      );

      expect(ligne.etat, EtatPresence.enRetard);
      expect(ligne.prenom, 'Maryam');
      expect(ligne.estEnseignant, isFalse);
      expect(ligne.entreLe, isNotNull);
    });

    test('une ligne vide ne fabrique aucun etat', () {
      final PresenceParticipant ligne = PresenceParticipant.depuisJson(
        const <String, dynamic>{},
      );

      expect(ligne.etat, EtatPresence.inconnu);
      expect(ligne.consolide, isFalse);
      expect(ligne.entreLe, isNull);
    });
  });
}
