import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/features/inscription/inscription_page.dart';

import '../support/harnais.dart';

/// Monte le parcours d'inscription sur des services en memoire.
///
/// **Mesure sur 390 x 844, jamais sur la surface par defaut.** Les deux echecs
/// anterieurs a ce lot -- `tap()` sur les cartes « Enseignant » et « Autre » --
/// n'etaient pas des defauts de l'ecran : `flutter_test` monte tout sur
/// 800 x 600, une fenetre plus COURTE que n'importe quel telephone du marche. La
/// question du role porte quatre cartes de 112 points chacune, soit 484 points
/// de choix ; il en restait 294 sous l'en-tete de parcours. Les deux dernieres
/// cartes tombaient donc hors cadre, `tap()` derivait un offset qui atteignait
/// la zone d'action collee, et « Continuer » etait presse a la place. Le meme
/// ecran tient a 390 x 844.
///
/// La difference avec `dossier_test.dart`, ou la cause etait l'inverse, est ce
/// qui rendait le diagnostic trompeur : deux tests rouges, le meme symptome, et
/// deux causes opposees.
Future<(FauxServiceDossier, FausseSourceSession)> _monter(
  WidgetTester tester,
) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final FauxServiceDossier dossier = FauxServiceDossier();
  final FausseSourceSession source = FausseSourceSession();

  await tester.pumpWidget(
    hote(
      const InscriptionPage(),
      surcharges: <Override>[
        serviceDossierProvider.overrideWithValue(dossier),
        sourceSessionProvider.overrideWithValue(source),
      ],
    ),
  );
  return (dossier, source);
}

/// L'unique action principale de la page courante.
ActionPrincipale _action(WidgetTester tester) =>
    tester.widget<ActionPrincipale>(find.byType(ActionPrincipale));

Future<void> _taper(WidgetTester tester, String libelle) async {
  await tester.tap(find.text(libelle));
  await tester.pumpAndSettle();
}

/// Tape une carte de choix, apres l'avoir amenee dans le cadre.
///
/// Les cartes vivent dans le corps defilant, et la quatrieme d'une liste de
/// quatre frole le bas de l'ecran a 390 x 844 : deux points de marge, qu'un
/// libelle plus long ou une echelle de texte suffiraient a manger. On amene donc
/// la cible plutot que de compter sur cette marge -- c'est le geste qu'une
/// personne ferait.
Future<void> _taperCarte(WidgetTester tester, String libelle) async {
  final Finder cible = find.text(libelle);
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

void main() {
  group('TUT-00c : le parcours en cartes', () {
    testWidgets('une question par page, et une seule action par page', (
      WidgetTester tester,
    ) async {
      await _monter(tester);

      // La regle « un ecran, une action principale » se verifie en comptant.
      expect(find.byType(ActionPrincipale), findsOneWidget);
      expect(find.text(t.inscription.roleQuestion), findsOneWidget);
      expect(find.text(t.inscription.identiteQuestion), findsNothing);
    });

    testWidgets('rien n avance tant qu aucune reponse n est donnee', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      expect(
        _action(tester).onPress,
        isNull,
        reason:
            'Le bouton doit rester inerte, et le rester visiblement, plutot '
            'que d echouer apres le geste.',
      );
    });

    testWidgets('un eleve adulte est son propre tuteur (ADR-009)', (
      WidgetTester tester,
    ) async {
      final (FauxServiceDossier dossier, FausseSourceSession source) =
          await _monter(tester);

      await _taperCarte(tester, t.inscription.roleEleveAdulte);
      await _taper(tester, t.commun.continuer);

      await tester.enterText(find.byType(TextField).first, 'Moussa');
      await tester.enterText(find.byType(TextField).last, 'Barry');
      await tester.pumpAndSettle();
      await _taper(tester, t.commun.continuer);

      await _taperCarte(tester, t.inscription.genreHomme);
      await _taper(tester, t.commun.continuer);
      await _taper(tester, t.inscription.creer);

      expect(dossier.profilsCrees, hasLength(1));
      expect(
        dossier.profilsCrees.single.role,
        AppRole.guardian,
        reason:
            'Un eleve adulte autonome constitue un foyer d une personne dont '
            'il est son propre tuteur : un seul chemin en base, deux libelles '
            'a l ecran.',
      );
      expect(dossier.profilsCrees.single.prenom, 'Moussa');
      expect(dossier.profilsCrees.single.genre, Genre.homme);

      // Le role et le foyer sont injectes dans le jeton par la base : sans ce
      // rafraichissement, le compte resterait sans role et le routeur le
      // laisserait devant une porte fermee.
      expect(source.rafraichissements, 1);
    });

    testWidgets('un enseignant est bien cree comme enseignant', (
      WidgetTester tester,
    ) async {
      final (FauxServiceDossier dossier, _) = await _monter(tester);

      await _taperCarte(tester, t.inscription.roleEnseignant);
      await _taper(tester, t.commun.continuer);
      await tester.enterText(find.byType(TextField).first, 'Aicha');
      await tester.enterText(find.byType(TextField).last, 'Sow');
      await tester.pumpAndSettle();
      await _taper(tester, t.commun.continuer);
      await _taperCarte(tester, t.inscription.genreFemme);
      await _taper(tester, t.commun.continuer);
      await _taper(tester, t.inscription.creer);

      expect(dossier.profilsCrees.single.role, AppRole.teacher);
      expect(dossier.profilsCrees.single.genre, Genre.femme);
    });

    testWidgets('la carte « Autre » offre une issue, jamais un role invente', (
      WidgetTester tester,
    ) async {
      // ADR-013 : la carte « Autre » est systematique. Sur la question du role,
      // elle ne peut pas produire de valeur, puisque la base n en connait que
      // deux. Elle doit donc mener quelque part, sans rien fabriquer.
      final (FauxServiceDossier dossier, _) = await _monter(tester);

      await _taperCarte(tester, t.choix.autre);

      expect(find.text(t.inscription.autreAide), findsOneWidget);
      expect(
        _action(tester).onPress,
        isNull,
        reason: 'Aucun role ne doit pouvoir sortir de la carte « Autre ».',
      );
      expect(dossier.profilsCrees, isEmpty);
    });

    testWidgets('le retour ramene a la question precedente', (
      WidgetTester tester,
    ) async {
      await _monter(tester);

      await _taperCarte(tester, t.inscription.roleTuteur);
      await _taper(tester, t.commun.continuer);
      expect(find.text(t.inscription.identiteQuestion), findsOneWidget);

      await _taper(tester, t.commun.retour);
      expect(find.text(t.inscription.roleQuestion), findsOneWidget);
    });

    testWidgets('un echec de creation se dit, et ne fait pas avancer', (
      WidgetTester tester,
    ) async {
      final (FauxServiceDossier dossier, FausseSourceSession source) =
          await _monter(tester);
      dossier.erreurAJeter = StateError('refus du serveur');

      await _taperCarte(tester, t.inscription.roleTuteur);
      await _taper(tester, t.commun.continuer);
      await tester.enterText(find.byType(TextField).first, 'Fatou');
      await tester.enterText(find.byType(TextField).last, 'Diallo');
      await tester.pumpAndSettle();
      await _taper(tester, t.commun.continuer);
      await _taperCarte(tester, t.inscription.genreFemme);
      await _taper(tester, t.commun.continuer);
      await _taper(tester, t.inscription.creer);

      expect(find.text(t.inscription.erreur), findsOneWidget);
      expect(source.rafraichissements, 0);
    });
  });
}
