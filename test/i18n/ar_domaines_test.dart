// AR-COMPLET-1 : l'interface est entierement traduite en arabe, et le reste.
//
// Tranches AR-SALLE-1, AR-TC-1, AR-ENS-1, AR-TRANSVERSE-1, AR-ELEVE-1,
// AR-FAMILLE-1, AR-ADULTE-1, AR-CONTROLE-1 et AR-ADMIN-1 : chaque cle du
// francais a sa traduction arabe, avec exactement les memes parametres ;
// chaque parametre ajoute par ces tranches est isole des deux cotes
// (U+2068 juste avant, U+2069 juste apres, bornes equilibrees),
// pour qu'un nom latin ne renverse pas la phrase. Un nouveau domaine
// francais doit etre ajoute a [_domaines] (le test global le verifie).
//
// Reunion de la ligne arabe dans ccr (10/10) : les libelles que ccr a ajoutes
// apres le depart de la ligne arabe n'ont pas encore de traduction. Ils sont
// figes dans `tool/ar_socle_non_traduites.txt`, socle qui ne peut que
// diminuer : une cle traduite doit en sortir, aucune cle nouvelle n'y entre.
// Les domaines venus de ccr sans tranche arabe sont dans [_enAttente].

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';

/// Les domaines entierement traduits, et leur nombre minimal de cles.
const Map<String, int> _domaines = <String, int>{
  'salle': 300,
  'tc': 450,
  'enseignant': 400,
  // AR-TRANSVERSE-1.
  'nav': 40,
  'commun': 70,
  'accessibilite': 50,
  'reseau': 3,
  'etat': 10,
  'vide': 4,
  'notifications': 5,
  'choix': 2,
  'accuse': 1,
  'aConstruire': 1,
  'juridique': 90,
  'destructif': 0,
  'avatar': 0,
  'pin': 2,
  'enfant': 2,
  'galerie': 8,
  // AR-ELEVE-1.
  'classe': 140,
  'ficheEleve': 80,
  'parcours': 80,
  'eleveConnexion': 70,
  'eleve': 55,
  'presence': 20,
  'priere': 10,
  // AR-FAMILLE-1.
  'compte': 180,
  // Menage du 17/10 (passation point 8) : les libelles orphelins des
  // anciens reglages de l'enfant et des disponibilites sont retires.
  'tuteur': 100,
  'historique': 90,
  'appareils': 75,
  'connexion': 40,
  'attente': 35,
  // Lot E6 : la page unique des accords.
  'accords': 8,
  'inscription': 30,
  'consentement': 30,
  'foyer': 50,
  // AR-ADULTE-1.
  'adulte': 300,
  'dossiers': 110,
  'kyc': 12,
  'contrat': 10,
  'creneaux': 20,
  'disponibilites': 10,
  // AR-CONTROLE-1.
  'controleur': 190,
  'agent': 12,
  // AR-ADMIN-1.
  'admin': 590,
  // RECH-1, RECH-2 : la surface de recherche, arabe des l'origine.
  'recherche': 55,
  // AR-SUIVI-FAMILLE.
  'suiviFamille': 40,
  // EA-HL-DOUBLE-1 etendu (17/10) : ce qui manque, hors ligne, par ecran.
  'sansDonnees': 12,
  // PE (18/10/2026) : protection des enfants, arabe des l'origine.
  'protectionEnfants': 7,
  'codeConduite': 8,
  // AVIS-PUBLICS (19/10/2026) : formulaire public d'avis et moderation.
  'avis': 100,
  // COURRIELS-1 (23/10/2026) : e-mails sortants de la direction.
  'courriels': 70,
};

/// Les domaines francais venus de ccr sans tranche arabe (reunion du 10/10) :
/// entierement dans le socle, ou traduits par les voies Communications et
/// Comptabilite selon leurs propres regles (`com`, `comptable`), pas encore
/// relus par la ligne arabe. Un domaine en sort quand sa tranche arabe entre
/// dans [_domaines].
const Set<String> _enAttente = <String>{
  // RECRUT-ECRANS : arabe non prioritaire au lancement (REPRISE.md).
  'presentationTuteur',
  'reprisesAdmin',
  'recrutement',
  'formulaire',
  'motifs',
  'suiviDemandes',
  'alertes',
  'argent',
  'identiteProfil',
  'com',
  'comptable',
};

/// Les cles francaises sans traduction arabe a la reunion (socle fige).
final Set<String> _socle = File('tool/ar_socle_non_traduites.txt')
    .readAsLinesSync()
    .where((String l) => l.isNotEmpty && !l.startsWith('#'))
    .toSet();

Map<String, String> _aplatir(
  Map<String, dynamic> carte, [
  String prefixe = '',
]) {
  final Map<String, String> sortie = <String, String>{};
  carte.forEach((String cle, dynamic valeur) {
    if (valeur is Map<String, dynamic>) {
      sortie.addAll(_aplatir(valeur, '$prefixe$cle.'));
    } else if (valeur is List<dynamic>) {
      for (int i = 0; i < valeur.length; i++) {
        sortie['$prefixe$cle.$i'] = valeur[i] as String;
      }
    } else {
      sortie['$prefixe$cle'] = valeur as String;
    }
  });
  return sortie;
}

Map<String, String> _domaine(String langue, String domaine) => _aplatir(
  (jsonDecode(File('assets/i18n/$langue.i18n.json').readAsStringSync())
          as Map<String, dynamic>)[domaine]
      as Map<String, dynamic>,
  '$domaine.',
);

/// Les textes gardes en latin (marque, format de fichier).
const Set<String> _latins = <String>{
  'salle.seance.rail.marque',
  'salle.seance.rail.sousMarque',
  'tc.bibliotheque.type.pdf',
  'nav.motSymbole',
  'commun.marque',
  'eleve.coran.sourceLien',
  'connexion.courrielIndice',
  'compte.tuteur.securite.methodeGoogle',
  'dossiers.file.zoneUtc',
  'agent.jetonExemple',
  // Raison sociale et adresse du siege : noms propres, gardes en latin.
  'juridique.coord.societe',
  'juridique.coord.adresse',
  // Hebergeurs (Supabase, Vercel, Cloudflare) : noms propres et domaines.
  'juridique.valeurs.hebergeur',
  'admin.politiqueRevueKyc.echecEnregistrement',
  'adulte.invitation.courrielInvalide',
  // Le premier jour du mois s'ecrit en chiffre en arabe (« 1 أكتوبر »),
  // sans le suffixe francais « er » (reunion de la ligne arabe dans ccr).
  'commun.dates.premierJour',
};

final RegExp _parametre = RegExp(r'\{\w+\}');

List<String> _parametres(String texte) =>
    _parametre.allMatches(texte).map((Match m) => m[0]!).toList()..sort();

/// Ce qui ne va pas dans l'isolation des parametres de [texte] : un
/// parametre qui n'est pas IMMEDIATEMENT precede de U+2068 ET suivi de
/// U+2069, ou des U+2068 / U+2069 desequilibres (un U+2069 sans ouvrant, un
/// U+2068 jamais ferme : il s'etendrait jusqu'a la fin du paragraphe).
List<String> defautsIsolation(String texte) {
  final List<String> defauts = <String>[];
  for (final Match m in _parametre.allMatches(texte)) {
    final bool ouvert = m.start > 0 && texte[m.start - 1] == '\u2068';
    final bool ferme = m.end < texte.length && texte[m.end] == '\u2069';
    if (!ouvert || !ferme) defauts.add(m[0]!);
  }
  int profondeur = 0;
  for (final int unite in texte.codeUnits) {
    // U+2066 (LRI) ouvre aussi un isolat : une fraction lue de gauche a
    // droite (« 2/4 ») isole ses deux parametres dedans.
    if (unite >= 0x2066 && unite <= 0x2068) profondeur++;
    if (unite == 0x2069 && --profondeur < 0) {
      defauts.add('U+2069 sans U+2068');
      profondeur = 0;
    }
  }
  if (profondeur != 0) defauts.add('U+2068 non ferme');
  return defauts;
}

/// Les mots latins admis dans une valeur arabe : la marque, un format, un
/// nom de produit ou un sigle que l'arabe garde tel quel.
const Set<String> _motsLatinsAdmis = <String>{
  'Rewayah',
  'Academy',
  'PDF',
  // IMM-ACCUEIL-FRONT : le format de fichier de l'import des inscriptions.
  'CSV',
  // CPT-SUPPR-EXPORT : le format de la copie des donnees (compte.donnees).
  'JSON',
  'QR',
  'UTC',
  'Google',
  'Android',
  'iPhone',
  'iPad',
  'Tanzil',
  // MUSHAF-15L : le credit du jeu de donnees de mise en page (CC-BY-4.0).
  'quran',
  'ws',
  'CC',
  'BY',
  'Project',
};

/// Les codes de situation de demonstration (SAL-00, PED-01...) et les
/// identifiants d'exemple (ELV-0042), gardes en latin (ecart voulu 3 de
/// AR-SALLE-1).
final RegExp _codeSituation = RegExp(r'\b[A-Z]{2,4}-\d{2,4}\b');

/// Les mots latins de deux lettres ou plus restes dans [texte], hors
/// parametres, codes de situation et mots admis.
List<String> motsLatinsInattendus(String texte) => RegExp('[A-Za-zÀ-ÿ]{2,}')
    .allMatches(texte.replaceAll(_parametre, '').replaceAll(_codeSituation, ''))
    .map((Match m) => m[0]!)
    .where((String mot) => !_motsLatinsAdmis.contains(mot))
    .toList();

/// Rien que des parametres et de la ponctuation : rien a traduire.
/// Les formes du pluriel arabe : le francais n'en a que deux (one, other).
const Set<String> _formesArabes = <String>{'zero', 'one', 'two', 'few', 'many'};

/// La forme `other` du francais dont [cle] est une forme plurielle arabe,
/// ou null si [cle] n'est pas une forme plurielle.
String? _autreFrancais(String cle, Map<String, String> fr) {
  final int point = cle.lastIndexOf('.');
  if (point < 0 || !_formesArabes.contains(cle.substring(point + 1))) {
    return null;
  }
  return fr['${cle.substring(0, point)}.other'];
}

/// Un nombre suivi d'un pluriel de 3 a 10 (« {n} أيام », parametre isole) hors d'un pluriel
/// slang : faux pour 2 (duel) et pour 11 et plus (singulier). Une telle phrase
/// passe en pluriel (zero, one, two, few, many, other).
///
/// AR-CORR-2 : une unite apres un nombre isole (« {n} دقيقة », « {n} ساعة »,
/// « {n} ثوانٍ », « {n} مقاعد », « {n} يوم ») est fausse pour une partie des
/// nombres. Hors pluriel slang, une duree s'ecrit avec l'unite abregee
/// (« {n} د », « {n} س », « {n} ث ») ; un compte passe en pluriel.
final RegExp _nombrePluriel = RegExp(
  '\u2069 (أيام|طلاب|ساعات|ملفات|طلبات|مرات|مستويات|أشخاص|مدخلات|دقائق|'
  'أسابيع|زيارات|عناصر|دروس|حصص|فصول|آيات|صفحات|رسائل|أسئلة|أجهزة|سور|'
  'دقيقة|ساعة|ثانية|ثوان|مقاعد|مقعد|يوم|أسبوع)',
);

bool _sansMots(String texte) => texte
    .replaceAll(_parametre, '')
    .replaceAll(RegExp('[\u2066\u2068\u2069 ·/%٪،,:()-]'), '')
    .isEmpty;

void main() {
  test('les detecteurs voient une borne manquante et un mot francais', () {
    expect(defautsIsolation('\u2068{a}\u2069 et \u2068{b}\u2069'), isEmpty);
    expect(defautsIsolation('\u2068{a}'), isNotEmpty);
    expect(defautsIsolation('{a}\u2069'), isNotEmpty);
    expect(defautsIsolation('\u2068{a}\u2069\u2069'), isNotEmpty);
    expect(defautsIsolation('\u2068 {a}\u2069'), isNotEmpty);
    expect(
      defautsIsolation('\u2066\u2068{a}\u2069/\u2068{b}\u2069\u2069'),
      isEmpty,
    );
    expect(motsLatinsInattendus('عرض Présenter'), <String>['Présenter']);
    expect(motsLatinsInattendus('SAL-00 Rewayah \u2068{nom}\u2069'), isEmpty);
  });

  _domaines.forEach((String domaine, int minimum) {
    group(domaine, () {
      final Map<String, String> fr = _domaine('fr', domaine);
      final Map<String, String> ar = _domaine('ar', domaine);

      test('chaque cle $domaine.* a sa traduction arabe', () {
        expect(fr.length, greaterThan(minimum));
        final List<String> manquantes = fr.keys
            .where((String cle) => !ar.containsKey(cle))
            .where((String cle) => !_socle.contains(cle))
            .toList();
        expect(manquantes, isEmpty);
        expect(
          ar.keys.where(
            (String cle) =>
                !fr.containsKey(cle) && _autreFrancais(cle, fr) == null,
          ),
          isEmpty,
        );
      });

      test('memes parametres qu\'en francais', () {
        for (final MapEntry<String, String> e in ar.entries) {
          final String? autre = _autreFrancais(e.key, fr);
          if (autre == null) {
            expect(
              _parametres(e.value),
              _parametres(fr[e.key]!),
              reason: e.key,
            );
          } else {
            // Une forme du pluriel peut taire {n} (« طالبان ») mais n'invente
            // aucun parametre.
            expect(
              _parametres(e.value)
                  .toSet()
                  .difference(_parametres(autre).toSet()),
              isEmpty,
              reason: e.key,
            );
          }
        }
      });

      test('pluriels arabes complets (zero, one, two, few, many, other)', () {
        final Iterable<String> pluriels = fr.keys
            .where((String cle) => cle.endsWith('.other'))
            .where((String cle) => !_socle.contains(cle))
            .map((String cle) => cle.substring(0, cle.length - 6));
        for (final String pluriel in pluriels) {
          for (final String forme in <String>{..._formesArabes, 'other'}) {
            expect(
              ar.containsKey('$pluriel.$forme'),
              isTrue,
              reason: '$pluriel.$forme',
            );
          }
        }
      });

      test('parametres isoles (U+2068 ... U+2069)', () {
        for (final MapEntry<String, String> e in ar.entries) {
          expect(defautsIsolation(e.value), isEmpty, reason: e.key);
        }
      });

      test('un nombre variable passe par un pluriel slang', () {
        for (final MapEntry<String, String> e in ar.entries) {
          final String forme = e.key.substring(e.key.lastIndexOf('.') + 1);
          if (forme == 'other' || _formesArabes.contains(forme)) continue;
          expect(_nombrePluriel.hasMatch(e.value), isFalse, reason: e.key);
        }
      });

      test('du texte arabe, jamais le francais recopie', () {
        final RegExp arabe = RegExp('[؀-ۿ]');
        for (final MapEntry<String, String> e in ar.entries) {
          if (_latins.contains(e.key) || _sansMots(e.value)) continue;
          expect(arabe.hasMatch(e.value), isTrue, reason: e.key);
          if (fr.containsKey(e.key)) {
            expect(e.value, isNot(fr[e.key]), reason: e.key);
          }
        }
      });

      test('aucun mot francais reste dans une valeur arabe', () {
        for (final MapEntry<String, String> e in ar.entries) {
          if (_latins.contains(e.key)) continue;
          expect(motsLatinsInattendus(e.value), isEmpty, reason: e.key);
        }
      });
    });
  });

  test('AR-COMPLET-1 : aucune cle francaise sans traduction arabe', () {
    Map<String, String> tout(String langue) => _aplatir(
      jsonDecode(File('assets/i18n/$langue.i18n.json').readAsStringSync())
          as Map<String, dynamic>,
    );
    final Map<String, String> fr = tout('fr');
    final Map<String, String> ar = tout('ar');
    // Hors socle, aucune cle sans traduction ; et le socle ne garde que des
    // cles francaises encore sans traduction (il ne peut que diminuer).
    expect(
      fr.keys.where(
        (String cle) => !ar.containsKey(cle) && !_socle.contains(cle),
      ),
      isEmpty,
    );
    expect(
      _socle.where((String cle) => !fr.containsKey(cle) || ar.containsKey(cle)),
      isEmpty,
      reason: 'cle traduite ou retiree : la sortir du socle',
    );
    // Chaque domaine du francais est garde par la boucle ci-dessus, ou en
    // attente de sa tranche arabe.
    final Set<String> domaines = fr.keys
        .map((String cle) => cle.split('.').first)
        .toSet();
    expect(
      domaines.difference(_domaines.keys.toSet()).difference(_enAttente),
      isEmpty,
    );
  });

  test('slang rend l\'arabe a l\'execution', () async {
    final Traductions traductions = await AppLocale.ar.build();
    expect(traductions.salle.seance.bibliotheque.presenter, 'عرض على الفصل');
    expect(
      traductions.salle.seance.surface.page(titre: 'X', page: 1, pages: 2),
      '\u2068X\u2069، الصفحة \u20681\u2069 من \u20682\u2069',
    );
    expect(traductions.tc.bibliotheque.titre, 'المكتبة');
    // Un pluriel garde le nom de son parametre (param=jours), en arabe
    // comme en francais.
    expect(traductions.admin.tableau.attenteJours(jours: 2), 'ينتظر منذ يومين');
    expect(t.admin.tableau.attenteJours(jours: 1), 'En attente depuis 1 jour');
    expect(t.admin.tableau.attenteJours(jours: 4), 'En attente depuis 4 jours');
    // Les six formes du pluriel arabe sont choisies a l'execution.
    expect(traductions.controleur.controle.eleves(n: 2), 'طالبان');
    expect(traductions.controleur.controle.eleves(n: 5), '\u20685\u2069 طلاب');
    expect(
      traductions.controleur.controle.eleves(n: 11),
      '\u206811\u2069 طالبًا',
    );
    // AR-CORR-2 : places, secondes et plafond d'heures accordes au nombre.
    expect(
      traductions.classe.pageCatalogue.places(nombre: 2),
      'مقعدان متبقيان',
    );
    expect(
      traductions.classe.pageCatalogue.places(nombre: 11),
      '\u206811\u2069 مقعدًا متبقيًا',
    );
    // Le singulier separe garde la shadda de la forme zero (« متبقٍّ »).
    expect(traductions.classe.pageCatalogue.placeUne, 'مقعد واحد متبقٍّ');
    expect(traductions.tc.observation.duree.secondes(n: 2), 'ثانيتان');
    expect(
      traductions.enseignant.profil.plafondValeur(nombre: 3),
      '\u20683\u2069 ساعات في الأسبوع',
    );
    expect(t.classe.pageCatalogue.places(nombre: 1), '1 place restante');
    expect(t.salle.fin.enseignant.connectes(n: 1), '1 élève connecté');
    expect(
      t.tc.observation.annonce.tuteursObservent(nombre: 3),
      '3 tuteurs observent',
    );
    expect(
      traductions.tc.bibliotheque.aucunResultat.message,
      isNot(t.tc.bibliotheque.aucunResultat.message),
    );
  });
}
