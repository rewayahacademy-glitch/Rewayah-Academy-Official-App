// PE-D1 MESSAGERIE-FIABLE : l'adaptateur Supabase.
// - le fil se lit par `com_lire_fil_page` (50 messages, `plus_anciens`, cle
//   d'envoi de mes messages) ; sans la fonction au serveur (migration pas
//   installee), il retombe sur `com_lire_fil`, une seule fois ;
// - la page precedente part avec le repere du plus ancien message ;
// - un refus du serveur devient sa vraie phrase (`EnvoiRefuse`), une coupure
//   devient `EnvoiCoupe` (reessayee par le fil), jamais l'inverse.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:rewayah_academy/core/communications/libelles_communication_slang.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_delais.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/features/com_messages/messages_metier_supabase.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthRetryableFetchException, PostgrestException;

const String _fil = '7c400000-0000-4000-8000-0000000000f9';
const String _cle = '7c400000-0000-4000-8000-00000000c1e1';

Map<String, dynamic> _filJson({bool plus = true}) => <String, dynamic>{
  'id': _fil,
  'objet': <String, dynamic>{'type': 'classe', 'id': _fil, 'classe': 'An-Nour'},
  'accessible': true,
  'peut_ecrire': true,
  'parties': <Object>[
    <String, dynamic>{
      'id': '7c400000-0000-4000-8000-0000000000e1',
      'nature': 'profil',
      'fonction': 'enseignant',
      'prenom': 'Fictive',
      'est_soi': true,
    },
    <String, dynamic>{
      'id': 'administration',
      'nature': 'equipe',
      'fonction': 'administration',
      'est_soi': false,
    },
  ],
  'plus_anciens': plus,
  'messages': <Object>[
    <String, dynamic>{
      'id': '7c400000-0000-4000-8000-0000000000a1',
      'texte': 'Bonjour',
      'envoye_le': '2026-11-20T10:00:00Z',
      'auteur': <String, dynamic>{
        'id': '7c400000-0000-4000-8000-0000000000e1',
        'nature': 'profil',
        'fonction': 'enseignant',
        'prenom': 'Fictive',
        'est_soi': true,
      },
      'cle_idempotence': _cle,
    },
    <String, dynamic>{
      'id': '7c400000-0000-4000-8000-0000000000a2',
      'texte': 'Reponse',
      'envoye_le': '2026-11-20T10:01:00Z',
      'auteur': <String, dynamic>{
        'id': 'administration',
        'nature': 'equipe',
        'fonction': 'administration',
        'est_soi': false,
      },
    },
  ],
};

/// Une coupure du client HTTP sous un nom quelconque (comme apres
/// minification) : elle reste une coupure.
class _CoupureAuNomQuelconque extends http.ClientException {
  _CoupureAuNomQuelconque() : super('coupe');
}

/// Un type au nom trompeur qui n'est PAS une coupure.
class _ClientExceptionPourLeNom implements Exception {}

class _Faux {
  final List<(String, Map<String, dynamic>)> appels =
      <(String, Map<String, dynamic>)>[];
  Exception? Function(String fonction)? erreur;
  Object? reponse;

  Future<Object?> call(String f, Map<String, dynamic> p) async {
    appels.add((f, p));
    final Exception? e = erreur?.call(f);
    if (e != null) throw e;
    return reponse;
  }
}

MessagesMetierSupabase _port(_Faux faux) => MessagesMetierSupabase(
  faux.call,
  libelles: const LibellesCommunicationSlang(),
);

void main() {
  group('lecture par pages', () {
    test('le fil : une page, plus_anciens, ma cle d envoi seulement', () async {
      final _Faux faux = _Faux()..reponse = _filJson();
      final FilMetier? fil = await _port(faux).fil(_fil);
      expect(faux.appels.single.$1, 'com_lire_fil_page');
      expect(faux.appels.single.$2['p_limite'], PortPagesFil.taillePage);
      expect(fil!.plusAnciens, isTrue);
      expect(fil.messages.first.cleIdempotence, _cle);
      expect(fil.messages.last.cleIdempotence, isNull);
    });

    test('fonction absente : repli sur com_lire_fil, une seule fois', () async {
      final _Faux faux = _Faux()
        ..reponse = _filJson(plus: false)
        ..erreur = (String f) => f == 'com_lire_fil_page'
            ? const PostgrestException(message: 'absente', code: 'PGRST202')
            : null;
      final MessagesMetierSupabase port = _port(faux);
      final FilMetier? fil = await port.fil(_fil);
      expect(fil, isNotNull);
      expect(fil!.plusAnciens, isFalse);
      await port.fil(_fil);
      expect(
        faux.appels.map(((String, Map<String, dynamic>) a) => a.$1),
        <String>['com_lire_fil_page', 'com_lire_fil', 'com_lire_fil'],
      );
      final PageMessagesFil page = await port.messagesAvant(
        _fil,
        '7c400000-0000-4000-8000-0000000000a1',
      );
      expect(page.messages, isEmpty);
      expect(page.plusAnciens, isFalse);
    });

    test('page precedente : le repere part, la page revient', () async {
      final _Faux faux = _Faux()..reponse = _filJson(plus: false);
      final PageMessagesFil page = await _port(faux)
          .messagesAvant(_fil, '7c400000-0000-4000-8000-0000000000b9');
      expect(faux.appels.single.$1, 'com_lire_fil_page');
      expect(
        faux.appels.single.$2['p_avant'],
        '7c400000-0000-4000-8000-0000000000b9',
      );
      expect(page.messages, hasLength(2));
      expect(page.plusAnciens, isFalse);
    });
  });

  group('envoi : refus ou coupure', () {
    Future<Object> echec(Exception erreur) async {
      final _Faux faux = _Faux()..erreur = (String _) => erreur;
      try {
        await _port(faux).envoyer(_fil, 'Bonjour', 'cle-ecran');
      } on Object catch (e) {
        return e;
      }
      fail('l envoi devait echouer');
    }

    final m = t.com.messages;

    test('42501 : plus le droit d ecrire', () async {
      final Object e = await echec(
        const PostgrestException(message: 'fil indisponible', code: '42501'),
      );
      expect(e, isA<EnvoiRefuse>());
      expect((e as EnvoiRefuse).phrase, m.fil.refusFerme);
    });

    test('22023 : texte vide ou trop long', () async {
      final Object e = await echec(
        const PostgrestException(message: 'texte', code: '22023'),
      );
      expect((e as EnvoiRefuse).phrase, m.fil.refusTexte);
    });

    test('53400 : la limite du jour d un candidat, comme avant', () async {
      final Object e = await echec(
        const PostgrestException(message: 'plafond', code: '53400'),
      );
      expect((e as EnvoiRefuse).phrase, m.candidature.plafond);
    });

    test('code inconnu : echec ordinaire (« Reessayer »), jamais un refus '
        'invente', () async {
      final Object e = await echec(
        const PostgrestException(message: 'x', code: 'P0001'),
      );
      expect(e, isA<PostgrestException>());
    });

    test('pannes passageres connues : coupure reessayable', () async {
      for (final String code in <String>[
        '',
        '503',
        '504',
        '408',
        '429',
        'PGRST000',
        'PGRST001',
        'PGRST002',
        'PGRST003',
        'PGRST301',
        '57014',
        '40001',
        '40P01',
        '53300',
        '08006',
        '57P01',
        '55P03',
      ]) {
        expect(
          await echec(PostgrestException(message: 'panne', code: code)),
          isA<EnvoiCoupe>(),
          reason: code,
        );
      }
    });

    test('jamais un statut a trois chiffres lu dans un SQLSTATE', () {
      expect(codePassager('42501'), isFalse);
      expect(codePassager('500'), isTrue);
      expect(codePassager('404'), isFalse);
    });

    test('reseau coupe, delai : coupure, classee par type et non par nom '
        '(le nom est illisible en JavaScript minifie)', () async {
      expect(await echec(_CoupureAuNomQuelconque()), isA<EnvoiCoupe>());
      expect(
        await echec(http.ClientException('Failed to fetch')),
        isA<EnvoiCoupe>(),
      );
      expect(await echec(TimeoutException('lent')), isA<EnvoiCoupe>());
      expect(
        await echec(AuthRetryableFetchException(message: 'reseau')),
        isA<EnvoiCoupe>(),
      );
      // Un type dont le NOM ressemble a une coupure, mais qui n'en est pas
      // une : echec ordinaire.
      expect(
        await echec(_ClientExceptionPourLeNom()),
        isA<_ClientExceptionPourLeNom>(),
      );
    });

    testWidgets('un envoi qui ne repond pas finit en coupure', (
      WidgetTester tester,
    ) async {
      final Completer<Object?> jamais = Completer<Object?>();
      final MessagesMetierSupabase port = MessagesMetierSupabase(
        (String f, Map<String, dynamic> p) => jamais.future,
        libelles: const LibellesCommunicationSlang(),
      );
      Object? erreur;
      unawaited(
        port
            .envoyer(_fil, 'Bonjour', 'cle-ecran')
            .then<void>((_) {}, onError: (Object e) => erreur = e),
      );
      await tester.pump(AppDelais.requeteMax - const Duration(seconds: 1));
      expect(erreur, isNull);
      await tester.pump(const Duration(seconds: 2));
      expect(erreur, isA<EnvoiCoupe>());
    });

    test('la cle d ecran donne toujours la meme cle serveur', () async {
      final _Faux faux = _Faux()
        ..reponse = <String, dynamic>{
          'id': '7c400000-0000-4000-8000-0000000000a1',
        };
      final MessagesMetierSupabase port = _port(faux);
      await port.envoyer(_fil, 'Bonjour', 'cle-ecran');
      await port.envoyer(_fil, 'Bonjour', 'cle-ecran');
      expect(
        faux.appels.first.$2['p_cle_idempotence'],
        faux.appels.last.$2['p_cle_idempotence'],
      );
    });
  });
}
