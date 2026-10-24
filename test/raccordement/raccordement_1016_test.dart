// RACCORDEMENT-1016 : les adaptateurs branches le 16/10 parlent aux bonnes
// RPC, avec les bons parametres, et decodent ce que le serveur rend.
//
// Le VRAI client Supabase parle a un serveur HTTP local (aucun service reel,
// aucune dependance ajoutee), comme `classes_foyer_supabase_tri_test.dart` ;
// les annonces passent par un faux appel RPC, comme
// `communications_supabase_test.dart`.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/accessibilite/accueil_accessibilite_supabase.dart';
import 'package:rewayah_academy/core/accessibilite/port_accueil_accessibilite.dart';
import 'package:rewayah_academy/core/admin/bibliotheque_admin_supabase.dart';
import 'package:rewayah_academy/core/admin/modeles_bibliotheque_admin.dart';
import 'package:rewayah_academy/core/admin/port_bibliotheque_admin.dart';
import 'package:rewayah_academy/core/capacites/port_classes_foyer.dart';
import 'package:rewayah_academy/core/communications/communications_supabase.dart';
import 'package:rewayah_academy/core/communications/modeles_communication.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/tc_groupe/group_home_vm.dart';
import 'package:rewayah_academy/core/tc_groupe/groupes_supabase.dart';
import 'package:rewayah_academy/core/tc_horloge/horloge_supabase.dart';
import 'package:rewayah_academy/core/tc_horloge/port_horloge_seance.dart';
import 'package:rewayah_academy/core/tc_horloge/session_clock_vm.dart';
import 'package:rewayah_academy/features/com_annonces/annonces_supabase.dart';
import 'package:rewayah_academy/features/com_annonces/port_annonces.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Une requete recue par le faux serveur.
typedef Requete = ({String methode, String chemin, Object? corps});

/// Un faux PostgREST : chaque chemin rend la reponse posee pour lui.
class _Serveur {
  final List<Requete> requetes = <Requete>[];
  final Map<String, ({int statut, Object? corps})> reponses =
      <String, ({int statut, Object? corps})>{};
  late HttpServer _http;
  late SupabaseClient client;

  Future<void> demarrer() async {
    _http = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _http.listen((HttpRequest r) async {
      final String brut = await utf8.decoder.bind(r).join();
      final String chemin = r.uri.path.replaceFirst('/rest/v1/', '');
      requetes.add((
        methode: r.method,
        chemin: chemin,
        corps: brut.isEmpty ? null : jsonDecode(brut),
      ));
      final ({int statut, Object? corps}) rep =
          reponses[chemin] ?? (statut: 200, corps: const <Object>[]);
      final bool objet = (r.headers.value('accept') ?? '').contains(
        'vnd.pgrst.object',
      );
      Object? corps = rep.corps;
      if (objet && corps is List) {
        corps = corps.isEmpty ? null : corps.first;
      }
      r.response
        ..statusCode = rep.statut
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(corps));
      await r.response.close();
    });
    client = SupabaseClient(
      'http://${_http.address.address}:${_http.port}',
      'cle-fictive',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
  }

  Future<void> arreter() async {
    await client.dispose();
    await _http.close(force: true);
  }

  List<Requete> vers(String chemin) =>
      requetes.where((Requete q) => q.chemin == chemin).toList();
}

const String _classe = '11111111-1111-4111-8111-111111111111';
const String _classeB = '22222222-2222-4222-8222-222222222222';
const String _seance = '33333333-3333-4333-8333-333333333333';
const String _eleve = '44444444-4444-4444-8444-444444444444';

Map<String, dynamic> _ligneHorloge(String? seance, String debut) =>
    <String, dynamic>{
      'session_id': seance,
      'debut_utc': debut,
      'fin_prevue_utc': '2026-10-20T09:45:00Z',
      'join_opens_at_utc': '2026-10-20T08:40:00Z',
      'fenetre_minutes': 20,
      'grace_minutes': 15,
      'maintenant_utc': '2026-10-16T10:00:00Z',
      'tz_utilisateur': 'Europe/Paris',
      'heure_utilisateur': '11:00',
      'jour_iso_utilisateur': 2,
      'date_utilisateur': '2026-10-20',
      'tz_groupe': 'Europe/Paris',
      'heure_groupe': '11:00',
      'jour_iso_groupe': 2,
      'date_groupe': '2026-10-20',
    };

Map<String, dynamic> _ligneClasse(String id, String libelle) =>
    <String, dynamic>{
      'groupe_id': id,
      'libelle': libelle,
      'type_public': 'enfant',
      'seuil_max': 5,
      'nb_membres': 3,
      'teacher_id': 'enseignant',
      'teacher_prenom': 'Maryam',
      'teacher_titre': 'sayyida',
    };

class _Classes implements PortClassesFoyer {
  _Classes(this.classes);
  final List<ClasseFoyer> classes;
  @override
  Future<List<ClasseFoyer>> classesDe(String eleveId) async => classes;
  @override
  Future<ClasseFoyer?> classe({
    required String groupeId,
    required String eleveId,
  }) async => null;
}

class _Horloges implements PortHorlogeSeance {
  _Horloges(this.parClasse);
  final Map<String, SessionClockVM> parClasse;
  final List<String> demandes = <String>[];
  @override
  Future<SessionClockVM?> horlogeDe({
    required String groupeId,
    String? sessionId,
  }) async {
    demandes.add(groupeId);
    return parClasse[groupeId];
  }

  @override
  Stream<SessionClockVM> suivre({
    required String groupeId,
    String? sessionId,
  }) => const Stream<SessionClockVM>.empty();

  @override
  Future<DateTime> maintenantServeurUtc() async => DateTime.utc(2026, 10, 16);
}

class _Libelles implements LibellesCommunication {
  const _Libelles();
  @override
  String classe(String libelle) => 'Classe $libelle';
  @override
  String administration() => 'Administration';
  @override
  String famille() => 'Famille';
  @override
  String enseignant({required String prenom, String? nom, String? titre}) =>
      prenom;
  @override
  String objet(TypeObjetLie type) => type.name;
  @override
  String publicAnnonce(String code) => 'public:$code';
}

void main() {
  late _Serveur serveur;

  setUp(() async {
    serveur = _Serveur();
    await serveur.demarrer();
    // `horloge_classe` (concierge (a), 24/10/2026) n'est pas encore sur la
    // base : l'adaptateur garde l'ancien chemin.
    serveur.reponses['rpc/horloge_classe'] = (
      statut: 404,
      corps: <String, dynamic>{'code': 'PGRST202', 'message': 'absente'},
    );
  });

  tearDown(() => serveur.arreter());

  group('A et B : la prochaine seance d une Classe', () {
    test('sans seance donnee, la prochaine est demandee au serveur, puis '
        'son horloge', () async {
      serveur.reponses['rpc/prochaine_seance_groupe'] = (
        statut: 200,
        corps: _seance,
      );
      serveur.reponses['rpc/horloge_seance'] = (
        statut: 200,
        corps: <Object>[_ligneHorloge(_seance, '2026-10-20T09:00:00Z')],
      );
      final SessionClockVM? h = await HorlogeSeanceSupabase(serveur.client)
          .horlogeDe(groupeId: _classe);

      expect(h, isNotNull);
      expect(h!.sessionId, _seance);
      expect(h.debutUtc, DateTime.utc(2026, 10, 20, 9));
      expect(
        serveur.vers('rpc/prochaine_seance_groupe').single.corps,
        <String, dynamic>{'p_groupe_id': _classe},
      );
      expect(serveur.vers('rpc/horloge_seance').single.corps, <String, dynamic>{
        'p_session_id': _seance,
      });
    });

    test('aucune seance programmee : null, aucune horloge fabriquee', () async {
      serveur.reponses['rpc/prochaine_seance_groupe'] = (
        statut: 200,
        corps: null,
      );
      expect(
        await HorlogeSeanceSupabase(serveur.client)
            .horlogeDe(groupeId: _classe),
        isNull,
      );
      expect(serveur.vers('rpc/horloge_seance'), isEmpty);
    });

    test('Classe qui ne concerne pas l appelant (42501) : null, pas une '
        'panne', () async {
      serveur.reponses['rpc/prochaine_seance_groupe'] = (
        statut: 403,
        corps: <String, dynamic>{'code': '42501', 'message': 'refus'},
      );
      expect(
        await HorlogeSeanceSupabase(serveur.client)
            .horlogeDe(groupeId: _classe),
        isNull,
      );
    });

    test('une seance donnee est lue telle quelle, sans detour', () async {
      serveur.reponses['rpc/horloge_seance'] = (
        statut: 200,
        corps: <Object>[_ligneHorloge(_seance, '2026-10-20T09:00:00Z')],
      );
      await HorlogeSeanceSupabase(serveur.client)
          .horlogeDe(groupeId: _classe, sessionId: _seance);
      expect(serveur.vers('rpc/prochaine_seance_groupe'), isEmpty);
    });

    test('le flux emet tout de suite, sans attendre la cadence', () async {
      serveur.reponses['rpc/prochaine_seance_groupe'] = (
        statut: 200,
        corps: _seance,
      );
      serveur.reponses['rpc/horloge_seance'] = (
        statut: 200,
        corps: <Object>[_ligneHorloge(_seance, '2026-10-20T09:00:00Z')],
      );
      final SessionClockVM premier = await HorlogeSeanceSupabase(
        serveur.client,
        cadence: const Duration(hours: 1),
      ).suivre(groupeId: _classe).first;
      expect(premier.sessionId, _seance);
    });
  });

  group('Concierge (a) : l horloge tiree du creneau de la Classe', () {
    test('horloge_classe repond : une seule lecture, session_id nul tant '
        'que la seance n existe pas', () async {
      serveur.reponses['rpc/horloge_classe'] = (
        statut: 200,
        corps: <Object>[_ligneHorloge(null, '2026-10-20T09:00:00Z')],
      );
      final SessionClockVM? h = await HorlogeSeanceSupabase(serveur.client)
          .horlogeDe(groupeId: _classe);
      expect(h, isNotNull);
      expect(h!.sessionId, isNull);
      expect(h.debutUtc, DateTime.utc(2026, 10, 20, 9));
      expect(serveur.vers('rpc/horloge_classe').single.corps, <String, dynamic>{
        'p_groupe_id': _classe,
      });
      expect(serveur.vers('rpc/prochaine_seance_groupe'), isEmpty);
      expect(serveur.vers('rpc/horloge_seance'), isEmpty);
    });

    test('horloge_classe vide : null, aucune horloge fabriquee', () async {
      serveur.reponses['rpc/horloge_classe'] = (
        statut: 200,
        corps: const <Object>[],
      );
      expect(
        await HorlogeSeanceSupabase(serveur.client)
            .horlogeDe(groupeId: _classe),
        isNull,
      );
      expect(serveur.vers('rpc/prochaine_seance_groupe'), isEmpty);
    });

    test('Classe qui ne concerne pas l appelant (42501) : null', () async {
      serveur.reponses['rpc/horloge_classe'] = (
        statut: 403,
        corps: <String, dynamic>{'code': '42501', 'message': 'refus'},
      );
      expect(
        await HorlogeSeanceSupabase(serveur.client)
            .horlogeDe(groupeId: _classe),
        isNull,
      );
      expect(serveur.vers('rpc/prochaine_seance_groupe'), isEmpty);
    });
  });

  group('A : l Accueil du Mode Accessibilite', () {
    test('prenom, tutoiement du mineur, Classe dont la seance vient en '
        'premier', () async {
      serveur.reponses['profiles'] = (
        statut: 200,
        corps: <Object>[
          <String, dynamic>{'first_name': 'Yasmine'},
        ],
      );
      serveur.reponses['student_profiles'] = (
        statut: 200,
        corps: <Object>[
          <String, dynamic>{'student_type': 'minor'},
        ],
      );
      final _Horloges horloges = _Horloges(<String, SessionClockVM>{
        _classeB: horlogeDepuisLigne(
          _ligneHorloge(_seance, '2026-10-20T09:00:00Z'),
        ),
      });
      final DonneesAccueilAccessibilite d = await AccueilAccessibiliteSupabase(
        serveur.client,
        utilisateur: () => _eleve,
        classes: _Classes(<ClasseFoyer>[
          ClasseFoyer(
            eleveId: _eleve,
            classe: groupeDepuisLigne(_ligneClasse(_classe, 'Al-Fajr')),
          ),
          ClasseFoyer(
            eleveId: _eleve,
            classe: groupeDepuisLigne(_ligneClasse(_classeB, 'An-Nour')),
          ),
        ]),
        horloges: horloges,
      ).lire();

      expect(d.prenom, 'Yasmine');
      expect(d.tutoiement, isTrue);
      expect(d.espace, isNotNull);
      expect(d.espace!.role, RoleEspaceGroupe.eleve);
      expect(d.espace!.identite.groupeId, _classeB);
      expect(d.espace!.horloge?.sessionId, _seance);
      expect(d.espace!.identite.prochaineSeance?.sessionId, _seance);
      expect(horloges.demandes, <String>[_classe, _classeB]);
      expect(
        serveur.vers('profiles').single.chemin,
        'profiles',
        reason: 'le prenom se lit dans le profil de la session',
      );
    });

    test('sans Classe : etat vide, jamais une Classe inventee', () async {
      serveur.reponses['profiles'] = (
        statut: 200,
        corps: <Object>[
          <String, dynamic>{'first_name': 'Hamza'},
        ],
      );
      serveur.reponses['student_profiles'] = (
        statut: 200,
        corps: <Object>[
          <String, dynamic>{'student_type': 'autonomous'},
        ],
      );
      final DonneesAccueilAccessibilite d = await AccueilAccessibiliteSupabase(
        serveur.client,
        utilisateur: () => _eleve,
        classes: _Classes(const <ClasseFoyer>[]),
        horloges: _Horloges(const <String, SessionClockVM>{}),
      ).lire();
      expect(d.espace, isNull);
      expect(d.tutoiement, isFalse);
    });

    test('Classe sans seance programmee : la Classe, sans horloge', () async {
      serveur.reponses['profiles'] = (
        statut: 200,
        corps: <Object>[
          <String, dynamic>{'first_name': 'Adam'},
        ],
      );
      final DonneesAccueilAccessibilite d = await AccueilAccessibiliteSupabase(
        serveur.client,
        utilisateur: () => _eleve,
        classes: _Classes(<ClasseFoyer>[
          ClasseFoyer(
            eleveId: _eleve,
            classe: groupeDepuisLigne(_ligneClasse(_classe, 'Al-Fajr')),
          ),
        ]),
        horloges: _Horloges(const <String, SessionClockVM>{}),
      ).lire();
      expect(d.espace!.identite.groupeId, _classe);
      expect(d.espace!.horloge, isNull);
    });

    test('profil illisible ou session absente : la lecture echoue', () async {
      final AccueilAccessibiliteSupabase sansProfil =
          AccueilAccessibiliteSupabase(
            serveur.client,
            utilisateur: () => _eleve,
            classes: _Classes(const <ClasseFoyer>[]),
            horloges: _Horloges(const <String, SessionClockVM>{}),
          );
      await expectLater(sansProfil.lire(), throwsStateError);
      final AccueilAccessibiliteSupabase sansSession =
          AccueilAccessibiliteSupabase(
            serveur.client,
            utilisateur: () => null,
            classes: _Classes(const <ClasseFoyer>[]),
            horloges: _Horloges(const <String, SessionClockVM>{}),
          );
      await expectLater(sansSession.lire(), throwsStateError);
    });
  });

  group('C : mise a jour d un support', () {
    test('seuls les champs renseignes partent, en valeurs SQL', () {
      expect(
        modificationJson(
          const ModificationSupport(
            titre: 'Tuhfat',
            organisme: '',
            visibilite: PolitiqueAcces.inscrits,
            politiqueHorsLigne: PolitiqueOffline.surDemande,
          ),
        ),
        <String, dynamic>{
          'titre': 'Tuhfat',
          'organisme': '',
          'visibilite': 'inscrits',
          'politiqueHorsLigne': 'sur_demande',
        },
      );
    });

    test('library_mettre_a_jour : revision attendue, EcritureFaite', () async {
      serveur.reponses['rpc/library_mettre_a_jour'] = (
        statut: 200,
        corps: <String, dynamic>{'resultat': 'EcritureFaite', 'revision': 8},
      );
      final ResultatEcriture r = await BibliothequeAdminSupabase(serveur.client)
          .mettreAJour(
            supportId: _classe,
            modification: const ModificationSupport(description: 'Poeme'),
            revisionAttendue: 7,
          );
      expect(r, isA<EcritureFaite>());
      expect((r as EcritureFaite).revision, 8);
      expect(
        serveur.vers('rpc/library_mettre_a_jour').single.corps,
        <String, dynamic>{
          'p_resource_id': _classe,
          'p_modification': <String, dynamic>{'description': 'Poeme'},
          'p_revision_attendue': 7,
        },
      );
    });

    test(
      'revision perimee : conflit ; refus serveur : non autorisee',
      () async {
        serveur.reponses['rpc/library_mettre_a_jour'] = (
          statut: 200,
          corps: <String, dynamic>{
            'resultat': 'EcritureEnConflit',
            'revision': 9,
          },
        );
        final BibliothequeAdminSupabase port = BibliothequeAdminSupabase(
          serveur.client,
        );
        expect(
          await port.mettreAJour(
            supportId: _classe,
            modification: const ModificationSupport(titre: 'x'),
            revisionAttendue: 7,
          ),
          isA<EcritureEnConflit>(),
        );
        serveur.reponses['rpc/library_mettre_a_jour'] = (
          statut: 403,
          corps: <String, dynamic>{'code': '42501', 'message': 'refus'},
        );
        await expectLater(
          port.mettreAJour(
            supportId: _classe,
            modification: const ModificationSupport(titre: 'x'),
            revisionAttendue: 7,
          ),
          throwsA(isA<BibliothequeNonAutorisee>()),
        );
      },
    );

    test('la fiche relit organisme, description et conditions', () {
      final FicheSupport f = ficheSupportJson(<String, dynamic>{
        'support': <String, dynamic>{
          'id': _classe,
          'titre': 'Tuhfat',
          'type': 'pdf',
          'langue': 'fr',
          'categorie': 'tajwid',
          'niveaux': <String>[],
          'politiqueAcces': 'admin',
          'politiqueHorsLigne': 'jamais',
          'modifieLeUtc': '2026-10-16T08:00:00Z',
          'organisme': 'Editions',
          'description': 'Poeme',
          'conditionsAttribution': 'Usage en classe',
        },
        'revision': 3,
        'versions': <Object>[],
        'historique': <Object>[],
        'capacites': <String, dynamic>{'peutModifier': true},
      }, acteur: 'Direction');
      expect(f.organisme, 'Editions');
      expect(f.description, 'Poeme');
      expect(f.conditionsAttribution, 'Usage en classe');
      expect(f.capacites.peutModifier, isTrue);
    });
  });

  group('D : consommation du code d invitation', () {
    test('enseignant invite : une seule RPC cree le profil et consomme le '
        'code', () async {
      serveur.reponses['rpc/inscrire_enseignant_invite'] = (
        statut: 200,
        corps: <String, dynamic>{'resultat': 'consommee'},
      );
      await ServiceDossierSupabase(serveur.client).creerProfil(
        role: AppRole.teacher,
        prenom: 'Hafsa',
        nom: 'Exemple',
        codeInvitation: 'ABCD-EFGH-JKMN',
      );
      expect(serveur.vers('rpc/creer_profil_inscription'), isEmpty);
      expect(
        serveur.vers('rpc/inscrire_enseignant_invite').single.corps,
        <String, dynamic>{
          'p_code': 'ABCD-EFGH-JKMN',
          'p_first_name': 'Hafsa',
          'p_last_name': 'Exemple',
          'p_gender': null,
        },
      );
    });

    test('code refuse : InvitationNonConsommee, avec la raison', () async {
      serveur.reponses['rpc/inscrire_enseignant_invite'] = (
        statut: 200,
        corps: <String, dynamic>{'resultat': 'expiree'},
      );
      await expectLater(
        ServiceDossierSupabase(serveur.client).creerProfil(
          role: AppRole.teacher,
          prenom: 'Hafsa',
          nom: 'Exemple',
          codeInvitation: 'ABCD-EFGH-JKMN',
        ),
        throwsA(
          isA<InvitationNonConsommee>().having(
            (InvitationNonConsommee e) => e.resultat,
            'resultat',
            'expiree',
          ),
        ),
      );
    });

    test('sans code, ou pour un tuteur, la creation publique reste celle '
        'd avant', () async {
      final ServiceDossierSupabase service = ServiceDossierSupabase(
        serveur.client,
      );
      await service.creerProfil(
        role: AppRole.teacher,
        prenom: 'Ali',
        nom: 'Bah',
      );
      await service.creerProfil(
        role: AppRole.guardian,
        prenom: 'Amina',
        nom: 'Diallo',
        codeInvitation: 'ABCD-EFGH-JKMN',
      );
      expect(serveur.vers('rpc/inscrire_enseignant_invite'), isEmpty);
      expect(serveur.vers('rpc/creer_profil_inscription'), hasLength(2));
    });
  });

  group('E : annonces de l academie', () {
    Map<String, dynamic> annonce(String id, String le, {bool classe = true}) =>
        <String, dynamic>{
          'id': id,
          'titre': 'Titre $id',
          'texte': 'Texte',
          'publiee_le': le,
          'classe': classe
              ? <String, dynamic>{'id': _classe, 'libelle': 'An-Nour'}
              : null,
          'auteur': <String, dynamic>{
            'id': 'administration',
            'nature': 'equipe',
            'fonction': 'administration',
          },
          'lue': false,
        };

    const String a1 = '55555555-5555-4555-8555-555555555551';
    const String a2 = '55555555-5555-4555-8555-555555555552';

    test('les annonces generales rejoignent la liste de la Classe, la plus '
        'recente d abord', () async {
      final List<String> appels = <String>[];
      Future<Object?> appel(String f, Map<String, dynamic> p) async {
        appels.add('$f ${p['p_groupe_id']}');
        return f == 'com_annonces_de_classe'
            ? <String, dynamic>{
                'annonces': <Object>[annonce(a1, '2026-10-15T08:00:00Z')],
                'peut_publier': false,
              }
            : <String, dynamic>{
                'annonces': <Object>[
                  annonce(a2, '2026-10-16T08:00:00Z'),
                  annonce(
                    '55555555-5555-4555-8555-555555555553',
                    '2026-10-16T09:00:00Z',
                    classe: false,
                  ),
                ],
              };
      }

      final AnnoncesDeLaClasse v = await AnnoncesSupabase(
        appel,
        libelles: const _Libelles(),
      ).annoncesDeClasse(_classe);
      expect(appels, <String>[
        'com_annonces_de_classe $_classe',
        'com_annonces_academie $_classe',
      ]);
      expect(v.annonces.map((AnnonceClasse a) => a.id), <String>[a2, a1]);
      expect(v.annonces.first.classe.libelle, 'Classe An-Nour');
    });

    test('RPC de l academie pas encore deployee : la liste de la Classe '
        'reste', () async {
      Future<Object?> appel(String f, Map<String, dynamic> p) async {
        if (f == 'com_annonces_academie') {
          throw const PostgrestException(message: 'absente', code: 'PGRST202');
        }
        return <String, dynamic>{
          'annonces': <Object>[annonce(a1, '2026-10-15T08:00:00Z')],
          'peut_publier': false,
        };
      }

      final AnnoncesDeLaClasse v = await AnnoncesSupabase(
        appel,
        libelles: const _Libelles(),
      ).annoncesDeClasse(_classe);
      expect(v.annonces.single.id, a1);
    });

    test('annonce generale sans Classe de contexte : null, jamais une '
        'erreur de decodage', () async {
      Future<Object?> appel(String f, Map<String, dynamic> p) async =>
          annonce(a2, '2026-10-16T08:00:00Z', classe: false);
      expect(
        await AnnoncesSupabase(appel, libelles: const _Libelles()).annonce(a2),
        isNull,
      );
    });
  });
}
