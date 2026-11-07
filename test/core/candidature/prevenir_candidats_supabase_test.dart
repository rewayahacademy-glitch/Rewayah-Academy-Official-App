// CAND-PREVENIR : l'adaptateur des RPC `apercu_prevenir_par_courriel` et
// `prevenir_par_courriel`.
//
// Ce que le test prouve : les parametres envoyes sont ceux de la signature
// versee (`p_limite`, rien pour l'apercu) ; les comptes rendus deviennent des
// modeles ; `{erreur: 'inscription_fermee'}` devient une erreur typee, ainsi
// qu'un code inconnu ; `42501`, `22023`, une fonction pas encore versee et une
// coupure du reseau se traduisent ; une forme inattendue est une erreur.
// CANDIDATS-FLUX (06/11/2026) : `etat_file_courriels` sans parametre, les
// desinscrits lus (zero pour un serveur d'avant le lot), et le reglage ecrit
// puis relu dans `app_config` (une ecriture ignoree par la RLS est un echec).
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_configuration.dart';
import 'package:rewayah_academy/core/candidature/port_prevenir_candidats.dart';
import 'package:rewayah_academy/core/candidature/prevenir_candidats_supabase.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/permission_insuffisante.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

void main() {
  late List<(String, Map<String, dynamic>?)> appels;
  late Object? reponse;
  Exception? erreur;

  PrevenirCandidatsSupabase adaptateur() => PrevenirCandidatsSupabase.avecAppel(
    (String nom, [Map<String, dynamic>? params]) async {
      appels.add((nom, params));
      if (erreur != null) throw erreur!;
      return reponse;
    },
  );

  setUp(() {
    appels = <(String, Map<String, dynamic>?)>[];
    reponse = null;
    erreur = null;
  });

  group('apercu', () {
    test('appelle la RPC sans parametre et lit les trois comptes', () async {
      reponse = <String, dynamic>{
        'aPrevenir': 5,
        'dejaPrevenus': 2,
        'dejaInscrits': 3,
        'inscriptionOuverte': true,
      };
      final ApercuPrevenir a = await adaptateur().apercu();
      expect(appels.single.$1, 'apercu_prevenir_par_courriel');
      expect(appels.single.$2, isNull);
      expect(a.aPrevenir, 5);
      expect(a.dejaPrevenus, 2);
      expect(a.dejaInscrits, 3);
      expect(a.inscriptionOuverte, isTrue);
    });

    test('inscription fermee : le compte et le drapeau sont lus', () async {
      reponse = <String, dynamic>{
        'aPrevenir': 0,
        'dejaPrevenus': 0,
        'dejaInscrits': 0,
        'inscriptionOuverte': false,
      };
      expect((await adaptateur().apercu()).inscriptionOuverte, isFalse);
    });

    test('une forme inattendue est une erreur de format', () async {
      reponse = <String, dynamic>{'aPrevenir': 'cinq'};
      await expectLater(adaptateur().apercu(), throwsFormatException);
      reponse = 'texte';
      await expectLater(adaptateur().apercu(), throwsFormatException);
    });

    test('42501 : permission insuffisante', () async {
      erreur = const PostgrestException(message: 'non', code: '42501');
      await expectLater(
        adaptateur().apercu(),
        throwsA(isA<PermissionInsuffisante>()),
      );
    });

    test('fonction pas encore versee : capacite indisponible', () async {
      for (final String code in <String>['PGRST202', '42883']) {
        erreur = PostgrestException(message: 'absente', code: code);
        await expectLater(
          adaptateur().apercu(),
          throwsA(isA<CapaciteIndisponible>()),
        );
      }
    });

    test('coupure du reseau : PrevenirHorsLigne', () async {
      erreur = Exception('SocketException: Failed host lookup');
      await expectLater(
        adaptateur().apercu(),
        throwsA(isA<PrevenirHorsLigne>()),
      );
    });
  });

  group('prevenir', () {
    test(
      'envoie p_limite (2000 par defaut, CANDIDATS-FLUX) et lit le resultat',
      () async {
        reponse = <String, dynamic>{'misEnFile': 200, 'restants': 40};
        final ResultatPrevenir r = await adaptateur().prevenir();
        expect(appels.single.$1, 'prevenir_par_courriel');
        expect(appels.single.$2, <String, dynamic>{'p_limite': 2000});
        expect(r.misEnFile, 200);
        expect(r.restants, 40);
      },
    );

    test('envoie la limite demandee', () async {
      reponse = <String, dynamic>{'misEnFile': 3, 'restants': 0};
      await adaptateur().prevenir(limite: 3);
      expect(appels.single.$2, <String, dynamic>{'p_limite': 3});
    });

    test('inscription fermee : erreur typee, rien de lu', () async {
      reponse = <String, dynamic>{'erreur': 'inscription_fermee'};
      await expectLater(
        adaptateur().prevenir(),
        throwsA(isA<InscriptionFermee>()),
      );
    });

    test('un code d\'erreur inconnu est garde pour la trace', () async {
      reponse = <String, dynamic>{'erreur': 'autre_chose'};
      await expectLater(
        adaptateur().prevenir(),
        throwsA(
          isA<PrevenirRefuseInconnu>().having(
            (PrevenirRefuseInconnu e) => e.code,
            'code',
            'autre_chose',
          ),
        ),
      );
    });

    test('22023 : limite invalide', () async {
      erreur = const PostgrestException(message: 'limite', code: '22023');
      await expectLater(
        adaptateur().prevenir(limite: 900),
        throwsA(isA<PrevenirInvalide>()),
      );
    });

    test('42501 : permission insuffisante', () async {
      erreur = const PostgrestException(message: 'non', code: '42501');
      await expectLater(
        adaptateur().prevenir(),
        throwsA(isA<PermissionInsuffisante>()),
      );
    });

    test('fonction pas encore versee : capacite indisponible', () async {
      erreur = const PostgrestException(message: 'absente', code: 'PGRST202');
      await expectLater(
        adaptateur().prevenir(),
        throwsA(isA<CapaciteIndisponible>()),
      );
    });

    test('coupure du reseau : PrevenirHorsLigne (non confirme)', () async {
      erreur = Exception('ClientException: Connection refused');
      await expectLater(
        adaptateur().prevenir(),
        throwsA(isA<PrevenirHorsLigne>()),
      );
    });

    test('une autre erreur remonte telle quelle', () async {
      erreur = Exception('inconnue');
      await expectLater(adaptateur().prevenir(), throwsA(isA<Exception>()));
    });

    test('une reponse sans comptes est une erreur de format', () async {
      reponse = <String, dynamic>{'misEnFile': 'x'};
      await expectLater(adaptateur().prevenir(), throwsFormatException);
    });
  });

  group('CANDIDATS-FLUX', () {
    test('les desinscrits sont lus ; absents : zero', () async {
      reponse = <String, dynamic>{
        'aPrevenir': 4,
        'desinscrits': 1,
        'dejaPrevenus': 0,
        'dejaInscrits': 0,
        'inscriptionOuverte': true,
      };
      expect((await adaptateur().apercu()).desinscrits, 1);
      reponse = <String, dynamic>{
        'aPrevenir': 4,
        'dejaPrevenus': 0,
        'dejaInscrits': 0,
        'inscriptionOuverte': true,
      };
      expect((await adaptateur().apercu()).desinscrits, 0);
    });

    test('etat de la file : sans parametre, quatre compteurs', () async {
      reponse = <String, dynamic>{
        'parJour': 15,
        'partis24h': 15,
        'enAttente': 25,
        'joursEstimes': 2,
      };
      final EtatFileCourriels e = await adaptateur().etatFile();
      expect(appels.single.$1, 'etat_file_courriels');
      expect(appels.single.$2, isNull);
      expect(
        <int>[e.parJour, e.partis24h, e.enAttente, e.joursEstimes],
        <int>[15, 15, 25, 2],
      );
    });

    test('etat de la file pas encore verse : CapaciteIndisponible', () async {
      erreur = const PostgrestException(message: 'absente', code: 'PGRST202');
      await expectLater(
        adaptateur().etatFile(),
        throwsA(isA<CapaciteIndisponible>()),
      );
    });

    test('le reglage est ecrit puis relu', () async {
      final _FausseConfiguration conf = _FausseConfiguration();
      final PrevenirCandidatsSupabase a = PrevenirCandidatsSupabase.avecAppel(
        (String nom, [Map<String, dynamic>? params]) async => null,
        conf,
      );
      await a.reglerParJour(15);
      expect(conf.ecrits, <(String, Object)>[
        ('courriels.non_essentiels_par_jour', 15),
      ]);
    });

    test('une ecriture ignoree (relue differente) est un echec', () async {
      final _FausseConfiguration conf = _FausseConfiguration()..ignorer = true;
      final PrevenirCandidatsSupabase a = PrevenirCandidatsSupabase.avecAppel(
        (String nom, [Map<String, dynamic>? params]) async => null,
        conf,
      );
      await expectLater(
        a.reglerParJour(15),
        throwsA(isA<ReglageNonEnregistre>()),
      );
    });

    test('hors bornes : rien n\'est ecrit', () async {
      final _FausseConfiguration conf = _FausseConfiguration();
      final PrevenirCandidatsSupabase a = PrevenirCandidatsSupabase.avecAppel(
        (String nom, [Map<String, dynamic>? params]) async => null,
        conf,
      );
      for (final int v in <int>[0, 2001, -1]) {
        await expectLater(
          a.reglerParJour(v),
          throwsA(isA<ReglageNonEnregistre>()),
        );
      }
      expect(conf.ecrits, isEmpty);
    });

    test('une panne de l\'ecriture est un echec type', () async {
      final _FausseConfiguration conf = _FausseConfiguration()..panne = true;
      final PrevenirCandidatsSupabase a = PrevenirCandidatsSupabase.avecAppel(
        (String nom, [Map<String, dynamic>? params]) async => null,
        conf,
      );
      await expectLater(
        a.reglerParJour(15),
        throwsA(isA<ReglageNonEnregistre>()),
      );
    });
  });
}

class _FausseConfiguration implements ServiceConfiguration {
  final List<(String, Object)> ecrits = <(String, Object)>[];
  final Map<String, Object> valeurs = <String, Object>{};
  bool ignorer = false;
  bool panne = false;

  @override
  Future<void> ecrire(String cle, Object valeur) async {
    if (panne) throw Exception('panne');
    ecrits.add((cle, valeur));
    if (!ignorer) valeurs[cle] = valeur;
  }

  @override
  Future<List<ValeurConfig>> lire(List<String> cles) async => <ValeurConfig>[
    for (final String c in cles) ValeurConfig(cle: c, valeur: valeurs[c]),
  ];
}
