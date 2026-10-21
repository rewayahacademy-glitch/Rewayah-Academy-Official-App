// COM-BACK-1 : decodage et appels des adaptateurs Supabase des Messages
// metier et des annonces, sur un faux appel RPC (aucun reseau).

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/communications/communications_supabase.dart';
import 'package:rewayah_academy/features/com_annonces/annonces_supabase.dart';
import 'package:rewayah_academy/features/com_annonces/port_annonces.dart';
import 'package:rewayah_academy/features/com_messages/messages_metier_supabase.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      titre == 'sayyida' ? 'Sayyida $prenom' : prenom;
  @override
  String objet(TypeObjetLie type) => type.name;
  @override
  String publicAnnonce(String code) => 'public:$code';
}

const String _fil = '11111111-1111-4111-8111-111111111111';
const String _classe = '22222222-2222-4222-8222-222222222222';
const String _foyer = '33333333-3333-4333-8333-333333333333';
const String _ens = '44444444-4444-4444-8444-444444444444';

final Map<String, dynamic> _filJson = <String, dynamic>{
  'id': _fil,
  'objet': <String, dynamic>{
    'type': 'classe',
    'id': _classe,
    'classe': 'An-Nour',
  },
  'accessible': true,
  'peut_ecrire': true,
  'dernier_message_le': '2026-10-16T08:00:00+00:00',
  'non_lus': 2,
  'parties': <Object>[
    <String, dynamic>{
      'id': _foyer,
      'nature': 'foyer',
      'fonction': 'famille',
      'eleves': <String>['Yasmine'],
      'est_soi': true,
    },
    <String, dynamic>{
      'id': _ens,
      'nature': 'profil',
      'fonction': 'enseignant',
      'prenom': 'Maryam',
      'titre': 'sayyida',
      'est_soi': false,
    },
  ],
  'messages': <Object>[
    <String, dynamic>{
      'id': '55555555-5555-4555-8555-555555555555',
      'texte': 'Salam',
      'envoye_le': '2026-10-16T10:00:00+02:00',
      'auteur': <String, dynamic>{
        'id': 'administration',
        'nature': 'equipe',
        'fonction': 'administration',
        'est_soi': false,
      },
    },
  ],
};

class _Faux {
  final List<(String, Map<String, dynamic>)> appels =
      <(String, Map<String, dynamic>)>[];
  Object? reponse;
  Exception? erreur;

  Future<Object?> call(String f, Map<String, dynamic> p) async {
    appels.add((f, p));
    if (erreur case final Exception e) throw e;
    return reponse;
  }
}

void main() {
  const _Libelles libelles = _Libelles();

  group('Messages metier', () {
    test('fil decode : parties, objet, capacite, instants UTC', () async {
      final _Faux faux = _Faux()..reponse = _filJson;
      final MessagesMetierSupabase port = MessagesMetierSupabase(
        faux.call,
        libelles: libelles,
      );
      final FilMetier? fil = await port.fil(_fil);
      expect(fil, isNotNull);
      expect(fil!.objet.libelle, 'Classe An-Nour');
      expect(fil.peut(CapaciteFil.ecrire), isTrue);
      expect(fil.interlocuteurs.single.nomAffiche, 'Sayyida Maryam');
      expect(fil.participants.first.fonction, 'Yasmine');
      expect(fil.messages.single.auteur.nomAffiche, 'Administration');
      expect(fil.messages.single.envoyeLe, DateTime.utc(2026, 10, 16, 8));
      expect(fil.attention.nonLus, 2);
      expect(faux.appels.single.$1, 'com_lire_fil');
    });

    test('fil refuse ou identifiant non uuid : null', () async {
      final _Faux faux = _Faux()
        ..erreur = const PostgrestException(message: 'x', code: '42501');
      final MessagesMetierSupabase port = MessagesMetierSupabase(
        faux.call,
        libelles: libelles,
      );
      expect(await port.fil(_fil), isNull);
      expect(await port.fil('pas-un-uuid'), isNull);
      expect(faux.appels, hasLength(1));
    });

    test('liste refusee (mineur) : capacite indisponible', () async {
      final _Faux faux = _Faux()
        ..erreur = const PostgrestException(message: 'x', code: '42501');
      expect(
        MessagesMetierSupabase(faux.call, libelles: libelles).fils(),
        throwsA(isA<CapaciteIndisponible>()),
      );
    });

    test('liste : resume avec apercu et interlocuteur', () async {
      final _Faux faux = _Faux()..reponse = <Object>[_filJson];
      final List<ResumeFil> fils = await MessagesMetierSupabase(
        faux.call,
        libelles: libelles,
      ).fils();
      expect(fils.single.apercu, 'Salam');
      expect(fils.single.interlocuteurs.single.id, _ens);
    });

    test('type sans contrat serveur : aucun appel', () async {
      final _Faux faux = _Faux();
      final MessagesMetierSupabase port = MessagesMetierSupabase(
        faux.call,
        libelles: libelles,
      );
      expect(
        await port.conversationsPourObjet(TypeObjetLie.mission, _fil),
        isEmpty,
      );
      expect(await port.filPourObjet(TypeObjetLie.annonce, _fil), isNull);
      expect(faux.appels, isEmpty);
    });

    test('conversations : nature, fil existant et attention', () async {
      final _Faux faux = _Faux()
        ..reponse = <Object>[
          <String, dynamic>{
            'interlocuteur': <String, dynamic>{
              'id': 'administration',
              'nature': 'equipe',
              'fonction': 'administration',
            },
            'nature': 'administration',
            'objet': <String, dynamic>{
              'type': 'classe',
              'id': _classe,
              'classe': 'An-Nour',
            },
            'fil_id': _fil,
            'non_lus': 1,
          },
        ];
      final List<ConversationPossible> c = await MessagesMetierSupabase(
        faux.call,
        libelles: libelles,
      ).conversationsPourObjet(TypeObjetLie.classe, _classe);
      expect(c.single.nature, NatureInterlocuteur.administration);
      expect(c.single.filId, _fil);
      expect(c.single.attention.nonLus, 1);
      expect(faux.appels.single.$2, <String, dynamic>{
        'p_type': 'classe',
        'p_objet_id': _classe,
      });
    });

    test(
      'envoi : cle serveur stable d un essai a l autre, refus propage',
      () async {
        final _Faux faux = _Faux()
          ..reponse = <String, dynamic>{
            'id': _fil,
            'envoye_le': '2026-10-16T08:00:00Z',
          };
        final MessagesMetierSupabase port = MessagesMetierSupabase(
          faux.call,
          libelles: libelles,
        );
        await port.envoyer(_fil, '  Salam  ', 'cle-ecran-1');
        await port.envoyer(_fil, 'Salam', 'cle-ecran-1');
        final Object? k1 = faux.appels[0].$2['p_cle_idempotence'];
        expect(k1, faux.appels[1].$2['p_cle_idempotence']);
        expect(estUuid(k1! as String), isTrue);
        expect(faux.appels[0].$2['p_texte'], 'Salam');
        faux.erreur = const PostgrestException(message: 'x', code: '42501');
        expect(
          port.envoyer(_fil, 'Salam', 'cle-ecran-2'),
          throwsA(isA<PostgrestException>()),
        );
      },
    );
  });

  group('Annonces', () {
    final Map<String, dynamic> annonce = <String, dynamic>{
      'id': _fil,
      'titre': 'Seance',
      'texte': 'Revisez.',
      'publiee_le': '2026-10-16T08:00:00Z',
      'classe': <String, dynamic>{'id': _classe, 'libelle': 'An-Nour'},
      'auteur': <String, dynamic>{
        'id': _ens,
        'nature': 'profil',
        'fonction': 'enseignant',
        'prenom': 'Maryam',
        'titre': 'sayyida',
      },
      'lue': true,
    };

    test('annonces de Classe et capacite publier', () async {
      final _Faux faux = _Faux()
        ..reponse = <String, dynamic>{
          'annonces': <Object>[annonce],
          'peut_publier': true,
        };
      final AnnoncesDeLaClasse v = await AnnoncesSupabase(
        faux.call,
        libelles: libelles,
      ).annoncesDeClasse(_classe);
      expect(v.peut(CapaciteAnnonces.publier), isTrue);
      expect(v.annonces.single.classe.libelle, 'Classe An-Nour');
      expect(v.annonces.single.auteur!.nomAffiche, 'Sayyida Maryam');
      expect(v.annonces.single.lue, isTrue);
      expect(v.annonces.single.niveau, NiveauAttention.aLire);
    });

    test(
      'lecture refusee : capacite indisponible ; annonce absente : null',
      () async {
        final _Faux faux = _Faux()
          ..erreur = const PostgrestException(message: 'x', code: '42501');
        final AnnoncesSupabase port = AnnoncesSupabase(
          faux.call,
          libelles: libelles,
        );
        expect(
          port.annoncesDeClasse(_classe),
          throwsA(isA<CapaciteIndisponible>()),
        );
        expect(await port.annonce(_fil), isNull);
      },
    );

    test('cibles : classe et public rediges', () async {
      final _Faux faux = _Faux()
        ..reponse = <Object>[
          <String, dynamic>{
            'id': 'toutes',
            'nature': 'toutes',
            'libelle': 'toutes',
          },
          <String, dynamic>{
            'id': 'classe:$_classe',
            'nature': 'classe',
            'classe_id': _classe,
            'libelle': 'An-Nour',
          },
        ];
      final List<CibleAnnonce> c = await AnnoncesSupabase(
        faux.call,
        libelles: libelles,
      ).ciblesPublication();
      expect(c.first.libelle, 'public:toutes');
      expect(c.last.classeId, _classe);
      expect(c.last.libelle, 'Classe An-Nour');
    });

    test('publier : accuse du serveur, date en UTC, cle stable', () async {
      final _Faux faux = _Faux()
        ..reponse = <String, dynamic>{
          'id': _fil,
          'etat': 'planifiee',
          'le': '2026-10-17T07:00:00Z',
        };
      final AnnonceConfirmee a =
          await AnnoncesSupabase(faux.call, libelles: libelles).publier(
            brouillon: BrouillonAnnonce(
              titre: ' Vacances ',
              texte: 'Pas de seance.',
              cible: const CibleAnnonce(
                id: 'toutes',
                libelle: 'x',
                nature: NatureCible.toutes,
              ),
              programmeeLe: DateTime.utc(2026, 10, 17, 7),
            ),
            cleIdempotence: 'cle-1',
          );
      expect(a.etat, EtatAnnonce.planifiee);
      expect(faux.appels.single.$2['p_titre'], 'Vacances');
      expect(
        faux.appels.single.$2['p_programmee_le'],
        '2026-10-17T07:00:00.000Z',
      );
      expect(faux.appels.single.$2['p_cle_idempotence'], cleServeur('cle-1'));
    });
  });
}
