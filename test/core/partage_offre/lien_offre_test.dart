// CAND-06 : le lien de l'offre. Jamais ecrit en dur : la configuration
// (`SITE_URL`), sinon l'origine de la page ouverte sur le web, sinon rien. Le
// lien ne porte aucun parametre.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/config/env.dart';
import 'package:rewayah_academy/core/partage_offre/lien_offre.dart';

void main() {
  group('lienOffre', () {
    test('la configuration donne l\'origine, la page d\'accueil francaise', () {
      final Uri? lien = lienOffre(configure: 'https://exemple.test');
      expect(lien.toString(), 'https://exemple.test$cheminOffre');
      expect(lien!.hasQuery, isFalse);
      expect(lien.hasFragment, isFalse);
    });

    test(
      'une configuration avec chemin, requete ou port : l\'origine seule',
      () {
        expect(
          lienOffre(configure: 'https://exemple.test:8443/x/y?z=1#t')
              .toString(),
          'https://exemple.test:8443$cheminOffre',
        );
        expect(
          lienOffre(configure: '  https://exemple.test/  ').toString(),
          'https://exemple.test$cheminOffre',
        );
      },
    );

    test('sans configuration, sur le web : l\'origine de la page ouverte', () {
      final Uri? lien = lienOffre(
        configure: '',
        base: Uri.parse('https://app.exemple.test/#/attente/partage'),
      );
      expect(lien.toString(), 'https://app.exemple.test$cheminOffre');
    });

    test('la configuration l\'emporte sur la page ouverte', () {
      final Uri? lien = lienOffre(
        configure: 'https://site.test',
        base: Uri.parse('https://app.test/'),
      );
      expect(lien!.host, 'site.test');
    });

    test('hors du web, la page ouverte est un dossier : aucun lien', () {
      expect(
        lienOffre(configure: '', base: Uri.parse('file:///home/user/projet/')),
        isNull,
      );
      expect(lienOffre(configure: ''), isNull);
    });

    test(
      'une configuration invalide est ignoree, comme si elle etait vide',
      () {
        for (final String mauvaise in <String>[
          'ftp://exemple.test',
          'exemple.test',
          'https://',
          '::pas une adresse::',
        ]) {
          expect(lienOffre(configure: mauvaise), isNull, reason: mauvaise);
          expect(
            lienOffre(
              configure: mauvaise,
              base: Uri.parse('https://app.test/'),
            ).toString(),
            'https://app.test$cheminOffre',
            reason: mauvaise,
          );
        }
      },
    );

    test('aucun parametre ne dit qui partage', () {
      final Uri? lien = lienOffre(
        configure: '',
        base: Uri.parse('https://app.test/?u=quelquun#/attente'),
      );
      expect(lien!.query, isEmpty);
      expect(lien.fragment, isEmpty);
      expect(lien.userInfo, isEmpty);
    });
  });

  group('lienLisible', () {
    test('sans le schema, avec le port quand il y en a un', () {
      expect(lienLisible(Uri.parse('https://app.test/fr/')), 'app.test/fr/');
      expect(
        lienLisible(Uri.parse('http://localhost:8080/fr/')),
        'localhost:8080/fr/',
      );
    });
  });

  group('le fournisseur', () {
    test('sans SITE_URL ni page web, sous les tests : aucun lien', () {
      expect(Env.siteUrl, isEmpty);
      final ProviderContainer conteneur = ProviderContainer();
      addTearDown(conteneur.dispose);
      expect(conteneur.read(lienOffreProvider), isNull);
    });
  });
}
