// HORLOGE-ET-LIEU, partie B (13/11/2026, architecte) : la regle des trois cas.
// A l'ecran : sans ville choisie, l'heure de l'appareil, dite ; avec une ville
// choisie, l'heure de la ville ; si l'appareil et la ville divergent (voyage),
// l'heure de l'appareil, dite, sans rien modifier au lieu enregistre.
//
// Les attendus se calculent a partir du fuseau de la machine de test : le
// resultat ne depend pas de l'endroit ou le test tourne.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_horloge/mon_horloge.dart';

final DateTime _instant = DateTime.utc(2026, 11, 18, 18);

Map<String, Object?> _fuseau(String nom, Duration decalage) =>
    <String, Object?>{
      'fuseau': nom,
      'decalage_secondes': decalage.inSeconds,
      'prochain_changement': null,
    };

void _poser(Duration decalageVille, {bool? lieuChoisi}) {
  poserMonHorlogePourTest(
    MonHorloge.lire(<String, Object?>{
      'maintenant': '2026-11-12T22:00:00Z',
      'moi': _fuseau('Test/Ville', decalageVille),
      'academie': _fuseau('Asia/Riyadh', const Duration(hours: 3)),
      'lieu_choisi': ?lieuChoisi,
    }),
  );
}

String _hhmm(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

void main() {
  tearDown(() => poserMonHorlogePourTest(null));

  final Duration appareil = _instant.toLocal().timeZoneOffset;
  final Duration ailleurs = appareil + const Duration(hours: 2);

  test('cas 1 : sans ville choisie, l heure de l appareil, et on le dit', () {
    _poser(ailleurs, lieuChoisi: false);
    expect(estHeureDeLAppareil(_instant), isTrue);
    expect(fuseauChezMoi(_instant), isNull);
    expect(heureChezMoi(_instant), _hhmm(_instant.toLocal()));
  });

  test('cas 2 : ville choisie et appareil d accord, l heure de la ville', () {
    _poser(appareil, lieuChoisi: true);
    expect(estHeureDeLAppareil(_instant), isFalse);
    expect(fuseauChezMoi(_instant), 'Test/Ville');
    expect(heureChezMoi(_instant), _hhmm(_instant.add(appareil)));
  });

  test('cas 3 : ville choisie, appareil ailleurs (voyage), l heure de '
      'l appareil, dite ; le lieu enregistre n est pas touche', () {
    _poser(ailleurs, lieuChoisi: true);
    expect(estHeureDeLAppareil(_instant), isTrue);
    expect(fuseauChezMoi(_instant), isNull);
    expect(heureChezMoi(_instant), _hhmm(_instant.toLocal()));
    // Rien n'est modifie : la lecture garde la ville et son fuseau.
    expect(_lecture().moi?.fuseau, 'Test/Ville');
    expect(_lecture().lieuChoisi, isTrue);
  });

  test('un serveur qui ne dit pas lieu_choisi garde l ancien comportement '
      '(le fuseau du profil)', () {
    _poser(ailleurs);
    expect(estHeureDeLAppareil(_instant), isFalse);
    expect(heureChezMoi(_instant), _hhmm(_instant.add(ailleurs)));
  });

  test('La Mecque en second suit l heure affichee : l appareil a La Mecque '
      'ne montre pas de seconde heure, la ville a La Mecque non plus', () {
    // Appareil dont le decalage est celui de La Mecque, sans ville choisie.
    _poser(const Duration(hours: 5), lieuChoisi: false);
    expect(
      heureMecqueSiDifferente(_instant),
      appareil == const Duration(hours: 3) ? isNull : '21:00',
    );
    // Ville choisie a La Mecque, appareil d'accord.
    _poser(const Duration(hours: 3), lieuChoisi: true);
    expect(
      heureMecqueSiDifferente(_instant),
      appareil == const Duration(hours: 3) ? isNull : '21:00',
    );
  });
}

MonHorloge _lecture() => MonHorloge.lire(<String, Object?>{
  'maintenant': '2026-11-12T22:00:00Z',
  'moi': _fuseau('Test/Ville', const Duration(hours: 1)),
  'lieu_choisi': true,
});
