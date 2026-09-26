import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/config/env.dart';
import 'package:rewayah_academy/core/observabilite/supervision.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Les garanties de la supervision (etape 0.6, onboarding etape F).
///
/// Ces tests tournent sans DSN, comme tout poste de developpement : c'est
/// justement l'un des comportements a tenir.
void main() {
  group('Supervision sans DSN', () {
    test('ne demarre pas quand aucun DSN n\'est injecte', () async {
      expect(Env.supervisionActive, isFalse);
      expect(Env.sentryDsn, isEmpty);

      await Supervision.demarrer();

      expect(Supervision.demarree, isFalse);
    });

    test(
      'l\'erreur volontaire ne part pas quand rien n\'est demarre',
      () async {
        expect(await Supervision.declencherErreurDeTest(), isNull);
      },
    );

    test('l\'environnement par defaut n\'est jamais la production', () {
      expect(Env.environnement, 'developpement');
    });
  });

  group('Nettoyage des evenements', () {
    /// Ce que PostgREST met dans une URL : le filtre, donc l'identifiant.
    const String urlAvecFiltre =
        'https://gggmtelinlpseweouyav.supabase.co/rest/v1/profils'
        '?id=eq.9f1c8e40-1c2b-4a77-9b3a-0d5e6f7a8b90&select=email';

    SentryEvent evenementAvecMiette(Map<String, dynamic>? donnees) {
      return SentryEvent(
        breadcrumbs: <Breadcrumb>[
          Breadcrumb(category: 'http', type: 'http', data: donnees),
        ],
      );
    }

    test('coupe la chaine de requete d\'une URL de miette', () {
      final SentryEvent? nettoye = Supervision.nettoyer(
        evenementAvecMiette(<String, dynamic>{
          'url': urlAvecFiltre,
          'method': 'GET',
        }),
        Hint(),
      );

      final Map<String, dynamic>? donnees = nettoye!.breadcrumbs!.single.data;
      expect(
        donnees!['url'],
        'https://gggmtelinlpseweouyav.supabase.co/rest/v1/profils',
      );
      expect(donnees['url'].toString(), isNot(contains('9f1c8e40')));
      expect(donnees['url'].toString(), isNot(contains('email')));
    });

    test('laisse intact ce qui ne porte pas de chaine de requete', () {
      const String url =
          'https://gggmtelinlpseweouyav.supabase.co/rest/v1/eleves';

      final SentryEvent? nettoye = Supervision.nettoyer(
        evenementAvecMiette(<String, dynamic>{'url': url, 'method': 'POST'}),
        Hint(),
      );

      final Map<String, dynamic>? donnees = nettoye!.breadcrumbs!.single.data;
      expect(donnees!['url'], url);
      expect(donnees['method'], 'POST');
    });

    test('conserve les autres champs de la miette', () {
      final SentryEvent? nettoye = Supervision.nettoyer(
        evenementAvecMiette(<String, dynamic>{
          'url': urlAvecFiltre,
          'status_code': 403,
        }),
        Hint(),
      );

      expect(nettoye!.breadcrumbs!.single.data!['status_code'], 403);
      expect(nettoye.breadcrumbs!.single.category, 'http');
    });

    // AD-11 (22.4, 26 quater) : une URL signee de piece KYC ne part jamais,
    // ni sa cle d'objet (dans le chemin), ni son jeton (dans la requete).
    const String urlSignee =
        'https://gggmtelinlpseweouyav.supabase.co/storage/v1/object/sign/'
        'kyc/9f1c8e40/piece-identite.webp?token=eyJhbGciOiJIUzI1NiJ9.x';

    void sansPiece(String? texte) {
      expect(texte, isNot(contains('9f1c8e40')));
      expect(texte, isNot(contains('piece-identite')));
      expect(texte, isNot(contains('token')));
      expect(texte, isNot(contains('eyJ')));
    }

    test('masque cle d objet et jeton d une URL signee (miette)', () {
      final SentryEvent? nettoye = Supervision.nettoyer(
        SentryEvent(
          breadcrumbs: <Breadcrumb>[
            Breadcrumb(
              category: 'http',
              message: 'GET $urlSignee',
              data: const <String, dynamic>{
                'url': urlSignee,
                'status_code': 403,
              },
            ),
          ],
        ),
        Hint(),
      );
      final Breadcrumb m = nettoye!.breadcrumbs!.single;
      sansPiece(m.data!['url'] as String);
      sansPiece(m.message);
      expect(m.data!['url'], contains('/storage/v1/object/'));
      expect(m.data!['status_code'], 403);
    });

    test('masque une URL signee dans une exception et dans le message', () {
      final SentryEvent? nettoye = Supervision.nettoyer(
        SentryEvent(
          exceptions: const <SentryException>[
            SentryException(
              type: 'NetworkImageLoadException',
              value: 'HTTP request failed, statusCode: 403, $urlSignee',
            ),
          ],
          message: const SentryMessage('Echec de chargement : $urlSignee'),
        ),
        Hint(),
      );
      sansPiece(nettoye!.exceptions!.single.value);
      sansPiece(nettoye.message!.formatted);
      expect(nettoye.exceptions!.single.value, contains('statusCode: 403'));
    });

    test('supporte une miette sans donnees et un evenement sans miette', () {
      expect(
        Supervision.nettoyer(
          evenementAvecMiette(null),
          Hint(),
        )!.breadcrumbs!.single.data,
        isNull,
      );
      expect(
        Supervision.nettoyer(SentryEvent(), Hint())!.breadcrumbs,
        anyOf(isNull, isEmpty),
      );
    });
  });
}
