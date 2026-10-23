// CAND-Q15, lot creer_groupe (21/10/2026) : l'adaptateur reel de la creation
// d'une classe traduit le refus du serveur, sur le chemin de production.
//
// Le VRAI client Supabase parle a un serveur HTTP local (aucun service reel,
// aucune dependance ajoutee), comme `raccordement_1016_test.dart` et
// `classes_foyer_supabase_tri_test.dart` : le faux serveur rend, pour
// `POST /rest/v1/rpc/creer_groupe`, le corps d'erreur que PostgREST rend pour
// un RAISE EXCEPTION (400, P0001) ou un droit EXECUTE retire (403, 42501).
// La feuille Classes lit
// `portCreationClasseProvider`, donc ce test passe par lui.
//
// Sans `traduireRefusCreationClasse` dans `ServiceGroupesSupabase.creer`, la
// PostgrestException brute remonterait jusqu'a la feuille, qui afficherait
// `creerErreur(message: ...)` avec le texte SQL et le SQLSTATE : ce test
// echoue alors (contre-epreuve faite le 21/10/2026).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' show ClientException;
import 'package:rewayah_academy/core/admin/creation_classe_refusee.dart';
import 'package:rewayah_academy/core/admin/service_groupes.dart';
import 'package:rewayah_academy/core/capacites/port_creation_classe.dart';
import 'package:rewayah_academy/core/capacites/port_enseignants_classe.dart'
    show GenreClasse;
import 'package:rewayah_academy/core/planning/service_planning.dart'
    show Creneau;
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthClientOptions, PostgrestException, SupabaseClient;

/// Une requete recue par le faux serveur.
typedef _Requete = ({String methode, String chemin, Object? corps});

/// Un faux PostgREST : rend [statut] et [corps] a chaque requete.
class _FauxPostgrest {
  final List<_Requete> requetes = <_Requete>[];
  int statut = HttpStatus.ok;
  Object? corps;
  HttpServer? _http;
  late SupabaseClient client;

  Future<void> demarrer() async {
    final HttpServer http = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      0,
    );
    _http = http;
    http.listen((HttpRequest r) async {
      final String brut = await utf8.decoder.bind(r).join();
      requetes.add((
        methode: r.method,
        chemin: r.uri.path.replaceFirst('/rest/v1/', ''),
        corps: brut.isEmpty ? null : jsonDecode(brut),
      ));
      r.response
        ..statusCode = statut
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(corps));
      await r.response.close();
    });
    client = SupabaseClient(
      'http://${http.address.address}:${http.port}',
      'cle-fictive',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
  }

  /// Ferme le port : l'appel suivant echoue avant toute reponse.
  Future<void> couper() async {
    await _http?.close(force: true);
    _http = null;
  }

  Future<void> arreter() async {
    await client.dispose();
    await couper();
  }

  /// Le corps d'erreur de PostgREST pour un refus de la base.
  void refuser({
    required int statut,
    required String code,
    required String message,
  }) {
    this.statut = statut;
    corps = <String, Object?>{
      'code': code,
      'details': null,
      'hint': null,
      'message': message,
    };
  }
}

/// Un refus du serveur, et le motif que l'ecran doit en tirer.
typedef _Refus = ({
  int statut,
  String code,
  String message,
  MotifRefusCreationClasse motif,
});

/// Quelques refus de `creer_groupe`, accents compris (ils traversent le JSON
/// en UTF-8), et le refus d'EXECUTE. Ce test prouve le branchement, pas la
/// liste : que ces messages soient bien ceux du serveur, et qu'aucun n'y
/// manque, `creation_classe_refusee_test.dart` le verifie en lisant les
/// migrations.
const List<_Refus> _refus = <_Refus>[
  (
    statut: HttpStatus.badRequest,
    code: 'P0001',
    message: "creation de groupe reservee a l'administration",
    motif: MotifRefusCreationClasse.reservee,
  ),
  (
    statut: HttpStatus.badRequest,
    code: 'P0001',
    message: 'enseignant indisponible ou genre inconnu',
    motif: MotifRefusCreationClasse.enseignantNonEligible,
  ),
  (
    statut: HttpStatus.badRequest,
    code: 'P0001',
    message: 'plafond horaire enseignant dépassé',
    motif: MotifRefusCreationClasse.plafond,
  ),
  (
    statut: HttpStatus.badRequest,
    code: 'P0001',
    message: 'chevauchement avec une séance existante',
    motif: MotifRefusCreationClasse.chevauchementSeance,
  ),
  (
    statut: HttpStatus.forbidden,
    code: '42501',
    message: 'permission denied for function creer_groupe',
    motif: MotifRefusCreationClasse.reservee,
  ),
  (
    statut: HttpStatus.badRequest,
    code: 'P0001',
    message: 'fuseau IANA inconnu : Mars/Olympus',
    motif: MotifRefusCreationClasse.inconnu,
  ),
];

const Creneau _mardi17 = Creneau(jour: 2, heure: 17, fuseau: 'Europe/Paris');

void main() {
  late _FauxPostgrest serveur;
  late ProviderContainer conteneur;

  /// La creation telle que la feuille Classes la lit : le fournisseur de
  /// production, avec le seul service des groupes pointe sur le faux serveur.
  PortCreationClasse creation() => conteneur.read(portCreationClasseProvider);

  Future<String> creer() => creation().creer(
    teacherId: 'enseignante-1',
    type: TypePublicGroupe.adulte,
    genre: GenreClasse.femmes,
    libelle: 'Tajwid du mardi',
    creneau: _mardi17,
    seuilMax: 6,
  );

  setUp(() async {
    serveur = _FauxPostgrest();
    await serveur.demarrer();
    conteneur = ProviderContainer(
      overrides: <Override>[
        serviceGroupesProvider.overrideWithValue(
          ServiceGroupesSupabase(serveur.client),
        ),
      ],
    );
  });

  tearDown(() async {
    conteneur.dispose();
    await serveur.arreter();
  });

  test('le fournisseur de production delegue a l\'adaptateur Supabase', () {
    expect(creation(), isA<CreationClasseParServiceGroupes>());
  });

  test('creation acceptee : l\'identifiant rendu, et la RPC part avec ses '
      'huit parametres', () async {
    serveur.corps = 'classe-1';

    expect(await creer(), 'classe-1');

    expect(serveur.requetes, hasLength(1));
    final _Requete r = serveur.requetes.single;
    expect(r.methode, 'POST');
    expect(r.chemin, 'rpc/creer_groupe');
    expect(r.corps, <String, Object?>{
      'p_teacher_profile_id': 'enseignante-1',
      'p_type_public': 'adulte',
      'p_libelle': 'Tajwid du mardi',
      'p_weekday': 2,
      'p_hour_local': 17,
      'p_seuil_max': 6,
      'p_timezone_iana': null,
      'p_couleur_jeton': null,
    });
  });

  for (final _Refus refus in _refus) {
    test('refus ${refus.code} « ${refus.message} » : CreationClasseRefusee '
        '(${refus.motif.name}), sans texte SQL ni SQLSTATE', () async {
      serveur.refuser(
        statut: refus.statut,
        code: refus.code,
        message: refus.message,
      );

      Object? leve;
      try {
        await creer();
      } on Object catch (e) {
        leve = e;
      }

      expect(leve, isNot(isA<PostgrestException>()));
      expect(leve, isA<CreationClasseRefusee>());
      expect((leve! as CreationClasseRefusee).motif, refus.motif);
      // Ce que `_message` de la feuille aurait lu : rien du serveur.
      final String texte = leve.toString();
      expect(texte, isNot(contains(refus.message)));
      expect(texte, isNot(contains(refus.code)));
      expect(serveur.requetes.single.chemin, 'rpc/creer_groupe');
    });
  }

  test('une erreur qui n\'est pas une reponse de PostgREST (connexion '
      'refusee) passe telle quelle : ce n\'est pas un refus', () async {
    await serveur.couper();

    Object? leve;
    try {
      await creer();
    } on Object catch (e) {
      leve = e;
    }

    expect(leve, isA<ClientException>());
    expect(leve, isNot(isA<CreationClasseRefusee>()));
  });
}
