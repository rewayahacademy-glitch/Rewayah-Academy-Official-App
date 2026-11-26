// PAIEMENT-FAMILLE-PRIX (23/11/2026) : l'explication d'un paiement, mise en
// mots. Le JSON de reference est celui que rend `recharge_beneficiaires`
// (migration 20261203000000) pour un profil entre en cours de mois, 2e
// inscrit, qui doit encore son premier mois : 25,30 USD (novembre, au
// prorata de 4 seances sur 8), puis N mois d'avance.
//
// Rien n'est calcule ici : chaque montant, chaque mois, chaque taux est une
// valeur du serveur ; le test verifie que chaque code a sa phrase, en
// francais, en anglais et en arabe, et qu'un code inconnu est ignore.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_recharge_foyer.dart';
import 'package:rewayah_academy/core/capacites/recharge_foyer_supabase.dart';
import 'package:rewayah_academy/core/finance/explication_recharge.dart';
import 'package:rewayah_academy/core/finance/format_montant.dart';
import 'package:rewayah_academy/core/finance/montant.dart';
import 'package:rewayah_academy/core/i18n/isolat_bidi.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';

String _m(int mineur) => sansAncre(formaterMontant(Montant(mineur, 'USD')));

Map<String, Object?> _montant(int mineur) => <String, Object?>{
  'mineur': mineur,
  'devise': 'USD',
};

Map<String, Object?> _option({
  required int nb,
  required String formule,
  required int montant,
  required int dette,
  required int avance,
  Map<String, Object?>? couverts,
  List<Map<String, Object?>> lignes = const <Map<String, Object?>>[],
  List<Map<String, Object?>> non = const <Map<String, Object?>>[],
}) => <String, Object?>{
  'nbMois': nb,
  'formule': formule,
  'montant': _montant(montant),
  'dette': _montant(dette),
  'avance': _montant(avance),
  'moisCouverts': couverts,
  'lignes': lignes,
  'nonAppliquees': non,
  'rang': 2,
};

/// Le profil de reference : 2e inscrit, premier mois au prorata.
Map<String, Object?> _profil() => <String, Object?>{
  'id': 'fa000000-0000-4000-8000-000000000031',
  'prenom': 'Hallowx',
  'cleAvatar': null,
  'solde': _montant(0),
  'etat': 'en_classe',
  'rang': 2,
  'tarif': _montant(5500),
  'montantSuggere': _montant(2530),
  'montantsProposes': <Object?>[
    _montant(2530),
    _montant(12650),
    _montant(61930),
  ],
  'formules': <Object?>[
    <String, Object?>{'montant': _montant(2530), 'formule': 'libre'},
    <String, Object?>{'montant': _montant(12650), 'formule': 'avance'},
    <String, Object?>{'montant': _montant(61930), 'formule': 'annuel'},
  ],
  'dette': <String, Object?>{
    'total': _montant(2530),
    'solde': _montant(0),
    'mois': <Object?>[
      <String, Object?>{
        'mois': '2026-11-01',
        'montant': _montant(2530),
        'apercu': false,
        'lignes': <Object?>[
          <String, Object?>{
            'nature': 'tarif',
            'montant': _montant(5500),
            'rang': null,
          },
          <String, Object?>{
            'nature': 'remise_rang',
            'montant': _montant(-440),
            'rang': 2,
          },
          <String, Object?>{
            'nature': 'prorata',
            'montant': _montant(-2530),
            'rang': null,
          },
        ],
        'prorata': <String, Object?>{
          'entreeLe': '2026-11-12',
          'seancesRestantes': 4,
          'seancesDuMois': 8,
        },
      },
    ],
  },
  'options': <Object?>[
    _option(nb: 0, formule: 'libre', montant: 2530, dette: 2530, avance: 0),
    _option(
      nb: 2,
      formule: 'avance',
      montant: 12650,
      dette: 2530,
      avance: 10120,
      couverts: <String, Object?>{
        'debut': '2026-12-01',
        'fin': '2027-01-01',
        'nbMois': 2,
      },
      lignes: <Map<String, Object?>>[
        <String, Object?>{
          'code': 'prix',
          'montant': _montant(11000),
          'nbMois': 2,
        },
        <String, Object?>{
          'code': 'remise_famille',
          'montant': _montant(-880),
          'rang': 2,
          'pourMille': 80,
        },
      ],
      non: <Map<String, Object?>>[
        <String, Object?>{
          'type': 'remise_prepaiement',
          'code': 'moins_de_trois_mois',
        },
      ],
    ),
    _option(
      nb: 12,
      formule: 'annuel',
      montant: 2530 + 59400,
      dette: 2530,
      avance: 59400,
      couverts: <String, Object?>{
        'debut': '2026-12-01',
        'fin': '2027-11-01',
        'nbMois': 12,
      },
      lignes: <Map<String, Object?>>[
        <String, Object?>{
          'code': 'prix',
          'montant': _montant(66000),
          'nbMois': 12,
        },
        <String, Object?>{
          'code': 'remise_famille',
          'montant': _montant(-5280),
          'rang': 2,
          'pourMille': 80,
        },
        <String, Object?>{
          'code': 'remise_prepaiement',
          'montant': _montant(-6600),
          'pourMille': 100,
        },
        <String, Object?>{'code': 'arrondi', 'montant': _montant(1280)},
        <String, Object?>{
          'code': 'code_inconnu_du_futur',
          'montant': _montant(1),
        },
      ],
      non: <Map<String, Object?>>[
        <String, Object?>{
          'type': 'remise',
          'code': 'plafond_atteint',
          'montant': _montant(1320),
          'pourMille': 250,
        },
        <String, Object?>{
          'type': 'remise_famille',
          'code': 'code_inconnu_du_futur',
        },
      ],
    ),
  ],
};

BeneficiaireRecharge _lu() =>
    beneficiaireRechargeJson(jsonDecode(jsonEncode(_profil())));

void main() {
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  test('l adaptateur lit le profil du serveur : etat, dette, offres', () {
    final BeneficiaireRecharge b = _lu();
    expect(b.etat, EtatRecharge.enClasse);
    expect(b.rang, 2);
    expect(b.dette!.total, const Montant(2530, 'USD'));
    expect(b.dette!.mois.single.prorata!.seancesRestantes, 4);
    expect(b.dette!.mois.single.prorata!.seancesDuMois, 8);
    expect(b.options.map((OptionPaiement o) => o.nbMois), <int>[0, 2, 12]);
    expect(b.optionPour(const Montant(12650, 'USD'))!.moisCouverts!.nbMois, 2);
  });

  test('une formule ou un etat inconnu du serveur est refuse, pas devine', () {
    final Map<String, Object?> p = _profil();
    (p['options']! as List<Object?>).add(
      _option(nb: 3, formule: 'inconnue', montant: 1, dette: 0, avance: 1),
    );
    expect(
      () => beneficiaireRechargeJson(jsonDecode(jsonEncode(p))),
      throwsFormatException,
    );
    final Map<String, Object?> q = _profil()..['etat'] = 'autre';
    expect(
      () => beneficiaireRechargeJson(jsonDecode(jsonEncode(q))),
      throwsFormatException,
    );
  });

  test(
    'la phrase dit la dette d abord, puis les mois d avance et leurs mois',
    () {
      final BeneficiaireRecharge b = _lu();
      expect(
        phraseSynthese(b, b.options[1]),
        'Vous payez d\'abord ${_m(2530)} (novembre), puis 2 mois d\'avance '
        '(décembre et janvier) : ${_m(12650)} en tout.',
      );
      expect(
        phraseSynthese(b, b.options[0]),
        'Vous payez ${_m(2530)} pour le mois dû (novembre).',
      );
      // Douze mois : « de decembre 2026 a novembre 2027 » (la periode change d'annee).
      expect(
        phraseSynthese(b, b.options[2]),
        contains('de décembre 2026 à novembre 2027'),
      );
    },
  );

  test(
    'chaque montant surprenant a sa phrase : prorata, remise, non appliquee',
    () {
      final BeneficiaireRecharge b = _lu();
      final List<LigneExplication> deux = detailOption(b, b.options[1]);
      final List<String> cles = deux
          .map((LigneExplication l) => l.cle)
          .toList();
      expect(cles, contains('À régler d\'abord'));
      expect(cles, contains('novembre'));
      expect(cles, contains('Au prorata des séances du mois'));
      expect(cles, contains('Prix de 2 mois'));
      expect(cles, contains('Remise de famille, 2ᵉ inscrit (8 %)'));
      expect(
        cles,
        contains('Pas de remise de paiement d\'avance en dessous de 3 mois.'),
      );
      expect(
        deux
            .firstWhere((LigneExplication l) => l.cle.startsWith('Au prorata'))
            .detail,
        'Début le 12 novembre : 4 séances sur 8 ce mois-ci',
      );
      expect(deux.last.cle, isNot(contains('inconnu')));
      // Le total est celui du serveur, jamais additionne ici.
      expect(deux.firstWhere((LigneExplication l) => l.fort).valeur, _m(12650));
    },
  );

  test('le plafond et l arrondi se disent ; un code inconnu est ignore', () {
    final BeneficiaireRecharge b = _lu();
    final List<LigneExplication> an = detailOption(b, b.options[2]);
    final List<String> cles = an.map((LigneExplication l) => l.cle).toList();
    expect(cles, contains('Remise de paiement d\'avance (10 %)'));
    expect(cles, contains('Arrondi au dollar'));
    expect(cles.any((String c) => c.startsWith('Plafond atteint')), isTrue);
    expect(
      cles.any((String c) => c.contains('inconnu')),
      isFalse,
      reason: 'un code que l ecran ne connait pas ne casse rien',
    );
    expect(
      an.where((LigneExplication l) => l.note && l.valeur == null),
      hasLength(greaterThan(0)),
    );
  });

  test('un profil sans classe ni creneau : la phrase dit quoi faire', () {
    final BeneficiaireRecharge b = beneficiaireRechargeJson(
      jsonDecode(
        jsonEncode(<String, Object?>{
          'id': 'fa000000-0000-4000-8000-000000000041',
          'prenom': 'Khadija',
          'cleAvatar': null,
          'solde': _montant(0),
          'etat': 'aucun_creneau',
          'rang': 1,
          'tarif': _montant(5500),
          'montantSuggere': null,
          'montantsProposes': <Object?>[],
          'formules': <Object?>[],
          'dette': <String, Object?>{
            'total': _montant(0),
            'solde': _montant(0),
            'mois': <Object?>[],
          },
          'options': <Object?>[],
        }),
      ),
    );
    expect(b.options, isEmpty);
    expect(phraseEtat(b), contains('Choisissez d\'abord un créneau'));
    expect(phraseAvantPremierMois(b), isNull);
  });

  test('avant le premier mois : un mois seulement, la phrase le dit', () {
    final BeneficiaireRecharge b = beneficiaireRechargeJson(
      jsonDecode(
        jsonEncode(<String, Object?>{
          'id': 'fa000000-0000-4000-8000-000000000051',
          'prenom': 'Hamza',
          'cleAvatar': null,
          'solde': _montant(0),
          'etat': 'avant_premier_mois',
          'rang': 1,
          'tarif': _montant(5500),
          'montantSuggere': null,
          'montantsProposes': <Object?>[_montant(5500)],
          'formules': <Object?>[
            <String, Object?>{'montant': _montant(5500), 'formule': 'mois'},
          ],
          'dette': <String, Object?>{
            'total': _montant(0),
            'solde': _montant(0),
            'mois': <Object?>[],
          },
          'options': <Object?>[
            _option(
              nb: 1,
              formule: 'mois',
              montant: 5500,
              dette: 0,
              avance: 5500,
            ),
          ],
        }),
      ),
    );
    expect(
      phraseSynthese(b, b.options.single),
      'Vous payez un mois, ${_m(5500)}. Il sera compté dès le début de vos cours.',
    );
    expect(
      phraseAvantPremierMois(b),
      'Avant le début des cours, un seul mois peut être payé.',
    );
    expect(libelleOption(b.options.single), '${_m(5500)} pour un mois');
  });

  test(
    'le libelle du moins / plus dit l offre, jamais seulement un montant',
    () {
      final BeneficiaireRecharge b = _lu();
      expect(libelleOption(b.options[0]), '${_m(2530)} : le mois dû');
      expect(
        libelleOption(b.options[1]),
        '${_m(12650)} : le mois dû et 2 mois d\'avance',
      );
      expect(
        b.montantsRediges[b.options[1].montant],
        libelleOption(b.options[1]),
      );
    },
  );

  test(
    'en anglais et en arabe : les memes faits, les parametres isoles',
    () async {
      final BeneficiaireRecharge b = _lu();
      await LocaleSettings.setLocale(AppLocale.en);
      expect(
        phraseSynthese(b, b.options[1]),
        allOf(
          contains('You first pay'),
          contains('December'),
          contains('January'),
        ),
      );
      await LocaleSettings.setLocale(AppLocale.ar);
      final String ar = phraseSynthese(b, b.options[1]);
      expect(ar, contains('تدفعون أولًا'));
      expect(ar, contains('ديسمبر'));
      expect(ar, contains('يناير'));
      expect(ar, isNot(contains('{')));
      expect(libelleOption(b.options[2]), contains('أشهر').or(contains('شهر')));
    },
  );
}

extension on Matcher {
  Matcher or(Matcher autre) => anyOf(this, autre);
}
