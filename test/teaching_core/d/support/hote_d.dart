import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3 : il vit
// dans `misc.dart`, meme convention que `test/support/harnais.dart`.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_outils/ancrage_annotation.dart';
import 'package:rewayah_academy/core/tc_outils/port_dock_hote.dart';
import 'package:rewayah_academy/core/tc_outils/ports_externes/content_position.dart';
import 'package:rewayah_academy/core/tc_outils/ports_externes/library_resource.dart';
import 'package:rewayah_academy/core/tc_outils/ports_externes/port_realtime_pedagogique.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';

/// L'hote minimal d'un widget du lot D.
///
/// Le theme est indispensable : `AppPalette.of` et `AppMetriques.of` lisent des
/// extensions de theme, et un widget monte sans elles echoue avant d'avoir
/// rendu quoi que ce soit. `TranslationProvider` l'est aussi des qu'une feuille
/// s'ouvre : `ChoiceCardGroup` lit un libelle slang pour sa carte « Autre ».
Widget hoteD(
  Widget enfant, {
  List<Override> surcharges = const <Override>[],
  InterfaceMode mode = InterfaceMode.standard,
}) => ProviderScope(
  overrides: surcharges,
  child: hoteSansScope(enfant, mode: mode),
);

/// Le meme hote, sans `ProviderScope`.
///
/// A employer quand le test doit tenir son propre `ProviderContainer` : armer
/// un outil avant le premier rendu, par exemple.
Widget hoteSansScope(
  Widget enfant, {
  InterfaceMode mode = InterfaceMode.standard,
}) => TranslationProvider(
  child: MaterialApp(
    theme: AppTheme.pour(mode, Brightness.light),
    home: Scaffold(body: enfant),
  ),
);

/// L'identifiant de la ressource employee par les tests.
const String ressourceTest = 'res-coran';

/// La position du premier verset de la Fatiha.
ContentPosition get ayah1 =>
    const ContentPosition.ayah(resourceId: ressourceTest, sourate: 1, ayah: 1);

/// La position du deuxieme verset de la Fatiha.
ContentPosition get ayah2 =>
    const ContentPosition.ayah(resourceId: ressourceTest, sourate: 1, ayah: 2);

/// La page courante, ancrage spatial de repli.
ContentPosition get pageCourante =>
    const ContentPosition.page(resourceId: ressourceTest, page: 1);

/// Un support presente, avec deux versets places.
///
/// [rectAyah1] et [rectAyah2] permettent de rejouer le meme support **apres une
/// recomposition** : c'est le coeur du test d'ancrage.
SupportPresente supportTest({
  ModeAffichagePartage mode = ModeAffichagePartage.verse,
  Rect rectAyah1 = const Rect.fromLTWH(0, 0, 200, 40),
  Rect rectAyah2 = const Rect.fromLTWH(0, 40, 200, 40),
  Rect cadre = const Rect.fromLTWH(0, 0, 200, 400),
  Set<CapaciteRessource> capacites = const <CapaciteRessource>{
    CapaciteRessource.focusable,
    CapaciteRessource.annotatable,
    CapaciteRessource.assignable,
    CapaciteRessource.selectable,
    CapaciteRessource.supportsStylus,
    CapaciteRessource.presentableInClass,
  },
}) => SupportPresente(
  resourceId: ressourceTest,
  capacites: capacites,
  modeAffichage: mode,
  ancrageCadre: pageCourante,
  blocs: CarteDesBlocs(
    cadre: cadre,
    blocs: <ContentPosition, Rect>{ayah1: rectAyah1, ayah2: rectAyah2},
  ),
);
