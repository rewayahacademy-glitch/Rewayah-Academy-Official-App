// Q-10 : photo et titre de l enseignant, et l absence de photo comme etat
// gere.
//
// Invariant 11 de la Phase 6 (« Sayyid/Sayyida partout dans le contexte
// cours »), checklist finale produit (« la photo enseignant est
// obligatoire »), decisions D-01 et D-02.
//
// L ABSENCE DE PHOTO EST LE VRAI SUJET. D-01 interdit l avatar generique
// silencieux : il masquerait une donnee manquante au lieu de la signaler. Le
// test verifie donc qu il n existe MEME PAS de troisieme etat possible --
// l enumeration ne porte que « presente » et « manquante ».

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/contrats/contrats_a_groupe.dart';
import '../fixtures/fixtures_groupes.dart';
import 'support/lecture_sources.dart';

/// Une carte de groupe reduite a ce que le test observe.
Widget _carteGroupe(GroupSummaryVM g) => MaterialApp(
  debugShowCheckedModeBanner: false,
  home: Scaffold(
    body: Column(
      children: <Widget>[
        Text(g.libelle, key: const Key('carte-libelle')),
        Text(
          libelleEnseignant(g.enseignant),
          key: const Key('carte-enseignant'),
        ),
        Text(libelleEffectif(g), key: const Key('carte-effectif')),
        if (etatPhoto(g.enseignant) == EtatPhotoEnseignant.manquante)
          const Text(
            'Photo de l enseignant manquante',
            key: Key('carte-photo-manquante'),
          )
        else
          Text(
            g.enseignant.photoUrlOuCle!,
            key: const Key('carte-photo-cle'),
          ),
      ],
    ),
  ),
);

void main() {
  group('Q-10 : le titre est Sayyid ou Sayyida, jamais Ustaz', () {
    test('les deux titres portent leur libelle francais et arabe', () {
      expect(TitreEnseignant.sayyid.libelleFr, 'Sayyid');
      expect(TitreEnseignant.sayyida.libelleFr, 'Sayyida');
      expect(TitreEnseignant.sayyid.libelleAr, 'سيد');
      expect(TitreEnseignant.sayyida.libelleAr, 'سيدة');
      expect(TitreEnseignant.values, hasLength(2));
    });

    test('la lecture d une valeur SQL inconnue rend null, sans repli', () {
      expect(TitreEnseignant.depuisSql('sayyid'), TitreEnseignant.sayyid);
      expect(TitreEnseignant.depuisSql('ustaz'), isNull);
      expect(TitreEnseignant.depuisSql(null), isNull);
    });

    test('le mot Ustaz n apparait nulle part dans les fixtures', () {
      // Decision D-02 : « Pas de Ustaz / Ustazah, nulle part ». Une lecture
      // de source, parce que c est une absence qu on verifie.
      final List<String> fautifs = <String>[];
      for (final File f in fichiersDart(CheminsDoubles.repertoireFixtures)) {
        final List<String> trouves = motsTrouves(
          f.readAsStringSync(),
          const <String>['ustaz', 'ustadh', 'ustaad', 'cheikh'],
        );
        if (trouves.isNotEmpty) fautifs.add('${f.path} -> $trouves');
      }
      expect(fautifs, isEmpty);
    });

    testWidgets('la carte affiche le titre devant le nom', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_carteGroupe(groupePlein));
      expect(find.text('Sayyid Yacine'), findsOneWidget);

      await tester.pumpWidget(_carteGroupe(groupeAdultePlein));
      expect(find.text('Sayyida Khadija'), findsOneWidget);
    });
  });

  group('Q-10 : la photo manquante est un etat, pas un avatar par defaut', () {
    test('il n existe que deux etats, et aucun ne s appelle « generique »', () {
      expect(EtatPhotoEnseignant.values, hasLength(2));
      expect(
        EtatPhotoEnseignant.values.map((EtatPhotoEnseignant e) => e.name),
        <String>['presente', 'manquante'],
      );
    });

    test('une cle absente ou vide vaut manquante', () {
      expect(etatPhoto(enseignantAvecPhoto), EtatPhotoEnseignant.presente);
      expect(etatPhoto(enseignantSansPhoto), EtatPhotoEnseignant.manquante);
      expect(
        etatPhoto(
          const EnseignantVM(
            enseignantId: 'ens-x',
            titre: TitreEnseignant.sayyid,
            nomAffichage: 'Vide',
            photoUrlOuCle: '   ',
          ),
        ),
        EtatPhotoEnseignant.manquante,
      );
    });

    testWidgets('sans photo, la carte le DIT au lieu de le masquer', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_carteGroupe(groupeSansPhotoEnseignant));

      expect(find.byKey(const Key('carte-photo-manquante')), findsOneWidget);
      expect(find.byKey(const Key('carte-photo-cle')), findsNothing);
      // Le reste de la carte continue de fonctionner : une donnee manquante
      // ne casse pas l ecran, elle se signale.
      expect(find.text('Les Aurores'), findsOneWidget);
      expect(find.text('Sayyid Idriss'), findsOneWidget);
    });

    testWidgets('avec photo, c est une CLE qui est portee, pas une URL', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_carteGroupe(groupePlein));

      final Text cle = tester.widget<Text>(
        find.byKey(const Key('carte-photo-cle')),
      );
      expect(cle.data, 'teacher-photos/ens-001.jpg');
      expect(cle.data!.startsWith('http'), isFalse);
      expect(cle.data!.contains('?'), isFalse);
    });
  });

  group('Q-10 : la carte de groupe ne ment pas sur la capacite', () {
    testWidgets('l effectif se lit toujours « x / seuil » du serveur', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_carteGroupe(groupeQuatreSurCinq));
      expect(find.text('4 / 5'), findsOneWidget);

      await tester.pumpWidget(_carteGroupe(groupeTroisSurQuatre));
      expect(find.text('3 / 4'), findsOneWidget);

      await tester.pumpWidget(_carteGroupe(groupeAdultePlein));
      expect(find.text('6 / 6'), findsOneWidget);
    });

    test('aucun seuil n est le meme partout : le 5 en dur serait faux', () {
      final Set<int> seuils = tousLesGroupes()
          .map((GroupSummaryVM g) => g.seuilMax)
          .toSet();
      expect(seuils.length, greaterThan(1));
      expect(seuils, containsAll(<int>[4, 5, 6]));
    });

    test('la couleur n est jamais le seul identifiant du groupe', () {
      // Invariant J7 du depot, repris par la decision D-18 : toute interface
      // qui affiche `couleurJeton` affiche aussi `libelle`.
      for (final GroupSummaryVM g in tousLesGroupes()) {
        expect(g.libelle.trim(), isNotEmpty, reason: g.groupeId);
        expect(g.couleurJeton.codeStable.startsWith('#'), isFalse);
        expect(g.couleurJeton.codeStable.startsWith('0x'), isFalse);
      }
    });

    test('le niveau affiche est humain, jamais un code technique', () {
      // Regle UX inscrite en commentaire SQL dans 0020 : `code_technique`
      // n est jamais expose comme titre.
      for (final GroupSummaryVM g in tousLesGroupes()) {
        final String? niveau = g.niveauHumain;
        if (niveau == null) continue;
        expect(RegExp(r'^n\d+$').hasMatch(niveau), isFalse, reason: niveau);
        expect(niveau.contains('_'), isFalse, reason: niveau);
      }
    });
  });
}
