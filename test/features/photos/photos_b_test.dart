// PHOTOS-B (05/11/2026, fiche PHOTOS-PARTOUT du garde-cap, part famille et
// gestion) : chaque portrait lit la photo de la personne par
// `photoPersonneProvider`, jamais une cle copiee. Ici, les ecrans que le
// robot de la pile locale ne parcourt pas, et Comptes au telephone.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/appairage/service_avatar.dart'
    show PhotoEnfant;
import 'package:rewayah_academy/core/capacites/port_beneficiaires_paiement.dart';
import 'package:rewayah_academy/core/comptable/modeles_comptable.dart';
import 'package:rewayah_academy/core/comptable/statuts_comptable.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/photos/photo_personne.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart'
    show sourceSessionProvider;
import 'package:rewayah_academy/core/widgets/avatar_tile.dart';
import 'package:rewayah_academy/features/accueil_eleve/mon_espace_accessibilite.dart';
import 'package:rewayah_academy/features/admin_comptes/comptes_page.dart';
import 'package:rewayah_academy/features/comptable/beneficiaires/carte_profil_paiement.dart';

import '../../support/harnais.dart';

class _FauxPort implements PortPhotos {
  _FauxPort(this.connues);

  final Map<String, SourcePhoto> connues;

  @override
  Future<bool> peutPoserMaPhoto() async => false;

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
  'hakim': const SourcePhoto(seau: 'avatars', cle: 'hakim/1.png'),
  'prof': const SourcePhoto(seau: 'photos_enseignants', cle: 'prof/1.jpg'),
});

const String _urlHakim = 'https://signee.test/avatars/hakim/1.png';
const String _urlProf = 'https://signee.test/photos_enseignants/prof/1.jpg';

Iterable<String?> _urls(WidgetTester tester) => tester
    .widgetList<AvatarTile>(find.byType(AvatarTile))
    .map((AvatarTile a) => a.urlSignee);

class _Comptes implements ServiceComptes {
  const _Comptes(this._liste);

  final List<CompteAdmin> _liste;

  @override
  Future<List<CompteAdmin>> comptes() async => _liste;
}

CompteAdmin _hakim() => CompteAdmin(
  profilId: 'hakim',
  identifiant: 'RA-26-4817',
  prenom: 'Hakim',
  nom: 'Test',
  role: AppRole.student,
  etat: AccountStatus.active,
  inscritLe: DateTime.now().subtract(const Duration(days: 30)),
  accesJusquAu: null,
  foyerId: null,
  piece: EtatPiece.aucune,
  contrats: 0,
  aEnseignant: false,
  enfantsDuFoyer: 0,
);

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  group('Comptes de la direction', () {
    for (final (double largeur, String nom) in <(double, String)>[
      (390, 'telephone'),
      (1440, 'bureau'),
    ]) {
      testWidgets('au $nom : la ligne porte la photo de la personne', (
        WidgetTester tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(largeur, 900);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          hote(
            const ComptesPage(requete: <String, String>{'vue': 'eleves'}),
            surcharges: <Override>[
              serviceComptesProvider.overrideWithValue(
                _Comptes(<CompteAdmin>[_hakim()]),
              ),
              serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
              portPhotosProvider.overrideWithValue(_port),
            ],
          ),
        );
        await tester.pumpAndSettle();
        // Avant PHOTOS-B, au telephone, aucune tuile : le titre de la carte
        // n'etait que du texte.
        expect(_urls(tester), contains(_urlHakim));
      });
    }
  });

  group('Comptable, profil de paiement', () {
    Widget scene(TypeBeneficiaire type, String id) => hote(
      Material(
        child: SingleChildScrollView(
          child: CarteProfilPaiement(
            profil: ProfilPaiementBeneficiaire(
              identite: IdentiteBeneficiaire(
                id: id,
                nom: 'Sayyida Amina',
                type: type,
              ),
              etat: EtatProfilPaiement.aucunMoyen,
            ),
          ),
        ),
      ),
      surcharges: <Override>[portPhotosProvider.overrideWithValue(_port)],
    );

    testWidgets('un enseignant : sa photo, lue par son profil', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(scene(TypeBeneficiaire.enseignant, 'prof'));
      await tester.pumpAndSettle();
      expect(_urls(tester), <String?>[_urlProf]);
    });

    testWidgets('un contractuel, sans profil : ses initiales', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(scene(TypeBeneficiaire.contractuel, 'prof'));
      await tester.pumpAndSettle();
      expect(_urls(tester), <String?>[null]);
    });
  });

  testWidgets('Mon espace guide : la photo de l eleve, par son profil', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hote(
        MonEspaceAccessibilite(
          prenom: 'Hakim',
          modeActif: true,
          onAide: () {},
          personneId: 'hakim',
        ),
        surcharges: <Override>[
          portPhotosProvider.overrideWithValue(_port),
          sourceSessionProvider.overrideWithValue(FausseSourceSession()),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(_urls(tester), contains(_urlHakim));
  });
}
