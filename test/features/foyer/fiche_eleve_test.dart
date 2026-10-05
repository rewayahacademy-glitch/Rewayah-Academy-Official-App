// La fiche eleve et ses sous-pages (lot B, sous-paquet 3), sur le VRAI
// routeur.
//
// Chaque parcours part de la navigation et TOUCHE les boutons : onglet Foyer
// de la barre basse, ligne du membre, lignes de la fiche, disques retour,
// cartes, interrupteur, actions de photo. Un `routeur.go` seul ne prouve pas
// qu'un ecran est atteignable (registre, section 5 bis) ; il ne sert ici
// qu'aux etats (chargement, erreur, hors ligne, introuvable) d'un lien
// profond.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/appairage/service_avatar.dart';
import 'package:rewayah_academy/core/capacites/port_classes_foyer.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/offres/offre_horaire.dart';
import 'package:rewayah_academy/core/offres/service_offres.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';
import 'package:rewayah_academy/features/appareils/appareils_eleve_page.dart';
import 'package:rewayah_academy/features/classe_tuteur/catalogue_classes_page.dart';
import 'package:rewayah_academy/features/classe_tuteur/classe_tuteur_page.dart';
import 'package:rewayah_academy/features/foyer/fiche/acces_page.dart';
import 'package:rewayah_academy/features/foyer/fiche/camera_page.dart';
import 'package:rewayah_academy/features/foyer/fiche/informations_page.dart';
import 'package:rewayah_academy/features/foyer/fiche/inscription_page.dart';
import 'package:rewayah_academy/features/foyer/fiche/interface_page.dart';
import 'package:rewayah_academy/features/foyer/fiche_eleve_page.dart';
import 'package:rewayah_academy/features/foyer/foyer_page.dart';
import 'package:rewayah_academy/features/foyer/photo_eleve.dart';
import 'package:rewayah_academy/features/parcours_offres/parcours_offres_page.dart';

import '../../capture/outil_capture.dart'
    show capturerVue, chargerPolicesDuDepot, masquerRubanDebug, sautSansCapture;
import '../../fixtures/tuteur/faux_classes_foyer.dart';
import '../../fixtures/tuteur/foyers.dart';
import '../../parcours/faux_service_offres.dart';
import '../../router/support_routeur.dart';
import '../../support/harnais.dart';
import '../../support/hors_ligne_une_fois.dart';

/// L'instant fixe des tests : le 24 septembre 2026 a midi.
final DateTime _maintenant = DateTime(2026, 9, 24, 12);

/// Une image PNG valide d'un pixel : l'apercu se decode sans erreur.
final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);

/// Un service d'appairage dont la lecture des eleves se pilote.
class _AppairagePilote extends FauxServiceAppairage {
  bool echoue = false;
  Completer<void>? attente;
  int lectures = 0;

  @override
  Future<List<EleveDuFoyer>> eleves() async {
    lectures++;
    final Completer<void>? a = attente;
    if (a != null) {
      await a.future;
    }
    if (echoue) {
      throw Exception('lecture refusee');
    }
    return elevesRendus;
  }
}

_AppairagePilote _foyerA() =>
    _AppairagePilote()..elevesRendus = FoyersFictifs.foyerA;

/// Un selecteur de photos qui leve (permission refusee, fichier illisible).
class _SelecteurQuiLeve implements SelecteurPhoto {
  @override
  Future<PhotoEnfant?> choisirPhoto() async =>
      throw Exception('permission refusee');
}

/// Un port des classes dont la lecture echoue tant que [echoue] est vrai
/// (service present : ce n'est pas `CapaciteIndisponible`).
class _ClassesEnEchec extends FauxClassesFoyer {
  _ClassesEnEchec({super.classes});

  bool echoue = true;
  int lectures = 0;

  @override
  Future<List<ClasseFoyer>> classesDe(String eleveId) async {
    lectures++;
    if (echoue) {
      throw Exception('lecture des classes refusee');
    }
    return super.classesDe(eleveId);
  }
}

Future<GoRouter> _monter(
  WidgetTester tester, {
  required ServiceAppairage appairage,
  String depart = Routes.tuteurAccueil,
  List<Override> autres = const <Override>[],
  Size taille = const Size(390, 844),
  ThemeMode mode = ThemeMode.light,
  InterfaceMode interface = InterfaceMode.standard,
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
        horlogeFoyerProvider.overrideWithValue(() => _maintenant),
        ...autres,
      ],
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext _, WidgetRef ref, Widget? _) {
            routeur = ref.read(routeurProvider);
            return MaterialApp.router(
              theme: AppTheme.pour(interface, Brightness.light),
              darkTheme: AppTheme.pour(interface, Brightness.dark),
              themeMode: mode,
              routerConfig: routeur,
            );
          },
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(depart);
  await stabiliser(tester);
  return routeur;
}

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await stabiliser(tester);
  await tester.tap(cible);
  await stabiliser(tester);
}

/// Onglet Foyer de la barre basse, puis la ligne du membre A1.
Future<void> _ouvrirFicheA1(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byKey(NavShell.barreBasseKey),
      matching: find.text(t.nav.tuteur.foyer),
    ),
  );
  await stabiliser(tester);
  await _toucher(tester, find.text('Eleve A1'));
}

/// Depuis la fiche, la ligne d'une sous-page.
Future<void> _ouvrirLigne(WidgetTester tester, String libelle) =>
    _toucher(tester, find.text(libelle));

/// Le conteneur de l'application montee.
ProviderContainer _conteneur(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

/// Le faux des offres pose par le harnais du routeur.
FauxServiceOffres _offres(WidgetTester tester) =>
    _conteneur(tester).read(serviceOffresProvider) as FauxServiceOffres;

Finder _etat(NatureEtat nature) => find.byWidgetPredicate(
  (Widget w) => w is EtatSysteme && w.nature == nature,
);

List<String> _textesVisibles(WidgetTester tester) => <String>[
  for (final Text texte in tester.widgetList<Text>(find.byType(Text)))
    if (texte.data != null) texte.data!,
];

void _verifierVocabulaire(WidgetTester tester) {
  for (final String texte in _textesVisibles(tester)) {
    final String bas = texte.toLowerCase();
    for (final String interdit in <String>[
      'session',
      'cours en cours',
      'ajouter enfant',
      'mode enfant',
      'groupe',
      'stud-',
      'db-',
    ]) {
      expect(bas.contains(interdit), isFalse, reason: '« $texte »');
    }
  }
}

void main() {
  final String a1 = FoyersFictifs.a1.id;

  group('Fiche : atteinte depuis la navigation', () {
    testWidgets('Foyer -> fiche : carte d identite, parametres, appareils, '
        'onglet Foyer actif, retour au Foyer', (WidgetTester tester) async {
      final GoRouter routeur = await _monter(tester, appairage: _foyerA());
      await _ouvrirFicheA1(tester);

      expect(lieu(routeur), Routes.ficheElevePour(a1));
      expect(find.byType(FicheElevePage), findsOneWidget);
      expect(find.byKey(FicheElevePage.enteteKey), findsOneWidget);
      expect(find.text(t.ficheEleve.parametres), findsOneWidget);
      expect(find.text(t.ficheEleve.lignes.informations), findsOneWidget);
      expect(find.text(t.ficheEleve.lignes.inscription), findsOneWidget);
      // A1 est en Interface guidee, camera non autorisee, sans echeance.
      expect(find.text(t.ficheEleve.interface.guidee), findsOneWidget);
      expect(find.text(t.ficheEleve.lignes.cameraNonAutorisee), findsOneWidget);
      expect(find.text(t.foyer.membre.accesSansEcheance), findsOneWidget);
      expect(
        tester.widget<NavShell>(find.byType(NavShell)).indexActif,
        1,
        reason: 'onglet Foyer actif',
      );
      _verifierVocabulaire(tester);

      await _toucher(tester, find.byType(DisqueRetour));
      expect(lieu(routeur), Routes.tuteurFoyer);
      expect(find.byType(FoyerPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('chaque ligne ouvre sa sous-page, son disque retour ramene a '
        'la fiche', (WidgetTester tester) async {
      final GoRouter routeur = await _monter(tester, appairage: _foyerA());
      await _ouvrirFicheA1(tester);

      final List<(String, String, Type)> lignes = <(String, String, Type)>[
        (
          t.ficheEleve.lignes.informations,
          'informations',
          InformationsElevePage,
        ),
        (t.ficheEleve.lignes.inscription, 'inscription', InscriptionElevePage),
        (t.ficheEleve.lignes.interface, 'interface', InterfaceElevePage),
        (t.ficheEleve.lignes.camera, 'camera', CameraElevePage),
        (t.ficheEleve.lignes.acces, 'acces', AccesElevePage),
      ];
      for (final (String libelle, String segment, Type ecran) in lignes) {
        await _ouvrirLigne(tester, libelle);
        expect(lieu(routeur), Routes.ficheEleveSousPage(a1, segment));
        expect(find.byType(ecran), findsOneWidget);
        expect(find.byType(DisqueRetour), findsOneWidget, reason: segment);
        _verifierVocabulaire(tester);

        await _toucher(tester, find.byType(DisqueRetour));
        expect(lieu(routeur), Routes.ficheElevePour(a1), reason: segment);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('la ligne Appareils ouvre l ecran des appareils de l eleve', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(tester, appairage: _foyerA());
      await _ouvrirFicheA1(tester);

      await _ouvrirLigne(
        tester,
        t.ficheEleve.lignes.appareils(prenom: 'Eleve A1'),
      );
      final Uri adresse = Uri.parse(lieu(routeur));
      expect(adresse.path, Routes.ficheEleveSousPage(a1, 'appareils'));
      expect(adresse.queryParameters['retour'], Routes.ficheElevePour(a1));
      expect(find.byType(AppareilsElevePage), findsOneWidget);

      // Le retour ramene a la fiche d ou l on vient (B-5).
      await tester.tap(find.byType(DisqueRetour));
      await stabiliser(tester);
      expect(lieu(routeur), Routes.ficheElevePour(a1));
      expect(find.byType(FicheElevePage), findsOneWidget);
    });
  });

  group('Fiche : etats', () {
    testWidgets('chargement : squelette puis contenu', (
      WidgetTester tester,
    ) async {
      final _AppairagePilote appairage = _foyerA()..attente = Completer<void>();
      await _monter(
        tester,
        appairage: appairage,
        depart: Routes.ficheElevePour(a1),
      );
      expect(find.byType(Skeleton), findsWidgets);
      expect(find.text(t.ficheEleve.parametres), findsNothing);
      // Le retour reste visible pendant le chargement : aucune impasse.
      expect(find.byType(DisqueRetour), findsOneWidget);

      appairage.attente!.complete();
      await stabiliser(tester);
      expect(find.text(t.ficheEleve.parametres), findsOneWidget);
    });

    testWidgets('erreur : « Reessayer » relit le foyer', (
      WidgetTester tester,
    ) async {
      final _AppairagePilote appairage = _foyerA()..echoue = true;
      await _monter(
        tester,
        appairage: appairage,
        depart: Routes.ficheEleveSousPage(a1, 'camera'),
      );
      expect(_etat(NatureEtat.echecServeur), findsOneWidget);
      final int avant = appairage.lectures;

      appairage.echoue = false;
      await tester.tap(find.text(t.commun.etats.actions.reessayer));
      await tester.pump();
      expect(appairage.lectures, greaterThan(avant));
      await stabiliser(tester);
      expect(find.byKey(CameraElevePage.interrupteurKey), findsOneWidget);
    });

    testWidgets('hors ligne : dit hors ligne, pas echec du serveur', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        appairage: _foyerA()..echoue = true,
        depart: Routes.ficheEleveSousPage(a1, 'informations'),
        autres: <Override>[
          horsLigneProvider.overrideWith((Ref ref) => Stream<bool>.value(true)),
        ],
      );
      expect(_etat(NatureEtat.horsLigne), findsOneWidget);
      expect(_etat(NatureEtat.echecServeur), findsNothing);
      expect(find.byType(DisqueRetour), findsOneWidget);
      // EA-HL-DOUBLE-1 : le bandeau dit le reseau, le bloc dit ce qui manque.
      expectSansDonnees(t.ficheEleve.sansDonnees);
    });

    testWidgets('identifiant inconnu : « introuvable », retour au foyer', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(
        tester,
        appairage: _foyerA(),
        depart: Routes.ficheElevePour('inconnu'),
      );
      expect(_etat(NatureEtat.introuvable), findsOneWidget);
      expect(find.text(t.ficheEleve.introuvable.titre), findsOneWidget);
      expect(find.text(t.ficheEleve.parametres), findsNothing);

      await _toucher(tester, find.text(t.ficheEleve.introuvable.retour));
      expect(lieu(routeur), Routes.tuteurFoyer);
    });

    testWidgets('sous-page d un identifiant inconnu : introuvable aussi', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        appairage: _foyerA(),
        depart: Routes.ficheEleveSousPage('inconnu', 'interface'),
      );
      expect(_etat(NatureEtat.introuvable), findsOneWidget);
      expect(find.byKey(InterfaceElevePage.choixKey), findsNothing);
    });
  });

  group('Informations et photo', () {
    Future<(GoRouter, FauxServiceAvatar, _AppairagePilote)> monterPhoto(
      WidgetTester tester, {
      PhotoEnfant? photo,
      bool horsLigne = false,
    }) async {
      final _AppairagePilote appairage = _foyerA();
      final GoRouter routeur = await _monter(
        tester,
        appairage: appairage,
        autres: <Override>[
          selecteurPhotoProvider.overrideWithValue(
            FauxSelecteurPhoto(
              photo ?? PhotoEnfant(octets: _png, nomFichier: 'visage.png'),
            ),
          ),
          if (horsLigne)
            horsLigneProvider.overrideWith(
              (Ref ref) => Stream<bool>.value(true),
            ),
        ],
      );
      // Le faux de photos pose par le harnais du routeur (une seule
      // surcharge par provider), relu dans le conteneur.
      final FauxServiceAvatar avatar =
          _conteneur(tester).read(serviceAvatarProvider) as FauxServiceAvatar;
      await _ouvrirFicheA1(tester);
      await _ouvrirLigne(tester, t.ficheEleve.lignes.informations);
      return (routeur, avatar, appairage);
    }

    testWidgets('identite en lecture, sans code interne ni age invente', (
      WidgetTester tester,
    ) async {
      await monterPhoto(tester);
      expect(find.text(t.ficheEleve.informations.prenom), findsOneWidget);
      expect(find.text(t.ficheEleve.informations.identiteNote), findsOneWidget);
      expect(find.text(t.ficheEleve.informations.ageNote), findsOneWidget);
      expect(find.textContaining('STUD-'), findsNothing);
      expect(find.text(t.ficheEleve.informations.photoAucune), findsOneWidget);
    });

    testWidgets('choisir, apercu, envoyer : deux etapes puis photo '
        'enregistree', (WidgetTester tester) async {
      final (_, FauxServiceAvatar avatar, _AppairagePilote appairage) =
          await monterPhoto(tester);

      await _toucher(tester, find.byKey(EditeurPhotoEleve.choisirKey));
      expect(find.byKey(EditeurPhotoEleve.apercuKey), findsOneWidget);
      expect(find.text(t.ficheEleve.informations.apercuTitre), findsOneWidget);
      // Rien n'est parti avant le geste d'envoi.
      expect(avatar.depots, isEmpty);

      await _toucher(tester, find.byKey(EditeurPhotoEleve.envoyerKey));
      expect(avatar.depots, hasLength(1));
      expect(avatar.depots.single.eleveId, a1);
      expect(avatar.depots.single.photo.typeMime, 'image/png');
      expect(appairage.reglagesEcrits.single.cleAvatar, isNotNull);
      // La seule colonne touchee est celle de la photo.
      expect(appairage.reglagesEcrits.single.mode, isNull);
      expect(appairage.reglagesEcrits.single.camera, isNull);
      expect(find.text(t.ficheEleve.informations.succes), findsOneWidget);
      expect(
        find.text(t.ficheEleve.informations.photoPresente),
        findsOneWidget,
      );
      expect(find.text(t.ficheEleve.informations.changer), findsOneWidget);
    });

    testWidgets('annuler l apercu : rien n est envoye', (
      WidgetTester tester,
    ) async {
      final (_, FauxServiceAvatar avatar, _) = await monterPhoto(tester);
      await _toucher(tester, find.byKey(EditeurPhotoEleve.choisirKey));
      await _toucher(tester, find.text(t.ficheEleve.informations.annuler));
      expect(find.byKey(EditeurPhotoEleve.apercuKey), findsNothing);
      expect(avatar.depots, isEmpty);
    });

    testWidgets('photo trop lourde : refus avant tout envoi', (
      WidgetTester tester,
    ) async {
      final (_, FauxServiceAvatar avatar, _) = await monterPhoto(
        tester,
        photo: PhotoEnfant(
          octets: Uint8List(ServiceAvatar.tailleMaximaleOctets + 1),
          nomFichier: 'lourde.jpg',
        ),
      );
      await _toucher(tester, find.byKey(EditeurPhotoEleve.choisirKey));
      expect(
        find.text(t.ficheEleve.informations.tropLourde(taille: '4')),
        findsOneWidget,
      );
      expect(find.byKey(EditeurPhotoEleve.apercuKey), findsNothing);
      expect(avatar.depots, isEmpty);
    });

    testWidgets('echec d envoi puis reprise : la photo choisie est gardee', (
      WidgetTester tester,
    ) async {
      final (_, FauxServiceAvatar avatar, _AppairagePilote appairage) =
          await monterPhoto(tester);
      avatar.erreurAJeter = Exception('reseau');

      await _toucher(tester, find.byKey(EditeurPhotoEleve.choisirKey));
      await _toucher(tester, find.byKey(EditeurPhotoEleve.envoyerKey));
      expect(find.text(t.ficheEleve.informations.echecEnvoi), findsOneWidget);
      expect(appairage.reglagesEcrits, isEmpty);
      expect(find.byKey(EditeurPhotoEleve.apercuKey), findsOneWidget);

      avatar.erreurAJeter = null;
      await _toucher(tester, find.byKey(EditeurPhotoEleve.reprendreKey));
      expect(avatar.depots, hasLength(1));
      expect(appairage.reglagesEcrits, hasLength(1));
      expect(find.text(t.ficheEleve.informations.succes), findsOneWidget);
    });

    testWidgets('echec d enregistrement puis reprise : le fichier n est pas '
        'renvoye', (WidgetTester tester) async {
      final (_, FauxServiceAvatar avatar, _AppairagePilote appairage) =
          await monterPhoto(tester);
      appairage.erreurAJeter = Exception('refus');

      await _toucher(tester, find.byKey(EditeurPhotoEleve.choisirKey));
      await _toucher(tester, find.byKey(EditeurPhotoEleve.envoyerKey));
      expect(
        find.text(t.ficheEleve.informations.echecEnregistrement),
        findsOneWidget,
      );
      expect(avatar.depots, hasLength(1));

      appairage.erreurAJeter = null;
      await _toucher(tester, find.byKey(EditeurPhotoEleve.reprendreKey));
      expect(avatar.depots, hasLength(1), reason: 'aucun second envoi');
      expect(appairage.reglagesEcrits, hasLength(1));
      expect(
        appairage.reglagesEcrits.single.cleAvatar,
        '$a1/1.png',
        reason: 'la cle du premier envoi',
      );
      expect(find.text(t.ficheEleve.informations.succes), findsOneWidget);
    });

    testWidgets('hors ligne : l envoi ne se presse pas, une phrase le dit', (
      WidgetTester tester,
    ) async {
      final (_, FauxServiceAvatar avatar, _) = await monterPhoto(
        tester,
        horsLigne: true,
      );
      await _toucher(tester, find.byKey(EditeurPhotoEleve.choisirKey));
      expect(find.text(t.ficheEleve.informations.horsLigne), findsOneWidget);
      await tester.tap(find.byKey(EditeurPhotoEleve.envoyerKey));
      await stabiliser(tester);
      expect(avatar.depots, isEmpty);
    });
  });

  group('Parcours et inscription', () {
    testWidgets('questionnaire : l etape de l eleve, la ligne ouvre le '
        'questionnaire', (WidgetTester tester) async {
      final GoRouter routeur = await _monter(tester, appairage: _foyerA());
      _offres(tester).parcoursRendu = <ParcoursApprenant>[
        ParcoursApprenant(
          eleveId: a1,
          prenom: 'Eleve A1',
          diagnostic: StatutDiagnostic.nonRequis,
        ),
      ];
      _conteneur(tester).invalidate(parcoursFoyerProvider);
      await _ouvrirFicheA1(tester);
      await _ouvrirLigne(tester, t.ficheEleve.lignes.inscription);

      expect(find.text(t.ficheEleve.inscription.aRemplir), findsOneWidget);
      await _toucher(tester, find.text(t.ficheEleve.inscription.questionnaire));
      expect(lieu(routeur), Routes.parcoursPour(a1));
      expect(find.byType(ParcoursOffresPage), findsOneWidget);
    });

    testWidgets('lecture du parcours en echec : phrase honnete, aucune etape '
        'inventee', (WidgetTester tester) async {
      await _monter(tester, appairage: _foyerA());
      _offres(tester).erreurParcours = Exception('0043 absente');
      _conteneur(tester).invalidate(parcoursFoyerProvider);
      await _ouvrirFicheA1(tester);
      await _ouvrirLigne(tester, t.ficheEleve.lignes.inscription);
      expect(find.text(t.ficheEleve.inscription.etatInconnu), findsOneWidget);
      expect(find.text(t.ficheEleve.inscription.aRemplir), findsNothing);
    });

    testWidgets('classes sans service : la ligne ouvre le choix de classe', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(tester, appairage: _foyerA());
      await _ouvrirFicheA1(tester);
      await _ouvrirLigne(tester, t.ficheEleve.lignes.inscription);

      expect(
        find.text(t.ficheEleve.inscription.classeIndisponible),
        findsOneWidget,
      );
      await _toucher(tester, find.text(t.ficheEleve.inscription.classe));
      expect(lieu(routeur), '${Routes.tuteurClassesCatalogue}?eleve=$a1');
      expect(find.byType(CatalogueClassesPage), findsOneWidget);
    });

    testWidgets('classe connue : son nom, la ligne ouvre la classe', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(
        tester,
        appairage: _foyerA(),
        autres: <Override>[
          portClassesFoyerProvider.overrideWithValue(
            FauxClassesFoyer(
              classes: <ClasseFoyer>[
                ClasseFoyer(eleveId: a1, classe: classeFictive()),
              ],
            ),
          ),
        ],
      );
      await _ouvrirFicheA1(tester);
      // La carte d'identite porte aussi la classe.
      expect(find.text('Classe fictive A'), findsOneWidget);
      await _ouvrirLigne(tester, t.ficheEleve.lignes.inscription);

      expect(find.text('Classe fictive A'), findsOneWidget);
      await _toucher(tester, find.text(t.ficheEleve.inscription.classe));
      expect(lieu(routeur), Routes.classePour('classe-a', eleveId: a1));
      expect(find.byType(ClasseTuteurPage), findsOneWidget);
    });

    testWidgets('eleve sans classe : « Pas encore de classe »', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        appairage: _foyerA(),
        depart: Routes.ficheEleveSousPage(a1, 'inscription'),
        autres: <Override>[
          portClassesFoyerProvider.overrideWithValue(FauxClassesFoyer()),
        ],
      );
      expect(find.text(t.ficheEleve.inscription.classeAucune), findsOneWidget);
    });
  });

  group('Interface', () {
    testWidgets('Interface guidee retenue ; toucher « standard » l ecrit, la '
        'relecture la retient', (WidgetTester tester) async {
      final _AppairagePilote appairage = _foyerA();
      await _monter(tester, appairage: appairage);
      await _ouvrirFicheA1(tester);
      await _ouvrirLigne(tester, t.ficheEleve.lignes.interface);

      bool retenue(String libelle) => tester
          .widget<Semantics>(
            find
                .ancestor(
                  of: find.text(libelle),
                  matching: find.byWidgetPredicate(
                    (Widget w) =>
                        w is Semantics && w.properties.checked != null,
                  ),
                )
                .first,
          )
          .properties
          .checked!;
      expect(find.text(t.ficheEleve.interface.guidee), findsOneWidget);
      expect(find.text(t.ficheEleve.interface.politique), findsOneWidget);

      await _toucher(tester, find.text(t.ficheEleve.interface.standard));
      expect(appairage.reglagesEcrits.single.mode, InterfaceMode.standard);
      expect(appairage.reglagesEcrits.single.camera, isNull);
      expect(
        appairage.elevesRendus.firstWhere((EleveDuFoyer e) => e.id == a1).mode,
        InterfaceMode.standard,
      );
      expect(retenue(t.ficheEleve.interface.standard), isTrue);

      // Toucher l'option deja retenue n'ecrit rien.
      await _toucher(tester, find.text(t.ficheEleve.interface.standard));
      expect(appairage.reglagesEcrits, hasLength(1));

      // De retour sur la fiche, la ligne dit la nouvelle interface.
      await _toucher(tester, find.byType(DisqueRetour));
      expect(find.text(t.ficheEleve.interface.standard), findsOneWidget);
    });

    testWidgets('MA-9 : depuis la coquille du tuteur, la page dit « Mode '
        'Accessibilité » et « Présentation standard », sans age ; toucher la '
        'carte hors de son titre ecrit le choix', (WidgetTester tester) async {
      final _AppairagePilote appairage = _foyerA();
      await _monter(tester, appairage: appairage);
      await _ouvrirFicheA1(tester);
      // La fiche annonce l'etat actuel avec le nouveau terme (K-57).
      expect(find.text('Mode Accessibilité'), findsOneWidget);
      await _ouvrirLigne(tester, t.ficheEleve.lignes.interface);

      // Phrase de contexte en tete, puis une ligne « quand / consequence »
      // par option (K-58).
      expect(
        find.textContaining('Choisissez comment Rewayah s\'affiche'),
        findsOneWidget,
      );
      expect(find.text('Mode Accessibilité'), findsOneWidget);
      expect(find.text('Présentation standard'), findsOneWidget);
      expect(find.textContaining('préfère des écrans aérés'), findsOneWidget);
      expect(find.textContaining('plus denses'), findsOneWidget);
      // MA2 : memes rubriques et memes droits dans les deux presentations.
      expect(find.textContaining('Toutes les rubriques'), findsNothing);
      expect(
        find.textContaining('Mêmes rubriques et mêmes droits'),
        findsNWidgets(2),
      );
      // Ni age, ni ancien terme, ni raison.
      for (final String texte in _textesVisibles(tester)) {
        final String bas = texte.toLowerCase();
        for (final String interdit in <String>[
          'âge',
          ' ans',
          'interface guidée',
          'interface standard',
          'handicap',
          'diagnostic',
        ]) {
          expect(bas.contains(interdit), isFalse, reason: '« $texte »');
        }
      }
      _verifierVocabulaire(tester);

      // La carte entiere se presse : on touche sa description.
      await _toucher(tester, find.textContaining('plus denses'));
      expect(appairage.reglagesEcrits.single.mode, InterfaceMode.standard);
    });

    testWidgets('echec d ecriture : phrase d erreur, aucun changement '
        'affiche', (WidgetTester tester) async {
      final _AppairagePilote appairage = _foyerA()
        ..erreurAJeter = Exception('refus');
      await _monter(
        tester,
        appairage: appairage,
        depart: Routes.ficheEleveSousPage(a1, 'interface'),
      );
      await _toucher(tester, find.text(t.ficheEleve.interface.standard));
      expect(
        find.text(
          t.ficheEleve.interface.echec(prenom: FoyersFictifs.a1.prenom),
        ),
        findsOneWidget,
      );
      expect(
        appairage.elevesRendus.firstWhere((EleveDuFoyer e) => e.id == a1).mode,
        InterfaceMode.enfant,
      );
      expect(appairage.reglagesEcrits, isEmpty);
    });
  });

  group('Camera en cours', () {
    testWidgets('l interrupteur ecrit la politique, la legende suit la '
        'relecture', (WidgetTester tester) async {
      final _AppairagePilote appairage = _foyerA();
      await _monter(tester, appairage: appairage);
      await _ouvrirFicheA1(tester);
      await _ouvrirLigne(tester, t.ficheEleve.lignes.camera);

      expect(
        find.text(t.ficheEleve.camera.interdite(prenom: 'Eleve A1')),
        findsOneWidget,
      );
      expect(find.text(t.ficheEleve.camera.distincte), findsOneWidget);

      await _toucher(tester, find.byKey(CameraElevePage.interrupteurKey));
      expect(appairage.reglagesEcrits.single.camera, CameraPolicy.allowed);
      expect(appairage.reglagesEcrits.single.mode, isNull);
      expect(
        find.text(t.ficheEleve.camera.autorisee(prenom: 'Eleve A1')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Switch>(find.byKey(CameraElevePage.interrupteurKey))
            .value,
        isTrue,
      );
    });

    testWidgets('echec d ecriture : l interrupteur garde la valeur lue', (
      WidgetTester tester,
    ) async {
      final _AppairagePilote appairage = _foyerA()
        ..erreurAJeter = Exception('refus');
      await _monter(
        tester,
        appairage: appairage,
        depart: Routes.ficheEleveSousPage(a1, 'camera'),
      );
      await _toucher(tester, find.byKey(CameraElevePage.interrupteurKey));
      expect(find.text(t.ficheEleve.camera.echec), findsOneWidget);
      expect(
        tester
            .widget<Switch>(find.byKey(CameraElevePage.interrupteurKey))
            .value,
        isFalse,
      );
    });
  });

  group('Acces Rewayah', () {
    Future<void> monterAcces(WidgetTester tester, DateTime? fin) async {
      final _AppairagePilote appairage = _AppairagePilote()
        ..elevesRendus = <EleveDuFoyer>[
          EleveDuFoyer(
            id: 'foyer-c-eleve-1',
            prenom: 'Eleve C1',
            identifiantImmuable: 'STUD-FC-000001',
            mode: InterfaceMode.standard,
            camera: CameraPolicy.forbidden,
            finAcces: fin,
          ),
        ];
      await _monter(tester, appairage: appairage);
      await tester.tap(
        find.descendant(
          of: find.byKey(NavShell.barreBasseKey),
          matching: find.text(t.nav.tuteur.foyer),
        ),
      );
      await stabiliser(tester);
      await _toucher(tester, find.text('Eleve C1'));
      await _ouvrirLigne(tester, t.ficheEleve.lignes.acces);
    }

    String pastille(WidgetTester tester) =>
        tester.widget<StatusPill>(find.byType(StatusPill)).libelle;

    testWidgets('echeance passee : « Expire », jamais valide, aucun motif', (
      WidgetTester tester,
    ) async {
      await monterAcces(tester, DateTime(2026, 9, 1, 12));
      expect(pastille(tester), t.ficheEleve.acces.pastilleExpire);
      expect(
        find.text(t.ficheEleve.acces.expireDepuis(date: '1 septembre 2026')),
        findsOneWidget,
      );
      expect(
        find.text(t.ficheEleve.acces.expirePhrase(prenom: 'Eleve C1')),
        findsOneWidget,
      );
      expect(find.text(t.ficheEleve.acces.detailIndisponible), findsOneWidget);
      expect(find.textContaining('abonnement'), findsNothing);
    });

    testWidgets('echeance a venir : « En cours » et la date', (
      WidgetTester tester,
    ) async {
      await monterAcces(tester, DateTime(2026, 10, 30, 12));
      expect(pastille(tester), t.ficheEleve.acces.pastilleEnCours);
      expect(
        find.text(t.ficheEleve.acces.jusquau(date: '30 octobre 2026')),
        findsOneWidget,
      );
    });

    testWidgets('sans echeance : dit sans echeance', (
      WidgetTester tester,
    ) async {
      await monterAcces(tester, null);
      expect(pastille(tester), t.ficheEleve.acces.pastilleSansEcheance);
      expect(find.text(t.ficheEleve.acces.sansEcheance), findsOneWidget);
    });
  });

  group('Revue du lot B : etats honnetes des pages d ecriture', () {
    List<Override> horsLigne() => <Override>[
      horsLigneProvider.overrideWith((Ref ref) => Stream<bool>.value(true)),
    ];

    testWidgets('camera hors ligne : interrupteur inactif, phrase hors '
        'ligne, aucune ecriture', (WidgetTester tester) async {
      final _AppairagePilote appairage = _foyerA();
      await _monter(
        tester,
        appairage: appairage,
        depart: Routes.ficheEleveSousPage(a1, 'camera'),
        autres: horsLigne(),
      );
      expect(find.byKey(CameraElevePage.horsLigneKey), findsOneWidget);
      expect(find.text(t.ficheEleve.camera.horsLigne), findsOneWidget);
      expect(
        tester
            .widget<Switch>(find.byKey(CameraElevePage.interrupteurKey))
            .onChanged,
        isNull,
      );
      await tester.tap(find.byKey(CameraElevePage.interrupteurKey));
      await stabiliser(tester);
      expect(appairage.reglagesEcrits, isEmpty);
      expect(find.text(t.ficheEleve.camera.echec), findsNothing);
    });

    testWidgets('interface hors ligne : cartes inactives, phrase hors '
        'ligne, aucune ecriture', (WidgetTester tester) async {
      final _AppairagePilote appairage = _foyerA();
      await _monter(
        tester,
        appairage: appairage,
        depart: Routes.ficheEleveSousPage(a1, 'interface'),
        autres: horsLigne(),
      );
      expect(find.byKey(InterfaceElevePage.horsLigneKey), findsOneWidget);
      await tester.tap(find.text(t.ficheEleve.interface.standard));
      await stabiliser(tester);
      expect(appairage.reglagesEcrits, isEmpty);
      expect(
        find.text(
          t.ficheEleve.interface.echec(prenom: FoyersFictifs.a1.prenom),
        ),
        findsNothing,
      );
    });

    testWidgets('selecteur de photo qui leve : refus lisible, rien envoye', (
      WidgetTester tester,
    ) async {
      final _AppairagePilote appairage = _foyerA();
      await _monter(
        tester,
        appairage: appairage,
        autres: <Override>[
          selecteurPhotoProvider.overrideWithValue(_SelecteurQuiLeve()),
        ],
      );
      final FauxServiceAvatar avatar =
          _conteneur(tester).read(serviceAvatarProvider) as FauxServiceAvatar;
      await _ouvrirFicheA1(tester);
      await _ouvrirLigne(tester, t.ficheEleve.lignes.informations);
      await _toucher(tester, find.byKey(EditeurPhotoEleve.choisirKey));

      expect(
        find.text(t.ficheEleve.informations.selectionEchec),
        findsOneWidget,
      );
      expect(find.byKey(EditeurPhotoEleve.apercuKey), findsNothing);
      expect(avatar.depots, isEmpty);
      expect(appairage.reglagesEcrits, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('classes en echec (service present) : « n a pas pu etre '
        'lue », Relire la classe relit', (WidgetTester tester) async {
      final _ClassesEnEchec classes = _ClassesEnEchec(
        classes: <ClasseFoyer>[
          ClasseFoyer(eleveId: a1, classe: classeFictive()),
        ],
      );
      await _monter(
        tester,
        appairage: _foyerA(),
        autres: <Override>[portClassesFoyerProvider.overrideWithValue(classes)],
      );
      await _ouvrirFicheA1(tester);
      await _ouvrirLigne(tester, t.ficheEleve.lignes.inscription);

      expect(find.text(t.ficheEleve.inscription.classeEchec), findsOneWidget);
      expect(
        find.text(t.ficheEleve.inscription.classeIndisponible),
        findsNothing,
      );
      // Le lien relit : une nouvelle lecture part a chaque geste.
      final int avant = classes.lectures;
      await _toucher(tester, find.byKey(InscriptionElevePage.relireClasseKey));
      expect(classes.lectures, greaterThan(avant));
      expect(find.byKey(InscriptionElevePage.relireClasseKey), findsOneWidget);

      // Le service repond de nouveau : le geste suivant rend la classe.
      classes.echoue = false;
      await tester.tap(find.byKey(InscriptionElevePage.relireClasseKey));
      await stabiliser(tester);
      expect(find.text('Classe fictive A'), findsWidgets);
      expect(find.byKey(InscriptionElevePage.relireClasseKey), findsNothing);
    });

    testWidgets('acces : medaillon, titre, echeance et pastille dans UN '
        'rectangle', (WidgetTester tester) async {
      await _monter(tester, appairage: _foyerA());
      await _ouvrirFicheA1(tester);
      await _ouvrirLigne(tester, t.ficheEleve.lignes.acces);

      final Finder carte = find.byKey(AccesElevePage.carteKey);
      expect(carte, findsOneWidget);
      expect(
        find.descendant(
          of: carte,
          matching: find.byKey(AccesElevePage.medaillonKey),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: carte, matching: find.byType(StatusPill)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: carte,
          matching: find.text(t.ficheEleve.acces.ligne(prenom: 'Eleve A1')),
        ),
        findsOneWidget,
      );
    });
  });

  group('Bureau', () {
    testWidgets('1440 : fiche en deux colonnes, parametres a gauche, '
        'appareils a droite', (WidgetTester tester) async {
      final GoRouter routeur = await _monter(
        tester,
        appairage: _foyerA(),
        taille: const Size(1440, 900),
      );
      expect(find.byKey(NavShell.barreBasseKey), findsNothing);
      await _toucher(tester, find.text(t.nav.tuteur.foyer).first);
      await _toucher(tester, find.text('Eleve A1'));
      expect(lieu(routeur), Routes.ficheElevePour(a1));

      final Rect parametres = tester.getRect(
        find.byKey(FicheElevePage.parametresKey),
      );
      final Rect appareils = tester.getRect(
        find.byKey(FicheElevePage.appareilsKey),
      );
      expect(appareils.left, greaterThan(parametres.right));
      expect((appareils.top - parametres.top).abs(), lessThan(1));

      await _toucher(tester, find.text(t.ficheEleve.lignes.informations));
      final Rect identite = tester.getRect(
        find.byKey(InformationsElevePage.identiteKey),
      );
      final Rect photo = tester.getRect(
        find.byKey(InformationsElevePage.photoKey),
      );
      expect(photo.left, greaterThan(identite.right));
      expect(tester.takeException(), isNull);
    });
  });

  // EA-HL-DOUBLE-1c : sombre, Interface guidee et texte x2 de la fiche
  // eleve hors ligne (revue EA-HL-DOUBLE-1-R, m4). Sautees sans CAPTURE_DIR.
  group('Capture EA-HL-DOUBLE-1c', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    for (final (String, Size, ThemeMode, InterfaceMode, bool) cas
        in <(String, Size, ThemeMode, InterfaceMode, bool)>[
          (
            'sans_donnees_390_sombre',
            const Size(390, 844),
            ThemeMode.dark,
            InterfaceMode.standard,
            true,
          ),
          (
            'sans_donnees_390_guidee',
            const Size(390, 844),
            ThemeMode.light,
            InterfaceMode.enfant,
            true,
          ),
          (
            'sans_donnees_1440_clair',
            const Size(1440, 900),
            ThemeMode.light,
            InterfaceMode.standard,
            true,
          ),
          (
            'avec_donnees_390_sombre',
            const Size(390, 844),
            ThemeMode.dark,
            InterfaceMode.standard,
            false,
          ),
          (
            'avec_donnees_390_guidee',
            const Size(390, 844),
            ThemeMode.light,
            InterfaceMode.enfant,
            false,
          ),
        ]) {
      testWidgets(cas.$1, (WidgetTester tester) async {
        await _monter(
          tester,
          appairage: _foyerA()..echoue = cas.$5,
          depart: Routes.ficheEleveSousPage(a1, 'informations'),
          taille: cas.$2,
          mode: cas.$3,
          interface: cas.$4,
          autres: <Override>[
            horsLigneProvider.overrideWith(
              (Ref ref) => Stream<bool>.value(true),
            ),
          ],
        );
        expect(tester.takeException(), isNull);
        if (cas.$5) {
          expectSansDonnees(t.ficheEleve.sansDonnees);
        } else {
          expectAvecDonnees();
        }
        debugPrint(
          'PNG ${await capturerVue(tester, 'ea_hl_double1_fiche_eleve_${cas.$1}')}',
        );
      });
    }
  });

  // EA-HL-DOUBLE-1 (reprise) : captures de preuve de la fiche eleve hors
  // ligne, sans donnees et avec donnees. Sautees sans CAPTURE_DIR.
  group('Capture EA-HL-DOUBLE-1', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    for (final (String, Size, bool) cas in <(String, Size, bool)>[
      ('sans_donnees_390', const Size(390, 844), true),
      ('sans_donnees_320', const Size(320, 900), true),
      ('avec_donnees_390', const Size(390, 844), false),
      ('avec_donnees_1440', const Size(1440, 900), false),
    ]) {
      testWidgets(cas.$1, (WidgetTester tester) async {
        await _monter(
          tester,
          appairage: _foyerA()..echoue = cas.$3,
          depart: Routes.ficheEleveSousPage(a1, 'informations'),
          taille: cas.$2,
          autres: <Override>[
            horsLigneProvider.overrideWith(
              (Ref ref) => Stream<bool>.value(true),
            ),
          ],
        );
        expect(tester.takeException(), isNull);
        if (cas.$3) {
          expectSansDonnees(t.ficheEleve.sansDonnees);
        } else {
          expectAvecDonnees();
        }
        debugPrint(
          'PNG ${await capturerVue(tester, 'ea_hl_double1_fiche_eleve_${cas.$1}_clair')}',
        );
      });
    }
  });
}
