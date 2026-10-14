import '../../core/i18n/strings.g.dart';
import '../../core/widgets/choice_card_group.dart';

/// Les quatre paires de makharij proposees par defaut dans le cahier.
///
/// **Une liste fermee, et courte.** La fiche `ENS-04` demande « une matrice
/// Makharij en puces geantes, quatre paires par defaut, trois taps maximum » :
/// un referentiel complet des dix-sept makharij ferait de l'ecran des 45
/// secondes un formulaire de phonetique. Ce sont les quatre confusions que
/// l'enseignant signale le plus souvent ; la carte « Autre » de
/// [ChoiceCardGroup] porte tout le reste, sans qu'aucun point ne soit
/// impossible a noter.
///
/// Les valeurs sont les cles techniques destinees a `makharij_findings.makhraj`
/// (`0001_fondations.sql`), pas des libelles : le libelle vit dans l'i18n, et
/// deux langues ne doivent pas produire deux cles.
///
/// **Cette liste vit ici et pas dans `lib/core/`** parce qu'un seul ecran la
/// consomme aujourd'hui. Le jour ou un second ecran en a besoin, elle remonte en
/// `core` par une demande de contrat : deux ecrans qui proposeraient deux listes
/// differentes de makharij seraient pires qu'une liste trop courte.
List<OptionChoix> referentielMakharij() => <OptionChoix>[
  OptionChoix(
    valeur: 'sin_sad',
    libelle: isolerPaireArabe(t.enseignant.cahier.makhrajSinSad),
  ),
  OptionChoix(
    valeur: 'ta_tah',
    libelle: isolerPaireArabe(t.enseignant.cahier.makhrajTaTah),
  ),
  OptionChoix(
    valeur: 'dhal_zay',
    libelle: isolerPaireArabe(t.enseignant.cahier.makhrajDhalZay),
  ),
  OptionChoix(
    valeur: 'ha_hah',
    libelle: isolerPaireArabe(t.enseignant.cahier.makhrajHaHah),
  ),
];

/// Isole la paire de lettres arabes entre parentheses d'un libelle francais.
///
/// EN-7c-200 : dans « Sîn / Sâd (س / ص) », la paire arabe est un passage de
/// droite a gauche dans une phrase de gauche a droite. A 200 % de texte, la
/// ligne se coupait dans la paire et l'algorithme bidirectionnel reordonnait
/// chaque morceau a part : « Sîn / Sâd (/ س » puis « ص) ». La paire est donc
/// encadree d'un isolat droite-a-gauche (U+2067 ... U+2069), qui la place d'un
/// bloc, et ses espaces deviennent insecables, pour qu'aucune coupure ne la
/// separe. Ce sont des lettres en libelle, pas du texte coranique.
String isolerPaireArabe(String libelle) => libelle.replaceAllMapped(
  RegExp('\\(([^()]*[\u0600-\u06FF][^()]*)\\)'),
  (Match m) => '(\u2067${m[1]!.replaceAll(' ', '\u00A0')}\u2069)',
);
