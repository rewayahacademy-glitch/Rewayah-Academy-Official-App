// PHOTO-CANDIDATURE-FIGEE (07/11/2026) : la fiche de candidature de la
// direction montre la photo envoyee avec la candidature (figee a l'envoi des
// reponses), jamais la photo d'affichage du jour.

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart';
import 'package:rewayah_academy/core/candidature/photo_dossier_candidat.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/photos/photo_personne.dart';
import 'package:rewayah_academy/core/widgets/avatar_tile.dart';
import 'package:rewayah_academy/features/admin_candidature/blocs_candidature.dart';
import 'package:rewayah_academy/features/admin_candidatures/libelles_candidatures.dart';

import '../../fixtures/candidature/faux_candidatures_direction.dart';
import 'hote_candidature.dart';

class _Dossier implements PortPhotoDossier {
  _Dossier(this.reponse);

  final Future<PhotoDossier> Function() reponse;
  final List<String> lus = <String>[];

  @override
  Future<PhotoDossier> lire(String candidatureId) {
    lus.add(candidatureId);
    return reponse();
  }
}

class _Photos extends PhotosNeutres {
  const _Photos();

  @override
  Future<String> urlSignee(String seau, String cle) async =>
      'https://photos.exemple/$seau/$cle';
}

FauxCandidaturesDirection _port() =>
    FauxCandidaturesDirection(details: <DetailCandidature>[detailTest()]);

void main() {
  final DateTime figee = DateTime.utc(2026, 11, 7, 9, 30);

  test('lecture du serveur : la cle figee, ou rien', () {
    final PhotoDossier p = photoDossierDepuis(<String, Object?>{
      'seau': 'photos_enseignants',
      'cle': 'p1/1.jpg',
      'figeeLe': '2026-11-07T09:30:00Z',
    });
    expect(p.cle, 'p1/1.jpg');
    expect(p.figeeLe, figee);
    expect(
      photoDossierDepuis(<String, Object?>{
        'seau': 'photos_enseignants',
        'cle': null,
      }).cle,
      isNull,
    );
    expect(
      photoDossierDepuis(<String, Object?>{'erreur': 'hors_portee'}).cle,
      isNull,
    );
  });

  testWidgets('la photo du dossier, et quand elle a ete gardee', (
    WidgetTester tester,
  ) async {
    final _Dossier dossier = _Dossier(
      () async => PhotoDossier(
        seau: 'photos_enseignants',
        cle: 'p1/1.jpg',
        figeeLe: figee,
      ),
    );
    await monterCandidature(
      tester,
      port: _port(),
      surcharges: <Override>[
        portPhotoDossierProvider.overrideWithValue(dossier),
        portPhotosProvider.overrideWithValue(const _Photos()),
      ],
    );
    expect(find.byKey(BlocPhotoDossier.cle), findsOneWidget);
    expect(dossier.lus, <String>['c1']);
    expect(find.text(t.admin.candidatures.detail.photo.titre), findsOneWidget);
    final AvatarTile avatar = tester.widget<AvatarTile>(
      find.descendant(
        of: find.byKey(BlocPhotoDossier.cle),
        matching: find.byType(AvatarTile),
      ),
    );
    expect(
      avatar.urlSignee,
      'https://photos.exemple/photos_enseignants/p1/1.jpg',
    );
    expect(
      find.text(
        t.admin.candidatures.detail.photo.figeeLe(
          date: dateCourteCandidature(figee),
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('aucune photo envoyee : la phrase le dit', (
    WidgetTester tester,
  ) async {
    await monterCandidature(
      tester,
      port: _port(),
      surcharges: <Override>[
        portPhotoDossierProvider.overrideWithValue(
          _Dossier(() async => const PhotoDossier(seau: 'photos_enseignants')),
        ),
        portPhotosProvider.overrideWithValue(const _Photos()),
      ],
    );
    expect(find.text(t.admin.candidatures.detail.photo.aucune), findsOneWidget);
  });

  testWidgets('lecture en echec : l etat le dit', (WidgetTester tester) async {
    int essais = 0;
    await monterCandidature(
      tester,
      port: _port(),
      surcharges: <Override>[
        portPhotoDossierProvider.overrideWithValue(
          _Dossier(() async {
            essais++;
            throw StateError('panne');
          }),
        ),
        portPhotosProvider.overrideWithValue(const _Photos()),
      ],
    );
    expect(find.text(t.admin.candidatures.detail.photo.echec), findsOneWidget);
    expect(essais, 1);
  });

  testWidgets('sans source serveur : le bloc ne dit rien de faux', (
    WidgetTester tester,
  ) async {
    await monterCandidature(
      tester,
      port: _port(),
      surcharges: <Override>[
        portPhotoDossierProvider.overrideWithValue(
          _Dossier(
            () => Future<PhotoDossier>.error(const CapaciteIndisponible('x')),
          ),
        ),
      ],
    );
    expect(find.text(t.admin.candidatures.detail.photo.aucune), findsNothing);
    expect(find.text(t.admin.candidatures.detail.photo.echec), findsNothing);
  });
}
