// Le nom en lettres latines (decision du directeur du 23/10/2026,
// `docs/current/DECISION-CANDIDATURES-2026-10-21.md`, section « Les noms dans
// une seule ecriture sur les listes »).
//
// Deux fonctions pures, sans reseau ni etat :
//
// - [nomEstLatin] : la meme definition que `private.nom_est_latin()` cote
//   serveur (au moins une lettre latine, aucune autre ecriture ; chiffres,
//   espaces et ponctuation sont neutres) ;
// - [proposerNomLatin] : une **proposition** de translitteration de l'arabe,
//   par des regles simples et previsibles. Elle n'est jamais imposee ni
//   enregistree d'elle-meme : la personne la corrige ou la confirme, et seul le
//   texte qu'elle confirme part au serveur. Un nom ecrit sans voyelles brèves
//   ne se lit pas de facon unique : la proposition est un point de depart.
//
// Regles de [proposerNomLatin], dans l'ordre :
// 1. les lettres latines, chiffres, espaces et signes sont gardes tels quels ;
// 2. un mot courant (liste ci-dessous) prend son ecriture usuelle ;
// 3. le « al » de l'article se detache par un trait d'union (« Al-Zahra ») ;
// 4. chaque lettre arabe prend une ecriture fixe (table ci-dessous) ; un mot
//    sans voyelles brèves recoit un « a » entre deux consonnes de suite ; un
//    mot qui en porte les garde, la chadda double la lettre ;
// 5. chaque mot prend une majuscule.
library;

/// Les lettres que la definition du nom latin accepte (basiques, supplement
/// latin-1, etendus A et B, additionnels), hors accents combinants.
const String _lettresLatines = r'A-Za-zÀ-ÖØ-öø-ɏḀ-ỿ';

final RegExp _uneLettreLatine = RegExp('[$_lettresLatines]');

// Ce qui n'est ni une lettre latine, ni un accent combinant, ni un chiffre, un
// espace ou un signe de ponctuation : une autre ecriture (ou un symbole).
final RegExp _autreEcriture = RegExp(
  '[^\\s\\d$_lettresLatines\\u0300-\\u036F'
  r'''!"#%&'()*+,\-./:;<=>?@\[\\\]^_`{|}~'''
  r'¡-¿×÷‐-‧‰-⁞]',
);

/// Vrai quand [texte] porte au moins une lettre latine et aucune autre
/// ecriture. Meme definition que `private.nom_est_latin()` (serveur) : l'ecran
/// et la base s'accordent sur ce qu'est un nom latin.
bool nomEstLatin(String texte) =>
    _uneLettreLatine.hasMatch(texte) && !_autreEcriture.hasMatch(texte);

/// Vrai quand le nom saisi demande la question « Votre nom en lettres
/// latines » : il porte une autre ecriture que l'alphabet latin. Un champ
/// vide ne la pose pas.
bool nomDemandeEcritureLatine(String texte) =>
    texte.trim().isNotEmpty && !nomEstLatin(texte);

/// Les blancs d'un nom latin saisi : de tete, de queue et repetes. Le serveur
/// fait de meme ; l'ecran envoie deja le texte propre.
String nomLatinNettoye(String texte) =>
    texte.trim().replaceAll(RegExp(r'\s+'), ' ');

/// Les mots arabes courants (formes sans voyelles brèves), a leur ecriture
/// usuelle. Une liste courte et fermee : ce qui n'y est pas passe par la table
/// des lettres.
const Map<String, String> _motsCourants = <String, String>{
  'محمد': 'Mohamed',
  'أحمد': 'Ahmed',
  'احمد': 'Ahmed',
  'علي': 'Ali',
  'عمر': 'Omar',
  'عثمان': 'Othman',
  'يوسف': 'Youssef',
  'إبراهيم': 'Ibrahim',
  'ابراهيم': 'Ibrahim',
  'إسماعيل': 'Ismail',
  'اسماعيل': 'Ismail',
  'موسى': 'Moussa',
  'عيسى': 'Issa',
  'يحيى': 'Yahya',
  'مريم': 'Maryam',
  'فاطمة': 'Fatima',
  'عائشة': 'Aicha',
  'خديجة': 'Khadija',
  'زينب': 'Zeinab',
  'بن': 'Ben',
  'ابن': 'Ibn',
  'أبو': 'Abou',
  'أبي': 'Abi',
  'عبد': 'Abd',
  'عبدالله': 'Abdallah',
  'الله': 'Allah',
  'الرحمن': 'Rahman',
  'الرحيم': 'Rahim',
  'الدين': 'Din',
  'الزهراء': 'Al-Zahra',
};

/// L'ecriture latine de chaque lettre arabe. Les voyelles longues et les
/// semi-voyelles sont traitees a part.
const Map<String, String> _consonnes = <String, String>{
  'ب': 'b',
  'ت': 't',
  'ث': 'th',
  'ج': 'j',
  'ح': 'h',
  'خ': 'kh',
  'د': 'd',
  'ذ': 'dh',
  'ر': 'r',
  'ز': 'z',
  'س': 's',
  'ش': 'sh',
  'ص': 's',
  'ض': 'd',
  'ط': 't',
  'ظ': 'z',
  'ع': 'a',
  'غ': 'gh',
  'ف': 'f',
  'ق': 'q',
  'ك': 'k',
  'ل': 'l',
  'م': 'm',
  'ن': 'n',
  'ه': 'h',
  'ء': '',
  'پ': 'p',
  'چ': 'tch',
  'گ': 'g',
  'ڤ': 'v',
};

/// Les voyelles et semi-voyelles : une ecriture fixe, jamais une consonne
/// (donc aucun « a » intercale a cote d'elles).
const Map<String, String> _voyelles = <String, String>{
  'ا': 'a',
  'أ': 'a',
  'إ': 'i',
  'آ': 'a',
  'ٱ': 'a',
  'ى': 'a',
  'ة': 'a',
  'ؤ': 'ou',
  'ئ': 'i',
  'و': 'ou',
  'ي': 'i',
  'ی': 'i',
};

/// Les voyelles brèves (signes en surcharge) et leur ecriture.
const Map<String, String> _breves = <String, String>{
  'َ': 'a', // fatha
  'ُ': 'ou', // damma
  'ِ': 'i', // kasra
};

const String _chadda = 'ّ';
const String _soukoun = 'ْ';
const String _tatwil = 'ـ';

/// Les autres signes en surcharge, ignores (tanwin, hamza et madda en
/// surcharge, alif suscrit).
final RegExp _signesIgnores = RegExp('[\\u064B-\\u064D\\u0653-\\u0655\\u0670]');

bool _estLettreArabe(String c) =>
    _consonnes.containsKey(c) || _voyelles.containsKey(c);

/// Propose l'ecriture latine de [nom].
///
/// Un nom deja latin est rendu tel quel. Ce qui n'est ni arabe ni latin est
/// garde tel quel aussi : la proposition n'est alors pas un nom latin et
/// l'ecran le dit, la personne la corrige. Rend toujours un texte aux blancs
/// nettoyes.
String proposerNomLatin(String nom) {
  final String propre = nomLatinNettoye(nom);
  if (propre.isEmpty || nomEstLatin(propre)) {
    return propre;
  }
  return propre
      .split(' ')
      .map(_proposerMot)
      .where((String m) => m.isNotEmpty)
      .join(' ');
}

String _proposerMot(String mot) {
  final String sansTatwil = mot.replaceAll(_tatwil, '');
  final String sansSignes = sansTatwil.replaceAll(_signesIgnores, '');
  // Un mot sans lettre arabe (latin, chiffres) reste tel quel.
  if (!sansSignes.split('').any(_estLettreArabe)) {
    return sansSignes;
  }
  final String nu = sansSignes.replaceAll(
    RegExp('[\\u064E\\u064F\\u0650\\u0651\\u0652]'),
    '',
  );
  final String? courant = _motsCourants[nu];
  if (courant != null) {
    return courant;
  }
  // « al » de l'article : detache par un trait d'union, sauf pour le mot
  // « al » seul.
  if (nu.length > 3 && nu.startsWith('ال')) {
    final String reste = sansSignes.substring(sansSignes.indexOf('ل') + 1);
    final String reste0 =
        _motsCourants[reste.replaceAll(
          RegExp('[\\u064E\\u064F\\u0650\\u0651\\u0652]'),
          '',
        )] ??
        _majuscule(_lettres(reste));
    return 'Al-$reste0';
  }
  return _majuscule(_lettres(sansSignes));
}

String _lettres(String mot) {
  final List<String> signes = mot.split('');
  final bool voyellesPresentes = signes.any(_breves.containsKey);
  final StringBuffer sortie = StringBuffer();
  // La derniere lettre ecrite etait une consonne arabe, sans voyelle apres elle.
  bool consonnePrecedente = false;
  // La derniere ecriture est une voyelle breve : la lettre de voyelle longue
  // qui la suit (« كَرِيم ») ne la double pas.
  String? breveEcrite;
  for (int i = 0; i < signes.length; i++) {
    final String c = signes[i];
    if (c == _chadda) {
      // Double la derniere lettre ecrite.
      final String ecrit = sortie.toString();
      if (ecrit.isNotEmpty) {
        sortie.write(ecrit[ecrit.length - 1]);
      }
      continue;
    }
    if (c == _soukoun) {
      continue;
    }
    final String? breve = _breves[c];
    if (breve != null) {
      sortie.write(breve);
      breveEcrite = breve;
      consonnePrecedente = false;
      continue;
    }
    final String? voyelle = _voyelles[c];
    if (voyelle != null) {
      if (voyelle != breveEcrite) {
        sortie.write(voyelle);
      }
      breveEcrite = null;
      consonnePrecedente = false;
      continue;
    }
    final String? consonne = _consonnes[c];
    if (consonne != null) {
      // Sans aucune voyelle brève dans le mot, un « a » separe deux
      // consonnes de suite : « mhmd » ne se lit pas.
      final bool suivieDeVoyelleBreve =
          i + 1 < signes.length &&
          (_breves.containsKey(signes[i + 1]) ||
              (signes[i + 1] == _chadda &&
                  i + 2 < signes.length &&
                  _breves.containsKey(signes[i + 2])));
      if (!voyellesPresentes && consonnePrecedente && !suivieDeVoyelleBreve) {
        sortie.write('a');
      }
      sortie.write(consonne);
      breveEcrite = null;
      consonnePrecedente = consonne.isNotEmpty;
      continue;
    }
    // Ni arabe ni signe connu : garde tel quel.
    sortie.write(c);
    breveEcrite = null;
    consonnePrecedente = false;
  }
  return sortie.toString();
}

String _majuscule(String mot) {
  if (mot.isEmpty) {
    return mot;
  }
  return mot[0].toUpperCase() + mot.substring(1);
}
