// RECH-1 : la forme de comparaison d'un texte de recherche, et les bornes de
// la requete (spec §6.2, §6.4).

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/recherche/budgets_recherche.dart';
import 'package:rewayah_academy/core/recherche/modeles_recherche.dart';
import 'package:rewayah_academy/core/recherche/normalisation_recherche.dart';

void main() {
  group('normaliserPourRecherche', () {
    test('al-fatiha trouve Al-Fātiḥa (translitteration repliee)', () {
      expect(
        correspondTousLesTermes(
          normaliserPourRecherche('Al-Fātiḥa'),
          normaliserPourRecherche('al-fatiha'),
        ),
        isTrue,
      );
    });

    test('accents francais, apostrophes et traits d\'union', () {
      expect(
        normaliserPourRecherche('Récitation d\'Ibrâhim'),
        'recitation dibrahim',
      );
      expect(normaliserPourRecherche('Nour al-Bayân'), 'nour al bayan');
    });

    test('arabe : sans voyelles breves, formes de l\'alif reunies', () {
      expect(
        normaliserPourRecherche('ٱلْفَاتِحَةِ') ==
            normaliserPourRecherche('ٱلفاتحة'),
        isTrue,
      );
      expect(normaliserPourRecherche('أحمد'), normaliserPourRecherche('احمد'));
    });

    test('un terme absent refuse la correspondance', () {
      expect(
        correspondTousLesTermes('classe al fatiha 1', 'fatiha lecture'),
        isFalse,
      );
      expect(correspondTousLesTermes('classe al fatiha 1', ''), isFalse);
    });
  });

  group('RequeteNormalisee', () {
    const ContexteRecherche commun = ContexteRecherche(
      espace: EspaceRecherche.famille,
    );
    const ContexteRecherche borne = ContexteRecherche(
      espace: EspaceRecherche.eleve,
      domaineCible: DomaineRecherche.supports,
    );

    test('champ vide : rien a chercher', () {
      expect(
        RequeteNormalisee.de('   ', commun).validite,
        ValiditeRequete.vide,
      );
    });

    test('moins de 3 caracteres : trop courte, aucun appel', () {
      expect(
        RequeteNormalisee.de('al', commun).validite,
        ValiditeRequete.tropCourte,
      );
      expect(
        RequeteNormalisee.de('alf', commun).validite,
        ValiditeRequete.valide,
      );
    });

    test('un mot arabe court n\'est admis que dans un domaine borne', () {
      expect(
        RequeteNormalisee.de('نور', commun).validite,
        ValiditeRequete.valide,
      );
      expect(
        RequeteNormalisee.de('نو', commun).validite,
        ValiditeRequete.tropCourte,
      );
      expect(
        RequeteNormalisee.de('نو', borne).validite,
        ValiditeRequete.valide,
      );
    });

    test('160 caracteres et 8 termes au plus', () {
      final RequeteNormalisee longue = RequeteNormalisee.de('a' * 400, commun);
      expect(longue.texte.length, BudgetsRecherche.longueurMaximale);
      final RequeteNormalisee termes = RequeteNormalisee.de(
        'un deux trois quatre cinq six sept huit neuf dix',
        commun,
      );
      expect(termes.texte.split(' ').length, BudgetsRecherche.termesMaximum);
    });

    test('les espaces multiples sont replies', () {
      expect(RequeteNormalisee.de('  al   fatiha ', commun).texte, 'al fatiha');
    });
  });

  group('coupe a 160 sur les runes (RECH-REC E1)', () {
    const ContexteRecherche contexte = ContexteRecherche(
      espace: EspaceRecherche.famille,
    );

    test('un emoji a la frontiere n\'est pas coupe en deux', () {
      final RequeteNormalisee q = RequeteNormalisee.de(
        '${'a' * 159}\u{1F600}fatiha',
        contexte,
      );
      expect(q.texte.runes.length, 160);
      expect(q.texte.endsWith('\u{1F600}'), isTrue);
      for (int i = 0; i < q.texte.length; i++) {
        final int u = q.texte.codeUnitAt(i);
        if (u >= 0xD800 && u <= 0xDBFF) {
          expect(q.texte.codeUnitAt(i + 1) & 0xFC00, 0xDC00);
          i++;
        } else {
          expect(u & 0xFC00, isNot(0xDC00));
        }
      }
    });

    test('160 emojis passent entiers, le 161e est retire', () {
      final RequeteNormalisee q = RequeteNormalisee.de(
        '\u{1F600}' * 170,
        contexte,
      );
      expect(q.texte.runes.length, 160);
    });
  });
}
