// COUPE-MOTS-FOND-1, point (6) : les reglages de l'enfant (tuteur) passent
// par la garde du rendu, page ENTIERE puis feuille « demander un
// changement » ouverte, aux gabarits de la fiche (320 x 568 texte x2,
// 390 x 844, 1440 x 900 texte x2), en francais (LTR) et en arabe (RTL), en
// standard et en Interface guidee.
//
// Le titre « Pourquoi ce changement ? » de la feuille porte une espace
// insecable avant « ? » dans `fr.i18n.json`, mais le JSON ne prouve pas le
// rendu : c'est le paragraphe dessine qui est mesure (ponctuation seule a
// la ligne, mot coupe, texte rogne ou tronque).
//
// Relecture de COUPE-MOTS-FOND-1 (10/10) : en arabe, les cles
// `tuteur.reglages` et `reglagesEnfant` manquaient ; le repli francais,
// rendu dans un paragraphe RTL, affichait « ? changement » et « .trancher ».
// La garde lit desormais la ligne VISUELLE (`ponctuationsIsolees`) : avec
// l'ancien `ar.i18n.json`, les configurations arabes echouent.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/matching/service_matching.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/regles/service_regles.dart';
import 'package:rewayah_academy/features/reglages_enfant/reglages_enfant_page.dart';

import '../capture/outil_capture.dart';
import '../support/aucun_mot_coupe.dart';
import '../support/balayage_ecrans.dart';
import '../support/garde_coupe_mots_rendu.dart';
import '../support/harnais.dart';

List<Override> _surcharges() => <Override>[
  serviceAppairageProvider.overrideWithValue(
    FauxServiceAppairage()
      ..elevesRendus = <EleveDuFoyer>[
        const EleveDuFoyer(
          id: 'e1',
          prenom: 'Amina',
          identifiantImmuable: 'STUD-AD-000001',
          mode: InterfaceMode.enfant,
          camera: CameraPolicy.forbidden,
        ),
      ],
  ),
  servicePlanningProvider.overrideWithValue(FauxServicePlanning()),
  serviceMatchingProvider.overrideWithValue(FauxServiceMatching()),
  serviceReglesProvider.overrideWithValue(FauxServiceRegles()),
];

/// L'ecran des reglages de l'enfant.
EcranBalayage reglagesEnfant() => (
  nom: 'tuteur reglages enfant',
  page: () => const ReglagesEnfantPage(),
  routeur: null,
  depart: null,
  surcharges: _surcharges,
);

/// Ouvre la feuille de demande dont le bouton porte [libelle].
Future<void> ouvrirDemande(WidgetTester tester, String libelle) async {
  final Finder bouton = find.text(libelle);
  await tester.ensureVisible(bouton);
  await stabiliser(tester);
  await tester.tap(bouton);
  await stabiliser(tester);
}

/// Un paragraphe [texte] rendu dans le sens [sens], a la largeur [largeur].
Widget _paragraphe(String texte, TextDirection sens, double largeur) =>
    Directionality(
      textDirection: sens,
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: SizedBox(
          width: largeur,
          child: Text(texte, style: const TextStyle(fontSize: 20)),
        ),
      ),
    );

/// Les feuilles de [arbre], en chemins pointes.
Set<String> _feuilles(Object? arbre, [String chemin = '']) => <String>{
  if (arbre is Map<String, dynamic>)
    for (final MapEntry<String, dynamic> e in arbre.entries)
      ..._feuilles(e.value, chemin.isEmpty ? e.key : '$chemin.${e.key}')
  else
    chemin,
};

void main() {
  group('la garde lit la ligne visuelle d\'un paragraphe RTL', () {
    const String question = 'Pourquoi ce changement\u00A0?';
    const String phrase = "C'est lui qui permet de trancher.";

    testWidgets('texte latin en RTL : « ? » et « . » loin de leur mot', (
      WidgetTester tester,
    ) async {
      for (final String texte in <String>[question, phrase]) {
        await tester.pumpWidget(_paragraphe(texte, TextDirection.rtl, 600));
        expect(
          ponctuationsIsolees(tester, find.byType(Text)),
          isNotEmpty,
          reason: texte,
        );
        // Passe a la ligne : « ? changement », « .trancher ».
        await tester.pumpWidget(_paragraphe(texte, TextDirection.rtl, 150));
        expect(
          ponctuationsIsolees(tester, find.byType(Text)),
          isNotEmpty,
          reason: texte,
        );
      }
    });

    testWidgets('le meme texte en LTR, et l\'arabe en RTL : rien', (
      WidgetTester tester,
    ) async {
      for (final double largeur in <double>[600, 150]) {
        for (final String texte in <String>[question, phrase]) {
          await tester.pumpWidget(
            _paragraphe(texte, TextDirection.ltr, largeur),
          );
          expect(ponctuationsIsolees(tester, find.byType(Text)), isEmpty);
        }
        await tester.pumpWidget(
          _paragraphe('ما سبب هذا التغيير؟', TextDirection.rtl, largeur),
        );
        expect(ponctuationsIsolees(tester, find.byType(Text)), isEmpty);
        await tester.pumpWidget(
          _paragraphe(
            'السبب مطلوب: على أساسه يُتَّخذ القرار.',
            TextDirection.rtl,
            largeur,
          ),
        );
        expect(ponctuationsIsolees(tester, find.byType(Text)), isEmpty);
      }
    });
  });

  test("l'arabe traduit toutes les cles de l'ecran", () {
    Map<String, dynamic> lire(String langue) =>
        jsonDecode(File('assets/i18n/$langue.i18n.json').readAsStringSync())
            as Map<String, dynamic>;
    final Map<String, dynamic> fr = lire('fr');
    final Map<String, dynamic> ar = lire('ar');
    for (final (Object? f, Object? a) in <(Object?, Object?)>[
      (
        (fr['tuteur'] as Map<String, dynamic>)['reglages'],
        (ar['tuteur'] as Map<String, dynamic>)['reglages'],
      ),
      (fr['reglagesEnfant'], ar['reglagesEnfant']),
      for (final String sorte in <String>[
        'reglageEnseignant',
        'reglageDuree',
        'reglageMinimum',
      ])
        (
          (fr['motifs'] as Map<String, dynamic>)[sorte],
          (ar['motifs'] as Map<String, dynamic>?)?[sorte],
        ),
    ]) {
      expect(a, isNotNull);
      expect(_feuilles(f).difference(_feuilles(a)), isEmpty);
    }
  });

  setUpAll(() async {
    await chargerPolicesDuDepot();
    await LocaleSettings.setLocale(AppLocale.ar);
    await LocaleSettings.setLocale(AppLocale.fr);
  });

  // Les gabarits de la fiche, plus deux largeurs de marge en Interface
  // guidee texte x2 (300 et 315 px) : a 320, « changement ? » ne tenait
  // qu'a 0,8 px pres ; un pixel de moins (une autre police de repli, une
  // marge de feuille) et le « ? » partait seul a la ligne.
  for (final ConfigBalayage c in <ConfigBalayage>[
    ...configsBalayage(),
    for (final double largeur in <double>[300, 315])
      for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar])
        (
          gabarit: (
            nom: '${largeur.toInt()}x2',
            taille: Size(largeur, 568),
            echelle: 2,
          ),
          langue: langue,
          interface: InterfaceMode.enfant,
        ),
  ]) {
    testWidgets('reglages enfant ${nomConfig(c)} : page entiere, aucun mot '
        'coupe ni rogne', (WidgetTester tester) async {
      await monterEcranBalayage(tester, reglagesEnfant(), c);
      expect(await defautsEcranDefile(tester), isEmpty);
    });

    for (final String Function() libelle in <String Function()>[
      () => t.tuteur.reglages.demandeDuree,
      () => t.tuteur.reglages.demandeMinimum,
    ]) {
      testWidgets('reglages enfant ${nomConfig(c)} : feuille '
          '« ${libelle()} » ouverte, « Pourquoi ce changement ? » entier', (
        WidgetTester tester,
      ) async {
        await monterEcranBalayage(tester, reglagesEnfant(), c);
        await ouvrirDemande(tester, libelle());
        expect(find.byType(BottomSheet), findsOneWidget);
        // Le titre du motif est rendu, et mesure avec tout le reste.
        expect(find.text(t.tuteur.reglages.demandeMotif), findsWidgets);
        expect(await defautsEcranDefile(tester), isEmpty);
      });
    }
  }
}
