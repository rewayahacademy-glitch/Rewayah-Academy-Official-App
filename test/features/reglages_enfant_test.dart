import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/appairage/service_avatar.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/matching/service_matching.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/regles/service_regles.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/features/reglages_enfant/reglages_enfant_page.dart';

import '../support/harnais.dart';

EleveDuFoyer _enfant({
  String id = 'e1',
  String prenom = 'Amina',
  InterfaceMode mode = InterfaceMode.enfant,
  CameraPolicy camera = CameraPolicy.forbidden,
  String? cleAvatar,
}) => EleveDuFoyer(
  id: id,
  prenom: prenom,
  identifiantImmuable: 'STUD-AD-000001',
  mode: mode,
  camera: camera,
  cleAvatar: cleAvatar,
);

Affectation _affectation({String eleveId = 'e1'}) => Affectation(
  id: 'a1',
  enseignantId: 't1',
  enseignantPrenom: 'Aminata',
  enseignantIdentifiant: 'TEACH-AD-000001',
  eleveId: eleveId,
  elevePrenom: 'Amina',
  creneau: const Creneau(jour: 2, heure: 17, fuseau: 'Europe/Paris'),
  depuis: DateTime(2026, 9, 1),
);

/// Une fenetre haute : une carte d'enfant porte trois reglages et trois
/// demandes, et un `ListView` ne construit pas ce qui n'est pas visible.
void _fenetreHaute(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 3600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

List<Override> _surcharges({
  required FauxServiceAppairage appairage,
  FauxServicePlanning? planning,
  FauxServiceMatching? matching,
  FauxServiceAvatar? avatar,
  FauxSelecteurPhoto? selecteur,
  FauxServiceRegles? regles,
}) => <Override>[
  serviceAppairageProvider.overrideWithValue(appairage),
  servicePlanningProvider.overrideWithValue(planning ?? FauxServicePlanning()),
  serviceMatchingProvider.overrideWithValue(matching ?? FauxServiceMatching()),
  serviceAvatarProvider.overrideWithValue(avatar ?? FauxServiceAvatar()),
  selecteurPhotoProvider.overrideWithValue(
    selecteur ?? FauxSelecteurPhoto(null),
  ),
  serviceReglesProvider.overrideWithValue(regles ?? FauxServiceRegles()),
];

Future<void> _monter(
  WidgetTester tester, {
  required FauxServiceAppairage appairage,
  FauxServicePlanning? planning,
  FauxServiceMatching? matching,
  FauxServiceAvatar? avatar,
  FauxSelecteurPhoto? selecteur,
  FauxServiceRegles? regles,
}) async {
  _fenetreHaute(tester);
  await tester.pumpWidget(
    hote(
      const ReglagesEnfantPage(),
      surcharges: _surcharges(
        appairage: appairage,
        planning: planning,
        matching: matching,
        avatar: avatar,
        selecteur: selecteur,
        regles: regles,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('TUT-05 : le texte dit la consequence, avec le prenom', () {
    testWidgets('camera interdite : le bouton n apparaitra pas pour l enfant', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        appairage: FauxServiceAppairage()
          ..elevesRendus = <EleveDuFoyer>[_enfant(prenom: 'Ibrahim')],
      );

      // La phrase de la fiche produit, mot pour mot dans son intention : la
      // consequence, pas un libelle abstrait comme « camera : desactivee ».
      expect(
        find.text(t.tuteur.reglages.cameraInterdite(prenom: 'Ibrahim')),
        findsOneWidget,
      );
      expect(
        find.text(t.tuteur.reglages.cameraAutorisee(prenom: 'Ibrahim')),
        findsNothing,
      );
    });

    testWidgets('camera autorisee : la mesure inverse, sur le meme ecran', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        appairage: FauxServiceAppairage()
          ..elevesRendus = <EleveDuFoyer>[
            _enfant(camera: CameraPolicy.allowed),
          ],
      );

      expect(
        find.text(t.tuteur.reglages.cameraAutorisee(prenom: 'Amina')),
        findsOneWidget,
      );
      expect(
        find.text(t.tuteur.reglages.cameraRetirer(prenom: 'Amina')),
        findsOneWidget,
      );
    });

    testWidgets('l ecran dit une fois que rien ne change pendant un cours', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        appairage: FauxServiceAppairage()
          ..elevesRendus = <EleveDuFoyer>[_enfant()],
      );

      expect(find.text(t.tuteur.reglages.intro), findsOneWidget);
    });
  });

  group('TUT-05 : trois colonnes, pas une de plus', () {
    testWidgets('basculer la camera n envoie que la camera', (
      WidgetTester tester,
    ) async {
      final FauxServiceAppairage appairage = FauxServiceAppairage()
        ..elevesRendus = <EleveDuFoyer>[_enfant()];
      await _monter(tester, appairage: appairage);

      await tester.tap(
        find.text(t.tuteur.reglages.cameraAutoriser(prenom: 'Amina')),
      );
      await tester.pumpAndSettle();

      expect(appairage.reglagesEcrits, hasLength(1));
      final ({
        String eleveId,
        InterfaceMode? mode,
        CameraPolicy? camera,
        String? cleAvatar,
      })
      ecrit = appairage.reglagesEcrits.single;
      expect(ecrit.eleveId, 'e1');
      expect(ecrit.camera, CameraPolicy.allowed);
      // Ce qui ne change pas n'est pas envoye : un envoi des trois colonnes a
      // chaque geste ecraserait ce qu'un autre appareil du foyer vient de
      // poser.
      expect(ecrit.mode, isNull);
      expect(ecrit.cleAvatar, isNull);

      // Et l'ecran relit ce que la base a accepte, sans etat local optimiste.
      expect(
        find.text(t.tuteur.reglages.cameraAutorisee(prenom: 'Amina')),
        findsOneWidget,
      );
    });

    testWidgets('basculer le mode n envoie que le mode', (
      WidgetTester tester,
    ) async {
      final FauxServiceAppairage appairage = FauxServiceAppairage()
        ..elevesRendus = <EleveDuFoyer>[_enfant()];
      await _monter(tester, appairage: appairage);

      await tester.tap(
        find.text(t.tuteur.reglages.modePasserStandard(prenom: 'Amina')),
      );
      await tester.pumpAndSettle();

      expect(appairage.reglagesEcrits.single.mode, InterfaceMode.standard);
      expect(appairage.reglagesEcrits.single.camera, isNull);
      expect(
        find.text(t.tuteur.reglages.modeStandard(prenom: 'Amina')),
        findsOneWidget,
      );
    });
  });

  group('TUT-05 : la photo', () {
    testWidgets('une photo choisie est deposee, puis sa cle est ecrite', (
      WidgetTester tester,
    ) async {
      final FauxServiceAppairage appairage = FauxServiceAppairage()
        ..elevesRendus = <EleveDuFoyer>[_enfant()];
      final FauxServiceAvatar avatar = FauxServiceAvatar();
      final FauxSelecteurPhoto selecteur = FauxSelecteurPhoto(
        PhotoEnfant(
          octets: Uint8List.fromList(<int>[1, 2, 3]),
          nomFichier: 'amina.jpg',
        ),
      );

      await _monter(
        tester,
        appairage: appairage,
        avatar: avatar,
        selecteur: selecteur,
      );

      expect(
        find.text(t.tuteur.reglages.photoAucune(prenom: 'Amina')),
        findsOneWidget,
      );
      await tester.tap(find.text(t.tuteur.reglages.photoAjouter));
      await tester.pumpAndSettle();

      // Le depot va bien dans le dossier de l'ENFANT : c'est lui que la policy
      // de stockage compare, pas l'identifiant du tuteur.
      expect(avatar.depots.single.eleveId, 'e1');
      // Et la cle rendue est ecrite par le seul chemin qui touche aux trois
      // colonnes.
      expect(
        appairage.reglagesEcrits.single.cleAvatar,
        '${avatar.depots.single.eleveId}/1.jpg',
      );
      expect(
        find.text(t.tuteur.reglages.photoPresente(prenom: 'Amina')),
        findsOneWidget,
      );
    });

    testWidgets('une photo trop lourde est refusee avant d etre envoyee', (
      WidgetTester tester,
    ) async {
      final FauxServiceAvatar avatar = FauxServiceAvatar();
      final FauxSelecteurPhoto selecteur = FauxSelecteurPhoto(
        PhotoEnfant(
          octets: Uint8List(ServiceAvatar.tailleMaximaleOctets + 1),
          nomFichier: 'enorme.png',
        ),
      );

      await _monter(
        tester,
        appairage: FauxServiceAppairage()
          ..elevesRendus = <EleveDuFoyer>[_enfant()],
        avatar: avatar,
        selecteur: selecteur,
      );

      await tester.tap(find.text(t.tuteur.reglages.photoAjouter));
      await tester.pumpAndSettle();

      // Rien n'est monte : le refus se dit avant l'envoi, pas apres quatre
      // mega-octets sur une connexion de telephone.
      expect(avatar.depots, isEmpty);
      expect(
        find.textContaining(t.tuteur.reglages.photoTropLourde(taille: '4')),
        findsOneWidget,
      );
    });

    testWidgets('un abandon du selecteur ne change rien', (
      WidgetTester tester,
    ) async {
      final FauxServiceAppairage appairage = FauxServiceAppairage()
        ..elevesRendus = <EleveDuFoyer>[_enfant()];
      final FauxServiceAvatar avatar = FauxServiceAvatar();

      await _monter(
        tester,
        appairage: appairage,
        avatar: avatar,
        selecteur: FauxSelecteurPhoto(null),
      );

      await tester.tap(find.text(t.tuteur.reglages.photoAjouter));
      await tester.pumpAndSettle();

      expect(avatar.depots, isEmpty);
      expect(appairage.reglagesEcrits, isEmpty);
    });
  });

  group('TUT-05 : les demandes du tuteur', () {
    testWidgets('sans enseignant, la reaffectation n est pas proposee', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        appairage: FauxServiceAppairage()
          ..elevesRendus = <EleveDuFoyer>[_enfant()],
      );

      // Un bouton qui ne peut pas aboutir n'est pas rendu : la base refuserait
      // « cet eleve n'a pas d'enseignant a changer » APRES le geste.
      expect(find.text(t.tuteur.reglages.demandeReaffectation), findsNothing);
      expect(
        find.text(t.tuteur.reglages.demandeSansEnseignant(prenom: 'Amina')),
        findsOneWidget,
      );
      // Les deux demandes de regle, elles, restent proposees.
      expect(find.text(t.tuteur.reglages.demandeDuree), findsOneWidget);
      expect(find.text(t.tuteur.reglages.demandeMinimum), findsOneWidget);
    });

    testWidgets('avec un enseignant, la reaffectation part avec son motif', (
      WidgetTester tester,
    ) async {
      final FauxServiceMatching matching = FauxServiceMatching();
      await _monter(
        tester,
        appairage: FauxServiceAppairage()
          ..elevesRendus = <EleveDuFoyer>[_enfant()],
        planning: FauxServicePlanning()
          ..affectationsRendues = <Affectation>[_affectation()],
        matching: matching,
      );

      await tester.tap(find.text(t.tuteur.reglages.demandeReaffectation));
      await tester.pumpAndSettle();

      expect(
        find.text(t.tuteur.reglages.demandeTitreReaffectation(prenom: 'Amina')),
        findsOneWidget,
      );
      // Sans motif, le bouton n'aboutit pas : la base refuse une demande sans
      // lui, et l'ecran ne fait pas semblant.
      final Finder envoyer = find.widgetWithText(
        ActionPrincipale,
        t.tuteur.reglages.demandeEnvoyer,
      );
      expect(tester.widget<ActionPrincipale>(envoyer).onPress, isNull);

      await tester.enterText(find.byType(TextField), 'Horaire impossible');
      await tester.pumpAndSettle();
      await tester.tap(envoyer);
      await tester.pumpAndSettle();

      expect(matching.demandes, hasLength(1));
      expect(matching.demandes.single.sorte, SorteDemande.reaffectation);
      expect(matching.demandes.single.sujetId, 'e1');
      expect(matching.demandes.single.motif, 'Horaire impossible');
      expect(matching.demandes.single.valeur, isNull);
      expect(find.text(t.tuteur.reglages.demandeEnvoyee), findsOneWidget);
    });

    testWidgets('une demande de duree porte la valeur choisie', (
      WidgetTester tester,
    ) async {
      final FauxServiceMatching matching = FauxServiceMatching();
      // La valeur qui s'applique DEJA a cet enfant, lue par `regle_effective()`
      // et non par une constante : elle peut differer de celle de la
      // plateforme.
      final FauxServiceRegles regles = FauxServiceRegles()
        ..parProfil['e1'] = const <RegleProfil>[
          RegleProfil(
            cle: CleRegle.dureeSeance,
            valeurEffective: 45,
            valeurPlateforme: 60,
          ),
        ];

      await _monter(
        tester,
        appairage: FauxServiceAppairage()
          ..elevesRendus = <EleveDuFoyer>[_enfant()],
        matching: matching,
        regles: regles,
      );

      await tester.tap(find.text(t.tuteur.reglages.demandeDuree));
      await tester.pumpAndSettle();

      expect(
        find.text(t.tuteur.reglages.demandeActuelle(minutes: '45')),
        findsOneWidget,
      );

      await tester.tap(
        find.text(t.tuteur.reglages.demandeMinutes(minutes: '30')),
      );
      await tester.enterText(find.byType(TextField).first, 'Elle decroche');
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(ActionPrincipale, t.tuteur.reglages.demandeEnvoyer),
      );
      await tester.pumpAndSettle();

      expect(matching.demandes.single.sorte, SorteDemande.regle);
      expect(matching.demandes.single.valeur, 30);
    });
  });
}
