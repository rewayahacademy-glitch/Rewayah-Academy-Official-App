// Decision « fi-elision » du 05/10 (FI-R4-08, par delegation du directeur) :
// « de » et « que » devant un nom s'elident devant une voyelle ou un h muet,
// dans toute l'application (hors voies Communications et Comptable, et hors
// Finance, deja faite sur sa branche).
//
// - la regle de lib/core/i18n/elision.dart, y compris « y » consonne ;
// - hors du francais, le nom reste seul (la traduction n'a pas de « de ») ;
// - des phrases reelles, ecrites en dur ;
// - aucun texte francais ne garde « de {prenom} » ou « que {prenom} ».

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/elision.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';

/// Les parametres qui portent un nom (personne, classe, groupe, sourate,
/// ville). Les heures, durees, dates et nombres n'elident pas.
const Set<String> _parametresNoms = <String>{
  'prenom',
  'nom',
  'eleve',
  'prenomEnfant',
  'auteur',
  'classe',
  'libelle',
  'groupe',
  'sourate',
  'ville',
};

/// Les espaces des autres voies (decision : ne pas y toucher) et les cles de
/// la Finance, corrigees sur `ui/finance-v1`.
bool _horsPerimetre(String cle) =>
    cle.startsWith('com.') ||
    cle.startsWith('comptable.') ||
    cle == 'ficheEleve.acces.ligne' ||
    cle == 'tuteur.accueil.accesJusqua' ||
    cle == 'tuteur.accueil.accesSansFin';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  group('la regle', () {
    test('voyelle, accent et h muet : « d\' » et « qu\' »', () {
      expect(deDevant('Aïcha'), "d'Aïcha");
      expect(deDevant('Élodie'), "d'Élodie");
      expect(deDevant('Ibrahim'), "d'Ibrahim");
      expect(deDevant('Omar'), "d'Omar");
      expect(deDevant('Hadi'), "d'Hadi");
      expect(deDevant('Al-Badr'), "d'Al-Badr");
      expect(queDevant('Aïcha'), "qu'Aïcha");
      expect(queDevant('Ibrahim'), "qu'Ibrahim");
    });

    test('consonne : « de » et « que »', () {
      expect(deDevant('Nour'), 'de Nour');
      expect(deDevant('Bilal'), 'de Bilal');
      expect(queDevant('Nour'), 'que Nour');
    });

    test('« y » suivi d une voyelle est une consonne', () {
      expect(deDevant('Youssef'), 'de Youssef');
      expect(deDevant('Yasmine'), 'de Yasmine');
      expect(queDevant('Yahya'), 'que Yahya');
      expect(deDevant('Yvette'), "d'Yvette");
    });

    test('hors du francais, le nom reste seul', () async {
      // L'arabe est charge a la demande (import differe) : setLocale attend.
      await LocaleSettings.setLocale(AppLocale.ar);
      expect(LocaleSettings.currentLocale, AppLocale.ar);
      expect(deDevant('Aïcha'), 'Aïcha');
      expect(queDevant('Nour'), 'Nour');
    });
  });

  group('des phrases reelles', () {
    test('« Appareils d\'Aïcha », « Appareils de Nour »', () {
      expect(
        t.ficheEleve.lignes.appareils(dePrenom: deDevant('Aïcha')),
        "Appareils d'Aïcha",
      );
      expect(
        t.ficheEleve.lignes.appareils(dePrenom: deDevant('Nour')),
        'Appareils de Nour',
      );
    });

    test('« Ce qu\'Ibrahim verra », « Ce que Bilal verra »', () {
      expect(
        t.adulte.acceptation.verraTitre(quePrenom: queDevant('Ibrahim')),
        "Ce qu'Ibrahim verra",
      );
      expect(
        t.adulte.acceptation.verraTitre(quePrenom: queDevant('Bilal')),
        'Ce que Bilal verra',
      );
    });

    test('« Continuer en tant qu\'Aya »', () {
      expect(
        t.eleveConnexion.profils.profilLibelle(quePrenom: queDevant('Aya')),
        "Continuer en tant qu'Aya",
      );
    });

    test('« Retirer Nour d\'Al-Badr », « Rejoindre la séance d\'An-Nour »', () {
      expect(
        t.admin.groupes.retirerTitre(
          prenom: 'Nour',
          deLibelle: deDevant('Al-Badr'),
        ),
        "Retirer Nour d'Al-Badr",
      );
      expect(
        t.classe.entree.rejoindreLecteur(deClasse: deDevant('An-Nour')),
        "Rejoindre la séance d'An-Nour",
      );
    });

    test('« Heure d\'Alger », « Présenter le début d\'Al-Fatiha »', () {
      expect(
        t.tuteur.accueil.heureDe(deVille: deDevant('Alger')),
        "Heure d'Alger",
      );
      expect(
        t.enseignant.salle.presenterSourate(deSourate: deDevant('Al-Fatiha')),
        "Présenter le début d'Al-Fatiha",
      );
    });
  });

  test(
    'aucun texte francais ne met « de » ou « que » devant un nom en dur',
    () {
      final Map<String, dynamic> fr = jsonDecode(
        File('assets/i18n/fr.i18n.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final RegExp devantNom = RegExp(r'\b(?:[Dd]e|[Qq]ue) \{(\w+)\}');
      final List<String> fautes = <String>[];
      void parcourir(String chemin, Object? noeud) {
        if (noeud is Map<String, dynamic>) {
          noeud.forEach(
            (String k, Object? v) =>
                parcourir(chemin.isEmpty ? k : '$chemin.$k', v),
          );
        } else if (noeud is String && !_horsPerimetre(chemin)) {
          for (final RegExpMatch m in devantNom.allMatches(noeud)) {
            if (_parametresNoms.contains(m.group(1))) {
              fautes.add('$chemin : $noeud');
            }
          }
        }
      }

      parcourir('', fr);
      expect(fautes, isEmpty, reason: fautes.join('\n'));
    },
  );
}
