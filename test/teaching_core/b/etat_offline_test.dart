import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/cache/media/cache_media.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/catalogue_local.dart';
import 'package:rewayah_academy/core/tc_telechargement/download_asset.dart';
import 'package:rewayah_academy/core/tc_telechargement/port_etat_offline.dart';
import 'package:rewayah_academy/core/tc_telechargement/port_telechargement.dart';

import 'faux/faux_ports_b.dart';

/// Un module d'etat cable sur des doubles.
EtatOfflineCache module({
  required bool possible,
  String? versionId = 'v1',
  Map<String, List<DownloadAsset>> artefacts =
      const <String, List<DownloadAsset>>{},
  Map<String, List<int>> octets = const <String, List<int>>{},
  CacheMedia? depot,
}) {
  final ArtefactsLocaux depotArtefacts = ArtefactsLocaux(
    parVersion: artefacts,
    octetsParCle: octets,
  );
  return EtatOfflineCache(
    depot: depot ?? FauxCacheMedia(),
    telechargement: depotArtefacts,
    lecteur: depotArtefacts,
    resoudre: (String resourceId) async => DescripteurOffline(
      resourceId: resourceId,
      versionId: versionId,
      possible: possible,
    ),
  );
}

void main() {
  group('Etat hors ligne : les cinq etats se distinguent', () {
    test('une ressource qui interdit le hors ligne est indisponible', () async {
      final EtatOfflineCache m = module(possible: false);
      addTearDown(m.fermer);

      expect(await m.etatDe('r1'), EtatOffline.indisponible);
    });

    test('sans octets locaux, la ressource est a telecharger', () async {
      final EtatOfflineCache m = module(possible: true);
      addTearDown(m.fermer);

      expect(await m.etatDe('r1'), EtatOffline.aTelecharger);
    });

    test('des octets presents sans demande valent en cache', () async {
      final FauxCacheMedia depot = FauxCacheMedia();
      await depot.deposer(EtatOfflineCache.cleCache('r1', 'v1'), <int>[
        1,
        2,
        3,
      ]);
      final EtatOfflineCache m = module(possible: true, depot: depot);
      addTearDown(m.fermer);

      // « En cache » et « telecharge » ne disent pas la meme chose : le
      // premier peut etre purge, le second a ete demande.
      expect(await m.etatDe('r1'), EtatOffline.enCache);
    });

    test(
      'une cle porte la version : une version neuve repart de zero',
      () async {
        final FauxCacheMedia depot = FauxCacheMedia();
        await depot.deposer(EtatOfflineCache.cleCache('r1', 'v1'), <int>[
          1,
          2,
          3,
        ]);
        final EtatOfflineCache m = module(
          possible: true,
          versionId: 'v2',
          depot: depot,
        );
        addTearDown(m.fermer);

        expect(await m.etatDe('r1'), EtatOffline.aTelecharger);
      },
    );
  });

  group('Telechargement : un echec est nomme, jamais avale', () {
    test('sans artefact publie, la demande echoue franchement', () async {
      final EtatOfflineCache m = module(possible: true);
      addTearDown(m.fermer);

      await expectLater(
        m.demanderTelechargement('r1'),
        throwsA(isA<EchecTelechargementRessource>()),
      );
      // Et l'etat ne reste pas bloque sur « en cours ».
      expect(await m.etatDe('r1'), EtatOffline.aTelecharger);
    });

    test('un artefact sans octets obtenables echoue aussi', () async {
      final EtatOfflineCache m = module(
        possible: true,
        artefacts: <String, List<DownloadAsset>>{
          'v1': <DownloadAsset>[artefact(id: 'a1', versionId: 'v1')],
        },
      );
      addTearDown(m.fermer);

      await expectLater(
        m.demanderTelechargement('r1'),
        throwsA(isA<EchecTelechargementRessource>()),
      );
      expect(await m.etatDe('r1'), EtatOffline.aTelecharger);
    });

    test(
      'une ressource qui interdit le hors ligne refuse la demande',
      () async {
        final EtatOfflineCache m = module(possible: false);
        addTearDown(m.fermer);

        await expectLater(
          m.demanderTelechargement('r1'),
          throwsA(isA<EchecTelechargementRessource>()),
        );
      },
    );

    test(
      'un telechargement complet mene a telecharge, puis se libere',
      () async {
        final EtatOfflineCache m = module(
          possible: true,
          artefacts: <String, List<DownloadAsset>>{
            'v1': <DownloadAsset>[
              artefact(id: 'a1', versionId: 'v1', cle: 'supports/r1.pdf'),
            ],
          },
          octets: <String, List<int>>{
            'supports/r1.pdf': <int>[37, 80, 68, 70],
          },
        );
        addTearDown(m.fermer);

        await m.demanderTelechargement('r1');
        expect(await m.etatDe('r1'), EtatOffline.telecharge);

        await m.libererCache('r1');
        expect(await m.etatDe('r1'), EtatOffline.aTelecharger);
      },
    );
  });

  group('Flux : l etat courant arrive a l abonnement', () {
    test('le premier evenement est l etat courant', () async {
      final EtatOfflineCache m = module(possible: true);
      addTearDown(m.fermer);

      expect(await m.suivre('r1').first, EtatOffline.aTelecharger);
    });

    test('un telechargement emet en cours puis l etat final', () async {
      final EtatOfflineCache m = module(
        possible: true,
        artefacts: <String, List<DownloadAsset>>{
          'v1': <DownloadAsset>[
            artefact(id: 'a1', versionId: 'v1', cle: 'supports/r1.pdf'),
          ],
        },
        octets: <String, List<int>>{
          'supports/r1.pdf': <int>[1],
        },
      );
      addTearDown(m.fermer);

      final List<EtatOffline> vus = <EtatOffline>[];
      final StreamSubscription<EtatOffline> abonnement = m
          .suivre('r1')
          .listen(vus.add);
      addTearDown(abonnement.cancel);

      // L'abonnement doit avoir atteint le flux du controleur avant la
      // demande : un `StreamController.broadcast` sans auditeur jette ce
      // qu'on lui donne, et le test mesurerait alors sa propre course.
      await pumpEventQueue();
      await m.demanderTelechargement('r1');
      await pumpEventQueue();

      expect(vus, <EtatOffline>[
        EtatOffline.aTelecharger,
        EtatOffline.enCours,
        EtatOffline.telecharge,
      ]);
    });
  });

  group('Artefacts : rien n est genere a la volee', () {
    test('sans stockage, une URL ephemere echoue au lieu de mentir', () async {
      final ArtefactsLocaux depot = ArtefactsLocaux();

      await expectLater(
        depot.urlEphemere(artefact(id: 'a1', versionId: 'v1')),
        throwsA(isA<EchecArtefact>()),
      );
    });

    test('une version sans artefact rend null, pas un PDF fabrique', () async {
      final ArtefactsLocaux depot = ArtefactsLocaux();

      expect(await depot.artefactDe('v1', FormatArtefact.pdf), isNull);
    });
  });
}
