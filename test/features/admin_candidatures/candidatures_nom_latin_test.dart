// ADM-20 x CAND-NOM-LATIN : la file montre le nom en lettres latines (decision
// du directeur du 23/10/2026). Ce que le test prouve :
// - le nom de reference d'une ligne est le nom latin confirme ; le nom d'origine
//   (en arabe) est garde tel quel et s'affiche en second, en petit, avec la
//   reference ;
// - une ligne dont le nom n'est pas latin et rien de confirme montre la
//   proposition de translitteration, marquee « a confirmer » (un mot, et le
//   lecteur d'ecran le dit) ; une ligne confirmee ou deja latine ne l'est pas ;
// - un nom deja latin n'a pas de seconde ecriture a montrer ;
// - la recherche trouve par l'une ou l'autre ecriture (au serveur), et le tri par
//   nom suit le nom latin ;
// - au tableau (1440) comme en cartes (390), en francais et en arabe, sans
//   debordement.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/admin_candidatures/libelles_candidatures.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../fixtures/candidature/faux_candidatures_direction.dart';
import 'hote_candidatures.dart';

const String _ahmedArabe = 'أحمد بن علي';
const String _youssefArabe = 'يوسف الدوسري';

FauxCandidaturesDirection _port() => FauxCandidaturesDirection(
  lignes: <LigneCandidature>[
    // Confirmee par la personne.
    ligneTest(id: 'a1', nom: _ahmedArabe, nomLatin: 'Ahmed Ben Ali'),
    // Non confirmee : la liste montre une proposition.
    ligneTest(id: 'b2', nom: _youssefArabe, nomLatinAConfirmer: true),
    // Deja en lettres latines.
    ligneTest(id: 'c3', nom: 'Amina Diallo', nomLatin: 'Amina Diallo'),
  ],
);

Finder _cle(String cle) => find.byKey(ValueKey<String>(cle));

void main() {
  setUpAll(chargerPolicesDuDepot);
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('le nom de reference et la ligne', () {
    test('nomAffiche : latin confirme, sinon proposition, sinon origine', () {
      final LigneCandidature confirmee = ligneTest(
        id: 'a1',
        nom: _ahmedArabe,
        nomLatin: 'Ahmed Ben Ali',
      );
      expect(nomAffiche(confirmee), 'Ahmed Ben Ali');
      expect(nomOrigineAffiche(confirmee), _ahmedArabe);
      expect(nomAConfirmer(confirmee), isFalse);

      final LigneCandidature proposee = ligneTest(
        id: 'b2',
        nom: _youssefArabe,
        nomLatinAConfirmer: true,
      );
      expect(nomAffiche(proposee), 'Youssef Al-Dousari');
      expect(nomOrigineAffiche(proposee), _youssefArabe);
      expect(nomAConfirmer(proposee), isTrue);

      final LigneCandidature latine = ligneTest(
        id: 'c3',
        nom: 'Amina Diallo',
        nomLatin: 'Amina Diallo',
      );
      expect(nomAffiche(latine), 'Amina Diallo');
      expect(nomOrigineAffiche(latine), isNull);
      expect(nomAConfirmer(latine), isFalse);
    });

    test('une ligne sans nom garde la reference, jamais un vide', () {
      final LigneCandidature sansNom = ligneTest(id: 'd4', nom: '   ');
      expect(nomAffiche(sansNom), sansNom.reference);
      expect(nomOrigineAffiche(sansNom), isNull);
    });

    test('le serveur sert les deux cles, lues sans rien deduire', () {
      final LigneCandidature? ligne = LigneCandidature.depuisJson(
        <String, Object?>{
          'id': 'x1',
          'reference': 'CAND-00001',
          'nomComplet': _youssefArabe,
          'nomLatin': null,
          'nomLatinAConfirmer': true,
        },
      );
      expect(ligne!.nomLatin, isNull);
      expect(ligne.nomLatinAConfirmer, isTrue);
      final LigneCandidature? ancienne = LigneCandidature.depuisJson(
        <String, Object?>{
          'id': 'x2',
          'reference': 'CAND-00002',
          'nomComplet': 'Amina Diallo',
        },
      );
      expect(ancienne!.nomLatin, isNull);
      expect(ancienne.nomLatinAConfirmer, isFalse);
    });
  });

  for (final double largeur in <double>[390, 1440]) {
    group('${largeur.toInt()} : la liste', () {
      testWidgets('nom latin en grand, nom d\'origine en petit, marque', (
        WidgetTester tester,
      ) async {
        await monterCandidatures(tester, port: _port(), largeur: largeur);
        // Le nom latin confirme fait reference ; l'arabe est en second.
        expect(find.text('Ahmed Ben Ali'), findsOneWidget);
        expect(
          find.textContaining(_ahmedArabe, findRichText: true),
          findsOneWidget,
        );
        expect(find.text(_ahmedArabe), findsNothing);
        // La proposition, marquee « a confirmer ».
        expect(find.text('Youssef Al-Dousari'), findsOneWidget);
        expect(
          find.textContaining(_youssefArabe, findRichText: true),
          findsOneWidget,
        );
        expect(
          find.text(t.admin.candidatures.liste.nomAConfirmer),
          findsOneWidget,
          reason: 'une seule marque : celle de la proposition',
        );
        // Un nom deja latin : rien de plus a dire.
        expect(find.text('Amina Diallo'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('la marque est dite au lecteur d\'ecran', (
        WidgetTester tester,
      ) async {
        final SemanticsHandle poignee = tester.ensureSemantics();
        await monterCandidatures(tester, port: _port(), largeur: largeur);
        expect(
          find.bySemanticsLabel(
            RegExp(
              RegExp.escape(t.admin.candidatures.liste.nomAConfirmerSemantique),
            ),
          ),
          findsWidgets,
        );
        poignee.dispose();
      });

      testWidgets('en arabe, sans debordement', (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
        await monterCandidatures(
          tester,
          port: _port(),
          largeur: largeur,
          direction: TextDirection.rtl,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Ahmed Ben Ali'), findsOneWidget);
        expect(
          find.text(t.admin.candidatures.liste.nomAConfirmer),
          findsOneWidget,
        );
      });
    });
  }

  group('recherche et tri, au serveur', () {
    testWidgets('l\'une ou l\'autre ecriture trouve la personne', (
      WidgetTester tester,
    ) async {
      final FauxCandidaturesDirection port = _port();
      await monterCandidatures(tester, port: port);
      await tester.enterText(_cle('candidatures-recherche'), 'ben ali');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(port.appels.last.filtre.recherche, 'ben ali');
      expect(find.text('Ahmed Ben Ali'), findsOneWidget);
      expect(find.text('Amina Diallo'), findsNothing);

      await tester.enterText(_cle('candidatures-recherche'), 'بن علي');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(port.appels.last.filtre.recherche, 'بن علي');
      expect(find.text('Ahmed Ben Ali'), findsOneWidget);
    });

    test('le double trie par nom latin quand il existe', () async {
      final FauxCandidaturesDirection port = _port();
      final PageCandidatures page = await port.lister(
        filtre: const FiltreCandidatures(),
        tri: TriCandidatures.nom,
        page: 1,
      );
      expect(page.lignes.map((LigneCandidature l) => l.id).toList(), <String>[
        'a1',
        'c3',
        'b2',
      ]);
    });
  });
}
