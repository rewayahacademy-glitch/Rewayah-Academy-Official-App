// MAJEUR (directeur, 16/11/2026) : « J'ai 18 ans ou plus. »
//
// Ce que les tests prouvent :
// - salle 1 : la question d'age passe avant les questions ; sans la case,
//   « Continuer » n'est pas rendu et une phrase dit pourquoi ; avec la case, la
//   declaration part (vrai) et le parcours s'ouvre ;
// - « J'ai moins de 18 ans » : la confirmation dit l'effet avant, la
//   declaration part (faux) seulement apres « oui », la page bienveillante suit ;
//   « Non, revenir » n'envoie rien ;
// - un echec dit que la reponse n'est pas confirmee et que faire, sans bloquer ;
//   une declaration deja faite se dit ;
// - un serveur d'avant ne pose pas la question : rien ne s'affiche ;
// - candidats avances (page d'attente) : la meme case en tete, la cocher
//   l'enregistre ; rien une fois l'age atteste ; une declaration de moins de 18
//   ans montre la phrase bienveillante, sans case ;
// - 390 et 1440, francais et arabe de droite a gauche.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/port_ma_candidature.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/candidature/coquille_parcours.dart';
import 'package:rewayah_academy/features/candidature/majorite_etape.dart';

import '../../capture/outil_capture.dart';
import '../../fixtures/candidature/faux_ma_candidature.dart';
import '../../support/harnais.dart';
import 'hote_candidature.dart';

const MajoriteCandidature _aFaire = MajoriteCandidature(servie: true);
const MajoriteCandidature _oui = MajoriteCandidature(
  servie: true,
  declaree: true,
);
const MajoriteCandidature _non = MajoriteCandidature(
  servie: true,
  declaree: false,
);

/// Un double qui, comme le serveur, change l'etat relu apres la declaration.
class _PortMajeur extends FauxMaCandidature {
  _PortMajeur(this.dossier, this.candidatureSelon);

  final FauxServiceDossier dossier;
  final CandidatureDossier Function(MajoriteCandidature) candidatureSelon;

  @override
  Future<MajoriteCandidature> attesterMajorite({required bool majeur}) async {
    final MajoriteCandidature m = await super.attesterMajorite(majeur: majeur);
    dossier.etatRendu = etatCandidat(candidature: candidatureSelon(m));
    return m;
  }
}

Finder _cle(Key cle) => find.byKey(cle);

CandidatureDossier _salle1(MajoriteCandidature m) =>
    candidatureAFaire(majorite: m);

CandidatureDossier _enExamen(MajoriteCandidature m) => CandidatureDossier(
  existe: true,
  etape: EtapeCandidature.prequalification,
  etat: EtatCandidature.enExamen,
  enPause: m.moinsDe18,
  version: 4,
  questionnaire: EtatQuestionnaire(envoyeLe: DateTime(2026, 11, 10)),
  majorite: m,
);

/// Monte la page voulue avec un port qui relit l'etat apres la declaration.
Future<_PortMajeur> _monter(
  WidgetTester tester,
  CandidatureDossier Function(MajoriteCandidature) candidature,
  MajoriteCandidature depart, {
  String page = Routes.attenteCandidature,
  Size taille = const Size(390, 844),
  TextDirection? direction,
}) async {
  final FauxServiceDossier dossier = FauxServiceDossier()
    ..etatRendu = etatCandidat(candidature: candidature(depart));
  final _PortMajeur port = _PortMajeur(dossier, candidature);
  await monterQuestionnaire(
    tester,
    port: port,
    depart: page,
    taille: taille,
    dossier: dossier,
    direction: direction,
  );
  return port;
}

void main() {
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  group('salle 1 : la question avant les questions', () {
    for (final Size taille in <Size>[
      const Size(390, 844),
      const Size(1440, 900),
    ]) {
      testWidgets(
        'sans la case, pas de Continuer et une phrase dit pourquoi (${taille.width.toInt()})',
        (WidgetTester tester) async {
          final _PortMajeur port = await _monter(
            tester,
            _salle1,
            _aFaire,
            taille: taille,
          );
          expect(find.text(t.recrutement.majeur.titre), findsWidgets);
          expect(_cle(MajoriteCles.caseEcran), findsOneWidget);
          expect(_cle(MajoriteCles.continuer), findsNothing);
          expect(
            find.text(t.recrutement.majeur.pourquoiBloque),
            findsOneWidget,
          );
          // Avant les questions : le parcours n'est pas ouvert.
          expect(_cle(CoquilleParcours.retourKey), findsNothing);
          expect(port.attestationsMajorite, isEmpty);
        },
      );
    }

    testWidgets(
      'la case cochee montre Continuer ; il declare et ouvre le parcours',
      (WidgetTester tester) async {
        final _PortMajeur port = await _monter(tester, _salle1, _aFaire);
        await tester.tap(_cle(MajoriteCles.caseEcran));
        await tester.pumpAndSettle();
        expect(_cle(MajoriteCles.continuer), findsOneWidget);
        expect(find.text(t.recrutement.majeur.pourquoiBloque), findsNothing);
        await tester.tap(_cle(MajoriteCles.continuer));
        await tester.pumpAndSettle();
        expect(port.attestationsMajorite, <bool>[true]);
        expect(_cle(CoquilleParcours.retourKey), findsOneWidget);
        expect(_cle(MajoriteCles.caseEcran), findsNothing);
      },
    );

    testWidgets('« J ai moins de 18 ans » : « Non, revenir » n envoie rien', (
      WidgetTester tester,
    ) async {
      final _PortMajeur port = await _monter(tester, _salle1, _aFaire);
      await tester.tap(_cle(MajoriteCles.lienMoins18));
      await tester.pumpAndSettle();
      expect(find.text(t.recrutement.majeur.confirmer.titre), findsWidgets);
      expect(
        find.text(t.recrutement.majeur.confirmer.explication),
        findsOneWidget,
      );
      await tester.tap(find.text(t.recrutement.majeur.confirmer.retour));
      await tester.pumpAndSettle();
      expect(port.attestationsMajorite, isEmpty);
      expect(_cle(MajoriteCles.caseEcran), findsOneWidget);
    });

    testWidgets(
      '« J ai moins de 18 ans » confirme : la declaration part, la page est bienveillante',
      (WidgetTester tester) async {
        final _PortMajeur port = await _monter(tester, _salle1, _aFaire);
        await tester.tap(_cle(MajoriteCles.lienMoins18));
        await tester.pumpAndSettle();
        await tester.tap(find.text(t.recrutement.majeur.confirmer.action));
        await tester.pumpAndSettle();
        expect(port.attestationsMajorite, <bool>[false]);
        expect(_cle(MajoriteCles.merci), findsOneWidget);
        expect(find.text(t.recrutement.majeur.moins18.texte), findsOneWidget);
        // Aucun questionnaire, aucune case.
        expect(_cle(MajoriteCles.caseEcran), findsNothing);
        expect(_cle(CoquilleParcours.retourKey), findsNothing);
      },
    );

    testWidgets(
      'un echec dit que la reponse n est pas confirmee ; la case reste',
      (WidgetTester tester) async {
        final _PortMajeur port = await _monter(tester, _salle1, _aFaire);
        port.erreurAttestationMajorite = Exception('reseau');
        await tester.tap(_cle(MajoriteCles.caseEcran));
        await tester.pumpAndSettle();
        await tester.tap(_cle(MajoriteCles.continuer));
        await tester.pumpAndSettle();
        expect(find.text(t.recrutement.majeur.echec), findsOneWidget);
        expect(_cle(MajoriteCles.continuer), findsOneWidget);
        expect(_cle(CoquilleParcours.retourKey), findsNothing);
      },
    );

    testWidgets('une declaration deja faite se dit', (
      WidgetTester tester,
    ) async {
      final _PortMajeur port = await _monter(tester, _salle1, _aFaire);
      port.erreurAttestationMajorite = const DeclarationDejaFaite();
      await tester.tap(_cle(MajoriteCles.caseEcran));
      await tester.pumpAndSettle();
      await tester.tap(_cle(MajoriteCles.continuer));
      await tester.pumpAndSettle();
      expect(find.text(t.recrutement.majeur.dejaFaite), findsOneWidget);
    });

    testWidgets(
      'un serveur d avant ne pose pas la question : le parcours s ouvre',
      (WidgetTester tester) async {
        await _monter(tester, _salle1, MajoriteCandidature.nonServie);
        expect(_cle(MajoriteCles.caseEcran), findsNothing);
        expect(_cle(CoquilleParcours.retourKey), findsOneWidget);
      },
    );

    testWidgets('age deja atteste : le parcours s ouvre aussitot', (
      WidgetTester tester,
    ) async {
      await _monter(tester, _salle1, _oui);
      expect(_cle(MajoriteCles.caseEcran), findsNothing);
      expect(_cle(CoquilleParcours.retourKey), findsOneWidget);
    });

    testWidgets(
      'en arabe, de droite a gauche, a 390 : la question et la case',
      (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
        await _monter(tester, _salle1, _aFaire, direction: TextDirection.rtl);
        expect(find.text(t.recrutement.majeur.titre), findsWidgets);
        expect(find.text(t.recrutement.majeur.coche), findsOneWidget);
        expect(_cle(MajoriteCles.continuer), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('candidats avances : la meme case, la ou ils sont', () {
    for (final Size taille in <Size>[
      const Size(390, 844),
      const Size(1440, 900),
    ]) {
      testWidgets('la carte est en tete de la page (${taille.width.toInt()})', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          _enExamen,
          _aFaire,
          page: Routes.attente,
          taille: taille,
        );
        expect(_cle(MajoriteCles.carte), findsOneWidget);
        expect(find.text(t.recrutement.majeur.portail.titre), findsOneWidget);
        expect(_cle(MajoriteCles.caseCarte), findsOneWidget);
      });
    }

    testWidgets('cocher la case l enregistre, puis la carte disparait', (
      WidgetTester tester,
    ) async {
      final _PortMajeur port = await _monter(
        tester,
        _enExamen,
        _aFaire,
        page: Routes.attente,
      );
      await tester.tap(_cle(MajoriteCles.caseCarte));
      await tester.pumpAndSettle();
      expect(port.attestationsMajorite, <bool>[true]);
      expect(_cle(MajoriteCles.carte), findsNothing);
    });

    testWidgets(
      'un echec decoche la case et dit que la reponse n est pas confirmee',
      (WidgetTester tester) async {
        final _PortMajeur port = await _monter(
          tester,
          _enExamen,
          _aFaire,
          page: Routes.attente,
        );
        port.erreurAttestationMajorite = Exception('reseau');
        await tester.tap(_cle(MajoriteCles.caseCarte));
        await tester.pumpAndSettle();
        expect(find.text(t.recrutement.majeur.echec), findsOneWidget);
        expect(_cle(MajoriteCles.carte), findsOneWidget);
      },
    );

    testWidgets(
      '« J ai moins de 18 ans » depuis la carte : confirmation, puis phrase bienveillante',
      (WidgetTester tester) async {
        final _PortMajeur port = await _monter(
          tester,
          _enExamen,
          _aFaire,
          page: Routes.attente,
        );
        await tester.tap(_cle(MajoriteCles.lienMoins18));
        await tester.pumpAndSettle();
        await tester.tap(find.text(t.recrutement.majeur.confirmer.action));
        await tester.pumpAndSettle();
        expect(port.attestationsMajorite, <bool>[false]);
        expect(find.text(t.recrutement.majeur.moins18.titre), findsOneWidget);
        expect(_cle(MajoriteCles.caseCarte), findsNothing);
      },
    );

    testWidgets('age atteste ou question non posee : aucune carte', (
      WidgetTester tester,
    ) async {
      await _monter(tester, _enExamen, _oui, page: Routes.attente);
      expect(_cle(MajoriteCles.carte), findsNothing);
    });

    testWidgets('serveur d avant : aucune carte', (WidgetTester tester) async {
      await _monter(
        tester,
        _enExamen,
        MajoriteCandidature.nonServie,
        page: Routes.attente,
      );
      expect(_cle(MajoriteCles.carte), findsNothing);
    });

    testWidgets(
      'moins de 18 ans declare : la phrase bienveillante, sans case',
      (WidgetTester tester) async {
        await _monter(tester, _enExamen, _non, page: Routes.attente);
        expect(_cle(MajoriteCles.carte), findsOneWidget);
        expect(find.text(t.recrutement.majeur.moins18.texte), findsOneWidget);
        expect(_cle(MajoriteCles.caseCarte), findsNothing);
      },
    );

    testWidgets('en arabe, de droite a gauche : la carte', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      await _monter(
        tester,
        _enExamen,
        _aFaire,
        page: Routes.attente,
        direction: TextDirection.rtl,
      );
      expect(find.text(t.recrutement.majeur.portail.titre), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  // Captures R3 (sautees sans CAPTURE_DIR) : la question de la salle 1, la
  // confirmation, la page bienveillante, la carte des candidats avances.
  group('captures', () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final Size taille in <Size>[
        const Size(1440, 900),
        const Size(390, 844),
      ]) {
        final String nom = '${taille.width.toInt()}-${langue.languageCode}';
        testWidgets('salle1-$nom', (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          await _monter(
            tester,
            _salle1,
            _aFaire,
            taille: taille,
            direction: langue == AppLocale.ar ? TextDirection.rtl : null,
          );
          await stabiliser(tester);
          await capturerVue(tester, 'MAJEUR/salle1-question-$nom');
          await tester.tap(_cle(MajoriteCles.caseEcran));
          await tester.pumpAndSettle();
          await capturerVue(tester, 'MAJEUR/salle1-case-cochee-$nom');
          await tester.tap(_cle(MajoriteCles.lienMoins18));
          await tester.pumpAndSettle();
          await capturerVue(tester, 'MAJEUR/salle1-confirmation-$nom');
          await tester.tap(find.text(t.recrutement.majeur.confirmer.action));
          await tester.pumpAndSettle();
          await capturerVue(tester, 'MAJEUR/salle1-moins-18-$nom');
        });
        testWidgets('avances-$nom', (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          await _monter(
            tester,
            _enExamen,
            _aFaire,
            page: Routes.attente,
            taille: taille,
            direction: langue == AppLocale.ar ? TextDirection.rtl : null,
          );
          await stabiliser(tester);
          await capturerVue(tester, 'MAJEUR/avances-carte-$nom');
        });
      }
    }
  }, skip: sautSansCapture);
}
