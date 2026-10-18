// CPT-SUPPR-EXPORT : l'adaptateur de « Mes donnees ». Decodage strict, noms de
// fonctions et parametres, copie JSON (nom et contenu), erreurs serveur
// (fonction absente, refus, hors ligne).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/mes_donnees_supabase.dart';
import 'package:rewayah_academy/core/capacites/permission_insuffisante.dart';
import 'package:rewayah_academy/core/capacites/port_mes_donnees.dart';
import 'package:rewayah_academy/core/finance/montant.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Map<String, Object?> _demande() => <String, Object?>{
  'id': 'd1',
  'statut': 'en_attente',
  'motif': null,
  'delai_jours': 14,
  'demandee_le': '2026-10-18T10:00:00+00:00',
  'echeance_le': '2026-11-01T10:00:00+00:00',
  'annulee_le': null,
  'traitee_le': null,
};

Map<String, Object?> _situation({
  Object? demande,
  List<Object?> dus = const <Object?>[],
  int seances = 0,
}) => <String, Object?>{
  'demande': demande,
  'delai_jours': 14,
  'situation': <String, Object?>{
    'solde_du': dus.isNotEmpty,
    'montants_dus': dus,
    'seances_a_venir': seances,
  },
};

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
  group('situation', () {
    test('sans demande : le delai, rien de du, aucune seance', () async {
      final _Faux faux = _Faux(
        <String, Object? Function(Map<String, dynamic>?)>{
          'ma_situation_suppression': (_) => _situation(),
        },
      );
      final SituationSuppression s = await MesDonneesSupabase.avecAppel(
        faux.call,
      ).situation();
      expect(s.demande, isNull);
      expect(s.delaiJours, 14);
      expect(s.soldeDu, isFalse);
      expect(s.seancesAVenir, 0);
      expect(faux.appels.single.$1, 'ma_situation_suppression');
    });

    test('avec demande, solde par devise et seances a venir', () async {
      final _Faux faux = _Faux(
        <String, Object? Function(Map<String, dynamic>?)>{
          'ma_situation_suppression': (_) => _situation(
            demande: _demande(),
            dus: <Object?>[
              <String, Object?>{'devise': 'USD', 'total_mineur': 4500},
              <String, Object?>{'devise': 'EUR', 'total_mineur': 300},
            ],
            seances: 3,
          ),
        },
      );
      final SituationSuppression s = await MesDonneesSupabase.avecAppel(
        faux.call,
      ).situation();
      expect(s.demande?.id, 'd1');
      expect(s.demande?.delaiJours, 14);
      expect(
        s.demande?.echeanceLe.difference(s.demande!.demandeeLe),
        const Duration(days: 14),
      );
      expect(s.soldeDu, isTrue);
      expect(s.montantsDus, const <Montant>[
        Montant(4500, 'USD'),
        Montant(300, 'EUR'),
      ]);
      expect(s.seancesAVenir, 3);
    });

    test('une forme inattendue est refusee, jamais completee', () async {
      for (final Object? mauvais in <Object?>[
        null,
        <String, Object?>{'delai_jours': 14},
        <String, Object?>{..._situation(), 'delai_jours': '14'},
        _situation(
          dus: <Object?>[
            <String, Object?>{'devise': 'dollar', 'total_mineur': 1},
          ],
        ),
        _situation(demande: <String, Object?>{'id': 'd1'}),
      ]) {
        final _Faux faux = _Faux(
          <String, Object? Function(Map<String, dynamic>?)>{
            'ma_situation_suppression': (_) => mauvais,
          },
        );
        await expectLater(
          MesDonneesSupabase.avecAppel(faux.call).situation(),
          throwsFormatException,
          reason: '$mauvais',
        );
      }
    });
  });

  group('demander et annuler', () {
    test('demander envoie le motif nettoye, ou rien', () async {
      final _Faux faux = _Faux(
        <String, Object? Function(Map<String, dynamic>?)>{
          'demander_suppression_compte': (_) => _demande(),
        },
      );
      final MesDonneesSupabase port = MesDonneesSupabase.avecAppel(faux.call);
      await port.demander(motif: '  Je pars  ');
      await port.demander(motif: '   ');
      await port.demander();
      expect(faux.appels.map((a) => a.$2), <Map<String, dynamic>>[
        <String, dynamic>{'p_motif': 'Je pars'},
        <String, dynamic>{'p_motif': null},
        <String, dynamic>{'p_motif': null},
      ]);
    });

    test('annuler appelle la fonction sans parametre', () async {
      final _Faux faux = _Faux(
        <String, Object? Function(Map<String, dynamic>?)>{
          'annuler_suppression_compte': (_) => _demande(),
        },
      );
      await MesDonneesSupabase.avecAppel(faux.call).annuler();
      expect(faux.appels.single, ('annuler_suppression_compte', null));
    });
  });

  group('exporter', () {
    test(
      'un fichier JSON lisible, date dans le nom, contenu du serveur',
      () async {
        final Map<String, Object?> contenu = <String, Object?>{
          'format': 'rewayah-export-v1',
          'genere_le': '2026-10-18T22:30:00+00:00',
          'profil': <String, Object?>{'prenom': 'Amina', 'nom': 'Élève'},
        };
        final _Faux faux = _Faux(
          <String, Object? Function(Map<String, dynamic>?)>{
            'mes_donnees_export': (_) => contenu,
          },
        );
        final CopieDonnees copie = await MesDonneesSupabase.avecAppel(faux.call)
            .exporter();
        expect(
          copie.nomFichier,
          matches(RegExp(r'^rewayah-mes-donnees-2026-10-\d{2}\.json$')),
        );
        final String texte = utf8.decode(copie.octets);
        expect(texte, contains('\n  '), reason: 'mis en forme');
        expect(jsonDecode(texte), contenu);
        expect(faux.appels.single, ('mes_donnees_export', null));
      },
    );

    test('sans date, un nom sans date', () {
      expect(
        copieDepuis(<String, dynamic>{'format': 'x'}).nomFichier,
        'rewayah-mes-donnees.json',
      );
    });

    test('une reponse qui n est pas un objet est refusee', () async {
      final _Faux faux = _Faux(
        <String, Object? Function(Map<String, dynamic>?)>{
          'mes_donnees_export': (_) => <Object?>[],
        },
      );
      await expectLater(
        MesDonneesSupabase.avecAppel(faux.call).exporter(),
        throwsFormatException,
      );
    });
  });

  group('erreurs', () {
    test(
      'fonction absente : capacite indisponible, pour chaque appel',
      () async {
        final MesDonneesSupabase port = MesDonneesSupabase.avecAppel(_absente);
        await expectLater(
          port.exporter(),
          throwsA(isA<CapaciteIndisponible>()),
        );
        await expectLater(
          port.situation(),
          throwsA(isA<CapaciteIndisponible>()),
        );
        await expectLater(
          port.demander(),
          throwsA(isA<CapaciteIndisponible>()),
        );
        await expectLater(port.annuler(), throwsA(isA<CapaciteIndisponible>()));
      },
    );

    test('refus du serveur : permission insuffisante', () async {
      final MesDonneesSupabase port = MesDonneesSupabase.avecAppel(_refus);
      await expectLater(
        port.exporter(),
        throwsA(isA<PermissionInsuffisante>()),
      );
      await expectLater(
        port.situation(),
        throwsA(isA<PermissionInsuffisante>()),
      );
      await expectLater(
        port.demander(),
        throwsA(isA<PermissionInsuffisante>()),
      );
      await expectLater(port.annuler(), throwsA(isA<PermissionInsuffisante>()));
    });

    test('hors ligne : l erreur remonte, jamais un succes', () async {
      final MesDonneesSupabase port = MesDonneesSupabase.avecAppel(_horsLigne);
      await expectLater(port.exporter(), throwsA(isA<SocketException>()));
      await expectLater(port.situation(), throwsA(isA<SocketException>()));
      await expectLater(port.demander(), throwsA(isA<SocketException>()));
      await expectLater(port.annuler(), throwsA(isA<SocketException>()));
    });

    test('le port par defaut est indisponible', () async {
      const PortMesDonnees port = MesDonneesIndisponibles();
      await expectLater(port.exporter(), throwsA(isA<CapaciteIndisponible>()));
      await expectLater(port.situation(), throwsA(isA<CapaciteIndisponible>()));
    });
  });
}
