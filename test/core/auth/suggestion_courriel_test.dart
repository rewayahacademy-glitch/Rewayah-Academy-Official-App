// PE-A8 (retours terrain R25) : « Vouliez-vous dire gmail.com ? ».
// Ce que le test prouve : les fautes relevees sur le terrain (gmail.coma,
// gamil.com, gmail.co ; pas geml.com, trop loin) et les fautes courantes (gmial, gmail.con,
// hotmial, yaho) recoivent une proposition ; un domaine courant juste, un vrai
// domaine proche (mail.com, gmx.de, email.com, mtn.com, cloud.com, gmail.ru),
// un domaine d'universite ou d'entreprise n'en recoivent aucune ; seuls les
// domaines tres courants sont proposes ; la partie avant « @ » n'est jamais
// touchee.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/auth/suggestion_courriel.dart';

void main() {
  test('les fautes du terrain et les fautes courantes sont proposees', () {
    const Map<String, String> attendu = <String, String>{
      'ali@gmial.com': 'ali@gmail.com',
      'ali@gmail.con': 'ali@gmail.com',
      'ali@gmail.coma': 'ali@gmail.com',
      'ali@gamil.com': 'ali@gmail.com',
      'ali@gmail.co': 'ali@gmail.com',
      'ali@gmal.com': 'ali@gmail.com',
      'ali@gmail': 'ali@gmail.com',
      'ali@gmailcom': 'ali@gmail.com',
      'ali@hotmial.com': 'ali@hotmail.com',
      'ali@hotmail.con': 'ali@hotmail.com',
      'ali@yaho.com': 'ali@yahoo.com',
      'ali@yahoo.fe': 'ali@yahoo.fr',
      'ali@outlok.com': 'ali@outlook.com',
      'ali@icloud.co': 'ali@icloud.com',
    };
    for (final MapEntry<String, String> e in attendu.entries) {
      expect(proposerCourriel(e.key), e.value, reason: e.key);
    }
  });

  test('la partie avant « @ » reste telle quelle, majuscules comprises', () {
    expect(
      proposerCourriel(' Fatou.Diallo@GMIAL.COM '),
      'Fatou.Diallo@gmail.com',
    );
  });

  test(
    'rien a proposer : domaine juste, vrai domaine proche, domaine inconnu',
    () {
      for (final String a in <String>[
        'ali@gmail.com',
        'ali@GMAIL.COM',
        'ali@yahoo.fr',
        'ali@mail.com',
        'ali@gmx.de',
        'ali@me.com',
        'ali@univ-paris.fr',
        'ali@rewayahacademy.com',
        'ali@ksu.edu.sa',
        'ali@orange.sn',
        'ali@yahoo.co.jp',
        'ali@outlook.sa',
        'ali@hotmail.de',
        // Relecture de la PR 660 : de vrais domaines, proches d'un domaine
        // courant, ne recoivent aucune proposition.
        'ali@email.com',
        'ali@mtn.com',
        'ali@cloud.com',
        'ali@gmail.ru',
        'ali@gmx.com',
        'ali@gmx.net',
        'ali@ymail.com',
        'ali@live.fr',
        'ali@mac.com',
        'ali@gail.com',
        'ali@msn.com',
        'ali@msm.com',
        'ali@hotmail.ca',
        'ali@hotmail.com.tr',
        'ali@protonmail.ch',
        'ali@yahoo.co.in',
        'a@b@gmial.com',
        'ali',
        'ali@',
        '@gmial.com',
        '',
      ]) {
        expect(proposerCourriel(a), isNull, reason: a);
      }
    },
  );

  test('distance : une inversion de deux lettres compte pour une faute', () {
    expect(distanceDomaines('gmial', 'gmail'), 1);
    expect(distanceDomaines('gmail.com', 'gmail.com'), 0);
    // Limite connue : « geml.com » (releve du terrain, R25) est a trois
    // fautes de « gmail.com » ; au-dela de deux, des domaines reels se
    // confondraient : rien n'est propose.
    expect(distanceDomaines('geml.com', 'gmail.com'), 3);
    expect(proposerCourriel('ali@geml.com'), isNull);
  });
}
