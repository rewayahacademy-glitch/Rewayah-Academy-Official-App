// CAND-07 : la tuile « Vos autres talents » du portail `/attente`, sous la tuile
// de partage. Ce que le test prouve :
// - sobre : une carte entiere qui se touche, un titre, une ligne ; aucun bouton
//   plein de plus (le portail garde son action unique) ;
// - elle ne se rend que si le serveur dit que c'est ouvert, ou s'il reste des
//   reponses a relire ou a retirer : jamais pendant la lecture, jamais en cas
//   d'echec, jamais sans lot serveur, jamais avant l'envoi de la candidature ;
// - sa ligne dit l'etat : facultatif, reponses enregistrees (a modifier), ou
//   enregistrees (a retirer) apres un refus ou un retrait ;
// - elle est sous la tuile de partage ;
// - elle mene a la page.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/permission_insuffisante.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/partage_offre/lien_offre.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/features/dossier/attente_page.dart';
import 'package:rewayah_academy/features/talents/talents_page.dart';
import 'package:rewayah_academy/features/talents/tuile_talents.dart';

import '../../fixtures/candidature/faux_autres_competences.dart';
import '../../support/garde_interface.dart';
import '../../support/harnais.dart';
import 'hote_talents.dart';

Finder _texte(String t) => find.text(t);

Finder get _tuile => find.byKey(TuileTalents.tuileKey);

/// Le portail, avec ou sans lien d'offre (la tuile de partage).
Future<void> _portail(
  WidgetTester tester, {
  required FauxAutresCompetences? port,
  CandidatureDossier candidature = candidatureEnvoyee,
  bool lienOffre = false,
  bool horsLigne = false,
  Size taille = const Size(390, 844),
  double echelle = 1,
  TextDirection? direction,
  bool attendre = true,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final List<Override> surcharges = <Override>[
    ...surchargesTalents(
      port: port,
      etat: etatEnvoye(candidature: candidature),
      horsLigne: horsLigne,
    ),
    lienOffreProvider.overrideWithValue(
      lienOffre ? Uri.parse('https://exemple.test/fr/') : null,
    ),
  ];
  await tester.pumpWidget(
    hoteRoutant(
      depart: Routes.attente,
      routes: routesTalents(),
      surcharges: surcharges,
      echelle: echelle,
      direction: direction,
    ),
  );
  if (attendre) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

Map<String, dynamic> _reponduEnCours() =>
    autresCompetencesJsonDeTest(version: 2, reponses: reponsesJsonDeTest());

void main() {
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('quand elle se rend', () {
    testWidgets('ouvert, sans reponse : le titre et « facultatif »', (
      WidgetTester tester,
    ) async {
      await _portail(tester, port: FauxAutresCompetences());
      expect(_tuile, findsOneWidget);
      expect(
        find.descendant(
          of: _tuile,
          matching: _texte(t.recrutement.talents.titre),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _tuile,
          matching: _texte(t.recrutement.talents.tuile.facultatif),
        ),
        findsOneWidget,
      );
      // Rien d'autre sur le portail ne change : une seule action pleine ou
      // aucune.
      verifierUnSeulBoutonPlein(tester);
    });

    testWidgets('des reponses enregistrees, encore ouvert : on peut les '
        'modifier', (WidgetTester tester) async {
      await _portail(
        tester,
        port: FauxAutresCompetences(lectureJson: _reponduEnCours()),
      );
      expect(
        find.descendant(
          of: _tuile,
          matching: _texte(t.recrutement.talents.tuile.enregistre),
        ),
        findsOneWidget,
      );
      expect(_texte(t.recrutement.talents.tuile.facultatif), findsNothing);
    });

    testWidgets('candidature refusee, des reponses a retirer : la tuile reste '
        'et le dit', (WidgetTester tester) async {
      await _portail(
        tester,
        port: FauxAutresCompetences(
          lectureJson: autresCompetencesJsonDeTest(
            ouvert: false,
            raison: 'candidature_close',
            version: 2,
            reponses: reponsesJsonDeTest(),
          ),
        ),
        candidature: const CandidatureDossier(
          existe: true,
          etape: EtapeCandidature.prequalification,
          etat: EtatCandidature.enExamen,
          issue: IssueCandidature.refusee,
          version: 5,
        ),
      );
      expect(
        find.descendant(
          of: _tuile,
          matching: _texte(t.recrutement.talents.tuile.enregistreClose),
        ),
        findsOneWidget,
      );
    });

    testWidgets('en arabe, de droite a gauche', (WidgetTester tester) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      await _portail(
        tester,
        port: FauxAutresCompetences(),
        direction: TextDirection.rtl,
      );
      expect(_tuile, findsOneWidget);
      expect(_texte('مواهبك الأخرى'), findsOneWidget);
      expect(_texte(t.recrutement.talents.tuile.facultatif), findsOneWidget);
    });
  });

  group('quand elle ne se rend pas', () {
    testWidgets('candidature non envoyee : pas de tuile', (
      WidgetTester tester,
    ) async {
      await _portail(
        tester,
        port: FauxAutresCompetences(
          lectureJson: autresCompetencesJsonDeTest(
            ouvert: false,
            raison: 'questionnaire_non_envoye',
          ),
        ),
      );
      expect(_tuile, findsNothing);
    });

    testWidgets('candidature terminee sans reponse : pas de tuile', (
      WidgetTester tester,
    ) async {
      await _portail(
        tester,
        port: FauxAutresCompetences(
          lectureJson: autresCompetencesJsonDeTest(
            ouvert: false,
            raison: 'candidature_close',
          ),
        ),
      );
      expect(_tuile, findsNothing);
    });

    testWidgets('sans lot serveur : pas de tuile, jamais une entree qui ne '
        'mene nulle part', (WidgetTester tester) async {
      await _portail(tester, port: null);
      expect(_tuile, findsNothing);
      expect(find.textContaining('CAND-BR'), findsNothing);
    });

    testWidgets('lecture en echec : pas de tuile, le portail reste lisible', (
      WidgetTester tester,
    ) async {
      await _portail(
        tester,
        port: FauxAutresCompetences()
          ..erreurLectureDurable = Exception('panne'),
      );
      expect(_tuile, findsNothing);
      expect(_texte(t.attente.titreDossier), findsOneWidget);
    });

    testWidgets('capacite indisponible : pas de tuile', (
      WidgetTester tester,
    ) async {
      await _portail(
        tester,
        port: FauxAutresCompetences()
          ..erreurLectureDurable = const CapaciteIndisponible('CAND-BR-19'),
      );
      expect(_tuile, findsNothing);
    });

    testWidgets('un compte que le serveur ne reconnait pas comme candidat : '
        'pas de tuile', (WidgetTester tester) async {
      await _portail(
        tester,
        port: FauxAutresCompetences()
          ..erreurLectureDurable = const PermissionInsuffisante('x'),
      );
      expect(_tuile, findsNothing);
    });

    testWidgets('pendant la lecture : rien ne clignote', (
      WidgetTester tester,
    ) async {
      final Completer<void> attente = Completer<void>();
      await _portail(
        tester,
        port: FauxAutresCompetences()..attente = attente,
        attendre: false,
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(_tuile, findsNothing);
      attente.complete();
      await tester.pumpAndSettle();
      expect(_tuile, findsOneWidget);
    });

    testWidgets('un compte sans candidature : pas de tuile', (
      WidgetTester tester,
    ) async {
      await _portail(
        tester,
        port: FauxAutresCompetences(),
        candidature: const CandidatureDossier(),
      );
      expect(_tuile, findsNothing);
    });
  });

  group('sa place et son geste', () {
    testWidgets('sous la tuile de partage, jamais au-dessus', (
      WidgetTester tester,
    ) async {
      await _portail(tester, port: FauxAutresCompetences(), lienOffre: true);
      final Finder partage = find.byKey(
        const ValueKey<String>('portail-partage'),
      );
      expect(partage, findsOneWidget);
      expect(_tuile, findsOneWidget);
      expect(
        tester.getTopLeft(_tuile).dy,
        greaterThan(tester.getBottomLeft(partage).dy - 1),
      );
    });

    testWidgets('la carte entiere se touche et mene a la page', (
      WidgetTester tester,
    ) async {
      await _portail(tester, port: FauxAutresCompetences());
      await tester.tap(_tuile);
      await tester.pumpAndSettle();
      expect(find.byType(TalentsPage), findsOneWidget);
      expect(
        GoRouter.of(tester.element(find.byType(TalentsPage))).state.uri.path,
        Routes.attenteTalents,
      );
      expect(_texte(t.recrutement.talents.intro.texte), findsOneWidget);
    });

    testWidgets('la tuile se lit en une phrase pour un lecteur d ecran', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle poignee = tester.ensureSemantics();
      await _portail(tester, port: FauxAutresCompetences());
      final SemanticsNode noeud = tester.getSemantics(
        find.descendant(of: _tuile, matching: find.byType(AppCard)),
      );
      expect(noeud.label, contains(t.recrutement.talents.titre));
      expect(noeud.label, contains(t.recrutement.talents.tuile.facultatif));
      poignee.dispose();
    });

    testWidgets('une candidature en examen : le portail garde son etat et son '
        'unique action', (WidgetTester tester) async {
      await _portail(tester, port: FauxAutresCompetences());
      expect(_texte(t.recrutement.portail.enExamenTitre), findsOneWidget);
      expect(find.byType(AttentePage), findsOneWidget);
    });
  });
}
