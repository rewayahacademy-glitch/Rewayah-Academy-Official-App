import '../i18n/strings.g.dart';
import '../tc_bibliotheque/content_position.dart';
import '../tc_bibliotheque/content_range.dart';

/// Comment une position se dit a un humain.
///
/// **Le lot H ne rend jamais un `ContentPosition` brut a l'ecran.** « Sourate 2,
/// verset 255 » se lit, `ayah(2, 255)` ne se lit pas, et un eleve de sept ans
/// encore moins. La conversion vit ici et nulle part ailleurs : le bloc
/// « Avant le prochain cours », le post-cours et la carte de reprise en
/// dependent tous les trois, et trois formulations differentes du meme endroit
/// feraient croire a trois endroits differents.
///
/// [TypeAncrage.fraction] n'a **pas** de formulation propre : « 43 % du
/// support » ne dit rien d'utile a personne, et la spec prefere l'ancrage
/// semantique pour cette raison exacte. On nomme alors le support entier.
String positionLisible(ContentPosition position) =>
    switch (position.typeAncrage) {
      TypeAncrage.page => _plagePages(
        premiere: position.page ?? 0,
        derniere: position.page ?? 0,
      ),
      TypeAncrage.ayah => _plageVersets(
        sourate: position.sourate ?? 0,
        premier: position.ayah ?? 0,
        dernier: position.ayah ?? 0,
      ),
      TypeAncrage.section => t.tc.parcours.plage.section(
        section: position.sectionId ?? '',
      ),
      TypeAncrage.fraction => t.tc.parcours.plage.ressource,
    };

/// Comment une plage de travail se dit a un humain.
///
/// Le cas d'une plage qui **traverse deux sourates** est traite a part : dire
/// « Sourate 2, versets 284 a 5 » serait faux et illisible.
String plageLisible(ContentRange plage) {
  switch (plage.typeAncrage) {
    case TypeAncrage.page:
      return _plagePages(
        premiere: plage.debut.page ?? 0,
        derniere: plage.fin.page ?? 0,
      );
    case TypeAncrage.ayah:
      if (plage.debut.sourate != plage.fin.sourate) {
        return t.tc.parcours.plage.versetsCroisee(
          sourateDebut: plage.debut.sourate ?? 0,
          versetDebut: plage.debut.ayah ?? 0,
          sourateFin: plage.fin.sourate ?? 0,
          versetFin: plage.fin.ayah ?? 0,
        );
      }
      return _plageVersets(
        sourate: plage.debut.sourate ?? 0,
        premier: plage.debut.ayah ?? 0,
        dernier: plage.fin.ayah ?? 0,
      );
    case TypeAncrage.section:
      return t.tc.parcours.plage.section(section: plage.debut.sectionId ?? '');
    case TypeAncrage.fraction:
      return t.tc.parcours.plage.ressource;
  }
}

/// Une page, ou un intervalle de pages quand elles different.
String _plagePages({required int premiere, required int derniere}) =>
    premiere == derniere
    ? t.tc.parcours.plage.pageUnique(premiere: premiere)
    : t.tc.parcours.plage.pages(premiere: premiere, derniere: derniere);

/// Un verset, ou un intervalle de versets quand ils different.
String _plageVersets({
  required int sourate,
  required int premier,
  required int dernier,
}) => premier == dernier
    ? t.tc.parcours.plage.versetUnique(sourate: sourate, premier: premier)
    : t.tc.parcours.plage.versets(
        sourate: sourate,
        premier: premier,
        dernier: dernier,
      );
