// DYNAMIQUE-CHRONO-1 (directeur, 12/11/2026, seance reelle : « le chrono
// cache le document ; a refaire pour que rien ne cache rien », points 2, 3, 5
// et 15 de `docs/current/salle/PLAN-RETOURS-2026-11-12.md`).
//
// Dans la vraie page `/salle` (`SallePage`, faux moteur du harnais, page 42
// du Coran presentee, chrono servi, pause programmee chez l'enseignant), a
// 320 (texte x2), 390, 834, 1280 et 1440, eleve et enseignant :
//
// (a) la Dynamique chrono repliee et la page ne se coupent jamais ;
// (b) la mention permanente et le mot d'etat ne coupent pas la page ;
// (c) sur ordinateur, la barre depliee tient entiere dans la tete de la
//     colonne, rien dessous (ni la colonne des commandes, ni le panneau) ;
// (d) le mot « Reste » est visible ;
// (e) un toucher deplie, les marques se lisent en mots, elle se replie seule ;
// (f) en arabe (de droite a gauche) a 390 ;
// (g) mouvement reduit : pas d'animation, l'information reste.
//
// Captures de test et rendu du faux moteur : ce n'est pas la preuve en
// production.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/core/widgets/ligne_presence.dart';
import 'package:rewayah_academy/core/widgets/permanent_notice.dart';
import 'package:rewayah_academy/features/salle_seance/chrono_salle.dart';
import 'package:rewayah_academy/features/salle_seance/dynamique_chrono.dart';
import 'package:rewayah_academy/features/salle_seance/salle_ordinateur.dart';
import 'package:rewayah_academy/features/salle_seance/telephone_plein_ecran.dart';

import '../capture/outil_capture.dart';
import '../support/garde_interface.dart';
import '../support/salle_chrono.dart';

final Finder _barre = find.byKey(
  const ValueKey<String>('ligne-etat-telephone'),
);
final Finder _ligneEtat = find.byKey(LigneEtatSalle.cle);
final Finder _zone = find.byKey(ZoneChrono.cle);
final Finder _fondPage = find.byKey(TelephonePleinEcran.cleFondPage);

/// Les cadres : la barre, la ligne d'etat, la zone et la page (sa boite et
/// sa marge) ne se coupent pas ; tout reste dans la fenetre.
void _verifierPlace(WidgetTester tester, Size taille, String cas) {
  expect(tester.takeException(), isNull, reason: cas);
  expect(_barre, findsOneWidget, reason: cas);
  expect(_fondPage, findsOneWidget, reason: cas);
  verifierSansChevauchement(tester, <Finder>[_barre, _fondPage]);
  verifierSansChevauchement(tester, <Finder>[_ligneEtat, _fondPage]);
  verifierSansChevauchement(tester, <Finder>[_zone, _fondPage]);
  final Rect fenetre = (Offset.zero & taille).inflate(toleranceGarde);
  for (final Finder f in <Finder>[_barre, _ligneEtat]) {
    final Rect r = tester.getRect(f);
    expect(
      fenetre.contains(r.topLeft) && fenetre.contains(r.bottomRight),
      isTrue,
      reason: '$cas : $f sort de la fenetre ($r)',
    );
  }
  // Le mot est visible, pas seulement lu.
  expect(find.text(t.salle.seance.chrono.reste), findsOneWidget, reason: cas);
}

Future<void> _deplier(WidgetTester tester) async {
  await tester.tap(find.byKey(DynamiqueChrono.cleDeplier));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  setUpAll(chargerPolicesDuDepot);
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  for (final (Size taille, double texte) in <(Size, double)>[
    (const Size(320, 640), 2),
    (const Size(390, 844), 1),
    (const Size(834, 1194), 1),
    (const Size(1280, 800), 1),
    (const Size(1440, 900), 1),
  ]) {
    for (final String role in <String>['student', 'teacher']) {
      final String nom =
          '$role ${taille.width.toInt()}x${taille.height.toInt()}, '
          'texte x${texte.toInt()}';
      testWidgets('$nom : la barre a sa place, rien ne se coupe ; depliee, '
          'les marques en mots, puis repliee seule', (
        WidgetTester tester,
      ) async {
        await monterSalleChrono(
          tester,
          role: role,
          taille: taille,
          echelleTexte: texte,
          etatEleve: EtatPresence.enRetard,
        );
        _verifierPlace(tester, taille, nom);
        // La mention permanente reste visible (ADR-011), hors de la barre.
        expect(find.byType(PermanentNotice), findsOneWidget);
        expect(
          find.descendant(of: _barre, matching: find.byType(PermanentNotice)),
          findsNothing,
        );
        final Rect place = tester.getRect(_barre);
        final Rect page = tester.getRect(_fondPage);

        await _deplier(tester);
        expect(tester.takeException(), isNull, reason: nom);
        expect(find.byKey(DynamiqueChrono.cleDepliee), findsOneWidget);
        if (role == 'student') {
          // Sa presence en mot : « En retard ».
          expect(
            find.text(LignePresence.libelle(EtatPresence.enRetard)),
            findsOneWidget,
          );
        } else {
          // La pause en mot, et sa commande (capacite `peutPiloter`).
          expect(find.byKey(ChronoSalle.clePause), findsOneWidget);
          expect(find.byKey(ChronoSalle.cleCommandePause), findsOneWidget);
        }
        final bool ordinateur =
            role == 'teacher' && taille.width >= 840;
        if (ordinateur) {
          // (c) Depliee dans la tete de la colonne : entiere, rien dessous.
          final Rect tete = tester.getRect(find.byKey(SalleOrdinateur.cleTete));
          final Rect depliee = tester.getRect(
            find.byKey(DynamiqueChrono.cleDepliee),
          );
          expect(
            tete.inflate(toleranceGarde).contains(depliee.topLeft) &&
                tete.inflate(toleranceGarde).contains(depliee.bottomRight),
            isTrue,
            reason: '$nom : depliee $depliee hors de la tete $tete',
          );
          verifierSansChevauchement(tester, <Finder>[
            find.byKey(DynamiqueChrono.cleDepliee),
            find.byKey(SalleOrdinateur.cleCommandes),
          ]);
          verifierSansChevauchement(tester, <Finder>[
            find.byKey(SalleOrdinateur.cleTete),
            _fondPage,
          ]);
          // Le lien de la pause est touchable (rien ne le cache).
          expect(
            find.byKey(ChronoSalle.cleCommandePause).hitTestable(),
            findsOneWidget,
          );
        } else {
          // Telephone et tablette : depliee par-dessus un instant, la place
          // reservee et la page ne bougent pas.
          expect(tester.getRect(_barre), place);
          expect(tester.getRect(_fondPage), page);
        }

        await tester.pump(AppMouvement.dynamiqueChronoDepliee);
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.byKey(DynamiqueChrono.cleDepliee), findsNothing);
        _verifierPlace(tester, taille, '$nom, repliee de nouveau');
      });
    }
  }

  testWidgets('arabe, eleve et enseignant 390 : la barre au bord de debut '
      '(a droite), rien ne se coupe', (WidgetTester tester) async {
    await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
    for (final String role in <String>['student', 'teacher']) {
      await monterSalleChrono(
        tester,
        role: role,
        taille: const Size(390, 844),
        etatEleve: EtatPresence.enRetard,
      );
      _verifierPlace(tester, const Size(390, 844), 'ar $role');
      // De droite a gauche : la barre commence au bord droit.
      expect(tester.getRect(_barre).right, moreOrLessEquals(390 - 16));
      await _deplier(tester);
      expect(tester.takeException(), isNull);
      expect(
        tester.getRect(find.byKey(DynamiqueChrono.cleDepliee)).right,
        lessThanOrEqualTo(390),
      );
    }
  });

  testWidgets('mouvement reduit : pas d animation, l information reste', (
    WidgetTester tester,
  ) async {
    await monterSalleChrono(
      tester,
      role: 'student',
      taille: const Size(390, 844),
      mouvementReduit: true,
      etatEleve: EtatPresence.enRetard,
    );
    _verifierPlace(tester, const Size(390, 844), 'reduit');
    await tester.tap(find.byKey(DynamiqueChrono.cleDeplier));
    await tester.pump();
    // D'un coup : depliee des la premiere image, le mot lisible.
    expect(find.byKey(DynamiqueChrono.cleDepliee), findsOneWidget);
    expect(
      find.text(LignePresence.libelle(EtatPresence.enRetard)),
      findsOneWidget,
    );
    await tester.pump(AppMouvement.dynamiqueChronoDepliee);
    await tester.pump();
    expect(find.byKey(DynamiqueChrono.cleDepliee), findsNothing);
    expect(find.text(t.salle.seance.chrono.reste), findsOneWidget);
  });

  // Directeur, 12/11/2026 (sur les captures d'ordinateur : « le dynamique
  // timing pose sur les panneaux et la barre ») : sur ordinateur et tablette
  // (840 et plus), rien de la zone d'etat (titre du document, barre repliee
  // ou depliee, mot d'etat, mention) ne coupe la colonne des commandes, un
  // panneau, la page ou ses boutons de marge, dans les quatre compositions.
  for (final Size taille in <Size>[
    const Size(1024, 768),
    const Size(1180, 820),
    const Size(1280, 800),
    const Size(1440, 900),
  ]) {
    for (final String composition in <String>[
      'deux panneaux',
      'Eleves seul',
      'Bibliotheque seule',
      'focus',
    ]) {
      final String nom =
          'ordinateur ${taille.width.toInt()}x${taille.height.toInt()}, '
          '$composition';
      testWidgets('$nom : la zone d etat ne coupe ni panneau, ni colonne, ni '
          'page, repliee comme depliee', (WidgetTester tester) async {
        await monterSalleChrono(
          tester,
          role: 'teacher',
          taille: taille,
          etatEleve: EtatPresence.enRetard,
        );
        Future<void> toucher(String cle) async {
          await tester.tap(find.byKey(ValueKey<String>(cle)));
          await tester.pumpAndSettle();
        }

        final bool gauche = find
            .byKey(SalleOrdinateur.cleGauche)
            .evaluate()
            .isNotEmpty;
        final bool droite = find
            .byKey(SalleOrdinateur.cleDroite)
            .evaluate()
            .isNotEmpty;
        switch (composition) {
          case 'deux panneaux':
            if (!gauche) await toucher('salle-eleves');
            if (!droite) await toucher('salle-bibliotheque');
          case 'Eleves seul':
            if (!gauche) await toucher('salle-eleves');
            if (droite) await toucher('salle-bibliotheque');
          case 'Bibliotheque seule':
            if (gauche) await toucher('salle-eleves');
            if (!droite) await toucher('salle-bibliotheque');
          case 'focus':
            await tester.tap(find.byKey(SalleOrdinateur.cleFocus));
            await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull, reason: nom);
        void verifier(String etat) {
          final List<Finder> zone = <Finder>[
            find.byKey(SalleOrdinateur.cleTete),
            _barre,
            _ligneEtat,
            if (find.byKey(DynamiqueChrono.cleDepliee).evaluate().isNotEmpty)
              find.byKey(DynamiqueChrono.cleDepliee),
          ];
          final List<Finder> autres = <Finder>[
            for (final Key k in <Key>[
              SalleOrdinateur.cleCommandes,
              SalleOrdinateur.cleGauche,
              SalleOrdinateur.cleDroite,
              SalleOrdinateur.cleSupport,
              TelephonePleinEcran.cleFondPage,
              const ValueKey<String>('fleches-page-salle'),
            ])
              if (find.byKey(k).evaluate().isNotEmpty) find.byKey(k),
          ];
          expect(_barre, findsOneWidget, reason: '$nom, $etat');
          expect(_ligneEtat, findsOneWidget, reason: '$nom, $etat');
          for (final Finder z in zone) {
            for (final Finder a in autres) {
              final Rect rz = tester.getRect(z);
              final Rect ra = tester.getRect(a);
              final Rect commun = rz.intersect(ra);
              expect(
                commun.width > toleranceGarde && commun.height > toleranceGarde,
                isFalse,
                reason: '$nom, $etat : $z ($rz) coupe $a ($ra)',
              );
            }
          }
          expect(
            find.text(t.salle.seance.chrono.reste),
            findsOneWidget,
            reason: '$nom, $etat',
          );
        }

        verifier('repliee');
        await _deplier(tester);
        expect(tester.takeException(), isNull, reason: nom);
        expect(find.byKey(ChronoSalle.cleCommandePause), findsOneWidget);
        expect(
          find.byKey(ChronoSalle.cleCommandePause).hitTestable(),
          findsOneWidget,
          reason: '$nom : la commande de la pause est cachee',
        );
        verifier('depliee');
      });
    }
  }
}
