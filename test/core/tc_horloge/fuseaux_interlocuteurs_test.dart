// FUSEAUX, partie client : lecture de horloge_interlocuteurs, heure murale
// par « instant UTC + decalage », et jamais une heure fausse apres un
// changement d'heure que le serveur n'a pas decrit.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_horloge/fuseaux_interlocuteurs.dart';
import 'package:rewayah_academy/core/tc_horloge/heure_double.dart';

Map<String, Object?> _paris({bool avecApres = true}) => <String, Object?>{
  'fuseau': 'Europe/Paris',
  'decalage_secondes': 7200,
  'prochain_changement': '2026-10-25T01:00:00+00:00',
  if (avecApres) 'decalage_apres': 3600,
  if (avecApres) 'changement_suivant': '2027-03-28T01:00:00+00:00',
};

const Map<String, Object?> _abidjan = <String, Object?>{
  'fuseau': 'Africa/Abidjan',
  'decalage_secondes': 0,
  'prochain_changement': null,
  'decalage_apres': null,
  'changement_suivant': null,
};

void main() {
  setUp(() => LocaleSettings.setLocale(AppLocale.fr));

  group('FuseauVu', () {
    test('avant le changement : instant UTC plus le decalage actuel', () {
      final FuseauVu f = FuseauVu.lire(_paris())!;
      expect(f.heureA(DateTime.utc(2026, 10, 20, 6)), '08:00');
    });

    test('apres le changement : le decalage d apres, donne par le serveur', () {
      final FuseauVu f = FuseauVu.lire(_paris())!;
      expect(f.heureA(DateTime.utc(2026, 10, 27, 7)), '08:00');
    });

    test('apres le changement suivant : heure non sure, jamais fausse', () {
      final FuseauVu f = FuseauVu.lire(_paris())!;
      expect(f.heureA(DateTime.utc(2027, 4, 2, 7)), isNull);
    });

    test('serveur sans decalage_apres : rien apres le changement', () {
      final FuseauVu f = FuseauVu.lire(_paris(avecApres: false))!;
      expect(f.heureA(DateTime.utc(2026, 10, 20, 6)), '08:00');
      expect(f.heureA(DateTime.utc(2026, 10, 27, 7)), isNull);
    });

    test('un fuseau sans heure d ete vaut toute l annee', () {
      final FuseauVu f = FuseauVu.lire(_abidjan)!;
      expect(f.heureA(DateTime.utc(2027, 7, 1, 6)), '06:00');
    });

    test('un objet incomplet ne fabrique aucune heure', () {
      expect(FuseauVu.lire(null), isNull);
      expect(
        FuseauVu.lire(<String, Object?>{'fuseau': 'Europe/Paris'}),
        isNull,
      );
      expect(
        FuseauVu.lire(<String, Object?>{'fuseau': '', 'decalage_secondes': 0}),
        isNull,
      );
    });
  });

  group('InterlocuteursClasse', () {
    test('sans maintenant lisible : erreur, pas une heure inventee', () {
      expect(
        () => InterlocuteursClasse.lire(<String, Object?>{'moi': _paris()}),
        throwsFormatException,
      );
    });

    test('la relecture est fixee au premier changement d heure lu', () {
      final InterlocuteursClasse lus = InterlocuteursClasse.lire(
        <String, Object?>{
          'maintenant': '2026-10-20T06:00:00Z',
          'moi': _paris(),
          'enseignant': const <String, Object?>{
            ..._abidjan,
            'source': 'enseignant',
          },
        },
      );
      expect(lus.relireA, DateTime.utc(2026, 10, 25, 1));
    });
  });

  group('lignesInterlocuteurs', () {
    test('famille : « Chez Sayyid Karim », titre enregistre et pays', () {
      final InterlocuteursClasse lus = InterlocuteursClasse.lire(
        <String, Object?>{
          'maintenant': '2026-10-20T06:00:00Z',
          'moi': _paris(),
          'enseignant': const <String, Object?>{
            ..._abidjan,
            'titre': 'sayyid',
            'prenom': 'Karim',
            'pays': 'CI',
            'remplacant': false,
            'source': 'enseignant',
          },
        },
      );
      final List<LigneHeure> l = lignesInterlocuteurs(
        lus,
        DateTime.utc(2026, 10, 20, 6),
      );
      expect(l, hasLength(1));
      expect(l.single.libelle, 'Chez Sayyid Karim');
      expect(l.single.heure, '06:00');
      expect(l.single.ville, 'Abidjan');
      expect(l.single.pays, 'CI');
    });

    test('titre absent : jamais deduit du prenom', () {
      final InterlocuteursClasse lus = InterlocuteursClasse.lire(
        <String, Object?>{
          'maintenant': '2026-10-20T06:00:00Z',
          'moi': _paris(),
          'enseignant': const <String, Object?>{
            ..._abidjan,
            'prenom': 'Amina',
            'source': 'enseignant',
          },
        },
      );
      expect(
        lignesInterlocuteurs(lus, DateTime.utc(2026, 10, 20, 6)).single.libelle,
        'Chez Amina',
      );
    });

    test('fuseau de l enseignant vide : « Heure de la classe », sans pays', () {
      final InterlocuteursClasse lus = InterlocuteursClasse.lire(
        <String, Object?>{
          'maintenant': '2026-10-20T06:00:00Z',
          'moi': _paris(),
          'enseignant': const <String, Object?>{
            ..._abidjan,
            'titre': 'sayyida',
            'prenom': 'Amina',
            'pays': 'CI',
            'source': 'classe',
          },
        },
      );
      final LigneHeure l = lignesInterlocuteurs(
        lus,
        DateTime.utc(2026, 10, 20, 6),
      ).single;
      expect(l.libelle, t.tc.groupe.horloges.heureGroupe);
      expect(l.pays, isNull);
    });

    test('enseignant : le nombre de familles par fuseau, jamais un nom', () {
      final InterlocuteursClasse lus = InterlocuteursClasse.lire(
        <String, Object?>{
          'maintenant': '2026-10-20T06:00:00Z',
          'moi': _abidjan,
          'familles': <Object?>[
            <String, Object?>{..._paris(), 'familles': 2},
            const <String, Object?>{..._abidjan, 'familles': 1},
          ],
        },
      );
      final List<LigneHeure> l = lignesInterlocuteurs(
        lus,
        DateTime.utc(2026, 10, 20, 6),
      );
      // Abidjan est le fuseau de l'enseignant : une seule ligne, Paris.
      expect(l, hasLength(1));
      expect(l.single.libelle, '2 familles');
      expect(l.single.heure, '08:00');
      expect(l.single.ville, 'Paris');
    });

    test('heure non sure : la ligne reste, sans heure', () {
      final InterlocuteursClasse lus = InterlocuteursClasse.lire(
        <String, Object?>{
          'maintenant': '2026-10-20T06:00:00Z',
          'moi': _abidjan,
          'familles': <Object?>[
            <String, Object?>{..._paris(avecApres: false), 'familles': 1},
          ],
        },
      );
      final LigneHeure l = lignesInterlocuteurs(
        lus,
        DateTime.utc(2026, 11, 2, 7),
      ).single;
      expect(l.libelle, '1 famille');
      expect(l.heure, isNull);
    });
  });
}
