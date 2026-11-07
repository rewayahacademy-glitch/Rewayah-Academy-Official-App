// PHOTOS-2b (04/11/2026, PLAN-LOTS §11) : la meme photo dans les ecrans qui
// restaient (cartes, espace de classe, cahier, messages, communaute), par le
// fournisseur unique ; et le Compte qui dit le prenom, jamais « Eleve ».

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/appairage/service_avatar.dart';
import 'package:rewayah_academy/core/capacites/port_identite_titulaire.dart';
import 'package:rewayah_academy/core/communications/communications_supabase.dart';
import 'package:rewayah_academy/core/communications/libelles_communication_slang.dart';
import 'package:rewayah_academy/core/communications/modeles_communication.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/photos/photo_personne.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/tc_groupe/group_summary_vm.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/avatar_nom.dart';
import 'package:rewayah_academy/core/widgets/avatar_tile.dart';
import 'package:rewayah_academy/features/compte/compte_page.dart';
import 'package:rewayah_academy/features/compte/ma_photo.dart';
import 'package:rewayah_academy/features/tc_mes_groupes/photo_enseignant.dart';

import '../../support/harnais.dart';

class _FauxPort implements PortPhotos {
  _FauxPort(this.connues, {this.capacite});

  final Map<String, SourcePhoto> connues;

  /// La capacite « poser sa photo » rendue (PHOTO-CAPACITE) ; `null` : non.
  final Future<bool> Function()? capacite;

  @override
  Future<bool> peutPoserMaPhoto() =>
      capacite?.call() ?? Future<bool>.value(false);

  @override
  Future<Map<String, SourcePhoto>> sources(List<String> profileIds) async =>
      <String, SourcePhoto>{
        for (final String id in profileIds)
          if (connues[id] case final SourcePhoto s) id: s,
      };

  @override
  Future<String> urlSignee(String seau, String cle) async =>
      'https://signee.test/$seau/$cle';

  @override
  Future<String> televerser({
    required String profileId,
    required String seau,
    required PhotoEnfant photo,
  }) async => '$profileId/1.${photo.extension}';

  @override
  Future<SourcePhoto?> poserMaPhoto(String? cle) async => null;

  @override
  Future<SourcePhoto?> poserPhotoEleve(String eleveId, String? cle) async =>
      null;

  @override
  Future<SourcePhoto?> poserPhotoCandidat(String? cle) async => null;
}

final _FauxPort _port = _FauxPort(<String, SourcePhoto>{
  'prof': const SourcePhoto(seau: 'photos_enseignants', cle: 'prof/1.jpg'),
});

const String _urlProf = 'https://signee.test/photos_enseignants/prof/1.jpg';

EnseignantVM _enseignant({String? cle}) => EnseignantVM(
  enseignantId: 'prof',
  titre: TitreEnseignant.sayyida,
  nomAffichage: 'Amina',
  photoUrlOuCle: cle,
);

String? _urlAffichee(WidgetTester tester) =>
    tester.widget<AvatarTile>(find.byType(AvatarTile)).urlSignee;

class _Identite implements PortIdentiteTitulaire {
  const _Identite(this.identite);

  final IdentiteTitulaire? identite;

  @override
  Future<IdentiteTitulaire> lire() async =>
      identite ?? (throw StateError('lecture refusee'));

  @override
  Future<void> modifier({String? prenom, String? nom}) async {}
}

void main() {
  group('PhotoEnseignant lit le fournisseur unique', () {
    Widget scene(Widget enfant) => hote(
      Material(child: enfant),
      surcharges: <Override>[portPhotosProvider.overrideWithValue(_port)],
    );

    testWidgets('sans URL fournie par l hote : la photo de la personne', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        scene(PhotoEnseignant(enseignant: _enseignant(cle: 'prof/1.jpg'))),
      );
      await tester.pumpAndSettle();
      expect(_urlAffichee(tester), _urlProf);
    });

    testWidgets('en repli (famille) : lue meme sans cle dans la vue', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        scene(PhotoEnseignant(enseignant: _enseignant(), repliInitiales: true)),
      );
      await tester.pumpAndSettle();
      expect(_urlAffichee(tester), _urlProf);
    });

    // PHOTOS-A (04/11/2026) : « Photo a fournir » se decide sur la source
    // unique, jamais sur la cle lue au chargement.
    testWidgets('source sans photo, hors repli : l etat explicite (D-01)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        scene(
          const PhotoEnseignant(
            enseignant: EnseignantVM(
              enseignantId: 'sans-photo',
              titre: TitreEnseignant.sayyid,
              nomAffichage: 'Karim',
              // Une cle lue au chargement ne suffit pas : la source dit non.
              photoUrlOuCle: 'perimee/1.jpg',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AvatarTile), findsNothing);
    });

    testWidgets('la source a une photo : plus de « Photo a fournir »', (
      WidgetTester tester,
    ) async {
      // La vue lue au chargement n'avait pas de cle (photoManquante) ; la
      // photo posee depuis s'affiche quand meme.
      await tester.pumpWidget(
        scene(PhotoEnseignant(enseignant: _enseignant())),
      );
      await tester.pumpAndSettle();
      expect(_urlAffichee(tester), _urlProf);
    });

    testWidgets('une URL copiee par l hote est ignoree : la source decide', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        scene(
          PhotoEnseignant(
            enseignant: _enseignant(cle: 'prof/1.jpg'),
            urlSignee: 'https://hote.test/x.jpg',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_urlAffichee(tester), _urlProf);
    });

    testWidgets('hors ProviderScope : les initiales, sans erreur', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          home: Material(
            child: PhotoEnseignant(enseignant: _enseignant(cle: 'prof/1.jpg')),
          ),
        ),
      );
      expect(_urlAffichee(tester), isNull);
      expect(tester.takeException(), isNull);
    });
  });

  group('Messages et communaute : la personne porte son profil', () {
    const LibellesCommunication libelles = LibellesCommunicationSlang();

    test('une personne (nature profil) : son identifiant de profil', () {
      final Participant p = participantJson(<String, dynamic>{
        'id': 'prof',
        'nature': 'profil',
        'fonction': 'enseignant',
        'prenom': 'Amina',
      }, libelles);
      expect(p.profilId, 'prof');
    });

    test('l Administration et une famille : aucun profil, les initiales', () {
      expect(
        participantJson(<String, dynamic>{
          'id': 'equipe',
          'nature': 'equipe',
        }, libelles).profilId,
        isNull,
      );
      expect(
        participantJson(<String, dynamic>{
          'id': 'f1',
          'nature': 'foyer',
          'eleves': <String>['Hakim'],
        }, libelles).profilId,
        isNull,
      );
    });
  });

  group('Compte : le prenom, jamais « Eleve » a sa place', () {
    List<Override> surcharges({
      IdentiteTitulaire? identite,
      InterfaceMode mode = InterfaceMode.standard,
      Future<bool> Function()? capacite,
    }) => <Override>[
      portPhotosProvider.overrideWithValue(
        _FauxPort(const <String, SourcePhoto>{}, capacite: capacite),
      ),
      sourceSessionProvider.overrideWithValue(
        FausseSourceSession(
          SessionState(
            resolue: true,
            role: AppRole.student,
            profileId: 'p1',
            accountStatus: AccountStatus.active,
            interfaceMode: mode,
          ),
        ),
      ),
      if (identite != null)
        portIdentiteTitulaireProvider.overrideWithValue(_Identite(identite)),
    ];

    testWidgets('le prenom lu dans le profil', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        hote(
          const ComptePage(),
          surcharges: surcharges(
            capacite: () async => true,
            identite: const IdentiteTitulaire(
              prenom: 'Hakim',
              nom: 'Ba',
              methodeConnexion: MethodeConnexion.inconnue,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // L'en-tete (le premier couple photo + nom) dit le prenom.
      final AvatarNom entete = tester.widget<AvatarNom>(
        find.byType(AvatarNom).first,
      );
      expect(entete.prenom, 'Hakim');
      // La ligne du dessous : « {role} · {statut} », des mots existants.
      expect(
        entete.role,
        LibellesGroupe.joindre(t.compte.roles.student, t.compte.statutActif),
      );
      expect(find.text('Hakim'), findsWidgets);
      // La capacite servie dit oui : la personne pose sa photo.
      expect(find.byKey(LienMaPhoto.choisirKey), findsOneWidget);
    });

    // PHOTO-CAPACITE : le lien se lit sur la capacite servie, jamais sur un
    // role ni sur l'Interface guidee ; il n'est propose que sur un oui lu.
    for (final (
          String cas,
          InterfaceMode mode,
          Future<bool> Function() capacite,
        )
        in <(String, InterfaceMode, Future<bool> Function())>[
          (
            'eleve mineur en Interface guidee : le serveur dit non',
            InterfaceMode.enfant,
            () async => false,
          ),
          (
            'eleve mineur hors Interface guidee : le serveur dit non',
            InterfaceMode.standard,
            () async => false,
          ),
          (
            'lecture en erreur : rien n est propose',
            InterfaceMode.standard,
            () async => throw StateError('lecture refusee'),
          ),
          (
            'reponse pas encore lue : rien n est propose',
            InterfaceMode.standard,
            () => Completer<bool>().future,
          ),
        ]) {
      testWidgets('$cas : pas de « Choisir une photo »', (
        WidgetTester tester,
      ) async {
        tester.view.physicalSize = const Size(390, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          hote(
            const ComptePage(),
            mode: mode,
            surcharges: surcharges(
              mode: mode,
              capacite: capacite,
              identite: const IdentiteTitulaire(
                prenom: 'Hakim',
                nom: 'Ba',
                methodeConnexion: MethodeConnexion.inconnue,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Hakim'), findsWidgets);
        expect(find.byKey(LienMaPhoto.choisirKey), findsNothing);
        expect(find.text(t.ficheEleve.informations.choisir), findsNothing);
      });
    }
  });

  test(
    'Compte : une lecture refusee rend null, sans nouvelle tentative',
    () async {
      final ProviderContainer c = ProviderContainer(
        overrides: <Override>[
          sourceSessionProvider.overrideWithValue(
            FausseSourceSession(
              const SessionState(
                resolue: true,
                role: AppRole.student,
                profileId: 'p1',
                accountStatus: AccountStatus.active,
              ),
            ),
          ),
          portIdentiteTitulaireProvider.overrideWithValue(
            const _Identite(null),
          ),
        ],
      );
      addTearDown(c.dispose);
      final ProviderSubscription<AsyncValue<String?>> abonnement = c.listen(
        prenomDuCompteProvider,
        (_, _) {},
      );
      addTearDown(abonnement.close);
      expect(await c.read(prenomDuCompteProvider.future), isNull);
    },
  );
}
