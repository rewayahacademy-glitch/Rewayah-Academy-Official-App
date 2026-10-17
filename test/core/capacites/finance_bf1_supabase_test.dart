// BF1 : les adaptateurs finance (revenus, mes finances, paiements du foyer).
// Decodage strict, erreurs serveur, fonction absente, hors ligne.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/mes_finances_supabase.dart';
import 'package:rewayah_academy/core/capacites/paiements_foyer_supabase.dart';
import 'package:rewayah_academy/core/capacites/port_paiements_foyer.dart';
import 'package:rewayah_academy/core/capacites/port_revenus_enseignant.dart';
import 'package:rewayah_academy/core/capacites/revenus_enseignant_supabase.dart';
import 'package:rewayah_academy/core/capacites/rpc_finance_supabase.dart';
import 'package:rewayah_academy/core/finance/finances_profil.dart';
import 'package:rewayah_academy/core/finance/montant.dart';
import 'package:rewayah_academy/core/finance/mouvements_profil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Map<String, Object?> _m(int mineur, [String devise = 'USD']) =>
    <String, Object?>{'mineur': mineur, 'devise': devise};

final Map<String, Object?> _revenus = <String, Object?>{
  'debut': '2026-10-01',
  'fin': '2026-10-31',
  'devise': 'USD',
  'regle': <String, Object?>{'base': _m(400), 'plafond': _m(400)},
  'classes': <Object?>[
    <String, Object?>{
      'classeId': 'c2',
      'classe': 'Al-Fajr',
      'type': 'adultes',
      'minutesAssurees': 90,
      'capacite': 6,
      'siegesEligibles': 1,
      'tauxHoraireEffectif': _m(400),
      'montantEstime': _m(600),
      'enRemplacement': true,
    },
  ],
  'total': <String, Object?>{
    'minutesAssurees': 90,
    'capacite': 6,
    'siegesEligibles': 1,
    'tauxHoraireMoyen': _m(400),
  },
  'totalEstime': _m(600),
  'allocationInternet': null,
};

Map<String, Object?> _finance({String etat = 'manque'}) => <String, Object?>{
  'profilId': 'p1',
  'prenom': 'Yasmine',
  'cleAccent': 'p1',
  'estAdulte': false,
  'cleAvatar': null,
  'classe': 'An-Nour',
  'age': null,
  'etat': etat,
  'solde': _m(-700),
  'periode': null,
  'prochainDebit': null,
  'mensualite': _m(0),
  'lignesMensualite': <Object?>[],
  'essaisUtilises': null,
  'manque': _m(700),
  'finConservation': null,
};

Map<String, Object?> _mouvement(
  String nature,
  int montant, [
  String s = 'enregistre',
]) => <String, Object?>{
  'id': '91',
  'date': '2026-10-17T10:00:00+00:00',
  'nature': nature,
  'montant': _m(montant),
  'statut': s,
  'periode': null,
  'recu': null,
};

/// Un faux appel : rend [reponses] par nom de fonction, note les parametres.
class _Faux {
  _Faux(this.reponses);
  final Map<String, Object? Function(Map<String, dynamic>?)> reponses;
  final List<(String, Map<String, dynamic>?)> appels =
      <(String, Map<String, dynamic>?)>[];

  Future<Object?> call(String f, Map<String, dynamic>? p) async {
    appels.add((f, p));
    final Object? Function(Map<String, dynamic>?)? r = reponses[f];
    if (r == null) throw StateError('appel inattendu: $f');
    return r(p);
  }
}

Future<Object?> _refus(String _, Map<String, dynamic>? _) async =>
    throw const PostgrestException(message: 'refus', code: '42501');
Future<Object?> _absente(String _, Map<String, dynamic>? _) async =>
    throw const PostgrestException(message: 'absente', code: 'PGRST202');
Future<Object?> _horsLigne(String _, Map<String, dynamic>? _) async =>
    throw const SocketException('reseau coupe');

void main() {
  group('RevenusEnseignantSupabase', () {
    test('decode la vue sans rien recalculer', () async {
      final _Faux faux = _Faux(
        <String, Object? Function(Map<String, dynamic>?)>{
          'mes_revenus_enseignant': (_) => _revenus,
        },
      );
      final RevenusEnseignant r = await RevenusEnseignantSupabase.avecAppel(
        faux.call,
      ).moisEnCours();
      expect(r.debut, DateTime(2026, 10));
      expect(r.fin, DateTime(2026, 10, 31));
      expect(r.classes.single.type, TypeClasseRevenus.adultes);
      expect(r.classes.single.enRemplacement, isTrue);
      expect(r.classes.single.montantEstime, const Montant(600, 'USD'));
      expect(r.total.tauxHoraireMoyen, const Montant(400, 'USD'));
      expect(r.baseHoraire, r.plafondHoraire);
      expect(r.allocationInternet, isNull);
      expect(faux.appels.single.$2, <String, dynamic>{'p_mois': null});
    });

    test('duMois envoie le premier jour du mois', () async {
      final _Faux faux = _Faux(
        <String, Object? Function(Map<String, dynamic>?)>{
          'mes_revenus_enseignant': (_) => _revenus,
        },
      );
      await RevenusEnseignantSupabase.avecAppel(faux.call)
          .duMois(DateTime(2026, 8, 17));
      expect(faux.appels.single.$2, <String, dynamic>{'p_mois': '2026-08-01'});
    });

    test('sans regle de remuneration : capacite indisponible', () async {
      final _Faux faux = _Faux(
        <String, Object? Function(Map<String, dynamic>?)>{
          'mes_revenus_enseignant': (_) => <String, Object?>{
            ..._revenus,
            'regle': null,
          },
        },
      );
      await expectLater(
        RevenusEnseignantSupabase.avecAppel(faux.call).moisEnCours(),
        throwsA(isA<CapaciteIndisponible>()),
      );
    });

    test('mois disponibles, dans l ordre rendu', () async {
      final _Faux faux = _Faux(
        <String, Object? Function(Map<String, dynamic>?)>{
          'mes_revenus_mois_disponibles': (_) => <Object?>[
            '2026-10-01',
            '2026-08-01',
          ],
        },
      );
      expect(
        await RevenusEnseignantSupabase.avecAppel(faux.call).moisDisponibles(),
        <DateTime>[DateTime(2026, 10), DateTime(2026, 8)],
      );
    });

    test('le releve reste indisponible, sans appel serveur', () async {
      final _Faux faux = _Faux(
        <String, Object? Function(Map<String, dynamic>?)>{},
      );
      await expectLater(
        RevenusEnseignantSupabase.avecAppel(faux.call).releve(),
        throwsA(isA<CapaciteIndisponible>()),
      );
      expect(faux.appels, isEmpty);
    });

    test('forme invalide : FormatException, jamais une valeur completee', () {
      expect(
        () => RevenusEnseignantSupabase.decoderRevenus(<String, Object?>{
          ..._revenus,
          'totalEstime': <String, Object?>{'mineur': 1.5, 'devise': 'USD'},
        }),
        throwsFormatException,
      );
      expect(
        () => RevenusEnseignantSupabase.decoderRevenus(<String, Object?>{
          ..._revenus,
          'classes': <Object?>[
            <String, Object?>{
              ...(_revenus['classes']! as List<Object?>).single!
                  as Map<String, Object?>,
              'type': 'inconnu',
            },
          ],
        }),
        throwsFormatException,
      );
    });

    test('refus, fonction absente et hors ligne', () async {
      await expectLater(
        RevenusEnseignantSupabase.avecAppel(_refus).moisEnCours(),
        throwsA(isA<PostgrestException>()),
      );
      await expectLater(
        RevenusEnseignantSupabase.avecAppel(_absente).moisEnCours(),
        throwsA(isA<CapaciteIndisponible>()),
      );
      await expectLater(
        RevenusEnseignantSupabase.avecAppel(_horsLigne).moisDisponibles(),
        throwsA(isA<SocketException>()),
      );
    });
  });

  group('MesFinancesSupabase', () {
    test('decode la finance du profil et ses mouvements', () async {
      final _Faux faux = _Faux(
        <String, Object? Function(Map<String, dynamic>?)>{
          'mes_finances_eleve': (_) => _finance(),
          'mes_mouvements_eleve': (_) => <Object?>[
            _mouvement('recharge', 2000, 'en_confirmation'),
            _mouvement('avoir', 100),
          ],
        },
      );
      final MesFinancesSupabase port = MesFinancesSupabase.avecAppel(faux.call);
      final FinancesProfil? f = await port.finances();
      expect(f!.etat, EtatFinancier.manque);
      expect(f.solde, const Montant(-700, 'USD'));
      expect(f.manque, const Montant(700, 'USD'));
      expect(f.periode, isNull);
      expect(f.prochainDebit, isNull);
      expect(f.lignesMensualite, isEmpty);
      final List<MouvementProfil> m = await port.mouvements();
      expect(m.first.statut, StatutMouvement.enConfirmation);
      expect(m.last.nature, NatureMouvement.avoir);
      expect(faux.appels.last.$2, <String, dynamic>{'p_limite': 50});
    });

    test('aucune finance encore rendue : null', () async {
      final _Faux faux = _Faux(
        <String, Object? Function(Map<String, dynamic>?)>{
          'mes_finances_eleve': (_) => null,
        },
      );
      expect(await MesFinancesSupabase.avecAppel(faux.call).finances(), isNull);
    });

    test('etat inconnu ou montant sans devise : FormatException', () {
      expect(
        () => financesProfilJson(_finance(etat: 'paye')),
        throwsFormatException,
      );
      expect(
        () => financesProfilJson(<String, Object?>{
          ..._finance(),
          'solde': <String, Object?>{'mineur': 1},
        }),
        throwsFormatException,
      );
    });

    test('chaque nature serveur a sa valeur, montant signe garde', () {
      final MouvementProfil r = mouvementProfilJson(
        _mouvement('remboursement', -1000),
      );
      expect(r.nature, NatureMouvement.remboursement);
      expect(r.montant, const Montant(-1000, 'USD'));
      expect(
        mouvementProfilJson(_mouvement('correction', -5)).nature,
        NatureMouvement.correction,
      );
      expect(
        mouvementProfilJson(_mouvement('debit', -1200)).nature,
        NatureMouvement.debitSeance,
      );
      expect(
        mouvementProfilJson(_mouvement('debit_periode', -1200)).nature,
        NatureMouvement.debitPeriode,
      );
      expect(
        () => mouvementProfilJson(_mouvement('payout', -1)),
        throwsFormatException,
      );
    });

    test('refus, fonction absente et hors ligne', () async {
      await expectLater(
        MesFinancesSupabase.avecAppel(_refus).finances(),
        throwsA(isA<PostgrestException>()),
      );
      await expectLater(
        MesFinancesSupabase.avecAppel(_absente).mouvements(),
        throwsA(isA<CapaciteIndisponible>()),
      );
      await expectLater(
        MesFinancesSupabase.avecAppel(_horsLigne).finances(),
        throwsA(isA<SocketException>()),
      );
    });
  });

  group('PaiementsFoyerSupabase', () {
    final Map<String, Object?> paiement = <String, Object?>{
      'id': '9100001',
      'montantMineur': 5000,
      'devise': 'USD',
      'statut': 'confirme',
      'date': '2026-10-17T10:00:00+00:00',
      'justificatifDisponible': false,
    };

    test('historique et detail', () async {
      final _Faux faux = _Faux(
        <String, Object? Function(Map<String, dynamic>?)>{
          'paiements_foyer': (Map<String, dynamic>? p) =>
              p!['p_id'] == 404 ? <Object?>[] : <Object?>[paiement],
        },
      );
      final PaiementsFoyerSupabase port = PaiementsFoyerSupabase.avecAppel(
        faux.call,
      );
      final List<PaiementFoyer> h = await port.historique();
      expect(h.single.montantMineur, 5000);
      expect(h.single.statutServeur, 'confirme');
      expect(faux.appels.last.$2, <String, dynamic>{'p_id': null});
      expect((await port.detail('9100001'))!.id, '9100001');
      expect(faux.appels.last.$2, <String, dynamic>{'p_id': 9100001});
      expect(await port.detail('404'), isNull);
      final int avant = faux.appels.length;
      expect(await port.detail('pas-un-id'), isNull);
      expect(faux.appels.length, avant);
    });

    test('statut inconnu : FormatException', () async {
      final _Faux faux = _Faux(
        <String, Object? Function(Map<String, dynamic>?)>{
          'paiements_foyer': (_) => <Object?>[
            <String, Object?>{...paiement, 'statut': 'paye'},
          ],
        },
      );
      await expectLater(
        PaiementsFoyerSupabase.avecAppel(faux.call).historique(),
        throwsFormatException,
      );
    });

    test('finances du foyer : synthese et profils rendus', () async {
      final _Faux faux = _Faux(
        <String, Object? Function(Map<String, dynamic>?)>{
          'finances_foyer': (_) => <String, Object?>{
            'synthese': <String, Object?>{
              'totalSoldes': _m(2600),
              'aPayerCeMois': _m(700),
              'profilsFinances': 1,
              'profils': 3,
              'paiementsDuMois': 2,
            },
            'profils': <Object?>[_finance(), _finance(etat: 'finance')],
          },
        },
      );
      final FinancesFoyer f = await PaiementsFoyerSupabase.avecAppel(faux.call)
          .finances();
      expect(f.synthese.totalSoldes, const Montant(2600, 'USD'));
      expect(f.synthese.profils, 3);
      expect(f.profils.map((FinancesProfil p) => p.etat), <EtatFinancier>[
        EtatFinancier.manque,
        EtatFinancier.finance,
      ]);
    });

    test('foyer sans portefeuille et soldes rediges : indisponibles', () async {
      final _Faux faux = _Faux(
        <String, Object? Function(Map<String, dynamic>?)>{
          'finances_foyer': (_) => null,
        },
      );
      final PaiementsFoyerSupabase port = PaiementsFoyerSupabase.avecAppel(
        faux.call,
      );
      await expectLater(port.finances(), throwsA(isA<CapaciteIndisponible>()));
      await expectLater(port.soldes(), throwsA(isA<CapaciteIndisponible>()));
    });

    test('mouvements d un profil et derniers mouvements du foyer', () async {
      final _Faux faux = _Faux(
        <String, Object? Function(Map<String, dynamic>?)>{
          'mouvements_profil_foyer': (_) => <Object?>[
            _mouvement('debit', -1200),
          ],
          'derniers_mouvements_foyer': (_) => <Object?>[
            <String, Object?>{
              'profilId': 'p1',
              'prenom': 'Yasmine',
              'mouvement': _mouvement('recharge', 5000),
            },
          ],
        },
      );
      final PaiementsFoyerSupabase port = PaiementsFoyerSupabase.avecAppel(
        faux.call,
      );
      expect(
        (await port.mouvements('p1')).single.montant,
        const Montant(-1200, 'USD'),
      );
      expect(faux.appels.last.$2, <String, dynamic>{
        'p_profil': 'p1',
        'p_limite': 50,
      });
      final List<MouvementFoyer> d = await port.derniersMouvements();
      expect(d.single.prenom, 'Yasmine');
      expect(faux.appels.last.$2, <String, dynamic>{'p_limite': 3});
    });

    test('refus, fonction absente et hors ligne', () async {
      await expectLater(
        PaiementsFoyerSupabase.avecAppel(_refus).historique(),
        throwsA(isA<PostgrestException>()),
      );
      await expectLater(
        PaiementsFoyerSupabase.avecAppel(_absente).finances(),
        throwsA(isA<CapaciteIndisponible>()),
      );
      await expectLater(
        PaiementsFoyerSupabase.avecAppel(_horsLigne).derniersMouvements(),
        throwsA(isA<SocketException>()),
      );
    });
  });
}
