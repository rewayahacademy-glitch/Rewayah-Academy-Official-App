// JUR-APP-1 : le lien « En savoir plus » du bandeau de la salle et les textes
// d'information E-1 / E-2 valides par le directeur le 02/10/2026
// (pilotage 14_controleur/juridique/INFO_ELEVES_PARENTS.md).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart'
    show DisqueRetour;
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/information_controle.dart';
import 'package:rewayah_academy/features/salle_seance/mention_seance.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../capture/outil_capture.dart';

VueSeance _vue(RoleSeance role) => VueSeance(
  role: role,
  nomClasse: 'Classe',
  nomEnseignant: 'Sayyid Ibrahim',
  initialesEnseignant: 'SI',
  enregistrementConfirme: true,
);

Future<void> _mention(
  WidgetTester tester,
  RoleSeance role, {
  bool lienAccepte = true,
  String? contact,
}) async {
  await tester.pumpWidget(
    hoteCapture(
      Scaffold(
        body: Center(
          child: MentionSeance(
            vue: _vue(role),
            lienAccepte: lienAccepte,
            contact: contact,
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
}

Finder get _lien => find.text(t.salle.informationControle.lien);

void main() {
  group('Les cles des textes valides existent, mot pour mot', () {
    test('E-1 : le texte de l enfant de moins de 13 ans', () {
      final Traductions$salle$informationControle$e1$fr e1 =
          t.salle.informationControle.e1;
      expect(e1.titre, "Quelqu'un veille sur ton cours");
      expect(
        e1.p3,
        'Elle ne parle pas. Elle ne filme pas. Elle ne montre ton cours à '
        'personne.',
      );
      expect(e1.signaler, 'Tu peux aussi appuyer sur Signaler.');
    });

    test('E-2 : le texte de l eleve de 13 a 17 ans, contact en parametre', () {
      final Traductions$salle$informationControle$e2$fr e2 =
          t.salle.informationControle.e2;
      expect(e2.titre, 'Les visites de contrôle');
      expect(
        e2.p4(contact: 'X'),
        endsWith('parle à tes parents ou écris à X.'),
      );
    });

    test('A3, E1 et la clause enseignant', () {
      expect(
        t.contrat.a3.titre,
        'Les cours sont enregistrés (le son seulement)',
      );
      expect(t.contrat.a3.quoi, contains("L'image n'est pas enregistrée."));
      expect(t.contrat.a3.qui, isNot(contains('qui a écouté')));
      expect(
        t.contrat.a3.qui,
        endsWith(
          'Vous pouvez demander si un enregistrement a été écouté, et pourquoi.',
        ),
      );
      expect(
        t.contrat.e1.quoi,
        contains(
          'Elle n\'enregistre rien. Elle envoie ensuite un compte rendu à '
          "l'académie.",
        ),
      );
      expect(
        t.contrat.a3.duree(duree: 30),
        startsWith('30 jours, puis effacé.'),
      );
      expect(t.contrat.clauseControle.titre, 'Visites de contrôle.');
      expect(
        t.contrat.clauseControle.texte,
        endsWith('En signant, vous confirmez l\'avoir reçue.'),
      );
      expect(t.contrat.clauseControle.caseReligion, startsWith("J'accepte"));
    });

    test('le bandeau lui-meme ne change pas (decision du 24/09)', () {
      expect(
        t.salle.bandeauPermanent,
        'Cours enregistré, visite de contrôle possible.',
      );
    });
  });

  group('Le lien « En savoir plus » du bandeau', () {
    testWidgets('interface guidee : le lien ouvre le texte E-1', (
      WidgetTester tester,
    ) async {
      await _mention(tester, RoleSeance.guidee);
      expect(_lien, findsOneWidget);

      await tester.tap(_lien);
      await stabiliser(tester);
      final Traductions$salle$informationControle$e1$fr e1 =
          t.salle.informationControle.e1;
      expect(find.text(e1.titre), findsOneWidget);
      for (final String p in <String>[e1.p1, e1.p2, e1.p3, e1.p4, e1.p5]) {
        expect(find.text(p), findsOneWidget);
      }
      // Le bouton « Signaler » n'existe pas pour l'eleve : sa phrase est cachee.
      expect(find.textContaining(e1.signaler), findsNothing);

      // Rien a accepter : la lecture se ferme d'un geste.
      await tester.tap(find.byType(DisqueRetour).last);
      await stabiliser(tester);
      expect(find.text(e1.titre), findsNothing);
      expect(_lien, findsOneWidget);
    });

    testWidgets('eleve, contact fourni : le lien ouvre le texte E-2', (
      WidgetTester tester,
    ) async {
      await _mention(tester, RoleSeance.eleve, contact: 'contact-test');
      await tester.tap(_lien);
      await stabiliser(tester);
      final Traductions$salle$informationControle$e2$fr e2 =
          t.salle.informationControle.e2;
      expect(find.text(e2.titre), findsOneWidget);
      expect(find.text(e2.p1), findsOneWidget);
      expect(find.text(e2.p4(contact: 'contact-test')), findsOneWidget);
    });

    testWidgets('eleve sans contact fourni : pas de lien (pas de trou)', (
      WidgetTester tester,
    ) async {
      await _mention(tester, RoleSeance.eleve);
      expect(find.text(t.salle.bandeauPermanent), findsOneWidget);
      expect(_lien, findsNothing);
    });

    testWidgets("l'enseignant n'a pas de lien", (WidgetTester tester) async {
      await _mention(tester, RoleSeance.enseignant, contact: 'contact-test');
      expect(find.text(t.salle.bandeauPermanent), findsOneWidget);
      expect(_lien, findsNothing);
    });

    testWidgets('refus du directeur : le bandeau redevient seul', (
      WidgetTester tester,
    ) async {
      await _mention(tester, RoleSeance.guidee, lienAccepte: false);
      expect(find.text(t.salle.bandeauPermanent), findsOneWidget);
      expect(_lien, findsNothing);
    });

    test('le reglage par defaut : lien accepte, contact pas encore fourni', () {
      expect(InformationControle.lienAccepte, isTrue);
      expect(InformationControle.contactConfidentialite, isNull);
      expect(InformationControle.boutonSignalerEleve, isFalse);
    });

    testWidgets('dans la vraie salle guidee (390 x 844), le lien est la', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        hoteCapture(
          SalleDemo(
            role: RoleSeance.guidee,
            etat: EtatDemoSalle.repos,
            onSortir: () {},
          ),
        ),
      );
      await stabiliser(tester);
      expect(_lien, findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
