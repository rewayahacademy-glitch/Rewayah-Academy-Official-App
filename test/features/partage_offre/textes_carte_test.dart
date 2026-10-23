// CAND-06 : les textes de la carte a partager, dans ses quatre langues (le
// francais, l'anglais, le portugais et l'arabe, et seulement ces quatre :
// directeur, 22/10/2026). Ils vivent dans un fichier de donnees
// (`textes_carte.dart`), jamais dans le dessin de la carte ; ce test garantit
// que chaque langue porte tous ses textes, que rien n'y est vide, et que les
// regles de la carte tiennent dans chacune : aucun prix, aucune promesse,
// jamais l'academie comme motif, « classe » et jamais « groupe », pas de tiret
// long, un hadith et une signature qui ne changent pas d'une langue a l'autre.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/partage_offre/personnalisation_carte.dart';
import 'package:rewayah_academy/features/partage_offre/textes_carte.dart';

/// Le hadith, tel que le directeur l'ecrit (22/10/2026).
const String _hadith = 'الدال على الخير كفاعله';

/// La signature arabe de la marque (M-26, 20/10/2026).
const String _signature = 'بوّابتك نحو القرآن';

/// Les textes d'une langue, champ par champ : le nom du champ et sa valeur.
Map<String, String?> _champs(TextesCarte t) => <String, String?>{
  'nomPropre': t.nomPropre,
  'titre': t.titre,
  'sousTitre': t.sousTitre,
  'decouvrir': t.decouvrir,
  'traduction': t.traduction,
  'reference': t.reference,
};

/// Le texte de la carte lisible : sans les espaces insecables.
String _lisible(String texte) => texte.replaceAll(' ', ' ');

final RegExp _arabe = RegExp('[؀-ۿ]');

void main() {
  test('une entree par langue de la carte, et pas une de plus', () {
    expect(textesCarte.keys.toSet(), LangueCarte.values.toSet());
    expect(textesCarte, hasLength(4));
  });

  group('chaque langue a tous ses textes', () {
    for (final LangueCarte langue in LangueCarte.values) {
      test('${langue.code} : aucun champ vide', () {
        final Map<String, String?> champs = _champs(textesCarte[langue]!);
        for (final MapEntry<String, String?> e in champs.entries) {
          // L'arabe n'a pas de traduction : le hadith se lit tel quel.
          if (e.key == 'traduction' && langue == LangueCarte.arabe) {
            expect(e.value, isNull, reason: 'pas de traduction en arabe');
            continue;
          }
          expect(e.value, isNotNull, reason: '${langue.code} : ${e.key}');
          expect(
            e.value!.trim(),
            isNotEmpty,
            reason: '${langue.code} : ${e.key}',
          );
        }
      });
    }

    test(
      'les memes champs, donc les memes textes, dans les quatre langues',
      () {
        final Set<String> reference = _champs(
          textesCarte[LangueCarte.francais]!,
        ).keys.toSet();
        for (final LangueCarte langue in LangueCarte.values) {
          expect(_champs(textesCarte[langue]!).keys.toSet(), reference);
        }
      },
    );

    test('un texte propre a sa langue : deux langues ne se recopient pas', () {
      for (final String champ in <String>[
        'titre',
        'sousTitre',
        'decouvrir',
        'reference',
        'nomPropre',
      ]) {
        final List<String?> valeurs = <String?>[
          for (final LangueCarte l in LangueCarte.values)
            _champs(textesCarte[l]!)[champ],
        ];
        expect(valeurs.toSet(), hasLength(valeurs.length), reason: champ);
      }
    });

    test('le nom d\'une langue est ecrit dans cette langue', () {
      expect(textesCarte[LangueCarte.francais]!.nomPropre, 'Français');
      expect(textesCarte[LangueCarte.anglais]!.nomPropre, 'English');
      expect(textesCarte[LangueCarte.portugais]!.nomPropre, 'Português');
      expect(textesCarte[LangueCarte.arabe]!.nomPropre, 'العربية');
    });
  });

  test('la signature de la marque et le hadith sont ceux du directeur, '
      'identiques dans les quatre langues', () {
    expect(signatureArabe, _signature);
    expect(hadithArabe, _hadith);
  });

  group('l\'ecriture de chaque langue', () {
    test('le francais, l\'anglais et le portugais ne portent aucun caractere '
        'arabe', () {
      for (final LangueCarte langue in <LangueCarte>[
        LangueCarte.francais,
        LangueCarte.anglais,
        LangueCarte.portugais,
      ]) {
        for (final MapEntry<String, String?> e in _champs(
          textesCarte[langue]!,
        ).entries) {
          expect(
            _arabe.hasMatch(e.value ?? ''),
            isFalse,
            reason: '${langue.code} : ${e.key}',
          );
        }
      }
    });

    test('l\'arabe n\'a aucune lettre latine, hors du nom d\'une langue', () {
      final RegExp latin = RegExp('[A-Za-z]');
      for (final MapEntry<String, String?> e in _champs(
        textesCarte[LangueCarte.arabe]!,
      ).entries) {
        expect(latin.hasMatch(e.value ?? ''), isFalse, reason: e.key);
      }
    });

    test('la traduction du hadith est en guillemets, avec sa reference', () {
      expect(textesCarte[LangueCarte.francais]!.traduction, startsWith('« '));
      expect(textesCarte[LangueCarte.francais]!.traduction, endsWith(' »'));
      expect(
        textesCarte[LangueCarte.francais]!.reference,
        'Rapporté par at-Tirmidhi',
      );
      expect(
        textesCarte[LangueCarte.anglais]!.reference,
        'Narrated by at-Tirmidhi',
      );
      expect(
        textesCarte[LangueCarte.portugais]!.reference,
        'Narrado por at-Tirmidhi',
      );
      expect(textesCarte[LangueCarte.arabe]!.reference, 'رواه الترمذي');
    });
  });

  group('ce que la carte dit, dans chaque langue', () {
    test(
      'le titre dit ce que l\'eleve y gagne : le Coran, en petite classe',
      () {
        final String fr = _lisible(textesCarte[LangueCarte.francais]!.titre);
        expect(fr, 'Apprendre le Coran, en petite classe.');
        expect(
          _lisible(textesCarte[LangueCarte.anglais]!.titre),
          'Learn the Quran in a small class.',
        );
        expect(
          _lisible(textesCarte[LangueCarte.portugais]!.titre),
          'Aprender o Alcorão, em turma pequena.',
        );
        expect(
          _lisible(textesCarte[LangueCarte.arabe]!.titre),
          'تعلُّم القرآن في فصل صغير',
        );
      },
    );

    test('la ligne sous le titre : le meme enseignant', () {
      expect(
        textesCarte[LangueCarte.francais]!.sousTitre,
        'Avec le même enseignant.',
      );
      expect(
        textesCarte[LangueCarte.anglais]!.sousTitre,
        'With the same teacher.',
      );
      expect(
        textesCarte[LangueCarte.portugais]!.sousTitre,
        'Com o mesmo professor.',
      );
      expect(textesCarte[LangueCarte.arabe]!.sousTitre, 'مع المعلم نفسه.');
    });

    test('« Decouvrir l\'offre », dans chaque langue', () {
      expect(
        textesCarte[LangueCarte.francais]!.decouvrir,
        'Découvrir l\'offre',
      );
      expect(textesCarte[LangueCarte.anglais]!.decouvrir, 'Discover the offer');
      expect(textesCarte[LangueCarte.portugais]!.decouvrir, 'Conheça a oferta');
      expect(textesCarte[LangueCarte.arabe]!.decouvrir, 'اكتشاف العرض');
    });

    test('aucun prix, aucun montant, aucune promesse, aucun mot interdit, '
        'aucun tiret long', () {
      final RegExp montant = RegExp(
        r'[0-9٠-٩]+\s*(\$|€|usd|dollars?|euros?|دولار|يورو|%)|[$€]',
        caseSensitive: false,
      );
      final Map<LangueCarte, List<String>> interdits =
          <LangueCarte, List<String>>{
            LangueCarte.francais: <String>[
              'prix',
              'tarif',
              'gratuit',
              'garanti',
              'certifié',
              'rembours',
              'remise',
              'bourse',
              'essai',
              'groupe',
              'mode enfant',
            ],
            LangueCarte.anglais: <String>[
              'price',
              'fee',
              'free',
              'guarantee',
              'certified',
              'refund',
              'discount',
              'scholarship',
              'trial',
              'group',
            ],
            LangueCarte.portugais: <String>[
              'preço',
              'preco',
              'tarifa',
              'grátis',
              'gratis',
              'gratuito',
              'garantid',
              'certificad',
              'reembolso',
              'desconto',
              'bolsa',
              'teste',
              'grupo',
            ],
            LangueCarte.arabe: <String>[
              'سعر',
              'أسعار',
              'مجان',
              'خصم',
              'استرداد',
              'ضمان',
              'مجموعة',
            ],
          };
      for (final LangueCarte langue in LangueCarte.values) {
        for (final MapEntry<String, String?> e in _champs(
          textesCarte[langue]!,
        ).entries) {
          final String texte = _lisible(e.value ?? '').toLowerCase();
          final String ou = '${langue.code} : ${e.key}';
          expect(montant.hasMatch(texte), isFalse, reason: ou);
          expect(texte, isNot(contains('—')), reason: '$ou : tiret long');
          expect(texte, isNot(contains('–')), reason: '$ou : tiret long');
          for (final String mot in interdits[langue]!) {
            expect(texte, isNot(contains(mot)), reason: '$ou : $mot');
          }
        }
      }
    });

    test(
      'jamais l\'academie comme motif : son nom n\'est dans aucun texte',
      () {
        for (final LangueCarte langue in LangueCarte.values) {
          for (final MapEntry<String, String?> e in _champs(
            textesCarte[langue]!,
          ).entries) {
            final String texte = (e.value ?? '').toLowerCase();
            for (final String mot in <String>[
              'rewayah',
              'académie',
              'academie',
              'academy',
              'academia',
              'أكاديمية',
              'الأكاديمية',
              'الرواية',
            ]) {
              expect(
                texte,
                isNot(contains(mot)),
                reason: '${langue.code} : ${e.key} : $mot',
              );
            }
          }
        }
      },
    );

    test('aucune demande faite a la personne : la carte parle a celui qui '
        'apprendra', () {
      // La carte est lue par le futur eleve : elle ne lui demande pas de
      // partager, d'aider ni de faire connaitre.
      final Map<LangueCarte, List<String>> demandes =
          <LangueCarte, List<String>>{
            LangueCarte.francais: <String>[
              'aidez',
              'partagez',
              'faites connaître',
              'soutenez',
            ],
            LangueCarte.anglais: <String>['help', 'share', 'support', 'spread'],
            LangueCarte.portugais: <String>[
              'ajude',
              'compartilhe',
              'partilhe',
              'apoie',
            ],
            LangueCarte.arabe: <String>['ساعد', 'شارك', 'انشر', 'ادعم'],
          };
      for (final LangueCarte langue in LangueCarte.values) {
        for (final MapEntry<String, String?> e in _champs(
          textesCarte[langue]!,
        ).entries) {
          // Le hadith traduit parle de « celui qui indique » : c'est un texte
          // du Prophete, pas une demande.
          if (e.key == 'traduction') {
            continue;
          }
          for (final String d in demandes[langue]!) {
            expect(
              (e.value ?? '').toLowerCase(),
              isNot(contains(d)),
              reason: '${langue.code} : ${e.key} : $d',
            );
          }
        }
      }
    });
  });
}
