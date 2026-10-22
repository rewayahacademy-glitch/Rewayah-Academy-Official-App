// Le harnais de CAND-06 : la page de partage (`/attente/partage`) ou le portail
// (`/attente`) montes sur un routeur de test, avec les doubles du menu de
// partage, de l'enregistrement et du rendu de la carte.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/partage_offre/lien_offre.dart';
import 'package:rewayah_academy/core/partage_offre/personnalisation_carte.dart';
import 'package:rewayah_academy/core/partage_offre/port_genre_partageur.dart';
import 'package:rewayah_academy/core/partage_offre/port_partage_offre.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/tc_telechargement/port_enregistrement_fichier.dart';
import 'package:rewayah_academy/features/dossier/attente_page.dart';
import 'package:rewayah_academy/features/partage_offre/partage_offre_page.dart';
import 'package:rewayah_academy/features/partage_offre/rendu_carte.dart';

import '../../fixtures/partage_offre/faux_partage_offre.dart';
import '../../support/harnais.dart';
import '../candidature/hote_candidature.dart';

/// Les mots qui nomment l'academie. **Jamais le motif d'un texte de CAND-06**
/// (consigne du directeur du 22/10/2026, apres coup : « il ne faut pas dire
/// faites ca pour Rewayah Academy ») : les textes parlent de la personne qui
/// apprendra, de ce qu'elle y gagne, et du geste de celui qui partage.
const List<String> motsQuiNommentLAcademie = <String>[
  'Rewayah',
  'Académie',
  'Academy',
  'أكاديمية',
  'الأكاديمية',
  'الرواية',
];

/// Le lien de l'offre des tests.
final Uri lienDeTest = Uri.parse('https://rewayah.test/fr/');

/// Les routes de test : le portail et la page de partage.
List<RouteBase> routesPartage() => <RouteBase>[
  GoRoute(
    path: Routes.attente,
    builder: (BuildContext _, GoRouterState _) => const AttentePage(),
  ),
  GoRoute(
    path: Routes.attentePartage,
    builder: (BuildContext _, GoRouterState _) => const PartageOffrePage(),
  ),
];

/// Les doubles d'une page montee, pour que le test les lise.
class MontagePartage {
  /// Cree le montage.
  MontagePartage({
    required this.partage,
    required this.enregistrement,
    required this.rendu,
    required this.dossier,
  });

  /// Le menu de partage de l'appareil.
  final FauxPartageOffre partage;

  /// L'enregistrement de l'image.
  final FauxEnregistrementImage enregistrement;

  /// Le rendu de la carte.
  final FauxRenduCarte rendu;

  /// Le service de dossier.
  final FauxServiceDossier dossier;
}

/// Les surcharges communes.
List<Override> surchargesPartage({
  required FauxPartageOffre partage,
  required FauxEnregistrementImage enregistrement,
  required FauxRenduCarte? rendu,
  required FauxServiceDossier dossier,
  required Uri? lien,
  FauxGenrePartageur? genre,
  List<String> langues = const <String>[],
  bool horsLigne = false,
}) => <Override>[
  serviceDossierProvider.overrideWithValue(dossier),
  sourceSessionProvider.overrideWithValue(FausseSourceSession()),
  serviceReseauProvider.overrideWithValue(
    FauxServiceReseau(horsLigneRendu: horsLigne),
  ),
  lienOffreProvider.overrideWithValue(lien),
  portGenrePartageurProvider.overrideWithValue(genre ?? FauxGenrePartageur()),
  languesEnseignementCandidatProvider.overrideWith((Ref ref) async => langues),
  portPartageOffreProvider.overrideWithValue(partage),
  portEnregistrementFichierProvider.overrideWithValue(enregistrement),
  if (rendu != null) renduCarteProvider.overrideWithValue(rendu.rendre),
];

/// Monte la page de partage (ou, avec [depart], le portail) pour une
/// candidature. Par defaut : une candidature en cours, un lien, un menu de
/// partage qui accepte l'image, un rendu qui rend tout de suite.
Future<MontagePartage> monterPartage(
  WidgetTester tester, {
  CandidatureDossier? candidature,
  Uri? lien,
  bool sansLien = false,
  NiveauPartage niveau = NiveauPartage.image,
  String depart = Routes.attentePartage,
  Size taille = const Size(390, 844),
  double echelle = 1,
  TextDirection? direction,
  ThemeMode themeMode = ThemeMode.light,
  bool horsLigne = false,
  FauxRenduCarte? rendu,
  bool vraiRendu = false,
  FauxServiceDossier? dossier,
  FauxPartageOffre? partage,
  Genre? genre,
  FauxGenrePartageur? lectureGenre,
  List<String> langues = const <String>[],
  bool attendre = true,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final FauxPartageOffre menu = partage ?? FauxPartageOffre(niveau: niveau);
  final FauxEnregistrementImage enregistrement = FauxEnregistrementImage();
  final FauxRenduCarte faux = rendu ?? FauxRenduCarte();
  final FauxServiceDossier service =
      dossier ??
      (FauxServiceDossier()
        ..etatRendu = etatCandidat(
          candidature: candidature ?? candidatureAFaire(),
        ));
  await tester.pumpWidget(
    hoteRoutant(
      depart: depart,
      routes: routesPartage(),
      echelle: echelle,
      direction: direction,
      themeMode: themeMode,
      surcharges: surchargesPartage(
        partage: menu,
        enregistrement: enregistrement,
        rendu: vraiRendu ? null : faux,
        dossier: service,
        lien: sansLien ? null : lien ?? lienDeTest,
        genre: lectureGenre ?? FauxGenrePartageur(genre: genre),
        langues: langues,
        horsLigne: horsLigne,
      ),
    ),
  );
  if (attendre) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  return MontagePartage(
    partage: menu,
    enregistrement: enregistrement,
    rendu: faux,
    dossier: service,
  );
}

/// Ce que le presse-papiers a recu, et un moyen de le faire echouer.
class PressePapiersDeTest {
  /// Branche le faux presse-papiers sur [tester].
  PressePapiersDeTest(WidgetTester tester, {this.echec = false}) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall appel) async {
        if (appel.method == 'Clipboard.setData') {
          if (echec) {
            throw PlatformException(code: 'refus');
          }
          copies.add(
            (appel.arguments as Map<Object?, Object?>)['text']! as String,
          );
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
  }

  /// Vrai pour que la copie echoue.
  bool echec;

  /// Les textes copies.
  final List<String> copies = <String>[];
}

/// Les textes affiches (`Text` et `SelectableText`) de l'arbre courant.
List<String> textesAffiches(WidgetTester tester) => <String>[
  for (final Text w in tester.widgetList<Text>(find.byType(Text)))
    if (w.data != null) w.data!,
  for (final SelectableText w in tester.widgetList<SelectableText>(
    find.byType(SelectableText),
  ))
    if (w.data != null) w.data!,
];
