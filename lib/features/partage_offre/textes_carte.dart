// Les textes de la carte a partager (CAND-06), dans ses quatre langues : le
// francais, l'anglais, le portugais et l'arabe, et seulement ces quatre
// (directeur, 22/10/2026 : « pas les langues vernaculaires, juste les
// internationales », puis « il va aussi avoir le portugais »).
//
// **Un fichier de donnees, pas du code** : le dessin de la carte
// (`carte_partage.dart`) ne contient aucun mot. Chaque langue porte tous ses
// textes, et `test/features/partage_offre/textes_carte_test.dart` le verifie.
// Ce ne sont pas des textes de l'application (`assets/i18n`, francais et arabe
// selon la langue de l'interface) : la carte est une image lue par quelqu'un
// d'autre, dans la langue de celui qui la partage ou de son choix, et l'anglais
// et le portugais n'existent que la.
//
// Mots de `mots-rewayah` : « Classe », jamais « groupe ». **Aucun prix, aucune
// promesse, jamais l'academie comme motif** : la carte parle a celui qui
// apprendra de ce qu'il y gagne. Le directeur ne valide pas de traduction
// (22/10/2026) : les textes anglais et portugais sont ecrits d'apres le
// francais et l'arabe, au sens pres (« turma » pour une Classe, le mot courant
// du portugais d'une classe d'eleves).
//
// Les deux textes arabes qui ne changent pas d'une langue a l'autre sont ici :
// la signature de marque (M-26) et le hadith (`DECISION-CANDIDATURES-2026-10-21`,
// section 1 bis).
library;

import '../../core/partage_offre/personnalisation_carte.dart';

/// L'espace insecable : il garde « petite classe » et les guillemets d'un seul
/// tenant au retour a la ligne.
const String _nbsp = '\u00a0';

/// La signature arabe de la marque (M-26, 20/10/2026), identique dans les
/// quatre langues : « ta porte vers le Coran ».
const String signatureArabe = 'بوّابتك نحو القرآن';

/// Le hadith, identique dans les quatre langues : at-Tirmidhi, d'apres Anas.
const String hadithArabe = 'الدال على الخير كفاعله';

/// Les textes de la carte dans une langue.
class TextesCarte {
  /// Cree les textes d'une langue.
  const TextesCarte({
    required this.nomPropre,
    required this.titre,
    required this.sousTitre,
    required this.decouvrir,
    required this.reference,
    this.traduction,
  });

  /// Le nom de la langue, dans la langue : « Français », « English »,
  /// « العربية ». Les puces de la page de partage.
  final String nomPropre;

  /// Le titre : ce que l'eleve y gagne.
  final String titre;

  /// La ligne sous le titre.
  final String sousTitre;

  /// L'appel du QR.
  final String decouvrir;

  /// La traduction du hadith ; `null` en arabe, ou le hadith se lit tel quel.
  final String? traduction;

  /// La reference du hadith.
  final String reference;
}

/// Les textes de chaque langue.
///
/// Les espaces insecables gardent « en petite classe » d'un seul tenant : le
/// titre se coupe apres la virgule, jamais au milieu de ce qu'il dit.
const Map<LangueCarte, TextesCarte> textesCarte = <LangueCarte, TextesCarte>{
  LangueCarte.francais: TextesCarte(
    nomPropre: 'Français',
    titre: 'Apprendre le Coran, en${_nbsp}petite${_nbsp}classe.',
    sousTitre: 'Avec le même enseignant.',
    decouvrir: 'Découvrir l\'offre',
    traduction:
        '«${_nbsp}Celui qui indique le bien est comme celui${_nbsp}qui${_nbsp}l\'accomplit.$_nbsp»',
    reference: 'Rapporté par at-Tirmidhi',
  ),
  LangueCarte.anglais: TextesCarte(
    nomPropre: 'English',
    titre: 'Learn the Quran in${_nbsp}a${_nbsp}small${_nbsp}class.',
    sousTitre: 'With the same teacher.',
    decouvrir: 'Discover the offer',
    traduction:
        '“The one who guides to good is like the${_nbsp}one${_nbsp}who${_nbsp}does${_nbsp}it.”',
    reference: 'Narrated by at-Tirmidhi',
  ),
  LangueCarte.portugais: TextesCarte(
    nomPropre: 'Português',
    titre: 'Aprender o Alcorão, em${_nbsp}turma${_nbsp}pequena.',
    sousTitre: 'Com o mesmo professor.',
    decouvrir: 'Conheça a oferta',
    traduction: '“Quem indica o bem é como quem o pratica.”',
    reference: 'Narrado por at-Tirmidhi',
  ),
  LangueCarte.arabe: TextesCarte(
    nomPropre: 'العربية',
    titre: 'تعلُّم القرآن في$_nbspفصل$_nbspصغير',
    sousTitre: 'مع المعلم نفسه.',
    decouvrir: 'اكتشاف العرض',
    reference: 'رواه الترمذي',
  ),
};
