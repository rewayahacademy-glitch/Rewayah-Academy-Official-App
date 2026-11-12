// EDIT-INFOS-PERSO (garde-cap, 12/11/2026) : le directeur ne trouvait pas
// comment changer ses informations personnelles (enseignant, eleve adulte).
// La page Informations (commune au tuteur, a l'eleve adulte autonome, que
// `/compte` mene au Compte du tuteur, et a l'enseignant) propose « Modifier
// mes informations » a qui peut changer ses noms (capacite servie, jamais un
// eleve mineur) ; les noms
// s'affichent tout de suite, reviennent comme avant si le serveur refuse ;
// aucun message de succes ; hors ligne, l'action est absente.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_identite_titulaire.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/photos/photo_personne.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/compte/compte_tuteur_page.dart';
import 'package:rewayah_academy/features/compte/informations_page.dart';
import 'package:rewayah_academy/features/compte/lignes_compte.dart';

import '../../capture/outil_capture.dart';
import '../../router/support_routeur.dart';
import 'support_compte.dart';

/// Une identite dont l'ecriture attend le test : il decide de l'issue.
class _IdentiteModifiable implements PortIdentiteTitulaire {
  String prenom = 'Titulaire';
  String nom = 'Foyer A';
  final List<({String? prenom, String? nom})> ecritures =
      <({String? prenom, String? nom})>[];
  Completer<void>? issue;

  @override
  Future<IdentiteTitulaire> lire() async => IdentiteTitulaire(
    prenom: prenom,
    nom: nom,
    courriel: 'titulaire.a@exemple.test',
    methodeConnexion: MethodeConnexion.lienCourriel,
    statut: AccountStatus.active,
  );

  @override
  Future<void> modifier({String? prenom, String? nom}) async {
    ecritures.add((prenom: prenom, nom: nom));
    final Completer<void> attente = Completer<void>();
    issue = attente;
    await attente.future;
    this.prenom = prenom!;
    this.nom = nom!;
  }
}

List<Override> _capacite({required bool adulte, bool horsLigne = false}) =>
    <Override>[
      peutPoserMaPhotoProvider.overrideWith((Ref _) async => adulte),
      horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(horsLigne)),
    ];

Finder _dansLaPage(String texte) => find.descendant(
  of: find.byType(InformationsComptePage),
  matching: find.text(texte),
);

Future<_IdentiteModifiable> _monter(
  WidgetTester tester, {
  required bool adulte,
  bool horsLigne = false,
  Size taille = const Size(390, 844),
  TextDirection? direction,
}) async {
  final _IdentiteModifiable identite = _IdentiteModifiable();
  await monterCompte(
    tester,
    depart: Routes.compteTuteurSousPage('informations'),
    identite: identite,
    taille: taille,
    direction: direction,
    surcharges: _capacite(adulte: adulte, horsLigne: horsLigne),
  );
  return identite;
}

Future<void> _saisir(WidgetTester tester, {String? prenom, String? nom}) async {
  await tester.tap(find.byKey(InformationsComptePage.modifierKey));
  await tester.pumpAndSettle();
  if (prenom != null) {
    await tester.enterText(
      find.byKey(InformationsComptePage.champPrenomKey),
      prenom,
    );
  }
  if (nom != null) {
    await tester.enterText(find.byKey(InformationsComptePage.champNomKey), nom);
  }
  await tester.tap(find.byKey(InformationsComptePage.enregistrerKey));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  group('Regles de saisie', () {
    test('prenom et nom rognes, vides ou trop longs refuses', () {
      expect(defautNom(''), DefautNom.vide);
      expect(defautNom('   '), DefautNom.vide);
      expect(defautNom(null), DefautNom.vide);
      expect(defautNom('a' * longueurMaxNom), isNull);
      expect(defautNom('a' * (longueurMaxNom + 1)), DefautNom.tropLong);
      expect(
        champsIdentite(prenom: ' Amina ', nom: ' Diallo '),
        <String, String>{'first_name': 'Amina', 'last_name': 'Diallo'},
      );
      expect(
        () => champsIdentite(prenom: ' ', nom: 'Diallo'),
        throwsArgumentError,
      );
    });
  });

  group('Capacite', () {
    testWidgets('eleve mineur : aucune action « Modifier »', (
      WidgetTester tester,
    ) async {
      await _monter(tester, adulte: false);
      expect(find.byType(InformationsComptePage), findsOneWidget);
      expect(find.byKey(InformationsComptePage.modifierKey), findsNothing);
      expect(
        _dansLaPage(t.compte.tuteur.pageInformations.note),
        findsOneWidget,
      );
    });

    testWidgets('ecriture non branchee : aucune action', (
      WidgetTester tester,
    ) async {
      await monterCompte(
        tester,
        depart: Routes.compteTuteurSousPage('informations'),
        identite: const IdentiteTitulaireIndisponible(),
        surcharges: _capacite(adulte: true),
      );
      expect(find.byKey(InformationsComptePage.modifierKey), findsNothing);
    });

    testWidgets('hors ligne : l action est absente, une phrase le dit', (
      WidgetTester tester,
    ) async {
      await _monter(tester, adulte: true, horsLigne: true);
      expect(find.byKey(InformationsComptePage.modifierKey), findsNothing);
      expect(find.byKey(InformationsComptePage.horsLigneKey), findsOneWidget);
    });
  });

  group('Modifier', () {
    testWidgets('les noms s affichent tout de suite, sans message de succes', (
      WidgetTester tester,
    ) async {
      final _IdentiteModifiable identite = await _monter(tester, adulte: true);
      expect(
        _dansLaPage(t.compte.tuteur.pageInformations.noteModifiable),
        findsOneWidget,
      );
      await _saisir(tester, prenom: '  Amina ', nom: 'Diallo');
      // Le serveur n'a pas encore repondu : les noms sont deja la.
      expect(identite.ecritures, <({String? prenom, String? nom})>[
        (prenom: 'Amina', nom: 'Diallo'),
      ]);
      expect(_dansLaPage('Amina'), findsOneWidget);
      expect(_dansLaPage('Diallo'), findsOneWidget);
      identite.issue!.complete();
      await tester.pumpAndSettle();
      expect(_dansLaPage('Amina'), findsOneWidget);
      expect(find.byKey(InformationsComptePage.echecKey), findsNothing);
      expect(find.textContaining('enregistr'), findsNothing);
    });

    testWidgets('refus du serveur : retour en arriere, phrase et Reessayer', (
      WidgetTester tester,
    ) async {
      final _IdentiteModifiable identite = await _monter(tester, adulte: true);
      await _saisir(tester, prenom: 'Amina', nom: 'Diallo');
      expect(_dansLaPage('Amina'), findsOneWidget);
      identite.issue!.completeError(Exception('refus'));
      await tester.pumpAndSettle();
      expect(_dansLaPage('Amina'), findsNothing);
      expect(_dansLaPage('Titulaire'), findsOneWidget);
      expect(_dansLaPage('Foyer A'), findsOneWidget);
      expect(find.byKey(InformationsComptePage.echecKey), findsOneWidget);

      await tester.tap(find.byKey(InformationsComptePage.reessayerKey));
      await tester.pump();
      expect(identite.ecritures.length, 2);
      expect(_dansLaPage('Amina'), findsOneWidget);
      expect(find.byKey(InformationsComptePage.echecKey), findsNothing);
      identite.issue!.complete();
      await tester.pumpAndSettle();
      expect(_dansLaPage('Amina'), findsOneWidget);
    });

    testWidgets('apres confirmation, l en-tete du Compte dit le nouveau nom', (
      WidgetTester tester,
    ) async {
      final _IdentiteModifiable identite = _IdentiteModifiable();
      final GoRouter routeur = await monterCompte(
        tester,
        depart: Routes.compteTuteurSousPage('informations'),
        identite: identite,
        surcharges: _capacite(adulte: true),
      );
      await _saisir(tester, prenom: 'Amina', nom: 'Diallo');
      identite.issue!.complete();
      await tester.pumpAndSettle();
      routeur.go(Routes.tuteurCompte);
      await tester.pumpAndSettle();
      expect(find.byType(CompteTuteurPage), findsOneWidget);
      expect(find.textContaining('Amina'), findsWidgets);
      expect(find.textContaining('Titulaire'), findsNothing);
    });

    testWidgets('formulaire inchange : la feuille se ferme, rien ne part', (
      WidgetTester tester,
    ) async {
      final _IdentiteModifiable identite = await _monter(tester, adulte: true);
      // Les memes noms, a des espaces pres.
      await _saisir(tester, prenom: ' Titulaire ');
      await tester.pumpAndSettle();
      expect(identite.ecritures, isEmpty);
      expect(find.byType(FeuilleNoms), findsNothing);
      expect(find.byKey(InformationsComptePage.echecKey), findsNothing);
      expect(_dansLaPage('Titulaire'), findsOneWidget);
    });

    testWidgets('prenom vide : rien ne part, la feuille le dit', (
      WidgetTester tester,
    ) async {
      final _IdentiteModifiable identite = await _monter(tester, adulte: true);
      await _saisir(tester, prenom: '   ');
      expect(identite.ecritures, isEmpty);
      expect(
        find.text(t.compte.tuteur.pageInformations.prenomVide),
        findsOneWidget,
      );
    });
  });

  group('Eleve adulte autonome', () {
    testWidgets('/compte le mene au Compte du tuteur, et sa page Informations '
        'propose Modifier', (WidgetTester tester) async {
      final _IdentiteModifiable identite = _IdentiteModifiable();
      final GoRouter routeur = await monterCompte(
        tester,
        depart: Routes.compte,
        identite: identite,
        session: sessionActive(AppRole.guardian).copyWith(eleveAutonome: true),
        surcharges: _capacite(adulte: true),
      );
      // La redirection de l'adulte (`_aliasTuteur`) : le Compte du tuteur.
      expect(lieu(routeur), Routes.tuteurCompte);
      await toucher(tester, find.byKey(cleLigneInformationsCompte));
      expect(lieu(routeur), Routes.compteTuteurSousPage('informations'));
      await _saisir(tester, prenom: 'Amina', nom: 'Diallo');
      expect(identite.ecritures, <({String? prenom, String? nom})>[
        (prenom: 'Amina', nom: 'Diallo'),
      ]);
      identite.issue!.complete();
      await tester.pumpAndSettle();
      expect(_dansLaPage('Amina'), findsOneWidget);
    });
  });

  group('Capture : EDIT-INFOS-PERSO', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    for (final AppLocale locale in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final double largeur in <double>[390, 1440]) {
        final String suffixe = '${locale.languageCode}_${largeur.toInt()}';
        Future<void> preparer(WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(locale));
          addTearDown(() => LocaleSettings.setLocale(AppLocale.fr));
        }

        TextDirection direction() =>
            locale == AppLocale.ar ? TextDirection.rtl : TextDirection.ltr;

        testWidgets('page_$suffixe', (WidgetTester tester) async {
          await preparer(tester);
          await _monter(
            tester,
            adulte: true,
            taille: Size(largeur, 1000),
            direction: direction(),
          );
          debugPrint('PNG ${await capturerVue(tester, 'page_$suffixe')}');
        });

        testWidgets('feuille_$suffixe', (WidgetTester tester) async {
          await preparer(tester);
          await _monter(
            tester,
            adulte: true,
            taille: Size(largeur, 1000),
            direction: direction(),
          );
          await tester.tap(find.byKey(InformationsComptePage.modifierKey));
          await tester.pumpAndSettle();
          debugPrint('PNG ${await capturerVue(tester, 'feuille_$suffixe')}');
        });

        testWidgets('echec_$suffixe', (WidgetTester tester) async {
          await preparer(tester);
          final _IdentiteModifiable identite = await _monter(
            tester,
            adulte: true,
            taille: Size(largeur, 1000),
            direction: direction(),
          );
          await _saisir(tester, prenom: 'Amina', nom: 'Diallo');
          identite.issue!.completeError(Exception('refus'));
          await tester.pumpAndSettle();
          debugPrint('PNG ${await capturerVue(tester, 'echec_$suffixe')}');
        });

        testWidgets('hors_ligne_$suffixe', (WidgetTester tester) async {
          await preparer(tester);
          await _monter(
            tester,
            adulte: true,
            horsLigne: true,
            taille: Size(largeur, 1000),
            direction: direction(),
          );
          debugPrint('PNG ${await capturerVue(tester, 'hors_ligne_$suffixe')}');
        });

        testWidgets('mineur_$suffixe', (WidgetTester tester) async {
          await preparer(tester);
          await _monter(
            tester,
            adulte: false,
            taille: Size(largeur, 1000),
            direction: direction(),
          );
          debugPrint('PNG ${await capturerVue(tester, 'mineur_$suffixe')}');
        });
      }
    }
  });
}
