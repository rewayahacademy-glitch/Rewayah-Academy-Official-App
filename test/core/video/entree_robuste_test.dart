import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:rewayah_academy/core/video/livekit_session_provider.dart';
import 'package:rewayah_academy/core/video/service_video.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';

/// Un essai d'entree joue sans reseau : les attentes demandees, les essais
/// faits, les echecs signales.
class _Essais {
  _Essais(this.erreurs);

  /// L'erreur de chaque essai, dans l'ordre ; au-dela, l'essai reussit.
  final List<Object> erreurs;

  final List<Duration> attentes = <Duration>[];
  final List<({int essai, NatureEchecEntree nature, bool definitif})> signales =
      <({int essai, NatureEchecEntree nature, bool definitif})>[];
  int faits = 0;
  bool quitte = false;

  /// Appele pendant l'attente du numero donne (0 = avant le 2e essai).
  void Function(int)? pendantAttente;

  Future<void> lancer() => essayerEntree(
    essayer: (int essai) async {
      faits++;
      if (essai < erreurs.length) {
        // ignore: only_throw_errors
        throw erreurs[essai];
      }
    },
    interrompue: () => quitte,
    attendre: (Duration d) async {
      attentes.add(d);
      pendantAttente?.call(attentes.length - 1);
    },
    signaler: (
      int essai,
      NatureEchecEntree nature,
      Object _, {
      required bool definitif,
    }) => signales.add((essai: essai, nature: nature, definitif: definitif)),
  );
}

/// ENTREE-ROBUSTE (directeur, 12/11/2026, point 11 : « l'eleve suivant a du
/// mal a rejoindre ») : la logique des essais de la premiere entree.
void main() {
  group('nature d un echec d entree', () {
    test('un jeton refuse par LiveKit (401, 403) est un refus', () {
      for (final int statut in <int>[401, 403]) {
        expect(
          natureEchecEntree(
            lk.ConnectException(
              'refuse',
              reason: lk.ConnectionErrorReason.NotAllowed,
              statusCode: statut,
            ),
          ),
          NatureEchecEntree.refus,
        );
      }
    });

    test('un refus du serveur de l application est un refus', () {
      expect(
        natureEchecEntree(const EchecSalle(MotifRefusSalle.acces)),
        NatureEchecEntree.refus,
      );
    });

    test('un delai depasse se distingue d une coupure et d un refus', () {
      expect(
        natureEchecEntree(
          const EchecSalle(MotifRefusSalle.reseau, delaiDepasse: true),
        ),
        NatureEchecEntree.delai,
      );
      expect(
        natureEchecEntree(
          lk.ConnectException('lent', reason: lk.ConnectionErrorReason.Timeout),
        ),
        NatureEchecEntree.delai,
      );
      expect(
        natureEchecEntree(TimeoutException('lent')),
        NatureEchecEntree.delai,
      );
      expect(
        natureEchecEntree(const EchecSalle(MotifRefusSalle.reseau)),
        NatureEchecEntree.transport,
      );
    });

    test('une panne du serveur LiveKit (503) ou ICE est une coupure', () {
      expect(
        natureEchecEntree(
          lk.ConnectException(
            'indisponible',
            reason: lk.ConnectionErrorReason.InternalError,
            statusCode: 503,
          ),
        ),
        NatureEchecEntree.transport,
      );
      expect(
        natureEchecEntree(lk.MediaConnectException()),
        NatureEchecEntree.transport,
      );
      expect(natureEchecEntree(StateError('x')), NatureEchecEntree.transport);
    });

    test('le statut HTTP accompagne la supervision, jamais un faux zero', () {
      expect(
        statutEchecEntree(
          lk.ConnectException(
            'refuse',
            reason: lk.ConnectionErrorReason.NotAllowed,
            statusCode: 401,
          ),
        ),
        401,
      );
      expect(
        statutEchecEntree(
          lk.ConnectException('x', reason: lk.ConnectionErrorReason.Timeout),
        ),
        isNull,
      );
    });
  });

  group('essais de la premiere entree', () {
    test('trois essais au plus, aux delais de la reprise (0, 2 s, 4 s)', () {
      expect(essaisEntree, 3);
      expect(delaisRepriseSansGeste.take(essaisEntree), <Duration>[
        Duration.zero,
        const Duration(seconds: 2),
        const Duration(seconds: 4),
      ]);
    });

    test('(a) un echec puis la connexion : entre sans geste', () async {
      final _Essais e = _Essais(<Object>[StateError('coupure')]);
      await e.lancer();
      expect(e.faits, 2);
      expect(e.attentes, <Duration>[const Duration(seconds: 2)]);
      expect(
        e.signales,
        <({int essai, NatureEchecEntree nature, bool definitif})>[
          (essai: 1, nature: NatureEchecEntree.transport, definitif: false),
        ],
      );
    });

    test('(b) trois coupures : la derniere erreur remonte, signalee '
        'definitive', () async {
      final StateError derniere = StateError('troisieme');
      final _Essais e = _Essais(<Object>[
        StateError('premiere'),
        const EchecSalle(MotifRefusSalle.reseau, delaiDepasse: true),
        derniere,
      ]);
      await expectLater(e.lancer(), throwsA(same(derniere)));
      expect(e.faits, 3);
      expect(e.attentes, <Duration>[
        const Duration(seconds: 2),
        const Duration(seconds: 4),
      ]);
      expect(
        e.signales,
        <({int essai, NatureEchecEntree nature, bool definitif})>[
          (essai: 1, nature: NatureEchecEntree.transport, definitif: false),
          (essai: 2, nature: NatureEchecEntree.delai, definitif: false),
          (essai: 3, nature: NatureEchecEntree.transport, definitif: true),
        ],
      );
    });

    test('(c) un refus du serveur : aucun essai de plus', () async {
      final lk.ConnectException refus = lk.ConnectException(
        'jeton refuse',
        reason: lk.ConnectionErrorReason.NotAllowed,
        statusCode: 401,
      );
      final _Essais e = _Essais(<Object>[refus]);
      await expectLater(e.lancer(), throwsA(same(refus)));
      expect(e.faits, 1);
      expect(e.attentes, isEmpty);
      expect(
        e.signales,
        <({int essai, NatureEchecEntree nature, bool definitif})>[
          (essai: 1, nature: NatureEchecEntree.refus, definitif: true),
        ],
      );
    });

    test('(c) un refus apres une coupure arrete aussi tout', () async {
      final _Essais e = _Essais(<Object>[
        StateError('coupure'),
        const EchecSalle(MotifRefusSalle.acces),
      ]);
      await expectLater(e.lancer(), throwsA(isA<EchecSalle>()));
      expect(e.faits, 2);
      expect(e.signales.last.definitif, isTrue);
    });

    // Directeur, 12/11/2026 au soir : le meme compte deja dans la salle sur
    // un autre appareil. Jamais un essai seul apres lui.
    test('le meme compte ouvert ailleurs : aucun essai de plus', () async {
      final _Essais e = _Essais(<Object>[const EntreeOuverteAilleurs()]);
      await expectLater(e.lancer(), throwsA(isA<EntreeOuverteAilleurs>()));
      expect(e.faits, 1);
      expect(e.attentes, isEmpty);
      expect(e.signales.single.nature, NatureEchecEntree.ouverteAilleurs);
      expect(e.signales.single.definitif, isTrue);
    });

    test('la reprise sans geste ne suit jamais un meme compte ouvert '
        'ailleurs, et la salle le dit', () {
      expect(
        repriseSansGestePermise(lk.DisconnectReason.duplicateIdentity),
        isFalse,
      );
      expect(
        LiveKitSessionProvider.issueDeconnexion(
          lk.DisconnectReason.duplicateIdentity,
        ),
        (etat: EtatSalle.echec, ailleurs: true),
      );
    });

    test('(d) quitter pendant l attente : aucun essai apres', () async {
      final _Essais e = _Essais(<Object>[StateError('coupure')]);
      e.pendantAttente = (int _) => e.quitte = true;
      await expectLater(e.lancer(), throwsA(isA<EntreeInterrompue>()));
      expect(e.faits, 1);
    });

    test('(d) quitter pendant un essai : ni signal definitif, ni essai de '
        'plus', () async {
      final _Essais e = _Essais(<Object>[]);
      final Future<void> lance = essayerEntree(
        essayer: (int _) async {
          e.faits++;
          e.quitte = true;
          throw StateError('salle fermee par la sortie');
        },
        interrompue: () => e.quitte,
        attendre: (Duration _) async => fail('aucune attente apres la sortie'),
        signaler: (
          int _,
          NatureEchecEntree _,
          Object _, {
          required bool definitif,
        }) => fail('une sortie n est pas un echec a signaler'),
      );
      await expectLater(lance, throwsA(isA<EntreeInterrompue>()));
      expect(e.faits, 1);
    });
  });
}
