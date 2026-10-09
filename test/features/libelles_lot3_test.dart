// LIB-LOT3-2 : libelles du lot 3 lus sur les VRAIS ecrans.
//
// - LIB-OBJ-1 : « Objectif d'Aya », « Ce qu'Aya doit atteindre », « Devoir
//   d'Aya » (elision devant un prenom a voyelle) et « de Nour » sinon ;
// - LIB-CAHIER-1 : « cahier de transmission » partout cote enseignant ;
// - LIB-ABS-1, KYC-PHOTO-1 : les textes que portent les cles
//   `journee-absence-contexte`, `cahier-intro`, `cahier-obligatoire`,
//   `journee-cahier-obligatoire`, `photo-obligatoire` et `kyc.confidentialite`,
//   mot pour mot.
//
// Chaque phrase est ecrite en dur : un changement de libelle fait echouer le
// test, et il faut alors le declarer dans `tool/libelles_sources.json`.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/enseignant/depot_cahiers.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';
import 'package:rewayah_academy/core/i18n/elision.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/widgets/point_rappel.dart';
import 'package:rewayah_academy/features/cahier/cahier_page.dart';
import 'package:rewayah_academy/features/cahier/vue_cahier.dart';
import 'package:rewayah_academy/features/demo/demo_enseignant_page.dart';
import 'package:rewayah_academy/features/demo/enseignant_demo.dart';
import 'package:rewayah_academy/features/dossier/depot_piece_page.dart';
import 'package:rewayah_academy/features/profil_enseignant/photo_publique.dart';

import '../capture/outil_capture.dart';
import '../support/harnais.dart';

Finder _cle(String cle) => find.byKey(ValueKey<String>(cle));

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await stabiliser(tester);
  await tester.tap(cible);
  await stabiliser(tester);
  await tester.pump(const Duration(milliseconds: 700));
  await stabiliser(tester);
}

/// Le brouillon de la demonstration, avec Aya (prenom a voyelle) avant Nour.
BrouillonCahier _brouillonAvecAya() {
  final BrouillonCahier b = DonneesEnseignantDemo.brouillonCahier();
  return BrouillonCahier(
    seanceId: b.seanceId,
    debut: b.debut,
    fin: b.fin,
    statut: b.statut,
    dureeMinutes: b.dureeMinutes,
    minutesInterruption: b.minutesInterruption,
    dejaDepose: false,
    groupeId: b.groupeId,
    participants: <ParticipantBrouillon>[
      const ParticipantBrouillon(
        membre: MembreSeance(
          studentId: 'e-aya',
          identifiantImmuable: 'RA-AYA',
          prenom: 'Aya',
        ),
        presence: EtatPresence.presente,
      ),
      b.participants.first,
    ],
    evenements: b.evenements,
  );
}

Future<void> _monterCahier(WidgetTester tester) async {
  fixerVueCapture(tester, const Size(390, 2400), 1);
  await tester.pumpWidget(
    hoteCapture(
      const CoquilleEnseignantDemo(
        ecran: EcranDemoEnseignant.cahier,
        etat: EtatDemoEnseignant.nominal,
      ),
      surcharges: <Override>[
        depotRapportsProvider.overrideWithValue(FauxDepotRapports()),
      ],
    ),
  );
  await stabiliser(tester);
}

void main() {
  test('elision : « de » et « que » devant une voyelle ou un h', () {
    expect(deDevant('Aya'), "d'Aya");
    expect(deDevant('Élodie'), "d'Élodie");
    // Jamais devant h (revue croisee de LIB-DIR-1, 08/10).
    expect(deDevant('Hadi'), 'de Hadi');
    expect(deDevant('Nour'), 'de Nour');
    expect(queDevant('Aya'), "qu'Aya");
    expect(queDevant('Ibrahim'), "qu'Ibrahim");
    expect(queDevant('Nour'), 'que Nour');
    expect(queDevant('Bilal'), 'que Bilal');
  });

  group('LIB-OBJ-1 : le cahier, depuis la vraie coquille', () {
    testWidgets("Aya : « Objectif d'Aya », « qu'Aya », « Devoir d'Aya »", (
      WidgetTester tester,
    ) async {
      // Le brouillon d'Aya remplace celui de la demonstration : la coquille
      // ne propose pas ce prenom, on monte donc la page elle-meme.
      fixerVueCapture(tester, const Size(390, 2400), 1);
      await tester.pumpWidget(
        hoteCapture(
          const CahierPage(seanceId: DonneesEnseignantDemo.cahierDemoSeanceId),
          surcharges: <Override>[
            ...surchargesCoquilleEnseignantDemo(EtatDemoEnseignant.nominal),
            soumissionCahierProvider.overrideWithValue(
              const SoumissionCahierDemo(),
            ),
            horlogeCahierProvider.overrideWithValue(
              () => DonneesEnseignantDemo.maintenant,
            ),
            brouillonCahierProvider(DonneesEnseignantDemo.cahierDemoSeanceId)
                .overrideWith((Ref _) async => _brouillonAvecAya()),
            depotRapportsProvider.overrideWithValue(FauxDepotRapports()),
          ],
        ),
      );
      await stabiliser(tester);
      await _toucher(tester, find.text('Aya'));

      expect(find.text("Objectif d'Aya"), findsOneWidget);
      expect(
        find.text(
          "Ce qu'Aya doit atteindre, dans le cadre du programme de "
          "l'académie.",
        ),
        findsOneWidget,
      );
      expect(find.text("Devoir d'Aya"), findsOneWidget);
      expect(find.textContaining('de Aya'), findsNothing);
      expect(find.textContaining('que Aya'), findsNothing);
    });

    testWidgets('Nour : « Objectif de Nour », « que Nour », « Devoir de '
        'Nour »', (WidgetTester tester) async {
      await _monterCahier(tester);
      await _toucher(tester, find.text('Nour'));
      expect(find.text('Objectif de Nour'), findsOneWidget);
      expect(
        find.text(
          'Ce que Nour doit atteindre, dans le cadre du programme de '
          "l'académie.",
        ),
        findsOneWidget,
      );
      expect(find.text('Devoir de Nour'), findsOneWidget);
    });
  });

  group('LIB-CAHIER-1 : « cahier de transmission »', () {
    testWidgets('cahier-intro : pastille « Obligatoire », sous-titre et '
        'description', (WidgetTester tester) async {
      await _monterCahier(tester);
      final Finder intro = _cle('cahier-intro');
      expect(intro, findsOneWidget);
      expect(
        find.descendant(
          of: _cle('cahier-obligatoire'),
          matching: find.text('Obligatoire'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: intro,
          matching: find.text(t.enseignant.cahier.sousTitre),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: intro,
          matching: find.text(t.enseignant.cahier.description),
        ),
        findsOneWidget,
      );
    });

    testWidgets('journee-cahier-obligatoire : la pastille de « À terminer »', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(390, 2400), 1);
      await tester.pumpWidget(
        hoteCapture(
          const CoquilleEnseignantDemo(ecran: EcranDemoEnseignant.aujourdhui),
        ),
      );
      await stabiliser(tester);
      expect(
        find.descendant(
          of: _cle('journee-cahier-obligatoire'),
          matching: find.text('Obligatoire'),
        ),
        findsOneWidget,
      );
      expect(find.text('À terminer'), findsOneWidget);
    });

    test('la deconnexion parle des « cahiers de transmission »', () {
      expect(
        t.enseignant.profil.deconnexionConsequence,
        'Votre journée, vos créneaux et vos cahiers de transmission restent '
        'enregistrés. Il faudra un nouveau lien de connexion pour revenir.',
      );
    });

    test('aucun libelle enseignant ne dit « cahier » sans « de '
        'transmission » (hors la pastille « Obligatoire » et le titre)', () {
      final Map<String, dynamic> fr = jsonDecode(
        File('assets/i18n/fr.i18n.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final List<String> fautes = <String>[];
      void parcourir(String chemin, Object? noeud) {
        if (noeud is Map<String, dynamic>) {
          noeud.forEach((String k, Object? v) => parcourir('$chemin.$k', v));
        } else if (noeud is String) {
          final String sansNom = noeud.replaceAll(
            RegExp('[Cc]ahiers? de transmission'),
            '',
          );
          if (RegExp(r'\b[Cc]ahiers?\b').hasMatch(sansNom)) {
            fautes.add('$chemin : $noeud');
          }
        }
      }

      parcourir('enseignant', fr['enseignant']);
      expect(fautes, isEmpty, reason: fautes.join('\n'));
    });
  });

  group('LIB-ABS-1 : la suite de l absence, sous le bouton', () {
    testWidgets('journee-absence-contexte : le texte, mot pour mot', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(390, 1900), 1);
      await tester.pumpWidget(
        hoteCapture(
          const CoquilleEnseignantDemo(ecran: EcranDemoEnseignant.aujourdhui),
        ),
      );
      await stabiliser(tester);
      expect(_cle('journee-declarer-absence'), findsOneWidget);
      final Finder contexte = _cle('journee-absence-contexte');
      expect(contexte, findsOneWidget);
      expect(
        tester.widget<Text>(contexte).data,
        'Un remplaçant sera recherché pour vos élèves.',
      );
    });
  });

  group('KYC-PHOTO-1 : photo obligatoire et pièce jamais publique', () {
    testWidgets('photo-obligatoire : le point dit « Photo obligatoire »', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(390, 1000), 1);
      await tester.pumpWidget(
        hoteCapture(
          const Scaffold(body: EditeurPhotoPublique(prenom: 'Ibrahim')),
        ),
      );
      await stabiliser(tester);
      expect(
        tester.widget<PointRappel>(_cle('photo-obligatoire')).libelle,
        'Photo obligatoire',
      );
      expect(
        find.textContaining('Votre photo est obligatoire'),
        findsOneWidget,
      );
    });

    testWidgets('kyc.confidentialite : sous l intro du depot de piece', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(390, 844), 1);
      await tester.pumpWidget(hoteCapture(const DepotPiecePage()));
      await stabiliser(tester);
      expect(
        find.text(
          "Votre pièce d'identité se dépose telle quelle\u00A0: elle n'est "
          'jamais publique, seule la direction la consulte, et elle est '
          "exigée par la réglementation sur la protection de l'enfance.",
        ),
        findsOneWidget,
      );
    });
  });
}
