// IMM-ACCUEIL-FRONT : lecture de `reclamer_preinscription_apres_preuve()` et
// controleur de l'accueil des inscrits (un seul appel par compte).

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/import_inscriptions/accueil_inscrits.dart';
import 'package:rewayah_academy/core/import_inscriptions/port_reclamation_preinscription.dart';
import 'package:rewayah_academy/core/import_inscriptions/reclamation_preinscription_supabase.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../router/support_routeur.dart' show SourcePilotee;

const SessionState _sansProfil = SessionState(
  resolue: true,
  profileId: 'u1',
  lectureProfil: LectureProfil.absente,
);

const SessionState _tuteurActif = SessionState(
  resolue: true,
  profileId: 'u1',
  role: AppRole.guardian,
  householdId: 'h1',
  accountStatus: AccountStatus.active,
  lectureProfil: LectureProfil.presente,
);

Map<String, Object?> _connue({Object? accueil, Object? patience}) =>
    <String, Object?>{
      'email_prouve': true,
      'inscription_connue': true,
      'message_accueil': accueil,
      'message_patience': patience,
      'personnes': <Object?>[
        <String, Object?>{
          'id': 'p-tuteur',
          'prenom': 'Mariam',
          'type': 'guardian',
          'etat': 'a_completer',
        },
        <String, Object?>{
          'id': 'p-eleve',
          'prenom': ' Yasmine ',
          'type': 'student',
          'etat': 'a_completer',
        },
      ],
    };

class _PortCompte implements PortReclamationPreinscription {
  _PortCompte(this.reponse);

  Future<ReclamationPreinscription> Function() reponse;
  int appels = 0;

  @override
  bool get disponible => true;

  @override
  Future<ReclamationPreinscription> reclamer() {
    appels++;
    return reponse();
  }
}

void main() {
  group('lireReclamation', () {
    test('adresse non prouvee ou inscription inconnue : parcours habituel', () {
      expect(
        lireReclamation(<String, Object?>{
          'email_prouve': false,
          'inscription_connue': false,
        }).connue,
        isFalse,
      );
      expect(
        lireReclamation(<String, Object?>{
          'email_prouve': true,
          'inscription_connue': false,
        }).connue,
        isFalse,
      );
    });

    test('inscription connue : personnes, eleves et mot de patience '
        "d'abord", () {
      final ReclamationPreinscription r = lireReclamation(
        _connue(accueil: 'Bienvenue', patience: '  Merci de votre patience '),
      );
      expect(r.connue, isTrue);
      expect(r.motAccueil, 'Merci de votre patience');
      expect(r.personnes, hasLength(2));
      expect(r.eleves.single.prenom, 'Yasmine');
      expect(r.eleves.single.nature, NaturePersonneImportee.eleve);
    });

    test('mot deja montre (null) ou vide : aucun mot', () {
      expect(lireReclamation(_connue()).motAccueil, isNull);
      expect(lireReclamation(_connue(accueil: '   ')).motAccueil, isNull);
      expect(lireReclamation(_connue(accueil: 'Salam')).motAccueil, 'Salam');
    });

    test('forme inattendue : echec, jamais une famille inconnue', () {
      expect(() => lireReclamation(null), throwsA(isA<ReclamationEnEchec>()));
      expect(
        () => lireReclamation(<String, Object?>{'email_prouve': true}),
        throwsA(isA<ReclamationEnEchec>()),
      );
      expect(
        () => lireReclamation(<String, Object?>{
          'email_prouve': true,
          'inscription_connue': true,
          'personnes': 'x',
        }),
        throwsA(isA<ReclamationEnEchec>()),
      );
    });
  });

  group('adaptateur', () {
    test(
      'un refus du serveur est un echec, une coupure est hors ligne',
      () async {
        await expectLater(
          ReclamationPreinscriptionSupabase.avecAppel(
            () async => throw const PostgrestException(message: 'refus'),
          ).reclamer(),
          throwsA(isA<ReclamationEnEchec>()),
        );
        await expectLater(
          ReclamationPreinscriptionSupabase.avecAppel(
            () async => throw TimeoutException('delai'),
          ).reclamer(),
          throwsA(isA<ReclamationInjoignable>()),
        );
        final ReclamationPreinscription r =
            await ReclamationPreinscriptionSupabase.avecAppel(
              () async => _connue(accueil: 'Salam'),
            ).reclamer();
        expect(r.connue, isTrue);
      },
    );
  });

  group('controleur', () {
    late SourcePilotee source;
    late _PortCompte port;
    late ProviderContainer conteneur;

    setUp(() {
      source = SourcePilotee(_sansProfil);
      port = _PortCompte(
        () async => lireReclamation(_connue(accueil: 'Salam')),
      );
      conteneur = ProviderContainer(
        overrides: <Override>[
          sourceSessionProvider.overrideWithValue(source),
          portReclamationPreinscriptionProvider.overrideWithValue(port),
        ],
      );
      addTearDown(conteneur.dispose);
      addTearDown(source.fermer);
    });

    Future<void> sessionResolue() async {
      conteneur.listen(sessionProvider, (_, _) {});
      await pumpEventQueue();
      expect(conteneur.read(sessionProvider).porte, PorteAcces.inscription);
    }

    test('une seule reclamation par compte, puis un nouveau jeton', () async {
      await sessionResolue();
      final AccueilInscritsControleur c = conteneur.read(
        accueilInscritsProvider.notifier,
      );
      await c.reclamerSiBesoin();
      await c.reclamerSiBesoin();
      await pumpEventQueue();
      expect(port.appels, 1);
      expect(source.rafraichissements, 1);
      final EtatAccueilInscrits etat = conteneur.read(accueilInscritsProvider);
      expect(etat, isA<AccueilConnu>());
      expect((etat as AccueilConnu).pret, isTrue);
      expect(conteneur.read(accueilInscritsEnAttenteProvider), isTrue);

      c.marquerVu();
      expect(conteneur.read(accueilInscritsEnAttenteProvider), isFalse);
    });

    test(
      'aucune pre-inscription : parcours habituel, aucun jeton redemande',
      () async {
        port.reponse = () async => const ReclamationPreinscription.inconnue();
        await sessionResolue();
        await conteneur
            .read(accueilInscritsProvider.notifier)
            .reclamerSiBesoin();
        expect(
          conteneur.read(accueilInscritsProvider),
          isA<AccueilSansInscription>(),
        );
        expect(source.rafraichissements, 0);
        expect(conteneur.read(accueilInscritsEnAttenteProvider), isFalse);
      },
    );

    test('echec puis nouvel essai ; coupure dite hors ligne', () async {
      port.reponse = () async => throw const ReclamationEnEchec();
      await sessionResolue();
      final AccueilInscritsControleur c = conteneur.read(
        accueilInscritsProvider.notifier,
      );
      await c.reclamerSiBesoin();
      expect(conteneur.read(accueilInscritsProvider), isA<AccueilEnEchec>());

      port.reponse = () async => throw const ReclamationInjoignable();
      await c.reessayer();
      expect(conteneur.read(accueilInscritsProvider), isA<AccueilHorsLigne>());

      port.reponse = () async => lireReclamation(_connue());
      await c.reessayer();
      expect(conteneur.read(accueilInscritsProvider), isA<AccueilConnu>());
      expect(port.appels, 3);
    });

    test('un compte qui a deja un profil ne reclame rien', () async {
      source = SourcePilotee(_tuteurActif);
      conteneur = ProviderContainer(
        overrides: <Override>[
          sourceSessionProvider.overrideWithValue(source),
          portReclamationPreinscriptionProvider.overrideWithValue(port),
        ],
      );
      addTearDown(conteneur.dispose);
      conteneur.listen(sessionProvider, (_, _) {});
      await pumpEventQueue();
      await conteneur.read(accueilInscritsProvider.notifier).reclamerSiBesoin();
      expect(port.appels, 0);
      expect(conteneur.read(accueilInscritsProvider), isA<AccueilNonDemande>());
    });

    test('un autre compte repart de zero', () async {
      await sessionResolue();
      await conteneur.read(accueilInscritsProvider.notifier).reclamerSiBesoin();
      expect(conteneur.read(accueilInscritsProvider), isA<AccueilConnu>());
      source.emettre(
        const SessionState(
          resolue: true,
          profileId: 'u2',
          lectureProfil: LectureProfil.absente,
        ),
      );
      await pumpEventQueue();
      // La porte `inscription` du nouveau compte relance sa propre
      // reclamation ; rien de la famille precedente ne lui reste.
      expect(port.appels, 2);
    });
  });
}
