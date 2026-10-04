// T3 : Interface guidee (CLV-05) et fin de seance eleve (CLV-09).
//
// Guidee : rien de reserve a l'enseignant, ni zoom, ni indicateur, ni
// signal, ni sous-titre ; dock de disques egaux ; point fixe pendant la
// visite ; video a cote du support en desktop. Fin : textes exacts, sans
// recapitulatif ni presence ni mention d'enregistrement.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/widgets/ecran_resultat.dart';
import 'package:rewayah_academy/core/widgets/permanent_notice.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/actions_seance.dart';
import 'package:rewayah_academy/features/salle_seance/dock_seance.dart';
import 'package:rewayah_academy/features/salle_seance/resultat_seance.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart';
import 'package:rewayah_academy/features/salle_seance/vignette_video.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../capture/outil_capture.dart';

void _rien() {}

/// Le bouton du dock nomme [libelle]. MA-CMD-1 : a 390 et 640, la salle
/// guidee pose ses commandes en icones seules (le nom est lu par le lecteur
/// d'ecran et montre en infobulle) ; on cherche donc le bouton, pas un texte.
Finder _bouton(String libelle) => find.byWidgetPredicate(
  (Widget w) => w is BoutonAppel && w.libelle == libelle,
);

const ActionsSeance _actions = ActionsSeance(
  onRetour: _rien,
  onQuitter: _rien,
  onMicro: _rien,
  onCamera: _rien,
  onAgrandir: _rien,
  onZoomMoins: _rien,
  onZoomPlus: _rien,
  onNotifications: _rien,
  onReglages: _rien,
  onCompte: _rien,
);

const Map<String, Size> _tailles = <String, Size>{
  'mobile': Size(390, 844),
  'web etroit': Size(640, 1000),
  'desktop': Size(1440, 900),
};

Future<void> _monterGuidee(
  WidgetTester tester,
  Size taille, {
  EtatDemoSalle etat = EtatDemoSalle.visite,
  ThemeMode mode = ThemeMode.light,
  VueSeance? vue,
}) async {
  fixerVueCapture(tester, taille, 1);
  await tester.pumpWidget(
    hoteCapture(
      SalleSeance(
        vue: vue ?? DonneesSeanceDemo.vue(RoleSeance.guidee, etat),
        actions: _actions,
      ),
      themeMode: mode,
      interfaceMode: InterfaceMode.enfant,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _monterFin(
  WidgetTester tester,
  Size taille,
  IssueSeance issue, {
  bool guidee = false,
  ThemeMode mode = ThemeMode.light,
}) async {
  fixerVueCapture(tester, taille, 1);
  await tester.pumpWidget(
    hoteCapture(
      ResultatSeance(issue: issue, onRetour: _rien),
      themeMode: mode,
      interfaceMode: guidee ? InterfaceMode.enfant : InterfaceMode.standard,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// L'opacite rendue du point : le produit des fondus au-dessus du disque.
double _opacitePoint(WidgetTester tester) {
  double opacite = 1;
  final Finder point = find.byType(PointEnregistrement);
  for (final FadeTransition f in tester.widgetList<FadeTransition>(
    find.descendant(of: point, matching: find.byType(FadeTransition)),
  )) {
    opacite *= f.opacity.value;
  }
  for (final Opacity o in tester.widgetList<Opacity>(
    find.descendant(of: point, matching: find.byType(Opacity)),
  )) {
    opacite *= o.opacity;
  }
  return opacite;
}

void main() {
  for (final MapEntry<String, Size> taille in _tailles.entries) {
    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('guidee visite, ${taille.key}, ${mode.name} : rien de '
          'reserve, ni zoom, ni indicateur, ni signal, ni sous-titre', (
        WidgetTester tester,
      ) async {
        await _monterGuidee(tester, taille.value, mode: mode);
        expect(tester.takeException(), isNull);

        expect(find.text('Ma séance'), findsOneWidget);
        expect(find.text('Ton parent observe la séance.'), findsOneWidget);
        expect(find.text('En ligne'), findsOneWidget);
        for (final String interdit in <String>[
          'Séance en direct',
          'Classe An-Nour',
          'La séance se poursuit.',
          'Élèves',
          'Supports',
          'Réseau',
          'Pointeur',
          'Marquer',
          'Masquer',
          'Annoter',
          'Foyer',
          'min restantes',
          'Tuteur de',
          'Votre parent',
          'Zoom local',
          '1 / 12',
          '‹',
          '›',
        ]) {
          expect(
            find.textContaining(interdit),
            findsNothing,
            reason: '« $interdit » ne doit pas paraitre en guidee',
          );
        }
        for (final String cle in <String>[
          'indicateur-page',
          'pagination-support',
          'zoom-local',
          'signal-video',
        ]) {
          expect(find.byKey(ValueKey<String>(cle)), findsNothing, reason: cle);
        }
        for (final String bouton in <String>[
          // ETATS-BTN-1 : le mot d'etat des deux bascules.
          'Micro ouvert',
          'Caméra allumée',
          'Quitter',
        ]) {
          expect(_bouton(bouton), findsOneWidget, reason: bouton);
        }
        // TB-2 (VIS-01) : Agrandir a quitte la barre de l'appel.
        expect(_bouton('Agrandir'), findsNothing);
        expect(find.text('Micro'), findsNothing);
        expect(find.text('Parler'), findsNothing);
      });
    }

    testWidgets('guidee, ${taille.key} : disques du dock de meme taille', (
      WidgetTester tester,
    ) async {
      await _monterGuidee(tester, taille.value);
      final List<Size> tailles = <Size>[
        for (final Element e
            in find
                .descendant(
                  of: find.byType(DockSeance),
                  matching: find.byKey(const ValueKey<String>('disque-appel')),
                )
                .evaluate())
          (e.renderObject! as RenderBox).size,
      ];
      // TB-2 : Micro, Camera, Quitter.
      expect(tailles, hasLength(3));
      for (final Size s in tailles) {
        expect(s, tailles.first);
        expect(s.width, s.height);
      }
    });
  }

  testWidgets('guidee : camera non autorisee, aucun bouton Camera', (
    WidgetTester tester,
  ) async {
    await _monterGuidee(
      tester,
      const Size(390, 844),
      vue: DonneesSeanceDemo.vue(
        RoleSeance.guidee,
        EtatDemoSalle.visite,
      ).copyWith(cameraAutorisee: false),
    );
    expect(find.text('Caméra allumée'), findsNothing);
    expect(find.text('Caméra éteinte'), findsNothing);
    expect(find.text('Micro ouvert'), findsOneWidget);
    // Le bouton lui-meme (MA-CMD-1 : icones seules), par son mot d'etat.
    expect(_bouton('Caméra allumée'), findsNothing);
    expect(_bouton('Caméra éteinte'), findsNothing);
    expect(_bouton('Micro ouvert'), findsOneWidget);
  });

  testWidgets('guidee : le point reste fixe pendant la visite', (
    WidgetTester tester,
  ) async {
    await _monterGuidee(tester, const Size(1440, 900));
    expect(
      find.byWidgetPredicate((Widget w) => w is PointEnregistrement),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (Widget w) => w is PointEnregistrement && w.clignote,
      ),
      findsNothing,
    );
    final double avant = _opacitePoint(tester);
    await tester.pump(const Duration(milliseconds: 700));
    final double apres = _opacitePoint(tester);
    expect(apres, avant);
    expect(avant, 1);
  });

  testWidgets('guidee desktop : video a cote du support, jamais dessus', (
    WidgetTester tester,
  ) async {
    await _monterGuidee(tester, const Size(1440, 900));
    final Rect video = tester.getRect(
      find.byKey(const ValueKey<String>('vignette-video')),
    );
    final Rect support = tester.getRect(
      find.byKey(const ValueKey<String>('cadre-support')),
    );
    expect(video.overlaps(support), isFalse);
    expect(video.left, greaterThan(support.right));
    expect(video.width, closeTo(MesuresVignette.largeurGuideeLarge, 0.5));
    expect(video.width / video.height, closeTo(MesuresVignette.ratio, 0.01));
  });

  for (final MapEntry<Size, double> cas in <Size, double>{
    const Size(390, 844): MesuresVignette.largeurGuideeMobile,
    const Size(640, 1000): MesuresVignette.largeurGuideeTablette,
  }.entries) {
    testWidgets('guidee ${cas.key.width.toInt()} : vignette en coin', (
      WidgetTester tester,
    ) async {
      await _monterGuidee(tester, cas.key);
      final Rect video = tester.getRect(
        find.byKey(const ValueKey<String>('vignette-video')),
      );
      final Rect support = tester.getRect(
        find.byKey(const ValueKey<String>('zone-support')),
      );
      expect(video.width, closeTo(cas.value, 0.5));
      expect(support.contains(video.topLeft), isTrue);
      expect(support.right - video.right, closeTo(MesuresVignette.retrait, 1));
    });
  }

  testWidgets('guidee web etroit : support sans encadre vide, carte '
      'ajustee au contenu', (WidgetTester tester) async {
    await _monterGuidee(tester, const Size(640, 1000));
    final Rect video = tester.getRect(
      find.byKey(const ValueKey<String>('vignette-video')),
    );
    final Rect support = tester.getRect(
      find.byKey(const ValueKey<String>('zone-support')),
    );
    final Rect dock = tester.getRect(
      find.byKey(const ValueKey<String>('dock-seance')),
    );
    // Environ 41 % de la largeur du support (image), rapport garde.
    expect(video.width / support.width, closeTo(0.41, 0.03));
    expect(video.width / video.height, closeTo(MesuresVignette.ratio, 0.01));
    // Le support de demonstration n'a plus d'encadre (E16, EN-RC lot 6) :
    // sans texte, aucune pastille vide n'est dessinee.
    expect(find.byKey(const ValueKey<String>('encadre-support')), findsNothing);
    // Un espace separe la carte du dock.
    expect(dock.top - support.bottom, greaterThan(40));
  });

  testWidgets('guidee desktop : dock aere comme l\'image', (
    WidgetTester tester,
  ) async {
    await _monterGuidee(tester, const Size(1440, 900));
    final Finder trouves = find.byKey(const ValueKey<String>('disque-appel'));
    final List<Rect> disques = <Rect>[
      for (int i = 0; i < trouves.evaluate().length; i++)
        tester.getRect(trouves.at(i)),
    ]..sort((Rect a, Rect b) => a.left.compareTo(b.left));
    // TB-2 : Micro, Camera, Quitter (Agrandir a quitte la barre).
    expect(disques.length, 3);
    for (int i = 1; i < disques.length; i++) {
      expect(disques[i].center.dx - disques[i - 1].center.dx, closeTo(130, 8));
    }
    final Rect dock = tester.getRect(
      find.byKey(const ValueKey<String>('dock-seance')),
    );
    // Une case aeree de moins (≈ 130) que la pilule de l'image (≈ 555).
    expect(dock.width, closeTo(555 - 130, 15));
  });

  testWidgets('guidee desktop : la sortie de l\'en-tete demande confirmation', (
    WidgetTester tester,
  ) async {
    await _monterGuidee(tester, const Size(1440, 900));
    await tester.tap(find.bySemanticsLabel('Quitter la séance').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.text('Vous pourrez revenir si la séance est encore ouverte.'),
      findsOneWidget,
    );
  });

  group('CLV-09 fin eleve', () {
    const List<String> interdits = <String>[
      'résent',
      'bsent',
      'enregistré',
      'connectés',
      'Élèves',
      'visite de contrôle',
      'Cahier',
    ];

    for (final MapEntry<String, Size> taille in _tailles.entries) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        testWidgets('standard, fin, ${taille.key}, ${mode.name}', (
          WidgetTester tester,
        ) async {
          await _monterFin(
            tester,
            taille.value,
            IssueSeance.terminee,
            mode: mode,
          );
          expect(tester.takeException(), isNull);
          expect(find.text('Séance terminée'), findsOneWidget);
          expect(
            find.text('Vous pouvez retrouver votre travail dans votre Classe.'),
            findsOneWidget,
          );
          expect(find.text('Retour à la Classe'), findsOneWidget);
          for (final String i in interdits) {
            expect(find.textContaining(i), findsNothing, reason: i);
          }
          expect(find.byType(PointEnregistrement), findsNothing);
        });

        testWidgets('guidee, fin, ${taille.key}, ${mode.name}', (
          WidgetTester tester,
        ) async {
          await _monterFin(
            tester,
            taille.value,
            IssueSeance.terminee,
            guidee: true,
            mode: mode,
          );
          expect(tester.takeException(), isNull);
          expect(find.text('La séance est terminée.'), findsOneWidget);
          expect(find.text("Retour à l'accueil"), findsOneWidget);
          expect(find.text('Séance terminée'), findsNothing);
          expect(find.text('Retour à la Classe'), findsNothing);
          for (final String i in interdits) {
            expect(find.textContaining(i), findsNothing, reason: i);
          }
        });
      }

      testWidgets('standard, sortie avant la fin, ${taille.key}', (
        WidgetTester tester,
      ) async {
        await _monterFin(tester, taille.value, IssueSeance.quittee);
        expect(tester.takeException(), isNull);
        expect(find.text('Vous avez quitté la séance.'), findsOneWidget);
        expect(
          find.text("Vous pourrez revenir tant qu'elle reste ouverte."),
          findsOneWidget,
        );
        expect(find.text('Retour à la Classe'), findsOneWidget);
      });

      testWidgets('guidee, sortie avant la fin, ${taille.key} : meme ecran '
          'que la fin, coche au ton succes', (WidgetTester tester) async {
        await _monterFin(
          tester,
          taille.value,
          IssueSeance.quittee,
          guidee: true,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('La séance est terminée.'), findsOneWidget);
        final EcranResultat ecran = tester.widget<EcranResultat>(
          find.byType(EcranResultat),
        );
        expect(ecran.icone, AppIcons.succes);
        expect(ecran.ton, TonEtat.succes);
      });
    }
  });
}
