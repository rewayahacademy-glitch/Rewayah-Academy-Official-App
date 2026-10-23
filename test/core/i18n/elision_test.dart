// Decision « fi-elision » du 05/10 (FI-R4-08, par delegation du directeur) :
// « de » et « que » devant un nom s'elident devant une voyelle, dans toute
// l'application (jamais devant h : revue croisee du 08/10) (hors voies Communications et Comptable, et hors
// Finance, deja faite sur sa branche).
//
// - la regle de lib/core/i18n/elision.dart, y compris « y » consonne ;
// - hors du francais : le nom seul pour une cle traduite (ou sans cle,
//   AR-ENS-1), l'elision francaise pour un texte de repli dont l'appel
//   passe sa cle (voir aussi elision_repli_arabe_test) ;
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
        'الانضمام إلى حصة \u2068Al-Badr\u2069',
      );
    });

    test('en arabe, sans cle, le nom seul (AR-ENS-1)', () async {
      await LocaleSettings.setLocale(AppLocale.ar);
      expect(deDevant('Al-Badr'), 'Al-Badr');
      expect(queDevant('Nour'), 'Nour');
    });

    test('en arabe, une cle NON traduite garde l elision francaise', () async {
      await LocaleSettings.setLocale(AppLocale.ar);
      // Repli francais : la cle passee n'est pas traduite en arabe.
      const String cle = 'ficheEleve.finances.erreurTitre';
      expect(deDevant('Aïcha', cle: cle), "d'Aïcha");
      expect(queDevant('Nour', cle: cle), 'que Nour');
    });

    test('en francais, la cle ne change rien', () {
      expect(
        deDevant('Al-Badr', cle: 'classe.entree.rejoindreLecteur'),
        "d'Al-Badr",
      );
    });

    test('les cles NON traduites en arabe qui recoivent un nom elide passent '
        'leur cle a deDevant', () {
      // Reunion de la ligne arabe dans ccr (10/10) : sans `cle:`, l'arabe
      // recoit le nom seul. Une cle francaise qui porte un parametre
      // `{de...}` / `{que...}` et que l'arabe ne traduit pas encore tombe
      // en repli francais : son appel doit passer `cle:`, sinon le repli lirait
      // « Les finances Aïcha ».
      Map<String, String> aplatir(Object? noeud, [String chemin = '']) {
        final Map<String, String> sortie = <String, String>{};
        if (noeud is Map<String, dynamic>) {
          noeud.forEach((String k, Object? v) {
            final String nom = k.replaceFirst(RegExp(r'\(.*\)$'), '');
            sortie.addAll(aplatir(v, chemin.isEmpty ? nom : '$chemin.$nom'));
          });
        } else if (noeud is String) {
          sortie[chemin] = noeud;
        }
        return sortie;
      }

      Map<String, String> lire(String langue) => aplatir(
        jsonDecode(File('assets/i18n/$langue.i18n.json').readAsStringSync()),
      );
      String sansForme(String cle) =>
          cle.replaceFirst(RegExp(r'\.(zero|one|two|few|many|other)$'), '');
      final Set<String> traduites = lire('ar').keys.map(sansForme).toSet();
      final Set<String> enRepli = <String>{
        for (final MapEntry<String, String> e in lire('fr').entries)
          if (RegExp(r'\{(?:de|que)[A-Z]\w*\}').hasMatch(e.value) &&
              !traduites.contains(sansForme(e.key)))
            sansForme(e.key),
      };
      const Set<String> appeleesAvecCle = <String>{
        'foyer.finances.voirDetailSemantique',
        'ficheEleve.finances.moisNonFinance',
        'ficheEleve.finances.indisponiblePhrase',
        'ficheEleve.finances.erreurTitre',
        'ficheEleve.finances.voirToutSemantique',
        'ficheEleve.finances.voirMouvementsSemantique',
        'ficheEleve.mouvements.contexte',
        'ficheEleve.mouvements.erreurTitre',
        'ficheEleve.mouvements.indisponiblePhrase',
        'admin.groupes.formulaire.creneauxLibresDe',
        'admin.groupes.formulaire.disponibilitesInconnues',
        'admin.regroupements.heureFuseau',
        'admin.regroupements.fuseauValeur',
        'admin.agents.libelleAuto',
        'admin.finance.vue.contexte',
        'admin.finance.vue.graphiqueRepartitionDetail',
        'admin.finance.vue.topClassesDetail',
        'suiviDemandes.carteTitre',
        'suiviFamille.carteTitre',
        'suiviFamille.detailTitre',
        'suiviFamille.fuseau',
        'suiviFamille.notification.enAttente',
        'suiviFamille.notification.eleveIntegre',
        'suiviFamille.notification.premiereSeance',
        'suiviFamille.notification.close',
        'suiviFamille.notification.dejaEnClasse',
        'presentationTuteur.refusee',
        'suiviDemandes.heureFuseau',
        'suiviDemandes.fuseauValeur',
        'suiviDemandes.debutValeur',
        'suiviDemandes.notification.envoyee',
        'suiviDemandes.notification.classeValidee',
        'suiviDemandes.notification.enseignantAffecte',
        'suiviDemandes.notification.close',
      };
      // Une cle traduite en sort ; une nouvelle cle en repli y entre.
      expect(enRepli.difference(appeleesAvecCle), isEmpty);
      // Et les appels du code passent bien leur cle.
      final String code = <String>[
        'lib/features/foyer/foyer_page.dart',
        'lib/features/foyer/fiche/finances_page.dart',
        'lib/features/foyer/fiche/mouvements_page.dart',
        'lib/features/admin_groupes/groupes_page.dart',
        'lib/features/admin_regroupements/regroupements_libelles.dart',
        'lib/features/admin_acces_agents/acces_agents_page.dart',
        'lib/features/admin_finance/vue_globale_finance.dart',
        'lib/features/suivi_demandes/suivi_demandes_page.dart',
        'lib/features/suivi_demandes/libelles_suivi_demandes.dart',
        'lib/features/suivi_famille/libelles_suivi_famille.dart',
        'lib/features/suivi_famille/suivi_famille_page.dart',
        'lib/features/presentation_tuteur/demandes_presentation_page.dart',
      ].map((String f) => File(f).readAsStringSync()).join();
      for (final String cle in enRepli) {
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
