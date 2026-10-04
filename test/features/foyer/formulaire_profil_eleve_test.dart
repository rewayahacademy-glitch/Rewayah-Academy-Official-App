// L'ajout d'un profil eleve (lot B, sous-paquet 2), sur le VRAI routeur.
//
// Chaque parcours part de la navigation (onglet Foyer de la barre basse, puis
// « Ajouter un profil eleve ») et TOUCHE les cartes, les champs et les
// boutons : un `routeur.go` seul ne prouve pas qu'un ecran est atteignable
// (registre, section 5 bis). Le port de creation reel (`CreationProfilEleve
// Appairage`, contrat K3) tourne sur un faux service d'appairage ; le double
// du port sert seulement a tenir un envoi ouvert (double soumission).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/capacites/port_identite_titulaire.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/foyer/port_creation_profil_eleve.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/appareils/ajouter_enfant_page.dart';
import 'package:rewayah_academy/features/compte/donnees_compte.dart'
    show identiteTitulaireProvider;
import 'package:rewayah_academy/features/foyer/fiche_eleve_page.dart';
import 'package:rewayah_academy/features/foyer/formulaire_profil_eleve.dart';
import 'package:rewayah_academy/features/foyer/foyer_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FunctionException;

import '../../fixtures/tuteur/faux_creation_profil_eleve.dart';
import '../../fixtures/tuteur/foyers.dart';
import '../../router/support_routeur.dart';
import '../../support/harnais.dart';

/// Un service d'appairage ou la creation ajoute vraiment un eleve au foyer :
/// la relecture qui suit le montre, comme le ferait `profils_du_foyer_v`.
class _AppairageCreant extends FauxServiceAppairage {
  _AppairageCreant() {
    elevesRendus = List<EleveDuFoyer>.of(FoyersFictifs.foyerA);
  }

  /// Ce que la creation jette APRES avoir ecrit (reponse perdue).
  Object? jeterApresEcriture;

  int _suivant = 0;

  @override
  Future<void> creerEnfant({
    required String prenom,
    required String nom,
    required int age,
    String? niveau,
  }) async {
    await super.creerEnfant(prenom: prenom, nom: nom, age: age);
    _suivant++;
    elevesRendus = <EleveDuFoyer>[
      ...elevesRendus,
      EleveDuFoyer(
        id: 'foyer-a-nouveau-$_suivant',
        prenom: prenom,
        identifiantImmuable: 'STUD-FA-10000$_suivant',
        mode: InterfaceMode.standard,
        camera: CameraPolicy.forbidden,
      ),
    ];
    final Object? erreur = jeterApresEcriture;
    if (erreur != null) {
      // ignore: only_throw_errors
      throw erreur;
    }
  }
}

Future<GoRouter> _monter(
  WidgetTester tester, {
  required ServiceAppairage appairage,
  List<Override> autres = const <Override>[],
  Size taille = const Size(390, 844),
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesRouteur(
          FausseSourceSession(sessionActive(AppRole.guardian)),
          appairage: appairage,
        ),
        horlogeFoyerProvider.overrideWithValue(() => DateTime(2026, 9, 24, 12)),
        ...autres,
      ],
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext _, WidgetRef ref, Widget? _) {
            routeur = ref.read(routeurProvider);
            return MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              routerConfig: routeur,
            );
          },
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(Routes.tuteurAccueil);
  await stabiliser(tester);
  return routeur;
}

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await stabiliser(tester);
  await tester.tap(cible);
  await stabiliser(tester);
}

/// Onglet Foyer de la barre basse, puis « Ajouter un profil eleve ».
Future<void> _ouvrirAjout(WidgetTester tester, {bool bureau = false}) async {
  if (bureau) {
    await _toucher(tester, find.text(t.nav.tuteur.foyer).first);
  } else {
    await _toucher(
      tester,
      find.descendant(
        of: find.byKey(NavShell.barreBasseKey),
        matching: find.text(t.nav.tuteur.foyer),
      ),
    );
  }
  await _toucher(tester, find.byKey(FoyerPage.ajouterKey));
}

VoidCallback? _action(WidgetTester tester) => tester
    .widget<ActionPrincipale>(find.byKey(FormulaireProfilEleve.actionKey))
    .onPress;

Future<void> _choisirEnfantPuisSuivant(WidgetTester tester) async {
  await _toucher(tester, find.text(t.foyer.ajout.pourQui.enfantTitre));
  await _toucher(tester, find.byKey(FormulaireProfilEleve.actionKey));
}

Future<void> _remplir(
  WidgetTester tester, {
  String prenom = 'Nouvel eleve',
  String nom = 'Fictif',
  String age = '9',
}) async {
  await tester.enterText(find.byKey(FormulaireProfilEleve.prenomKey), prenom);
  await tester.enterText(find.byKey(FormulaireProfilEleve.nomKey), nom);
  await _toucher(
    tester,
    find.byKey(FormulaireProfilEleve.ageChoixKey(int.parse(age))),
  );
  await stabiliser(tester);
}

void main() {
  group('Ajout : atteint et mene depuis la navigation', () {
    testWidgets(
      'Foyer -> « Ajouter un profil eleve » -> pour qui -> identite -> '
      'creation -> fiche du nouveau profil',
      (WidgetTester tester) async {
        final _AppairageCreant service = _AppairageCreant();
        final GoRouter routeur = await _monter(tester, appairage: service);
        await _ouvrirAjout(tester);

        expect(lieu(routeur), Routes.tuteurAjouterEnfant);
        expect(find.byType(AjouterEnfantPage), findsOneWidget);
        expect(find.text(t.foyer.ajout.pourQui.question), findsOneWidget);
        expect(find.text(t.commun.etape.sur(n: 1, total: 2)), findsOne);
        // Aucune presélection : le bouton attend un choix.
        expect(_action(tester), isNull);

        await _choisirEnfantPuisSuivant(tester);
        expect(find.text(t.foyer.ajout.identite.question), findsOneWidget);
        expect(find.text(t.commun.etape.sur(n: 2, total: 2)), findsOne);

        await _remplir(tester, prenom: '  Nouvel eleve ', nom: ' Fictif ');
        await _toucher(tester, find.byKey(FormulaireProfilEleve.actionKey));

        // Un seul envoi, nettoye des espaces ; la relecture du foyer designe
        // le profil cree et sa fiche s'ouvre.
        expect(service.enfantsCrees, hasLength(1));
        expect(service.enfantsCrees.single.prenom, 'Nouvel eleve');
        expect(service.enfantsCrees.single.nom, 'Fictif');
        expect(service.enfantsCrees.single.age, 9);
        expect(lieu(routeur), Routes.ficheElevePour('foyer-a-nouveau-1'));
        expect(find.byType(FicheElevePage), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'proche adulte absent (F2, EA-5) ; moi-meme visible, dit indisponible, '
      'ne se choisit pas',
      (WidgetTester tester) async {
        await _monter(tester, appairage: _AppairageCreant());
        await _ouvrirAjout(tester);

        // Les cles « procheTitre » et « procheDescription » sont retirees de
        // l'i18n (EA-5c) : le texte ne peut plus revenir a l'ecran.
        expect(find.text('Un proche adulte'), findsNothing);
        expect(find.text(t.foyer.ajout.pourQui.moiTitre), findsOneWidget);
        expect(find.text(t.foyer.ajout.pourQui.moiDescription), findsOne);
        expect(find.text(t.foyer.ajout.pourQui.indisponible), findsOneWidget);

        await _toucher(tester, find.text(t.foyer.ajout.pourQui.moiTitre));
        expect(_action(tester), isNull);
        expect(find.text(t.foyer.ajout.pourQui.question), findsOneWidget);

        // Semantique : groupe exclusif, cartes indisponibles non actives.
        final SemanticsHandle poignee = tester.ensureSemantics();
        expect(
          tester.getSemantics(find.text(t.foyer.ajout.pourQui.moiTitre)),
          isSemantics(
            isInMutuallyExclusiveGroup: true,
            hasCheckedState: true,
            isChecked: false,
            hasEnabledState: true,
            isEnabled: false,
          ),
        );
        poignee.dispose();
      },
    );

    testWidgets('retour : identite -> pour qui sans perte, puis Foyer', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(
        tester,
        appairage: _AppairageCreant(),
      );
      await _ouvrirAjout(tester);
      await _choisirEnfantPuisSuivant(tester);
      await _remplir(tester);

      await _toucher(tester, find.byType(DisqueRetour));
      expect(find.text(t.foyer.ajout.pourQui.question), findsOneWidget);
      // Le choix est garde : « Suivant » est actif.
      expect(_action(tester), isNotNull);

      await _toucher(tester, find.byKey(FormulaireProfilEleve.actionKey));
      expect(find.text('Nouvel eleve'), findsOneWidget);
      expect(find.text('Fictif'), findsOneWidget);

      await _toucher(tester, find.byType(DisqueRetour));
      await _toucher(tester, find.byType(DisqueRetour));
      expect(lieu(routeur), Routes.tuteurFoyer);
      expect(find.byType(FoyerPage), findsOneWidget);
    });
  });

  group('Ajout : erreurs sous les champs', () {
    testWidgets('champs vides : trois erreurs, aucun envoi', (
      WidgetTester tester,
    ) async {
      final _AppairageCreant service = _AppairageCreant();
      await _monter(tester, appairage: service);
      await _ouvrirAjout(tester);
      await _choisirEnfantPuisSuivant(tester);

      // Avant toute tentative, aucune erreur n'accuse la personne.
      expect(find.text(t.foyer.ajout.erreurs.prenomRequis), findsNothing);

      await _toucher(tester, find.byKey(FormulaireProfilEleve.actionKey));
      expect(find.text(t.foyer.ajout.erreurs.prenomRequis), findsOneWidget);
      expect(find.text(t.foyer.ajout.erreurs.nomRequis), findsOneWidget);
      expect(find.text(t.foyer.ajout.erreurs.ageRequis), findsOneWidget);
      expect(service.enfantsCrees, isEmpty);
    });

    testWidgets('FORM-L6 : l age se choisit dans les bornes (3 a 18), il ne se '
        'tape pas ; sans choix, l erreur dit quoi faire', (
      WidgetTester tester,
    ) async {
      final _AppairageCreant service = _AppairageCreant();
      await _monter(tester, appairage: service);
      await _ouvrirAjout(tester);
      await _choisirEnfantPuisSuivant(tester);

      // Aucun champ de saisie pour l'age : une puce par age des bornes.
      expect(
        find.descendant(
          of: find.byKey(FormulaireProfilEleve.ageKey),
          matching: find.byType(TextField),
        ),
        findsNothing,
      );
      for (int age = 3; age <= 18; age++) {
        expect(
          find.byKey(FormulaireProfilEleve.ageChoixKey(age)),
          findsOneWidget,
          reason: 'puce $age',
        );
      }
      expect(find.byKey(FormulaireProfilEleve.ageChoixKey(2)), findsNothing);
      expect(find.byKey(FormulaireProfilEleve.ageChoixKey(19)), findsNothing);

      await tester.enterText(
        find.byKey(FormulaireProfilEleve.prenomKey),
        'Aya',
      );
      await tester.enterText(find.byKey(FormulaireProfilEleve.nomKey), 'Ba');
      await _toucher(tester, find.byKey(FormulaireProfilEleve.actionKey));
      expect(find.text(t.foyer.ajout.erreurs.ageRequis), findsOneWidget);
      expect(service.enfantsCrees, isEmpty);

      // Choisir une puce leve l'erreur et part tel quel.
      await _toucher(tester, find.byKey(FormulaireProfilEleve.ageChoixKey(18)));
      expect(find.text(t.foyer.ajout.erreurs.ageRequis), findsNothing);
      await _toucher(tester, find.byKey(FormulaireProfilEleve.actionKey));
      expect(service.enfantsCrees.single.age, 18);
    });

    testWidgets('FORM-L6 : le nom de famille est prerempli avec celui du '
        'titulaire, reste modifiable et part tel que modifie', (
      WidgetTester tester,
    ) async {
      final _AppairageCreant service = _AppairageCreant();
      await _monter(
        tester,
        appairage: service,
        autres: <Override>[
          identiteTitulaireProvider.overrideWith(
            (Ref _) async => const IdentiteTitulaire(
              prenom: 'Awa',
              nom: ' Diallo ',
              methodeConnexion: MethodeConnexion.lienCourriel,
            ),
          ),
        ],
      );
      await _ouvrirAjout(tester);
      await _choisirEnfantPuisSuivant(tester);

      TextField nom() =>
          tester.widget<TextField>(find.byKey(FormulaireProfilEleve.nomKey));
      expect(nom().controller!.text, 'Diallo');
      expect(find.text(t.foyer.ajout.identite.nomAidePrerempli), findsOne);

      // Modifiable : une autre saisie remplace le prerempli.
      await tester.enterText(
        find.byKey(FormulaireProfilEleve.nomKey),
        'Ndiaye',
      );
      await tester.enterText(
        find.byKey(FormulaireProfilEleve.prenomKey),
        'Aya',
      );
      await _toucher(tester, find.byKey(FormulaireProfilEleve.ageChoixKey(7)));
      await _toucher(tester, find.byKey(FormulaireProfilEleve.actionKey));
      expect(service.enfantsCrees.single.nom, 'Ndiaye');
      expect(service.enfantsCrees.single.age, 7);
    });

    testWidgets('FORM-L6 : compte illisible, le nom reste vide et le serveur '
        'garde la main', (WidgetTester tester) async {
      await _monter(tester, appairage: _AppairageCreant());
      await _ouvrirAjout(tester);
      await _choisirEnfantPuisSuivant(tester);

      expect(
        tester
            .widget<TextField>(find.byKey(FormulaireProfilEleve.nomKey))
            .controller!
            .text,
        isEmpty,
      );
      expect(find.text(t.foyer.ajout.identite.nomAide), findsOne);
      expect(find.text(t.foyer.ajout.identite.nomAidePrerempli), findsNothing);
    });
  });

  group('Ajout : reponses du service', () {
    testWidgets('dossier non valide : dit la raison, reste sur la page', (
      WidgetTester tester,
    ) async {
      final _AppairageCreant service = _AppairageCreant()
        ..erreurAJeter = const FunctionException(
          status: 403,
          details: <String, String>{'error': 'compte tuteur non valide'},
        );
      final GoRouter routeur = await _monter(tester, appairage: service);
      await _ouvrirAjout(tester);
      await _choisirEnfantPuisSuivant(tester);
      await _remplir(tester);
      await _toucher(tester, find.byKey(FormulaireProfilEleve.actionKey));

      expect(find.text(t.foyer.ajout.refus.compteNonValide), findsOneWidget);
      expect(lieu(routeur), Routes.tuteurAjouterEnfant);
      // Aucun texte du serveur a l'ecran.
      expect(find.textContaining('compte tuteur'), findsNothing);
    });

    testWidgets('age refuse par le serveur : erreur sous l age', (
      WidgetTester tester,
    ) async {
      final _AppairageCreant service = _AppairageCreant()
        ..erreurAJeter = const FunctionException(
          status: 400,
          details: <String, String>{'error': 'age hors bornes'},
        );
      await _monter(tester, appairage: service);
      await _ouvrirAjout(tester);
      await _choisirEnfantPuisSuivant(tester);
      await _remplir(tester);
      await _toucher(tester, find.byKey(FormulaireProfilEleve.actionKey));

      expect(find.text(t.foyer.ajout.refus.ageHorsBornes), findsOneWidget);
      expect(
        find.text(t.foyer.ajout.erreurs.ageHorsBornes(min: 3, max: 18)),
        findsOneWidget,
      );
    });

    testWidgets(
      'reponse perdue, rien de cree : l ecran le dit, « Voir le foyer » y '
      'ramene',
      (WidgetTester tester) async {
        final _AppairageCreant service = _AppairageCreant()
          ..erreurAJeter = const FunctionException(status: 504);
        final GoRouter routeur = await _monter(tester, appairage: service);
        await _ouvrirAjout(tester);
        await _choisirEnfantPuisSuivant(tester);
        await _remplir(tester);
        await _toucher(tester, find.byKey(FormulaireProfilEleve.actionKey));

        expect(find.text(t.foyer.ajout.incertaine.titre), findsOneWidget);
        expect(find.textContaining('DB-FOY'), findsNothing);
        // Aucun nouvel envoi aveugle : le bouton du bas est retenu.
        expect(_action(tester), isNull);

        await _toucher(tester, find.text(t.foyer.ajout.incertaine.voirFoyer));
        expect(lieu(routeur), Routes.tuteurFoyer);
      },
    );

    testWidgets('reponse perdue : « Reessayer quand meme » renvoie une fois', (
      WidgetTester tester,
    ) async {
      final _AppairageCreant service = _AppairageCreant()
        ..erreurAJeter = const FunctionException(status: 504);
      final GoRouter routeur = await _monter(tester, appairage: service);
      await _ouvrirAjout(tester);
      await _choisirEnfantPuisSuivant(tester);
      await _remplir(tester);
      await _toucher(tester, find.byKey(FormulaireProfilEleve.actionKey));

      service.erreurAJeter = null;
      await _toucher(tester, find.text(t.foyer.ajout.incertaine.reessayer));
      expect(service.enfantsCrees, hasLength(1));
      expect(lieu(routeur), Routes.ficheElevePour('foyer-a-nouveau-1'));
    });

    testWidgets(
      'reponse perdue mais profil ecrit : la relecture le retrouve, la fiche '
      's ouvre',
      (WidgetTester tester) async {
        final _AppairageCreant service = _AppairageCreant()
          ..jeterApresEcriture = Exception('coupure');
        final GoRouter routeur = await _monter(tester, appairage: service);
        await _ouvrirAjout(tester);
        await _choisirEnfantPuisSuivant(tester);
        await _remplir(tester);
        await _toucher(tester, find.byKey(FormulaireProfilEleve.actionKey));

        expect(find.text(t.foyer.ajout.incertaine.titre), findsNothing);
        expect(lieu(routeur), Routes.ficheElevePour('foyer-a-nouveau-1'));
      },
    );

    testWidgets('envoi en cours : un seul envoi malgre deux appuis', (
      WidgetTester tester,
    ) async {
      final FauxCreationProfilEleve port = FauxCreationProfilEleve()
        ..attente = Completer<void>();
      await _monter(
        tester,
        appairage: _AppairageCreant(),
        autres: <Override>[
          portCreationProfilEleveProvider.overrideWithValue(port),
        ],
      );
      await _ouvrirAjout(tester);
      await _choisirEnfantPuisSuivant(tester);
      await _remplir(tester);

      await tester.tap(find.byKey(FormulaireProfilEleve.actionKey));
      await tester.pump();
      await tester.tap(find.byKey(FormulaireProfilEleve.actionKey));
      await tester.pump();

      expect(port.envois, hasLength(1));
      expect(
        tester
            .widget<ActionPrincipale>(
              find.byKey(FormulaireProfilEleve.actionKey),
            )
            .enCours,
        isTrue,
      );
      port.attente!.complete();
      await stabiliser(tester);
    });
  });

  group('Ajout : etats', () {
    testWidgets('hors ligne : le dit, n envoie rien', (
      WidgetTester tester,
    ) async {
      final _AppairageCreant service = _AppairageCreant();
      await _monter(
        tester,
        appairage: service,
        autres: <Override>[
          horsLigneProvider.overrideWith((Ref ref) => Stream<bool>.value(true)),
        ],
      );
      await _ouvrirAjout(tester);
      await _choisirEnfantPuisSuivant(tester);
      await _remplir(tester);

      expect(find.text(t.foyer.ajout.horsLigne), findsOneWidget);
      expect(_action(tester), isNull);
      expect(service.enfantsCrees, isEmpty);
    });

    testWidgets(
      'compte pas encore actif : le choix enfant est desactive et explique',
      (WidgetTester tester) async {
        await _monter(
          tester,
          appairage: _AppairageCreant(),
          autres: <Override>[
            porteAjoutProfilProvider.overrideWithValue(PorteAcces.attente),
          ],
        );
        await _ouvrirAjout(tester);

        expect(find.text(t.foyer.ajout.pourQui.enfantAttente), findsOneWidget);
        // « Moi-meme » seul dit « Indisponible » : plus de proche adulte (F2).
        expect(find.text(t.foyer.ajout.pourQui.indisponible), findsOneWidget);
        await _toucher(tester, find.text(t.foyer.ajout.pourQui.enfantTitre));
        expect(_action(tester), isNull);
      },
    );

    // Revue du lot B : une session pas encore lue, illisible ou hors ligne ne
    // se dit jamais « Possible des que votre dossier est valide ».
    for (final (String nom, PorteAcces? porte, Key cle)
        in <(String, PorteAcces?, Key)>[
          (
            'session en chargement : squelette',
            PorteAcces.chargement,
            FormulaireProfilEleve.porteChargementKey,
          ),
          (
            'session illisible : erreur et relecture',
            null,
            FormulaireProfilEleve.porteIllisibleKey,
          ),
          (
            'session hors ligne : hors ligne',
            PorteAcces.horsLigne,
            FormulaireProfilEleve.porteHorsLigneKey,
          ),
        ]) {
      testWidgets('$nom, jamais la raison du dossier en attente', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          appairage: _AppairageCreant(),
          autres: <Override>[porteAjoutProfilProvider.overrideWithValue(porte)],
        );
        await _ouvrirAjout(tester);

        expect(find.byKey(cle), findsOneWidget);
        expect(find.text(t.foyer.ajout.pourQui.enfantAttente), findsNothing);
        expect(find.byKey(FormulaireProfilEleve.choixKey), findsNothing);
        expect(_action(tester), isNull);
        // Le retour reste visible : aucune impasse.
        expect(find.byType(DisqueRetour), findsOneWidget);
      });
    }

    testWidgets('vocabulaire : aucun libelle interdit sur les deux pages', (
      WidgetTester tester,
    ) async {
      await _monter(tester, appairage: _AppairageCreant());
      await _ouvrirAjout(tester);
      final List<String> textes = <String>[];
      void relever() {
        for (final Text texte in tester.widgetList<Text>(find.byType(Text))) {
          if (texte.data != null) {
            textes.add(texte.data!);
          }
        }
      }

      relever();
      await _choisirEnfantPuisSuivant(tester);
      relever();
      expect(textes, isNotEmpty);
      for (final String texte in textes) {
        final String bas = texte.toLowerCase();
        for (final String interdit in <String>[
          'session',
          'cours en cours',
          'ajouter enfant',
          'ajouter un enfant',
          'mode enfant',
          'groupe',
          'db-',
        ]) {
          expect(bas.contains(interdit), isFalse, reason: '« $texte »');
        }
      }
    });
  });

  group('Ajout : bureau', () {
    testWidgets('1440 : colonne centree de largeur de dialogue, atteinte par '
        'la barre laterale', (WidgetTester tester) async {
      final GoRouter routeur = await _monter(
        tester,
        appairage: _AppairageCreant(),
        taille: const Size(1440, 900),
      );
      await _ouvrirAjout(tester, bureau: true);
      expect(lieu(routeur), Routes.tuteurAjouterEnfant);

      final Rect colonne = tester.getRect(
        find.byKey(FormulaireProfilEleve.colonneKey),
      );
      final Rect action = tester.getRect(
        find.byKey(FormulaireProfilEleve.actionKey),
      );
      expect(colonne.width, lessThanOrEqualTo(AppPage.largeurDialogue));
      expect(action.width, lessThanOrEqualTo(AppPage.largeurDialogue));
      // Centree : l'action et la colonne partagent le meme axe.
      expect((colonne.center.dx - action.center.dx).abs(), lessThan(1));
      expect(tester.takeException(), isNull);
    });
  });
}
