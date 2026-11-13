// HORLOGE-ET-LIEU (revue du 13/11/2026, bloquant) : le candidat enseignant
// enregistre sa ville AVEC l'adaptateur reel (`LieuSupabase`) contre un serveur
// HTTP local : aucun faux port ne masque un refus du serveur.
//
// - le serveur accepte (le candidat en pending_kyc, apres la migration
//   20261123943200) : la ville part (`p_ville_id`), son fuseau repond a la question ;
// - le serveur refuse (42501 « ville non autorisee », l'etat d'avant la
//   migration) : le candidat voit la phrase d'echec, rien ne repond a la question.

import 'dart:convert';
import 'dart:io' show HttpStatus;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' show Request, Response;
import 'package:http/testing.dart' show MockClient;
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/lieu/lieu.dart';
import 'package:rewayah_academy/core/lieu/lieu_supabase.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/features/candidature/ville_etape.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthClientOptions, SupabaseClient;

import '../../support/harnais.dart';

typedef _Requete = ({String chemin, Object? corps});

class _FauxServeur {
  final List<_Requete> requetes = <_Requete>[];
  bool refuserEnregistrement = false;
  late SupabaseClient client;

  /// Le VRAI client Supabase, dont le transport est remplace par une reponse en
  /// memoire : le meme chemin de production (corps JSON, code d'erreur
  /// PostgREST), sans socket ni minuterie.
  void demarrer() {
    final MockClient http = MockClient((Request r) async {
      final String chemin = r.url.path.replaceFirst('/rest/v1/', '');
      requetes.add((
        chemin: chemin,
        corps: r.body.isEmpty ? null : jsonDecode(r.body),
      ));
      int statut = HttpStatus.ok;
      Object? corps;
      if (chemin == 'rpc/villes_proposees') {
        corps = <Map<String, Object?>>[
          <String, Object?>{
            'id': 2422465,
            'nom': 'Conakry',
            'nom_ar': null,
            'pays_code': 'GN',
            'region': 'Conakry',
            'fuseau_iana': 'Africa/Conakry',
            'milliers': 1660,
          },
        ];
      } else if (chemin == 'rpc/enregistrer_ma_ville') {
        if (refuserEnregistrement) {
          statut = HttpStatus.forbidden;
          corps = <String, Object?>{
            'code': '42501',
            'details': null,
            'hint': null,
            'message': 'ville non autorisee',
          };
        } else {
          corps = <String, Object?>{
            'ville': 'Conakry',
            'pays_code': 'GN',
            'fuseau_iana': 'Africa/Conakry',
            'disponibilites_a_relire': false,
          };
        }
      }
      return Response(
        jsonEncode(corps),
        statut,
        request: r,
        headers: <String, String>{'content-type': 'application/json'},
      );
    });
    client = SupabaseClient(
      'http://serveur.test',
      'cle-fictive',
      httpClient: http,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
  }
}

void main() {
  late _FauxServeur serveur;

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.fr);
    serveur = _FauxServeur()..demarrer();
  });

  Future<void> attendre(WidgetTester tester) => tester.pumpAndSettle();

  Future<void> finir(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  }

  Future<void> monter(
    WidgetTester tester,
    ValueChanged<String> onChange,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 1600);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      hoteRoutant(
        depart: '/',
        surcharges: <Override>[
          portLieuProvider.overrideWithValue(LieuSupabase(serveur.client)),
          horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
        ],
        routes: <RouteBase>[
          GoRoute(
            path: '/',
            builder: (BuildContext _, GoRouterState _) => Scaffold(
              body: SingleChildScrollView(
                child: VilleEtape(
                  options: const <String>['Africa/Conakry', 'Europe/Paris'],
                  choisi: null,
                  onChange: onChange,
                ),
              ),
            ),
          ),
        ],
      ),
    );
    await attendre(tester);
  }

  testWidgets('le serveur accepte : la ville part avec son identifiant, son '
      'fuseau repond a la question', (tester) async {
    String? repondu;
    await monter(tester, (String f) => repondu = f);
    await tester.tap(find.text('Conakry'));
    await attendre(tester);
    final _Requete envoi = serveur.requetes.firstWhere(
      (_Requete r) => r.chemin == 'rpc/enregistrer_ma_ville',
    );
    expect(envoi.corps, <String, Object?>{'p_ville_id': 2422465});
    expect(repondu, 'Africa/Conakry');
    expect(find.text(t.lieu.echec), findsNothing);
    await finir(tester);
  });

  testWidgets('le serveur refuse (42501) : le candidat voit l\'echec, rien ne '
      'repond a la question', (tester) async {
    serveur.refuserEnregistrement = true;
    String? repondu;
    await monter(tester, (String f) => repondu = f);
    await tester.tap(find.text('Conakry'));
    await attendre(tester);
    expect(
      serveur.requetes.where(
        (_Requete r) => r.chemin == 'rpc/enregistrer_ma_ville',
      ),
      hasLength(1),
    );
    expect(repondu, isNull);
    expect(find.text(t.lieu.echec), findsOneWidget);
    await finir(tester);
  });
}
