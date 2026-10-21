// La recherche dans les Messages metier (`ThreadSearch`, spec section 18
// « Recherche » ; COM-0b UX_REV-04 ; contrat COM-BR-01, reserve COM-BR-A05).
//
// Ce n'est ni une route ni un ecran : un ETAT de la liste des fils.
//
// - Ordinateur et tablette : un champ en tete de la colonne des fils ; les
//   resultats remplacent la liste dans la meme surface, effacer le champ la
//   rend telle quelle.
// - Telephone : une surface plein ecran temporaire (`SurfaceRecherche` du
//   core), ouverte depuis la liste ; son retour restaure la liste et sa
//   position.
//
// V1 : un filtre LOCAL sur `fils()`. Il ne peut donc jamais rendre un fil que
// la personne n'a pas le droit de lire : il ne voit que ce que le serveur a
// deja autorise.

import 'package:flutter/material.dart';

import '../../core/tc_bibliotheque/recherche_catalogue.dart';
import 'port_messages_metier.dart';

/// Les fils dont un interlocuteur, une fonction, un objet ou l'apercu
/// contient chacun des mots de [texte], sans tenir compte des majuscules ni
/// des accents. Un texte vide rend [fils] tels quels, dans le meme ordre.
List<ResumeFil> filtrerFils(List<ResumeFil> fils, String texte) {
  final List<String> mots = RechercheCatalogue.normaliser(texte)
      .split(RegExp(r'\s+'))
      .where((String m) => m.isNotEmpty)
      .toList();
  if (mots.isEmpty) return fils;
  return <ResumeFil>[
    for (final ResumeFil f in fils)
      if (_contientTout(_texteCherchable(f), mots)) f,
  ];
}

String _texteCherchable(ResumeFil f) => RechercheCatalogue.normaliser(
  <String>[
    for (final Participant p in f.interlocuteurs) ...<String>[
      p.nomAffiche,
      ?p.fonction,
    ],
    f.objet.libelle,
    ?f.apercu,
  ].join(' '),
);

bool _contientTout(String cible, List<String> mots) =>
    mots.every((String m) => cible.contains(m));

/// L'etat de la recherche des fils : le texte cherche et, sur telephone,
/// l'ouverture de la surface plein ecran.
///
/// Il vit hors de la liste pour survivre a un changement d'adresse : ouvrir
/// un fil a cote de la liste (`/messages/:filId`) pose une nouvelle page,
/// et la liste de cette page reprend la meme recherche (spec section 18 :
/// la recherche est un etat de la liste, pas de la page).
class RechercheFilsControleur extends ChangeNotifier {
  /// Le texte cherche.
  final TextEditingController texte = TextEditingController();

  bool _surfaceOuverte = false;

  /// Vrai quand la surface plein ecran du telephone est ouverte, ou qu'une
  /// recherche est en cours : un filtre n'est jamais applique sans que son
  /// champ soit visible.
  bool get surfaceOuverte => _surfaceOuverte || texte.text.isNotEmpty;

  /// Ouvre la surface plein ecran.
  void ouvrirSurface() {
    if (_surfaceOuverte) return;
    _surfaceOuverte = true;
    notifyListeners();
  }

  /// Ferme la surface et efface la recherche : la liste revient entiere.
  void fermerSurface() {
    _surfaceOuverte = false;
    texte.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    texte.dispose();
    super.dispose();
  }
}

/// Les cles de la recherche des fils, pour les tests. Le champ et la
/// surface sont ceux du core (`ChampRecherche`, `SurfaceRecherche`, revue
/// COM-R, R-07), parametres par les textes des Messages et ces cles.
abstract final class ClesRechercheFils {
  /// Le champ de saisie.
  static const ValueKey<String> champ = ValueKey<String>(
    'recherche-fils-champ',
  );

  /// Le bouton qui efface.
  static const ValueKey<String> effacer = ValueKey<String>(
    'recherche-fils-effacer',
  );

  /// La surface plein ecran du telephone.
  static const ValueKey<String> surface = ValueKey<String>(
    'recherche-fils-surface',
  );

  /// Le bouton qui ferme la surface.
  static const ValueKey<String> fermer = ValueKey<String>(
    'recherche-fils-fermer',
  );
}
