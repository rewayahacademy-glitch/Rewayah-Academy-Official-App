// CAND-06 : le lien de l'offre. Toujours le site public, jamais l'application
// (directeur, 14/11/2026), dans la langue de la carte ; la configuration
// (`SITE_URL`) choisit l'origine quand elle est valide et n'est pas
// l'application. Le lien ne porte aucun parametre.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/config/env.dart';
import 'package:rewayah_academy/core/partage_offre/lien_offre.dart';
import 'package:rewayah_academy/core/partage_offre/port_partage_offre.dart';

void main() {
  group('cheminOffre', () {
    test('une langue publiee du site : son dossier', () {
      expect(cheminOffre('fr'), '/fr/');
      expect(cheminOffre('ar'), '/ar/');
      expect(cheminOffre('en'), '/en/');
      expect(cheminOffre('es'), '/es/');
      expect(cheminOffre('pt'), '/pt/');
      expect(cheminOffre(' AR '), '/ar/');
    });

    test('une langue que le site n\'a pas : le francais', () {
      expect(cheminOffre('wo'), '/fr/');
      expect(cheminOffre(''), '/fr/');
    });
  });

  group('lienOffre', () {
    test('sans configuration : le site public de production, en francais', () {
      expect(
        lienOffre(configure: '').toString(),
        'https://rewayahacademy.com/fr/',
      );
    });

    test('la langue de celui qui partage choisit le dossier', () {
      expect(
        lienOffre(configure: '', langue: 'ar').toString(),
        'https://rewayahacademy.com/ar/',
      );
      expect(
        lienOffre(configure: '', langue: 'en').toString(),
        'https://rewayahacademy.com/en/',
      );
    });

    test('jamais l\'application, meme configuree', () {
      for (final String app in <String>[
        'https://app.rewayahacademy.com',
        'https://app.rewayahacademy.com/fr/',
        'https://app.exemple.test',
      ]) {
        final Uri lien = lienOffre(configure: app);
        expect(lien.host, 'rewayahacademy.com', reason: app);
        expect(lien.host.startsWith('app.'), isFalse, reason: app);
      }
    });

    test(
      'la configuration valide donne l\'origine, sans chemin ni requete',
      () {
        expect(
          lienOffre(
            configure: 'https://exemple.test:8443/x/y?z=1#t',
            langue: 'pt',
          ).toString(),
          'https://exemple.test:8443/pt/',
        );
        final Uri lien = lienOffre(configure: '  https://exemple.test/  ');
        expect(lien.toString(), 'https://exemple.test/fr/');
        expect(lien.hasQuery, isFalse);
        expect(lien.hasFragment, isFalse);
        expect(lien.userInfo, isEmpty);
      },
    );

    test('une configuration invalide est ignoree : le site de production', () {
      for (final String mauvaise in <String>[
        'ftp://exemple.test',
        'exemple.test',
        'https://',
        '::pas une adresse::',
      ]) {
        expect(
          lienOffre(configure: mauvaise).toString(),
          'https://rewayahacademy.com/fr/',
          reason: mauvaise,
        );
      }
    });
  });

  group('lienOffreDepuis', () {
    test('remplace le chemin de l\'origine par celui de la langue', () {
      expect(
        lienOffreDepuis(Uri.parse('https://rewayah.test/fr/'), 'ar').toString(),
        'https://rewayah.test/ar/',
      );
    });
  });

  group('lienLisible', () {
    test('sans le schema, avec le port quand il y en a un', () {
      expect(
        lienLisible(Uri.parse('https://rewayahacademy.com/ar/')),
        'rewayahacademy.com/ar/',
      );
      expect(
        lienLisible(Uri.parse('http://localhost:8080/fr/')),
        'localhost:8080/fr/',
      );
    });
  });

  group('texteAvecLien', () {
    test('la phrase puis le lien du site public sur sa ligne', () {
      expect(
        texteAvecLien(
          'Avec le même enseignant.',
          Uri.parse('https://rewayahacademy.com/fr/'),
        ),
        'Avec le même enseignant.\nhttps://rewayahacademy.com/fr/',
      );
    });
  });

  group('le fournisseur', () {
    test('sans SITE_URL : l\'origine du site public de production', () {
      expect(Env.siteUrl, isEmpty);
      final ProviderContainer conteneur = ProviderContainer();
      addTearDown(conteneur.dispose);
      expect(conteneur.read(lienOffreProvider).toString(), sitePublicParDefaut);
    });
  });
}
