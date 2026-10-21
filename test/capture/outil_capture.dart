// Outil de capture d'ecran fidele, pour comparer l'implementation aux
// maquettes du directeur (recette C11 du chantier Tuteur V1, prototype
// `pilotage-tuteur-v1/02_code/capture_proto`, integre en phase 0c1).
//
// Ce que l'outil prouve : un PNG rendu avec les VRAIES polices et icones du
// depot, a une taille de vue fixee, sous le vrai theme. Ce qu'il ne prouve
// pas : la fidelite a une maquette (c'est la lecture de la planche qui le
// dit), ni un service branche, ni un parcours.
//
// **Jamais execute sans `CAPTURE_DIR`** : sans cette variable, les groupes de
// capture sont sautes (`sautSansCapture`), donc la CI ne les lance pas et
// n'ecrit rien sur le disque. Mode d'emploi : `test/capture/LISEZ-MOI.md`.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';

/// Le dossier de sortie des PNG, ou `null` quand la capture est desactivee.
final String? dossierCapture = () {
  final String? brut = Platform.environment['CAPTURE_DIR'];
  return brut == null || brut.trim().isEmpty ? null : brut;
}();

/// A passer au `skip:` d'un `group` de capture : une raison lisible quand
/// `CAPTURE_DIR` est absent, `false` sinon.
final Object sautSansCapture = dossierCapture == null
    ? 'CAPTURE_DIR absent : captures sautees (voir test/capture/LISEZ-MOI.md)'
    : false;

/// La cle du cadre capture, pose AU-DESSUS de `MaterialApp` : fond, surfaces
/// modales et superpositions sont dans le PNG.
const Key cadreCapture = ValueKey<String>('capture-cadre');

/// Charge TOUTES les familles declarees dans `FontManifest.json` : les
/// quatre familles de texte du pubspec, les deux graisses Phosphor, et celles
/// des paquets. Sans cela, `flutter test` dessine chaque glyphe avec sa
/// police de test (des carres) et les icones sont des rectangles.
///
/// A appeler dans `setUpAll`, hors du `FakeAsync` de `testWidgets`.
Future<List<String>> chargerPolicesDuDepot() async {
  neutraliserStockageAppareil();
  final String brut = await rootBundle.loadString('FontManifest.json');
  final List<Object?> familles = jsonDecode(brut) as List<Object?>;
  final List<String> chargees = <String>[];
  for (final Object? entree in familles) {
    final Map<String, Object?> famille = entree! as Map<String, Object?>;
    final String nom = famille['family']! as String;
    final FontLoader chargeur = FontLoader(nom);
    for (final Object? f in famille['fonts']! as List<Object?>) {
      final String asset = (f! as Map<String, Object?>)['asset']! as String;
      chargeur.addFont(rootBundle.load(asset));
    }
    await chargeur.load();
    chargees.add(nom);
  }
  return chargees;
}

/// L11 : la base locale de l'appareil (drift, `path_provider`) n'a pas de
/// greffon sous `flutter test`. Plusieurs ecrans l'ouvrent en passant
/// (profils locaux, cahiers, preferences) ; sans reponse du greffon, la
/// lecture echouait APRES la capture et faisait tomber le test. Le canal
/// repond desormais par une attente qui ne se termine pas : la base reste
/// « en ouverture », exactement comme sur un appareil lent, et la capture
/// montre l'ecran tel qu'il est rendu sans elle.
void neutraliserStockageAppareil() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (MethodCall _) => Completer<Object?>().future,
      );
}

/// Largeur de dix « i » a 20 px dans [famille] : environ 200 avec la police
/// de test (glyphes carres de 1 em), bien moins avec une vraie police. C'est
/// le garde-fou contre une capture en carres.
double largeurSonde(String famille) {
  final TextPainter peintre = TextPainter(
    text: TextSpan(
      text: 'iiiiiiiiii',
      style: TextStyle(fontFamily: famille, fontSize: 20),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final double largeur = peintre.width;
  peintre.dispose();
  return largeur;
}

/// Fixe la vue : taille LOGIQUE et densite. 390x844 @3 donne un PNG de
/// 1170x2532 ; 1440x900 @1 donne 1440x900. [zoneSure] simule la barre d'etat
/// et l'indicateur d'accueil d'un telephone (en points logiques).
void fixerVueCapture(
  WidgetTester tester,
  Size logique,
  double densite, {
  EdgeInsets zoneSure = EdgeInsets.zero,
}) {
  tester.view.physicalSize = logique * densite;
  tester.view.devicePixelRatio = densite;
  final FakeViewPadding zone = FakeViewPadding(
    top: zoneSure.top * densite,
    bottom: zoneSure.bottom * densite,
  );
  tester.view.padding = zone;
  tester.view.viewPadding = zone;
  addTearDown(tester.view.reset);
}

/// Fixe la vue d'apres les PIXELS d'une maquette et une largeur LOGIQUE
/// choisie (390 pour un telephone, 1440 pour un bureau) : densite = largeur
/// en pixels / largeur logique, hauteur logique deduite. La capture a alors
/// exactement la taille en pixels de la maquette, et les deux se comparent
/// sans deformation.
void fixerVueMaquette(
  WidgetTester tester, {
  required int largeurPx,
  required int hauteurPx,
  required double largeurLogique,
  EdgeInsets zoneSure = EdgeInsets.zero,
}) {
  final double densite = largeurPx / largeurLogique;
  fixerVueCapture(
    tester,
    Size(largeurLogique, hauteurPx / densite),
    densite,
    zoneSure: zoneSure,
  );
}

/// L'hote d'un ecran isole : vrai theme clair et sombre, locale et delegues
/// de l'application (`lib/app.dart`), cadre de capture au-dessus de
/// `MaterialApp`.
Widget hoteCapture(
  Widget ecran, {
  List<Override> surcharges = const <Override>[],
  ThemeMode themeMode = ThemeMode.light,
  double echelleTexte = 1,
  InterfaceMode interfaceMode = InterfaceMode.standard,
}) => ProviderScope(
  overrides: surcharges,
  child: TranslationProvider(
    child: RepaintBoundary(
      key: cadreCapture,
      child: Builder(
        builder: (BuildContext context) => MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.pour(interfaceMode, Brightness.light),
          darkTheme: AppTheme.pour(interfaceMode, Brightness.dark),
          themeMode: themeMode,
          locale: TranslationProvider.of(context).flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (BuildContext contexte, Widget? app) => MediaQuery(
            data: MediaQuery.of(contexte)
                .copyWith(textScaler: TextScaler.linear(echelleTexte)),
            child: app!,
          ),
          home: ecran,
        ),
      ),
    ),
  ),
);

/// Laisse passer les animations d'entree sans exiger qu'elles s'arretent :
/// un squelette ou une pulsation infinie ferait echouer `pumpAndSettle`.
Future<void> stabiliser(WidgetTester tester) async {
  for (int i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Le chemin d'un PNG de sortie.
String cheminSortie(String nom) {
  final String? dossier = dossierCapture;
  if (dossier == null) {
    throw StateError('CAPTURE_DIR absent : aucune capture ne doit tourner.');
  }
  return '$dossier${Platform.pathSeparator}$nom.png';
}

/// Ecrit le cadre en PNG et rend son chemin.
///
/// `toImage`, l'encodage et l'ecriture disque sont de vraies operations
/// asynchrones : hors de `runAsync`, le `FakeAsync` de `testWidgets` les
/// laisse pendre.
Future<String> capturer(WidgetTester tester, String nom) async {
  final double densite = tester.view.devicePixelRatio;
  final String chemin = cheminSortie(nom);
  // `flutter_test` peint les ombres sans flou (`debugDisableShadows`) : une
  // ombre de niveau 3 devient une bande grise nette sous la surface (revue du
  // 09/10, volet des Commandes). La capture peint les vraies ombres, puis
  // rend le reglage du test.
  await _avecOmbres(tester, () async {
    final RenderRepaintBoundary boite = tester.renderObject(
      find.byKey(cadreCapture),
    );
    await tester.runAsync(() async {
      final ui.Image image = await boite.toImage(pixelRatio: densite);
      final ByteData? png = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      image.dispose();
      final File fichier = File(chemin);
      await fichier.parent.create(recursive: true);
      await fichier.writeAsBytes(png!.buffer.asUint8List());
    });
  });
  return chemin;
}

/// A appeler dans le `setUp` d'un groupe qui capture un ecran monte par le
/// harnais d'un test : masque le ruban « DEBUG » de `MaterialApp`, puis le
/// rend a la fin du test.
void masquerRubanDebug() {
  WidgetsApp.debugAllowBannerOverride = false;
  addTearDown(() => WidgetsApp.debugAllowBannerOverride = true);
}

/// Ecrit TOUTE la vue en PNG, sans cadre [cadreCapture] : pour capturer un
/// ecran monte par le harnais d'un test existant (EA-HL-DOUBLE-1, reprise).
/// La vue doit etre a la densite 1 : la couche racine porte deja la mise a
/// l'echelle de la densite.
Future<String> capturerVue(WidgetTester tester, String nom) async {
  assert(tester.view.devicePixelRatio == 1, 'capturerVue : densite 1 seule');
  final OffsetLayer couche =
      tester.binding.renderViews.first.debugLayer! as OffsetLayer;
  final Size taille = tester.view.physicalSize;
  final String chemin = cheminSortie(nom);
  await tester.runAsync(() async {
    final ui.Image image = await couche.toImage(Offset.zero & taille);
    final ByteData? png = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    image.dispose();
    final File fichier = File(chemin);
    await fichier.parent.create(recursive: true);
    await fichier.writeAsBytes(png!.buffer.asUint8List());
  });
  return chemin;
}

/// Peint les ombres floues le temps de [corps], comme a l'execution, puis
/// rend `debugDisableShadows` a sa valeur (le test la verifie a la fin).
Future<void> _avecOmbres(
  WidgetTester tester,
  Future<void> Function() corps,
) async {
  final bool avant = debugDisableShadows;
  void repeindre() {
    void marquer(RenderObject objet) {
      objet
        ..markNeedsPaint()
        ..visitChildren(marquer);
    }

    for (final RenderView vue in tester.binding.renderViews) {
      marquer(vue);
    }
  }

  debugDisableShadows = false;
  try {
    repeindre();
    await tester.pump();
    await corps();
  } finally {
    debugDisableShadows = avant;
    repeindre();
    await tester.pump();
  }
}

/// Capture le cadre, puis compose la planche **maquette | capture**, cote a
/// cote, a la taille de la capture ; ecrit aussi la capture seule
/// (`<nom>_capture.png`). Tout en `dart:ui`, sans dependance.
///
/// La maquette est redimensionnee a la taille de la capture : si leurs
/// proportions different, elle est deformee, d'ou [fixerVueMaquette].
Future<String> capturerEtComparer(
  WidgetTester tester,
  String nom,
  String cheminMaquette,
) async {
  final RenderRepaintBoundary boite = tester.renderObject(
    find.byKey(cadreCapture),
  );
  final double densite = tester.view.devicePixelRatio;
  final String chemin = cheminSortie(nom);
  await tester.runAsync(() async {
    final ui.Image capture = await boite.toImage(pixelRatio: densite);
    final int l = capture.width;
    final int h = capture.height;
    final ui.Codec codec = await ui.instantiateImageCodec(
      await File(cheminMaquette).readAsBytes(),
      targetWidth: l,
      targetHeight: h,
    );
    final ui.Image maquette = (await codec.getNextFrame()).image;
    final ui.PictureRecorder enregistreur = ui.PictureRecorder();
    final Canvas toile = Canvas(enregistreur);
    final Paint neutre = Paint();
    toile.drawImage(maquette, Offset.zero, neutre);
    toile.drawImage(capture, Offset(l.toDouble(), 0), neutre);
    final ui.Image planche = await enregistreur.endRecording().toImage(
      2 * l,
      h,
    );
    final ByteData? png = await planche.toByteData(
      format: ui.ImageByteFormat.png,
    );
    final ByteData? pngCapture = await capture.toByteData(
      format: ui.ImageByteFormat.png,
    );
    for (final ui.Image i in <ui.Image>[capture, maquette, planche]) {
      i.dispose();
    }
    await File(chemin).parent.create(recursive: true);
    await File(chemin).writeAsBytes(png!.buffer.asUint8List());
    await File(chemin.replaceFirst(RegExp(r'\.png$'), '_capture.png'))
        .writeAsBytes(pngCapture!.buffer.asUint8List());
  });
  return chemin;
}

/// Compose une planche de recette : l'image retouchee [cheminImage] en haut,
/// a la largeur [largeur], puis une rangee des [captures] (PNG deja ecrits)
/// dessous, chacune reduite sans deformation dans une case de meme largeur.
/// Tout en `dart:ui`, dans `tester.runAsync` (decodage et ecriture reels).
/// Rend le chemin de la planche `<nom>.png` dans `CAPTURE_DIR`.
Future<String> plancheRangee(
  WidgetTester tester, {
  required String nom,
  required String cheminImage,
  required List<String> captures,
  int largeur = 1600,
}) async {
  const double marge = 16;
  final String chemin = cheminSortie(nom);
  await tester.runAsync(() async {
    Future<ui.Image> lire(String c) async {
      final ui.Codec codec = await ui.instantiateImageCodec(
        await File(c).readAsBytes(),
      );
      return (await codec.getNextFrame()).image;
    }

    final ui.Image image = await lire(cheminImage);
    final List<ui.Image> rangee = <ui.Image>[
      for (final String c in captures) await lire(c),
    ];
    final double l = largeur.toDouble();
    final double hImage = image.height * l / image.width;
    final double largeurCase =
        (l - marge * (rangee.length + 1)) / rangee.length;
    double hRangee = 0;
    for (final ui.Image c in rangee) {
      final double h = c.height * largeurCase / c.width;
      if (h > hRangee) hRangee = h;
    }
    final double hTotale = hImage + marge * 2 + hRangee;
    final ui.PictureRecorder enregistreur = ui.PictureRecorder();
    final Canvas toile = Canvas(enregistreur);
    final Paint neutre = Paint()..filterQuality = FilterQuality.medium;
    toile.drawRect(
      Rect.fromLTWH(0, 0, l, hTotale),
      Paint()..color = const Color(0xFF7A7A7A),
    );
    toile.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, l, hImage),
      neutre,
    );
    for (int i = 0; i < rangee.length; i++) {
      final ui.Image c = rangee[i];
      final double h = c.height * largeurCase / c.width;
      toile.drawImageRect(
        c,
        Rect.fromLTWH(0, 0, c.width.toDouble(), c.height.toDouble()),
        Rect.fromLTWH(
          marge + i * (largeurCase + marge),
          hImage + marge,
          largeurCase,
          h,
        ),
        neutre,
      );
    }
    final ui.Image planche = await enregistreur.endRecording().toImage(
      largeur,
      hTotale.ceil(),
    );
    final ByteData? png = await planche.toByteData(
      format: ui.ImageByteFormat.png,
    );
    for (final ui.Image i in <ui.Image>[image, ...rangee, planche]) {
      i.dispose();
    }
    await File(chemin).parent.create(recursive: true);
    await File(chemin).writeAsBytes(png!.buffer.asUint8List());
  });
  return chemin;
}
