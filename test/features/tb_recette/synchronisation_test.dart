// TB-11b (plan V2 §10, §11, §12 lignes reseau et sauvegarde, §19.5 ; K-59,
// D5 ; ERR-01 a ERR-03) : etats de synchronisation et de conservation,
// sans faux succes.
//
// Mesures sur le rendu : le bandeau monte et son rectangle, les traits et
// la saisie passes au calque, les pixels du trait non partage (tirets), le
// micro qui repond, la ligne de conservation montee ; jamais le texte du
// code. Deux recherches lisent le depot lui-meme : aucun « Sauvegarde »
// (succes) dans le code ni dans les cles, aucun « Suivre ».

import 'dart:convert' show jsonDecode;
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data' show ByteData;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_outils/annotation_layer.dart';
import 'package:rewayah_academy/core/tc_outils/etat_outils.dart';
import 'package:rewayah_academy/core/tc_outils/port_annotations.dart';
import 'package:rewayah_academy/core/tc_outils/port_dock_hote.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/chrome_seance.dart';
import 'package:rewayah_academy/features/salle_seance/commandes_pedagogiques.dart';
import 'package:rewayah_academy/features/salle_seance/ecriture_seance.dart';
import 'package:rewayah_academy/features/salle_seance/notes_deposees.dart';
import 'package:rewayah_academy/features/salle_seance/panneau_seance.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart';
import 'package:rewayah_academy/features/salle_seance/surface_page_fixe.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';
import 'package:rewayah_academy/features/tc_dock/barre_stylet.dart';
import 'package:rewayah_academy/features/tc_dock/couche_annotation.dart';

import '../../capture/outil_capture.dart'
    show cadreCapture, chargerPolicesDuDepot, fixerVueCapture, hoteCapture;
import '../../router/support_routeur.dart';

const Size _telephone = Size(390, 844);
const Size _bureau = Size(1440, 900);
const Size _etroit = Size(320, 700);

final Finder _bandeau = find.byKey(const ValueKey<String>('bandeau-secours'));
final Finder _page = find.byKey(SurfacePageFixe.clePage);
final Finder _couche = find.byKey(SurfacePageFixe.cleCouche);
final Finder _entreeCommandes = find.byWidgetPredicate(
  (Widget w) =>
      w.key == DeclencheurCommandes.cle || w.key == BarreStylet.cleCommandes,
);
final Finder _onglets = find.byKey(CommandesPedagogiques.cleOnglets);
final Finder _ecrire = find.byKey(const ValueKey<String>('outil-ecrire'));
final Finder _conservation = find.byKey(CommandesPedagogiques.cleConservation);

final String _nonPartage = DonneesSeanceDemo.traitNonPartageDemonstration.id;

Future<void> _attendre(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _monter(
  WidgetTester tester, {
  required RoleSeance role,
  required SituationTb situation,
  Size taille = _telephone,
  double texte = 1,
}) async {
  fixerVueCapture(tester, taille, texte > 1 ? 2 : 1);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hoteCapture(
      DemoSallePage(role: role, situation: situation),
      echelleTexte: texte,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _taper(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pump();
  await tester.tap(cible);
  await _attendre(tester);
}

ProviderContainer _conteneur(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(SalleSeance)));

CoucheAnnotation _calque(WidgetTester tester) =>
    tester.widget<CoucheAnnotation>(_couche);

/// Le texte du bandeau monte (message et suite).
String _texteBandeau(WidgetTester tester) => <String>[
  for (final Element e
      in find
          .descendant(of: _bandeau, matching: find.byType(RichText))
          .evaluate())
    (e.widget as RichText).text.toPlainText(),
].join(' ');

/// TB-11b (tour 2) : le bandeau se VOIT en entier, mesure sur le rendu :
/// dans l'ecran ; dans la tete bornee du telephone, sous son bord haut et
/// au-dessus de son fondu ; et le toucher au centre de chacun de ses textes
/// ([textes]) atteint ce texte (rien ne le couvre, il n'est pas rogne par
/// le defilement de la tete).
void _bandeauVu(WidgetTester tester, Size taille, List<String> textes) {
  expect(_bandeau, findsOneWidget);
  final Rect bandeau = tester.getRect(_bandeau);
  expect(bandeau.left, greaterThanOrEqualTo(-0.5));
  expect(bandeau.top, greaterThanOrEqualTo(-0.5));
  expect(bandeau.right, lessThanOrEqualTo(taille.width + 0.5));
  expect(bandeau.bottom, lessThanOrEqualTo(taille.height + 0.5));
  final Finder tete = find.ancestor(
    of: _bandeau,
    matching: find.byKey(TeteSalleBornee.defilementKey),
  );
  if (tete.evaluate().isNotEmpty) {
    final Rect cadre = tester.getRect(tete);
    final double fondu = find.byKey(TeteSalleBornee.cleFondu).evaluate().isEmpty
        ? 0
        : AppSpacing.xxxl;
    expect(bandeau.top, greaterThanOrEqualTo(cadre.top - 0.5));
    expect(
      bandeau.bottom,
      lessThanOrEqualTo(cadre.bottom - fondu + 0.5),
      reason: 'le bandeau sous le bord ou sous le fondu de la tete',
    );
    // Tour 3 : l'etat montre, la tete n'a pas defile (aucun fondu haut) et
    // aucune ligne n'est coupee a son bord haut.
    expect(find.byKey(TeteSalleBornee.cleFonduHaut), findsNothing);
    _teteSansLigneRognee(tester);
  }
  for (final String texte in textes) {
    final Finder ligne = find.descendant(
      of: _bandeau,
      matching: find.byWidgetPredicate(
        (Widget w) => w is RichText && w.text.toPlainText() == texte,
      ),
    );
    expect(ligne, findsOneWidget, reason: texte);
    final RenderObject objet = tester.renderObject(ligne);
    final HitTestResult touche = tester.hitTestOnBinding(
      tester.getRect(ligne).center,
    );
    expect(
      touche.path.any((HitTestEntry e) => e.target == objet),
      isTrue,
      reason: '« $texte » ne se touche pas : il est couvert ou rogne',
    );
  }
}

/// TB-11b (tour 3) : sur le rendu, chaque ligne de texte de la tete bornee
/// est entiere ou, si elle passe un bord de la tete, ce bord porte son
/// fondu (« une ligne coupee se lit comme une suite a faire defiler, jamais
/// comme un texte rogne »). Mesure : les rectangles des paragraphes montes
/// et la presence des deux fondus.
void _teteSansLigneRognee(WidgetTester tester) {
  final Finder tete = find.byKey(TeteSalleBornee.defilementKey);
  if (tete.evaluate().isEmpty) return;
  final Rect cadre = tester.getRect(tete);
  final bool fonduHaut = find
      .byKey(TeteSalleBornee.cleFonduHaut)
      .evaluate()
      .isNotEmpty;
  final bool fonduBas = find
      .byKey(TeteSalleBornee.cleFondu)
      .evaluate()
      .isNotEmpty;
  for (final Element e
      in find
          .descendant(of: tete, matching: find.byType(RichText))
          .evaluate()) {
    final Rect r = tester.getRect(find.byWidget(e.widget));
    final String texte = (e.widget as RichText).text.toPlainText();
    if (r.top < cadre.top - 0.5 && r.bottom > cadre.top + 0.5) {
      expect(fonduHaut, isTrue, reason: '« $texte » coupe au bord haut');
    }
    if (r.top < cadre.bottom - 0.5 && r.bottom > cadre.bottom + 0.5) {
      expect(fonduBas, isTrue, reason: '« $texte » coupe au bord bas');
    }
  }
}

/// Combien de textes montes valent exactement [texte].
int _fois(WidgetTester tester, String texte) =>
    _textes(tester).where((String x) => x == texte).length;

/// Tous les textes montes de l'ecran.
List<String> _textes(WidgetTester tester) => <String>[
  for (final Element e in find.byType(RichText).evaluate())
    (e.widget as RichText).text.toPlainText(),
];

/// Les textes montes hors de la barre d'ecriture (dont « Annuler » apparait
/// legitimement apres un trait), et le nombre de regions annoncees.
(Set<String>, int) _annonces(WidgetTester tester) => (
  <String>{
    for (final Element e in find.byType(RichText).evaluate())
      if (find
          .ancestor(
            of: find.byWidget(e.widget),
            matching: find.byType(BarreStylet),
          )
          .evaluate()
          .isEmpty)
        (e.widget as RichText).text.toPlainText(),
  },
  find
      .byWidgetPredicate(
        (Widget w) => w is Semantics && (w.properties.liveRegion ?? false),
      )
      .evaluate()
      .length,
);

/// Commandes > Outils > Ecrire (enseignant), ou Commandes > Ecrire
/// (eleve autorise), puis le panneau reduit.
Future<void> _armerEcrire(WidgetTester tester, {required bool outils}) async {
  await _taper(tester, _entreeCommandes);
  if (outils) {
    await _taper(
      tester,
      find.descendant(
        of: _onglets,
        matching: find.text(t.salle.seance.commandes.ongletOutils),
      ),
    );
  }
  await _taper(tester, _ecrire);
  expect(
    _conteneur(tester).read(etatOutilsProvider).outilActif,
    OutilDock.stylet,
  );
  await _taper(tester, find.byKey(PanneauSeance.cleReduire));
}

Offset _surPage(WidgetTester tester, double x, double y) {
  final Rect r = tester.getRect(_page);
  return r.topLeft + Offset(x * r.width, y * r.height);
}

Future<void> _glisser(WidgetTester tester, Offset a, Offset b) async {
  final TestPointer p = TestPointer(31, PointerDeviceKind.stylus);
  await tester.sendEventToBinding(p.down(a));
  for (int i = 1; i <= 8; i++) {
    await tester.sendEventToBinding(p.move(Offset.lerp(a, b, i / 8)!));
    await tester.pump();
  }
  await tester.sendEventToBinding(p.up());
  await _attendre(tester);
}

List<TraitVectoriel> _depot(WidgetTester tester) => <TraitVectoriel>[
  for (final AnnotationLayer c in (_conteneur(
    tester,
  ).read(portAnnotationsProvider) as AnnotationsMemoire).couches)
    ...c.traits,
];

/// Les segments d'encre sur la ligne [y] (logique) de la page, entre [de]
/// et [a] (parts de la largeur), lus pixel a pixel sur l'image rendue.
Future<int> _segmentsEncre(
  WidgetTester tester,
  double y,
  double de,
  double a,
) async {
  final Rect page = tester.getRect(_page);
  final double densite = tester.view.devicePixelRatio;
  final RenderRepaintBoundary cadre = tester.renderObject(
    find.byKey(cadreCapture),
  );
  final (ByteData, int)? lu = await tester.runAsync<(ByteData, int)>(() async {
    final ui.Image image = await cadre.toImage(pixelRatio: densite);
    final ByteData? brut = await image.toByteData();
    final int largeur = image.width;
    image.dispose();
    return (brut!, largeur);
  });
  final ByteData octets = lu!.$1;
  final int largeur = lu.$2;
  final int ligne = ((page.top + y * page.height) * densite).round();
  int segments = 0;
  bool dansEncre = false;
  final int debut = ((page.left + de * page.width) * densite).round();
  final int fin = ((page.left + a * page.width) * densite).round();
  for (int x = debut; x <= fin; x++) {
    // Clarte la plus basse sur trois lignes : le trait fin peut tomber
    // entre deux rangees de pixels.
    int clarte = 765;
    for (int d = -1; d <= 1; d++) {
      final int i = ((ligne + d) * largeur + x) * 4;
      final int c =
          octets.getUint8(i) + octets.getUint8(i + 1) + octets.getUint8(i + 2);
      if (c < clarte) clarte = c;
    }
    final bool encre = clarte < 600;
    if (encre && !dansEncre) segments++;
    dansEncre = encre;
  }
  return segments;
}

void main() {
  setUpAll(chargerPolicesDuDepot);

  group('Donnees des situations (une seule source)', () {
    test('ERR-01 : enseignant interrompu, son trait non partage ; la classe '
        'ne le recoit pas', () {
      final VueSeance ens = DonneesSeanceDemo.vueTb(
        RoleSeance.enseignant,
        SituationTb.err01,
      );
      expect(ens.synchroTableau, SynchroTableau.interrompue);
      expect(ens.traitsNonPartages, <String>{_nonPartage});
      expect(ens.notesAffichees.map((TraitVectoriel t) => t.id), <String>[
        DonneesSeanceDemo.traitDemonstration.id,
        _nonPartage,
      ]);
      expect(ens.encreNonPartagee, isTrue);
      expect(ens.ecritureSuspendue, isFalse);
      final VueSeance eleve = DonneesSeanceDemo.vueTb(
        RoleSeance.eleve,
        SituationTb.err01,
      );
      expect(eleve.traitsNonPartages, isEmpty);
      expect(
        eleve.notesAffichees.map((TraitVectoriel t) => t.id),
        isNot(contains(_nonPartage)),
      );
      expect(eleve.peutEcrire, isTrue);
      expect(eleve.ecritureSuspendue, isTrue);
      expect(eleve.ecritPossible, isFalse);
    });

    test('ERR-02 : ecriture suspendue pour tous ; ERR-03 enseignant seul', () {
      for (final RoleSeance role in RoleSeance.values) {
        final VueSeance v = DonneesSeanceDemo.vueTb(role, SituationTb.err02);
        expect(v.synchroTableau, SynchroTableau.reprise);
        expect(v.ecritPossible, isFalse, reason: role.name);
      }
      expect(SituationTb.err03.concerne(RoleSeance.eleve), isFalse);
      expect(SituationTb.err03.concerne(RoleSeance.guidee), isFalse);
      // Meme avec la donnee, l'eleve n'a aucune alerte de sauvegarde (§12).
      final VueSeance eleve = DonneesSeanceDemo.vueTb(
        RoleSeance.eleve,
        SituationTb.sal00,
      ).copyWith(conservation: ConservationNotes.nonSauvegardees);
      expect(eleve.texteTableau, isNull);
      expect(eleve.texteConservation, isNull);
    });

    test('le bloc d\'echec de la room prime : un seul etat', () {
      final VueSeance v = DonneesSeanceDemo.vueTb(
        RoleSeance.enseignant,
        SituationTb.err01,
      ).copyWith(connexion: ConnexionSeance.echec);
      expect(v.texteTableau, isNull);
      expect(v.texteBandeau, isNull);
    });
  });

  for (final (Size taille, double texte) in <(Size, double)>[
    (_telephone, 1),
    (_bureau, 1),
    (_etroit, 2),
  ]) {
    final String cas = '${taille.width.toInt()} x${texte.toInt()}';

    testWidgets('ERR-01 enseignant : un seul bandeau, le texte du §12 et sa '
        'suite ; le trait non partage passe au calque ($cas)', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        role: RoleSeance.enseignant,
        situation: SituationTb.err01,
        taille: taille,
        texte: texte,
      );
      expect(_bandeau, findsOneWidget);
      final String bandeau = _texteBandeau(tester);
      expect(bandeau, contains(t.salle.seance.synchro.nonPartagees));
      expect(bandeau, contains(t.salle.seance.synchro.nonPartageesSuite));
      // TB-11b (tour 2) : le bandeau se voit, en entier, et se touche.
      _bandeauVu(tester, taille, <String>[
        t.salle.seance.synchro.nonPartagees,
        t.salle.seance.synchro.nonPartageesSuite,
      ]);
      expect(_calque(tester).traitsNonPartages, contains(_nonPartage));
      expect(_calque(tester).encreNonPartagee, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ERR-01 et ERR-02 eleve : « Le tableau se reconnecte. », '
        '« Le tableau revient. », sans le trait non partage ($cas)', (
      WidgetTester tester,
    ) async {
      for (final (SituationTb s, String attendu) in <(SituationTb, String)>[
        (SituationTb.err01, t.salle.seance.synchro.seReconnecte),
        (SituationTb.err02, t.salle.seance.synchro.revient),
      ]) {
        await _monter(
          tester,
          role: RoleSeance.eleve,
          situation: s,
          taille: taille,
          texte: texte,
        );
        expect(_texteBandeau(tester), contains(attendu));
        expect(
          _texteBandeau(tester),
          contains(t.salle.seance.synchro.ecritureSuspendue),
        );
        _bandeauVu(tester, taille, <String>[
          attendu,
          t.salle.seance.synchro.ecritureSuspendue,
        ]);
        expect(
          _textes(tester).join(' '),
          isNot(contains(t.salle.seance.synchro.nonPartagees)),
        );
        expect(
          _calque(tester).traits.map((TraitVectoriel t) => t.id),
          isNot(contains(_nonPartage)),
        );
        expect(_calque(tester).encreNonPartagee, isFalse);
      }
    });

    testWidgets('ERR-03 : « ... ne sont pas sauvegardees. », sans '
        '« Reessayer » ; la conservation dans les Commandes ($cas)', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        role: RoleSeance.enseignant,
        situation: SituationTb.err03,
        taille: taille,
        texte: texte,
      );
      final String bandeau = _texteBandeau(tester);
      expect(bandeau, contains(t.salle.seance.synchro.nonSauvegardees));
      expect(bandeau, contains(t.salle.seance.synchro.nonSauvegardeesSuite));
      _bandeauVu(tester, taille, <String>[
        t.salle.seance.synchro.nonSauvegardees,
        t.salle.seance.synchro.nonSauvegardeesSuite,
      ]);
      // TB-BR-18 : aucun « Reessayer » tant que le contrat durable manque.
      expect(find.text(t.salle.secours.reessayer), findsNothing);
      expect(find.text(t.commun.reessayer), findsNothing);
      await _taper(tester, _entreeCommandes);
      expect(_conservation, findsOneWidget);
      expect(
        tester.widget<Text>(_conservation).data,
        t.salle.seance.rangement.notesConservees,
      );
      expect(tester.takeException(), isNull);
    });
  }

  // TB-11b (tour 2) : pendant la suspension, rien ne propose d'ecrire :
  // ni tuile « Ecrire », ni barre (Stylo, Gomme, Annuler, Terminer), ni
  // aide qui dit d'ecrire ; la phrase de la suspension a leur place. Un
  // stylet deja retenu ne prend rien et ne rend pas sa barre.
  for (final (Size taille, double texte) in <(Size, double)>[
    (_telephone, 1),
    (_etroit, 2),
  ]) {
    final String cas = '${taille.width.toInt()} x${texte.toInt()}';

    testWidgets('ERR-02 enseignant : « Ecrire » n\'est pas propose, la '
        'phrase dit pourquoi ; le stylet retenu n\'ecrit pas ($cas)', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        role: RoleSeance.enseignant,
        situation: SituationTb.err02,
        taille: taille,
        texte: texte,
      );
      expect(_texteBandeau(tester), contains(t.salle.seance.synchro.reprise));
      // Tour 3 (revue du tour 2) : ce bandeau aussi est mesure.
      _bandeauVu(tester, taille, <String>[
        t.salle.seance.synchro.reprise,
        t.salle.seance.synchro.ecritureSuspendue,
      ]);
      await _taper(tester, _entreeCommandes);
      await _taper(
        tester,
        find.descendant(
          of: _onglets,
          matching: find.text(t.salle.seance.commandes.ongletOutils),
        ),
      );
      expect(_ecrire, findsNothing, reason: 'aucune tuile « Ecrire »');
      final Finder suspendue = find.byKey(
        CommandesPedagogiques.cleEcritureSuspendue,
      );
      expect(suspendue, findsOneWidget);
      expect(
        tester.widget<Text>(suspendue).data,
        t.salle.seance.synchro.ecritureSuspendue,
      );
      await tester.ensureVisible(suspendue);
      await tester.pump();
      expect(
        tester.getRect(suspendue).bottom,
        lessThanOrEqualTo(taille.height),
      );
      // Un stylet retenu avant la reprise : ni barre, ni aide d'Ecrire.
      _conteneur(tester)
          .read(etatOutilsProvider.notifier)
          .choisirOutil(OutilDock.stylet);
      await _attendre(tester);
      expect(find.byType(EcritureSeance), findsNothing);
      expect(find.byType(BarreStylet), findsNothing);
      expect(find.text(t.salle.seance.outils.aideEcrire), findsNothing);
      await _taper(tester, find.byKey(PanneauSeance.cleReduire));
      expect(find.byType(PaletteEcriture), findsNothing);
      expect(find.byType(BarreStylet), findsNothing);
      expect(_calque(tester).saisie, isFalse);
      final int avant = _depot(tester).length;
      await _glisser(
        tester,
        _surPage(tester, 0.3, 0.3),
        _surPage(tester, 0.6, 0.35),
      );
      expect(_depot(tester).length, avant, reason: 'rien n\'est ecrit');
      expect(tester.takeException(), isNull);
    });

    testWidgets('ERR-01 et ERR-02 eleve autorise : ecriture suspendue, '
        'aucune tuile ni barre, la phrase a leur place ($cas)', (
      WidgetTester tester,
    ) async {
      for (final SituationTb s in <SituationTb>[
        SituationTb.err01,
        SituationTb.err02,
      ]) {
        await _monter(
          tester,
          role: RoleSeance.eleve,
          situation: s,
          taille: taille,
          texte: texte,
        );
        await _taper(tester, _entreeCommandes);
        expect(_ecrire, findsNothing, reason: '${s.name} : tuile');
        // Tour 3 : la phrase n'est pas dite deux fois a l'ecran.
        expect(
          _fois(tester, t.salle.seance.synchro.ecritureSuspendue),
          1,
          reason: s.name,
        );
        final Finder suspendue = find.descendant(
          of: find.byKey(CommandesPedagogiques.cleEcritureEleve),
          matching: find.byKey(CommandesPedagogiques.cleEcritureSuspendue),
        );
        expect(suspendue, findsOneWidget, reason: s.name);
        final List<String> textes = _textes(tester);
        for (final String menteur in <String>[
          t.salle.seance.ecriture.aideEleveTu,
          t.salle.seance.ecriture.aideEleveVous,
          t.salle.seance.ecriture.choisirTu,
          t.salle.seance.ecriture.choisirVous,
          t.salle.seance.ecriture.tuPeuxEcrire,
          t.salle.seance.ecriture.vousPouvezEcrire,
        ]) {
          expect(textes, isNot(contains(menteur)), reason: s.name);
        }
        _conteneur(tester)
            .read(etatOutilsProvider.notifier)
            .choisirOutil(OutilDock.stylet);
        await _attendre(tester);
        expect(find.byType(BarreStylet), findsNothing, reason: s.name);
        await _taper(tester, find.byKey(PanneauSeance.cleReduire));
        expect(find.byType(PaletteEcriture), findsNothing, reason: s.name);
        expect(_calque(tester).saisie, isFalse);
        final int avant = _depot(tester).length;
        await _glisser(
          tester,
          _surPage(tester, 0.3, 0.3),
          _surPage(tester, 0.6, 0.35),
        );
        expect(_depot(tester).length, avant, reason: s.name);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      }
    });
  }

  // Tour 2 : la guidee autorisee, a 320 x2 en Mode Accessibilite : le
  // bandeau court du §20, en entier, sans debordement de la page ; la
  // suspension se lit dans les Commandes.
  for (final (Size taille, double texte) in <(Size, double)>[
    (_telephone, 1),
    (_etroit, 2),
  ]) {
    testWidgets('guidee ERR-01 et ERR-02 : bandeau court, vu en entier, '
        'rien ne deborde (${taille.width.toInt()} x${texte.toInt()})', (
      WidgetTester tester,
    ) async {
      for (final (SituationTb s, String attendu) in <(SituationTb, String)>[
        (SituationTb.err01, t.salle.seance.synchro.seReconnecte),
        (SituationTb.err02, t.salle.seance.synchro.revient),
      ]) {
        await _monter(
          tester,
          role: RoleSeance.guidee,
          situation: s,
          taille: taille,
          texte: texte,
        );
        expect(tester.takeException(), isNull, reason: s.name);
        _bandeauVu(tester, taille, <String>[attendu]);
        expect(
          _texteBandeau(tester),
          isNot(contains(t.salle.seance.synchro.ecritureSuspendue)),
        );
        await tester.pumpWidget(const SizedBox());
      }
    });
  }

  // TB-11b (tour 3, revue du tour 2) : a 320 x2, l'etat critique qui ne
  // tenait pas a sa place passe en tete, la tete a son debut : aucune
  // ligne coupee au bord haut ; l'en-tete suit et se relit en faisant
  // defiler la tete, fondu haut pose des qu'elle a defile.
  testWidgets('320 x2 : l\'etat en tete, rien de coupe au bord haut, '
      'l\'en-tete joignable sous un fondu', (WidgetTester tester) async {
    for (final (RoleSeance role, SituationTb s) in <(RoleSeance, SituationTb)>[
      (RoleSeance.enseignant, SituationTb.err01),
      (RoleSeance.enseignant, SituationTb.err02),
      (RoleSeance.enseignant, SituationTb.err03),
      (RoleSeance.eleve, SituationTb.err01),
      (RoleSeance.eleve, SituationTb.err02),
    ]) {
      final String cas = '${role.name} ${s.name}';
      await _monter(
        tester,
        role: role,
        situation: s,
        taille: _etroit,
        texte: 2,
      );
      final Finder tete = find.byKey(TeteSalleBornee.defilementKey);
      final Rect cadre = tester.getRect(tete);
      final Rect bandeau = tester.getRect(_bandeau);
      final Rect chrome = tester.getRect(find.byType(ChromeSeance));
      // L'etat, premier bloc de la tete, a son bord haut ; l'en-tete dessous.
      expect(bandeau.top, closeTo(cadre.top, 0.5), reason: cas);
      expect(chrome.top, greaterThanOrEqualTo(bandeau.bottom - 0.5));
      expect(find.byKey(TeteSalleBornee.cleFonduHaut), findsNothing);
      _teteSansLigneRognee(tester);
      // La tete defile : le fondu haut se pose, l'en-tete se rejoint.
      await tester.drag(tete, const Offset(0, -120));
      await tester.pumpAndSettle();
      expect(find.byKey(TeteSalleBornee.cleFonduHaut), findsOneWidget);
      _teteSansLigneRognee(tester);
      await tester.ensureVisible(find.byType(ChromeSeance));
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byType(ChromeSeance)).top,
        greaterThanOrEqualTo(cadre.top - 0.5),
        reason: cas,
      );
      expect(tester.takeException(), isNull, reason: cas);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('390 x1 : la tete tient, l\'en-tete reste au-dessus de l\'etat', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      role: RoleSeance.enseignant,
      situation: SituationTb.err01,
    );
    expect(
      tester.getRect(find.byType(ChromeSeance)).bottom,
      lessThanOrEqualTo(tester.getRect(_bandeau).top + 0.5),
    );
    expect(find.byKey(TeteSalleBornee.cleFonduHaut), findsNothing);
  });

  testWidgets('1440 : Commandes ouvertes, la phrase de la suspension est '
      'dite une fois', (WidgetTester tester) async {
    for (final (RoleSeance role, SituationTb s) in <(RoleSeance, SituationTb)>[
      (RoleSeance.eleve, SituationTb.err01),
      (RoleSeance.eleve, SituationTb.err02),
    ]) {
      await _monter(tester, role: role, situation: s, taille: _bureau);
      expect(_fois(tester, t.salle.seance.synchro.ecritureSuspendue), 1);
      await _taper(tester, _entreeCommandes);
      expect(_texteBandeau(tester), isNotEmpty);
      expect(
        find.byKey(CommandesPedagogiques.cleEcritureSuspendue),
        findsOneWidget,
        reason: '${role.name} ${s.name}',
      );
      expect(
        _fois(tester, t.salle.seance.synchro.ecritureSuspendue),
        1,
        reason: '${role.name} ${s.name}',
      );
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('temoin : tableau partage, « Ecrire » se propose a l\'eleve '
      'autorise, sans phrase de suspension', (WidgetTester tester) async {
    await _monter(
      tester,
      role: RoleSeance.eleve,
      situation: SituationTb.autorisationEcrire,
    );
    await _taper(tester, _entreeCommandes);
    expect(_ecrire, findsOneWidget);
    expect(
      find.byKey(CommandesPedagogiques.cleEcritureSuspendue),
      findsNothing,
    );
  });

  test('donnees : la suspension retire « Ecrire » et dit pourquoi', () {
    final VueSeance suspendue = DonneesSeanceDemo.vueTb(
      RoleSeance.eleve,
      SituationTb.err01,
    );
    expect(suspendue.voitEcriture, isTrue);
    expect(suspendue.ecritureProposee, isFalse);
    expect(
      suspendue.texteEcritureSuspendue,
      t.salle.seance.synchro.ecritureSuspendue,
    );
    final VueSeance partage = suspendue.copyWith(
      synchroTableau: SynchroTableau.partage,
    );
    expect(partage.ecritureProposee, isTrue);
    expect(partage.texteEcritureSuspendue, isNull);
    // L'enseignant interrompu ecrit encore (ses traits sont marques).
    expect(
      DonneesSeanceDemo.vueTb(
        RoleSeance.enseignant,
        SituationTb.err01,
      ).ecritureProposee,
      isTrue,
    );
  });

  test('donnees : « Connexion retablie. » et l\'etat du tableau ensemble, '
      'le bandeau dit le tableau', () {
    final VueSeance v = DonneesSeanceDemo.vueTb(
      RoleSeance.enseignant,
      SituationTb.err01,
    ).copyWith(connexion: ConnexionSeance.retablie);
    expect(v.texteRetabli, isNotNull);
    expect(v.texteBandeau, t.salle.seance.synchro.nonPartagees);
    expect(v.bandeauDitTableau, isTrue);
    final VueSeance faible = v.copyWith(
      connexion: ConnexionSeance.reseauFaible,
    );
    expect(faible.bandeauDitTableau, isFalse);
  });

  testWidgets('le tableau revenu (meme salle), les traits ne sont plus '
      'marques ; l\'interruption suivante ne les remarque pas', (
    WidgetTester tester,
  ) async {
    // La meme salle dont le tableau change d'etat sur place (comme en
    // production) : SalleDemo sans cle, son depot et sa portee gardes.
    Widget salle(SituationTb s) => hoteCapture(
      SalleDemo(
        role: RoleSeance.enseignant,
        etat: DonneesSeanceDemo.etatBaseTb(s),
        situation: s,
        onSortir: () {},
      ),
    );
    fixerVueCapture(tester, _telephone, 1);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(salle(SituationTb.err01));
    await tester.pumpAndSettle();
    await _armerEcrire(tester, outils: true);
    await _glisser(
      tester,
      _surPage(tester, 0.3, 0.3),
      _surPage(tester, 0.6, 0.35),
    );
    final String pose = _depot(tester).single.id;
    expect(_conteneur(tester).read(traitsNonPartagesProvider), contains(pose));
    expect(_calque(tester).traitsNonPartages, contains(pose));
    // Le tableau revient : la marque est levee sans renvoi ni accuse de
    // reception par trait (TB-RC, m19 : ecart ecrit, la levee sur accuse
    // arrive avec TB-BR-42). Le depot local garde le trait ; rien ne prouve
    // que la classe l'a recu.
    await tester.pumpWidget(salle(SituationTb.ped03));
    await _attendre(tester);
    expect(_depot(tester).map((TraitVectoriel x) => x.id), contains(pose));
    expect(_conteneur(tester).read(traitsNonPartagesProvider), isEmpty);
    // Nouvelle interruption : le trait pose pendant la precedente n'est plus
    // marque (marque levee au retour, sans accuse).
    await tester.pumpWidget(salle(SituationTb.err01));
    await _attendre(tester);
    expect(_calque(tester).traitsNonPartages, isNot(contains(pose)));
  });

  testWidgets('une autre salle ne recoit pas les marques de la precedente', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      role: RoleSeance.enseignant,
      situation: SituationTb.err01,
    );
    await _armerEcrire(tester, outils: true);
    await _glisser(
      tester,
      _surPage(tester, 0.3, 0.3),
      _surPage(tester, 0.6, 0.35),
    );
    expect(_conteneur(tester).read(traitsNonPartagesProvider), isNotEmpty);
    // La salle se ferme, l'application (sa portee racine) reste.
    await tester.pumpWidget(hoteCapture(const SizedBox()));
    await _monter(
      tester,
      role: RoleSeance.enseignant,
      situation: SituationTb.err01,
    );
    expect(
      _conteneur(tester).read(traitsNonPartagesProvider),
      isEmpty,
      reason: 'la portee est celle de la salle',
    );
  });

  testWidgets('ERR-01 enseignant : il ecrit encore ; le nouveau trait est '
      'marque non partage, sans aucune notification', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      role: RoleSeance.enseignant,
      situation: SituationTb.err01,
    );
    await _armerEcrire(tester, outils: true);
    expect(_calque(tester).saisie, isTrue);
    final (Set<String>, int) avant = _annonces(tester);
    await _glisser(
      tester,
      _surPage(tester, 0.3, 0.3),
      _surPage(tester, 0.6, 0.35),
    );
    final List<TraitVectoriel> depot = _depot(tester);
    expect(depot, hasLength(1));
    expect(_calque(tester).traitsNonPartages, contains(depot.single.id));
    // Pas de notification par trait : aucun texte nouveau, aucun SnackBar.
    expect(_annonces(tester).$1.difference(avant.$1), isEmpty);
    expect(_annonces(tester).$2, avant.$2);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('trait pose en ligne (PED-03) : ni marque, ni notification', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      role: RoleSeance.enseignant,
      situation: SituationTb.ped03,
    );
    await _armerEcrire(tester, outils: true);
    final (Set<String>, int) avant = _annonces(tester);
    await _glisser(
      tester,
      _surPage(tester, 0.3, 0.3),
      _surPage(tester, 0.6, 0.35),
    );
    expect(_depot(tester), hasLength(1));
    expect(_calque(tester).traitsNonPartages, isEmpty);
    expect(_annonces(tester).$1.difference(avant.$1), isEmpty);
    expect(_annonces(tester).$2, avant.$2);
    expect(_bandeau, findsNothing);
  });

  testWidgets('le trait non partage est peint en tirets, la classe ne le '
      'voit pas (pixels)', (WidgetTester tester) async {
    await _monter(
      tester,
      role: RoleSeance.enseignant,
      situation: SituationTb.err01,
    );
    final int tirets = await _segmentsEncre(tester, 0.8, 0.27, 0.73);
    expect(tirets, greaterThanOrEqualTo(4), reason: 'tirets : $tirets');
    // Temoin : en PED-03 (tableau partage), la ligne mesuree est vide ;
    // les tirets ci-dessus sont donc bien le trait non partage.
    await tester.pumpWidget(const SizedBox());
    await _monter(
      tester,
      role: RoleSeance.enseignant,
      situation: SituationTb.ped03,
    );
    // Aucun trait sur cette ligne en PED-03.
    expect(await _segmentsEncre(tester, 0.8, 0.27, 0.73), 0);
    await tester.pumpWidget(const SizedBox());
    await _monter(tester, role: RoleSeance.eleve, situation: SituationTb.err01);
    expect(await _segmentsEncre(tester, 0.8, 0.27, 0.73), 0);
  });

  testWidgets('l\'audio n\'est jamais interrompu par l\'etat du tableau : le '
      'micro repond en ERR-01, ERR-02 et ERR-03', (WidgetTester tester) async {
    for (final (RoleSeance role, SituationTb s) in <(RoleSeance, SituationTb)>[
      (RoleSeance.enseignant, SituationTb.err01),
      (RoleSeance.eleve, SituationTb.err01),
      (RoleSeance.enseignant, SituationTb.err02),
      (RoleSeance.eleve, SituationTb.err02),
      (RoleSeance.enseignant, SituationTb.err03),
    ]) {
      await _monter(tester, role: role, situation: s);
      // Standard des commandes d'appel : le mot d'etat est l'infobulle.
      final Finder ouvert = find.byTooltip(t.salle.microOuvert);
      expect(ouvert, findsOneWidget, reason: '${role.name} ${s.name}');
      await _taper(tester, ouvert);
      expect(
        find.byTooltip(t.salle.microCoupe),
        findsWidgets,
        reason: '${role.name} ${s.name}',
      );
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('arrivee tardive : l\'etat actuel, aucun bouton « Suivre »', (
    WidgetTester tester,
  ) async {
    for (final SituationTb s in <SituationTb>[
      SituationTb.err01,
      SituationTb.err02,
      SituationTb.ped03,
    ]) {
      for (final RoleSeance role in <RoleSeance>[
        RoleSeance.eleve,
        RoleSeance.guidee,
      ]) {
        await _monter(tester, role: role, situation: s);
        expect(_page, findsOneWidget, reason: 'la page presentee, directement');
        // TB-11b (tour 2) : arriver tard, c'est recevoir l'etat actuel, deja
        // ecrit : le trait pose avant l'arrivee est au calque, sans geste.
        if (s != SituationTb.ped03) {
          expect(
            _calque(tester).traits.map((TraitVectoriel x) => x.id),
            contains(DonneesSeanceDemo.traitDemonstration.id),
            reason: '${role.name} ${s.name}',
          );
        }
        expect(
          _textes(tester).where((String x) => x.startsWith('Suivre')),
          isEmpty,
        );
        await tester.pumpWidget(const SizedBox());
      }
    }
  });

  testWidgets('conservation : enseignant seulement, jamais chez l\'eleve', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      role: RoleSeance.enseignant,
      situation: SituationTb.ped03,
    );
    await _taper(tester, _entreeCommandes);
    expect(_conservation, findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await _monter(tester, role: RoleSeance.eleve, situation: SituationTb.ped03);
    await _taper(tester, _entreeCommandes);
    expect(_conservation, findsNothing);
  });

  // Verification TB-11b : a 320 x2, la phrase de conservation avait sa
  // derniere ligne coupee au bord bas de la feuille, et en arabe elle ne
  // paraissait pas du tout. Elle s'atteint au defilement, signale par le
  // fondu du bas, et se lit entiere dans la vue de la colonne.
  group('320 x2 : la conservation atteinte et entiere', () {
    setUpAll(chargerPolicesDuDepot);
    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      testWidgets('enseignant ${langue.languageCode}', (
        WidgetTester tester,
      ) async {
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
        await _monter(
          tester,
          role: RoleSeance.enseignant,
          situation: SituationTb.ped03,
          taille: _etroit,
          texte: 2,
        );
        await _taper(tester, _entreeCommandes);
        expect(_conservation, findsOneWidget);
        final Finder colonne = find.byKey(CommandesPedagogiques.cleDefilement);
        final Rect vue = tester.getRect(colonne);
        final Rect avant = tester.getRect(_conservation);
        if (avant.top < vue.top - 0.5 || avant.bottom > vue.bottom + 0.5) {
          // Hors de la vue : le fondu du bas dit qu'il reste a lire.
          expect(
            find.byKey(CommandesPedagogiques.cleFonduBas),
            findsOneWidget,
            reason: 'aucun signe de la suite (phrase $avant, vue $vue)',
          );
        }
        await tester.scrollUntilVisible(
          _conservation,
          24,
          scrollable: find.descendant(
            of: colonne,
            matching: find.byType(Scrollable),
          ),
        );
        await tester.pumpAndSettle();
        // La phrase amenee en haut de la vue : sa premiere ligne n'est pas
        // coupee au bord haut, et tant qu'elle depasse en bas, le fondu du
        // bas le dit (la vue de la feuille fait 80 px a 320 x2 en francais
        // pour une phrase de 96 : limite notee, disposition TB-4 / HU-1).
        await tester.runAsync(
          () => Scrollable.ensureVisible(tester.element(_conservation)),
        );
        await tester.pumpAndSettle();
        final Rect phrase = tester.getRect(_conservation);
        final Rect cadre = tester.getRect(colonne);
        expect(
          phrase.top,
          closeTo(cadre.top, 0.5),
          reason: 'phrase $phrase, vue $cadre',
        );
        if (phrase.bottom > cadre.bottom + 0.5) {
          expect(
            find.byKey(CommandesPedagogiques.cleFonduBas),
            findsOneWidget,
            reason: 'la fin de la phrase est sous le bord, sans signe',
          );
        }
        // Au bout du defilement, la derniere ligne de la phrase est passee
        // dans la vue : elle s'atteint entiere en lisant.
        await tester.runAsync(
          () => Scrollable.ensureVisible(
            tester.element(_conservation),
            alignment: 1,
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.getRect(_conservation).bottom,
          lessThanOrEqualTo(tester.getRect(colonne).bottom + 0.5),
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('aucun « Sauvegarde » de succes (§12, §19.5 point 5)', () {
    // Le succes d'une sauvegarde (« Sauvegarde », « Notes sauvegardees. ») ;
    // la negation « ne sont pas sauvegardees » et l'etiquette « Sauvegarde
    // en echec » (sans accent) ne sont pas des succes.
    // Tour 3 (revue du tour 2) : toutes les formes, avec ou sans accent, en
    // capitale ou non, ponctuees ou non (« notes sauvegardees dans ... ») ;
    // seules la negation (« pas », « non ») et l'etiquette d'echec ou
    // d'absence (« Sauvegarde en echec », « Sauvegarde absente ») passent.
    final RegExp succes = RegExp(
      r'(?<![\wÀ-ÿ])(?<!pas )(?<!non )(?<!non-)sauvegard[eé][eé]?s?'
      r'(?![\wÀ-ÿ])(?!\s+(?:en\s+[ée]chec|absente))',
      caseSensitive: false,
    );

    // Verification TB-11b (lot D-surface) : la garde lit les VALEURS des
    // cles (JSON lu) et les chaines entieres du code (multilignes ''' et
    // chaines adjacentes jointes), et connait les synonymes de succes.
    //
    // Partout (toutes les cles, tout lib) : « sauvegarde » sous toutes ses
    // formes, l'arabe « تم الحفظ » / « تم حفظ » et le passif « حُفظ »
    // (« حُفظت » : a ete sauvegardee). Le simple « حفظ » n'est pas un
    // succes : c'est le bouton « Enregistrer » ou la memorisation du Coran
    // (« للحفظ »).
    final List<RegExp> partout = <RegExp>[
      succes,
      RegExp(r'تم\s+(?:ال)?حفظ'),
      RegExp('حُفِ?ظ'),
    ];
    // Dans la salle (cles `salle.` et `tc.`, code de salle_seance, tc_dock,
    // demo) : aussi « enregistre(e)(s) » et « محفوظ(ة) ». Ailleurs dans
    // l'application, « Photo enregistree » ou « accord enregistre » sont
    // de vrais succes confirmes par le serveur, hors tableau.
    final List<RegExp> salle = <RegExp>[
      ...partout,
      RegExp(r'(?<![\wÀ-ÿ])enregistr[eé]e?s?(?![\wÀ-ÿ])', caseSensitive: false),
      RegExp(
        '(?<![ء-ي])محفوظ'
        '(?:ة|ات|ون)?(?![ء-ي])',
      ),
    ];
    // Une negation dans la meme proposition, avant le motif, en fait un
    // aveu d'absence (« n'a pas ete enregistre », « غير محفوظة ») ; une
    // etiquette d'echec juste apres aussi (« Sauvegarde en echec »).
    final RegExp negation = RegExp(
      r'(?<![\wÀ-ÿ])(?:pas|non|jamais|rien|aucune?|ni)(?![\wÀ-ÿ])|'
      '(?<![ء-ي])(?:غير|لم|لا|'
      'لن|فشل)(?![ء-ي])',
      caseSensitive: false,
    );
    final RegExp echecApres = RegExp(
      r'^\s+(?:en\s+[ée]chec|absente)',
      caseSensitive: false,
    );
    final RegExp finProposition = RegExp('[.!?;:\n،؛]');
    final RegExp diacritiques = RegExp('[ً-ِّْٰ]');

    // LISTE BLANCHE, cle par cle, chacune justifiee. Ce ne sont pas des
    // succes de sauvegarde des notes ou du tableau :
    const Map<String, String> listeBlanche = <String, String>{
      // ar « محفوظة في هذه الحصة فقط » : la conservation limitee a la
      // seance, dite honnetement (fr « conservees ... uniquement »).
      'salle.seance.rangement.notesConservees': 'conservation dans la seance',
      // Une copie de fichier enregistree sur l'appareil, a la demande.
      'tc.bibliotheque.message.copieEnregistree': 'copie de fichier',
      // La file locale du post-cours, qui dit « partira des le retour du
      // reseau » (hors tableau).
      'tc.parcours.postCours.enFile': 'file locale du post-cours',
      // Jonction avec la ligne arabe (ccr) : hors de la salle, l'arabe dit
      // « enregistre » par حفظ ; ce ne sont pas des notes ni le tableau.
      'classe.cartes.enregistree':
          'carte de classe enregistree (ar « حُفظ » traduit « enregistre »)',
      'enseignant.photo.succes': 'photo de profil enregistree',
      'enseignant.cahier.depose': 'cahier de transmission depose',
      'enseignant.profil.enregistre': 'profil enregistre',
      'enseignant.creneaux.heureEnregistree': 'heure de creneau enregistree',
      'ficheEleve.informations.succes': 'photo de la fiche eleve enregistree',
      'parcours.finTitre': 'preference du parcours enregistree',
      'consentement.compte.merci': 'consentement du compte enregistre',
      // Hors de la salle : l'arabe dit « enregistre » par « تم الحفظ / تم
      // حفظ » ; ce ne sont ni des notes ni le tableau.
      'compte.langueCourriels.retour.enregistre':
          'langue des courriels enregistree',
      'recrutement.partage.fait.enregistre': 'image de partage enregistree',
    };

    final Map<String, Map<String, String>> valeurs =
        <String, Map<String, String>>{
          for (final String langue in <String>['fr', 'ar'])
            langue: _valeursDesCles(
              jsonDecode(
                File('assets/i18n/$langue.i18n.json').readAsStringSync(),
              ),
            ),
        };
    // Le code (`strings_*.g.dart`) montre un parametre comme une espace.
    final List<String> textesBlancs = <String>[
      for (final Map<String, String> v in valeurs.values)
        for (final String cle in listeBlanche.keys)
          if (v[cle] != null) ...<String>[
            v[cle]!,
            v[cle]!.replaceAll(RegExp(r'\{\w+\}'), ' '),
          ],
    ];

    bool annonceUnSucces(String texte, {required List<RegExp> motifs}) {
      String reste = texte;
      for (final String blanc in textesBlancs) {
        reste = reste.replaceAll(blanc, ' ');
      }
      for (final String vu in <String>{
        reste,
        reste.replaceAll(diacritiques, ''),
      }) {
        for (final RegExp motif in motifs) {
          for (final RegExpMatch m in motif.allMatches(vu)) {
            final String avant = vu.substring(0, m.start);
            final int debut =
                finProposition.allMatches(avant).lastOrNull?.end ?? 0;
            if (negation.hasMatch(avant.substring(debut))) continue;
            if (echecApres.hasMatch(vu.substring(m.end))) continue;
            return true;
          }
        }
      }
      return false;
    }

    test('la garde reconnait chaque forme de succes, pas la negation', () {
      for (final String vu in <String>[
        'Sauvegardé',
        'Sauvegarde',
        'sauvegarde',
        'Notes sauvegardées.',
        'notes sauvegardees dans la bibliotheque',
        'SAUVEGARDÉES',
        'Tout est sauvegardé !',
        'Sauvegarde réussie',
        'Notes enregistrées.',
        'Tableau enregistré',
        'Tout est enregistré !',
        'تم الحفظ',
        'تمّ حفظ الملاحظات',
        'حُفظت الملاحظات',
        'الملاحظات محفوظة.',
      ]) {
        expect(annonceUnSucces(vu, motifs: salle), isTrue, reason: vu);
      }
      for (final String passe in <String>[
        'Les notes de cette séance ne sont pas sauvegardées.',
        'ERR-03 Sauvegarde en échec',
        'Sauvegarde absente',
        'notes non sauvegardees',
        'Sauvegarder',
        'Enregistrer',
        'Enregistrement actif',
        "Le changement n'a pas été enregistré.",
        'ملاحظات هذه الحصة غير محفوظة.',
        'ERR-03 فشل الحفظ',
        'حفظ',
        'للحفظ',
      ]) {
        expect(annonceUnSucces(passe, motifs: salle), isFalse, reason: passe);
      }
      // Hors de la salle, « enregistre » ne compte pas ; « sauvegarde », si.
      expect(annonceUnSucces('Photo enregistrée', motifs: partout), isFalse);
      expect(annonceUnSucces('Photo sauvegardée', motifs: partout), isTrue);
    });

    test('la liste blanche ne nomme que des cles existantes', () {
      for (final String cle in listeBlanche.keys) {
        expect(valeurs['fr']![cle], isNotNull, reason: cle);
        expect(valeurs['ar']![cle], isNotNull, reason: cle);
      }
    });

    test('le lecteur du code joint les chaines multilignes et adjacentes', () {
      const String source =
          "final a = '''\n  Les notes du tableau :\n  Notes enregistrées.\n''';\n"
          "final b = 'Notes '\n      'sauve'\n      'gardées.';\n"
          'final c = "Tout est \${x} sauvegardé";\n'
          '// final d = "Notes sauvegardees" (un commentaire)\n'
          "final e = r'Sauvegarder';\n";
      final List<String> chaines = _chainesDuCode(source);
      expect(chaines, hasLength(4));
      expect(chaines[0], contains('Notes enregistrées.'));
      expect(chaines[1], 'Notes sauvegardées.');
      expect(
        <bool>[
          for (final String c in chaines) annonceUnSucces(c, motifs: salle),
        ],
        <bool>[true, true, true, false],
      );
    });

    test('dans les valeurs des cles (fr, ar)', () {
      final List<String> trouves = <String>[
        for (final MapEntry<String, Map<String, String>> langue
            in valeurs.entries)
          for (final MapEntry<String, String> cle in langue.value.entries)
            if (annonceUnSucces(
              cle.value,
              motifs: cle.key.startsWith('salle.') || cle.key.startsWith('tc.')
                  ? salle
                  : partout,
            ))
              '${langue.key} ${cle.key} : ${cle.value}',
      ];
      expect(trouves, isEmpty);
    });

    test('dans le code (lib, et la salle en entier)', () {
      // Les chaines du code, entieres (les commentaires parlent de « la
      // sauvegarde » absente : ce ne sont pas des textes montres).
      const List<String> dossiersSalle = <String>[
        'lib/features/salle_seance/',
        'lib/features/tc_dock/',
        'lib/features/demo/',
      ];
      int fichiersSalle = 0;
      final List<String> trouves = <String>[];
      for (final FileSystemEntity f in Directory(
        'lib',
      ).listSync(recursive: true)) {
        if (f is! File || !f.path.endsWith('.dart')) continue;
        final String chemin = f.path.replaceAll(r'\', '/');
        final bool dansLaSalle = dossiersSalle.any(chemin.startsWith);
        if (dansLaSalle) fichiersSalle++;
        for (final String c in _chainesDuCode(f.readAsStringSync())) {
          if (annonceUnSucces(c, motifs: dansLaSalle ? salle : partout)) {
            trouves.add('$chemin : $c');
          }
        }
      }
      expect(fichiersSalle, greaterThan(20));
      expect(trouves, isEmpty);
    });

    testWidgets('a l\'ecran, dans chaque situation de la salle', (
      WidgetTester tester,
    ) async {
      for (final RoleSeance role in RoleSeance.values) {
        for (final SituationTb s in situationsTb(role)) {
          await _monter(tester, role: role, situation: s, taille: _bureau);
          final List<String> trouves = <String>[
            for (final String x in _textes(tester))
              if (annonceUnSucces(x, motifs: salle)) x,
          ];
          expect(trouves, isEmpty, reason: '${role.name} ${s.name}');
          await tester.pumpWidget(const SizedBox());
        }
      }
    });
  });

  testWidgets('K-07 : ERR-01, ERR-02, ERR-03 depuis la vraie coquille', (
    WidgetTester tester,
  ) async {
    for (final (RoleSeance role, SituationTb s, String attendu)
        in <(RoleSeance, SituationTb, String)>[
          (
            RoleSeance.enseignant,
            SituationTb.err01,
            t.salle.seance.synchro.nonPartagees,
          ),
          (
            RoleSeance.eleve,
            SituationTb.err01,
            t.salle.seance.synchro.seReconnecte,
          ),
          (
            RoleSeance.enseignant,
            SituationTb.err02,
            t.salle.seance.synchro.reprise,
          ),
          (
            RoleSeance.guidee,
            SituationTb.err02,
            t.salle.seance.synchro.revient,
          ),
          (
            RoleSeance.enseignant,
            SituationTb.err03,
            t.salle.seance.synchro.nonSauvegardees,
          ),
        ]) {
      final GoRouter routeur = await monterRouteur(
        tester,
        Routes.demoSalle,
        taille: _bureau,
      );
      final Finder lien = find.byKey(
        ValueKey<String>('lien-${role.name}-tb-${s.name}'),
      );
      await tester.ensureVisible(lien);
      await tester.pump();
      await tester.tap(lien);
      await tester.pumpAndSettle();
      expect(lieu(routeur), adresseDemoSalleTb(role, s));
      expect(_texteBandeau(tester), contains(attendu));
      if (s == SituationTb.err03) {
        await _taper(tester, _entreeCommandes);
        expect(_conservation, findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }
  });
}

/// Les valeurs des cles i18n, a plat (`salle.seance.x` -> texte).
Map<String, String> _valeursDesCles(Object? json, [String prefixe = '']) {
  final Map<String, String> valeurs = <String, String>{};
  if (json is Map<String, Object?>) {
    json.forEach((String cle, Object? v) {
      valeurs.addAll(
        _valeursDesCles(v, prefixe.isEmpty ? cle : '$prefixe.$cle'),
      );
    });
  } else if (json is List<Object?>) {
    for (int i = 0; i < json.length; i++) {
      valeurs.addAll(_valeursDesCles(json[i], '$prefixe.$i'));
    }
  } else if (json is String) {
    valeurs[prefixe] = json;
  }
  return valeurs;
}

/// Les chaines d'un source Dart, entieres : commentaires sautes, chaines
/// multilignes (`'''`, `"""`) lues d'un bloc, chaines adjacentes (separees
/// seulement par des blancs, retours a la ligne compris) jointes, comme le
/// compilateur les joint. Une interpolation `${...}` compte pour un blanc.
List<String> _chainesDuCode(String s) {
  final List<String> chaines = <String>[];
  final RegExp identifiant = RegExp(r'[\w$]');
  StringBuffer? courante;
  int finPrecedente = 0;
  int i = 0;
  while (i < s.length) {
    if (s.startsWith('//', i)) {
      final int fin = s.indexOf('\n', i);
      i = fin < 0 ? s.length : fin;
      continue;
    }
    if (s.startsWith('/*', i)) {
      final int fin = s.indexOf('*/', i + 2);
      i = fin < 0 ? s.length : fin + 2;
      continue;
    }
    final int debut = i;
    bool brute = false;
    if ((s[i] == 'r' || s[i] == 'R') &&
        i + 1 < s.length &&
        (s[i + 1] == "'" || s[i + 1] == '"') &&
        (i == 0 || !identifiant.hasMatch(s[i - 1]))) {
      brute = true;
      i++;
    }
    final String q = s[i];
    if (q != "'" && q != '"') {
      i++;
      continue;
    }
    final String fermeture = s.startsWith(q * 3, i) ? q * 3 : q;
    int j = i + fermeture.length;
    final StringBuffer contenu = StringBuffer();
    while (j < s.length && !s.startsWith(fermeture, j)) {
      if (!brute && s[j] == r'\') {
        if (j + 1 < s.length) contenu.write(s[j + 1]);
        j += 2;
        continue;
      }
      if (!brute && s.startsWith(r'${', j)) {
        int profondeur = 1;
        j += 2;
        while (j < s.length && profondeur > 0) {
          if (s[j] == '{') profondeur++;
          if (s[j] == '}') profondeur--;
          j++;
        }
        contenu.write(' ');
        continue;
      }
      contenu.write(s[j]);
      j++;
    }
    final int fin = math.min(s.length, j + fermeture.length);
    if (courante != null && s.substring(finPrecedente, debut).trim().isEmpty) {
      courante.write(contenu);
    } else {
      if (courante != null) chaines.add(courante.toString());
      courante = StringBuffer(contenu.toString());
    }
    finPrecedente = fin;
    i = fin;
  }
  if (courante != null) chaines.add(courante.toString());
  return chaines;
}
