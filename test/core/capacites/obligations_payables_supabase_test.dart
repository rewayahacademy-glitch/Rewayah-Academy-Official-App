// B2.5 : l'adaptateur de la paie des enseignants (releve_paie_mensuel,
// releve_paie_seances). Decodage strict, sans calcul ; filtres ; erreurs
// serveur, fonction absente, hors ligne.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/obligations_payables_supabase.dart';
import 'package:rewayah_academy/core/capacites/port_obligations_payables.dart';
import 'package:rewayah_academy/core/comptable/statuts_comptable.dart';
import 'package:rewayah_academy/core/finance/montant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Map<String, Object?> _m(int mineur) => <String, Object?>{
  'mineur': mineur,
  'devise': 'USD',
};

Map<String, Object?> _releve(String debut, String fin, {int attente = 0}) =>
    <String, Object?>{
      'debut': debut,
      'fin': fin,
      'devise': 'USD',
      'enseignants': <Object?>[
        <String, Object?>{
          'enseignantId': 'b1',
          'prenom': 'Maryam',
          'nom': 'Bah',
          'seancesTenues': 3,
          'seancesEnAttente': attente,
          'minutes': 180,
          'minutesEleves': 180,
          'montant': _m(597),
          'classes': <Object?>['An-Nour'],
        },
      ],
      'total': _m(597),
    };

final Map<String, Object?> _detail = <String, Object?>{
  'debut': '2026-10-01',
  'fin': '2026-10-31',
  'devise': 'USD',
  'enseignant': <String, Object?>{
    'enseignantId': 'b1',
    'prenom': 'Maryam',
    'nom': 'Bah',
  },
  'seances': <Object?>[
    <String, Object?>{
      'seanceId': 's1',
      'classeId': 'c1',
      'classe': 'An-Nour',
      'debut': '2026-10-11T07:00:00+00:00',
      'minutes': 60,
      'elevesPresents': 2,
      'elevesInscrits': 3,
      'montant': _m(398),
      'enAttente': false,
    },
    <String, Object?>{
      'seanceId': 's4',
      'classeId': 'c1',
      'classe': 'An-Nour',
      'debut': '2026-10-12T07:00:00+00:00',
      'minutes': 20,
      'elevesPresents': 1,
      'elevesInscrits': 1,
      'montant': null,
      'enAttente': true,
    },
  ],
  'total': _m(398),
};

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  group('liste', () {
    late List<({String fonction, Map<String, dynamic>? params})> appels;
    late ObligationsPayablesSupabase port;

    setUp(() {
      appels = <({String fonction, Map<String, dynamic>? params})>[];
      port = ObligationsPayablesSupabase.avecAppel((
        String fonction,
        Map<String, dynamic>? params,
      ) async {
        appels.add((fonction: fonction, params: params));
        return params!['p_mois'] == '2026-10-01'
            ? _releve('2026-10-01', '2026-10-31', attente: 1)
            : _releve('2026-11-01', '2026-11-30');
      }, () => DateTime(2026, 11, 3));
    });

    test('lit le mois precedent et le mois en cours, sans recalcul', () async {
      final List<ObligationPayable> l = await port.liste(
        FiltreObligations.tout,
      );
      expect(appels.map((a) => a.params!['p_mois']), <String>[
        '2026-10-01',
        '2026-11-01',
      ]);
      expect(appels.every((a) => a.fonction == 'releve_paie_mensuel'), isTrue);
      expect(l, hasLength(2));
      final ObligationPayable octobre = l.first;
      expect(octobre.montant, const Montant(597, 'USD'));
      expect(octobre.beneficiaire.nom, 'Maryam Bah');
      expect(octobre.beneficiaire.type, TypeBeneficiaire.enseignant);
      expect(octobre.periode, 'Octobre 2026');
      expect(octobre.etat, EtatPaiementSortant.aVerifier);
      expect(octobre.echeance, DateTime(2026, 10, 31));
      expect(octobre.classes, <String>['An-Nour']);
      expect(octobre.permissions.actions, isEmpty);
      expect(l.last.etat, EtatPaiementSortant.calcule);
      expect(octobre.id, 'b1_2026-10-01');
    });

    test(
      'filtre par Classe ; contractuels et etats de paiement vides',
      () async {
        expect(
          await port.liste(const FiltreObligations(classe: 'Al-Fajr')),
          isEmpty,
        );
        expect(
          await port.liste(const FiltreObligations(classe: 'An-Nour')),
          hasLength(2),
        );
        appels.clear();
        expect(
          await port.liste(
            const FiltreObligations(type: TypeBeneficiaire.contractuel),
          ),
          isEmpty,
        );
        expect(
          await port.liste(
            const FiltreObligations(filtre: FiltrePaiements.prets),
          ),
          isEmpty,
        );
        expect(appels, isEmpty);
      },
    );
  });

  test('detail : une ligne par seance, la source dit les presents', () async {
    Map<String, dynamic>? recu;
    final ObligationsPayablesSupabase port =
        ObligationsPayablesSupabase.avecAppel((
          String fonction,
          Map<String, dynamic>? params,
        ) async {
          expect(fonction, 'releve_paie_seances');
          recu = params;
          return _detail;
        });
    final ObligationPayable o = await port.detail('b1_2026-10-01');
    expect(recu, <String, dynamic>{
      'p_mois': '2026-10-01',
      'p_enseignant': 'b1',
    });
    expect(o.montant, const Montant(398, 'USD'));
    expect(o.lignes, hasLength(2));
    expect(o.lignes.first.montant, const Montant(398, 'USD'));
    expect(o.lignes.first.source, 'Élèves : 2 présents sur 3 attendus');
    expect(o.lignes.last.montant, const Montant(0, 'USD'));
    expect(o.lignes.last.source, t.etat.enAttente);
    expect(o.etat, EtatPaiementSortant.aVerifier);
  });

  test('signalement et journal restent indisponibles', () async {
    final ObligationsPayablesSupabase port =
        ObligationsPayablesSupabase.avecAppel(
          (String _, Map<String, dynamic>? _) async => null,
        );
    await expectLater(
      port.journal('b1_2026-10-01'),
      throwsA(isA<CapaciteIndisponible>()),
    );
    await expectLater(
      port.signalerEcart(
        obligationId: 'b1_2026-10-01',
        ligneId: 's1',
        motif: 'autre',
        cleIdempotence: 'k',
      ),
      throwsA(isA<CapaciteIndisponible>()),
    );
  });

  group('erreurs', () {
    Future<List<ObligationPayable>> lire(Exception erreur) =>
        ObligationsPayablesSupabase.avecAppel(
          (String _, Map<String, dynamic>? _) async => throw erreur,
        ).liste(FiltreObligations.tout);

    test('fonction absente : capacite indisponible', () {
      expect(
        lire(const PostgrestException(message: 'absente', code: 'PGRST202')),
        throwsA(isA<CapaciteIndisponible>()),
      );
    });

    test('refus et hors ligne remontent tels quels', () {
      expect(
        lire(const PostgrestException(message: 'refus', code: '42501')),
        throwsA(isA<PostgrestException>()),
      );
      expect(
        lire(const SocketException('reseau coupe')),
        throwsA(isA<SocketException>()),
      );
    });

    test('forme inattendue : FormatException, jamais une valeur completee', () {
      expect(
        () => ObligationsPayablesSupabase.decoderReleve(<String, Object?>{
          'debut': '2026-10-01',
          'fin': '2026-10-31',
          'enseignants': <Object?>[
            <String, Object?>{'enseignantId': 'b1'},
          ],
        }),
        throwsFormatException,
      );
    });
  });
}
