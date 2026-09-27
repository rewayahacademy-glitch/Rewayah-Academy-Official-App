// AD-6 : la revue ADM-02B sur la VRAIE coque admin et le vrai routeur, en
// demonstration (`?demo=admin`). Chaque geste part d'un bouton reel (K-07) :
// Personnes dans la barre laterale ou le tiroir, puis la ligne du dossier.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/app.dart';
import 'package:rewayah_academy/core/admin/admin_domaine.dart';
import 'package:rewayah_academy/core/capacites/port_revue_dossiers.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/core/widgets/groupe_reglages.dart';
import 'package:rewayah_academy/features/admin_dossiers/etat_file_dossiers.dart';
import 'package:rewayah_academy/features/demo/dossiers_demo.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/demo/repere_demonstration.dart';

Future<void> _stabiliser(WidgetTester tester) async {
  for (int i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _monter(
  WidgetTester tester,
  Size taille, {
  EtatRevueDemo? etat,
  List<Override> plus = const <Override>[],
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesDemoAdmin(environnement: 'staging', etat: etat),
        ...plus,
      ],
      child: TranslationProvider(
        child: RewayahApp(
          builder: (BuildContext context, Widget? child) =>
              RepereDemonstration(child: child),
        ),
      ),
    ),
  );
  await _stabiliser(tester);
  ProviderScope.containerOf(tester.element(find.byType(RewayahApp)))
      .read(routeurProvider)
      .go(Routes.admin);
  await _stabiliser(tester);
}

/// Personnes depuis la coque : tiroir sur mobile, barre laterale sur bureau.
Future<void> _ouvrirDossiers(WidgetTester tester) async {
  final Finder barre = find.byKey(AdminShell.barreLateraleKey);
  final bool mobile = barre.evaluate().isEmpty;
  if (mobile) {
    await tester.tap(find.bySemanticsLabel(t.nav.admin.menu));
    await _stabiliser(tester);
  }
  await tester.tap(
    find.descendant(
      of: mobile ? find.byKey(AdminShell.tiroirKey) : barre,
      matching: find.text(AdminDomaine.personnes.libelle),
    ),
  );
  await _stabiliser(tester);
}

Finder _ligne(String debutNom) =>
    find.bySemanticsLabel(RegExp("^Ouvrir le dossier d(e |')$debutNom"));

Future<void> _ouvrir(WidgetTester tester, String prenom) async {
  await _ouvrirDossiers(tester);
  await tester.ensureVisible(_ligne(prenom));
  await _stabiliser(tester);
  await tester.tap(_ligne(prenom));
  await _stabiliser(tester);
}

Future<void> _taperTexte(WidgetTester tester, String libelle) async {
  await tester.ensureVisible(find.text(libelle));
  await _stabiliser(tester);
  await tester.tap(find.text(libelle));
  await _stabiliser(tester);
}

ActionPrincipale _bouton(WidgetTester tester, String libelle) =>
    tester.widget<ActionPrincipale>(
      find
          .ancestor(
            of: find.text(libelle),
            matching: find.byType(ActionPrincipale),
          )
          .first,
    );

bool _coche(WidgetTester tester, String libelle) =>
    isSemantics(isChecked: true)
        .matches(tester.getSemantics(find.text(libelle)), <dynamic, dynamic>{});

const List<String> _points = <String>[
  'La pièce est lisible',
  'Le nom correspond à celui du compte',
  "La pièce n'est pas expirée",
];

/// Un Stream qui ne rend jamais rien : le detail reste en chargement.
Future<DossierPourRevue> _jamais() => Completer<DossierPourRevue>().future;

void main() {
  testWidgets('1440 : quatre cartes dans l ordre, aucune image ni URL', (
    WidgetTester tester,
  ) async {
    await _monter(tester, const Size(1440, 900));
    await _ouvrirDossiers(tester);
    // Omar est selectionne automatiquement (premier de la file).
    expect(find.text("Dossier d'Omar Haddad"), findsOneWidget);
    final List<double> ys = <double>[
      for (final String titre in <String>[
        'Identité et dossier',
        "Pièce d'identité",
        'Vérifications',
      ])
        tester.getTopLeft(find.text(titre)).dy,
    ];
    expect(ys[0] < ys[1] && ys[1] < ys[2], isTrue);
    expect(find.byType(Image), findsNothing);
    expect(find.textContaining('http'), findsNothing);
    expect(find.textContaining('demo-fictif'), findsNothing);
    expect(find.textContaining('DEMO-D01'), findsNothing);
    // AD-7 : Voir la piece est actif, sans legende d'indisponibilite.
    expect(_bouton(tester, 'Voir la pièce').onPress, isNotNull);
    expect(
      find.text('La consultation de la pièce est indisponible pour le moment.'),
      findsNothing,
    );
    expect(find.textContaining("journal d'audit"), findsNothing);
  });

  testWidgets('1440 : cases jamais precochees, lien vers la premiere', (
    WidgetTester tester,
  ) async {
    await _monter(tester, const Size(1440, 900));
    await _ouvrirDossiers(tester);
    // Valider ferme n'est pas rendu : le lien tient sa place.
    expect(find.text('Valider le dossier'), findsNothing);
    for (final String p in _points) {
      expect(_coche(tester, p), isFalse);
    }
    const String lien = 'Terminez les vérifications requises.';
    // Le lien est annonce comme lien, pas comme bouton (une seule annonce).
    expect(
      tester.getSemantics(find.bySemanticsLabel(lien)),
      isSemantics(isLink: true, isButton: false),
    );
    await _taperTexte(tester, lien);
    Rect focus = FocusManager.instance.primaryFocus!.rect;
    expect(tester.getRect(find.text(_points[0])).overlaps(focus), isTrue);

    await _taperTexte(tester, _points[0]);
    await _taperTexte(tester, lien);
    focus = FocusManager.instance.primaryFocus!.rect;
    expect(tester.getRect(find.text(_points[1])).overlaps(focus), isTrue);

    await _taperTexte(tester, _points[1]);
    await _taperTexte(tester, _points[2]);
    for (final String p in _points) {
      expect(_coche(tester, p), isTrue);
    }
    expect(_bouton(tester, 'Valider le dossier').onPress, isNotNull);
    expect(find.text(lien), findsNothing);
  });

  testWidgets('1440 : motif ouvert, un seul Refuser visible (destructif)', (
    WidgetTester tester,
  ) async {
    await _monter(tester, const Size(1440, 900));
    await _ouvrirDossiers(tester);
    expect(find.text('Refuser le dossier'), findsOneWidget);
    await _taperTexte(tester, 'Refuser le dossier');
    // AD-8 : le motif est dans 02D (dialogue a 1440), plus en ligne.
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text(t.dossiers.refus.corps), findsOneWidget);
    final ActionPrincipale confirmer = tester.widget<ActionPrincipale>(
      find
          .ancestor(
            of: find.text('Refuser le dossier').last,
            matching: find.byType(ActionPrincipale),
          )
          .first,
    );
    expect(confirmer.niveau, NiveauAction.destructive);
    expect(confirmer.pleineLargeur, isFalse);
    // Un seul bouton destructif dans la surface : l'autre est Annuler.
    expect(find.text(t.commun.annuler), findsOneWidget);
    // 02D s'ouvre sur le champ.
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'adm02d-motif');
  });

  testWidgets('1440 : les cases repartent a zero en changeant de dossier', (
    WidgetTester tester,
  ) async {
    await _monter(tester, const Size(1440, 900));
    await _ouvrirDossiers(tester);
    await _taperTexte(tester, _points[0]);
    await _taperTexte(tester, _points[1]);
    await tester.tap(_ligne('Amina'));
    await _stabiliser(tester);
    for (final String p in _points) {
      expect(_coche(tester, p), isFalse);
    }
    await tester.tap(_ligne('Omar'));
    await _stabiliser(tester);
    for (final String p in _points) {
      expect(_coche(tester, p), isFalse);
    }
  });

  testWidgets('1440 : geometrie du groupe d actions (contrat B)', (
    WidgetTester tester,
  ) async {
    await _monter(tester, const Size(1440, 900));
    await _ouvrirDossiers(tester);
    for (final String p in _points) {
      await _taperTexte(tester, p);
    }
    final Finder refuser = find
        .ancestor(
          of: find.text('Refuser le dossier'),
          matching: find.byType(ActionPrincipale),
        )
        .first;
    final Finder valider = find
        .ancestor(
          of: find.text('Valider le dossier'),
          matching: find.byType(ActionPrincipale),
        )
        .first;
    await tester.ensureVisible(valider);
    await _stabiliser(tester);
    final Rect r = tester.getRect(refuser);
    final Rect v = tester.getRect(valider);
    expect(r.right <= v.left, isTrue);
    expect(r.top, v.top);
    expect(v.left - r.right, 8);
    final Rect carte = tester.getRect(find.byType(GroupeReglages).last);
    expect(v.right, closeTo(carte.right, 0.5));
    expect(v.top - carte.bottom, closeTo(16, 0.5));
    expect(v.width < 728 && r.width < 728, isTrue);
    expect(
      tester.widget<ActionPrincipale>(refuser).niveau,
      NiveauAction.destructive,
    );
    expect(
      tester
          .widgetList<ActionPrincipale>(find.byType(ActionPrincipale))
          .where((ActionPrincipale a) => a.niveau == NiveauAction.principale),
      hasLength(1),
    );
  });

  // 200 % : le controle de fin de ligne d'un `GroupeReglages` (« Voir la
  // piece ») passe sous le libelle au lieu de deborder (AD-6, corrections).
  for (final double texte in <double>[1, 2]) {
    testWidgets('390 a ${texte * 100} % : actions dans la marge de 16', (
      WidgetTester tester,
    ) async {
      await _monter(tester, const Size(390, 844));
      await _ouvrir(tester, 'Omar');
      // Le texte grandit une fois le dossier ouvert : le tiroir de la coque a
      // 200 % n'est pas l'objet de ce test (hors AD-6).
      tester.platformDispatcher.textScaleFactorTestValue = texte;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _stabiliser(tester);
      final Object? erreur = tester.takeException();
      expect(erreur, isNull, reason: '$erreur');
      Rect bouton(String libelle) => tester.getRect(
        find
            .ancestor(
              of: find.text(libelle),
              matching: find.byType(ActionPrincipale),
            )
            .first,
      );
      // HL-A-5 : Valider ferme n'est pas rendu ; le lien tient sa place au
      // bord de debut, puis Refuser en pleine largeur dessous.
      expect(find.text('Valider le dossier'), findsNothing);
      await tester.ensureVisible(find.text('Refuser le dossier'));
      await _stabiliser(tester);
      final Rect lien = tester.getRect(
        find.text('Terminez les vérifications requises.'),
      );
      Rect r = bouton('Refuser le dossier');
      expect(r.left, closeTo(16, 0.5));
      expect(r.right, closeTo(374, 0.5));
      // Texte du lien : bord de debut + le retrait de LienFleche (xs, 4).
      expect(lien.left, closeTo(16 + 4, 0.5));
      expect(lien.bottom <= r.top, isTrue);
      // Pret : Valider en pleine largeur, Refuser dessous.
      for (final String p in _points) {
        await _taperTexte(tester, p);
      }
      await tester.ensureVisible(find.text('Refuser le dossier'));
      await _stabiliser(tester);
      final Rect v = bouton('Valider le dossier');
      r = bouton('Refuser le dossier');
      for (final Rect b in <Rect>[v, r]) {
        expect(b.left, closeTo(16, 0.5));
        expect(b.right, closeTo(374, 0.5));
      }
      expect(v.bottom <= r.top, isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('1440 : le lien des verifications tient la place de Valider', (
    WidgetTester tester,
  ) async {
    await _monter(tester, const Size(1440, 900));
    await _ouvrirDossiers(tester);
    expect(find.text('Valider le dossier'), findsNothing);
    final Rect carte = tester.getRect(find.byType(GroupeReglages).last);
    final Rect lien = tester.getRect(
      find.text('Terminez les vérifications requises.'),
    );
    // Ligne d'etat au bord de debut, sous Refuser.
    // Texte du lien : bord de debut + le retrait de LienFleche (xs, 4).
    expect(lien.left, closeTo(carte.left + 4, 0.5));
    expect(
      lien.top,
      greaterThan(tester.getRect(find.text('Refuser le dossier')).bottom),
    );
  });

  for (final (String prenom, String texte, bool validerFerme, bool refuserFerme)
      in <(String, String, bool, bool)>[
        ('Sofia', 'Un accord requis manque à ce dossier.', true, false),
        ('Nabil', 'La décision est indisponible pour le moment.', true, false),
        (
          'Adam',
          'Ce dossier ne peut pas être refusé dans son état actuel.',
          true,
          true,
        ),
        ('Yanis', 'La pièce requise n’a pas été transmise.', true, false),
      ]) {
    testWidgets('390 : $prenom -> $texte', (WidgetTester tester) async {
      await _monter(tester, const Size(390, 844));
      await _ouvrir(tester, prenom);
      // Yanis : la raison est dite une fois, dans la carte ; l'emplacement
      // de decision dit « pas pret » (HL-A-5, §10.11).
      expect(find.text(texte), findsOneWidget);
      if (prenom == 'Yanis') {
        expect(find.text(t.dossiers.revue.pasPret), findsOneWidget);
      }
      // Un bouton ferme n'est pas rendu : sa raison tient sa place.
      expect(
        find.text('Valider le dossier'),
        validerFerme ? findsNothing : findsOneWidget,
      );
      expect(
        find.text('Refuser le dossier'),
        refuserFerme ? findsNothing : findsOneWidget,
      );
      if (prenom == 'Yanis' || prenom == 'Adam') {
        // §10.4 : la carte reste, sans case active ni cochee (absence de
        // controle, pas controle negatif).
        expect(find.text('Vérifications'), findsOneWidget);
        for (final String p in _points) {
          expect(find.text(p), findsOneWidget);
          expect(_coche(tester, p), isFalse);
          await tester.tap(find.text(p), warnIfMissed: false);
          await _stabiliser(tester);
          expect(_coche(tester, p), isFalse);
        }
      }
    });
  }

  testWidgets('1440 : Sofia montre ses accords acceptes', (
    WidgetTester tester,
  ) async {
    await _monter(tester, const Size(1440, 900));
    await _ouvrir(tester, 'Sofia');
    expect(find.text('Accords et éléments soumis'), findsOneWidget);
  });

  testWidgets('1440 : hors ligne, decisions fermees, Reessayer relit', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      const Size(1440, 900),
      plus: <Override>[
        horsLigneProvider.overrideWith((Ref ref) => Stream<bool>.value(true)),
      ],
    );
    await _ouvrirDossiers(tester);
    expect(
      find.text('Vous êtes hors ligne. Aucune décision ne peut être envoyée.'),
      findsOneWidget,
    );
    expect(find.text('Valider le dossier'), findsNothing);
    expect(find.text('Refuser le dossier'), findsNothing);
    await _taperTexte(tester, t.commun.reessayer);
    expect(find.text("Dossier d'Omar Haddad"), findsOneWidget);
  });

  testWidgets('1440 : permission perdue, detail purge, retour aux dossiers', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      const Size(1440, 900),
      plus: <Override>[
        dossierPourRevueProvider.overrideWith(
          (Ref ref, String id) =>
              throw const ErreurRevueDossier(CodeErreurRevue.interdit),
        ),
      ],
    );
    await _ouvrirDossiers(tester);
    expect(find.text('Vous n’avez plus accès à ce dossier.'), findsOneWidget);
    expect(find.text('Nom'), findsNothing);
    expect(find.text(_points[0]), findsNothing);
    await _taperTexte(tester, 'Retour aux dossiers');
    expect(find.text(t.dossiers.file.aucuneSelection), findsOneWidget);
  });

  testWidgets('1440 : chargement, aucune decision dans l arbre', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      const Size(1440, 900),
      plus: <Override>[
        dossierPourRevueProvider.overrideWith(
          (Ref ref, String id) => _jamais(),
        ),
      ],
    );
    await _ouvrirDossiers(tester);
    expect(find.text('Chargement du dossier…'), findsOneWidget);
    expect(find.text('Valider le dossier'), findsNothing);
    expect(find.text('Refuser le dossier'), findsNothing);
  });

  testWidgets('1440 : Lina, dossier modifie puis Actualiser le dossier', (
    WidgetTester tester,
  ) async {
    await _monter(tester, const Size(1440, 900));
    await _ouvrir(tester, 'Lina');
    for (final String p in _points) {
      await _taperTexte(tester, p);
    }
    expect(_bouton(tester, 'Valider le dossier').onPress, isNotNull);
    await _taperTexte(tester, 'Valider le dossier');
    // 02E s'ouvre sur Annuler ; la confirmation est le dernier « Valider ».
    expect(find.text(t.dossiers.validation.titre), findsOneWidget);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'surface-annuler');
    await tester.tap(find.text('Valider le dossier').last);
    await _stabiliser(tester);
    expect(
      find.text(t.dossiers.decision.conflit),
      findsOneWidget,
      reason: find
          .byType(Text)
          .evaluate()
          .map((Element e) => (e.widget as Text).data)
          .join(' | '),
    );
    // Conflit : la confirmation disparait, seul « Actualiser le dossier ».
    expect(find.text('Valider le dossier'), findsOneWidget);
    await tester.tap(find.text('Actualiser le dossier').last);
    await _stabiliser(tester);
    expect(find.text(t.dossiers.decision.conflit), findsNothing);
    expect(find.text(t.dossiers.validation.titre), findsNothing);
  });
}
