// CAND-06 : la tuile du portail `/attente`, « Aidez une personne a apprendre la
// parole d'Allah. » (« une soeur » pour une femme). Tres peu de mots : le
// directeur, le 22/10/2026, veut « la fierte de participer a un geste noble et
// la simplicite ». Elle parle de la personne qui apprendra, jamais de
// l'academie. Facultative et sans bouton plein : le portail garde une seule
// action pleine. Rendue pour qui candidate encore et seulement quand un lien
// d'offre existe ; le mot suit le genre du profil, jamais devine.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/features/partage_offre/carte_partage.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../fixtures/partage_offre/faux_partage_offre.dart';
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
  Genre? genre,
  FauxGenrePartageur? lectureGenre,
}) => monterPartage(
  tester,
  depart: Routes.attente,
  candidature: candidature,
  sansLien: sansLien,
  taille: taille,
  direction: direction,
  echelle: echelle,
  genre: genre,
  lectureGenre: lectureGenre,
);

String _texte(WidgetTester tester, String cle) => tester
    .widget<Text>(find.descendant(of: _cle(cle), matching: find.byType(Text)))
    .data!;

void main() {
  setUpAll(chargerPolicesDuDepot);
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('la tuile du portail', () {
    testWidgets('a completer et en examen : la tuile, ses deux textes dans l\'ordre '
        '(l\'invitation, puis « Facultatif »)', (WidgetTester tester) async {
      for (final CandidatureDossier c in <CandidatureDossier>[
        candidatureAFaire(),
        _enExamen,
      ]) {
        await _portail(tester, c);
        final c0 = t.recrutement.partage;
        expect(_cle('portail-partage'), findsOneWidget, reason: '${c.etat}');
        expect(find.text(c0.titre), findsOneWidget);
        expect(find.text(c0.facultatif), findsOneWidget);
        expect(
          tester.getTopLeft(_cle('portail-partage-titre')).dy,
          lessThan(tester.getTopLeft(_cle('portail-partage-facultatif')).dy),
        );
        // Rien d'autre : ni explication, ni hadith, ni description de l'offre.
        final Iterable<Text> textes = tester.widgetList<Text>(
          find.descendant(
            of: _cle('portail-partage'),
            matching: find.byType(Text),
          ),
        );
        expect(textes, hasLength(2));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets(
      'les mots du directeur (22/10), tels quels : l\'invitation et la mention '
      'facultative',
      (WidgetTester tester) async {
        final c = t.recrutement.partage;
        expect(c.titre, 'Aidez une personne à apprendre la parole d\'Allah.');
        expect(c.titreFemme, 'Aidez une sœur à apprendre la parole d\'Allah.');
        expect(
          c.facultatif,
          'Facultatif : partager ne change rien à votre candidature.',
        );
        await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
        final a = t.recrutement.partage;
        expect(a.titre, 'ساعد شخصًا على تعلّم كلام الله');
        expect(a.titreFemme, 'ساعدي أختًا على تعلّم كلام الله');
      },
    );

    testWidgets(
      'une femme : « une soeur » ; un homme ou un genre inconnu : « une '
      'personne » ; jamais devine',
      (WidgetTester tester) async {
        final c = t.recrutement.partage;
        await _portail(tester, candidatureAFaire(), genre: Genre.femme);
        expect(_texte(tester, 'portail-partage-titre'), c.titreFemme);
        await _portail(tester, candidatureAFaire(), genre: Genre.homme);
        expect(_texte(tester, 'portail-partage-titre'), c.titre);
        // Genre inconnu : la neutre.
        await _portail(tester, candidatureAFaire());
        expect(_texte(tester, 'portail-partage-titre'), c.titre);
        // Profil illisible : la neutre, la tuile reste.
        await _portail(
          tester,
          candidatureAFaire(),
          lectureGenre: FauxGenrePartageur(genre: Genre.femme)
            ..erreur = StateError('hors ligne'),
        );
        expect(_texte(tester, 'portail-partage-titre'), c.titre);
        expect(_cle('portail-partage'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'en arabe, au feminin pour une femme : « ساعدي أختًا على تعلّم كلام الله »',
      (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
        await _portail(
          tester,
          candidatureAFaire(),
          genre: Genre.femme,
          direction: TextDirection.rtl,
        );
        expect(
          _texte(tester, 'portail-partage-titre'),
          'ساعدي أختًا على تعلّم كلام الله',
        );
        await _portail(
          tester,
          candidatureAFaire(),
          genre: Genre.homme,
          direction: TextDirection.rtl,
        );
        expect(
          _texte(tester, 'portail-partage-titre'),
          'ساعد شخصًا على تعلّم كلام الله',
        );
      },
    );

    testWidgets(
      'aucun texte de la tuile ne demande d\'agir pour l\'academie : son nom '
      'n\'est jamais le motif, en francais comme en arabe, pour les deux genres',
      (WidgetTester tester) async {
        for (final AppLocale langue in <AppLocale>[
          AppLocale.fr,
          AppLocale.ar,
        ]) {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          for (final Genre? genre in <Genre?>[null, Genre.femme]) {
            await _portail(
              tester,
              candidatureAFaire(),
              genre: genre,
              direction: langue == AppLocale.ar ? TextDirection.rtl : null,
            );
            final Iterable<String> textes = <String>[
              for (final String cle in <String>[
                'portail-partage-titre',
                'portail-partage-facultatif',
              ])
                _texte(tester, cle),
            ];
            for (final String texte in textes) {
              for (final String mot in motsQuiNommentLAcademie) {
                expect(texte, isNot(contains(mot)), reason: '$langue : $texte');
              }
              for (final String demande in <String>[
                'faites connaître',
                'pour nous',
                'nous aider',
                'aidez-nous',
                'عرّفوا',
                'ساعدونا',
                'ساعدنا',
              ]) {
                expect(
                  texte.toLowerCase(),
                  isNot(contains(demande)),
                  reason: '$langue : $texte',
                );
              }
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
      await tester.ensureVisible(_cle('portail-partage-titre'));
      await tester.pump();
      await tester.tap(_cle('portail-partage-titre'));
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
            genre: Genre.femme,
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
            genre: Genre.femme,
          );
          expect(tester.takeException(), isNull);
          expect(_cle('portail-partage'), findsOneWidget);
          expect(find.text(t.recrutement.partage.titreFemme), findsOneWidget);
          expect(find.text(t.recrutement.partage.facultatif), findsOneWidget);
        },
      );
    }
  });
}
