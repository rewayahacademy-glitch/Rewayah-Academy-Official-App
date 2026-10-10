// TB-11b (plan V2 §10, §11, §12 lignes reseau et sauvegarde, §19.5 ; K-59,
// D5 ; ERR-01 a ERR-03) : etats de synchronisation et de conservation,
// sans faux succes.
//
// Mesures sur le rendu : le bandeau monte et son rectangle, les traits et
// la saisie passes au calque, les pixels du trait non partage (tirets), le
// micro qui repond, la ligne de conservation montee ; jamais le texte du
// code. Deux recherches lisent le depot lui-meme : aucun « Sauvegarde »
// (succes) dans le code ni dans les cles, aucun « Suivre ».

import 'dart:io';
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
    // Le tableau revient.
    await tester.pumpWidget(salle(SituationTb.ped03));
    await _attendre(tester);
    expect(_depot(tester).map((TraitVectoriel x) => x.id), contains(pose));
    expect(_conteneur(tester).read(traitsNonPartagesProvider), isEmpty);
    // Nouvelle interruption : le trait recu n'est pas remarque.
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
      final Finder ouvert = find.text(t.salle.microOuvert);
      expect(ouvert, findsOneWidget, reason: '${role.name} ${s.name}');
      await _taper(tester, ouvert);
      expect(
        find.text(t.salle.microCoupe),
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

  group('aucun « Sauvegarde » de succes (§12, §19.5 point 5)', () {
    // Le succes d'une sauvegarde (« Sauvegarde », « Notes sauvegardees. ») ;
    // la negation « ne sont pas sauvegardees » et l'etiquette « Sauvegarde
    // en echec » (sans accent) ne sont pas des succes. L'arabe n'est pas
    // traduit avant LG-1 (K-41) : « تم الحفظ » existant traduit
    // « Enregistre » d'une file locale (tc.parcours.postCours), hors
    // tableau.
    // Tour 3 (revue du tour 2) : toutes les formes, avec ou sans accent, en
    // capitale ou non, ponctuees ou non (« notes sauvegardees dans ... ») ;
    // seules la negation (« pas », « non ») et l'etiquette d'echec ou
    // d'absence (« Sauvegarde en echec », « Sauvegarde absente ») passent.
    final RegExp succes = RegExp(
      r'(?<![\wÀ-ÿ])(?<!pas )(?<!non )(?<!non-)sauvegard[eé][eé]?s?'
      r'(?![\wÀ-ÿ])(?!\s+(?:en\s+[ée]chec|absente))',
      caseSensitive: false,
    );

    test('la garde reconnait chaque forme de succes, pas la negation', () {
      for (final String vu in <String>[
        'Sauvegardé',
        'Sauvegarde',
        'sauvegarde',
        'Notes sauvegardées.',
        'notes sauvegardees dans la bibliotheque',
        'SAUVEGARDÉES',
        'Tout est sauvegardé !',
      ]) {
        expect(succes.hasMatch(vu), isTrue, reason: vu);
      }
      for (final String passe in <String>[
        'Les notes de cette séance ne sont pas sauvegardées.',
        'ERR-03 Sauvegarde en échec',
        'Sauvegarde absente',
        'notes non sauvegardees',
        'Sauvegarder',
      ]) {
        expect(succes.hasMatch(passe), isFalse, reason: passe);
      }
    });

    test('dans les cles (fr, ar)', () {
      for (final String chemin in <String>[
        'assets/i18n/fr.i18n.json',
        'assets/i18n/ar.i18n.json',
      ]) {
        final List<String> trouves = <String>[
          for (final String ligne in File(chemin).readAsLinesSync())
            if (succes.hasMatch(ligne)) ligne.trim(),
        ];
        expect(trouves, isEmpty, reason: chemin);
      }
    });

    test('dans le code (lib)', () {
      // Les chaines du code (les commentaires parlent de « la sauvegarde »
      // absente : ce ne sont pas des textes montres).
      final RegExp chaine = RegExp(
        r"'(?:[^'\\]|\\.)*'|"
        r'"(?:[^"\\]|\\.)*"',
      );
      final List<String> trouves = <String>[
        for (final FileSystemEntity f in Directory(
          'lib',
        ).listSync(recursive: true))
          if (f is File && f.path.endsWith('.dart'))
            for (final String ligne in f.readAsLinesSync())
              if (!ligne.trimLeft().startsWith('//'))
                for (final RegExpMatch m in chaine.allMatches(ligne))
                  if (succes.hasMatch(m[0]!)) '${f.path}: ${ligne.trim()}',
      ];
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
              if (succes.hasMatch(x)) x,
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
