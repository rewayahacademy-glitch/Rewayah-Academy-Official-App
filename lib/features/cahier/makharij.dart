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
  OptionChoix(valeur: 'sin_sad', libelle: t.enseignant.cahier.makhrajSinSad),
  OptionChoix(valeur: 'ta_tah', libelle: t.enseignant.cahier.makhrajTaTah),
  OptionChoix(valeur: 'dhal_zay', libelle: t.enseignant.cahier.makhrajDhalZay),
  OptionChoix(valeur: 'ha_hah', libelle: t.enseignant.cahier.makhrajHaHah),
];
