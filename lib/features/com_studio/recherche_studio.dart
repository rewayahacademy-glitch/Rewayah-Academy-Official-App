// La recherche du Studio (`StudioSearch`, spec section 18 « Recherche » ;
// contrat COM-BR-08, `PortStudio.rechercher`).
//
// Ce n'est ni une route ni un ecran : un ETAT des surfaces du Studio.
//
// - Ordinateur et tablette : un champ PERSISTANT en tete de la colonne des
//   canaux ; les resultats prennent la place du canal dans la colonne de
//   contenu, avec leurs filtres dans la meme surface. Le canal ouvert reste
//   monte dessous (brouillon, position de lecture) : effacer ou fermer la
//   recherche le rend tel quel.
// - Telephone : une surface plein ecran temporaire, ouverte depuis la liste
//   des canaux ; son retour restaure la liste et sa position.
//
// Les resultats ne viennent que des canaux que la personne a le droit de
// lire : le port les limite, et l'ecran retire encore tout ce qui viendrait
// d'un canal absent (R-COM-08, `ResultatsStudio.sansCanalAbsent`).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/tc_bibliotheque/recherche_catalogue.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/carte_piece_jointe.dart';
import '../../core/widgets/controle_segmente.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/selecteur_section.dart';
import '../../core/widgets/vue_etat_communication.dart';
import 'port_studio.dart';

/// Les mots de [texte], normalises (sans majuscules ni accents) ; vide si
/// [texte] ne contient que des espaces.
List<String> motsRecherche(String texte) =>
    RechercheCatalogue.normaliser(texte)
        .split(RegExp(r'\s+'))
        .where((String m) => m.isNotEmpty)
        .toList();

/// Vrai si [cible] contient chacun des [mots], sans tenir compte des
/// majuscules ni des accents.
bool contientTousLesMots(String cible, List<String> mots) {
  final String normale = RechercheCatalogue.normaliser(cible);
  return mots.every(normale.contains);
}

/// Le debut d'un texte, coupe a un mot entier autour de [longueur]
/// caracteres, avec des points de suspension s'il a ete coupe.
String extraitDe(String texte, {int longueur = 120}) {
  final String plat = texte.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (plat.length <= longueur) return plat;
  final int coupe = plat.lastIndexOf(' ', longueur);
  return '${plat.substring(0, coupe > 0 ? coupe : longueur)}…';
}

/// Les familles de resultats que l'on peut filtrer (dans la meme surface).
enum FiltreRechercheStudio {
  /// Tous les resultats.
  tout,

  /// Les canaux.
  canaux,

  /// Les messages.
  messages,

  /// Les fichiers.
  fichiers,
}

/// Les cles de la recherche du Studio, pour les tests. Le champ et la
/// surface sont ceux du core (`ChampRecherche`, `SurfaceRecherche`, revue
/// COM-R, R-07), parametres par les textes du Studio et ces cles.
abstract final class ClesRechercheStudio {
  /// Le champ de saisie.
  static const ValueKey<String> champ = ValueKey<String>('studio-recherche');

  /// Le bouton qui efface.
  static const ValueKey<String> effacer = ValueKey<String>(
    'studio-recherche-effacer',
  );

  /// La surface plein ecran du telephone.
  static const ValueKey<String> surface = ValueKey<String>(
    'studio-recherche-surface',
  );

  /// Le bouton qui ferme la surface.
  static const ValueKey<String> fermer = ValueKey<String>(
    'studio-recherche-fermer',
  );
}

/// Les resultats d'une recherche du Studio, avec leurs filtres.
///
/// [resultats] est la lecture en cours : chargement (squelette annonce),
/// echec (« Reessayer » si [onReessayer]), capacite absente (sans
/// « Reessayer »), aucun resultat (ce qu'on peut essayer), ou contenu.
class ResultatsRechercheStudio extends StatelessWidget {
  /// Cree la vue.
  const ResultatsRechercheStudio({
    required this.texte,
    required this.resultats,
    required this.filtre,
    required this.onFiltre,
    required this.onOuvrirCanal,
    super.key,
    this.onReessayer,
    this.horsLigne = false,
  });

  /// Le texte cherche, tel que la personne l'a saisi.
  final String texte;

  /// La lecture des resultats.
  final AsyncValue<ResultatsStudio> resultats;

  /// La famille de resultats montree.
  final FiltreRechercheStudio filtre;

  /// Change la famille montree.
  final ValueChanged<FiltreRechercheStudio> onFiltre;

  /// Ouvre le canal d'identifiant donne (le resultat lui-meme, ou le canal
  /// du message ou du fichier trouve).
  final ValueChanged<String> onOuvrirCanal;

  /// Relance la recherche.
  final VoidCallback? onReessayer;

  /// Vrai si l'appareil est hors ligne : un echec le dit.
  final bool horsLigne;

  /// La cle de la vue, pour les tests.
  static const ValueKey<String> cle = ValueKey<String>('studio-resultats');

  /// La cle du compte des resultats, pour les tests.
  static const ValueKey<String> cleCompte = ValueKey<String>(
    'studio-resultats-compte',
  );

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: cle, child: _corps(context));
  }

  Widget _corps(BuildContext context) {
    if (resultats.isLoading) {
      return const SingleChildScrollView(
        child: VueEtatCommunication(etat: EtatCommunication.chargement),
      );
    }
    if (resultats.hasError) {
      return SingleChildScrollView(
        child: VueEtatCommunication.depuisErreur(
          resultats.error!,
          horsLigne: horsLigne,
          onReessayer: onReessayer,
        ),
      );
    }
    final ResultatsStudio tous = (resultats.value ?? ResultatsStudio())
        .sansCanalAbsent();
    if (tous.total == 0) {
      return SingleChildScrollView(
        child: EtatSysteme(
          nature: NatureEtat.aucunResultat,
          titre: t.com.studio.recherche.aucunTitre,
          phrase: t.com.studio.recherche.aucun(texte: texte.trim()),
        ),
      );
    }
    return _liste(context, tous);
  }

  Widget _liste(BuildContext context, ResultatsStudio tous) {
    final r = t.com.studio.recherche;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final bool canaux =
        filtre == FiltreRechercheStudio.tout ||
        filtre == FiltreRechercheStudio.canaux;
    final bool messages =
        filtre == FiltreRechercheStudio.tout ||
        filtre == FiltreRechercheStudio.messages;
    final bool fichiers =
        filtre == FiltreRechercheStudio.tout ||
        filtre == FiltreRechercheStudio.fichiers;
    final int vus =
        (canaux ? tous.canaux.length : 0) +
        (messages ? tous.messages.length : 0) +
        (fichiers ? tous.fichiers.length : 0);
    final List<Widget> groupes = <Widget>[
      if (canaux && tous.canaux.isNotEmpty)
        GroupeReglages(
          key: const ValueKey<String>('studio-resultats-canaux'),
          titre: r.canaux,
          lignes: <LigneRubrique>[
            for (final ResumeCanal c in tous.canaux)
              LigneRubrique(
                icone: AppIcons.discussion,
                libelle: c.nom,
                legende: c.description,
                onPress: () => onOuvrirCanal(c.id),
              ),
          ],
        ),
      if (messages && tous.messages.isNotEmpty)
        GroupeReglages(
          key: const ValueKey<String>('studio-resultats-messages'),
          titre: r.messages,
          lignes: <LigneRubrique>[
            for (final MessageTrouve m in tous.messages)
              LigneRubrique(
                icone: AppIcons.envoyerMessage,
                libelle: extraitDe(m.message.texte),
                legende: r.messageDe(
                  auteur: m.message.deSoi
                      ? t.com.socle.composants.composer.auteurSoi
                      : m.message.auteur.nomAffiche,
                  canal: m.canal.nom,
                ),
                onPress: () => onOuvrirCanal(m.canal.id),
              ),
          ],
        ),
      if (fichiers && tous.fichiers.isNotEmpty)
        GroupeReglages(
          key: const ValueKey<String>('studio-resultats-fichiers'),
          titre: r.fichiers,
          lignes: <LigneRubrique>[
            for (final FichierTrouve f in tous.fichiers)
              LigneRubrique(
                icone: switch (f.element.piece) {
                  final PieceJointe p => CartePieceJointe.iconeNature(p.nature),
                  null => AppIcons.supports,
                },
                libelle: f.element.titre,
                legende: r.dansCanal(canal: f.canal.nom),
                onPress: () => onOuvrirCanal(f.canal.id),
              ),
          ],
        ),
    ];
    return ListView(
      key: const PageStorageKey<String>('studio-resultats-liste'),
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      children: <Widget>[
        SelecteurSection<FiltreRechercheStudio>(
          libelle: r.filtre,
          valeur: filtre,
          onChange: onFiltre,
          sections: <Segment<FiltreRechercheStudio>>[
            Segment<FiltreRechercheStudio>(
              valeur: FiltreRechercheStudio.tout,
              libelle: r.tout,
            ),
            Segment<FiltreRechercheStudio>(
              valeur: FiltreRechercheStudio.canaux,
              libelle: r.canaux,
            ),
            Segment<FiltreRechercheStudio>(
              valeur: FiltreRechercheStudio.messages,
              libelle: r.messages,
            ),
            Segment<FiltreRechercheStudio>(
              valeur: FiltreRechercheStudio.fichiers,
              libelle: r.fichiers,
            ),
          ],
        ),
        Ecart.vLg,
        Semantics(
          liveRegion: true,
          child: Text(
            vus == 1 ? r.resultatUn : r.resultats(nombre: vus),
            key: cleCompte,
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
        ),
        Ecart.vSm,
        if (vus == 0)
          EtatSysteme(
            nature: NatureEtat.aucunResultat,
            titre: r.aucunTitre,
            phrase: r.aucunDansFiltre,
          )
        else
          for (final (int i, Widget g) in groupes.indexed) ...<Widget>[
            if (i > 0) Ecart.vXl,
            g,
          ],
      ],
    );
  }
}
