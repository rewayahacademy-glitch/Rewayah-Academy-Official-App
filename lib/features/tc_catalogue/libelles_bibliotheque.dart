import '../../core/i18n/strings.g.dart';
import '../../core/tc_bibliotheque/library_resource.dart';
import '../../core/tc_bibliotheque/vue_catalogue.dart';
import '../../core/tc_telechargement/port_etat_offline.dart';

/// Le titre d'une section du catalogue.
String libelleSection(IdSectionCatalogue id) => switch (id) {
  IdSectionCatalogue.continuer => t.tc.bibliotheque.sections.continuer,
  IdSectionCatalogue.pourCeGroupe => t.tc.bibliotheque.sections.pourCeGroupe,
  IdSectionCatalogue.recents => t.tc.bibliotheque.sections.recents,
  IdSectionCatalogue.tousLesSupports =>
    t.tc.bibliotheque.sections.tousLesSupports,
  IdSectionCatalogue.resultats => t.tc.bibliotheque.sections.resultats,
};

/// Le libelle d'un etat hors ligne.
String libelleOffline(EtatOffline etat) => switch (etat) {
  EtatOffline.aTelecharger => t.tc.bibliotheque.offline.aTelecharger,
  EtatOffline.enCours => t.tc.bibliotheque.offline.enCours,
  EtatOffline.enCache => t.tc.bibliotheque.offline.enCache,
  EtatOffline.telecharge => t.tc.bibliotheque.offline.telecharge,
  EtatOffline.indisponible => t.tc.bibliotheque.offline.indisponible,
};

/// Le libelle d'un type de ressource.
String libelleTypeRessource(TypeRessource type) => switch (type) {
  TypeRessource.quran => t.tc.bibliotheque.type.quran,
  TypeRessource.texteStructure => t.tc.bibliotheque.type.texteStructure,
  TypeRessource.pdf => t.tc.bibliotheque.type.pdf,
  TypeRessource.image => t.tc.bibliotheque.type.image,
  TypeRessource.lecon => t.tc.bibliotheque.type.lecon,
};
