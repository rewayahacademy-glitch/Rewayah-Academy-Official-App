import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/cle_audio.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';

void main() {
  group('Texte et audio partagent une seule cle', () {
    test('chaque cle audio declaree existe bien en texte', () {
      for (final CleAudio cle in ClesAudio.toutes) {
        final String texte = t.parCle(cle);
        expect(
          texte,
          isNotEmpty,
          reason:
              'La cle ${cle.chemin} n a pas de texte. Un libelle audio sans '
              'texte laisse un lecteur d ecran muet.',
        );
      }
    });

    test(
      'le chemin du fichier son se derive de la cle, pas d une constante',
      () {
        expect(
          ClesAudio.eleveAccueilRejoindre.fichierPour('fr'),
          'assets/audio/fr/eleve.accueil.rejoindre.mp3',
        );
        expect(
          ClesAudio.eleveAccueilRejoindre.fichierPour('ar'),
          'assets/audio/ar/eleve.accueil.rejoindre.mp3',
        );
      },
    );

    test('les cles suivent la convention en points', () {
      for (final CleAudio cle in ClesAudio.toutes) {
        expect(
          cle.chemin,
          matches(RegExp(r'^[a-z][a-zA-Z0-9]*(\.[a-z][a-zA-Z0-9]*)+$')),
          reason:
              '${cle.chemin} ne suit pas la convention role.ecran.element '
              '(etape-2-core-flutter.md section 5).',
        );
      }
    });
  });

  group('Langues declarees', () {
    test('le francais est la langue de base', () {
      expect(AppLocaleUtils.instance.baseLocale, AppLocale.fr);
    });

    test('l arabe est declare, le poular ne l est pas', () {
      final List<String> codes = AppLocale.values
          .map((AppLocale l) => l.languageCode)
          .toList();
      expect(codes, contains('fr'));
      expect(codes, contains('ar'));
      // Decision de l operateur : pas de poular dans l application, malgre ce
      // que disaient les specs d origine. Voir ADR-015.
      expect(codes, isNot(contains('ff')));
      expect(codes, isNot(contains('fuf')));
    });

    test('l arabe se construit, complet, sans repli sur le francais', () async {
      // fallback_strategy: base_locale dans slang.yaml. La construction est
      // asynchrone parce que slang charge les langues non basiques en
      // differe : sur le Web, l arabe est un morceau separe qui ne pese pas
      // sur le demarrage a froid.
      final Traductions ar = await AppLocale.ar.build();
      // fallback_strategy: base_locale reste pose ; depuis AR-COMPLET-1,
      // aucune cle ne s en sert (test/i18n/ar_domaines_test.dart).
      expect(ar.admin.tableau.titre, isNot(t.admin.tableau.titre));
      expect(ar.salle.bandeauPermanent, isNot(t.salle.bandeauPermanent));
    });
  });

  group('Regles de copywriting', () {
    test('aucun libelle ne contient d emoji ni de M-dash', () {
      final RegExp emoji = RegExp(
        '[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{FE0F}]',
        unicode: true,
      );

      for (final CleAudio cle in ClesAudio.toutes) {
        final String texte = t.parCle(cle);
        expect(emoji.hasMatch(texte), isFalse, reason: cle.chemin);
        expect(texte.contains('—'), isFalse, reason: cle.chemin);
      }
      expect(t.salle.bandeauPermanent.contains('—'), isFalse);
      expect(t.reseau.horsLigne.contains('—'), isFalse);
    });
  });
}
