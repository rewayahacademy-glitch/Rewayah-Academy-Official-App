import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/agent/amorce_agent.dart';
import 'package:rewayah_academy/core/agent/session_agent.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/router/redirection.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/claims_jwt.dart';
import 'package:rewayah_academy/core/session/session_state.dart';

/// Ce que la fonction Edge rend, pour un jeton valable [secondes] secondes.
Map<String, dynamic> _remise({
  int secondes = 900,
  bool masquee = true,
  String parcours = 'student',
}) => <String, dynamic>{
  'access_token': 'a.b.c',
  'expires_at':
      DateTime.now().toUtc().add(Duration(seconds: secondes)).millisecondsSinceEpoch ~/
      1000,
  'parcours': parcours,
  'identite_masquee': masquee,
  'jeton_expire_le': DateTime.now().toUtc().add(const Duration(hours: 8))
      .toIso8601String(),
};

SessionState _sessionActive({
  AppRole role = AppRole.student,
  Observation? observation,
}) => SessionState(
  resolue: true,
  profileId: 'p1',
  householdId: 'h1',
  role: role,
  accountStatus: AccountStatus.active,
  lectureProfil: LectureProfil.presente,
  observation: observation,
);

void main() {
  final DateTime maintenant = DateTime.utc(2026, 9, 18, 10);

  group('Le jeton ne vit que dans l adresse', () {
    test('un jeton bien forme se lit', () {
      expect(
        jetonAgentDeLUrl(Uri.parse('https://x.test/agent?jeton=rag_abc123')),
        'rag_abc123',
      );
    });

    test('un parametre qui n est pas un jeton est ignore', () {
      // Sans ce filtre, n'importe quel parametre d'URL partirait a la fonction
      // Edge et compterait comme une tentative sur un jeton.
      for (final String adresse in <String>[
        'https://x.test/agent',
        'https://x.test/agent?jeton=',
        'https://x.test/agent?jeton=bonjour',
        'https://x.test/agent?autre=rag_abc',
      ]) {
        expect(
          jetonAgentDeLUrl(Uri.parse(adresse)),
          isNull,
          reason: adresse,
        );
      }
    });
  });

  group('Le porteur de session', () {
    test('n echange qu une fois tant que le jeton signe est frais', () async {
      int appels = 0;
      final PorteurSessionAgent porteur = PorteurSessionAgent(
        jeton: 'rag_x',
        url: 'https://x.test',
        cleAnon: 'anon',
        echangeur: (String _) async {
          appels++;
          return _remise();
        },
      );

      await porteur.ouvrir();
      await porteur.jetonFrais();
      await porteur.jetonFrais();

      expect(appels, 1, reason: 'chaque lecture ne doit pas rouvrir de session');
    });

    test('redemande un jeton avant l expiration, pas apres', () async {
      // La marge est d'une minute : un jeton qui expire dans 30 secondes est
      // deja considere comme mort, sinon une requete partie a l'instant precis
      // de l'expiration reviendrait en 401.
      int appels = 0;
      final PorteurSessionAgent porteur = PorteurSessionAgent(
        jeton: 'rag_x',
        url: 'https://x.test',
        cleAnon: 'anon',
        echangeur: (String _) async {
          appels++;
          return _remise(secondes: 30);
        },
      );

      await porteur.ouvrir();
      await porteur.jetonFrais();

      expect(appels, 2, reason: 'un jeton en fin de vie doit etre renouvele');
    });

    test('une seule remise en vol, meme sur dix demandes simultanees', () async {
      // Au demarrage, plusieurs ecrans demandent leurs donnees en meme temps :
      // autant d'echanges paralleles feraient autant d'ouvertures de session
      // pour une seule entree.
      int appels = 0;
      final PorteurSessionAgent porteur = PorteurSessionAgent(
        jeton: 'rag_x',
        url: 'https://x.test',
        cleAnon: 'anon',
        echangeur: (String _) async {
          appels++;
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return _remise();
        },
      );

      await Future.wait<String?>(
        List<Future<String?>>.generate(10, (int _) => porteur.jetonFrais()),
      );

      expect(appels, 1);
    });

    test('un refus de la base remonte comme un refus, pas comme une panne', () async {
      final PorteurSessionAgent porteur = PorteurSessionAgent(
        jeton: 'rag_x',
        url: 'https://x.test',
        cleAnon: 'anon',
        echangeur: (String _) async =>
            throw const ErreurAgent(EchecAgent.jetonRefuse),
      );

      await expectLater(
        porteur.ouvrir(),
        throwsA(
          isA<ErreurAgent>().having(
            (ErreurAgent e) => e.cause,
            'cause',
            EchecAgent.jetonRefuse,
          ),
        ),
      );
    });

    test('une reponse sans jeton est illisible, pas valide', () async {
      final PorteurSessionAgent porteur = PorteurSessionAgent(
        jeton: 'rag_x',
        url: 'https://x.test',
        cleAnon: 'anon',
        echangeur: (String _) async => <String, dynamic>{'parcours': 'student'},
      );

      await expectLater(
        porteur.ouvrir(),
        throwsA(
          isA<ErreurAgent>().having(
            (ErreurAgent e) => e.cause,
            'cause',
            EchecAgent.reponseIllisible,
          ),
        ),
      );
    });

    test('le passe-vole rend null au lieu de lever', () async {
      // Une erreur levee ici traverserait chaque requete du client Supabase.
      final PorteurSessionAgent porteur = PorteurSessionAgent(
        jeton: 'rag_x',
        url: 'https://x.test',
        cleAnon: 'anon',
        echangeur: (String _) async =>
            throw const ErreurAgent(EchecAgent.jetonRefuse),
      );

      expect(await porteur.jetonFrais(), isNull);
    });
  });

  group('Le sujet du jeton est la personne observee', () {
    test('ClaimsJwt lit le sub a cote du role et du foyer', () {
      // {"sub":"p-42","app_metadata":{"role":"teacher","household_id":"h-7"}}
      const String charge =
          'eyJzdWIiOiJwLTQyIiwiYXBwX21ldGFkYXRhIjp7InJvbGUiOiJ0ZWFjaGVyIiwi'
          'aG91c2Vob2xkX2lkIjoiaC03In19';
      final ClaimsJwt claims = ClaimsJwt.depuisJeton('en.$charge.sig');

      expect(claims.sujet, 'p-42');
      expect(claims.role, 'teacher');
      expect(claims.householdId, 'h-7');
    });

    test('un jeton illisible n accorde rien', () {
      expect(ClaimsJwt.depuisJeton('nimporte quoi').sujet, isNull);
      expect(ClaimsJwt.depuisJeton(null).sujet, isNull);
    });
  });

  group('La capacite d ecrire', () {
    test('une session humaine peut ecrire', () {
      expect(_sessionActive().peutEcrire, isTrue);
    });

    test('une session d observation ne le peut pas', () {
      // Ce booleen ne borne rien : la lecture seule vient des privileges du
      // role Postgres `agent_ro`. Il sert a le DIRE a l'ecran, parce qu'un
      // bouton qui echouera est une promesse non tenue.
      final SessionState session = _sessionActive(
        observation: const Observation(identiteMasquee: true),
      );
      expect(session.peutEcrire, isFalse);
    });

    test('l observation entre dans l egalite de l etat', () {
      expect(
        _sessionActive(observation: const Observation(identiteMasquee: true)),
        isNot(
          _sessionActive(observation: const Observation(identiteMasquee: false)),
        ),
      );
    });
  });

  group('La porte d entree de l agent', () {
    test('est atteignable sans session', () {
      // Sans cette regle, un agent qui clique sur son lien serait renvoye sur
      // l'ecran de connexion humaine, et le jeton serait perdu avec l'URL.
      expect(
        deciderRedirection(
          session: const SessionState.deconnecte(),
          cheminDemande: Routes.agentEntree,
          maintenant: maintenant,
        ),
        isNull,
      );
    });

    test('une session resolue la quitte, comme on quitte la connexion', () {
      expect(
        deciderRedirection(
          session: _sessionActive(
            observation: const Observation(identiteMasquee: true),
          ),
          cheminDemande: Routes.agentEntree,
          maintenant: maintenant,
        ),
        Routes.eleve,
      );
    });

    test('elle n ouvre aucune autre route a un visiteur sans session', () {
      // La porte publique ne doit pas devenir un sous-arbre public.
      for (final String route in <String>[
        Routes.adminSecuriteAuditAccesAgents,
        Routes.admin,
        Routes.eleve,
        Routes.tuteurAccueil,
      ]) {
        // Vers la connexion humaine, la destination gardee en `retour`
        // (chemin interne valide, jamais un jeton).
        final String? decision = deciderRedirection(
          session: const SessionState.deconnecte(),
          cheminDemande: route,
          maintenant: maintenant,
        );
        expect(Uri.parse(decision!).path, Routes.connexion, reason: route);
      }
    });

    test('l ecran d emission reste dans l espace d administration', () {
      // Il est sous `/admin`, donc borne par le prefixe de role comme les
      // autres : un enseignant qui taperait l'adresse rentre chez lui.
      expect(
        deciderRedirection(
          session: _sessionActive(role: AppRole.teacher),
          cheminDemande: Routes.adminSecuriteAuditAccesAgents,
          maintenant: maintenant,
        ),
        Routes.enseignantJournee,
      );
      expect(
        deciderRedirection(
          session: _sessionActive(role: AppRole.admin),
          cheminDemande: Routes.adminSecuriteAuditAccesAgents,
          maintenant: maintenant,
        ),
        isNull,
      );
    });
  });

  group('Le lien remis a l agent', () {
    test('porte le jeton, et se relit', () {
      const String secret = 'rag_0123456789abcdef';
      final String lien = Routes.entreePour(secret);

      expect(lien, startsWith(Routes.agentEntree));
      expect(jetonAgentDeLUrl(Uri.parse('https://x.test$lien')), secret);
    });
  });
}
