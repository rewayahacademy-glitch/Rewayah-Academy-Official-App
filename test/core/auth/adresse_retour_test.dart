// POSTULER-ICI (16/11/2026) : la marque du candidat voyage dans l'adresse de
// retour du lien de connexion, et la reprise la relit meme quand la memoire de
// l'appareil est vide (lien ouvert dans un autre navigateur).

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/auth/adresse_retour.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/inscription/invitation_en_cours.dart';

const String _origine = 'https://app.exemple';

void main() {
  setUp(oublierInvitationEnCours);
  tearDown(oublierInvitationEnCours);

  group('adresseRetourConnexion', () {
    test('hors du web : rien', () {
      expect(
        adresseRetourConnexion(
          courante: Uri.parse('$_origine/#/connexion?candidature=1'),
          origine: null,
        ),
        isNull,
      );
    });

    test("sans marque : l'origine seule, comme avant", () {
      expect(
        adresseRetourConnexion(
          courante: Uri.parse('$_origine/#/connexion?mode=creer'),
          origine: _origine,
        ),
        _origine,
      );
    });

    test('lien du candidat (fragment) : candidature=1 voyage', () {
      final String? a = adresseRetourConnexion(
        courante: Uri.parse('$_origine/#/connexion?mode=creer&candidature=1'),
        origine: _origine,
      );
      expect(Uri.parse(a!).queryParameters, <String, String>{
        'candidature': '1',
      });
      expect(a, startsWith('$_origine/?'));
    });

    test('le code du lien du candidat ne voyage pas', () {
      final String? a = adresseRetourConnexion(
        courante: Uri.parse(
          '$_origine/#/connexion?mode=creer&candidature=1&code=ABCD-EFGH-JKMN',
        ),
        origine: _origine,
      );
      expect(Uri.parse(a!).queryParameters, <String, String>{
        'candidature': '1',
      });
    });

    test("invitation d'enseignant : le code voyage sous code_invitation", () {
      final String? a = adresseRetourConnexion(
        courante: Uri.parse(
          '$_origine/#/connexion?mode=creer&invitation=1&code=ABCD-EFGH-JKMN',
        ),
        origine: _origine,
      );
      final Map<String, String> p = Uri.parse(a!).queryParameters;
      expect(p['invitation'], '1');
      expect(p[parametreCodeInvitationRetour], 'ABCD-EFGH-JKMN');
      // Jamais sous `code` : le flux de connexion y met le sien.
      expect(p.containsKey('code'), isFalse);
    });

    test("un code illisible ne voyage pas ; rien d'autre ne voyage", () {
      final String? a = adresseRetourConnexion(
        courante: Uri.parse(
          '$_origine/#/connexion?invitation=1&code=%3Cscript%3E&email=a%40b.c',
        ),
        origine: _origine,
      );
      final Map<String, String> p = Uri.parse(a!).queryParameters;
      expect(p, <String, String>{'invitation': '1'});
    });
  });

  group("au retour, memoire de l'appareil vide", () {
    test("candidature=1 dans l'adresse : le parcours candidat reprend", () {
      expect(lireInvitationEnCours(), isNull);
      retenirInvitationDepuisAdresse(Uri.parse('$_origine/?candidature=1'));
      expect(lireInvitationEnCours()?.candidature, isTrue);
      expect(
        lireInvitationEnCours()?.route,
        '${Routes.inscriptionInvitation}?candidature=1',
      );
    });

    test("invitation d'enseignant : le code revient et ouvre l'ecran", () {
      retenirInvitationDepuisAdresse(
        Uri.parse('$_origine/?invitation=1&code_invitation=ABCD-EFGH-JKMN'),
      );
      expect(lireInvitationEnCours()?.code, 'ABCD-EFGH-JKMN');
    });

    test("le code du flux de connexion (36 signes) n'est jamais retenu", () {
      retenirInvitationDepuisAdresse(
        Uri.parse(
          '$_origine/?invitation=1&code=0b6f7a3e-9c1d-4b8a-8f2e-5d1c3a9e7b42',
        ),
      );
      expect(lireInvitationEnCours()?.code, isNull);
    });

    test('un retour sans marque ne pose rien', () {
      retenirInvitationDepuisAdresse(Uri.parse('$_origine/?code=abc'));
      expect(lireInvitationEnCours(), isNull);
    });
  });
}
