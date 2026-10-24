// Q-11 : l abstraction de telechargement PDF ne regenere pas le PDF a chaque
// appel.
//
// CONTRACTS section 5 invariant 3 (« `downloadAssetId` est renseigne une
// seule fois, a la publication ») et section 6 invariants 1 et 4 (« genere
// une seule fois puis reutilise », « l enregistrement passe toujours par le
// selecteur systeme, jamais un chemin /sdcard bricole »).
//
// POURQUOI UN COMPTEUR ET PAS UNE INSPECTION. « Ne pas regenerer » n est pas
// un etat observable : c est un nombre d appels. Le double compte donc les
// generations, les lectures et les signatures d URL separement -- trois
// nombres qui ne doivent pas evoluer ensemble.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/resource_version.dart';
import 'package:rewayah_academy/core/tc_telechargement/download_asset.dart';

import '../fixtures/fixtures_ressources.dart';
import 'faux/faux_telechargement.dart';

final DateTime _maintenant = DateTime.utc(2026, 9, 1, 8);

void main() {
  late FauxDepotTelechargement depot;

  setUp(() {
    depot = FauxDepotTelechargement(horlogeUtc: _maintenant);
  });

  group('Q-11 : un PDF se genere une fois, a la publication', () {
    test('cinquante lectures ne provoquent aucune seconde generation', () {
      final DownloadAsset publie = depot.publier(
        resourceVersionId: 'ver-pdf-2',
        cleStockage: 'supports/res-pdf/ver-pdf-2.pdf',
        tailleOctets: 1_482_112,
        empreinte: versionPdfPubliee.empreinte,
      );
      expect(depot.generations, 1);

      for (int i = 0; i < 50; i++) {
        final DownloadAsset? relu = depot.artefactDe(
          'ver-pdf-2',
          FormatArtefact.pdf,
        );
        expect(relu, isNotNull);
        expect(relu!.id, publie.id);
        expect(relu.cleStockage, publie.cleStockage);
        expect(relu.empreinte, publie.empreinte);
      }

      expect(depot.lectures, 50);
      expect(
        depot.generations,
        1,
        reason: 'une seule generation, a la publication, quoi qu il arrive',
      );
    });

    test('un PDF importe n est JAMAIS genere', () {
      depot.importer(artefactPdfImporte);

      for (int i = 0; i < 10; i++) {
        depot.artefactDe('ver-texte-1', FormatArtefact.pdf);
      }

      expect(depot.generations, 0);
      expect(
        depot.artefactDe('ver-texte-1', FormatArtefact.pdf)?.origine,
        OrigineArtefact.importeTelQuel,
      );
    });

    test('un format absent rend null, il ne declenche pas une generation', () {
      depot.publier(
        resourceVersionId: 'ver-pdf-2',
        cleStockage: 'supports/res-pdf/ver-pdf-2.pdf',
        tailleOctets: 10,
      );
      expect(depot.artefactDe('ver-pdf-2', FormatArtefact.epub), isNull);
      expect(depot.artefactDe('ver-inconnue', FormatArtefact.pdf), isNull);
      expect(depot.generations, 1);
    });
  });

  group('Q-11 : on persiste la CLE, jamais l URL signee', () {
    test(
      'chaque URL est differente, la cle ne bouge pas, rien ne regenere',
      () {
        final DownloadAsset asset = depot.publier(
          resourceVersionId: 'ver-pdf-2',
          cleStockage: 'supports/res-pdf/ver-pdf-2.pdf',
          tailleOctets: 1_482_112,
        );

        final List<Uri> urls = <Uri>[
          for (int i = 0; i < 5; i++) depot.urlEphemere(asset),
        ];

        expect(urls.toSet(), hasLength(5), reason: 'une URL signee est unique');
        expect(depot.signatures, 5);
        expect(depot.generations, 1);
        // La cle, elle, n a pas bouge d un caractere.
        expect(asset.cleStockage, 'supports/res-pdf/ver-pdf-2.pdf');
        for (final Uri u in urls) {
          expect(u.path.contains(asset.cleStockage), isTrue);
        }
      },
    );

    test('aucune cle d artefact des fixtures ne ressemble a une URL', () {
      for (final DownloadAsset a in <DownloadAsset>[
        artefactPdfGenere,
        artefactPdfImporte,
      ]) {
        expect(a.cleStockage.startsWith('http'), isFalse);
        expect(a.cleStockage.contains('://'), isFalse);
        expect(a.cleStockage.contains('?'), isFalse);
        expect(a.cleStockage.contains('signature'), isFalse);
      }
    });

    test('la version publiee pointe l artefact par identifiant, une fois', () {
      expect(versionPdfPubliee.statut, StatutVersionRessource.publiee);
      expect(versionPdfPubliee.downloadAssetId, 'asset-pdf-2');
      expect(artefactPdfGenere.resourceVersionId, versionPdfPubliee.id);
      // Un brouillon n a ni artefact ni empreinte : c est normal, pas un
      // manque a combler par une generation opportuniste.
      expect(versionPdfBrouillon.statut, StatutVersionRessource.brouillon);
      expect(versionPdfBrouillon.downloadAssetId, isNull);
      expect(versionPdfBrouillon.empreinte, isNull);
    });
  });

  group('Q-11 : enregistrer une copie passe par le selecteur systeme', () {
    test(
      'le chemin rendu vient de l usager, jamais d un /sdcard bricole',
      () async {
        final FauxEnregistrementFichier selecteur = FauxEnregistrementFichier();

        final String? chemin = await selecteur.enregistrerCopie(
          octets: const <int>[37, 80, 68, 70],
          nomFichierPropose: 'ajurrumiyya-v2.pdf',
          typeMime: 'application/pdf',
        );

        expect(selecteur.ouverturesSelecteur, 1);
        expect(chemin, isNotNull);
        expect(chemin!.contains('/sdcard'), isFalse);
        expect(chemin.contains('Download'), isFalse);
        expect(selecteur.propositions.single, 'ajurrumiyya-v2.pdf');
      },
    );

    test('une annulation rend null, et ce n est pas une erreur', () async {
      final FauxEnregistrementFichier selecteur = FauxEnregistrementFichier(
        annuleParUsager: true,
      );

      expect(
        await selecteur.enregistrerCopie(
          octets: const <int>[37, 80],
          nomFichierPropose: 'ajurrumiyya-v2.pdf',
          typeMime: 'application/pdf',
        ),
        isNull,
      );
      expect(selecteur.ouverturesSelecteur, 1);
    });

    test('telecharger cinq fois de suite ne regenere toujours rien', () async {
      final FauxEnregistrementFichier selecteur = FauxEnregistrementFichier();
      final DownloadAsset asset = depot.publier(
        resourceVersionId: 'ver-pdf-2',
        cleStockage: 'supports/res-pdf/ver-pdf-2.pdf',
        tailleOctets: 4,
      );

      for (int i = 0; i < 5; i++) {
        final DownloadAsset? a = depot.artefactDe(
          'ver-pdf-2',
          FormatArtefact.pdf,
        );
        depot.urlEphemere(a!);
        await selecteur.enregistrerCopie(
          octets: const <int>[37, 80, 68, 70],
          nomFichierPropose: 'ajurrumiyya-v2.pdf',
          typeMime: 'application/pdf',
        );
      }

      expect(selecteur.ouverturesSelecteur, 5);
      expect(depot.signatures, 5);
      expect(depot.generations, 1);
      expect(asset.origine, OrigineArtefact.genereALaPublication);
    });
  });
}
