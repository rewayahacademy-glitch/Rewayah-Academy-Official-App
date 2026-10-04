// La recherche dans les Messages metier (`ThreadSearch`, spec section 18
// « Recherche » ; COM-0b UX_REV-04 ; contrat COM-BR-01, reserve COM-BR-A05).
//
// Ce n'est ni une route ni un ecran : un ETAT de la liste des fils.
//
// - Ordinateur et tablette : un champ en tete de la colonne des fils ; les
//   resultats remplacent la liste dans la meme surface, effacer le champ la
//   rend telle quelle.
// - Telephone : une surface plein ecran temporaire (`SurfaceRechercheFils`),
//   ouverte depuis la liste ; son retour restaure la liste et sa position.
//
// V1 : un filtre LOCAL sur `fils()`. Il ne peut donc jamais rendre un fil que
// la personne n'a pas le droit de lire : il ne voit que ce que le serveur a
// deja autorise.

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/tc_bibliotheque/recherche_catalogue.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bouton_icone.dart';
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

/// Le champ de recherche des fils.
///
/// Etiquete (« Rechercher une conversation »), avec l'aide « Nom, Classe ou
/// dossier » ; « Effacer la recherche » n'est rendu que s'il y a quelque
/// chose a effacer.
class ChampRechercheFils extends StatelessWidget {
  /// Cree le champ.
  const ChampRechercheFils({
    required this.controleur,
    super.key,
    this.autofocus = false,
    this.focusNode,
  });

  /// Le texte cherche ; l'appelant l'ecoute.
  final TextEditingController controleur;

  /// Vrai : le champ prend le focus a l'apparition (surface mobile).
  final bool autofocus;

  /// Le noeud de focus du champ, si l'appelant en a besoin.
  final FocusNode? focusNode;

  /// La cle du champ, pour les tests.
  static const ValueKey<String> cle = ValueKey<String>('recherche-fils-champ');

  /// La cle du bouton qui efface, pour les tests.
  static const ValueKey<String> cleEffacer = ValueKey<String>(
    'recherche-fils-effacer',
  );

  @override
  Widget build(BuildContext context) {
    final r = t.com.messages.recherche;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controleur,
      builder: (BuildContext context, TextEditingValue valeur, Widget? _) =>
          TextField(
            key: cle,
            controller: controleur,
            focusNode: focusNode,
            autofocus: autofocus,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              labelText: r.champ,
              hintText: r.aide,
              prefixIcon: ExcludeSemantics(
                child: Icon(AppIcons.recherche.repos),
              ),
              suffixIcon: valeur.text.isEmpty
                  ? null
                  : BoutonIcone(
                      key: cleEffacer,
                      icone: AppIcons.effacer,
                      libelle: r.effacer,
                      infobulle: r.effacer,
                      onPress: controleur.clear,
                    ),
            ),
          ),
    );
  }
}

/// La recherche plein ecran du telephone : retour, champ, resultats.
///
/// Temporaire : elle ne pousse aucune route. [onFermer] la referme et rend
/// la liste a l'appelant, qui garde sa position.
class SurfaceRechercheFils extends StatelessWidget {
  /// Cree la surface.
  const SurfaceRechercheFils({
    required this.controleur,
    required this.onFermer,
    required this.resultats,
    super.key,
  });

  /// Le texte cherche.
  final TextEditingController controleur;

  /// Ferme la recherche.
  final VoidCallback onFermer;

  /// Les resultats, sous le champ ; ils gerent leur propre defilement.
  final Widget resultats;

  /// La cle de la surface, pour les tests.
  static const ValueKey<String> cle = ValueKey<String>(
    'recherche-fils-surface',
  );

  /// La cle du bouton qui ferme la recherche, pour les tests.
  static const ValueKey<String> cleFermer = ValueKey<String>(
    'recherche-fils-fermer',
  );

  @override
  Widget build(BuildContext context) {
    final r = t.com.messages.recherche;
    return Column(
      key: cle,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            BoutonIcone(
              key: cleFermer,
              icone: AppIcons.retour,
              libelle: r.fermer,
              infobulle: r.fermer,
              onPress: onFermer,
            ),
            Ecart.hSm,
            Expanded(
              child: ChampRechercheFils(
                controleur: controleur,
                autofocus: true,
              ),
            ),
          ],
        ),
        Ecart.vLg,
        Expanded(child: resultats),
      ],
    );
  }
}
