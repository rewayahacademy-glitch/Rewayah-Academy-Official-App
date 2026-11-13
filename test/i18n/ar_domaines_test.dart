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
  // Lot demarrage (25/10/2026) : bandeau « nouvelle version ».
  'miseAJour': 1,
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
  // CALENDRIER-ET-PAUSES (12/11/2026) : le calendrier de l'ecole et la pause
  // d'un mois, arabes des l'origine (texte propose, a valider).
  'calendrier': 115,
  'pause': 37,
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
  // ADMISSION-C (30/10/2026) : l'onglet Demandes de la direction.
  'admissions': 70,
  // IMM-ACCUEIL-FRONT (31/10/2026) : accueil d'une famille deja inscrite.
  'accueilInscrits': 14,
  'accueilInvite': 8,
  // N1 (02/11/2026) : regles de portee des annonces, alertes de signalement.
  'n1': 8,
  // I1 « Inviter quelqu'un » (02/11/2026).
  'i1': 40,
  // A3-bis (02/11/2026) : remplacement sans perte de seance, page Regles.
  'a3bis': 13,
  // SNT (03/11/2026) : seance non tenue, reportee. HEURES-PROFIL H3
  // (12/11/2026) : snt.planning.heureAppareil retiree (l'heure est celle du
  // profil).
  'snt': 32,
  // D1-ter (03/11/2026) : messages de l'academie a la famille.
  'd1ter': 8,
  // PAY-UX, la page de paiement (02/11/2026).
  'payUx': 5,
  // CAHIER-C1 (06/11/2026) : « On reprend page N ».
  'cahierC1': 0,
  // CAHIER-C3 (07/11/2026) : le cahier de confirmation.
  'cahierC3': 0,
  // ACCUEIL-HORAIRE (05/11/2026).
  'accueilHoraire': 2,
  // CANDIDATS-FLUX (06/11/2026) : import des formulaires, Prevenir par e-mail,
  // rythme de la file, langues des cours.
  'candidatsFlux': 300,
  // PUSH-1 (07/11/2026) : notifications sur l'appareil, evenements par role.
  'push1': 55,
  // NOUVEAUTES (07/11/2026) : le badge « Nouveau » (« جديد »).
  'nouveautes': 1,
  // SUIVI-ELEVE (07/11/2026) : « Où j'en suis », etape, rythme.
  'suiviPedagogique': 10,
  // SOURATES (11/11/2026) : les sourates des bases au cahier.
  'cahierSourates': 3,
  // CORRIGER-SOURATE-DIRECTION (12/11/2026) : les sourates retirables d'une
  // Classe.
  'souratesRetirables': 7,
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
  // CAND-04 : le nom de chaque langue, ecrit dans cette langue, identique
  // dans les deux fichiers, sur les cartes de choix de la langue du candidat.
  'inscription.langue.francais',
  'inscription.langue.arabe',
  'salle.seance.rail.marque',
  'salle.seance.rail.sousMarque',
  'tc.bibliotheque.type.pdf',
  'nav.motSymbole',
  'commun.marque',
  'eleve.coran.sourceLien',
  'connexion.courrielIndice',
  'compte.tuteur.securite.methodeGoogle',
  // FUSEAU-IDENTITE-PRO (12/11/2026) : « Riyad · UTC+3 », la ville (deja
  // traduite, parametre) et le decalage sur UTC : un format, rien a traduire.
  'enseignant.profil.fuseauValeur',
  'agent.jetonExemple',
  // Lot 22 a : chaque langue se nomme dans sa propre langue (« Systeme /
  // Francais / العربية », plan des lots 22 a), pour qu'on retrouve la sienne.
  'commun.langue.francais',
  'commun.langue.arabe',
  // SUPPORTS-ETAGERE (directeur, 11/11/2026) : la couverture du Coran est
  // toujours en arabe, quelle que soit la langue de l'interface.
  'salle.etagere.coranCouverture.titre',
  'salle.etagere.coranCouverture.edition',
  // Raison sociale et adresse du siege : noms propres, gardes en latin.
  'juridique.coord.societe',
  'juridique.coord.adresse',
  // Hebergeurs (Supabase, Vercel, Cloudflare) : noms propres et domaines.
  'juridique.valeurs.hebergeur',
  // ANTI-ROBOT (06/11/2026) : Cloudflare Turnstile et « IP », noms propres.
  'juridique.confidentialite.s6.blocs.1',
  'admin.politiqueRevueKyc.echecEnregistrement',
  'adulte.invitation.courrielInvalide',
  // Le premier jour du mois s'ecrit en chiffre en arabe (« 1 أكتوبر »),
  // sans le suffixe francais « er » (reunion de la ligne arabe dans ccr).
  'commun.dates.premierJour',
  // Decision du directeur du 03/11/2026 : la version, en anglais seulement,
  // dans toutes les langues (« Version 0.2.0 (423) », lot FOYER-UX).
  'compte.version',
  'compte.versionSeule',
  // DATE-ARABE-SOURCE (garde-cap, 12/11/2026) : l'heure arabe s'ecrit en
  // chiffres, « 5:00 », isolee de gauche a droite (U+2066) ; aucun mot.
  'admin.regroupements.heure',
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
  // FUSEAU-IDENTITE-PRO (12/11/2026) : l'exemple du nom international d'un
  // fuseau (« Asia/Riyadh »), qui se saisit tel quel, en latin.
  'Asia',
  'Riyadh',
  'Academy',
  'PDF',
  // IMM-ACCUEIL-FRONT : le format de fichier de l'import des inscriptions.
  'CSV',
  // CPT-SUPPR-EXPORT : le format de la copie des donnees (compte.donnees).
  'JSON',
  // BIBLIOTHEQUE-UNE (12/11/2026) : le protocole d'une adresse de lien et les
  // formats audio acceptes au depot, que l'arabe garde tels quels.
  'https',
  'MP3',
  'MP',
  'M4A',
  'OGG',
  'PNG',
  'JPEG',
  'WebP',
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
  // Decision du directeur du 03/11/2026 : la ligne de version reste en
  // anglais (compte.version, compte.versionSeule).
  'Version',
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
    // FIL-ARIANE : le chevron du fil d'Ariane (« › », miroir en arabe) est
    // une ponctuation, sans mot a traduire.
    .replaceAll(RegExp('[\u2066\u2068\u2069 ·/%٪،,:()›-]'), '')
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
    // AR-CORR-2 : secondes et plafond d'heures accordes au nombre.
    expect(traductions.tc.observation.duree.secondes(n: 2), 'ثانيتان');
    expect(
      traductions.enseignant.profil.plafondValeur(nombre: 3),
      '\u20683\u2069 ساعات في الأسبوع',
    );
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
