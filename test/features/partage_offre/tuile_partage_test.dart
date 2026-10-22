// CAND-06 : la tuile « Un proche veut apprendre le Coran ? » du portail
// `/attente`. Elle parle de la personne qui apprendra, jamais de l'academie
// (consigne du directeur du 22/10/2026). Facultative et sans bouton plein : le
// portail garde une seule action pleine. Rendue pour qui candidate encore et
// seulement quand un lien d'offre existe.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/features/partage_offre/carte_partage.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/garde_interface.dart';
import '../candidature/hote_candidature.dart';
import 'hote_partage.dart';

Finder _cle(String cle) => find.byKey(ValueKey<String>(cle));

const CandidatureDossier _enExamen = CandidatureDossier(
  existe: true,
  etape: EtapeCandidature.prequalification,
  etat: EtatCandidature.enExamen,
  version: 4,
);

Future<void> _portail(
  WidgetTester tester,
  CandidatureDossier candidature, {
  bool sansLien = false,
  Size taille = const Size(390, 844),
  TextDirection? direction,
  double echelle = 1,
}) => monterPartage(
  tester,
  depart: Routes.attente,
  candidature: candidature,
  sansLien: sansLien,
  taille: taille,
  direction: direction,
  echelle: echelle,
);

void main() {
  setUpAll(chargerPolicesDuDepot);
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('la tuile du portail', () {
    testWidgets(
      'a completer et en examen : la tuile, ses quatre textes dans l\'ordre '
      '(la question, ce que la personne y gagne, le motif, facultatif)',
      (WidgetTester tester) async {
        for (final CandidatureDossier c in <CandidatureDossier>[
          candidatureAFaire(),
          _enExamen,
        ]) {
          await _portail(tester, c);
          final c0 = t.recrutement.partage;
          expect(_cle('portail-partage'), findsOneWidget, reason: '${c.etat}');
          expect(find.text(c0.titre), findsOneWidget);
          expect(find.text(c0.introduction), findsOneWidget);
          expect(find.text(c0.motif), findsOneWidget);
          expect(find.text(c0.facultatif), findsOneWidget);
          double haut(String cle) => tester.getTopLeft(_cle(cle)).dy;
          expect(
            haut('portail-partage-titre'),
            lessThan(haut('portail-partage-texte')),
          );
          expect(
            haut('portail-partage-texte'),
            lessThan(haut('portail-partage-motif')),
          );
          expect(
            haut('portail-partage-motif'),
            lessThan(haut('portail-partage-facultatif')),
          );
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'les mots de la consigne du directeur (22/10) : la question, le texte, '
      'le motif et la mention facultative',
      (WidgetTester tester) async {
        final c = t.recrutement.partage;
        expect(c.titre, 'Un proche veut apprendre le\u00a0Coran\u00a0?');
        expect(
          c.introduction,
          'Envoyez-lui l\'offre en un geste\u00a0: il apprendra en petite '
          'classe, en visio, avec le même enseignant chaque semaine.',
        );
        expect(
          c.facultatif,
          'Facultatif\u00a0: partager ne change rien à votre candidature.',
        );
        // Le hadith est le motif de celui qui partage, pas de l'academie.
        expect(c.motif, contains('celui qui indique le bien'));
        expect(c.motif, contains('Pour vous aussi'));
      },
    );

    testWidgets(
      'aucun texte de la tuile ne demande d\'agir pour l\'academie : son nom '
      'n\'est jamais le motif, en francais comme en arabe',
      (WidgetTester tester) async {
        for (final AppLocale langue in <AppLocale>[
          AppLocale.fr,
          AppLocale.ar,
        ]) {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          await _portail(
            tester,
            candidatureAFaire(),
            direction: langue == AppLocale.ar ? TextDirection.rtl : null,
          );
          final Iterable<String> textes = <String>[
            for (final String cle in <String>[
              'portail-partage-titre',
              'portail-partage-texte',
              'portail-partage-motif',
              'portail-partage-facultatif',
            ])
              tester
                  .widget<Text>(
                    find.descendant(of: _cle(cle), matching: find.byType(Text)),
                  )
                  .data!,
          ];
          for (final String texte in textes) {
            for (final String mot in motsQuiNommentLAcademie) {
              expect(texte, isNot(contains(mot)), reason: '$langue : $texte');
            }
          }
        }
      },
    );

    testWidgets(
      'le portail garde un seul bouton plein, la tuile n\'en ajoute aucun',
      (WidgetTester tester) async {
        await _portail(tester, candidatureAFaire());
        verifierUnSeulBoutonPlein(tester);
        final int pleins = find
            .byWidgetPredicate(
              (Widget w) =>
                  w is ActionPrincipale && w.niveau == NiveauAction.principale,
            )
            .evaluate()
            .length;
        expect(pleins, 1);
        // En examen : aucune action pleine, la tuile n'en cree pas non plus.
        await _portail(tester, _enExamen);
        verifierUnSeulBoutonPlein(tester);
        expect(
          find
              .byWidgetPredicate(
                (Widget w) =>
                    w is ActionPrincipale &&
                    w.niveau == NiveauAction.principale,
              )
              .evaluate(),
          isEmpty,
        );
      },
    );

    testWidgets('toucher la tuile ouvre la page de partage', (
      WidgetTester tester,
    ) async {
      await _portail(tester, _enExamen);
      await tester.ensureVisible(find.text(t.recrutement.partage.titre));
      await tester.pump();
      await tester.tap(find.text(t.recrutement.partage.titre));
      await tester.pumpAndSettle();
      expect(find.byType(CartePartage), findsOneWidget);
      expect(find.text(t.recrutement.partage.facultatif), findsOneWidget);
    });

    testWidgets('la tuile se place sous l\'etat et sa prochaine action', (
      WidgetTester tester,
    ) async {
      await _portail(tester, candidatureAFaire());
      final double tuile = tester.getTopLeft(_cle('portail-partage')).dy;
      expect(
        tester.getTopLeft(find.text(t.recrutement.portail.aCompleterTitre)).dy,
        lessThan(tuile),
      );
      expect(
        tester.getBottomLeft(find.text(t.recrutement.portail.completer)).dy,
        lessThan(tuile),
      );
    });

    testWidgets('en pause : la tuile reste proposee', (
      WidgetTester tester,
    ) async {
      await _portail(tester, candidatureAFaire(enPause: true));
      expect(_cle('portail-partage'), findsOneWidget);
    });

    testWidgets('refusee ou retiree : pas de tuile', (
      WidgetTester tester,
    ) async {
      for (final IssueCandidature issue in <IssueCandidature>[
        IssueCandidature.refusee,
        IssueCandidature.retiree,
      ]) {
        await _portail(
          tester,
          CandidatureDossier(
            existe: true,
            etape: EtapeCandidature.prequalification,
            etat: EtatCandidature.enExamen,
            issue: issue,
            version: 5,
          ),
        );
        expect(_cle('portail-partage'), findsNothing, reason: '$issue');
        expect(find.text(t.recrutement.partage.titre), findsNothing);
      }
    });

    testWidgets('aucune candidature pour ce compte : pas de tuile', (
      WidgetTester tester,
    ) async {
      await _portail(tester, const CandidatureDossier());
      expect(_cle('portail-partage'), findsNothing);
    });

    testWidgets(
      'sans lien d\'offre : la tuile n\'est pas rendue (elle mene a une carte '
      'qui ne peut pas exister)',
      (WidgetTester tester) async {
        await _portail(tester, candidatureAFaire(), sansLien: true);
        expect(_cle('portail-partage'), findsNothing);
        expect(find.text(t.recrutement.partage.titre), findsNothing);
      },
    );

    for (final Size taille in const <Size>[
      Size(320, 640),
      Size(390, 844),
      Size(1440, 900),
    ]) {
      testWidgets(
        'a ${taille.width.toInt()}, texte x2 : la tuile ne deborde pas, en '
        'francais puis en arabe de droite a gauche',
        (WidgetTester tester) async {
          await _portail(
            tester,
            candidatureAFaire(),
            taille: taille,
            echelle: 2,
          );
          expect(tester.takeException(), isNull);
          expect(_cle('portail-partage'), findsOneWidget);
          await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
          await _portail(
            tester,
            candidatureAFaire(),
            taille: taille,
            direction: TextDirection.rtl,
            echelle: 2,
          );
          expect(tester.takeException(), isNull);
          expect(_cle('portail-partage'), findsOneWidget);
          expect(find.text(t.recrutement.partage.titre), findsOneWidget);
          expect(find.text(t.recrutement.partage.introduction), findsOneWidget);
        },
      );
    }
  });
}
