// Decision « fi-elision » du 05/10 (FI-R4-08, par delegation du directeur) :
// « de » et « que » devant un nom s'elident devant une voyelle, dans toute
// l'application (jamais devant h : revue croisee du 08/10) (hors voies Communications et Comptable, et hors
// Finance, deja faite sur sa branche).
//
// - la regle de lib/core/i18n/elision.dart, y compris « y » consonne ;
// - hors du francais : le nom seul pour une cle traduite, l'elision
//   francaise pour un texte de repli (voir aussi elision_repli_arabe_test) ;
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

/// Les espaces des autres voies (decision : ne pas y toucher), les cles de
/// la Finance, corrigees sur `ui/finance-v1`, et les dossiers (deja elides).
bool _horsPerimetre(String cle) =>
    cle.startsWith('com.') ||
    cle.startsWith('comptable.') ||
    cle == 'ficheEleve.acces.ligne' ||
    // Les dossiers ont leur propre elision, par des cles « ...Elide » et
    // sans h (« de Hana », textes_dossier.dart) : la cle « de » ne sert
    // qu'a un nom qui commence par une consonne.
    cle.startsWith('dossiers.');

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  group('la regle', () {
    test('voyelle et accent : « d\' » et « qu\' »', () {
      expect(deDevant('Aïcha'), "d'Aïcha");
      expect(deDevant('Élodie'), "d'Élodie");
      expect(deDevant('Ibrahim'), "d'Ibrahim");
      expect(deDevant('Omar'), "d'Omar");
      expect(deDevant('Al-Badr'), "d'Al-Badr");
      expect(queDevant('Aïcha'), "qu'Aïcha");
      expect(queDevant('Ibrahim'), "qu'Ibrahim");
    });

    test('consonne et h (aspire) : « de » et « que »', () {
      expect(deDevant('Hamza'), 'de Hamza');
      expect(deDevant('Hana'), 'de Hana');
      expect(queDevant('Hadi'), 'que Hadi');
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

    test('en arabe, une cle traduite recoit le nom seul', () async {
      // L'arabe est charge a la demande (import differe) : setLocale attend.
      await LocaleSettings.setLocale(AppLocale.ar);
      expect(LocaleSettings.currentLocale, AppLocale.ar);
      const String cle = 'classe.entree.rejoindreLecteur';
      expect(deDevant('Al-Badr', cle: cle), 'Al-Badr');
      expect(
        t.classe.entree.rejoindreLecteur(
          deClasse: deDevant('Al-Badr', cle: cle),
        ),
        'الانضمام إلى حصة Al-Badr',
      );
    });

    test('en arabe, une cle NON traduite garde l elision francaise', () async {
      await LocaleSettings.setLocale(AppLocale.ar);
      // Repli francais : la cle passee n'est pas traduite en arabe.
      expect(deDevant('Aïcha', cle: 'ficheEleve.lignes.appareils'), "d'Aïcha");
      expect(queDevant('Nour'), 'que Nour');
    });

    test('en francais, la cle ne change rien', () {
      expect(
        deDevant('Al-Badr', cle: 'classe.entree.rejoindreLecteur'),
        "d'Al-Badr",
      );
    });

    test('les cles traduites en arabe qui recoivent un nom elide passent '
        'leur cle a deDevant', () {
      // Chaque cle arabe qui porte un parametre `{de...}` / `{que...}`, ou
      // un `{classe}` rempli par deDevant cote francais, doit etre appelee
      // avec `cle:` : sinon l'arabe recevrait « d'Al-Badr ».
      final Map<String, dynamic> ar = jsonDecode(
        File('assets/i18n/ar.i18n.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final Set<String> trouvees = <String>{};
      void parcourir(String chemin, Object? noeud) {
        if (noeud is Map<String, dynamic>) {
          noeud.forEach(
            (String k, Object? v) =>
                parcourir(chemin.isEmpty ? k : '$chemin.$k', v),
          );
        } else if (noeud is String &&
            RegExp(r'\{(?:de|que)[A-Z]\w*\}').hasMatch(noeud)) {
          trouvees.add(chemin);
        }
      }

      parcourir('', ar);
      const Set<String> appeleesAvecCle = <String>{
        'classe.entree.rejoindreLecteur',
      };
      expect(trouvees.difference(appeleesAvecCle), isEmpty);
      // Et les appels du code passent bien leur cle.
      final String code = <String>[
        'lib/core/tc_horloge/emplacement_entree.dart',
        'lib/features/journee/journee_page.dart',
      ].map((String f) => File(f).readAsStringSync()).join();
      for (final String cle in <String>[
        'classe.entree.rejoindreLecteur',
        'enseignant.journee.cahierObligatoire',
        'enseignant.journee.voirCahier',
      ]) {
        expect(code, contains("cle: '$cle'"), reason: cle);
      }
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
